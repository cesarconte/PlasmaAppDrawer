import QtQuick 2.12
import QtQuick.Layouts 1.12
import Qt5Compat.GraphicalEffects
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import QtQuick.Controls 2.15
import QtQuick.Templates as T
import org.kde.plasma.plasmoid
import CachyOS.UI

import "../code/tools.js" as Tools

T.ItemDelegate {
	id: listDelegate

	property bool compact: Plasmoid.configuration.compactListItems
	property bool showDescription: Plasmoid.configuration.showListItemDescription

	property int itemHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset, implicitContentHeight + topPadding + bottomPadding)
	
	implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
							implicitContentWidth + leftPadding + rightPadding)
	implicitHeight: itemHeight
	leftPadding: compact ? 6 : 10
	rightPadding: compact ? 6 : 10
	bottomPadding: compact ? 6 : 8
	topPadding: compact ? 6 : 8

	background: Rectangle {
		radius: CachyTheme.radiusMedium
		color: {
			if (ma.containsMouse || (listView.currentIndex === index && listView.activeFocus)) {
				return CachyPalette.cardBackgroundHover;
			}
			return "transparent";
		}
		border.width: (ma.containsMouse || (listView.currentIndex === index && listView.activeFocus)) ? 1 : 0
		border.color: CachyPalette.specularBorder

		Behavior on color {
			ColorAnimation { duration: 120 }
		}
	}

	property bool isDraging: false

	signal aboutToShowActionMenu(variant actionMenu)

	property bool hasActionList: ((model.favoriteId !== null) || (("hasActionList" in model) && (model.hasActionList !== null)))

	property var triggerModel

	onAboutToShowActionMenu: {
		var actionList = listDelegate.hasActionList ? model.actionList : [];
		//Tools.fillActionMenu(i18n, actionMenu, actionList, ListView.view.model.favoritesModel, model.favoriteId);
		Tools.fillActionMenu(i18n, actionMenu, actionList, globalFavorites, model.favoriteId);
	}

	function openActionMenu(x, y) {
		aboutToShowActionMenu(actionMenu);      
		actionMenu.visualParent = listDelegate;
		actionMenu.open(x, y);
	}
	function actionTriggered(actionId, actionArgument) {
		var close = (Tools.triggerAction(triggerModel, index, actionId, actionArgument) === true);
		if (close) {
			if (typeof root !== "undefined" && root && root.toggle) {
				root.toggle();
			} else if (typeof kicker !== "undefined" && kicker && kicker.dashWindow) {
				kicker.dashWindow.visible = false;
			}
		}
	}
	function trigger() {
		triggerModel.trigger(index, "", null);
		if (typeof root !== "undefined" && root && root.toggle) {
			root.toggle();
		} else if (typeof kicker !== "undefined" && kicker && kicker.dashWindow) {
			kicker.dashWindow.visible = false;
		}
	}

 	contentItem: RowLayout {
		id: row
		spacing: 8
		Kirigami.Icon {
			id: icon
			implicitWidth: compact ? Kirigami.Units.iconSizes.smallMedium : Kirigami.Units.iconSizes.medium
			implicitHeight: implicitWidth
			Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
			
			source: model.decoration // || root.icon.name || root.icon.source
		}

		GridLayout {
			id: gridLayout

			Layout.fillWidth: true

			rows: listDelegate.compact ? 1 : 2
			columns: listDelegate.compact ? 2 : 1
			rowSpacing: 0
			columnSpacing: Kirigami.Units.largeSpacing

			Label {
				id: label
				Layout.fillWidth: !descriptionLabel.visible
				Layout.maximumWidth: listDelegate.width - listDelegate.leftPadding - listDelegate.rightPadding - icon.width - row.spacing
				text: ("name" in model ? model.name : model.display)
				textFormat: Text.PlainText
				elide: Text.ElideRight
				wrapMode: Text.NoWrap
				font.pixelSize: 12
				font.weight: (ma.containsMouse || listView.currentIndex === index) ? Font.DemiBold : Font.Normal
				verticalAlignment: Text.AlignVCenter
				color: CachyPalette.text
			}

			Label {
				id: descriptionLabel
				Layout.fillWidth: true
				visible: text && showDescription
				text: model.description
				textFormat: Text.PlainText
				font.pixelSize: 10
				elide: Text.ElideRight
				verticalAlignment: Text.AlignVCenter
				horizontalAlignment: listDelegate.compact ? Text.AlignRight : Text.AlignLeft
				maximumLineCount: 1
				color: CachyPalette.textMuted
			}
		}
	}

	MouseArea {
		id: ma
		anchors.fill: parent
		z: parent.z + 1
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		hoverEnabled:  !listView.movedWithWheel && !listView.blockingHoverFocus
		onClicked: {
			if (mouse.button == Qt.RightButton) {
				if (listDelegate.hasActionList) {
					var mapped = mapToItem(listDelegate, mouse.x, mouse.y);
					listDelegate.openActionMenu(mapped.x, mapped.y);
				}
			} else { trigger(); }
		}
		onReleased: { isDraging: false; }

		onEntered: {
			// - When the movedWithKeyboard condition is broken, we do not want to
			//   select the hovered item without moving the mouse.
			// - Don't highlight separators.
			// - Don't switch category items on hover if the setting isn't enabled
			if (listView.movedWithKeyboard) {
				return
			}

			// forceActiveFocus() touches multiple items, so check for
			// activeFocus first to be more efficient.
			if (!listView.activeFocus) {
				listView.forceActiveFocus(Qt.MouseFocusReason)
			}
			// No need to check currentIndex first because it's
			// built into QQuickListView::setCurrentIndex() already
			listView.currentIndex = index
		}
		onPositionChanged: {
			isDraging = pressed
			if (pressed && canDrag){
				if ("pluginName" in model) {
					dragHelper.startDrag(kicker, model.url, model.decoration, "text/x-plasmoidservicename", model.pluginName);
				} else {
					dragHelper.startDrag(kicker, model.url, model.decoration);
				}
			}
		}
	}
	ActionMenu {
		id: actionMenu

		onActionClicked: {
			visualParent.actionTriggered(actionId, actionArgument);
		}
	}
}
