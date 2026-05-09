#ifndef EXPORTCONTROLLER_H
#define EXPORTCONTROLLER_H

#include <QObject>
#include <QSize>
#include <QImage>
#include <QString>

class Composition;
class TimelineModel;
class Layer;
class ShapeLayer;
class TextLayer;

class ExportController : public QObject
{
    Q_OBJECT
public:
    explicit ExportController(QObject *parent = nullptr);
    ~ExportController() override;

    Q_INVOKABLE void exportSequence(Composition *comp, TimelineModel *timeline,
                                    const QString &outputDir, const QString &outputVideo = QString());

    static QImage renderFrame(Composition *comp, int frame);

signals:
    void exportProgress(int frame, int total);
    void exportFinished(bool success, const QString &message);

private:
    static void renderLayer(QImage &image, Layer *layer);
    static void renderShapeLayer(QImage &image, ShapeLayer *layer);
    static void renderTextLayer(QImage &image, TextLayer *layer);
};

#endif
