import QtQuick 2.0
import Aseba 1.0
import Simulator 1.0

Item {
	property var variables: ({})
	property var events: ({})
    property var userTask: ({})
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

	Simulator {
		id: simulator
	}

	onNodeChanged: {
		setVariables();
		setProgram();
	}
	onVariablesChanged: setVariables()
	onEventsChanged: setProgram()
	onSourceChanged: setProgram()

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
		// TODO: put simulation in a thread
        simulator.testProgram(userTask, events, source);
		if (node) {
			error = node.setProgram(events, source);
		}
	}
}
