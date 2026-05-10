#pragma once

#include <QtNodes/NodeData>
#include "../../core/Layer.h"

class LayerData : public QtNodes::NodeData
{
public:
    LayerData(Layer *layer = nullptr)
        : m_layer(layer)
    {}

    QtNodes::NodeDataType type() const override
    {
        return { "layer", "Layer" };
    }

    Layer* layer() const { return m_layer; }
    void setLayer(Layer *l) { m_layer = l; }

private:
    Layer *m_layer = nullptr;
};
