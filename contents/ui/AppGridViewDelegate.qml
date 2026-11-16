import QtQuick 2.12
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami
import QtQuick.Controls 2.15
import CachyOS.UI

import "../code/tools.js" as Tools

Item {
	id: gridDelegate

	property var triggerModel

	width: root.cellSizeWidth
	height: root.cellSizeHeight

	signal itemActivated(int index, string actionId, string argument)
	signal actionTriggered(string actionId, variant actionArgument)
	signal aboutToShowActionMenu(variant actionMenu)

	property bool isDraging: false
	property bool highlighted: false
	readonly property bool isSelected: (grid.canMoveWithKeyboard ? focus : highlighted)

	property bool hasActionList: ((model.favoriteId !== null) || (("hasActionList" in model) && (model.hasActionList !== null)))

	function openActionMenu(visualParent, x, y) {
		var isPinned = (kicker && kicker.isDockPinnedSync) ? kicker.isDockPinnedSync(model.url) : false;
		const actionList = (model.hasActionList !== null && model.actionList) ? model.actionList : [];
		Tools.fillActionMenu(i18n, actionMenu, actionList, globalFavorites, model.favoriteId, model.url, isPinned);
		actionMenu.visualParent = visualParent;
		actionMenu.open(x, y);
	}

	function trigger() {
		triggerModel.trigger(index, "", null);
		if (typeof root !== "undefined" && root && root.toggle) {
			root.toggle();
		} else if (typeof kicker !== "undefined" && kicker && kicker.dashWindow) {
			kicker.dashWindow.visible = false;
		}
	}

	onActionTriggered: (actionId, actionArgument) => {
		if (Tools.triggerAction(triggerModel, model.index, actionId, actionArgument, kicker) === true) {
			if (typeof root !== "undefined" && root && root.toggle) {
				root.toggle();
			} else if (typeof kicker !== "undefined" && kicker && kicker.dashWindow) {
				kicker.dashWindow.visible = false;
			}
		}
	}

	Rectangle {
		id: cardBg
		anchors.fill: parent
		anchors.margins: 4
		radius: CachyTheme.radiusMedium
		color: isSelected ? CachyPalette.cardBackgroundHover : "transparent"
		border.width: isSelected ? 1 : 0
		border.color: CachyPalette.specularBorder

		Behavior on color {
			ColorAnimation { duration: 120 }
		}
	}

 	Kirigami.Icon {
		id: appicon
		anchors.top: parent.top
		anchors.topMargin: 10
		anchors.horizontalCenter: parent.horizontalCenter
		width: root.iconSize
		height: width
		source: model.decoration
		scale: isSelected ? 1.06 : 1.0

		Behavior on scale {
			NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
		}
	}

	// macOS Running Indicator Dot
	Rectangle {
		id: runningDot
		visible: (kicker && kicker.isAppRunning) ? kicker.isAppRunning(model.appId, model.url) : false
		width: 4
		height: 4
		radius: 2
		anchors.top: appicon.bottom
		anchors.topMargin: 2
		anchors.horizontalCenter: parent.horizontalCenter
		color: CachyTheme.accentColor
	}

	// macOS Notification Badge
	CachyBadge {
		id: notifBadge
		readonly property string badgeVal: (kicker && kicker.getAppBadge) ? kicker.getAppBadge(model.appId, model.url) : ""
		visible: badgeVal.length > 0
		text: badgeVal
		badgeType: "accent"
		anchors.top: appicon.top
		anchors.topMargin: -4
		anchors.right: appicon.right
		anchors.rightMargin: -6
	}

	PlasmaComponents.Label {
		id: appname
		text: ("name" in model ? model.name : model.display)
		font.family: main.textFont
		font.pixelSize: 11
		font.weight: isSelected ? Font.DemiBold : Font.Normal
		color: CachyPalette.text
		anchors {
			top: appicon.bottom
			left: parent.left
			right: parent.right
			topMargin: 8
			leftMargin: 4
			rightMargin: 4
		}
		textFormat: Text.PlainText
		elide: Text.ElideMiddle
		horizontalAlignment: Text.AlignHCenter
		maximumLineCount: 2
		wrapMode: Text.Wrap
	}

	MouseArea {
		id: ma
		anchors.fill: parent
		z: parent.z + 1
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		hoverEnabled:  !grid.movedWithWheel
		onClicked: {
			if (mouse.button == Qt.RightButton ) {
				if (gridDelegate.hasActionList) {
					var mapped = mapToItem(gridDelegate, mouse.x, mouse.y);
					gridDelegate.openActionMenu(gridDelegate, mouse.x, mouse.y);
				}
			} else { trigger(); }
		}
		onReleased: { isDraging: false }
		onEntered: {
			// - When the movedWithKeyboard condition is broken, we do not want to
			//   select the hovered item without moving the mouse.
			// - Don't highlight separators.
			// - Don't switch category items on hover if the setting isn't enabled
			if (grid.movedWithKeyboard) {
				return;
			}

			// forceActiveFocus() touches multiple items, so check for
			// activeFocus first to be more efficient.
			if (!grid.activeFocus) {
				grid.forceActiveFocus(Qt.MouseFocusReason);
			}
			// No need to check currentIndex first because it's
			// built into QQuickListView::setCurrentIndex() already
			grid.currentIndex = index;
			highlighted = true;
		}

		onExited: { highlighted = false; }

		onPositionChanged: {
			isDraging = pressed
			if (pressed){
				if ("pluginName" in model) {
					dragHelper.startDrag(kicker, model.url, model.decoration, "text/x-plasmoidservicename", model.pluginName);
				} else {
					kicker.dragSource = gridDelegate;
					dragHelper.startDrag(kicker, model.url, model.icon);
				}
			}
		}
	}
	ActionMenu {
		id: actionMenu

		onActionClicked: {
			actionTriggered(actionId, actionArgument);
		}
	}
	Transition {
		id: highlight
		ColorAnimation {duration: 100 }
		PropertyAnimation {properties: 'opacity'; duration: 100; easing.type: Easing.OutQuart}
	}
}
