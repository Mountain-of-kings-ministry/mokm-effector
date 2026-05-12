#include "EffectChain.h"
#include "EffectInstance.h"

EffectChain::EffectChain(QObject *parent)
    : QObject(parent)
{
}

EffectChain::~EffectChain()
{
    qDeleteAll(m_effects);
    m_effects.clear();
}

QQmlListProperty<EffectInstance> EffectChain::effects()
{
    return QQmlListProperty<EffectInstance>(this, this,
                                            &EffectChain::effectsCount,
                                            &EffectChain::effectsAt);
}

EffectInstance* EffectChain::effectAt(int index) const
{
    if (index < 0 || index >= m_effects.size())
        return nullptr;
    return m_effects[index];
}

void EffectChain::addEffect(EffectInstance *effect)
{
    if (!effect || m_effects.contains(effect))
        return;
    m_effects.append(effect);
    emit effectsChanged();
}

void EffectChain::removeEffect(int index)
{
    if (index < 0 || index >= m_effects.size())
        return;
    EffectInstance *effect = m_effects.takeAt(index);
    delete effect;
    emit effectsChanged();
}

void EffectChain::moveEffect(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_effects.size())
        return;
    if (toIndex < 0 || toIndex >= m_effects.size())
        return;
    if (fromIndex == toIndex)
        return;
    m_effects.move(fromIndex, toIndex);
    emit effectsChanged();
}

void EffectChain::clear()
{
    if (m_effects.isEmpty())
        return;
    qDeleteAll(m_effects);
    m_effects.clear();
    emit effectsChanged();
}

QJsonArray EffectChain::toJson() const
{
    QJsonArray arr;
    for (const auto *effect : m_effects)
        arr.append(effect->toJson());
    return arr;
}

void EffectChain::fromJson(const QJsonArray &arr)
{
    clear();
    for (const auto &val : arr) {
        QJsonObject obj = val.toObject();
        auto *effect = new EffectInstance(
            obj["name"].toString(),
            obj["pluginId"].toString(),
            obj["format"].toString(),
            this);
        effect->fromJson(obj);
        m_effects.append(effect);
    }
    emit effectsChanged();
}

qsizetype EffectChain::effectsCount(QQmlListProperty<EffectInstance> *prop)
{
    auto *chain = static_cast<EffectChain*>(prop->data);
    return chain->m_effects.size();
}

EffectInstance* EffectChain::effectsAt(QQmlListProperty<EffectInstance> *prop, qsizetype index)
{
    auto *chain = static_cast<EffectChain*>(prop->data);
    if (index < 0 || index >= chain->m_effects.size())
        return nullptr;
    return chain->m_effects[index];
}
