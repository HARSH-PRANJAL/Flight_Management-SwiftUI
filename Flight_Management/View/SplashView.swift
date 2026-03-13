import SwiftData
import SwiftUI

struct SplashView: View {
    @Environment(\.modelContext) private var context
    @Environment(SessionManager.self) var session
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showContent = false

    var body: some View {
        Group {
            if showContent {
                ContentView()
                    .environment(session)
            } else {
                GeometryReader { geo in

                    ZStack {
                        Color(.systemBackground)
                            .ignoresSafeArea()

                        VStack(spacing: geo.size.height * 0.03) {

                            LottieView(filename: "Airplane")
                                .frame(
                                    width: min(geo.size.width * 0.35, 360),
                                    height: min(geo.size.width * 0.35, 360)
                                )

                            Text("Trip Manager")
                                .font(
                                    .system(
                                        size: horizontalSizeClass == .regular
                                            ? 48 : 34,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
