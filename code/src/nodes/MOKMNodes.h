#pragma once

#include "NodeEditor/BaseNode.h"

namespace NodeEditor {

// ── MOKM Input Node ──
class MOKMInputNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["value"] = inputs.value("value", 0.0);
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Float, "value", QVariant(0.0)}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Float, "value", QVariant()}};
    }

    QString nodeType() const override { return "mokm/input"; }
    QString nodeName() const override { return "Input"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Basic"; }
    QString displayColor() const override { return "#4CDF8B"; }
};

// ── MOKM Output Node ──
class MOKMOutputNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["display"] = inputs.value("value", 0.0);
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Float, "value", QVariant(0.0)}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Float, "display", QVariant()}};
    }

    QString nodeType() const override { return "mokm/output"; }
    QString nodeName() const override { return "Output"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Basic"; }
    QString displayColor() const override { return "#FF6B6B"; }
};

// ── MOKM Transform Node ──
class MOKMTransformNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["x"] = inputs.value("x", 0.0).toDouble() + inputs.value("offsetX", 0.0).toDouble();
        out["y"] = inputs.value("y", 0.0).toDouble() + inputs.value("offsetY", 0.0).toDouble();
        out["rotation"] = inputs.value("rotation", 0.0);
        out["scale"] = inputs.value("scale", 1.0);
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Float, "x", QVariant(0.0)},
                {PortType::Float, "y", QVariant(0.0)},
                {PortType::Float, "offsetX", QVariant(0.0)},
                {PortType::Float, "offsetY", QVariant(0.0)},
                {PortType::Float, "rotation", QVariant(0.0)},
                {PortType::Float, "scale", QVariant(1.0)}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Float, "x", QVariant()},
                {PortType::Float, "y", QVariant()},
                {PortType::Float, "rotation", QVariant()},
                {PortType::Float, "scale", QVariant()}};
    }

    QString nodeType() const override { return "mokm/transform"; }
    QString nodeName() const override { return "Transform"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Transform"; }
    QString displayColor() const override { return "#4A9EFF"; }
};

// ── MOKM Blend Node ──
class MOKMBlendNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        double a = inputs.value("a", 0.0).toDouble();
        double b = inputs.value("b", 0.0).toDouble();
        double factor = inputs.value("factor", 0.5).toDouble();
        QVariantMap out;
        out["result"] = a * (1.0 - factor) + b * factor;
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Float, "a", QVariant(0.0)},
                {PortType::Float, "b", QVariant(0.0)},
                {PortType::Float, "factor", QVariant(0.5)}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Float, "result", QVariant()}};
    }

    QString nodeType() const override { return "mokm/blend"; }
    QString nodeName() const override { return "Blend"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Blend"; }
    QString displayColor() const override { return "#FF9F43"; }
};

} // namespace NodeEditor
