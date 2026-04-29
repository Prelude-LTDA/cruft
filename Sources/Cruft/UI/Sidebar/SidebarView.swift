import SwiftUI

struct SidebarView: View {
    @Bindable var model: AppModel

    var body: some View {
        List {
            Section("Regeneration Effort") {
                RegenEffortSegments(selection: $model.filterTier)
            }

            Section("Sources") {
                // Empty-state nudge for users whose code lives at non-canonical
                // paths (e.g. ~/Documents/Projetos). Sits at the top of the
                // Sources section so a fresh user sees it before the toggles.
                // No dismiss animation — SwiftUI's List intercepts row-level
                // transitions and ignores List-level animation context too.
                if model.scanRoots.isEmpty && !model.emptyScanRootsCalloutDismissed {
                    EmptyScanRootsCallout(
                        addScanRoot: addScanRoot,
                        dismiss: { model.emptyScanRootsCalloutDismissed = true }
                    )
                }
                SystemCachesRow(model: model)
                PerAppCachesRow(model: model)
                GlobalCachesRow(model: model)
                ForEach(model.scanRoots) { root in
                    RootRow(
                        root: root,
                        toggle: { model.setRootEnabled(root.path, enabled: !root.enabled) },
                        remove: { removeRoot(root) }
                    )
                }
                SpotlightRow(model: model)
                // Always-visible "Add Folder…" link. Quietly available
                // once the empty-state nudge has done its job (or been
                // dismissed).
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
            model.updateScanRoots(roots)  // persists + triggers rescan
        }
    }

    private func removeRoot(_ root: ScanRoot) {
        guard !root.isDefault else { return }
        let roots = model.scanRoots.filter { $0.path != root.path }
        model.updateScanRoots(roots)
    }
}

/// One-shot callout shown in the Sources section when the auto-detector
/// found no canonical project folders (`~/Developer`, `~/Code`, `~/Projects`,
/// …). Surfaces both *why* the sidebar looks sparse and *what* to do about
/// it, so users with non-English path names (e.g. `~/Documents/Projetos`,
/// `~/Documents/Projets`, `~/Documents/Projekte`) aren't left wondering.
///
/// Disappears automatically once the user adds a folder — the only sensible
/// dismissal action is exactly the one we want them to take, so there's no
/// "Don't show again" toggle.
private struct EmptyScanRootsCallout: View {
    let addScanRoot: () -> Void
    let dismiss: () -> Void

    // Visual constants. Card uses a uniform corner radius, derived so the
    // top-left arc shares a center with the icon's circular wrapper:
    //   cardCornerRadius = cardPadding + iconWrapperSize / 2
    // `padding` is the tuning lever — increase for a softer, more pillowy
    // card; decrease for a tighter, snappier one. Concentricity holds at
    // any value because the icon and corner share the same offset from the
    // card's top-left edge.
    //
    // (`ConcentricRectangle` can't auto-derive a corner from a sibling
    // `Circle` — its derivation only flows container→corner — so the math
    // is ours. Per-corner control exists but doesn't earn its keep here:
    // mixing radii reads as visually unbalanced in this small a card.)
    private static let iconWrapperSize: CGFloat = 24
    private static let cardPadding: CGFloat = 12
    private static var cardCornerRadius: CGFloat {
        cardPadding + iconWrapperSize / 2
    }

    var body: some View {
        ZStack {
            // Card background. Uniform `ConcentricRectangle()` reads the
            // parent's `.containerShape(...)` and inherits its radius — the
            // radius itself is computed from `cardPadding + iconRadius` (see
            // top of struct), so the icon's circle and the card's corners
            // share a common arc center.
            //
            // Fill recipe matches `RegenEffortSegments` above: a soft
            // secondary-tint fill + hairline secondary-tint stroke. Reads
            // more solidly than `.regularMaterial` in a sidebar context
            // where there's very little behind the card to blur.
            ConcentricRectangle()
                .fill(Color.secondary.opacity(0.10))
            // `.stroke` (not `.strokeBorder`) because ConcentricRectangle
            // doesn't expose the InsettableShape API directly. At a 0.5pt
            // line width the half-pixel straddle is invisible.
            ConcentricRectangle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)

            VStack(alignment: .leading, spacing: 8) {
                // Title block: icon-in-circle on the left + title/subtitle
                // VStack on the right. Mirrors the anatomy of Apple's
                // "Shared Library Suggestion" Photos prompt — the circular
                // icon container reads as a small avatar, with the
                // text column hung off its right side. `alignment: .top`
                // anchors the icon's top to the title's top so the icon
                // doesn't drift downward as the subtitle wraps.
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "folder.badge.questionmark")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: Self.iconWrapperSize, height: Self.iconWrapperSize)
                        .background(Circle().fill(Color.secondary.opacity(0.18)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add code projects folder?")
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("We can scan each project for reclaimable space.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                // Concentric-pill button row: primary CTA + secondary
                // dismiss, matching the Review/Not Now pairing in Apple's
                // Photos prompts. `.buttonBorderShape(.capsule)` forces
                // true rounded ends regardless of the system's default
                // bordered shape on the current OS version. With the
                // smaller icon (and therefore smaller card corner radius),
                // the standard `cardPadding` is already enough inset for
                // the button pills to feel tucked into the bottom corners
                // — no extra trailing/bottom padding needed.
                HStack(spacing: 6) {
                    Spacer(minLength: 0)
                    Button("Add folder") { addScanRoot() }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                    Button("Not now") { dismiss() }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                }
                .padding(.top, 2)
            }
            .padding(Self.cardPadding)
            // Force the panel to take the row's full width so the body
            // text has room to wrap. Without `maxWidth: .infinity` the
            // VStack hugs its tightest child, squeezing Text into a single
            // line that truncates.
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Declare the container shape for the ConcentricRectangle background
        // above. Radius is derived (see top of the struct) so that the card's
        // top-left arc shares a center with the icon's circular wrapper.
        .containerShape(.rect(cornerRadius: Self.cardCornerRadius))
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
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
                .fill(
                    isOn
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
        .help(
            "Root-owned paths (e.g. /nix/store, /opt/local/var/macports). Cleaning these requires your password."
        )
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
        .help(
            "User-scoped package caches and build artifacts at known paths (Xcode DerivedData, ~/.cargo, ~/.npm, Homebrew, etc.)."
        )
    }
}

/// Row for per-bundle Darwin-cache subdirs (one finding per app's
/// `com.apple.metal/` etc.). Off by default — usually a long tail of
/// small caches that would dominate the default scan.
private struct PerAppCachesRow: View {
    @Bindable var model: AppModel

    var body: some View {
        HStack(spacing: 6) {
            Toggle(isOn: $model.perAppCachesEnabled) { EmptyView() }
                .toggleStyle(.checkbox)
                .labelsHidden()

            Image(systemName: "app.badge")
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .center)
            Text("Apps")
                .font(.caption)
                .foregroundStyle(model.perAppCachesEnabled ? .primary : .secondary)
            Spacer()
        }
        .help(
            "Per-bundle shader caches under $DARWIN_USER_CACHE_DIR/<bundle-id>/. Off by default — typically hundreds of mostly-tiny rows."
        )
    }
}
