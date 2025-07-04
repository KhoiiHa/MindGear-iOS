import SwiftUI

struct FavoritenView: View {
    var body: some View {
        VStack {
            Text("⭐ Deine Favoriten")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("Hier werden deine gespeicherten Favoriten angezeigt.")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Favoriten")
    }
}

struct FavoritenView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritenView()
    }
}
