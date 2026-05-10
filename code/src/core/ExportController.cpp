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

    for (int i = 0; i < comp->flatLayerCount(); ++i) {
        auto *layer = comp->flatLayerAt(i);
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
    case ShapeLayer::Polygon: {
        painter.setBrush(layer->color());
        painter.setPen(pen);
        QPolygonF poly;
        int sides = layer->sides();
        qreal a = qMin(w, h) / 2.0;
        for (int i = 0; i < sides; ++i) {
            qreal angle = 2.0 * M_PI * i / sides - M_PI_2;
            poly << QPointF(a * cos(angle), a * sin(angle));
        }
        painter.drawPolygon(poly);
        break;
    }
    case ShapeLayer::Star: {
        painter.setBrush(layer->color());
        painter.setPen(pen);
        QPolygonF star;
        int points = layer->sides();
        qreal outer = qMin(w, h) / 2.0;
        qreal inner = outer * 0.4;
        for (int i = 0; i < points * 2; ++i) {
            qreal angle = M_PI * i / points - M_PI_2;
            qreal r2 = (i % 2 == 0) ? outer : inner;
            star << QPointF(r2 * cos(angle), r2 * sin(angle));
        }
        painter.drawPolygon(star);
        break;
    }
    case ShapeLayer::Line: {
        QPen linePen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                     layer->strokeWidth() > 0 ? layer->strokeWidth() : 2);
        painter.setPen(linePen);
        painter.setBrush(Qt::NoBrush);
        qreal len = qMin(w, h) * 0.8;
        painter.drawLine(QPointF(-len / 2, 0), QPointF(len / 2, 0));
        break;
    }
    case ShapeLayer::Arrow: {
        QPen arrowPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                      layer->strokeWidth() > 0 ? layer->strokeWidth() : 2);
        painter.setPen(arrowPen);
        painter.setBrush(layer->color());
        qreal len = qMin(w, h) * 0.7;
        qreal head = qMin(w, h) * 0.25;
        QPolygonF arrow;
        arrow << QPointF(len / 2, 0)
              << QPointF(len / 2 - head, -head * 0.4)
              << QPointF(len / 2 - head, head * 0.4);
        painter.drawLine(QPointF(-len / 2, 0), QPointF(len / 2, 0));
        painter.drawPolygon(arrow);
        break;
    }
    case ShapeLayer::RoundedRect: {
        painter.setBrush(layer->color());
        painter.setPen(pen);
        painter.drawRoundedRect(rect, qMin(r > 0 ? r : 20.0, qMin(w, h) / 2.0),
                                qMin(r > 0 ? r : 20.0, qMin(w, h) / 2.0));
        break;
    }
    case ShapeLayer::Arc: {
        QPen arcPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                    layer->strokeWidth() > 0 ? layer->strokeWidth() : 2);
        painter.setPen(arcPen);
        painter.setBrush(layer->color());
        qreal sa = layer->startAngle() * 16;
        qreal span = layer->spanAngle() * 16;
        painter.drawPie(rect, static_cast<int>(sa), static_cast<int>(span));
        break;
    }
    case ShapeLayer::Grid: {
        QPen gridPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                     layer->strokeWidth() > 0 ? layer->strokeWidth() : 1);
        painter.setPen(gridPen);
        painter.setBrush(Qt::NoBrush);
        int cols = layer->gridColumns();
        int rows = layer->gridRows();
        qreal cellSize = w;
        qreal gap = h;
        qreal totalW = cols * cellSize + (cols - 1) * gap;
        qreal totalH = rows * cellSize + (rows - 1) * gap;
        qreal ox = -totalW / 2.0;
        qreal oy = -totalH / 2.0;
        for (int x = 0; x < cols; ++x) {
            for (int y = 0; y < rows; ++y) {
                qreal cx = ox + x * (cellSize + gap);
                qreal cy = oy + y * (cellSize + gap);
                painter.drawRect(QRectF(cx, cy, cellSize, cellSize));
            }
        }
        break;
    }
    case ShapeLayer::Spiral: {
        QPen spiralPen(layer->strokeColor() == Qt::transparent ? layer->color() : layer->strokeColor(),
                       layer->strokeWidth() > 0 ? layer->strokeWidth() : 1.5);
        painter.setPen(spiralPen);
        painter.setBrush(Qt::NoBrush);
        int turns = layer->turns();
        qreal maxRadius = w;
        qreal spacing = h > 0 ? h : 20;
        int segments = turns * 72;
        QPolygonF spiral;
        for (int i = 0; i <= segments; ++i) {
            qreal t = (qreal)i / segments * turns * 2.0 * M_PI;
            qreal radius = spacing * t / (2.0 * M_PI);
            if (radius > maxRadius) break;
            spiral << QPointF(radius * cos(t), radius * sin(t));
        }
        painter.drawPolyline(spiral);
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
