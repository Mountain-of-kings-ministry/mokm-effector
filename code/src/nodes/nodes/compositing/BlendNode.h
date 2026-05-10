#pragma once

#include <QtNodes/NodeDelegateModel>
#include <QtNodes/NodeData>
#include <memory>

class BlendNode : public QtNodes::NodeDelegateModel
{
    Q_OBJECT

public:
    BlendNode();
    ~BlendNode() override = default;

    QString name() const override { return "Blend"; }
    QString caption() const override { return "Blend"; }
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
    void process();

    std::shared_ptr<QtNodes::NodeData> m_inputA;
    std::shared_ptr<QtNodes::NodeData> m_inputB;
    std::shared_ptr<QtNodes::NodeData> m_output;
    QtNodes::NodeValidationState m_validationState;

    int m_blendMode = 0; // 0=Normal,1=Add,2=Multiply,3=Screen,4=Overlay
};
