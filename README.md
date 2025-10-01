<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1759330282/MindGear_README_SlideWide_1600x900_nilt0u.png" alt="MindGear Header" width="100%" />
</p>

# 🧠 **MindGear – iOS-App für Mentoring & Video-Learning**

*iOS-App zur Selbstentwicklung & mentalen Klarheit – speziell für Männer.*

> ✨ Dieses Projekt verbindet **technische Tiefe** mit **klarer UI**:  
> SwiftUI, YouTube API, Offline-Strategien & Dark Mode – alles in einer durchdachten MVVM-Architektur.  
> Die App ist **zweisprachig (DE/EN)** – Inhalte wie Mentoren-Bios und Videos bleiben bewusst im englischen Original, inkl. UX-Hinweis im Interface.

---

## 📄 Case Study

📘 [PDF ansehen → MindGear Case Study Final.pdf](./MindGear%20Case%20Study%20Final.pdf)

Enthält technische Highlights, Designentscheidungen & Learnings.

---

## 🚀 Highlights

- 🔍 YouTube-Integration mit Playlists & Mentoren
- ❤️ Favoriten, Watch-History & Seed-Fallbacks (SwiftData)
- 🌘 Dark Mode only – modern & clean
- 🗂️ Strukturierte Architektur (Views, ViewModels, Services)
- 🌍 DE/EN UI mit `Localizable.strings`
- ✅ Unit Tests auf Kernlogik (z. B. Config, Favoriten, Suche)

---

## 🧩 Features

- Autovervollständigung für Video-Suche 🎯  
- Mentoren-Profilseiten mit Playlist & Biografie  
- Kategorien- und Playlists-Ansicht (dynamisch oder Fallback)  
- Verlauf, Favoriten & lokale Caches  
- YouTube-Videos via WebView, mit Fallback bei Offline-Zugriff  

---

## 🛠️ Tech Stack & Architektur

- **SwiftUI**, **MVVM**, **SwiftData**
- **YouTube API v3** – Playlists, Channels, Videos
- **Cloudinary** + `SDWebImageSwiftUI` (Mentoren-Avatare)
- **WebKit** für Video-Einbettung (YouTube-Player)
- **Fallback & Caching** mit `URLSession`, Seed JSONs & Manager-Struktur
- **Optional**: `AnalyticsManager`, `NotificationManager`

---

## ⚙️ Setup in Xcode

1. `Config/Config.sample.plist` → kopieren als `Config.plist`
2. `YOUTUBE_API_KEY` eintragen (und optional Channel-/Playlist-IDs)
3. Build & Run

> 🔄 Kein Key? → App nutzt automatisch Seed-Daten oder Caches.  
> 🛠 Logs zeigen: `⚠️ Kein gültiger API Key – nutze Seed/Cache.`

---

## ✅ Testabdeckung

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1756995107/Unit_Tests_vavwls.png" alt="Unit Tests – alle grün" width="600" />
</p>

---

## 🧠 UX & Design

- Dark Mode UI mit sanfter Typografie  
- Figma-Kits: *Freud*, *Onboarding Smart*, *Lumina*, *DesignWave Studio*  
- Fokus auf „Klartext statt UI-Lärm“  
- Mentoren-Avatare: Cloudinary CDN & LazyLoad

---

## 📆 Projektstatus

- 🔄 Letztes Update: September 2025  
- ✅ Status: Fertig für Portfolio + Case Study + Unit Tests

---

## 👋 Kontakt

Minh Khoi Ha · Mobile App Developer (iOS/Android)  
[💼 LinkedIn](https://www.linkedin.com/in/minh-khoi-ha-209561142)  
[🌐 GitHub Profil](https://github.com/KhoiiHa)

---

**🚀 MindGear – Denkanstöße. Klarheit. Stärke.**  
👉 Entwickelt als Portfolio-Projekt (SwiftUI · SwiftData · YouTube API)
