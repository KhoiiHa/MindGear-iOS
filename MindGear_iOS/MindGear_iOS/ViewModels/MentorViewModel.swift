
//
//  MentorViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import Foundation

class MentorViewModel: ObservableObject {
    @Published var mentor: Mentor

    init(mentor: Mentor) {
        self.mentor = mentor
        // Hier kannst du später API-Calls, Favoriten-Logik etc. ergänzen
    }

    // Beispiel für weitere Methoden:
    // func loadMentorDetails() async { ... }
    // func toggleFavorite() { ... }
}

