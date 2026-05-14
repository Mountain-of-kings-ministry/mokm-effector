#ifndef KEYFRAME_H
#define KEYFRAME_H

#include <QObject>
#include <QVariant>
#include <QString>

class Keyframe : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int frame READ frame WRITE setFrame NOTIFY frameChanged)
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)
    Q_PROPERTY(Easing easing READ easing WRITE setEasing NOTIFY easingChanged)
    Q_PROPERTY(QPointF handleIn READ handleIn WRITE setHandleIn NOTIFY handleChanged)
    Q_PROPERTY(QPointF handleOut READ handleOut WRITE setHandleOut NOTIFY handleChanged)
public:
    enum Easing { Linear, EaseIn, EaseOut, EaseInOut, Bezier };
    Q_ENUM(Easing)

    explicit Keyframe(QObject *parent = nullptr);
    ~Keyframe() override = default;

    int frame() const { return m_frame; }
    void setFrame(int frame);

    QVariant value() const { return m_value; }
    void setValue(const QVariant &value);

    Easing easing() const { return m_easing; }
    void setEasing(Easing easing);

    QPointF handleIn() const { return m_handleIn; }
    void setHandleIn(const QPointF &h);
    QPointF handleOut() const { return m_handleOut; }
    void setHandleOut(const QPointF &h);

    static qreal interpolate(qreal t, Easing easing);

signals:
    void frameChanged();
    void valueChanged();
    void easingChanged();
    void handleChanged();

private:
    int m_frame = 0;
    QVariant m_value = 0.0;
    Easing m_easing = Linear;
    QPointF m_handleIn {-0.1, 0.0};
    QPointF m_handleOut {0.1, 0.0};
};

#endif
