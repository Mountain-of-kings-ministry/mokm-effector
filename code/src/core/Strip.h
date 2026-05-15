#ifndef STRIP_H
#define STRIP_H

#include <QObject>
#include <QString>

#include "Track.h"

class Layer;
class TimelineLayer;

class Strip : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int startFrame READ startFrame WRITE setStartFrame NOTIFY startFrameChanged)
    Q_PROPERTY(int duration READ duration WRITE setDuration NOTIFY durationChanged)
    Q_PROPERTY(Layer* element READ element WRITE setElement NOTIFY elementChanged)
    Q_PROPERTY(Track* track READ track CONSTANT)
    Q_PROPERTY(int linkGroupId READ linkGroupId WRITE setLinkGroupId NOTIFY linkGroupIdChanged)
    Q_PROPERTY(QString transitionIn READ transitionIn WRITE setTransitionIn NOTIFY transitionChanged)
    Q_PROPERTY(QString transitionOut READ transitionOut WRITE setTransitionOut NOTIFY transitionChanged)
    Q_PROPERTY(int transitionInDuration READ transitionInDuration WRITE setTransitionInDuration NOTIFY transitionChanged)
    Q_PROPERTY(int transitionOutDuration READ transitionOutDuration WRITE setTransitionOutDuration NOTIFY transitionChanged)
public:
    explicit Strip(QObject *parent = nullptr);
    ~Strip() override;

    QString name() const { return m_name; }
    void setName(const QString &name);

    int startFrame() const { return m_startFrame; }
    void setStartFrame(int frame);
    int duration() const { return m_duration; }
    void setDuration(int frames);

    Layer* element() const { return m_element; }
    void setElement(Layer *layer);

    Track* track() const { return m_track; }
    void setTrack(Track *track);

    int linkGroupId() const { return m_linkGroupId; }
    void setLinkGroupId(int id);

    QString transitionIn() const { return m_transitionIn; }
    void setTransitionIn(const QString &v);
    QString transitionOut() const { return m_transitionOut; }
    void setTransitionOut(const QString &v);
    int transitionInDuration() const { return m_transitionInDuration; }
    void setTransitionInDuration(int v);
    int transitionOutDuration() const { return m_transitionOutDuration; }
    void setTransitionOutDuration(int v);

    Q_INVOKABLE virtual void moveToTrack(Track *newTrack);
    Q_INVOKABLE virtual void deleteStrip();
    Q_INVOKABLE virtual Strip* clone(QObject *parent = nullptr) const;

    QJsonObject toJson() const;
    void fromJson(const QJsonObject &obj);

signals:
    void nameChanged();
    void startFrameChanged();
    void durationChanged();
    void elementChanged();
    void linkGroupIdChanged();
    void transitionChanged();

private:
    QString m_name = "Strip";
    int m_startFrame = 0;
    int m_duration = 90;
    Layer *m_element = nullptr;
    Track *m_track = nullptr;
    int m_linkGroupId = 0;

    QString m_transitionIn = "fade";
    QString m_transitionOut = "fade";
    int m_transitionInDuration = 0;
    int m_transitionOutDuration = 0;
};

#endif
