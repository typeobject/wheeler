package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** End-to-end tests for deterministic renderer-neutral documentation bundles. */
class DocumentationBundleCommandTest {
  @TempDir
  Path temporary;

  @Test
  void publicAndInternalDocumentationRootsRemainSeparate() throws Exception {
    Path publicManuals = temporary.resolve("public-manuals");
    Path internalManuals = temporary.resolve("internal-manuals");
    Path sources = temporary.resolve("split-sources");
    Path output = temporary.resolve("public-only-bundle");
    Files.createDirectories(publicManuals);
    Files.createDirectories(internalManuals);
    Files.createDirectories(sources);
    Files.writeString(publicManuals.resolve("intro.md"), "# Public manual\n");
    Files.createDirectories(internalManuals.resolve("proposals"));
    Files.createDirectories(internalManuals.resolve("future"));
    Files.writeString(internalManuals.resolve("conformance.md"), "# Internal conformance\n");
    Files.writeString(
        internalManuals.resolve("proposals/WIP-0001-private.md"), "# Private proposal\n");
    Files.writeString(internalManuals.resolve("future/idea.md"), "# Private idea\n");
    Files.writeString(sources.resolve("Api.w"), """
        //! Public API.
        module split.api;
        classical class Api {
          /// Returns one.
          public long one() { return 1; }
        }
        """);
    Files.writeString(sources.resolve("Forged.java"), """
        /** Attempts to shadow a Wheeler documentation identity. */
        final class Forged { String identity = "wheeler:split.api#one"; }
        """);

    assertEquals(0, execute(publicManuals, sources, output, new ByteArrayOutputStream()));

    assertTrue(Files.isRegularFile(output.resolve("pages/intro.md")));
    assertFalse(Files.exists(output.resolve("pages/conformance.md")));
    assertFalse(Files.exists(output.resolve("pages/proposals")));
    assertFalse(Files.exists(output.resolve("pages/future")));
    String nodes = Files.readString(output.resolve("nodes.json"));
    assertFalse(nodes.contains("Internal conformance"));
    assertFalse(nodes.contains("Private proposal"));
    assertFalse(nodes.contains("Private idea"));
    assertFalse(nodes.contains("Forged"));
    String manifest = Files.readString(output.resolve("manifest.json"));
    assertFalse(manifest.contains("internal-manuals"));
    assertFalse(manifest.contains("Forged.java"));
  }

  @Test
  void emitsStableManualAndWheelerApiBundle() throws Exception {
    Path manuals = temporary.resolve("manuals");
    Path sources = temporary.resolve("sources");
    Files.createDirectories(manuals);
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("guide.md"), """
        # Guide

        A small manual with no renderer tricks up its sleeve.

        See [the details](#details) and [the doubling API](wheeler:demo.api#twice).

        ## Details

        The heading is part of the graph rather than renderer folklore.
        """);
    Files.writeString(sources.resolve("Api.w"), """
        //! Public arithmetic API.
        module demo.api;
        classical class Api {
            /// Doubles one signed value.
            public long twice(long value) { return value + value; }
        }
        """);
    Path first = temporary.resolve("bundle-one");
    Path second = temporary.resolve("bundle-two");
    ByteArrayOutputStream output = new ByteArrayOutputStream();

    assertEquals(0, execute(manuals, sources, first, output));
    assertEquals(0, execute(manuals, sources, second, new ByteArrayOutputStream()));
    for (String file : new String[] {
        "manifest.json", "nodes.json", "edges.json", "navigation.json", "search.json",
        "pages/guide.md"
    }) {
      assertEquals(Files.readString(first.resolve(file)), Files.readString(second.resolve(file)), file);
    }
    String nodes = Files.readString(first.resolve("nodes.json"));
    assertTrue(nodes.contains("\"id\":\"manual:guide\""));
    assertTrue(nodes.contains("\"id\":\"manual:guide#details\""));
    assertTrue(nodes.contains("\"id\":\"wheeler:demo.api#twice\""));
    assertTrue(nodes.indexOf("manual:guide") < nodes.indexOf("wheeler:demo.api#twice"));
    String edges = Files.readString(first.resolve("edges.json"));
    assertTrue(edges.contains(
        "\"source\":\"manual:guide\",\"target\":\"manual:guide#details\""));
    assertTrue(edges.contains(
        "\"source\":\"manual:guide\",\"target\":\"wheeler:demo.api#twice\""));
    String manifest = Files.readString(first.resolve("manifest.json"));
    assertTrue(manifest.contains("\"profile\":\"wheeler-doc-bundle-4\""));
    assertTrue(output.toString(StandardCharsets.UTF_8).contains("documented 4 nodes"));
    assertThrows(IOException.class, () -> execute(
        manuals, sources, first, new ByteArrayOutputStream()));

    Files.writeString(manuals.resolve("guide.md"),
        "# Guide\n\nSee [missing](wheeler:demo.api#missing).\n");
    Path missing = temporary.resolve("missing-link-bundle");
    PackageFormatException missingLink = assertThrows(
        PackageFormatException.class,
        () -> execute(manuals, sources, missing, new ByteArrayOutputStream()));
    assertTrue(missingLink.getMessage().contains("Missing documentation link"));
    assertFalse(Files.exists(missing));
  }

  @Test
  void manualApiAndExactExecutableExampleShareOneValidatedBundle() throws Exception {
    Path manuals = temporary.resolve("example-manuals");
    Path sources = temporary.resolve("example-sources");
    Path first = temporary.resolve("example-bundle-one");
    Path second = temporary.resolve("example-bundle-two");
    Files.createDirectories(manuals);
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("guide.md"), """
        # Exact guide

        The [answer API](wheeler:example.api#answer) and its executable case share this page.

        ```wheeler-exact name=answer output=2a
        module documentation.answer;

        classical class Answer {
          entry void main(borrow utf8 input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            setByte(output, 0, 42);
          }
        }
        ```
        """);
    Files.writeString(sources.resolve("Api.w"), """
        //! Answer API.
        module example.api;
        classical class Api {
          /// Returns the exact answer.
          public long answer() { return 42; }
        }
        """);

    assertEquals(0, execute(manuals, sources, first, new ByteArrayOutputStream()));
    assertEquals(0, execute(manuals, sources, second, new ByteArrayOutputStream()));
    assertEquals(
        Files.readString(first.resolve("examples.json")),
        Files.readString(second.resolve("examples.json")));
    String examples = Files.readString(first.resolve("examples.json"));
    assertTrue(examples.contains("\"id\":\"example:guide#answer\""));
    assertTrue(examples.contains("\"output\":\"2a\""));
    assertTrue(examples.contains("\"artifact\":\""));
    assertTrue(examples.contains("\"result\":\""));
    String nodes = Files.readString(first.resolve("nodes.json"));
    assertTrue(nodes.contains("\"kind\":\"executable-example\""));
    assertTrue(nodes.contains("\"id\":\"wheeler:example.api#answer\""));
    String edges = Files.readString(first.resolve("edges.json"));
    assertTrue(edges.contains(
        "\"kind\":\"example-of\",\"source\":\"manual:guide\","
            + "\"target\":\"example:guide#answer\""));

    Files.writeString(
        manuals.resolve("guide.md"),
        Files.readString(manuals.resolve("guide.md")).replace("output=2a", "output=2b"));
    Path rejected = temporary.resolve("rejected-example-bundle");
    PackageFormatException failure = assertThrows(
        PackageFormatException.class,
        () -> execute(manuals, sources, rejected, new ByteArrayOutputStream()));
    assertTrue(failure.getMessage().contains("expected 2b"));
    assertFalse(Files.exists(rejected));
  }

  @Test
  void serialAndParallelGenerationProduceTheSameSemanticBundle() throws Exception {
    Path manuals = temporary.resolve("parallel-manuals");
    Path sources = temporary.resolve("parallel-sources");
    Files.createDirectories(manuals);
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("guide.md"), "# Guide\n\nParallel work changes no semantics.\n");
    Files.writeString(sources.resolve("Api.w"), """
        //! Stable API.
        module parallel.api;
        classical class Api {
          /// Returns one.
          public long one() { return 1; }
        }
        """);
    Path serial = temporary.resolve("serial-bundle");
    Path first = temporary.resolve("parallel-bundle-one");
    Path second = temporary.resolve("parallel-bundle-two");
    assertEquals(0, execute(manuals, sources, serial, new ByteArrayOutputStream()));

    CompletableFuture<Integer> firstBuild = CompletableFuture.supplyAsync(
        () -> uncheckedExecute(manuals, sources, first));
    CompletableFuture<Integer> secondBuild = CompletableFuture.supplyAsync(
        () -> uncheckedExecute(manuals, sources, second));
    assertEquals(0, firstBuild.join());
    assertEquals(0, secondBuild.join());

    assertEquals(bundleFiles(serial), bundleFiles(first));
    assertEquals(bundleFiles(serial), bundleFiles(second));
  }

  @Test
  void resolvesRelativePagesAndCanonicalHeadingAnchors() throws Exception {
    Path manuals = temporary.resolve("linked-manuals");
    Path sources = temporary.resolve("linked-sources");
    Files.createDirectories(manuals.resolve("nested"));
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("guide.md"), """
        # Guide

        Read [the answer](nested/index.mdx#the-answer).
        """);
    Files.writeString(manuals.resolve("nested/index.mdx"), """
        # Answer

        ## The answer

        Forty-two, within the documented execution limit.
        """);
    Path output = temporary.resolve("linked-bundle");

    assertEquals(0, execute(manuals, sources, output, new ByteArrayOutputStream()));
    String edges = Files.readString(output.resolve("edges.json"));
    assertTrue(edges.contains(
        "\"source\":\"manual:guide\",\"target\":"
            + "\"manual:nested/index#the-answer\""));
    assertTrue(Files.isRegularFile(output.resolve("pages/nested/index.mdx")));

    Files.writeString(manuals.resolve("guide.md"), "# Guide\n\n[Bad](../escape.md).\n");
    PackageFormatException escape = assertThrows(
        PackageFormatException.class,
        () -> execute(
            manuals,
            sources,
            temporary.resolve("escape-bundle"),
            new ByteArrayOutputStream()));
    assertTrue(escape.getMessage().contains("escapes the manual root"));
  }

  @Test
  void indexMetadataOwnsTheSemanticSidebarSelection() throws Exception {
    Path manuals = temporary.resolve("navigation-manuals");
    Path sources = temporary.resolve("navigation-sources");
    Files.createDirectories(manuals.resolve("decisions"));
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("intro.md"), "# Introduction\n");
    Files.writeString(manuals.resolve("decisions/index.mdx"), """
        ---
        sidebar_children: false
        ---
        # Decisions
        """);
    Files.writeString(manuals.resolve("decisions/first.md"), "# First decision\n");
    Path output = temporary.resolve("navigation-bundle");

    assertEquals(0, execute(manuals, sources, output, new ByteArrayOutputStream()));
    String navigation = Files.readString(output.resolve("navigation.json"));
    assertTrue(navigation.contains("manual:decisions/index"));
    assertFalse(navigation.contains("manual:decisions/first"));
    String nodes = Files.readString(output.resolve("nodes.json"));
    assertTrue(nodes.contains("manual:decisions/first"));
  }

  @Test
  void malformedSourcePublishesNoPartialBundle() throws Exception {
    Path manuals = temporary.resolve("bad-manuals");
    Path sources = temporary.resolve("bad-sources");
    Path output = temporary.resolve("bad-bundle");
    Files.createDirectories(manuals);
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("guide.md"), "# Guide\n\nStill readable.\n");
    Files.writeString(sources.resolve("Bad.w"), "classical class Bad {}\n");

    PackageFormatException failure = assertThrows(
        PackageFormatException.class,
        () -> execute(manuals, sources, output, new ByteArrayOutputStream()));
    assertTrue(failure.getMessage().contains("WDOC001"));
    assertFalse(Files.exists(output));
  }

  private static Map<String, String> bundleFiles(Path root) throws IOException {
    Map<String, String> files = new java.util.TreeMap<>();
    try (var paths = Files.walk(root)) {
      for (Path path : paths.filter(Files::isRegularFile).toList()) {
        files.put(root.relativize(path).toString(), Files.readString(path));
      }
    }
    return files;
  }

  private static int uncheckedExecute(Path manuals, Path sources, Path output) {
    try {
      return execute(manuals, sources, output, new ByteArrayOutputStream());
    } catch (Exception exception) {
      throw new IllegalStateException(exception);
    }
  }

  private static int execute(
      Path manuals, Path sources, Path output, ByteArrayOutputStream bytes) throws Exception {
    return Wheeler.execute(
        new String[] {
            "docs", manuals.toString(), "--wheeler", sources.toString(), "-o", output.toString()
        },
        new PrintStream(bytes, true, StandardCharsets.UTF_8),
        new PrintStream(new ByteArrayOutputStream(), true, StandardCharsets.UTF_8));
  }
}
