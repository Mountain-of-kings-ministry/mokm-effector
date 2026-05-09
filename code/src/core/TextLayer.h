#ifndef TEXTLAYER_H
#define TEXTLAYER_H

#include "Layer.h"
#include <QColor>
#include <QFont>

class TextLayer : public Layer
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QString fontFamily READ fontFamily WRITE setFontFamily NOTIFY fontChanged)
    Q_PROPERTY(qreal fontSize READ fontSize WRITE setFontSize NOTIFY fontChanged)
    Q_PROPERTY(int fontWeight READ fontWeight WRITE setFontWeight NOTIFY fontChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(int alignment READ alignment WRITE setAlignment NOTIFY alignmentChanged)
public:
    explicit TextLayer(QObject *parent = nullptr);
    ~TextLayer() override = default;

    QString text() const { return m_text; }
    void setText(const QString &text);

    QString fontFamily() const { return m_fontFamily; }
    void setFontFamily(const QString &family);
    qreal fontSize() const { return m_fontSize; }
    void setFontSize(qreal size);
    int fontWeight() const { return m_fontWeight; }
    void setFontWeight(int weight);

    QColor color() const { return m_color; }
    void setColor(const QColor &color);

    int alignment() const { return m_alignment; }
    void setAlignment(int alignment);

    Layer* clone(QObject *parent = nullptr) const override;
    QJsonObject toJson() const override;
    void fromJson(const QJsonObject &obj) override;

signals:
    void textChanged();
    void fontChanged();
    void colorChanged();
    void alignmentChanged();

private:
    QString m_text = "Text";
    QString m_fontFamily = "Sans Serif";
    qreal m_fontSize = 48;
    int m_fontWeight = QFont::Normal;
    QColor m_color = Qt::white;
    int m_alignment = Qt::AlignLeft;
};

#endif
