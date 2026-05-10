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

void TimelineModel::setAutoKeyframeEnabled(bool enabled)
{
    if (m_autoKeyframeEnabled != enabled) {
        m_autoKeyframeEnabled = enabled;
        emit autoKeyframeEnabledChanged();
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

void TimelineModel::addKeyframe(QObject *obj, const QString &property, int frame, const QVariant &value)
{
    if (!obj) return;

    auto &layerKeyframes = m_keyframes[obj];
    auto &propKeyframes = layerKeyframes[property];

    if (propKeyframes.contains(frame)) {
        propKeyframes[frame]->setValue(value);
        qDebug() << "Updated keyframe:" << property << "at frame" << frame << "val:" << value;
    } else {
        auto *kf = new Keyframe(this);
        kf->setFrame(frame);
        kf->setValue(value);
        propKeyframes[frame] = kf;
        qDebug() << "Added keyframe:" << property << "at frame" << frame << "val:" << value;
    }
    m_keyframesStamp++;
    emit keyframesChanged();
}

void TimelineModel::removeKeyframe(QObject *obj, const QString &property, int frame)
{
    if (!obj) return;

    auto layerIt = m_keyframes.find(obj);
    if (layerIt == m_keyframes.end()) return;

    auto propIt = layerIt.value().find(property);
    if (propIt == layerIt.value().end()) return;

    auto kfIt = propIt.value().find(frame);
    if (kfIt != propIt.value().end()) {
        kfIt.value()->deleteLater();
        propIt.value().erase(kfIt);

        if (propIt.value().isEmpty()) {
            layerIt.value().erase(propIt);
            if (layerIt.value().isEmpty())
                m_keyframes.erase(layerIt);
        }

        m_keyframesStamp++;
        emit keyframesChanged();
        qDebug() << "Removed keyframe:" << property << "at frame" << frame;
    }
}

void TimelineModel::setKeyframeEasing(QObject *obj, const QString &property, int frame, int easing)
{
    if (!obj) return;
    auto layerIt = m_keyframes.find(obj);
    if (layerIt == m_keyframes.end()) return;
    auto propIt = layerIt.value().find(property);
    if (propIt == layerIt.value().end()) return;
    auto kfIt = propIt.value().find(frame);
    if (kfIt != propIt.value().end()) {
        kfIt.value()->setEasing(static_cast<Keyframe::Easing>(qBound(0, easing, 3)));
        m_keyframesStamp++;
        emit keyframesChanged();
        qDebug() << "Set easing:" << property << "at frame" << frame << "easing:" << easing;
    }
}

QVariant TimelineModel::getValueAt(QObject *obj, const QString &property, int frame) const
{
    if (!obj) return QVariant();

    auto layerIt = m_keyframes.find(obj);
    if (layerIt == m_keyframes.end()) return QVariant();

    auto propIt = layerIt.value().find(property);
    if (propIt == layerIt.value().end()) return QVariant();

    const auto &propKF = propIt.value();
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
    if (it == propKF.end()) {
        auto last = propKF.end();
        --last;
        return last.value()->value();
    }

    // Between two keyframes — interpolate
    auto next = it;
    auto prev = it;
    --prev;
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

bool TimelineModel::hasKeyframe(QObject *obj, const QString &property, int frame) const
{
    if (!obj) return false;
    auto layerIt = m_keyframes.find(obj);
    if (layerIt == m_keyframes.end()) return false;
    auto propIt = layerIt.value().find(property);
    if (propIt == layerIt.value().end()) return false;
    return propIt.value().contains(frame);
}

QVector<int> TimelineModel::keyframeFrames(QObject *obj, const QString &property) const
{
    QVector<int> frames;
    if (!obj) return frames;
    auto layerIt = m_keyframes.find(obj);
    if (layerIt == m_keyframes.end()) return frames;
    auto propIt = layerIt.value().find(property);
    if (propIt == layerIt.value().end()) return frames;

    for (auto it = propIt.value().begin(); it != propIt.value().end(); ++it)
        frames.append(it.key());
        
    std::sort(frames.begin(), frames.end());
    return frames;
}

QVariantList TimelineModel::getKeyframeData(QObject *obj, const QString &property) const
{
    QVariantList result;
    if (!obj) return result;
    auto objIt = m_keyframes.find(obj);
    if (objIt == m_keyframes.end()) return result;
    auto propIt = objIt.value().find(property);
    if (propIt == objIt.value().end()) return result;
    for (auto it = propIt.value().begin(); it != propIt.value().end(); ++it) {
        QVariantMap entry;
        entry["frame"] = it.key();
        entry["value"] = it.value()->value().toReal();
        entry["easing"] = static_cast<int>(it.value()->easing());
        result.append(entry);
    }
    return result;
}

void TimelineModel::applyKeyframes()
{
    for (auto lit = m_keyframes.begin(); lit != m_keyframes.end(); ++lit) {
        QObject *obj = lit.key();
        if (!obj) continue;
        const auto &props = lit.value();
        for (auto pit = props.begin(); pit != props.end(); ++pit) {
            const QString &prop = pit.key();
            QVariant val = getValueAt(obj, prop, m_currentFrame);
            if (val.isValid())
                obj->setProperty(prop.toUtf8().constData(), val);
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
