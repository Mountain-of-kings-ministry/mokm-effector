#include "SpiralNode.h"
#include "../LayerData.hpp"
#include "../../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QSpinBox>
#include <QDoubleSpinBox>

SpiralNode::SpiralNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int SpiralNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType SpiralNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void SpiralNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> SpiralNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *SpiralNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(2);

    auto addRow = [&](const QString &label, QWidget *ctrl) {
        auto *row = new QHBoxLayout();
        auto *lbl = new QLabel(label);
        lbl->setStyleSheet("color: #ccc; font-size: 9px;");
        row->addWidget(lbl);
        row->addWidget(ctrl);
        layout->addLayout(row);
    };

    auto *turnsSpin = new QSpinBox();
    turnsSpin->setRange(1, 100);
    turnsSpin->setValue(m_turns);
    turnsSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    turnsSpin->setMaximumWidth(50);
    QObject::connect(turnsSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this](int v) {
        m_turns = v; generateOutput();
    });
    addRow("T:", turnsSpin);

    auto *sizeSpin = new QDoubleSpinBox();
    sizeSpin->setRange(10, 2000);
    sizeSpin->setValue(m_size);
    sizeSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    sizeSpin->setMaximumWidth(55);
    QObject::connect(sizeSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_size = v; generateOutput();
    });
    addRow("S:", sizeSpin);

    auto *gapSpin = new QDoubleSpinBox();
    gapSpin->setRange(1, 200);
    gapSpin->setValue(m_spacing);
    gapSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    gapSpin->setMaximumWidth(55);
    QObject::connect(gapSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_spacing = v; generateOutput();
    });
    addRow("G:", gapSpin);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(16, 16);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 2px;").arg(m_color.name()));
    layout->addWidget(colorRect, 0, Qt::AlignCenter);

    return widget;
}

QtNodes::NodeValidationState SpiralNode::validationState() const
{
    return m_validationState;
}

QJsonObject SpiralNode::save() const
{
    QJsonObject obj;
    obj["turns"] = m_turns;
    obj["size"] = m_size;
    obj["spacing"] = m_spacing;
    obj["color"] = m_color.name();
    return obj;
}

void SpiralNode::load(QJsonObject const &obj)
{
    if (obj.contains("turns"))   m_turns = obj["turns"].toInt();
    if (obj.contains("size"))    m_size = obj["size"].toDouble();
    if (obj.contains("spacing")) m_spacing = obj["spacing"].toDouble();
    if (obj.contains("color"))   m_color = QColor(obj["color"].toString());
    generateOutput();
}

void SpiralNode::generateOutput()
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
    shape->setShapeType(ShapeLayer::Spiral);
    shape->setShapeWidth(m_size);
    shape->setShapeHeight(m_spacing);
    shape->setTurns(m_turns);
    shape->setColor(m_color);
    shape->setName("Spiral Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
