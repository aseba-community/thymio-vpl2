import QtQuick 2.0

Item {
    property string name

    property int simTime
    property vector3d initialPosition

    property vector2d worldSize
    property list<Wall> walls

    property string evaluationMetric
    property list<QVector2D> tiles
    property list<int> tileScores
}
