<p align="center">
  <img src="https://res.cloudinary.com/dpaehynl2/image/upload/v1747665413/ChatGPT_Image_18._Mai_2025_16_37_57_rkbu11.png" alt="MindGear Icon" width="120" />
</p>

# **MindGear – Mentale Stärke für moderne Männer** 🧠🎧  
*iOS-App zur Selbstentwicklung und mentalen Gesundheit – speziell für Männer*

> ✨ Dieses Projekt zeigt nicht nur technische, sondern auch gestalterische Stärke:  
> Von AppTheme-Architektur bis hin zum Dark-Mode-Redesign wurden alle UI-Komponenten konsistent und portfolio-reif umgesetzt.

**MindGear** ist eine native iOS-App für Männer, die in herausfordernden Zeiten Orientierung, mentale Stärke und neue Impulse suchen.  
Die App bietet eine kuratierte Auswahl an YouTube-Videos und Podcasts von bekannten Denkern, Mentoren und Interviewern wie:

- Chris Williamson, Lex Fridman  
- The Diary of a CEO, HealthyGamerGG, Shi Heng Yi  
- Jordan B. Peterson, Simon Sinek, Jay Shetty u. v. m.

Durch thematische Empfehlungen, Favoritenfunktion und eine leistungsstarke Suche unterstützt MindGear dich dabei, neue Perspektiven zu gewinnen und deine innere Widerstandskraft zu stärken.

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

## 🛠️ **Tech Stack & Architektur**

- **SwiftUI** – Deklaratives UI-Framework  
- **MVVM** – saubere Trennung von Views, ViewModels & Models  
- **SwiftData** – Favoriten, Playlists & Watch-History (`FavoriteVideoEntity`, `FavoriteMentorEntity`, `FavoritePlaylistEntity`, `WatchHistoryEntity`)  
- **YouTube API** – PlaylistItems & Channel-Endpunkte  
- **WebKit/WebView** – Einbettung externer Videos  
- **Manager/Services**  
  - `APIService` – YouTube-API mit Caching & Retry  
  - `NetworkManager` & `NetworkMonitor` – Offline-Erkennung & Statusprüfung  
  - `FavoritesManager` – zentrales Favoriten-Handling  
  - `VideoManager` – Video-/Playlist-Helfer  
  - `ConfigManager` – Zugriff auf API-Key & Playlist-IDs aus `Config.plist`  
  - `NotificationManager`, `AnalyticsManager` – vorbereitet für kommende Features  

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

## 🧪 **Offene Punkte (To-Dos)**

- [ ] `OnboardingView` – Navigation & Inhalte umsetzen  
- [ ] `NotificationManager` – echte Push-Benachrichtigungen (Reminder)  
- [ ] `AnalyticsManager` – Anbindung an Analytics-SDK  
- [ ] Konsistente Naming-Strategie (Deutsch/Englisch vereinheitlichen)  
- [ ] Duplikate auflösen (`VideoManager` vs. `Video.swift`)  
- [ ] Erweiterte Detailansichten für Playlists & History  
- [ ] Suche-Chips in `VideoListView` aktivieren  

---

## 📆 **Projektstatus**

- 🔄 **Letztes Update:** August 2025  
- 🧱 **Aktueller Fokus:** Favoriten-Logik, API-Integration, Dark-Mode  
- 🎯 **Ziel:** Testphase & Release-Readiness  

---

## 🤝 **Kontakt & Mitwirken**

Dieses Projekt ist Teil meines Portfolios als Mobile App Developer.  
Ich freue mich über Rückmeldungen, Hinweise oder Kooperationen:

📫 GitHub Issues | 📬 Xing / LinkedIn (auf Anfrage)

---

**🚀 MindGear – Denkanstöße. Klarheit. Stärke.**  
*Entdecke deine mentale Power – täglich neu.*
