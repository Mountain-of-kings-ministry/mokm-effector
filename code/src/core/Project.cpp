#include "Project.h"
#include "Composition.h"
#include "Track.h"
#include "Layer.h"
#include "ShapeLayer.h"
#include "TextLayer.h"
#include "Keyframe.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDir>
#include <QFileInfo>

Project::Project(QObject *parent)
    : QObject(parent)
{
    auto *defaultComp = new Composition(this);
    defaultComp->setName("Main Composition");
    m_compositions.append(defaultComp);
    m_activeComposition = defaultComp;
}

Project::~Project()
{
}

void Project::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Project::setFilePath(const QUrl &path)
{
    if (m_filePath != path) {
        m_filePath = path;
        emit filePathChanged();
    }
}

void Project::setFrameRate(qreal fps)
{
    fps = qMax(1.0, fps);
    if (!qFuzzyCompare(m_frameRate, fps)) {
        m_frameRate = fps;
        emit frameRateChanged();
    }
}

QQmlListProperty<Composition> Project::compositions()
{
    return QQmlListProperty<Composition>(this, &m_compositions);
}

Composition* Project::compositionAt(int index) const
{
    if (index >= 0 && index < m_compositions.size())
        return m_compositions[index];
    return nullptr;
}

void Project::addComposition(Composition *comp)
{
    if (!comp || m_compositions.contains(comp))
        return;
    comp->setParent(this);
    m_compositions.append(comp);
    emit compositionsChanged();
}

void Project::removeComposition(Composition *comp)
{
    if (m_compositions.removeOne(comp)) {
        if (m_activeComposition == comp)
            setActiveComposition(m_compositions.isEmpty() ? nullptr : m_compositions.first());
        emit compositionsChanged();
    }
}

void Project::setActiveComposition(Composition *comp)
{
    if (m_activeComposition != comp) {
        m_activeComposition = comp;
        emit activeCompositionChanged();
    }
}

// ── Assets ──

QQmlListProperty<Layer> Project::assets()
{
    return QQmlListProperty<Layer>(this, &m_assets);
}

Layer* Project::assetAt(int index) const
{
    if (index >= 0 && index < m_assets.size())
        return m_assets[index];
    return nullptr;
}

void Project::addAsset(Layer *layer)
{
    if (!layer || m_assets.contains(layer))
        return;
    layer->setParent(this);
    m_assets.append(layer);
    emit assetsChanged();
}

void Project::removeAsset(Layer *layer)
{
    if (m_assets.removeOne(layer)) {
        emit assetsChanged();
    }
}

// ── Undo / Redo ──

void Project::captureSnapshot()
{
    QJsonObject snap;
    snap["project"] = serializeToJson();
    m_undoStack.append(snap);
    if (m_undoStack.size() > kMaxUndoSteps)
        m_undoStack.removeFirst();
    m_redoStack.clear();
    emit undoChanged();
}

void Project::undo()
{
    if (m_undoStack.isEmpty())
        return;
    // save current state to redo
    QJsonObject currentSnap;
    currentSnap["project"] = serializeToJson();
    m_redoStack.append(currentSnap);
    if (m_redoStack.size() > kMaxUndoSteps)
        m_redoStack.removeFirst();

    QJsonObject snap = m_undoStack.takeLast();
    deserializeFromJson(snap["project"].toString());
    emit undoChanged();
}

void Project::redo()
{
    if (m_redoStack.isEmpty())
        return;
    // save current state to undo
    QJsonObject currentSnap;
    currentSnap["project"] = serializeToJson();
    m_undoStack.append(currentSnap);
    if (m_undoStack.size() > kMaxUndoSteps)
        m_undoStack.removeFirst();

    QJsonObject snap = m_redoStack.takeLast();
    deserializeFromJson(snap["project"].toString());
    emit undoChanged();
}

void Project::clearUndoRedo()
{
    m_undoStack.clear();
    m_redoStack.clear();
    emit undoChanged();
}

// ── JSON Serialization ──

QString Project::serializeToJson() const
{
    QJsonObject root;
    root["name"] = m_name;
    root["version"] = "0.1";
    root["frameRate"] = m_frameRate;

    // Assets
    QJsonArray assetsArr;
    for (auto *asset : m_assets) {
        if (auto *sl = qobject_cast<ShapeLayer*>(asset))
            assetsArr.append(sl->toJson());
        else if (auto *tl = qobject_cast<TextLayer*>(asset))
            assetsArr.append(tl->toJson());
    }
    root["assets"] = assetsArr;

    // Compositions
    QJsonArray compsArr;
    for (auto *comp : m_compositions) {
        QJsonObject compObj;
        compObj["name"] = comp->name();
        compObj["width"] = comp->width();
        compObj["height"] = comp->height();
        compObj["duration"] = comp->duration();
        compObj["frameRate"] = comp->frameRate();

        // Tracks
        QJsonArray tracksArr;
        for (int ti = 0; ti < comp->trackCount(); ++ti) {
            auto *track = comp->trackAt(ti);
            QJsonObject trackObj;
            trackObj["name"] = track->name();
            trackObj["locked"] = track->locked();

            QJsonArray clipsArr;
            for (int ci = 0; ci < track->clipCount(); ++ci) {
                auto *clip = track->clipAt(ci);
                QJsonObject clipObj;
                if (auto *sl = qobject_cast<ShapeLayer*>(clip))
                    clipObj = sl->toJson();
                else if (auto *tl = qobject_cast<TextLayer*>(clip))
                    clipObj = tl->toJson();
                clipsArr.append(clipObj);
            }
            trackObj["clips"] = clipsArr;
            tracksArr.append(trackObj);
        }
        compObj["tracks"] = tracksArr;
        compsArr.append(compObj);
    }
    root["compositions"] = compsArr;

    // Active composition index
    int activeIdx = m_compositions.indexOf(m_activeComposition);
    if (activeIdx >= 0)
        root["activeComposition"] = activeIdx;

    QJsonDocument doc(root);
    return QString::fromUtf8(doc.toJson(QJsonDocument::Indented));
}

bool Project::deserializeFromJson(const QString &json)
{
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
    if (doc.isNull() || !doc.isObject())
        return false;

    QJsonObject root = doc.object();
    setName(root["name"].toString("Untitled"));
    setFrameRate(root["frameRate"].toDouble(30.0));

    // Clear existing
    for (auto *comp : m_compositions)
        comp->deleteLater();
    m_compositions.clear();
    for (auto *asset : m_assets)
        asset->deleteLater();
    m_assets.clear();

    // Load assets
    QJsonArray assetsArr = root["assets"].toArray();
    for (const auto &val : assetsArr) {
        QJsonObject obj = val.toObject();
        Layer *layer = layerFromJson(obj, this);
        if (layer)
            m_assets.append(layer);
    }
    emit assetsChanged();

    // Load compositions
    QJsonArray compsArr = root["compositions"].toArray();
    for (const auto &val : compsArr) {
        QJsonObject compObj = val.toObject();
        auto *comp = new Composition(this);
        comp->setName(compObj["name"].toString("Composition"));
        comp->setWidth(compObj["width"].toInt(1920));
        comp->setHeight(compObj["height"].toInt(1080));
        comp->setDuration(compObj["duration"].toInt(150));
        comp->setFrameRate(compObj["frameRate"].toDouble(30.0));

        // Load tracks
        QJsonArray tracksArr = compObj["tracks"].toArray();
        for (const auto &tval : tracksArr) {
            QJsonObject trackObj = tval.toObject();
            auto *track = comp->addTrack(trackObj["name"].toString());
            track->setLocked(trackObj["locked"].toBool(false));

            QJsonArray clipsArr = trackObj["clips"].toArray();
            for (const auto &cval : clipsArr) {
                QJsonObject clipObj = cval.toObject();
                Layer *clip = layerFromJson(clipObj, track);
                if (clip)
                    track->addClip(clip);
            }
        }
        m_compositions.append(comp);
    }
    emit compositionsChanged();

    // Restore active composition
    int activeIdx = root["activeComposition"].toInt(0);
    if (activeIdx >= 0 && activeIdx < m_compositions.size())
        setActiveComposition(m_compositions[activeIdx]);
    else if (!m_compositions.isEmpty())
        setActiveComposition(m_compositions.first());

    return true;
}

bool Project::saveToFile(const QUrl &path)
{
    QString filePath = path.toLocalFile();
    if (filePath.isEmpty())
        return false;

    // Ensure .mokm extension
    if (!filePath.endsWith(".mokm", Qt::CaseInsensitive))
        filePath += ".mokm";

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    file.write(serializeToJson().toUtf8());
    file.close();

    setFilePath(QUrl::fromLocalFile(filePath));
    setName(QFileInfo(filePath).baseName());
    return true;
}

bool Project::loadFromFile(const QUrl &path)
{
    QString filePath = path.toLocalFile();
    if (filePath.isEmpty())
        return false;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QString json = QString::fromUtf8(file.readAll());
    file.close();

    if (!deserializeFromJson(json))
        return false;

    setFilePath(path);
    setName(QFileInfo(filePath).baseName());
    return true;
}

// ── Private Helpers ──

QJsonObject Project::layerToJson(Layer *layer) const
{
    if (auto *sl = qobject_cast<ShapeLayer*>(layer))
        return sl->toJson();
    if (auto *tl = qobject_cast<TextLayer*>(layer))
        return tl->toJson();
    return layer->toJson();
}

Layer* Project::layerFromJson(const QJsonObject &obj, QObject *parent) const
{
    QString type = obj["type"].toString();
    if (type == "shape") {
        auto *sl = new ShapeLayer(parent);
        sl->fromJson(obj);
        return sl;
    } else if (type == "text") {
        auto *tl = new TextLayer(parent);
        tl->fromJson(obj);
        return tl;
    }
    return nullptr;
}
