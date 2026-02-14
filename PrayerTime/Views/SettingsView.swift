import SwiftUI

struct SettingsView: View {

    @Binding var showSettings: Bool
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Text("Settings coming in Phase 5")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
