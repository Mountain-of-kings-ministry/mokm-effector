#include "CircleNode.h"
#include "../LayerData.hpp"
#include "../../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QLabel>

CircleNode::CircleNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int CircleNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType CircleNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void CircleNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> CircleNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *CircleNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(2);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(16, 16);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 8px;").arg(m_color.name()));
    layout->addWidget(colorRect, 0, Qt::AlignCenter);

    return widget;
}

QtNodes::NodeValidationState CircleNode::validationState() const
{
    return m_validationState;
}

QJsonObject CircleNode::save() const
{
    QJsonObject obj;
    obj["radius"] = m_radius;
    obj["color"] = m_color.name();
    return obj;
}

void CircleNode::load(QJsonObject const &obj)
{
    if (obj.contains("radius")) m_radius = obj["radius"].toDouble();
    if (obj.contains("color"))  m_color = QColor(obj["color"].toString());
    generateOutput();
}

void CircleNode::generateOutput()
{
    if (m_output) {
        auto oldData = std::dynamic_pointer_cast<LayerData>(m_output);
        if (oldData) {
            Layer *oldLayer = oldData->layer();
            if (oldLayer) {
                oldLayer->setParent(nullptr);
                delete oldLayer;
            }
        }
    }

    auto *shape = new ShapeLayer();
    shape->setShapeType(ShapeLayer::Circle);
    shape->setShapeWidth(m_radius * 2);
    shape->setShapeHeight(m_radius * 2);
    shape->setColor(m_color);
    shape->setName("Circle Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
