import SwiftData
import SwiftUI

struct SplashView: View {
    @Environment(\.modelContext) private var context
    @Environment(SessionManager.self) var session
    @State private var showContent = false

    var body: some View {
        Group {
            if showContent {
                ContentView()
                    .environment(session)
            } else {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image("AppIconPreview")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        Text("Flight Management")
                            .font(.title2)
                            .bold()
                    }
                }
                .task {
                    let start = Date()

                    await DemoDataAPI.seedIfNeeded(in: context)

                    await DemoDataAPI.resolveExpiredTrips(in: context)
                    DemoDataAPI.startAutoUpdates(in: context)

                    let duration = Date().timeIntervalSince(start)
                    print("Seeding took \(duration) seconds")
                    if duration < 0.5 {
                        try? await Task.sleep(for: .seconds(2))
                    }

                    await MainActor.run {
                        withAnimation(.easeOut) {
                            showContent = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .modelContainer(for: User.self, inMemory: true)
        .environment(SessionManager.shared)
}
