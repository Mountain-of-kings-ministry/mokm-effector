#ifndef EFFECTINSTANCE_H
#define EFFECTINSTANCE_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QJsonObject>
#include <QEvent>

class CLAPInstance;
class VST3Instance;

class EffectInstance : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString pluginId READ pluginId CONSTANT)
    Q_PROPERTY(QString format READ format CONSTANT)
    Q_PROPERTY(bool bypassed READ bypassed WRITE setBypassed NOTIFY bypassedChanged)
    Q_PROPERTY(QVariantMap parameters READ parameters NOTIFY parametersChanged)
public:
    explicit EffectInstance(const QString &name,
                            const QString &pluginId,
                            const QString &format,
                            QObject *parent = nullptr);
    ~EffectInstance() override;

    QString name() const { return m_name; }
    QString pluginId() const { return m_pluginId; }
    QString format() const { return m_format; }
    bool bypassed() const { return m_bypassed; }
    void setBypassed(bool v);

    QVariantMap parameters() const { return m_parameters; }

    Q_INVOKABLE void setParameter(const QString &paramId, double value);
    Q_INVOKABLE double getParameter(const QString &paramId) const;

    void setClapInstance(CLAPInstance *instance);
    CLAPInstance* clapInstance() const { return m_clapInstance; }

    void setVst3Instance(VST3Instance *instance);
    VST3Instance* vst3Instance() const { return m_vst3Instance; }

    void setParameterMeta(const QString &paramId, const QString &label,
                          double min, double max, double defaultValue);
    struct ParamInfo {
        QString label;
        double min = 0.0;
        double max = 1.0;
        double defaultValue = 0.0;
    };
    const ParamInfo* parameterInfo(const QString &paramId) const;

    QJsonObject toJson() const;
    void fromJson(const QJsonObject &obj);

protected:
    bool event(QEvent *e) override;

signals:
    void nameChanged();
    void bypassedChanged();
    void parametersChanged();

private:
    QString m_name;
    QString m_pluginId;
    QString m_format;
    bool m_bypassed = false;
    QVariantMap m_parameters;
    QMap<QString, ParamInfo> m_paramInfo;
    CLAPInstance *m_clapInstance = nullptr;
    VST3Instance *m_vst3Instance = nullptr;
};

#endif
