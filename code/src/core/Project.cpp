#include "Project.h"
#include "Composition.h"

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


