import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

Item {
	id: musicEditor
	width: 256
	height: 256

	property int params
	function getParams() {
		return params;
	}

	Repeater {
		model: 8
		RadioButton {
			property double angle: index * Math.PI / 4
			property double buttonRadius: enabled ? 90 : 70
			scale: 1.5
			checked: musicEditor.params === index
			x: 128 - width/2 + Math.sin(angle) * buttonRadius
			y: 128 - height/2 - Math.cos(angle) * buttonRadius
			onCheckedChanged: {
				if (checked) {
					musicEditor.params = index;
				}
			}
			Material.accent: "yellow"
		}
	}
}
