import Foundation
import SwiftUI

/// The embedded rule catalog. One file on purpose — the catalog is the product's
/// core value, and collecting it in one place makes audits and pull-requests
/// trivial. ~40 rules across 12 ecosystems covering the GB-class offenders.
enum RuleCatalog {

    static let rules: [Rule] = {
        var out: [Rule] = []
        out.append(contentsOf: node)
        out.append(contentsOf: apple)
        out.append(contentsOf: rust)
        out.append(contentsOf: python)
        out.append(contentsOf: go)
        out.append(contentsOf: jvm)
        out.append(contentsOf: cpp)
        out.append(contentsOf: dotnet)
        out.append(contentsOf: ruby)
        out.append(contentsOf: php)
        out.append(contentsOf: haskell)
        out.append(contentsOf: dartFlutter)
        out.append(contentsOf: elixirErlang)
        out.append(contentsOf: otherLangs)
        out.append(contentsOf: ssg)
        out.append(contentsOf: ai)
        out.append(contentsOf: aiCodingAgents)
        out.append(contentsOf: vm)
        out.append(contentsOf: ide)
        out.append(contentsOf: bazel)
        out.append(contentsOf: packageManagers)
        out.append(contentsOf: devops)
        out.append(contentsOf: gameDev)
        return out
    }()

    static func rule(id: String) -> Rule? { rules.first { $0.id == id } }

    // MARK: - Node family

    /// Lockfiles that guarantee reproducible regeneration. Required for every
    /// Node rule — without a lockfile, version drift could change the installed
    /// deps and break the project. This doubles as the runtime signal.
    static let nodeLockfiles = [
        "bun.lockb", "bun.lock",
        "pnpm-lock.yaml",
        "yarn.lock",
        "package-lock.json",
    ]

    private static let node: [Rule] = [
        Rule(
            id: "node.modules", displayName: "node_modules/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: "node_modules", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Project-local installed dependency tree.",
            iconAsset: nil,   // runtime-detected; resolved at Finding creation
            languageKey: "javascript",
            item: ItemInfo(
                description: "`node_modules/` holds the fully materialised dependency tree that npm, pnpm, yarn, or bun installs from the registry. Typical projects contain hundreds of nested packages; on active machines the cumulative size across projects is often several gigabytes.",
                safetyNote: "A lockfile is present on the project tree, so `npm install` (or the matching package manager) will restore the exact same dependency tree.",
                regenCommand: "npm install   # or pnpm install / yarn / bun install",
                links: [
                    InfoLink(title: "npm — Folders", url: "https://docs.npmjs.com/cli/v11/configuring-npm/folders", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.modules-unlocked",
            displayName: "node_modules/ (no lockfile)",
            ecosystem: .node, scope: .projectLocal,
            // A node_modules next to a package.json but NO lockfile — reinstall
            // won't be deterministic, so we classify this as extreme.
            matcher: .marker(directoryName: "node_modules",
                             requiredMarkers: ["package.json"],
                             forbiddenMarkers: nodeLockfiles),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "node_modules with no lockfile next to it.",
            iconAsset: nil,
            languageKey: "javascript",
            item: ItemInfo(
                description: "A `node_modules/` directory whose project has a `package.json` but no lockfile (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, or `bun.lockb`). Without a lockfile, reinstalling will resolve dependency versions against the current registry state — you may get different transitive versions than you had installed.",
                safetyNote: "Reinstall via `npm install` (or pnpm/yarn/bun) will produce a *similar* tree but not necessarily the same one — new patch/minor versions may be pulled in. Consider generating a lockfile before deleting.",
                regenCommand: "npm install   # or pnpm install / yarn / bun install (may drift)",
                links: [
                    InfoLink(title: "npm — package-lock.json", url: "https://docs.npmjs.com/cli/v11/configuring-npm/package-lock-json", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.next", displayName: ".next/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: ".next", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Next.js build cache.",
            iconAsset: "nextjs-icon",
            brandTint: Color(red: 0x10/255, green: 0x10/255, blue: 0x10/255), // near-black
            languageKey: "javascript",
            toolKey: "nextjs",
            item: ItemInfo(
                description: "The `.next/` directory is Next.js's build output folder, containing compiled server and client bundles, static assets, and incremental build cache. It is created by `next build` and also populated during `next dev` to cache page and component compilation.",
                safetyNote: "Fully reproducible by running `next build`; the dev server recreates it automatically on startup.",
                regenCommand: "next build",
                links: [
                    InfoLink(title: "next.config.js — distDir", url: "https://nextjs.org/docs/app/api-reference/config/next-config-js/distDir", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.nuxt", displayName: ".nuxt/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: ".nuxt", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Nuxt build cache.", iconAsset: "nuxt-icon",
            languageKey: "javascript",
            toolKey: "nuxt",
            item: ItemInfo(
                description: "The `.nuxt/` directory is generated by Nuxt during `nuxt dev` and `nuxt build`. It contains the compiled Vue application, generated routes, server middleware, and TypeScript type definitions derived from your project structure.",
                safetyNote: "Auto-generated on every dev server start and build; safe to delete at any time.",
                regenCommand: "nuxt build",
                links: [
                    InfoLink(title: "Nuxt — .nuxt/ directory", url: "https://nuxt.com/docs/guide/directory-structure/nuxt", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.svelte", displayName: ".svelte-kit/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: ".svelte-kit", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "SvelteKit build cache.", iconAsset: "svelte-icon",
            languageKey: "javascript",
            toolKey: "sveltekit",
            item: ItemInfo(
                description: "The `.svelte-kit/` directory is SvelteKit's internal output directory, written during `vite dev` and `vite build`. It contains generated route manifests, TypeScript configuration, adapter output, and compiled server/client code.",
                safetyNote: "Regenerated automatically on every dev server start and build run.",
                regenCommand: "vite build",
                links: [
                    InfoLink(title: "SvelteKit — configuration (outDir)", url: "https://svelte.dev/docs/kit/configuration", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.turbo", displayName: ".turbo/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: ".turbo", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Turborepo cache.", iconAsset: "turborepo",
            languageKey: "javascript",
            toolKey: "turborepo",
            item: ItemInfo(
                description: "The `.turbo/` directory stores Turborepo's local task cache, including hashed inputs and outputs for each pipeline task. When inputs haven't changed, Turborepo replays the cached output instead of re-running the task.",
                safetyNote: "Deleting it only causes tasks to re-run without cache hits; no source files are affected.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Turborepo — caching", url: "https://turborepo.dev/repo/docs/crafting-your-repository/caching", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.parcel", displayName: ".parcel-cache/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: ".parcel-cache", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Parcel bundler cache.", iconAsset: "parcel",
            languageKey: "javascript",
            toolKey: "parcel",
            item: ItemInfo(
                description: "Parcel's `.parcel-cache/` directory stores the results of every file transformation and bundle step performed during previous builds. It is used to speed up subsequent builds by skipping unchanged work.",
                safetyNote: "Deleting it causes a full cold rebuild on the next `parcel` invocation; no source files are modified.",
                regenCommand: "parcel build",
                links: [
                    InfoLink(title: "Parcel — development (caching)", url: "https://parceljs.org/features/development/#caching", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.vite", displayName: ".vite/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: ".vite", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Vite dev server cache.", iconAsset: "vite",
            languageKey: "javascript",
            toolKey: "vite",
            item: ItemInfo(
                description: "Vite stores pre-bundled dependencies in `node_modules/.vite/` (and a legacy `.vite/` location) to accelerate dev server startup. CommonJS and UMD packages are converted to ESM and bundled into single files so the browser makes fewer requests.",
                safetyNote: "Regenerated automatically on the next `vite dev` startup or when lockfile/config changes are detected.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Vite — dependency pre-bundling", url: "https://vite.dev/guide/dep-pre-bundling", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.astro", displayName: ".astro/",
            ecosystem: .node, scope: .projectLocal,
            matcher: .marker(directoryName: ".astro", requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Astro build cache.", iconAsset: "astro-icon",
            languageKey: "javascript",
            toolKey: "astro",
            item: ItemInfo(
                description: "Astro generates a `.astro/` directory containing auto-generated TypeScript type definitions (referenced in `tsconfig.json` as `.astro/types.d.ts`) and internal build metadata. The build cache itself defaults to `node_modules/.astro/`.",
                safetyNote: "Regenerated automatically when the Astro dev server starts or a build runs.",
                regenCommand: "astro build",
                links: [
                    InfoLink(title: "Astro — TypeScript", url: "https://docs.astro.build/en/guides/typescript/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.npm-global", displayName: "npm cache",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".npm"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Global npm content-addressable package cache.",
            iconAsset: "npm-icon",
            brandTint: Color(red: 0xCB/255, green: 0x38/255, blue: 0x37/255),  // npm red
            languageKey: "javascript",
            toolKey: "npm",
            item: ItemInfo(
                description: "npm stores all downloaded package tarballs and metadata in `~/.npm/_cacache`, a content-addressable store keyed by package integrity hash. It is shared across all projects on the machine and speeds up installs by skipping network requests for packages already present.",
                safetyNote: "npm re-populates the cache automatically on the next `npm install`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "npm — cache command", url: "https://docs.npmjs.com/cli/v11/commands/npm-cache", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.yarn-global", displayName: "Yarn cache",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/Yarn"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Global Yarn package cache.",
            iconAsset: "yarn",
            brandTint: Color(red: 0x2C/255, green: 0x8E/255, blue: 0xBB/255),  // yarn blue
            languageKey: "javascript",
            toolKey: "yarn",
            item: ItemInfo(
                description: "Yarn stores compressed package archives in `~/Library/Caches/Yarn` (classic) or `~/.yarn/berry/cache` (Berry/v2+). These cached tarballs are reused across all projects so that re-installing a previously downloaded package requires no network request.",
                safetyNote: "Deleting the cache is safe — Yarn re-downloads and revalidates packages from the registry on the next install.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Yarn — cache clean command", url: "https://yarnpkg.com/cli/cache/clean", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.pnpm-store", displayName: "pnpm content-addressed store",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/pnpm/store"),
            action: .cleanCommand(.pnpmStorePrune),
            tier: .medium, aggregation: .none,
            notes: "pnpm content-addressed package store.",
            iconAsset: "pnpm",
            brandTint: Color(red: 0xF6/255, green: 0x92/255, blue: 0x20/255),  // pnpm orange
            languageKey: "javascript",
            toolKey: "pnpm",
            item: ItemInfo(
                description: "pnpm keeps a single copy of every package version under `~/Library/pnpm/store` and hardlinks each project's `node_modules` entries into it, so identical packages are never duplicated on disk. Deleting the store directory directly would orphan every linked project; `pnpm store prune` removes only versions that no live project currently references.",
                safetyNote: "Always cleaned via `pnpm store prune` — direct deletion will break linked projects.",
                regenCommand: "pnpm store prune",
                links: [
                    InfoLink(title: "pnpm — store prune", url: "https://pnpm.io/cli/store#prune", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.bun-cache", displayName: "Bun install cache",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".bun/install/cache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Global Bun package cache.",
            iconAsset: "bun",
            brandTint: Color(red: 0x4E/255, green: 0x31/255, blue: 0x27/255),
            languageKey: "javascript",
            toolKey: "bun",
            item: ItemInfo(
                description: "Bun stores all downloaded packages in `~/.bun/install/cache`, organised as `<name>@<version>` subdirectories. On Linux and Windows, Bun uses hardlinks from the cache into `node_modules`; on macOS it uses `clonefile`, so package data is shared rather than duplicated.",
                safetyNote: "Deleting the cache is safe — Bun re-downloads and re-extracts packages on the next `bun install`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Bun — global cache", url: "https://bun.sh/docs/install/cache", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.nvm-versions", displayName: "nvm Node version",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".nvm/versions/node"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "nvm-managed Node.js runtime installation.",
            iconAsset: "nodejs-icon",
            languageKey: "javascript",
            toolKey: "nvm",
            item: ItemInfo(
                description: "nvm (Node Version Manager) stores each installed Node.js version as a self-contained directory under `~/.nvm/versions/node/`. Each entry contains the Node binary, the bundled npm, and the standard library for that release.",
                safetyNote: "Removing a version only affects projects pinned to it; reinstall at any time with `nvm install <version>`.",
                regenCommand: "nvm install <version>",
                links: [
                    InfoLink(title: "nvm — GitHub", url: "https://github.com/nvm-sh/nvm", kind: .official),
                ]
            )
        ),
        Rule(
            id: "node.fnm-versions", displayName: "fnm Node version",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".fnm/node-versions"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "fnm-managed Node.js runtime installation.",
            iconAsset: "nodejs-icon",
            languageKey: "javascript",
            toolKey: "fnm",
            item: ItemInfo(
                description: "fnm (Fast Node Manager) is a Rust-based Node.js version manager. It stores each installed Node.js version as a self-contained directory under `~/.fnm/node-versions/`, containing the complete Node runtime for that release.",
                safetyNote: "Removing a version only affects projects pinned to it; reinstall with `fnm install <version>`.",
                regenCommand: "fnm install <version>",
                links: [
                    InfoLink(title: "fnm — GitHub", url: "https://github.com/Schniz/fnm", kind: .official),
                ]
            )
        ),
        Rule(
            id: "node.nvm-fish-versions", displayName: "nvm.fish Node version",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".local/share/nvm"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "nvm.fish-managed Node.js runtime installation.",
            iconAsset: "nodejs-icon",
            languageKey: "javascript",
            toolKey: "nvm",
            item: ItemInfo(
                description: "nvm.fish (jorgebucaran/nvm) is a Node.js version manager for the Fish shell. It stores each installed Node.js version under `~/.local/share/nvm` (or a custom `$nvm_data` path), with one self-contained directory per release.",
                safetyNote: "Removing a version only affects Fish shell sessions pinned to it; reinstall with `nvm install <version>`.",
                regenCommand: "nvm install <version>",
                links: [
                    InfoLink(title: "nvm.fish — GitHub", url: "https://github.com/jorgebucaran/nvm.fish", kind: .official),
                ]
            )
        ),
        Rule(
            id: "node.asdf-node-versions", displayName: "asdf Node version",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".asdf/installs/nodejs"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "asdf-managed Node.js runtime installation.",
            iconAsset: "nodejs-icon",
            languageKey: "javascript",
            toolKey: "asdf",
            item: ItemInfo(
                description: "asdf is a universal version manager that handles multiple language runtimes through a plugin system. Node.js versions installed via the `asdf-nodejs` plugin are stored under `~/.asdf/installs/nodejs/`, one self-contained directory per version.",
                safetyNote: "Removing a version only affects projects that declare it in `.tool-versions`; reinstall with `asdf install nodejs <version>`.",
                regenCommand: "asdf install nodejs <version>",
                links: [
                    InfoLink(title: "asdf — managing versions", url: "https://asdf-vm.com/manage/versions.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "node.n-versions", displayName: "n Node version",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "n/versions/node"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "n-managed Node.js runtime installation.",
            iconAsset: "nodejs-icon",
            languageKey: "javascript",
            toolKey: "n",
            item: ItemInfo(
                description: "`n` (tj/n) is a Node.js version manager written as a shell script. Downloaded Node.js versions are cached under `~/n/versions/node/` (or `$N_PREFIX/n/versions/node/`), one directory per release, so switching between them requires no re-downloading.",
                safetyNote: "Removing a cached version forces a fresh download next time that version is activated with `n <version>`.",
                regenCommand: "n <version>",
                links: [
                    InfoLink(title: "n — GitHub", url: "https://github.com/tj/n", kind: .official),
                ]
            )
        ),
        Rule(
            id: "node.deno-cache", displayName: "Deno Cache",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/deno"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Deno's user cache: remote modules, npm packages, compile cache.",
            iconAsset: "deno",
            languageKey: "javascript",
            toolKey: "deno",
            item: ItemInfo(
                description: "`~/Library/Caches/deno` is Deno's combined cache: `deps/` (downloaded ESM modules from URL imports), `gen/` (TypeScript→JavaScript compile cache), `npm/` (npm-compatible package store), and Deno KV files. Override path via `$DENO_DIR`.",
                safetyNote: "Modules are re-fetched on the next `deno cache <entry>` or first run of any script that imports them.",
                regenCommand: "deno cache <entry>",
                links: [
                    InfoLink(title: "Deno — DENO_DIR", url: "https://docs.deno.com/runtime/manual/tools/cache/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "expo.cache", displayName: "Expo CLI Cache",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".expo"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Expo CLI versions / schema / template / native-modules cache.",
            iconAsset: "expo",
            brandTint: Color(red: 0x00/255, green: 0x00/255, blue: 0x00/255),  // Expo black
            languageKey: "javascript",
            toolKey: "expo",
            item: ItemInfo(
                description: "`~/.expo/` collects Expo CLI's persistent state: `versions-cache/`, `schema-cache/`, `native-modules-cache/`, `ios-simulator-app-cache/`, `template-cache/`. Used by both the classic Expo CLI and EAS CLI.",
                safetyNote: "Regenerated by the next Expo CLI invocation.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Expo CLI", url: "https://docs.expo.dev/more/expo-cli/", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Apple platform (Swift / Objective-C / Xcode / CocoaPods / Simulator)

    /// Canonical Apple-family brand tints.
    private static let xcodeBlue = Color(red: 0x1D/255, green: 0x9B/255, blue: 0xF0/255)
    private static let cocoapodsRed = Color(red: 0xEE/255, green: 0x33/255, blue: 0x22/255)

    private static let apple: [Rule] = [
        Rule(
            id: "xcode.deriveddata", displayName: "Xcode DerivedData",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/Xcode/DerivedData"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-project build intermediates.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Developer/Xcode/DerivedData` holds per-project build intermediates: compiled object files, index data, Swift module caches, and linked binaries. Xcode creates one UUID-named subdirectory per project; each can reach several gigabytes.",
                safetyNote: "Xcode regenerates `DerivedData` on the next build; no source code lives here.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Xcode — build system", url: "https://developer.apple.com/documentation/xcode/build-system", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.ios-devicesupport", displayName: "iOS DeviceSupport",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/Xcode/iOS DeviceSupport"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Device symbol files; re-downloaded when device reconnects.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Developer/Xcode/iOS DeviceSupport` stores symbol files and debugging support data fetched from a physical device the first time it is connected. Each iOS version occupies its own subdirectory, typically several gigabytes.",
                safetyNote: "Xcode re-downloads the files next time a device running that iOS version is connected.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Xcode — running your app on a device", url: "https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.archives", displayName: "Xcode Archives",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/Xcode/Archives"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "App Store submission archives. Not regenerable from source.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Developer/Xcode/Archives` stores `.xcarchive` bundles produced by **Product > Archive**. Each archive contains the compiled app binary, dSYM symbol files, and metadata required for App Store submission and crash log symbolication.",
                safetyNote: "Archives cannot be regenerated from source — delete only those for already-shipped versions you no longer need to symbolicate.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "swift.build", displayName: ".build/",
            ecosystem: .apple, scope: .projectLocal,
            matcher: .marker(directoryName: ".build", requiredMarkers: ["Package.swift"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Swift Package Manager build directory.",
            iconAsset: "swift",
            // Inherits Swift orange from the ecosystem
            languageKey: "swift",
            toolKey: "swiftpm",
            item: ItemInfo(
                description: "`.build/` is the Swift Package Manager build directory, created alongside `Package.swift`. It contains compiled object files, linked executables, and resolved dependency checkouts under `.build/checkouts/`.",
                safetyNote: "`swift build` recreates the directory; dependency sources are re-fetched from pinned revisions in `Package.resolved`.",
                regenCommand: "swift build",
                links: [
                    InfoLink(title: "Swift Package Manager — swift.org", url: "https://www.swift.org/package-manager/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "cocoapods.pods", displayName: "Pods/",
            ecosystem: .apple, scope: .projectLocal,
            matcher: .marker(directoryName: "Pods", requiredMarkers: ["Podfile"]),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "CocoaPods-managed dependency sources.",
            iconAsset: "cocoapods",
            brandTint: cocoapodsRed,
            languageKey: "swift",
            toolKey: "cocoapods",
            item: ItemInfo(
                description: "`Pods/` contains downloaded source code for every pod declared in `Podfile`, plus generated Xcode projects that your workspace references. Created and managed by `pod install`.",
                safetyNote: "Lockfile-gated — `Podfile.lock` pins every pod version so `pod install` restores an identical tree.",
                regenCommand: "pod install",
                links: [
                    InfoLink(title: "CocoaPods — pod install", url: "https://guides.cocoapods.org/using/pod-install-vs-update.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "cocoapods.carthage", displayName: "Carthage/Build",
            ecosystem: .apple, scope: .projectLocal,
            matcher: .marker(directoryName: "Carthage", requiredMarkers: ["Cartfile", "Cartfile.resolved"]),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Carthage pre-built binary frameworks.",
            iconAsset: "cocoapods",
            brandTint: cocoapodsRed,
            languageKey: "swift",
            toolKey: "carthage",
            item: ItemInfo(
                description: "`Carthage/Build/` holds compiled `.xcframework` or `.framework` bundles produced by Carthage and linked directly into your Xcode project. The lockfile `Cartfile.resolved` pins every framework version.",
                safetyNote: "Lockfile-gated — `carthage bootstrap` rebuilds the exact framework versions from `Cartfile.resolved`.",
                regenCommand: "carthage bootstrap --use-xcframeworks",
                links: []
            )
        ),
        Rule(
            id: "cocoapods.global", displayName: "CocoaPods cache",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/CocoaPods"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Global pod source archive cache.",
            iconAsset: "cocoapods",
            brandTint: cocoapodsRed,
            languageKey: "swift",
            toolKey: "cocoapods",
            item: ItemInfo(
                description: "`~/Library/Caches/CocoaPods` is CocoaPods' global download cache, storing pod source archives and spec files. It avoids re-downloading the same pod version across multiple projects.",
                safetyNote: "CocoaPods re-downloads required archives on the next `pod install`.",
                regenCommand: "pod install",
                links: [
                    InfoLink(title: "CocoaPods — cache", url: "https://guides.cocoapods.org/using/troubleshooting.html#clearing-the-cache", kind: .docs),
                ]
            )
        ),
        // Simulator has no bundled SVG logo (Apple-specific), so we use an
        // SF Symbol glyph tinted Xcode-blue — distinct icon, matched color.
        Rule(
            id: "simulator.unavailable", displayName: "Unavailable simulators",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/CoreSimulator/Devices"),
            action: .cleanCommand(.simctlDeleteUnavailable),
            tier: .low, aggregation: .none,
            notes: "Simulator devices with no matching installed runtime.",
            sfSymbol: "iphone.gen3",
            brandTint: xcodeBlue,
            customSizer: .simctlDeleteUnavailable,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Developer/CoreSimulator/Devices` stores data and state for every iOS, watchOS, tvOS, and visionOS simulator created in Xcode. Simulators whose runtime has been uninstalled remain on disk marked \"unavailable\" and accumulate over time.",
                safetyNote: "`xcrun simctl delete unavailable` removes only orphaned simulators; all active simulators and their data remain untouched.",
                regenCommand: "xcrun simctl delete unavailable",
                links: [
                    InfoLink(title: "simctl — Apple Developer Documentation", url: "https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.simulator-runtimes-unavailable",
            displayName: "Unavailable simulator runtimes",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedAbsolutePath("/Library/Developer/CoreSimulator/Profiles/Runtimes"),
            action: .cleanCommand(.simctlRuntimeDeleteUnavailable),
            tier: .low, aggregation: .none,
            notes: "Simulator OS runtime bundles, 4–10 GB each.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            customSizer: .simctlRuntimeDeleteUnavailable,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`/Library/Developer/CoreSimulator/Profiles/Runtimes` holds simulator runtime bundles installed by Xcode — one per OS version and platform (iOS, watchOS, tvOS, visionOS). Each bundle is 4–10 GB.",
                safetyNote: "`xcrun simctl runtime delete unavailable` removes only runtimes Xcode no longer tracks; active runtimes are left intact.",
                regenCommand: "xcrun simctl runtime delete unavailable",
                links: [
                    InfoLink(title: "simctl — Apple Developer Documentation", url: "https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.kdks",
            displayName: "Kernel Debug Kit",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedAbsolutePathChildren("/Library/Developer/KDKs"),
            action: .shellSudo(.kdkRm), tier: .high, aggregation: .none,
            notes: "Kernel Debug Kits for kext debugging, 2–5 GB each.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "Kernel Debug Kits (KDKs) at `/Library/Developer/KDKs` contain symbols and headers for kernel-extension (kext) and kernel-level debugging. Each KDK targets a specific macOS kernel version and is 2–5 GB.",
                safetyNote: "KDKs for old kernel versions are safe to remove; keep the one matching your current kernel if you need kext debugging.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "simulator.caches", displayName: "Simulator caches",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/CoreSimulator/Caches"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "CoreSimulator pre-warmed disk images.",
            sfSymbol: "iphone.gen3",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Developer/CoreSimulator/Caches` holds transient disk images and runtime assets pre-warmed by CoreSimulator to speed up simulator boot.",
                safetyNote: "CoreSimulator recreates these pre-warmed images on the next simulator launch; no app data or installed simulator runtimes are affected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "xcode.modulecache", displayName: "Module Cache",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/Xcode/DerivedData/ModuleCache.noindex"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cross-project precompiled Clang/Swift modules.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`DerivedData/ModuleCache.noindex` stores precompiled Clang/Swift modules (`.pcm`, `.swiftmodule`) shared across every project's build. Sits next to per-project `DerivedData` folders but lives independently — clearing one project's `DerivedData` doesn't touch this.",
                safetyNote: "Auto-rebuilt by the Xcode build system on next compile of each project; first build after clearing is noticeably slower while the cache repopulates.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Xcode — build system", url: "https://developer.apple.com/documentation/xcode/build-system", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.compilationcache", displayName: "Compilation Cache",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/Xcode/DerivedData/CompilationCache.noindex"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Xcode 16+ explicit-modules cache.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`DerivedData/CompilationCache.noindex` is the explicit-modules / cached-compilation store added in Xcode 16. It accelerates builds by reusing compiled outputs across targets that share the same input fingerprint.",
                safetyNote: "Auto-rebuilt by Xcode; subsequent compiles will be slower until the cache repopulates.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "WWDC23 — Demystify explicitly built modules", url: "https://developer.apple.com/videos/play/wwdc2023/10421/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.symbolcache", displayName: "Symbol Cache",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/Xcode/DerivedData/SymbolCache.noindex"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cached symbol indexes for Xcode debugger/symbolicator.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`DerivedData/SymbolCache.noindex` caches symbol indexes used by Xcode's debugger and symbolicator across projects.",
                safetyNote: "Rebuilt on demand whenever Xcode needs symbols.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "xcode.previews", displayName: "SwiftUI Previews",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Developer/Xcode/UserData/Previews"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cross-project SwiftUI Preview shim build artifacts.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`Xcode/UserData/Previews` holds the per-target shim build products that power SwiftUI's `#Preview` canvas. The cross-project tree accumulates as different SwiftUI projects render previews; per-project preview build products live alongside their `DerivedData`.",
                safetyNote: "Auto-rebuilt on the next preview render in any project. SwiftUI previews simply take an extra moment to come up the first time after clearing.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "SwiftUI Previews — Apple Developer", url: "https://developer.apple.com/documentation/swiftui/previews-in-xcode", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.coresimulator-logs", displayName: "CoreSimulator Logs",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Logs/CoreSimulator"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-device simulator runtime logs.",
            sfSymbol: "iphone.gen3",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Logs/CoreSimulator` contains per-device subdirectories of simulator runtime logs plus a master `CoreSimulator.log`. Heavy during UI test runs and CI-style local invocations.",
                safetyNote: "Recreated on the next simulator boot; logs are diagnostic only and don't affect simulator state.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "xcode.fscacheddata", displayName: "Xcode FS Cache",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/com.apple.dt.Xcode/fsCachedData"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Xcode's generic NSURLCache-style storage.",
            iconAsset: "xcode",
            brandTint: xcodeBlue,
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Caches/com.apple.dt.Xcode/fsCachedData` is Xcode's generic NSURLCache-style storage — Asset Catalog thumbnails, account avatars, remotely-fetched resources, and various small artifacts. The sibling `Cache.db*` SQLite files in the same directory follow the same lifecycle.",
                safetyNote: "Refetched on demand by Xcode.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "swiftpm.user-cache", displayName: "SwiftPM User Cache",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/org.swift.swiftpm"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "User-level SwiftPM cache (manifests, repos, package metadata).",
            iconAsset: "swift",
            // Inherits Swift orange from ecosystem
            languageKey: "swift",
            toolKey: "swiftpm",
            item: ItemInfo(
                description: "`~/Library/Caches/org.swift.swiftpm` holds SwiftPM-the-CLI's user cache: `manifests/`, `repositories/` (cloned dependency repos), `package-collection.db`, and `package-metadata/`. Used by `swift build` and Xcode alike — distinct from the existing `xcode.swiftpm-cache` rule, which targets Xcode's per-IDE SwiftPM directory.",
                safetyNote: "SwiftPM re-clones repositories and refetches metadata on the next package resolve. Pinned revisions in `Package.resolved` ensure deterministic re-fetch.",
                regenCommand: "swift package resolve",
                links: [
                    InfoLink(title: "Swift Package Manager — swift.org", url: "https://www.swift.org/package-manager/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "cocoapods.xcode-cache", displayName: "CocoaPods User Cache",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/CocoaPods"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Pod source archives + extracted sources cached for reuse.",
            iconAsset: "cocoapods",
            brandTint: cocoapodsRed,
            languageKey: "swift",
            toolKey: "cocoapods",
            item: ItemInfo(
                description: "`~/Library/Caches/CocoaPods` is CocoaPods' user-level cache of downloaded pod source archives (`Pods/Cache/`) plus reusable working copies. Distinct from `~/.cocoapods` (master spec repo) and the per-project `Pods/` directory — equivalent to running `pod cache clean --all`.",
                safetyNote: "Re-downloaded from the source repo (often GitHub) on the next `pod install`. Heavy iOS users can see this reach several gigabytes.",
                regenCommand: "pod install",
                links: [
                    InfoLink(title: "pod cache — CocoaPods CLI", url: "https://guides.cocoapods.org/terminal/commands.html#pod_cache", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "apple.diagnostic-reports", displayName: "Diagnostic Reports",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Logs/DiagnosticReports"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "User-process crash reports (.ips files).",
            sfSymbol: "exclamationmark.triangle",
            // No brand tint — system logs, fallback to ecosystem default
            languageKey: "swift",
            item: ItemInfo(
                description: "`~/Library/Logs/DiagnosticReports` collects `.ips` crash reports for user-launched processes. Disproportionately populated by debug builds, fuzzers, and dev tools that crash often during iteration. The system-wide `/Library/Logs/DiagnosticReports/` is owned by root and not touched here.",
                safetyNote: "Generated fresh by `ReportCrash` on the next crash; safe to wipe — these are diagnostic records of past failures, not anything macOS depends on.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Acquiring crash reports — Apple Developer", url: "https://developer.apple.com/documentation/xcode/acquiring-crash-reports-and-diagnostic-logs", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "apple.spindump-user", displayName: "Spin Reports",
            ecosystem: .apple, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Logs/Spin Reports"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Spindump samples from hung user processes.",
            sfSymbol: "tornado",
            languageKey: "swift",
            item: ItemInfo(
                description: "`~/Library/Logs/Spin Reports` stores spindump samples macOS captures when a user process becomes unresponsive. Common with debug GUI app builds that hang under the debugger.",
                safetyNote: "macOS regenerates a fresh report on the next hang. The samples here are diagnostic-only.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "spindump(8) — man page", url: "https://www.unix.com/man-page/osx/8/spindump/", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Rust

    private static let rust: [Rule] = [
        Rule(
            id: "rust.target",
            displayName: "target/",
            ecosystem: .rust, scope: .projectLocal,
            matcher: .marker(
                directoryName: "target",
                requiredMarkers: ["Cargo.toml"],
                forbiddenMarkers: ["pom.xml"]
            ),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cargo build output directory.",
            languageKey: "rust",
            toolKey: "cargo",
            item: ItemInfo(
                description: "`target/` is Cargo's build output directory, created alongside `Cargo.toml`. It holds compiled object files, linked binaries, incremental compilation data, and test artifacts organised by profile (`debug/`, `release/`) and target triple.",
                safetyNote: "`cargo build` recreates `target/` from source; no hand-written code lives here.",
                regenCommand: "cargo build",
                links: [
                    InfoLink(title: "Cargo — build cache", url: "https://doc.rust-lang.org/cargo/reference/build-cache.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "rust.registry-cache",
            displayName: "Cargo registry cache",
            ecosystem: .rust, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cargo/registry/cache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Downloaded crate tarballs from crates.io.",
            languageKey: "rust",
            toolKey: "cargo",
            item: ItemInfo(
                description: "`~/.cargo/registry/cache` stores compressed `.crate` tarballs downloaded from crates.io and other registries. Cargo checks here before hitting the network.",
                safetyNote: "Cargo re-downloads any required `.crate` tarballs from crates.io on the next build.",
                regenCommand: "cargo build",
                links: [
                    InfoLink(title: "Cargo — Cargo home", url: "https://doc.rust-lang.org/cargo/guide/cargo-home.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "rust.registry-src",
            displayName: "Cargo registry src",
            ecosystem: .rust, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cargo/registry/src"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Unpacked crate source trees for rustc.",
            languageKey: "rust",
            toolKey: "cargo",
            item: ItemInfo(
                description: "`~/.cargo/registry/src` holds source trees extracted from `.crate` tarballs in `registry/cache/`. `rustc` reads crate source from this directory during compilation.",
                safetyNote: "Cargo re-extracts from the local tarball cache (or re-downloads if that is also absent) on the next build.",
                regenCommand: "cargo build",
                links: [
                    InfoLink(title: "Cargo — Cargo home", url: "https://doc.rust-lang.org/cargo/guide/cargo-home.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "rust.git-cache",
            displayName: "Cargo git checkouts",
            ecosystem: .rust, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cargo/git"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Bare clones and checkouts of git-sourced crates.",
            languageKey: "rust",
            toolKey: "cargo",
            item: ItemInfo(
                description: "`~/.cargo/git` holds bare clones (`git/db/`) and checked-out working trees (`git/checkouts/`) of crates declared as git dependencies in `Cargo.toml`. Each unique git URL and revision gets its own subdirectory.",
                safetyNote: "Cargo re-clones and re-checks out any required git dependencies on the next build.",
                regenCommand: "cargo build",
                links: [
                    InfoLink(title: "Cargo — Cargo home", url: "https://doc.rust-lang.org/cargo/guide/cargo-home.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "rust.rustup-toolchains", displayName: "rustup toolchain",
            ecosystem: .rust, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".rustup/toolchains"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Installed Rust toolchain. Reinstall with `rustup`.",
            languageKey: "rust",
            toolKey: "rustup",
            item: ItemInfo(
                description: "`~/.rustup/toolchains` stores each installed Rust toolchain (`stable`, `beta`, `nightly`, version-pinned) as a self-contained directory containing `rustc`, `cargo`, the standard library, and other components. Each toolchain can be several hundred megabytes.",
                safetyNote: "Removing a toolchain only affects projects that pin to it via `rust-toolchain.toml`.",
                regenCommand: "rustup toolchain install stable",
                links: [
                    InfoLink(title: "rustup — toolchains", url: "https://rust-lang.github.io/rustup/concepts/toolchains.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "rust.sccache", displayName: "sccache",
            ecosystem: .rust, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/Mozilla.sccache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Shared compiler cache for Rust / C / C++ / CUDA.",
            iconAsset: "rust",  // No standalone sccache logo — reuses parent language
            languageKey: "rust",
            toolKey: "sccache",
            item: ItemInfo(
                description: "`~/Library/Caches/Mozilla.sccache` is sccache's local on-disk cache of hashed compile artifacts. Despite the Rust association, sccache works for C, C++, and CUDA too. Capped by `SCCACHE_CACHE_SIZE` (default 10 GB).",
                safetyNote: "Repopulated on the next compile; only a perf hit while the cache rebuilds.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "sccache — local cache", url: "https://github.com/mozilla/sccache/blob/main/docs/Local.md", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Python

    private static let python: [Rule] = [
        Rule(
            id: "py.venv",
            displayName: ".venv/",
            ecosystem: .python, scope: .projectLocal,
            matcher: .marker(
                directoryName: ".venv",
                requiredMarkers: ["pyproject.toml", "setup.py", "requirements.txt", "Pipfile"]
            ),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Project-local Python virtual environment.",
            languageKey: "python",
            item: ItemInfo(
                description: "`.venv/` is a project-local Python virtual environment created by `python -m venv .venv`, `uv venv`, or `poetry install`. It holds an isolated interpreter, pip, and all installed packages for the project.",
                safetyNote: "Reproducible from `requirements.txt`, `Pipfile`, or `pyproject.toml`.",
                regenCommand: "python -m venv .venv && pip install -r requirements.txt",
                links: [
                    InfoLink(title: "venv — Python docs", url: "https://docs.python.org/3/library/venv.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.venv-plain",
            displayName: "venv/",
            ecosystem: .python, scope: .projectLocal,
            matcher: .marker(
                directoryName: "venv",
                requiredMarkers: ["pyproject.toml", "setup.py", "requirements.txt", "Pipfile"]
            ),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Project-local Python virtual environment.",
            languageKey: "python",
            item: ItemInfo(
                description: "`venv/` is a project-local Python virtual environment created by `python -m venv venv`. It has the same structure as `.venv/` — an isolated interpreter, pip, and all installed packages.",
                safetyNote: "Reproducible from `requirements.txt`, `Pipfile`, or `pyproject.toml`.",
                regenCommand: "python -m venv venv && pip install -r requirements.txt",
                links: [
                    InfoLink(title: "venv — Python docs", url: "https://docs.python.org/3/library/venv.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.pycache",
            displayName: "__pycache__/",
            ecosystem: .python, scope: .projectLocal,
            matcher: .aggregateByName(
                directoryName: "__pycache__",
                requiredProjectMarkers: ["pyproject.toml", "setup.py", "requirements.txt", "Pipfile"]
            ),
            action: .trash, tier: .low, aggregation: .perProject,
            notes: "CPython compiled bytecode cache.",
            languageKey: "python",
            item: ItemInfo(
                description: "`__pycache__/` directories contain compiled bytecode files (`.pyc`) that CPython writes alongside each `.py` source file on first import. One directory appears next to every Python module in the package tree.",
                safetyNote: "Python regenerates bytecode automatically on the next import.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Python — cached bytecode invalidation", url: "https://docs.python.org/3/reference/import.html#cached-bytecode-invalidation", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.pip-cache",
            displayName: "pip cache",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/pip"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "pip's global wheel and HTTP cache.",
            languageKey: "python",
            toolKey: "pip",
            item: ItemInfo(
                description: "`~/Library/Caches/pip` stores downloaded wheel archives and HTTP responses for pip's global cache on macOS. pip checks here before hitting the network, so reinstalling a previously downloaded package version is instant.",
                safetyNote: "pip re-downloads what it needs from PyPI on the next install.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "pip — caching", url: "https://pip.pypa.io/en/stable/topics/caching/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.uv-cache", displayName: "uv cache",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/uv"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "uv's global package cache.", iconAsset: "uv",
            languageKey: "python",
            toolKey: "uv",
            item: ItemInfo(
                description: "`~/Library/Caches/uv` is uv's global package cache on macOS. It stores downloaded wheel archives in a content-addressed store shared across all uv-managed environments, deduplicating identical package versions.",
                safetyNote: "uv re-downloads and re-caches packages on the next `uv sync` or `uv pip install`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "uv — caching", url: "https://docs.astral.sh/uv/concepts/cache/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.poetry-cache", displayName: "Poetry cache",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/pypoetry"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Poetry's global download cache.", iconAsset: "poetry",
            languageKey: "python",
            toolKey: "poetry",
            item: ItemInfo(
                description: "`~/Library/Caches/pypoetry` is Poetry's global download cache on macOS (set via `poetry config cache-dir`). It holds wheel archives and package metadata fetched during `poetry install` and is shared across all Poetry-managed projects.",
                safetyNote: "Poetry re-downloads all required packages from PyPI on the next `poetry install`.",
                regenCommand: "poetry install",
                links: [
                    InfoLink(title: "Poetry — configuration (cache-dir)", url: "https://python-poetry.org/docs/configuration/#cache-dir", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.pyenv-versions", displayName: "pyenv Python version",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".pyenv/versions"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "pyenv-installed Python interpreter.",
            iconAsset: "python",
            languageKey: "python",
            toolKey: "pyenv",
            item: ItemInfo(
                description: "`~/.pyenv/versions/` holds each Python interpreter installed by pyenv. Each subdirectory is a self-contained installation with its own interpreter binary, standard library, and pip; individual versions can be several hundred megabytes.",
                safetyNote: "Deleting a version removes that interpreter — projects whose `.python-version` specifies it will break until reinstalled.",
                regenCommand: "pyenv install <version>",
                links: [
                    InfoLink(title: "pyenv — version selection", url: "https://github.com/pyenv/pyenv?tab=readme-ov-file#understanding-python-version-selection", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.pipenv-cache", displayName: "pipenv Cache",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/pipenv"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "pipenv's HTTP wheel + hash cache.",
            iconAsset: "python",  // No standalone pipenv logo — reuses parent language
            languageKey: "python",
            toolKey: "pipenv",
            item: ItemInfo(
                description: "`~/.cache/pipenv` holds pipenv's HTTP wheel cache, hash cache, and cached packages. Notorious for unbounded growth — issue tracker reports of 16+ GB after long use are common. Override with `PIPENV_CACHE_DIR`.",
                safetyNote: "Re-downloaded from PyPI on the next `pipenv install`.",
                regenCommand: "pipenv install",
                links: [
                    InfoLink(title: "pipenv configuration", url: "https://pipenv.pypa.io/en/latest/configuration.html", kind: .docs),
                    InfoLink(title: "pipenv #3655 — unbounded cache growth", url: "https://github.com/pypa/pipenv/issues/3655", kind: .issue),
                ]
            )
        ),
        Rule(
            id: "py.pdm-cache", displayName: "PDM Cache",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/pdm"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "PDM's HTTP cache + downloaded wheels + metadata.",
            iconAsset: "pdm",
            languageKey: "python",
            toolKey: "pdm",
            item: ItemInfo(
                description: "`~/.cache/pdm` holds PDM's HTTP cache, downloaded wheels, package metadata, and hash cache. Known to grow large (issue #1301). PDM uses XDG-style paths even on macOS.",
                safetyNote: "Refilled from PyPI on the next `pdm install`.",
                regenCommand: "pdm install",
                links: [
                    InfoLink(title: "PDM configuration", url: "https://pdm-project.org/en/latest/reference/configuration/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.conda-pkgs", displayName: "Conda Package Cache",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".conda/pkgs"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Downloaded conda package archives + extracted dirs.",
            iconAsset: "conda",
            languageKey: "python",
            toolKey: "conda",
            item: ItemInfo(
                description: "`~/.conda/pkgs` stores downloaded `.conda`/`.tar.bz2` package archives plus extracted package directories used as the link source for conda environments. One of the largest offenders on conda machines (1–20 GB typical).",
                safetyNote: "Don't run while a conda env that hardlinks into this dir is active — re-create the env after cleaning if needed. Equivalent to `conda clean -p`.",
                regenCommand: "conda clean -p",
                links: [
                    InfoLink(title: "Conda — custom env/pkg locations", url: "https://docs.conda.io/projects/conda/en/stable/user-guide/configuration/custom-env-and-pkg-locations.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "py.pixi-cache", displayName: "Pixi / Rattler Cache",
            ecosystem: .python, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/rattler/cache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Pixi's conda packages + repodata + uv + http cache.",
            iconAsset: "pixi",
            languageKey: "python",
            toolKey: "pixi",
            item: ItemInfo(
                description: "`~/.cache/rattler/cache` is Pixi's combined cache: `pkgs/` (conda packages), `repodata/`, `uv-cache/`, and `http-cache/`. Override with `$PIXI_CACHE_DIR` or `$RATTLER_CACHE_DIR`.",
                safetyNote: "Refilled by the next `pixi install`.",
                regenCommand: "pixi install",
                links: [
                    InfoLink(title: "Pixi documentation", url: "https://pixi.sh/", kind: .official),
                ]
            )
        ),
    ]

    // MARK: - Go

    private static let go: [Rule] = [
        Rule(
            id: "go.build-cache",
            displayName: "Go build cache",
            ecosystem: .go, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/go-build"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Go incremental build cache (GOCACHE).",
            languageKey: "go",
            toolKey: "go-modules",
            item: ItemInfo(
                description: "`~/Library/Caches/go-build` is the Go build cache (`GOCACHE`) on macOS, storing compiled package objects and test results keyed by their inputs. Only packages whose inputs change are recompiled.",
                safetyNote: "`go build ./...` repopulates the cache from source; the module source cache at `~/go/pkg/mod` is unaffected.",
                regenCommand: "go build ./...",
                links: [
                    InfoLink(title: "Go — build and test caching", url: "https://pkg.go.dev/cmd/go#hdr-Build_and_test_caching", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "go.mod-cache",
            displayName: "Go module cache",
            ecosystem: .go, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "go/pkg/mod"),
            action: .cleanCommand(.goModCacheClean),
            tier: .medium, aggregation: .none,
            notes: "Downloaded module source trees, read-only.",
            languageKey: "go",
            toolKey: "go-modules",
            item: ItemInfo(
                description: "`~/go/pkg/mod` is the Go module cache (`GOPATH/pkg/mod`), containing downloaded module source trees and pre-compiled packages. Files are stored read-only to prevent accidental modification.",
                safetyNote: "`go clean -modcache` removes it safely; the toolchain re-downloads and verifies modules from the checksum database on the next build.",
                regenCommand: "go clean -modcache",
                links: [
                    InfoLink(title: "Go Modules reference — go clean -modcache", url: "https://go.dev/ref/mod#go-clean-modcache", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "go.golangci-lint-cache", displayName: "golangci-lint Cache",
            ecosystem: .go, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/golangci-lint"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-package lint result cache.",
            iconAsset: "golangci-lint",
            languageKey: "go",
            toolKey: "golangci-lint",
            item: ItemInfo(
                description: "`~/Library/Caches/golangci-lint` caches per-package lint results and intermediate analysis data so subsequent runs don't re-analyze unchanged code. Override with `$GOLANGCI_LINT_CACHE`.",
                safetyNote: "Refilled on the next lint run; only a perf hit.",
                regenCommand: "golangci-lint cache clean",
                links: [
                    InfoLink(title: "golangci-lint", url: "https://golangci-lint.run/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "go.gopls-cache", displayName: "gopls Cache",
            ecosystem: .go, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/gopls"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "gopls LSP analysis cache.",
            iconAsset: "go",
            languageKey: "go",
            toolKey: "gopls",
            item: ItemInfo(
                description: "`~/Library/Caches/gopls` is the on-disk cache for gopls (the Go language server) — parsed packages, type information, references. Used by VS Code, Neovim, and other gopls-backed editors.",
                safetyNote: "Editor restart re-indexes lazily; only a perf hit.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "gopls — Go language server", url: "https://pkg.go.dev/golang.org/x/tools/gopls", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - JVM (Gradle / Maven)

    private static let jvm: [Rule] = [
        Rule(
            id: "gradle.build",
            displayName: "build/ (Gradle)",
            ecosystem: .java, scope: .projectLocal,
            matcher: .marker(
                directoryName: "build",
                requiredMarkers: ["build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts"]
            ),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Gradle compiled classes and packaged JARs.",
            languageKey: "java",
            toolKey: "gradle",
            item: ItemInfo(
                description: "`build/` is Gradle's output directory, containing compiled classes, processed resources, packaged JARs or WARs, and test reports. Its layout mirrors Gradle's task graph and the project's source set structure.",
                safetyNote: "`gradle build` recreates the directory from source; no hand-written code lives here.",
                regenCommand: "gradle build",
                links: [
                    InfoLink(title: "Gradle — project directory layout", url: "https://docs.gradle.org/current/userguide/directory_layout.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "gradle.local",
            displayName: ".gradle/",
            ecosystem: .java, scope: .projectLocal,
            matcher: .marker(
                directoryName: ".gradle",
                requiredMarkers: ["build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts"]
            ),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-project Gradle cache and wrapper files.",
            languageKey: "java",
            toolKey: "gradle",
            item: ItemInfo(
                description: "`.gradle/` is Gradle's per-project cache directory, storing the Gradle wrapper JAR (`wrapper/dists/`), project-level caches, and configuration state. It is separate from the global `~/.gradle` cache.",
                safetyNote: "Gradle re-downloads the wrapper JAR and repopulates the project cache on the next `gradle build`.",
                regenCommand: "gradle build",
                links: [
                    InfoLink(title: "Gradle — project directory layout", url: "https://docs.gradle.org/current/userguide/directory_layout.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "maven.target",
            displayName: "target/ (Maven)",
            ecosystem: .java, scope: .projectLocal,
            matcher: .marker(
                directoryName: "target",
                requiredMarkers: ["pom.xml"],
                forbiddenMarkers: ["Cargo.toml"]
            ),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Maven compiled classes and packaged artifacts.",
            languageKey: "java",
            toolKey: "maven",
            item: ItemInfo(
                description: "`target/` is Maven's build output directory, containing compiled `.class` files, packaged JARs or WARs, generated sources, and test results produced by the Maven lifecycle.",
                safetyNote: "`mvn package` recreates the directory from source; no hand-written code lives here.",
                regenCommand: "mvn package",
                links: [
                    InfoLink(title: "Maven — standard directory layout", url: "https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "gradle.global",
            displayName: "Gradle caches",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".gradle/caches"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Gradle global dependency and build cache.",
            languageKey: "java",
            toolKey: "gradle",
            item: ItemInfo(
                description: "`~/.gradle/caches` is Gradle's global cache, storing downloaded dependencies, resolved script classpath artifacts, the build cache, and Gradle distribution metadata shared across all projects on the machine.",
                safetyNote: "Gradle re-downloads dependencies from configured repositories on the next build; no project source files are stored here.",
                regenCommand: "gradle build",
                links: [
                    InfoLink(title: "Gradle — build cache", url: "https://docs.gradle.org/current/userguide/build_cache.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "maven.global",
            displayName: "Maven local repository",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".m2/repository"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Maven local artifact repository.",
            languageKey: "java",
            toolKey: "maven",
            item: ItemInfo(
                description: "`~/.m2/repository` is Maven's local repository — a mirror of artifacts downloaded from Maven Central and other remote repositories. Maven checks here before hitting the network; it grows with every distinct dependency version used across all projects.",
                safetyNote: "Maven re-downloads all required artifacts from Maven Central or configured mirrors on the next build.",
                regenCommand: "mvn dependency:resolve",
                links: [
                    InfoLink(title: "Maven — introduction to repositories", url: "https://maven.apache.org/guides/introduction/introduction-to-repositories.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jvm.coursier-cache", displayName: "Coursier Cache",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/Coursier/v1"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Resolved JARs/POMs/sources shared across all Scala tooling.",
            iconAsset: "scala",  // No standalone Coursier logo — reuses Scala
            languageKey: "java",
            toolKey: "coursier",
            item: ItemInfo(
                description: "`~/Library/Caches/Coursier/v1` holds resolved JARs, POMs, and source artifacts shared by every Coursier-backed JVM tool — sbt, Mill, Bloop, Metals, Scala-CLI. Often the largest JVM cache on a Scala-heavy machine (1–10+ GB).",
                safetyNote: "Re-downloaded from Maven Central / configured resolvers on the next dependency resolution.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Coursier — cache docs", url: "https://get-coursier.io/docs/cache", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jvm.ivy2", displayName: "Ivy Resolution Cache",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".ivy2"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "sbt's classic Ivy cache (separate from Coursier).",
            iconAsset: "sbt",
            languageKey: "java",
            toolKey: "sbt",
            item: ItemInfo(
                description: "`~/.ivy2` is sbt's classic Ivy resolution cache (`cache/`, `local/`) — the older sibling of Coursier. Many sbt builds still use it. Override with `sbt.ivy.home`.",
                safetyNote: "sbt refills on demand via `sbt update`.",
                regenCommand: "sbt update",
                links: [
                    InfoLink(title: "sbt — cached resolution", url: "https://www.scala-sbt.org/1.x/docs/Cached-Resolution.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jvm.sbt-boot", displayName: "sbt Boot Directories",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".sbt"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "sbt launcher boot dirs + minigraph cache.",
            iconAsset: "sbt",
            languageKey: "java",
            toolKey: "sbt",
            item: ItemInfo(
                description: "`~/.sbt` holds sbt's launcher boot directories (`boot/` — one per Scala/sbt version pair) and minigraph dependency cache (`1.0/dependency/`). Bootstrapping a fresh sbt is slow.",
                safetyNote: "sbt re-bootstraps on the next launch — first run takes minutes.",
                regenCommand: "sbt",
                links: [
                    InfoLink(title: "sbt — launcher configuration", url: "https://www.scala-sbt.org/1.x/docs/Launcher-Configuration.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jvm.scala-cli-cache", displayName: "Scala CLI Cache",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/ScalaCli"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Bloop session, BSP state, prebuilts.",
            iconAsset: "scala",  // No standalone Scala CLI logo — reuses Scala
            languageKey: "java",
            toolKey: "scala-cli",
            item: ItemInfo(
                description: "`~/Library/Caches/ScalaCli` is Scala CLI's working state — Bloop server workdir, scripts cache, downloaded JVMs/Scala compilers used by `scala-cli`. Distinct from Coursier (which Scala CLI also uses for dependency JARs).",
                safetyNote: "Recreated on the next `scala-cli` invocation.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Scala CLI — internals", url: "https://scala-cli.virtuslab.org/docs/guides/advanced/internals/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jvm.metals-cache", displayName: "Metals Cache",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/org.scalameta.metals"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Metals trace logs, BSP cache, indexed symbols.",
            iconAsset: "metals",
            languageKey: "java",
            toolKey: "metals",
            item: ItemInfo(
                description: "`~/Library/Caches/org.scalameta.metals` holds Metals' trace logs, BSP cache, and indexed symbols. Used by VS Code (Metals extension), Neovim, and other Metals-backed editors for Scala.",
                safetyNote: "Recreated when Metals re-imports the build (next editor open of a Scala project).",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Metals — Scala language server", url: "https://scalameta.org/metals/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "gradle.wrapper-dists", displayName: "Gradle Wrapper Distributions",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".gradle/wrapper/dists"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Per-version Gradle distributions downloaded by the wrapper.",
            iconAsset: "gradle",
            languageKey: "java",
            toolKey: "gradle",
            item: ItemInfo(
                description: "`~/.gradle/wrapper/dists/` holds the full Gradle distribution (`gradle-X.Y.Z-bin.zip`, ~100 MB unzipped) for every version any Gradle Wrapper has requested. Each project's `gradle/wrapper/gradle-wrapper.properties` pins one.",
                safetyNote: "The wrapper re-downloads the pinned version on the next build.",
                regenCommand: "./gradlew --version",
                links: [
                    InfoLink(title: "Gradle — Wrapper", url: "https://docs.gradle.org/current/userguide/gradle_wrapper.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "android-sdk.system-images", displayName: "Android Emulator System Images",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Android/sdk/system-images"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Per-API-level emulator system images (5–40 GB total).",
            iconAsset: "android",
            brandTint: Color(red: 0x3D/255, green: 0xDC/255, blue: 0x84/255),  // Android green
            languageKey: "java",
            toolKey: "android-sdk",
            item: ItemInfo(
                description: "`~/Library/Android/sdk/system-images/` holds emulator system images, one per API level + architecture. Each image is multi-GB; AVDs (Android Virtual Devices) reference them.",
                safetyNote: "Re-installed via SDK Manager (`sdkmanager` or Android Studio's UI) when needed. AVDs that pin a deleted image will fail to boot until the image is reinstalled.",
                regenCommand: "sdkmanager 'system-images;<api>;<variant>;<arch>'",
                links: [
                    InfoLink(title: "Android — sdkmanager", url: "https://developer.android.com/tools/sdkmanager", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "android-sdk.platforms-cache", displayName: "Android SDK Download Staging",
            ecosystem: .java, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Android/sdk/.downloadIntermediates"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Partial / temp downloads from SDK Manager.",
            iconAsset: "android",
            brandTint: Color(red: 0x3D/255, green: 0xDC/255, blue: 0x84/255),
            languageKey: "java",
            toolKey: "android-sdk",
            item: ItemInfo(
                description: "`~/Library/Android/sdk/.downloadIntermediates/` (and the sibling `.temp/`) hold partial and intermediate downloads from the Android SDK Manager. Safe to clear when no SDK install is in progress.",
                safetyNote: "Recreated by the SDK Manager during the next install/update.",
                regenCommand: nil,
                links: []
            )
        ),
    ]

    // MARK: - C / C++

    private static let cpp: [Rule] = [
        Rule(
            id: "cpp.cmake", displayName: "build/ (CMake)",
            ecosystem: .cpp, scope: .projectLocal,
            matcher: .marker(
                directoryName: "build",
                requiredMarkers: ["CMakeLists.txt"],
                forbiddenMarkers: ["package.json", "pom.xml", "build.gradle", "build.gradle.kts", "pyproject.toml"]
            ),
            action: .trash, tier: .low, aggregation: .none,
            notes: "CMake out-of-source build directory.",
            iconAsset: "cmake",
            languageKey: "cpp",
            toolKey: "cmake",
            item: ItemInfo(
                description: "`build/` is CMake's out-of-source build directory, created by `cmake -B build`. It contains generated Makefiles or Ninja scripts, compiled object files, linked libraries, executables, and `CMakeCache.txt`.",
                safetyNote: "All contents are generated; `cmake -B build && cmake --build build` recreates the directory from source.",
                regenCommand: "cmake -B build && cmake --build build",
                links: [
                    InfoLink(title: "CMake — user interaction guide", url: "https://cmake.org/cmake/help/latest/guide/user-interaction/index.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "cpp.ccache", displayName: "ccache",
            ecosystem: .cpp, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/ccache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Compiler output cache for GCC and Clang.",
            iconAsset: "c-plusplus",
            languageKey: "cpp",
            toolKey: "ccache",
            item: ItemInfo(
                description: "`~/Library/Caches/ccache` (or `~/.ccache` if configured) is ccache's cache of previous compiler outputs, keyed by preprocessed source and compiler flags. It supports GCC, Clang, and compatible compilers for C, C++, Objective-C, and CUDA.",
                safetyNote: "Deleting the cache only causes slower rebuilds; ccache repopulates it transparently on the next compilation.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "ccache — manual", url: "https://ccache.dev/manual/latest.html", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Bazel

    private static let bazel: [Rule] = [
        Rule(
            id: "bazel.global", displayName: "Bazel output",
            ecosystem: .bazel, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/bazel"),
            action: .cleanCommand(.bazelExpunge),
            tier: .medium, aggregation: .none,
            notes: "Bazel output user root; use `bazel clean --expunge`.",
            iconAsset: "bazel",
            toolKey: "bazel",
            item: ItemInfo(
                description: "`~/.cache/bazel` is Bazel's output user root on macOS, containing the action cache, external repository downloads, and build outputs for every workspace on the machine. It can grow to tens of gigabytes.",
                safetyNote: "`bazel clean --expunge` stops the Bazel server and removes the output base cleanly before clearing.",
                regenCommand: "bazel clean --expunge",
                links: [
                    InfoLink(title: "Bazel — output directory layout", url: "https://bazel.build/docs/output_directories", kind: .docs),
                    InfoLink(title: "Bazel — bazel clean", url: "https://bazel.build/docs/user-manual#clean", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Package Managers (Homebrew, MacPorts, Nix)

    private static let nixosBlue    = Color(red: 0x52/255, green: 0x77/255, blue: 0xC3/255)
    private static let macportsBlue = Color(red: 0x18/255, green: 0x68/255, blue: 0xA7/255)

    private static let packageManagers: [Rule] = [
        Rule(
            id: "homebrew.cache", displayName: "Homebrew cache",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/Homebrew"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Homebrew's downloaded bottles and source archives.",
            iconAsset: "homebrew",
            toolKey: "homebrew",
            item: ItemInfo(
                description: "`~/Library/Caches/Homebrew` holds bottle tarballs (pre-compiled binaries) and formula source archives downloaded by `brew install` and `brew upgrade`. Homebrew consults this cache before hitting the network, so reinstalls of the same version require no download.",
                safetyNote: "Homebrew re-downloads bottles and archives on the next `brew install` or `brew upgrade`; installed formulae at `/opt/homebrew` are unaffected.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Homebrew — brew cleanup", url: "https://docs.brew.sh/Manpage#cleanup", kind: .docs),
                    InfoLink(title: "Homebrew — Bottles", url: "https://docs.brew.sh/Bottles", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "macports.user-config", displayName: "MacPorts user config",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".macports"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "MacPorts user-level variant overrides.",
            iconAsset: "macports", brandTint: macportsBlue,
            toolKey: "macports",
            item: ItemInfo(
                description: "`~/.macports/` stores user-level MacPorts configuration, including per-user variant overrides that control how ports are compiled (e.g. enabling or disabling optional features). Deleting it resets those preferences to MacPorts defaults; installed ports at `/opt/local` are unaffected.",
                safetyNote: "Installed ports at `/opt/local` are unaffected — only per-user variant preferences are lost and can be re-applied with `port variant`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "MacPorts Guide — variants", url: "https://guide.macports.org/#using.variants", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "nix.user-cache", displayName: "Nix user cache",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/nix"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Nix flake eval caches and fetched tarballs.",
            iconAsset: "nixos", brandTint: nixosBlue,
            toolKey: "nix",
            item: ItemInfo(
                description: "`~/.cache/nix/` stores flake evaluation SQLite databases and tarballs fetched during `nix` command runs. These caches speed up repeated evaluations of the same flake inputs but are rebuilt automatically on the next invocation.",
                safetyNote: "Nix rebuilds the evaluation cache and re-fetches tarballs automatically on the next command; the Nix store at `/nix/store` is unaffected.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Nix Reference Manual — nix flake", url: "https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "nix.flake-state", displayName: "Nix flake state",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/state/nix"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Nix flake lock state and per-user profile metadata.",
            iconAsset: "nixos", brandTint: nixosBlue,
            toolKey: "nix",
            item: ItemInfo(
                description: "`~/.local/state/nix/` holds flake lock-file state and per-user profile generation records. Nix uses this to track which profile generation is active and which flake inputs are pinned.",
                safetyNote: "Deleting removes profile generation history (old rollback points); the Nix store and currently installed packages are not removed, but rollbacks older than the current generation become unavailable.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Nix Reference Manual — profiles", url: "https://nix.dev/manual/nix/stable/package-management/profiles.html", kind: .docs),
                ]
            )
        ),
        // Lane 3 — sudo paths
        Rule(
            id: "nix.store-gc", displayName: "Nix store garbage collection",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedAbsolutePath("/nix/store"),
            action: .shellSudo(.nixCollectGarbage), tier: .high, aggregation: .none,
            notes: "Runs `nix-collect-garbage -d` — removes unreferenced store paths.",
            iconAsset: "nixos", brandTint: nixosBlue,
            toolKey: "nix",
            item: ItemInfo(
                description: "`/nix/store` is an immutable, content-addressed directory containing every package version ever built or fetched. Packages that are no longer reachable from any live profile accumulate here over time and can be deleted with `nix-collect-garbage -d`.",
                safetyNote: "Running `nix-collect-garbage -d` removes only unreferenced store paths; all packages reachable from live profiles remain intact.",
                regenCommand: "nix-collect-garbage -d",
                links: [
                    InfoLink(title: "Nix Reference Manual — nix-collect-garbage", url: "https://nix.dev/manual/nix/stable/command-ref/nix-collect-garbage", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "nix.logs", displayName: "Nix daemon logs",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedAbsolutePath("/nix/var/log/nix"),
            action: .shellSudo(.nixLogsRm), tier: .low, aggregation: .none,
            notes: "Nix daemon build and evaluation logs.",
            iconAsset: "nixos", brandTint: nixosBlue,
            toolKey: "nix",
            item: ItemInfo(
                description: "`/nix/var/log/nix/` contains root-owned logs written by the Nix daemon, capturing build output and daemon activity. These files are used only for debugging failed builds.",
                safetyNote: "These are diagnostic logs only; deleting them has no effect on the Nix store or installed packages. Note: the `.shellSudo` action will prompt for your password.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Nix Reference Manual — nix-daemon", url: "https://nix.dev/manual/nix/stable/command-ref/nix-daemon.html", kind: .docs),
                ]
            )
        ),
        // Homebrew cellar cleanup — old formula versions (lane 2, no sudo)
        Rule(
            id: "homebrew.cleanup-silicon", displayName: "Homebrew old versions",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedAbsolutePath("/opt/homebrew/Cellar"),
            action: .cleanCommand(.brewCleanup), tier: .medium, aggregation: .none,
            notes: "Old Homebrew formula versions (Apple Silicon). Runs `brew cleanup --prune=all`.",
            iconAsset: "homebrew",
            customSizer: .brewCleanupDryRun,
            toolKey: "homebrew",
            item: ItemInfo(
                description: "`/opt/homebrew/Cellar` stores every installed formula version on Apple Silicon Macs. Upgrading a formula leaves the previous version in place; `brew cleanup` removes those outdated copies while keeping the active version.",
                safetyNote: "The size shown is computed by `brew cleanup --dry-run` and covers only non-live versions; the currently active formula versions are not touched.",
                regenCommand: "brew cleanup --prune=all",
                links: [
                    InfoLink(title: "Homebrew — brew cleanup", url: "https://docs.brew.sh/Manpage#cleanup", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "homebrew.cleanup-intel", displayName: "Homebrew old versions",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedAbsolutePath("/usr/local/Cellar"),
            action: .cleanCommand(.brewCleanup), tier: .medium, aggregation: .none,
            notes: "Old Homebrew formula versions (Intel). Runs `brew cleanup --prune=all`.",
            iconAsset: "homebrew",
            customSizer: .brewCleanupDryRun,
            toolKey: "homebrew",
            item: ItemInfo(
                description: "`/usr/local/Cellar` stores every installed formula version on Intel Macs. Upgrading a formula leaves the previous version in place; `brew cleanup` removes those outdated copies while keeping the active version.",
                safetyNote: "The size shown is computed by `brew cleanup --dry-run` and covers only non-live versions; the currently active formula versions are not touched.",
                regenCommand: "brew cleanup --prune=all",
                links: [
                    InfoLink(title: "Homebrew — brew cleanup", url: "https://docs.brew.sh/Manpage#cleanup", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "macports.clean-all", displayName: "MacPorts cleanup",
            ecosystem: .packageManager, scope: .globalCache,
            matcher: .fixedAbsolutePath("/opt/local/var/macports/build"),
            action: .shellSudo(.macPortsCleanAll), tier: .medium, aggregation: .none,
            notes: "MacPorts build trees, distfiles, and logs. Runs `port clean --all installed`.",
            iconAsset: "macports", brandTint: macportsBlue,
            toolKey: "macports",
            item: ItemInfo(
                description: "`/opt/local/var/macports/build` accumulates work directories, source distfiles, and build logs as ports are compiled from source. After successful installation these intermediates serve no purpose.",
                safetyNote: "Installed ports at `/opt/local` are unaffected; only post-install build intermediates are removed. Note: the `.shellSudo` action will prompt for your password.",
                regenCommand: "sudo port clean --all installed",
                links: [
                    InfoLink(title: "MacPorts Guide — port clean", url: "https://guide.macports.org/#using.port.clean", kind: .docs),
                ]
            )
        ),
    ]

    // Brand tints used across multiple rules
    private static let netPurple   = Color(red: 0x51/255, green: 0x2B/255, blue: 0xD4/255)
    private static let nugetBlue   = Color(red: 0x00/255, green: 0x48/255, blue: 0x80/255)
    private static let riderPink   = Color(red: 0xC4/255, green: 0x0B/255, blue: 0x55/255)
    private static let rubyRed     = Color(red: 0xCC/255, green: 0x34/255, blue: 0x2D/255)
    private static let railsRed    = Color(red: 0xCC/255, green: 0x00/255, blue: 0x00/255)
    private static let jekyllRed   = Color(red: 0xCC/255, green: 0x00/255, blue: 0x00/255)
    private static let phpPurple   = Color(red: 0x77/255, green: 0x7B/255, blue: 0xB4/255)
    private static let laravelRed  = Color(red: 0xFF/255, green: 0x2D/255, blue: 0x20/255)
    private static let haskellPurple = Color(red: 0x5D/255, green: 0x4F/255, blue: 0x85/255)
    private static let dartBlue    = Color(red: 0x01/255, green: 0x75/255, blue: 0xC2/255)
    private static let flutterBlue = Color(red: 0x02/255, green: 0x56/255, blue: 0x9B/255)
    private static let elixirPurple = Color(red: 0x4B/255, green: 0x27/255, blue: 0x5F/255)
    private static let phoenixOrange = Color(red: 0xFD/255, green: 0x4F/255, blue: 0x00/255)
    private static let erlangRed   = Color(red: 0xA9/255, green: 0x05/255, blue: 0x33/255)
    private static let zigOrange   = Color(red: 0xF7/255, green: 0xA4/255, blue: 0x1D/255)
    private static let crystalBlack = Color(red: 0x10/255, green: 0x10/255, blue: 0x10/255)
    private static let nimYellow   = Color(red: 0xFF/255, green: 0xE9/255, blue: 0x53/255)
    private static let ocamlOrange = Color(red: 0xEC/255, green: 0x68/255, blue: 0x13/255)
    private static let dlangRed    = Color(red: 0xB0/255, green: 0x39/255, blue: 0x31/255)
    private static let juliaPurple = Color(red: 0x95/255, green: 0x58/255, blue: 0xB2/255)
    private static let rBlue       = Color(red: 0x27/255, green: 0x6D/255, blue: 0xC3/255)
    private static let hugoPink    = Color(red: 0xFF/255, green: 0x40/255, blue: 0x88/255)
    private static let gatsbyPurple = Color(red: 0x66/255, green: 0x33/255, blue: 0x99/255)
    private static let docusaurusGreen = Color(red: 0x3E/255, green: 0xCC/255, blue: 0x5F/255)
    private static let zolaBlue    = Color(red: 0x0B/255, green: 0x5A/255, blue: 0xAE/255)
    private static let mkdocsBlue  = Color(red: 0x52/255, green: 0x6C/255, blue: 0xFE/255)
    private static let astroOrange = Color(red: 0xFF/255, green: 0x5D/255, blue: 0x01/255)
    // Ollama's mark is a dark llama on a white disc. A near-black tint makes
    // the IconTile read as a black blob in dark mode. Use white so the tile
    // sits on a light background in both light and dark schemes, which is
    // how Ollama ships its own branding.
    private static let ollamaWhite = Color.white
    private static let hfYellow    = Color(red: 0xFF/255, green: 0xD2/255, blue: 0x1E/255)
    private static let pytorchOrange = Color(red: 0xEE/255, green: 0x4C/255, blue: 0x2C/255)
    private static let tfOrange    = Color(red: 0xFF/255, green: 0x6F/255, blue: 0x00/255)
    private static let kerasRed    = Color(red: 0xD0/255, green: 0x00/255, blue: 0x00/255)
    private static let dockerBlue  = Color(red: 0x24/255, green: 0x96/255, blue: 0xED/255)
    private static let orbstackOrange = Color(red: 0xFF/255, green: 0x6B/255, blue: 0x35/255)
    private static let vscodeBlue  = Color(red: 0x00/255, green: 0x7A/255, blue: 0xCC/255)
    private static let vscodeInsidersTeal = Color(red: 0x24/255, green: 0xBF/255, blue: 0xA5/255)
    private static let cursorBlack = Color(red: 0x0B/255, green: 0x0B/255, blue: 0x0B/255)
    private static let zedBlack    = Color(red: 0x0E/255, green: 0x11/255, blue: 0x16/255)
    private static let jetbrainsBlack = Color(red: 0x10/255, green: 0x10/255, blue: 0x10/255)
    private static let fleetBlue   = Color(red: 0x08/255, green: 0x7C/255, blue: 0xFA/255)
    private static let sublimeOrange = Color(red: 0xFF/255, green: 0x98/255, blue: 0x00/255)
    private static let novaPurple  = Color(red: 0x5B/255, green: 0x41/255, blue: 0xF5/255)
    private static let neovimGreen = Color(red: 0x57/255, green: 0xA1/255, blue: 0x43/255)
    private static let emacsPurple = Color(red: 0x7F/255, green: 0x5A/255, blue: 0xB6/255)
    private static let helixGray   = Color(red: 0xBA/255, green: 0xB6/255, blue: 0xBE/255)
    private static let eclipsePurple = Color(red: 0x2C/255, green: 0x22/255, blue: 0x55/255)
    private static let llvmBlack   = Color(red: 0x26/255, green: 0x2D/255, blue: 0x3A/255)
    private static let playwrightGreen = Color(red: 0x2E/255, green: 0xAD/255, blue: 0x33/255)

    // MARK: - .NET

    private static let dotnet: [Rule] = [
        Rule(
            id: "dotnet.bin", displayName: "bin/ (.NET)",
            ecosystem: .dotnet, scope: .projectLocal,
            matcher: .marker(directoryName: "bin",
                             requiredMarkers: ["*.csproj", "*.fsproj", "*.vbproj", "*.sln", "*.slnx"],
                             forbiddenMarkers: ["package.json", "Cargo.toml", "go.mod", "pom.xml", "build.gradle", "build.gradle.kts"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "MSBuild final output — compiled assemblies.",
            iconAsset: "dotnet", brandTint: netPurple,
            languageKey: "dotnet",
            toolKey: "dotnet-cli",
            item: ItemInfo(
                description: "`bin/` is MSBuild's final output directory, containing compiled assemblies (`.dll` or `.exe`), dependencies, resource files, and configuration. Subdirectories mirror build configuration (`Debug/`, `Release/`) and target framework (`net8.0/`).",
                safetyNote: "`dotnet build` recreates the directory from source; no hand-written code lives here.",
                regenCommand: "dotnet build",
                links: [
                    InfoLink(title: "dotnet build — Microsoft Learn", url: "https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "dotnet.obj", displayName: "obj/ (.NET)",
            ecosystem: .dotnet, scope: .projectLocal,
            matcher: .marker(directoryName: "obj",
                             requiredMarkers: ["*.csproj", "*.fsproj", "*.vbproj", "*.sln", "*.slnx"],
                             forbiddenMarkers: ["package.json", "Cargo.toml", "go.mod"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "MSBuild intermediate files and NuGet assets.",
            iconAsset: "dotnet", brandTint: netPurple,
            languageKey: "dotnet",
            toolKey: "dotnet-cli",
            item: ItemInfo(
                description: "`obj/` is MSBuild's intermediate build directory, containing restored NuGet assets (`project.assets.json`), compiled intermediate files, and MSBuild-generated code. It is distinct from the final `bin/` output.",
                safetyNote: "`dotnet build` restores NuGet assets and recreates all intermediate files from source.",
                regenCommand: "dotnet build",
                links: [
                    InfoLink(title: "dotnet clean — Microsoft Learn", url: "https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-clean", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "dotnet.nuget-packages", displayName: "NuGet packages",
            ecosystem: .dotnet, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".nuget/packages"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "NuGet global packages folder, shared across projects.",
            iconAsset: "nuget", brandTint: nugetBlue,
            languageKey: "dotnet",
            toolKey: "nuget",
            item: ItemInfo(
                description: "`~/.nuget/packages` is NuGet's global packages folder, where every downloaded package version is extracted. Projects using PackageReference read assemblies directly from this folder rather than copying them locally.",
                safetyNote: "`dotnet restore` re-downloads and re-extracts all required packages from nuget.org or configured feeds.",
                regenCommand: "dotnet restore",
                links: [
                    InfoLink(title: "NuGet — managing global packages and cache folders", url: "https://learn.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "dotnet.nuget-http-cache", displayName: "NuGet HTTP cache",
            ecosystem: .dotnet, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/share/NuGet/v3-cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "NuGet HTTP response and feed metadata cache.",
            iconAsset: "nuget", brandTint: nugetBlue,
            languageKey: "dotnet",
            toolKey: "nuget",
            item: ItemInfo(
                description: "`~/.local/share/NuGet/v3-cache` is NuGet's HTTP response cache, storing feed metadata, package version lists, and partial download responses. Items expire after 30 minutes under normal use.",
                safetyNote: "NuGet re-fetches feed metadata on the next `dotnet restore`; packages already in the global folder are unaffected.",
                regenCommand: "dotnet restore",
                links: [
                    InfoLink(title: "NuGet — managing global packages and cache folders", url: "https://learn.microsoft.com/en-us/nuget/consume-packages/managing-the-global-packages-and-cache-folders", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "dotnet.omnisharp", displayName: "OmniSharp cache",
            ecosystem: .dotnet, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".omnisharp"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "OmniSharp LSP server cache.",
            iconAsset: "dotnet", brandTint: netPurple,
            languageKey: "dotnet",
            toolKey: "omnisharp",
            item: ItemInfo(
                description: "`~/.omnisharp` holds OmniSharp's global configuration and server cache. OmniSharp is the LSP server that powers the C# extension for VS Code and other editors, providing IntelliSense, diagnostics, and refactoring for .NET projects.",
                safetyNote: "OmniSharp recreates its cache when the editor next opens a .NET project.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "OmniSharp — GitHub", url: "https://github.com/OmniSharp/omnisharp-roslyn", kind: .official),
                ]
            )
        ),
    ]

    // MARK: - Ruby

    private static let ruby: [Rule] = [
        Rule(
            id: "ruby.dot-bundle", displayName: ".bundle/",
            ecosystem: .ruby, scope: .projectLocal,
            matcher: .marker(directoryName: ".bundle",
                             requiredMarkers: ["Gemfile", "Gemfile.lock"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Bundler per-project config directory.",
            iconAsset: "ruby", brandTint: rubyRed,
            languageKey: "ruby",
            toolKey: "bundler",
            item: ItemInfo(
                description: "`.bundle/` is Bundler's per-project configuration directory. It contains a `config` file written by `bundle config` that stores local overrides such as `BUNDLE_PATH` and excluded groups.",
                safetyNote: "Bundler falls back to global defaults and rewrites it on the next `bundle install` or `bundle config` call.",
                regenCommand: "bundle install",
                links: [
                    InfoLink(title: "Bundler — bundle config", url: "https://bundler.io/v2.5/man/bundle-config.1.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "ruby.gem-user", displayName: "~/.gem",
            ecosystem: .ruby, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".gem"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "User-level RubyGems installation directory.",
            iconAsset: "ruby", brandTint: rubyRed,
            languageKey: "ruby",
            item: ItemInfo(
                description: "`~/.gem` is the user-level RubyGems installation prefix, holding gem specifications, installed gem source trees, and compiled build extensions for gems installed without `sudo`. It is populated by `gem install --user-install` and by Bundler when no project-specific `BUNDLE_PATH` is set.",
                safetyNote: "System-level gems are unaffected; reinstall user gems with `gem install <name>` or `bundle install`.",
                regenCommand: "bundle install",
                links: [
                    InfoLink(title: "RubyGems — user install FAQ", url: "https://guides.rubygems.org/faqs/#user-install", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "ruby.rbenv-versions", displayName: "rbenv Ruby version",
            ecosystem: .ruby, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".rbenv/versions"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "rbenv-installed Ruby interpreter.",
            iconAsset: "ruby", brandTint: rubyRed,
            languageKey: "ruby",
            toolKey: "rbenv",
            item: ItemInfo(
                description: "`~/.rbenv/versions/` contains each Ruby interpreter installed by rbenv (via the `ruby-build` plugin). Each subdirectory is a self-contained installation with the interpreter, standard library, and default gems, typically several hundred megabytes.",
                safetyNote: "Deleting a version removes that interpreter — projects whose `.ruby-version` points to it will fail until reinstalled.",
                regenCommand: "rbenv install <version>",
                links: [
                    InfoLink(title: "rbenv — installing Ruby versions", url: "https://github.com/rbenv/rbenv?tab=readme-ov-file#installing-ruby-versions", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "ruby.rvm-rubies", displayName: "RVM Ruby version",
            ecosystem: .ruby, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".rvm/rubies"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "RVM-installed Ruby interpreter.",
            iconAsset: "ruby", brandTint: rubyRed,
            languageKey: "ruby",
            toolKey: "rvm",
            item: ItemInfo(
                description: "`~/.rvm/rubies/` contains each Ruby interpreter managed by RVM. Each subdirectory is a self-contained installation with the interpreter binary, standard library, and default gems, typically 100 MB to several hundred megabytes per version.",
                safetyNote: "Deleting a version removes that interpreter and its gemsets — reinstall with `rvm install <version>` before switching to it.",
                regenCommand: "rvm install <version>",
                links: [
                    InfoLink(title: "RVM — installing Ruby", url: "https://rvm.io/rubies/installing", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "ruby.rvm-archives", displayName: "RVM archives",
            ecosystem: .ruby, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".rvm/archives"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "RVM Ruby source tarball cache.",
            iconAsset: "ruby", brandTint: rubyRed,
            languageKey: "ruby",
            toolKey: "rvm",
            item: ItemInfo(
                description: "`~/.rvm/archives/` caches source tarballs downloaded by RVM when compiling Ruby versions from source. Once a version is compiled and installed, these archives serve only as a download cache.",
                safetyNote: "RVM re-downloads the tarball on the next install of the same version.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "ruby.chruby-rubies", displayName: "chruby Ruby version",
            ecosystem: .ruby, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".rubies"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "chruby/ruby-install Ruby interpreter.",
            iconAsset: "ruby", brandTint: rubyRed,
            languageKey: "ruby",
            toolKey: "chruby",
            item: ItemInfo(
                description: "`~/.rubies/` is the default installation prefix for `ruby-install`, the companion installer to chruby. Each subdirectory is a self-contained Ruby installation; chruby switches between them by adjusting `PATH` and related environment variables.",
                safetyNote: "Deleting a version removes that interpreter — reinstall with `ruby-install ruby <version>` before using projects that depend on it.",
                regenCommand: "ruby-install ruby <version>",
                links: [
                    InfoLink(title: "ruby-install — GitHub", url: "https://github.com/postmodern/ruby-install", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "ruby.asdf-ruby", displayName: "asdf Ruby version",
            ecosystem: .ruby, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".asdf/installs/ruby"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "asdf-installed Ruby interpreter.",
            iconAsset: "ruby", brandTint: rubyRed,
            languageKey: "ruby",
            toolKey: "asdf",
            item: ItemInfo(
                description: "`~/.asdf/installs/ruby/` contains Ruby versions installed by asdf's ruby plugin. Each subdirectory is a self-contained Ruby installation; asdf selects among them based on the project's `.tool-versions` file.",
                safetyNote: "Deleting a version removes that interpreter — projects whose `.tool-versions` specifies it will break until reinstalled.",
                regenCommand: "asdf install ruby <version>",
                links: [
                    InfoLink(title: "asdf — managing versions", url: "https://asdf-vm.com/manage/versions.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jekyll.site", displayName: "_site/ (Jekyll)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "_site",
                             requiredMarkers: ["_config.yml", "_config.yaml"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Jekyll rendered site output.",
            iconAsset: "jekyll", brandTint: jekyllRed,
            languageKey: "ruby",
            toolKey: "jekyll",
            item: ItemInfo(
                description: "`_site/` is Jekyll's build output directory, containing the complete static HTML, CSS, JavaScript, and assets rendered from Markdown content and Liquid templates. `jekyll build` or `jekyll serve` writes to it.",
                safetyNote: "`jekyll build` regenerates the entire directory from source.",
                regenCommand: "jekyll build",
                links: [
                    InfoLink(title: "Jekyll — directory structure", url: "https://jekyllrb.com/docs/structure/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jekyll.cache", displayName: ".jekyll-cache/",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: ".jekyll-cache",
                             requiredMarkers: ["_config.yml", "_config.yaml"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Jekyll incremental build cache.",
            iconAsset: "jekyll", brandTint: jekyllRed,
            languageKey: "ruby",
            toolKey: "jekyll",
            item: ItemInfo(
                description: "`.jekyll-cache/` holds Jekyll's incremental build cache — rendered Markdown pages and Liquid template output stored between builds. It lets `jekyll build --incremental` skip re-processing unchanged files.",
                safetyNote: "Jekyll does a full rebuild on the next `jekyll build`; no source files are affected.",
                regenCommand: "jekyll build",
                links: [
                    InfoLink(title: "Jekyll — incremental regeneration", url: "https://jekyllrb.com/docs/configuration/incremental-regeneration/", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - PHP

    private static let php: [Rule] = [
        Rule(
            id: "php.vendor", displayName: "vendor/ (Composer)",
            ecosystem: .php, scope: .projectLocal,
            matcher: .marker(directoryName: "vendor",
                             requiredMarkers: ["composer.json", "composer.lock"],
                             forbiddenMarkers: ["go.mod", "Cargo.toml"]),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Composer PHP dependency directory.",
            iconAsset: "php", brandTint: phpPurple,
            languageKey: "php",
            toolKey: "composer",
            item: ItemInfo(
                description: "`vendor/` is Composer's project-local dependency directory, containing the source code of every PHP library declared in `composer.json`. Composer also writes `vendor/autoload.php`, the PSR-4 autoloader that provides class auto-loading for all installed packages.",
                safetyNote: "Reproducible from `composer.lock` — `composer install` restores exact versions recorded in the lockfile.",
                regenCommand: "composer install",
                links: [
                    InfoLink(title: "Composer — basic usage", url: "https://getcomposer.org/doc/01-basic-usage.md", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "php.composer-cache", displayName: "Composer cache",
            ecosystem: .php, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".composer/cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Composer global download cache.",
            iconAsset: "composer", brandTint: phpPurple,
            languageKey: "php",
            toolKey: "composer",
            item: ItemInfo(
                description: "`~/.composer/cache/` is Composer's global download cache, storing package zip archives and Packagist repository metadata. It prevents repeated network downloads when the same package version is installed across multiple projects.",
                safetyNote: "Composer re-downloads required packages from Packagist on the next `composer install` or `composer update`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Composer — clear-cache command", url: "https://getcomposer.org/doc/03-cli.md#clear-cache-clearcache-cc", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "php.composer-cache-xdg", displayName: "Composer cache (XDG)",
            ecosystem: .php, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/composer"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Composer cache (XDG Base Directory location).",
            iconAsset: "composer", brandTint: phpPurple,
            languageKey: "php",
            toolKey: "composer",
            item: ItemInfo(
                description: "`~/.cache/composer/` is the XDG Base Directory-compliant location for Composer's download cache, used on Linux or when `$XDG_CACHE_HOME` is set. It serves the same purpose as `~/.composer/cache/`, storing package archives and Packagist metadata.",
                safetyNote: "Composer re-downloads required packages on the next `composer install` or `composer update`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Composer — clear-cache command", url: "https://getcomposer.org/doc/03-cli.md#clear-cache-clearcache-cc", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Haskell

    private static let haskell: [Rule] = [
        Rule(
            id: "haskell.dist-newstyle", displayName: "dist-newstyle/",
            ecosystem: .haskell, scope: .projectLocal,
            matcher: .marker(directoryName: "dist-newstyle",
                             requiredMarkers: ["*.cabal", "cabal.project"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cabal build artifacts directory.",
            iconAsset: "haskell", brandTint: haskellPurple,
            languageKey: "haskell",
            item: ItemInfo(
                description: "`dist-newstyle/` is the build output for Cabal's nix-style build system. It contains GHC-compiled object files, interface files (`.hi`), and linked executables organised by GHC version and architecture.",
                safetyNote: "`cabal build` recreates the directory by recompiling the project.",
                regenCommand: "cabal build",
                links: []
            )
        ),
        Rule(
            id: "haskell.stack-work", displayName: ".stack-work/",
            ecosystem: .haskell, scope: .projectLocal,
            matcher: .marker(directoryName: ".stack-work",
                             requiredMarkers: ["stack.yaml", "*.cabal", "package.yaml"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Stack per-project build directory.",
            iconAsset: "haskell", brandTint: haskellPurple,
            languageKey: "haskell",
            item: ItemInfo(
                description: "`.stack-work/` is Stack's per-project build directory, containing compiled object files, GHC interface files, and installed library registrations for the project and its snapshot dependencies.",
                safetyNote: "`stack build` recreates it; snapshot packages are re-linked from the global Stack cache.",
                regenCommand: "stack build",
                links: []
            )
        ),
        Rule(
            id: "haskell.stack-global", displayName: "Stack global",
            ecosystem: .haskell, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".stack"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Stack global snapshots, GHC installs, and package store.",
            iconAsset: "haskell", brandTint: haskellPurple,
            languageKey: "haskell",
            item: ItemInfo(
                description: "`~/.stack/` is Stack's global data directory, holding downloaded Stackage snapshots, prebuilt GHC installations, and compiled snapshot package stores shared across all Stack projects. It can grow to many gigabytes.",
                safetyNote: "Deleting it removes all Stack-managed GHC installations and compiled snapshot packages — rebuilding from scratch takes significant time.",
                regenCommand: "stack build",
                links: []
            )
        ),
        Rule(
            id: "haskell.cabal-store", displayName: "Cabal store",
            ecosystem: .haskell, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cabal/store"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Cabal global Nix-style package store.",
            iconAsset: "haskell", brandTint: haskellPurple,
            languageKey: "haskell",
            item: ItemInfo(
                description: "`~/.cabal/store/` is Cabal's global package store (introduced in Cabal 3.x). Compiled libraries are laid out by package name, version, and build flags in a content-addressed format and hardlinked into project builds that share the same configuration.",
                safetyNote: "Cabal recompiles and repopulates the store from Hackage on the next `cabal build`; first rebuild will be slow.",
                regenCommand: "cabal build",
                links: [
                    InfoLink(title: "Hackage — Haskell package repository", url: "https://hackage.haskell.org", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "haskell.ghcup-ghcs", displayName: "GHC install (ghcup)",
            ecosystem: .haskell, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".ghcup/ghc"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "ghcup-installed GHC compiler.",
            iconAsset: "haskell", brandTint: haskellPurple,
            languageKey: "haskell",
            toolKey: "ghcup",
            item: ItemInfo(
                description: "`~/.ghcup/ghc/` contains GHC (Glasgow Haskell Compiler) versions installed by ghcup. Each subdirectory is a self-contained installation with the compiler, runtime libraries, and base packages; individual versions can exceed 1 GB.",
                safetyNote: "Deleting a GHC version removes that compiler — Stack and Cabal projects that require it will fail until reinstalled.",
                regenCommand: "ghcup install ghc <version>",
                links: [
                    InfoLink(title: "GHCup — installation guide", url: "https://www.haskell.org/ghcup/install/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "haskell.ghcup-cache", displayName: "ghcup cache",
            ecosystem: .haskell, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".ghcup/cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "ghcup toolchain download cache.",
            iconAsset: "haskell", brandTint: haskellPurple,
            languageKey: "haskell",
            toolKey: "ghcup",
            item: ItemInfo(
                description: "`~/.ghcup/cache/` stores tarballs downloaded by ghcup when installing GHC versions, HLS (Haskell Language Server), and other toolchain components. Once a tool is installed, these archives are kept only as a download cache.",
                safetyNote: "ghcup re-downloads the required archives from its distribution server on the next installation.",
                regenCommand: nil,
                links: []
            )
        ),
    ]

    // MARK: - Dart / Flutter

    private static let dartFlutter: [Rule] = [
        Rule(
            id: "dart.tool", displayName: ".dart_tool/",
            ecosystem: .dart, scope: .projectLocal,
            matcher: .marker(directoryName: ".dart_tool",
                             requiredMarkers: ["pubspec.yaml"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Dart/Flutter per-project tool metadata.",
            iconAsset: "dart", brandTint: dartBlue,
            languageKey: "dart", toolKey: "pub",
            item: ItemInfo(
                description: "`.dart_tool/` stores per-project metadata written by `dart pub get` or `flutter pub get`, including the resolved package dependency map, build runner outputs, and tool-specific caches. Its contents are machine-specific and must not be committed to version control.",
                safetyNote: "Recreated by `dart pub get` or `flutter pub get` from `pubspec.yaml` and `pubspec.lock`.",
                regenCommand: "dart pub get",
                links: [
                    InfoLink(title: "Dart — package layout conventions", url: "https://dart.dev/tools/pub/package-layout", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "flutter.build", displayName: "build/ (Flutter)",
            ecosystem: .dart, scope: .projectLocal,
            matcher: .marker(directoryName: "build",
                             requiredMarkers: ["pubspec.yaml"],
                             forbiddenMarkers: ["package.json", "Cargo.toml", "go.mod", "CMakeLists.txt", "pom.xml", "build.gradle"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Flutter compiled build artifacts.",
            iconAsset: "flutter", brandTint: flutterBlue,
            languageKey: "dart", toolKey: "flutter",
            item: ItemInfo(
                description: "`build/` contains compiled Flutter build artifacts — native binaries, web bundles, and platform-specific intermediates — written during `flutter build`. The directory is organised by target platform (`build/ios/`, `build/web/`, etc.).",
                safetyNote: "Entirely generated output; rebuilt by `flutter build <target>`.",
                regenCommand: "flutter build",
                links: [
                    InfoLink(title: "Flutter CLI reference", url: "https://docs.flutter.dev/reference/flutter-cli", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "dart.pub-cache", displayName: "pub cache",
            ecosystem: .dart, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".pub-cache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "pub global package cache.",
            iconAsset: "dart", brandTint: dartBlue,
            languageKey: "dart", toolKey: "pub",
            item: ItemInfo(
                description: "`~/.pub-cache/` is the global package cache for the `pub` package manager, shared across all Dart and Flutter projects. It stores downloaded package archives and extracted source trees so that repeated `pub get` calls skip re-downloading already-fetched packages.",
                safetyNote: "`dart pub get` or `flutter pub get` re-downloads all required packages from pub.dev on the next run.",
                regenCommand: "dart pub get",
                links: [
                    InfoLink(title: "dart pub — pub commands", url: "https://dart.dev/tools/pub/cmd", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Elixir / Erlang (BEAM ecosystem)

    private static let elixirErlang: [Rule] = [
        Rule(
            id: "elixir.build", displayName: "_build/ (Mix)",
            ecosystem: .elixir, scope: .projectLocal,
            matcher: .marker(directoryName: "_build",
                             requiredMarkers: ["mix.exs", "mix.lock"],
                             forbiddenMarkers: ["rebar.config", "dune-project"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Mix compiled BEAM output.",
            iconAsset: "elixir", brandTint: elixirPurple,
            languageKey: "elixir",
            item: ItemInfo(
                description: "`_build/` is Mix's output directory for compiled BEAM bytecode, consolidated protocols, and application resource files. Subdirectories correspond to environments: `_build/dev/`, `_build/test/`, and `_build/prod/`.",
                safetyNote: "`mix compile` or `mix deps.compile` rebuilds the entire output tree.",
                regenCommand: "mix compile",
                links: [
                    InfoLink(title: "Mix — build tool", url: "https://hexdocs.pm/mix/Mix.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "elixir.deps", displayName: "deps/ (Mix)",
            ecosystem: .elixir, scope: .projectLocal,
            matcher: .marker(directoryName: "deps",
                             requiredMarkers: ["mix.exs", "mix.lock"]),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Mix fetched dependency sources.",
            iconAsset: "elixir", brandTint: elixirPurple,
            languageKey: "elixir",
            item: ItemInfo(
                description: "`deps/` contains the source code of all Hex and Git dependencies declared in `mix.exs`. Mix downloads and unpacks each dependency here; `mix.lock` pins exact versions so `mix deps.get` produces a reproducible result.",
                safetyNote: "`mix deps.get` re-fetches all dependencies from Hex and configured Git sources.",
                regenCommand: "mix deps.get",
                links: [
                    InfoLink(title: "Mix — deps.get task", url: "https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "elixir.mix", displayName: "~/.mix",
            ecosystem: .elixir, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".mix"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Mix global home: archives, Hex config, rebar3.",
            iconAsset: "elixir", brandTint: elixirPurple,
            languageKey: "elixir",
            item: ItemInfo(
                description: "`~/.mix/` is Mix's global home directory, holding installed Mix archives (e.g. `phx_new`), Hex package manager configuration, and a bundled copy of rebar3 used to compile Erlang dependencies.",
                safetyNote: "Mix re-downloads Hex and rebar3 on the next invocation that requires them.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Mix — archive tasks", url: "https://hexdocs.pm/mix/Mix.Tasks.Archive.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "elixir.hex", displayName: "~/.hex",
            ecosystem: .elixir, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".hex"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Hex global package cache (Elixir + Erlang).",
            iconAsset: "hex", brandTint: elixirPurple,
            languageKey: "elixir", toolKey: "hex",
            item: ItemInfo(
                description: "`~/.hex/` is the global Hex cache, shared between Elixir (Mix) and Erlang (rebar3) projects. It stores the Hex registry index and downloaded package tarballs; packages fetched once are reused across all projects.",
                safetyNote: "Hex re-downloads the registry and required packages from hex.pm on the next `mix deps.get` or `rebar3 get-deps`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Hex — package manager for BEAM", url: "https://hexdocs.pm/hex/Mix.Tasks.Hex.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "erlang.rebar3-build", displayName: "_build/ (rebar3)",
            ecosystem: .elixir, scope: .projectLocal,
            matcher: .marker(directoryName: "_build",
                             requiredMarkers: ["rebar.config", "rebar.lock"],
                             forbiddenMarkers: ["dune-project", "mix.exs"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "rebar3 compiled BEAM output.",
            iconAsset: "erlang", brandTint: erlangRed,
            languageKey: "elixir",
            toolKey: "rebar3",
            item: ItemInfo(
                description: "`_build/` is rebar3's output directory for compiled Erlang BEAM files, application resource files, and release artifacts. Per-profile subdirectories (`_build/default/`, `_build/prod/`) hold both project modules and compiled dependency copies.",
                safetyNote: "`rebar3 compile` rebuilds the entire tree from source.",
                regenCommand: "rebar3 compile",
                links: [
                    InfoLink(title: "rebar3 — commands", url: "https://rebar3.org/docs/commands/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "erlang.rebar3-cache", displayName: "rebar3 cache",
            ecosystem: .elixir, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/rebar3"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "rebar3 Hex package and plugin cache.",
            iconAsset: "erlang", brandTint: erlangRed,
            languageKey: "elixir",
            toolKey: "rebar3",
            item: ItemInfo(
                description: "`~/.cache/rebar3/` is rebar3's global cache, storing downloaded Hex package tarballs, compiled plugin archives, and the Hex registry index. It is shared across all Erlang projects to avoid repeated network downloads.",
                safetyNote: "rebar3 re-downloads the Hex registry and required packages from hex.pm on the next build.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "rebar3 — dependencies", url: "https://rebar3.org/docs/configuration/dependencies/", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Other Languages (Zig / D / Crystal / Nim / OCaml / Julia / R)

    private static let otherLangs: [Rule] = [
        // Zig
        Rule(
            id: "zig.cache", displayName: ".zig-cache/",
            ecosystem: .otherLangs, scope: .projectLocal,
            matcher: .marker(directoryName: ".zig-cache",
                             requiredMarkers: ["build.zig", "build.zig.zon"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Zig per-project build cache.",
            iconAsset: "zig", brandTint: zigOrange,
            item: ItemInfo(
                description: "`.zig-cache/` stores intermediate compilation artifacts and hash-based build state for the Zig build system. It enables incremental builds by skipping steps whose inputs are unchanged.",
                safetyNote: "`zig build` repopulates it on the next invocation; first build is a full cold compile.",
                regenCommand: "zig build",
                links: [
                    InfoLink(title: "Zig — build system", url: "https://ziglang.org/learn/build-system/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "zig.out", displayName: "zig-out/",
            ecosystem: .otherLangs, scope: .projectLocal,
            matcher: .marker(directoryName: "zig-out",
                             requiredMarkers: ["build.zig"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Zig build install output prefix.",
            iconAsset: "zig", brandTint: zigOrange,
            item: ItemInfo(
                description: "`zig-out/` is the default install prefix written by `zig build install`. It contains compiled executables, libraries, and other artifacts designated for installation by `build.zig`, organised into `bin/`, `lib/`, and similar subdirectories.",
                safetyNote: "Entirely generated output; `zig build install` recreates it.",
                regenCommand: "zig build install",
                links: [
                    InfoLink(title: "Zig — build system", url: "https://ziglang.org/learn/build-system/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "zig.global-cache", displayName: "Zig global cache",
            ecosystem: .otherLangs, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/zig"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Zig global package and compilation cache.",
            iconAsset: "zig", brandTint: zigOrange,
            item: ItemInfo(
                description: "`~/.cache/zig/` is Zig's global cache shared across all projects. It stores downloaded package tarballs fetched via `zig fetch` and globally cached compilation artifacts, enabling packages declared in `build.zig.zon` to be reused without re-downloading.",
                safetyNote: "Zig re-downloads and recompiles cached packages on the next build; first rebuild may be slower.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Zig — build system", url: "https://ziglang.org/learn/build-system/", kind: .docs),
                ]
            )
        ),
        // D
        Rule(
            id: "d.dub-build", displayName: ".dub/ (D)",
            ecosystem: .otherLangs, scope: .projectLocal,
            matcher: .marker(directoryName: ".dub",
                             requiredMarkers: ["dub.json", "dub.sdl"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "DUB per-project build cache.",
            iconAsset: "dlang", brandTint: dlangRed,
            item: ItemInfo(
                description: "`.dub/` is DUB's per-project build cache, holding compiled object files, generated code, and incremental build state for the current D project.",
                safetyNote: "DUB recreates it on the next `dub build`.",
                regenCommand: "dub build",
                links: [
                    InfoLink(title: "DUB — building", url: "https://dub.pm/dub-guide/building/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "d.dub-global", displayName: "Dub package cache",
            ecosystem: .otherLangs, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".dub"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "DUB global package cache.",
            iconAsset: "dlang", brandTint: dlangRed,
            item: ItemInfo(
                description: "`~/.dub/` is DUB's global cache directory, storing downloaded package sources from the DUB registry (code.dlang.org) and precompiled library artifacts shared across projects. Package sources live under `~/.dub/packages/`.",
                safetyNote: "DUB re-downloads and rebuilds required packages from the registry on the next `dub build`.",
                regenCommand: "dub build",
                links: [
                    InfoLink(title: "DUB — dependencies", url: "https://dub.pm/dub-reference/dependencies/", kind: .docs),
                ]
            )
        ),
        // Crystal
        Rule(
            id: "crystal.lib", displayName: "lib/ (Crystal)",
            ecosystem: .otherLangs, scope: .projectLocal,
            matcher: .marker(directoryName: "lib",
                             requiredMarkers: ["shard.yml", "shard.lock"],
                             forbiddenMarkers: ["package.json", "Cargo.toml", "go.mod", "*.csproj", "pom.xml"]),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Shards dependency source directory.",
            iconAsset: "crystal", brandTint: crystalBlack,
            item: ItemInfo(
                description: "`lib/` is Shards' project-local dependency directory. `shards install` resolves the dependency graph from `shard.yml`, locks versions in `shard.lock`, and clones or copies each shard's source into `lib/<shard-name>/`.",
                safetyNote: "`shards install` recreates the directory from `shard.lock` with exact pinned versions.",
                regenCommand: "shards install",
                links: [
                    InfoLink(title: "Shards — Crystal dependency manager", url: "https://crystal-lang.org/reference/1.16/man/shards/index.html", kind: .docs),
                ]
            )
        ),
        // Nim
        Rule(
            id: "nim.nimcache", displayName: "nimcache/",
            ecosystem: .otherLangs, scope: .projectLocal,
            matcher: .marker(directoryName: "nimcache",
                             requiredMarkers: ["*.nim", "*.nimble", "nim.cfg"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Nim generated C sources and object files.",
            iconAsset: "nim", brandTint: nimYellow,
            item: ItemInfo(
                description: "`nimcache/` holds the C source files and compiled object files Nim generates as an intermediate compilation step. Nim transpiles to C by default; the generated C files here are compiled by the system C compiler to produce the final binary.",
                safetyNote: "Nim regenerates the C sources and objects from `.nim` sources on the next compilation.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Nim compiler user guide", url: "https://nim-lang.org/docs/nimc.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "nim.choosenim", displayName: "choosenim Nim version",
            ecosystem: .otherLangs, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".choosenim/toolchains"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "choosenim-installed Nim toolchain.",
            iconAsset: "nim", brandTint: nimYellow,
            item: ItemInfo(
                description: "`~/.choosenim/toolchains/` stores each Nim toolchain installed by choosenim, the Nim version manager. Each subdirectory (e.g. `nim-2.0.0/`) is a self-contained installation with the `nim` compiler, `nimble` package manager, and standard library.",
                safetyNote: "Deleting a version removes that Nim compiler — reinstall with `choosenim <version>` before using projects that depend on it.",
                regenCommand: "choosenim <version>",
                links: [
                    InfoLink(title: "choosenim — GitHub", url: "https://github.com/dom96/choosenim", kind: .official),
                ]
            )
        ),
        // OCaml
        Rule(
            id: "ocaml.build", displayName: "_build/ (Dune)",
            ecosystem: .otherLangs, scope: .projectLocal,
            matcher: .marker(directoryName: "_build",
                             requiredMarkers: ["dune-project", "*.opam"],
                             forbiddenMarkers: ["mix.exs", "rebar.config"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Dune OCaml build output directory.",
            iconAsset: "ocaml", brandTint: ocamlOrange,
            item: ItemInfo(
                description: "`_build/` is Dune's unified build directory for OCaml projects. Dune compiles all modules and places `.cmi`, `.cmx`, `.cmo` interface and object files, and linked executables here, including artifacts for all dependencies in the same workspace.",
                safetyNote: "`dune build` reconstructs the full output tree by recompiling all source files.",
                regenCommand: "dune build",
                links: [
                    InfoLink(title: "Dune — OCaml build system", url: "https://dune.build/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "ocaml.opam-local", displayName: "_opam/ (local switch)",
            ecosystem: .otherLangs, scope: .projectLocal,
            matcher: .marker(directoryName: "_opam",
                             requiredMarkers: ["dune-project", "*.opam"]),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "opam project-local switch.",
            iconAsset: "ocaml", brandTint: ocamlOrange,
            item: ItemInfo(
                description: "`_opam/` is a project-local opam switch created by `opam switch create .`. It is a self-contained OCaml installation with its own compiler version and package set, isolated from the global opam environment.",
                safetyNote: "Deleting removes the local switch and all installed packages; recreate with `opam switch create . --deps-only`.",
                regenCommand: "opam switch create . --deps-only",
                links: [
                    InfoLink(title: "opam — local switches", url: "https://opam.ocaml.org/doc/Manual.html#lt-switch-gt-package", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "ocaml.opam-download", displayName: "opam download cache",
            ecosystem: .otherLangs, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".opam/download-cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "opam package source tarball cache.",
            iconAsset: "ocaml", brandTint: ocamlOrange,
            item: ItemInfo(
                description: "`~/.opam/download-cache/` stores source tarballs downloaded by opam when installing packages. The cache is keyed by checksum, so re-installing a package or using the same version across switches avoids a redundant network download.",
                safetyNote: "opam re-downloads tarballs from upstream on the next install; installed switches are unaffected.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "opam — usage guide", url: "https://opam.ocaml.org/doc/Usage.html", kind: .docs),
                ]
            )
        ),
        // Julia
        Rule(
            id: "julia.compiled", displayName: "Julia compiled cache",
            ecosystem: .otherLangs, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".julia/compiled"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Julia precompiled package images.",
            iconAsset: "julia", brandTint: juliaPurple,
            item: ItemInfo(
                description: "`~/.julia/compiled/` stores precompiled package images (`.ji` files) that Julia generates the first time a package is loaded with `using`. These images reduce load times on subsequent sessions by skipping redundant compilation.",
                safetyNote: "Julia regenerates precompilation images the next time each package is loaded; first load will be slower.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Julia Pkg — Pkg.precompile", url: "https://pkgdocs.julialang.org/v1/api/#Pkg.precompile", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "julia.scratchspaces", displayName: "Julia scratchspaces",
            ecosystem: .otherLangs, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".julia/scratchspaces"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Julia Scratch.jl package scratch data.",
            iconAsset: "julia", brandTint: juliaPurple,
            item: ItemInfo(
                description: "`~/.julia/scratchspaces/` holds package-specific scratch data written via the `Scratch.jl` API — temporary files, build outputs, downloaded assets, and other package-managed data that does not belong in source trees. Each package occupies its own UUID-keyed subdirectory.",
                safetyNote: "Packages recreate scratch data on demand; no user-authored content is stored here.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Scratch.jl — GitHub", url: "https://github.com/JuliaPackaging/Scratch.jl", kind: .docs),
                ]
            )
        ),
        // R
        Rule(
            id: "r.renv-cache", displayName: "renv cache",
            ecosystem: .otherLangs, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/org.R-project.R/R/renv"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "renv global compiled R package cache.",
            iconAsset: "r", brandTint: rBlue,
            item: ItemInfo(
                description: "The renv global cache at `~/Library/Caches/org.R-project.R/R/renv` stores compiled R package binaries shared across all renv-managed projects. When a project calls `renv::restore()`, packages already in the global cache are linked directly rather than re-downloaded.",
                safetyNote: "renv re-downloads and installs packages from CRAN or Bioconductor on the next `renv::restore()`; packages requiring source compilation will be slow.",
                regenCommand: "renv::restore()",
                links: [
                    InfoLink(title: "renv — cache paths", url: "https://rstudio.github.io/renv/reference/paths.html", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - Static Site Generators (routed through language ecosystems)

    private static let ssg: [Rule] = [
        // Hugo (Go)
        Rule(
            id: "hugo.public", displayName: "public/ (Hugo)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "public",
                             requiredMarkers: ["hugo.toml", "hugo.yaml", "hugo.json"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Hugo rendered site output directory.",
            iconAsset: "hugo", brandTint: hugoPink,
            toolKey: "hugo",
            item: ItemInfo(
                description: "Hugo writes the fully rendered static site to `public/` when you run `hugo` or `hugo build`. The directory contains all HTML pages, processed assets, and copied static files. Hugo does not automatically clear it before each build, so stale files from renamed or deleted content may persist.",
                safetyNote: "Entirely generated output; safe to delete before every build for a clean result.",
                regenCommand: "hugo",
                links: [
                    InfoLink(title: "Hugo — basic usage", url: "https://gohugo.io/getting-started/usage/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "hugo.resources-gen", displayName: "resources/_gen/ (Hugo)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "resources",
                             requiredMarkers: ["hugo.toml", "hugo.yaml", "hugo.json"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Hugo image/asset processing cache.",
            iconAsset: "hugo", brandTint: hugoPink,
            toolKey: "hugo",
            item: ItemInfo(
                description: "Hugo caches the output of its asset pipeline — resized images, transpiled SCSS, and other processed resources — in `resources/_gen/`. This avoids reprocessing unchanged assets on every build.",
                safetyNote: "Fully reproducible; Hugo regenerates `resources/_gen/` from source assets on the next build.",
                regenCommand: "hugo",
                links: [
                    InfoLink(title: "Hugo — directory structure", url: "https://gohugo.io/getting-started/directory-structure/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "hugo.user-cache", displayName: "Hugo module cache",
            ecosystem: .ssg, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/hugo_cache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Downloaded Hugo modules + remote assets.",
            iconAsset: "hugo", brandTint: hugoPink,
            toolKey: "hugo",
            item: ItemInfo(
                description: "Hugo stores downloaded theme modules, remote data, and processed asset pipeline outputs in `~/Library/Caches/hugo_cache`. This cache speeds up builds that reference remote Hugo modules or CDN-hosted content.",
                safetyNote: "Deleting it causes Hugo to re-fetch modules and remote assets on the next build.",
                regenCommand: "hugo",
                links: [
                    InfoLink(title: "Hugo — configuration (cacheDir)", url: "https://gohugo.io/getting-started/configuration/", kind: .docs),
                ]
            )
        ),
        // Gatsby (Node)
        Rule(
            id: "gatsby.cache", displayName: ".cache/ (Gatsby)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: ".cache",
                             requiredMarkers: ["gatsby-config.js", "gatsby-config.ts", "gatsby-node.js", "gatsby-node.ts"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Gatsby incremental build cache.",
            iconAsset: "gatsby", brandTint: gatsbyPurple,
            languageKey: "javascript",
            toolKey: "gatsby",
            item: ItemInfo(
                description: "Gatsby stores incremental build outputs, processed images, GraphQL query results, and webpack bundles in `.cache/`. It is used alongside `public/` to enable fast rebuilds without reprocessing unchanged content.",
                safetyNote: "Regenerated automatically on the next build; `gatsby clean` removes both `.cache/` and `public/` for a full cold start.",
                regenCommand: "gatsby build",
                links: [
                    InfoLink(title: "Gatsby — build caching", url: "https://www.gatsbyjs.com/docs/build-caching/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "gatsby.public", displayName: "public/ (Gatsby)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "public",
                             requiredMarkers: ["gatsby-config.js", "gatsby-config.ts"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Gatsby rendered site output directory.",
            iconAsset: "gatsby", brandTint: gatsbyPurple,
            languageKey: "javascript",
            toolKey: "gatsby",
            item: ItemInfo(
                description: "Gatsby writes the final static site — HTML pages, JavaScript bundles, CSS, and optimised images — to `public/` during `gatsby build`. This directory is what gets deployed to a CDN or static host.",
                safetyNote: "Entirely generated output; safe to delete at any time and rebuilt by `gatsby build`.",
                regenCommand: "gatsby build",
                links: [
                    InfoLink(title: "Gatsby — build caching", url: "https://www.gatsbyjs.com/docs/build-caching/", kind: .docs),
                ]
            )
        ),
        // Docusaurus (Node)
        Rule(
            id: "docusaurus.build", displayName: "build/ (Docusaurus)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "build",
                             requiredMarkers: ["docusaurus.config.js", "docusaurus.config.ts", "docusaurus.config.mjs"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Docusaurus build output.",
            iconAsset: "docusaurus", brandTint: docusaurusGreen,
            languageKey: "javascript",
            toolKey: "docusaurus",
            item: ItemInfo(
                description: "Docusaurus writes the compiled static site to `build/` during `docusaurus build`. The directory contains the full HTML, JavaScript, CSS, and asset output ready for deployment.",
                safetyNote: "Entirely generated output; `docusaurus build` recreates it from source.",
                regenCommand: "docusaurus build",
                links: [
                    InfoLink(title: "Docusaurus — CLI", url: "https://docusaurus.io/docs/cli", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "docusaurus.cache", displayName: ".docusaurus/",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: ".docusaurus",
                             requiredMarkers: nodeLockfiles),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Docusaurus incremental cache.",
            iconAsset: "docusaurus", brandTint: docusaurusGreen,
            languageKey: "javascript",
            toolKey: "docusaurus",
            item: ItemInfo(
                description: "Docusaurus stores generated route manifests, plugin state, and incremental build metadata in `.docusaurus/`. The `docusaurus clear` command removes this directory along with any other generated assets.",
                safetyNote: "Regenerated automatically on the next `docusaurus start` or `docusaurus build`.",
                regenCommand: "docusaurus build",
                links: [
                    InfoLink(title: "Docusaurus — CLI", url: "https://docusaurus.io/docs/cli", kind: .docs),
                ]
            )
        ),
        // MkDocs (Python)
        Rule(
            id: "mkdocs.site", displayName: "site/ (MkDocs)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "site",
                             requiredMarkers: ["mkdocs.yml", "mkdocs.yaml"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "MkDocs rendered documentation output directory.",
            iconAsset: "mkdocs", brandTint: mkdocsBlue,
            languageKey: "python",
            toolKey: "mkdocs",
            item: ItemInfo(
                description: "MkDocs generates a complete static documentation site in `site/` when you run `mkdocs build`. The directory contains HTML pages, a search index, theme assets, and any static files copied from the docs source. The output path is controlled by the `site_dir` key in `mkdocs.yml` (default: `site`).",
                safetyNote: "Entirely generated output; safe to delete and rebuilt from `mkdocs.yml` and the `docs/` directory.",
                regenCommand: "mkdocs build",
                links: [
                    InfoLink(title: "MkDocs — deploying your docs", url: "https://www.mkdocs.org/user-guide/deploying-your-docs/", kind: .docs),
                ]
            )
        ),
        // Pelican (Python)
        Rule(
            id: "pelican.output", displayName: "output/ (Pelican)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "output",
                             requiredMarkers: ["pelicanconf.py", "publishconf.py"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Pelican rendered site output directory.",
            iconAsset: "python", brandTint: Color(red: 0x19/255, green: 0xA4/255, blue: 0xE7/255),
            languageKey: "python",
            toolKey: "pelican",
            item: ItemInfo(
                description: "Pelican writes the fully generated static site to `output/` when you run `pelican content`. The directory contains rendered HTML pages, Atom/RSS feeds, and copied static assets from the `content/` and `static/` directories.",
                safetyNote: "Entirely generated output; `pelican content` recreates it from source Markdown and reStructuredText files.",
                regenCommand: "pelican content",
                links: []
            )
        ),
        // Zola (Rust)
        Rule(
            id: "zola.public", displayName: "public/ (Zola)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "public",
                             requiredMarkers: ["config.toml"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Zola rendered site output directory.",
            iconAsset: "zola", brandTint: zolaBlue,
            toolKey: "zola",
            item: ItemInfo(
                description: "Zola writes all rendered HTML pages, processed SCSS, images, and other assets to `public/` when you run `zola build`. The directory is completely overwritten on each build.",
                safetyNote: "Entirely generated output; `zola build` recreates the directory from Markdown content and Tera templates.",
                regenCommand: "zola build",
                links: [
                    InfoLink(title: "Zola — CLI usage", url: "https://www.getzola.org/documentation/getting-started/cli-usage/", kind: .docs),
                ]
            )
        ),
        // Eleventy (Node)
        Rule(
            id: "eleventy.site", displayName: "_site/ (Eleventy)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "_site",
                             requiredMarkers: [".eleventy.js", "eleventy.config.js", "eleventy.config.cjs", "eleventy.config.mjs"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Eleventy rendered site output directory.",
            iconAsset: "eleventy", brandTint: Color(red: 0x22/255, green: 0x22/255, blue: 0x22/255),
            languageKey: "javascript",
            toolKey: "eleventy",
            item: ItemInfo(
                description: "Eleventy (11ty) outputs the fully rendered static site to `_site/` by default. It compiles Markdown, Nunjucks, Liquid, HTML, and other template formats into plain HTML pages alongside copied static assets. The output directory is configurable via `dir.output` in the Eleventy config.",
                safetyNote: "Entirely generated output; `npx @11ty/eleventy` recreates the directory from source templates and content.",
                regenCommand: "npx @11ty/eleventy",
                links: [
                    InfoLink(title: "Eleventy — output directory", url: "https://www.11ty.dev/docs/config/#output-directory", kind: .docs),
                ]
            )
        ),
        // Hexo (Node)
        Rule(
            id: "hexo.public", displayName: "public/ (Hexo)",
            ecosystem: .ssg, scope: .projectLocal,
            matcher: .marker(directoryName: "public",
                             requiredMarkers: ["_config.yml"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Hexo rendered site output directory.",
            iconAsset: "hexo", brandTint: Color(red: 0x0E/255, green: 0x83/255, blue: 0xCD/255),
            languageKey: "javascript",
            toolKey: "hexo",
            item: ItemInfo(
                description: "Hexo generates a static blog site into `public/` when you run `hexo generate`. The directory contains rendered HTML posts and pages, theme assets, feed files, and a sitemap — everything needed to deploy the blog to a static host.",
                safetyNote: "Entirely generated output; `hexo generate` recreates the directory from Markdown posts and theme templates.",
                regenCommand: "hexo generate",
                links: [
                    InfoLink(title: "Hexo — generating", url: "https://hexo.io/docs/generating", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - AI / ML / Image-gen

    private static let ai: [Rule] = [
        // LLM runtimes
        Rule(
            id: "ollama.models", displayName: "Ollama model",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".ollama/models/manifests/registry.ollama.ai/library"),
            action: .cleanCommand(.ollamaRm), tier: .high, aggregation: .none,
            notes: "Ollama local LLM weight store.",
            iconAsset: "ollama", brandTint: ollamaWhite,
            toolKey: "ollama",
            item: ItemInfo(
                description: "Ollama stores downloaded LLM weights under `~/.ollama/models/`. Each model family ranges from around 1 GB for small 1B-parameter models to over 400 GB for large dense models such as Llama 3.1 405B. Blobs are content-addressed and shared between tags; running `ollama rm` correctly decrements the reference count rather than leaving orphaned blob files.",
                safetyNote: "Re-downloading large models can take hours; run `ollama pull <model>` to restore a removed model.",
                regenCommand: "ollama pull <model>",
                links: [
                    InfoLink(title: "Ollama — model library", url: "https://ollama.com/library", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "ollama.logs", displayName: "Ollama logs",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".ollama/logs"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Ollama diagnostic log files.",
            iconAsset: "ollama", brandTint: ollamaWhite,
            toolKey: "ollama",
            item: ItemInfo(
                description: "Ollama writes diagnostic and request logs to `~/.ollama/logs/`. Log files accumulate over time but are typically only a few megabytes even after extended use.",
                safetyNote: "Log files are diagnostic only; deleting them has no effect on installed models or Ollama's operation.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "lmstudio.models", displayName: "LM Studio model",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathGrandchildren(relativeToHome: ".lmstudio/models"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "LM Studio downloaded GGUF model files.",
            iconAsset: "lmstudio",
            brandTint: Color(red: 0x4A/255, green: 0x6F/255, blue: 0xDC/255),
            toolKey: "lmstudio",
            item: ItemInfo(
                description: "LM Studio stores downloaded GGUF model files under `~/.lmstudio/models/<publisher>/<model>/`. Individual GGUF files range from around 3 GB for small quantised models to 40 GB or more for full-precision large models. Models are sourced from Hugging Face mirrors and can be browsed directly within the LM Studio app.",
                safetyNote: "Re-downloading large GGUF models can take hours; use the LM Studio app or Hugging Face to re-fetch any removed model.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "jan.models", displayName: "Jan models",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "jan/models"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Jan local AI app downloaded model files.",
            iconAsset: "", brandTint: Color(red: 0x0B/255, green: 0x6E/255, blue: 0xF2/255),
            item: ItemInfo(
                description: "Jan is a local AI chat app that stores downloaded model files under `~/jan/models/`. Each model directory contains the GGUF weights and metadata; individual models range from 1 GB to over 70 GB depending on the architecture and quantisation level.",
                safetyNote: "Re-downloading large models can take hours; use Jan's built-in Hub browser to reinstall any removed model.",
                regenCommand: nil,
                links: []
            )
        ),
        // HuggingFace
        Rule(
            id: "hf.hub", displayName: "HuggingFace Hub repo",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".cache/huggingface/hub"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Hugging Face Hub content-addressed repo cache.",
            iconAsset: "huggingface", brandTint: hfYellow,
            toolKey: "huggingface",
            item: ItemInfo(
                description: "The Hugging Face Hub Python library caches downloaded models, datasets, and spaces under `~/.cache/huggingface/hub/`. Each repository is stored as a content-addressed tree of blobs with symbolic-link snapshots, enabling multiple revisions to share unchanged files. Heavy ML users can accumulate hundreds of gigabytes across large language models, image-generation checkpoints, and training datasets.",
                safetyNote: "Re-downloading large models can take hours on slow connections; use `huggingface-cli delete-cache` or the Python API to selectively remove only unneeded revisions.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "HuggingFace — manage cache", url: "https://huggingface.co/docs/huggingface_hub/guides/manage-cache", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "hf.xet", displayName: "HuggingFace Xet cache",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/huggingface/xet"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Hugging Face Xet chunk-level deduplication cache.",
            iconAsset: "huggingface", brandTint: hfYellow,
            toolKey: "huggingface",
            item: ItemInfo(
                description: "The Hugging Face Xet storage layer adds a chunk-level deduplication cache at `~/.cache/huggingface/xet/`. It stores 64 KB content-addressed data chunks and shard index files that speed up both downloads and uploads of Xet-enabled repositories. The chunk cache is capped at 10 GB and the shard cache at 4 GB.",
                safetyNote: "The Xet cache is a pure optimisation layer; deleting it does not remove any cached model files and `huggingface_hub` will rebuild it transparently on subsequent access.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "HuggingFace — manage cache", url: "https://huggingface.co/docs/huggingface_hub/guides/manage-cache", kind: .docs),
                ]
            )
        ),
        // ML frameworks
        Rule(
            id: "torch.hub", displayName: "PyTorch checkpoint",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".cache/torch/hub/checkpoints"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "PyTorch Hub downloaded pretrained weight checkpoints.",
            iconAsset: "pytorch", brandTint: pytorchOrange,
            languageKey: "python",
            toolKey: "pytorch",
            item: ItemInfo(
                description: "PyTorch Hub downloads pretrained model weights to `~/.cache/torch/hub/checkpoints/` when code calls `torch.hub.load()` or `torchvision.models.*()`. Checkpoints range from around 100 MB for lightweight vision models to 5 GB or more for large transformer architectures. The directory also stores weights fetched via `torch.hub.download_url_to_file()`.",
                safetyNote: "Re-downloading checkpoints requires an internet connection; large checkpoints can take tens of minutes on slow connections.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "PyTorch Hub — documentation", url: "https://docs.pytorch.org/docs/stable/hub.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "tf.datasets", displayName: "TensorFlow dataset",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "tensorflow_datasets"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "TensorFlow Datasets downloaded and prepared dataset shards.",
            iconAsset: "tensorflow", brandTint: tfOrange,
            languageKey: "python",
            toolKey: "tensorflow",
            item: ItemInfo(
                description: "TensorFlow Datasets (TFDS) downloads and prepares datasets to `~/tensorflow_datasets/` via `tfds.load()`. Datasets are stored as sharded TFRecord files alongside metadata; large datasets such as ImageNet can exceed 150 GB. TFDS supports over 1,000 ready-to-use datasets for training and evaluation.",
                safetyNote: "Re-downloading and re-preparing large datasets can take many hours; only delete datasets you no longer need for active projects.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "TensorFlow Datasets — overview", url: "https://www.tensorflow.org/datasets/overview", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "keras.models", displayName: "Keras model",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".keras/models"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Keras built-in application pretrained weight files.",
            iconAsset: "keras", brandTint: kerasRed,
            languageKey: "python",
            toolKey: "keras",
            item: ItemInfo(
                description: "Keras caches the pretrained weights of built-in application models (ResNet, EfficientNet, MobileNet, VGG, and others) under `~/.keras/models/`. These weights are downloaded automatically the first time a model is instantiated with `weights='imagenet'` or similar. Individual weight files range from around 50 MB to 1 GB.",
                safetyNote: "Weights are re-downloaded automatically on the next call to `keras.applications.*()` with pretrained weights; an internet connection is required.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Keras — applications", url: "https://keras.io/api/applications/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "fastai.data", displayName: "fastai data",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".fastai/data"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "fastai downloaded benchmark datasets and pretrained weights.",
            iconAsset: "", brandTint: Color(red: 0x4A/255, green: 0xA7/255, blue: 0xC9/255),
            languageKey: "python",
            item: ItemInfo(
                description: "fastai downloads training datasets and pretrained model weights to `~/.fastai/data/`. Convenience functions such as `untar_data()` fetch standard benchmark datasets (ImageNette, MNIST, IMDB, etc.) and cache them here so subsequent runs can skip the download. Individual datasets vary from tens of MB to several GB.",
                safetyNote: "Deleted datasets are re-downloaded automatically on the next `untar_data()` call; an internet connection is required.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "fastai — external data", url: "https://docs.fast.ai/data.external.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "mlx.cache", displayName: "MLX cache",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/mlx"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Apple MLX kernels/compilation cache.",
            iconAsset: "", brandTint: Color(red: 0x00/255, green: 0x00/255, blue: 0x00/255),
            item: ItemInfo(
                description: "Apple MLX stores compiled Metal kernel binaries and other compilation artefacts in `~/Library/Caches/mlx/`. MLX is Apple's array framework for machine learning on Apple Silicon; it compiles operations on first use and caches the result to avoid recompilation on subsequent runs.",
                safetyNote: "The cache is fully reproducible; MLX recompiles and repopulates it automatically on next use.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "ultralytics.weights", displayName: "Ultralytics YOLO weight",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".config/Ultralytics"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Ultralytics YOLO auto-downloaded pretrained weight files.",
            iconAsset: "ultralytics",
            brandTint: Color(red: 0x04/255, green: 0x2A/255, blue: 0xFF/255),
            languageKey: "python",
            toolKey: "ultralytics",
            item: ItemInfo(
                description: "Ultralytics YOLO automatically downloads pretrained model weights to `~/.config/Ultralytics/` on first use. Weight files span nano to extra-large model sizes, ranging from around 6 MB (YOLOv8n) to 150 MB (YOLOv8x). The directory also stores settings and usage telemetry.",
                safetyNote: "Weights are re-downloaded automatically when the model is next loaded; an internet connection is required.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "invokeai.models", displayName: "InvokeAI model",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "invokeai/models"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "InvokeAI image-generation model checkpoint store.",
            iconAsset: "invokeai",
            brandTint: Color(red: 0x0C/255, green: 0xB0/255, blue: 0xA9/255),
            toolKey: "invokeai",
            item: ItemInfo(
                description: "InvokeAI stores Stable Diffusion and other image-generation model checkpoints under `~/invokeai/models/`. Each checkpoint file is typically 2–7 GB for standard Stable Diffusion variants, with larger FLUX and SDXL models reaching 10–20 GB. Models can be installed via the InvokeAI web UI or by placing checkpoint files directly into the directory.",
                safetyNote: "Re-downloading large model checkpoints can take hours; reinstall via the InvokeAI model manager or Hugging Face.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "diffusionbee.models", displayName: "DiffusionBee models",
            ecosystem: .ai, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".diffusionbee"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "DiffusionBee Stable Diffusion model store.",
            iconAsset: "", brandTint: Color(red: 0xFF/255, green: 0x6B/255, blue: 0x6B/255),
            item: ItemInfo(
                description: "DiffusionBee is a macOS-native Stable Diffusion app that stores downloaded model checkpoints and app data under `~/.diffusionbee/`. Standard SD 1.5 models are around 2 GB; SDXL and specialised fine-tuned models can reach 6–7 GB each. The directory also contains generated images if the default output path has not been changed.",
                safetyNote: "Deleting `~/.diffusionbee/` removes all downloaded models and may remove locally generated images; re-download models from within the DiffusionBee app.",
                regenCommand: nil,
                links: []
            )
        ),
        // Browser-automation runners — they live in their own .browserAutomation
        // bucket. Kept physically here because they share the same "heavy
        // browser binary download under ~/Library/Caches" pattern as the AI
        // model rules above; the ecosystem tag is what drives the UI grouping.
        Rule(
            id: "playwright.browsers", displayName: "Playwright browsers",
            ecosystem: .browserAutomation, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Caches/ms-playwright"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Playwright versioned browser runtime binaries.",
            iconAsset: "playwright", brandTint: playwrightGreen,
            languageKey: "javascript",
            toolKey: "playwright",
            item: ItemInfo(
                description: "Playwright downloads versioned browser binaries — Chromium, Firefox, and WebKit — to `~/Library/Caches/ms-playwright/` so test runs are hermetically isolated from system browsers. Each browser binary is around 500 MB to 1 GB, and multiple versions accumulate as Playwright is updated.",
                safetyNote: "Deleted binaries are restored by running `npx playwright install` or `playwright install`; the command only downloads the browsers required by the current Playwright version.",
                regenCommand: "npx playwright install",
                links: [
                    InfoLink(title: "Playwright — browsers", url: "https://playwright.dev/docs/browsers", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "cypress.binary", displayName: "Cypress binary",
            ecosystem: .browserAutomation, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Caches/Cypress"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Cypress bundled Electron browser binary cache.",
            iconAsset: "cypress",
            brandTint: Color(red: 0x17/255, green: 0x20/255, blue: 0x2C/255),
            languageKey: "javascript",
            toolKey: "cypress",
            item: ItemInfo(
                description: "Cypress downloads its bundled Electron-based browser binary to `~/Library/Caches/Cypress/` during installation, separate from the npm package itself. Each Cypress major version ships its own binary of around 500 MB; multiple versions accumulate if projects pin different Cypress versions.",
                safetyNote: "The binary is restored by running `cypress install` or by re-running `npm install` in a project that depends on Cypress.",
                regenCommand: "npx cypress install",
                links: [
                    InfoLink(title: "Cypress — installation", url: "https://docs.cypress.io/app/get-started/install-cypress", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "puppeteer.browsers", displayName: "Puppeteer browser",
            ecosystem: .browserAutomation, scope: .globalCache,
            matcher: .fixedPathGrandchildren(relativeToHome: ".cache/puppeteer"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Puppeteer downloaded browser binary.",
            iconAsset: "puppeteer",
            brandTint: Color(red: 0x00/255, green: 0xD3/255, blue: 0xB0/255),
            languageKey: "javascript",
            toolKey: "puppeteer",
            item: ItemInfo(
                description: "A single downloaded browser binary under `~/.cache/puppeteer/<browser>/<build>/` — typically Chrome, Firefox, or chrome-headless-shell. Puppeteer fetches a pinned revision during `npm install` so headless automation runs against a known-good build; older revisions linger as Puppeteer is upgraded.",
                safetyNote: "Re-downloaded on the next `npm install` in a project that depends on Puppeteer, or via `npx puppeteer browsers install`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Puppeteer — browsers management", url: "https://pptr.dev/guides/browsers-management", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "selenium.manager-cache", displayName: "Selenium Manager Cache",
            ecosystem: .browserAutomation, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/selenium"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Selenium Manager-downloaded driver/browser binaries.",
            iconAsset: "selenium",
            brandTint: Color(red: 0x43/255, green: 0xB0/255, blue: 0x2A/255),  // Selenium green
            toolKey: "selenium",
            item: ItemInfo(
                description: "`~/.cache/selenium/` is Selenium Manager's cache of automatically-downloaded driver and browser binaries — chromedriver, geckodriver, edgedriver, and matched browser builds. Selenium Manager handles the version-pinning so users don't have to.",
                safetyNote: "Re-downloaded on the next test run when Selenium Manager resolves the required driver version.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Selenium Manager", url: "https://www.selenium.dev/documentation/selenium_manager/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "webdrivermanager.cache", displayName: "webdriver-manager Cache",
            ecosystem: .browserAutomation, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".wdm"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Python webdriver-manager driver cache.",
            sfSymbol: "rectangle.connected.to.line.below",
            brandTint: Color(red: 0x43/255, green: 0xB0/255, blue: 0x2A/255),
            toolKey: "webdriver-manager",
            item: ItemInfo(
                description: "`~/.wdm/` is the cache used by Python's webdriver-manager package — pinned chromedriver/geckodriver/edgedriver binaries and version metadata. Sibling Node `webdriver-manager` writes to `~/.cache/webdriver/`.",
                safetyNote: "Re-downloaded by webdriver-manager on the next test run.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "webdriver-manager (Python)", url: "https://pypi.org/project/webdriver-manager/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "electron.binaries", displayName: "Electron binaries",
            ecosystem: .node, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/electron"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Cached Electron runtime binaries shared across projects.",
            iconAsset: "electron",
            brandTint: Color(red: 0x47/255, green: 0x84/255, blue: 0x8F/255),
            languageKey: "javascript",
            toolKey: "electron",
            item: ItemInfo(
                description: "When a project installs `electron` via npm, the postinstall script downloads the Electron runtime binary to `~/Library/Caches/electron/`. The download is shared across projects using the same Electron version, so the cache avoids redundant downloads. Each Electron release is around 100–200 MB.",
                safetyNote: "The binary is re-downloaded by the postinstall script when `npm install` is next run in a project that depends on Electron.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Electron — installation", url: "https://www.electronjs.org/docs/latest/tutorial/installation", kind: .docs),
                ]
            )
        ),
    ]

    // MARK: - VMs & Containers (aggregate-only — deletion routed through vendor CLI)

    private static let vm: [Rule] = [
        Rule(
            id: "docker.desktop-raw", displayName: "Docker Desktop disk image",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Docker Desktop's sparse VM disk — contains ALL images, containers, and volumes.",
            iconAsset: "docker", brandTint: dockerBlue,
            toolKey: "docker",
            item: ItemInfo(
                description: "`Docker.raw` is a sparse disk image that Docker Desktop uses as the entire storage backend for its Linux VM. All pulled images, running and stopped containers, named volumes, and build cache live inside this single file, which grows as data is added but does not automatically shrink when data is removed.",
                safetyNote: "Deleting `Docker.raw` permanently destroys all images, containers, and volumes — use `docker system prune -a --volumes` for targeted cleanup instead.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Docker — docker system prune", url: "https://docs.docker.com/reference/cli/docker/system/prune/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "tart.vms", displayName: "Tart VM",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".tart/vms"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Tart VM bundles — macOS/Linux disk images, 30–80 GB each.",
            iconAsset: "", brandTint: Color(red: 0x10/255, green: 0x10/255, blue: 0x10/255),
            item: ItemInfo(
                description: "`~/.tart/vms/` stores macOS and Linux virtual machine bundles used by Tart, a virtualization tool for Apple Silicon built on Apple's Virtualization.framework. Each bundle contains a disk image and a configuration file; macOS VMs typically occupy 30–80 GB.",
                safetyNote: "Deleting a VM bundle permanently destroys its disk state — use `tart delete <name>` via the CLI instead, or re-pull with `tart pull <name>`.",
                regenCommand: "tart pull <name>",
                links: [
                    InfoLink(title: "Tart — quick start", url: "https://tart.run/quick-start/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "tart.oci-cache", displayName: "Tart OCI cache",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".tart/cache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Tart OCI layer cache for pulled VM images.",
            iconAsset: "", brandTint: Color(red: 0x10/255, green: 0x10/255, blue: 0x10/255),
            item: ItemInfo(
                description: "`~/.tart/cache/` stores compressed OCI image layers downloaded by `tart pull`. The cache speeds up repeated pulls of the same image from a registry and grows as more VM images are fetched.",
                safetyNote: "Installed VMs in `~/.tart/vms/` are not affected; only the layer cache used to speed up future pulls is removed.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Tart — GitHub", url: "https://github.com/cirruslabs/tart", kind: .official),
                ]
            )
        ),
        // OrbStack — single sparse disk image holding all containers, k8s, and Linux machines.
        Rule(
            id: "orbstack.data", displayName: "OrbStack data image",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Group Containers/HUAQ24HBR6.dev.orbstack/data/data.img.raw"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "OrbStack's sparse VM disk — contains ALL container images, volumes, k8s clusters, and Linux machines.",
            iconAsset: "orbstack", sfSymbol: "shippingbox.fill",
            brandTint: Color(red: 0xA0/255, green: 0x6C/255, blue: 0xDD/255),  // OrbStack sphere violet
            toolKey: "orbstack",
            item: ItemInfo(
                description: "`data.img.raw` is a sparse virtualization disk that OrbStack uses as the entire storage backend for its container runtime, Kubernetes clusters, and Linux machines. The file's apparent size can read as huge (multi-TB) because it is sparse — actual on-disk usage is what matters.",
                safetyNote: "Deleting `data.img.raw` permanently destroys every container image, volume, k8s cluster, and Linux machine. Prefer `docker system prune -a --volumes` and `orb delete <machine>` for targeted cleanup.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "OrbStack — Install / Uninstall", url: "https://docs.orbstack.dev/install", kind: .docs),
                ]
            )
        ),
        // Vagrant — downloaded box archives.
        Rule(
            id: "vagrant.boxes", displayName: "Vagrant boxes",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".vagrant.d/boxes"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Downloaded base box archives — each can be 200 MB to 5 GB.",
            iconAsset: "vagrant", sfSymbol: "shippingbox.fill",
            brandTint: Color(red: 0x14/255, green: 0x63/255, blue: 0xFF/255),
            toolKey: "vagrant",
            item: ItemInfo(
                description: "`~/.vagrant.d/boxes/<provider>/<name>/<version>/` stores downloaded base VM box archives that `vagrant up` clones to create per-project VMs. Each box is a complete OS image — typically 200 MB to 5 GB — and multiple versions accumulate as boxes are upgraded.",
                safetyNote: "Removing boxes does NOT destroy already-cloned per-project VMs. They are re-fetched the next time a project requests a missing version, or via `vagrant box add`.",
                regenCommand: "vagrant box prune",
                links: [
                    InfoLink(title: "Vagrant — box CLI", url: "https://developer.hashicorp.com/vagrant/docs/cli/box", kind: .docs),
                ]
            )
        ),
        // Vagrant — per-project provisioned VM state.
        Rule(
            id: "vagrant.machines", displayName: ".vagrant/ (Vagrant)",
            ecosystem: .vm, scope: .projectLocal,
            matcher: .marker(directoryName: ".vagrant", requiredMarkers: ["Vagrantfile"]),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Per-project Vagrant VM state — destroying it loses all in-VM data.",
            iconAsset: "vagrant", sfSymbol: "externaldrive.fill",
            brandTint: Color(red: 0x14/255, green: 0x63/255, blue: 0xFF/255),
            toolKey: "vagrant",
            item: ItemInfo(
                description: "`.vagrant/machines/<name>/<provider>/` holds the cloned VM disk, machine ID, and SSH key for each VM defined in this project's `Vagrantfile`. Deleting it destroys the running VM and everything installed inside it.",
                safetyNote: "`vagrant up` will re-provision a fresh VM from the `Vagrantfile`, but any files, packages, or state inside the old VM are gone forever. For a clean teardown that also removes the underlying provider VM, run `vagrant destroy` from the project directory before deleting.",
                regenCommand: "vagrant up",
                links: [
                    InfoLink(title: "Vagrant — destroy", url: "https://developer.hashicorp.com/vagrant/docs/cli/destroy", kind: .docs),
                ]
            )
        ),
        // VirtualBox — VM disk + config bundle directory.
        Rule(
            id: "virtualbox.vms", displayName: "VirtualBox VM",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "VirtualBox VMs"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Each VM directory contains its disk images and config — deletion is irreversible.",
            iconAsset: "virtualbox", sfSymbol: "externaldrive.fill",
            brandTint: Color(red: 0x18/255, green: 0x39/255, blue: 0x70/255),
            toolKey: "virtualbox",
            item: ItemInfo(
                description: "`~/VirtualBox VMs/<name>/` is a per-VM directory containing the `.vbox` config, `.vdi` / `.vmdk` disk images, snapshots, and logs. The disk image holds everything inside the VM — installed OS, files, configuration.",
                safetyNote: "Deleting the directory leaves a stale entry in VirtualBox's global registry (`~/Library/VirtualBox/VirtualBox.xml`). For a clean removal that also clears the registry, run `VBoxManage unregistervm <name> --delete`.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "VirtualBox — Manual", url: "https://www.virtualbox.org/manual/ch10.html", kind: .docs),
                ]
            )
        ),
        // UTM — VM bundles (popular QEMU/Apple-Virtualization frontend on Apple Silicon).
        Rule(
            id: "utm.vms", displayName: "UTM VM",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Containers/com.utmapp.UTM/Data/Documents"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "UTM `.utm` VM bundle — disk image and config in one self-contained package.",
            iconAsset: "utm", sfSymbol: "externaldrive.fill",
            brandTint: Color(red: 0x52/255, green: 0x2D/255, blue: 0xC4/255),
            toolKey: "utm",
            item: ItemInfo(
                description: "Each `.utm` bundle contains a VM's qcow2 disk(s), NVRAM/EFI variables, and `config.plist`. UTM stores these under its sandboxed Container directory; the bundle is fully self-contained.",
                safetyNote: "Sending the bundle to the Trash removes the VM permanently. UTM has no destructive CLI — recovering from the Trash is the only undo.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "UTM — documentation", url: "https://docs.getutm.app/", kind: .docs),
                ]
            )
        ),
        // VMware Fusion — VM bundles (now free for personal use).
        Rule(
            id: "vmware-fusion.vms", displayName: "VMware Fusion VM",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Virtual Machines"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "`.vmwarevm` bundle — full disk and snapshot state for a Fusion VM.",
            iconAsset: "vmware-fusion", sfSymbol: "externaldrive.fill",
            brandTint: Color(red: 0x60/255, green: 0x77/255, blue: 0x96/255),
            toolKey: "vmware-fusion",
            item: ItemInfo(
                description: "Each `.vmwarevm` bundle contains the VM's `.vmdk` disk(s), `.nvram`, `.vmx` config, and any snapshots. The default location for newer Fusion installs is `~/Virtual Machines/`; older or upgraded installs may use `~/Documents/Virtual Machines.localized/` instead.",
                safetyNote: "Trashing the bundle permanently deletes the VM. Fusion's library auto-removes stale entries on next launch.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "VMware Fusion — default VM file location", url: "https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/13-0/using-vmware-fusion/understanding-vmware-fusion/navigating-and-taking-action-using-the-vmware-fusion-interface/default-file-location-of-a-virtual-machine.html", kind: .docs),
                ]
            )
        ),
        // Parallels Desktop — VM bundles.
        Rule(
            id: "parallels.vms", displayName: "Parallels VM",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Parallels"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "`.pvm` (Linux/Windows) or `.macvm` (macOS guest) bundle — full disk and snapshot state.",
            iconAsset: "parallels", sfSymbol: "externaldrive.fill",
            brandTint: Color(red: 0xCC/255, green: 0x00/255, blue: 0x00/255),
            toolKey: "parallels",
            item: ItemInfo(
                description: "Each `.pvm` or `.macvm` bundle contains the guest's disk image, snapshots, NVRAM, and config. Parallels stores these in `~/Parallels/` for v12+; older versions and the App Store edition use different roots.",
                safetyNote: "Trashing the bundle permanently deletes the VM. Parallels Control Center auto-removes stale library entries on next launch.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Parallels — Locate VM on Mac (KB 117333)", url: "https://kb.parallels.com/117333", kind: .docs),
                ]
            )
        ),
        // Lima — Linux-on-Mac VM instances.
        Rule(
            id: "lima.instances", displayName: "Lima VM instance",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".lima"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Per-instance Lima VM — disk and runtime sockets.",
            iconAsset: "lima", sfSymbol: "externaldrive.fill",
            brandTint: Color(red: 0xF1/255, green: 0xC4/255, blue: 0x0F/255),
            toolKey: "lima",
            item: ItemInfo(
                description: "`~/.lima/<instance>/` holds the instance's `lima.yaml`, `disk` file, `cidata.iso`, and runtime sockets. The disk is recreated by `limactl start` from the YAML config, but data inside the VM is destroyed on delete.",
                safetyNote: "For a clean teardown that also stops the VM and removes its sockets, run `limactl delete <name>` before trashing the directory.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Lima — directory layout", url: "https://lima-vm.io/docs/dev/internals/", kind: .docs),
                ]
            )
        ),
        // Lima — base-image download cache.
        Rule(
            id: "lima.download-cache", displayName: "Lima download cache",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/lima/download"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Cached cloud-image downloads keyed by URL hash.",
            iconAsset: "lima", sfSymbol: "shippingbox.fill",
            brandTint: Color(red: 0xF1/255, green: 0xC4/255, blue: 0x0F/255),
            toolKey: "lima",
            item: ItemInfo(
                description: "`~/Library/Caches/lima/download/by-url-sha256/` stores downloaded cloud images (Ubuntu, Fedora, Alpine, etc.) keyed by their source URL hash. Lima reuses these across instances to avoid redundant downloads.",
                safetyNote: "Cached images are re-downloaded on the next `limactl start` for an instance that needs them.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Lima — directory layout", url: "https://lima-vm.io/docs/dev/internals/", kind: .docs),
                ]
            )
        ),
        // Colima — Lima-based container runtime.
        Rule(
            id: "colima.instances", displayName: "Colima instance",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".colima/_lima"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Colima profile VM — contains all OCI images, containers, and named volumes.",
            iconAsset: "colima", sfSymbol: "externaldrive.fill",
            brandTint: Color(red: 0x2B/255, green: 0xB3/255, blue: 0x67/255),
            toolKey: "colima",
            item: ItemInfo(
                description: "`~/.colima/_lima/<profile>/` holds the Lima-managed VM that backs Colima's container runtime. The VM's disk contains every pulled OCI image, every running and stopped container, and all named volumes.",
                safetyNote: "Deleting the directory destroys all container state. Prefer `colima delete [profile]` (or `colima delete --data` to wipe just the data disk on v0.9+) for a clean teardown.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Colima — README", url: "https://github.com/abiosoft/colima", kind: .official),
                ]
            )
        ),
        Rule(
            id: "docker.buildx-cache", displayName: "Docker BuildKit Cache",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".docker/buildx/cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "BuildKit local cache for `docker buildx build`.",
            iconAsset: "docker",
            toolKey: "docker",
            item: ItemInfo(
                description: "`~/.docker/buildx/cache` is BuildKit's local content-addressable cache for `docker buildx build` invocations using the default builder. Distinct from anything Docker Desktop's VM holds internally — this lives in the user's home and is reused across BuildKit-backed builds.",
                safetyNote: "Repopulated by the next build; only a perf hit while the cache rebuilds.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Docker Build — caching", url: "https://docs.docker.com/build/cache/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "docker.scout", displayName: "Docker Scout Cache",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".docker/scout"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Docker Scout vulnerability-scan cache.",
            iconAsset: "docker",
            toolKey: "docker",
            item: ItemInfo(
                description: "`~/.docker/scout` is Docker Scout's local cache of image vulnerability data. Grows with every image scanned by `docker scout cves` etc.",
                safetyNote: "Regenerated by the next scout scan.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Docker Scout", url: "https://docs.docker.com/scout/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "podman.machine", displayName: "Podman Machine Disks",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/share/containers/podman/machine/applehv"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Podman VM disk images (Apple Hypervisor backend).",
            iconAsset: "podman",
            toolKey: "podman",
            item: ItemInfo(
                description: "`~/.local/share/containers/podman/machine/applehv/` holds the disk images backing each Podman machine on the Apple Hypervisor backend. Each machine is multiple GB.",
                safetyNote: "`podman machine init` rebuilds the VM from scratch (re-downloads the base image, loses any container/image state held inside).",
                regenCommand: "podman machine init",
                links: [
                    InfoLink(title: "Podman — podman machine", url: "https://docs.podman.io/en/latest/markdown/podman-machine.1.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "rancher-desktop.vm", displayName: "Rancher Desktop VM",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/rancher-desktop"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Rancher Desktop VM disk + k3s state (5–20 GB).",
            iconAsset: "rancher",
            toolKey: "rancher-desktop",
            item: ItemInfo(
                description: "`~/Library/Application Support/rancher-desktop/` holds Rancher Desktop's VM disk image plus its embedded k3s/k8s state. Typically 5–20 GB.",
                safetyNote: "Reset via the app: Preferences → Reset Kubernetes / Reset Application. Loses any container or k8s state held inside.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Rancher Desktop", url: "https://rancherdesktop.io/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "minikube.machines", displayName: "minikube Machines",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".minikube/machines"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Per-profile VM disks + downloaded ISOs/images.",
            iconAsset: "minikube",
            toolKey: "minikube",
            item: ItemInfo(
                description: "`~/.minikube/machines/` holds per-profile VM disks for minikube clusters. The sibling `~/.minikube/cache/` keeps downloaded ISOs and k8s component images. Both can be 5–20 GB.",
                safetyNote: "`minikube delete --all` is the clean teardown; rebuilding pulls images and provisions a fresh VM.",
                regenCommand: "minikube delete --all && minikube start",
                links: [
                    InfoLink(title: "minikube", url: "https://minikube.sigs.k8s.io/docs/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "kind.cache", displayName: "kind Cache",
            ecosystem: .vm, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/share/kind"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "kind node-image cache (clusters live in Docker, not here).",
            iconAsset: "kind",
            toolKey: "kind",
            item: ItemInfo(
                description: "`~/.local/share/kind/` caches kind's node images. The actual cluster state lives inside Docker (not here), so removing this cache only forces a re-pull of the node image on the next `kind create cluster`.",
                safetyNote: "Re-pulled from the registry on the next cluster create.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "kind — kubernetes-sigs", url: "https://kind.sigs.k8s.io/", kind: .official),
                ]
            )
        ),
    ]

    // MARK: - AI Coding Agents (CLI / TUI / agentic dev assistants)

    private static let aiCodingAgents: [Rule] = [
        // Claude Code — full session transcripts. Irreversible if deleted.
        Rule(
            id: "claude-code.projects", displayName: "Claude Code transcripts",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".claude/projects"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Per-project Claude Code session transcripts — chat, tool calls, diffs.",
            iconAsset: "claude-code", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0xD9/255, green: 0x77/255, blue: 0x57/255),  // Anthropic terracotta
            toolKey: "claude-code",
            item: ItemInfo(
                description: "`~/.claude/projects/<encoded-cwd>/*.jsonl` contains the full session transcript for every Claude Code conversation: model messages, tool calls (including file reads and edits), and diffs. Sessions accumulate per working directory; heavy users can build up several gigabytes of history.",
                safetyNote: "Once deleted, transcripts are unrecoverable — `claude --resume` will no longer find them. Anthropic does not store these server-side.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Claude Code — overview", url: "https://platform.claude.com/docs/en/docs/agents/claude-code/overview", kind: .official),
                ]
            )
        ),
        // OpenAI Codex CLI — sessions and input history. Irreversible.
        Rule(
            id: "codex-cli.sessions", displayName: "Codex CLI sessions",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".codex/sessions"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Codex CLI session rollouts — resumable transcripts and tool calls.",
            iconAsset: "codex-cli", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x10/255, green: 0xA3/255, blue: 0x7F/255),  // OpenAI green
            toolKey: "codex-cli",
            item: ItemInfo(
                description: "`~/.codex/sessions/` stores JSONL session rollouts that the OpenAI Codex CLI uses to resume prior conversations and replay tool calls. The companion file `~/.codex/history.jsonl` records every prompt the user has typed.",
                safetyNote: "Rollouts and history are local-only — deletion is permanent and breaks `codex resume`. The `CODEX_HOME` env var can relocate this directory; if set, the rule does not apply.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "OpenAI Codex CLI", url: "https://developers.openai.com/codex/cli", kind: .official),
                ]
            )
        ),
        // OpenCode (sst) — session storage. XDG layout used on macOS.
        Rule(
            id: "opencode.storage", displayName: "OpenCode storage",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/share/opencode/storage"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "OpenCode per-project sessions, messages, and parts.",
            iconAsset: "opencode", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0xE2/255, green: 0x4D/255, blue: 0x1A/255),  // SST orange
            toolKey: "opencode",
            item: ItemInfo(
                description: "OpenCode (the SST project) stores session, message, and part records under `~/.local/share/opencode/storage/`, organised per-project. Even on macOS, OpenCode follows the XDG Base Directory layout used by its Linux build.",
                safetyNote: "Sessions are local-only — once deleted they cannot be restored. Auth credentials live in `~/.local/share/opencode/auth.json`, which this rule deliberately leaves untouched so you stay signed in.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "OpenCode", url: "https://opencode.ai/", kind: .official),
                    InfoLink(title: "OpenCode — GitHub", url: "https://github.com/sst/opencode", kind: .official),
                ]
            )
        ),
        // Gemini CLI — per-project chat sessions and checkpoints.
        Rule(
            id: "gemini-cli.tmp", displayName: "Gemini CLI sessions",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: ".gemini/tmp"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Per-project Gemini CLI chat sessions and file checkpoints.",
            iconAsset: "gemini-cli", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x42/255, green: 0x85/255, blue: 0xF4/255),  // Google blue
            toolKey: "gemini-cli",
            item: ItemInfo(
                description: "`~/.gemini/tmp/<project_hash>/chats/session-*.json` stores per-project chat history; `~/.gemini/tmp/<project_hash>/checkpoints/` stores file checkpoints captured before edits. Each working directory gets its own hashed subfolder.",
                safetyNote: "Chats are unrecoverable once deleted. Checkpoints are typically also recoverable from git, if the working directory is a git repo.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Gemini CLI — GitHub", url: "https://github.com/google-gemini/gemini-cli", kind: .official),
                ]
            )
        ),
        // Aider — per-project ctags + treesitter cache (regenerable).
        Rule(
            id: "aider.tags-cache", displayName: ".aider.tags.cache.v3/",
            ecosystem: .aiCodingAgent, scope: .projectLocal,
            matcher: .marker(directoryName: ".aider.tags.cache.v3", requiredMarkers: [".git"]),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Aider's repo-map ctags + treesitter cache — rebuilt on next run.",
            iconAsset: "aider", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0xF6/255, green: 0x82/255, blue: 0x1F/255),  // Aider orange
            toolKey: "aider",
            item: ItemInfo(
                description: "Aider scans the repo with ctags + treesitter to build a `repo map` for the LLM, caching results under `.aider.tags.cache.v3/` next to the project. On large repos this cache can run to hundreds of megabytes.",
                safetyNote: "The cache is rebuilt automatically on the next `aider` run in this project — typically under a minute. Chat history (`.aider.chat.history.md`) is a separate file and is left untouched by this rule.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Aider — repo map", url: "https://aider.chat/docs/repomap.html", kind: .docs),
                ]
            )
        ),
        // Continue — codebase embedding/index store. Multi-GB on large monorepos.
        Rule(
            id: "continue.index", displayName: "Continue index",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".continue/index"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Continue's per-workspace LanceDB embeddings, autocomplete cache, docs index.",
            iconAsset: "continue", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x6B/255, green: 0x46/255, blue: 0xFF/255),  // Continue purple
            toolKey: "continue",
            item: ItemInfo(
                description: "`~/.continue/index/` holds Continue's persistent state for codebase chat: a LanceDB vector store with embeddings, an autocomplete cache, and a docs SQLite index. On a large monorepo this directory can reach multi-gigabyte sizes.",
                safetyNote: "Re-indexed on the next workspace open — typically a few minutes per project, depending on size.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Continue — GitHub", url: "https://github.com/continuedev/continue", kind: .official),
                ]
            )
        ),
        // Continue — chat sessions. Irreversible.
        Rule(
            id: "continue.sessions", displayName: "Continue sessions",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".continue/sessions"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Continue chat session JSONs.",
            iconAsset: "continue", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x6B/255, green: 0x46/255, blue: 0xFF/255),
            toolKey: "continue",
            item: ItemInfo(
                description: "`~/.continue/sessions/` stores Continue's chat history as one JSON per session. Sessions persist across IDE restarts and accumulate over time.",
                safetyNote: "Deleted sessions cannot be restored — Continue stores chat locally only.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Continue — GitHub", url: "https://github.com/continuedev/continue", kind: .official),
                ]
            )
        ),
        // Continue — bundled Chromium / esbuild used for docs scraping.
        Rule(
            id: "continue.utils", displayName: "Continue utils",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".continue/.utils"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Bundled Chromium and esbuild used by the docs scraper.",
            iconAsset: "continue", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x6B/255, green: 0x46/255, blue: 0xFF/255),
            toolKey: "continue",
            item: ItemInfo(
                description: "`~/.continue/.utils/` caches helper binaries Continue downloads on demand: a Chromium snapshot for the docs scraper plus an esbuild binary. Together these run several hundred megabytes.",
                safetyNote: "Re-downloaded on the next docs-index run.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Continue — GitHub", url: "https://github.com/continuedev/continue", kind: .official),
                ]
            )
        ),
        // Cline — task transcripts.
        Rule(
            id: "cline.tasks", displayName: "Cline tasks",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cline/tasks"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Per-task Cline transcripts and tool outputs.",
            iconAsset: "cline", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x18/255, green: 0x18/255, blue: 0x18/255),
            toolKey: "cline",
            item: ItemInfo(
                description: "`~/.cline/tasks/` stores Cline's per-task history: messages, tool inputs and outputs, file diffs. Each task can run from several megabytes to gigabytes depending on length.",
                safetyNote: "Once deleted, task histories cannot be recovered. Cline's separate checkpoint store (shadow git worktrees, kept under VS Code's globalStorage) is not touched by this rule.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Cline — checkpoints", url: "https://docs.cline.bot/features/checkpoints", kind: .docs),
                ]
            )
        ),
        // Goose CLI — session transcripts.
        Rule(
            id: "goose.sessions", displayName: "Goose CLI sessions",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/share/goose/sessions"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Block Goose CLI per-session JSONL transcripts.",
            iconAsset: "goose", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x4F/255, green: 0x46/255, blue: 0xE5/255),  // Block indigo
            toolKey: "goose",
            item: ItemInfo(
                description: "`~/.local/share/goose/sessions/` stores Block's Goose CLI session transcripts as JSONL — one file per session. The companion config in `~/.config/goose/` is left untouched by this rule.",
                safetyNote: "Sessions are local-only and cannot be restored after deletion.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Goose — documentation", url: "https://block.github.io/goose/", kind: .official),
                ]
            )
        ),
        // Windsurf (Codeium) — completion indexes, models, daemon state.
        Rule(
            id: "windsurf.codeium", displayName: "Windsurf / Codeium state",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".codeium/windsurf"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Codeium daemon state, indexes, and completion models for Windsurf.",
            iconAsset: "windsurf", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0x14/255, green: 0xB1/255, blue: 0x9C/255),  // Codeium teal
            toolKey: "windsurf",
            item: ItemInfo(
                description: "`~/.codeium/windsurf/` is Windsurf's primary state directory: Codeium daemon state, codebase indexes, downloaded completion models, and per-project caches. Codeium's official uninstall instructions point users at this directory.",
                safetyNote: "Indexes and models are re-downloaded on next launch. Cascade chat history may live separately under `~/Library/Application Support/Windsurf/User/globalStorage/`; this rule does not touch that.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Windsurf — documentation", url: "https://docs.windsurf.com/", kind: .official),
                ]
            )
        ),
        // OpenHands — conversation history, sandbox state.
        Rule(
            id: "openhands.data", displayName: "OpenHands data",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".openhands"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "OpenHands conversation history, file_store, sandbox state.",
            iconAsset: "openhands", sfSymbol: "bubble.and.pencil",
            brandTint: Color(red: 0xFF/255, green: 0x6B/255, blue: 0xA1/255),
            toolKey: "openhands",
            item: ItemInfo(
                description: "`~/.openhands/` stores OpenHands conversation history, sandbox file mounts, and runtime state. Conversation history is irreversible; the sandbox file_store is recreated on next run.",
                safetyNote: "Pulled OpenHands runtime Docker images (`docker.all-hands.dev/all-hands-ai/runtime:*`) are not stored here — those live in Docker and would be cleared via the Docker rule.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "OpenHands — installation", url: "https://docs.openhands.dev/usage/installation", kind: .docs),
                ]
            )
        ),
        // Claude Code — shell-snapshot recordings (separate from session transcripts).
        Rule(
            id: "claude-code.shell-snapshots", displayName: "Claude Code Shell Snapshots",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".claude/shell-snapshots"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Recorded shell snapshots from Claude Code's terminal sessions.",
            iconAsset: "claude-code", sfSymbol: "terminal",
            brandTint: Color(red: 0xD9/255, green: 0x77/255, blue: 0x57/255),
            toolKey: "claude-code",
            item: ItemInfo(
                description: "`~/.claude/shell-snapshots/` holds recorded shell snapshots that Claude Code captures during terminal sessions for diagnostic and replay purposes. Distinct from `~/.claude/projects/` which holds the chat transcripts themselves.",
                safetyNote: "Recreated as new sessions run; snapshots are diagnostic-only and not needed for resuming a session.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Claude Code — overview", url: "https://platform.claude.com/docs/en/docs/agents/claude-code/overview", kind: .official),
                ]
            )
        ),
        // Claude Desktop — Electron app caches (separate from claude-code CLI).
        Rule(
            id: "claude-desktop.cache", displayName: "Claude Desktop Cache",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/com.anthropic.claudefordesktop"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Claude Desktop Electron HTTP/asset cache (Cache.db, fsCachedData).",
            iconAsset: "claude-code", sfSymbol: "bubble.left.and.bubble.right",
            brandTint: Color(red: 0xD9/255, green: 0x77/255, blue: 0x57/255),
            toolKey: "claude-desktop",
            item: ItemInfo(
                description: "`~/Library/Caches/com.anthropic.claudefordesktop/` is Claude Desktop's Electron-style HTTP and asset cache (`Cache.db`, `fsCachedData`).",
                safetyNote: "Refetched on demand; signin token lives in Keychain so the user stays signed in.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "claude-desktop.app-cache", displayName: "Claude Desktop App Cache",
            ecosystem: .aiCodingAgent, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Claude/Cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Claude Desktop Chromium subsystem cache.",
            iconAsset: "claude-code", sfSymbol: "bubble.left.and.bubble.right",
            brandTint: Color(red: 0xD9/255, green: 0x77/255, blue: 0x57/255),
            toolKey: "claude-desktop",
            item: ItemInfo(
                description: "`~/Library/Application Support/Claude/Cache/` is Claude Desktop's Chromium HTTP cache. Sibling directories `Code Cache/`, `GPUCache/`, `DawnGraphiteCache/`, `DawnWebGPUCache/`, and `Service Worker/` follow the same lifecycle but live alongside conversation state — this rule targets only the regenerable Cache/ leaf to stay safe.",
                safetyNote: "Auto-rebuilt on next launch.",
                regenCommand: nil,
                links: []
            )
        ),
    ]

    // MARK: - Editors & IDEs

    private static let ide: [Rule] = [
        // JetBrains
        Rule(
            id: "jetbrains.per-ide-caches", displayName: "JetBrains IDE cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Caches/JetBrains"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "JetBrains per-IDE symbol indexes and VFS snapshots.",
            iconAsset: "jetbrains", brandTint: jetbrainsBlack,
            toolKey: "jetbrains",
            item: ItemInfo(
                description: "`~/Library/Caches/JetBrains/<product version>/` stores symbol indexes, Virtual File System snapshots, and compiled class data that each JetBrains IDE builds from your project sources. The IDE rebuilds these caches on next launch.",
                safetyNote: "The IDE rebuilds its symbol index and VFS snapshot automatically on the next launch; no project source files are stored here.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "JetBrains — IDE directories", url: "https://www.jetbrains.com/help/idea/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jetbrains.per-ide-logs", displayName: "JetBrains IDE logs",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Logs/JetBrains"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "JetBrains per-IDE diagnostic logs and thread dumps.",
            iconAsset: "jetbrains", brandTint: jetbrainsBlack,
            toolKey: "jetbrains",
            item: ItemInfo(
                description: "`~/Library/Logs/JetBrains/<product version>/` stores diagnostic logs, thread dumps, and internal event traces written by each JetBrains IDE. These files are useful for diagnosing crashes but have no effect on IDE operation.",
                safetyNote: "These are diagnostic logs only; deleting them has no effect on IDE settings, project indexes, or installed plugins.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "JetBrains — IDE directories", url: "https://www.jetbrains.com/help/idea/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html", kind: .docs),
                ]
            )
        ),
        // VSCode
        Rule(
            id: "vscode.cached-extensions", displayName: "VSCode cached extensions",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/CachedExtensions"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code extension manifest cache.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`CachedExtensions/` stores serialized extension manifests and contribution-point data so the extension host starts without re-parsing each extension's `package.json`. Updated automatically when extensions are installed or updated.",
                safetyNote: "VS Code repopulates this cache on the next launch; installed extensions and their settings are unaffected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.cached-data", displayName: "VSCode V8 cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/CachedData"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code V8 bytecode cache, keyed per Electron version.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`CachedData/` contains V8 compiled bytecode for VS Code's JavaScript bundles, keyed per Electron version. Each VS Code update creates a new subdirectory; stale entries from prior versions accumulate and are never pruned automatically.",
                safetyNote: "VS Code recompiles and repopulates this cache on the next launch; only the startup time is affected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.cache", displayName: "VSCode HTTP cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/Cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Chromium HTTP disk cache.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`Cache/` is VS Code's Chromium HTTP response cache, storing network resources fetched by the renderer — including extension marketplace data and webview content loaded by extensions.",
                safetyNote: "VS Code refetches all network resources and rebuilds this cache on next use; no user data or settings are stored here.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.code-cache", displayName: "VSCode Code Cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/Code Cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Chromium compiled JS/Wasm code cache.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`Code Cache/` holds Chromium's byte-compiled JavaScript and WebAssembly, separate from the HTTP response cache. Scripts cached here load without reparsing on subsequent VS Code launches.",
                safetyNote: "Chromium recompiles scripts and repopulates this cache on the next VS Code launch; only first-launch performance is affected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.gpu-cache", displayName: "VSCode GPU cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/GPUCache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Chromium compiled GPU shader cache.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`GPUCache/` stores Chromium's compiled GPU shader programs and graphics pipeline state. Caching shaders avoids stalling the GPU on recompile each time VS Code starts.",
                safetyNote: "Chromium recompiles shaders and rebuilds this cache on the next VS Code launch; no user data is stored here.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.logs", displayName: "VSCode logs",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/logs"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code per-session diagnostic logs.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`logs/` contains timestamped subdirectories written by VS Code's main process, extension host, renderer, and language server clients. Each launch creates a new session directory; old sessions accumulate over time.",
                safetyNote: "These are diagnostic logs only; deleting them has no effect on installed extensions, settings, or workspace data.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.crashpad", displayName: "VSCode crash reports",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/Crashpad"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Chromium crash dump minidumps.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`Crashpad/` stores `.dmp` minidump files generated when VS Code or its renderer processes crash. Files accumulate after each crash and are used only for post-mortem analysis.",
                safetyNote: "These are crash diagnostic files only; deleting them has no effect on VS Code's operation or settings.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.workspace-storage", displayName: "VSCode workspace storage",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Application Support/Code/User/workspaceStorage"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "VS Code per-workspace editor state and extension data.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`workspaceStorage/` holds one UUID-named subdirectory per workspace, containing open editor tabs, scroll positions, breakpoints, and data written by extensions. AI chat extensions (e.g. GitHub Copilot Chat, Cline) persist conversation logs here.",
                safetyNote: "Deletes your local AI chat history and editor state for that workspace — only remove if you've archived anything important.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.history", displayName: "VSCode local file history",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/User/History"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "VS Code local file history — per-file save snapshots.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`History/` stores per-file save snapshots recorded by VS Code's Local History feature (added in v1.66). Snapshots are browsable from the Timeline view and provide file-level undo history that persists across editor restarts.",
                safetyNote: "Deletes all saved file snapshots permanently — only remove if you no longer need any previous file version.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "VS Code v1.66 — Local History", url: "https://code.visualstudio.com/updates/v1_66", kind: .docs),
                ]
            )
        ),
        // VSCode Insiders
        Rule(
            id: "vscode-insiders.cached-extensions", displayName: "VSCode Insiders cached extensions",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code - Insiders/CachedExtensions"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Insiders extension manifest cache.",
            iconAsset: "visualstudiocode", brandTint: vscodeInsidersTeal,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`CachedExtensions/` in VS Code Insiders' support directory mirrors the stable channel layout, caching extension manifests and contribution-point data independently so the two channels don't interfere.",
                safetyNote: "VS Code Insiders repopulates this cache on the next launch; installed extensions and their settings are unaffected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode-insiders.cached-data", displayName: "VSCode Insiders V8 cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code - Insiders/CachedData"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Insiders V8 bytecode cache.",
            iconAsset: "visualstudiocode", brandTint: vscodeInsidersTeal,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`CachedData/` in Insiders holds V8 bytecode separate from the stable channel. Because Insiders ships daily builds with changing Electron versions, stale subdirectories accumulate more quickly here than in stable.",
                safetyNote: "VS Code Insiders recompiles and repopulates this cache on the next launch; only the startup time is affected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode-insiders.cache", displayName: "VSCode Insiders HTTP cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code - Insiders/Cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Insiders Chromium HTTP disk cache.",
            iconAsset: "visualstudiocode", brandTint: vscodeInsidersTeal,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`Cache/` in VS Code Insiders' support directory holds Chromium HTTP responses independently of the stable channel cache, covering extension marketplace requests and webview content.",
                safetyNote: "VS Code Insiders refetches network resources and rebuilds this cache on next use; no user data or settings are stored here.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode-insiders.logs", displayName: "VSCode Insiders logs",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code - Insiders/logs"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "VS Code Insiders per-session diagnostic logs.",
            iconAsset: "visualstudiocode", brandTint: vscodeInsidersTeal,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`logs/` in VS Code Insiders holds timestamped session directories from the main process, extension host, and renderer. Because Insiders updates daily, session directories accumulate quickly.",
                safetyNote: "These are diagnostic logs only; deleting them has no effect on installed extensions, settings, or workspace data.",
                regenCommand: nil,
                links: []
            )
        ),
        // Cursor
        Rule(
            id: "cursor.cached-data", displayName: "Cursor V8 cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Cursor/CachedData"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cursor V8 bytecode cache, keyed per Electron version.",
            iconAsset: "cursor", brandTint: cursorBlack,
            toolKey: "cursor",
            item: ItemInfo(
                description: "`CachedData/` in Cursor's support directory holds V8 compiled bytecode using the same layout as VS Code. Entries are keyed per Electron version and accumulate as Cursor updates ship new builds.",
                safetyNote: "Cursor recompiles and repopulates this cache on the next launch; only startup time is affected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "cursor.cached-extensions", displayName: "Cursor cached extensions",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Cursor/CachedExtensions"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cursor extension manifest cache.",
            iconAsset: "cursor", brandTint: cursorBlack,
            toolKey: "cursor",
            item: ItemInfo(
                description: "`CachedExtensions/` stores serialized extension manifests and contribution-point data so Cursor's extension host starts without re-parsing each extension's `package.json`.",
                safetyNote: "Cursor repopulates this cache on the next launch; installed extensions and their settings are unaffected.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "cursor.cache", displayName: "Cursor HTTP cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Cursor/Cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cursor Chromium HTTP disk cache.",
            iconAsset: "cursor", brandTint: cursorBlack,
            toolKey: "cursor",
            item: ItemInfo(
                description: "`Cache/` in Cursor's support directory holds Chromium HTTP responses for extension marketplace data and webview content fetched during a Cursor session.",
                safetyNote: "Cursor refetches network resources and rebuilds this cache on next use; no user data or settings are stored here.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "cursor.logs", displayName: "Cursor logs",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Cursor/logs"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cursor per-session diagnostic logs.",
            iconAsset: "cursor", brandTint: cursorBlack,
            toolKey: "cursor",
            item: ItemInfo(
                description: "`logs/` in Cursor's support directory holds timestamped session directories from the main process, extension host, renderer, and AI subsystem. Old sessions accumulate over time.",
                safetyNote: "These are diagnostic logs only; deleting them has no effect on installed extensions, settings, or AI chat history.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "cursor.workspace-storage", displayName: "Cursor workspace storage",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Application Support/Cursor/User/workspaceStorage"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Cursor per-workspace editor state and AI chat history.",
            iconAsset: "cursor", brandTint: cursorBlack,
            toolKey: "cursor",
            item: ItemInfo(
                description: "`workspaceStorage/` holds one UUID-named subdirectory per workspace, containing editor state (open tabs, positions) and the local log of Cursor's AI pair-programming conversations.",
                safetyNote: "Deletes your local AI conversation history for that workspace — only remove if you've archived anything important.",
                regenCommand: nil,
                links: []
            )
        ),
        // Zed
        Rule(
            id: "zed.cache", displayName: "Zed cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/Zed"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Zed transient application cache.",
            iconAsset: "zed", brandTint: zedBlack,
            toolKey: "zed",
            item: ItemInfo(
                description: "`~/Library/Caches/Zed` stores crash handler working directories and other transient data Zed writes outside its Application Support directory. The directory is typically small.",
                safetyNote: "Zed recreates transient cache data on next launch; no conversation history or editor settings are stored here.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "zed.extensions-work", displayName: "Zed extensions work dir",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Zed/extensions/work"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Zed extension installation work directory.",
            iconAsset: "zed", brandTint: zedBlack,
            toolKey: "zed",
            item: ItemInfo(
                description: "`extensions/work/` holds per-extension build intermediates — compiled WASM modules, download in-progress files — written during extension installation. Completed extensions move to the parent `extensions/` directory.",
                safetyNote: "Contains only installation intermediates; completed extensions in the parent `extensions/` directory are unaffected.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Zed — installing extensions", url: "https://zed.dev/docs/extensions/installing-extensions", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "zed.languages", displayName: "Zed LSP binaries",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Zed/languages"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Zed auto-downloaded language server binaries.",
            iconAsset: "zed", brandTint: zedBlack,
            toolKey: "zed",
            item: ItemInfo(
                description: "`languages/` stores language server binaries (`rust-analyzer`, `gopls`, `typescript-language-server`, etc.) that Zed downloads automatically when you first open a file of the corresponding type. Each server lives in its own subdirectory and can be tens to hundreds of megabytes.",
                safetyNote: "Zed re-downloads each language server binary automatically the next time you open a file of the corresponding type.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "zed.node", displayName: "Zed bundled Node",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Zed/node"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Zed's bundled Node.js runtime for extensions.",
            iconAsset: "zed", brandTint: zedBlack,
            toolKey: "zed",
            item: ItemInfo(
                description: "`node/` contains Zed's own Node.js installation, separate from any system Node.js, used by extensions that require a JavaScript environment. Zed manages this runtime independently.",
                safetyNote: "Zed re-downloads its bundled Node.js runtime automatically the next time an extension that requires it is activated.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "zed.threads", displayName: "Zed AI conversation history",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Zed/threads"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Zed AI assistant conversation history.",
            iconAsset: "zed", brandTint: zedBlack,
            toolKey: "zed",
            item: ItemInfo(
                description: "`threads/` stores each Zed AI assistant conversation as a JSON file. These threads are accessible from the AI panel and can be revisited and continued across sessions.",
                safetyNote: "Deletes your entire local Zed AI conversation history — only remove if you've archived anything important.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Zed — AI overview", url: "https://zed.dev/docs/ai/overview", kind: .docs),
                ]
            )
        ),
        // Sublime Text
        Rule(
            id: "sublime.cache", displayName: "Sublime Text cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/com.sublimetext.4"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Sublime Text compiled syntax definitions and package metadata.",
            iconAsset: "sublimetext", brandTint: sublimeOrange,
            toolKey: "sublimetext",
            item: ItemInfo(
                description: "`~/Library/Caches/com.sublimetext.4/` stores compiled syntax definitions, package metadata, and other derived content built from installed Sublime Text packages. Rebuilt automatically on next launch.",
                safetyNote: "Sublime Text rebuilds compiled syntax definitions and package metadata automatically on the next launch.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "sublime.index", displayName: "Sublime Text symbol index",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Sublime Text/Index"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Sublime Text symbol and file index for Go To Anything.",
            iconAsset: "sublimetext", brandTint: sublimeOrange,
            toolKey: "sublimetext",
            item: ItemInfo(
                description: "`Index/` stores the symbol and file index that powers Go To Anything, Go To Symbol, and Go To Definition in Sublime Text. The index is built by scanning open project directories and accumulates entries for every project ever opened.",
                safetyNote: "Sublime Text rebuilds the index by re-scanning open project directories; Go To Anything will be slower until the index is complete.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Sublime Text — Indexing", url: "https://www.sublimetext.com/docs/indexing.html", kind: .docs),
                ]
            )
        ),
        // Nova
        Rule(
            id: "nova.cache", displayName: "Nova (Panic) cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/com.panic.Nova"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Nova application cache.",
            iconAsset: "panic", brandTint: novaPurple,
            toolKey: "nova",
            item: ItemInfo(
                description: "`~/Library/Caches/com.panic.Nova` holds transient UI state, extension-derived data, and other content that Nova rebuilds from your project and extensions on demand.",
                safetyNote: "Nova rebuilds this cache automatically on the next launch; no project files or extension settings are stored here.",
                regenCommand: nil,
                links: []
            )
        ),
        // Xcode specifics not already covered
        Rule(
            id: "xcode.swiftpm-cache", displayName: "Xcode SwiftPM cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/org.swift.swiftpm"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Xcode SwiftPM repository clone cache.",
            iconAsset: "swift", brandTint: Color(red: 0xF0/255, green: 0x51/255, blue: 0x38/255),
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Caches/org.swift.swiftpm/` stores remote Swift package repository clones that Xcode reuses across dependency resolutions instead of re-fetching from the network.",
                safetyNote: "Xcode re-clones required Swift package repositories on the next dependency resolution; no source files are stored here.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Swift Package Manager — swift.org", url: "https://www.swift.org/package-manager/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "xcode.caches", displayName: "Xcode IDE cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/com.apple.dt.Xcode"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Xcode source editor symbol indexes and module map cache.",
            iconAsset: "xcode", brandTint: Color(red: 0x1D/255, green: 0x9B/255, blue: 0xF0/255),
            languageKey: "swift",
            toolKey: "xcode",
            item: ItemInfo(
                description: "`~/Library/Caches/com.apple.dt.Xcode` stores source editor symbol indexes, module-map caches, and other derived data that power code completion, syntax highlighting, and Jump to Definition. It is separate from per-project `DerivedData` and holds IDE-wide state.",
                safetyNote: "No source code lives here; Xcode rebuilds these caches from your project sources the next time you open the project, and indexing resumes automatically.",
                regenCommand: nil,
                links: []
            )
        ),
        // Neovim / Vim / Emacs
        Rule(
            id: "neovim.cache", displayName: "Neovim cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/nvim"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Neovim logs, LSP traces, and Tree-sitter parser cache.",
            iconAsset: "neovim", brandTint: neovimGreen,
            toolKey: "neovim",
            item: ItemInfo(
                description: "`~/.cache/nvim` stores log files, LSP protocol traces, Tree-sitter compiled parser libraries (`.so` files), and plugin-specific cache data. Neovim follows the XDG Base Directory spec.",
                safetyNote: "Neovim and plugins recompile Tree-sitter parsers and recreate cache data on next use; no user configuration or plugin source code is stored here.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Neovim — XDG Base Directories", url: "https://neovim.io/doc/user/starting.html#base-directories", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "neovim.swap", displayName: "Neovim swap files",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/share/nvim/swap"),
            action: .trash, tier: .extreme, aggregation: .none,
            notes: "Neovim crash-recovery swap files.",
            iconAsset: "neovim", brandTint: neovimGreen,
            toolKey: "neovim",
            item: ItemInfo(
                description: "`~/.local/share/nvim/swap/` stores `*.swp` swap files for each open buffer. If Neovim is killed or crashes, these files enable recovery of unsaved changes on next open.",
                safetyNote: "Safe to delete when Neovim is not running — swap files from a clean session contain no unsaved changes.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "mason-nvim.packages", displayName: "Mason.nvim LSP binaries",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".local/share/nvim/mason/packages"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Mason.nvim downloaded LSP, DAP, linter, and formatter binaries.",
            iconAsset: "neovim", brandTint: neovimGreen,
            toolKey: "neovim",
            item: ItemInfo(
                description: "`~/.local/share/nvim/mason/packages/` stores LSP servers, DAP adapters, linters, and formatters installed by Mason.nvim. Each tool occupies its own subdirectory and is exposed to Neovim via PATH shims.",
                safetyNote: "Reinstall tools individually via `:MasonInstall <name>` or run `:MasonInstall` on all previously installed packages; language features will be unavailable until reinstalled.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Mason.nvim — GitHub", url: "https://github.com/mason-org/mason.nvim", kind: .official),
                ]
            )
        ),
        Rule(
            id: "emacs.eln-cache", displayName: "Emacs native-comp cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".emacs.d/eln-cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Emacs 28+ native-compiled Elisp (.eln files).",
            iconAsset: "emacs", brandTint: emacsPurple,
            toolKey: "emacs",
            item: ItemInfo(
                description: "`~/.emacs.d/eln-cache/` stores Elisp packages compiled to native machine code (`.eln` files) by Emacs 28+'s native compilation feature. Emacs recompiles stale entries automatically on startup.",
                safetyNote: "Emacs recompiles all Elisp packages to native code automatically on the next startup; startup may be slower until compilation completes in the background.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "doom-emacs.cache", displayName: "Doom Emacs cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".emacs.d/.local/cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Doom Emacs package metadata and autoload cache.",
            iconAsset: "emacs", brandTint: emacsPurple,
            toolKey: "emacs",
            item: ItemInfo(
                description: "`~/.emacs.d/.local/cache/` stores Doom Emacs package metadata, compiled autoload files, and other derived artifacts. Managed exclusively by `doom sync`.",
                safetyNote: "`doom sync` regenerates the cache; Doom will not function correctly until that command is run.",
                regenCommand: "doom sync",
                links: [
                    InfoLink(title: "Doom Emacs — GitHub", url: "https://github.com/doomemacs/doomemacs", kind: .official),
                ]
            )
        ),
        Rule(
            id: "helix.cache", displayName: "Helix cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/helix"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Helix editor log file.",
            iconAsset: "helix", brandTint: helixGray,
            toolKey: "helix",
            item: ItemInfo(
                description: "`~/.cache/helix/` stores Helix's log file, recording startup events, LSP communication traces, and runtime warnings. Helix follows the XDG Base Directory spec.",
                safetyNote: "These are log files only; deleting them has no effect on Helix configuration, themes, or LSP operation.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Helix — documentation", url: "https://docs.helix-editor.com", kind: .docs),
                ]
            )
        ),
        // Language-server caches
        Rule(
            id: "rust-analyzer.cache", displayName: "rust-analyzer cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/rust-analyzer"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "rust-analyzer incremental analysis database.",
            iconAsset: "rust", brandTint: Color(red: 0xCE/255, green: 0x41/255, blue: 0x2B/255),
            languageKey: "rust",
            item: ItemInfo(
                description: "`~/.cache/rust-analyzer/` holds rust-analyzer's incremental analysis database — proc-macro expansion results, Salsa query cache, and type-checking outputs — allowing it to resume analysis quickly after a restart.",
                safetyNote: "rust-analyzer rebuilds its analysis database from source on the next editor session; IntelliSense will be slower until the index is complete.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "rust-analyzer — manual", url: "https://rust-analyzer.github.io/book/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jdtls.cache", displayName: "Eclipse JDT LS cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/jdtls"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Eclipse JDT Language Server workspace index cache.",
            iconAsset: "eclipseide", brandTint: eclipsePurple,
            languageKey: "java",
            toolKey: "eclipse",
            item: ItemInfo(
                description: "`~/.cache/jdtls/` stores the Eclipse JDT Language Server's workspace index — compiled class metadata, type hierarchies, and cross-reference data — keyed per workspace. Used by VS Code's Java Extension Pack, Neovim, and other LSP clients.",
                safetyNote: "jdtls rebuilds its workspace index from the project's source and class files on the next editor session; Java IntelliSense will be slower until the index is complete.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Eclipse JDT Language Server — GitHub", url: "https://github.com/eclipse-jdtls/eclipse.jdt.ls", kind: .official),
                ]
            )
        ),
        Rule(
            id: "coc-nvim.extensions", displayName: "coc.nvim node_modules",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".config/coc/extensions/node_modules"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "coc.nvim extension node_modules tree.",
            iconAsset: "", brandTint: neovimGreen,
            item: ItemInfo(
                description: "`~/.config/coc/extensions/node_modules/` stores each coc.nvim extension's `node_modules` subtree. coc.nvim loads VS Code-compatible extensions written in Node.js and installs them here.",
                safetyNote: "coc.nvim extensions must be reinstalled via `:CocInstall <name>`; language-server features will be unavailable until reinstalled.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "coc.nvim — GitHub", url: "https://github.com/neoclide/coc.nvim", kind: .official),
                ]
            )
        ),
        Rule(
            id: "sourcekit-lsp.cache", displayName: "SourceKit-LSP cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/org.llvm.sourcekit-lsp"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "SourceKit-LSP Swift and C language source index.",
            iconAsset: "swift", brandTint: Color(red: 0xF0/255, green: 0x51/255, blue: 0x38/255),
            languageKey: "swift",
            item: ItemInfo(
                description: "`~/Library/Caches/org.llvm.sourcekit-lsp/` stores SourceKit-LSP's source index database — symbol information, cross-references, and type data for Swift and C-based languages. Used by VS Code's Swift extension, Neovim, Helix, and other LSP clients.",
                safetyNote: "SourceKit-LSP rebuilds the source index from the project's build artifacts on the next editor session; Swift IntelliSense will be slower until indexing completes.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "SourceKit-LSP — GitHub", url: "https://github.com/swiftlang/sourcekit-lsp", kind: .official),
                ]
            )
        ),
        // VS Code extension globalStorage — the long-lived bloat sources
        Rule(
            id: "vscode.copilot-cache", displayName: "VSCode Copilot Cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/User/globalStorage/github.copilot"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "GitHub Copilot completion telemetry + model cache.",
            iconAsset: "github-copilot", brandTint: vscodeBlue,
            toolKey: "github-copilot",
            item: ItemInfo(
                description: "`~/Library/Application Support/Code/User/globalStorage/github.copilot/` holds GitHub Copilot's completion telemetry queue and model cache for the VS Code extension.",
                safetyNote: "Regenerated on the next launch; Copilot stays signed in via a separate token store.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "GitHub Copilot in VS Code", url: "https://code.visualstudio.com/docs/copilot/overview", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "vscode.copilot-chat-cache", displayName: "VSCode Copilot Chat Cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/User/globalStorage/github.copilot-chat"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Copilot Chat workspace index + cached transcripts.",
            iconAsset: "github-copilot", brandTint: vscodeBlue,
            toolKey: "github-copilot",
            item: ItemInfo(
                description: "`~/Library/Application Support/Code/User/globalStorage/github.copilot-chat/` stores Copilot Chat's local workspace embeddings index and cached chat transcripts. Chat history syncs to your GitHub account, so the local copy is rebuildable.",
                safetyNote: "Workspace index re-indexes on demand; chat transcripts re-sync from github.com when you sign in.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "GitHub Copilot Chat", url: "https://docs.github.com/en/copilot/github-copilot-chat", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "vscode.gh-pr-cache", displayName: "VSCode GitHub PRs Cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/User/globalStorage/github.vscode-pull-request-github"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Cached PR/issue data per repo.",
            iconAsset: "github", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`User/globalStorage/github.vscode-pull-request-github/` caches per-repo PR and issue data fetched by VS Code's official GitHub Pull Requests extension.",
                safetyNote: "Refetched on demand from the GitHub API on the next extension activation.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.gitlens-cache", displayName: "VSCode GitLens Cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/User/globalStorage/eamodio.gitlens"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "GitLens cached blame data + avatars.",
            iconAsset: "gitlens", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`User/globalStorage/eamodio.gitlens/` holds GitLens' cached blame metadata and contributor avatars across opened repositories.",
                safetyNote: "Regenerated lazily as GitLens re-blames files.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.shared-cachedData", displayName: "VSCode Per-Commit V8 Cache",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/CachedData"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-commit V8 code cache (separate from Code Cache/).",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`Code/CachedData/` is a peer of `Code Cache/` — VS Code keeps a per-commit V8 bytecode cache here, accumulating across editor upgrades.",
                safetyNote: "Auto-rebuilt by the next launch; first launch after clearing is slightly slower.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "vscode.shared-cachedExtensionsVSIXs", displayName: "VSCode Cached Extension VSIXs",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Code/CachedExtensionVSIXs"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Downloaded VSIX archives for installed extensions.",
            iconAsset: "visualstudiocode", brandTint: vscodeBlue,
            toolKey: "vscode",
            item: ItemInfo(
                description: "`Code/CachedExtensionVSIXs/` keeps the downloaded `.vsix` archives for installed extensions. Used by the extension manager for reinstalls/repairs.",
                safetyNote: "Re-downloaded by the extension manager when needed.",
                regenCommand: nil,
                links: []
            )
        ),
        // JetBrains finer-grained slices (existing per-ide-caches/-logs are coarse)
        Rule(
            id: "jetbrains.per-ide-index", displayName: "JetBrains Index Snapshots",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Caches/JetBrains"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Per-IDE symbol/stub indexes (slower first reindex).",
            iconAsset: "jetbrains", brandTint: jetbrainsBlack,
            toolKey: "jetbrains",
            item: ItemInfo(
                description: "Within each `~/Library/Caches/JetBrains/<IDE><Year>.<X>/` directory, the `index/` subtree holds symbol and stub indexes per project. These are re-derived from sources but the rebuild is slow.",
                safetyNote: "Rebuilt on the next project open. Shared-index plugins (if installed) speed this up.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "JetBrains — indexing", url: "https://www.jetbrains.com/help/idea/indexing.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "jetbrains.per-ide-event-log", displayName: "JetBrains FUS Event Log",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Application Support/JetBrains"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Feature Usage Statistics event-log queue.",
            iconAsset: "jetbrains", brandTint: jetbrainsBlack,
            toolKey: "jetbrains",
            item: ItemInfo(
                description: "Per-IDE `event-log-data/` directories under `~/Library/Application Support/JetBrains/` queue Feature Usage Statistics telemetry payloads before they're shipped or expired.",
                safetyNote: "Recreated automatically; only telemetry is lost.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "jetbrains.per-ide-plugin-sandbox", displayName: "JetBrains Plugin Sandbox",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Application Support/JetBrains"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Plugin SDK sandbox runs (Gradle IntelliJ Plugin).",
            iconAsset: "jetbrains", brandTint: jetbrainsBlack,
            toolKey: "jetbrains",
            item: ItemInfo(
                description: "Per-IDE `plugins-sandbox/` directories hold the sandboxed IDE installs spun up by the Gradle IntelliJ Plugin during plugin development. Each sandbox is a self-contained ~hundreds-of-MB IDE clone.",
                safetyNote: "Rebuilt by the next `runIde`/`buildPlugin` Gradle task.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "jetbrains.per-ide-log-archive", displayName: "JetBrains Log Archive",
            ecosystem: .ide, scope: .globalCache,
            matcher: .fixedPathChildren(relativeToHome: "Library/Caches/JetBrains"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-IDE rolled log archive.",
            iconAsset: "jetbrains", brandTint: jetbrainsBlack,
            toolKey: "jetbrains",
            item: ItemInfo(
                description: "Per-IDE `log-archive/` and similar rolled-log directories under the JetBrains caches tree. Diagnostic-only.",
                safetyNote: "Recreated on the next launch.",
                regenCommand: nil,
                links: []
            )
        ),
    ]

    // MARK: - DevOps & Cloud CLIs

    private static let pulumiPurple    = Color(red: 0x80/255, green: 0x59/255, blue: 0xC2/255)
    private static let terraformPurple = Color(red: 0x82/255, green: 0x4A/255, blue: 0xC4/255)
    private static let helmBlue        = Color(red: 0x27/255, green: 0x7A/255, blue: 0x9F/255)
    private static let kubernetesBlue  = Color(red: 0x32/255, green: 0x6C/255, blue: 0xE5/255)
    private static let gcloudBlue      = Color(red: 0x42/255, green: 0x85/255, blue: 0xF4/255)
    private static let githubBlack     = Color(red: 0x18/255, green: 0x17/255, blue: 0x17/255)
    private static let actBlue         = Color(red: 0x2C/255, green: 0x70/255, blue: 0xC1/255)

    private static let devops: [Rule] = [
        Rule(
            id: "pulumi.plugins", displayName: "Pulumi Plugins",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".pulumi/plugins"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Resource-provider plugin binaries.",
            iconAsset: "pulumi",
            brandTint: pulumiPurple,
            toolKey: "pulumi",
            item: ItemInfo(
                description: "`~/.pulumi/plugins` holds Pulumi's downloaded resource-provider plugins, one directory per provider+version. Provider plugins are individually large (single AWS/Azure/GCP plugins are hundreds of MB) and Pulumi keeps every version it has ever installed.",
                safetyNote: "Pulumi re-downloads needed plugins on the next `pulumi up` (or via `pulumi plugin install`). The companion `~/.pulumi/templates/` holds project templates and refills via `pulumi new`.",
                regenCommand: "pulumi plugin install",
                links: [
                    InfoLink(title: "Pulumi — pulumi plugin", url: "https://www.pulumi.com/docs/cli/commands/pulumi_plugin/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "terraform.plugin-cache", displayName: "Terraform Plugin Cache",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".terraform.d/plugin-cache"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Provider plugin binaries shared across Terraform projects.",
            iconAsset: "terraform",
            brandTint: terraformPurple,
            toolKey: "terraform",
            item: ItemInfo(
                description: "`~/.terraform.d/plugin-cache` is the shared provider-plugin cache that Terraform projects pull from instead of each downloading their own copy. Only populated when `plugin_cache_dir` is set in `~/.terraformrc`. The AWS provider alone is ~600 MB unzipped.",
                safetyNote: "`terraform init` re-downloads any provider versions referenced by your projects.",
                regenCommand: "terraform init",
                links: [
                    InfoLink(title: "Terraform — provider plugin cache", url: "https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "helm.repo-cache", displayName: "Helm Repository Cache",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/helm/repository"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Cached chart .tgz archives + repo index.yaml files.",
            iconAsset: "helm",
            brandTint: helmBlue,
            toolKey: "helm",
            item: ItemInfo(
                description: "`~/Library/Caches/helm/repository` holds downloaded chart archives (`.tgz`) and `<repo>-index.yaml` metadata for every Helm repository the user has added. Refetched by `helm repo update` and on chart pulls.",
                safetyNote: "`helm repo update` refreshes the index files; charts are re-downloaded on `helm pull`/`helm install` as needed.",
                regenCommand: "helm repo update",
                links: [
                    InfoLink(title: "Helm — XDG paths", url: "https://helm.sh/docs/helm/helm/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "kubectl.discovery-cache", displayName: "kubectl Discovery Cache",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".kube/cache/discovery"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-cluster API discovery documents.",
            iconAsset: "kubernetes",
            brandTint: kubernetesBlue,
            toolKey: "kubectl",
            item: ItemInfo(
                description: "`~/.kube/cache/discovery/` caches API-discovery documents (`servergroups.json`, `serverresources.json`) per cluster API endpoint. Default TTL is 10 minutes; one tree per server kubectl has talked to.",
                safetyNote: "Refilled automatically on the next `kubectl` call.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "kubectl options — --cache-dir", url: "https://kubernetes.io/docs/reference/kubectl/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "kubectl.http-cache", displayName: "kubectl HTTP Cache",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".kube/cache/http"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "ETag-keyed HTTP response cache for discovery requests.",
            iconAsset: "kubernetes",
            brandTint: kubernetesBlue,
            toolKey: "kubectl",
            item: ItemInfo(
                description: "`~/.kube/cache/http/` is kubectl's HTTP response cache, keyed by ETag. Used to short-circuit unchanged discovery responses.",
                safetyNote: "Refilled automatically on the next `kubectl` call.",
                regenCommand: nil,
                links: []
            )
        ),
        Rule(
            id: "gcloud.logs", displayName: "gcloud CLI Logs",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".config/gcloud/logs"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Per-invocation gcloud CLI logs.",
            iconAsset: "google-cloud",
            brandTint: gcloudBlue,
            toolKey: "gcloud",
            item: ItemInfo(
                description: "`~/.config/gcloud/logs/` collects per-invocation gcloud CLI logs in dated subdirectories (`YYYY.MM.DD/HH.MM.SS.NNNNNN.log`). Accumulates indefinitely without rotation.",
                safetyNote: "Written fresh on every `gcloud` call. Logs are diagnostic-only.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Google Cloud SDK — configurations", url: "https://cloud.google.com/sdk/docs/configurations", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "gh.cli-cache", displayName: "GitHub CLI Cache",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/com.github.gh"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "HTTP response cache for `gh api` / `gh pr` / `gh repo` calls.",
            iconAsset: "github",
            brandTint: githubBlack,
            toolKey: "gh",
            item: ItemInfo(
                description: "`~/Library/Caches/com.github.gh` is the GitHub CLI's HTTP cache layer for `gh api`/`gh pr`/`gh repo` calls. Some commands use the cache implicitly; others opt in via `--cache`.",
                safetyNote: "Refilled automatically on the next `gh` call.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "GitHub CLI", url: "https://cli.github.com/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "act.cache", displayName: "act Cache",
            ecosystem: .devops, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: ".cache/act"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Local GitHub Actions runner cache (nektos/act).",
            iconAsset: "github-actions",
            brandTint: actBlue,
            toolKey: "act",
            item: ItemInfo(
                description: "`~/.cache/act/` holds nektos/act's cached runner images, action source checkouts, and artifact-server payloads from running GitHub Actions locally.",
                safetyNote: "act re-pulls runner images and re-fetches actions on the next invocation.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "nektos/act — GitHub", url: "https://github.com/nektos/act", kind: .official),
                ]
            )
        ),
    ]

    // MARK: - Game Dev (Unity / Unreal / Godot + Metal shader caches)

    private static let unityBlack    = Color(red: 0x18/255, green: 0x18/255, blue: 0x18/255)
    private static let unrealBlack   = Color(red: 0x10/255, green: 0x10/255, blue: 0x10/255)
    private static let godotBlue     = Color(red: 0x47/255, green: 0x8C/255, blue: 0xBF/255)
    private static let metalSilver   = Color(red: 0x8E/255, green: 0x8E/255, blue: 0x93/255)

    private static let gameDev: [Rule] = [
        // ── Unity ────────────────────────────────────────────────────────────
        Rule(
            id: "unity.cache", displayName: "Unity Package Cache",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Unity/cache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Unity's per-user package cache.",
            iconAsset: "unity",
            brandTint: unityBlack,
            toolKey: "unity",
            item: ItemInfo(
                description: "`~/Library/Unity/cache/` holds packages downloaded by Unity's Package Manager (UPM) for use across projects, alongside other per-user Unity working data.",
                safetyNote: "Unity re-downloads packages from the registry on the next project open.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Unity Package Manager", url: "https://docs.unity3d.com/Manual/Packages.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "unity.asset-store", displayName: "Unity Asset Store Downloads",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Unity/Asset Store-5.x"),
            action: .trash, tier: .high, aggregation: .none,
            notes: "Downloaded Asset Store packages — re-downloadable from your Asset Store library.",
            iconAsset: "unity",
            brandTint: unityBlack,
            toolKey: "unity",
            item: ItemInfo(
                description: "`~/Library/Unity/Asset Store-5.x/` is where the Unity Editor caches `.unitypackage` archives downloaded from the Asset Store. Heavy users — especially those with paid asset libraries — see this reach tens of GB.",
                safetyNote: "Re-downloadable from your Asset Store library (purchased entitlements persist on Unity's side). Free assets only stay re-downloadable while their listings remain on the store — verify before clearing if you depend on a publisher who may have delisted.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Unity Asset Store", url: "https://assetstore.unity.com/", kind: .official),
                ]
            )
        ),
        Rule(
            id: "unity-hub.editor-cache", displayName: "Unity Hub Installer Cache",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/UnityHub/cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Unity Hub's editor-installer staging area.",
            iconAsset: "unity",
            brandTint: unityBlack,
            toolKey: "unity",
            item: ItemInfo(
                description: "`~/Library/Application Support/UnityHub/cache/` is the staging area Unity Hub uses while downloading and installing editor versions and modules.",
                safetyNote: "Cleared safely between installs. Hub re-stages on the next download.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Unity Hub", url: "https://unity.com/unity-hub", kind: .official),
                ]
            )
        ),
        // ── Unreal Engine ───────────────────────────────────────────────────
        Rule(
            id: "unreal.derived-data", displayName: "Unreal DerivedDataCache",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Epic/UnrealEngine/Common/DerivedDataCache"),
            action: .trash, tier: .medium, aggregation: .none,
            notes: "Engine-wide DDC: cooked assets + compiled shaders.",
            iconAsset: "unrealengine",
            brandTint: unrealBlack,
            toolKey: "unreal",
            item: ItemInfo(
                description: "`~/Library/Application Support/Epic/UnrealEngine/Common/DerivedDataCache/` is Unreal's engine-wide DDC — derived versions of source assets (cooked textures, light maps, etc.) and compiled shaders, shared across projects on this machine. Easily reaches 5–50 GB on active users; per-project DDC may also live alongside the project's `.uproject`.",
                safetyNote: "Unreal rebuilds DDC entries on demand the next time you open a project or trigger a cook. The first build after clearing is slow (minutes per project) but everything is reproducible from sources.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Unreal — Derived Data Cache", url: "https://dev.epicgames.com/documentation/en-us/unreal-engine/derived-data-cache", kind: .docs),
                ]
            )
        ),
        // ── Godot ───────────────────────────────────────────────────────────
        Rule(
            id: "godot.editor-cache", displayName: "Godot Editor Cache",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Caches/Godot"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Godot editor's user-level cache (project metadata, thumbnails).",
            iconAsset: "godot",
            brandTint: godotBlue,
            toolKey: "godot",
            item: ItemInfo(
                description: "`~/Library/Caches/Godot/` is Godot's user-level editor cache — recent-projects metadata, thumbnails, and other transient data the editor regenerates on demand. Godot's per-project shader and import caches live in each project's `.godot/` directory, separate from this.",
                safetyNote: "Recreated on the next editor launch.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Godot — file paths in Godot projects", url: "https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "godot.shader-cache", displayName: "Godot Editor Shader Cache",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .fixedPath(relativeToHome: "Library/Application Support/Godot/shader_cache"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "Godot editor-side compiled shader cache.",
            iconAsset: "godot",
            brandTint: godotBlue,
            toolKey: "godot",
            item: ItemInfo(
                description: "`~/Library/Application Support/Godot/shader_cache/` holds the editor's compiled shader binaries (used by previews and the editor's own rendering). Per-project runtime shader caches live in each project's `.godot/shader_cache/` directory and aren't touched by this rule.",
                safetyNote: "Recompiled on demand by the editor.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Godot — file paths", url: "https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html", kind: .docs),
                ]
            )
        ),
        // ── Metal shader binary cache (catches non-bundled binaries) ──────
        Rule(
            id: "metal.global-cache", displayName: "Metal Shader Cache",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .darwinCachePath(relativePath: "com.apple.metal"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "macOS Metal AIR cache — catches non-bundled binaries (cargo / swift run / scripts).",
            iconAsset: "metal",
            brandTint: metalSilver,
            languageKey: "swift",
            toolKey: "metal",
            item: ItemInfo(
                description: "`$DARWIN_USER_CACHE_DIR/com.apple.metal/` (resolves to `/private/var/folders/<X>/<Y>/C/com.apple.metal/`) is the catch-all Metal binary shader cache for processes that don't have a bundle ID — `cargo run` builds, `swift run` executables, ad-hoc Python scripts hitting Metal via PyTorch / MLX, and similar non-bundled binaries. Bundled apps get their own `<bundle-id>/com.apple.metal/` peer subdirectories that aren't enumerated here yet.",
                safetyNote: "macOS rebuilds the cache on the next render; only a perf hit while it warms back up. Doesn't affect WGPU's own pipeline cache (which apps store at developer-defined locations) or MoltenVK's per-app pipeline blob.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "Metal — Apple Developer", url: "https://developer.apple.com/metal/", kind: .docs),
                ]
            )
        ),
        Rule(
            id: "metal.global-mtlfe", displayName: "MetalFX Shader Cache",
            ecosystem: .gameDev, scope: .globalCache,
            matcher: .darwinCachePath(relativePath: "com.apple.metalfe"),
            action: .trash, tier: .low, aggregation: .none,
            notes: "MetalFX (upscaling / temporal AA) shader cache.",
            iconAsset: "metal",
            brandTint: metalSilver,
            languageKey: "swift",
            toolKey: "metal",
            item: ItemInfo(
                description: "`$DARWIN_USER_CACHE_DIR/com.apple.metalfe/` caches compiled shaders for MetalFX (Apple's spatial / temporal upscaling framework used by some games and rendering apps). Same per-user-session cache root as `com.apple.metal/`.",
                safetyNote: "Recompiled on demand by MetalFX's first invocation in each affected app.",
                regenCommand: nil,
                links: [
                    InfoLink(title: "MetalFX — Apple Developer", url: "https://developer.apple.com/documentation/metalfx", kind: .docs),
                ]
            )
        ),
    ]
}