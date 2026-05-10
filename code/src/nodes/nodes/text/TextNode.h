#pragma once

#include <QtNodes/NodeDelegateModel>
#include <QtNodes/NodeData>
#include <memory>

class TextNode : public QtNodes::NodeDelegateModel
{
    Q_OBJECT

public:
    TextNode();
    ~TextNode() override = default;

    QString name() const override { return "Text"; }
    QString caption() const override { return "Text"; }
    bool captionVisible() const override { return true; }

    unsigned int nPorts(QtNodes::PortType portType) const override;
    QtNodes::NodeDataType dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const override;

    void setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex) override;
    std::shared_ptr<QtNodes::NodeData> outData(QtNodes::PortIndex port) override;

    QWidget *embeddedWidget() override;

    QtNodes::NodeValidationState validationState() const override;

    QJsonObject save() const override;
    void load(QJsonObject const &) override;

private:
    void generateOutput();

    std::shared_ptr<QtNodes::NodeData> m_output;
    QtNodes::NodeValidationState m_validationState;

    QString m_text = "Hello World";
    QString m_fontFamily = "Sans Serif";
    double m_fontSize = 48.0;
    QColor m_color = Qt::white;
};
