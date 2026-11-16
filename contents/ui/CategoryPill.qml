import QtQuick 
import org.kde.kirigami as Kirigami
import CachyOS.UI

Item {
    id: pill

    property alias text: pillText.text
    property bool selected: false
    signal clicked

    implicitWidth: pillText.implicitWidth + 24
    implicitHeight: 28

    Rectangle {
        id: pillBg
        anchors.fill: parent
        radius: height / 2
        color: {
            if (pill.selected) {
                return CachyTheme.accentColor;
            }
            if (hoverHandler.hovered) {
                return CachyPalette.cardBackgroundHover;
            }
            return CachyPalette.cardBackground;
        }
        border.width: 1
        border.color: pill.selected ? CachyPalette.specularBorder : CachyPalette.subtleBorder

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    Text {
        id: pillText
        anchors.centerIn: parent
        font.pixelSize: 12
        font.weight: pill.selected ? Font.DemiBold : Font.Normal
        color: pill.selected ? CachyPalette.accentText : CachyPalette.text
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: pill.clicked()
    }
}
