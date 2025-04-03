import SwiftUI

struct MainTabView: View {
    @State private var showComingSoonAlert = false

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            AlbumsView()
                .tabItem {
                    Label("Albums", systemImage: "photo.on.rectangle")
                }

            Text("Camera tab")
                .onTapGesture {
                    showComingSoonAlert = true
                }
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }
                .alert("Camera Coming Soon", isPresented: $showComingSoonAlert) {
                    Button("OK", role: .cancel) { }
                }
        }
    }
}
