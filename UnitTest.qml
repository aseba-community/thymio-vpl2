import QtQuick 2.0

QtObject {
    property string name: "newUnitTest"
	// Image representing the Test on the scoreboard
	property string image: ""
    // List of scenarios
    property list<Scenario> scenarios
    // Rule ussed to compute the uniTest's score from the scenarios' scores
    // Possible choices: none, mean, max, min
    property string combinationRule: "none"

	// Score threshold for "goal reached"
	property double scoreMax: 0.8
	// Score threshold for "average performance"
	property double scoreAverage: 0.4
	// Experience needed to make the icon appear in the score board
	property double experienceNeeded: 0.0
}
