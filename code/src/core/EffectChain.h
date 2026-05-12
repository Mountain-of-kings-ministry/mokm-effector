#ifndef EFFECTCHAIN_H
#define EFFECTCHAIN_H

#include <QObject>
#include <QVector>
#include <QQmlListProperty>
#include <QJsonArray>
#include <QJsonObject>

class EffectInstance;

class EffectChain : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<EffectInstance> effects READ effects NOTIFY effectsChanged)
    Q_PROPERTY(int count READ count NOTIFY effectsChanged)
public:
    explicit EffectChain(QObject *parent = nullptr);
    ~EffectChain() override;

    QQmlListProperty<EffectInstance> effects();
    int count() const { return m_effects.size(); }

    Q_INVOKABLE EffectInstance* effectAt(int index) const;
    Q_INVOKABLE void addEffect(EffectInstance *effect);
    Q_INVOKABLE void removeEffect(int index);
    Q_INVOKABLE void moveEffect(int fromIndex, int toIndex);
    Q_INVOKABLE void clear();

    const QVector<EffectInstance*>& list() const { return m_effects; }

    QJsonArray toJson() const;
    void fromJson(const QJsonArray &arr);

signals:
    void effectsChanged();

private:
    static qsizetype effectsCount(QQmlListProperty<EffectInstance> *prop);
    static EffectInstance* effectsAt(QQmlListProperty<EffectInstance> *prop, qsizetype index);

    QVector<EffectInstance*> m_effects;
};

#endif
