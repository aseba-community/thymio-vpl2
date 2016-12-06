#include "aseba/targets/playground/DirectAsebaGlue.h"
#include "aseba/common/msg/NodesManager.h"
#include "aseba.h"
#include "simulator.h"
#include <iostream>
#include <QDebug>

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

QString Simulator::testProgram(QVariantMap newUserTask, QVariantMap events, QString source) {

	qInfo() << "Simulating" << source;

	// parameters
	const double dt(0.03);

	// create world, robot and nodes manager
	World world(40, 20);

	DirectAsebaThymio2* thymio(new DirectAsebaThymio2());
	thymio->pos = {10, 10};
	world.addObject(thymio);

	SimulatorNodesManager SimulatorNodesManager(thymio);

	// list the nodes and step, the robot should send its description to the nodes manager
	thymio->inQueue.emplace(ListNodes().clone());

	// we define a step lambda
	auto step = [&]()
	{
		world.step(dt);
		SimulatorNodesManager.step();
		//qInfo() << "- stepped, robot pos:" << thymio->pos.x << thymio->pos.y;
	};

	// step twice for the detection and enumeration round-trip
	step();
	step();

	// check that the nodes manager has received the description from the robot
	bool ok(false);
	unsigned nodeId(SimulatorNodesManager.getNodeId(L"thymio-II", 0, &ok));
	if (!ok)
	{
		qCritical() << "nodes manager did not find \"thymio-II\"";
		return "";
	}
	if (nodeId != 1)
	{
		qCritical() << "nodes manager did not return the right nodeId for \"thymio-II\", should be 1, was " << nodeId;
		return "";
	}
	const TargetDescription *targetDescription(SimulatorNodesManager.getDescription(nodeId));
	if (!targetDescription)
	{
		qCritical() << "nodes manager did not return a target description for \"thymio-II\"";
		return "";
	}

	// compile a small code
	Compiler compiler;
	CommonDefinitions commonDefinitions(AsebaNode::commonDefinitionsFromEvents(events));
	compiler.setTargetDescription(targetDescription);
	compiler.setCommonDefinitions(&commonDefinitions);
	std::wistringstream input(source.toStdWString());
	BytecodeVector bytecode;
	unsigned allocatedVariablesCount;
	Error error;
	const bool compilationResult(compiler.compile(input, bytecode, allocatedVariablesCount, error));
	if (!compilationResult)
	{
		qWarning() << "compilation error: " << QString::fromStdWString(error.toWString());
		qWarning() << source;
		return QString::fromStdWString(error.message);
	}

	// fill the bytecode messages
	vector<Message*> setBytecodeMessages;
	sendBytecode(setBytecodeMessages, nodeId, vector<uint16>(bytecode.begin(), bytecode.end()));
	for_each(setBytecodeMessages.begin(), setBytecodeMessages.end(), [=](Message* message){ thymio->inQueue.emplace(message); });

	// then run the code...
	thymio->inQueue.emplace(new Run(nodeId));

	// ...run for hundred time steps
	for (unsigned i(0); i<100; ++i)
		step();

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

	return "simulation success";
}
