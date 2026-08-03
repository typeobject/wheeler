package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
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
    assertTrue(publication.contains("\"profile\":\"wheeler.doc-site/2\""));
    assertTrue(publication.contains("\"bundleIdentity\":"));
    assertTrue(publication.contains("\"rendererIdentity\":"));
    assertTrue(Files.isRegularFile(first.resolve("index.html")));
    assertTrue(Files.isRegularFile(first.resolve("proposals/index.html")));
    assertTrue(Files.isRegularFile(first.resolve("reference/bytecode.html")));
    assertTrue(Files.isRegularFile(first.resolve("sitemap.xml")));
    assertTrue(publication.contains("\"path\":\"sitemap.xml\""));
    assertTrue(publication.contains("\"path\":\"copy.js\""));
    assertTrue(Files.readString(first.resolve("copy.js")).contains("navigator.clipboard.writeText"));
    String style = Files.readString(first.resolve("style.css"));
    assertTrue(style.contains("pre { overflow: auto; padding: 1rem;"));
    assertTrue(style.contains("pre code { display: block; padding: 0 6rem 0 0; }"));
    assertFalse(style.contains("padding: 2.35rem 1rem 1rem"));
    String sitemap = Files.readString(first.resolve("sitemap.xml"));
    assertTrue(sitemap.startsWith("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"));
    assertTrue(sitemap.contains("Wheeler content-set-sha256:"));
    assertTrue(sitemap.contains("<loc>https://wheeler.typeobject.com/</loc>"));
    assertTrue(sitemap.contains("<loc>https://wheeler.typeobject.com/proposals/"
        + "WIP-0037-hierarchical-semantic-routine-graphs.html</loc>"));
    String index = Files.readString(first.resolve("index.html"));
    assertTrue(index.startsWith("<!doctype html>"));
    assertTrue(index.contains("Content-Security-Policy"));
    assertTrue(index.contains("Generated from the verified Wheeler documentation graph"));
    assertTrue(index.contains("<script src=\"copy.js\" defer></script>"));
    assertTrue(index.contains("class=\"copy-code\""));
    assertFalse(index.contains("<script>"));
    assertFalse(index.contains("sidebar_position:"));
    assertFalse(index.contains("description: Wheeler"));
    assertFalse(index.contains("reversible classical/quantum systems"));
    int manual = index.indexOf("<section><h2>manual</h2>");
    int tutorials = index.indexOf("<section><h2>tutorials</h2>");
    int reference = index.indexOf("<section><h2>reference</h2>");
    int proposals = index.indexOf("<section><h2>proposals</h2>");
    assertTrue(manual >= 0 && manual < tutorials && tutorials < reference
        && reference < proposals);
    int tutorialsEnd = index.indexOf("</section>", tutorials);
    String tutorialSidebar = index.substring(tutorials, tutorialsEnd);
    assertTrue(tutorialSidebar.contains(
        "<a href=\"tutorials/index.html\">Instructions for Returning</a>"));
    assertFalse(tutorialSidebar.contains("tutorials/00-return-to-which-state.html"));
    assertFalse(tutorialSidebar.contains("tutorials/12-weather.html"));
    assertTrue(Files.isRegularFile(first.resolve("tutorials/00-return-to-which-state.html")));
    assertTrue(Files.isRegularFile(first.resolve("tutorials/12-weather.html")));
    String tutorialIndex = Files.readString(first.resolve("tutorials/index.html"));
    assertTrue(tutorialIndex.contains("href=\"00-return-to-which-state.html\""));
    assertFalse(tutorialIndex.contains("href=\"01-write-the-first-instruction.html\""));
    assertFalse(tutorialIndex.contains("href=\"12-weather.html\""));
    assertFalse(index.contains("<section><h2>future</h2>"));
    assertFalse(index.contains(">WIP-0042: First-principles reversible and quantum computing tutorials</a>"));
    assertTrue(index.indexOf(">What Is Wheeler?</a>")
        < index.indexOf(">Executable examples</a>"));
    assertFalse(index.contains("WIP-XXXX: Short decision title"));
    assertTrue(Files.isRegularFile(first.resolve(
        "proposals/WIP-0037-hierarchical-semantic-routine-graphs.html")));
    assertTrue(Files.isRegularFile(first.resolve("future/index.html")));
    assertTrue(Files.isRegularFile(first.resolve("future/foundry.html")));
    String proposalsIndex = Files.readString(first.resolve("proposals/index.html"));
    assertFalse(proposalsIndex.contains(">WIP-0037: Hierarchical semantic routine graphs and verified transformations</a>"));
    assertFalse(proposalsIndex.contains("<section><h2>future</h2>"));
    assertEquals(proposalsIndex,
        Files.readString(second.resolve("proposals/index.html")));
    assertTrue(output.toString(StandardCharsets.UTF_8)
        .contains("published Wheeler documentation site"));

    assertThrows(IOException.class, () -> Wheeler.execute(
        new String[] {"site", "-o", first.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
  }

  @Test
  void sitemapIdentityChangesWithPageContentAndRoutes() throws Exception {
    Map<String, byte[]> first = Map.of(
        "index.html", "first".getBytes(StandardCharsets.UTF_8),
        "reference/index.html", "reference".getBytes(StandardCharsets.UTF_8),
        "style.css", "ignored".getBytes(StandardCharsets.UTF_8));
    Map<String, byte[]> changedContent = Map.of(
        "index.html", "second".getBytes(StandardCharsets.UTF_8),
        "reference/index.html", "reference".getBytes(StandardCharsets.UTF_8));
    Map<String, byte[]> changedRoutes = Map.of(
        "index.html", "first".getBytes(StandardCharsets.UTF_8),
        "guide.html", "guide".getBytes(StandardCharsets.UTF_8));

    String sitemap = DocumentationSiteCommand.sitemap(first);
    assertNotEquals(sitemap, DocumentationSiteCommand.sitemap(changedContent));
    assertNotEquals(sitemap, DocumentationSiteCommand.sitemap(changedRoutes));
    assertTrue(sitemap.contains("<loc>https://wheeler.typeobject.com/reference/</loc>"));
    assertFalse(sitemap.contains("style.css"));
  }
}
