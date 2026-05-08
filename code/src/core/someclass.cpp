#include "someclass.h"
#include "QDebug"
someClass::someClass(QObject *parent)
    : QObject{parent},
      m_manager("1234567")
{
}

QString someClass::manager()
{
    return m_manager;
}

QString someClass::getManagerState()
{
    return m_manager;
}

void someClass::logToConsole()
{
    qDebug() << "am loging to console";
}

void someClass::setManager(QString newVar)
{
    if (newVar != m_manager)
    {
        m_manager = newVar;
        emit managerChanged();
    }
}
