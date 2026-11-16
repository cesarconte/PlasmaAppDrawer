import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import CachyOS.UI
import "../code/tools.js" as Tools

Rectangle {
    id: categoryCard

    property string title: ""
    property var categoryModel: null
    property int totalCount: categoryModel ? categoryModel.count : 0

    function updateCount() {
        totalCount = categoryModel ? categoryModel.count : 0;
    }

    onCategoryModelChanged: updateCount()

    Connections {
        target: categoryCard.categoryModel
        ignoreUnknownSignals: true
        function onModelReset() { categoryCard.updateCount(); }
        function onRowsInserted() { categoryCard.updateCount(); }
        function onRowsRemoved() { categoryCard.updateCount(); }
        function onCountChanged() { categoryCard.updateCount(); }
        function onLayoutChanged() { categoryCard.updateCount(); }
    }

    signal expandRequested()

    implicitWidth: 176
    implicitHeight: 200
    radius: CachyTheme.radiusLarge
    color: CachyPalette.cardBackground
    border.width: 1
    border.color: CachyPalette.specularBorder

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Category Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: categoryCard.title
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: CachyPalette.text
                elide: Text.ElideRight
            }

            Text {
                visible: categoryCard.totalCount > 4
                text: String(categoryCard.totalCount)
                font.pixelSize: 10
                font.weight: Font.Medium
                color: CachyPalette.textMuted
            }
        }

        // 2x2 Apps Grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rows: 2
            rowSpacing: 4
            columnSpacing: 4

            // Slot 0 (Top-Left)
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: (categoryCard.totalCount > 0) ? appSlotComponent : null
                property int slotIndex: 0
            }

            // Slot 1 (Top-Right)
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: (categoryCard.totalCount > 1) ? appSlotComponent : null
                property int slotIndex: 1
            }

            // Slot 2 (Bottom-Left)
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: (categoryCard.totalCount > 2) ? appSlotComponent : null
                property int slotIndex: 2
            }

            // Slot 3 (Bottom-Right: either 4th app or Mini-Folder)
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: {
                    if (categoryCard.totalCount <= 0) return null;
                    if (categoryCard.totalCount <= 4) return appSlotComponent;
                    return miniFolderComponent;
                }
                property int slotIndex: 3
            }
        }
    }

    // Component for individual app slots (0, 1, 2, and 3 if <= 4 apps)
    Component {
        id: appSlotComponent

        Rectangle {
            id: slotRect
            property int targetIndex: slotIndex
            property var itemData: (categoryCard.categoryModel && targetIndex < categoryCard.categoryModel.count) ? {
                display: categoryCard.categoryModel.data(categoryCard.categoryModel.index(targetIndex, 0), Qt.DisplayRole) || "",
                decoration: categoryCard.categoryModel.data(categoryCard.categoryModel.index(targetIndex, 0), Qt.DecorationRole) || "",
                url: categoryCard.categoryModel.data(categoryCard.categoryModel.index(targetIndex, 0), 266) || categoryCard.categoryModel.data(categoryCard.categoryModel.index(targetIndex, 0), 259) || "",
                appId: categoryCard.categoryModel.data(categoryCard.categoryModel.index(targetIndex, 0), 259) || ""
            } : null

            radius: CachyTheme.radiusMedium
            color: slotHover.hovered ? CachyPalette.cardBackgroundHover : "transparent"
            border.width: slotHover.hovered ? 1 : 0
            border.color: CachyPalette.specularBorder

            Behavior on color { ColorAnimation { duration: 120 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 2

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36

                    Kirigami.Icon {
                        id: slotIcon
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        source: slotRect.itemData ? slotRect.itemData.decoration : ""
                        scale: slotHover.hovered ? 1.08 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }

                    // Running dot
                    Rectangle {
                        visible: (typeof kicker !== "undefined" && kicker && kicker.isAppRunning && slotRect.itemData) ? kicker.isAppRunning(slotRect.itemData.appId, slotRect.itemData.url) : false
                        width: 4
                        height: 4
                        radius: 2
                        anchors.top: slotIcon.bottom
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: CachyTheme.accentColor
                    }

                    // Notification Badge
                    CachyBadge {
                        readonly property string bText: (typeof kicker !== "undefined" && kicker && kicker.getAppBadge && slotRect.itemData) ? kicker.getAppBadge(slotRect.itemData.appId, slotRect.itemData.url) : ""
                        visible: bText.length > 0
                        text: bText
                        badgeType: "accent"
                        anchors.top: slotIcon.top
                        anchors.topMargin: -3
                        anchors.right: slotIcon.right
                        anchors.rightMargin: -4
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: slotRect.itemData ? slotRect.itemData.display : ""
                    font.pixelSize: 10
                    font.weight: slotHover.hovered ? Font.DemiBold : Font.Normal
                    color: CachyPalette.text
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            HoverHandler {
                id: slotHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    if (categoryCard.categoryModel && categoryCard.categoryModel.trigger) {
                        categoryCard.categoryModel.trigger(slotRect.targetIndex, "", null);
                        if (typeof root !== "undefined" && root && root.toggle) {
                            root.toggle();
                        } else if (typeof kicker !== "undefined" && kicker && kicker.dashWindow) {
                            kicker.dashWindow.visible = false;
                        }
                    }
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: (eventPoint) => {
                    if (slotRect.itemData) {
                        var isPinned = (typeof kicker !== "undefined" && kicker && kicker.isDockPinnedSync) ? kicker.isDockPinnedSync(slotRect.itemData.url) : false;
                        var rawActions = [];
                        if (categoryCard.categoryModel && categoryCard.categoryModel.data) {
                            var actData = categoryCard.categoryModel.data(categoryCard.categoryModel.index(slotRect.targetIndex, 0), 265);
                            if (actData && Array.isArray(actData)) rawActions = actData;
                        }
                        Tools.fillActionMenu(i18n, slotActionMenu, rawActions, globalFavorites, slotRect.itemData.url, slotRect.itemData.url, isPinned);
                        slotActionMenu.visualParent = slotRect;
                        slotActionMenu.open(eventPoint.position.x, eventPoint.position.y);
                    }
                }
            }

            ActionMenu {
                id: slotActionMenu
                onActionClicked: (actionId, actionArgument) => {
                    if (Tools.triggerAction(categoryCard.categoryModel, slotRect.targetIndex, actionId, actionArgument, (typeof kicker !== "undefined" ? kicker : null)) === true) {
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

    // Component for Slot 3 when category has > 4 apps (Mini-Folder thumbnail)
    Component {
        id: miniFolderComponent

        Rectangle {
            id: folderSlot
            radius: CachyTheme.radiusMedium
            color: folderHover.hovered ? CachyPalette.cardBackgroundHover : CachyTheme.withAlpha(CachyPalette.text, 0.06)
            border.width: 1
            border.color: CachyPalette.specularBorder

            Behavior on color { ColorAnimation { duration: 120 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                // 2x2 Mini-Icons Grid
                GridLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    columns: 2
                    rows: 2
                    rowSpacing: 2
                    columnSpacing: 2

                    Repeater {
                        model: Math.min(4, Math.max(0, categoryCard.totalCount - 3))
                        Kirigami.Icon {
                            required property int index
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            source: {
                                var realIdx = index + 3;
                                if (categoryCard.categoryModel && realIdx < categoryCard.totalCount) {
                                    return categoryCard.categoryModel.data(categoryCard.categoryModel.index(realIdx, 0), Qt.DecorationRole) || "";
                                }
                                return "";
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "+" + String(categoryCard.totalCount - 3)
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: CachyTheme.accentColor
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            HoverHandler {
                id: folderHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: categoryCard.expandRequested()
            }
        }
    }
}
