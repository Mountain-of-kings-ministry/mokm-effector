#ifndef SOMECLASS_H
#define SOMECLASS_H

#include <QObject>

class someClass : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString manager READ manager WRITE setManager NOTIFY managerChanged FINAL)
public:
    explicit someClass(QObject *parent = nullptr);
    // main state == default
    QString manager();

private:
    // for state managment and notification
    QString m_manager;

public slots:
    void logToConsole();
    QString getManagerState();
    // set state
    void setManager(QString);

signals:
    // notify on state change
    void managerChanged();
};

#endif // SOMECLASS_H
