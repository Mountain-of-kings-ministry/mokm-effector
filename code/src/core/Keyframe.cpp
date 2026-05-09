#include "Keyframe.h"
#include <QtMath>

Keyframe::Keyframe(QObject *parent)
    : QObject(parent)
{
}

void Keyframe::setFrame(int frame)
{
    if (m_frame != frame) {
        m_frame = frame;
        emit frameChanged();
    }
}

void Keyframe::setValue(const QVariant &value)
{
    m_value = value;
    emit valueChanged();
}

void Keyframe::setEasing(Easing easing)
{
    if (m_easing != easing) {
        m_easing = easing;
        emit easingChanged();
    }
}

qreal Keyframe::interpolate(qreal t, Easing easing)
{
    t = qBound(0.0, t, 1.0);
    switch (easing) {
    case Linear:
        return t;
    case EaseIn:
        return t * t;
    case EaseOut:
        return 1.0 - (1.0 - t) * (1.0 - t);
    case EaseInOut:
        return t < 0.5 ? 2.0 * t * t : 1.0 - qPow(-2.0 * t + 2.0, 2.0) / 2.0;
    }
    return t;
}
