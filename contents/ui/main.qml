
/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
 *   Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>           *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.taskmanager as TaskManager

import org.kde.ksvg as KSvg

import org.kde.plasma.private.kicker 0.1 as Kicker

import org.kde.kirigami 2.20 as Kirigami
import CachyOS.UI

PlasmoidItem {
    id: kicker

    anchors.fill: parent

    signal reset

    property bool isDash: false

    preferredRepresentation: fullRepresentation

    property Item dragSource: null

    // Running tasks model for active app dots and badges
    TaskManager.TasksModel {
        id: runningTasksModel
        filterByVirtualDesktop: false
        filterByActivity: false
        filterByScreen: false
    }

    // Process executor for dock-pin and file-manager integration
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        onNewData: (sourceName, data) => {
            var stdout = data["stdout"] || "";
            if (callbacks[sourceName] !== undefined) {
                callbacks[sourceName](stdout);
                delete callbacks[sourceName];
            }
            disconnectSource(sourceName);
        }

        function exec(cmd, callback) {
            if (callback !== undefined) {
                callbacks[cmd] = callback;
            }
            connectSource(cmd);
        }
    }

    function isAppRunning(appId, url) {
        if (!runningTasksModel) return false;
        var t1 = appId ? String(appId).replace(/\.desktop$/i, "").toLowerCase() : "";
        var t2 = url ? String(url).replace(/^.*[\\\/]/, "").replace(/\.desktop$/i, "").toLowerCase() : "";
        for (var i = 0; i < runningTasksModel.count; ++i) {
            var mIdx = runningTasksModel.makeModelIndex(i);
            var taskAppId = String(runningTasksModel.data(mIdx, TaskManager.AbstractTasksModel.AppId) || "").replace(/\.desktop$/i, "").toLowerCase();
            var taskUrl = String(runningTasksModel.data(mIdx, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) || "").toLowerCase();
            if (t1.length > 0 && (taskAppId === t1 || taskUrl.indexOf(t1) !== -1)) return true;
            if (t2.length > 0 && (taskAppId === t2 || taskUrl.indexOf(t2) !== -1)) return true;
        }
        return false;
    }

    function getAppBadge(appId, url) {
        if (!runningTasksModel) return "";
        var t1 = appId ? String(appId).replace(/\.desktop$/i, "").toLowerCase() : "";
        for (var i = 0; i < runningTasksModel.count; ++i) {
            var mIdx = runningTasksModel.makeModelIndex(i);
            var taskAppId = String(runningTasksModel.data(mIdx, TaskManager.AbstractTasksModel.AppId) || "").replace(/\.desktop$/i, "").toLowerCase();
            if (t1.length > 0 && taskAppId === t1) {
                var count = runningTasksModel.data(mIdx, TaskManager.AbstractTasksModel.SmartLauncherCount);
                if (count && count > 0) return String(count);
                var demandsAtt = runningTasksModel.data(mIdx, TaskManager.AbstractTasksModel.IsDemandingAttention);
                if (demandsAtt) return "!";
            }
        }
        return "";
    }

    property var pinnedLaunchersList: []

    function refreshPinnedLaunchers() {
        executable.exec("grep '^launchers=' ~/.config/macosdockrc | tail -n 1", function(stdout) {
            var line = stdout.trim().replace(/^launchers=/, "");
            if (line.length > 0) {
                pinnedLaunchersList = line.split(",");
            }
        });
    }

    function isDockPinnedSync(url) {
        if (!url || !pinnedLaunchersList || pinnedLaunchersList.length === 0) return false;
        var clean = String(url).replace("applications:", "").replace(/^.*[\\\/]/, "").toLowerCase();
        for (var i = 0; i < pinnedLaunchersList.length; i++) {
            var p = String(pinnedLaunchersList[i]).toLowerCase();
            if (p.indexOf(clean) !== -1) return true;
        }
        return false;
    }

    function toggleDockPin(url) {
        if (!url) return;
        var cleanUrl = String(url);
        if (!cleanUrl.startsWith("applications:") && !cleanUrl.startsWith("preferred:")) {
            cleanUrl = "applications:" + cleanUrl.replace(/^.*[\\\/]/, "");
        }
        var isPinned = isDockPinnedSync(cleanUrl);
        var action = isPinned ? "remove" : "add";
        executable.exec("/home/cesar/.local/bin/macos-dock-pin " + action + " '" + cleanUrl + "'", function() {
            refreshPinnedLaunchers();
        });
    }

    function checkDockPinned(url, callback) {
        if (!url) { if (callback) callback(false); return; }
        if (callback) {
            callback(isDockPinnedSync(url));
        }
    }

    function showInFileManager(url) {
        if (!url) return;
        var filename = String(url).replace("applications:", "").replace(/^.*[\\\/]/, "");
        executable.exec("bash -c 'f=$(find /usr/share/applications ~/.local/share/applications -name \"" + filename + "\" 2>/dev/null | head -n 1); if [ -n \"$f\" ]; then dolphin --select \"$f\"; fi'");
    }

    compactRepresentation: null
    fullRepresentation: compactRepresentation

    // Drawer dialog (managed here so it works even when compact rep is hidden)
    property var dashWindow: null

    function showContextMenu(target, x, y, actionList, cb) {
        if (dashWindow && typeof dashWindow.showContextMenu === "function") {
            dashWindow.showContextMenu(target, x, y, actionList, cb);
        }
    }

    // External toggle (e.g. from dock launcher)
    property bool toggleRequested: false

    property QtObject globalFavorites: rootModel.favoritesModel
    property QtObject systemFavorites: rootModel.systemFavoritesModel

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : (Plasmoid.configuration.icon || "launchpad")

    // Global shortcut is configured via preferences / panel (default set in ConfigGeneral)

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    Component {
        id: compactRepresentation
        CompactRepresentation { }
    }

    Component {
        id: menuRepresentation
        MenuRepresentation { }
    }

    Kicker.RootModel {
        id: rootModel

        autoPopulate: false

        appNameFormat: 0// Plasmoid.configuration.appNameFormat
        flat: true
        sorted: true
        showSeparators: false
        showRootSeparator: false
        appletInterface: kicker

        showAllApps: true
        showAllAppsCategorized: false
        showTopLevelItems: true//!kicker.isDash
        showRecentApps: false // Plasmoid.configuration.showRecentApps
        showRecentDocs: false //Plasmoid.configuration.showRecentDocs
        showPowerSession: false
       // showRecentContacts: true//Plasmoid.configuration.showRecentContacts
       // recentOrdering: 1 // Plasmoid.configuration.recentOrdering

        onRecentOrderingChanged: {
            Plasmoid.configuration.recentOrdering = recentOrdering;
        }

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)

           // kicker.logListModel("rootmodel", rootModel);
            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1 && Plasmoid.configuration.favoriteApps) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favoriteApps);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    Connections {
        target: globalFavorites

        function onFavoritesChanged() {
            Plasmoid.configuration.favoriteApps = target.favorites;
        }
    }

    Connections {
        target: systemFavorites

        function onFavoritesChanged() {
            Plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Connections {
        target: Plasmoid.configuration

        function onFavoriteAppsChanged() {
            globalFavorites.favorites = Plasmoid.configuration.favoriteApps;
        }

        function onFavoriteSystemActionsChanged() {
            systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }
    }

    Kicker.RunnerModel {
        id: runnerModel

        favoritesModel: globalFavorites
        appletInterface: kicker
        mergeResults: true
    }

    Kicker.DragHelper {
        id: dragHelper

        dragIconSize: Kirigami.Units.iconSizes.medium
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    KSvg.FrameSvgItem {
        id: highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    KSvg.FrameSvgItem {
        id: panelSvg
        visible: false
        imagePath: "widgets/panel-background"
    }

    KSvg.FrameSvgItem {
        id: dialogSvg
        visible: false
        imagePath: "dialogs/background"
    }

    PlasmaComponents.Label {
        id: toolTipDelegate

        width: contentWidth
        height: contentHeight

        property Item toolTip

        text: (toolTip != null) ? toolTip.text : ""
    }

    function resetDragSource() {
        dragSource = null;
    }

     Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        //plasmoid.setAction("menuedit", i18n("Edit Applications..."));
        rootModel.refreshed.connect(reset);

        dragHelper.dropped.connect(resetDragSource);

        // Default global shortcut (macOS-like) if none set yet
        try {
            if (!Plasmoid.globalShortcut) {
                Plasmoid.globalShortcut = "F4";
            }
        } catch (e) {
        }

        // Refresh dock pinned launchers list
        refreshPinnedLaunchers();

        // Create the drawer dialog and wire activation (works with dock launcher)
        dashWindow = Qt.createQmlObject("import QtQuick; import \".\"; MenuRepresentation {}", kicker);
        if (dashWindow) {
            plasmoid.activated.connect(function() {
                if (dashWindow) dashWindow.visible = !dashWindow.visible;
            });
        }
    }
}
