#ifndef PROJECT_H
#define PROJECT_H

#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlListProperty>
#include <QUrl>
#include <QJsonObject>
#include <QJsonArray>

class Composition;
class Track;
class Layer;

class Project : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QUrl filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(qreal frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(QQmlListProperty<Composition> compositions READ compositions NOTIFY compositionsChanged)
    Q_PROPERTY(Composition* activeComposition READ activeComposition WRITE setActiveComposition NOTIFY activeCompositionChanged)
    Q_PROPERTY(QQmlListProperty<Layer> assets READ assets NOTIFY assetsChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY undoChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY undoChanged)
public:
    explicit Project(QObject *parent = nullptr);
    ~Project() override;

    QString name() const { return m_name; }
    void setName(const QString &name);

    QUrl filePath() const { return m_filePath; }
    void setFilePath(const QUrl &path);

    qreal frameRate() const { return m_frameRate; }
    void setFrameRate(qreal fps);

    QQmlListProperty<Composition> compositions();
    int compositionCount() const { return m_compositions.size(); }
    Composition* compositionAt(int index) const;
    void addComposition(Composition *comp);
    void removeComposition(Composition *comp);

    Composition* activeComposition() const { return m_activeComposition; }
    void setActiveComposition(Composition *comp);

    QQmlListProperty<Layer> assets();
    int assetCount() const { return m_assets.size(); }
    Layer* assetAt(int index) const;
    Q_INVOKABLE void addAsset(Layer *layer);
    Q_INVOKABLE void removeAsset(Layer *layer);

    Q_INVOKABLE void captureSnapshot();
    Q_INVOKABLE void undo();
    Q_INVOKABLE void redo();
    Q_INVOKABLE void clearUndoRedo();
    bool canUndo() const { return !m_undoStack.isEmpty(); }
    bool canRedo() const { return !m_redoStack.isEmpty(); }

    Q_INVOKABLE bool saveToFile(const QUrl &path);
    Q_INVOKABLE bool loadFromFile(const QUrl &path);
    Q_INVOKABLE QString serializeToJson() const;
    Q_INVOKABLE bool deserializeFromJson(const QString &json);

signals:
    void nameChanged();
    void filePathChanged();
    void frameRateChanged();
    void compositionsChanged();
    void activeCompositionChanged();
    void assetsChanged();
    void undoChanged();

private:
    QJsonObject layerToJson(Layer *layer) const;
    Layer* layerFromJson(const QJsonObject &obj, QObject *parent) const;

    QString m_name = "Untitled";
    QUrl m_filePath;
    qreal m_frameRate = 30.0;
    QVector<Composition*> m_compositions;
    Composition *m_activeComposition = nullptr;
    QVector<Layer*> m_assets;

    QVector<QJsonObject> m_undoStack;
    QVector<QJsonObject> m_redoStack;
    static constexpr int kMaxUndoSteps = 5;
};

#endif
