import Foundation

/// Keyed lookup table of `ToolInfo`. Rules reference entries via
/// `Rule.toolKey`. The panel pairs a tool section with its parent
/// language section (via `ToolInfo.languageKey`) so one select can
/// surface both.
enum ToolCatalog {
    static let all: [String: ToolInfo] = Dictionary(
        uniqueKeysWithValues: entries.map { ($0.key, $0) }
    )

    static func info(for key: String?) -> ToolInfo? {
        guard let key else { return nil }
        return all[key]
    }

    private static let entries: [ToolInfo] = [

        // MARK: - JavaScript / TypeScript

        ToolInfo(
            key: "nodejs",
            displayName: "Node.js",
            tagline: "An open-source, cross-platform JavaScript runtime built on Chrome's V8 engine — the foundation for server-side JavaScript.",
            description: "Node.js executes JavaScript outside the browser using Google's V8 engine, enabling back-end services, CLIs, build tools, and desktop applications written in JavaScript or TypeScript. It ships with npm as the default package manager and is compatible with pnpm, Yarn, Bun, and other Node.js-aware package managers. Node.js itself stores almost no persistent cache — it is the package managers layered on top that accumulate cacheable data.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Node.js", url: "https://nodejs.org/en", kind: .official),
                InfoLink(title: "Node.js — introduction", url: "https://nodejs.org/en/learn/getting-started/introduction-to-nodejs", kind: .docs),
                InfoLink(title: "Node.js — Wikipedia", url: "https://en.wikipedia.org/wiki/Node.js", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "npm",
            displayName: "npm",
            tagline: "The default package manager bundled with Node.js, backed by the npmjs.com registry.",
            description: "npm ships with every Node.js installation and provides install, publish, and lifecycle script commands used in virtually every JavaScript project. Packages downloaded from the registry are stored in a content-addressable global cache, so re-installing dependencies skips network requests when possible. npm reads project dependencies from `package.json` and locks exact versions in `package-lock.json`.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "npm", url: "https://docs.npmjs.com", kind: .official),
                InfoLink(title: "npm — cache command", url: "https://docs.npmjs.com/cli/v11/commands/npm-cache", kind: .docs),
                InfoLink(title: "npm — Wikipedia", url: "https://en.wikipedia.org/wiki/Npm", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "pnpm",
            displayName: "pnpm",
            tagline: "A disk-efficient package manager — dependencies are hard-linked from a single content-addressable store.",
            description: "pnpm stores every package version exactly once in a global content-addressable store and projects hard-link their `node_modules` entries into it, so identical packages are never duplicated across projects. This approach reduces total disk usage on machines with many Node.js projects. pnpm has a built-in store-pruning command to reclaim entries that no live project references.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "pnpm", url: "https://pnpm.io", kind: .official),
                InfoLink(title: "pnpm — store prune", url: "https://pnpm.io/cli/store", kind: .docs),
                InfoLink(title: "pnpm — Wikipedia", url: "https://en.wikipedia.org/wiki/Pnpm", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "yarn",
            displayName: "Yarn",
            tagline: "A JavaScript package manager with built-in workspace support for monorepos.",
            description: "Yarn (v2+, also called Berry) manages JavaScript dependencies with a strong emphasis on reproducibility and workspace support for monorepos. It stores compressed package archives in a global cache that is reused across all projects on the machine. Yarn supports Plug'n'Play (PnP) mode as an alternative to materialising a `node_modules` tree.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Yarn", url: "https://yarnpkg.com", kind: .official),
                InfoLink(title: "Yarn — getting started", url: "https://yarnpkg.com/getting-started", kind: .docs),
                InfoLink(title: "Yarn (package manager) — Wikipedia", url: "https://en.wikipedia.org/wiki/Yarn_(package_manager)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "bun",
            displayName: "Bun",
            tagline: "An all-in-one JavaScript runtime and package manager with a Node.js-compatible API.",
            description: "Bun is both a JavaScript/TypeScript runtime (powered by JavaScriptCore) and a package manager with an npm-compatible registry. It aims to be a compatible replacement for Node.js and npm in existing projects. Bun maintains a global install cache to speed up repeated installations across projects.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Bun", url: "https://bun.sh", kind: .official),
                InfoLink(title: "Bun — documentation", url: "https://bun.sh/docs", kind: .docs),
                InfoLink(title: "Bun (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Bun_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "deno",
            displayName: "Deno",
            tagline: "A JavaScript and TypeScript runtime with built-in security permissions and a package manager.",
            description: "Deno is a runtime built on V8, written in Rust, with first-class TypeScript support and built-in tooling for formatting, linting, and testing. It can install npm packages or import modules directly from URLs, and maintains a global module cache to avoid redundant downloads. Deno's permission model requires explicit flags to access the filesystem, network, and environment variables.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Deno", url: "https://deno.com", kind: .official),
                InfoLink(title: "Deno — documentation", url: "https://docs.deno.com", kind: .docs),
                InfoLink(title: "Deno (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Deno_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "nextjs",
            displayName: "Next.js",
            tagline: "The React framework for the web — built-in routing, SSR, SSG, and full-stack API routes in a single project.",
            description: "Next.js is an open-source React framework maintained by Vercel that provides file-based routing, server-side rendering (SSR), static site generation (SSG), and API routes out of the box. Build output contains compiled server and client bundles, static assets, and an incremental build cache. Next.js supports both the App Router (React Server Components) and the older Pages Router.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Next.js", url: "https://nextjs.org", kind: .official),
                InfoLink(title: "Next.js — documentation", url: "https://nextjs.org/docs", kind: .docs),
                InfoLink(title: "Next.js — Wikipedia", url: "https://en.wikipedia.org/wiki/Next.js", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "nuxt",
            displayName: "Nuxt",
            tagline: "The Vue.js framework — file-based routing, SSR, SSG, and auto-imports in one opinionated setup.",
            description: "Nuxt is the open-source framework for Vue.js, providing file-based routing, server-side rendering, static site generation, and an auto-import system that eliminates boilerplate. During development and builds, Nuxt writes compiled output, generated route manifests, and TypeScript type definitions to a build directory. Nuxt 3 is built on top of the Nitro server engine, enabling deployment to serverless platforms as well as traditional Node.js servers.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Nuxt", url: "https://nuxt.com", kind: .official),
                InfoLink(title: "Nuxt — documentation", url: "https://nuxt.com/docs", kind: .docs),
                InfoLink(title: "Nuxt — Wikipedia", url: "https://en.wikipedia.org/wiki/Nuxt.js", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "sveltekit",
            displayName: "SvelteKit",
            tagline: "The official Svelte application framework — routing, SSR, adapters, and a Vite-powered dev experience.",
            description: "SvelteKit is the official full-stack framework for Svelte, bringing file-based routing, server-side rendering, static site generation, and a rich adapter system for deploying to any platform. It is powered by Vite for the development server and production build. Build output holds generated route manifests, TypeScript configuration, and compiled code, all fully reproducible from source.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Svelte", url: "https://svelte.dev", kind: .official),
                InfoLink(title: "SvelteKit — documentation", url: "https://svelte.dev/docs/kit/introduction", kind: .docs),
                InfoLink(title: "Svelte — Wikipedia", url: "https://en.wikipedia.org/wiki/Svelte", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "vite",
            displayName: "Vite",
            tagline: "A frontend build tool that uses native ES modules for development and Rollup for production builds.",
            description: "Vite is a frontend build tool that serves source files over native ES modules during development, eliminating slow bundling and enabling near-instant hot module replacement. For production it bundles with Rollup, applying tree-shaking and code-splitting. Pre-bundled dependencies are cached in a project-local directory to avoid redundant work between dev server restarts.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Vite", url: "https://vite.dev", kind: .official),
                InfoLink(title: "Vite — getting started", url: "https://vite.dev/guide/", kind: .docs),
                InfoLink(title: "Vite — Wikipedia", url: "https://en.wikipedia.org/wiki/Vite_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "parcel",
            displayName: "Parcel",
            tagline: "A zero-configuration web application bundler for JavaScript, TypeScript, CSS, HTML, and other assets.",
            description: "Parcel is a zero-config bundler that handles JavaScript, TypeScript, CSS, HTML, images, and more without any configuration file. It caches the result of every file transformation so subsequent builds only reprocess changed files. Parcel supports tree-shaking, code splitting, and hot module replacement in its development server.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Parcel", url: "https://parceljs.org", kind: .official),
                InfoLink(title: "Parcel — documentation", url: "https://parceljs.org/docs/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "turborepo",
            displayName: "Turborepo",
            tagline: "A build system for JavaScript and TypeScript monorepos — task caching and parallel execution built in.",
            description: "Turborepo orchestrates build, test, lint, and other tasks across monorepo packages, using a content-hash-based task cache to skip work whose inputs haven't changed. It can fan out to Vercel's remote cache to share task results across team members and CI environments. Turborepo integrates with npm, pnpm, and Yarn workspaces without requiring migration of existing projects.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Turborepo", url: "https://turborepo.dev", kind: .official),
                InfoLink(title: "Turborepo — documentation", url: "https://turborepo.dev/repo/docs", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "astro",
            displayName: "Astro",
            tagline: "The web framework for content-driven websites — ships zero JavaScript by default with opt-in component islands.",
            description: "Astro is a meta-framework designed for content-heavy websites that renders components to static HTML at build time, shipping zero client-side JavaScript unless you opt in via its component islands architecture. It supports components from React, Vue, Svelte, Solid, and other frameworks in the same project. Build output includes the deployable static site alongside auto-generated TypeScript definitions and internal metadata.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Astro", url: "https://astro.build", kind: .official),
                InfoLink(title: "Astro — documentation", url: "https://docs.astro.build/en/getting-started/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "electron",
            displayName: "Electron",
            tagline: "Build cross-platform desktop apps with JavaScript, HTML, and CSS — powered by Chromium and Node.js.",
            description: "Electron embeds the Chromium rendering engine and a Node.js runtime into a single executable, letting web developers ship native desktop applications for macOS, Windows, and Linux from a single codebase. The Electron runtime binary is downloaded separately from the npm package and cached globally, shared across all projects on the same machine. Well-known apps built on Electron include VS Code, Slack, Figma, and GitHub Desktop.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Electron", url: "https://www.electronjs.org", kind: .official),
                InfoLink(title: "Electron — documentation", url: "https://www.electronjs.org/docs/latest/", kind: .docs),
                InfoLink(title: "Electron (software framework) — Wikipedia", url: "https://en.wikipedia.org/wiki/Electron_(software_framework)", kind: .wiki),
            ]
        ),

        // MARK: - Python

        ToolInfo(
            key: "pip",
            displayName: "pip",
            tagline: "The standard package installer for Python, used to install packages from PyPI.",
            description: "pip is the default package installer shipped with CPython and is used to install Python libraries from PyPI (the Python Package Index). It maintains a global wheel and HTTP cache to accelerate re-installs across environments. Most projects declare dependencies in `requirements.txt` or `pyproject.toml`.",
            languageKey: "python",
            links: [
                InfoLink(title: "pip", url: "https://pip.pypa.io/en/stable/", kind: .official),
                InfoLink(title: "PyPI", url: "https://pypi.org", kind: .official),
                InfoLink(title: "pip (package manager) — Wikipedia", url: "https://en.wikipedia.org/wiki/Pip_(package_manager)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "uv",
            displayName: "uv",
            tagline: "A Python package and project manager written in Rust, from the makers of Ruff.",
            description: "uv is a Python package and environment manager that replaces pip, pip-tools, and virtualenv in a single tool. It maintains a central package cache, deduplicating downloaded wheels across environments. uv supports lockfiles for reproducible installs and has a built-in cache-pruning command to reclaim space from stale entries.",
            languageKey: "python",
            links: [
                InfoLink(title: "uv", url: "https://docs.astral.sh/uv", kind: .official),
                InfoLink(title: "uv — cache management", url: "https://docs.astral.sh/uv/concepts/cache/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "poetry",
            displayName: "Poetry",
            tagline: "Python dependency management and packaging with a single, declarative `pyproject.toml`.",
            description: "Poetry manages Python project dependencies, virtual environments, and package publishing through a unified `pyproject.toml`-based workflow. It stores downloaded packages in a centralised cache and keeps virtual environments lean by symlinking from that cache. Poetry also handles building and publishing packages to PyPI.",
            languageKey: "python",
            links: [
                InfoLink(title: "Poetry", url: "https://python-poetry.org", kind: .official),
                InfoLink(title: "Poetry — documentation", url: "https://python-poetry.org/docs/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "pyenv",
            displayName: "pyenv",
            tagline: "Python version manager — install and switch between multiple Python versions per project.",
            description: "pyenv intercepts Python commands via shims on `PATH` and lets you set a global, per-project, or per-shell Python version. Each installed Python version is stored as a self-contained tree; removing an individual version directory frees that space. pyenv reads `.python-version` files to select the interpreter automatically per directory.",
            languageKey: "python",
            links: [
                InfoLink(title: "pyenv — GitHub", url: "https://github.com/pyenv/pyenv", kind: .official),
            ]
        ),

        ToolInfo(
            key: "conda",
            displayName: "Conda",
            tagline: "Cross-language package and environment manager for Python, R, and more — the backbone of the Anaconda distribution.",
            description: "Conda manages packages and isolated environments for Python and other languages, and is the foundation of the Anaconda and Miniconda distributions. Downloaded package archives are cached in a package cache directory before being unpacked into environments. Conda has a built-in cleanup command to remove cached tarballs and unused packages.",
            languageKey: "python",
            links: [
                InfoLink(title: "Conda", url: "https://docs.conda.io/en/latest/", kind: .official),
                InfoLink(title: "Conda — managing packages", url: "https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-pkgs.html", kind: .docs),
                InfoLink(title: "Conda (package manager) — Wikipedia", url: "https://en.wikipedia.org/wiki/Conda_(package_manager)", kind: .wiki),
            ]
        ),

        // MARK: - Rust

        ToolInfo(
            key: "cargo",
            displayName: "Cargo",
            tagline: "The Rust build system and package manager — handles dependencies, compilation, testing, and publishing.",
            description: "Cargo is the official build tool and package manager for Rust, tightly integrated into the `rustc` toolchain. It downloads crate sources into a global registry cache and stores compiled artifacts in project-local `target/` directories. Cargo resolves dependencies from crates.io and lockfiles, and supports workspaces for multi-crate projects.",
            languageKey: "rust",
            links: [
                InfoLink(title: "Cargo", url: "https://doc.rust-lang.org/cargo/", kind: .official),
                InfoLink(title: "crates.io", url: "https://crates.io", kind: .official),
            ]
        ),

        ToolInfo(
            key: "rustup",
            displayName: "rustup",
            tagline: "The official Rust toolchain installer — manages stable, beta, and nightly releases plus cross-compilation targets.",
            description: "rustup installs and updates the Rust compiler (`rustc`), Cargo, and the standard library for any supported target triple. It manages multiple toolchain channels (stable, beta, nightly) and cross-compilation targets from a single command. Unused toolchains can be uninstalled and reinstalled at any time.",
            languageKey: "rust",
            links: [
                InfoLink(title: "rustup", url: "https://rustup.rs", kind: .official),
            ]
        ),

        // MARK: - Ruby

        ToolInfo(
            key: "bundler",
            displayName: "Bundler",
            tagline: "The standard dependency manager for Ruby applications — locks gem versions via `Gemfile.lock`.",
            description: "Bundler resolves and installs the exact gem versions declared in a project's `Gemfile`, writing a `Gemfile.lock` that pins the dependency graph for reproducible installs. Gems can be installed into a shared system or user path, or into a project-local `vendor/bundle` directory for isolation. Bundler is included in Ruby's standard library since Ruby 2.6.",
            languageKey: "ruby",
            links: [
                InfoLink(title: "Bundler", url: "https://bundler.io", kind: .official),
                InfoLink(title: "Bundler — documentation", url: "https://bundler.io/docs.html", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "rbenv",
            displayName: "rbenv",
            tagline: "A Ruby version manager that switches versions per project via shims on PATH.",
            description: "rbenv intercepts Ruby commands through shims placed at the front of `PATH`, reading `.ruby-version` files to select the right interpreter per directory. Ruby versions are installed via the `ruby-build` plugin and stored as self-contained trees. Removing a version directory uninstalls it; it can be reinstalled at any time.",
            languageKey: "ruby",
            links: [
                InfoLink(title: "rbenv", url: "https://rbenv.org", kind: .official),
            ]
        ),

        ToolInfo(
            key: "rvm",
            displayName: "RVM",
            tagline: "Ruby Version Manager — installs multiple Ruby interpreters and manages per-project gemsets.",
            description: "RVM (Ruby Version Manager) installs and manages multiple Ruby versions as well as per-project gemsets that isolate gem dependencies completely from each other. It works via shell function overrides rather than shims, which can affect shell startup time. Individual rubies or gemsets can be removed and reinstalled through RVM's own commands.",
            languageKey: "ruby",
            links: [
                InfoLink(title: "RVM", url: "https://rvm.io", kind: .official),
            ]
        ),

        // MARK: - Go

        ToolInfo(
            key: "go-modules",
            displayName: "Go Modules",
            tagline: "Go's built-in dependency management system — modules declared in `go.mod`, resolved by the `go` toolchain.",
            description: "Go Modules, introduced in Go 1.11, define a project's module path and dependency versions in a `go.mod` file with a `go.sum` checksum database. The Go toolchain caches downloaded module source trees and pre-compiled build artifacts in a user-level module cache. Modules are verified against a public checksum database (sum.golang.org) to guard against tampering.",
            languageKey: "go",
            links: [
                InfoLink(title: "Go", url: "https://go.dev", kind: .official),
                InfoLink(title: "Go Modules reference", url: "https://go.dev/ref/mod", kind: .docs),
            ]
        ),

        // MARK: - Java / JVM

        ToolInfo(
            key: "maven",
            displayName: "Maven",
            tagline: "The standard build and dependency management tool for Java projects, driven by a `pom.xml` descriptor.",
            description: "Apache Maven builds Java projects according to a Project Object Model (`pom.xml`), downloading declared dependencies from Maven Central and other repositories into a local repository cache. Maven follows a convention-over-configuration model with a standard directory layout and a lifecycle of phases (compile, test, package, install, deploy). The local repository cache can grow large on active machines as multiple versions of the same artifact accumulate.",
            languageKey: "java",
            links: [
                InfoLink(title: "Apache Maven", url: "https://maven.apache.org", kind: .official),
                InfoLink(title: "Maven — introduction to repositories", url: "https://maven.apache.org/guides/introduction/introduction-to-repositories.html", kind: .docs),
                InfoLink(title: "Apache Maven — Wikipedia", url: "https://en.wikipedia.org/wiki/Apache_Maven", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "gradle",
            displayName: "Gradle",
            tagline: "A build automation tool for Java, Kotlin, and Android with incremental builds and an extensible plugin system.",
            description: "Gradle builds JVM projects (and more) using a Groovy or Kotlin DSL, with an incremental build system and a local build cache. Downloaded dependencies and build-cache entries are stored in a user-level cache directory that can grow to several gigabytes. Gradle is the required build system for Android projects and supports parallel task execution across multi-project builds.",
            languageKey: "java",
            links: [
                InfoLink(title: "Gradle", url: "https://gradle.org", kind: .official),
                InfoLink(title: "Gradle User Manual", url: "https://docs.gradle.org/current/userguide/userguide.html", kind: .docs),
                InfoLink(title: "Gradle build cache", url: "https://docs.gradle.org/current/userguide/build_cache.html", kind: .docs),
                InfoLink(title: "Gradle — Wikipedia", url: "https://en.wikipedia.org/wiki/Gradle", kind: .wiki),
            ]
        ),

        // MARK: - .NET

        ToolInfo(
            key: "dotnet-cli",
            displayName: ".NET CLI",
            tagline: "The cross-platform `dotnet` command — build, run, test, publish, and manage .NET projects from the terminal.",
            description: "The .NET CLI (`dotnet`) is the primary command-line interface for creating, building, testing, and publishing .NET applications. It restores NuGet packages and stores them in a global NuGet cache shared across all projects on the machine. Build outputs land in project-local `bin/` and `obj/` directories and are fully reproducible from source.",
            languageKey: "dotnet",
            links: [
                InfoLink(title: ".NET CLI", url: "https://learn.microsoft.com/en-us/dotnet/core/tools/", kind: .official),
            ]
        ),

        ToolInfo(
            key: "nuget",
            displayName: "NuGet",
            tagline: "The .NET package manager — the central registry and tooling for sharing and consuming .NET libraries.",
            description: "NuGet is the package management system for .NET: it defines the `.nupkg` format, hosts the public `nuget.org` registry, and is integrated into both `dotnet` CLI and Visual Studio. Downloaded packages are extracted into a global packages folder shared across all projects on the machine. Dependency versions are pinned via `packages.lock.json` for reproducible restores.",
            languageKey: "dotnet",
            links: [
                InfoLink(title: "NuGet", url: "https://www.nuget.org", kind: .official),
                InfoLink(title: "NuGet — what is NuGet", url: "https://learn.microsoft.com/en-us/nuget/what-is-nuget", kind: .docs),
                InfoLink(title: "NuGet — Wikipedia", url: "https://en.wikipedia.org/wiki/NuGet", kind: .wiki),
            ]
        ),

        // MARK: - PHP

        ToolInfo(
            key: "composer",
            displayName: "Composer",
            tagline: "Dependency management for PHP — installs libraries declared in `composer.json` and pins them via `composer.lock`.",
            description: "Composer is the standard dependency manager for PHP, resolving packages from Packagist and other repositories according to `composer.json` and writing a `composer.lock` for reproducible installs. Dependencies are installed into a project-local `vendor/` directory. Composer also maintains a global cache of downloaded package archives to speed up installs across projects.",
            languageKey: "php",
            links: [
                InfoLink(title: "Composer", url: "https://getcomposer.org", kind: .official),
                InfoLink(title: "Composer — basic usage", url: "https://getcomposer.org/doc/01-basic-usage.md", kind: .docs),
                InfoLink(title: "Composer (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Composer_(software)", kind: .wiki),
            ]
        ),

        // MARK: - Dart / Flutter

        ToolInfo(
            key: "pub",
            displayName: "pub",
            tagline: "The Dart and Flutter package manager — installs packages from pub.dev and the Flutter ecosystem.",
            description: "pub is the built-in package manager for Dart and Flutter projects, resolving dependencies declared in `pubspec.yaml` and writing a `pubspec.lock` for reproducible installs. Downloaded packages are stored in a global cache shared across all Dart and Flutter projects on the machine. pub.dev hosts the public package registry for the Dart/Flutter ecosystem.",
            languageKey: "dart",
            links: [
                InfoLink(title: "pub.dev", url: "https://pub.dev", kind: .official),
                InfoLink(title: "Dart — pub commands", url: "https://dart.dev/tools/pub/cmd", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "flutter",
            displayName: "Flutter",
            tagline: "Google's open-source UI toolkit for building natively compiled, multi-platform apps from a single Dart codebase.",
            description: "Flutter compiles Dart code to native ARM/x86 binaries for iOS, Android, macOS, Windows, and Linux, and to JavaScript/WebAssembly for the web — all from one project. Build artifacts land in a project-local `build/` directory organised by target platform. The Flutter SDK caches engine binaries and tool artifacts that are recreated automatically when the SDK is updated.",
            languageKey: "dart",
            links: [
                InfoLink(title: "Flutter", url: "https://flutter.dev", kind: .official),
                InfoLink(title: "Flutter — CLI reference", url: "https://docs.flutter.dev/reference/flutter-cli", kind: .docs),
                InfoLink(title: "Flutter — Wikipedia", url: "https://en.wikipedia.org/wiki/Flutter_(software)", kind: .wiki),
            ]
        ),

        // MARK: - Swift / Objective-C

        ToolInfo(
            key: "swiftpm",
            displayName: "Swift Package Manager",
            tagline: "Apple's built-in package manager for Swift — declares dependencies in `Package.swift` and integrates with Xcode.",
            description: "Swift Package Manager (SwiftPM) is the official dependency manager and build system for Swift packages, integrated into both the `swift` command-line tools and Xcode. Resolved packages are checked out into a global cache for Xcode builds and into a project-local `.build/checkouts/` directory for command-line builds. Build artifacts live in the project's `.build/` directory and are reproducible from source.",
            languageKey: "swift",
            links: [
                InfoLink(title: "Swift Package Manager", url: "https://www.swift.org/package-manager/", kind: .official),
            ]
        ),

        ToolInfo(
            key: "cocoapods",
            displayName: "CocoaPods",
            tagline: "A dependency manager for Swift and Objective-C Cocoa projects, predating Swift Package Manager.",
            description: "CocoaPods manages library dependencies for Xcode projects via a `Podfile` and `Podfile.lock`, downloading pod source code into a project-local `Pods/` directory and modifying the Xcode workspace. A global spec repository and download cache are maintained to speed up subsequent installs. CocoaPods predates Swift Package Manager and remains in use for libraries not yet distributed as Swift packages.",
            languageKey: "swift",
            links: [
                InfoLink(title: "CocoaPods", url: "https://cocoapods.org", kind: .official),
                InfoLink(title: "CocoaPods — Wikipedia", url: "https://en.wikipedia.org/wiki/CocoaPods", kind: .wiki),
            ]
        ),

        // MARK: - C / C++

        ToolInfo(
            key: "cmake",
            displayName: "CMake",
            tagline: "A cross-platform meta-build system for C and C++ — generates native build files for Make, Ninja, Xcode, and more.",
            description: "CMake reads `CMakeLists.txt` files and generates platform-native build scripts (Makefiles, Ninja build files, Xcode projects, Visual Studio solutions). Build artifacts — object files, compiled libraries, executables — accumulate in a separate build directory that is conventionally kept out of version control. CMake supports out-of-source builds, so source and build trees remain cleanly separated.",
            languageKey: "cpp",
            links: [
                InfoLink(title: "CMake", url: "https://cmake.org", kind: .official),
                InfoLink(title: "CMake — reference documentation", url: "https://cmake.org/cmake/help/latest/", kind: .docs),
                InfoLink(title: "CMake — Wikipedia", url: "https://en.wikipedia.org/wiki/CMake", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "conan",
            displayName: "Conan",
            tagline: "A decentralised, open-source package manager for C and C++ with broad build-system support.",
            description: "Conan resolves and installs C/C++ library dependencies, storing downloaded packages and compiled binaries in a local user-level cache. Projects declare dependencies in a `conanfile.txt` or `conanfile.py`. Conan integrates with CMake, Meson, Autotools, and other build systems, and supports cross-compilation profiles for different target platforms.",
            languageKey: "cpp",
            links: [
                InfoLink(title: "Conan", url: "https://conan.io", kind: .official),
                InfoLink(title: "Conan — documentation", url: "https://docs.conan.io/2/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "vcpkg",
            displayName: "vcpkg",
            tagline: "Microsoft's open-source C/C++ package manager — integrates with CMake and MSBuild to install thousands of libraries.",
            description: "vcpkg simplifies acquiring and building open-source C/C++ libraries on Windows, macOS, and Linux, with first-class CMake and MSBuild integration. It operates in two modes: classic mode installs packages into a shared vcpkg tree, while manifest mode uses a per-project `vcpkg.json` and stores built libraries in a project-local directory. All installed files are built from source and are reproducible.",
            languageKey: "cpp",
            links: [
                InfoLink(title: "vcpkg", url: "https://vcpkg.io/en/", kind: .official),
                InfoLink(title: "vcpkg — Microsoft Learn", url: "https://learn.microsoft.com/en-us/vcpkg/", kind: .docs),
                InfoLink(title: "vcpkg — Wikipedia", url: "https://en.wikipedia.org/wiki/Vcpkg", kind: .wiki),
            ]
        ),

        // MARK: - Cross-language package managers

        ToolInfo(
            key: "homebrew",
            displayName: "Homebrew",
            tagline: "A package manager for macOS and Linux — installs command-line tools and GUI apps via `brew install`.",
            description: "Homebrew manages open-source command-line tools and GUI apps on macOS and Linux. It resolves a formula definition to a pre-compiled bottle (or builds from source), tracks installed versions, and provides upgrade and removal operations. Casks extend Homebrew to macOS GUI applications distributed as `.dmg` or `.pkg` installers.",
            languageKey: nil,
            links: [
                InfoLink(title: "Homebrew", url: "https://brew.sh", kind: .official),
                InfoLink(title: "Homebrew — documentation", url: "https://docs.brew.sh", kind: .docs),
                InfoLink(title: "Homebrew — FAQ", url: "https://docs.brew.sh/FAQ", kind: .docs),
                InfoLink(title: "Homebrew (package manager) — Wikipedia", url: "https://en.wikipedia.org/wiki/Homebrew_(package_manager)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "macports",
            displayName: "MacPorts",
            tagline: "A community-driven package manager for macOS that compiles ports from source under `/opt/local`.",
            description: "MacPorts is an open-source project that provides a large collection of Unix and open-source software for macOS, compiling each port from source (or from pre-built binaries where available) into a self-contained prefix. Downloaded source archives are cached locally to avoid redundant network fetches. MacPorts maintains its own dependency tree independent of the system and of Homebrew.",
            languageKey: nil,
            links: [
                InfoLink(title: "MacPorts", url: "https://www.macports.org", kind: .official),
                InfoLink(title: "MacPorts — installation guide", url: "https://www.macports.org/install.php", kind: .docs),
                InfoLink(title: "MacPorts — Wikipedia", url: "https://en.wikipedia.org/wiki/MacPorts", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "nix",
            displayName: "Nix",
            tagline: "A purely functional package manager with reproducible, atomic builds and per-user package environments.",
            description: "Nix is a purely functional package manager that builds packages in isolation and stores them in an immutable content-addressed store, guaranteeing reproducibility across machines. Every build closure is recorded, so multiple versions of the same package coexist without conflict. Nix supports declarative system configuration (NixOS) and reproducible development shells via `nix develop`.",
            languageKey: nil,
            links: [
                InfoLink(title: "Nix", url: "https://nixos.org", kind: .official),
                InfoLink(title: "Nix — reference manual", url: "https://nix.dev/manual/nix/stable/", kind: .docs),
                InfoLink(title: "Nix (package manager) — Wikipedia", url: "https://en.wikipedia.org/wiki/Nix_(package_manager)", kind: .wiki),
            ]
        ),

        // MARK: - Editors & IDEs

        ToolInfo(
            key: "zed",
            displayName: "Zed",
            tagline: "A code editor written in Rust with real-time collaboration and built-in AI assistant support.",
            description: "Zed is an open-source code editor written in Rust, designed for performance and real-time collaboration. It integrates an AI assistant panel with conversation history persisted locally. Language server binaries are downloaded on demand and cached locally; Zed re-fetches them automatically when needed.",
            languageKey: nil,
            links: [
                InfoLink(title: "Zed", url: "https://zed.dev", kind: .official),
                InfoLink(title: "Zed — documentation", url: "https://zed.dev/docs", kind: .docs),
                InfoLink(title: "Zed (text editor) — Wikipedia", url: "https://en.wikipedia.org/wiki/Zed_(text_editor)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "cursor",
            displayName: "Cursor",
            tagline: "A VS Code fork with an AI assistant that can edit across multiple files and run terminal commands.",
            description: "Cursor is a fork of VS Code that embeds an AI assistant capable of editing across multiple files, running terminal commands, and maintaining multi-turn conversations. It stores AI chat history per workspace and accumulates V8 bytecode caches, Chromium caches, and logs in the same layout as VS Code. Cursor extensions are compatible with VS Code's extension marketplace.",
            languageKey: nil,
            links: [
                InfoLink(title: "Cursor", url: "https://cursor.com", kind: .official),
                InfoLink(title: "Cursor — documentation", url: "https://cursor.com/docs", kind: .docs),
                InfoLink(title: "Cursor (code editor) — Wikipedia", url: "https://en.wikipedia.org/wiki/Cursor_(code_editor)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "vscode",
            displayName: "Visual Studio Code",
            tagline: "Microsoft's open-source, Electron-based code editor with a large extension marketplace.",
            description: "Visual Studio Code (VS Code) is a free, cross-platform code editor built on Electron, with a vast extension marketplace and deep language-server protocol (LSP) integration. It stores per-workspace state including open tabs, extension scratch data, and AI chat logs from extensions like GitHub Copilot Chat. V8 bytecode caches, Chromium HTTP caches, GPU shader caches, and session logs also accumulate over time.",
            languageKey: nil,
            links: [
                InfoLink(title: "Visual Studio Code", url: "https://code.visualstudio.com", kind: .official),
                InfoLink(title: "VS Code — documentation", url: "https://code.visualstudio.com/docs", kind: .docs),
                InfoLink(title: "Visual Studio Code — Wikipedia", url: "https://en.wikipedia.org/wiki/Visual_Studio_Code", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "jetbrains",
            displayName: "JetBrains IDEs",
            tagline: "A family of professional IDEs covering every major language — IntelliJ IDEA, PyCharm, WebStorm, GoLand, CLion, and more.",
            description: "JetBrains produces a suite of language-specific IDEs (IntelliJ IDEA, PyCharm, WebStorm, GoLand, CLion, Rider, RubyMine, and others) that share a common platform and cache layout. Per-product indexing caches accumulate as projects are opened and can be safely deleted — the IDE rebuilds indexes on next launch. Diagnostic logs are separate from the index and are not needed for normal operation.",
            languageKey: nil,
            links: [
                InfoLink(title: "JetBrains", url: "https://www.jetbrains.com", kind: .official),
                InfoLink(title: "JetBrains — IDE directories", url: "https://www.jetbrains.com/help/idea/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html", kind: .docs),
                InfoLink(title: "JetBrains — Wikipedia", url: "https://en.wikipedia.org/wiki/JetBrains", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "sublimetext",
            displayName: "Sublime Text",
            tagline: "A cross-platform text and code editor with a command palette, multi-cursor editing, and a package ecosystem.",
            description: "Sublime Text is a cross-platform text and code editor with a command palette, Goto Anything navigation, and multi-cursor editing. Compiled syntax definitions, package metadata, and derived content are kept in a cache directory, while the symbol and file index that powers Goto Anything is stored separately. Both are rebuilt automatically on next launch if cleared.",
            languageKey: nil,
            links: [
                InfoLink(title: "Sublime Text", url: "https://www.sublimetext.com", kind: .official),
                InfoLink(title: "Sublime Text — documentation", url: "https://www.sublimetext.com/docs/", kind: .docs),
                InfoLink(title: "Sublime Text — Wikipedia", url: "https://en.wikipedia.org/wiki/Sublime_Text", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "emacs",
            displayName: "Emacs",
            tagline: "A Lisp-powered text editor with deep customisation via Emacs Lisp, available since 1976.",
            description: "GNU Emacs is an extensible editor whose behaviour can be customised in Emacs Lisp; it also functions as an email client, organiser, and more through its large package ecosystem. Emacs 28+ natively compiles Elisp packages to machine code (`.eln` files) for faster execution, caching the results locally. Community configurations such as Doom Emacs add their own cache layers that are all rebuilt on next launch if cleared.",
            languageKey: nil,
            links: [
                InfoLink(title: "GNU Emacs", url: "https://www.gnu.org/software/emacs/", kind: .official),
                InfoLink(title: "GNU Emacs — Wikipedia", url: "https://en.wikipedia.org/wiki/GNU_Emacs", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "neovim",
            displayName: "Neovim",
            tagline: "A modernised, embeddable fork of Vim with Lua scripting, a built-in LSP client, and a thriving plugin ecosystem.",
            description: "Neovim is a community-driven refactor of Vim that adds first-class Lua configuration, a built-in Language Server Protocol client, Tree-sitter syntax parsing, and a stable remote API. Following the XDG Base Directory spec, it separates logs, swap files, and plugin data into distinct cache and data directories. LSP server binaries managed by Mason.nvim are downloaded on demand and stored in a user-owned data directory.",
            languageKey: nil,
            links: [
                InfoLink(title: "Neovim", url: "https://neovim.io", kind: .official),
                InfoLink(title: "Neovim — documentation", url: "https://neovim.io/doc/user/", kind: .docs),
                InfoLink(title: "Neovim — Wikipedia", url: "https://en.wikipedia.org/wiki/Neovim", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "helix",
            displayName: "Helix",
            tagline: "A modal terminal editor written in Rust with multiple selections, Tree-sitter, and LSP built in.",
            description: "Helix is a terminal text editor inspired by Kakoune, implemented in Rust, that ships with Tree-sitter syntax highlighting and Language Server Protocol support out of the box — no plugin manager needed. It follows the XDG Base Directory specification, separating configuration, cache, and data into standard directories. Helix uses a selections-first editing model rather than the operators-first model of Vim.",
            languageKey: nil,
            links: [
                InfoLink(title: "Helix", url: "https://helix-editor.com", kind: .official),
                InfoLink(title: "Helix — documentation", url: "https://docs.helix-editor.com", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "eclipse",
            displayName: "Eclipse IDE",
            tagline: "The veteran open-source Java IDE — and platform for language-specific IDEs — from the Eclipse Foundation.",
            description: "Eclipse IDE is a long-standing open-source integrated development environment primarily used for Java development, though language-specific packages extend it to C/C++, PHP, Python, and more. The Eclipse JDT Language Server (eclipse.jdt.ls) powers Java IntelliSense in VS Code and other LSP clients. Its workspace index grows with each project analysed and is rebuilt automatically if cleared.",
            languageKey: nil,
            links: [
                InfoLink(title: "Eclipse IDE", url: "https://eclipseide.org", kind: .official),
                InfoLink(title: "Eclipse IDE — downloads", url: "https://www.eclipse.org/downloads/", kind: .docs),
                InfoLink(title: "Eclipse (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Eclipse_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "nova",
            displayName: "Nova",
            tagline: "Panic's native macOS code editor, built entirely with AppKit rather than Electron.",
            description: "Nova is a native macOS code editor from Panic Inc., built with AppKit rather than an Electron wrapper. It supports extensions via a built-in marketplace, remote servers via SSH, and a built-in terminal. Application cache data is accumulated over time and is rebuilt from installed extensions and projects on next launch.",
            languageKey: nil,
            links: [
                InfoLink(title: "Nova", url: "https://nova.app", kind: .official),
                InfoLink(title: "Nova — help", url: "https://nova.app/help/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "xcode",
            displayName: "Xcode",
            tagline: "Apple's official IDE for developing apps across all Apple platforms — macOS, iOS, iPadOS, watchOS, tvOS, and visionOS.",
            description: "Xcode is the primary development environment for Apple platform applications, integrating a source editor, Interface Builder, Instruments profiler, and the Simulator. Build intermediates accumulate in a DerivedData directory (often many gigabytes per project) and are fully reproducible. Additional large caches include device support files for connected hardware and SwiftPM repository clones.",
            languageKey: "swift",
            links: [
                InfoLink(title: "Xcode", url: "https://developer.apple.com/xcode/", kind: .official),
                InfoLink(title: "Xcode — Apple Developer", url: "https://developer.apple.com/documentation/xcode", kind: .docs),
                InfoLink(title: "Xcode — Wikipedia", url: "https://en.wikipedia.org/wiki/Xcode", kind: .wiki),
            ]
        ),

        // MARK: - Elixir

        ToolInfo(
            key: "hex",
            displayName: "Hex",
            tagline: "The package manager for the Erlang ecosystem — used by Elixir (Mix) and Erlang (rebar3) projects alike.",
            description: "Hex is the central package registry and client for Elixir and Erlang, hosting packages at hex.pm. Mix integrates Hex natively; declaring a dependency in `mix.exs` and running `mix deps.get` downloads tarballs into a global cache and unpacks dependency source into the project's `deps/` directory. rebar3 uses Hex for Erlang projects in the same way.",
            languageKey: "elixir",
            links: [
                InfoLink(title: "Hex", url: "https://hex.pm", kind: .official),
                InfoLink(title: "Hex — Mix tasks", url: "https://hexdocs.pm/hex/Mix.Tasks.Hex.html", kind: .docs),
            ]
        ),

        // MARK: - Build systems & containers

        ToolInfo(
            key: "bazel",
            displayName: "Bazel",
            tagline: "Google's open-source, language-agnostic build and test system with hermetic sandboxing and incremental caching.",
            description: "Bazel is a multi-language, multi-platform build system that uses hermetic sandboxing and a content-addressed action cache to produce incremental, reproducible builds. It stores the action cache, downloaded external repository sources, and build outputs in a user-level output root that can grow to tens of gigabytes. Bazel supports remote caching and remote execution, allowing build artifacts to be shared across a team.",
            languageKey: nil,
            links: [
                InfoLink(title: "Bazel", url: "https://bazel.build", kind: .official),
                InfoLink(title: "Bazel — output directories", url: "https://bazel.build/docs/output_directories", kind: .docs),
                InfoLink(title: "Bazel — commands and options", url: "https://bazel.build/docs/user-manual", kind: .docs),
                InfoLink(title: "Bazel (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Bazel_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "docker",
            displayName: "Docker",
            tagline: "A platform for packaging, distributing, and running applications in containers.",
            description: "Docker packages applications and their dependencies into portable container images that run consistently across development, staging, and production environments. On macOS, Docker Desktop stores all images, containers, volumes, and build cache inside a single sparse virtual-machine disk image that can grow to hundreds of gigabytes. Docker provides built-in pruning commands to reclaim space from unused images, stopped containers, and dangling build cache.",
            languageKey: nil,
            links: [
                InfoLink(title: "Docker", url: "https://docs.docker.com/get-started/overview/", kind: .official),
                InfoLink(title: "Docker Desktop — documentation", url: "https://docs.docker.com/desktop/", kind: .docs),
                InfoLink(title: "docker system prune", url: "https://docs.docker.com/reference/cli/docker/system/prune/", kind: .docs),
                InfoLink(title: "Docker (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Docker_(software)", kind: .wiki),
            ]
        ),

        // MARK: - Static Site Generators

        ToolInfo(
            key: "gatsby",
            displayName: "Gatsby",
            tagline: "A React-based static site generator with a GraphQL data layer for sourcing content.",
            description: "Gatsby is a React framework for building static websites, pulling content from Markdown files, CMSes, APIs, and databases through a unified GraphQL data layer. Build output includes an incremental build cache and webpack bundles alongside the final deployable static site. Gatsby supports a plugin ecosystem for sourcing content from headless CMSes and third-party APIs.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Gatsby", url: "https://www.gatsbyjs.com", kind: .official),
                InfoLink(title: "Gatsby — documentation", url: "https://www.gatsbyjs.com/docs/", kind: .docs),
                InfoLink(title: "Gatsby (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Gatsby_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "docusaurus",
            displayName: "Docusaurus",
            tagline: "Meta's open-source static site generator for documentation websites — MDX, versioning, and i18n built in.",
            description: "Docusaurus is a React-based documentation site generator from Meta that supports versioning, internationalization, and full-text search. The compiled static site and incremental build metadata are both fully reproducible from source. Docusaurus supports MDX, allowing React components to be embedded directly in Markdown documentation.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Docusaurus", url: "https://docusaurus.io", kind: .official),
                InfoLink(title: "Docusaurus — documentation", url: "https://docusaurus.io/docs", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "eleventy",
            displayName: "Eleventy",
            tagline: "A static site generator with no client-side JavaScript by default, supporting eleven template languages.",
            description: "Eleventy (11ty) is a JavaScript-based static site generator that supports a broad range of template languages — Nunjucks, Liquid, Markdown, HTML, JavaScript, and more — without imposing any particular front-end framework. Output contains only plain HTML, CSS, and static assets and is entirely generated from source. Eleventy makes no assumptions about JavaScript bundling or CSS preprocessing, leaving those choices to the author.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Eleventy", url: "https://www.11ty.dev", kind: .official),
                InfoLink(title: "Eleventy — documentation", url: "https://www.11ty.dev/docs/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "hexo",
            displayName: "Hexo",
            tagline: "A Node.js blog framework that converts Markdown posts and themes into a static site.",
            description: "Hexo converts Markdown posts and configurable themes into a complete static site, including rendered HTML pages, feed files, and a sitemap. Generated output is fully reproducible from source. Hexo supports plugins for deployment to GitHub Pages, Heroku, and other hosting targets.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Hexo", url: "https://hexo.io", kind: .official),
                InfoLink(title: "Hexo — documentation", url: "https://hexo.io/docs/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "hugo",
            displayName: "Hugo",
            tagline: "A static site generator distributed as a single Go binary, with no external dependencies.",
            description: "Hugo is a Go-based static site generator. Authors write content in Markdown and structure layouts with Go's html/template system. Build output includes the deployable static site alongside a processed asset pipeline cache; both are fully regenerated from source on each build.",
            languageKey: nil,
            links: [
                InfoLink(title: "Hugo", url: "https://gohugo.io", kind: .official),
                InfoLink(title: "Hugo — documentation", url: "https://gohugo.io/documentation/", kind: .docs),
                InfoLink(title: "Hugo (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Hugo_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "jekyll",
            displayName: "Jekyll",
            tagline: "The blog-aware static site generator that powers GitHub Pages — write Markdown, get a site.",
            description: "Jekyll is a Ruby-based static site generator that transforms Markdown content and Liquid templates into a complete website. It is the engine behind GitHub Pages and is used for documentation and blogs. The compiled site and incremental build cache are both fully reproducible from source. Ruby plugins extend the build pipeline with custom logic.",
            languageKey: "ruby",
            links: [
                InfoLink(title: "Jekyll", url: "https://jekyllrb.com", kind: .official),
                InfoLink(title: "Jekyll — documentation", url: "https://jekyllrb.com/docs/", kind: .docs),
                InfoLink(title: "Jekyll (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Jekyll_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "mkdocs",
            displayName: "MkDocs",
            tagline: "A Python-based documentation site generator that builds from Markdown files and a `mkdocs.yml` config.",
            description: "MkDocs reads Markdown files and a `mkdocs.yml` configuration to produce a static site for hosting on GitHub Pages, Read the Docs, or any static host. Generated output is written to a `site/` directory and is fully reproducible from source. Python plugins declared in `mkdocs.yml` extend the build pipeline.",
            languageKey: "python",
            links: [
                InfoLink(title: "MkDocs", url: "https://www.mkdocs.org", kind: .official),
                InfoLink(title: "MkDocs — user guide", url: "https://www.mkdocs.org/user-guide/", kind: .docs),
                InfoLink(title: "MkDocs — Wikipedia", url: "https://en.wikipedia.org/wiki/MkDocs", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "pelican",
            displayName: "Pelican",
            tagline: "A Python static site generator — write content in Markdown or reStructuredText, extend with Python plugins.",
            description: "Pelican is a Python-based static site generator that converts Markdown and reStructuredText content into a complete website using Jinja2 templates. A `pelicanconf.py` file controls the site configuration, and the plugin system lets authors extend the build with arbitrary Python code. Generated output is entirely reproducible from source.",
            languageKey: "python",
            links: [
                InfoLink(title: "Pelican", url: "https://getpelican.com", kind: .official),
            ]
        ),

        ToolInfo(
            key: "zola",
            displayName: "Zola",
            tagline: "A static site generator distributed as a single binary — Markdown content, Tera templates, built-in Sass.",
            description: "Zola is a static site generator written in Rust and distributed as a single binary with no dependencies, offering built-in Sass compilation, syntax highlighting, and shortcodes. Authors write content in Markdown and define layouts with Tera templates; no Rust knowledge is required. Generated output is entirely reproducible from source.",
            languageKey: nil,
            links: [
                InfoLink(title: "Zola", url: "https://www.getzola.org", kind: .official),
                InfoLink(title: "Zola — documentation", url: "https://www.getzola.org/documentation/getting-started/overview/", kind: .docs),
            ]
        ),

        // MARK: - AI / ML

        ToolInfo(
            key: "pytorch",
            displayName: "PyTorch",
            tagline: "An open-source deep learning framework built around dynamic computation graphs, backed by Meta AI.",
            description: "PyTorch is a Python-based deep learning framework used in academic research and production ML systems. It caches pretrained model weights locally; individual checkpoints can reach several gigabytes for large transformers. PyTorch integrates with the Python scientific-computing stack (NumPy, SciPy, Pandas) and with CUDA and Metal for GPU acceleration.",
            languageKey: "python",
            links: [
                InfoLink(title: "PyTorch", url: "https://pytorch.org", kind: .official),
                InfoLink(title: "PyTorch — documentation", url: "https://docs.pytorch.org/docs/stable/index.html", kind: .docs),
                InfoLink(title: "PyTorch — Wikipedia", url: "https://en.wikipedia.org/wiki/PyTorch", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "tensorflow",
            displayName: "TensorFlow",
            tagline: "Google's open-source machine learning platform with a high-level Keras API and low-level graph computation.",
            description: "TensorFlow is a machine learning platform developed by Google, offering a high-level Keras API and low-level graph-based computation for custom training loops. Datasets downloaded via TensorFlow Datasets (TFDS) are cached locally; model weights can reach hundreds of gigabytes for large benchmarks. TensorFlow supports deployment across CPUs, GPUs, TPUs, and edge devices via TensorFlow Lite.",
            languageKey: "python",
            links: [
                InfoLink(title: "TensorFlow", url: "https://www.tensorflow.org", kind: .official),
                InfoLink(title: "TensorFlow — guide", url: "https://www.tensorflow.org/guide", kind: .docs),
                InfoLink(title: "TensorFlow — Wikipedia", url: "https://en.wikipedia.org/wiki/TensorFlow", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "keras",
            displayName: "Keras",
            tagline: "A high-level deep learning API that runs on JAX, TensorFlow, or PyTorch as the backend.",
            description: "Keras is a neural network API that prioritises modularity and ease of experimentation; since Keras 3 it runs on top of JAX, TensorFlow, or PyTorch interchangeably. Pretrained weights for built-in application models (ResNet, EfficientNet, VGG, and others) are cached locally; model weights for large architectures can reach tens of gigabytes. Keras is available as a standalone `keras` package from PyPI.",
            languageKey: "python",
            links: [
                InfoLink(title: "Keras", url: "https://keras.io", kind: .official),
                InfoLink(title: "Keras — getting started", url: "https://keras.io/getting_started/", kind: .docs),
                InfoLink(title: "Keras — Wikipedia", url: "https://en.wikipedia.org/wiki/Keras", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "ultralytics",
            displayName: "Ultralytics YOLO",
            tagline: "Object detection and computer vision models — YOLO11, YOLOv8, and related architectures.",
            description: "Ultralytics provides the YOLOv8 and YOLO11 families of object detection, segmentation, pose-estimation, and classification models used in computer-vision pipelines. Pretrained weights are downloaded automatically on first use and cached locally; larger custom checkpoints can be several gigabytes. The package is distributed via PyPI and supports ONNX and TensorRT export paths for edge deployment.",
            languageKey: "python",
            links: [
                InfoLink(title: "Ultralytics", url: "https://docs.ultralytics.com", kind: .official),
            ]
        ),

        ToolInfo(
            key: "huggingface",
            displayName: "Hugging Face",
            tagline: "The hub for open-source AI models, datasets, and spaces — and the Python libraries that power them.",
            description: "Hugging Face is both a hosting platform (Hub) and a suite of Python libraries — including `transformers`, `diffusers`, and `datasets` — that provide access to pretrained models for NLP, computer vision, and audio tasks. All downloaded model repositories are cached locally using a content-addressed blob store; large language models and diffusion checkpoints can accumulate hundreds of gigabytes. The optional Xet storage layer adds chunk-level deduplication to reduce redundant downloads across related model versions.",
            languageKey: "python",
            links: [
                InfoLink(title: "Hugging Face", url: "https://huggingface.co", kind: .official),
                InfoLink(title: "huggingface_hub — documentation", url: "https://huggingface.co/docs/huggingface_hub/index", kind: .docs),
                InfoLink(title: "Transformers — documentation", url: "https://huggingface.co/docs/transformers/index", kind: .docs),
                InfoLink(title: "Hugging Face — Wikipedia", url: "https://en.wikipedia.org/wiki/Hugging_Face", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "ollama",
            displayName: "Ollama",
            tagline: "Run large language models locally on macOS, Linux, and Windows — no cloud required.",
            description: "Ollama is a standalone runtime (available as a native Mac app and a CLI) that downloads and serves open-weight LLMs such as Llama, Mistral, and Gemma locally, exposing an OpenAI-compatible REST API. Model weights are stored as content-addressed blobs shared across tags; individual model families range from around 1 GB for small models to over 400 GB for the largest dense models. Removing a model via Ollama correctly handles blob reference counts rather than leaving orphaned files.",
            languageKey: nil,
            links: [
                InfoLink(title: "Ollama", url: "https://ollama.com", kind: .official),
                InfoLink(title: "Ollama — model library", url: "https://ollama.com/download", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "lmstudio",
            displayName: "LM Studio",
            tagline: "A GUI Mac app for discovering, downloading, and running local LLMs — no command line required.",
            description: "LM Studio is a native macOS (and Windows/Linux) application that lets users browse Hugging Face model repositories, download GGUF quantised models, and run them locally via a built-in chat interface and an OpenAI-compatible API server. Individual GGUF files range from around 3 GB for small quantised models to 40 GB or more for full-precision large models. The app supports GPU acceleration on Apple Silicon via Metal.",
            languageKey: nil,
            links: [
                InfoLink(title: "LM Studio", url: "https://lmstudio.ai", kind: .official),
                InfoLink(title: "LM Studio — documentation", url: "https://lmstudio.ai/docs", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "invokeai",
            displayName: "InvokeAI",
            tagline: "An open-source application for AI image generation built on Stable Diffusion, SDXL, and FLUX.",
            description: "InvokeAI is an open-source Python application that provides a professional web-based UI and API for Stable Diffusion, SDXL, and FLUX image generation models. Standard Stable Diffusion checkpoints are 2–7 GB each, while SDXL and FLUX models can reach 10–20 GB. InvokeAI can be installed as a Python package via PyPI or via its official installer.",
            languageKey: "python",
            links: [
                InfoLink(title: "InvokeAI", url: "https://invoke.ai", kind: .official),
                InfoLink(title: "InvokeAI — GitHub", url: "https://github.com/invoke-ai/InvokeAI", kind: .docs),
            ]
        ),

        // MARK: - Browser automation

        ToolInfo(
            key: "playwright",
            displayName: "Playwright",
            tagline: "A cross-browser end-to-end testing and automation library for web apps — from Microsoft.",
            description: "Playwright is a Node.js (and Python/Java/.NET) library for automating Chromium, Firefox, and WebKit browsers with a single API, designed for reliable end-to-end testing and web scraping. Browser binaries are downloaded at install time and cached globally; each browser is around 500 MB to 1 GB, and multiple versions accumulate as Playwright is updated across projects. Playwright can run browsers in headed or headless mode and supports network interception and request mocking.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Playwright", url: "https://playwright.dev", kind: .official),
                InfoLink(title: "Playwright — installation", url: "https://playwright.dev/docs/intro", kind: .docs),
                InfoLink(title: "Playwright (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Playwright_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "puppeteer",
            displayName: "Puppeteer",
            tagline: "A Node.js library that provides a high-level API to control Chrome or Firefox over the DevTools Protocol.",
            description: "Puppeteer is a JavaScript automation library maintained by the Chrome DevTools team that drives headless (or headed) Chrome and Firefox instances for scraping, screenshot generation, PDF export, and end-to-end testing. During install, Puppeteer downloads a bundled Chromium (or Firefox) binary to guarantee a known-good browser revision; the binary is around 200–300 MB and is re-downloaded for each Puppeteer release that ships a new browser revision. The cache location can be customised via a Puppeteer configuration file.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Puppeteer", url: "https://pptr.dev", kind: .official),
                InfoLink(title: "Puppeteer — configuration", url: "https://pptr.dev/guides/configuration", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "cypress",
            displayName: "Cypress",
            tagline: "An all-in-one JavaScript testing framework that runs directly in the browser — no WebDriver required.",
            description: "Cypress is an Electron-based end-to-end testing framework that runs tests inside the browser process, giving direct access to the DOM, network layer, and application state without the indirection of WebDriver. The Cypress binary is downloaded separately from the npm package and cached globally; each major version is around 500 MB, and multiple versions accumulate when different projects pin different Cypress releases. Cypress supports component testing in addition to full end-to-end tests.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Cypress", url: "https://www.cypress.io", kind: .official),
                InfoLink(title: "Cypress — why Cypress", url: "https://docs.cypress.io/app/get-started/why-cypress", kind: .docs),
                InfoLink(title: "Cypress — installation", url: "https://docs.cypress.io/app/get-started/install-cypress", kind: .docs),
                InfoLink(title: "Cypress (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Cypress_(software)", kind: .wiki),
            ]
        ),
    ]
}
