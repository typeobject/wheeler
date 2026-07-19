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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** End-to-end tests for deterministic renderer-neutral documentation bundles. */
class DocumentationBundleCommandTest {
  @TempDir
  Path temporary;

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
    assertTrue(manifest.contains("\"profile\":\"wheeler-doc-bundle-1\""));
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
  void resolvesRelativePagesAndCanonicalHeadingAnchors() throws Exception {
    Path manuals = temporary.resolve("linked-manuals");
    Path sources = temporary.resolve("linked-sources");
    Files.createDirectories(manuals.resolve("nested"));
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("guide.md"), """
        # Guide

        Read [the answer](nested/answer.md#the-answer).
        """);
    Files.writeString(manuals.resolve("nested/answer.md"), """
        # Answer

        ## The answer

        Forty-two, within the documented execution limit.
        """);
    Path output = temporary.resolve("linked-bundle");

    assertEquals(0, execute(manuals, sources, output, new ByteArrayOutputStream()));
    String edges = Files.readString(output.resolve("edges.json"));
    assertTrue(edges.contains(
        "\"source\":\"manual:guide\",\"target\":"
            + "\"manual:nested/answer#the-answer\""));

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
