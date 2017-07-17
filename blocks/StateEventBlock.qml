import QtQuick 2.7
import QtQuick.Controls 2.2
import ".."
import "widgets"

BlockDefinition {
	type: "event"
	category: "state"

	defaultParams: 0

	editor: Component {
		StateEditor {
			params: defaultParams
		}
	}

	miniature: Component {
		StateEditor {
			enabled: false
			scale: 1.0
			params: defaultParams
		}
	}

	function compile(params) {
		return {
			condition: "state == " + params,
			varDef: "var state = 0"
		};
	}
}
