// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 realFelinora — Felinora SDDM
// Felinora-shell ile aynı renk paletleri (theme.conf → palette=<id>)
.pragma library

var themes = [
    { id: "pembe", name: "Pembe Gece", desc: "pembe & mor",
      bg: "#0a090d", bgAlt: "#0f0d13", surface: "#141119", surface2: "#1c1823", surface3: "#27212f", border: "#2a2332", frame: "#0b0a0e",
      accent: "#ff79c6", accentSoft: "#ffb8e0", accent2: "#a77bff", accent2Deep: "#6f45d9", tint: "#d6c1ff",
      text: "#f2eaf7", subtext: "#a197b0", muted: "#5d5469" },
    { id: "obsidyen", name: "Obsidyen", desc: "simsiyah + pembe & mor", frameTint: 0,
      bg: "#070608", bgAlt: "#0b0a0d", surface: "#121015", surface2: "#1a171e", surface3: "#25202b", border: "#26212c", frame: "#050406",
      accent: "#ff79c6", accentSoft: "#ffb8e0", accent2: "#a77bff", accent2Deep: "#6f45d9", tint: "#d6c1ff",
      text: "#f2eaf7", subtext: "#a197b0", muted: "#5d5469" },
    { id: "gece", name: "Gece Moru", desc: "derin menekşe",
      bg: "#08080d", bgAlt: "#0d0c14", surface: "#12111a", surface2: "#1a1824", surface3: "#252233", border: "#262335", frame: "#0a0910",
      accent: "#b794ff", accentSoft: "#dccbff", accent2: "#7c6cff", accent2Deep: "#4c3fc9", tint: "#cfc6ff",
      text: "#ece9f7", subtext: "#9b97b3", muted: "#565271" },
    { id: "kan", name: "Kan Kırmızısı", desc: "koyu kızıl",
      bg: "#0b0708", bgAlt: "#110b0d", surface: "#161012", surface2: "#1f1619", surface3: "#2b1e22", border: "#2e2024", frame: "#0d0809",
      accent: "#ff4d6d", accentSoft: "#ffb3c1", accent2: "#c9184a", accent2Deep: "#800f2f", tint: "#ffccd5",
      text: "#f7eaec", subtext: "#b39a9f", muted: "#6b5458" },
    { id: "buz", name: "Buz Mavisi", desc: "soğuk ve sakin",
      bg: "#07090d", bgAlt: "#0b0e14", surface: "#10141b", surface2: "#171c25", surface3: "#212836", border: "#222a37", frame: "#090b10",
      accent: "#7dd3fc", accentSoft: "#c9ecff", accent2: "#818cf8", accent2Deep: "#4f46e5", tint: "#c7d2fe",
      text: "#e8eef7", subtext: "#94a3b8", muted: "#526075" },
    { id: "sakura", name: "Sakura", desc: "açık pembe & fuşya",
      bg: "#0c090b", bgAlt: "#120d10", surface: "#171215", surface2: "#20191d", surface3: "#2c2228", border: "#30252b", frame: "#0e0a0c",
      accent: "#ffa6c9", accentSoft: "#ffd6e5", accent2: "#e879f9", accent2Deep: "#a21caf", tint: "#ffe4ef",
      text: "#fbeef3", subtext: "#b8a2ad", muted: "#6e5a64" },
    { id: "nane", name: "Nane", desc: "nane & lavanta",
      bg: "#070a09", bgAlt: "#0b0f0e", surface: "#0f1513", surface2: "#161e1b", surface3: "#1f2a26", border: "#203029", frame: "#090c0b",
      accent: "#6ee7b7", accentSoft: "#c6f6e3", accent2: "#a78bfa", accent2Deep: "#6d28d9", tint: "#d1fae5",
      text: "#e8f5ef", subtext: "#93ada3", muted: "#50655d" }
];

function get(id) {
    for (var i = 0; i < themes.length; i++) if (themes[i].id === id) return themes[i]
    return themes[0]
}
