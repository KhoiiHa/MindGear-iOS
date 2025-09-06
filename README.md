<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1747665413/ChatGPT_Image_18._Mai_2025_16_37_57_rkbu11.png" alt="MindGear Icon" width="120" />
</p>

# **MindGear – Mentale Stärke für moderne Männer** 🧠🎧  
*iOS-App zur Selbstentwicklung und mentalen Gesundheit – speziell für Männer*

> ✨ Dieses Projekt zeigt sowohl **technische Tiefe** als auch **gestalterische Stärke**:  
> Von AppTheme-Architektur bis hin zum Dark-Mode-Redesign – alle UI-Komponenten wurden konsistent und portfolio-reif umgesetzt.

---

## 🚀 **Highlights**

- Native iOS-App mit **SwiftUI + MVVM**
- **Favoriten, Verlauf & Kategorien** mit SwiftData
- **YouTube API Integration** (Videos, Playlists, Mentoren)
- **Dark Mode & konsistentes Design** via AppTheme
- **Offline-fähig** dank Caching & Retry
- **Unit Tests** mit grünem Status ✅

---

## 🧩 **Features**

- **Intuitive Navigation** über Tabs: Start, Videos, Favoriten, Kategorien, Mentoren, Playlists, Verlauf, Einstellungen  
- **Kuratiertes Home**: empfohlene Playlists mit Offline-Cache  
- **Video-Listen & Detailansicht**: Suche mit Autovervollständigung, Verlauf & Favoriten-Option  
- **Mentoren-Profilseiten**: Bio, Social Links & empfohlene Playlists  
- **Favoriten**: Videos, Playlists & Mentoren speichern und verwalten  
- **Kategorien**: thematische Entdeckung von Inhalten  
- **Verlauf**: zuletzt gesehene Videos inkl. Löschfunktion  
- **Einstellungen**: Benutzername, Benachrichtigungen (Stub), Link zum Verlauf  
- **Dark-Mode Design**: konsistente Farben, Typografie & Spacing-Tokens  
- **Suche mit Debounce & Vorschlägen**: modernes `SearchField`  
- **Offline-Fallbacks**: Seed-Daten, Response-Caching, Network-Retry  

---

## 🖼️ **Screenshots (Platzhalter)**

👉 Geplante Screenshots aus dem iOS-Simulator:  
- HomeView  
- VideoDetailView  
- MentorsView  

*(aktuell Platzhalter – Screens folgen in Kürze)*

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
- ✅ **Aktueller Stand:** iOS-Version fertig für Portfolio (inkl. API-Härtung & Onboarding)  

---

## 🤝 **Kontakt & Mitwirken**

Dieses Projekt ist Teil meines Portfolios als Mobile App Developer.  
Ich freue mich über Feedback, Hinweise oder Kooperationen:

📫 GitHub Issues | 📬 Xing / LinkedIn (auf Anfrage)

---

**🚀 MindGear – Denkanstöße. Klarheit. Stärke.**  
*Entdecke deine mentale Power – täglich neu.*
