#include "NodeStrip.h"
#include "NodeGraph.h"
#include "../core/Layer.h"
#include "../core/Track.h"

#include <QtNodes/DataFlowGraphModel>
#include <QJsonObject>

NodeStrip::NodeStrip(QObject *parent)
    : Strip(parent)
{
}

NodeStrip::~NodeStrip()
{
}

void NodeStrip::setNodeGraph(NodeGraph *graph)
{
    if (m_nodeGraph != graph) {
        if (m_nodeGraph && m_nodeGraph->parent() == this)
            delete m_nodeGraph;
        m_nodeGraph = graph;
        if (m_nodeGraph)
            m_nodeGraph->setParent(this);
        emit nodeGraphChanged();
    }
}

void NodeStrip::cook()
{
    if (!m_nodeGraph)
        return;

    Layer *output = m_nodeGraph->cook();
    if (output)
        setElement(output);
}

Strip* NodeStrip::clone(QObject *parent) const
{
    return cloneNodeStrip(parent);
}

NodeStrip* NodeStrip::cloneNodeStrip(QObject *parent) const
{
    auto *s = new NodeStrip(parent);
    s->setName(name());
    s->setStartFrame(startFrame());
    s->setDuration(duration());

    // Deep copy the node graph via JSON serialization
    if (m_nodeGraph) {
        auto json = m_nodeGraph->graphModel()->save();
        auto *graphCopy = new NodeGraph(s);
        graphCopy->graphModel()->load(json);
        s->setNodeGraph(graphCopy);
    }

    return s;
}

QJsonObject NodeStrip::toJson() const
{
    QJsonObject obj = Strip::toJson();
    obj["__type"] = "NodeStrip";
    if (m_nodeGraph) {
        obj["nodeGraph"] = m_nodeGraph->graphModel()->save();
    }
    return obj;
}

void NodeStrip::fromJson(const QJsonObject &obj)
{
    Strip::fromJson(obj);

    if (obj.contains("nodeGraph") && !obj["nodeGraph"].isNull()) {
        auto *graph = new NodeGraph(this);
        graph->graphModel()->load(obj["nodeGraph"].toObject());
        setNodeGraph(graph);
    }
}
