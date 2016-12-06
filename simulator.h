#ifndef SIMULATOR_H
#define SIMULATOR_H

#include <QVariantMap>
#include <QVector2D>
#include <QVector3D>

class Simulator: public QObject {
	Q_OBJECT

    // Sub struct
    struct Program {
        QVariantMap events;
        QString source;
    };

    struct Wall {
        QVector2D position;
        QVector3D size;
        QVector3D colo;
    };
    struct Scenario {
        QString name;
        int simTime;
        QVector3D initialPosition;

        QVector2D worldSize;
        Wall *walls;

        bool evaluation_tiles;
        bool evaluation_distance;
        bool evaluation_sensor;
    };
    struct UnitTest {
        Scenario *scenarios;
    };
    struct UserTask {
        int test = 0;
        UnitTest *unitTests;
    };

public slots:
    QString testProgram(QVariantMap userTask, QVariantMap events, QString source);
    //QString testProgram();
    //void SetProgram(QVariantMap events, QString source);
    //void setUserTask(QVariantMap userTask);

private:
    Program program;
    UserTask userTask;
};

#endif // SIMULATOR_H
