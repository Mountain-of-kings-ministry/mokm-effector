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
