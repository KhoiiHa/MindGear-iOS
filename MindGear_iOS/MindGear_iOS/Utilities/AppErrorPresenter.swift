//
//  
//
//  Created by Vu Minh Khoi Ha on 08.09.25.
//

//
//  AppErrorPresenter.swift
//  MindGear_iOS
//
//  Zweck: Zentrale Abbildung von AppError → Nutzertexte.
//  Warum: Einheitliche Sprache, weniger Duplikate, klare UX.
//

import Foundation

enum AppErrorPresenter {
    /// Primäre Meldung für die UI (Banner/Alert)
    static func message(for error: AppError) -> String {
        // Priorität: Recovery → Description → Fallback
        if let suggest = error.recoverySuggestion, !suggest.isEmpty { return suggest }
        if let desc = error.errorDescription, !desc.isEmpty { return desc }
        return "Ein Fehler ist aufgetreten. Bitte später erneut versuchen."
    }

    /// Optionaler Kontext/Hinweis (z. B. Offline)
    static func hint(for error: AppError) -> String? {
        if error.isNetworkRelated { return "Offline oder Serverproblem erkannt." }
        return nil
    }
}
