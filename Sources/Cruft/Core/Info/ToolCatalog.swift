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
            tagline: "A JavaScript runtime built on the V8 engine, used for server-side and tooling code.",
            description: "Node.js executes JavaScript outside the browser, supporting back-end services, CLIs, build tools, and desktop apps in JavaScript or TypeScript. It ships with npm and works with pnpm, Yarn, Bun, and other Node.js-compatible package managers. Node.js itself stores almost no persistent cache; the package managers layered on top do.",
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
            description: "npm ships with every Node.js installation and handles install, publish, and lifecycle script commands. Downloaded packages live in a content-addressable global cache so re-installs skip network requests when possible. Project dependencies are declared in `package.json` and pinned in `package-lock.json`.",
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
            tagline: "A package manager that hard-links dependencies from a single content-addressable store.",
            description: "pnpm stores every package version once in a global content-addressable store and links each project's `node_modules` entries into it, avoiding duplicate copies across projects. A built-in store-pruning command reclaims entries no live project references.",
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
            description: "Yarn (v2+, also called Berry) manages JavaScript dependencies with workspace support for monorepos and a focus on reproducibility. Compressed package archives are stored in a global cache reused across projects. Yarn also supports Plug'n'Play (PnP) mode as an alternative to a materialised `node_modules` tree.",
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
            tagline: "A JavaScript runtime and package manager built on JavaScriptCore.",
            description: "Bun combines a JavaScript/TypeScript runtime with an npm-compatible package manager, intended as a drop-in replacement for Node.js + npm. It keeps a global install cache so repeated installs reuse already-downloaded packages.",
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
            tagline: "A JavaScript and TypeScript runtime with built-in permission flags and tooling.",
            description: "Deno is a V8-based runtime, implemented in Rust, with native TypeScript support and built-in formatting, linting, and testing. It can install npm packages or import modules directly from URLs, and keeps a global module cache to avoid redundant downloads. Filesystem, network, and environment access requires explicit permission flags.",
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
            tagline: "A React framework with file-based routing, SSR, SSG, and API routes.",
            description: "Next.js is a React framework maintained by Vercel that provides file-based routing, server-side rendering, static site generation, and API routes. Build output contains compiled server and client bundles, static assets, and an incremental build cache. Both the App Router (React Server Components) and the older Pages Router are supported.",
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
            tagline: "A Vue.js framework with file-based routing, SSR, SSG, and auto-imports.",
            description: "Nuxt is the framework for Vue.js, providing file-based routing, server-side rendering, static site generation, and an auto-import system. During development and builds it writes compiled output, route manifests, and generated TypeScript definitions to a build directory. Nuxt 3 runs on the Nitro server engine, allowing deployment to serverless platforms and traditional Node.js servers.",
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
            tagline: "The Svelte application framework — routing, SSR, adapters, Vite-powered builds.",
            description: "SvelteKit is the official full-stack framework for Svelte, with file-based routing, server-side rendering, static site generation, and an adapter system for deploying to different platforms. It uses Vite for the dev server and production build. Build output holds generated route manifests, TypeScript config, and compiled code, all reproducible from source.",
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
            tagline: "A frontend build tool that uses native ES modules in dev and Rollup for production.",
            description: "Vite serves source files over native ES modules during development, avoiding bundling and enabling hot module replacement. Production builds go through Rollup with tree-shaking and code-splitting. Pre-bundled dependencies are cached in a project-local directory to avoid redundant work between dev server restarts.",
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
            tagline: "A zero-configuration web bundler for JavaScript, TypeScript, CSS, HTML, and assets.",
            description: "Parcel bundles JavaScript, TypeScript, CSS, HTML, images, and other assets without a configuration file. It caches the result of every file transformation so subsequent builds only reprocess changed files. The dev server supports tree-shaking, code splitting, and hot module replacement.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Parcel", url: "https://parceljs.org", kind: .official),
                InfoLink(title: "Parcel — documentation", url: "https://parceljs.org/docs/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "turborepo",
            displayName: "Turborepo",
            tagline: "A task runner for JavaScript and TypeScript monorepos with content-hash caching.",
            description: "Turborepo orchestrates build, test, lint, and other tasks across monorepo packages, using a content-hash task cache to skip work whose inputs haven't changed. It can also use Vercel's remote cache to share task results across team members and CI. Integrates with npm, pnpm, and Yarn workspaces.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Turborepo", url: "https://turborepo.dev", kind: .official),
                InfoLink(title: "Turborepo — documentation", url: "https://turborepo.dev/repo/docs", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "astro",
            displayName: "Astro",
            tagline: "A web framework for content-driven sites — zero client JS by default, opt-in islands.",
            description: "Astro renders components to static HTML at build time and ships no client-side JavaScript unless opted in via its component islands architecture. Components from React, Vue, Svelte, Solid, and other frameworks can coexist in the same project. Build output includes the deployable static site alongside generated TypeScript definitions and internal metadata.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Astro", url: "https://astro.build", kind: .official),
                InfoLink(title: "Astro — documentation", url: "https://docs.astro.build/en/getting-started/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "electron",
            displayName: "Electron",
            tagline: "A framework for building desktop apps with web technologies, bundling Chromium and Node.js.",
            description: "Electron embeds the Chromium rendering engine and a Node.js runtime into a single executable, allowing desktop apps for macOS, Windows, and Linux to be written in JavaScript, HTML, and CSS. The runtime binary is downloaded separately from the npm package and cached globally so it's shared across projects. VS Code, Slack, Figma, and GitHub Desktop are built on Electron.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Electron", url: "https://www.electronjs.org", kind: .official),
                InfoLink(title: "Electron — documentation", url: "https://www.electronjs.org/docs/latest/", kind: .docs),
                InfoLink(title: "Electron (software framework) — Wikipedia", url: "https://en.wikipedia.org/wiki/Electron_(software_framework)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "nvm",
            displayName: "nvm",
            tagline: "Node Version Manager — installs and switches between Node.js versions per shell.",
            description: "nvm is a shell-based Node.js version manager that downloads pre-built binaries into `~/.nvm/versions/node/<version>/` and switches the active version by adjusting `PATH`. A `.nvmrc` file pins a per-project version. Each installed version is a self-contained directory containing the Node.js binary, npm, and bundled docs.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "nvm — GitHub", url: "https://github.com/nvm-sh/nvm", kind: .official),
            ]
        ),

        ToolInfo(
            key: "fnm",
            displayName: "fnm",
            tagline: "A Rust-implemented Node.js version manager with per-directory auto-switching.",
            description: "fnm is written in Rust rather than as shell scripts, reducing shell-startup overhead compared to nvm. It installs Node.js versions under `~/Library/Application Support/fnm/node-versions/` (or a configurable location) and reads `.nvmrc` and `.node-version` files for per-project pinning. Shell integration switches versions automatically when entering a project directory.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "fnm — GitHub", url: "https://github.com/Schniz/fnm", kind: .official),
            ]
        ),

        ToolInfo(
            key: "n",
            displayName: "n",
            tagline: "A minimal Node.js version manager implemented as a single shell script.",
            description: "`n` installs Node.js versions into `$N_PREFIX/n/versions/node/<version>/` (defaulting to `/usr/local`) and switches the active version by replacing the system Node.js binary symlink. Unlike nvm and fnm, it requires no shell hooks or shell-init configuration.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "n — GitHub", url: "https://github.com/tj/n", kind: .official),
            ]
        ),

        // MARK: - Python

        ToolInfo(
            key: "pip",
            displayName: "pip",
            tagline: "The standard Python package installer, sourcing packages from PyPI.",
            description: "pip is the default package installer shipped with CPython, used to install libraries from the Python Package Index. It keeps a global wheel and HTTP cache so re-installs across environments avoid re-downloading. Project dependencies are declared in `requirements.txt` or `pyproject.toml`.",
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
            description: "uv replaces pip, pip-tools, and virtualenv with a single tool. A central package cache deduplicates downloaded wheels across environments. uv supports lockfiles for reproducible installs and has a built-in cache-pruning command to reclaim stale entries.",
            languageKey: "python",
            links: [
                InfoLink(title: "uv", url: "https://docs.astral.sh/uv", kind: .official),
                InfoLink(title: "uv — cache management", url: "https://docs.astral.sh/uv/concepts/cache/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "poetry",
            displayName: "Poetry",
            tagline: "Python dependency management and packaging driven by a single `pyproject.toml`.",
            description: "Poetry manages Python project dependencies, virtual environments, and package publishing from a unified `pyproject.toml`-based workflow. Downloaded packages are stored in a central cache and reused via symlinks from each environment. Poetry also builds and publishes packages to PyPI.",
            languageKey: "python",
            links: [
                InfoLink(title: "Poetry", url: "https://python-poetry.org", kind: .official),
                InfoLink(title: "Poetry — documentation", url: "https://python-poetry.org/docs/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "pyenv",
            displayName: "pyenv",
            tagline: "Python version manager that switches between installed Python versions per project.",
            description: "pyenv intercepts Python commands via shims on `PATH` and selects a global, per-project, or per-shell version. Each installed Python is a self-contained tree; removing a version directory frees that space. `.python-version` files pick the interpreter automatically per directory.",
            languageKey: "python",
            links: [
                InfoLink(title: "pyenv — GitHub", url: "https://github.com/pyenv/pyenv", kind: .official),
            ]
        ),

        ToolInfo(
            key: "conda",
            displayName: "Conda",
            tagline: "Cross-language package and environment manager — the basis of Anaconda and Miniconda.",
            description: "Conda manages packages and isolated environments for Python and other languages, and is the foundation of the Anaconda and Miniconda distributions. Downloaded package archives are cached in a package cache directory before being unpacked into environments. A built-in cleanup command removes cached tarballs and unused packages.",
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
            tagline: "Rust's official build system and package manager.",
            description: "Cargo is the official build tool and package manager for Rust, integrated with the `rustc` toolchain. Crate sources land in a global registry cache, and compiled artifacts go in a project-local `target/` directory. Dependencies are resolved from crates.io with lockfiles, and workspaces support multi-crate projects.",
            languageKey: "rust",
            links: [
                InfoLink(title: "Cargo", url: "https://doc.rust-lang.org/cargo/", kind: .official),
                InfoLink(title: "crates.io", url: "https://crates.io", kind: .official),
            ]
        ),

        ToolInfo(
            key: "rustup",
            displayName: "rustup",
            tagline: "The official Rust toolchain installer for stable, beta, and nightly channels.",
            description: "rustup installs and updates the Rust compiler (`rustc`), Cargo, and the standard library for any supported target triple. It manages stable, beta, and nightly toolchains and cross-compilation targets from a single command. Unused toolchains can be uninstalled and reinstalled at any time.",
            languageKey: "rust",
            links: [
                InfoLink(title: "rustup", url: "https://rustup.rs", kind: .official),
            ]
        ),

        // MARK: - Ruby

        ToolInfo(
            key: "bundler",
            displayName: "Bundler",
            tagline: "The standard Ruby dependency manager — locks gem versions via `Gemfile.lock`.",
            description: "Bundler resolves and installs the gem versions declared in a project's `Gemfile`, writing a `Gemfile.lock` that pins the full dependency graph. Gems can be installed into a shared system or user path, or into a project-local `vendor/bundle` directory for isolation. Bundler ships with Ruby's standard library.",
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
            description: "rbenv intercepts Ruby commands through shims at the front of `PATH`, reading `.ruby-version` files to pick the right interpreter per directory. Ruby versions are installed via the `ruby-build` plugin and stored as self-contained trees. Removing a version directory uninstalls it; it can be reinstalled at any time.",
            languageKey: "ruby",
            links: [
                InfoLink(title: "rbenv", url: "https://rbenv.org", kind: .official),
            ]
        ),

        ToolInfo(
            key: "rvm",
            displayName: "RVM",
            tagline: "Ruby Version Manager — installs Ruby interpreters and manages per-project gemsets.",
            description: "RVM installs and manages multiple Ruby versions plus gemsets that isolate gem dependencies between projects. It works through shell function overrides rather than shims, which can affect shell startup time. Rubies and gemsets are removed and reinstalled through RVM's own commands.",
            languageKey: "ruby",
            links: [
                InfoLink(title: "RVM", url: "https://rvm.io", kind: .official),
            ]
        ),

        ToolInfo(
            key: "chruby",
            displayName: "chruby",
            tagline: "A Ruby version switcher implemented as a small set of shell functions.",
            description: "chruby locates installed Ruby interpreters under `~/.rubies/` (or `/opt/rubies/`) and switches between them by editing `PATH` and `GEM_HOME`. It does not install Rubies itself — that's left to a companion tool like `ruby-install`.",
            languageKey: "ruby",
            links: [
                InfoLink(title: "chruby — GitHub", url: "https://github.com/postmodern/chruby", kind: .official),
            ]
        ),

        // MARK: - Go

        ToolInfo(
            key: "go-modules",
            displayName: "Go Modules",
            tagline: "Go's built-in dependency system — modules declared in `go.mod`, resolved by the toolchain.",
            description: "Go Modules define a project's module path and dependency versions in a `go.mod` file with a `go.sum` checksum database. The Go toolchain caches downloaded module sources and pre-compiled build artifacts in a user-level module cache. Modules are verified against the public checksum database at sum.golang.org.",
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
            tagline: "The standard Java build and dependency tool, driven by a `pom.xml` descriptor.",
            description: "Apache Maven builds Java projects from a Project Object Model (`pom.xml`), downloading declared dependencies from Maven Central and other repositories into a local repository cache. It follows a convention-over-configuration model with a standard directory layout and a lifecycle of phases (compile, test, package, install, deploy). The local repository accumulates multiple versions of the same artifacts over time.",
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
            tagline: "A build automation tool for Java, Kotlin, and Android with incremental builds.",
            description: "Gradle builds JVM projects (and more) from a Groovy or Kotlin DSL, with incremental builds and a local build cache. Downloaded dependencies and build-cache entries are stored in a user-level cache directory. It is the required build system for Android projects and supports parallel task execution across multi-project builds.",
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
            tagline: "The `dotnet` command — build, run, test, publish, and manage .NET projects.",
            description: "The .NET CLI (`dotnet`) is the primary command-line interface for creating, building, testing, and publishing .NET applications. It restores NuGet packages into a global NuGet cache shared across projects. Build outputs land in project-local `bin/` and `obj/` directories and are reproducible from source.",
            languageKey: "dotnet",
            links: [
                InfoLink(title: ".NET CLI", url: "https://learn.microsoft.com/en-us/dotnet/core/tools/", kind: .official),
            ]
        ),

        ToolInfo(
            key: "nuget",
            displayName: "NuGet",
            tagline: "The .NET package manager — `.nupkg` format, the nuget.org registry, and tooling.",
            description: "NuGet is the package management system for .NET: it defines the `.nupkg` format, hosts the public `nuget.org` registry, and integrates with the `dotnet` CLI and Visual Studio. Downloaded packages are extracted into a global packages folder shared across projects. `packages.lock.json` pins dependency versions for reproducible restores.",
            languageKey: "dotnet",
            links: [
                InfoLink(title: "NuGet", url: "https://www.nuget.org", kind: .official),
                InfoLink(title: "NuGet — what is NuGet", url: "https://learn.microsoft.com/en-us/nuget/what-is-nuget", kind: .docs),
                InfoLink(title: "NuGet — Wikipedia", url: "https://en.wikipedia.org/wiki/NuGet", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "omnisharp",
            displayName: "OmniSharp",
            tagline: "An open-source language server for C# and F# editor support outside Visual Studio.",
            description: "OmniSharp provides IntelliSense, refactoring, navigation, and diagnostics for C# and F# projects in editors like VS Code, Vim, Emacs, and Sublime Text. It runs as a background process per workspace and caches project metadata, NuGet asset graphs, and Roslyn analyzer state under a per-user directory.",
            languageKey: "dotnet",
            links: [
                InfoLink(title: "OmniSharp", url: "https://www.omnisharp.net/", kind: .official),
                InfoLink(title: "OmniSharp — GitHub", url: "https://github.com/OmniSharp/omnisharp-roslyn", kind: .official),
            ]
        ),

        // MARK: - PHP

        ToolInfo(
            key: "composer",
            displayName: "Composer",
            tagline: "PHP dependency management — `composer.json` for declared deps, `composer.lock` for pinning.",
            description: "Composer is the standard dependency manager for PHP, resolving packages from Packagist and other repositories according to `composer.json` and writing a `composer.lock` for reproducible installs. Dependencies are installed into a project-local `vendor/` directory. A global cache of downloaded package archives is reused across projects.",
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
            tagline: "The Dart and Flutter package manager, sourcing packages from pub.dev.",
            description: "pub is the built-in package manager for Dart and Flutter, resolving dependencies declared in `pubspec.yaml` and writing a `pubspec.lock` for reproducible installs. Downloaded packages live in a global cache shared across all Dart and Flutter projects on the machine. pub.dev hosts the public package registry.",
            languageKey: "dart",
            links: [
                InfoLink(title: "pub.dev", url: "https://pub.dev", kind: .official),
                InfoLink(title: "Dart — pub commands", url: "https://dart.dev/tools/pub/cmd", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "flutter",
            displayName: "Flutter",
            tagline: "A UI toolkit from Google for multi-platform apps written in Dart.",
            description: "Flutter compiles Dart code to native binaries for iOS, Android, macOS, Windows, and Linux, and to JavaScript/WebAssembly for the web. Build artifacts land in a project-local `build/` directory organised by target platform. The SDK caches engine binaries and tool artifacts that are recreated automatically when the SDK is updated.",
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
            tagline: "Apple's built-in Swift package manager, declared via `Package.swift`.",
            description: "Swift Package Manager (SwiftPM) is the official dependency manager and build system for Swift, integrated into both the `swift` command-line tools and Xcode. Resolved packages are checked out into a global cache for Xcode builds and into a project-local `.build/checkouts/` directory for command-line builds. Build artifacts live in the project's `.build/` directory and are reproducible from source.",
            languageKey: "swift",
            links: [
                InfoLink(title: "Swift Package Manager", url: "https://www.swift.org/package-manager/", kind: .official),
            ]
        ),

        ToolInfo(
            key: "cocoapods",
            displayName: "CocoaPods",
            tagline: "A dependency manager for Swift and Objective-C Cocoa projects, predating SwiftPM.",
            description: "CocoaPods manages library dependencies for Xcode projects via a `Podfile` and `Podfile.lock`, downloading pod source into a project-local `Pods/` directory and modifying the Xcode workspace. A global spec repository and download cache are reused across installs. CocoaPods remains in use for libraries not yet distributed as Swift packages.",
            languageKey: "swift",
            links: [
                InfoLink(title: "CocoaPods", url: "https://cocoapods.org", kind: .official),
                InfoLink(title: "CocoaPods — Wikipedia", url: "https://en.wikipedia.org/wiki/CocoaPods", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "carthage",
            displayName: "Carthage",
            tagline: "A decentralised Swift/Objective-C dependency manager that builds standalone frameworks.",
            description: "Carthage builds project dependencies as XCFrameworks (or `.framework` bundles) and leaves Xcode integration to the developer. Sources are cloned into a global `~/Library/Caches/org.carthage.CarthageKit/` cache and into a project-local `Carthage/` directory. It was widely used before Swift Package Manager matured and remains in use where its build model is preferred.",
            languageKey: "swift",
            links: [
                InfoLink(title: "Carthage — GitHub", url: "https://github.com/Carthage/Carthage", kind: .official),
            ]
        ),

        // MARK: - C / C++

        ToolInfo(
            key: "cmake",
            displayName: "CMake",
            tagline: "A cross-platform meta-build system that generates native build files from `CMakeLists.txt`.",
            description: "CMake reads `CMakeLists.txt` files and generates platform-native build scripts (Makefiles, Ninja build files, Xcode projects, Visual Studio solutions). Object files, compiled libraries, and executables accumulate in a separate build directory kept out of version control. Out-of-source builds keep source and build trees cleanly separated.",
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
            tagline: "A decentralised C/C++ package manager that integrates with multiple build systems.",
            description: "Conan resolves and installs C/C++ library dependencies, storing downloaded packages and compiled binaries in a user-level cache. Projects declare dependencies in `conanfile.txt` or `conanfile.py`. It integrates with CMake, Meson, Autotools, and others, and supports cross-compilation profiles for different target platforms.",
            languageKey: "cpp",
            links: [
                InfoLink(title: "Conan", url: "https://conan.io", kind: .official),
                InfoLink(title: "Conan — documentation", url: "https://docs.conan.io/2/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "vcpkg",
            displayName: "vcpkg",
            tagline: "Microsoft's open-source C/C++ package manager with CMake and MSBuild integration.",
            description: "vcpkg installs open-source C/C++ libraries on Windows, macOS, and Linux, integrating with CMake and MSBuild. Classic mode installs packages into a shared vcpkg tree; manifest mode uses a per-project `vcpkg.json` and stores built libraries in a project-local directory. All installed files are built from source and reproducible.",
            languageKey: "cpp",
            links: [
                InfoLink(title: "vcpkg", url: "https://vcpkg.io/en/", kind: .official),
                InfoLink(title: "vcpkg — Microsoft Learn", url: "https://learn.microsoft.com/en-us/vcpkg/", kind: .docs),
                InfoLink(title: "vcpkg — Wikipedia", url: "https://en.wikipedia.org/wiki/Vcpkg", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "ccache",
            displayName: "ccache",
            tagline: "A C/C++ compiler cache that reuses object files when inputs haven't changed.",
            description: "ccache wraps `gcc`, `clang`, and other C/C++ compilers, hashing each compilation's inputs (source, flags, headers) and serving previous outputs from a local cache on a hash hit. Cache entries are kept under `~/.cache/ccache/` (or `~/Library/Caches/ccache/`). On a hash miss it falls through to the real compiler, preserving correctness.",
            languageKey: "cpp",
            links: [
                InfoLink(title: "ccache", url: "https://ccache.dev/", kind: .official),
                InfoLink(title: "ccache — manual", url: "https://ccache.dev/manual/latest.html", kind: .docs),
                InfoLink(title: "Ccache — Wikipedia", url: "https://en.wikipedia.org/wiki/Ccache", kind: .wiki),
            ]
        ),

        // MARK: - Cross-language package managers

        ToolInfo(
            key: "homebrew",
            displayName: "Homebrew",
            tagline: "A package manager for macOS and Linux that installs CLI tools and GUI apps via `brew`.",
            description: "Homebrew manages open-source command-line tools and GUI apps on macOS and Linux. It resolves a formula to a pre-compiled bottle (or builds from source), tracks installed versions, and handles upgrade and removal. Casks extend Homebrew to macOS GUI applications distributed as `.dmg` or `.pkg` installers.",
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
            tagline: "A package manager for macOS that compiles ports from source under `/opt/local`.",
            description: "MacPorts provides a collection of Unix and open-source software for macOS, compiling each port from source (or from pre-built binaries where available) into a self-contained prefix. Downloaded source archives are cached locally to avoid redundant network fetches. Its dependency tree is independent of both the system and Homebrew.",
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
            tagline: "A purely functional package manager with reproducible, atomic builds.",
            description: "Nix builds packages in isolation and stores them in an immutable content-addressed store, so the same input always produces the same output across machines. Multiple versions of a package coexist without conflict because each is keyed by its full build closure. It also supports declarative system configuration (NixOS) and reproducible development shells via `nix develop`.",
            languageKey: nil,
            links: [
                InfoLink(title: "Nix", url: "https://nixos.org", kind: .official),
                InfoLink(title: "Nix — reference manual", url: "https://nix.dev/manual/nix/stable/", kind: .docs),
                InfoLink(title: "Nix (package manager) — Wikipedia", url: "https://en.wikipedia.org/wiki/Nix_(package_manager)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "asdf",
            displayName: "asdf",
            tagline: "A multi-language version manager driven by plugins, replacing rbenv, nvm, pyenv, etc.",
            description: "asdf manages installed runtimes for many languages through a plugin system: `asdf plugin add <name>` registers support for a language, and `asdf install <name> <version>` installs the interpreter under `~/.asdf/installs/<plugin>/<version>/`. Per-project versions are pinned via a `.tool-versions` file. Each installed runtime is a self-contained directory.",
            languageKey: nil,
            links: [
                InfoLink(title: "asdf", url: "https://asdf-vm.com/", kind: .official),
                InfoLink(title: "asdf — GitHub", url: "https://github.com/asdf-vm/asdf", kind: .official),
            ]
        ),

        // MARK: - Editors & IDEs

        ToolInfo(
            key: "zed",
            displayName: "Zed",
            tagline: "A code editor written in Rust with real-time collaboration and built-in AI features.",
            description: "Zed is an open-source code editor written in Rust, with real-time collaboration and an integrated AI assistant panel whose conversation history is persisted locally. Language server binaries are downloaded on demand and cached locally; Zed re-fetches them automatically when needed.",
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
            tagline: "A VS Code fork with an AI assistant that edits across files and runs commands.",
            description: "Cursor is a fork of VS Code that embeds an AI assistant capable of editing across files, running terminal commands, and maintaining multi-turn conversations. It stores AI chat history per workspace and accumulates V8 bytecode caches, Chromium caches, and logs in the same layout as VS Code. Extensions are compatible with the VS Code marketplace.",
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
            tagline: "Microsoft's open-source, Electron-based code editor with an extension marketplace.",
            description: "Visual Studio Code (VS Code) is a free, cross-platform code editor built on Electron, with an extension marketplace and Language Server Protocol (LSP) integration. It stores per-workspace state including open tabs, extension scratch data, and AI chat logs from extensions like GitHub Copilot Chat. V8 bytecode caches, Chromium HTTP caches, GPU shader caches, and session logs also accumulate over time.",
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
            tagline: "A family of language-specific IDEs sharing a common platform — IntelliJ, PyCharm, WebStorm, etc.",
            description: "JetBrains produces a suite of language-specific IDEs (IntelliJ IDEA, PyCharm, WebStorm, GoLand, CLion, Rider, RubyMine, and others) that share a common platform and cache layout. Per-product indexing caches accumulate as projects are opened and can be deleted safely — the IDE rebuilds indexes on next launch. Diagnostic logs are separate from the index and not needed for normal operation.",
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
            tagline: "A cross-platform text and code editor with a command palette and multi-cursor editing.",
            description: "Sublime Text is a cross-platform text and code editor with a command palette, Goto Anything navigation, and multi-cursor editing. Compiled syntax definitions, package metadata, and derived content are kept in a cache directory; the symbol and file index that powers Goto Anything is stored separately. Both are rebuilt automatically on next launch if cleared.",
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
            tagline: "An extensible text editor customised through Emacs Lisp.",
            description: "GNU Emacs is an extensible editor whose behaviour is customised in Emacs Lisp; through its package ecosystem it also functions as an email client, organiser, and more. Emacs 28+ natively compiles Elisp packages to machine code (`.eln` files) for faster execution, caching the results locally. Community configurations such as Doom Emacs add their own cache layers that are rebuilt on next launch if cleared.",
            languageKey: nil,
            links: [
                InfoLink(title: "GNU Emacs", url: "https://www.gnu.org/software/emacs/", kind: .official),
                InfoLink(title: "GNU Emacs — Wikipedia", url: "https://en.wikipedia.org/wiki/GNU_Emacs", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "neovim",
            displayName: "Neovim",
            tagline: "A fork of Vim with Lua scripting, a built-in LSP client, and a remote API.",
            description: "Neovim is a community-driven refactor of Vim that adds native Lua configuration, a built-in Language Server Protocol client, Tree-sitter syntax parsing, and a stable remote API. Following the XDG Base Directory spec, it separates logs, swap files, and plugin data into distinct cache and data directories. LSP server binaries managed by Mason.nvim are downloaded on demand and stored in a user-owned data directory.",
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
            tagline: "A modal terminal editor written in Rust with built-in Tree-sitter and LSP support.",
            description: "Helix is a terminal text editor inspired by Kakoune and implemented in Rust, with Tree-sitter syntax highlighting and Language Server Protocol support built in — no plugin manager required. It follows the XDG Base Directory specification, splitting configuration, cache, and data into standard directories. Editing uses a selections-first model rather than the operators-first model of Vim.",
            languageKey: nil,
            links: [
                InfoLink(title: "Helix", url: "https://helix-editor.com", kind: .official),
                InfoLink(title: "Helix — documentation", url: "https://docs.helix-editor.com", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "eclipse",
            displayName: "Eclipse IDE",
            tagline: "An open-source IDE platform from the Eclipse Foundation, primarily used for Java.",
            description: "Eclipse IDE is an open-source integrated development environment primarily used for Java, with language-specific packages extending it to C/C++, PHP, Python, and others. The Eclipse JDT Language Server (eclipse.jdt.ls) also powers Java IntelliSense in VS Code and other LSP clients. The workspace index grows as projects are analysed and is rebuilt automatically if cleared.",
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
            tagline: "Panic's native macOS code editor, built with AppKit rather than Electron.",
            description: "Nova is a native macOS code editor from Panic Inc., built with AppKit rather than an Electron wrapper. It supports extensions via a built-in marketplace, remote servers via SSH, and an integrated terminal. Application cache data accumulates over time and is rebuilt from installed extensions and projects on next launch.",
            languageKey: nil,
            links: [
                InfoLink(title: "Nova", url: "https://nova.app", kind: .official),
                InfoLink(title: "Nova — help", url: "https://nova.app/help/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "xcode",
            displayName: "Xcode",
            tagline: "Apple's IDE for macOS, iOS, iPadOS, watchOS, tvOS, and visionOS development.",
            description: "Xcode is the primary development environment for Apple platforms, integrating a source editor, Interface Builder, Instruments profiler, and the Simulator. Build intermediates accumulate in a DerivedData directory and are reproducible from source. Additional caches include device support files for connected hardware and SwiftPM repository clones.",
            languageKey: "swift",
            links: [
                InfoLink(title: "Xcode", url: "https://developer.apple.com/xcode/", kind: .official),
                InfoLink(title: "Xcode — Apple Developer", url: "https://developer.apple.com/documentation/xcode", kind: .docs),
                InfoLink(title: "Xcode — Wikipedia", url: "https://en.wikipedia.org/wiki/Xcode", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "metal",
            displayName: "Metal",
            tagline: "Apple's low-level GPU API for rendering and compute on Apple platforms.",
            description: "Metal is the GPU API every Apple-platform graphics or compute workload bottoms out on — directly through apps written against `MTLDevice`, or transitively through wgpu, MoltenVK (Vulkan-on-Mac), Apple's MPS and MLX, PyTorch's MPS backend, and SwiftUI / Core Animation. The driver compiles MSL into AIR (Apple's intermediate representation) and caches the binaries per-process: bundled apps get their own `<bundle-id>/com.apple.metal/` subdirectory under the per-user Darwin cache, while non-bundled binaries (anything launched via `cargo run`, `swift run`, or a script interpreter) share the top-level `com.apple.metal/` pool.",
            languageKey: "swift",
            links: [
                InfoLink(title: "Metal", url: "https://developer.apple.com/metal/", kind: .official),
                InfoLink(title: "Metal Shading Language Specification", url: "https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf", kind: .docs),
                InfoLink(title: "Metal — Apple Developer Documentation", url: "https://developer.apple.com/documentation/metal", kind: .docs),
                InfoLink(title: "Metal (API) — Wikipedia", url: "https://en.wikipedia.org/wiki/Metal_(API)", kind: .wiki),
            ]
        ),

        // MARK: - Elixir

        ToolInfo(
            key: "hex",
            displayName: "Hex",
            tagline: "The package registry for the Erlang ecosystem, used by both Mix (Elixir) and rebar3.",
            description: "Hex is the central package registry and client for Elixir and Erlang, hosted at hex.pm. Mix integrates Hex natively; declaring a dependency in `mix.exs` and running `mix deps.get` downloads tarballs into a global cache and unpacks source into the project's `deps/` directory. rebar3 uses Hex for Erlang projects the same way.",
            languageKey: "elixir",
            links: [
                InfoLink(title: "Hex", url: "https://hex.pm", kind: .official),
                InfoLink(title: "Hex — Mix tasks", url: "https://hexdocs.pm/hex/Mix.Tasks.Hex.html", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "rebar3",
            displayName: "rebar3",
            tagline: "The standard build tool for Erlang — handles dependencies, builds, releases, and tests.",
            description: "rebar3 is the canonical build tool for Erlang/OTP projects, configured via `rebar.config`. It resolves dependencies through Hex, compiles `.erl` source to BEAM bytecode, and builds OTP releases. Build artifacts and downloaded dependencies live in `_build/` per project, with a global cache under `~/.cache/rebar3/` storing fetched packages and compiled artifacts shared across projects.",
            languageKey: "elixir",
            links: [
                InfoLink(title: "rebar3", url: "https://rebar3.org/", kind: .official),
                InfoLink(title: "rebar3 — documentation", url: "https://rebar3.org/docs/", kind: .docs),
                InfoLink(title: "rebar3 — GitHub", url: "https://github.com/erlang/rebar3", kind: .official),
            ]
        ),

        // MARK: - Haskell

        ToolInfo(
            key: "ghcup",
            displayName: "ghcup",
            tagline: "Installer for the Haskell toolchain — manages GHC, Cabal, Stack, and HLS.",
            description: "ghcup is the standard installer for Haskell on macOS and Linux: a single CLI that downloads and switches between GHC compiler versions, Cabal, Stack, and the Haskell Language Server. Installed toolchains live under `~/.ghcup/ghc/` and shared download caches under `~/.ghcup/cache/`. Per-project compiler versions are pinned via `cabal.project` or shell tooling.",
            languageKey: "haskell",
            links: [
                InfoLink(title: "ghcup", url: "https://www.haskell.org/ghcup/", kind: .official),
                InfoLink(title: "ghcup — GitLab", url: "https://gitlab.haskell.org/haskell/ghcup-hs", kind: .official),
            ]
        ),

        // MARK: - Build systems & containers

        ToolInfo(
            key: "bazel",
            displayName: "Bazel",
            tagline: "A language-agnostic build and test system with hermetic sandboxing and action caching.",
            description: "Bazel is a multi-language, multi-platform build system that uses hermetic sandboxing and a content-addressed action cache for incremental, reproducible builds. The action cache, downloaded external repository sources, and build outputs all live under a user-level output root. Remote caching and remote execution allow build artifacts to be shared across a team.",
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
            description: "Docker packages applications and their dependencies into portable container images that run consistently across development, staging, and production. On macOS, Docker Desktop stores all images, containers, volumes, and build cache inside a single sparse virtual-machine disk image. Built-in pruning commands reclaim space from unused images, stopped containers, and dangling build cache.",
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
            description: "Gatsby is a React framework for building static websites, pulling content from Markdown files, CMSes, APIs, and databases through a unified GraphQL data layer. Build output contains an incremental build cache and webpack bundles alongside the deployable static site. A plugin ecosystem covers headless CMSes and third-party APIs.",
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
            tagline: "An open-source static site generator from Meta for documentation websites.",
            description: "Docusaurus is a React-based documentation site generator that supports versioning, internationalization, and full-text search. The compiled static site and incremental build metadata are reproducible from source. MDX support allows React components to be embedded directly in Markdown.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Docusaurus", url: "https://docusaurus.io", kind: .official),
                InfoLink(title: "Docusaurus — documentation", url: "https://docusaurus.io/docs", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "eleventy",
            displayName: "Eleventy",
            tagline: "A static site generator that ships no client-side JavaScript by default.",
            description: "Eleventy (11ty) is a JavaScript-based static site generator that supports a range of template languages — Nunjucks, Liquid, Markdown, HTML, JavaScript, and more — without imposing a front-end framework. Output is plain HTML, CSS, and static assets, generated entirely from source. JavaScript bundling and CSS preprocessing are left to the author.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Eleventy", url: "https://www.11ty.dev", kind: .official),
                InfoLink(title: "Eleventy — documentation", url: "https://www.11ty.dev/docs/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "hexo",
            displayName: "Hexo",
            tagline: "A Node.js blog framework that turns Markdown posts and themes into a static site.",
            description: "Hexo converts Markdown posts and configurable themes into a static site, including rendered HTML pages, feed files, and a sitemap. Generated output is reproducible from source. Plugins handle deployment to GitHub Pages, Heroku, and other hosting targets.",
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
            description: "Hugo is a Go-based static site generator. Authors write content in Markdown and structure layouts with Go's html/template system. Build output contains the deployable static site alongside a processed asset pipeline cache; both are regenerated from source on each build.",
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
            tagline: "A blog-aware static site generator written in Ruby — the engine behind GitHub Pages.",
            description: "Jekyll is a Ruby-based static site generator that transforms Markdown content and Liquid templates into a website. It is the engine behind GitHub Pages and is widely used for documentation and blogs. The compiled site and incremental build cache are reproducible from source. Ruby plugins extend the build pipeline with custom logic.",
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
            tagline: "A Python documentation site generator driven by Markdown and `mkdocs.yml`.",
            description: "MkDocs reads Markdown files and a `mkdocs.yml` configuration to produce a static site suitable for GitHub Pages, Read the Docs, or any static host. Output is written to a `site/` directory and is reproducible from source. Python plugins declared in `mkdocs.yml` extend the build pipeline.",
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
            tagline: "A Python static site generator with Markdown, reStructuredText, and Jinja2 templates.",
            description: "Pelican converts Markdown and reStructuredText content into a website using Jinja2 templates. A `pelicanconf.py` file controls site configuration, and the plugin system lets authors extend the build with arbitrary Python code. Output is reproducible from source.",
            languageKey: "python",
            links: [
                InfoLink(title: "Pelican", url: "https://getpelican.com", kind: .official),
            ]
        ),

        ToolInfo(
            key: "zola",
            displayName: "Zola",
            tagline: "A static site generator written in Rust and shipped as a single binary.",
            description: "Zola is a Rust-based static site generator distributed as a single binary with no dependencies, including built-in Sass compilation, syntax highlighting, and shortcodes. Content is written in Markdown and laid out with Tera templates; no Rust knowledge is required. Output is reproducible from source.",
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
            tagline: "A deep learning framework built around dynamic computation graphs, backed by Meta AI.",
            description: "PyTorch is a Python deep learning framework used across research and production ML systems. Pretrained model weights are cached locally; checkpoints for large transformers can be sizeable. It integrates with the Python scientific-computing stack (NumPy, SciPy, Pandas) and with CUDA and Metal for GPU acceleration.",
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
            tagline: "A machine learning platform from Google with the Keras API and graph computation.",
            description: "TensorFlow is a machine learning platform offering a high-level Keras API and low-level graph-based computation for custom training loops. Datasets downloaded via TensorFlow Datasets (TFDS) are cached locally, and model weights for large benchmarks can be substantial. Deployment targets include CPUs, GPUs, TPUs, and edge devices via TensorFlow Lite.",
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
            tagline: "A high-level deep learning API that runs on JAX, TensorFlow, or PyTorch.",
            description: "Keras is a neural network API focused on modular, quickly-iterable models; since Keras 3 it runs on top of JAX, TensorFlow, or PyTorch interchangeably. Pretrained weights for built-in application models (ResNet, EfficientNet, VGG, and others) are cached locally, and weights for larger architectures can be sizeable. Available as a standalone `keras` package from PyPI.",
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
            tagline: "Object detection and computer vision models — the YOLO11 and YOLOv8 families.",
            description: "Ultralytics distributes the YOLOv8 and YOLO11 families of object detection, segmentation, pose-estimation, and classification models. Pretrained weights are downloaded automatically on first use and cached locally; custom checkpoints can be sizeable. The package is on PyPI and supports ONNX and TensorRT export for edge deployment.",
            languageKey: "python",
            links: [
                InfoLink(title: "Ultralytics", url: "https://docs.ultralytics.com", kind: .official),
            ]
        ),

        ToolInfo(
            key: "huggingface",
            displayName: "Hugging Face",
            tagline: "A hub for open-source AI models and datasets, with Python libraries to consume them.",
            description: "Hugging Face is a hosting platform (Hub) and a set of Python libraries — `transformers`, `diffusers`, `datasets` — providing pretrained models for NLP, computer vision, and audio tasks. Downloaded model repositories are cached locally via a content-addressed blob store; large LLMs and diffusion checkpoints can be very large on disk. The optional Xet storage layer adds chunk-level deduplication across related model versions.",
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
            tagline: "A local runtime for open-weight LLMs on macOS, Linux, and Windows.",
            description: "Ollama is a standalone runtime (a native Mac app and a CLI) that downloads and serves open-weight LLMs such as Llama, Mistral, and Gemma locally, exposing an OpenAI-compatible REST API. Model weights are stored as content-addressed blobs shared across tags; weights are large on disk. Removing a model via Ollama handles blob reference counts rather than leaving orphaned files behind.",
            languageKey: nil,
            links: [
                InfoLink(title: "Ollama", url: "https://ollama.com", kind: .official),
                InfoLink(title: "Ollama — model library", url: "https://ollama.com/download", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "lmstudio",
            displayName: "LM Studio",
            tagline: "A GUI app for discovering, downloading, and running local LLMs.",
            description: "LM Studio is a desktop application for macOS, Windows, and Linux that browses Hugging Face model repositories, downloads GGUF quantised models, and runs them locally via a built-in chat interface and an OpenAI-compatible API server. Quantised model files vary widely in size depending on parameter count and precision. GPU acceleration on Apple Silicon goes through Metal.",
            languageKey: nil,
            links: [
                InfoLink(title: "LM Studio", url: "https://lmstudio.ai", kind: .official),
                InfoLink(title: "LM Studio — documentation", url: "https://lmstudio.ai/docs", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "invokeai",
            displayName: "InvokeAI",
            tagline: "An open-source AI image generation app for Stable Diffusion, SDXL, and FLUX.",
            description: "InvokeAI is an open-source Python application providing a web UI and API for Stable Diffusion, SDXL, and FLUX image generation models. Model checkpoints are large on disk and accumulate as different base models and fine-tunes are downloaded. It can be installed as a Python package via PyPI or via its own installer.",
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
            tagline: "A cross-browser end-to-end testing and automation library, from Microsoft.",
            description: "Playwright is a library for driving Chromium, Firefox, and WebKit through a single API, used for end-to-end testing and scripted browser automation. Browser binaries are downloaded at install time and cached globally, with multiple versions accumulating as the library is updated. It runs browsers headed or headless and supports network interception and request mocking.",
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
            tagline: "A Node.js library that drives Chrome and Firefox over the DevTools Protocol.",
            description: "Puppeteer is a JavaScript automation library maintained by the Chrome DevTools team that drives headless (or headed) Chrome and Firefox instances for scraping, screenshot generation, PDF export, and end-to-end testing. On install it downloads a bundled Chromium (or Firefox) binary to guarantee a known-good browser revision; a new binary is fetched for each Puppeteer release that pins a new revision. The cache location is configurable via a Puppeteer config file.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Puppeteer", url: "https://pptr.dev", kind: .official),
                InfoLink(title: "Puppeteer — configuration", url: "https://pptr.dev/guides/configuration", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "cypress",
            displayName: "Cypress",
            tagline: "A JavaScript testing framework that runs tests directly inside the browser process.",
            description: "Cypress is an Electron-based end-to-end testing framework that runs tests inside the browser process, giving direct access to the DOM, network layer, and application state without the indirection of WebDriver. The Cypress binary is downloaded separately from the npm package and cached globally, with multiple versions accumulating when projects pin different releases. Component testing is supported alongside full end-to-end tests.",
            languageKey: "javascript",
            links: [
                InfoLink(title: "Cypress", url: "https://www.cypress.io", kind: .official),
                InfoLink(title: "Cypress — why Cypress", url: "https://docs.cypress.io/app/get-started/why-cypress", kind: .docs),
                InfoLink(title: "Cypress — installation", url: "https://docs.cypress.io/app/get-started/install-cypress", kind: .docs),
                InfoLink(title: "Cypress (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Cypress_(software)", kind: .wiki),
            ]
        ),

        // MARK: - VMs & Containers

        ToolInfo(
            key: "orbstack",
            displayName: "OrbStack",
            tagline: "A macOS Docker, Linux, and Kubernetes runtime built on Apple's Virtualization framework.",
            description: "OrbStack runs containers and Linux machines via Apple's Virtualization framework, supporting Docker, Kubernetes, and full Linux distros side by side. The entire runtime — every image, container, volume, and Linux machine — is backed by a single sparse virtualization disk image (`data.img.raw`), which grows as state accumulates.",
            languageKey: nil,
            links: [
                InfoLink(title: "OrbStack", url: "https://orbstack.dev/", kind: .official),
                InfoLink(title: "OrbStack — documentation", url: "https://docs.orbstack.dev/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "vagrant",
            displayName: "Vagrant",
            tagline: "HashiCorp's declarative VM provisioning tool, driven by a `Vagrantfile`.",
            description: "Vagrant describes a reproducible VM environment in a `Vagrantfile` and spins it up against a chosen provider (VirtualBox by default on macOS, with Parallels and VMware as alternatives). It keeps two distinct caches: a global library of downloaded \"boxes\" (base VM templates) under `~/.vagrant.d/boxes/`, and a per-project `.vagrant/` directory containing the live cloned VM state.",
            languageKey: nil,
            links: [
                InfoLink(title: "Vagrant", url: "https://www.vagrantup.com/", kind: .official),
                InfoLink(title: "Vagrant — documentation", url: "https://developer.hashicorp.com/vagrant/docs", kind: .docs),
                InfoLink(title: "Vagrant (software) — Wikipedia", url: "https://en.wikipedia.org/wiki/Vagrant_(software)", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "virtualbox",
            displayName: "VirtualBox",
            tagline: "Oracle's open-source x86/AMD64 virtualization hypervisor for desktop hosts.",
            description: "VirtualBox runs guest operating systems as VMs on top of a host. On macOS it supports Intel hosts and, via experimental Apple Silicon builds, ARM64. Each VM lives in its own directory under `~/VirtualBox VMs/<name>/`, holding the disk images (`.vdi` / `.vmdk`), config (`.vbox`), snapshots, and logs. Global registry and host-only network state lives separately in `~/Library/VirtualBox/`.",
            languageKey: nil,
            links: [
                InfoLink(title: "VirtualBox", url: "https://www.virtualbox.org/", kind: .official),
                InfoLink(title: "VirtualBox — manual", url: "https://www.virtualbox.org/manual/", kind: .docs),
                InfoLink(title: "VirtualBox — Wikipedia", url: "https://en.wikipedia.org/wiki/VirtualBox", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "utm",
            displayName: "UTM",
            tagline: "An open-source macOS frontend for QEMU and Apple's Virtualization framework.",
            description: "UTM is a graphical macOS application that wraps QEMU (full emulation, any architecture) and Apple's Virtualization framework (paravirtualized ARM64 guests). VMs are stored as `.utm` bundles under UTM's sandboxed Container directory, each containing the qcow2 disk(s), NVRAM/EFI variables, and configuration plist. The bundles are self-contained and can be moved between machines.",
            languageKey: nil,
            links: [
                InfoLink(title: "UTM", url: "https://getutm.app/", kind: .official),
                InfoLink(title: "UTM — documentation", url: "https://docs.getutm.app/", kind: .docs),
                InfoLink(title: "UTM — GitHub", url: "https://github.com/utmapp/UTM", kind: .official),
            ]
        ),

        ToolInfo(
            key: "vmware-fusion",
            displayName: "VMware Fusion",
            tagline: "Broadcom/VMware's Mac desktop hypervisor for Windows, Linux, and other guests.",
            description: "VMware Fusion is the macOS member of the VMware desktop hypervisor family (alongside Workstation on Linux/Windows), running guests on Intel and Apple Silicon hosts. Each VM is a `.vmwarevm` bundle containing the `.vmdk` disk(s), `.nvram`, `.vmx` config, and any snapshots. Fusion became free for personal use in 2024 and free for all use, including commercial, in 2025.",
            languageKey: nil,
            links: [
                InfoLink(title: "VMware Fusion", url: "https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion", kind: .official),
                InfoLink(title: "VMware Fusion — Wikipedia", url: "https://en.wikipedia.org/wiki/VMware_Fusion", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "parallels",
            displayName: "Parallels Desktop",
            tagline: "A commercial macOS virtualization app focused on Windows-on-Mac integration.",
            description: "Parallels Desktop runs Linux, Windows, and (on Apple Silicon) macOS guest VMs with host integration features such as Coherence mode, which renders Windows apps as host-window peers, and shared folders between guest and host. VMs are stored as `.pvm` bundles (Linux/Windows) or `.macvm` bundles (macOS guests on Apple Silicon) under `~/Parallels/`. The App Store edition uses a different Group Container path for sandboxing reasons.",
            languageKey: nil,
            links: [
                InfoLink(title: "Parallels Desktop", url: "https://www.parallels.com/products/desktop/", kind: .official),
                InfoLink(title: "Parallels — knowledge base", url: "https://kb.parallels.com/", kind: .docs),
                InfoLink(title: "Parallels Desktop — Wikipedia", url: "https://en.wikipedia.org/wiki/Parallels_Desktop_for_Mac", kind: .wiki),
            ]
        ),

        ToolInfo(
            key: "lima",
            displayName: "Lima",
            tagline: "Linux-on-Mac VM manager — the engine behind Colima and Rancher Desktop.",
            description: "Lima (\"Linux Machines\") provisions and manages headless Linux VMs on macOS via Apple's Virtualization framework or QEMU, configured by YAML. Each instance lives under `~/.lima/<instance>/` with its disk image, cloud-init config, and runtime sockets. Cached cloud-image downloads (Ubuntu, Fedora, Alpine, and others) are kept under `~/Library/Caches/lima/download/`, keyed by URL hash for reuse.",
            languageKey: nil,
            links: [
                InfoLink(title: "Lima", url: "https://lima-vm.io/", kind: .official),
                InfoLink(title: "Lima — internals", url: "https://lima-vm.io/docs/dev/internals/", kind: .docs),
                InfoLink(title: "Lima — GitHub", url: "https://github.com/lima-vm/lima", kind: .official),
            ]
        ),

        ToolInfo(
            key: "colima",
            displayName: "Colima",
            tagline: "A container runtime for macOS built on Lima, as an alternative to Docker Desktop.",
            description: "Colima runs containers (Docker, containerd, Kubernetes via k3s) inside a Lima-managed Linux VM. Each profile gets its own Lima VM under `~/.colima/_lima/<profile>/`; the VM's disk holds every OCI image, container, and named volume. Since v0.9.0 container-runtime data lives on a separate disk, so `colima delete --data` can wipe just container state without re-provisioning the VM.",
            languageKey: nil,
            links: [
                InfoLink(title: "Colima — GitHub", url: "https://github.com/abiosoft/colima", kind: .official),
            ]
        ),

        // MARK: - AI coding agents

        ToolInfo(
            key: "claude-code",
            displayName: "Claude Code",
            tagline: "Anthropic's terminal coding agent for the Claude family of models.",
            description: "Claude Code is a terminal-resident agentic coding tool from Anthropic. It performs file edits, shell commands, and multi-step plans against the working directory, and persists each session as a JSONL transcript so conversations can be resumed across runs. It also ships an in-IDE companion for VS Code and JetBrains.",
            languageKey: nil,
            links: [
                InfoLink(title: "Claude Code", url: "https://platform.claude.com/docs/en/docs/agents/claude-code/overview", kind: .official),
                InfoLink(title: "Claude Code — GitHub", url: "https://github.com/anthropics/claude-code", kind: .official),
            ]
        ),

        ToolInfo(
            key: "codex-cli",
            displayName: "OpenAI Codex CLI",
            tagline: "OpenAI's open-source command-line coding agent.",
            description: "Codex CLI is OpenAI's terminal agent, built around the `gpt-codex` family of coding models. It edits files, runs commands inside a sandbox, and supports session resume via local JSONL `rollout` files. Released as open source on GitHub and configurable via the `CODEX_HOME` environment variable.",
            languageKey: nil,
            links: [
                InfoLink(title: "OpenAI Codex CLI", url: "https://developers.openai.com/codex/cli", kind: .official),
                InfoLink(title: "OpenAI Codex CLI — GitHub", url: "https://github.com/openai/codex", kind: .official),
            ]
        ),

        ToolInfo(
            key: "opencode",
            displayName: "OpenCode",
            tagline: "An open-source, model-agnostic terminal coding agent from SST.",
            description: "OpenCode is an open-source TUI coding agent maintained by the SST team. It runs in the terminal and supports many model backends (Claude, OpenAI, Google, local models via Ollama, and others), positioned as an alternative to closed-source agents like Claude Code and Codex CLI. On macOS it follows the XDG Base Directory layout, storing session data under `~/.local/share/opencode/`.",
            languageKey: nil,
            links: [
                InfoLink(title: "OpenCode", url: "https://opencode.ai/", kind: .official),
                InfoLink(title: "OpenCode — documentation", url: "https://opencode.ai/docs", kind: .docs),
                InfoLink(title: "OpenCode — GitHub", url: "https://github.com/sst/opencode", kind: .official),
            ]
        ),

        ToolInfo(
            key: "gemini-cli",
            displayName: "Gemini CLI",
            tagline: "Google's open-source command-line agent for Gemini models.",
            description: "Gemini CLI is Google's terminal coding assistant for the Gemini family of models. It performs multi-step file edits, runs shell commands, and shares the same model and tool stack as Gemini Code Assist in supported IDEs. Released under google-gemini/gemini-cli on GitHub.",
            languageKey: nil,
            links: [
                InfoLink(title: "Gemini CLI — GitHub", url: "https://github.com/google-gemini/gemini-cli", kind: .official),
                InfoLink(title: "Gemini for developers", url: "https://ai.google.dev/gemini-api/docs", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "aider",
            displayName: "Aider",
            tagline: "An open-source pair-programming CLI built around git as the system of record.",
            description: "Aider is a terminal coding assistant that records every model-generated change as a git commit, so the session is reversible with standard git tooling. It builds a `repo map` from ctags and Tree-sitter so the model can reason about the wider codebase, and supports many model backends (OpenAI, Anthropic, Gemini, local models via Ollama).",
            languageKey: nil,
            links: [
                InfoLink(title: "Aider", url: "https://aider.chat/", kind: .official),
                InfoLink(title: "Aider — repo map", url: "https://aider.chat/docs/repomap.html", kind: .docs),
                InfoLink(title: "Aider — GitHub", url: "https://github.com/Aider-AI/aider", kind: .official),
            ]
        ),

        ToolInfo(
            key: "continue",
            displayName: "Continue",
            tagline: "An open-source AI assistant for VS Code and JetBrains, distributed as an extension.",
            description: "Continue adds chat, autocomplete, and codebase-aware retrieval to VS Code and JetBrains IDEs. It supports multiple model backends and stores per-workspace LanceDB embeddings under `~/.continue/index/` so completions and chat answers can be grounded in the user's actual code.",
            languageKey: nil,
            links: [
                InfoLink(title: "Continue", url: "https://www.continue.dev/", kind: .official),
                InfoLink(title: "Continue — GitHub", url: "https://github.com/continuedev/continue", kind: .official),
            ]
        ),

        ToolInfo(
            key: "cline",
            displayName: "Cline",
            tagline: "An open-source autonomous coding agent that runs as a VS Code extension.",
            description: "Cline (originally Claude Dev) performs multi-step coding tasks inside VS Code, requesting user approval for each tool call. After every action it captures a shadow-git checkpoint so any change can be rolled back; on large repos, the checkpoint store grows quickly.",
            languageKey: nil,
            links: [
                InfoLink(title: "Cline", url: "https://cline.bot/", kind: .official),
                InfoLink(title: "Cline — checkpoints", url: "https://docs.cline.bot/features/checkpoints", kind: .docs),
                InfoLink(title: "Cline — GitHub", url: "https://github.com/cline/cline", kind: .official),
            ]
        ),

        ToolInfo(
            key: "goose",
            displayName: "Goose",
            tagline: "An open-source, extensible AI agent framework from Block.",
            description: "Goose is an on-machine AI agent developed by Block (Square / Cash App). It uses Model Context Protocol (MCP) servers as its extension mechanism, ships as both a desktop app and a CLI, and is model-agnostic.",
            languageKey: nil,
            links: [
                InfoLink(title: "Goose", url: "https://block.github.io/goose/", kind: .official),
                InfoLink(title: "Goose — GitHub", url: "https://github.com/block/goose", kind: .official),
            ]
        ),

        ToolInfo(
            key: "windsurf",
            displayName: "Windsurf",
            tagline: "A standalone IDE from Codeium with built-in AI agent and inline completions.",
            description: "Windsurf is Codeium's standalone coding IDE, built on a forked VS Code base. Its agent (Cascade) and inline completions ship in-app, backed by the Codeium daemon and on-disk indexes of any open codebase. Codeium also offers extension-only versions for stock VS Code and JetBrains, separate from the Windsurf application.",
            languageKey: nil,
            links: [
                InfoLink(title: "Windsurf", url: "https://windsurf.com/", kind: .official),
                InfoLink(title: "Windsurf — documentation", url: "https://docs.windsurf.com/", kind: .docs),
            ]
        ),

        ToolInfo(
            key: "openhands",
            displayName: "OpenHands",
            tagline: "An open-source platform for autonomous coding agents in a sandboxed Docker runtime.",
            description: "OpenHands runs AI agents that can execute code, browse the web, and run shell commands inside a sandboxed Docker runtime. It supports many model backends and ships as a Docker image plus a web UI and CLI for issuing tasks. Originally developed under the name OpenDevin before being renamed.",
            languageKey: nil,
            links: [
                InfoLink(title: "OpenHands — documentation", url: "https://docs.openhands.dev/", kind: .docs),
                InfoLink(title: "OpenHands — GitHub", url: "https://github.com/All-Hands-AI/OpenHands", kind: .official),
            ]
        ),
    ]
}
