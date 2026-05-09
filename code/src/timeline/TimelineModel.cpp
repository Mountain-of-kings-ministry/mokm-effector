#include "TimelineModel.h"
#include "../core/Composition.h"
#include "../core/Layer.h"
#include "../core/Keyframe.h"

#include <algorithm>

TimelineModel::TimelineModel(QObject *parent)
    : QObject(parent)
{
    m_timer = new QTimer(this);
    m_timer->setTimerType(Qt::PreciseTimer);
    connect(m_timer, &QTimer::timeout, this, &TimelineModel::onTick);
}

TimelineModel::~TimelineModel() = default;

void TimelineModel::setComposition(Composition *comp)
{
    if (m_composition != comp) {
        if (m_composition)
            disconnect(m_composition, nullptr, this, nullptr);
        m_composition = comp;
        if (comp) {
            connect(comp, &QObject::destroyed, this, [this]{ setComposition(nullptr); });
        }
        m_currentFrame = 0;
        m_keyframes.clear();
        m_keyframesStamp++;
        emit compositionChanged();
        emit currentFrameChanged();
        emit keyframesChanged();
    }
}

void TimelineModel::setCurrentFrame(int frame)
{
    frame = qMax(0, frame);
    if (m_composition)
        frame = qMin(frame, m_composition->duration() - 1);
    if (m_currentFrame != frame) {
        m_currentFrame = frame;
        applyKeyframes();
        emit currentFrameChanged();
    }
}

void TimelineModel::setPlaying(bool playing)
{
    if (m_playing != playing) {
        m_playing = playing;
        if (playing)
            m_timer->start(1000 / 60);
        else
            m_timer->stop();
        emit playingChanged();
    }
}

void TimelineModel::setPlaybackSpeed(qreal speed)
{
    speed = qMax(0.1, speed);
    if (!qFuzzyCompare(m_playbackSpeed, speed)) {
        m_playbackSpeed = speed;
        emit playbackSpeedChanged();
    }
}

void TimelineModel::play()
{
    if (!m_composition) return;
    setPlaying(true);
}

void TimelineModel::pause()
{
    setPlaying(false);
}

void TimelineModel::stop()
{
    setPlaying(false);
    setCurrentFrame(0);
}

void TimelineModel::goToFrame(int frame)
{
    setCurrentFrame(frame);
}

void TimelineModel::goToStart()
{
    setCurrentFrame(0);
}

void TimelineModel::goToEnd()
{
    if (m_composition)
        setCurrentFrame(m_composition->duration() - 1);
}

void TimelineModel::stepForward()
{
    setCurrentFrame(m_currentFrame + 1);
}

void TimelineModel::stepBackward()
{
    setCurrentFrame(m_currentFrame - 1);
}

void TimelineModel::addKeyframe(Layer *layer, const QString &property, int frame, const QVariant &value)
{
    if (!layer) return;

    auto &layerKeyframes = m_keyframes[layer];
    auto &propKeyframes = layerKeyframes[property];

    if (propKeyframes.contains(frame)) {
        propKeyframes[frame]->setValue(value);
    } else {
        auto *kf = new Keyframe(this);
        kf->setFrame(frame);
        kf->setValue(value);
        propKeyframes[frame] = kf;
    }
    m_keyframesStamp++;
    emit keyframesChanged();
}

void TimelineModel::removeKeyframe(Layer *layer, const QString &property, int frame)
{
    if (!layer) return;

    if (m_keyframes.contains(layer) &&
        m_keyframes[layer].contains(property) &&
        m_keyframes[layer][property].contains(frame)) {
        m_keyframes[layer][property][frame]->deleteLater();
        m_keyframes[layer][property].remove(frame);
        if (m_keyframes[layer][property].isEmpty())
            m_keyframes[layer].remove(property);
        m_keyframesStamp++;
        emit keyframesChanged();
    }
}

QVariant TimelineModel::getValueAt(Layer *layer, const QString &property, int frame) const
{
    if (!layer || !m_keyframes.contains(layer) || !m_keyframes[layer].contains(property))
        return QVariant();

    const auto &propKF = m_keyframes[layer][property];
    if (propKF.isEmpty())
        return QVariant();

    auto it = propKF.lowerBound(frame);

    // Exact hit
    if (it != propKF.end() && it.key() == frame)
        return it.value()->value();

    // Before first keyframe
    if (it == propKF.begin())
        return it.value()->value();

    // After last keyframe
    if (it == propKF.end())
        return (--it).value()->value();

    // Between two keyframes — interpolate
    auto next = it;
    auto prev = --it;
    int prevFrame = prev.key();
    int nextFrame = next.key();
    qreal t = qreal(frame - prevFrame) / qreal(nextFrame - prevFrame);
    auto easing = prev.value()->easing();
    qreal easedT = Keyframe::interpolate(t, easing);

    return interpolateValue(prev.value()->value().toReal(),
                            next.value()->value().toReal(),
                            easedT,
                            easing);
}

bool TimelineModel::hasKeyframe(Layer *layer, const QString &property, int frame) const
{
    return m_keyframes.contains(layer) &&
           m_keyframes[layer].contains(property) &&
           m_keyframes[layer][property].contains(frame);
}

QVector<int> TimelineModel::keyframeFrames(Layer *layer, const QString &property) const
{
    QVector<int> frames;
    if (m_keyframes.contains(layer) && m_keyframes[layer].contains(property)) {
        for (auto it = m_keyframes[layer][property].begin(); it != m_keyframes[layer][property].end(); ++it)
            frames.append(it.key());
    }
    std::sort(frames.begin(), frames.end());
    return frames;
}

void TimelineModel::applyKeyframes()
{
    for (auto lit = m_keyframes.begin(); lit != m_keyframes.end(); ++lit) {
        Layer *layer = lit.key();
        if (!layer) continue;
        const auto &props = lit.value();
        for (auto pit = props.begin(); pit != props.end(); ++pit) {
            const QString &prop = pit.key();
            QVariant val = getValueAt(layer, prop, m_currentFrame);
            if (val.isValid())
                layer->setProperty(prop.toUtf8().constData(), val);
        }
    }
}

void TimelineModel::onTick()
{
    if (!m_playing || !m_composition) {
        setPlaying(false);
        return;
    }

    int nextFrame = m_currentFrame + 1;
    int duration = m_composition->duration();

    if (nextFrame >= duration)
        nextFrame = 0;

    setCurrentFrame(nextFrame);
}

qreal TimelineModel::interpolateValue(qreal from, qreal to, qreal t, Keyframe::Easing easing) const
{
    Q_UNUSED(easing);
    return from + (to - from) * t;
}
