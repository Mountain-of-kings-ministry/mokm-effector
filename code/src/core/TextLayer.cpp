#include "TextLayer.h"

TextLayer::TextLayer(QObject *parent)
    : Layer(Layer::TextLayer, parent)
{
    setName("Text");
}

void TextLayer::setText(const QString &text)
{
    if (m_text != text) {
        m_text = text;
        emit textChanged();
    }
}

void TextLayer::setFontFamily(const QString &family)
{
    if (m_fontFamily != family) {
        m_fontFamily = family;
        emit fontChanged();
    }
}

void TextLayer::setFontSize(qreal size)
{
    size = qMax(1.0, size);
    if (!qFuzzyCompare(m_fontSize, size)) {
        m_fontSize = size;
        emit fontChanged();
    }
}

void TextLayer::setFontWeight(int weight)
{
    if (m_fontWeight != weight) {
        m_fontWeight = weight;
        emit fontChanged();
    }
}

void TextLayer::setColor(const QColor &color)
{
    if (m_color != color) {
        m_color = color;
        emit colorChanged();
    }
}

void TextLayer::setAlignment(int alignment)
{
    if (m_alignment != alignment) {
        m_alignment = alignment;
        emit alignmentChanged();
    }
}

Layer* TextLayer::clone(QObject *parent) const
{
    auto *t = new TextLayer(parent);
    t->setName(name());
    t->setEnabled(enabled());
    t->setOpacity(opacity());
    t->setVisible(visible());
    t->setX(x());
    t->setY(y());
    t->setRotation(rotation());
    t->setScaleX(scaleX());
    t->setScaleY(scaleY());
    t->setStartFrame(startFrame());
    t->setDuration(duration());
    t->m_text = m_text;
    t->m_fontFamily = m_fontFamily;
    t->m_fontSize = m_fontSize;
    t->m_fontWeight = m_fontWeight;
    t->m_color = m_color;
    t->m_alignment = m_alignment;
    return t;
}

QJsonObject TextLayer::toJson() const
{
    QJsonObject obj = Layer::toJson();
    obj["text"] = m_text;
    obj["fontFamily"] = m_fontFamily;
    obj["fontSize"] = m_fontSize;
    obj["fontWeight"] = m_fontWeight;
    obj["color"] = m_color.name();
    obj["alignment"] = m_alignment;
    return obj;
}

void TextLayer::fromJson(const QJsonObject &obj)
{
    Layer::fromJson(obj);
    setText(obj["text"].toString("Text"));
    setFontFamily(obj["fontFamily"].toString("Sans Serif"));
    setFontSize(obj["fontSize"].toDouble(48));
    setFontWeight(obj["fontWeight"].toInt(400));
    setColor(QColor(obj["color"].toString("#ffffff")));
    setAlignment(obj["alignment"].toInt(0));
}
