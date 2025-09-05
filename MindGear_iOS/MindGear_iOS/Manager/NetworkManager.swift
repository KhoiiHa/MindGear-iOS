//
//  NetworkManager.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 12.08.25.
//

import Foundation
import Network
import Combine

// MARK: - Debug helpers
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

/// Zentraler Netzwerk-Monitor für die gesamte App.
/// Nutzung in Views:
///   @StateObject private var network = NetworkMonitor.shared
///   if network.isOffline { ... }
final class NetworkMonitor: ObservableObject {
    // Singleton-Instanz – ein Monitor für die gesamte App
    static let shared = NetworkMonitor()

    // Veröffentlicht: Online-/Offline-Status
    @Published private(set) var isOnline: Bool = true
    @Published private(set) var isExpensive: Bool = false      // z. B. Hotspot
    @Published private(set) var isConstrained: Bool = false    // Low Data Mode
    @Published private(set) var interface: NWInterface.InterfaceType? = nil

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor.queue")

    private init() {
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

// Praktische Convenience
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


// MARK: - NetworkManager (Mentor Convenience)
final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    // MARK: - Helpers
    private func isValidApiKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "REPLACE_ME"
    }

    private var monitor: NetworkMonitor { NetworkMonitor.shared }

    /// Lädt einen Mentor per YouTube-Handle (z. B. "ShiHengYiOnline") und mappt ihn auf dein `Mentor`-Model.
    @MainActor
    func loadMentor(byHandle handle: String, apiKey: String) async throws -> Mentor {
        dlog("fetch by handle=\(handle), key=\(maskKey(apiKey))")
        guard isValidApiKey(apiKey) else {
            dlog("⚠️ missing/placeholder API key – skip network (byHandle)")
            throw AppError.networkError
        }
        guard monitor.isOnline else {
            dlog("⚠️ offline – skip network (byHandle)")
            throw AppError.networkError
        }
        let response = try await APIService.shared.fetchChannel(byHandle: handle, apiKey: apiKey)
        guard let item = response.items.first else { throw AppError.networkError }
        dlog("OK by handle → id=\(item.id), title=\(item.snippet.title)")
        return mapChannelItemToMentor(item)
    }

    /// Lädt einen Mentor per YouTube-Channel-ID (z. B. "UCRRtZjnxd5N6Vvq-jU9uoOw") und mappt ihn auf dein `Mentor`-Model.
    @MainActor
    func loadMentor(byChannelId id: String, apiKey: String) async throws -> Mentor {
        dlog("fetch by channelId=\(id), key=\(maskKey(apiKey))")
        guard isValidApiKey(apiKey) else {
            dlog("⚠️ missing/placeholder API key – skip network (byChannelId)")
            throw AppError.networkError
        }
        guard monitor.isOnline else {
            dlog("⚠️ offline – skip network (byChannelId)")
            throw AppError.networkError
        }
        let response = try await APIService.shared.fetchChannel(byId: id, apiKey: apiKey)
        guard let item = response.items.first else { throw AppError.networkError }
        dlog("OK by id → id=\(item.id), title=\(item.snippet.title)")
        return mapChannelItemToMentor(item)
    }

    /// Lädt einen Mentor – bevorzugt per Channel-ID, fällt auf Handle zurück
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

    // MARK: - Mapping
    @MainActor
    private func bestThumbnailURL(_ thumbs: YouTubeChannelThumbnails) -> String? {
        thumbs.high?.url ?? thumbs.medium?.url ?? thumbs.defaultThumb?.url
    }

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
