import SwiftUI

/// A 28pt rounded-square tile showing a brand logo (or SF Symbol fallback).
/// Optional runtime overlay in the bottom-trailing corner for node_modules
/// cases where the logo is already the runtime mark — we skip the overlay then.
struct IconTile: View {
    let finding: Finding
    let rule: Rule
    var size: CGFloat = 28

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let asset = finding.resolvedIconAsset(rule: rule)
        let tint = finding.resolvedTint(rule: rule)

        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(tint.opacity(scheme == .dark ? 0.28 : 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                        .strokeBorder(tint.opacity(0.40), lineWidth: 0.5)
                )

            if let asset, let img = LogoLoader.image(named: asset) {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.72, height: size * 0.72)
            } else if let sf = rule.sfSymbol {
                Image(systemName: sf)
                    .font(.system(size: size * 0.56, weight: .semibold))
                    .foregroundStyle(tint)
            } else {
                Image(systemName: finding.ecosystem.glyph)
                    .font(.system(size: size * 0.52, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("\(finding.ecosystem.displayName)\(finding.runtime.map { ", \($0.displayName)" } ?? "")")
    }
}
