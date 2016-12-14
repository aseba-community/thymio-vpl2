import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import Simulator 1.0

Rectangle {
	property bool scoreBarVisible: true
	visible: scoreBarVisible

	property double experience: 0
	property var scores: []
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

	function setProgram(events, source) {
		simulator.setProgram(events, source)
	}

	// Update scoreBar information
	function update_scores(newScores, mainScore) {
		// update icones
		scores = newScores

		// Check for new icon to unlock
		for (var i=0 ; i<userTask.unitTests.length ; i++)
			iconUnlock[i] = experience >= userTask.unitTests[i].experienceNeeded ? true : false
		if (iconProgression < userTask.unitTests.length)
			iconProgression++

		// Update best score on main task
		if (percentageCompletion < mainScore)
			percentageCompletion = mainScore
		console.log(iconUnlock, iconVisibility, iconProgression)
	}

	// Run the test of the program over each unitTests' scenario
	function testProgram(events, source) {
		// TODO: put simulation in a thread
		var testScores = []
		var userTaskScore = 0
		for (var i=0 ; i<userTask.unitTests.length ; i++) {
			var scenarioScores = []
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
}
