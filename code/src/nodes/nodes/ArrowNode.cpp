#include "ArrowNode.h"
#include "LayerData.hpp"
#include "../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QDoubleSpinBox>

ArrowNode::ArrowNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int ArrowNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType ArrowNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void ArrowNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> ArrowNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *ArrowNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(4, 4, 4, 4);
    layout->setSpacing(4);

    auto *lenRow = new QHBoxLayout();
    auto *lenLabel = new QLabel("Length:");
    lenLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    auto *lenSpin = new QDoubleSpinBox();
    lenSpin->setRange(10, 2000);
    lenSpin->setValue(m_length);
    lenSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    QObject::connect(lenSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_length = v;
        generateOutput();
    });
    lenRow->addWidget(lenLabel);
    lenRow->addWidget(lenSpin);
    layout->addLayout(lenRow);

    auto *strokeRow = new QHBoxLayout();
    auto *strokeLabel = new QLabel("Width:");
    strokeLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    auto *strokeSpin = new QDoubleSpinBox();
    strokeSpin->setRange(0.5, 50);
    strokeSpin->setValue(m_strokeWidth);
    strokeSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    QObject::connect(strokeSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_strokeWidth = v;
        generateOutput();
    });
    strokeRow->addWidget(strokeLabel);
    strokeRow->addWidget(strokeSpin);
    layout->addLayout(strokeRow);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(20, 20);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 3px;").arg(m_color.name()));
    layout->addWidget(colorRect);

    return widget;
}

QtNodes::NodeValidationState ArrowNode::validationState() const
{
    return m_validationState;
}

QJsonObject ArrowNode::save() const
{
    QJsonObject obj;
    obj["length"] = m_length;
    obj["strokeWidth"] = m_strokeWidth;
    obj["color"] = m_color.name();
    return obj;
}

void ArrowNode::load(QJsonObject const &obj)
{
    if (obj.contains("length"))      m_length = obj["length"].toDouble();
    if (obj.contains("strokeWidth")) m_strokeWidth = obj["strokeWidth"].toDouble();
    if (obj.contains("color"))       m_color = QColor(obj["color"].toString());
    generateOutput();
}

void ArrowNode::generateOutput()
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
    shape->setShapeType(ShapeLayer::Arrow);
    shape->setShapeWidth(m_length);
    shape->setShapeHeight(m_length);
    shape->setColor(m_color);
    shape->setStrokeColor(m_color);
    shape->setStrokeWidth(m_strokeWidth);
    shape->setName("Arrow Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
