#include "PolygonNode.h"
#include "LayerData.hpp"
#include "../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QSpinBox>

PolygonNode::PolygonNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int PolygonNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType PolygonNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void PolygonNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> PolygonNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *PolygonNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(4, 4, 4, 4);
    layout->setSpacing(4);

    auto *sidesRow = new QHBoxLayout();
    auto *sidesLabel = new QLabel("Sides:");
    sidesLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    auto *sidesSpin = new QSpinBox();
    sidesSpin->setRange(3, 64);
    sidesSpin->setValue(m_sides);
    sidesSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    QObject::connect(sidesSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this](int v) {
        m_sides = v;
        generateOutput();
    });
    sidesRow->addWidget(sidesLabel);
    sidesRow->addWidget(sidesSpin);
    layout->addLayout(sidesRow);

    auto *sizeLabel = new QLabel(QString("Size: %1").arg(m_size));
    sizeLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    layout->addWidget(sizeLabel);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(20, 20);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 3px;").arg(m_color.name()));
    layout->addWidget(colorRect);

    return widget;
}

QtNodes::NodeValidationState PolygonNode::validationState() const
{
    return m_validationState;
}

QJsonObject PolygonNode::save() const
{
    QJsonObject obj;
    obj["sides"] = m_sides;
    obj["size"] = m_size;
    obj["color"] = m_color.name();
    return obj;
}

void PolygonNode::load(QJsonObject const &obj)
{
    if (obj.contains("sides")) m_sides = obj["sides"].toInt();
    if (obj.contains("size"))  m_size = obj["size"].toDouble();
    if (obj.contains("color")) m_color = QColor(obj["color"].toString());
    generateOutput();
}

void PolygonNode::generateOutput()
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
    shape->setShapeType(ShapeLayer::Polygon);
    shape->setShapeWidth(m_size);
    shape->setShapeHeight(m_size);
    shape->setSides(m_sides);
    shape->setColor(m_color);
    shape->setName("Polygon Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
