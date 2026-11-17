pragma Singleton
// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 realFelinora — Felinora-shell
import Quickshell
import QtQuick

// hangi pencere açık — her yerden erişilir
Singleton {
    property bool dashboardOpen: false
    property int dashTab: 0
    property bool sessionOpen: false
    property bool netOpen: false
    property bool launcherOpen: false
    property bool pickerOpen: false
    property string pickerPurpose: "profile"
    // dosya yöneticisi (files/FileManager.qml): Dolphin gibi istediğin kadar ayrı pencere, her biri bir kimlik numarası
    property var filesWins: []
    property var filesStartMap: ({})
    property int filesNextId: 1
    readonly property bool filesOpen: filesWins.length > 0
    function openFiles(path) {
        const id = filesNextId++
        const m = Object.assign({}, filesStartMap); m[id] = path || ""; filesStartMap = m
        filesWins = filesWins.concat([id])
    }
    function closeFiles(id) { filesWins = filesWins.filter(x => x !== id) }
    function closeAllFiles() { filesWins = [] }

    readonly property var tabs: ["dashboard", "media", "performance", "weather", "theme"]

    function openTab(name) {
        const i = tabs.indexOf(name)
        if (i >= 0) dashTab = i
        dashboardOpen = true
    }
    signal lockRequested()
    function lock() { sessionOpen = false; dashboardOpen = false; netOpen = false; launcherOpen = false; lockRequested() }
    function toggleLauncher() {
        if (!launcherOpen) { sessionOpen = false; dashboardOpen = false; netOpen = false }
        launcherOpen = !launcherOpen
    }

    function openPicker(purpose) {
        pickerPurpose = purpose
        pickerOpen = true
    }
}
