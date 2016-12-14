import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import Simulator 1.0

Rectangle {
	property bool scoreBarVisible: true
	visible: scoreBarVisible

	property string userName: "test"
	property string logFileName: userName + "_" + timeBegin.toLocaleTimeString().substr(0,8).replace(":","-").replace(":","-") + ".txt"
	property bool firstLogEntry: true
	property var timeBegin: new Date()

	property var scores: []
	property var scenarioScores: []
	property int iconProgression: 0
	property var iconUnlock: [true,false,true,false,true]
	property var iconVisibility: vplEditor.compiler.error !== "" ? false : true
	property double percentageCompletion: 0
	property string userTaskName: userTask.name

	// TODO: use a loader for userTask
	UserTask {
		id: userTask
	}

	Simulator {
		id: simulator
	}

	Component.onCompleted: changeUserName.open()
	onScoreBarVisibleChanged: {
		if (scoreBarVisible === true) {
			changeUserName.open()
		}
	}

	function writeLog() {
		var timeNow = new Date()
		if (firstLogEntry) {
			firstLogEntry = false
			console.log("log file : ", logFileName)
			simulator.setNewLogFile(logFileName)
			simulator.writeLog(timeBegin.getTime().toString() + " BEGIN")
		}
		// Acquire vpl2 and aesl code
		var vplCode = vplEditor.getProgram()
		var aeslCode = aeslSourceDialog.prettyPrintGeneratedAesl(vplEditor.compiler.script)
		simulator.writeLog(timeNow.getTime().toString() + " RUN " + (timeNow.getTime()-timeBegin.getTime()).toString() + " " +
						   scenarioScores.toString() + " " + percentageCompletion.toString() + "\n" + vplCode + "\n" + aeslCode)

	}

	function setProgram(events, source) {
		simulator.setProgram(events, source)
	}

	// Update scoreBar information
	function update_scores(newScores, mainScore) {
		// update icones
		scores = newScores

		// Check for new icon to unlock
		if (iconProgression < userTask.unitTests.length) {
			var timeSpent_min = (new Date().getTime() - timeBegin.getTime()) / 60000
			iconProgression = Math.round(timeSpent_min/2 - 0.5)
			//iconProgression = Math.round(timeSpent_min * 12 - 0.5)     // fro Debug (display each 5 sec)
		}

		// Update progressBar
		if (percentageCompletion < mainScore)
			percentageCompletion = mainScore
	}

	// Run the test of the program over each unitTests' scenario
	function testProgram(events, source) {
		// TODO: put simulation in a thread
		scenarioScores = []
		var testScores = []
		var userTaskScore = 0
		for (var i=0 ; i<userTask.unitTests.length ; i++) {
			for (var j=0 ; j<userTask.unitTests[i].scenarios.length ; j++) {
				scenarioScores.push(simulator.testProgram(userTask.unitTests[i].scenarios[j], events, source))
				console.log(userTask.unitTests[i].scenarios[j].name, scenarioScores[scenarioScores.length-1])
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

		// send scores to scoreBar
		update_scores(testScores, userTaskScore)
		writeLog(false)
	}

	// Icons corresponding to unitTests (representing progress on each)
	Flow {
		anchors.verticalCenter: parent.verticalCenter
		anchors.horizontalCenter: parent.horizontalCenter
		height: parent.height - 10
		width: parent.width - 20

		layoutDirection: "RightToLeft"
		spacing: parent.width >= 500 ? parent.width/2 - 230 : 40
		Row {
			spacing: 5

			ProgressBar {
				from: 0; to: 1
				value: percentageCompletion
				anchors.verticalCenter: parent.verticalCenter
				width: 155
			}
			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: 60
				height: 50
				color: "lightgrey"
				Image {
					anchors.centerIn: parent
					width: parent.width
					fillMode: Image.PreserveAspectFit
					source: userTask.image
				}
			}
		}

		Row {
			spacing: 5
			Repeater {
				model: iconProgression
				Rectangle {
					color: scores[index] > userTask.unitTests[index].scoreMax ? "green" :
						  (scores[index] > userTask.unitTests[index].scoreAverage ? "orange" :
																					"red")
					width: 50
					height: 50
					radius: 25
					// TODO: change visibility depending on experience
					visible: true

					Image {
						anchors.centerIn: parent
						width: parent.width
						fillMode: Image.PreserveAspectFit
						source: userTask.unitTests[index].image
					}/*

					Text {
						anchors.left: parent.left
						anchors.top: parent.bottom
						width: parent.width
						text: Math.round(scores[index] * 100) / 100
						color: "white"
					}*/
				}
			}
		}
	}

	Popup {
		id: changeUserName
		x: (parent.width - width) / 2
		y: (parent.height - height) / 2
		modal: true
		focus: true
		closePolicy: Popup.OnEscape | Popup.OnPressOutside

		ColumnLayout {
			spacing: 16

			Label {
				text: qsTr("User Name")
				font.weight: Font.Medium
				font.pointSize: 21
			}

			TextField {
				id: newUserName
				text: userName
				anchors.left: parent.left
				anchors.right: parent.right
				focus: true
			}

			Button {
				id: okButton
				text: qsTr("Save")
				enabled: newUserName.text !== ""
				onClicked: {
					if (newUserName.text != userName) {
						userName = newUserName.text
						timeBegin = new Date()
						firstLogEntry = true
					}
					changeUserName.close()
				}
			}
		}
	}
}
