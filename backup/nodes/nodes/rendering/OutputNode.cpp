#include "OutputNode.h"
#include "../LayerData.hpp"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QLabel>

OutputNode::OutputNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
}

unsigned int OutputNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 1;
    case QtNodes::PortType::Out: return 0;
    default: return 0;
    }
}

QtNodes::NodeDataType OutputNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void OutputNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(portIndex)
    m_input = nodeData;
}

std::shared_ptr<QtNodes::NodeData> OutputNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return nullptr;
}

QWidget *OutputNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(0);

    auto *label = new QLabel("Final Output");
    label->setStyleSheet("color: #3b82f6; font-size: 10px; font-weight: bold;");
    layout->addWidget(label, 0, Qt::AlignCenter);

    return widget;
}

QtNodes::NodeValidationState OutputNode::validationState() const
{
    return m_validationState;
}

QJsonObject OutputNode::save() const
{
    return {};
}

void OutputNode::load(QJsonObject const &)
{
}
