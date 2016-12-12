#ifndef SIMULATOR_H
#define SIMULATOR_H

#include <enki/enki/PhysicalEngine.h>
#include <aseba.h>

#include <QVariantMap>
#include <QVector>
#include <QVector2D>
#include <QVector3D>

class Simulator: public QObject {
	Q_OBJECT

    // Sub struct
    struct Program {
        QVariantMap events;
        QString source;
        Aseba::BytecodeVector bytecode;
    };

    struct Scenario {
        Scenario() : name("newScenario"), simTime(0), initialPosition(20,20,0), worldSize(20,20), evaluationMetric("none") {}

        QString name;
        int simTime;
        QVector3D initialPosition;

        QVector2D worldSize;
        QVector<Enki::PhysicalObject> walls;

        QString evaluationMetric;
        QVector<QVector2D> tiles;
        QVector<int> tileScores;
    };
    struct UnitTest {
        UnitTest() : name("newUnitTest"), scenarios(NULL), combinationRule("none") {}

        QString name;
        QVector<Scenario> scenarios;
        QString combinationRule;
    };
    struct UserTask {
        UserTask() : unitTests(NULL) {}

        QString name;
        QVector<UnitTest> unitTests;
    };

public slots:
    // Update the userTask, events and source in the simulator and run the simulation
    QString testProgram(QVariant userTask, QVariantMap newEvents, QString newSource);
    // run the simulation
    QString testProgram();
    // Update program information in the simulator (events and source)
    void setProgram(QVariantMap newEvents, QString newSource);
    // Update the userTask in the simulator
    void setUserTask(QVariant newUserTask);

private:
    Program program;
    UserTask userTask;
};

#endif // SIMULATOR_H
