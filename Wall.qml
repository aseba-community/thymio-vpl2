import QtQuick 2.0

QtObject {
    // Position of the center (x,y)
    property vector2d position: Qt.vector2d(0,0)
    // orientation in radians
    property double angle: 0
    // Size of the wall (x,y,z)
    property vector3d size: Qt.vector3d(2,2,10)
    // Color of the wall in RGB from 0 to 1
    property vector3d color: Qt.vector3d(0.6,0.6,0.6)
}
