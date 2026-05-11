#pragma once

#include <QtNodes/NodeDelegateModel>
#include <QtNodes/NodeData>
#include <memory>

class TransformNode : public QtNodes::NodeDelegateModel
{
    Q_OBJECT

public:
    TransformNode();
    ~TransformNode() override = default;

    QString name() const override { return "Transform"; }
    QString caption() const override { return "Transform"; }
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

    std::shared_ptr<QtNodes::NodeData> m_input;
    std::shared_ptr<QtNodes::NodeData> m_output;
    QtNodes::NodeValidationState m_validationState;

    double m_x = 0;
    double m_y = 0;
    double m_rotation = 0;
    double m_scaleX = 1.0;
    double m_scaleY = 1.0;
};
