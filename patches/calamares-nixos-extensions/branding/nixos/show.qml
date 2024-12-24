/*
 *
 *   SPDX-FileCopyrightText: 2015 Teo Mrnjavac <teo@kde.org>
 *   SPDX-FileCopyrightText: 2018 Adriaan de Groot <groot@kde.org>
 *   SPDX-FileCopyrightText: 2022 Victor Fuentes <vmfuentes64@gmail.com>
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Calamares is Free Software: see the License-Identifier above.
 *
 */

import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        console.log("QML Component (default slideshow) Next slide");
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 15000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Text {
            id: text1
            anchors.centerIn: parent
            text: qsTr("A community of players")
            font.pixelSize: 30
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
            color: "#6586C8"
        }
        Image {
            id: background1
            source: "gaming.png"
            width: 200; height: 200
            fillMode: Image.PreserveAspectFit
            anchors.bottom: text1.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            anchors.horizontalCenter: background1.horizontalCenter
            anchors.top: text1.bottom
            text: qsTr("The tools you need to play are natively integrated.<br/>"+
                  "We also tested the applications needed by content creators for their work. <br/>")
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Text {
            id: text2
            anchors.centerIn: parent
            text: qsTr("Based on NixOS")
            font.pixelSize: 30
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
            color: "#6586C8"
        }
        Image {
            id: background2
            source: "base.png"
            width: 200; height: 200
            fillMode: Image.PreserveAspectFit
            anchors.bottom: text2.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            anchors.horizontalCenter: background2.horizontalCenter
            anchors.top: text2.bottom
            text: qsTr("Based on NixOS, installing or upgrading one package cannot break other packages.<br/>"+
                  "You can easily roll back to previous versions when you want.")
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Text {
            id: text3
            anchors.centerIn: parent
            text: "Fast"
            font.pixelSize: 30
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
            color: "#6586C8"
        }
        Image {
            id: background3
            source: "fast.png"
            width: 200; height: 200
            fillMode: Image.PreserveAspectFit
            anchors.bottom: text3.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            anchors.horizontalCenter: background3.horizontalCenter
            anchors.top: text3.bottom
            text: qsTr("GLF OS is fast. Really.<br/>"+
                  "It has been designed from the beginning for optimal out-of-the-box performance.<br/>"+
                  "It was designed from the outset to deliver optimum performance straight out of the box.")
            wrapMode: Text.WordWrap
            width: presentation.width
            horizontalAlignment: Text.Center
        }
    }

    // When this slideshow is loaded as a V1 slideshow, only
    // activatedInCalamares is set, which starts the timer (see above).
    //
    // In V2, also the onActivate() and onLeave() methods are called.
    // These example functions log a message (and re-start the slides
    // from the first).
    function onActivate() {
        console.log("QML Component (default slideshow) activated");
        presentation.currentSlide = 0;
    }

    function onLeave() {
        console.log("QML Component (default slideshow) deactivated");
    }

}
