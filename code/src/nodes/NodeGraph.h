#pragma once

#include <QObject>
#include <QString>
#include <QVector>
#include <memory>

namespace QtNodes
{
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
    Q_PROPERTY(int selectedNodeId READ selectedNodeId NOTIFY selectedNodeChanged)
public:
    explicit NodeGraph(QObject *parent = nullptr);
    ~NodeGraph() override;

    Q_INVOKABLE int addNode(const QString &type);
    Q_INVOKABLE int addNodeAt(const QString &type, qreal x, qreal y);
    Q_INVOKABLE void removeNode(int nodeId);
    Q_INVOKABLE void connectNodes(int outNodeId, int outPort, int inNodeId, int inPort);
    Q_INVOKABLE void disconnectAll();
    Q_INVOKABLE void clear();

    int nodeCount() const;
    Q_INVOKABLE QStringList nodeIds() const;
    Q_INVOKABLE int outputNodeId() const;
    Q_INVOKABLE int addNodeAutoConnect(const QString &type);
    Q_INVOKABLE int addNodeAutoConnectAt(const QString &type, qreal x, qreal y);
    Q_INVOKABLE void ensureOutputCompact();
    Q_INVOKABLE bool testConnectionPossible(int outNodeId, int outPort, int inNodeId, int inPort) const;

    int selectedNodeId() const { return m_selectedNodeId; }

    Q_INVOKABLE QVariantMap nodeParameters(int nodeId) const;
    Q_INVOKABLE QStringList nodeParameterNames(int nodeId) const;
    Q_INVOKABLE QVariant nodeParameter(int nodeId, const QString &name) const;
    Q_INVOKABLE void setNodeParameter(int nodeId, const QString &name, const QVariant &value);

    Layer *cook();

    QtNodes::DataFlowGraphModel *graphModel() const { return m_graphModel.get(); }
    QtNodes::DataFlowGraphicsScene *graphicsScene() const { return m_scene.get(); }

signals:
    void graphChanged();
    void selectedNodeChanged(int nodeId);

private:
    void setupRegistry();
    void onSelectionChanged();

    std::shared_ptr<QtNodes::NodeDelegateModelRegistry> m_registry;
    std::unique_ptr<QtNodes::DataFlowGraphModel> m_graphModel;
    std::unique_ptr<QtNodes::DataFlowGraphicsScene> m_scene;

    int m_outputNodeId = -1;
    bool m_hasAutoOutput = false;
    int m_selectedNodeId = -1;
};
