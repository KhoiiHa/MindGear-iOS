<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1747665413/ChatGPT_Image_18._Mai_2025_16_37_57_rkbu11.png" alt="MindGear Icon" width="120" />
</p>

# **MindGear – iOS-App für mentale Stärke & Selbstentwicklung** 🧠🎧  
*iOS-App zur Selbstentwicklung und mentalen Gesundheit – speziell für Männer*

> ✨ Dieses Projekt zeigt sowohl **technische Tiefe** als auch **gestalterische Stärke**:  
> Von AppTheme-Architektur bis hin zum Dark-Mode-Redesign – alle UI-Komponenten wurden konsistent und portfolio-reif umgesetzt.  
> **Neu:** Die gesamte **App-UI ist zweisprachig (Deutsch/Englisch)**, während internationale Inhalte (YouTube, Mentoren-Bios) bewusst im **Original (Englisch)** angezeigt werden – inkl. klarer Hinweis im UI.  

---

## 🚀 **Highlights**

- Native iOS-App mit **SwiftUI + MVVM**
- **Favoriten, Verlauf & Kategorien** mit SwiftData
- **YouTube API Integration** (Videos, Playlists, Mentoren)
- **Dark Mode & konsistentes Design** via AppTheme
- **Zweisprachige UI (DE/EN)** über Localizable.strings
- **Hinweis für englischsprachige Inhalte** (Video- & Mentor-Detailansichten)
- **Offline-fähig** dank Caching & Retry
- **Unit Tests** mit grünem Status ✅

---

## 🧩 **Features**

- **Intuitive Navigation** über Tabs: Start, Videos, Favoriten, Kategorien, Mentoren, Playlists, Verlauf, Einstellungen  
- **Kuratiertes Home**: empfohlene Playlists mit Offline-Cache  
- **Video-Listen & Detailansicht**: Suche mit Autovervollständigung, Verlauf & Favoriten-Option  
- **Mentoren-Profilseiten**: Bio, Social Links & empfohlene Playlists (inkl. Hinweis: *„Inhalt auf Englisch“*)  
- **Favoriten**: Videos, Playlists & Mentoren speichern und verwalten  
- **Kategorien**: thematische Entdeckung von Inhalten  
- **Verlauf**: zuletzt gesehene Videos inkl. Löschfunktion  
- **Einstellungen**: Benutzername, Benachrichtigungen (Stub), Link zum Verlauf  
- **Dark-Mode Design**: konsistente Farben, Typografie & Spacing-Tokens  
- **Suche mit Debounce & Vorschlägen**: modernes `SearchField`  
- **Offline-Fallbacks**: Seed-Daten, Response-Caching, Network-Retry  

---

## 🌍 **Mehrsprachigkeit**

- **App-UI vollständig lokalisiert**: Deutsch & Englisch (Tabs, Onboarding, Settings, Empty States)  
- **API-Inhalte bewusst im Original**: Internationale Mentoren & YouTube-Beschreibungen bleiben Englisch  
- **UX-Hinweis im UI**: Klare Kennzeichnung *„Inhalt auf Englisch“*, um Nutzer zu informieren  

---

## ❓ **Warum MindGear?**

Die Idee für **MindGear** entstand aus meiner eigenen Auseinandersetzung mit mentaler Gesundheit und Persönlichkeitsentwicklung.  
Ich wollte eine App schaffen, die:

- Inhalte von internationalen Mentoren und Denkern **kuratieren** und leicht zugänglich machen.  
- Männern (und allen Interessierten) eine **strukturierte Plattform** für Selbstreflexion und Inspiration bietet.  
- Mir als Entwickler die Chance gab, **YouTube-API, SwiftData-Persistenz und modernes iOS-Design** (Dark Mode, AppTheme, Komponenten) **praxisnah zu erlernen**.

> Dieses Projekt ist eine Kombination aus **persönlicher Motivation** und **technischem Lernziel** – eine App, die ich selbst gerne nutze und die gleichzeitig mein Können als Mobile Developer zeigt.

---

## 🖼️ **Screenshots**

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1757505241/Simulator_Screenshot_-_iPhone_16_Pro_-_2025-09-10_at_13.44.35_ugmxun.png" alt="Onboarding" width="220" />
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1757505278/Simulator_Screenshot_-_iPhone_16_Pro_-_2025-09-10_at_13.46.08_fsic9x.png" alt="Home – Empfohlene Playlists" width="220" />
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1757505291/Simulator_Screenshot_-_iPhone_16_Pro_-_2025-09-10_at_13.46.24_ptjhih.png" alt="Kategorien-Übersicht" width="220" />
</p>

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1757505331/Simulator_Screenshot_-_iPhone_16_Pro_-_2025-09-10_at_13.47.12_q2zdkh.png" alt="Mentoren-Liste" width="220" />
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1757505364/Simulator_Screenshot_-_iPhone_16_Pro_-_2025-09-10_at_13.47.26_ptjvdy.png" alt="Favoriten – leerer Zustand" width="220" />
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1757505388/Simulator_Screenshot_-_iPhone_16_Pro_-_2025-09-10_at_13.47.41_i2ye10.png" alt="Favoriten – mit Inhalten" width="220" />
</p>

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1757505409/Simulator_Screenshot_-_iPhone_16_Pro_-_2025-09-10_at_13.48.33_j0afix.png" alt="Video-Detailansicht (Englischer Inhalt)" width="220" />
</p>

---

## 🛠️ **Tech Stack & Architektur**

- **SwiftUI** – modernes UI-Framework  
- **MVVM-Architektur** – saubere Trennung von UI & Logik  
- **SwiftData** – Persistenz für Favoriten, Playlists & Watch-History  
- **YouTube API v3** – dynamische Inhalte (Videos, Channels, Playlists)  
- **WebKit/WebView** – YouTube-Player nahtlos integriert  
- **Manager & Services**  
  - `APIService` – YouTube-Requests mit Caching, Retry & Guard-Logik  
  - `NetworkManager` & `NetworkMonitor` – Offline-Erkennung & API-Key-Checks  
  - `FavoritesManager` – zentrales Favoriten-Handling  
  - `VideoManager` – Video-/Playlist-Utilities  
  - `ConfigManager` – Zugriff auf API-Key & Playlist-IDs aus `Config.plist`  
  - `NotificationManager`, `AnalyticsManager` – vorbereitet für künftige Features  

---

## 🔐 **Setup & Secrets**

Die App nutzt eine **lokale `Config.plist`** für API-Keys & IDs.  
Die echte Datei ist **nicht im Repo** – stattdessen liegt eine Vorlage (`Config.sample.plist`) bei.

**Setup in 3 Schritten:**
1. Kopiere `MindGear_iOS/Config/Config.sample.plist` → `Config.plist`.  
2. Trage deinen **YouTube Data API v3** Key bei `YOUTUBE_API_KEY` ein.  
   (Optional: zusätzliche Channel-/Playlist-IDs einfügen)  
3. Build & Run in Xcode.  

> Ohne API-Key werden automatisch **Seed-Daten** oder **Caches** genutzt.  
> Debugger zeigt klare Logs, z. B.:  
> `⚠️ [APIService] Kein gültiger API Key – nutze Seed/Cache.`

---

## ✅ **Testabdeckung**

Alle Kernkomponenten sind mit **Unit Tests** abgesichert  
(ConfigManager, FavoritesManager, MentorSearch).  

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1756995107/Unit_Tests_vavwls.png" alt="Unit Tests – alle grün" width="600" />
</p>

---

## 🎨 **Design-Inspiration (Figma)**

Die Gestaltung basiert auf hochwertigen Figma UI-Kits, angepasst an Zielgruppe & Dark-Mode:  
- 🥇 Onboarding Screens – Simple & Smart  
- 🥈 Freud – Mental Health App Kit  
- 🥉 Meditation App (DesignWave Studio)  
- 🧩 Lumina – Productivity App (Dark Mode)  
- 🔄 Mental Wellness Mobile App – Modern UI Kit  

---

## 📆 **Projektstatus**

- 🔄 **Letztes Update:** September 2025  
- ✅ **Aktueller Stand:** iOS-Version fertig für Portfolio (inkl. API-Härtung, Onboarding & Mehrsprachigkeit)  

---

## 🤝 **Kontakt & Mitwirken**

Dieses Projekt ist Teil meines Portfolios als Mobile App Developer.  
Ich freue mich über Feedback, Hinweise oder Kooperationen:

📫 GitHub Issues | 📬 Xing / LinkedIn (auf Anfrage)

---

**🚀 MindGear – Denkanstöße. Klarheit. Stärke.**  
*Entdecke deine mentale Power – täglich neu.*
