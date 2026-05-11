#include "GridNode.h"
#include "../LayerData.hpp"
#include "../../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QSpinBox>
#include <QDoubleSpinBox>

GridNode::GridNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int GridNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType GridNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void GridNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> GridNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *GridNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(2);

    auto addRow = [&](const QString &label, QWidget *ctrl) {
        auto *row = new QHBoxLayout();
        auto *lbl = new QLabel(label);
        lbl->setStyleSheet("color: #ccc; font-size: 9px;");
        row->addWidget(lbl);
        row->addWidget(ctrl);
        layout->addLayout(row);
    };

    auto *colSpin = new QSpinBox();
    colSpin->setRange(1, 100);
    colSpin->setValue(m_columns);
    colSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    colSpin->setMaximumWidth(50);
    QObject::connect(colSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this](int v) {
        m_columns = v; generateOutput();
    });
    addRow("C:", colSpin);

    auto *rowSpin = new QSpinBox();
    rowSpin->setRange(1, 100);
    rowSpin->setValue(m_rows);
    rowSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    rowSpin->setMaximumWidth(50);
    QObject::connect(rowSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this](int v) {
        m_rows = v; generateOutput();
    });
    addRow("R:", rowSpin);

    auto *sizeSpin = new QDoubleSpinBox();
    sizeSpin->setRange(5, 500);
    sizeSpin->setValue(m_cellSize);
    sizeSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    sizeSpin->setMaximumWidth(55);
    QObject::connect(sizeSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_cellSize = v; generateOutput();
    });
    addRow("S:", sizeSpin);

    auto *gapSpin = new QDoubleSpinBox();
    gapSpin->setRange(0, 200);
    gapSpin->setValue(m_spacing);
    gapSpin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
    gapSpin->setMaximumWidth(55);
    QObject::connect(gapSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_spacing = v; generateOutput();
    });
    addRow("G:", gapSpin);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(16, 16);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 2px;").arg(m_color.name()));
    layout->addWidget(colorRect, 0, Qt::AlignCenter);

    return widget;
}

QtNodes::NodeValidationState GridNode::validationState() const
{
    return m_validationState;
}

QJsonObject GridNode::save() const
{
    QJsonObject obj;
    obj["columns"] = m_columns;
    obj["rows"] = m_rows;
    obj["cellSize"] = m_cellSize;
    obj["spacing"] = m_spacing;
    obj["color"] = m_color.name();
    return obj;
}

void GridNode::load(QJsonObject const &obj)
{
    if (obj.contains("columns"))  m_columns = obj["columns"].toInt();
    if (obj.contains("rows"))     m_rows = obj["rows"].toInt();
    if (obj.contains("cellSize")) m_cellSize = obj["cellSize"].toDouble();
    if (obj.contains("spacing"))  m_spacing = obj["spacing"].toDouble();
    if (obj.contains("color"))    m_color = QColor(obj["color"].toString());
    generateOutput();
}

void GridNode::generateOutput()
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

    auto *shape = new ShapeLayer();
    shape->setShapeType(ShapeLayer::Grid);
    shape->setGridColumns(m_columns);
    shape->setGridRows(m_rows);
    shape->setShapeWidth(m_cellSize);
    shape->setShapeHeight(m_spacing);
    shape->setColor(m_color);
    shape->setName("Grid Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
