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
}
