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

#include <QtNodes/DataFlowGraphModel>
#include <QtNodes/DataFlowGraphicsScene>
#include <QtNodes/GraphicsView>
#include <QtNodes/NodeDelegateModelRegistry>
#include <QtNodes/NodeStyle>
#include <QtNodes/ConnectionStyle>
#include <QtNodes/GraphicsViewStyle>
#include <QJsonObject>
#include <QGraphicsScene>
#include <QSize>
#include <QPointF>
#include <QDebug>

NodeGraph::NodeGraph(QObject *parent)
    : QObject(parent)
{
    setupRegistry();
    m_graphModel = std::make_unique<QtNodes::DataFlowGraphModel>(m_registry);
    m_scene = std::make_unique<QtNodes::DataFlowGraphicsScene>(*m_graphModel);

    // Track node selection
    connect(m_scene.get(), &QGraphicsScene::selectionChanged, this, &NodeGraph::onSelectionChanged);

    // Use QtNodes default geometry/painter (clean calculator-like style)
    QtNodes::NodeStyle::setNodeStyle(R"({
        "NodeStyle": {
            "NormalBoundaryColor": [200, 200, 200],
            "SelectedBoundaryColor": [255, 170, 0],
            "GradientColor0": [80, 80, 80],
            "GradientColor1": [60, 60, 60],
            "GradientColor2": [50, 50, 50],
            "GradientColor3": [45, 45, 45],
            "ShadowColor": [20, 20, 20],
            "ShadowEnabled": true,
            "FontColor": "white",
            "FontColorFaded": [160, 160, 160],
            "ConnectionPointColor": [180, 180, 180],
            "FilledConnectionPointColor": "cyan",
            "ErrorColor": [211, 47, 47],
            "WarningColor": [255, 179, 0],
            "PenWidth": 0.8,
            "HoveredPenWidth": 1.2,
            "ConnectionPointDiameter": 14.0,
            "Opacity": 0.95
        }
    })");

    QtNodes::ConnectionStyle::setConnectionStyle(R"({
        "ConnectionStyle": {
            "ConstructionColor": [140, 140, 140],
            "NormalColor": [180, 180, 180],
            "SelectedColor": [200, 200, 200],
            "SelectedHaloColor": [255, 170, 0],
            "HoveredColor": "cyan",
            "LineWidth": 2.0,
            "ConstructionLineWidth": 1.2,
            "PointDiameter": 14.0,
            "UseDataDefinedColors": true
        }
    })");

    QtNodes::GraphicsViewStyle::setStyle(R"({
        "GraphicsViewStyle": {
            "BackgroundColor": [26, 26, 26],
            "FineGridColor": [45, 45, 45],
            "CoarseGridColor": [35, 35, 35]
        }
    })");

    // Auto-create a non-removable Output node
    QtNodes::NodeId outId = m_graphModel->addNode("Output");
    m_outputNodeId = static_cast<int>(outId);
    m_hasAutoOutput = true;
    // Place the output node at a visible canvas location
    m_graphModel->setNodeData(outId, QtNodes::NodeRole::Position, QPointF(200, 200));
    // Ensure the output node has a clear header style
    QVariantMap outStyle;
    QVariantMap outInner;
    outInner["GradientColor0"] = QVariant::fromValue(QList<int>({50, 50, 60}));
    outInner["GradientColor1"] = QVariant::fromValue(QList<int>({30, 30, 40}));
    outInner["FontColor"] = QString("white");
    outStyle["NodeStyle"] = outInner;
    m_graphModel->setNodeData(outId, QtNodes::NodeRole::Style, outStyle);
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

    // Set a conservative, compact default size for newly created nodes
    // to make the node graph denser and closer to the example UI.
    QSize defaultSize(140, 40);
    m_graphModel->setNodeData(nodeId, QtNodes::NodeRole::Size, defaultSize);

    // Apply a category-based header color style where possible.
    // Lightweight heuristic map from node `type` -> category palette.
    const auto toLower = [](const QString &s)
    { return s.toLower(); };
    QString t = toLower(type);

    // Define colors per category (GradientColor0, GradientColor1)
    QMap<QString, QList<int>> cat0;
    QMap<QString, QList<int>> cat1;
    cat0["generators"] = {60, 120, 190};
    cat1["generators"] = {40, 90, 160};
    cat0["text"] = {120, 60, 170};
    cat1["text"] = {90, 40, 130};
    cat0["media"] = {16, 150, 140};
    cat1["media"] = {12, 120, 110};
    cat0["animation"] = {255, 135, 0};
    cat1["animation"] = {200, 100, 0};
    cat0["motion"] = {200, 60, 140};
    cat1["motion"] = {160, 40, 110};
    cat0["procedural"] = {40, 160, 80};
    cat1["procedural"] = {20, 120, 60};
    cat0["effects"] = {200, 60, 60};
    cat1["effects"] = {150, 40, 40};
    cat0["audio"] = {255, 200, 0};
    cat1["audio"] = {200, 150, 0};
    cat0["utility"] = {120, 120, 120};
    cat1["utility"] = {90, 90, 90};
    cat0["compositing"] = {0, 170, 170};
    cat1["compositing"] = {0, 120, 120};
    cat0["rendering"] = {40, 200, 120};
    cat1["rendering"] = {20, 160, 80};
    cat0["geometry"] = {180, 120, 60};
    cat1["geometry"] = {140, 90, 40};

    // Simple membership checks
    auto isOneOf = [&](const QStringList &list)
    {
        for (auto &s : list) if (t == toLower(s)) return true; return false; };

    QString chosenCat;
    if (isOneOf({"rectangle", "circle", "ellipse", "polygon", "star", "line", "arrow", "roundedrect", "arc", "grid", "spiral", "generator"}))
        chosenCat = "generators";
    else if (isOneOf({"text", "svg", "font", "glyphs", "textpath"}))
        chosenCat = "text";
    else if (isOneOf({"image", "movie", "camera", "render", "fbo", "color", "gradient", "noisemap", "pattern"}))
        chosenCat = "media";
    else if (isOneOf({"keyframe", "animation", "curve", "easing", "spring", "bounce", "oscillator", "wiggle", "loop", "pingpong", "timestretch"}))
        chosenCat = "animation";
    else if (isOneOf({"cloner", "radialclone", "gridclone", "followpath", "lookat", "align", "distribute", "randomtransform", "trail", "echo"}))
        chosenCat = "motion";
    else if (isOneOf({"noise", "curlnoise", "random", "voronoi", "perlin", "fractal", "expression", "formula"}))
        chosenCat = "procedural";
    else if (isOneOf({"blur", "glow", "bloom", "shadow", "outline", "chromaticaberration", "distortion", "pixelate", "sharpen", "glitch", "filmgrain", "colorcorrection", "curves", "levels", "keyer"}))
        chosenCat = "effects";
    else if (isOneOf({"audioreactive", "audiospectrum", "audiowaveform", "beatdetection", "fft", "midiinput"}))
        chosenCat = "audio";
    else if (isOneOf({"clamp", "remap", "lerp", "mix", "math", "vectormath", "timer", "counter", "utility"}))
        chosenCat = "utility";
    else if (isOneOf({"blend", "merge", "alphaover", "multiply", "screen", "overlay", "mask", "crop", "transform2d"}))
        chosenCat = "compositing";
    else if (isOneOf({"output", "renderlayer", "renderpass", "viewport"}))
        chosenCat = "rendering";
    else if (isOneOf({"point", "line", "polygon", "path", "curve", "textshape", "extrude", "bevel", "subdivide", "boolean"}))
        chosenCat = "geometry";

    if (!chosenCat.isEmpty() && cat0.contains(chosenCat))
    {
        QVariantMap nodeStyle;
        QVariantMap inner;
        inner["GradientColor0"] = QVariant::fromValue(cat0[chosenCat]);
        inner["GradientColor1"] = QVariant::fromValue(cat1[chosenCat]);
        inner["FontColor"] = QString("white");
        nodeStyle["NodeStyle"] = inner;
        m_graphModel->setNodeData(nodeId, QtNodes::NodeRole::Style, nodeStyle);
    }

    emit graphChanged();
    return static_cast<int>(nodeId);
}

int NodeGraph::addNodeAt(const QString &type, qreal x, qreal y)
{
    int nodeId = addNode(type);
    m_graphModel->setNodeData(static_cast<QtNodes::NodeId>(nodeId),
                              QtNodes::NodeRole::Position, QPointF(x, y));
    return nodeId;
}

void NodeGraph::ensureOutputCompact()
{
    if (!m_hasAutoOutput || !m_graphModel || m_outputNodeId < 0)
        return;
    QSize outputSize(120, 32);
    m_graphModel->setNodeData(static_cast<QtNodes::NodeId>(m_outputNodeId),
                              QtNodes::NodeRole::Size, outputSize);
}

int NodeGraph::addNodeAutoConnectAt(const QString &type, qreal x, qreal y)
{
    int nodeId = addNodeAt(type, x, y);
    int outId = outputNodeId();
    if (outId >= 0 && nodeId >= 0)
    {
        unsigned int outPorts = m_graphModel->nodeData(
                                                static_cast<QtNodes::NodeId>(nodeId),
                                                QtNodes::NodeRole::OutPortCount)
                                    .value<unsigned int>();
        if (outPorts > 0)
            connectNodes(nodeId, 0, outId, 0);
    }
    return nodeId;
}

void NodeGraph::removeNode(int nodeId)
{
    if (m_hasAutoOutput && nodeId == m_outputNodeId)
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
        static_cast<QtNodes::PortIndex>(inPort)};
    bool possible = false;
    if (m_graphModel)
        possible = m_graphModel->connectionPossible(conn);
    if (!possible)
    {
        qDebug() << "connectNodes: connection not possible:" << outNodeId << outPort << "->" << inNodeId << inPort;
        return;
    }
    m_graphModel->addConnection(conn);
    qDebug() << "connectNodes: added connection:" << outNodeId << outPort << "->" << inNodeId << inPort;
    emit graphChanged();
}

bool NodeGraph::testConnectionPossible(int outNodeId, int outPort, int inNodeId, int inPort) const
{
    if (!m_graphModel)
        return false;
    QtNodes::ConnectionId conn{
        static_cast<QtNodes::NodeId>(outNodeId),
        static_cast<QtNodes::PortIndex>(outPort),
        static_cast<QtNodes::NodeId>(inNodeId),
        static_cast<QtNodes::PortIndex>(inPort)};
    return m_graphModel->connectionPossible(conn);
}

void NodeGraph::disconnectAll()
{
    for (auto nodeId : m_graphModel->allNodeIds())
    {
        for (auto connId : m_graphModel->allConnectionIds(nodeId))
        {
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
    {
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
    return m_outputNodeId;
}

int NodeGraph::addNodeAutoConnect(const QString &type)
{
    int nodeId = addNode(type);
    int outId = outputNodeId();
    if (outId >= 0 && nodeId >= 0)
    {
        unsigned int outPorts = m_graphModel->nodeData(
                                                static_cast<QtNodes::NodeId>(nodeId),
                                                QtNodes::NodeRole::OutPortCount)
                                    .value<unsigned int>();
        if (outPorts > 0)
            connectNodes(nodeId, 0, outId, 0);
    }
    return nodeId;
}

void NodeGraph::onSelectionChanged()
{
    auto nodes = m_scene->selectedNodes();
    int prevId = m_selectedNodeId;
    if (nodes.empty())
    {
        m_selectedNodeId = -1;
    }
    else
    {
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

Layer *NodeGraph::cook()
{
    auto ids = m_graphModel->allNodeIds();
    if (ids.empty())
        return nullptr;

    // Find OutputNode and use its input
    int outId = outputNodeId();
    if (outId >= 0)
    {
        auto *outNode = m_graphModel->delegateModel<OutputNode>(
            static_cast<QtNodes::NodeId>(outId));
        if (outNode)
        {
            auto input = outNode->inputData();
            if (input)
            {
                auto layerData = std::dynamic_pointer_cast<LayerData>(input);
                if (layerData && layerData->layer())
                    return layerData->layer();
            }
        }
    }

    // Fallback: walk the DAG, find terminal nodes (no outgoing connections)
    QtNodes::NodeId terminalId = *ids.begin();

    for (auto id : ids)
    {
        auto conns = m_graphModel->allConnectionIds(id);
        bool hasOutputs = false;
        for (auto &c : conns)
        {
            if (c.inNodeId != id)
            {
                hasOutputs = true;
                break;
            }
        }
        if (!hasOutputs)
        {
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
