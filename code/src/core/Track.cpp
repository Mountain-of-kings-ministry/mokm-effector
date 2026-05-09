#include "Track.h"
#include "Layer.h"

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

void Track::setLocked(bool locked)
{
    if (m_locked != locked) {
        m_locked = locked;
        emit lockedChanged();
    }
}

QQmlListProperty<Layer> Track::clips()
{
    return QQmlListProperty<Layer>(this, &m_clips);
}

Layer* Track::clipAt(int index) const
{
    if (index >= 0 && index < m_clips.size())
        return m_clips[index];
    return nullptr;
}

void Track::addClip(Layer *layer)
{
    if (!layer || m_clips.contains(layer))
        return;
    layer->setParent(this);
    m_clips.append(layer);
    emit clipsChanged();
}

void Track::removeClip(Layer *layer)
{
    if (m_clips.removeOne(layer)) {
        emit clipsChanged();
    }
}

Layer* Track::removeClipAt(int index)
{
    if (index < 0 || index >= m_clips.size())
        return nullptr;
    auto *layer = m_clips.takeAt(index);
    emit clipsChanged();
    return layer;
}

void Track::moveClip(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_clips.size())
        return;
    if (toIndex < 0 || toIndex >= m_clips.size())
        return;
    if (fromIndex == toIndex)
        return;
    m_clips.move(fromIndex, toIndex);
    emit clipsChanged();
}

int Track::indexOf(Layer *layer) const
{
    return m_clips.indexOf(layer);
}
