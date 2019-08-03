/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2019 Slava Monich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../js/Utils.js" as Utils

Page {
    id: textPage

    allowedOrientations: window.allowedOrientations

    property string text
    property string recordId
    property string timestamp
    property bool hasImage
    property bool canDelete
    property alias format: textArea.label
    readonly property string normalizedText: Utils.convertLineBreaks(text)
    readonly property bool isVCard: Utils.isVcard(normalizedText)
    readonly property bool haveContact: vcard ? (vcard.count > 0) : false
    property var vcard

    signal deleteEntry()

    onNormalizedTextChanged: {
        textArea.text = normalizedText
        if (vcard) {
            vcard.content = normalizedText
        }
    }

    onIsVCardChanged: {
        if (isVCard && !vcard) {
            var component = Qt.createComponent("VCard.qml");
            if (component.status === Component.Ready) {
                vcard = component.createObject(textPage, { content: text })
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            // Hide the keyboard on flick
            textArea.focus = false
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            visible: textPage.canDelete
            MenuItem {
                //: Context menu item
                //% "Delete"
                text: qsTrId("history-menu-delete")
                onClicked: textPage.deleteEntry()
            }
        }

        Column {
            id: column

            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            height: childrenRect.height

            //: Page header
            //% "Decoded text"
            PageHeader { title: qsTrId("text-header") }

            TextArea {
                id: textArea
                width: parent.width
                selectionMode: TextEdit.SelectWords
                labelVisible: true
                readOnly: false
                wrapMode: TextEdit.Wrap
                property int lastCursorPosition
                property int currentCursorPosition
                property bool settingTextFromTextChangedHandler
                onCursorPositionChanged: {
                    lastCursorPosition = currentCursorPosition
                    currentCursorPosition = cursorPosition
                }
                onTextChanged: {
                    if (settingTextFromTextChangedHandler) {
                        // TextArea isn't just accepting the text, sometimes
                        // it internally mutates it which can send us into
                        // an infinite setText/textChanged/setText recursion.
                        // We don't want that to happen.
                        console.warn("refusing to recurse!")
                    } else if (text !== textPage.normalizedText) {
                        settingTextFromTextChangedHandler = true
                        text = textPage.normalizedText
                        settingTextFromTextChangedHandler = false
                        // The text doesn't actually get updated until the
                        // cursor position changes
                        cursorPosition = lastCursorPosition
                    }
                }
            }

            Item {
                height: Theme.paddingMedium
                width: parent.width
            }

            Button {
                id: button
                anchors.horizontalCenter: parent.horizontalCenter
                //: Button text
                //% "Open link"
                text: qsTrId("text-open_link")
                visible: Utils.isLink(textPage.text)
                enabled: !holdOffTimer.running
                onClicked: {
                    console.log("opening", textPage.text)
                    Qt.openUrlExternally(textPage.text)
                    holdOffTimer.restart()
                }
                Timer {
                    id: holdOffTimer
                    interval: 2000
                }
            }

            Item {
                visible: button.visible
                height: Theme.paddingLarge
                width: parent.width
            }

            Button {
                id: contactButton
                anchors.horizontalCenter: parent.horizontalCenter
                //: Button text
                //% "Contact card"
                text: qsTrId("text-contact_card")
                visible: haveContact
                onClicked: {
                    // Workaround for Sailfish.Contacts not being allowed in harbour apps
                    var page = Qt.createQmlObject("import QtQuick 2.0;import Sailfish.Silica 1.0;import Sailfish.Contacts 1.0; \
Page { id: page; signal saveContact(); property alias contact: card.contact; property alias saveText: saveMenu.text; \
ContactCard { id: card; PullDownMenu { MenuItem { id: saveMenu; onClicked: page.saveContact(); }}}}",
                        textPage, "ContactPage")
                    pageStack.push(page, {
                        contact: textPage.vcard.contact(),
                        allowedOrientations: textPage.allowedOrientations,
                        //: Pulley menu item (saves contact)
                        //% "Save"
                        saveText: qsTrId("contact-menu-save")
                    }).saveContact.connect(function() {
                       pageStack.pop()
                       textPage.vcard.importContact()
                    })
                }
            }

            Item {
                visible: contactButton.visible
                height: Theme.paddingLarge
                width: parent.width
            }

            Image {
                id: image

                readonly property bool isPortrait: sourceSize.height > sourceSize.width
                readonly property bool rotate: image.isPortrait != textPage.isPortrait

                anchors.horizontalCenter: parent.horizontalCenter
                source: (hasImage && recordId.length && AppSettings.saveImages) ?
                    ("image://scanner/saved/" + (textPage.isPortrait ? "portrait/" : "landscape/") + recordId) : ""
                visible: status === Image.Ready
                asynchronous: true
                cache: false
            }

            Item {
                visible: timestampLabel.visible
                height: Theme.paddingSmall
                width: parent.width
            }

            Label {
                id: timestampLabel
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: timestamp
                visible: image.visible && timestamp.length > 0
            }

            Item {
                visible: image.visible
                height: Theme.paddingLarge
                width: parent.width
            }
        }

        VerticalScrollDecorator { }
    }
}
