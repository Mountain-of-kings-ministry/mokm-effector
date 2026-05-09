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
public:
    enum Easing { Linear, EaseIn, EaseOut, EaseInOut };
    Q_ENUM(Easing)

    explicit Keyframe(QObject *parent = nullptr);
    ~Keyframe() override = default;

    int frame() const { return m_frame; }
    void setFrame(int frame);

    QVariant value() const { return m_value; }
    void setValue(const QVariant &value);

    Easing easing() const { return m_easing; }
    void setEasing(Easing easing);

    static qreal interpolate(qreal t, Easing easing);

signals:
    void frameChanged();
    void valueChanged();
    void easingChanged();

private:
    int m_frame = 0;
    QVariant m_value = 0.0;
    Easing m_easing = Linear;
};

#endif
