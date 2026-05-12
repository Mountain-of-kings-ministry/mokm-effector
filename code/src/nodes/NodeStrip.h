#pragma once

#include "../core/Strip.h"

class NodeStrip : public Strip
{
    Q_OBJECT
    Q_PROPERTY(QString nodeGraphJson READ nodeGraphJson WRITE setNodeGraphJson NOTIFY nodeGraphJsonChanged)
public:
    explicit NodeStrip(QObject *parent = nullptr);
    ~NodeStrip() override;

    QString nodeGraphJson() const { return m_nodeGraphJson; }
    void setNodeGraphJson(const QString &json);

    Q_INVOKABLE void cook();
    Q_INVOKABLE Strip* clone(QObject *parent = nullptr) const override;
    Q_INVOKABLE NodeStrip* cloneNodeStrip(QObject *parent = nullptr) const;

    QJsonObject toJson() const;
    void fromJson(const QJsonObject &obj);

signals:
    void nodeGraphJsonChanged();

private:
    QString m_nodeGraphJson;
};
