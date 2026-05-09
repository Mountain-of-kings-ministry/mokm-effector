#include "Composition.h"
#include "Layer.h"
#include "Track.h"

Composition::Composition(QObject *parent)
    : QObject(parent)
{
}

Composition::~Composition()
{
    qDeleteAll(m_tracks);
    m_tracks.clear();
    m_layers.clear();
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

QQmlListProperty<Layer> Composition::layers()
{
    return QQmlListProperty<Layer>(this, &m_layers);
}

Layer* Composition::layerAt(int index) const
{
    if (index >= 0 && index < m_layers.size())
        return m_layers[index];
    return nullptr;
}

int Composition::layerIndex(Layer *layer) const
{
    return m_layers.indexOf(layer);
}

void Composition::addLayer(Layer *layer)
{
    if (!layer || m_layers.contains(layer))
        return;
    ensureDefaultTrack()->addClip(layer);
}

void Composition::removeLayer(Layer *layer)
{
    for (auto *track : m_tracks) {
        if (track->clipList().contains(layer)) {
            track->removeClip(layer);
            return;
        }
    }
}

void Composition::moveLayer(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_layers.size())
        return;
    if (toIndex < 0 || toIndex >= m_layers.size())
        return;
    if (fromIndex == toIndex)
        return;

    Layer *layer = m_layers[fromIndex];
    for (auto *track : m_tracks) {
        int idx = track->indexOf(layer);
        if (idx >= 0) {
            track->moveClip(idx, toIndex);
            return;
        }
    }
}

void Composition::clearLayers()
{
    Track *defaultTrack = ensureDefaultTrack();
    QVector<Layer*> allClips = m_layers;
    for (auto *layer : allClips)
        defaultTrack->removeClip(layer);
}

// ── Track management ──

QQmlListProperty<Track> Composition::tracks()
{
    return QQmlListProperty<Track>(this, &m_tracks);
}

Track* Composition::trackAt(int index) const
{
    if (index >= 0 && index < m_tracks.size())
        return m_tracks[index];
    return nullptr;
}

Track* Composition::addTrack(const QString &name)
{
    auto *track = new Track(this);
    if (!name.isEmpty())
        track->setName(name);
    else
        track->setName(QString("Track %1").arg(m_tracks.size() + 1));
    m_tracks.append(track);
    connectTrack(track);
    emit tracksChanged();
    return track;
}

void Composition::removeTrack(Track *track)
{
    if (!track || m_tracks.size() <= 1)
        return;
    if (m_tracks.removeOne(track)) {
        rebuildLayers();
        emit tracksChanged();
        track->deleteLater();
    }
}

int Composition::trackIndex(Track *track) const
{
    return m_tracks.indexOf(track);
}

void Composition::moveTrack(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_tracks.size())
        return;
    if (toIndex < 0 || toIndex >= m_tracks.size())
        return;
    if (fromIndex == toIndex)
        return;
    m_tracks.move(fromIndex, toIndex);
    rebuildLayers();
    emit tracksChanged();
}

void Composition::rebuildLayers()
{
    m_layers.clear();
    for (auto *track : m_tracks) {
        for (auto *clip : track->clipList()) {
            m_layers.append(clip);
        }
    }
    emit layersChanged();
}

Track* Composition::ensureDefaultTrack()
{
    if (m_tracks.isEmpty())
        return addTrack("Track 1");
    return m_tracks.first();
}

void Composition::connectTrack(Track *track)
{
    connect(track, &Track::clipsChanged, this, &Composition::rebuildLayers);
}
