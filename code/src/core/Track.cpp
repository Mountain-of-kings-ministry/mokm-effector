#include "Track.h"
#include "EffectChain.h"
#include "Strip.h"
#include "Layer.h"
#include "ShapeLayer.h"
#include "TextLayer.h"
#include "VideoLayer.h"
#include "AudioLayer.h"
#include "ImageLayer.h"
#include "TimelineLayer.h"

#ifdef MOKM_ENABLE_NODES
#include "../nodes/NodeStrip.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUuid>
#endif

Track::Track(QObject *parent)
    : QObject(parent)
    , m_name("Track 1")
{
    m_effectChain = new EffectChain(this);
}

void Track::setTrackType(int type)
{
    if (m_trackType != type) {
        m_trackType = type;
        
        // Update default name and color based on type
        switch (type) {
        case Video:
            m_name = QStringLiteral("Video");
            m_color = QColor("#1e3a8a"); // Deep Blue
            break;
        case Audio:
            m_name = QStringLiteral("Audio");
            m_color = QColor("#064e3b"); // Deep Green
            break;
        case Image:
            m_name = QStringLiteral("Image");
            m_color = QColor("#7f1d1d"); // Deep Red
            break;
        }
        
        emit trackTypeChanged();
        emit nameChanged();
        emit colorChanged();
    }
}

void Track::setColor(const QColor &c)
{
    if (m_color != c) {
        m_color = c;
        emit colorChanged();
    }
}

QString Track::trackTypeName(int type) const
{
    return trackTypeNameStatic(type);
}

QString Track::trackTypeNameStatic(int type)
{
    switch (type) {
    case Audio: return QStringLiteral("Audio");
    case Image: return QStringLiteral("Image");
    case Video:
    default:    return QStringLiteral("Video");
    }
}

Track::~Track()
{
}

void Track::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

QQmlListProperty<Strip> Track::strips()
{
    return QQmlListProperty<Strip>(this, &m_strips);
}

Strip* Track::stripAt(int index) const
{
    if (index >= 0 && index < m_strips.size())
        return m_strips[index];
    return nullptr;
}

void Track::addStrip(Strip *strip)
{
    if (!strip || m_strips.contains(strip))
        return;
    strip->setParent(this);
    strip->setTrack(this);
    m_strips.append(strip);
    emit stripsChanged();
}

void Track::removeStrip(Strip *strip)
{
    if (m_strips.removeOne(strip)) {
        strip->setTrack(nullptr);
        emit stripsChanged();
    }
}

Strip* Track::removeStripAt(int index)
{
    if (index < 0 || index >= m_strips.size())
        return nullptr;
    auto *strip = m_strips.takeAt(index);
    strip->setTrack(nullptr);
    emit stripsChanged();
    return strip;
}

void Track::moveStrip(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_strips.size())
        return;
    if (toIndex < 0 || toIndex >= m_strips.size())
        return;
    if (fromIndex == toIndex)
        return;
    m_strips.move(fromIndex, toIndex);
    emit stripsChanged();
}

int Track::indexOf(Strip *strip) const
{
    return m_strips.indexOf(strip);
}

Strip* Track::createStripFromAsset(Layer *asset, const QString &stripName, int startFrame, int duration)
{
    if (!asset)
        return nullptr;

    // Validate asset type matches track type
    bool typeOk = false;
    switch (m_trackType) {
    case Video:
        typeOk = (qobject_cast<VideoLayer*>(asset) != nullptr)
              || (qobject_cast<ShapeLayer*>(asset) != nullptr)
              || (qobject_cast<TextLayer*>(asset) != nullptr)
              || (qobject_cast<ImageLayer*>(asset) != nullptr);
        break;
    case Audio:
        typeOk = (qobject_cast<AudioLayer*>(asset) != nullptr);
        break;
    case Image:
        typeOk = (qobject_cast<ImageLayer*>(asset) != nullptr)
              || (qobject_cast<ShapeLayer*>(asset) != nullptr)
              || (qobject_cast<TextLayer*>(asset) != nullptr);
        break;
    }
    if (!typeOk)
        return nullptr;

    int actualDuration = duration;
    if (actualDuration <= 0) {
        if (auto *vl = qobject_cast<VideoLayer*>(asset)) {
            actualDuration = vl->frameCount();
            if (actualDuration <= 0) actualDuration = 90;
        } else if (auto *al = qobject_cast<AudioLayer*>(asset)) {
            actualDuration = al->frameCount();
            if (actualDuration <= 0) actualDuration = qMax(1, al->duration());
        } else {
            actualDuration = 90;
        }
    }

#ifdef MOKM_ENABLE_NODES
    auto *strip = new NodeStrip(this);
    strip->setName(stripName.isEmpty() ? asset->name() : stripName);
    strip->setStartFrame(startFrame);
    strip->setDuration(actualDuration);

    // Clone the asset element
    auto *element = asset->clone(strip);
    strip->setElement(element);

    // Auto-generate initial node graph: source → render output
    {
        QJsonObject rootObj;
        QJsonArray nodesArr;

        QString srcType = QStringLiteral("mokm/strip/source/shape");
        if (qobject_cast<VideoLayer*>(asset))
            srcType = QStringLiteral("mokm/strip/source/video");
        else if (qobject_cast<AudioLayer*>(asset))
            srcType = QStringLiteral("mokm/strip/source/audio");
        else if (qobject_cast<ImageLayer*>(asset))
            srcType = QStringLiteral("mokm/strip/source/image");

        QJsonObject srcNode;
        QString srcId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        srcNode["id"] = srcId;
        srcNode["type"] = srcType;
        srcNode["x"] = 100;
        srcNode["y"] = 200;
        srcNode["data"] = QJsonObject();
        nodesArr.append(srcNode);

        QJsonObject outNode;
        QString outId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        outNode["id"] = outId;
        outNode["type"] = QStringLiteral("mokm/output/render");
        outNode["x"] = 500;
        outNode["y"] = 200;
        outNode["data"] = QJsonObject();
        nodesArr.append(outNode);

        rootObj["nodes"] = nodesArr;

        QJsonArray edgesArr;
        QJsonObject edge;
        edge["id"] = QUuid::createUuid().toString(QUuid::WithoutBraces);
        edge["sourceNodeId"] = srcId;
        edge["sourcePort"] = QStringLiteral("output");
        edge["targetNodeId"] = outId;
        edge["targetPort"] = QStringLiteral("input");
        edgesArr.append(edge);
        rootObj["edges"] = edgesArr;

        QJsonDocument doc(rootObj);
        auto jsonStr = QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
        strip->setNodeGraphJson(jsonStr);
        qDebug() << "Track: created NodeStrip with auto-generated graph, json length:" << jsonStr.length();
    }

    addStrip(strip);
    return strip;
#else
    auto *strip = new Strip(this);
    strip->setName(stripName.isEmpty() ? asset->name() : stripName);
    strip->setStartFrame(startFrame);
    strip->setDuration(actualDuration);
    auto *element = asset->clone(strip);
    strip->setElement(element);
    addStrip(strip);
    return strip;
#endif
}

void Track::deleteTrack()
{
    if (m_layer)
        m_layer->removeTrack(this);
}

// ── Track property setters ──

void Track::setEnabled(bool v)
{
    if (m_enabled != v) {
        m_enabled = v;
        emit enabledChanged();
    }
}

void Track::setMute(bool v)
{
    if (m_mute != v) {
        m_mute = v;
        emit muteChanged();
    }
}

void Track::setSolo(bool v)
{
    if (m_solo != v) {
        m_solo = v;
        emit soloChanged();
    }
}

void Track::setOpacity(qreal v)
{
    v = qBound(0.0, v, 1.0);
    if (!qFuzzyCompare(m_opacity, v)) {
        m_opacity = v;
        emit opacityChanged();
    }
}

void Track::setPan(qreal v)
{
    v = qBound(-1.0, v, 1.0);
    if (!qFuzzyCompare(m_pan, v)) {
        m_pan = v;
        emit panChanged();
    }
}

void Track::setCollapsed(bool v)
{
    if (m_collapsed != v) {
        m_collapsed = v;
        emit collapsedChanged();
    }
}

void Track::setLocked(bool v)
{
    if (m_locked != v) {
        m_locked = v;
        emit lockedChanged();
    }
}

void Track::setPriority(int v)
{
    if (m_priority != v) {
        m_priority = v;
        emit priorityChanged();
    }
}

void Track::setLooping(bool v)
{
    if (m_looping != v) {
        m_looping = v;
        emit loopingChanged();
    }
}

void Track::setLoopCount(int v)
{
    v = qMax(1, v);
    if (m_loopCount != v) {
        m_loopCount = v;
        emit loopCountChanged();
    }
}

void Track::setLayer(TimelineLayer *layer)
{
    m_layer = layer;
}
