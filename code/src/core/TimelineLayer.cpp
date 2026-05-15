#include "TimelineLayer.h"
#include "Track.h"
#include "Composition.h"

TimelineLayer::TimelineLayer(QObject *parent)
    : QObject(parent)
{
}

TimelineLayer::~TimelineLayer()
{
    qDeleteAll(m_tracks);
    m_tracks.clear();
}

void TimelineLayer::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

QQmlListProperty<Track> TimelineLayer::tracks()
{
    return QQmlListProperty<Track>(this, &m_tracks);
}

Track* TimelineLayer::trackAt(int index) const
{
    if (index >= 0 && index < m_tracks.size())
        return m_tracks[index];
    return nullptr;
}

Track* TimelineLayer::addTrack(const QString &name)
{
    auto *track = new Track(this);
    if (!name.isEmpty())
        track->setName(name);
    else
        track->setName(QString("Track %1").arg(m_tracks.size() + 1));
    track->setLayer(this);
    m_tracks.append(track);
    if (m_composition)
        connect(track, &Track::stripsChanged, m_composition, &Composition::rebuildFlatLayers);
    emit tracksChanged();
    return track;
}

void TimelineLayer::addTrack(Track *track)
{
    if (!track || m_tracks.contains(track))
        return;
    track->setParent(this);
    track->setLayer(this);
    if (!track->name().isEmpty() && track->name() == "Track 1") {
        track->setName(QString("Track %1").arg(m_tracks.size() + 1));
    }
    m_tracks.append(track);
    if (m_composition)
        connect(track, &Track::stripsChanged, m_composition, &Composition::rebuildFlatLayers);
    emit tracksChanged();
}

Track* TimelineLayer::insertTrack(int index, int trackType)
{
    auto *track = new Track(this);
    track->setTrackType(trackType);
    track->setLayer(this);
    
    if (index < 0) index = 0;
    if (index > m_tracks.size()) index = m_tracks.size();
    
    m_tracks.insert(index, track);
    
    if (m_composition)
        connect(track, &Track::stripsChanged, m_composition, &Composition::rebuildFlatLayers);
        
    emit tracksChanged();
    return track;
}

void TimelineLayer::removeTrack(Track *track)
{
    if (!track || m_tracks.size() <= 1)
        return;
    if (m_tracks.removeOne(track)) {
        emit tracksChanged();
        track->deleteLater();
    }
}

int TimelineLayer::trackIndex(Track *track) const
{
    return m_tracks.indexOf(track);
}

void TimelineLayer::moveTrack(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_tracks.size())
        return;
    if (toIndex < 0 || toIndex >= m_tracks.size())
        return;
    if (fromIndex == toIndex)
        return;
    m_tracks.move(fromIndex, toIndex);
    emit tracksChanged();
}

void TimelineLayer::deleteLayer()
{
    if (m_composition)
        m_composition->removeLayer(this);
}

// ── Layer properties ──

void TimelineLayer::setOpacity(qreal v)
{
    v = qBound(0.0, v, 1.0);
    if (!qFuzzyCompare(m_opacity, v)) {
        m_opacity = v;
        emit opacityChanged();
    }
}

void TimelineLayer::setVisible(bool v)
{
    if (m_visible != v) {
        m_visible = v;
        emit visibleChanged();
    }
}

void TimelineLayer::setLocked(bool v)
{
    if (m_locked != v) {
        m_locked = v;
        emit lockedChanged();
    }
}

void TimelineLayer::setEnabled(bool v)
{
    if (m_enabled != v) {
        m_enabled = v;
        emit enabledChanged();
    }
}

void TimelineLayer::setMute(bool v)
{
    if (m_mute != v) {
        m_mute = v;
        emit muteChanged();
    }
}

void TimelineLayer::setSolo(bool v)
{
    if (m_solo != v) {
        m_solo = v;
        emit soloChanged();
    }
}

void TimelineLayer::setOffsetX(qreal v)
{
    if (!qFuzzyCompare(m_offsetX, v)) {
        m_offsetX = v;
        emit offsetXChanged();
    }
}

void TimelineLayer::setOffsetY(qreal v)
{
    if (!qFuzzyCompare(m_offsetY, v)) {
        m_offsetY = v;
        emit offsetYChanged();
    }
}

void TimelineLayer::setRotation(qreal v)
{
    if (!qFuzzyCompare(m_rotation, v)) {
        m_rotation = v;
        emit rotationChanged();
    }
}

void TimelineLayer::setScaleX(qreal v)
{
    if (!qFuzzyCompare(m_scaleX, v)) {
        m_scaleX = v;
        emit scaleXChanged();
    }
}

void TimelineLayer::setScaleY(qreal v)
{
    if (!qFuzzyCompare(m_scaleY, v)) {
        m_scaleY = v;
        emit scaleYChanged();
    }
}

void TimelineLayer::setAnchorX(qreal v)
{
    if (!qFuzzyCompare(m_anchorX, v)) {
        m_anchorX = v;
        emit anchorXChanged();
    }
}

void TimelineLayer::setAnchorY(qreal v)
{
    if (!qFuzzyCompare(m_anchorY, v)) {
        m_anchorY = v;
        emit anchorYChanged();
    }
}

void TimelineLayer::setComposition(Composition *comp)
{
    if (m_composition != comp) {
        m_composition = comp;
        emit compositionChanged();
    }
}
