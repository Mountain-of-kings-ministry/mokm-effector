#ifndef VST3INSTANCE_H
#define VST3INSTANCE_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <memory>

#include "pluginterfaces/vst/ivstcomponent.h"
#include "pluginterfaces/vst/ivstaudioprocessor.h"
#include "pluginterfaces/vst/ivsteditcontroller.h"
#include "public.sdk/source/vst/hosting/module.h"

namespace Steinberg { namespace Vst { class IComponent; class IAudioProcessor; class IEditController; }}

class VST3Instance : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)
    Q_PROPERTY(QVariantMap parameters READ parameters NOTIFY parametersChanged)

public:
    explicit VST3Instance(const QString &pluginPath, const QString &cid, QObject *parent = nullptr);
    ~VST3Instance() override;

    QString name() const { return m_name; }
    bool active() const { return m_active; }
    QVariantMap parameters() const { return m_parameters; }

    Q_INVOKABLE bool load();
    Q_INVOKABLE void unload();
    Q_INVOKABLE bool activate(double sampleRate, int maxFrames);
    Q_INVOKABLE void deactivate();
    Q_INVOKABLE void setParameter(const QString &paramId, double value);
    Q_INVOKABLE double getParameter(const QString &paramId) const;

    // Audio processing
    bool process(float **inputs, float **outputs, int nChannels, int nFrames);

signals:
    void nameChanged();
    void activeChanged();
    void parametersChanged();

private:
    QString m_pluginPath;
    QString m_cid;
    QString m_name;
    bool m_active = false;

    VST3::Hosting::Module::Ptr m_module;
    Steinberg::IPtr<Steinberg::Vst::IComponent> m_component;
    Steinberg::IPtr<Steinberg::Vst::IAudioProcessor> m_audioProcessor;
    Steinberg::IPtr<Steinberg::Vst::IEditController> m_editController;

    QVariantMap m_parameters;
};

#endif
