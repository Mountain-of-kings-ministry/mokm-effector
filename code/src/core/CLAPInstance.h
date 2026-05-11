#ifndef CLAPINSTANCE_H
#define CLAPINSTANCE_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QVariantMap>
#include <QByteArray>

class CLAPInstance : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString pluginId READ pluginId CONSTANT)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(QVariantMap parameters READ parameters NOTIFY parametersChanged)

public:
    explicit CLAPInstance(const QString &pluginId,
                          const QString &pluginPath,
                          QObject *parent = nullptr);
    ~CLAPInstance() override;

    QString pluginId() const { return m_pluginId; }
    QString name() const { return m_name; }
    bool active() const { return m_active; }
    QVariantMap parameters() const { return m_parameters; }

    Q_INVOKABLE bool load();
    Q_INVOKABLE void unload();
    Q_INVOKABLE bool activate(double sampleRate, int minFrames, int maxFrames);
    Q_INVOKABLE void deactivate();
    Q_INVOKABLE void setParameter(const QString &paramId, double value);
    Q_INVOKABLE double getParameter(const QString &paramId) const;

    bool process(float *const *audioInputs, float **audioOutputs,
                 uint32_t nChannels, uint32_t nFrames);

signals:
    void nameChanged();
    void activeChanged();
    void parametersChanged();

private:
    QString m_pluginId;
    QString m_pluginPath;
    QString m_name;
    bool m_active = false;

    void *m_libHandle = nullptr;
    void *m_plugin = nullptr;
    QVariantMap m_parameters;
};

#endif
