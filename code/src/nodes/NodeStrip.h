#pragma once

#include "../core/Strip.h"

class NodeGraph;
class Layer;

class NodeStrip : public Strip
{
    Q_OBJECT
    Q_PROPERTY(NodeGraph* nodeGraph READ nodeGraph WRITE setNodeGraph NOTIFY nodeGraphChanged)
public:
    explicit NodeStrip(QObject *parent = nullptr);
    ~NodeStrip() override;

    NodeGraph* nodeGraph() const { return m_nodeGraph; }
    void setNodeGraph(NodeGraph *graph);

    Q_INVOKABLE void cook();
    Q_INVOKABLE Strip* clone(QObject *parent = nullptr) const override;
    Q_INVOKABLE NodeStrip* cloneNodeStrip(QObject *parent = nullptr) const;

    QJsonObject toJson() const;
    void fromJson(const QJsonObject &obj);

signals:
    void nodeGraphChanged();

private:
    NodeGraph *m_nodeGraph = nullptr;
};
