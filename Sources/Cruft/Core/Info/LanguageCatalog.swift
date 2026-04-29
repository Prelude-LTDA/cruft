import Foundation

/// Keyed lookup table of `LanguageInfo`. Rules reference entries via
/// `Rule.languageKey`. Keeping them in one file avoids duplicating the
/// same blurb across every rule that targets the same language.
///
/// Seed data is minimal on purpose — the bulk of content (descriptions,
/// curated links) is filled in by subagents in a later pass. Each link
/// URL should be verified (WebFetch -> 200 OK, relevant content) before
/// landing here.
enum LanguageCatalog {
    static let all: [String: LanguageInfo] = Dictionary(
        uniqueKeysWithValues: entries.map { ($0.key, $0) }
    )

    static func info(for key: String?) -> LanguageInfo? {
        guard let key else { return nil }
        return all[key]
    }

    private static let entries: [LanguageInfo] = [
        LanguageInfo(
            key: "javascript",
            displayName: "JavaScript / TypeScript",
            tagline: "The scripting language of the web browser, now used across front-end, back-end, and tooling.",
            description: "JavaScript is a high-level, dynamically typed language originally designed for interactive web pages, since spread to server-side runtimes, CLI tooling, and desktop applications. TypeScript is a statically typed superset that compiles to JavaScript, adding type annotations, interfaces, and generics checked at compile time.",
            links: [
                InfoLink(title: "MDN — JavaScript", url: "https://developer.mozilla.org/en-US/docs/Web/JavaScript", kind: .docs),
                InfoLink(title: "TypeScript", url: "https://www.typescriptlang.org", kind: .official),
                InfoLink(title: "TypeScript Handbook", url: "https://www.typescriptlang.org/docs/", kind: .docs),
                InfoLink(title: "ECMAScript Specification", url: "https://tc39.es/ecma262/", kind: .docs),
                InfoLink(title: "JavaScript — Wikipedia", url: "https://en.wikipedia.org/wiki/JavaScript", kind: .wiki),
                InfoLink(title: "TypeScript — Wikipedia", url: "https://en.wikipedia.org/wiki/TypeScript", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "rust",
            displayName: "Rust",
            tagline: "A systems language that enforces memory safety at compile time without a garbage collector.",
            description: "Rust is a compiled, statically typed systems language whose ownership-and-borrowing model rules out null-pointer dereferences, data races, and use-after-free at compile time. It targets command-line tools, networking services, WebAssembly, embedded firmware, and OS components.",
            links: [
                InfoLink(title: "Rust", url: "https://www.rust-lang.org", kind: .official),
                InfoLink(title: "The Rust Programming Language", url: "https://doc.rust-lang.org/book/", kind: .docs),
                InfoLink(title: "Rust Standard Library", url: "https://doc.rust-lang.org/std/", kind: .docs),
                InfoLink(title: "Rust (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Rust_(programming_language)", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "python",
            displayName: "Python",
            tagline: "A general-purpose, dynamically typed language used across data science, web back-ends, and scripting.",
            description: "Python is a high-level, dynamically typed language that emphasises readable, concise syntax. It sees heavy use in data science, machine learning, web back-ends, automation, and scientific computing; the reference implementation is CPython, with third-party packages distributed through PyPI.",
            links: [
                InfoLink(title: "Python", url: "https://www.python.org", kind: .official),
                InfoLink(title: "Python 3 Documentation", url: "https://docs.python.org/3/", kind: .docs),
                InfoLink(title: "Python Tutorial", url: "https://docs.python.org/3/tutorial/", kind: .docs),
                InfoLink(title: "Python (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Python_(programming_language)", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "swift",
            displayName: "Swift / Objective-C",
            tagline: "Apple's two first-party languages for building native apps, with full interoperability between them.",
            description: "Objective-C is a superset of C that adds Smalltalk-style dynamic message dispatch and was Apple's primary application language for decades. Swift is a statically typed compiled language designed around safety (optionals, value types, structured concurrency) that interoperates with the Objective-C runtime; both target macOS, iOS, iPadOS, watchOS, tvOS, and visionOS through the Cocoa frameworks.",
            links: [
                InfoLink(title: "Swift", url: "https://www.swift.org", kind: .official),
                InfoLink(title: "The Swift Programming Language", url: "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/", kind: .docs),
                InfoLink(title: "Swift — Apple Developer", url: "https://developer.apple.com/documentation/swift", kind: .docs),
                InfoLink(title: "Objective-C — Apple Developer", url: "https://developer.apple.com/documentation/objectivec", kind: .docs),
                InfoLink(title: "Swift (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Swift_(programming_language)", kind: .wiki),
                InfoLink(title: "Objective-C — Wikipedia", url: "https://en.wikipedia.org/wiki/Objective-C", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "go",
            displayName: "Go",
            tagline: "A statically typed, compiled language with garbage collection and built-in concurrency primitives.",
            description: "Go is a compiled language with static typing, garbage collection, and a terse syntax. Goroutines and channels provide a structured model for concurrent programming, making it a common choice for network services, cloud infrastructure tooling, CLIs, and distributed systems.",
            links: [
                InfoLink(title: "Go", url: "https://go.dev", kind: .official),
                InfoLink(title: "Go Documentation", url: "https://go.dev/doc/", kind: .docs),
                InfoLink(title: "Go Language Specification", url: "https://go.dev/ref/spec", kind: .docs),
                InfoLink(title: "Go (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Go_(programming_language)", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "java",
            displayName: "JVM",
            tagline: "A family of languages that compile to bytecode and run on the Java Virtual Machine.",
            description: "The JVM hosts a family of languages — Java, Kotlin, Scala, Groovy, Clojure — that compile to platform-independent bytecode and interoperate at the library level. The ecosystem shows up most often in back-end services, big-data tooling, and Android applications (where Kotlin is now the preferred language).",
            links: [
                InfoLink(title: "Java SE", url: "https://www.java.com/en/", kind: .official),
                InfoLink(title: "Java SE 21 API Docs", url: "https://docs.oracle.com/en/java/javase/21/docs/api/", kind: .docs),
                InfoLink(title: "Kotlin", url: "https://kotlinlang.org", kind: .official),
                InfoLink(title: "Kotlin Documentation", url: "https://kotlinlang.org/docs/home.html", kind: .docs),
                InfoLink(title: "Java (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Java_(programming_language)", kind: .wiki),
                InfoLink(title: "Kotlin — Wikipedia", url: "https://en.wikipedia.org/wiki/Kotlin_(programming_language)", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "cpp",
            displayName: "C / C++",
            tagline: "Two related compiled languages that provide direct hardware access and underpin systems software.",
            description: "C is a procedural systems language that compiles to native code with minimal runtime overhead and underpins most operating system kernels and embedded firmware. C++ extends C with classes, templates, and the Standard Template Library, and is widely used for game engines, compilers, databases, and graphics drivers.",
            links: [
                InfoLink(title: "Standard C++", url: "https://isocpp.org", kind: .official),
                InfoLink(title: "C++ Language Reference — Microsoft Learn", url: "https://learn.microsoft.com/en-us/cpp/cpp/", kind: .docs),
                InfoLink(title: "C (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/C_(programming_language)", kind: .wiki),
                InfoLink(title: "C++ — Wikipedia", url: "https://en.wikipedia.org/wiki/C%2B%2B", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "dotnet",
            displayName: ".NET",
            tagline: "Microsoft's cross-platform, open-source runtime supporting C#, F#, and Visual Basic.",
            description: ".NET is an open-source runtime and framework maintained by Microsoft that hosts C# (the flagship statically typed, object-oriented language), F# (functional-first), and Visual Basic over a shared base class library. It targets web, desktop, mobile, cloud, and game workloads, having converged from the older Windows-only .NET Framework and Mono into a unified cross-platform SDK.",
            links: [
                InfoLink(title: ".NET", url: "https://dotnet.microsoft.com/en-us/", kind: .official),
                InfoLink(title: "C# Documentation", url: "https://learn.microsoft.com/en-us/dotnet/csharp/", kind: .docs),
                InfoLink(title: ".NET — Wikipedia", url: "https://en.wikipedia.org/wiki/.NET", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "ruby",
            displayName: "Ruby",
            tagline: "A dynamic, object-oriented language with a focus on readable syntax.",
            description: "Ruby is an interpreted, object-oriented language where every value is an object. It is most often associated with the Ruby on Rails web framework, but also shows up in DevOps tooling (Chef, Vagrant, Homebrew) and general scripting. The reference implementation is CRuby (MRI).",
            links: [
                InfoLink(title: "Ruby", url: "https://www.ruby-lang.org/en/", kind: .official),
                InfoLink(title: "Ruby Core API Documentation", url: "https://ruby-doc.org/core/", kind: .docs),
                InfoLink(title: "Ruby (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Ruby_(programming_language)", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "php",
            displayName: "PHP",
            tagline: "A dynamically typed scripting language used extensively in server-side web development.",
            description: "PHP is a dynamically typed scripting language designed for web development, with tight HTML integration and built-in functions for databases, file I/O, and networking. It powers WordPress, Drupal, and Laravel, typically running through the PHP-FPM interpreter behind a web server such as Nginx or Apache.",
            links: [
                InfoLink(title: "PHP", url: "https://www.php.net", kind: .official),
                InfoLink(title: "PHP Manual", url: "https://www.php.net/docs.php", kind: .docs),
                InfoLink(title: "PHP — Wikipedia", url: "https://en.wikipedia.org/wiki/PHP", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "haskell",
            displayName: "Haskell",
            tagline: "A purely functional, lazily evaluated language with a Hindley-Milner static type system.",
            description: "Haskell is a statically typed, purely functional language with lazy evaluation by default and a Hindley-Milner type system extended with type classes; side effects are tracked in the type system via monads. The primary compiler is GHC, and it shows up in compilers and interpreters, financial systems, and research applications.",
            links: [
                InfoLink(title: "Haskell", url: "https://www.haskell.org", kind: .official),
                InfoLink(title: "Haskell Documentation", url: "https://haskell.org/documentation", kind: .docs),
                InfoLink(title: "GHC", url: "https://www.haskell.org/ghc/", kind: .official),
                InfoLink(title: "Hackage", url: "https://hackage.haskell.org", kind: .official),
                InfoLink(title: "Haskell — Wikipedia", url: "https://en.wikipedia.org/wiki/Haskell", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "dart",
            displayName: "Dart / Flutter",
            tagline: "Google's compiled language, used primarily as the language behind the Flutter UI framework.",
            description: "Dart is a statically typed, object-oriented language that compiles to native ARM/x86 code for mobile and desktop and to JavaScript for the web, with sound null safety and async/await concurrency. It is the language behind Flutter, Google's UI toolkit for building applications for mobile, web, and desktop from a single codebase.",
            links: [
                InfoLink(title: "Dart", url: "https://dart.dev", kind: .official),
                InfoLink(title: "Dart Language Tour", url: "https://dart.dev/language", kind: .docs),
                InfoLink(title: "Flutter", url: "https://flutter.dev", kind: .official),
                InfoLink(title: "Dart (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Dart_(programming_language)", kind: .wiki),
                InfoLink(title: "Flutter — Wikipedia", url: "https://en.wikipedia.org/wiki/Flutter_(software)", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "elixir",
            displayName: "Elixir / Erlang",
            tagline: "Functional languages on the BEAM virtual machine, targeting fault-tolerant, concurrent distributed systems.",
            description: "Erlang is a dynamically typed functional language whose actor-based concurrency model (lightweight processes, message passing) and OTP framework target highly available, distributed software. Elixir runs on the same BEAM VM with a Ruby-inspired syntax, metaprogramming via macros, and the Mix build toolchain; both interoperate freely at the library level and are common in real-time web back-ends (Phoenix), messaging infrastructure, and embedded systems.",
            links: [
                InfoLink(title: "Elixir", url: "https://elixir-lang.org", kind: .official),
                InfoLink(title: "Elixir Documentation", url: "https://hexdocs.pm/elixir/", kind: .docs),
                InfoLink(title: "Erlang", url: "https://www.erlang.org", kind: .official),
                InfoLink(title: "Erlang Documentation", url: "https://www.erlang.org/docs", kind: .docs),
                InfoLink(title: "Elixir (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Elixir_(programming_language)", kind: .wiki),
                InfoLink(title: "Erlang (programming language) — Wikipedia", url: "https://en.wikipedia.org/wiki/Erlang_(programming_language)", kind: .wiki),
            ]
        ),
    ]
}
