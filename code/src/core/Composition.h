#ifndef COMPOSITION_H
#define COMPOSITION_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>

class Layer;
class Track;

class Composition : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY resolutionChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY resolutionChanged)
    Q_PROPERTY(int duration READ duration WRITE setDuration NOTIFY durationChanged)
    Q_PROPERTY(qreal frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(QQmlListProperty<Layer> layers READ layers NOTIFY layersChanged)
    Q_PROPERTY(QQmlListProperty<Track> tracks READ tracks NOTIFY tracksChanged)
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
    int layerCount() const { return m_layers.size(); }
    Layer* layerAt(int index) const;
    int layerIndex(Layer *layer) const;

    Q_INVOKABLE void addLayer(Layer *layer);
    Q_INVOKABLE void removeLayer(Layer *layer);
    Q_INVOKABLE void moveLayer(int fromIndex, int toIndex);
    Q_INVOKABLE void clearLayers();

    QQmlListProperty<Track> tracks();
    Q_PROPERTY(int trackCount READ trackCount NOTIFY tracksChanged)
    int trackCount() const { return m_tracks.size(); }
    Q_INVOKABLE Track* trackAt(int index) const;
    Q_INVOKABLE Track* addTrack(const QString &name = QString());
    Q_INVOKABLE void removeTrack(Track *track);
    Q_INVOKABLE int trackIndex(Track *track) const;
    Q_INVOKABLE void moveTrack(int fromIndex, int toIndex);

signals:
    void nameChanged();
    void resolutionChanged();
    void durationChanged();
    void frameRateChanged();
    void layersChanged();
    void tracksChanged();

public slots:
    void rebuildLayers();

private:
    Track* ensureDefaultTrack();
    void connectTrack(Track *track);

    QString m_name = "New Composition";
    int m_width = 1920;
    int m_height = 1080;
    int m_duration = 150;
    qreal m_frameRate = 30.0;
    QVector<Layer*> m_layers;
    QVector<Track*> m_tracks;
};

#endif
