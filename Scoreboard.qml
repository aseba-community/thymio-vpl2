import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3

Popup {
	id: dialog
	x: (parent.width - width) / 2
	y: (parent.height - height) / 2
	modal: true
	focus: true
	closePolicy: Popup.OnEscape | Popup.OnPressOutside

	property double experience: 0
	property var scores
	property double percentageCompletion: 20
	property string userTaskName: userTask.name

	UserTask {
		id: userTask
	}

	function update_experience(timeSinceBegin, timePlayed, runNumber) {
		experience = timeSinceBegin
	}

	function update_scores(newScores) {
		dialog.scores = newScores
		// TODO: update percentageComplation based on userTask.unitTests[i].threshold
	}

	ColumnLayout {
		spacing: 30

		// Title
		Label {
			text: "Program Progress - " + userTaskName
			font.weight: Font.Medium
			font.pointSize: 21
		}

		// ProgressBar
		Rectangle {
			Layout.alignment: Qt.AlignCenter
			color: "black"
			Layout.preferredWidth: 520
			Layout.preferredHeight: 1
			radius: 2

			Image {
				id: progressionBarBorder
				width: parent.width
				anchors.verticalCenter: parent.verticalCenter
				fillMode: Image.PreserveAspectFit
				source: "qrc:/thymio-vpl2/images/userhints/barre.png"
			}

			Row {
				id: progressionBarFilling
				x: 10
				anchors.verticalCenter: progressionBarBorder.verticalCenter

				Repeater {
					model: percentageCompletion
					Image {
						width: 5
						height: 15
						source: "qrc:/thymio-vpl2/images/userhints/barre vert.png"
					}
				}
			}

			Image {
				id: progressionWheel
				anchors.horizontalCenter: progressionBarFilling.right
				anchors.verticalCenter: progressionBarBorder.verticalCenter
				height: 50
				fillMode: Image.PreserveAspectFit
				source: "qrc:/thymio-vpl2/images/userhints/barre rouage.png"
			}
		}

		// Icone of unitTests + success/fail light
		Row {
			spacing: 20
			anchors.horizontalCenter: parent.horizontalCenter
			Repeater {
				model: 3
				ColumnLayout {
					spacing: 5
					Layout.alignment: Qt.AlignHCenter
					Rectangle {
						Layout.alignment: Qt.AlignVCenter
						color: "grey"
						Layout.preferredWidth: 80
						Layout.preferredHeight: 80
						radius: 40
						// TODO: change visibility depending on experience
						visible: true
						Image {
							anchors.centerIn: parent
							width: parent.width
							fillMode: Image.PreserveAspectFit
							visible: true
							source: userTask.unitTests[index].image
						}
					}
					Rectangle {
						Layout.alignment: Qt.AlignCenter
						color: "black"
						Layout.preferredWidth: 40
						Layout.preferredHeight: 40
						radius: 20
						Image {
							anchors.centerIn: parent
							width: parent.width
							fillMode: Image.PreserveAspectFit
							visible: true
							// TODO: change iamge depending on scores
							source: "qrc:/thymio-vpl2/images/userhints/feu_rouge.png"
						}
					}
				}
			}
		}

		// Back button
		Button {
			id: okButton
			anchors.horizontalCenter: parent.horizontalCenter
			text: "Back"
			onClicked: {
				dialog.close();
			}
		}
	}
}

