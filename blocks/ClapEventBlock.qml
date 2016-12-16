import QtQuick 2.5
import ".."

BlockDefinition {
	type: "event"
	advanced: true

	defaultParams: null

	editor: Component {
		Item {
			id: block;

			width: 256
			height: 256

			property var params: defaultParams

			Image {
				source: "images/clap.svg"
				width: 256 // working around Qt bug with SVG and HiDPI
				height: 256 // working around Qt bug with SVG and HiDPI
				anchors.centerIn: parent
			}

			function getParams() {
				return null;
			}
		}
	}

	function compile(params) {
		return {
			global: "mic.threshold = 250",
			event: "mic",
			condition: "event == event_mic",
		};
	}
}
