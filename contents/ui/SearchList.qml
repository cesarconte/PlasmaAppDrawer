import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import CachyOS.UI
import "../code/tools.js" as Tools

Item {
    id: searchList

    property alias count: resultsView.count
    property alias currentIndex: resultsView.currentIndex
    property alias model: resultsView.model

    function triggerCurrent() {
        if (resultsView.count > 0) {
            var targetIdx = Math.max(0, resultsView.currentIndex);
            if (resultsView.model && resultsView.model.trigger) {
                resultsView.model.trigger(targetIdx, "", null);
                if (typeof root !== "undefined" && root && root.toggle) {
                    root.toggle();
                } else if (typeof kicker !== "undefined" && kicker && kicker.dashWindow) {
                    kicker.dashWindow.visible = false;
                }
            }
        }
    }

    // Results ListView
    ListView {
        id: resultsView
        anchors.fill: parent
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 80

        header: Item {
            width: resultsView.width
            height: 24
            visible: resultsView.count > 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Text {
                    text: i18n("Mejor resultado")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: CachyTheme.accentColor
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: i18n("↵ para abrir")
                    font.pixelSize: 10
                    color: CachyPalette.textMuted
                }
            }
        }

        delegate: Rectangle {
            id: resultDelegate
            required property int index
            required property var model

            readonly property bool isSelected: resultsView.currentIndex === index
            readonly property bool isTopHit: index === 0

            width: resultsView.width
            implicitHeight: isTopHit ? 52 : 44
            height: implicitHeight
            radius: isTopHit ? CachyTheme.radiusLarge : CachyTheme.radiusMedium
            clip: true

            color: {
                if (isSelected) {
                    return isTopHit ? CachyTheme.withAlpha(CachyTheme.accentColor, CachyPalette.isDark ? 0.32 : 0.20) : CachyPalette.cardBackgroundHover;
                }
                return isTopHit ? CachyPalette.cardBackground : "transparent";
            }
            border.width: isSelected || isTopHit ? 1 : 0
            border.color: isSelected ? CachyTheme.withAlpha(CachyTheme.accentColor, 0.6) : CachyPalette.specularBorder

            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Item {
                    Layout.preferredWidth: isTopHit ? 34 : 26
                    Layout.preferredHeight: isTopHit ? 34 : 26
                    Layout.alignment: Qt.AlignVCenter

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: resultDelegate.model.decoration || ""
                    }

                    // Running dot
                    Rectangle {
                        visible: (kicker && kicker.isAppRunning) ? kicker.isAppRunning(resultDelegate.model.appId, resultDelegate.model.url) : false
                        width: 4
                        height: 4
                        radius: 2
                        anchors.top: parent.bottom
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: CachyTheme.accentColor
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: ("name" in resultDelegate.model ? resultDelegate.model.name : resultDelegate.model.display) || ""
                            font.pixelSize: isTopHit ? 13 : 12
                            font.weight: isTopHit || isSelected ? Font.DemiBold : Font.Normal
                            color: CachyPalette.text
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        // Category tag (e.g. Calculadora, Aplicaciones, Lugares)
                        Rectangle {
                            readonly property string catName: (resultDelegate.model.category || "").trim()
                            visible: catName.length > 0 && catName.length < 24
                            Layout.preferredHeight: 18
                            Layout.preferredWidth: catText.implicitWidth + 10
                            radius: 4
                            color: CachyTheme.withAlpha(CachyPalette.text, 0.08)

                            Text {
                                id: catText
                                anchors.centerIn: parent
                                text: parent.catName
                                font.pixelSize: 9
                                color: CachyPalette.textMuted
                            }
                        }
                    }

                    Text {
                        readonly property string desc: (resultDelegate.model.description || "").trim()
                        visible: desc.length > 0
                        Layout.fillWidth: true
                        text: desc
                        font.pixelSize: 10
                        color: CachyPalette.textMuted
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                // Top hit shortcut return icon
                Kirigami.Icon {
                    visible: isTopHit
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    Layout.alignment: Qt.AlignVCenter
                    source: "edit-undo"
                    color: isSelected ? CachyTheme.accentColor : CachyPalette.textMuted
                }
            }

            HoverHandler {
                id: resHover
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    if (hovered) {
                        resultsView.currentIndex = resultDelegate.index;
                    }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    searchList.triggerCurrent();
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: eventPoint => {
                    var modelData = resultDelegate.model;
                    if (modelData) {
                        var appUrl = modelData.url || (modelData.urls && modelData.urls.length > 0 ? modelData.urls[0] : "") || modelData.favoriteId || "";
                        var favId = modelData.favoriteId || "";
                        var isPinned = (kicker && kicker.isDockPinnedSync && appUrl) ? kicker.isDockPinnedSync(appUrl) : false;
                        var rawActions = (modelData.hasActionList !== null && modelData.actionList) ? modelData.actionList : [];
                        Tools.fillActionMenu(i18n, searchActionMenu, rawActions, globalFavorites, favId, appUrl, isPinned);
                        searchActionMenu.visualParent = resultDelegate;
                        searchActionMenu.open(eventPoint.position.x, eventPoint.position.y);
                    }
                }
            }

            ActionMenu {
                id: searchActionMenu
                onActionClicked: (actionId, actionArgument) => {
                    if (Tools.triggerAction(resultsView.model, resultDelegate.index, actionId, actionArgument, kicker) === true) {
                        if (typeof root !== "undefined" && root && root.toggle) {
                            root.toggle();
                        } else if (typeof kicker !== "undefined" && kicker && kicker.dashWindow) {
                            kicker.dashWindow.visible = false;
                        }
                    }
                }
            }
        }
    }

    // Empty state hint
    Loader {
        anchors.fill: parent
        active: resultsView.count === 0 && runnerModel.query.length > 0
        visible: active

        sourceComponent: PlasmaExtras.PlaceholderMessage {
            id: emptyHint
            iconName: "edit-none"
            text: i18nc("@info:status", "No matches found in Spotlight")
        }
    }

    Connections {
        target: runnerModel
        function onQueryChanged() { 
            resultsView.model = runnerModel.modelForRow(0);
            resultsView.currentIndex = 0;
        }
        function onQueryFinished() {
            if (!resultsView.model) {
                resultsView.model = runnerModel.modelForRow(0);
            }
            if (resultsView.currentIndex < 0 && resultsView.count > 0) {
                resultsView.currentIndex = 0;
            }
        }
    }

    Keys.onDownPressed: {
        if (resultsView.currentIndex < resultsView.count - 1) {
            resultsView.currentIndex++;
        }
    }

    Keys.onUpPressed: {
        if (resultsView.currentIndex > 0) {
            resultsView.currentIndex--;
        } else {
            searchBar.textField.forceActiveFocus();
        }
    }

    Keys.onReturnPressed: searchList.triggerCurrent()
    Keys.onEnterPressed: searchList.triggerCurrent()
}
