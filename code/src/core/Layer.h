#ifndef LAYER_H
#define LAYER_H

#include <QObject>
#include <QString>
#include <QPointF>
#include <QJsonObject>

class Layer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(qreal opacity READ opacity WRITE setOpacity NOTIFY opacityChanged)
    Q_PROPERTY(bool visible READ visible WRITE setVisible NOTIFY visibleChanged)
    Q_PROPERTY(qreal x READ x WRITE setX NOTIFY transformChanged)
    Q_PROPERTY(qreal y READ y WRITE setY NOTIFY transformChanged)
    Q_PROPERTY(qreal rotation READ rotation WRITE setRotation NOTIFY transformChanged)
    Q_PROPERTY(qreal scaleX READ scaleX WRITE setScaleX NOTIFY transformChanged)
    Q_PROPERTY(qreal scaleY READ scaleY WRITE setScaleY NOTIFY transformChanged)
    Q_PROPERTY(int startFrame READ startFrame WRITE setStartFrame NOTIFY startFrameChanged)
    Q_PROPERTY(int duration READ duration WRITE setDuration NOTIFY durationChanged)
    Q_PROPERTY(qreal blurRadius READ blurRadius WRITE setBlurRadius NOTIFY blurChanged)
public:
    enum Type { ShapeLayer, TextLayer, NullLayer };
    Q_ENUM(Type)

    explicit Layer(Type type = NullLayer, QObject *parent = nullptr);
    ~Layer() override = default;

    Type type() const { return m_type; }

    QString name() const { return m_name; }
    void setName(const QString &name);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    qreal opacity() const { return m_opacity; }
    void setOpacity(qreal opacity);

    bool visible() const { return m_visible; }
    void setVisible(bool visible);

    qreal x() const { return m_x; }
    void setX(qreal x);
    qreal y() const { return m_y; }
    void setY(qreal y);
    qreal rotation() const { return m_rotation; }
    void setRotation(qreal rotation);
    qreal scaleX() const { return m_scaleX; }
    void setScaleX(qreal scaleX);
    qreal scaleY() const { return m_scaleY; }
    void setScaleY(qreal scaleY);

    int startFrame() const { return m_startFrame; }
    void setStartFrame(int frame);
    int duration() const { return m_duration; }
    void setDuration(int frames);

    qreal blurRadius() const { return m_blurRadius; }
    void setBlurRadius(qreal r);

    Q_INVOKABLE virtual Layer* clone(QObject *parent = nullptr) const;
    virtual QJsonObject toJson() const;
    virtual void fromJson(const QJsonObject &obj);
    Q_INVOKABLE QString serialize() const;
    Q_INVOKABLE void deserialize(const QString &json);

signals:
    void nameChanged();
    void enabledChanged();
    void opacityChanged();
    void visibleChanged();
    void transformChanged();
    void startFrameChanged();
    void durationChanged();
    void blurChanged();

private:
    Type m_type;
    QString m_name;
    bool m_enabled = true;
    qreal m_opacity = 1.0;
    bool m_visible = true;
    qreal m_x = 0;
    qreal m_y = 0;
    qreal m_rotation = 0;
    qreal m_scaleX = 1.0;
    qreal m_scaleY = 1.0;
    int m_startFrame = 0;
    int m_duration = 90;
    qreal m_blurRadius = 0;
};

#endif
