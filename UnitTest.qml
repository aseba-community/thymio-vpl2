import QtQuick 2.0

QtObject {
    property string name: "newUnitTest"
	// Image representing the Test on the scoreBar
	property string image: ""
    // List of scenarios
    property list<Scenario> scenarios
    // Rule ussed to compute the uniTest's score from the scenarios' scores
    // Possible choices: none, mean, max, min
    property string combinationRule: "none"

	// Score threshold for "goal reached" [0-1]
	property double scoreMax: 0.8
	// Score threshold for "average performance" [0-1]
	property double scoreAverage: 0.4
}
