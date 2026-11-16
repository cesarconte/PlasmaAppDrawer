import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import CachyOS.UI

RowLayout {
    spacing: 8

    property alias textField: textField

    Kirigami.Icon {
        id: searchIcon
        Layout.preferredWidth: 16
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter
        source: "search"
        color: CachyPalette.textMuted
    }

    TextField {
        id: textField
        Layout.fillHeight: true
        Layout.fillWidth: true
        font.pixelSize: 13
        color: CachyPalette.text
        placeholderText: i18n("Search applications, files, calculations…")
        placeholderTextColor: CachyPalette.textMuted
        background: Item {}
        focus: true
        onTextChanged: {
            textField.forceActiveFocus(Qt.ShortcutFocusReason)
            runnerModel.query = text;   
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (main.searching) {
                    clear();
                } else {
                    root.toggle();
                }
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true;
                if (main.searching) {
                    searchListView.triggerCurrent();
                }
            } else if (event.key === Qt.Key_Down) {
                event.accepted = true;
                if (main.searching) {
                    searchListView.forceActiveFocus();
                    if (searchListView.currentIndex < searchListView.count - 1) {
                        searchListView.currentIndex++;
                    }
                }
            } else if (event.key === Qt.Key_Up) {
                event.accepted = true;
                if (main.searching && searchListView.currentIndex > 0) {
                    searchListView.currentIndex--;
                }
            }
        }
    }

    // Clear search button
    Item {
        visible: textField.text.length > 0
        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: clearHover.hovered ? CachyPalette.cardBackgroundHover : "transparent"

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 12
                height: 12
                source: "edit-clear-symbolic"
                color: CachyPalette.textMuted
            }

            HoverHandler {
                id: clearHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: {
                    textField.clear();
                    textField.forceActiveFocus();
                }
            }
        }
    }
}