#include "BlurNode.h"
#include "LayerData.hpp"
#include "../../core/Layer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QDoubleSpinBox>

BlurNode::BlurNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
}

unsigned int BlurNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 1;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType BlurNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void BlurNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(portIndex)
    m_input = nodeData;
    process();
}

std::shared_ptr<QtNodes::NodeData> BlurNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *BlurNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(4, 4, 4, 4);
    layout->setSpacing(4);

    auto *blurRow = new QHBoxLayout();
    auto *blurLabel = new QLabel("Radius:");
    blurLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    auto *blurSpin = new QDoubleSpinBox();
    blurSpin->setRange(0, 100);
    blurSpin->setDecimals(1);
    blurSpin->setSingleStep(1);
    blurSpin->setValue(m_blurRadius);
    blurSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    QObject::connect(blurSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_blurRadius = v;
        process();
    });
    blurRow->addWidget(blurLabel);
    blurRow->addWidget(blurSpin);
    layout->addLayout(blurRow);

    auto *info = new QLabel("Blur effect node");
    info->setStyleSheet("color: #888; font-size: 9px;");
    layout->addWidget(info);

    return widget;
}

QtNodes::NodeValidationState BlurNode::validationState() const
{
    if (m_blurRadius <= 0)
        return QtNodes::NodeValidationState(QtNodes::NodeValidationState::State::Warning, "Blur radius is 0");
    if (!m_input)
        return QtNodes::NodeValidationState(QtNodes::NodeValidationState::State::Warning, "No input connected");
    return m_validationState;
}

QJsonObject BlurNode::save() const
{
    QJsonObject obj;
    obj["blurRadius"] = m_blurRadius;
    return obj;
}

void BlurNode::load(QJsonObject const &obj)
{
    if (obj.contains("blurRadius")) m_blurRadius = obj["blurRadius"].toDouble();
    process();
}

void BlurNode::process()
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

    // Delete old output
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

    // Clone the input layer and set blur radius
    Layer *layer = inData->layer()->clone();
    layer->setBlurRadius(m_blurRadius);
    layer->setName(inData->layer()->name() + " (blurred)");

    m_output = std::make_shared<LayerData>(layer);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
