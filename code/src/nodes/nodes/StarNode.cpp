#include "StarNode.h"
#include "LayerData.hpp"
#include "../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QSpinBox>

StarNode::StarNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int StarNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType StarNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void StarNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> StarNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *StarNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(4, 4, 4, 4);
    layout->setSpacing(4);

    auto *pointsRow = new QHBoxLayout();
    auto *pointsLabel = new QLabel("Points:");
    pointsLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    auto *pointsSpin = new QSpinBox();
    pointsSpin->setRange(3, 32);
    pointsSpin->setValue(m_points);
    pointsSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    QObject::connect(pointsSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this](int v) {
        m_points = v;
        generateOutput();
    });
    pointsRow->addWidget(pointsLabel);
    pointsRow->addWidget(pointsSpin);
    layout->addLayout(pointsRow);

    auto *sizeLabel = new QLabel(QString("Size: %1").arg(m_size));
    sizeLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    layout->addWidget(sizeLabel);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(20, 20);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 3px;").arg(m_color.name()));
    layout->addWidget(colorRect);

    return widget;
}

QtNodes::NodeValidationState StarNode::validationState() const
{
    return m_validationState;
}

QJsonObject StarNode::save() const
{
    QJsonObject obj;
    obj["points"] = m_points;
    obj["size"] = m_size;
    obj["color"] = m_color.name();
    return obj;
}

void StarNode::load(QJsonObject const &obj)
{
    if (obj.contains("points")) m_points = obj["points"].toInt();
    if (obj.contains("size"))   m_size = obj["size"].toDouble();
    if (obj.contains("color"))  m_color = QColor(obj["color"].toString());
    generateOutput();
}

void StarNode::generateOutput()
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
    shape->setShapeType(ShapeLayer::Star);
    shape->setShapeWidth(m_size);
    shape->setShapeHeight(m_size);
    shape->setSides(m_points);
    shape->setColor(m_color);
    shape->setName("Star Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
