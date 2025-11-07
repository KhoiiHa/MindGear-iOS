<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1759330282/MindGear_README_SlideWide_1600x900_nilt0u.png" alt="MindGear App Banner" width="640" />
</p>

<h1 align="center">🧠 MindGear – iOS App für Mentoring & mentale Stärke</h1>
<h3 align="center"><em>MindGear – iOS App for Mentorship & Mental Focus</em></h3>

---

## 🇩🇪 Einführung  
MindGear ist eine minimalistische iOS-App zur **Selbstentwicklung und mentalen Klarheit**, entwickelt mit **SwiftUI**, **SwiftData** und der **YouTube-API**.  
Sie kombiniert Fokus-Videos, Mentoren-Profile und Offline-Caching in einer klaren, modernen MVVM-Architektur.

> Ziel: Eine App schaffen, die Struktur, Ruhe und technische Präzision vereint – für Menschen, die mentale Stärke trainieren möchten.

## 🇬🇧 Introduction  
MindGear is a minimalist iOS app for **self-development and mental clarity**, built using **SwiftUI**, **SwiftData**, and the **YouTube API**.  
It combines focus videos, mentor profiles, and offline caching within a clean and modern MVVM architecture.

> Goal: To create an app that blends structure, calmness, and technical precision – designed for people who want to strengthen their mindset.

---

## 📄 Case Study  
📘 [PDF ansehen / View PDF → MindGear Case Study Final.pdf](./MindGear%20Case%20Study%20Final.pdf)

### 🇩🇪  
Die Case Study enthält technische Architektur, Designentscheidungen und persönliche Learnings – ideal für Portfolio und Bewerbungsgespräche.  

### 🇬🇧  
The case study includes technical architecture, design decisions, and personal learnings – ideal for portfolios and interviews.

---

## 🚀 Highlights  

### 🇩🇪  
- 🎥 **YouTube API v3** – Playlists & Mentoren mit Filterung  
- ❤️ **Favoriten + Verlauf** – Speicherung & Caching mit SwiftData  
- 🧩 **Offline-First Strategie** – Seed-Fallbacks & lokale Datenhaltung  
- 🌘 **Dark Mode only** – klar, ruhig, professionell  
- 🌍 **Zweisprachige UI (DE/EN)** mit `Localizable.strings`  
- 🗂 **MVVM-Struktur** mit klaren ViewModels und Managern  
- ✅ **Unit Tests** für Kernlogik (Config, Favoriten, Suche)

### 🇬🇧  
- 🎥 **YouTube API v3** – curated playlists & mentors  
- ❤️ **Favorites + History** – stored & cached via SwiftData  
- 🧩 **Offline-First Strategy** – seed fallbacks & local persistence  
- 🌘 **Dark Mode only** – clean, focused and professional  
- 🌍 **Bilingual UI (DE/EN)** via `Localizable.strings`  
- 🗂 **MVVM Architecture** with clear ViewModels and managers  
- ✅ **Unit Tests** for core logic (Config, Favorites, Search)

---

## 🧩 Features  

### 🇩🇪  
- 🔎 Autovervollständigung & Debounce-Suche für Videos  
- 🧘 Mentorenprofile mit Biografie & zugehörigen Playlists  
- 🗂 Kategorien-Ansicht & dynamische Playlists  
- 🕒 Verlauf & Favoriten lokal gespeichert mit SwiftData  
- 📶 Offline-Modus mit automatischer Seed-Umschaltung  
- 🌐 YouTube-Player via WebView (inkl. Retry-Logik)

### 🇬🇧  
- 🔎 Autocomplete & debounced search for videos  
- 🧘 Mentor profiles with bio & related playlists  
- 🗂 Category view and dynamic playlists  
- 🕒 History and favorites stored locally with SwiftData  
- 📶 Offline mode with automatic seed switching  
- 🌐 Embedded YouTube player via WebView (with retry logic)

---

## 🛠️ Tech Stack & Architektur  

### 🇩🇪  
- **SwiftUI · MVVM · SwiftData**  
- **YouTube API v3** für Video-Inhalte  
- **Cloudinary + SDWebImageSwiftUI** für Mentor-Avatare  
- **NetworkMonitor & URLCache** für stabile Offline-Erfahrung  
- **AppTheme** für Farben, Abstände und Typografie  
- **Optionale Module:** `AnalyticsManager`, `NotificationManager`

### 🇬🇧  
- **SwiftUI · MVVM · SwiftData**  
- **YouTube API v3** for video content  
- **Cloudinary + SDWebImageSwiftUI** for mentor avatars  
- **NetworkMonitor & URLCache** for resilient offline experience  
- **AppTheme** for colors, spacing, and typography  
- **Optional modules:** `AnalyticsManager`, `NotificationManager`

---

## ⚙️ Setup in Xcode  

### 🇩🇪  
1. `Config/Config.sample.plist` → kopieren als `Config.plist`  
2. Trage deinen `YOUTUBE_API_KEY` ein (optional Channel-/Playlist-IDs)  
3. Build & Run  

> 🔄 Kein Key? → App nutzt automatisch Seed- oder Cache-Daten.  
> 🧾 Log: `⚠️ Kein gültiger API Key – nutze Seed/Cache.`

### 🇬🇧  
1. Copy `Config/Config.sample.plist` → rename to `Config.plist`  
2. Insert your `YOUTUBE_API_KEY` (optional channel/playlist IDs)  
3. Build & Run  

> 🔄 No API key? → The app automatically uses seed or cached data.  
> 🧾 Log: `⚠️ No valid API key – using seed/cache mode.`

---

## ✅ Testabdeckung / Testing  

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1756995107/Unit_Tests_vavwls.png" alt="Unit Tests – alle grün" width="600" />
</p>

### 🇩🇪  
- **Unit Tests:** ConfigManager · FavoritesManager · SearchService  
- **Manuelle Tests:** Offline-Fallback · Ladefehler · Lokalisierung  
- **Geplant:** Snapshot- und Offline-Simulationstests  

### 🇬🇧  
- **Unit Tests:** ConfigManager · FavoritesManager · SearchService  
- **Manual Tests:** Offline fallback · YouTube load errors · Localization  
- **Planned:** Snapshot and offline simulation tests  

---

## 🧠 UX & Design  

### 🇩🇪  
- Dark Mode UI mit ruhiger Typografie & stimmiger Farbpalette  
- Figma-Kits: *Freud*, *Onboarding Smart*, *Lumina*, *DesignWave Studio*  
- Fokus auf Lesbarkeit & Struktur statt visueller Ablenkung  
- Mentoren-Avatare: Cloudinary CDN + Lazy Loading  

### 🇬🇧  
- Dark Mode UI with calm typography and consistent color palette  
- Figma kits: *Freud*, *Onboarding Smart*, *Lumina*, *DesignWave Studio*  
- Focus on clarity and readability instead of visual overload  
- Mentor avatars: Cloudinary CDN + Lazy Loading  

---

## 🔍 Codex Review Insights / Verbesserungsvorschläge  

### 🇩🇪  
> Diese Punkte stammen aus einem **Senior-Review durch Codex**.  
> Sie sind nicht zwingend notwendig, zeigen aber **technisches Verständnis und Weiterentwicklungspotenzial** – ein Pluspunkt bei Bewerbungen.

- **Dependency Injection:** Ersetze Singletons (`APIService.shared`) schrittweise durch Injektion (z. B. Environment Container) für bessere Testbarkeit.  
- **Error Handling:** Detailliertere Fehlerdifferenzierung in `NetworkManager` (z. B. APIError, TimeoutError).  
- **Unit Tests:** Erweiterung der Testabdeckung (SwiftData Sync, Offline Simulation).  
- **Naming Consistency:** Einheitliche englische Bezeichnungen für Views & Dateien.  
- **README-Erweiterung:** Dokumentation dieser Verbesserungen (du liest sie gerade 😉).  

### 🇬🇧  
> These insights come from a **senior-level Codex review**.  
> They are not mandatory but demonstrate **technical awareness and growth potential** – a strong advantage in job applications.

- **Dependency Injection:** Gradually replace singletons (`APIService.shared`) with injected dependencies (e.g., Environment Container) to improve testability.  
- **Error Handling:** Add more granular error types in `NetworkManager` (e.g., APIError, TimeoutError).  
- **Unit Tests:** Expand test coverage (SwiftData sync, offline simulation).  
- **Naming Consistency:** Ensure consistent English naming for all views and files.  
- **README Extension:** Document these improvements (you’re reading them now 😉).  

---

## 📆 Projektstatus / Project Status  

### 🇩🇪  
- 🔄 Letztes Update: **September 2025**  
- ✅ Status: **Fertig für Portfolio / Case Study / Testing**

### 🇬🇧  
- 🔄 Last update: **September 2025**  
- ✅ Status: **Ready for portfolio, case study, and testing**

---

## 👋 Kontakt / Contact  

**Vu Minh Khoi Ha** · Mobile App Developer (iOS / Android)  
[💼 LinkedIn](https://www.linkedin.com/in/minh-khoi-ha-209561142) • [🌐 GitHub](https://github.com/KhoiiHa)

---

<h3 align="center">🚀 MindGear – Denkanstöße. Klarheit. Stärke.</h3>
<p align="center"><em>Developed as a portfolio project using SwiftUI · SwiftData · YouTube API.</em></p>
