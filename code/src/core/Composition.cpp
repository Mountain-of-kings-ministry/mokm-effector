#include "Composition.h"
#include "TimelineLayer.h"
#include "Track.h"
#include "Strip.h"
#include "Layer.h"

Composition::Composition(QObject *parent)
    : QObject(parent)
{
}

Composition::~Composition()
{
    qDeleteAll(m_timelineLayers);
    m_timelineLayers.clear();
    m_flatLayers.clear();
}

void Composition::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Composition::setWidth(int w)
{
    if (m_width != w) {
        m_width = w;
        emit resolutionChanged();
    }
}

void Composition::setHeight(int h)
{
    if (m_height != h) {
        m_height = h;
        emit resolutionChanged();
    }
}

void Composition::setDuration(int frames)
{
    frames = qMax(1, frames);
    if (m_duration != frames) {
        m_duration = frames;
        emit durationChanged();
    }
}

void Composition::setFrameRate(qreal fps)
{
    fps = qMax(1.0, fps);
    if (!qFuzzyCompare(m_frameRate, fps)) {
        m_frameRate = fps;
        emit frameRateChanged();
    }
}

// ── TimelineLayer management ──

QQmlListProperty<TimelineLayer> Composition::layers()
{
    return QQmlListProperty<TimelineLayer>(this, &m_timelineLayers);
}

TimelineLayer* Composition::layerAt(int index) const
{
    if (index >= 0 && index < m_timelineLayers.size())
        return m_timelineLayers[index];
    return nullptr;
}

void Composition::addLayer(TimelineLayer *layer)
{
    if (!layer || m_timelineLayers.contains(layer))
        return;
    layer->setParent(this);
    layer->setComposition(this);
    m_timelineLayers.append(layer);
    connect(layer, &TimelineLayer::tracksChanged, this, [this, layer]() {
        for (int ti = 0; ti < layer->trackCount(); ++ti) {
            auto *track = layer->trackAt(ti);
            disconnect(track, &Track::stripsChanged, this, &Composition::rebuildFlatLayers);
            connect(track, &Track::stripsChanged, this, &Composition::rebuildFlatLayers);
        }
        rebuildFlatLayers();
    });
    for (int ti = 0; ti < layer->trackCount(); ++ti)
        connect(layer->trackAt(ti), &Track::stripsChanged, this, &Composition::rebuildFlatLayers);
    rebuildFlatLayers();
    emit layersChanged();
}

void Composition::removeLayer(TimelineLayer *layer)
{
    if (!layer)
        return;
    if (m_timelineLayers.removeOne(layer)) {
        rebuildFlatLayers();
        emit layersChanged();
        layer->deleteLater();
    }
}

int Composition::layerIndex(TimelineLayer *layer) const
{
    return m_timelineLayers.indexOf(layer);
}

void Composition::moveLayer(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_timelineLayers.size())
        return;
    if (toIndex < 0 || toIndex >= m_timelineLayers.size())
        return;
    if (fromIndex == toIndex)
        return;
    m_timelineLayers.move(fromIndex, toIndex);
    emit layersChanged();
}

void Composition::clearLayers()
{
    if (m_timelineLayers.isEmpty())
        return;
    qDeleteAll(m_timelineLayers);
    m_timelineLayers.clear();
    rebuildFlatLayers();
    emit layersChanged();
}

TimelineLayer* Composition::ensureDefaultLayer()
{
    if (m_timelineLayers.isEmpty()) {
        auto *layer = new TimelineLayer(this);
        layer->setName("Layer 1");
        // Ensure at least one track before addLayer so the connection loop catches it
        layer->addTrack("Track 1");
        addLayer(layer);
    }
    return m_timelineLayers.first();
}

// ── Flat visual layer list ──

Layer* Composition::flatLayerAt(int index) const
{
    if (index >= 0 && index < m_flatLayers.size())
        return m_flatLayers[index];
    return nullptr;
}

void Composition::rebuildFlatLayers()
{
    m_flatLayers.clear();
    for (auto *tl : m_timelineLayers) {
        for (int ti = 0; ti < tl->trackCount(); ++ti) {
            auto *track = tl->trackAt(ti);
            for (int si = 0; si < track->stripCount(); ++si) {
                auto *strip = track->stripAt(si);
                if (strip && strip->element())
                    m_flatLayers.append(strip->element());
            }
        }
    }
    emit layersChanged();
}
