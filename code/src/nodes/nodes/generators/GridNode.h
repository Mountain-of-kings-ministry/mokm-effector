#pragma once

#include <QtNodes/NodeDelegateModel>
#include <QtNodes/NodeData>
#include <memory>

class GridNode : public QtNodes::NodeDelegateModel
{
    Q_OBJECT

public:
    GridNode();
    ~GridNode() override = default;

    QString name() const override { return "Grid"; }
    QString caption() const override { return "Grid"; }
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

    int m_columns = 5;
    int m_rows = 5;
    double m_cellSize = 40.0;
    double m_spacing = 10.0;
    QColor m_color = QColor(255, 170, 0);
};
