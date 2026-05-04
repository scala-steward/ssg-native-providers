# ssg-native-providers

Pre-built [tree-sitter](https://tree-sitter.github.io/) native libraries for
[SSG](https://github.com/kubuszok/ssg) (Scala Static Site Generator), packaged
as fat JARs for Maven Central.

Consumes binary artifacts from
[tree-sitter-natives](https://github.com/kubuszok/tree-sitter-natives) releases
and packages them for consumption by Scala Native, JVM (via Panama FFM), and
Scala.js (via WASM).

## Provider Artifacts

| Artifact | Contents | Consumer |
|----------|----------|----------|
| `sn-provider-tree-sitter` | Static libraries (`.a`/`.lib`) | Scala Native linker |
| `pnm-provider-tree-sitter-desktop` | Shared libraries (`.so`/`.dylib`/`.dll`) | JVM Panama FFM |
| `wasm-provider-tree-sitter` | `web-tree-sitter.js` + `.wasm` grammars | Scala.js (Node.js) |
| `tree-sitter-queries` | Highlight query files (`.scm`) | All platforms |

## Supported Platforms

| Classifier | OS | Arch |
|------------|------|------|
| `linux-x86_64` | Linux | x86_64 |
| `linux-aarch64` | Linux | aarch64 |
| `macos-x86_64` | macOS | x86_64 |
| `macos-aarch64` | macOS | aarch64 |
| `windows-x86_64` | Windows | x86_64 |
| `windows-aarch64` | Windows | aarch64 |

## Fat JAR Layout

```
sn-provider-tree-sitter.jar
├── sn-provider.json
└── native/
    ├── linux-x86_64/libtree_sitter_all.a
    ├── linux-aarch64/libtree_sitter_all.a
    ├── macos-x86_64/libtree_sitter_all.a
    ├── macos-aarch64/libtree_sitter_all.a
    ├── windows-x86_64/tree_sitter_all.lib
    └── windows-aarch64/tree_sitter_all.lib

pnm-provider-tree-sitter-desktop.jar
├── pnm-provider.json
└── native/
    ├── linux-x86_64/libtree_sitter_all.so
    ├── macos-x86_64/libtree_sitter_all.dylib
    ├── windows-x86_64/tree_sitter_all.dll
    └── ...

wasm-provider-tree-sitter.jar
└── wasm/
    ├── web-tree-sitter.js
    ├── web-tree-sitter.wasm
    └── grammars/
        ├── tree-sitter-bash.wasm
        ├── tree-sitter-python.wasm
        └── ...

tree-sitter-queries.jar
└── queries/
    ├── bash/highlights.scm
    ├── python/highlights.scm
    ├── rust/highlights.scm
    └── ...
```

## Usage

### Scala Native

```scala
libraryDependencies += "com.kubuszok" % "sn-provider-tree-sitter" % version
```

### JVM (Panama FFM)

```scala
libraryDependencies += "com.kubuszok" % "pnm-provider-tree-sitter-desktop" % version
```

### Scala.js

```scala
libraryDependencies += "com.kubuszok" % "wasm-provider-tree-sitter" % version
```

### Query Files (all platforms)

```scala
libraryDependencies += "com.kubuszok" % "tree-sitter-queries" % version
```

## Local Build

```bash
# Download tree-sitter-natives release artifacts
scripts/download-release.sh v0.1.0

# Package JARs
sbt packageBin

# Verify contents
scripts/verify-jars.sh

# Publish to local Maven cache
sbt publishLocal
```

## License

Apache-2.0
