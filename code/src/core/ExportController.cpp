#include "ExportController.h"
#include "Composition.h"
#include "Layer.h"
#include "ShapeLayer.h"
#include "TextLayer.h"
#include "../timeline/TimelineModel.h"

#include <QPainter>
#include <QProcess>
#include <QDir>
#include <QFontMetrics>

ExportController::ExportController(QObject *parent)
    : QObject(parent)
{
}

ExportController::~ExportController() = default;

QImage ExportController::renderFrame(Composition *comp, int frame)
{
    int w = comp->width();
    int h = comp->height();
    QImage image(w, h, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);

    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing, true);

    int checkSize = 16;
    QColor c1(40, 40, 40);
    QColor c2(50, 50, 50);
    for (int y = 0; y < h; y += checkSize) {
        for (int x = 0; x < w; x += checkSize) {
            painter.fillRect(x, y, checkSize, checkSize,
                             ((x / checkSize + y / checkSize) % 2) ? c1 : c2);
        }
    }
    painter.fillRect(0, 0, w, h, QColor(18, 18, 18));

    for (int i = 0; i < comp->layerCount(); ++i) {
        auto *layer = comp->layerAt(i);
        if (!layer || !layer->enabled() || !layer->visible())
            continue;
        if (frame < layer->startFrame() || frame >= layer->startFrame() + layer->duration())
            continue;

        painter.save();
        painter.setOpacity(layer->opacity());
        painter.translate(layer->x(), layer->y());
        painter.translate(w / 2.0, h / 2.0);
        painter.rotate(layer->rotation());
        painter.scale(layer->scaleX(), layer->scaleY());
        painter.translate(-w / 2.0, -h / 2.0);

        if (layer->type() == Layer::ShapeLayer)
            renderShapeLayer(painter, qobject_cast<ShapeLayer*>(layer));
        else if (layer->type() == Layer::TextLayer)
            renderTextLayer(painter, qobject_cast<TextLayer*>(layer));

        painter.restore();
    }

    painter.end();
    return image;
}

void ExportController::renderShapeLayer(QPainter &painter, ShapeLayer *layer)
{
    if (!layer) return;

    qreal w = layer->shapeWidth();
    qreal h = layer->shapeHeight();
    qreal r = layer->radius();
    QRectF rect(-w / 2.0, -h / 2.0, w, h);

    QPen pen(layer->strokeColor(), layer->strokeWidth());

    switch (layer->shapeType()) {
    case ShapeLayer::Rectangle:
        painter.setBrush(layer->color());
        painter.setPen(pen);
        if (r > 0)
            painter.drawRoundedRect(rect, r, r);
        else
            painter.drawRect(rect);
        break;
    case ShapeLayer::Ellipse:
        painter.setBrush(layer->color());
        painter.setPen(pen);
        painter.drawEllipse(rect);
        break;
    case ShapeLayer::Circle:
        painter.setBrush(layer->color());
        painter.setPen(pen);
        painter.drawEllipse(QRectF(-qMin(w, h) / 2.0, -qMin(w, h) / 2.0, qMin(w, h), qMin(w, h)));
        break;
    case ShapeLayer::Triangle: {
        painter.setBrush(layer->color());
        painter.setPen(pen);
        QPolygonF tri;
        tri << QPointF(0, -h / 2.0) << QPointF(-w / 2.0, h / 2.0) << QPointF(w / 2.0, h / 2.0);
        painter.drawPolygon(tri);
        break;
    }
    }
}

void ExportController::renderTextLayer(QPainter &painter, TextLayer *layer)
{
    if (!layer) return;

    QFont font(layer->fontFamily(), (int)layer->fontSize());
    font.setWeight(static_cast<QFont::Weight>(layer->fontWeight()));

    painter.setFont(font);
    painter.setPen(layer->color());

    QRectF textRect(-500, -200, 1000, 400);
    painter.drawText(textRect, layer->alignment() | Qt::TextWordWrap, layer->text());
}

void ExportController::exportSequence(Composition *comp, TimelineModel *timeline,
                                      const QString &outputDir, const QString &outputVideo)
{
    if (!comp || !timeline) {
        emit exportFinished(false, "No composition or timeline provided");
        return;
    }

    QDir dir(outputDir);
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            emit exportFinished(false, "Failed to create output directory");
            return;
        }
    }

    int totalFrames = comp->duration();
    int oldFrame = timeline->currentFrame();

    for (int frame = 0; frame < totalFrames; ++frame) {
        timeline->setCurrentFrame(frame);
        QImage img = renderFrame(comp, frame);
        QString path = dir.filePath(QString("frame_%1.png")
                        .arg(frame, 5, 10, QChar('0')));
        img.save(path);
        emit exportProgress(frame + 1, totalFrames);
    }

    timeline->setCurrentFrame(oldFrame);

    if (!outputVideo.isEmpty()) {
        QProcess ffmpeg;
        QStringList args;
        args << "-y"
             << "-framerate" << QString::number((int)comp->frameRate())
             << "-i" << dir.filePath("frame_%05d.png")
             << "-c:v" << "libx264"
             << "-pix_fmt" << "yuv420p"
             << outputVideo;

        ffmpeg.start("ffmpeg", args);
        ffmpeg.waitForFinished(-1);

        if (ffmpeg.exitCode() != 0) {
            emit exportFinished(false, "FFmpeg encoding failed: " + ffmpeg.readAllStandardError());
            return;
        }
    }

    emit exportFinished(true, "Export completed successfully");
}
