import QtQuick 2.6
import QtQuick.Window 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.0
import Simulator 1.0

Item {
	visible: scoreBarVisible

	property bool scoreBarVisible: true

	property string userName: "test"
	property string logFileName: userName + "_" + timeBegin.toLocaleTimeString().substr(0,8).replace(":","-").replace(":","-") + ".txt"
	property bool firstLogEntry: true
	property var timeBegin: new Date()

	property int runNumberPerScenario: 5
	property var unitTestScores: []
	property var scenarioScores: []
	property var bestUnitTestScores: []

	property bool iconFeedback: false

	property int currentLevel: 1
	property var levelTimeBegin: timeBegin
	// Global score (obtained by performing good scores at unitTest and finishing tests before timeOut)
	property int experience: 0

	height: flow.height + 20

	Rectangle {
		anchors.fill: parent
		color: Material.primary;
		opacity: 0.5
	}

	// TODO: use a loader for userTask
	UserTask {
		id: userTask
	}

	Simulator {
		id: simulator
	}

	Component.onCompleted: { changeUserNamePopup.open() }
	onVisibleChanged: {
		if (visible === true) {
			changeUserNamePopup.open()
		}
	}

	function writeLog() {
		var timeNow = new Date()
		if (firstLogEntry) {
			firstLogEntry = false
			simulator.setNewLogFile(logFileName)
			simulator.writeLog(timeBegin.getTime().toString() + " BEGIN")
		}
		// Acquire vpl2 and aesl code
		var vplCode = vplEditor.getProgram()
		simulator.writeLog(timeNow.getTime().toString() + " RUN " + (timeNow.getTime()-timeBegin.getTime()).toString() + " " +
						   scenarioScores.toString() + " " + bestUnitTestScores.toString() + " " + experience + "\n\t" + vplCode)
	}

	// Update scoreBar information
	function update_scores(newScores) {
		var spentLevelTime = (new Date().getTime() - levelTimeBegin.getTime()) / 1000

		// update instant scores and best achieved scores
		unitTestScores = newScores
		if (bestUnitTestScores.length === 0)
			bestUnitTestScores = newScores
		else
			for (var i=0 ; i<userTask.unitTests.length ; i++)
				bestUnitTestScores[i] = Math.max(bestUnitTestScores[i], newScores[i])

		if (currentLevel <= userTask.levelNumber) {

			// Check if all previous unitTests and current one are completed
			var unitTestTimeOut = false
			var unitTestCompleted = true

			if (iconFeedback)
				for (var i=0 ; i<userTask.unitTests.length ; i++) {
					if (userTask.unitTestLevel[i] <= currentLevel)
						if (unitTestScores[i] < userTask.unitTests[i].scoreMax) {
							unitTestCompleted = false
							break
						}
				}
			else
				unitTestCompleted = false

			// Check timeout to pass to next unitTest
			if (spentLevelTime > userTask.levelDuration[currentLevel-1]) {
				unitTestCompleted = false
				unitTestTimeOut = true
			}

			// Apply transition to next test if needed
			if (unitTestCompleted || unitTestTimeOut) {
				if (unitTestCompleted) {
					nextTestPopup.experienceEarned = 100
					nextTestPopup.timeBonus = 100 * (userTask.levelDuration[currentLevel-1] - spentLevelTime) / userTask.levelDuration[currentLevel-1]
				}
				else {
					var totalScore = 0
					var scoreNumber = 0
					for (var i=0 ; i<userTask.unitTests.length ; i++) {
						if (userTask.unitTestLevel[i] === currentLevel) {
							scoreNumber++
							totalScore += bestUnitTestScores[i]
						}
					}
					if (scoreNumber === 0)
						nextTestPopup.experienceEarned = 0
					else
						nextTestPopup.experienceEarned = 100 * totalScore/scoreNumber
					nextTestPopup.timeBonus = 0
				}
				experience += nextTestPopup.experienceEarned + nextTestPopup.timeBonus
				currentLevel++


				// log levelUp
				var timeNow = new Date()
				simulator.writeLog(timeNow.getTime().toString() + " NEXT_LEVEL " + (timeNow.getTime()-timeBegin.getTime()).toString() + " " +
								   currentLevel + " " + nextTestPopup.experienceEarned + " " + nextTestPopup.timeBonus)

				nextTestPopup.open()
			}
		}
	}

	// Run the test of the program over each unitTests' scenario
	function testProgram(events, source) {
		// TODO: put simulation in a thread
		var testScores = [] // scorse of the unitTests
		scenarioScores = [] // scores of each scenario inside unitTests
		for(var i=0 ; i<userTask.unitTests.length ; i++) {
			var unitTestInternalScores = [] // scores of scenario contained in one unitTest
			for (var j=0 ; j<userTask.unitTests[i].scenarios.length ; j++) {
				var bestRun = 0
				for (var k=0 ; k<runNumberPerScenario ; k++) {
					var scoreBuffer = simulator.testProgram(userTask.unitTests[i].scenarios[j], events, source)
					if (scoreBuffer > bestRun)
						bestRun = scoreBuffer
				}
				unitTestInternalScores.push(bestRun)
				console.log(unitTestInternalScores)
			}
			scenarioScores.push(unitTestInternalScores)
			// Combinate scenarios' scores to make test's score
			switch(userTask.unitTests[i].combinationRule) {
				case "mean":
					var sum = 0
					for (j=0 ; j<unitTestInternalScores.length ; j++) {
						sum += unitTestInternalScores[j]
					}
					testScores.push(sum/unitTestInternalScores.length)
					break;
				case "max":
					var max = 0
					for (j=0 ; j<unitTestInternalScores.length ; j++) {
						if (unitTestInternalScores[j] > max) {
							max = unitTestInternalScores[j]
						}
					}
					testScores.push(max)
					break;
				case "min":
					var min = 0
					for (j=0 ; j<unitTestInternalScores.length ; j++) {
						if (unitTestInternalScores[j] < min) {
							min = unitTestInternalScores[j]
						}
					}
					testScores.push(min)
					break;
				default:
					testScores.push(unitTestInternalScores[0])
			}
		}

		writeLog(false)

		// update scoreBar information
		update_scores(testScores)
		}

	// Icons corresponding to unitTests (representing progress on each)
	Flow {
		id: flow
		anchors.verticalCenter: parent.verticalCenter
		anchors.horizontalCenter: parent.horizontalCenter
		width: parent.width - 20

		spacing: unitTestsItem.width + scoreItem.width < width ? width - (unitTestsItem.width + scoreItem.width) : 0

		Row {
			id: unitTestsItem
			spacing: 5
			Repeater {
				model: userTask.unitTests.length
				Rectangle {
					width: 50
					height: 50
					radius: 25
					visible: currentLevel >= level ? true : false

					property int level: userTask.unitTestLevel[index]
					property string feedbackColor: unitTestScores[index] > userTask.unitTests[index].scoreMax ? "green" :
												  (unitTestScores[index] > userTask.unitTests[index].scoreAverage ? "orange" : "red")
					property string unlockColor: "grey"
					color: iconFeedback? (currentLevel > level ? feedbackColor : unlockColor) : unlockColor

					Image {
						anchors.centerIn: parent
						width: parent.width
						fillMode: Image.PreserveAspectFit
						source: userTask.unitTests[index].image
					}
				}
			}
		}

		Row {
			id: scoreItem
			spacing: 15
			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: qsTr("SCORE: %1").arg(experience.toString())
				font.pixelSize: 14
				font.weight: Font.Medium
				color: "white"
				visible: iconFeedback
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


	}

	Popup {
		id: changeUserNamePopup
		x: (parent.width - width) / 2
		y: (vplEditor.height - height) / 2
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

			CheckBox {
				id: activateFeedback
				text: "Feedback"
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
						currentLevel = 1
					}
					iconFeedback = activateFeedback.checked
					changeUserNamePopup.close()
				}
			}
		}
	}

	Popup {
		id: nextTestPopup
		x: (parent.width - width) / 2
		y: (vplEditor.height - height) / 2
		width: Screen.width / 2
		modal: true
		focus: true
		closePolicy: Popup.OnEscape | Popup.OnPressOutside

		property int timeBonus: 0
		property int experienceEarned: 0
		property string headerText: currentLevel == userTask.levelNumber ? "Bravo!!!" : (timeBonus ? "Niveau Réussi!" : "Prochain Niveau")
		property string dialogText: !iconFeedback ? "Tu peux maintenant essayer des situations plus compliquées.\nLes dessins en haut de l'écran les différentes situations que le robot peut rencontrer" :
									(timeBonus ? "Félicitations! Tu as finis cette étape en avance.\nLes dessins colorés en haut de l'écran t'indiquent si ton robot\nsait quoi faire dans les différentes situations" :
												"Tu peux maintenant essayer des situations plus compliquées.\nLes dessins colorés en haut de l'écran t'indiquent si ton robot\nsait quoi faire dans les différentes situations")
		ColumnLayout {
			spacing: 16

			Label {
				text: qsTr("Prochain Niveau")
				horizontalAlignment: Text.AlignHCenter
				font.weight: Font.Medium
				font.pointSize: 21
			}

			Text {
				text: qsTr(nextTestPopup.dialogText)
				horizontalAlignment: Text.AlignLeft
				wrapMode: Text.WordWrap
				font.weight: Font.Medium
				font.pointSize: 14
				color: "white"
			}
			Text {
				text: qsTr("Score + " + (nextTestPopup.experienceEarned + nextTestPopup.timeBonus).toString())
				horizontalAlignment: Text.AlignLeft
				font.weight: Font.Medium
				font.pointSize: 16
				visible: iconFeedback
				color: "white"
			}
			Text {
				text: qsTr("(Bonus de Temps : " + nextTestPopup.timeBonus.toString() + ")")
				horizontalAlignment: Text.AlignLeft
				//font.weight: Font.Medium
				font.pointSize: 16
				visible: iconFeedback
				color: "white"
			}

			Button {
				text: qsTr("Ok")
				enabled: true
				anchors.horizontalCenter: parent.horizontalCenter
				onClicked: {
					levelTimeBegin = new Date()
					nextTestPopup.close()
				}
			}
		}
	}
}
