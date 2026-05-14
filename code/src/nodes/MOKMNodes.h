#pragma once

#include "NodeEditor/BaseNode.h"
#include "NodeEditor/GraphModel.h"
#include <QColor>

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

// ── MOKM Transform Node (media passthrough) ──
class MOKMTransformNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        double x = inputs.value("x", 0.0).toDouble() + inputs.value("offsetX", 0.0).toDouble();
        double y = inputs.value("y", 0.0).toDouble() + inputs.value("offsetY", 0.0).toDouble();
        double rotation = inputs.value("rotation", 0.0).toDouble();
        double scaleX = inputs.value("scaleX", 1.0).toDouble();
        double scaleY = inputs.value("scaleY", 1.0).toDouble();

        out["input"] = inputs.value("input", QVariant());
        out["x"] = x;
        out["y"] = y;
        out["rotation"] = rotation;
        out["scaleX"] = scaleX;
        out["scaleY"] = scaleY;
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Generic, "input", QVariant()},
                {PortType::Float, "x", QVariant(0.0)},
                {PortType::Float, "y", QVariant(0.0)},
                {PortType::Float, "offsetX", QVariant(0.0)},
                {PortType::Float, "offsetY", QVariant(0.0)},
                {PortType::Float, "rotation", QVariant(0.0)},
                {PortType::Float, "scaleX", QVariant(1.0)},
                {PortType::Float, "scaleY", QVariant(1.0)}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Generic, "output", QVariant()},
                {PortType::Float, "x", QVariant()},
                {PortType::Float, "y", QVariant()},
                {PortType::Float, "rotation", QVariant()},
                {PortType::Float, "scaleX", QVariant()},
                {PortType::Float, "scaleY", QVariant()}};
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

// ── MOKM Strip Source Node ──
class MOKMStripSourceNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["output"] = inputs.value("output", QVariant());
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Generic, "output", QVariant()}};
    }

    QString nodeType() const override { return "mokm/strip/source"; }
    QString nodeName() const override { return "Strip Source"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Strip"; }
    QString displayColor() const override { return "#00CEC9"; }
};

// ── MOKM Strip Shape Source Node ──
class MOKMStripShapeSourceNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["output"] = QVariantMap{
            {"shapeType", inputs.value("shapeType", 0)},
            {"shapeWidth", inputs.value("shapeWidth", 200.0)},
            {"shapeHeight", inputs.value("shapeHeight", 200.0)},
            {"color", inputs.value("color", "#eab308")},
            {"strokeColor", inputs.value("strokeColor", "#000000")},
            {"strokeWidth", inputs.value("strokeWidth", 0.0)},
            {"radius", inputs.value("radius", 0.0)},
            {"sides", inputs.value("sides", 5)}
        };
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Generic, "output", QVariant()}};
    }

    QString nodeType() const override { return "mokm/strip/source/shape"; }
    QString nodeName() const override { return "Shape Source"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Strip"; }
    QString displayColor() const override { return "#00CEC9"; }
};

// ── MOKM Strip Image Source Node ──
class MOKMStripImageSourceNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["output"] = QVariantMap{
            {"source", inputs.value("source", QString())},
            {"imageWidth", inputs.value("imageWidth", 0)},
            {"imageHeight", inputs.value("imageHeight", 0)}
        };
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Generic, "output", QVariant()}};
    }

    QString nodeType() const override { return "mokm/strip/source/image"; }
    QString nodeName() const override { return "Image Source"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Strip"; }
    QString displayColor() const override { return "#00CEC9"; }
};

// ── MOKM Strip Audio Source Node ──
class MOKMStripAudioSourceNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["output"] = QVariantMap{
            {"volume", inputs.value("volume", 1.0)},
            {"pan", inputs.value("pan", 0.0)},
            {"mute", inputs.value("mute", false)},
            {"solo", inputs.value("solo", false)}
        };
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Generic, "output", QVariant()}};
    }

    QString nodeType() const override { return "mokm/strip/source/audio"; }
    QString nodeName() const override { return "Audio Source"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Strip"; }
    QString displayColor() const override { return "#00CEC9"; }
};

// ── MOKM Strip Video Source Node ──
class MOKMStripVideoSourceNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["output"] = QVariantMap{
            {"videoWidth", inputs.value("videoWidth", 0)},
            {"videoHeight", inputs.value("videoHeight", 0)},
            {"frameRate", inputs.value("frameRate", 30.0)},
            {"frameCount", inputs.value("frameCount", 0)}
        };
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Generic, "output", QVariant()}};
    }

    QString nodeType() const override { return "mokm/strip/source/video"; }
    QString nodeName() const override { return "Video Source"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Strip"; }
    QString displayColor() const override { return "#00CEC9"; }
};

// ── MOKM Output Render Node ──
class MOKMOutputRenderNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        out["input"] = inputs.value("input", QVariant());
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Generic, "input", QVariant()}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {};
    }

    QString nodeType() const override { return "mokm/output/render"; }
    QString nodeName() const override { return "Render Output"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Strip"; }
    QString displayColor() const override { return "#6C5CE7"; }
};

// ── MOKM Color Blend Node ──
class MOKMColorBlendNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QString mode = inputs.value("mode", "mix").toString();
        double aR = 0, aG = 0, aB = 0, aA = 1;
        double bR = 0, bG = 0, bB = 0, bA = 1;
        double factor = inputs.value("factor", 0.5).toDouble();
        QVariantMap out;

        auto parseColor = [](const QVariant &v, double &r, double &g, double &b, double &a) {
            QColor c(v.toString());
            r = c.redF(); g = c.greenF(); b = c.blueF(); a = c.alphaF();
        };

        parseColor(inputs.value("a", "#000000"), aR, aG, aB, aA);
        parseColor(inputs.value("b", "#000000"), bR, bG, bB, bA);

        double r, g, b;
        if (mode == "multiply") {
            r = aR * bR; g = aG * bG; b = aB * bB;
        } else if (mode == "screen") {
            r = 1.0 - (1.0 - aR) * (1.0 - bR);
            g = 1.0 - (1.0 - aG) * (1.0 - bG);
            b = 1.0 - (1.0 - aB) * (1.0 - bB);
        } else if (mode == "overlay") {
            auto overlay = [](double x, double y) {
                return x < 0.5 ? 2.0 * x * y : 1.0 - 2.0 * (1.0 - x) * (1.0 - y);
            };
            r = overlay(aR, bR); g = overlay(aG, bG); b = overlay(aB, bB);
        } else {
            r = aR * (1.0 - factor) + bR * factor;
            g = aG * (1.0 - factor) + bG * factor;
            b = aB * (1.0 - factor) + bB * factor;
        }

        out["result"] = QColor::fromRgbF(r, g, b, aA).name();
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Color, "a", QVariant("#000000")},
                {PortType::Color, "b", QVariant("#000000")},
                {PortType::Float, "factor", QVariant(0.5)},
                {PortType::String, "mode", QVariant("mix")}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Color, "result", QVariant()}};
    }

    QString nodeType() const override { return "mokm/color/blend"; }
    QString nodeName() const override { return "Color Blend"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Color"; }
    QString displayColor() const override { return "#A29BFE"; }
};

// ── MOKM Color Adjust Node ──
class MOKMColorAdjustNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QColor c(inputs.value("input", "#000000").toString());
        double brightness = inputs.value("brightness", 0.0).toDouble();
        double contrast = inputs.value("contrast", 0.0).toDouble();
        double saturation = inputs.value("saturation", 1.0).toDouble();

        double r = c.redF(), g = c.greenF(), b = c.blueF();

        r += brightness; g += brightness; b += brightness;

        double f = (1.0 - contrast) / 2.0;
        r = r * contrast + f;
        g = g * contrast + f;
        b = b * contrast + f;

        double gray = 0.299 * r + 0.587 * g + 0.114 * b;
        r = gray + saturation * (r - gray);
        g = gray + saturation * (g - gray);
        b = gray + saturation * (b - gray);

        r = qBound(0.0, r, 1.0);
        g = qBound(0.0, g, 1.0);
        b = qBound(0.0, b, 1.0);

        QVariantMap out;
        out["result"] = QColor::fromRgbF(r, g, b).name();
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Color, "input", QVariant("#000000")},
                {PortType::Float, "brightness", QVariant(0.0)},
                {PortType::Float, "contrast", QVariant(0.0)},
                {PortType::Float, "saturation", QVariant(1.0)}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Color, "result", QVariant()}};
    }

    QString nodeType() const override { return "mokm/color/adjust"; }
    QString nodeName() const override { return "Color Adjust"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Color"; }
    QString displayColor() const override { return "#FD79A8"; }
};

// ── MOKM Scale Rotate Node ──
class MOKMScaleRotateNode : public BaseNode {
    Q_OBJECT
public:
    using BaseNode::BaseNode;

    QVariantMap compute(const QVariantMap &inputs) override
    {
        QVariantMap out;
        double x = inputs.value("x", 0.0).toDouble();
        double y = inputs.value("y", 0.0).toDouble();
        double sx = inputs.value("scaleX", 1.0).toDouble();
        double sy = inputs.value("scaleY", 1.0).toDouble();
        double rot = inputs.value("rotation", 0.0).toDouble();
        double px = inputs.value("pivotX", 0.5).toDouble();
        double py = inputs.value("pivotY", 0.5).toDouble();

        double rad = rot * 3.14159265 / 180.0;
        double cosR = qCos(rad);
        double sinR = qSin(rad);

        double tx = x - px;
        double ty = y - py;
        double rx = tx * cosR * sx - ty * sinR * sy + px;
        double ry = tx * sinR * sx + ty * cosR * sy + py;

        out["x"] = rx;
        out["y"] = ry;
        out["scaleX"] = sx;
        out["scaleY"] = sy;
        out["rotation"] = rot;
        return out;
    }

    QList<PortInfo> inputSpec() const override
    {
        return {{PortType::Float, "x", QVariant(0.0)},
                {PortType::Float, "y", QVariant(0.0)},
                {PortType::Float, "scaleX", QVariant(1.0)},
                {PortType::Float, "scaleY", QVariant(1.0)},
                {PortType::Float, "rotation", QVariant(0.0)},
                {PortType::Float, "pivotX", QVariant(0.5)},
                {PortType::Float, "pivotY", QVariant(0.5)}};
    }

    QList<PortInfo> outputSpec() const override
    {
        return {{PortType::Float, "x", QVariant()},
                {PortType::Float, "y", QVariant()},
                {PortType::Float, "scaleX", QVariant()},
                {PortType::Float, "scaleY", QVariant()},
                {PortType::Float, "rotation", QVariant()}};
    }

    QString nodeType() const override { return "mokm/transform/scale-rotate"; }
    QString nodeName() const override { return "Scale Rotate"; }
    QString nodeCategory() const override { return "MOKM"; }
    QString nodeSubCategory() const override { return "Transform"; }
    QString displayColor() const override { return "#E17055"; }
};

// ── Registration ──
inline void registerMOKMNodeTypes(GraphModel *model)
{
    if (!model) return;

    model->registerCategory({"MOKM", "MOKM", QColor("#636E72")});

    auto registerMOKM = [&](const QString &type, auto *instance) {
        using NodeClass = std::decay_t<decltype(*instance)>;
        BaseNode::registerType(type, []() { return new NodeClass(); });

        NodeTypeInfo info;
        for (auto &p : instance->inputSpec())
            info.inputs[p.name] = p;
        for (auto &p : instance->outputSpec())
            info.outputs[p.name] = p;
        info.displayColor = instance->displayColor();
        info.categoryId = instance->nodeCategory();
        info.subCategory = instance->nodeSubCategory();
        info.nodeName = instance->nodeName();
        model->registerNodeType(type, info);
    };

    registerMOKM("mokm/input", new MOKMInputNode());
    registerMOKM("mokm/output", new MOKMOutputNode());
    registerMOKM("mokm/transform", new MOKMTransformNode());
    registerMOKM("mokm/blend", new MOKMBlendNode());
    registerMOKM("mokm/strip/source", new MOKMStripSourceNode());
    registerMOKM("mokm/strip/source/shape", new MOKMStripShapeSourceNode());
    registerMOKM("mokm/strip/source/image", new MOKMStripImageSourceNode());
    registerMOKM("mokm/strip/source/audio", new MOKMStripAudioSourceNode());
    registerMOKM("mokm/strip/source/video", new MOKMStripVideoSourceNode());
    registerMOKM("mokm/output/render", new MOKMOutputRenderNode());
    registerMOKM("mokm/color/blend", new MOKMColorBlendNode());
    registerMOKM("mokm/color/adjust", new MOKMColorAdjustNode());
    registerMOKM("mokm/transform/scale-rotate", new MOKMScaleRotateNode());
}

} // namespace NodeEditor
