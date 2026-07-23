import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Daily dashboard")
                .font(.title2.bold())

            Text("The app shell is ready. Feature work comes next.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.95, blue: 0.90), Color(red: 0.93, green: 0.97, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

