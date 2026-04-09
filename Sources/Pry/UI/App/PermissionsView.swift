import SwiftUI
import AVFoundation
import CoreLocation
import UserNotifications
import Photos
import Contacts
import EventKit

/// Dashboard showing the current status of all iOS permissions.
struct PermissionsView: View {

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var refreshID = UUID()

    var body: some View {
        List {
            Section {
                permissionRow(
                    icon: "camera",
                    name: "Camera",
                    status: avStatus(AVCaptureDevice.authorizationStatus(for: .video))
                )
                permissionRow(
                    icon: "mic",
                    name: "Microphone",
                    status: avStatus(AVCaptureDevice.authorizationStatus(for: .audio))
                )
                permissionRow(
                    icon: "bell.badge",
                    name: "Notifications",
                    status: notificationPermissionStatus
                )
                permissionRow(
                    icon: "photo.on.rectangle",
                    name: "Photo Library",
                    status: photoStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
                )
                permissionRow(
                    icon: "person.crop.circle",
                    name: "Contacts",
                    status: contactsStatus(CNContactStore.authorizationStatus(for: .contacts))
                )
                permissionRow(
                    icon: "location",
                    name: "Location",
                    status: locationStatus
                )
                permissionRow(
                    icon: "calendar",
                    name: "Calendar",
                    status: eventStatus(EKEventStore.authorizationStatus(for: .event))
                )
                permissionRow(
                    icon: "checklist",
                    name: "Reminders",
                    status: eventStatus(EKEventStore.authorizationStatus(for: .reminder))
                )
            } header: {
                Text("Permissions")
            }
            .listRowBackground(PryTheme.Colors.surface)

            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("Open Settings", systemImage: "gear")
                            .font(PryTheme.Typography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(PryTheme.Colors.accent)
                        Spacer()
                    }
                }
            }
            .listRowBackground(PryTheme.Colors.surface)
        }
        .id(refreshID)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .pryBackground()
        .task { await fetchNotificationStatus() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await fetchNotificationStatus() }
                    refreshID = UUID()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Row

    private func permissionRow(icon: String, name: String, status: PermissionStatus) -> some View {
        HStack(spacing: PryTheme.Spacing.md) {
            Image(systemName: icon)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.accent)
                .frame(width: PryTheme.Size.iconMedium, height: PryTheme.Size.iconMedium)
                .background(PryTheme.Colors.accent.opacity(PryTheme.Opacity.tint))
                .clipShape(.rect(cornerRadius: PryTheme.Radius.sm))

            Text(name)
                .font(PryTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(PryTheme.Colors.textPrimary)

            Spacer()

            Text(status.label)
                .font(.system(size: PryTheme.FontSize.smallIcon, weight: .bold))
                .foregroundStyle(status.color)
                .padding(.horizontal, PryTheme.Spacing.sm)
                .padding(.vertical, PryTheme.Spacing.xxs)
                .background(status.color.opacity(PryTheme.Opacity.badge))
                .clipShape(.capsule)
        }
    }

    // MARK: - Status Model

    private enum PermissionStatus {
        case granted, denied, notAsked, restricted, limited

        var label: String {
            switch self {
            case .granted:    "Granted"
            case .denied:     "Denied"
            case .notAsked:   "Not Asked"
            case .restricted: "Restricted"
            case .limited:    "Limited"
            }
        }

        var color: Color {
            switch self {
            case .granted:    PryTheme.Colors.success
            case .denied:     PryTheme.Colors.error
            case .notAsked:   PryTheme.Colors.textTertiary
            case .restricted: PryTheme.Colors.warning
            case .limited:    PryTheme.Colors.pending
            }
        }
    }

    // MARK: - Status Mappers

    private func avStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:                    .granted
        case .denied:                        .denied
        case .restricted:                    .restricted
        case .notDetermined:                 .notAsked
        @unknown default:                    .notAsked
        }
    }

    private var notificationPermissionStatus: PermissionStatus {
        switch notificationStatus {
        case .authorized:    .granted
        case .denied:        .denied
        case .provisional:   .limited
        case .ephemeral:     .limited
        case .notDetermined: .notAsked
        @unknown default:    .notAsked
        }
    }

    private func photoStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:    .granted
        case .denied:        .denied
        case .restricted:    .restricted
        case .limited:       .limited
        case .notDetermined: .notAsked
        @unknown default:    .notAsked
        }
    }

    private func contactsStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:    .granted
        case .denied:        .denied
        case .restricted:    .restricted
        case .notDetermined: .notAsked
        case .limited:       .limited
        @unknown default:    .notAsked
        }
    }

    private var locationStatus: PermissionStatus {
        let manager = CLLocationManager()
        return switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: .granted
        case .denied:                                 .denied
        case .restricted:                             .restricted
        case .notDetermined:                          .notAsked
        @unknown default:                             .notAsked
        }
    }

    private func eventStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .fullAccess, .authorized: .granted
        case .denied:                  .denied
        case .restricted:              .restricted
        case .notDetermined:           .notAsked
        case .writeOnly:               .limited
        @unknown default:              .notAsked
        }
    }

    // MARK: - Async

    private func fetchNotificationStatus() async {
        let status = await UNUserNotificationCenter.current().currentAuthorizationStatus()
        await MainActor.run { notificationStatus = status }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Permissions") {
    NavigationStack {
        PermissionsView()
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
