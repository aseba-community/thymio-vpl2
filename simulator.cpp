#include "aseba/targets/playground/DirectAsebaGlue.h"
#include "aseba/common/msg/NodesManager.h"
#include "aseba.h"
#include "simulator.h"
#include <iostream>
#include <QDebug>

#include <QJSValue>
#include <QJSValueIterator>
#include <QQmlListReference>
#include <QQmlProperty>

using namespace Aseba;
using namespace Enki;
using namespace std;

struct SimulatorNodesManager: NodesManager
{
	DirectAsebaThymio2* thymio;

	SimulatorNodesManager(DirectAsebaThymio2* thymio): thymio(thymio) {}

	virtual void sendMessage(const Message& message)
	{
		thymio->inQueue.emplace(message.clone());
	}

	void step()
	{
		while (!thymio->outQueue.empty())
		{
			processMessage(thymio->outQueue.front().get());
			thymio->outQueue.pop();
		}
	}
};

void Simulator::setUserTask(QVariant newUserTask) {

    // Delete previous data in userTask member
    userTask.unitTests.clear();

    // Get userTask from qml
    QObject * newUserTaskObj = qvariant_cast<QObject *>(newUserTask);
    userTask.name = qvariant_cast<QString>(newUserTaskObj->property("name"));

    // Get unitTest list from qml
    QQmlProperty property_unitTests(newUserTaskObj, "unitTests");
    QQmlListReference unitTests = qvariant_cast<QQmlListReference>(property_unitTests.read());
    for (int i=0 ; i<unitTests.count() ; i++) {
        UnitTest newUnitTest;
        newUnitTest.name = qvariant_cast<QString>(unitTests.at(i)->property("name"));
        newUnitTest.combinationRule = qvariant_cast<QString>(unitTests.at(i)->property("combinationRule"));

        // Get scenario list from qml
        QQmlProperty property_scenarios(unitTests.at(i), "scenarios");
        QQmlListReference scenarios = qvariant_cast<QQmlListReference>(property_scenarios.read());
        for (int j=0 ; j<scenarios.count() ; j++) {
            Scenario newScenario;

            newScenario.name = qvariant_cast<QString>(scenarios.at(j)->property("name"));
            newScenario.simTime = qvariant_cast<double>(scenarios.at(j)->property("simTime"));
            newScenario.initialPosition = qvariant_cast<QVector3D>(scenarios.at(j)->property("initialPosition"));
            newScenario.worldSize = qvariant_cast<QVector2D>(scenarios.at(j)->property("worldSize"));
            newScenario.evaluationMetric = qvariant_cast<QString>(scenarios.at(j)->property("evaluationMetric"));

            // Get tiles from qml, which come as a QJSValue containing a list of QVariant(QVector2D)
            QJSValueIterator tiles(qvariant_cast<QJSValue>(scenarios.at(j)->property("tiles")));
            while(tiles.hasNext()) {
                tiles.next();
                if (tiles.name() != "length")
                    newScenario.tiles.append(qvariant_cast<QVector2D>(tiles.value().toVariant()));
            }

            // Get tileScores from qml, which come as a QJSValue containing a list of double
            QJSValueIterator tileScores(qvariant_cast<QJSValue>(scenarios.at(j)->property("tileScores")));
            while(tileScores.hasNext()) {
                tileScores.next();
                if (tileScores.name() != "length")
                    newScenario.tileScores.append(tileScores.value().toNumber());
            }

            // Get wall list from qml
            QQmlProperty property_walls(scenarios.at(j), "walls");
            QQmlListReference walls = qvariant_cast<QQmlListReference>(property_walls.read());
            for (int k=0 ; k<walls.count() ; k++) {
                Enki::PhysicalObject newWall;

                newWall.pos.x = qvariant_cast<QVector2D>(walls.at(k)->property("position"))[0];
                newWall.pos.y = qvariant_cast<QVector2D>(walls.at(k)->property("position"))[1];
                newWall.angle = qvariant_cast<double>(walls.at(k)->property("angle"));
                newWall.setRectangular(qvariant_cast<QVector3D>(walls.at(k)->property("size"))[0],
                                       qvariant_cast<QVector3D>(walls.at(k)->property("size"))[1],
                                       qvariant_cast<QVector3D>(walls.at(k)->property("size"))[2],
                                       0);
                Color color(qvariant_cast<QVector3D>(walls.at(k)->property("color"))[0],
                            qvariant_cast<QVector3D>(walls.at(k)->property("color"))[1],
                            qvariant_cast<QVector3D>(walls.at(k)->property("color"))[2],
                            1.0);
                newWall.setColor(color);

                newScenario.walls.append(newWall);
            }

            newUnitTest.scenarios.append(newScenario);
        }
        userTask.unitTests.append(newUnitTest);
    }
    /*
    qDebug() << userTask.name << userTask.unitTests.count();
    for (int i=0 ; i<userTask.unitTests.count() ; i++) {
        qDebug() << userTask.unitTests[i].name;
        qDebug() << userTask.unitTests[i].combinationRule;
        for (int j=0 ; j<userTask.unitTests[i].scenarios.count() ; j++) {
            qDebug() << "\t" << userTask.unitTests[i].scenarios[j].name;
            qDebug() << "\t\t" << userTask.unitTests[i].scenarios[j].simTime;
            qDebug() << "\t\t" << userTask.unitTests[i].scenarios[j].initialPosition;
            qDebug() << "\t\t" << userTask.unitTests[i].scenarios[j].worldSize;
            qDebug() << "\t\t" << userTask.unitTests[i].scenarios[j].evaluationMetric;
            qDebug() << "\t\t" << userTask.unitTests[i].scenarios[j].tiles;
            qDebug() << "\t\t" << userTask.unitTests[i].scenarios[j].tileScores;
            for (int k=0 ; k<userTask.unitTests[i].scenarios[j].walls.count() ; k++) {
                qDebug() << "\t\ŧWall" << k;
                qDebug() << "\t\t\t" << userTask.unitTests[i].scenarios[j].walls[k].pos.x;
                qDebug() << "\t\t\t" << userTask.unitTests[i].scenarios[j].walls[k].pos.y;
                qDebug() << "\t\t\t" << userTask.unitTests[i].scenarios[j].walls[k].angle;
                qDebug() << "\t\t\t" << userTask.unitTests[i].scenarios[j].walls[k].getHeight();
                qDebug() << "\t\t\t" << userTask.unitTests[i].scenarios[j].walls[k].getColor().r();
                qDebug() << "\t\t\t" << userTask.unitTests[i].scenarios[j].walls[k].getColor().g();
                qDebug() << "\t\t\t" << userTask.unitTests[i].scenarios[j].walls[k].getColor().r();
            }
        }
    }
    */
}

void Simulator::setProgram(QVariantMap newEvents, QString newSource) {

    // Update program member
    program.events = newEvents;
    program.source = newSource;

    // Update byteCode
    program.bytecode.clear();
}

QString Simulator::testProgram(QVariant newUserTask, QVariantMap newEvents, QString newSource) {
    setUserTask(newUserTask);
    setProgram(newEvents, newSource);
    return testProgram();
}

QString Simulator::testProgram() {
    // Parameters
    const double dt(0.03);
    qDebug() << program.events;
    qDebug() << program.source;

    // create world, robot and nodes manager
    World world(40,40);
    DirectAsebaThymio2* thymio(new DirectAsebaThymio2());
    thymio->pos = {10, 10};
    world.addObject(thymio);
    SimulatorNodesManager SimulatorNodesManager(thymio);

    // list the nodes and step, the robot should send its description to the nodes manager
    thymio->inQueue.emplace(ListNodes().clone());

    // we define a step lambda
    auto step = [&]() {
        world.step(dt);
        SimulatorNodesManager.step();
        qInfo() << "- stepped, robot pos:" << thymio->pos.x << thymio->pos.y;
    };

    // step twice for the detection and enumeration round-trip
    step();
    step();

    // check that the nodes manager has received the description from the robot
    bool ok(false);
    unsigned nodeId(SimulatorNodesManager.getNodeId(L"thymio-II", 0, &ok));
    if (!ok) {
        qCritical() << "nodes manager did not find \"thymio-II\"";
        return "";
    }
    if (nodeId != 1) {
        qCritical() << "nodes manager did not return the right nodeId for \"thymio-II\", should be 1, was " << nodeId;
        return "";
    }

    const TargetDescription *targetDescription(SimulatorNodesManager.getDescription(nodeId));
    if (!targetDescription) {
        qCritical() << "nodes manager did not return a target description for \"thymio-II\"";
        return "";
    }

    // compile a small code
    Compiler compiler;
    CommonDefinitions commonDefinitions(AsebaNode::commonDefinitionsFromEvents(program.events));
    compiler.setTargetDescription(targetDescription);
    compiler.setCommonDefinitions(&commonDefinitions);
    std::wistringstream input(program.source.toStdWString());
    BytecodeVector bytecode;
    unsigned allocatedVariablesCount;
    Error error;
    const bool compilationResult(compiler.compile(input, bytecode, allocatedVariablesCount, error));
    if (!compilationResult) {
        qWarning() << "compilation error: " << QString::fromStdWString(error.toWString());
        qWarning() << program.source;
        return QString::fromStdWString(error.message);
    }
    else {
        qDebug() << "compilation ok";
    }

    // fill the bytecode messages
    vector<Message*> setBytecodeMessages;
    sendBytecode(setBytecodeMessages, nodeId, vector<uint16>(bytecode.begin(), bytecode.end()));
    for_each(setBytecodeMessages.begin(), setBytecodeMessages.end(), [=](Message* message){ thymio->inQueue.emplace(message); });

    // then run the code...
    thymio->inQueue.emplace(new Run(nodeId));

    // ...run for hundred time steps
    for (unsigned i(0); i<100; ++i) {
        //qDebug() << "Thymio Position : " << thymio->pos.x << thymio->pos.y;
        step();
    }

    // and check the robot has stopped
    const Point robotPos(thymio->pos);
    step();
    const Point deltaPos(thymio->pos - robotPos);

    // if not it is an error
    if (deltaPos.x > numeric_limits<double>::epsilon() || deltaPos.y > numeric_limits<double>::epsilon())
    {
        qWarning() << "Robot is still moving after 100 time steps, delta:" << deltaPos.x << deltaPos.y;
        return "";
    }
    else {
        qWarning() << "Robot is not moving 100 time steps, position:" << robotPos.x << robotPos.y;
    }

    return "simulation success";
}
