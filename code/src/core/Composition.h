#ifndef COMPOSITION_H
#define COMPOSITION_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>

class Layer;
class Track;
class TimelineLayer;
class Strip;

class Composition : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY resolutionChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY resolutionChanged)
    Q_PROPERTY(int duration READ duration WRITE setDuration NOTIFY durationChanged)
    Q_PROPERTY(qreal frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(QQmlListProperty<TimelineLayer> layers READ layers NOTIFY layersChanged)
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

    // TimelineLayer management
    QQmlListProperty<TimelineLayer> layers();
    Q_INVOKABLE int layerCount() const { return m_timelineLayers.size(); }
    Q_INVOKABLE TimelineLayer* layerAt(int index) const;
    Q_INVOKABLE void addLayer(TimelineLayer *layer);
    Q_INVOKABLE void removeLayer(TimelineLayer *layer);
    Q_INVOKABLE int layerIndex(TimelineLayer *layer) const;
    Q_INVOKABLE void moveLayer(int fromIndex, int toIndex);
    Q_INVOKABLE void clearLayers();
    Q_INVOKABLE TimelineLayer* ensureDefaultLayer();

    // Returns the last frame that has any content across all layers
    Q_INVOKABLE int lastClipEndFrame() const;

    // Flat visual layer list (computed from all strips' elements — for viewport/export)
    Q_PROPERTY(int flatLayerCount READ flatLayerCount NOTIFY layersChanged)
    int flatLayerCount() const { return m_flatLayers.size(); }
    Q_INVOKABLE Layer* flatLayerAt(int index) const;

signals:
    void nameChanged();
    void resolutionChanged();
    void durationChanged();
    void frameRateChanged();
    void layersChanged();

public slots:
    void rebuildFlatLayers();

private:
    QString m_name = "New Composition";
    int m_width = 1920;
    int m_height = 1080;
    int m_duration = 150;
    qreal m_frameRate = 30.0;
    QVector<TimelineLayer*> m_timelineLayers;
    QVector<Layer*> m_flatLayers;
};

#endif
