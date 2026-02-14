import SwiftUI

struct SettingsView: View {

    @Binding var showSettings: Bool
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var locationViewModel: LocationViewModel
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    locationSection
                    Divider()
                    calculationMethodSection
                    Divider()
                    notificationsSection
                    Divider()
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
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
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let location = settingsViewModel.savedLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                    Text(location.displayName)
                        .font(.body)
                    Spacer()
                }
                .padding(8)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            TextField("Search city...", text: $locationViewModel.searchText)
                .textFieldStyle(.roundedBorder)

            if locationViewModel.isSearching {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !locationViewModel.searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(locationViewModel.searchResults) { result in
                        Button {
                            locationViewModel.selectResult(result)
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundStyle(.orange)
                                Text(result.displayName)
                                    .font(.callout)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)

                        if result.id != locationViewModel.searchResults.last?.id {
                            Divider()
                        }
                    }
                }
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if !locationViewModel.isLocationDenied {
                Button {
                    locationViewModel.detectLocation()
                } label: {
                    HStack(spacing: 4) {
                        if locationViewModel.isLocating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location")
                        }
                        Text("Use My Location")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .disabled(locationViewModel.isLocating)
            }

            if let error = locationViewModel.locationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Calculation Method

    private var calculationMethodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calculation Method")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Method", selection: $settingsViewModel.selectedMethod) {
                ForEach(CalculationMethodOption.allCases) { method in
                    Text(method.displayName).tag(method)
                }
            }
            .labelsHidden()

            Text("Asr Calculation")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Picker("Madhab", selection: $settingsViewModel.selectedMadhab) {
                ForEach(MadhabOption.allCases) { madhab in
                    Text(madhab.displayName).tag(madhab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if !notificationService.isAuthorized {
                Button("Enable Notifications") {
                    Task {
                        await notificationService.requestAuthorization()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                HStack {
                    Text("Alert before prayer")
                    Spacer()
                    Stepper(
                        "\(settingsViewModel.notificationMinutesBefore) min",
                        value: $settingsViewModel.notificationMinutesBefore,
                        in: 0...60,
                        step: 5
                    )
                    .fixedSize()
                }

                Toggle("Show floating panel", isOn: $settingsViewModel.showFloatingPanel)

                if settingsViewModel.showFloatingPanel {
                    Toggle("Always show Dynamic Island", isOn: $settingsViewModel.alwaysShowDynamicIsland)
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("About")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                Text("PrayerTime")
                    .font(.body)
                Spacer()
                Text(appVersion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
}
