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

void Keyframe::setHandleIn(const QPointF &h)
{
    if (m_handleIn != h) {
        m_handleIn = h;
        emit handleChanged();
    }
}

void Keyframe::setHandleOut(const QPointF &h)
{
    if (m_handleOut != h) {
        m_handleOut = h;
        emit handleChanged();
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
    case Bezier:
        // Placeholder for Cubic Bezier solver
        return t;
    }
    return t;
}
