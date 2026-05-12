#include "NodeStrip.h"
#include "../core/Layer.h"
#include "../core/Track.h"

#include <QJsonObject>

NodeStrip::NodeStrip(QObject *parent)
    : Strip(parent)
{
}

NodeStrip::~NodeStrip()
{
}

void NodeStrip::setNodeGraphJson(const QString &json)
{
    if (m_nodeGraphJson != json) {
        m_nodeGraphJson = json;
        emit nodeGraphJsonChanged();
    }
}

void NodeStrip::cook()
{
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
    s->setNodeGraphJson(m_nodeGraphJson);
    return s;
}

QJsonObject NodeStrip::toJson() const
{
    QJsonObject obj = Strip::toJson();
    obj["__type"] = "NodeStrip";
    if (!m_nodeGraphJson.isEmpty())
        obj["nodeGraph"] = m_nodeGraphJson;
    return obj;
}

void NodeStrip::fromJson(const QJsonObject &obj)
{
    Strip::fromJson(obj);
    if (obj.contains("nodeGraph"))
        setNodeGraphJson(obj["nodeGraph"].toString());
}
