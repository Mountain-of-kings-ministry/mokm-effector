#pragma once

#include <QObject>
#include <QString>
#include <QVector>
#include <memory>

namespace QtNodes {
class DataFlowGraphModel;
class DataFlowGraphicsScene;
class GraphicsView;
class NodeDelegateModelRegistry;
}

class Layer;

class NodeGraph : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int nodeCount READ nodeCount NOTIFY graphChanged)
public:
    explicit NodeGraph(QObject *parent = nullptr);
    ~NodeGraph() override;

    Q_INVOKABLE int addNode(const QString &type);
    Q_INVOKABLE void removeNode(int nodeId);
    Q_INVOKABLE void connectNodes(int outNodeId, int outPort, int inNodeId, int inPort);
    Q_INVOKABLE void disconnectAll();
    Q_INVOKABLE void clear();

    int nodeCount() const;
    Q_INVOKABLE QStringList nodeIds() const;

    Layer* cook();

    QtNodes::DataFlowGraphModel* graphModel() const { return m_graphModel.get(); }
    QtNodes::DataFlowGraphicsScene* graphicsScene() const { return m_scene.get(); }

signals:
    void graphChanged();

private:
    void setupRegistry();

    std::shared_ptr<QtNodes::NodeDelegateModelRegistry> m_registry;
    std::unique_ptr<QtNodes::DataFlowGraphModel> m_graphModel;
    std::unique_ptr<QtNodes::DataFlowGraphicsScene> m_scene;
};
