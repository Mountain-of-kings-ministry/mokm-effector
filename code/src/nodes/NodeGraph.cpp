#include "NodeGraph.h"
#include "nodes/generators/RectangleNode.h"
#include "nodes/generators/EllipseNode.h"
#include "nodes/generators/CircleNode.h"
#include "nodes/generators/TriangleNode.h"
#include "nodes/text/TextNode.h"
#include "nodes/generators/PolygonNode.h"
#include "nodes/generators/StarNode.h"
#include "nodes/generators/LineNode.h"
#include "nodes/generators/ArrowNode.h"
#include "nodes/generators/RoundedRectNode.h"
#include "nodes/generators/ArcNode.h"
#include "nodes/generators/GridNode.h"
#include "nodes/generators/SpiralNode.h"
#include "nodes/effects/BlurNode.h"
#include "nodes/effects/TransformNode.h"
#include "nodes/compositing/BlendNode.h"
#include "nodes/rendering/OutputNode.h"
#include "nodes/LayerData.hpp"
#include "CompactNodeGeometry.h"
#include "CompactNodePainter.h"

#include <QtNodes/DataFlowGraphModel>
#include <QtNodes/DataFlowGraphicsScene>
#include <QtNodes/GraphicsView>
#include <QtNodes/NodeDelegateModelRegistry>
#include <QtNodes/NodeStyle>
#include <QJsonObject>
#include <QGraphicsScene>

NodeGraph::NodeGraph(QObject *parent)
    : QObject(parent)
{
    setupRegistry();
    m_graphModel = std::make_unique<QtNodes::DataFlowGraphModel>(m_registry);
    m_scene = std::make_unique<QtNodes::DataFlowGraphicsScene>(*m_graphModel);

    // Track node selection
    connect(m_scene.get(), &QGraphicsScene::selectionChanged, this, &NodeGraph::onSelectionChanged);

    // Apply compact geometry and painter
    m_scene->setNodeGeometry(std::make_unique<CompactNodeGeometry>(*m_graphModel));
    m_scene->setNodePainter(std::make_unique<CompactNodePainter>());

    // Apply a base dark style
    QtNodes::NodeStyle::setNodeStyle(R"({
        "NodeStyle": {
            "ShadowEnabled": true,
            "Opacity": 0.95
        }
    })");

    // Auto-create a non-removable Output node
    m_outputNodeId = m_graphModel->addNode("Output");
    m_hasAutoOutput = true;
}

NodeGraph::~NodeGraph() = default;

void NodeGraph::setupRegistry()
{
    m_registry = std::make_shared<QtNodes::NodeDelegateModelRegistry>();
    
    // 1. GENERATORS
    m_registry->registerModel<RectangleNode>("Generators");
    m_registry->registerModel<EllipseNode>("Generators");
    m_registry->registerModel<CircleNode>("Generators");
    m_registry->registerModel<TriangleNode>("Generators");
    m_registry->registerModel<PolygonNode>("Generators");
    m_registry->registerModel<StarNode>("Generators");
    m_registry->registerModel<LineNode>("Generators");
    m_registry->registerModel<ArrowNode>("Generators");
    m_registry->registerModel<RoundedRectNode>("Generators");
    m_registry->registerModel<ArcNode>("Generators");
    m_registry->registerModel<GridNode>("Generators");
    m_registry->registerModel<SpiralNode>("Generators");

    // 2. TEXT
    m_registry->registerModel<TextNode>("Text");

    // 11. EFFECTS
    m_registry->registerModel<BlurNode>("Effects");
    m_registry->registerModel<TransformNode>("Effects");

    // 14. COMPOSITING
    m_registry->registerModel<BlendNode>("Compositing");

    // 15. RENDERING (Final Output)
    m_registry->registerModel<OutputNode>("Rendering");
}

int NodeGraph::addNode(const QString &type)
{
    auto nodeId = m_graphModel->addNode(type);
    emit graphChanged();
    return static_cast<int>(nodeId);
}

void NodeGraph::removeNode(int nodeId)
{
    if (m_hasAutoOutput && static_cast<unsigned int>(nodeId) == m_outputNodeId)
        return;
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
    for (auto id : ids) {
        if (m_hasAutoOutput && id == static_cast<QtNodes::NodeId>(m_outputNodeId))
            continue;
        m_graphModel->deleteNode(id);
    }
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

int NodeGraph::outputNodeId() const
{
    for (auto id : m_graphModel->allNodeIds()) {
        QString caption = m_graphModel->nodeData(id, QtNodes::NodeRole::Caption).toString();
        if (caption == "Output")
            return static_cast<int>(id);
    }
    return -1;
}

int NodeGraph::addNodeAutoConnect(const QString &type)
{
    int nodeId = addNode(type);
    int outId = outputNodeId();
    if (outId >= 0 && nodeId >= 0) {
        unsigned int outPorts = m_graphModel->nodeData(
            static_cast<QtNodes::NodeId>(nodeId),
            QtNodes::NodeRole::OutPortCount).value<unsigned int>();
        if (outPorts > 0)
            connectNodes(nodeId, 0, outId, 0);
    }
    return nodeId;
}

void NodeGraph::onSelectionChanged()
{
    auto nodes = m_scene->selectedNodes();
    int prevId = m_selectedNodeId;
    if (nodes.empty()) {
        m_selectedNodeId = -1;
    } else {
        m_selectedNodeId = static_cast<int>(nodes.front());
    }
    if (m_selectedNodeId != prevId)
        emit selectedNodeChanged(m_selectedNodeId);
}

QVariantMap NodeGraph::nodeParameters(int nodeId) const
{
    QJsonObject state = m_graphModel->saveNode(static_cast<QtNodes::NodeId>(nodeId));
    return state.toVariantMap();
}

QStringList NodeGraph::nodeParameterNames(int nodeId) const
{
    QJsonObject state = m_graphModel->saveNode(static_cast<QtNodes::NodeId>(nodeId));
    return state.keys();
}

QVariant NodeGraph::nodeParameter(int nodeId, const QString &name) const
{
    QJsonObject state = m_graphModel->saveNode(static_cast<QtNodes::NodeId>(nodeId));
    return state[name].toVariant();
}

void NodeGraph::setNodeParameter(int nodeId, const QString &name, const QVariant &value)
{
    QJsonObject state = m_graphModel->saveNode(static_cast<QtNodes::NodeId>(nodeId));
    state[name] = QJsonValue::fromVariant(value);
    m_graphModel->loadNode(state);
    emit graphChanged();
}

Layer* NodeGraph::cook()
{
    auto ids = m_graphModel->allNodeIds();
    if (ids.empty())
        return nullptr;

    // Find OutputNode and use its input
    int outId = outputNodeId();
    if (outId >= 0) {
        auto *outNode = m_graphModel->delegateModel<OutputNode>(
            static_cast<QtNodes::NodeId>(outId));
        if (outNode) {
            auto input = outNode->inputData();
            if (input) {
                auto layerData = std::dynamic_pointer_cast<LayerData>(input);
                if (layerData && layerData->layer())
                    return layerData->layer();
            }
        }
    }

    // Fallback: walk the DAG, find terminal nodes (no outgoing connections)
    QtNodes::NodeId terminalId = *ids.begin();

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
