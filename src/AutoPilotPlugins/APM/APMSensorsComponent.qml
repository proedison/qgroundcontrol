/*=====================================================================

 QGroundControl Open Source Ground Control Station

 (c) 2009 - 2015 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>

 This file is part of the QGROUNDCONTROL project

 QGROUNDCONTROL is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 QGROUNDCONTROL is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with QGROUNDCONTROL. If not, see <http://www.gnu.org/licenses/>.

 ======================================================================*/

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.2

import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Palette 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controllers 1.0

QGCView {
    id:         rootQGCView
    viewPanel:  panel

    // Help text which is shown both in the status text area prior to pressing a cal button and in the
    // pre-calibration dialog.

    readonly property string orientationHelp:       "If the orientation is in the direction of flight, select None."
    readonly property string boardRotationText:     "If the autopilot is mounted in flight direction, leave the default value (None)"
    readonly property string compassRotationText:   "If the compass or GPS module is mounted in flight direction, leave the default value (None)"

    readonly property string compassHelp:   "For Compass calibration you will need to rotate your vehicle through a number of positions. Most users prefer to do this wirelessly with the telemetry link."
    readonly property string gyroHelp:      "For Gyroscope calibration you will need to place your vehicle on a surface and leave it still."
    readonly property string accelHelp:     "For Accelerometer calibration you will need to place your vehicle on all six sides on a perfectly level surface and hold it still in each orientation for a few seconds."
    readonly property string levelHelp:     "To level the horizon you need to place the vehicle in its level flight position and press OK."
    readonly property string airspeedHelp:  "For Airspeed calibration you will need to keep your airspeed sensor out of any wind and then blow across the sensor."

    readonly property string statusTextAreaDefaultText: "Start the individual calibration steps by clicking one of the buttons above."

    // Used to pass what type of calibration is being performed to the preCalibrationDialog
    property string preCalibrationDialogType

    // Used to pass help text to the preCalibrationDialog dialog
    property string preCalibrationDialogHelp

    readonly property int sideBarH1PointSize:  ScreenTools.mediumFontPixelSize
    readonly property int mainTextH1PointSize: ScreenTools.mediumFontPixelSize // Seems to be unused

    readonly property int rotationColumnWidth: 250

    property Fact compass1Id:       controller.getParameterFact(-1, "COMPASS_DEV_ID")
    property Fact compass2Id:       controller.getParameterFact(-1, "COMPASS_DEV_ID2")
    property Fact compass3Id:       controller.getParameterFact(-1, "COMPASS_DEV_ID3")
    property Fact compass1External: controller.getParameterFact(-1, "COMPASS_EXTERNAL")
    property Fact compass2External: controller.getParameterFact(-1, "COMPASS_EXTERN2")
    property Fact compass3External: controller.getParameterFact(-1, "COMPASS_EXTERN3")
    property Fact compass1Rot:      controller.getParameterFact(-1, "COMPASS_ORIENT")
    property Fact compass2Rot:      controller.getParameterFact(-1, "COMPASS_ORIENT2")
    property Fact compass3Rot:      controller.getParameterFact(-1, "COMPASS_ORIENT3")
    property Fact compass1Use:      controller.getParameterFact(-1, "COMPASS_USE")
    property Fact compass2Use:      controller.getParameterFact(-1, "COMPASS_USE2")
    property Fact compass3Use:      controller.getParameterFact(-1, "COMPASS_USE3")

    property Fact boardRot:     controller.getParameterFact(-1, "AHRS_ORIENTATION")

    property bool accelCalNeeded:   controller.accelSetupNeeded
    property bool compassCalNeeded: controller.compassSetupNeeded

    // Id > = signals compass available, rot < 0 signals internal compass
    property bool showCompass1Rot: compass1Id.value > 0 && compass1External.value != 0 && compass1Use.value != 0
    property bool showCompass2Rot: compass2Id.value > 0 && compass2External.value != 0 && compass2Use.value != 0
    property bool showCompass3Rot: compass3Id.value > 0 && compass3External.value != 0 && compass3Use.value != 0

    APMSensorsComponentController {
        id:                         controller
        factPanel:                  panel
        statusLog:                  statusTextArea
        progressBar:                progressBar
        compassButton:              compassButton
        accelButton:                accelButton
        nextButton:                 nextButton
        cancelButton:               cancelButton
        orientationCalAreaHelpText: orientationCalAreaHelpText

        onResetStatusTextArea: statusLog.text = statusTextAreaDefaultText

        onWaitingForCancelChanged: {
            if (controller.waitingForCancel) {
                showMessage("Calibration Cancel", "Waiting for Vehicle to response to Cancel. This may take a few seconds.", 0)
            } else {
                hideDialog()
            }
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: panel.enabled }

    Component {
        id: preCalibrationDialogComponent

        QGCViewDialog {
            id: preCalibrationDialog

            function accept() {
                if (preCalibrationDialogType == "accel") {
                    controller.calibrateAccel()
                } else if (preCalibrationDialogType == "compass") {
                    controller.calibrateCompass()
                }
                preCalibrationDialog.hideDialog()
            }

            QGCLabel {
                id:             label
                anchors.left:   parent.left
                anchors.right:  parent.right
                wrapMode:       Text.WordWrap
                text:           "Before calibrating make sure orientation settings are correct."
            }

            Loader {
                id:                 rotationsLoader
                anchors.topMargin:  ScreenTools.defaultFontPixelHeight
                anchors.top:        label.bottom
                anchors.left:       parent.left
                anchors.right:      parent.right
                sourceComponent:    rotationCombosComponent

                property bool showCompassRotations: preCalibrationDialogType == "accel" ? false : true
            }
        }
    }

    Component {
        id: rotationCombosComponent

        Column {
            QGCLabel {
                font.pixelSize: sideBarH1PointSize
                text:           "Set Orientations"
            }

            Item {
                width:  1
                height: ScreenTools.defaultFontPixelHeight
            }

            QGCLabel {
                width:      parent.width
                wrapMode:   Text.WordWrap
                text:       orientationHelp
            }

            Item {
                width:  1
                height: ScreenTools.defaultFontPixelHeight
            }

            // Board rotation
            QGCLabel {
                text:           "Autopilot Orientation"
            }

            FactComboBox {
                id:         boardRotationCombo
                width:      parent.width
                fact:       boardRot
                indexModel: false
            }

            Item {
                width:  1
                height: ScreenTools.defaultFontPixelHeight
            }

            // Compass 1 rotation
            QGCLabel {
                text:       "Compass 1 Orientation"
                visible:    showCompassRotations && showCompass1Rot
            }

            FactComboBox {
                width:      parent.width
                fact:       compass1Rot
                indexModel: false
                visible:    showCompassRotations && showCompass1Rot
            }

            Item {
                width:  1
                height: ScreenTools.defaultFontPixelHeight
            }

            // Compass 2 rotation
            QGCLabel {
                text:       "Compass 2 Orientation"
                visible:    showCompassRotations && showCompass2Rot
            }

            FactComboBox {
                width:      parent.width
                fact:       compass2Rot
                indexModel: false
                visible:    showCompassRotations && showCompass2Rot
            }

            Item {
                width:  1
                height: ScreenTools.defaultFontPixelHeight
            }

            // Compass 3 rotation
            QGCLabel {
                text:       "Compass 3 Orientation"
                visible:    showCompassRotations && showCompass3Rot
            }

            FactComboBox {
                width:      parent.width
                fact:       compass3Rot
                indexModel: false
                visible:    showCompassRotations && showCompass3Rot
            }
        } // Column
    } // Component - Rotation combos

    QGCViewPanel {
        id:             panel
        anchors.fill:   parent

        Row {
            id:         buttonsRow
            spacing:    ScreenTools.defaultFontPixelWidth

            readonly property int buttonWidth: ScreenTools.defaultFontPixelWidth * 15

            QGCLabel { text: "Calibrate:"; anchors.baseline: compassButton.baseline }

            IndicatorButton {
                id:             compassButton
                width:          parent.buttonWidth
                text:           "Compass"
                indicatorGreen: !compassCalNeeded

                onClicked: {
                    if (controller.accelSetupNeeded) {
                        showMessage("Calibrate Compass", "Accelerometer must be calibrated prior to Compass.", StandardButton.Ok)
                    } else if (compass3Id.value != 0 && compass3Use.value !=0) {
                        showMessage("Unabled to calibrate", "Support for calibrating compass 3 is currently not supported by QGroundControl.", StandardButton.Ok)
                    } else {
                        preCalibrationDialogType = "compass"
                        preCalibrationDialogHelp = compassHelp
                        showDialog(preCalibrationDialogComponent, "Calibrate Compass", 50, StandardButton.Cancel | StandardButton.Ok)
                    }
                }
            }

            IndicatorButton {
                id:             accelButton
                width:          parent.buttonWidth
                text:           "Accelerometer"
                indicatorGreen: !accelCalNeeded

                onClicked: {
                    preCalibrationDialogType = "accel"
                    preCalibrationDialogHelp = accelHelp
                    showDialog(preCalibrationDialogComponent, "Calibrate Accelerometer", 50, StandardButton.Cancel | StandardButton.Ok)
                }
            }
            QGCButton {
                id:         nextButton
                showBorder: true
                text:       "Next"
                enabled:    false
                onClicked:  controller.nextClicked()
            }

            QGCButton {
                id:         cancelButton
                showBorder: true
                text:       "Cancel"
                enabled:    false
                onClicked:  controller.cancelCalibration()
            }
        } // Row - Cal buttons

        ProgressBar {
            id:                 progressBar
            anchors.topMargin:  ScreenTools.defaultFontPixelHeight
            anchors.top:        buttonsRow.bottom
            anchors.left:       parent.left
            anchors.right:      rotationsLoader.left
        }

        Item {
            anchors.topMargin:      ScreenTools.defaultFontPixelHeight
            anchors.rightMargin:    ScreenTools.defaultFontPixelHeight
            anchors.top:            progressBar.bottom
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          rotationsLoader.left

            TextArea {
                id:             statusTextArea
                anchors.fill:   parent
                readOnly:       true
                frameVisible:   false
                text:           statusTextAreaDefaultText

                style: TextAreaStyle {
                    textColor: qgcPal.text
                    backgroundColor: qgcPal.windowShade
                }
            }

            Rectangle {
                id:             orientationCalArea
                anchors.fill:   parent
                visible:        controller.showOrientationCalArea
                color:          qgcPal.windowShade

                QGCLabel {
                    id:                 orientationCalAreaHelpText
                    anchors.margins:    ScreenTools.defaultFontPixelWidth
                    anchors.top:        orientationCalArea.top
                    anchors.left:       orientationCalArea.left
                    width:              parent.width
                    wrapMode:           Text.WordWrap
                    font.pixelSize:     ScreenTools.mediumFontPixelSize
                }

                Flow {
                    anchors.topMargin:  ScreenTools.defaultFontPixelWidth
                    anchors.top:        orientationCalAreaHelpText.bottom
                    anchors.left:       orientationCalAreaHelpText.left
                    width:              parent.width
                    height:             parent.height - orientationCalAreaHelpText.implicitHeight
                    spacing:            ScreenTools.defaultFontPixelWidth

                    VehicleRotationCal {
                        visible:            controller.orientationCalDownSideVisible
                        calValid:           controller.orientationCalDownSideDone
                        calInProgress:      controller.orientationCalDownSideInProgress
                        calInProgressText:  controller.orientationCalDownSideRotate ? "Rotate" : "Hold Still"
                        imageSource:        controller.orientationCalDownSideRotate ? "qrc:///qmlimages/VehicleDownRotate.png" : "qrc:///qmlimages/VehicleDown.png"
                    }
                    VehicleRotationCal {
                        visible:            controller.orientationCalUpsideDownSideVisible
                        calValid:           controller.orientationCalUpsideDownSideDone
                        calInProgress:      controller.orientationCalUpsideDownSideInProgress
                        calInProgressText:  controller.orientationCalUpsideDownSideRotate ? "Rotate" : "Hold Still"
                        imageSource:        controller.orientationCalUpsideDownSideRotate ? "qrc:///qmlimages/VehicleUpsideDownRotate.png" : "qrc:///qmlimages/VehicleUpsideDown.png"
                    }
                    VehicleRotationCal {
                        visible:            controller.orientationCalNoseDownSideVisible
                        calValid:           controller.orientationCalNoseDownSideDone
                        calInProgress:      controller.orientationCalNoseDownSideInProgress
                        calInProgressText:  controller.orientationCalNoseDownSideRotate ? "Rotate" : "Hold Still"
                        imageSource:        controller.orientationCalNoseDownSideRotate ? "qrc:///qmlimages/VehicleNoseDownRotate.png" : "qrc:///qmlimages/VehicleNoseDown.png"
                    }
                    VehicleRotationCal {
                        visible:            controller.orientationCalTailDownSideVisible
                        calValid:           controller.orientationCalTailDownSideDone
                        calInProgress:      controller.orientationCalTailDownSideInProgress
                        calInProgressText:  controller.orientationCalTailDownSideRotate ? "Rotate" : "Hold Still"
                        imageSource:        controller.orientationCalTailDownSideRotate ? "qrc:///qmlimages/VehicleTailDownRotate.png" : "qrc:///qmlimages/VehicleTailDown.png"
                    }
                    VehicleRotationCal {
                        visible:            controller.orientationCalLeftSideVisible
                        calValid:           controller.orientationCalLeftSideDone
                        calInProgress:      controller.orientationCalLeftSideInProgress
                        calInProgressText:  controller.orientationCalLeftSideRotate ? "Rotate" : "Hold Still"
                        imageSource:        controller.orientationCalLeftSideRotate ? "qrc:///qmlimages/VehicleLeftRotate.png" : "qrc:///qmlimages/VehicleLeft.png"
                    }
                    VehicleRotationCal {
                        visible:            controller.orientationCalRightSideVisible
                        calValid:           controller.orientationCalRightSideDone
                        calInProgress:      controller.orientationCalRightSideInProgress
                        calInProgressText:  controller.orientationCalRightSideRotate ? "Rotate" : "Hold Still"
                        imageSource:        controller.orientationCalRightSideRotate ? "qrc:///qmlimages/VehicleRightRotate.png" : "qrc:///qmlimages/VehicleRight.png"
                    }
                }
            }
        } // Item - Cal display area

        Loader {
            id:                 rotationsLoader
            anchors.topMargin:  ScreenTools.defaultFontPixelHeight
            anchors.right:      parent.right
            width:              rotationColumnWidth
            sourceComponent:    rotationCombosComponent

            property bool showCompassRotations: true
        }
    } // QGCViewPanel
} // QGCView
