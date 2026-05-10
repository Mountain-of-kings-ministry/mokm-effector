#include "EllipseNode.h"
#include "LayerData.hpp"
#include "../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QLabel>

EllipseNode::EllipseNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int EllipseNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType EllipseNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void EllipseNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> EllipseNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *EllipseNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(4, 4, 4, 4);
    layout->setSpacing(4);

    auto *sizeLabel = new QLabel(QString("%1 x %2").arg(m_width).arg(m_height));
    sizeLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    layout->addWidget(sizeLabel);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(20, 20);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 10px;").arg(m_color.name()));
    layout->addWidget(colorRect);

    return widget;
}

QtNodes::NodeValidationState EllipseNode::validationState() const
{
    return m_validationState;
}

QJsonObject EllipseNode::save() const
{
    QJsonObject obj;
    obj["width"] = m_width;
    obj["height"] = m_height;
    obj["color"] = m_color.name();
    return obj;
}

void EllipseNode::load(QJsonObject const &obj)
{
    if (obj.contains("width"))  m_width = obj["width"].toDouble();
    if (obj.contains("height")) m_height = obj["height"].toDouble();
    if (obj.contains("color"))  m_color = QColor(obj["color"].toString());
    generateOutput();
}

void EllipseNode::generateOutput()
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
    shape->setShapeType(ShapeLayer::Ellipse);
    shape->setShapeWidth(m_width);
    shape->setShapeHeight(m_height);
    shape->setColor(m_color);
    shape->setName("Ellipse Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
