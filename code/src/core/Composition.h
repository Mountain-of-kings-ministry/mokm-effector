#ifndef COMPOSITION_H
#define COMPOSITION_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>

class Layer;

class Composition : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY resolutionChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY resolutionChanged)
    Q_PROPERTY(int duration READ duration WRITE setDuration NOTIFY durationChanged)
    Q_PROPERTY(qreal frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(QQmlListProperty<Layer> layers READ layers NOTIFY layersChanged)
public:
    explicit Composition(QObject *parent = nullptr);
    ~Composition() override;

    QString name() const { return m_name; }
    void setName(const QString &name);

    int width() const { return m_width; }
    void setWidth(int w);
    int height() const { return m_height; }
    void setHeight(int h);

    int duration() const { return m_duration; }
    void setDuration(int frames);
    qreal frameRate() const { return m_frameRate; }
    void setFrameRate(qreal fps);

    QQmlListProperty<Layer> layers();
    QVector<Layer*> layerList() const { return m_layers; }
    int layerCount() const { return m_layers.size(); }
    Layer* layerAt(int index) const;
    Q_INVOKABLE void addLayer(Layer *layer);
    Q_INVOKABLE void removeLayer(Layer *layer);
    Q_INVOKABLE void moveLayer(int fromIndex, int toIndex);
    void clearLayers();

signals:
    void nameChanged();
    void resolutionChanged();
    void durationChanged();
    void frameRateChanged();
    void layersChanged();

private:
    QString m_name = "New Composition";
    int m_width = 1920;
    int m_height = 1080;
    int m_duration = 150;
    qreal m_frameRate = 30.0;
    QVector<Layer*> m_layers;
};

#endif
