<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1759330282/MindGear_README_SlideWide_1600x900_nilt0u.png" alt="MindGear App Banner" width="640" />
</p>

<h1 align="center">🧠 MindGear – iOS App für Mentoring & mentale Stärke</h1>
<h3 align="center"><em>MindGear – iOS App for Mentorship & Mental Focus</em></h3>

---

## 🇩🇪 Einführung  
MindGear ist eine minimalistische iOS-App zur **Selbstentwicklung und mentalen Klarheit**, entwickelt mit **SwiftUI**, **SwiftData** und der **YouTube-API**.  
Die App kombiniert Fokus-Videos, Mentorenprofile und Offline-Caching in einer klaren, modernen MVVM-Architektur.

> Ziel: Eine ruhige, strukturierte Umgebung schaffen – für Menschen, die ihre mentale Stärke gezielt trainieren möchten.

## 🇬🇧 Introduction  
MindGear is a minimalist iOS app for **self-development and mental clarity**, built using **SwiftUI**, **SwiftData**, and the **YouTube API**.  
It combines focus videos, mentor profiles, and offline caching in a clean, modern MVVM architecture.

> Goal: Provide a calm and structured space for people who want to grow their mindset intentionally.

---

## 📄 Case Study  
📘 [PDF ansehen / View PDF → MindGear Case Study](./MindGear_CaseStudy.pdf)

### 🇩🇪  
Die Case Study zeigt Architektur, Designentscheidungen und Learnings – ideal für Portfolio und Bewerbungsgespräche.  

### 🇬🇧  
The case study outlines architecture, design decisions and learnings – ideal for portfolios and interviews.

---

## 🚀 Highlights  

### 🇩🇪  
- 🎥 **YouTube API v3** – kuratierte Playlists & Mentoren  
- ❤️ **Favoriten + Verlauf** – SwiftData-Persistenz  
- 🧩 **Offline-First** – Seed-Fallbacks & Caching  
- 🌘 **Dark Mode only** – ruhiges, fokussiertes UI  
- 🌍 **Deutsch & Englisch** über `Localizable.strings`  
- 🗂 **MVVM-Struktur** mit klaren Verantwortlichkeiten  
- ✅ **Unit Tests** für Config, Favoriten & Suche

### 🇬🇧  
- 🎥 **YouTube API v3** – curated playlists & mentors  
- ❤️ **Favorites + History** – persisted via SwiftData  
- 🧩 **Offline-First** – seed fallbacks & caching  
- 🌘 **Dark Mode only** – calm, focused UI  
- 🌍 **Bilingual UI (DE/EN)** with `Localizable.strings`  
- 🗂 **MVVM architecture** with clear responsibilities  
- ✅ **Unit tests** for config, favorites & search

---

## 🧩 Features  

### 🇩🇪  
- 🔎 Autovervollständigung & Debounce-Suche  
- 🧘 Mentorenprofile mit Biografie & Playlists  
- 🗂 Kategorienansicht & dynamische Playlists  
- 🕒 Verlauf & Favoriten mittels SwiftData  
- 📶 Offline-Modus mit automatischer Seed-Umschaltung  
- 🌐 YouTube-WebPlayer mit Retry-Logik

### 🇬🇧  
- 🔎 Autocomplete & debounced search  
- 🧘 Mentor profiles with bio & playlists  
- 🗂 Category view & dynamic playlist loading  
- 🕒 History & favorites stored with SwiftData  
- 📶 Offline mode with automatic seed fallback  
- 🌐 Embedded YouTube player with retry logic

---

## 🛠️ Tech Stack & Architektur  

### 🇩🇪  
- **SwiftUI · MVVM · SwiftData**  
- **YouTube API v3** für Video-Inhalte  
- **Cloudinary + SDWebImageSwiftUI** für Mentorenbilder  
- **NetworkMonitor & URLCache** für Offline/Retry  
- **AppTheme** für Farben, Abstände, Typografie  
- **Optionale Module:** `AnalyticsManager`, `NotificationManager`

### 🇬🇧  
- **SwiftUI · MVVM · SwiftData**  
- **YouTube API v3** for video content  
- **Cloudinary + SDWebImageSwiftUI** for mentor avatars  
- **NetworkMonitor & URLCache** for offline & retry  
- **AppTheme** for colors, spacing & typography  
- **Optional:** `AnalyticsManager`, `NotificationManager`

---

## ⚙️ Setup in Xcode  

### 🇩🇪  
1. `Config/Config.sample.plist` → kopieren als `Config.plist`  
2. `YOUTUBE_API_KEY` eintragen  
3. Build & Run  

> 🔄 Kein Key? → App nutzt automatisch Seeds oder Cache.

### 🇬🇧  
1. Copy `Config/Config.sample.plist` → rename to `Config.plist`  
2. Add your `YOUTUBE_API_KEY`  
3. Build & Run  

> 🔄 No API key? → Seeds or cached data will be used.

---

## ✅ Testabdeckung / Testing  

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1756995107/Unit_Tests_vavwls.png" alt="Unit Tests – alle grün" width="600" />
</p>

### 🇩🇪  
- **Unit Tests:** ConfigManager, FavoritesManager, SearchService  
- **Manuelle Tests:** Offline, Fehlerfälle, Lokalisierung  
- **Geplant:** Snapshot-Tests & Offline-Simulation

### 🇬🇧  
- **Unit Tests:** ConfigManager, FavoritesManager, SearchService  
- **Manual tests:** offline behaviour, load errors, localization  
- **Planned:** snapshot tests & offline simulation

---

## 🧠 UX & Design  

### 🇩🇪  
- Dark Mode only  
- Ruhige Typografie & klare Layouts  
- Figma-Kits: *Freud*, *Onboarding Smart*, *Lumina*, *DesignWave Studio*  
- Cloudinary-CDN + Lazy Loading für Avatare  

### 🇬🇧  
- Dark mode only  
- Calm typography & clear layouts  
- Figma kits: *Freud*, *Onboarding Smart*, *Lumina*, *DesignWave Studio*  
- Cloudinary CDN + lazy loading for avatars

---

## 🔍 Codex Review Insights  

### 🇩🇪  
- Dependency Injection statt Singletons  
- Feineres Error Handling  
- Mehr Unit Tests (SwiftData/Offline)  
- Konsistente englische Namensgebung  
- README zeigt Verbesserungen transparent  

### 🇬🇧  
- Dependency injection instead of singletons  
- More granular error handling  
- Expand unit tests (SwiftData/offline)  
- Consistent English naming  
- README highlights improvements clearly  

---

## 📆 Projektstatus / Project Status  

### 🇩🇪  
- 🔄 Letztes Update: **September 2025**  
- ✅ Bereit für Portfolio, Case Study & Testing

### 🇬🇧  
- 🔄 Last update: **September 2025**  
- ✅ Ready for portfolio, case study & testing

---

## 👋 Kontakt / Contact  

**Vu Minh Khoi Ha** – Mobile App Developer (iOS / Android)  
[💼 LinkedIn](https://www.linkedin.com/in/minh-khoi-ha-209561142) • [🌐 GitHub](https://github.com/KhoiiHa)

---

<h3 align="center">🚀 MindGear – Klarheit. Fokus. Mentale Stärke.</h3>
<p align="center"><em>Built with SwiftUI · SwiftData · YouTube API.</em></p>
