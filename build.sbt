import kubuszok.sbt._
import sbtwelcome.UsefulTask
import kubuszok.sbt.KubuszokPlugin.autoImport._
import multiarch.core.Platform

val publishSettings = Seq(
  organization := "com.kubuszok",
  homepage := Some(url("https://github.com/kubuszok/ssg-native-providers")),
  organizationHomepage := Some(url("https://kubuszok.com")),
  licenses := Seq("Apache-2.0" -> url("https://www.apache.org/licenses/LICENSE-2.0")),
  scmInfo := Some(
    ScmInfo(
      url("https://github.com/kubuszok/ssg-native-providers/"),
      "scm:git:git@github.com:kubuszok/ssg-native-providers.git"
    )
  ),
  startYear := Some(2026),
  developers := List(
    Developer("MateuszKubuszok", "Mateusz Kubuszok", "", url("https://github.com/MateuszKubuszok"))
  ),
  pomExtra := (
    <issueManagement>
      <system>GitHub issues</system>
      <url>https://github.com/kubuszok/ssg-native-providers/issues</url>
    </issueManagement>
  ),
  projectType := ProjectType.ScalaLibrary
)

val noPublishSettings =
  Seq(projectType := ProjectType.NonPublished)

// ── Shared helpers ────────────────────────────────────────────────────

// Root directory containing downloaded native artifacts from tree-sitter-natives releases
val crossDir = settingKey[File]("Root directory containing cross-compiled native artifacts")
ThisBuild / crossDir := (ThisBuild / baseDirectory).value / "native" / "cross"

/** Create fat JAR mappings: native/<platform-classifier>/<file> for matching files. */
def fatJarMappings(crossRoot: File, platforms: Seq[Platform], fileFilter: String => Boolean): Seq[(File, String)] =
  platforms.flatMap { p =>
    val dir = crossRoot / p.classifier
    if (dir.exists())
      sbt.IO.listFiles(dir).filter(f => f.isFile && fileFilter(f.getName)).map(f => f -> s"native/${p.classifier}/${f.getName}").toSeq
    else Seq.empty
  }

// Common provider settings (no Scala code, pure resource JARs)
val providerSettings = Seq(
  autoScalaLibrary := false,
  crossPaths       := false,
  Compile / packageDoc / publishArtifact := false,
  Compile / packageSrc / publishArtifact := false
)

// ── Root project ──────────────────────────────────────────────────────

lazy val root = project
  .in(file("."))
  .enablePlugins(KubuszokRootPlugin)
  .settings(publishSettings *)
  .settings(noPublishSettings *)
  .aggregate(
    `sn-provider-tree-sitter`,
    `pnm-provider-tree-sitter-desktop`,
    `wasm-provider-tree-sitter`,
    `tree-sitter-queries`
  )
  .settings(
    name := "ssg-native-providers-root",
    logo := s"ssg-native-providers ${version.value}",
    usefulTasks := Seq(
      UsefulTask("compile", "Compile all provider JARs").noAlias,
      UsefulTask("publishLocal", "Publish all providers locally").noAlias,
      UsefulTask("ci-release", "Publish snapshot or release (based on git tags)").noAlias
    )
  )

// ── Scala Native provider (static libraries) ─────────────────────────

lazy val `sn-provider-tree-sitter` = project
  .in(file("providers/sn-provider-tree-sitter"))
  .settings(publishSettings *)
  .settings(providerSettings *)
  .settings(
    name := "sn-provider-tree-sitter",
    Compile / packageBin / mappings ++= {
      val cross = crossDir.value
      val libs = Set(
        "libtree_sitter_all.a", "tree_sitter_all.lib"
      )
      fatJarMappings(cross, Platform.desktop, libs.contains)
    }
  )

// ── JVM/Panama provider (shared libraries) ───────────────────────────

lazy val `pnm-provider-tree-sitter-desktop` = project
  .in(file("providers/pnm-provider-tree-sitter-desktop"))
  .enablePlugins(KubuszokRootPlugin)
  .settings(publishSettings *)
  .settings(providerSettings *)
  .settings(
    name := "pnm-provider-tree-sitter-desktop",
    Compile / packageBin / mappings ++= {
      val cross = crossDir.value
      val libs = Set(
        "libtree_sitter_all.dylib", "libtree_sitter_all.so",
        "tree_sitter_all.dll", "tree_sitter_all.dll.lib"
      )
      fatJarMappings(cross, Platform.desktop, libs.contains)
    }
  )

// ── Scala.js/WASM provider ───────────────────────────────────────────

lazy val `wasm-provider-tree-sitter` = project
  .in(file("providers/wasm-provider-tree-sitter"))
  .enablePlugins(KubuszokRootPlugin)
  .settings(publishSettings *)
  .settings(providerSettings *)
  .settings(
    name := "wasm-provider-tree-sitter",
    Compile / packageBin / mappings ++= {
      val wasmDir = (ThisBuild / baseDirectory).value / "native" / "wasm"
      if (wasmDir.exists()) {
        val core = Seq("web-tree-sitter.js", "web-tree-sitter.wasm")
          .map(f => wasmDir / f)
          .filter(_.exists())
          .map(f => f -> s"wasm/${f.getName}")
        val grammars = {
          val gDir = wasmDir / "grammars"
          if (gDir.exists())
            sbt.IO.listFiles(gDir).filter(f => f.isFile && f.getName.endsWith(".wasm"))
              .map(f => f -> s"wasm/grammars/${f.getName}").toSeq
          else Seq.empty
        }
        core ++ grammars
      } else Seq.empty
    }
  )

// ── Query files (.scm, platform-independent) ─────────────────────────

lazy val `tree-sitter-queries` = project
  .in(file("providers/tree-sitter-queries"))
  .enablePlugins(KubuszokRootPlugin)
  .settings(publishSettings *)
  .settings(providerSettings *)
  .settings(
    name := "tree-sitter-queries",
    Compile / packageBin / mappings ++= {
      val queriesDir = (ThisBuild / baseDirectory).value / "native" / "queries"
      if (queriesDir.exists()) {
        val langDirs = sbt.IO.listFiles(queriesDir).filter(_.isDirectory)
        langDirs.flatMap { langDir =>
          sbt.IO.listFiles(langDir).filter(f => f.isFile && f.getName.endsWith(".scm"))
            .map(f => f -> s"queries/${langDir.getName}/${f.getName}")
        }.toSeq
      } else Seq.empty
    }
  )
