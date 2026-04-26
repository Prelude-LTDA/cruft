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
            tagline: "Tools that pre-render a website from source files into a folder of plain HTML, CSS, and assets — deployable to any static host or CDN.",
            description: "Static site generators (SSGs) compile content (typically Markdown) and templates into a folder of static files at build time, rather than assembling pages on every request like a traditional dynamic server. The output directory is disposable — it is fully reproducible from source — and is typically the bulk of an SSG project's disk footprint. SSGs are the foundation of the Jamstack architecture, which treats the pre-rendered frontend as decoupled from data and business logic served through APIs.",
            links: [
                InfoLink(title: "Static site generator — Wikipedia", url: "https://en.wikipedia.org/wiki/Static_site_generator", kind: .wiki),
                InfoLink(title: "Jamstack", url: "https://jamstack.org/", kind: .official),
                InfoLink(title: "Jamstack — SSG directory", url: "https://jamstack.org/generators/", kind: .docs),
            ]
        ),
        EcosystemInfo(
            ecosystem: .packageManager,
            displayName: "Package Managers",
            tagline: "System-level tools that install, update, and manage open-source software outside the App Store.",
            description: "macOS package managers — primarily Homebrew, MacPorts, and Nix — let developers install command-line tools, libraries, and runtimes that don't ship with the OS. Each manager maintains its own isolated prefix where it stores downloaded source archives, compiled binaries, and package metadata. Over time these caches can grow substantially as packages are upgraded and old versions are retained.",
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
            tagline: "Code editors and integrated development environments — from lightweight text editors to full IDEs with debuggers and build systems.",
            description: "An editor or IDE typically maintains on-disk caches that speed up code completion, symbol search, incremental builds, and full-text search across large projects. Installed extensions, language servers, and themes add further bulk in per-user support directories. The tradeoff is that these caches can grow continuously as more projects are opened and more extensions are installed, without the editor surfacing a built-in cleanup pass.",
            links: [
                InfoLink(title: "Integrated development environment — Wikipedia", url: "https://en.wikipedia.org/wiki/Integrated_development_environment", kind: .wiki),
                InfoLink(title: "Source-code editor — Wikipedia", url: "https://en.wikipedia.org/wiki/Source-code_editor", kind: .wiki),
            ]
        ),
        EcosystemInfo(
            ecosystem: .ai,
            displayName: "Local AI & ML",
            tagline: "Local LLM runtimes and ML frameworks store multi-gigabyte model weights in user-owned cache directories.",
            description: "Tools like Ollama and LM Studio let developers run large language models on-device, while the Hugging Face Hub library is the standard distribution channel for model weights used by PyTorch, TensorFlow, and JAX projects. Each model download is cached in a framework-specific directory and can range from a few hundred megabytes to over 100 GB for large parameter counts. Unlike most developer caches, model weights can take hours to re-download, so removal should be deliberate.",
            links: [
                InfoLink(title: "Large language model — Wikipedia", url: "https://en.wikipedia.org/wiki/Large_language_model", kind: .wiki),
                InfoLink(title: "Ollama", url: "https://ollama.com/", kind: .official),
                InfoLink(title: "Hugging Face", url: "https://huggingface.co/", kind: .official),
            ]
        ),
        EcosystemInfo(
            ecosystem: .browserAutomation,
            displayName: "Browser Automation",
            tagline: "End-to-end test runners that download and manage their own bundled browser binaries — typically multi-hundred-megabyte Chromium builds per version.",
            description: "Tools like Playwright, Cypress, and Puppeteer drive real browsers programmatically for end-to-end testing and scripted scraping. Rather than relying on the user's installed browser, each tool downloads a pinned version of Chromium (and often Firefox / WebKit) into a per-user cache, so test runs are hermetic and reproducible across machines. These bundled browsers are large — typically 200 MB to 1 GB per version — and accumulate as the testing tool itself is upgraded.",
            links: [
                InfoLink(title: "Headless browser — Wikipedia", url: "https://en.wikipedia.org/wiki/Headless_browser", kind: .wiki),
                InfoLink(title: "Playwright", url: "https://playwright.dev/", kind: .official),
                InfoLink(title: "Cypress", url: "https://www.cypress.io/", kind: .official),
            ]
        ),
        EcosystemInfo(
            ecosystem: .vm,
            displayName: "VMs & Containers",
            tagline: "Container engines and VM frameworks cache large disk images and layer stores that rebuild automatically but can consume significant space.",
            description: "Container engines like Docker and OrbStack store every pulled image as a stack of content-addressed layers in a local image store, plus writable layers for running and stopped containers. VM frameworks such as Tart maintain full disk images for each virtual machine. These stores grow continuously as new images are pulled and old containers accumulate. Container engines provide built-in pruning commands to reclaim space from unused images and stopped containers.",
            links: [
                InfoLink(title: "OS-level virtualization — Wikipedia", url: "https://en.wikipedia.org/wiki/OS-level_virtualization", kind: .wiki),
                InfoLink(title: "Docker", url: "https://www.docker.com/", kind: .official),
                InfoLink(title: "OrbStack", url: "https://orbstack.dev/", kind: .official),
            ]
        ),
    ]
}
