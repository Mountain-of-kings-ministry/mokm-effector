#include "Strip.h"
#include "Layer.h"
#include "Track.h"
#include "TimelineLayer.h"
#include <QJsonObject>

Strip::Strip(QObject *parent)
    : QObject(parent)
{
}

Strip::~Strip()
{
}

void Strip::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Strip::setStartFrame(int frame)
{
    frame = qMax(0, frame);
    if (m_startFrame != frame) {
        m_startFrame = frame;
        if (m_element)
            m_element->setStartFrame(frame);
        emit startFrameChanged();
    }
}

void Strip::setDuration(int frames)
{
    frames = qMax(1, frames);
    if (m_duration != frames) {
        m_duration = frames;
        if (m_element)
            m_element->setDuration(frames);
        emit durationChanged();
    }
}

void Strip::setElement(Layer *layer)
{
    if (m_element != layer) {
        m_element = layer;
        if (layer)
            layer->setParent(this);
        emit elementChanged();
    }
}

void Strip::setTrack(Track *track)
{
    m_track = track;
}

void Strip::setLinkGroupId(int id)
{
    if (m_linkGroupId != id) {
        m_linkGroupId = id;
        emit linkGroupIdChanged();
    }
}

void Strip::setTransitionIn(const QString &v)
{
    if (m_transitionIn != v) {
        m_transitionIn = v;
        emit transitionChanged();
    }
}

void Strip::setTransitionOut(const QString &v)
{
    if (m_transitionOut != v) {
        m_transitionOut = v;
        emit transitionChanged();
    }
}

void Strip::setTransitionInDuration(int v)
{
    v = qMax(0, v);
    if (m_transitionInDuration != v) {
        m_transitionInDuration = v;
        emit transitionChanged();
    }
}

void Strip::setTransitionOutDuration(int v)
{
    v = qMax(0, v);
    if (m_transitionOutDuration != v) {
        m_transitionOutDuration = v;
        emit transitionChanged();
    }
}

void Strip::moveToTrack(Track *newTrack)
{
    if (!newTrack || !m_track || newTrack == m_track)
        return;
    // Prevent moving across different TimelineLayers
    if (m_track->layer() != newTrack->layer())
        return;
    m_track->removeStrip(this);
    newTrack->addStrip(this);

    // Move linked strips too
    if (m_linkGroupId != 0) {
        auto strips = m_track->stripList();
        for (auto *s : strips) {
            if (s != this && s->linkGroupId() == m_linkGroupId) {
                s->moveToTrack(newTrack);
            }
        }
    }
}

void Strip::deleteStrip()
{
    if (m_track)
        m_track->removeStrip(this);
}

Strip* Strip::clone(QObject *parent) const
{
    auto *s = new Strip(parent);
    s->m_name = m_name;
    s->m_startFrame = m_startFrame;
    s->m_duration = m_duration;
    if (m_element)
        s->m_element = m_element->clone(s);
    return s;
}

QJsonObject Strip::toJson() const
{
    QJsonObject obj;
    obj["name"] = m_name;
    obj["startFrame"] = m_startFrame;
    obj["duration"] = m_duration;
    obj["transitionIn"] = m_transitionIn;
    obj["transitionOut"] = m_transitionOut;
    obj["transitionInDuration"] = m_transitionInDuration;
    obj["transitionOutDuration"] = m_transitionOutDuration;
    if (m_element)
        obj["element"] = m_element->toJson();
    return obj;
}

void Strip::fromJson(const QJsonObject &obj)
{
    setName(obj["name"].toString());
    setStartFrame(obj["startFrame"].toInt());
    setDuration(obj["duration"].toInt(90));
    setTransitionIn(obj["transitionIn"].toString("fade"));
    setTransitionOut(obj["transitionOut"].toString("fade"));
    setTransitionInDuration(obj["transitionInDuration"].toInt(0));
    setTransitionOutDuration(obj["transitionOutDuration"].toInt(0));
}
