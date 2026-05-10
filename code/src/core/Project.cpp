#include "Project.h"
#include "Composition.h"
#include "TimelineLayer.h"
#include "Track.h"
#include "Strip.h"
#include "Layer.h"
#include "ShapeLayer.h"
#include "TextLayer.h"
#include "ImageLayer.h"
#include "AudioLayer.h"
#include "VideoLayer.h"
#include "Keyframe.h"

#include <QFile>
#include <QJsonDocument>
#include <QStandardPaths>
#include <QDir>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
#include <libswresample/swresample.h>
}
#include <QJsonArray>
#include <QJsonObject>
#include <QDir>
#include <QFileInfo>

Project::Project(QObject *parent)
    : QObject(parent)
{
    auto *defaultComp = new Composition(this);
    defaultComp->setName("Main Composition");
    m_compositions.append(defaultComp);
    m_activeComposition = defaultComp;
}

Project::~Project()
{
}

void Project::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Project::setFilePath(const QUrl &path)
{
    if (m_filePath != path) {
        m_filePath = path;
        emit filePathChanged();
    }
}

void Project::setFrameRate(qreal fps)
{
    fps = qMax(1.0, fps);
    if (!qFuzzyCompare(m_frameRate, fps)) {
        m_frameRate = fps;
        emit frameRateChanged();
    }
}

QQmlListProperty<Composition> Project::compositions()
{
    return QQmlListProperty<Composition>(this, &m_compositions);
}

Composition* Project::compositionAt(int index) const
{
    if (index >= 0 && index < m_compositions.size())
        return m_compositions[index];
    return nullptr;
}

void Project::addComposition(Composition *comp)
{
    if (!comp || m_compositions.contains(comp))
        return;
    comp->setParent(this);
    m_compositions.append(comp);
    emit compositionsChanged();
}

void Project::removeComposition(Composition *comp)
{
    if (m_compositions.removeOne(comp)) {
        if (m_activeComposition == comp)
            setActiveComposition(m_compositions.isEmpty() ? nullptr : m_compositions.first());
        emit compositionsChanged();
    }
}

void Project::setActiveComposition(Composition *comp)
{
    if (m_activeComposition != comp) {
        m_activeComposition = comp;
        emit activeCompositionChanged();
    }
}

// ── Assets ──

QQmlListProperty<Layer> Project::assets()
{
    return QQmlListProperty<Layer>(this, &m_assets);
}

Layer* Project::assetAt(int index) const
{
    if (index >= 0 && index < m_assets.size())
        return m_assets[index];
    return nullptr;
}

void Project::addAsset(Layer *layer)
{
    if (!layer || m_assets.contains(layer))
        return;
    layer->setParent(this);
    m_assets.append(layer);
    emit assetsChanged();
}

void Project::removeAsset(Layer *layer)
{
    if (m_assets.removeOne(layer)) {
        emit assetsChanged();
    }
}

// ── Undo / Redo ──

void Project::captureSnapshot()
{
    QJsonObject snap;
    snap["project"] = serializeToJson();
    m_undoStack.append(snap);
    if (m_undoStack.size() > kMaxUndoSteps)
        m_undoStack.removeFirst();
    m_redoStack.clear();
    emit undoChanged();
}

void Project::undo()
{
    if (m_undoStack.isEmpty())
        return;
    // save current state to redo
    QJsonObject currentSnap;
    currentSnap["project"] = serializeToJson();
    m_redoStack.append(currentSnap);
    if (m_redoStack.size() > kMaxUndoSteps)
        m_redoStack.removeFirst();

    QJsonObject snap = m_undoStack.takeLast();
    deserializeFromJson(snap["project"].toString());
    emit undoChanged();
}

void Project::redo()
{
    if (m_redoStack.isEmpty())
        return;
    // save current state to undo
    QJsonObject currentSnap;
    currentSnap["project"] = serializeToJson();
    m_undoStack.append(currentSnap);
    if (m_undoStack.size() > kMaxUndoSteps)
        m_undoStack.removeFirst();

    QJsonObject snap = m_redoStack.takeLast();
    deserializeFromJson(snap["project"].toString());
    emit undoChanged();
}

void Project::clearUndoRedo()
{
    m_undoStack.clear();
    m_redoStack.clear();
    emit undoChanged();
}

// ── JSON Serialization ──

QString Project::serializeToJson() const
{
    QJsonObject root;
    root["name"] = m_name;
    root["version"] = "0.2";
    root["frameRate"] = m_frameRate;

    // Assets
    QJsonArray assetsArr;
    for (auto *asset : m_assets) {
        if (auto *sl = qobject_cast<ShapeLayer*>(asset))
            assetsArr.append(sl->toJson());
        else if (auto *tl = qobject_cast<TextLayer*>(asset))
            assetsArr.append(tl->toJson());
        else if (auto *il = qobject_cast<ImageLayer*>(asset))
            assetsArr.append(il->toJson());
        else if (auto *al = qobject_cast<AudioLayer*>(asset))
            assetsArr.append(al->toJson());
        else if (auto *vl = qobject_cast<VideoLayer*>(asset))
            assetsArr.append(vl->toJson());
    }
    root["assets"] = assetsArr;

    // Compositions
    QJsonArray compsArr;
    for (auto *comp : m_compositions) {
        QJsonObject compObj;
        compObj["name"] = comp->name();
        compObj["width"] = comp->width();
        compObj["height"] = comp->height();
        compObj["duration"] = comp->duration();
        compObj["frameRate"] = comp->frameRate();

        // Layers → Tracks → Strips
        QJsonArray layersArr;
        for (int li = 0; li < comp->layerCount(); ++li) {
            auto *tl = comp->layerAt(li);
            QJsonObject tlObj;
            tlObj["name"] = tl->name();

            QJsonArray tracksArr;
            for (int ti = 0; ti < tl->trackCount(); ++ti) {
                auto *track = tl->trackAt(ti);
                QJsonObject trackObj;
                trackObj["name"] = track->name();

                QJsonArray stripsArr;
                for (int si = 0; si < track->stripCount(); ++si) {
                    auto *strip = track->stripAt(si);
                    QJsonObject stripObj = strip->toJson();
                    stripsArr.append(stripObj);
                }
                trackObj["strips"] = stripsArr;
                tracksArr.append(trackObj);
            }
            tlObj["tracks"] = tracksArr;
            layersArr.append(tlObj);
        }
        compObj["layers"] = layersArr;
        compsArr.append(compObj);
    }
    root["compositions"] = compsArr;

    // Active composition index
    int activeIdx = m_compositions.indexOf(m_activeComposition);
    if (activeIdx >= 0)
        root["activeComposition"] = activeIdx;

    QJsonDocument doc(root);
    return QString::fromUtf8(doc.toJson(QJsonDocument::Indented));
}

bool Project::deserializeFromJson(const QString &json)
{
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
    if (doc.isNull() || !doc.isObject())
        return false;

    QJsonObject root = doc.object();
    setName(root["name"].toString("Untitled"));
    setFrameRate(root["frameRate"].toDouble(30.0));

    // Clear existing
    for (auto *comp : m_compositions)
        comp->deleteLater();
    m_compositions.clear();
    for (auto *asset : m_assets)
        asset->deleteLater();
    m_assets.clear();

    // Load assets
    QJsonArray assetsArr = root["assets"].toArray();
    for (const auto &val : assetsArr) {
        QJsonObject obj = val.toObject();
        Layer *layer = layerFromJson(obj, this);
        if (layer)
            m_assets.append(layer);
    }
    emit assetsChanged();

    // Load compositions
    QJsonArray compsArr = root["compositions"].toArray();
    for (const auto &val : compsArr) {
        QJsonObject compObj = val.toObject();
        auto *comp = new Composition(this);
        comp->setName(compObj["name"].toString("Composition"));
        comp->setWidth(compObj["width"].toInt(1920));
        comp->setHeight(compObj["height"].toInt(1080));
        comp->setDuration(compObj["duration"].toInt(150));
        comp->setFrameRate(compObj["frameRate"].toDouble(30.0));

        // Load layers → tracks → strips
        QJsonArray layersArr = compObj["layers"].toArray();
        for (const auto &lval : layersArr) {
            QJsonObject tlObj = lval.toObject();
            auto *tl = new TimelineLayer(comp);
            tl->setName(tlObj["name"].toString("Layer"));
            comp->addLayer(tl);

            QJsonArray tracksArr = tlObj["tracks"].toArray();
            for (const auto &tval : tracksArr) {
                QJsonObject trackObj = tval.toObject();
                auto *track = tl->addTrack(trackObj["name"].toString());

                QJsonArray stripsArr = trackObj["strips"].toArray();
                for (const auto &sval : stripsArr) {
                    QJsonObject stripObj = sval.toObject();
                    auto *strip = new Strip(track);
                    strip->fromJson(stripObj);
                    // Restore element if present
                    if (stripObj.contains("element")) {
                        QJsonObject elemObj = stripObj["element"].toObject();
                        Layer *elem = layerFromJson(elemObj, strip);
                        if (elem)
                            strip->setElement(elem);
                    }
                    track->addStrip(strip);
                }
            }
        }
        m_compositions.append(comp);
    }
    emit compositionsChanged();

    // Restore active composition
    int activeIdx = root["activeComposition"].toInt(0);
    if (activeIdx >= 0 && activeIdx < m_compositions.size())
        setActiveComposition(m_compositions[activeIdx]);
    else if (!m_compositions.isEmpty())
        setActiveComposition(m_compositions.first());

    return true;
}

bool Project::saveToFile(const QUrl &path)
{
    QString filePath = path.toLocalFile();
    if (filePath.isEmpty())
        return false;

    // Ensure .mokm extension
    if (!filePath.endsWith(".mokm", Qt::CaseInsensitive))
        filePath += ".mokm";

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    file.write(serializeToJson().toUtf8());
    file.close();

    setFilePath(QUrl::fromLocalFile(filePath));
    setName(QFileInfo(filePath).baseName());
    return true;
}

bool Project::loadFromFile(const QUrl &path)
{
    QString filePath = path.toLocalFile();
    if (filePath.isEmpty())
        return false;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QString json = QString::fromUtf8(file.readAll());
    file.close();

    if (!deserializeFromJson(json))
        return false;

    setFilePath(path);
    setName(QFileInfo(filePath).baseName());
    return true;
}

QString Project::extractAudioFromVideo(const QUrl &videoUrl, const QString &outputName)
{
    QString inPath = videoUrl.toLocalFile();
    if (inPath.isEmpty()) return {};

    AVFormatContext *fmtCtx = nullptr;
    if (avformat_open_input(&fmtCtx, inPath.toUtf8().constData(), nullptr, nullptr) != 0)
        return {};
    if (avformat_find_stream_info(fmtCtx, nullptr) < 0) {
        avformat_close_input(&fmtCtx);
        return {};
    }

    int audioIdx = av_find_best_stream(fmtCtx, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    if (audioIdx < 0) {
        avformat_close_input(&fmtCtx);
        return {};
    }

    const AVStream *stream = fmtCtx->streams[audioIdx];
    const AVCodec *codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (!codec) {
        avformat_close_input(&fmtCtx);
        return {};
    }

    AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
    if (!codecCtx || avcodec_parameters_to_context(codecCtx, stream->codecpar) < 0) {
        avcodec_free_context(&codecCtx);
        avformat_close_input(&fmtCtx);
        return {};
    }
    codecCtx->thread_count = 0;
    if (avcodec_open2(codecCtx, codec, nullptr) < 0) {
        avcodec_free_context(&codecCtx);
        avformat_close_input(&fmtCtx);
        return {};
    }

    int sampleRate = codecCtx->sample_rate;
    int channels = codecCtx->ch_layout.nb_channels;
    AVSampleFormat sampleFmt = codecCtx->sample_fmt;

    // Use SWR for format conversion to s16
    SwrContext *swr = nullptr;
    swr_alloc_set_opts2(&swr,
        &codecCtx->ch_layout, AV_SAMPLE_FMT_S16, sampleRate,
        &codecCtx->ch_layout, sampleFmt, sampleRate,
        0, nullptr);

    if (!swr || swr_init(swr) < 0) {
        swr_free(&swr);
        avcodec_free_context(&codecCtx);
        avformat_close_input(&fmtCtx);
        return {};
    }

    QByteArray pcm;
    AVPacket *pkt = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();

    while (av_read_frame(fmtCtx, pkt) >= 0) {
        if (pkt->stream_index != audioIdx) {
            av_packet_unref(pkt);
            continue;
        }
        if (avcodec_send_packet(codecCtx, pkt) < 0) {
            av_packet_unref(pkt);
            continue;
        }
        av_packet_unref(pkt);

        while (avcodec_receive_frame(codecCtx, frame) == 0) {
            uint8_t *s16Data = nullptr;
            int outSamples = swr_get_out_samples(swr, frame->nb_samples);
            av_samples_alloc(&s16Data, nullptr, channels, outSamples, AV_SAMPLE_FMT_S16, 0);
            int converted = swr_convert(swr, &s16Data, outSamples,
                                        (const uint8_t**)frame->data, frame->nb_samples);
            if (converted > 0) {
                int bytes = av_samples_get_buffer_size(nullptr, channels, converted, AV_SAMPLE_FMT_S16, 1);
                pcm.append(reinterpret_cast<const char*>(s16Data), bytes);
            }
            av_freep(&s16Data);
        }
    }

    av_frame_free(&frame);
    av_packet_free(&pkt);
    swr_free(&swr);
    avcodec_free_context(&codecCtx);
    avformat_close_input(&fmtCtx);

    if (pcm.isEmpty()) return {};

    // Write WAV file
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation)
                       + "/mokm_audio";
    QDir().mkpath(cacheDir);
    QString wavPath = cacheDir + "/" + outputName + ".wav";

    QFile wavFile(wavPath);
    if (!wavFile.open(QIODevice::WriteOnly))
        return {};

    auto write32 = [&](quint32 v) {
        wavFile.write(reinterpret_cast<const char*>(&v), 4);
    };
    auto write16 = [&](quint16 v) {
        wavFile.write(reinterpret_cast<const char*>(&v), 2);
    };

    int dataSize = pcm.size();
    int fmtSize = 16;
    int headerSize = 4 + 8 + fmtSize + 8;

    wavFile.write("RIFF", 4);
    write32(headerSize + dataSize);
    wavFile.write("WAVE", 4);
    wavFile.write("fmt ", 4);
    write32(fmtSize);
    write16(1); // PCM
    write16(channels);
    write32(sampleRate);
    write32(sampleRate * channels * 2); // byte rate
    write16(channels * 2); // block align
    write16(16); // bits per sample
    wavFile.write("data", 4);
    write32(dataSize);
    wavFile.write(pcm);
    wavFile.close();

    return QUrl::fromLocalFile(wavPath).toString();
}

// ── Private Helpers ──

QJsonObject Project::layerToJson(Layer *layer) const
{
    if (auto *sl = qobject_cast<ShapeLayer*>(layer))
        return sl->toJson();
    if (auto *tl = qobject_cast<TextLayer*>(layer))
        return tl->toJson();
    if (auto *il = qobject_cast<ImageLayer*>(layer))
        return il->toJson();
    if (auto *al = qobject_cast<AudioLayer*>(layer))
        return al->toJson();
    if (auto *vl = qobject_cast<VideoLayer*>(layer))
        return vl->toJson();
    return layer->toJson();
}

Layer* Project::layerFromJson(const QJsonObject &obj, QObject *parent) const
{
    QString type = obj["type"].toString();
    if (type == "shape") {
        auto *sl = new ShapeLayer(parent);
        sl->fromJson(obj);
        return sl;
    } else if (type == "text") {
        auto *tl = new TextLayer(parent);
        tl->fromJson(obj);
        return tl;
    } else if (type == "image") {
        auto *il = new ImageLayer(parent);
        il->fromJson(obj);
        return il;
    } else if (type == "audio") {
        auto *al = new AudioLayer(parent);
        al->fromJson(obj);
        return al;
    } else if (type == "video") {
        auto *vl = new VideoLayer(parent);
        vl->fromJson(obj);
        return vl;
    }
    return nullptr;
}
