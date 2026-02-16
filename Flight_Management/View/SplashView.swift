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
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        Text("Flight Management")
                            .font(.title2)
                            .bold()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut) {
                            showContent = true
                        }
                    }
                    Task {
                        let start = Date()
                        await DemoDataAPI.seedIfNeeded(in: context)
                        DemoDataAPI.startAutoUpdates(in: context)
                        let elapsed = Date().timeIntervalSince(start)
                        let minDelay: TimeInterval = 1.5
                        if elapsed < minDelay {
                            do { try await Task.sleep(nanoseconds: UInt64((minDelay - elapsed) * 1_000_000_000)) } catch { }
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
}

#Preview {
    SplashView()
        .modelContainer(for: User.self, inMemory: true)
        .environment(SessionManager.shared)
}
