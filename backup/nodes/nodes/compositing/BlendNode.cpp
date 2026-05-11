#include "BlendNode.h"
#include "../LayerData.hpp"
#include "../../../core/Layer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QComboBox>

BlendNode::BlendNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
}

unsigned int BlendNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 2; // A (background), B (foreground)
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType BlendNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void BlendNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    if (portIndex == 0)
        m_inputA = nodeData;
    else if (portIndex == 1)
        m_inputB = nodeData;
    process();
}

std::shared_ptr<QtNodes::NodeData> BlendNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *BlendNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(2);

    auto *row = new QHBoxLayout();
    auto *label = new QLabel("Mode:");
    label->setStyleSheet("color: #ccc; font-size: 9px;");
    auto *combo = new QComboBox();
    combo->addItems({"Normal", "Add", "Multiply", "Screen", "Overlay"});
    combo->setCurrentIndex(m_blendMode);
    combo->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    combo->setMaximumWidth(80);
    QObject::connect(combo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int idx) {
        m_blendMode = idx;
        process();
    });
    row->addWidget(label);
    row->addWidget(combo);
    layout->addLayout(row);

    return widget;
}

QtNodes::NodeValidationState BlendNode::validationState() const
{
    if (!m_inputA)
        return QtNodes::NodeValidationState(QtNodes::NodeValidationState::State::Warning, "No background (A) input");
    if (!m_inputB)
        return QtNodes::NodeValidationState(QtNodes::NodeValidationState::State::Warning, "No foreground (B) input");
    return m_validationState;
}

QJsonObject BlendNode::save() const
{
    QJsonObject obj;
    obj["blendMode"] = m_blendMode;
    return obj;
}

void BlendNode::load(QJsonObject const &obj)
{
    if (obj.contains("blendMode")) m_blendMode = obj["blendMode"].toInt();
    process();
}

void BlendNode::process()
{
    if (!m_inputA || !m_inputB) {
        m_output.reset();
        emit dataUpdated(0);
        return;
    }

    auto inA = std::dynamic_pointer_cast<LayerData>(m_inputA);
    auto inB = std::dynamic_pointer_cast<LayerData>(m_inputB);
    if (!inA || !inA->layer() || !inB || !inB->layer()) {
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

    // Clone input A (background) and set blend mode, store input B as child
    Layer *layer = inA->layer()->clone();
    layer->setBlendMode(m_blendMode);
    layer->setName(inA->layer()->name() + " (blend)");

    m_output = std::make_shared<LayerData>(layer);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
