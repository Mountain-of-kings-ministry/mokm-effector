#include "TextNode.h"
#include "LayerData.hpp"
#include "../../core/TextLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QLabel>

TextNode::TextNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int TextNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType TextNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void TextNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> TextNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *TextNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(4, 4, 4, 4);
    layout->setSpacing(4);

    auto *textLabel = new QLabel(m_text);
    textLabel->setStyleSheet("color: #ccc; font-size: 10px;");
    textLabel->setWordWrap(true);
    layout->addWidget(textLabel);

    return widget;
}

QtNodes::NodeValidationState TextNode::validationState() const
{
    return m_validationState;
}

QJsonObject TextNode::save() const
{
    QJsonObject obj;
    obj["text"] = m_text;
    obj["fontFamily"] = m_fontFamily;
    obj["fontSize"] = m_fontSize;
    obj["color"] = m_color.name();
    return obj;
}

void TextNode::load(QJsonObject const &obj)
{
    if (obj.contains("text"))       m_text = obj["text"].toString();
    if (obj.contains("fontFamily")) m_fontFamily = obj["fontFamily"].toString();
    if (obj.contains("fontSize"))   m_fontSize = obj["fontSize"].toDouble();
    if (obj.contains("color"))      m_color = QColor(obj["color"].toString());
    generateOutput();
}

void TextNode::generateOutput()
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

    auto *textLayer = new TextLayer();
    textLayer->setText(m_text);
    textLayer->setFontFamily(m_fontFamily);
    textLayer->setFontSize(m_fontSize);
    textLayer->setColor(m_color);
    textLayer->setName("Text Output");

    m_output = std::make_shared<LayerData>(textLayer);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
