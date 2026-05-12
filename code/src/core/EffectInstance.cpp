#include "EffectInstance.h"
#include "CLAPInstance.h"

#include <QJsonArray>
#include <QJsonObject>

EffectInstance::EffectInstance(const QString &name,
                               const QString &pluginId,
                               const QString &format,
                               QObject *parent)
    : QObject(parent)
    , m_name(name)
    , m_pluginId(pluginId)
    , m_format(format)
{
}

EffectInstance::~EffectInstance()
{
}

void EffectInstance::setBypassed(bool v)
{
    if (m_bypassed == v) return;
    m_bypassed = v;
    emit bypassedChanged();
}

void EffectInstance::setParameter(const QString &paramId, double value)
{
    auto it = m_paramInfo.find(paramId);
    if (it != m_paramInfo.end())
        value = qBound(it->min, value, it->max);

    QVariant prev = m_parameters.value(paramId);
    if (qFuzzyCompare(prev.toDouble(), value))
        return;

    m_parameters[paramId] = value;

    if (m_clapInstance)
        m_clapInstance->setParameter(paramId, value);

    emit parametersChanged();
}

double EffectInstance::getParameter(const QString &paramId) const
{
    return m_parameters.value(paramId, 0.0).toDouble();
}

void EffectInstance::setClapInstance(CLAPInstance *instance)
{
    m_clapInstance = instance;
    if (!instance) return;

    // Sync parameters from CLAP
    QVariantMap clapParams = instance->parameters();
    for (auto it = clapParams.begin(); it != clapParams.end(); ++it) {
        m_parameters[it.key()] = it.value();
    }

    connect(instance, &CLAPInstance::parametersChanged, this, [this]() {
        if (!m_clapInstance) return;
        QVariantMap clapParams = m_clapInstance->parameters();
        for (auto it = clapParams.begin(); it != clapParams.end(); ++it) {
            if (m_parameters.value(it.key()) != it.value()) {
                m_parameters[it.key()] = it.value();
            }
        }
        emit parametersChanged();
    });
}

void EffectInstance::setParameterMeta(const QString &paramId, const QString &label,
                                      double min, double max, double defaultValue)
{
    ParamInfo info;
    info.label = label;
    info.min = min;
    info.max = max;
    info.defaultValue = defaultValue;
    m_paramInfo[paramId] = info;

    if (!m_parameters.contains(paramId))
        m_parameters[paramId] = defaultValue;
}

const EffectInstance::ParamInfo* EffectInstance::parameterInfo(const QString &paramId) const
{
    auto it = m_paramInfo.find(paramId);
    if (it != m_paramInfo.end())
        return &it.value();
    return nullptr;
}

QJsonObject EffectInstance::toJson() const
{
    QJsonObject obj;
    obj["name"] = m_name;
    obj["pluginId"] = m_pluginId;
    obj["format"] = m_format;
    obj["bypassed"] = m_bypassed;

    QJsonObject params;
    for (auto it = m_parameters.begin(); it != m_parameters.end(); ++it)
        params[it.key()] = it.value().toDouble();
    obj["parameters"] = params;

    return obj;
}

void EffectInstance::fromJson(const QJsonObject &obj)
{
    m_name = obj["name"].toString();
    m_pluginId = obj["pluginId"].toString();
    m_format = obj["format"].toString();
    m_bypassed = obj["bypassed"].toBool();

    QJsonObject params = obj["parameters"].toObject();
    for (auto it = params.begin(); it != params.end(); ++it)
        m_parameters[it.key()] = it.value().toDouble();
}
