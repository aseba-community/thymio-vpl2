import QtQuick 2.7
import QtQuick.Controls 2.2
import ".."
import "widgets"

BlockDefinition {
	type: "action"
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
			action: "state = " + params + "\ncallsub updateCircle",
			varDef: "var state = 0",
			initCode: "callsub updateCircle",
			eventImpl: "sub updateCircle
call leds.circle(
	((1 << state) & (1<<0)) << 5,
	((1 << state) & (1<<1)) << 4,
	((1 << state) & (1<<2)) << 3,
	((1 << state) & (1<<3)) << 2,
	((1 << state) & (1<<4)) << 1,
	((1 << state) & (1<<5)),
	((1 << state) & (1<<6)) >> 1,
	((1 << state) & (1<<7)) >> 2
)"
		};
	}
}
