#include "NodeGraph.h"
#include "nodes/RectangleNode.h"
#include "nodes/EllipseNode.h"
#include "nodes/CircleNode.h"
#include "nodes/TriangleNode.h"
#include "nodes/TextNode.h"
#include "nodes/LayerData.hpp"

#include <QtNodes/DataFlowGraphModel>
#include <QtNodes/DataFlowGraphicsScene>
#include <QtNodes/GraphicsView>
#include <QtNodes/NodeDelegateModelRegistry>
#include <QJsonObject>

NodeGraph::NodeGraph(QObject *parent)
    : QObject(parent)
{
    setupRegistry();
    m_graphModel = std::make_unique<QtNodes::DataFlowGraphModel>(m_registry);
    m_scene = std::make_unique<QtNodes::DataFlowGraphicsScene>(*m_graphModel);
}

NodeGraph::~NodeGraph() = default;

void NodeGraph::setupRegistry()
{
    m_registry = std::make_shared<QtNodes::NodeDelegateModelRegistry>();
    m_registry->registerModel<RectangleNode>("Generators");
    m_registry->registerModel<EllipseNode>("Generators");
    m_registry->registerModel<CircleNode>("Generators");
    m_registry->registerModel<TriangleNode>("Generators");
    m_registry->registerModel<TextNode>("Generators");
}

int NodeGraph::addNode(const QString &type)
{
    auto nodeId = m_graphModel->addNode(type);
    emit graphChanged();
    return static_cast<int>(nodeId);
}

void NodeGraph::removeNode(int nodeId)
{
    m_graphModel->deleteNode(static_cast<QtNodes::NodeId>(nodeId));
    emit graphChanged();
}

void NodeGraph::connectNodes(int outNodeId, int outPort, int inNodeId, int inPort)
{
    QtNodes::ConnectionId conn{
        static_cast<QtNodes::NodeId>(outNodeId),
        static_cast<QtNodes::PortIndex>(outPort),
        static_cast<QtNodes::NodeId>(inNodeId),
        static_cast<QtNodes::PortIndex>(inPort)
    };
    if (m_graphModel->connectionPossible(conn))
        m_graphModel->addConnection(conn);
    emit graphChanged();
}

void NodeGraph::disconnectAll()
{
    for (auto nodeId : m_graphModel->allNodeIds()) {
        for (auto connId : m_graphModel->allConnectionIds(nodeId)) {
            m_graphModel->deleteConnection(connId);
        }
    }
    emit graphChanged();
}

void NodeGraph::clear()
{
    disconnectAll();
    auto ids = m_graphModel->allNodeIds();
    for (auto id : ids)
        m_graphModel->deleteNode(id);
    emit graphChanged();
}

int NodeGraph::nodeCount() const
{
    return static_cast<int>(m_graphModel->allNodeIds().size());
}

QStringList NodeGraph::nodeIds() const
{
    QStringList ids;
    for (auto id : m_graphModel->allNodeIds())
        ids.append(QString::number(id));
    return ids;
}

Layer* NodeGraph::cook()
{
    auto ids = m_graphModel->allNodeIds();
    if (ids.empty())
        return nullptr;

    // Walk the DAG: find terminal nodes (no outgoing connections)
    // For now, return the last generator node's output
    QtNodes::NodeId terminalId = *ids.begin();

    // Try to find a node with no outputs
    for (auto id : ids) {
        auto conns = m_graphModel->allConnectionIds(id);
        bool hasOutputs = false;
        for (auto &c : conns) {
            if (c.inNodeId != id) {
                hasOutputs = true;
                break;
            }
        }
        if (!hasOutputs) {
            terminalId = id;
            break;
        }
    }

    // Get the output data from the terminal node's first output port
    auto portData = m_graphModel->portData(terminalId, QtNodes::PortType::Out, 0, QtNodes::PortRole::Data);
    if (portData.isNull())
        return nullptr;

    auto data = portData.value<std::shared_ptr<QtNodes::NodeData>>();
    if (!data)
        return nullptr;

    auto layerData = std::dynamic_pointer_cast<LayerData>(data);
    if (!layerData)
        return nullptr;

    return layerData->layer();
}
