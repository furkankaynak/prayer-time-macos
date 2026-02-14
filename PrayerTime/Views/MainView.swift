import SwiftUI
import Adhan

struct MainView: View {

    @EnvironmentObject var prayerViewModel: PrayerViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                SettingsView(showSettings: $showSettings)
            } else {
                prayerContent
            }
        }
        .frame(width: 320, height: 420)
    }

    private var prayerContent: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            SunPositionView(
                progress: prayerViewModel.sunProgress,
                sunriseTime: prayerViewModel.todayTimes?.entry(for: .sunrise)?.formattedTime ?? "--:--",
                sunsetTime: prayerViewModel.todayTimes?.entry(for: .maghrib)?.formattedTime ?? "--:--"
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 16)

            if let times = prayerViewModel.todayTimes {
                PrayerListView(
                    entries: times.entries,
                    currentPrayer: prayerViewModel.currentPrayer,
                    nextPrayer: prayerViewModel.nextPrayer,
                    countdownText: prayerViewModel.countdownText
                )
                .padding(.top, 4)
            } else {
                noLocationView
            }

            Spacer(minLength: 0)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(settingsViewModel.savedLocation?.displayName ?? "No Location Set")
                    .font(.headline)
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var noLocationView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "location.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Set your location in Settings")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Open Settings") {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    private var dateString: String {
        Self.dateFormatter.string(from: Date())
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}
