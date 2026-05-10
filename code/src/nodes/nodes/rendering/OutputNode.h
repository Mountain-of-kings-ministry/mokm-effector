#pragma once

#include <QtNodes/NodeDelegateModel>
#include <QtNodes/NodeData>
#include <memory>

class OutputNode : public QtNodes::NodeDelegateModel
{
    Q_OBJECT

public:
    OutputNode();
    ~OutputNode() override = default;

    QString name() const override { return "Output"; }
    QString caption() const override { return "Output"; }
    bool captionVisible() const override { return true; }

    unsigned int nPorts(QtNodes::PortType portType) const override;
    QtNodes::NodeDataType dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const override;

    void setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex) override;
    std::shared_ptr<QtNodes::NodeData> outData(QtNodes::PortIndex port) override;

    QWidget *embeddedWidget() override;

    QtNodes::NodeValidationState validationState() const override;

    QJsonObject save() const override;
    void load(QJsonObject const &) override;

    std::shared_ptr<QtNodes::NodeData> inputData() const { return m_input; }

private:
    std::shared_ptr<QtNodes::NodeData> m_input;
    QtNodes::NodeValidationState m_validationState;
};
