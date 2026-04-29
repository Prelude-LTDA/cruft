import Foundation

/// Keyed lookup table of `EcosystemInfo`. The info panel surfaces one of these
/// for rules whose ecosystem has a registered entry (currently just `.ssg` —
/// the category sits above individual tools like Hugo, Zola, Gatsby, etc.).
///
/// Keep entries sparing — we only add one when the *category* itself is worth
/// explaining. For buckets that just mirror a language (`.node`, `.rust`,
/// `.python`, …), the language section already covers it.
enum EcosystemCatalog {
    static let all: [Ecosystem: EcosystemInfo] = Dictionary(
        uniqueKeysWithValues: entries.map { ($0.ecosystem, $0) }
    )

    static func info(for ecosystem: Ecosystem) -> EcosystemInfo? {
        all[ecosystem]
    }

    private static let entries: [EcosystemInfo] = [
        EcosystemInfo(
            ecosystem: .ssg,
            displayName: "Static Site Generators",
            tagline: "Tools that pre-render a website from source files into static HTML, CSS, and assets.",
            description: "Static site generators compile content (typically Markdown) and templates into a folder of static files at build time, rather than assembling pages on every request. The output directory is reproducible from source and usually accounts for the bulk of an SSG project's disk footprint.",
            links: [
                InfoLink(title: "Static site generator — Wikipedia", url: "https://en.wikipedia.org/wiki/Static_site_generator", kind: .wiki),
                InfoLink(title: "Jamstack", url: "https://jamstack.org/", kind: .official),
                InfoLink(title: "Jamstack — SSG directory", url: "https://jamstack.org/generators/", kind: .docs),
            ]
        ),
        EcosystemInfo(
            ecosystem: .packageManager,
            displayName: "Package Managers",
            tagline: "System-level tools that install and manage open-source software outside the App Store.",
            description: "macOS package managers like Homebrew, MacPorts, and Nix install command-line tools, libraries, and runtimes that don't ship with the OS. Each maintains its own prefix containing downloaded archives, compiled binaries, and package metadata, with old versions accumulating across upgrades.",
            links: [
                InfoLink(title: "Package manager — Wikipedia", url: "https://en.wikipedia.org/wiki/Package_manager", kind: .wiki),
                InfoLink(title: "Homebrew", url: "https://brew.sh/", kind: .official),
                InfoLink(title: "MacPorts", url: "https://www.macports.org/", kind: .official),
                InfoLink(title: "Nix & NixOS", url: "https://nixos.org/", kind: .official),
            ]
        ),
        EcosystemInfo(
            ecosystem: .ide,
            displayName: "Editors & IDEs",
            tagline: "Code editors and integrated development environments, from text editors to full IDEs.",
            description: "Editors and IDEs maintain on-disk caches that speed up code completion, symbol search, incremental builds, and full-text search. Installed extensions, language servers, and themes add further bulk in per-user support directories, and few editors surface a built-in cleanup pass.",
            links: [
                InfoLink(title: "Integrated development environment — Wikipedia", url: "https://en.wikipedia.org/wiki/Integrated_development_environment", kind: .wiki),
                InfoLink(title: "Source-code editor — Wikipedia", url: "https://en.wikipedia.org/wiki/Source-code_editor", kind: .wiki),
            ]
        ),
        EcosystemInfo(
            ecosystem: .ai,
            displayName: "Local AI & ML",
            tagline: "Local LLM runtimes and ML frameworks that cache model weights on disk.",
            description: "Tools like Ollama, LM Studio, and the Hugging Face Hub library cache model weights locally so they can be loaded without re-downloading. Unlike most developer caches, weights can take a long time to re-download, so removal should be deliberate.",
            links: [
                InfoLink(title: "Large language model — Wikipedia", url: "https://en.wikipedia.org/wiki/Large_language_model", kind: .wiki),
                InfoLink(title: "Ollama", url: "https://ollama.com/", kind: .official),
                InfoLink(title: "Hugging Face", url: "https://huggingface.co/", kind: .official),
            ]
        ),
        EcosystemInfo(
            ecosystem: .aiCodingAgent,
            displayName: "AI Coding Agents",
            tagline: "Terminal- and editor-resident coding assistants that store session transcripts and shadow checkpoints.",
            description: "Agentic coding tools like Claude Code, OpenAI Codex CLI, Gemini CLI, and OpenCode accumulate two kinds of state: chat transcripts (irreversible if deleted, often the only record of long pair-programming sessions) and operational caches like embedding indexes, repo-map ctags, and shadow git worktrees that regenerate on next use.",
            links: [
                InfoLink(title: "AI agent — Wikipedia", url: "https://en.wikipedia.org/wiki/Intelligent_agent", kind: .wiki),
                InfoLink(title: "Claude Code", url: "https://platform.claude.com/docs/en/docs/agents/claude-code/overview", kind: .official),
                InfoLink(title: "OpenAI Codex CLI", url: "https://developers.openai.com/codex/cli", kind: .official),
            ]
        ),
        EcosystemInfo(
            ecosystem: .browserAutomation,
            displayName: "Browser Automation",
            tagline: "End-to-end test runners that download and manage their own browser binaries.",
            description: "Tools like Playwright, Cypress, and Puppeteer drive real browsers programmatically for end-to-end testing and scripted scraping. Each downloads pinned versions of Chromium (and often Firefox and WebKit) into a per-user cache so test runs are hermetic, with bundled browsers accumulating across upgrades.",
            links: [
                InfoLink(title: "Headless browser — Wikipedia", url: "https://en.wikipedia.org/wiki/Headless_browser", kind: .wiki),
                InfoLink(title: "Playwright", url: "https://playwright.dev/", kind: .official),
                InfoLink(title: "Cypress", url: "https://www.cypress.io/", kind: .official),
            ]
        ),
        EcosystemInfo(
            ecosystem: .vm,
            displayName: "VMs & Containers",
            tagline: "Container engines and VM frameworks that cache disk images and layer stores.",
            description: "Container engines like Docker and OrbStack store pulled images as stacks of content-addressed layers, plus writable layers for running and stopped containers; VM frameworks such as Tart maintain full disk images per VM. These stores grow as new images are pulled, though container engines provide built-in pruning commands to reclaim space.",
            links: [
                InfoLink(title: "OS-level virtualization — Wikipedia", url: "https://en.wikipedia.org/wiki/OS-level_virtualization", kind: .wiki),
                InfoLink(title: "Docker", url: "https://www.docker.com/", kind: .official),
                InfoLink(title: "OrbStack", url: "https://orbstack.dev/", kind: .official),
            ]
        ),
        EcosystemInfo(
            ecosystem: .devops,
            displayName: "DevOps & Cloud CLIs",
            tagline: "Command-line tools for cloud, Kubernetes, and CI workflows that cache plugins and responses.",
            description: "Infrastructure CLIs share a common pattern: download plugins or provider binaries on first use, cache HTTP responses to avoid re-issuing the same API calls, and write per-invocation logs. The caches refill on the next command, so reclaiming space only costs a re-download.",
            links: [
                InfoLink(title: "Infrastructure as code — Wikipedia", url: "https://en.wikipedia.org/wiki/Infrastructure_as_code", kind: .wiki),
                InfoLink(title: "Terraform", url: "https://www.terraform.io/", kind: .official),
                InfoLink(title: "Kubernetes — kubectl", url: "https://kubernetes.io/docs/reference/kubectl/", kind: .docs),
            ]
        ),
        EcosystemInfo(
            ecosystem: .gameDev,
            displayName: "Game Dev & Shaders",
            tagline: "Game engines and GPU shader caches — derived data reproducible from sources but slow to rebuild.",
            description: "Engines like Unity, Unreal, and Godot generate cooked assets, derived-data caches, and per-platform shader binaries during development. On macOS, the Metal framework also maintains a user-level AIR/IR shader cache that catches non-bundled binaries (e.g. `cargo run` or `swift run` of a wgpu app, ad-hoc scripts hitting Metal).",
            links: [
                InfoLink(title: "Game engine — Wikipedia", url: "https://en.wikipedia.org/wiki/Game_engine", kind: .wiki),
                InfoLink(title: "Unity", url: "https://unity.com/", kind: .official),
                InfoLink(title: "Unreal Engine", url: "https://www.unrealengine.com/", kind: .official),
                InfoLink(title: "Godot Engine", url: "https://godotengine.org/", kind: .official),
                InfoLink(title: "Metal — Apple Developer", url: "https://developer.apple.com/metal/", kind: .docs),
            ]
        ),
        EcosystemInfo(
            ecosystem: .database,
            displayName: "Databases",
            tagline: "Local database server data — almost always irreplaceable, with a few rebuildable caches around the edges.",
            description: "Local database servers like PostgreSQL, MySQL/MariaDB, Redis, and MongoDB store tables, indexes, write-ahead logs, and replication state inside a single data directory. Unlike build artifacts, this content is not derivable from a source tree, so rules targeting data directories are tagged `Extreme` regen effort while the handful of cache and log entries (DB GUIs, MongoDB diagnostic rotation) are tagged accordingly.",
            links: [
                InfoLink(title: "Database — Wikipedia", url: "https://en.wikipedia.org/wiki/Database", kind: .wiki),
                InfoLink(title: "PostgreSQL", url: "https://www.postgresql.org/", kind: .official),
                InfoLink(title: "MySQL", url: "https://www.mysql.com/", kind: .official),
                InfoLink(title: "Redis", url: "https://redis.io/", kind: .official),
                InfoLink(title: "MongoDB", url: "https://www.mongodb.com/", kind: .official),
            ]
        ),
    ]
}
