#include "ArcNode.h"
#include "../LayerData.hpp"
#include "../../../core/ShapeLayer.h"

#include <QJsonObject>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QDoubleSpinBox>

ArcNode::ArcNode()
    : m_validationState{QtNodes::NodeValidationState::State::Valid, ""}
{
    generateOutput();
}

unsigned int ArcNode::nPorts(QtNodes::PortType portType) const
{
    switch (portType) {
    case QtNodes::PortType::In:  return 0;
    case QtNodes::PortType::Out: return 1;
    default: return 0;
    }
}

QtNodes::NodeDataType ArcNode::dataType(QtNodes::PortType portType, QtNodes::PortIndex portIndex) const
{
    Q_UNUSED(portType)
    Q_UNUSED(portIndex)
    return { "layer", "Layer" };
}

void ArcNode::setInData(std::shared_ptr<QtNodes::NodeData> nodeData, QtNodes::PortIndex portIndex)
{
    Q_UNUSED(nodeData)
    Q_UNUSED(portIndex)
}

std::shared_ptr<QtNodes::NodeData> ArcNode::outData(QtNodes::PortIndex port)
{
    Q_UNUSED(port)
    return m_output;
}

QWidget *ArcNode::embeddedWidget()
{
    auto *widget = new QWidget();
    auto *layout = new QVBoxLayout(widget);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(2);

    auto addRow = [&](const QString &label, QDoubleSpinBox *spin) {
        auto *row = new QHBoxLayout();
        auto *lbl = new QLabel(label);
        lbl->setStyleSheet("color: #ccc; font-size: 9px;");
        spin->setStyleSheet("color: #fff; background: #333; border: 1px solid #555;");
        spin->setMaximumWidth(55);
        row->addWidget(lbl);
        row->addWidget(spin);
        layout->addLayout(row);
    };

    auto *wSpin = new QDoubleSpinBox();
    wSpin->setRange(10, 5000);
    wSpin->setValue(m_width);
    QObject::connect(wSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_width = v; generateOutput();
    });
    addRow("W:", wSpin);

    auto *hSpin = new QDoubleSpinBox();
    hSpin->setRange(10, 5000);
    hSpin->setValue(m_height);
    QObject::connect(hSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_height = v; generateOutput();
    });
    addRow("H:", hSpin);

    auto *saSpin = new QDoubleSpinBox();
    saSpin->setRange(0, 360);
    saSpin->setValue(m_startAngle);
    saSpin->setSuffix("\u00B0");
    QObject::connect(saSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_startAngle = v; generateOutput();
    });
    addRow("S:", saSpin);

    auto *spanSpin = new QDoubleSpinBox();
    spanSpin->setRange(1, 360);
    spanSpin->setValue(m_spanAngle);
    spanSpin->setSuffix("\u00B0");
    QObject::connect(spanSpin, QOverload<double>::of(&QDoubleSpinBox::valueChanged), this, [this](double v) {
        m_spanAngle = v; generateOutput();
    });
    addRow("Sp:", spanSpin);

    auto *colorRect = new QWidget();
    colorRect->setFixedSize(16, 16);
    colorRect->setStyleSheet(QString("background-color: %1; border-radius: 2px;").arg(m_color.name()));
    layout->addWidget(colorRect, 0, Qt::AlignCenter);

    return widget;
}

QtNodes::NodeValidationState ArcNode::validationState() const
{
    return m_validationState;
}

QJsonObject ArcNode::save() const
{
    QJsonObject obj;
    obj["width"] = m_width;
    obj["height"] = m_height;
    obj["startAngle"] = m_startAngle;
    obj["spanAngle"] = m_spanAngle;
    obj["color"] = m_color.name();
    return obj;
}

void ArcNode::load(QJsonObject const &obj)
{
    if (obj.contains("width"))      m_width = obj["width"].toDouble();
    if (obj.contains("height"))     m_height = obj["height"].toDouble();
    if (obj.contains("startAngle")) m_startAngle = obj["startAngle"].toDouble();
    if (obj.contains("spanAngle"))  m_spanAngle = obj["spanAngle"].toDouble();
    if (obj.contains("color"))      m_color = QColor(obj["color"].toString());
    generateOutput();
}

void ArcNode::generateOutput()
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
    shape->setShapeType(ShapeLayer::Arc);
    shape->setShapeWidth(m_width);
    shape->setShapeHeight(m_height);
    shape->setStartAngle(m_startAngle);
    shape->setSpanAngle(m_spanAngle);
    shape->setColor(m_color);
    shape->setName("Arc Output");

    m_output = std::make_shared<LayerData>(shape);
    m_validationState._state = QtNodes::NodeValidationState::State::Valid;
    m_validationState._stateMessage = "Ready";

    emit dataUpdated(0);
}
