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
            tagline: "The scripting language of the web browser, now used across front-end, back-end, and tooling contexts.",
            description: "JavaScript is a high-level, dynamically typed language originally designed for interactive web pages; it has since spread to server-side runtimes, CLI tooling, and desktop applications. TypeScript is a statically typed superset of JavaScript that compiles to plain JavaScript, adding optional type annotations, interfaces, and generics to catch errors at compile time. Both are common in front-end development and in back-end and scripting contexts. The ECMAScript specification (ECMA-262) standardises the core language; new editions are released annually.",
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
            description: "Rust is a compiled, statically typed systems programming language designed for performance, reliability, and safe concurrency. Its ownership-and-borrowing model eliminates whole classes of bugs — null-pointer dereferences, data races, use-after-free — at compile time rather than at runtime. Rust targets a wide range of domains: command-line tools, networking services, WebAssembly, embedded firmware, and operating system components. The `rustc` compiler ships with Cargo, an integrated build system and package manager, and the standard library (`std`) provides portable abstractions over platform primitives.",
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
            tagline: "A general-purpose, dynamically typed language used across data science, web back-ends, automation, and scripting.",
            description: "Python is a high-level, dynamically typed language that emphasises code readability and a concise syntax. It sees heavy use in data science, machine learning, web back-ends, automation, scientific computing, and general-purpose scripting. The reference implementation, CPython, ships with an extensive standard library and is complemented by a large ecosystem of third-party packages distributed through PyPI. Alternative implementations include PyPy (JIT-compiled), Jython (JVM), and MicroPython (microcontrollers). Python 3 has been the active branch since 2008.",
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
            tagline: "The two first-party languages for building native apps across Apple's platforms, with full interoperability between them.",
            description: "Objective-C was Apple's primary application language for over three decades — a superset of C that adds Smalltalk-style dynamic message dispatch and the NeXT-era Foundation framework. Swift, introduced in 2014, is a statically typed compiled language designed around safety (optionals, value types, structured concurrency) while remaining binary- and source-compatible with the existing Objective-C runtime; new code can call into old code and vice versa. Both languages target macOS, iOS, iPadOS, watchOS, tvOS, and visionOS, and share the same Cocoa / Cocoa Touch frameworks. Swift additionally runs on Linux and Windows as an open-source project.",
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
            description: "Go (also known as Golang) is an open-source compiled language developed at Google and released in 2009. It features static typing, garbage collection, and a terse syntax. Go's goroutines and channels provide a structured model for concurrent programming, making it a common choice for network services, cloud infrastructure tooling, CLIs, and distributed systems. The toolchain — `go build`, `go test`, `go mod` — is built in and opinionated, producing a consistent developer experience across projects.",
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
            tagline: "A family of languages that compile to bytecode and run on the Java Virtual Machine, sharing a common library ecosystem.",
            description: "The JVM (Java Virtual Machine) hosts a family of languages — most prominently Java, Kotlin, Scala, Groovy, and Clojure — that compile to platform-independent bytecode and interoperate freely at the library level. Java, originally released by Sun Microsystems in 1995 and now steered by Oracle, established the platform; Kotlin, developed by JetBrains, is now the preferred language for Android development. Scala and Clojure bring functional-programming idioms to the JVM, while Groovy provides a dynamic scripting layer. The JVM ecosystem is commonly used in back-end services, big-data tooling, and Android applications.",
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
            tagline: "Two closely related compiled languages that provide direct hardware access and underpin systems, embedded, and performance-critical software.",
            description: "C is a procedural systems language standardised as ISO C (with revisions through C23) that compiles to efficient native code with minimal runtime overhead; virtually every major operating system kernel and embedded firmware is written in C. C++ extends C with classes, templates, the Standard Template Library, and language features (move semantics, lambdas, concepts) through a series of standards from C++11 onward, enabling both low-level control and high-level abstractions in the same codebase. Together they power game engines, compilers, databases, graphics drivers, scientific simulations, and the majority of performance-critical software. Common compilers include GCC, Clang/LLVM, and MSVC.",
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
            tagline: "Microsoft's cross-platform, open-source developer platform supporting C#, F#, and Visual Basic.",
            description: ".NET is a free, open-source runtime and framework maintained by Microsoft that supports multiple languages — primarily C#, F#, and Visual Basic — targeting web, desktop, mobile, cloud, and game workloads from a shared base class library. C# is the flagship language: a statically typed, object-oriented language with features including records, pattern matching, async/await, and LINQ. F# is a functional-first language on the same runtime, and Visual Basic provides a legacy-friendly option. The .NET ecosystem has converged from the older .NET Framework (Windows-only) and Mono into a single unified cross-platform SDK starting with .NET 5.",
            links: [
                InfoLink(title: ".NET", url: "https://dotnet.microsoft.com/en-us/", kind: .official),
                InfoLink(title: "C# Documentation", url: "https://learn.microsoft.com/en-us/dotnet/csharp/", kind: .docs),
                InfoLink(title: ".NET — Wikipedia", url: "https://en.wikipedia.org/wiki/.NET", kind: .wiki),
            ]
        ),
        LanguageInfo(
            key: "ruby",
            displayName: "Ruby",
            tagline: "A dynamic, object-oriented language used in web frameworks, DevOps tooling, and scripting.",
            description: "Ruby is a dynamic, object-oriented, interpreted language created by Yukihiro Matsumoto (Matz) and first released in 1995. Every value in Ruby is an object, and the language emphasises readable, concise syntax inspired by Perl, Smalltalk, and Lisp. It rose to widespread popularity through the Ruby on Rails web framework, which demonstrated how convention-over-configuration could dramatically speed up application development. The reference implementation is CRuby (MRI); JRuby runs on the JVM and TruffleRuby provides a high-performance alternative. Ruby remains common in web back-ends, DevOps tooling (Chef, Vagrant, Homebrew), and rapid prototyping.",
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
            description: "PHP is a dynamically typed scripting language originally designed for web development. Its tight integration with HTML and built-in functions for databases, file I/O, and networking made it a common choice for dynamic websites; it continues to power a large share of the web today, including WordPress, Drupal, and Laravel. PHP 8.x has added a JIT compiler, typed properties, union types, named arguments, fibers, and match expressions. PHP code typically runs through the PHP-FPM interpreter behind a web server such as Nginx or Apache.",
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
            description: "Haskell is a statically typed, purely functional programming language with lazy (non-strict) evaluation by default and a Hindley-Milner type system extended with type classes. Its design prioritises mathematical correctness and composability: side effects are tracked in the type system via monads, and immutable data is the norm. Many features now common in mainstream languages — algebraic data types, pattern matching, type inference, monadic error handling — trace their lineage through Haskell's design and research community. The primary compiler is GHC (Glasgow Haskell Compiler); packages are distributed through Hackage. Common use cases include compilers and interpreters, financial systems, and research applications.",
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
            tagline: "Google's compiled language used primarily as the language behind the Flutter UI framework.",
            description: "Dart is a statically typed, object-oriented language developed by Google that compiles to native ARM/x86 code for mobile and desktop targets and to optimised JavaScript for the web. It features sound null safety, async/await concurrency, and a class-and-mixin type model. Dart is the language behind Flutter, Google's open-source UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. Outside Flutter, Dart is used for command-line tools and server-side applications. Packages are distributed through pub.dev.",
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
            tagline: "Functional languages built on the BEAM virtual machine, targeting fault-tolerant, concurrent distributed systems.",
            description: "Erlang is a dynamically typed functional language developed at Ericsson in the 1980s for telecom switching systems; its actor-based concurrency model (lightweight processes, message passing) and OTP framework made it a reference point for building highly available, distributed software. Elixir, created by José Valim and first released in 2012, runs on the same BEAM virtual machine and inherits all of Erlang's concurrency and fault-tolerance characteristics while adding a Ruby-inspired syntax, metaprogramming via macros, and the Mix build toolchain. Both languages interoperate freely at the library level. Common applications include real-time web back-ends (Phoenix), messaging infrastructure, and embedded systems.",
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
