import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

/// A language / runtime / build-system bucket. Drives the IconTile color + glyph.
enum Ecosystem: String, Sendable, CaseIterable, Hashable, Identifiable, Codable {
    // Core language/runtime buckets
    case node, rust, python, apple, go, java, cpp
    case dotnet, ruby, php, haskell, dart, elixir
    case otherLangs         // Zig / D / Crystal / Nim / OCaml / Julia / R / Erlang-only

    // Tool buckets
    case bazel
    case packageManager     // Homebrew + MacPorts + Nix (user-owned parts)
    case ssg                // Static site generators — cross-language by implementation
                            // (Hugo=Go, Zola=Rust, Jekyll=Ruby, Gatsby=JS…) but users
                            // think about them as SSGs first.
    case ide                // Editors & IDE caches
    case ai                 // LLM runtimes + ML caches + image-gen
    case aiCodingAgent      // Claude Code / Codex CLI / Aider / Continue / Cline / etc.
    case browserAutomation  // Playwright / Cypress / Puppeteer — bundled browser binaries
    case vm                 // Docker / OrbStack / Tart / Lima / Vagrant / VirtualBox / ...
    case devops             // Cloud + IaC + k8s CLIs — Pulumi / Terraform / Helm /
                            // kubectl / gcloud / gh / act / …
    case gameDev            // Game engines + GPU shader caches — Unity / Unreal /
                            // Godot + the global Metal AIR cache
    case database           // PostgreSQL / MySQL / MariaDB / Redis / MongoDB —
                            // service data dirs (irreplaceable user data) and a
                            // few caches around DB GUIs.

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .node: "JavaScript / TypeScript"
        case .rust: "Rust"
        case .python: "Python"
        case .apple: "Swift / Objective-C"
        case .go: "Go"
        case .java: "JVM"
        case .cpp: "C / C++"
        case .dotnet: ".NET"
        case .ruby: "Ruby"
        case .php: "PHP"
        case .haskell: "Haskell"
        case .dart: "Dart / Flutter"
        case .elixir: "Elixir / Erlang"
        case .otherLangs: "Other Languages"
        case .bazel: "Bazel"
        case .packageManager: "Homebrew / MacPorts / Nix"
        case .ssg: "Static Site Generators"
        case .ide: "Editors & IDEs"
        case .ai: "Local AI & ML"
        case .aiCodingAgent: "AI Coding Agents"
        case .browserAutomation: "Browser Automation"
        case .vm: "VMs & Containers"
        case .devops: "DevOps & Cloud CLIs"
        case .gameDev: "Game Dev & Shaders"
        case .database: "Databases"
        }
    }

    /// Brand-accurate tint for the IconTile and filter checkbox.
    var tint: Color {
        switch self {
        case .node: Color(red: 0xF7/255, green: 0xDF/255, blue: 0x1E/255)
        case .rust: Color(red: 0xCE/255, green: 0x41/255, blue: 0x2B/255)
        case .python: Color(red: 0x37/255, green: 0x76/255, blue: 0xAB/255)
        case .apple: Color(red: 0xF0/255, green: 0x51/255, blue: 0x38/255)
        case .go: Color(red: 0x00/255, green: 0xAD/255, blue: 0xD8/255)
        case .java: Color(red: 0xF8/255, green: 0x98/255, blue: 0x20/255)
        case .cpp: Color(red: 0x00/255, green: 0x59/255, blue: 0x9C/255)
        case .dotnet: Color(red: 0x51/255, green: 0x2B/255, blue: 0xD4/255)
        case .ruby: Color(red: 0xCC/255, green: 0x34/255, blue: 0x2D/255)
        case .php: Color(red: 0x77/255, green: 0x7B/255, blue: 0xB4/255)
        case .haskell: Color(red: 0x5D/255, green: 0x4F/255, blue: 0x85/255)
        case .dart: Color(red: 0x01/255, green: 0x75/255, blue: 0xC2/255)
        case .elixir: Color(red: 0x4B/255, green: 0x27/255, blue: 0x5F/255)
        case .otherLangs: Color(red: 0x6B/255, green: 0x72/255, blue: 0x80/255)  // slate
        case .bazel: Color(red: 0x43/255, green: 0xA0/255, blue: 0x47/255)
        case .packageManager: Color(red: 0xFB/255, green: 0xB0/255, blue: 0x40/255) // Homebrew gold
        case .ssg: Color(red: 0xE9/255, green: 0x4B/255, blue: 0xA6/255)  // publishing magenta
        case .ide: Color(red: 0x4C/255, green: 0x5A/255, blue: 0x76/255)
        case .ai: Color(red: 0x63/255, green: 0x63/255, blue: 0xF1/255)  // indigo-500
        case .aiCodingAgent: Color(red: 0xF4/255, green: 0x3F/255, blue: 0x5E/255)  // rose-500
        case .browserAutomation: Color(red: 0x14/255, green: 0xB8/255, blue: 0xA6/255)  // teal-500
        case .vm: Color(red: 0x24/255, green: 0x96/255, blue: 0xED/255)
        case .devops: Color(red: 0x06/255, green: 0xB6/255, blue: 0xD4/255)  // cyan-500
        case .gameDev: Color(red: 0x8B/255, green: 0x5C/255, blue: 0xF6/255)  // violet-500
        case .database: Color(red: 0x10/255, green: 0xB9/255, blue: 0x81/255) // emerald-500
        }
    }

    /// Default glyph. Individual rules may override.
    var glyph: String {
        switch self {
        case .node: "shippingbox.fill"
        case .rust: "flame.fill"
        case .python: "leaf.fill"
        case .apple: "swift"
        case .go: "bolt.horizontal.fill"
        case .java: "cup.and.saucer.fill"
        case .cpp: "c.circle.fill"
        case .dotnet: "number.square.fill"
        case .ruby: "diamond.fill"
        case .php: "globe"
        case .haskell: "function"
        case .dart: "arrow.right.circle.fill"
        case .elixir: "drop.fill"
        case .otherLangs: "curlybraces"
        case .bazel: "cube.transparent.fill"
        case .packageManager: "mug.fill"
        case .ssg: "doc.richtext"
        case .ide: "text.alignleft"
        case .ai: "sparkles"
        case .aiCodingAgent: "bubble.and.pencil"
        case .browserAutomation: "cursorarrow.click.2"
        case .vm: "cube.box.fill"
        case .devops: "cloud.fill"
        case .gameDev: "gamecontroller.fill"
        case .database: "cylinder.fill"
        }
    }

    /// Default bundled SVG asset name (without extension).
    var defaultAsset: String {
        switch self {
        case .node: "nodejs-icon"
        case .rust: "rust"
        case .python: "python"
        case .apple: "swift"
        case .go: "go"
        case .java: "java"
        case .cpp: "c-plusplus"
        case .dotnet: "dotnet"
        case .ruby: "ruby"
        case .php: "php"
        case .haskell: "haskell"
        case .dart: "flutter"
        case .elixir: "elixir"
        case .otherLangs: ""                // falls back to glyph
        case .bazel: "bazel"
        case .packageManager: "homebrew"    // default; per-rule override for macports/nix
        case .ssg: ""                       // per-rule override (hugo/gatsby/zola/…)
        case .ide: ""
        case .ai: ""
        case .aiCodingAgent: ""
        case .browserAutomation: ""
        case .vm: "docker"
        case .devops: ""                    // per-rule override
        case .gameDev: ""                   // per-rule override (unity / unrealengine / godot)
        case .database: ""                  // per-rule override (postgres / mysql / mariadb / …)
        }
    }
}

/// A well-known runtime. Drives the primary IconTile asset for `node_modules`
/// (replacing the generic Node mark) and, elsewhere, an overlay badge.
enum Runtime: String, Sendable, Hashable, Codable {
    case npm, pnpm, yarn, bun, deno
    case cargo, uv, poetry

    var displayName: String {
        switch self {
        case .npm: "npm"; case .pnpm: "pnpm"; case .yarn: "yarn"; case .bun: "bun"; case .deno: "deno"
        case .cargo: "cargo"; case .uv: "uv"; case .poetry: "poetry"
        }
    }

    var iconAsset: String? {
        switch self {
        case .npm: "npm-icon"
        case .pnpm: "pnpm"
        case .yarn: "yarn"
        case .bun: "bun"
        case .deno: "deno"
        case .cargo: "rust"
        case .uv: "uv"
        case .poetry: "poetry"
        }
    }

    var tint: SwiftUI.Color? {
        switch self {
        case .npm: SwiftUI.Color(red: 0.80, green: 0.16, blue: 0.18)
        case .pnpm: SwiftUI.Color(red: 0.97, green: 0.61, blue: 0.18)
        case .yarn: SwiftUI.Color(red: 0.18, green: 0.44, blue: 0.70)
        case .bun: SwiftUI.Color(red: 0.98, green: 0.87, blue: 0.70)
        case .deno: SwiftUI.Color(red: 0.00, green: 0.00, blue: 0.00)
        default: nil
        }
    }
}

// MARK: - Transferable

/// Lets `Ecosystem` travel through SwiftUI's drag-and-drop pipeline so the
/// filter-chip row can be user-reordered via `.draggable(...)` /
/// `.dropDestination(for: Ecosystem.self)`. Uses the raw `String` value as
/// the wire format — trivially encodable, no custom UTType needed.
extension Ecosystem: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plainText)
    }
}
