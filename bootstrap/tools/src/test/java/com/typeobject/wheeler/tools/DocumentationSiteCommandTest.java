package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/** End-to-end checks for the fixed zero-configuration Wheeler static documentation site. */
class DocumentationSiteCommandTest {
  @TempDir
  Path temporary;

  @Test
  void repositorySiteIsSafeDeterministicAndSelfContained() throws Exception {
    Path first = temporary.resolve("first-site");
    Path second = temporary.resolve("second-site");
    ByteArrayOutputStream output = new ByteArrayOutputStream();

    assertEquals(0, Wheeler.execute(
        new String[] {"site", "-o", first.toString()},
        new PrintStream(output, true, StandardCharsets.UTF_8),
        new PrintStream(new ByteArrayOutputStream())));
    assertEquals(0, Wheeler.execute(
        new String[] {"site", "-o", second.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));

    String publication = Files.readString(first.resolve("publication-manifest.json"));
    assertEquals(publication, Files.readString(second.resolve("publication-manifest.json")));
    assertTrue(publication.contains("\"profile\":\"wheeler.doc-site/1\""));
    assertTrue(publication.contains("\"bundleIdentity\":"));
    assertTrue(publication.contains("\"rendererIdentity\":"));
    assertTrue(Files.isRegularFile(first.resolve("index.html")));
    assertTrue(Files.isRegularFile(first.resolve("proposals/index.html")));
    assertTrue(Files.isRegularFile(first.resolve("reference/bytecode.html")));
    String index = Files.readString(first.resolve("index.html"));
    assertTrue(index.startsWith("<!doctype html>"));
    assertTrue(index.contains("Content-Security-Policy"));
    assertTrue(index.contains("Generated from the verified Wheeler documentation graph"));
    assertFalse(index.contains("<script"));
    assertEquals(Files.readString(first.resolve("proposals/index.html")),
        Files.readString(second.resolve("proposals/index.html")));
    assertTrue(output.toString(StandardCharsets.UTF_8)
        .contains("published Wheeler documentation site"));

    assertThrows(IOException.class, () -> Wheeler.execute(
        new String[] {"site", "-o", first.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
  }
}
