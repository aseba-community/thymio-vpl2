#ifndef SIMULATOR_H
#define SIMULATOR_H

#include <QVariantMap>
#include <QVector>
#include <QVector2D>
#include <QVector3D>

class Simulator: public QObject {
	Q_OBJECT

    // Sub struct
    struct Program {
        Program() : events(), source() {}

        QVariantMap events;
        QString source;
    };

    struct Wall {
        Wall() : position(0,0), size(0,0,0), color(16,16,16) {}

        QVector2D position;
        QVector3D size;
        QVector3D color;
    };
    struct Scenario {
        Scenario() : name("newScenario"), simTime(0), initialPosition(20,20,0),
                     worldSize(40,40), walls(NULL), evaluationMetric("noMetric") {}

        QString name;
        int simTime;
        QVector3D initialPosition;

        QVector2D worldSize;
        QVector<Wall> walls;
        QString evaluationMetric;
        QVector<QVector2D> tiles;
        QVector<int> tileScores;
    };
    struct UnitTest {
        UnitTest() : scenarios(NULL), combinationRule("mean") {}

        QVector<Scenario> scenarios;
        QString combinationRule;
    };
    struct UserTask {
        UserTask() : unitTests(NULL) {}

        QVector<UnitTest> unitTests;
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
