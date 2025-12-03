import QtQuick
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

Item {
    id: root
    width: 640
    height: 480

    // Properties to control the model rotation and position
    property real modelRotationX: 0
    property real modelRotationY: 0
    property real modelPositionX: 0
    property real modelPositionY: 0
    property real modelScale: 1.0
    property color modelColor: "#4fc3f7"

    View3D {
        id: view3D
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "#1a1a2e"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        // Camera setup
        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 100, 500)
            eulerRotation.x: -10
            clipNear: 0.1
            clipFar: 100000
        }

        // Lighting - color affects the model tint
        DirectionalLight {
            id: mainLight
            eulerRotation.x: -30
            eulerRotation.y: -30
            color: root.modelColor
            ambientColor: root.modelColor
            brightness: 1.0
        }

        PointLight {
            position: Qt.vector3d(200, 200, 200)
            color: root.modelColor
            brightness: 0.8
        }

        PointLight {
            position: Qt.vector3d(-200, 200, -200)
            color: "white"
            brightness: 0.3
        }

        // Runtime loader for 3D models (Blender export as .glb or .gltf)
        // Export from Blender: File → Export → glTF 2.0 (.glb/.gltf)
        RuntimeLoader {
            id: loadedModel
            source: modelPath  // Set from C++ via env var MODEL_PATH or default path
            scale: Qt.vector3d(root.modelScale * 100, root.modelScale * 100, root.modelScale * 100)
            position: Qt.vector3d(root.modelPositionX, root.modelPositionY, 0)
            eulerRotation: Qt.vector3d(root.modelRotationX, root.modelRotationY, 0)

            onStatusChanged: {
                if (status === RuntimeLoader.Error) {
                    console.log("Error loading model:", errorString)
                } else if (status === RuntimeLoader.Success) {
                    console.log("Model loaded successfully")
                    console.log("Bounds min:", bounds.minimum)
                    console.log("Bounds max:", bounds.maximum)
                }
            }

            onBoundsChanged: {
                console.log("Bounds changed:", bounds.minimum, bounds.maximum)
            }
        }
    }

    // Mouse/Touch interaction area
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        property real lastX: 0
        property real lastY: 0

        onPressed: (mouse) => {
            lastX = mouse.x
            lastY = mouse.y
            console.log("Mouse pressed at:", mouse.x, mouse.y)
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                var deltaX = mouse.x - lastX
                var deltaY = mouse.y - lastY

                if (mouse.buttons & Qt.LeftButton) {
                    // Left button: rotate the model
                    root.modelRotationY += deltaX * 0.5
                    root.modelRotationX += deltaY * 0.5
                } else if (mouse.buttons & Qt.RightButton) {
                    // Right button: move the model
                    root.modelPositionX += deltaX
                    root.modelPositionY -= deltaY
                }

                lastX = mouse.x
                lastY = mouse.y
            }
        }

        onWheel: (wheel) => {
            // Zoom in/out with mouse wheel
            root.modelScale += wheel.angleDelta.y * 0.001
            root.modelScale = Math.max(0.1, Math.min(5, root.modelScale))
            console.log("Scale:", root.modelScale)
        }
    }

    // Touch: Single finger drag for rotation
    DragHandler {
        id: dragHandler
        target: null  // Don't move anything directly
        acceptedButtons: Qt.NoButton  // Touch only, not mouse (mouse handled by MouseArea)

        property real lastX: 0
        property real lastY: 0

        onActiveChanged: {
            if (active) {
                lastX = centroid.position.x
                lastY = centroid.position.y
                console.log("Drag started at:", lastX, lastY)
            }
        }

        onCentroidChanged: {
            if (active) {
                var deltaX = centroid.position.x - lastX
                var deltaY = centroid.position.y - lastY

                root.modelRotationY += deltaX * 0.5
                root.modelRotationX += deltaY * 0.5

                lastX = centroid.position.x
                lastY = centroid.position.y
            }
        }
    }

    // Touch: Two finger pinch for zoom
    PinchHandler {
        id: pinchHandler
        target: null  // Don't transform anything directly

        property real initialScale: 1.0
        property real initialRotation: 0

        onActiveChanged: {
            if (active) {
                initialScale = root.modelScale
                initialRotation = root.modelRotationY
                console.log("Pinch started, scale:", initialScale)
            }
        }

        onScaleChanged: {
            if (active) {
                root.modelScale = Math.max(0.1, Math.min(5, initialScale * activeScale))
                console.log("Pinch scale:", root.modelScale, "activeScale:", activeScale)
            }
        }

        onRotationChanged: {
            if (active) {
                root.modelRotationY = initialRotation + activeRotation
            }
        }
    }

    // Color picker
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 15
        width: 60
        height: 320
        color: "#80000000"
        radius: 8

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                text: "Color"
                font.pixelSize: 12
                font.bold: true
            }

            Repeater {
                model: ["#4fc3f7", "#f44336", "#4caf50", "#ffeb3b", "#9c27b0", "#ff9800", "#ffffff", "#607d8b"]

                Rectangle {
                    width: 44
                    height: 30
                    color: modelData
                    radius: 5
                    border.color: root.modelColor === modelData ? "white" : "transparent"
                    border.width: 3

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.modelColor = modelData
                    }
                }
            }
        }
    }

    // Instructions overlay
    Rectangle {
        anchors.bottom: ySliderRect.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 10
        width: instructionText.width + 20
        height: instructionText.height + 10
        color: "#80000000"
        radius: 5

        Text {
            id: instructionText
            anchors.centerIn: parent
            color: "white"
            text: "Drag: Rotate | Right click: Move | Scroll/Slider: Zoom"
            font.pixelSize: 12
        }
    }

    // Y Position slider (horizontal at bottom)
    Rectangle {
        id: ySliderRect
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 15
        width: 300
        height: 80
        color: "#80000000"
        radius: 8

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                text: "Y"
                font.pixelSize: 16
                font.bold: true
            }

            Slider {
                id: ySlider
                anchors.verticalCenter: parent.verticalCenter
                orientation: Qt.Horizontal
                width: parent.width - 80
                height: 40
                from: -500
                to: 500
                value: root.modelPositionY
                onValueChanged: root.modelPositionY = value
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                text: root.modelPositionY.toFixed(0)
                font.pixelSize: 14
                width: 40
            }
        }
    }

    // Zoom slider
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 15
        width: 80
        height: 300
        color: "#80000000"
        radius: 8

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                text: "Zoom"
                font.pixelSize: 16
                font.bold: true
            }

            Slider {
                id: zoomSlider
                anchors.horizontalCenter: parent.horizontalCenter
                orientation: Qt.Vertical
                height: parent.height - 80
                width: 40
                from: 0.1
                to: 5.0
                value: root.modelScale
                onValueChanged: root.modelScale = value
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white"
                text: root.modelScale.toFixed(1) + "x"
                font.pixelSize: 16
                font.bold: true
            }
        }
    }

    // Reset button
    Button {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        text: "Reset"
        onClicked: {
            root.modelRotationX = 0
            root.modelRotationY = 0
            root.modelPositionX = 0
            root.modelPositionY = 0
            root.modelScale = 1.0
            root.modelColor = "#4fc3f7"
            zoomSlider.value = 1.0
            ySlider.value = 0
        }
    }
}
