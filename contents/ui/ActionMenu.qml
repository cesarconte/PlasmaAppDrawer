/*
    SPDX-FileCopyrightText: 2026 CachyOS UI
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick

Item {
    id: root

    property var actionList: []
    property Item visualParent: null
    property bool opened: false

    signal actionClicked(string actionId, var actionArgument)
    signal closed

    function _findContextMenuHost() {
        // 1. Walk up visual parent hierarchy
        var p = visualParent || root.parent;
        while (p) {
            if (typeof p.showContextMenu === "function") {
                return p;
            }
            p = p.parent;
        }

        // 2. Try kicker.dashWindow
        if (typeof kicker !== "undefined" && kicker && kicker.dashWindow && typeof kicker.dashWindow.showContextMenu === "function") {
            return kicker.dashWindow;
        }

        return null;
    }

    function open(x, y) {
        if (!actionList || actionList.length === 0) return;

        var target = visualParent || root.parent || root;
        var host = _findContextMenuHost();

        if (host && typeof host.showContextMenu === "function") {
            root.opened = true;
            host.showContextMenu(target, x, y, actionList, function(actionId, actionArgument) {
                root.opened = false;
                root.actionClicked(actionId, actionArgument);
                root.closed();
            });
        } else {
            console.warn("[ActionMenu] Could not find host with showContextMenu");
        }
    }
}
