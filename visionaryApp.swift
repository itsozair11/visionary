import SwiftUI

@main
struct visionaryApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                OnboardingView()
            }
        }
    }
}
