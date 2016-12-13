import QtQuick 2.0
import Aseba 1.0
import Simulator 1.0

Item {
	property var variables: ({})
    property var events: ({})
	property string source: ""
	property string error: ""

	property var node: {
		for (var i = 0; i < aseba.nodes.length; ++i) {
			var node = aseba.nodes[i];
			if (node.name === "thymio-II") {
				return node;
			}
		}
	}

	// TODO: use a loader for userTask
    UserTask {
        id: userTask
    }

	Simulator {
		id: simulator
	}

	onNodeChanged: {
		setVariables();
		setProgram();
	}
	onVariablesChanged: setVariables()
	onEventsChanged: setProgram()
	onSourceChanged: {
		setProgram()
		testProgram()
	}

	function setVariables() {
		if (node) {
			Object.keys(variables).forEach(function(name) {
				var value = variables[name];
				if (typeof value === "number") {
					value = [value];
				}
				node.setVariable(name, value);
			})
		}
	}
	function setProgram() {
		simulator.setProgram(events, source)
		if (node) {
			error = node.setProgram(events, source);
		}
	}

	function testProgram() {
        // TODO: put simulation in a thread
		var i, j
		var testScores = []
		var userTaskScore = 0
		for (i=0 ; i<userTask.unitTests.length ; i++) {
			var scenarioScores = []
			for (j=0 ; j<userTask.unitTests[i].scenarios.length ; j++) {
				scenarioScores.push(simulator.testProgram(userTask.unitTests[i].scenarios[j], events, source))
			}

			// Combinate scenarios' scores to make test's score
			switch(userTask.unitTests[i].combinationRule) {
				case "mean":
					var sum = 0
					for (j=0 ; j<scenarioScores.length ; j++) {
						sum += scenarioScores[j]
					}
					testScores.push(sum/scenarioScores.length)
					break;
				case "max":
					var max = 0
					for (j=0 ; j<scenarioScores.length ; j++) {
						if (scenarioScores[j] > max) {
							max = scenarioScores[j]
						}
					}
					testScores.push(max)
					break;
				case "min":
					var min = 0
					for (j=0 ; j<scenarioScores.length ; j++) {
						if (scenarioScores[j] < min) {
							min = scenarioScores[j]
						}
					}
					testScores.push(min)
					break;
				default:
					testScores.push(scenarioScores[0])
			}

			// Check if this unitTest correspond to the task
			if (userTask.unitTests[i].name === "test_" + userTask.name) {
				userTaskScore = testScores[testScores.length - 1] > userTask.unitTests[i].scoreMax ?
							1 : testScores[testScores.length - 1] / userTask.unitTests[i].scoreMax
			}
		}

		// send scores to scoreboard
		console.log(testScores)
		scoreBoard.update_scores(testScores, userTaskScore)
	}
}
