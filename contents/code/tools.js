/*
    SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
    SPDX-FileCopyrightText: 2013-2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2017 Ivan Cukic <ivan.cukic@kde.org>
    SPDX-FileCopyrightText: 2026 CachyOS UI contributors

    SPDX-License-Identifier: GPL-2.0-or-later
*/

.pragma library

function fillActionMenu(i18n, actionMenu, actionList, favoriteModel, favoriteId, appUrl, isPinned) {
    var actions = [];

    // 1. Abrir
    actions.push({
        text: i18n("Abrir"),
        icon: "system-run",
        actionId: "_app_open"
    });

    // 2. Fijar / Quitar del Dock (macos-dock)
    actions.push({
        text: isPinned ? i18n("Eliminar del Dock") : i18n("Fijar en el Dock"),
        icon: isPinned ? "list-remove" : "list-add",
        actionId: "_dock_pin_toggle",
        actionArgument: { url: appUrl, isPinned: isPinned }
    });

    // 3. Mostrar en el gestor de archivos (Dolphin)
    actions.push({
        text: i18n("Mostrar en el gestor de archivos"),
        icon: "system-file-manager",
        actionId: "_show_in_folder",
        actionArgument: { url: appUrl }
    });

    // 4. Acciones rápidas del .desktop (Jump Lists)
    if (actionList && Array.isArray(actionList) && actionList.length > 0) {
        var hasAddedSep = false;
        for (var i = 0; i < actionList.length; i++) {
            var item = actionList[i];
            if (!item || typeof item !== "object") continue;
            if (item.type === "separator") {
                actions.push({ type: "separator" });
            } else if (item.text && String(item.text).trim().length > 0) {
                if (!hasAddedSep) {
                    actions.push({ type: "separator" });
                    hasAddedSep = true;
                }
                actions.push({
                    text: item.text,
                    icon: item.icon || "",
                    actionId: item.actionId || "",
                    actionArgument: item.actionArgument || ""
                });
            }
        }
    }

    actionMenu.actionList = actions;
}

function triggerAction(model, index, actionId, actionArgument, kicker) {
    if (actionId === "_app_open") {
        if (model && model.trigger) {
            model.trigger(index, "", null);
        }
        return true;
    }

    if (actionId === "_dock_pin_toggle") {
        if (kicker && actionArgument && actionArgument.url) {
            kicker.toggleDockPin(actionArgument.url);
        }
        return false;
    }

    if (actionId === "_show_in_folder") {
        if (kicker && actionArgument && actionArgument.url) {
            kicker.showInFileManager(actionArgument.url);
        }
        return true;
    }

    if (model && model.trigger) {
        var closeRequested = model.trigger(index, actionId, actionArgument);
        return closeRequested ? true : false;
    }

    return false;
}
