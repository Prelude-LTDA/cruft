import SwiftUI

struct SidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        List {
            Section("Regeneration Effort") {
                RegenEffortSegments(selection: $model.filterTier)
            }

            Section("Sources") {
                SystemCachesRow(model: model)
                GlobalCachesRow(model: model)
                ForEach(model.scanRoots) { root in
                    RootRow(
                        root: root,
                        toggle: { model.setRootEnabled(root.path, enabled: !root.enabled) },
                        remove: { removeRoot(root) }
                    )
                }
                SpotlightRow(model: model)
                Button {
                    addScanRoot()
                } label: {
                    Label("Add Folder…", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
        }
        .listStyle(.sidebar)
    }

    private func addScanRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            let root = ScanRoot(path: url.path, isDefault: false)
            guard !model.scanRoots.contains(where: { $0.path == root.path }) else { return }
            var roots = model.scanRoots
            roots.append(root)
            model.updateScanRoots(roots)   // persists + triggers rescan
        }
    }

    private func removeRoot(_ root: ScanRoot) {
        guard !root.isDefault else { return }
        let roots = model.scanRoots.filter { $0.path != root.path }
        model.updateScanRoots(roots)
    }
}

/// A custom segmented control for the RegenEffort tiers. SwiftUI's
/// `.segmented` Picker collapses icons to monochrome; this one preserves
/// each tier's brand color on both idle and selected states.
///
/// Styling follows Xcode 26's Liquid Glass segmented toolbars: a fully
/// capsule-shaped outer track, a capsule-shaped selection pill that fills
/// the track edge-to-edge, and thin vertical hairlines between adjacent
/// unselected segments that fade out when either neighbor becomes selected.
private struct RegenEffortSegments: View {
    @Binding var selection: RegenEffort

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(RegenEffort.allCases.enumerated()), id: \.offset) { idx, tier in
                if idx > 0 {
                    separator(between: RegenEffort.allCases[idx - 1], and: tier)
                }
                segment(for: tier)
            }
        }
        .padding(2)
        .background(
            Capsule(style: .continuous)
                .fill(Color.secondary.opacity(0.10))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func segment(for tier: RegenEffort) -> some View {
        let isOn = tier == selection
        Button {
            selection = tier
        } label: {
            Image(systemName: tier.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tier.tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Capsule(style: .continuous)
                .fill(isOn
                      ? Color.primary.opacity(0.14)
                      : Color.clear)
        )
        .help(tier.title)
    }

    /// Thin vertical hairline shown only between two adjacent unselected
    /// segments. Keeps its 1pt column so the layout doesn't shift as the
    /// selection moves — opacity toggles instantly since the selection pill
    /// itself snaps without animation.
    @ViewBuilder
    private func separator(between left: RegenEffort, and right: RegenEffort) -> some View {
        let visible = left != selection && right != selection
        Rectangle()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 1, height: 18)
            .opacity(visible ? 1 : 0)
    }
}

/// A single row representing a user-added (or default) scan root, with a
/// Calendar-style enable checkbox and an on-hover remove button.
private struct RootRow: View {
    let root: ScanRoot
    let toggle: () -> Void
    let remove: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            Toggle(isOn: Binding(get: { root.enabled }, set: { _ in toggle() })) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()

            Image(systemName: root.exists ? "folder" : "folder.badge.questionmark")
                .foregroundStyle(root.exists ? Color.secondary : Color.orange)
                .frame(width: 18, alignment: .center)
            Text((root.path as NSString).abbreviatingWithTildeInPath)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.head)
                .foregroundStyle(root.enabled ? .primary : .secondary)
            Spacer()
            if !root.isDefault, hovering {
                Button(action: remove) {
                    Image(systemName: "minus.circle").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove this scan root")
            }
        }
        .onHover { hovering = $0 }
        .contextMenu {
            FindingActions.contextButtons(for: [root.url.path])
            if !root.isDefault {
                Divider()
                Button("Remove", role: .destructive, action: remove)
            }
        }
    }
}

/// A synthetic "source" row for the Spotlight-wide discovery pass.
private struct SpotlightRow: View {
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            Toggle(isOn: $model.spotlightEnabled) { EmptyView() }
                .toggleStyle(.checkbox)
                .labelsHidden()

            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .center)
            Text("Spotlight")
                .font(.caption)
                .foregroundStyle(model.spotlightEnabled ? .primary : .secondary)
            Spacer()
        }
        .help("Include matches found anywhere in your home via Spotlight. Dimmed in the list.")
    }
}

/// Row for root-owned system paths (`/nix/store`, `/opt/local/var/macports/*`).
/// Cleaning these requires the sudo password prompt.
private struct SystemCachesRow: View {
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            Toggle(isOn: $model.systemCachesEnabled) { EmptyView() }
                .toggleStyle(.checkbox)
                .labelsHidden()

            Image(systemName: "externaldrive")
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .center)
            Text("System")
                .font(.caption)
                .foregroundStyle(model.systemCachesEnabled ? .primary : .secondary)
            Spacer()
        }
        .help("Root-owned paths (e.g. /nix/store, /opt/local/var/macports). Cleaning these requires your password.")
    }
}

/// Row for the hardcoded global-cache paths (Xcode DerivedData, ~/.cargo, etc.).
private struct GlobalCachesRow: View {
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            Toggle(isOn: $model.globalCachesEnabled) { EmptyView() }
                .toggleStyle(.checkbox)
                .labelsHidden()

            Image(systemName: "house")
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .center)
            Text("Current User")
                .font(.caption)
                .foregroundStyle(model.globalCachesEnabled ? .primary : .secondary)
            Spacer()
        }
        .help("User-scoped package caches and build artifacts at known paths (Xcode DerivedData, ~/.cargo, ~/.npm, Homebrew, etc.).")
    }
}
