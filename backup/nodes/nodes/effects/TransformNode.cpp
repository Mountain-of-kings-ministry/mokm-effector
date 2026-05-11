#include "TransformNode.h"
#include "../LayerData.hpp"
#include "../../../core/Layer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QDoubleSpinBox>

TransformNode::TransformNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
}

unsigned int TransformNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 1;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType TransformNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void TransformNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(portIndex)
    m_input = nodeData;
    process();
}

std::shared_ptr<QtNodes::NodeData> TransformNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *TransformNode::embeddedWidget()
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

    auto *xSpin = new QDoubleSpinBox();
    xSpin->setRange(-10000, 10000);
    xSpin->setValue(m_x);
    QObject::connect(xSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_x = v; process();
    });
    addRow("X:", xSpin);

    auto *ySpin = new QDoubleSpinBox();
    ySpin->setRange(-10000, 10000);
    ySpin->setValue(m_y);
    QObject::connect(ySpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_y = v; process();
    });
    addRow("Y:", ySpin);

    auto *rotSpin = new QDoubleSpinBox();
    rotSpin->setRange(-360, 360);
    rotSpin->setValue(m_rotation);
    QObject::connect(rotSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_rotation = v; process();
    });
    addRow("R:", rotSpin);

    auto *sxSpin = new QDoubleSpinBox();
    sxSpin->setRange(0.01, 100);
    sxSpin->setSingleStep(0.1);
    sxSpin->setDecimals(2);
    sxSpin->setValue(m_scaleX);
    QObject::connect(sxSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_scaleX = v; process();
    });
    addRow("SX:", sxSpin);

    auto *sySpin = new QDoubleSpinBox();
    sySpin->setRange(0.01, 100);
    sySpin->setSingleStep(0.1);
    sySpin->setDecimals(2);
    sySpin->setValue(m_scaleY);
    QObject::connect(sySpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_scaleY = v; process();
    });
    addRow("SY:", sySpin);

    return widget;
}

QtNodes::NodeValidationState TransformNode::validationState() const
{
    if (!m_input)
        return QtNodes::NodeValidationState(QtNodes::NodeValidationState::State::Warning, "No input connected");
    return m_validationState;
}

QJsonObject TransformNode::save() const
{
    QJsonObject obj;
    obj["x"] = m_x;
    obj["y"] = m_y;
    obj["rotation"] = m_rotation;
    obj["scaleX"] = m_scaleX;
    obj["scaleY"] = m_scaleY;
    return obj;
}

void TransformNode::load(QJsonObject const &obj)
{
    if (obj.contains("x")) m_x = obj["x"].toDouble();
    if (obj.contains("y")) m_y = obj["y"].toDouble();
    if (obj.contains("rotation")) m_rotation = obj["rotation"].toDouble();
    if (obj.contains("scaleX")) m_scaleX = obj["scaleX"].toDouble();
    if (obj.contains("scaleY")) m_scaleY = obj["scaleY"].toDouble();
    process();
}

void TransformNode::process()
{
    if (!m_input) {
        m_output.reset();
        emit dataUpdated(0);
        return;
    }

    auto inData = std::dynamic_pointer_cast<LayerData>(m_input);
    if (!inData || !inData->layer()) {
        m_output.reset();
        emit dataUpdated(0);
        return;
    }

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

    Layer *layer = inData->layer()->clone();
    layer->setX(m_x);
    layer->setY(m_y);
    layer->setRotation(m_rotation);
    layer->setScaleX(m_scaleX);
    layer->setScaleY(m_scaleY);
    layer->setName(inData->layer()->name() + " (transformed)");

    m_output = std::make_shared<LayerData>(layer);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
