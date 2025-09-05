<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1747665413/ChatGPT_Image_18._Mai_2025_16_37_57_rkbu11.png" alt="MindGear Icon" width="120" />
</p>

# **MindGear – Mentale Stärke für moderne Männer** 🧠🎧  
*iOS-App zur Selbstentwicklung und mentalen Gesundheit – speziell für Männer*

> ✨ Dieses Projekt zeigt nicht nur technische, sondern auch gestalterische Stärke:  
> Von AppTheme-Architektur bis hin zum Dark-Mode-Redesign wurden alle UI-Komponenten konsistent und portfolio-reif umgesetzt.

---

## 🚀 **Highlights**

- Native iOS-App mit **SwiftUI + MVVM**
- **Favoriten, Verlauf & Kategorien** mit SwiftData
- **YouTube API Integration** (Videos, Playlists, Mentoren)
- **Dark Mode & konsistentes Design** über AppTheme
- **Offline-fähig** dank Caching & Retry
- **Unit Tests** mit grünem Status

---

## 🧩 **Features**

- ✅ **Navigation über MainTabView** – Home, Videos, Favoriten, Kategorien, Mentoren, Playlists, Verlauf, Einstellungen  
- ✅ **HomeView** – Startseite mit kuratierten Playlists  
- ✅ **VideoListView** – Videos einer YouTube-Playlist, Suche mit Autovervollständigung & Pull-to-Refresh  
- ✅ **VideoDetailView** – integrierter YouTube-Player, Beschreibung, Favoriten-Button, automatisches Speichern im Verlauf  
- ✅ **FavoritenView** – einheitliche Verwaltung von Video-, Mentor- und Playlist-Favoriten, inkl. Suche & Swipe-to-Delete  
- ✅ **CategoriesView / CategoryDetailView** – thematische Entdeckung mit Playlist-Vorschauen  
- ✅ **MentorsView / MentorDetailView** – Seed-Daten + API-Update, Detailansicht mit Bio, Social Links & Playlists  
- ✅ **HistoryView** – zuletzt gesehene Videos, mit Löschfunktion  
- ✅ **SettingsView** – Benutzername, Notifications-Toggle (Stub), Link zum Verlauf  
- ✅ **Dark-Mode Design** – konsistentes Theming über `AppTheme`  
- ✅ **Offline-Fallbacks** – Seed-Daten, Response-Caching, Network-Retry  
- ✅ **Suche mit Debounce & Vorschlägen** – modernes `SearchField`  

---

## 🖼️ **Screenshots (Platzhalter)**

👉 Hier werden künftig Screenshots aus dem iOS-Simulator eingefügt:  
- HomeView  
- VideoDetailView  
- MentorsView  

*(aktuell Platzhalter – Screens folgen in Kürze)*

---

## 🛠️ **Tech Stack & Architektur**

- **SwiftUI** – deklaratives UI-Framework  
- **MVVM-Architektur** – konsequent umgesetzt für sauberen, testbaren Code  
- **SwiftData** – Favoriten, Playlists & Watch-History (`FavoriteVideoEntity`, `FavoriteMentorEntity`, `FavoritePlaylistEntity`, `WatchHistoryEntity`)  
- **YouTube API** – PlaylistItems & Channel-Endpunkte  
- **WebKit/WebView** – Einbettung externer Videos  
- **Manager & Services**  
  - `APIService` – YouTube-API mit Caching, Retry & Guards bei fehlenden Keys  
  - `NetworkManager` & `NetworkMonitor` – Offline-Erkennung, API-Key-Prüfung & Statusprüfung  
  - `FavoritesManager` – zentrales Favoriten-Handling  
  - `VideoManager` – Video-/Playlist-Helfer  
  - `ConfigManager` – Zugriff auf API-Key & Playlist-IDs aus `Config.plist`  
  - `NotificationManager`, `AnalyticsManager` – vorbereitet für kommende Features  

---

## 🔐 **Setup & Secrets**

MindGear nutzt eine lokale `Config.plist` für API-Keys & IDs.  
**Die echte Datei ist absichtlich nicht im Repo** – stattdessen liegt eine Vorlage (`Config.sample.plist`) bei.

**So startest du das Projekt:**
1. Kopiere `MindGear_iOS/Config/Config.sample.plist` → `Config.plist`.
2. Trage deinen **YouTube Data API v3** Key bei `YOUTUBE_API_KEY` ein.  
   (Optional: weitere Channel-/Playlist-IDs einfügen.)
3. Build & Run in Xcode.

> `.gitignore` sorgt dafür, dass `Config.plist` nicht ins Repo gelangt.

**Ohne API-Key?**  
- Die App crasht nicht.  
- Requests werden übersprungen, stattdessen werden Seed-Daten/Caches genutzt.  
- Im Debugger erscheinen klare Logs wie:  
  - `⚠️ [ConfigManager] Kein gültiger YOUTUBE_API_KEY (leer/REPLACE_ME).`  
  - `⚠️ [APIService] Kein gültiger API Key – überspringe Request, nutze Seed/Cache.`  
  - `⚠️ [NetworkManager] offline – skip network …`

---

## ✅ **Testabdeckung**

Alle wichtigen Kernkomponenten wurden mit **Unit Tests** abgesichert  
(ConfigManager, FavoritesManager, MentorSearch).  

<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1756995107/Unit_Tests_vavwls.png" alt="Unit Tests – alle grün" width="600" />
</p>

---

## ✨ **Design-Inspiration (Figma)**

Die visuelle Gestaltung basiert auf hochwertigen Figma UI-Kits aus der Community, angepasst für Zielgruppe & Dark-Mode:  
- 🥇 Onboarding Screens – Simple & Smart  
- 🥈 Freud – Mental Health App Kit  
- 🥉 Meditation Mobile App (DesignWave Studio)  
- 🧩 Lumina – Productivity App (Dark Mode)  
- 🔄 Mental Wellness Mobile App – Modern UI Kit  

Diese Vorlagen flossen ins Moodboard und in den finalen Prototypen ein.

---

## 📆 **Projektstatus**

- 🔄 **Letztes Update:** September 2025  
- 🧱 **Aktueller Stand:** iOS-Version fertig für Portfolio, inkl. API-Härtung & Onboarding  

---

## 🤝 **Kontakt & Mitwirken**

Dieses Projekt ist Teil meines Portfolios als Mobile App Developer.  
Ich freue mich über Rückmeldungen, Hinweise oder Kooperationen:

📫 GitHub Issues | 📬 Xing / LinkedIn (auf Anfrage)

---

**🚀 MindGear – Denkanstöße. Klarheit. Stärke.**  
*Entdecke deine mentale Power – täglich neu.*
