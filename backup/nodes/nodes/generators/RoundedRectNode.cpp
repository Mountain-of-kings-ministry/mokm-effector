#include "RoundedRectNode.h"
#include "../LayerData.hpp"
#include "../../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QDoubleSpinBox>

RoundedRectNode::RoundedRectNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int RoundedRectNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType RoundedRectNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void RoundedRectNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> RoundedRectNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *RoundedRectNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(2);

    auto addRow = [&](const QString &label, QDoubleSpinBox *spin) {
        auto *row = new QHBoxLayout();
        auto *lbl = new QLabel(label);
        lbl->setStyleSheet("color: #ccc; font-size: 9px;");
        spin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
        spin->setMaximumWidth(55);
        row->addWidget(lbl);
        row->addWidget(spin);
        layout->addLayout(row);
    };

    auto *wSpin = new QDoubleSpinBox();
    wSpin->setRange(10, 5000);
    wSpin->setValue(m_width);
    QObject::connect(wSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_width = v; generateOutput();
    });
    addRow("W:", wSpin);

    auto *hSpin = new QDoubleSpinBox();
    hSpin->setRange(10, 5000);
    hSpin->setValue(m_height);
    QObject::connect(hSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_height = v; generateOutput();
    });
    addRow("H:", hSpin);

    auto *rSpin = new QDoubleSpinBox();
    rSpin->setRange(0, 500);
    rSpin->setValue(m_radius);
    QObject::connect(rSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_radius = v; generateOutput();
    });
    addRow("R:", rSpin);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(16, 16);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 2px;").arg(m_color.name()));
    layout->addWidget(colorRect, 0, Qt::AlignCenter);

    return widget;
}

QtNodes::NodeValidationState RoundedRectNode::validationState() const
{
    return m_validationState;
}

QJsonObject RoundedRectNode::save() const
{
    QJsonObject obj;
    obj["width"] = m_width;
    obj["height"] = m_height;
    obj["radius"] = m_radius;
    obj["color"] = m_color.name();
    return obj;
}

void RoundedRectNode::load(QJsonObject const &obj)
{
    if (obj.contains("width"))  m_width = obj["width"].toDouble();
    if (obj.contains("height")) m_height = obj["height"].toDouble();
    if (obj.contains("radius")) m_radius = obj["radius"].toDouble();
    if (obj.contains("color"))  m_color = QColor(obj["color"].toString());
    generateOutput();
}

void RoundedRectNode::generateOutput()
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
    shape->setShapeType(ShapeLayer::RoundedRect);
    shape->setShapeWidth(m_width);
    shape->setShapeHeight(m_height);
    shape->setRadius(m_radius);
    shape->setColor(m_color);
    shape->setName("RoundedRect Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
