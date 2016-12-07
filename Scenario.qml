import QtQuick 2.0

Item {
    property string name

    property int simTime
    property var initialPosition

    property var worldSize
    property list<Wall> walls

    property string evaluationMetric
    property var tiles: []
    property var tileScores: []
}
