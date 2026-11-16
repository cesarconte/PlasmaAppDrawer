/*****************************************************************************
 *   Copyright (C) 2022 by Friedrich Schriewer <friedrich.schriewer@gmx.net> *
 *   Copyright (C) 2026 CachyOS UI contributors                             *
 ****************************************************************************/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import CachyOS.UI

Item {
    id: main
    property bool searching: (searchBar.textField.text.trim() !== "")
    property alias isExpanded: appsCategorizedView.isExpanded

    readonly property color textColor: CachyPalette.text
    readonly property string textFont: Kirigami.Theme.defaultFont.family
    readonly property real textSize: Kirigami.Theme.defaultFont.pointSize
    readonly property color bgColor: CachyPalette.windowBackground
    readonly property color highlightColor: CachyTheme.accentColor
    readonly property color highlightedTextColor: CachyPalette.accentText
    readonly property bool isTop: plasmoid.location == PlasmaCore.Types.TopEdge & plasmoid.configuration.launcherPosition != 2 & !plasmoid.configuration.floating

    property bool isDarkTheme: CachyPalette.isDark
    property color contrastBgColor: CachyPalette.cardBackground
    property color dimmedTextColor: CachyPalette.textMuted

    function reload() {
        reset();
    }
    function reset() {
        searchBar.textField.clear();
        appsCategorizedView.reset();
    }

    function showContextMenu(target, x, y, actionList, cb) {
        if (main.parent && typeof main.parent.showContextMenu === "function") {
            main.parent.showContextMenu(target, x, y, actionList, cb);
        } else if (typeof fs !== "undefined" && fs && typeof fs.showContextMenu === "function") {
            fs.showContextMenu(target, x, y, actionList, cb);
        } else if (typeof root !== "undefined" && root && typeof root.showContextMenu === "function") {
            root.showContextMenu(target, x, y, actionList, cb);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Spotlight-style Search Bar Container
        Rectangle {
            id: searchBarContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.maximumHeight: Layout.preferredHeight
            Layout.rightMargin: fs.innerPadding
            radius: height / 2
            color: CachyPalette.cardBackground
            border.color: CachyPalette.specularBorder
            border.width: 1

            SearchBar {
                id: searchBar
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                Keys.forwardTo: main.searching ? [searchListView] : []
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.rightMargin: fs.innerPadding
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            height: 1
            color: CachyPalette.hardDividerColor
        }

        // Content Area Container (App Library or Spotlight Search)
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            AppsCategorized {
                id: appsCategorizedView
                anchors.fill: parent
                visible: !main.searching
            }

            SearchList {
                id: searchListView
                anchors.fill: parent
                visible: main.searching
                Keys.forwardTo: [searchBar.textField]
            }
        }
    }
}
