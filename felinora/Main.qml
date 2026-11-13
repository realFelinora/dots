// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 realFelinora — Felinora SDDM
//
// Felinora-shell SDDM teması
//   karşılama ekranı → (tıkla / bir tuşa bas) → giriş ekranı
// Giriş ekranı, shell'in kilit ekranıyla aynı tasarımı kullanır.

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import "components"
import "components/Palettes.js" as Pal

Rectangle {
    id: root
    width: 1920
    height: 1080

    // ---------------- ayarlar (theme.conf) ----------------
    function conf(key, def) {
        const v = config.stringValue(key)
        return v === undefined || v === null || v === "" ? def : String(v)
    }
    readonly property var pal: Pal.get(conf("palette", "pembe"))
    readonly property string bgPath: conf("background", "")
    readonly property string avatarPath: conf("avatar", "")
    readonly property string osId: conf("os", "arch")
    readonly property bool clock24: conf("clock24", "false") === "true"
    readonly property int idleSeconds: Number(conf("idleSeconds", "30"))

    // ---------------- renkler (shell ile aynı mantık) ----------------
    readonly property real frameTint: pal.frameTint !== undefined ? pal.frameTint : 0.21
    readonly property color frameColor: Qt.tint(pal.frame, Qt.alpha(pal.accent2, frameTint))
    readonly property color frameTop: Qt.tint(pal.frame, Qt.alpha(pal.accent, frameTint > 0 ? frameTint + 0.1 : 0))
    readonly property color frameBottom: Qt.tint(pal.frame, Qt.alpha(pal.accent2, frameTint > 0 ? frameTint + 0.12 : 0))
    readonly property color red: "#ff5c7c"
    readonly property color warn: "#ffb36b"
    color: pal.bg

    readonly property int t: 8          // çerçeve kalınlığı
    readonly property int bw: 56        // sol bar
    readonly property int fr: 24        // çerçeve iç köşe
    readonly property int pr: 22        // panel köşe
    readonly property var curveSpatial: [0.38, 1.21, 0.22, 1.0, 1, 1]
    readonly property var curveDecel: [0.05, 0.7, 0.1, 1.0, 1, 1]
    readonly property string fontText: "Nunito"
    readonly property string fontMono: "JetBrainsMono Nerd Font Propo"

    function cp(c) { return String.fromCodePoint(c) }
    readonly property var osIcons: ({
        arch: 0xf303, debian: 0xf306, ubuntu: 0xf31b, fedora: 0xf30a, nixos: 0xf313, opensuse: 0xf314,
        manjaro: 0xf312, endeavouros: 0xf322, gentoo: 0xf30d, void: 0xf32e, linuxmint: 0xf30e, pop: 0xf32a,
        cachyos: 0xf385, garuda: 0xf337, artix: 0xf31f, alpine: 0xf300, kali: 0xf327
    })
    readonly property string iOs: cp(osIcons[osId] || 0xf31a)
    readonly property string iPaw: cp(0xf03e9)
    // şifre yazarken her harfe rastgele bir şekil: pati (daha sık), kalp, yıldız, kedi, balık, ışıltı
    readonly property var pwShapes: [cp(0xf03e9), cp(0xf03e9), cp(0xf02d1), cp(0xf04ce), cp(0xf011b), cp(0xf023a), cp(0xf0674)]
    readonly property string iLock: cp(0xf033e)
    readonly property string iLockOpen: cp(0xf0fc6)
    readonly property string iPower: cp(0xf0425)
    readonly property string iSleep: cp(0xf0904)
    readonly property string iRestart: cp(0xf0709)
    readonly property string iEnter: cp(0xf0cdf)
    readonly property string iLeft: cp(0xf0141)
    readonly property string iRight: cp(0xf0142)
    readonly property string iCaps: cp(0xf0632)
    readonly property string iAlert: cp(0xf0028)
    readonly property string iAccount: cp(0xf0004)
    readonly property string iDesktop: cp(0xf07c0)
    readonly property string iMouse: cp(0xf037d)
    readonly property string iKeyboard: cp(0xf030c)

    // ---------------- durum ----------------
    property bool login: false          // false: karşılama, true: giriş
    property bool powerOpen: false
    property string status: ""          // "" | checking | fail | ok
    property real intro: 0              // açılış animasyonu
    Component.onCompleted: introAnim.start()
    NumberAnimation { id: introAnim; target: root; property: "intro"; from: 0; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveDecel }

    property real reveal: login ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveDecel } }

    readonly property bool exiting: status === "ok"

    // karşılama ↔ giriş geçişi sıralı: biri tamamen gitmeden diğeri gelmez (üst üste binmesin)
    property real wIn: 1       // karşılama görünürlüğü
    property real lIn: 0       // giriş görünürlüğü
    onLoginChanged: {
        if (login) { toWelcome.stop(); toLogin.restart() }
        else { toLogin.stop(); toWelcome.restart() }
    }
    SequentialAnimation {
        id: toLogin
        NumberAnimation { target: root; property: "wIn"; to: 0; duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "lIn"; to: 1; duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveDecel }
    }
    SequentialAnimation {
        id: toWelcome
        NumberAnimation { target: root; property: "lIn"; to: 0; duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "wIn"; to: 1; duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveDecel }
    }

    // basılan tuş yalnızca girişi açar, şifre kutusuna yazılmaz
    function showLogin() {
        if (exiting) return
        login = true
        pw.forceActiveFocus()
        idle.restart()
    }
    function showWelcome() {
        login = false
        powerOpen = false
        pw.text = ""
        keys.forceActiveFocus()
    }
    function submit() {
        if (status === "checking" || pw.text.length === 0) return
        status = "checking"
        sddm.login(userName, pw.text, sessionIndex)
    }

    // ---------------- kullanıcılar & oturumlar ----------------
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    Repeater {
        id: users
        model: userModel
        delegate: Item {
            required property string name
            required property string realName
            required property string icon
        }
    }
    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item { required property string name }
    }
    readonly property var userItem: users.count > 0 ? users.itemAt(Math.min(userIndex, users.count - 1)) : null
    readonly property string userName: userItem ? userItem.name : userModel.lastUser
    readonly property string userReal: userItem && userItem.realName ? userItem.realName : userName
    readonly property string userIcon: userItem ? userItem.icon : ""
    readonly property string sessionName: sessions.count > 0 && sessions.itemAt(Math.min(sessionIndex, sessions.count - 1))
                                          ? sessions.itemAt(Math.min(sessionIndex, sessions.count - 1)).name : "oturum"

    Connections {
        target: sddm
        function onLoginFailed() {
            root.status = "fail"
            pw.text = ""
            shake.restart()
            failAnim.restart()
            statusReset.restart()
            pw.forceActiveFocus()
        }
        function onLoginSucceeded() { root.status = "ok" }
    }
    Timer { id: statusReset; interval: 3500; onTriggered: if (root.status === "fail") root.status = "" }

    // hareketsiz kalınca karşılama ekranına dön
    Timer {
        id: idle
        interval: root.idleSeconds * 1000
        onTriggered: if (root.login && pw.text.length === 0 && root.status === "") root.showWelcome()
    }

    // ---------------- saat ----------------
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }
    function pad(n) { return n < 10 ? "0" + n : "" + n }
    readonly property int hh: clock24 ? now.getHours() : (now.getHours() % 12 === 0 ? 12 : now.getHours() % 12)
    readonly property var days: ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
    readonly property var months: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
    readonly property string greeting: {
        const h = now.getHours()
        return h < 6 ? "iyi geceler" : h < 12 ? "günaydın" : h < 18 ? "iyi günler" : "iyi akşamlar"
    }

    // ================================================================
    //                            ÇİZİM
    // ================================================================

    // ---- arka plan ----
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.tint(root.pal.bg, Qt.alpha(root.pal.accent2, 0.25)) }
            GradientStop { position: 1; color: Qt.tint(root.pal.bg, Qt.alpha(root.pal.accent, 0.12)) }
        }
    }
    Image {
        id: bg
        anchors.fill: parent
        source: root.bgPath ? Qt.resolvedUrl(root.bgPath) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
        scale: 1.08 - 0.08 * root.intro + 0.04 * root.reveal
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.reveal
            blurMax: 64
            saturation: -0.25 * root.reveal
        }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Qt.tint(root.pal.bg, Qt.alpha(root.pal.accent, 0.18)), 0.25 + 0.35 * root.reveal) }
            GradientStop { position: 0.5; color: Qt.alpha(root.pal.bg, 0.15 + 0.4 * root.reveal) }
            GradientStop { position: 1.0; color: Qt.alpha(Qt.tint(root.pal.bg, Qt.alpha(root.pal.accent2, 0.2)), 0.35 + 0.35 * root.reveal) }
        }
    }

    // ---- çerçeve + paneller (gölge + keskin şekil) ----
    Component {
        id: shadowFx
        MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 20; brightness: -1.0 }
    }
    Repeater {
        model: 2
        delegate: Item {
            required property int index
            readonly property bool isShadow: index === 0
            width: root.width
            height: root.height
            y: isShadow ? 3 : 0
            opacity: (isShadow ? 0.8 : 1) * root.intro
            layer.enabled: isShadow
            layer.textureSize: Qt.size(Math.round(root.width / 2), Math.round(root.height / 2))
            layer.effect: isShadow ? shadowFx : null

            Shape {
                anchors.fill: parent
                preferredRendererType: parent.isShadow ? Shape.GeometryRenderer : Shape.CurveRenderer
                readonly property bool isShadow: parent.isShadow
                LinearGradient {
                    id: frameGrad
                    x1: 0; y1: 0; x2: 0; y2: root.height
                    GradientStop { position: 0.0; color: root.frameTop }
                    GradientStop { position: 0.45; color: root.frameColor }
                    GradientStop { position: 1.0; color: root.frameBottom }
                }
                FramePath {
                    fillColor: root.frameColor; fillGradient: isShadow ? null : frameGrad
                    w: root.width; h: root.height; left: root.bw; t: root.t; r: root.fr
                }
                EdgePath {
                    fillColor: root.frameColor; fillGradient: isShadow ? null : frameGrad
                    edge: "top"; start: topD.along; length: topD.length
                    inner: root.t; depth: topD.depth; radius: root.pr
                }
                EdgePath {
                    fillColor: root.frameColor; fillGradient: isShadow ? null : frameGrad
                    edge: "bottom"; start: bottomD.along; length: bottomD.length
                    inner: root.height - root.t; depth: bottomD.depth; radius: root.pr
                }
                EdgePath {
                    fillColor: root.frameColor; fillGradient: isShadow ? null : frameGrad
                    edge: "right"; start: powerD.along; length: powerD.length
                    inner: root.width - root.t; depth: powerD.depth; radius: root.pr
                }
            }
        }
    }

    // ---- karşılama: tıkla ya da bir tuşa bas ----
    MouseArea {
        anchors.fill: parent
        enabled: !root.login
        cursorShape: Qt.PointingHandCursor
        onClicked: root.showLogin()
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.login
        hoverEnabled: true
        onPositionChanged: idle.restart()
        onClicked: { root.powerOpen = false; pw.forceActiveFocus() }
    }

    // ---- sol bar ----
    Item {
        width: root.bw
        height: root.height
        opacity: root.intro
        x: -14 * (1 - root.intro)

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            spacing: 10

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 40; implicitHeight: 48
                Item {
                    width: 40; height: 40
                    anchors.bottom: parent.bottom
                    Ears { anchors.bottom: parent.top; anchors.bottomMargin: -9; width: parent.width; earSize: 15; inset: 1 }
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: root.pal.surface2
                        border.width: 2
                        border.color: root.pal.accent
                        Glyph { anchors.centerIn: parent; text: root.iOs; size: 22 }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // nabız atan kilit
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 40; implicitHeight: 40
                Rectangle {
                    anchors.centerIn: parent
                    width: 38; height: 38; radius: 19
                    color: "transparent"
                    border.width: 2
                    border.color: root.pal.accent
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.85; to: 1.3; duration: 1500; easing.type: Easing.OutCubic }
                        PauseAnimation { duration: 500 }
                    }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.8; to: 0; duration: 1500; easing.type: Easing.OutCubic }
                        PauseAnimation { duration: 500 }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 38; height: 38; radius: 19
                    color: root.pal.surface
                    border.width: 1
                    border.color: Qt.alpha(root.pal.accent, 0.5)
                    Glyph { anchors.centerIn: parent; text: root.status === "ok" ? root.iLockOpen : root.iLock; size: 18 }
                }
            }

            Item { Layout.fillHeight: true }

            Column {
                Layout.alignment: Qt.AlignHCenter
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.pad(root.hh); mono: true; size: 19; font.weight: Font.Bold; color: root.pal.accent }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.pad(root.now.getMinutes()); mono: true; size: 19; font.weight: Font.Bold }
                Item { width: 1; height: 4 }
                Rectangle {
                    visible: !root.clock24
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 32; height: 16; radius: 8
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: root.pal.accent }
                        GradientStop { position: 1; color: root.pal.accent2 }
                    }
                    Label { anchors.centerIn: parent; text: root.now.getHours() < 12 ? "AM" : "PM"; size: 10; font.weight: Font.Black; color: root.pal.bg }
                }
            }

            // güç menüsü
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 44; implicitHeight: 42
                Rectangle {
                    anchors.centerIn: parent
                    width: 38; height: 38; radius: 19
                    color: pbm.containsMouse || powerD.open ? root.pal.accent : root.pal.surface
                    border.width: 1
                    border.color: Qt.alpha(root.pal.accent, 0.45)
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Glyph {
                        anchors.centerIn: parent
                        text: root.iPower
                        size: 18
                        color: pbm.containsMouse || powerD.open ? root.pal.bg : root.pal.accent
                        rotation: pbm.containsMouse ? 90 : 0
                        Behavior on rotation { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                    }
                }
                MouseArea {
                    id: pbm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.powerOpen = !root.powerOpen
                }
            }
        }
    }

    // ---- üstten: büyük saat ----
    Drawer {
        id: topD
        edge: "top"
        open: root.intro > 0.3 && !root.exiting
        duration: 700
        radius: root.pr
        inner: root.t
        contentW: 460
        contentH: 172
        along: (root.width + root.bw - root.t - contentW) / 2
    }
    Item {
        parent: topD.slot
        anchors.fill: parent
        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 4
            spacing: 2
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Row {
                    Label { text: root.pad(root.hh); mono: true; size: 80; font.weight: Font.Bold; color: root.pal.accent }
                    Label { text: ":"; mono: true; size: 80; font.weight: Font.Bold; color: root.pal.accent2; opacity: root.now.getSeconds() % 2 ? 0.35 : 1
                            Behavior on opacity { NumberAnimation { duration: 300 } } }
                    Label { text: root.pad(root.now.getMinutes()); mono: true; size: 80; font.weight: Font.Bold }
                }
                Rectangle {
                    visible: !root.clock24
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 58; implicitHeight: 28; radius: 14
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: root.pal.accent }
                        GradientStop { position: 1; color: root.pal.accent2 }
                    }
                    Label { anchors.centerIn: parent; text: root.now.getHours() < 12 ? "AM" : "PM"; size: 15; font.weight: Font.Black; color: root.pal.bg }
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.days[root.now.getDay()] + ", " + root.now.getDate() + " " + root.months[root.now.getMonth()]
                size: 17
                color: root.pal.subtext
            }
        }
    }

    // ---- karşılama: süzülen ışık noktaları ----
    Item {
        anchors.fill: parent
        opacity: root.intro * root.wIn
        visible: opacity > 0.01
        Repeater {
            model: 18
            delegate: Rectangle {
                id: dot
                required property int index
                readonly property real seed: (index * 0.6180339) % 1
                width: 4 + seed * 8
                height: width
                radius: width / 2
                color: index % 3 === 0 ? root.pal.accent2 : root.pal.accent
                x: root.bw + seed * (root.width - root.bw - 40) + (index % 4) * 13
                opacity: 0
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.6; blurMax: 12 }
                SequentialAnimation {
                    running: !root.login
                    loops: Animation.Infinite
                    PauseAnimation { duration: dot.index * 650 }
                    ParallelAnimation {
                        NumberAnimation { target: dot; property: "y"; from: root.height + 20; to: root.height * (0.15 + dot.seed * 0.3); duration: 9000 + dot.seed * 7000; easing.type: Easing.OutSine }
                        SequentialAnimation {
                            NumberAnimation { target: dot; property: "opacity"; from: 0; to: 0.55; duration: 2200 }
                            PauseAnimation { duration: 3000 + dot.seed * 4000 }
                            NumberAnimation { target: dot; property: "opacity"; to: 0; duration: 2500 }
                        }
                    }
                }
            }
        }
    }

    // ---- karşılama: selam + kedi kulaklı pati rozeti ----
    Column {
        id: welcome
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (root.bw - root.t) / 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 30 + 46 * (1 - root.wIn)
        spacing: 4
        opacity: root.intro * root.wIn
        visible: opacity > 0.01
        scale: 0.92 + 0.08 * root.wIn

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.greeting + ","
            size: 26
            font.weight: Font.Bold
            color: Qt.alpha(root.pal.text, 0.85)
            style: Text.Raised
            styleColor: Qt.alpha("black", 0.4)
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.userReal
            size: 48
            font.weight: Font.Black
            color: root.pal.text
            style: Text.Raised
            styleColor: Qt.alpha("black", 0.4)
        }

        Item { width: 1; height: 42 }

        // pati rozeti
        Item {
            id: tap
            anchors.horizontalCenter: parent.horizontalCenter
            width: 150; height: 150
            property real bob: 0
            property bool hovered: tapMa.containsMouse
            SequentialAnimation on bob {
                loops: Animation.Infinite
                running: !root.login
                NumberAnimation { to: -9; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: 1500; easing.type: Easing.InOutSine }
            }
            transform: Translate { y: tap.bob }

            // yayılan dalga halkaları
            Repeater {
                model: 3
                delegate: Rectangle {
                    id: ring
                    required property int index
                    anchors.centerIn: parent
                    width: tap.width; height: tap.height
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: index === 1 ? root.pal.accent2 : root.pal.accent
                    opacity: 0
                    SequentialAnimation {
                        running: !root.login
                        loops: Animation.Infinite
                        PauseAnimation { duration: ring.index * 900 }
                        ParallelAnimation {
                            NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.75; duration: 2700; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ring; property: "opacity"; from: 0.55; to: 0; duration: 2700; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Ears {
                anchors.bottom: badge.top
                anchors.bottomMargin: -22
                anchors.horizontalCenter: badge.horizontalCenter
                width: badge.width * 0.82
                earSize: 40
                inset: 0
                fill: Qt.tint(root.pal.surface2, Qt.alpha(root.pal.accent, 0.22))
                line: 3
                rotation: tap.hovered ? Math.sin(tap.wiggle) * 4 : 0
            }
            property real wiggle: 0
            NumberAnimation on wiggle { running: tap.hovered; from: 0; to: Math.PI * 2; duration: 700; loops: Animation.Infinite }

            Rectangle {
                id: badge
                anchors.fill: parent
                radius: width / 2
                scale: tapMa.pressed ? 0.88 : (tap.hovered ? 1.07 : 1)
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveSpatial } }
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.tint(root.pal.surface2, Qt.alpha(root.pal.accent, 0.22)) }
                    GradientStop { position: 1; color: Qt.tint(root.pal.surface, Qt.alpha(root.pal.accent2, 0.18)) }
                }
                border.width: 3
                border.color: root.pal.accent
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.pal.accent
                    shadowBlur: 1.0
                    shadowOpacity: tap.hovered ? 0.95 : 0.55
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }

                // pati: pembe→mor degrade
                Item {
                    anchors.centerIn: parent
                    width: 80; height: 80
                    rotation: tap.hovered ? Math.sin(tap.wiggle) * 14 : -8
                    Behavior on rotation { enabled: !tap.hovered; NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                    Glyph {
                        id: pawGlyph
                        anchors.centerIn: parent
                        text: root.iPaw
                        size: 70
                        visible: false
                    }
                    Rectangle {
                        id: pawFill
                        anchors.fill: parent
                        visible: false
                        gradient: Gradient {
                            GradientStop { position: 0; color: root.pal.accentSoft }
                            GradientStop { position: 0.5; color: root.pal.accent }
                            GradientStop { position: 1; color: root.pal.accent2 }
                        }
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: pawFill
                        maskEnabled: true
                        maskSource: pawMask
                    }
                    Item {
                        id: pawMask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Glyph { anchors.centerIn: parent; text: root.iPaw; size: 70; color: "black" }
                    }
                }
            }

            MouseArea {
                id: tapMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tapDelay.start()
            }
            Timer { id: tapDelay; interval: 140; onTriggered: root.showLogin() }
        }

        Item { width: 1; height: 22 }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: tapLabel.implicitWidth + 30
            height: 32
            radius: 16
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.pal.accent }
                GradientStop { position: 1; color: root.pal.accent2 }
            }
            Label { id: tapLabel; anchors.centerIn: parent; text: "dokun~"; size: 15; font.weight: Font.Black; color: root.pal.bg }
        }
    }

    // ---- giriş: profil + şifre (shell'in kilit ekranıyla aynı) ----
    ColumnLayout {
        id: center
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: (root.bw - root.t) / 2
        spacing: 14
        opacity: root.lIn * (root.exiting ? 0 : 1)
        anchors.verticalCenterOffset: -40 * (1 - root.lIn)
        visible: opacity > 0.01
        scale: root.exiting ? 1.06 : 0.92 + 0.08 * root.lIn
        Behavior on opacity { enabled: root.exiting; NumberAnimation { duration: 400 } }
        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveSpatial } }

        // profil resmi
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 156; implicitHeight: 156
            Item {
                anchors.fill: parent
                RotationAnimation on rotation { from: 0; to: 360; duration: root.status === "checking" ? 1400 : 8000; loops: Animation.Infinite; running: root.login }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    rotation: root.spin
                    gradient: Gradient {
                        GradientStop { position: 0; color: root.failFlash > 0 ? root.red : root.pal.accent }
                        GradientStop { position: 1; color: root.pal.accent2Deep }
                    }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: root.failFlash > 0 ? root.red : root.pal.accent
                        shadowBlur: 1.0
                        shadowOpacity: Math.min(1, 0.45 + root.glow * 0.5 + (root.status === "checking" ? 0.35 : 0))
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                }
            }
            Rectangle {
                id: avatarClip
                anchors.fill: parent
                anchors.margins: 5
                radius: width / 2
                color: root.pal.surface2
                Glyph {
                    anchors.centerIn: parent
                    visible: avatarImg.status !== Image.Ready
                    text: root.iAccount
                    size: 72
                }
                Image {
                    id: avatarImg
                    anchors.fill: parent
                    visible: false
                    source: root.avatarPath ? Qt.resolvedUrl(root.avatarPath) : (root.userIcon ? "file://" + root.userIcon : "")
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(300, 300)
                    asynchronous: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: avatarImg
                    visible: avatarImg.status === Image.Ready
                    maskEnabled: true
                    maskSource: avatarMask
                }
                Item {
                    id: avatarMask
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    Rectangle { anchors.fill: parent; radius: width / 2; color: "black" }
                }
            }
        }

        // kullanıcı adı (birden fazla kullanıcı varsa oklarla değişir)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Arrow { visible: users.count > 1; text: root.iLeft; onClicked: root.userIndex = (root.userIndex - 1 + users.count) % users.count }
            Label { text: root.userReal; size: 28; font.weight: Font.Black }
            Arrow { visible: users.count > 1; text: root.iRight; onClicked: root.userIndex = (root.userIndex + 1) % users.count }
        }

        // şifre kutusu
        Item {
            id: inputBox
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 380
            implicitHeight: 56
            transform: Translate { id: shakeX }
            scale: root.bump

            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeX; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: shakeX; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: -9; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: 6; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 90 }
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.alpha(root.pal.surface, 0.92)
                border.width: 2
                border.color: root.failFlash > 0 || root.status === "fail" ? root.red
                            : root.status === "ok" ? root.pal.accent
                            : pw.text.length > 0 ? Qt.alpha(root.pal.accent, 0.55 + 0.45 * root.glow) : root.pal.border
                Behavior on border.color { ColorAnimation { duration: 160 } }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.failFlash > 0 ? root.red : root.pal.accent
                    shadowBlur: 1.0
                    shadowOpacity: Math.max(root.glow * 0.85, root.failFlash * 0.9, root.status === "checking" ? 0.5 : 0)
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
            }

            Glyph {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: root.status === "ok" ? root.iLockOpen : root.iLock
                size: 18
                color: root.failFlash > 0 || root.status === "fail" ? root.red : root.pal.accent
            }

            // gerçek giriş alanı görünmez; ekranda patiler gösterilir
            TextInput {
                id: pw
                anchors.fill: parent
                opacity: 0
                echoMode: TextInput.Password
                cursorVisible: false
                focus: root.login
                onTextChanged: {
                    idle.restart()
                    root.syncPaws(text.length)
                    if (text.length > root.lastLen) { root.spin += 24; bumpAnim.restart() }
                    else if (text.length < root.lastLen) { root.spin -= 18; if (root.lastLen - text.length === 1) ghostAnim.restart() }
                    root.lastLen = text.length
                }
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.submit(); e.accepted = true }
                    else if (e.key === Qt.Key_Escape) { if (text.length) text = ""; else root.showWelcome(); e.accepted = true }
                    else if (e.key === Qt.Key_Tab) { root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessions.count); e.accepted = true }
                }
            }

            Item {
                id: pawsBox
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: paws.width
                x: (inputBox.width - width) / 2
                Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveDecel } }

                Row {
                    id: paws
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: pwModel
                        delegate: Item {
                            id: pawItem
                            required property int index
                            required property int shape
                            required property real tilt
                            readonly property real mix: Math.min(1, index / 10)
                            readonly property color tint: root.status === "ok" ? root.pal.accentSoft
                                     : Qt.tint(root.pal.accent, Qt.alpha(root.pal.accent2, mix))
                            width: 18; height: 24

                            // yayılan halka
                            Rectangle {
                                id: ring
                                anchors.centerIn: parent
                                width: 22; height: 22; radius: 11
                                color: "transparent"
                                border.width: 1.5
                                border.color: pawItem.tint
                                opacity: 0
                            }
                            // etrafa saçılan kıvılcımlar
                            Repeater {
                                model: 5
                                delegate: Rectangle {
                                    id: spark
                                    required property int index
                                    readonly property real ang: index / 5 * 2 * Math.PI + pawItem.tilt / 12
                                    property real d: 0
                                    x: pawItem.width / 2 - 2; y: pawItem.height / 2 - 2
                                    width: 4; height: 4; radius: 2
                                    color: index % 2 ? root.pal.accent2 : root.pal.accent
                                    opacity: 0
                                    transform: Translate { x: Math.cos(spark.ang) * spark.d; y: Math.sin(spark.ang) * spark.d }
                                    Component.onCompleted: sparkAnim.start()
                                    ParallelAnimation {
                                        id: sparkAnim
                                        NumberAnimation { target: spark; property: "d"; from: 4; to: 17; duration: 460; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: spark; property: "opacity"; from: 1; to: 0; duration: 460; easing.type: Easing.InQuad }
                                        NumberAnimation { target: spark; property: "scale"; from: 1.3; to: 0.3; duration: 460 }
                                    }
                                }
                            }

                            Glyph {
                                id: pawIcon
                                anchors.centerIn: parent
                                text: root.pwShapes[pawItem.shape] || root.iPaw
                                size: 15
                                color: pawItem.tint
                                scale: 0
                                opacity: 0
                                rotation: pawItem.tilt * 4
                                transform: [
                                    Translate { id: drop; y: -12 },
                                    Translate { y: root.status === "" ? Math.sin(root.wave - pawItem.index * 0.65) * 2.2 : 0 }
                                ]
                                Component.onCompleted: popIn.start()
                                ParallelAnimation {
                                    id: popIn
                                    NumberAnimation { target: pawIcon; property: "opacity"; from: 0; to: 1; duration: 120 }
                                    SequentialAnimation {
                                        NumberAnimation { target: pawIcon; property: "scale"; from: 0; to: 1.35; duration: 170; easing.type: Easing.OutCubic }
                                        NumberAnimation { target: pawIcon; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                                    }
                                    NumberAnimation { target: pawIcon; property: "rotation"; to: pawItem.tilt * 0.4; duration: 430; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
                                    NumberAnimation { target: drop; property: "y"; from: -12; to: 0; duration: 430; easing.type: Easing.OutBounce }
                                    NumberAnimation { target: ring; property: "scale"; from: 0.3; to: 1.7; duration: 480; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: ring; property: "opacity"; from: 0.75; to: 0; duration: 480; easing.type: Easing.InQuad }
                                }
                                SequentialAnimation {
                                    running: root.status === "checking"
                                    loops: Animation.Infinite
                                    onStopped: pawIcon.opacity = 1
                                    PauseAnimation { duration: pawItem.index * 60 }
                                    NumberAnimation { target: pawIcon; property: "opacity"; to: 0.25; duration: 260; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: pawIcon; property: "opacity"; to: 1; duration: 260; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    x: paws.width + (paws.width > 0 ? 4 : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2; height: 18; radius: 1
                    color: root.pal.accent
                    visible: pw.text.length > 0 && root.status === ""
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 0 }
                        PauseAnimation { duration: 520 }
                        NumberAnimation { to: 0.1; duration: 220 }
                        PauseAnimation { duration: 300 }
                        NumberAnimation { to: 1; duration: 220 }
                    }
                }
            }

            Glyph {
                id: ghost
                text: root.ghostShape
                size: 14
                color: root.pal.muted
                opacity: 0
                x: pawsBox.x + paws.width + 4
                anchors.verticalCenter: parent.verticalCenter
                transform: Translate { id: ghostDrop }
                ParallelAnimation {
                    id: ghostAnim
                    NumberAnimation { target: ghost; property: "opacity"; from: 0.8; to: 0; duration: 240 }
                    NumberAnimation { target: ghost; property: "scale"; from: 1; to: 0.2; duration: 240; easing.type: Easing.InBack }
                    NumberAnimation { target: ghostDrop; property: "y"; from: 0; to: 8; duration: 240 }
                }
            }

            Label {
                anchors.centerIn: parent
                opacity: pw.text.length === 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                text: root.status === "checking" ? "kontrol ediliyor..." : root.status === "ok" ? "hoş geldin~" : "şifreni yaz~"
                size: 14
                color: root.pal.muted
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                gradient: Gradient {
                    GradientStop { position: 0; color: pw.text.length > 0 ? root.pal.accent : root.pal.surface3 }
                    GradientStop { position: 1; color: pw.text.length > 0 ? root.pal.accent2 : root.pal.surface3 }
                }
                scale: sm.pressed ? 0.88 : 1
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                Glyph { anchors.centerIn: parent; text: root.iEnter; size: 22; color: pw.text.length > 0 ? root.pal.bg : root.pal.muted }
                MouseArea { id: sm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.submit() }
            }
        }

        // durum satırı
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 380
            implicitHeight: 22
            Row {
                anchors.centerIn: parent
                spacing: 6
                visible: root.status === "fail" || keyboard.capsLock
                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.status === "fail" ? root.iAlert : root.iCaps
                    size: 14
                    color: root.status === "fail" ? root.red : root.warn
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.status === "fail" ? "yanlış şifre, tekrar dene (=；ω；=)" : "Caps Lock açık"
                    size: 12
                    color: root.status === "fail" ? root.red : root.warn
                }
            }
        }
    }

    // ---- alttan: ipucu (karşılama) / oturum seçimi (giriş) ----
    Drawer {
        id: bottomD
        edge: "bottom"
        open: root.intro > 0.45 && !root.exiting
        duration: 760
        radius: root.pr
        inner: root.height - root.t
        screenH: root.height
        contentW: root.login ? 440 : 360
        contentH: 74
        along: (root.width + root.bw - root.t - contentW) / 2
        Behavior on contentW { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveSpatial } }
    }
    Item {
        parent: bottomD.slot
        anchors.fill: parent

        // karşılama: sağa yürüyen pati izleri + ipucu
        Item {
            anchors.fill: parent
            opacity: root.wIn
            visible: opacity > 0.01

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 12
                spacing: 18
                Repeater {
                    model: 9
                    delegate: Glyph {
                        id: step
                        required property int index
                        text: root.iPaw
                        size: 13
                        rotation: 90
                        color: index % 2 ? root.pal.accent2 : root.pal.accent
                        transform: Translate { y: step.index % 2 ? 5 : -5 }
                        opacity: 0
                        SequentialAnimation {
                            running: !root.login
                            loops: Animation.Infinite
                            PauseAnimation { duration: step.index * 220 }
                            NumberAnimation { target: step; property: "opacity"; to: 1; duration: 160 }
                            NumberAnimation { target: step; property: "opacity"; to: 0; duration: 1100; easing.type: Easing.InQuad }
                            PauseAnimation { duration: (8 - step.index) * 220 + 500 }
                        }
                    }
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                spacing: 8
                Glyph { text: root.iKeyboard; size: 16; color: root.pal.accent2; anchors.verticalCenter: parent.verticalCenter }
                Label { text: "ya da herhangi bir tuşa bas"; size: 13; color: root.pal.subtext; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // giriş: oturum seçimi
        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            opacity: root.lIn
            visible: opacity > 0.01
            Glyph { text: root.iDesktop; size: 18; color: root.pal.accent2 }
            Label { text: "oturum"; size: 12; color: root.pal.subtext }
            Arrow { visible: sessions.count > 1; text: root.iLeft; onClicked: root.sessionIndex = (root.sessionIndex - 1 + sessions.count) % sessions.count }
            Rectangle {
                implicitWidth: Math.max(150, sessLabel.implicitWidth + 28)
                implicitHeight: 34
                radius: 17
                color: root.pal.surface2
                border.width: 1
                border.color: Qt.alpha(root.pal.accent, 0.45)
                Label { id: sessLabel; anchors.centerIn: parent; text: root.sessionName; size: 14; font.weight: Font.Bold }
            }
            Arrow { visible: sessions.count > 1; text: root.iRight; onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessions.count }
            Label { visible: sessions.count > 1; text: "Tab"; mono: true; size: 10; color: root.pal.muted }
        }
    }

    // ---- sağdan: güç menüsü ----
    Drawer {
        id: powerD
        edge: "right"
        open: (root.login || root.powerOpen) && root.intro > 0.6 && !root.exiting
        duration: 600
        radius: root.pr
        inner: root.width - root.t
        screenW: root.width
        contentW: 120
        contentH: powerCol.implicitHeight + 30
        along: (root.height - contentH) / 2
    }
    Item {
        parent: powerD.slot
        anchors.fill: parent
        ColumnLayout {
            id: powerCol
            anchors.centerIn: parent
            spacing: 10
            PowerButton { glyph: root.iSleep; label: "uyku"; tint: root.pal.tint; enabled: sddm.canSuspend; onActivated: sddm.suspend() }
            PowerButton { glyph: root.iRestart; label: "yeniden"; tint: root.pal.accent; enabled: sddm.canReboot; onActivated: sddm.reboot() }
            PowerButton { glyph: root.iPower; label: "kapat"; tint: root.red; enabled: sddm.canPowerOff; onActivated: sddm.powerOff() }
        }
    }

    // ---- klavye (karşılama ekranında herhangi bir tuş) ----
    Item {
        id: keys
        anchors.fill: parent
        focus: !root.login
        Keys.onPressed: e => {
            if (root.login) return
            root.showLogin()
            e.accepted = true
        }
    }

    // ---- yazma animasyonu durumları ----
    property real bump: 1
    property real glow: 0
    property real spin: 0
    property real failFlash: 0
    property int lastLen: 0
    property real wave: 0
    property string ghostShape: iPaw
    NumberAnimation on wave { from: 0; to: 2 * Math.PI; duration: 1800; loops: Animation.Infinite; running: root.login }
    ListModel { id: pwModel }
    function syncPaws(n) {
        n = Math.min(n, 13)
        while (pwModel.count < n)
            pwModel.append({ shape: Math.floor(Math.random() * pwShapes.length), tilt: Math.random() * 36 - 18 })
        while (pwModel.count > n) { ghostShape = pwShapes[pwModel.get(pwModel.count - 1).shape] || iPaw; pwModel.remove(pwModel.count - 1) }
    }
    Behavior on spin { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveDecel } }
    SequentialAnimation {
        id: bumpAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "bump"; to: 1.035; duration: 70; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "glow"; to: 1; duration: 70 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "bump"; to: 1; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curveSpatial }
            NumberAnimation { target: root; property: "glow"; to: 0; duration: 420; easing.type: Easing.OutCubic }
        }
    }
    SequentialAnimation {
        id: failAnim
        NumberAnimation { target: root; property: "failFlash"; to: 1; duration: 90 }
        PauseAnimation { duration: 500 }
        NumberAnimation { target: root; property: "failFlash"; to: 0; duration: 600 }
    }

    // ================================================================
    //                         küçük bileşenler
    // ================================================================
    component Label: Text {
        property real size: 13
        property bool mono: false
        color: root.pal.text
        font.family: mono ? root.fontMono : root.fontText
        font.pixelSize: size
        font.weight: Font.DemiBold
    }
    component Glyph: Text {
        property real size: 16
        color: root.pal.accent
        font.family: root.fontMono
        font.pixelSize: size
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    component Arrow: Rectangle {
        id: arr
        property alias text: g.text
        signal clicked()
        implicitWidth: 30; implicitHeight: 30; radius: 15
        color: am.containsMouse ? root.pal.surface3 : "transparent"
        Glyph { id: g; anchors.centerIn: parent; size: 18 }
        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: arr.clicked() }
    }
    component PowerButton: Rectangle {
        id: pbtn
        property string glyph
        property string label
        property color tint: root.pal.accent
        signal activated()
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 88; implicitHeight: 76
        radius: 22
        opacity: enabled ? 1 : 0.35
        color: pm.containsMouse && enabled ? tint : root.pal.surface
        border.width: 1
        border.color: Qt.alpha(tint, 0.4)
        scale: pm.pressed ? 0.92 : (pm.containsMouse ? 1.05 : 1)
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        Column {
            anchors.centerIn: parent
            spacing: 4
            Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: pbtn.glyph; size: 24; color: pm.containsMouse && pbtn.enabled ? root.pal.bg : pbtn.tint }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: pbtn.label; size: 12; font.weight: Font.Bold; color: pm.containsMouse && pbtn.enabled ? root.pal.bg : root.pal.text }
        }
        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (pbtn.enabled) pbtn.activated() }
    }
    component Ears: Item {
        id: ears
        property real earSize: 15
        property real inset: 1
        property color fill: root.pal.surface2
        property real line: 2
        height: earSize
        Repeater {
            model: 2
            Canvas {
                required property int index
                readonly property bool flip: index === 1
                width: ears.earSize; height: ears.earSize
                x: flip ? ears.width - width - ears.inset : ears.inset
                rotation: flip ? 12 : -12
                transformOrigin: Item.Bottom
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    const tip = flip ? width * 0.72 : width * 0.28
                    c.beginPath(); c.moveTo(1, height); c.lineTo(tip, 1.5); c.lineTo(width - 1, height); c.closePath()
                    c.fillStyle = ears.fill; c.fill()
                    c.lineWidth = ears.line; c.lineJoin = "round"; c.strokeStyle = root.pal.accent; c.stroke()
                    c.beginPath(); c.moveTo(width * 0.24, height); c.lineTo(flip ? width * 0.66 : width * 0.34, height * 0.32); c.lineTo(width * 0.76, height); c.closePath()
                    c.fillStyle = Qt.alpha(root.pal.accent, 0.45); c.fill()
                }
            }
        }
    }
}
