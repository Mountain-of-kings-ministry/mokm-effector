#include "Track.h"
#include "Strip.h"
#include "Layer.h"
#include "ShapeLayer.h"
#include "TextLayer.h"
#include "VideoLayer.h"
#include "AudioLayer.h"
#include "TimelineLayer.h"

#ifdef MOKM_ENABLE_NODES
#include "../nodes/NodeStrip.h"
#include "../nodes/NodeGraph.h"
#include "../nodes/nodes/generators/RectangleNode.h"
#endif

Track::Track(QObject *parent)
    : QObject(parent)
    , m_name("Track 1")
{
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

    // Create a NodeGraph with a generator node matching the asset type
    auto *graph = new NodeGraph(strip);
    QString nodeType = "Rectangle"; // Default fallback

    // Determine node type from asset
    if (auto *shape = qobject_cast<ShapeLayer*>(asset)) {
        static const char* shapeNames[] = {
            "Rectangle", "Ellipse", "Circle", "Triangle",
            "Polygon", "Star", "Line", "Arrow", "RoundedRect",
            "Arc", "Grid", "Spiral"
        };
        int st = shape->shapeType();
        if (st >= 0 && st < 12)
            nodeType = QString::fromLatin1(shapeNames[st]);
    } else if (qobject_cast<TextLayer*>(asset)) {
        nodeType = "Text";
    }

    int nodeId = graph->addNodeAutoConnect(nodeType);
    Q_UNUSED(nodeId)

    strip->setNodeGraph(graph);

    // Clone the asset element for backward compat
    auto *element = asset->clone(strip);
    strip->setElement(element);

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
