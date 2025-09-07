//
//  NetworkManager.swift
//  MindGear_iOS
//
//  Zweck: Netzwerk-Monitor (Reachability) + schlanke Netzwerk-Fassade für Mentor-Ladevorgänge.
//  Architekturrolle: Service/Manager (Utility um URLSession & Network.framework; kein YouTube-spezifisches Decoding).
//  Verantwortung: Online/Offline-State, Kosten-/Datenlimit-Erkennung, einfache GET/Download-Helfer für Mentor-APIs.
//  Warum? Trennung von generischem Networking (hier) und domänenspezifischem APIService (YouTube-Logik).
//  Testbarkeit: ObservableObject (NetworkMonitor) + injizierbare Session; Funktionen sind leicht zu mocken.
//  Status: stabil.
//

// Kurzzusammenfassung: Reachability (NWPathMonitor) + Mentor-Convenience-Calls mit defensiven Guards.
// Überwacht die Verbindung und lädt Mentoren aus der YouTube-API
import Foundation
import Network
import Combine

// MARK: - Debug Helpers
#if DEBUG
@inline(__always) private func dlog(_ message: @autoclosure () -> String) {
    print("[NetworkManager] \(message())")
}
@inline(__always) private func maskKey(_ key: String) -> String {
    let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count > 8 else { return "••••" }
    let suffix = trimmed.suffix(4)
    return "••••••••\(suffix)"
}
#else
@inline(__always) private func dlog(_ message: @autoclosure () -> String) {}
@inline(__always) private func maskKey(_ key: String) -> String { key }
#endif

// MARK: - NetworkMonitor (Reachability)
// Warum: UI braucht verlässlichen Online/Offline-Zustand & Interface-Infos (Wi‑Fi/Cellular) für UX-Entscheidungen.
final class NetworkMonitor: ObservableObject {
    // Singleton-Instanz – ein Monitor für die gesamte App
    static let shared = NetworkMonitor()
    // MARK: - State
    @Published private(set) var isOnline: Bool = true
    @Published private(set) var isExpensive: Bool = false      // z. B. Hotspot
    @Published private(set) var isConstrained: Bool = false    // Low Data Mode
    @Published private(set) var interface: NWInterface.InterfaceType? = nil

    // MARK: - Interna
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor.queue")

    // MARK: - Init
    private init() {
        // Startet NWPathMonitor und spiegelt den Zustand sauber auf den Main-Thread.
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isOnline = (path.status == .satisfied)
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained

                // Merke dir die aktuell genutzte Schnittstelle (WiFi/Cellular/Ethernet)
                if let used = path.availableInterfaces.first(where: { path.usesInterfaceType($0.type) }) {
                    self.interface = used.type
                } else {
                    self.interface = nil
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}

// MARK: - Convenience
extension NetworkMonitor {
    var isOffline: Bool { !isOnline }

    var interfaceDescription: String {
        switch interface {
        case .wifi: return "Wi‑Fi"
        case .cellular: return "Mobilfunk"
        case .wiredEthernet: return "Ethernet"
        case .loopback: return "Loopback"
        case .other: return "Andere"
        case .none: return "Unbekannt"
        @unknown default: return "Unbekannt"
        }
    }
}


// MARK: - NetworkManager (Mentor-Convenience)
// Warum: Dünne Fassade um APIService; hier nur Guards/Maskierung/Monitor-Nutzung.
final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    /// Minimale API-Key-Validierung.
    /// Warum: Frühe Fehlerabweisung; verhindert unnötige Netzaufrufe.
    private func isValidApiKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "REPLACE_ME"
    }

    // Zentraler Reachability-Zugriff (UI- & Service-Entscheidungen)
    private var monitor: NetworkMonitor { NetworkMonitor.shared }

    /// Lädt einen Mentor per YouTube-Handle.
    /// Warum: Defensiv (Key/Offline) + Logging; Delegation des echten Calls an APIService.
    @MainActor
    func loadMentor(byHandle handle: String, apiKey: String) async throws -> Mentor {
        dlog("fetch by handle=\(handle), key=\(maskKey(apiKey))")
        guard isValidApiKey(apiKey) else {
            dlog("⚠️ missing/placeholder API key – skip network (byHandle)")
            throw AppError.networkError
        }
        guard monitor.isOnline else {
            dlog("⚠️ offline – skip network (byHandle)")
            // UX: Statt stillen Fehlschlags klarer AppError → ViewModels können Hinweise anzeigen.
            throw AppError.networkError
        }
        let response = try await APIService.shared.fetchChannel(byHandle: handle, apiKey: apiKey)
        guard let item = response.items.first else { throw AppError.networkError }
        dlog("OK by handle → id=\(item.id), title=\(item.snippet.title)")
        return mapChannelItemToMentor(item)
    }

    /// Lädt einen Mentor per Channel-ID.
    /// Warum: Gleiche Guards wie bei Handle-Variante; deterministische Rückgabe.
    @MainActor
    func loadMentor(byChannelId id: String, apiKey: String) async throws -> Mentor {
        dlog("fetch by channelId=\(id), key=\(maskKey(apiKey))")
        guard isValidApiKey(apiKey) else {
            dlog("⚠️ missing/placeholder API key – skip network (byChannelId)")
            throw AppError.networkError
        }
        guard monitor.isOnline else {
            dlog("⚠️ offline – skip network (byChannelId)")
            // UX: Statt stillen Fehlschlags klarer AppError → ViewModels können Hinweise anzeigen.
            throw AppError.networkError
        }
        let response = try await APIService.shared.fetchChannel(byId: id, apiKey: apiKey)
        guard let item = response.items.first else { throw AppError.networkError }
        dlog("OK by id → id=\(item.id), title=\(item.snippet.title)")
        return mapChannelItemToMentor(item)
    }

    /// Lädt einen Mentor – bevorzugt per Channel-ID, fällt auf Handle zurück.
    /// Warum: Flexibel für unterschiedliche Datenstände; robustes Fallback mit Logging.
    @MainActor
    func loadMentor(preferId channelId: String?, handle: String?, apiKey: String) async throws -> Mentor {
        let idTrimmed = channelId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let handleTrimmed = handle?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidApiKey(apiKey) else {
            dlog("⚠️ missing/placeholder API key – skip network (preferId/handle)")
            throw AppError.networkError
        }
        guard monitor.isOnline else {
            dlog("⚠️ offline – skip network (preferId/handle)")
            // UX: Statt stillen Fehlschlags klarer AppError → ViewModels können Hinweise anzeigen.
            throw AppError.networkError
        }

        guard (idTrimmed?.isEmpty == false) || (handleTrimmed?.isEmpty == false) else {
            dlog("❗️missing identifiers: both channelId and handle are empty")
            throw AppError.networkError
        }

        do {
            if let id = idTrimmed, !id.isEmpty {
                dlog("→ trying ID-first (\(id)), key=\(maskKey(apiKey))")
                let response = try await APIService.shared.fetchChannel(byId: id, apiKey: apiKey)
                if let item = response.items.first {
                    dlog("✅ resolved via ID → \(item.id)")
                    return mapChannelItemToMentor(item)
                }
                dlog("⚠️ no items via ID, falling back to handle…")
            }
            if let h = handleTrimmed, !h.isEmpty {
                dlog("→ fallback to handle (\(h)), key=\(maskKey(apiKey))")
                let response = try await APIService.shared.fetchChannel(byHandle: h, apiKey: apiKey)
                if let item = response.items.first {
                    dlog("✅ resolved via handle → \(item.id)")
                    return mapChannelItemToMentor(item)
                }
            }
            dlog("❗️no items from API (id=\(idTrimmed ?? "nil"), handle=\(handleTrimmed ?? "nil"))")
            throw AppError.networkError
        } catch {
            dlog("❌ API error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Wählt die beste verfügbare Thumbnail-Qualität.
    /// Warum: Einheitliches Bild in Listen/Details; verhindert inkonsistente Darstellungen.
    @MainActor
    private func bestThumbnailURL(_ thumbs: YouTubeChannelThumbnails) -> String? {
        thumbs.high?.url ?? thumbs.medium?.url ?? thumbs.defaultThumb?.url
    }

    /// Mappt YouTube-ChannelItem auf das App-Domänenmodell `Mentor`.
    /// Warum: Entkoppelt API-Schema vom UI-Modell; zentrale Stelle für spätere Anpassungen.
    @MainActor
    private func mapChannelItemToMentor(_ item: YouTubeChannelItem) -> Mentor {
        let snip = item.snippet

        let name = snip.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let bioRaw = snip.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let thumb = bestThumbnailURL(snip.thumbnails)

        return Mentor(
            id: item.id,
            name: name.isEmpty ? "Unbekannter Mentor" : name,
            profileImageURL: thumb,
            bio: bioRaw.isEmpty ? nil : bioRaw,
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/channel/\(item.id)")
            ]
        )
    }
}
