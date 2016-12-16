#include "aseba/targets/playground/DirectAsebaGlue.h"
#include "aseba/common/msg/NodesManager.h"
#include "aseba.h"
#include "simulator.h"
#include <iostream>
#include <QFile>
#include <QDebug>
#include <QStandardPaths>
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

void Simulator::setNewLogFile(QString newFileName) {
	QString basePath = QStandardPaths::standardLocations(QStandardPaths::DownloadLocation)[0];
	logFile.setFileName(basePath + "/" + newFileName);
	// Check if the file already exists
	while (logFile.exists()) {
		static int i = 1;
		logFile.setFileName(newFileName + "_" + i);
		i++;
	}
}

void Simulator::writeLog(QString logLine) {
	if (logFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
		QTextStream logStream(&logFile);
		logStream << logLine << endl;
		logFile.close();
	}
	else
		qDebug() << "[Simulator] ERROR: Unable to open logFile : " << logFile.fileName();
}

void Simulator::setScenario(QVariant newScenario) {

	// Get scenario from qml
	QObject * scenarioObj = qvariant_cast<QObject *>(newScenario);

	scenario.name = qvariant_cast<QString>(scenarioObj->property("name"));
	scenario.simTime = qvariant_cast<double>(scenarioObj->property("simTime"));
	scenario.initialPosition = qvariant_cast<QVector3D>(scenarioObj->property("initialPosition"));
	scenario.worldSize = qvariant_cast<QVector2D>(scenarioObj->property("worldSize"));
	scenario.evaluationMetric = qvariant_cast<QString>(scenarioObj->property("evaluationMetric"));
	scenario.distanceMax = qvariant_cast<double>(scenarioObj->property("distanceMax"));

	// Get tiles from qml, which come as a QJSValue containing a list of QVariant(QVector2D)
	scenario.tiles.clear();
	QJSValueIterator tiles(qvariant_cast<QJSValue>(scenarioObj->property("tiles")));
	while(tiles.hasNext()) {
		tiles.next();
		if (tiles.name() != "length")
			scenario.tiles.append(qvariant_cast<QVector2D>(tiles.value().toVariant()));
	}

	// Get tileScores from qml, which come as a QJSValue containing a list of QVariant(double)
	scenario.tileScores.clear();
	QJSValueIterator tileScores(qvariant_cast<QJSValue>(scenarioObj->property("tileScores")));
	while(tileScores.hasNext()) {
		tileScores.next();
		if (tileScores.name() != "length")
			scenario.tileScores.append(tileScores.value().toNumber());
	}

	// Get wall list from qml
	scenario.walls.clear();
	QQmlProperty property_walls(scenarioObj, "walls");
	QQmlListReference walls = qvariant_cast<QQmlListReference>(property_walls.read());
	for (int i=0 ; i<walls.count() ; i++) {
		Enki::PhysicalObject newWall;
		newWall.pos.x = qvariant_cast<QVector2D>(walls.at(i)->property("position"))[0];
		newWall.pos.y = qvariant_cast<QVector2D>(walls.at(i)->property("position"))[1];
		newWall.angle = qvariant_cast<double>(walls.at(i)->property("angle"));
		newWall.setRectangular(qvariant_cast<QVector3D>(walls.at(i)->property("size"))[0],
							   qvariant_cast<QVector3D>(walls.at(i)->property("size"))[1],
							   qvariant_cast<QVector3D>(walls.at(i)->property("size"))[2],
							   0);
		Color color(qvariant_cast<QVector3D>(walls.at(i)->property("color"))[0],
					qvariant_cast<QVector3D>(walls.at(i)->property("color"))[1],
					qvariant_cast<QVector3D>(walls.at(i)->property("color"))[2],
					1.0);
		newWall.setColor(color);

		scenario.walls.append(newWall);
	}
}

void Simulator::setProgram(QVariantMap newEvents, QString newSource) {

    // Update program member
    program.events = newEvents;
    program.source = newSource;

    // Update byteCode
    program.bytecode.clear();
}

double Simulator::testProgram(QVariant newScenario, QVariantMap newEvents, QString newSource) {
	setProgram(newEvents, newSource);
	setScenario(newScenario);

    // Parameters
	const double dt(0.2);

	// Create world, robot and nodes manager
	World world(scenario.worldSize.x(), scenario.worldSize.y());
	Enki::getWorld = [&]() { return &world; };

	for (int i=0 ; i<scenario.walls.count() ; i++){
		world.addObject(new Enki::PhysicalObject(scenario.walls[i]));
	}

	DirectAsebaThymio2* thymio(new DirectAsebaThymio2());
	thymio->pos = {scenario.initialPosition.x(), scenario.initialPosition.y()};
	thymio->angle = scenario.initialPosition.z();
	world.addObject(thymio);

    SimulatorNodesManager SimulatorNodesManager(thymio);

	// List the nodes and step, the robot should send its description to the nodes manager
    thymio->inQueue.emplace(ListNodes().clone());

	// Define a step lambda
    auto step = [&]() {
        world.step(dt);
		SimulatorNodesManager.step();
    };

	// Step twice for the detection and enumeration round-trip
    step();
    step();

	// Check that the nodes manager has received the description from the robot
	bool ok(false);
	unsigned nodeId(SimulatorNodesManager.getNodeId(L"thymio-II", 0, &ok));
	if (!ok) {
		qCritical() << "nodes manager did not find \"thymio-II\"";
		return -1;
	}
    if (nodeId != 1) {
        qCritical() << "nodes manager did not return the right nodeId for \"thymio-II\", should be 1, was " << nodeId;
		return -1;
    }

    const TargetDescription *targetDescription(SimulatorNodesManager.getDescription(nodeId));
    if (!targetDescription) {
        qCritical() << "nodes manager did not return a target description for \"thymio-II\"";
		return -1;
    }

	// Compile the code
    Compiler compiler;
	CommonDefinitions commonDefinitions(AsebaNode::commonDefinitionsFromEvents(program.events));
    compiler.setTargetDescription(targetDescription);
    compiler.setCommonDefinitions(&commonDefinitions);

	wistringstream input(newSource.toStdWString());
	BytecodeVector bytecode;
	unsigned allocatedVariablesCount;
	Error error;
	const bool compilationResult(compiler.compile(input, bytecode, allocatedVariablesCount, error));

    if (!compilationResult) {
        qWarning() << "compilation error: " << QString::fromStdWString(error.toWString());
        qWarning() << program.source;
		qDebug() << QString::fromStdWString(error.message);
		return -2;
    }

	// Fill the bytecode messages
    vector<Message*> setBytecodeMessages;
    sendBytecode(setBytecodeMessages, nodeId, vector<uint16>(bytecode.begin(), bytecode.end()));
    for_each(setBytecodeMessages.begin(), setBytecodeMessages.end(), [=](Message* message){ thymio->inQueue.emplace(message); });

	// Run the code and log neede information
	QVector<QVector3D> positionLog;
	QVector<QVector<double>> sensorLog;
    thymio->inQueue.emplace(new Run(nodeId));
	for (unsigned i(0); i<scenario.simTime/dt; ++i) {
		step();
		if (scenario.evaluationMetric == "distance" or
				scenario.evaluationMetric == "tiles" or
				scenario.evaluationMetric == "linearity") {
			QVector3D position(thymio->pos.x, thymio->pos.y, thymio->angle);
			positionLog.append(position);
		}
		if (scenario.evaluationMetric == "sensor") {
			QVector<double> sensor;
			sensor.append(thymio->infraredSensor0.getValue());
			sensor.append(thymio->infraredSensor1.getValue());
			sensor.append(thymio->infraredSensor2.getValue());
			sensor.append(thymio->infraredSensor3.getValue());
			sensor.append(thymio->infraredSensor4.getValue());
			sensorLog.append(sensor);
		}
	}
	/*
	// Check that the robot has stopped, if not it is an error
    const Point robotPos(thymio->pos);
    step();
    const Point deltaPos(thymio->pos - robotPos);
    if (deltaPos.x > numeric_limits<double>::epsilon() || deltaPos.y > numeric_limits<double>::epsilon())
    {
        qWarning() << "Robot is still moving after 100 time steps, delta:" << deltaPos.x << deltaPos.y;
        return "";
    }
    else {
        qWarning() << "Robot is not moving 100 time steps, position:" << robotPos.x << robotPos.y;
    }
	*/
	return compute_score(positionLog, sensorLog);;
}

double Simulator::compute_score(QVector<QVector3D> positionLog, QVector<QVector<double>> sensorLog) {
	if (scenario.evaluationMetric == "tiles") {
		if (scenario.tiles.isEmpty())
			return 0.0;
		double score(0);
		for (int i=0 ; i<positionLog.length() ; i++) {
			double minDistance(sqrt(pow(positionLog[i].x() - scenario.tiles[0].x(),2) +
									pow(positionLog[i].y() - scenario.tiles[0].y(),2)));
			int nearestTileIndex(0);
			for (int j=1 ; j<scenario.tiles.length() ; j++) {
				double distance(sqrt(pow(positionLog[i].x() - scenario.tiles[j].x(),2) +
									  pow(positionLog[i].y() - scenario.tiles[j].y(),2)));
				if (distance < minDistance) {
					nearestTileIndex = j;
					minDistance = distance;
				}
			}
			if (nearestTileIndex+1 < scenario.tiles.length()) {
				score = max(score, scenario.tileScores[nearestTileIndex] + 20 - sqrt(pow(positionLog[i].x() - scenario.tiles[nearestTileIndex+1].x(),2) +
																					 pow(positionLog[i].y() - scenario.tiles[nearestTileIndex+1].y(),2)));
			}
			else
				score = scenario.tileScores.last();
		}
		if (scenario.tileScores.last() != 0)
			return score / scenario.tileScores.last();
		else
			return 0.0;
	}
	else if (scenario.evaluationMetric == "distance") {
		// Score based on distance travelled
		double distanceScore(0);
		double maxDistance(0.0);
		for (int i=0 ; i<positionLog.length() ; i++) {
			double distance(sqrt(pow(positionLog[i].x() - positionLog[0].x(),2) +
								 pow(positionLog[i].y() - positionLog[0].y(),2)));
			if (distance > maxDistance) {
				maxDistance = distance;
			}
		}
		if (scenario.distanceMax != 0.0)
			distanceScore = maxDistance / scenario.distanceMax;
		else
			distanceScore = 0.0;

		// Check if robot move backward
		bool moveBackward(false);
		if (positionLog[positionLog.length()-1].x() - positionLog[0].x() < 0)
			moveBackward = true;

		// Score base on linearity
		double meanAbsAngle(0);
		for (int i=0 ; i<positionLog.length() ; i++)
			meanAbsAngle += abs(positionLog[i].z());

		double linearityScore = 1 - meanAbsAngle/positionLog.length();

		if (linearityScore <= 0 || moveBackward)
			return 0.0;
		else
			return linearityScore * distanceScore;
	}
	else if (scenario.evaluationMetric == "sensor") {
		/*
		# Compute score depending on sensor values
		scoreList = []
		for sensor in sensorMat:
			scoreList.append(np.max(sensor))
		scoreSensor = (4500 - float(np.mean(scoreList))) / 2500
		*/
		return 0.1;
	}
	else if (scenario.evaluationMetric == "collision") {
		/*
		# Compute a score based on collisions
		scoreCollision = 0
		for sensorArray in sensorMat:
			if np.max(sensorArray) >= 4500:
				scoreCollision += 1
		scoreCollision = float(scoreCollision) / len(sensorMat)

		scoreCollision = math.fabs(scoreCollision - 1.0) # scale so that 1 is "good" and 0 is "bad"
		*/
		return 0.1;
	}
	else {
		qDebug() << "[Simulator] Unknown metric : " << scenario.evaluationMetric;
		return 0.0;
	}
}
