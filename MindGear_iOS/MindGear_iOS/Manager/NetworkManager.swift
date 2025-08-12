//
//  NetworkManager.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 12.08.25.
//

//
//  NetworkManager.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 12.08.25.
//

import Foundation
import Network
import Combine

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
