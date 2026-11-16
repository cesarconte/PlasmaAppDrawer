import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import CachyOS.UI

Item {
    id: appsCategorized

    property var categoriesList: []
    property var expandedCategoryModel: null
    property string expandedCategoryTitle: ""
    property bool isExpanded: expandedCategoryModel !== null

    function refreshCategories() {
        var list = [];
        if (!rootModel) return;
        for (var i = 4; i < rootModel.count; i++) {
            var name = rootModel.data(rootModel.index(i, 0), Qt.DisplayRole);
            if (!name || String(name).trim() === "" || name === "Inicio y apagado") continue;
            var sub = rootModel.modelForRow(i);
            if (!sub || sub.count === 0) continue;
            list.push({
                name: name,
                modelIndex: i,
                icon: rootModel.data(rootModel.index(i, 0), Qt.DecorationRole)
            });
        }
        categoriesList = list;
    }

    Component.onCompleted: refreshCategories()

    Connections {
        target: rootModel
        function onCountChanged() { appsCategorized.refreshCategories(); }
        function onRefreshed() { appsCategorized.refreshCategories(); }
    }

    // Overview state: Grid of Category Cards (macOS Tahoe App Library)
    ScrollView {
        id: overviewScroll
        anchors.fill: parent
        visible: !appsCategorized.isExpanded
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Flow {
            id: overviewFlow
            width: overviewScroll.availableWidth > 0 ? overviewScroll.availableWidth : overviewScroll.width
            spacing: 12
            padding: 8

            readonly property real cardWidth: Math.max(160, Math.floor((width - 28) / 2))

            // 1. Smart Card: Sugerencias (Top used / recent apps)
            CategoryCard {
                title: i18n("Sugerencias")
                categoryModel: rootModel.modelForRow(0)
                width: overviewFlow.cardWidth
                onExpandRequested: {
                    appsCategorized.expandedCategoryModel = rootModel.modelForRow(0);
                    appsCategorized.expandedCategoryTitle = i18n("Sugerencias");
                }
            }

            // 2. Smart Card: Añadidas recientemente
            CategoryCard {
                title: i18n("Añadidas recientemente")
                categoryModel: rootModel.modelForRow(2)
                width: overviewFlow.cardWidth
                onExpandRequested: {
                    appsCategorized.expandedCategoryModel = rootModel.modelForRow(2);
                    appsCategorized.expandedCategoryTitle = i18n("Añadidas recientemente");
                }
            }

            // 3. Regular Categories from system (Desarrollo, Gráficos, Internet, etc.)
            Repeater {
                model: appsCategorized.categoriesList

                CategoryCard {
                    required property var modelData
                    title: modelData.name || ""
                    categoryModel: rootModel.modelForRow(modelData.modelIndex)
                    width: overviewFlow.cardWidth
                    onExpandRequested: {
                        appsCategorized.expandedCategoryModel = rootModel.modelForRow(modelData.modelIndex);
                        appsCategorized.expandedCategoryTitle = modelData.name || "";
                    }
                }
            }
        }
    }

    // Expanded state: Full view of a selected category
    ColumnLayout {
        id: expandedView
        anchors.fill: parent
        visible: appsCategorized.isExpanded
        spacing: 8
        anchors.margins: 6

        // Expanded Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Back button (← Biblioteca)
            Rectangle {
                Layout.preferredHeight: 28
                Layout.preferredWidth: backContent.implicitWidth + 20
                radius: height / 2
                color: backHover.hovered ? CachyPalette.cardBackgroundHover : CachyPalette.cardBackground
                border.width: 1
                border.color: CachyPalette.specularBorder

                RowLayout {
                    id: backContent
                    anchors.centerIn: parent
                    spacing: 4

                    Kirigami.Icon {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        source: "arrow-left"
                        color: CachyPalette.text
                    }

                    Text {
                        text: i18n("Biblioteca")
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: CachyPalette.text
                    }
                }

                HoverHandler {
                    id: backHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        appsCategorized.expandedCategoryModel = null;
                        appsCategorized.expandedCategoryTitle = "";
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: appsCategorized.expandedCategoryTitle
                font.pixelSize: 15
                font.weight: Font.Bold
                color: CachyPalette.text
                elide: Text.ElideRight
            }

            Text {
                text: (appsCategorized.expandedCategoryModel ? appsCategorized.expandedCategoryModel.count : 0) + " " + i18n("apps")
                font.pixelSize: 11
                color: CachyPalette.textMuted
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: CachyPalette.hardDividerColor
        }

        // Full grid of apps in the expanded category
        GridView {
            id: expandedGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: root.cellSizeWidth
            cellHeight: root.cellSizeHeight
            model: appsCategorized.expandedCategoryModel

            delegate: AppGridViewDelegate {
                triggerModel: expandedGrid.model
            }
        }
    }

    function reset() {
        expandedCategoryModel = null;
        expandedCategoryTitle = "";
    }
}
