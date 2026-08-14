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
    assertFalse(sitemap.contains("/proposals/"));
    assertFalse(sitemap.contains("/future/"));
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
    int story = index.indexOf("<section><h2>story</h2>");
    int reference = index.indexOf("<section><h2>reference</h2>");
    assertTrue(manual >= 0 && manual < story && story < reference);
    assertFalse(index.contains("<section><h2>proposals</h2>"));
    assertFalse(index.contains("<section><h2>future</h2>"));
    int storyEnd = index.indexOf("</section>", story);
    String tutorialSidebar = index.substring(story, storyEnd);
    assertTrue(tutorialSidebar.contains(
        "<a href=\"tutorials/index.html\">Home Was the Easy Part</a>"));
    assertTrue(tutorialSidebar.contains(
        "<a class=\"nav-child\" href=\"tutorials/00-return-to-which-state.html\">Home</a>"));
    assertTrue(tutorialSidebar.contains(
        "<a class=\"nav-child\" href=\"tutorials/12-weather.html\">Weather</a>"));
    assertTrue(tutorialSidebar.indexOf("Home Was the Easy Part")
        < tutorialSidebar.indexOf(">Home</a>"));
    assertTrue(tutorialSidebar.indexOf(">Home</a>")
        < tutorialSidebar.indexOf(">Weather</a>"));
    assertTrue(Files.isRegularFile(first.resolve("tutorials/00-return-to-which-state.html")));
    assertTrue(Files.isRegularFile(first.resolve("tutorials/12-weather.html")));
    String tutorialIndex = Files.readString(first.resolve("tutorials/index.html"));
    assertTrue(tutorialIndex.contains(
        "<a href=\"00-return-to-which-state.html\">Begin with <strong>Home</strong>.</a>"));
    assertTrue(tutorialIndex.contains(
        "class=\"nav-child\" href=\"01-write-the-first-instruction.html\""));
    assertTrue(tutorialIndex.contains(
        "class=\"nav-child\" href=\"12-weather.html\""));
    assertFalse(index.contains(">WIP-0042: First-principles reversible and quantum computing tutorials</a>"));
    assertTrue(index.indexOf(">What Is Wheeler?</a>")
        < index.indexOf(">Executable examples</a>"));
    assertFalse(index.contains("WIP-XXXX: Short decision title"));
    assertFalse(Files.exists(first.resolve("conformance.html")));
    assertFalse(Files.exists(first.resolve("proposals")));
    assertFalse(Files.exists(first.resolve("future")));
    assertFalse(publication.contains("conformance.html"));
    assertFalse(publication.contains("proposals/"));
    assertFalse(publication.contains("future/"));
    assertFalse(sitemap.contains("conformance"));
    assertTrue(output.toString(StandardCharsets.UTF_8)
        .contains("published Wheeler documentation site"));

    assertThrows(IOException.class, () -> Wheeler.execute(
        new String[] {"site", "-o", first.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
  }

  @Test
  void immutableBundleCanRenderAgainWithoutSemanticGeneration() throws Exception {
    Path manuals = temporary.resolve("manuals");
    Path sources = temporary.resolve("sources");
    Path bundle = temporary.resolve("bundle");
    Files.createDirectories(manuals);
    Files.createDirectories(sources);
    Files.writeString(manuals.resolve("intro.md"), "# Introduction\n\nOne page.\n");
    Files.writeString(sources.resolve("Api.w"), """
        //! One API.
        module demo.api;
        classical class Api {
          /// Returns one.
          public long one() { return 1; }
        }
        """);
    assertEquals(0, Wheeler.execute(
        new String[] {
            "docs", manuals.toString(), "--wheeler", sources.toString(),
            "-o", bundle.toString()
        },
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
    Files.delete(manuals.resolve("intro.md"));
    Files.delete(sources.resolve("Api.w"));
    Path first = temporary.resolve("bundle-site-one");
    Path second = temporary.resolve("bundle-site-two");

    assertEquals(0, Wheeler.execute(
        new String[] {"site", "--bundle", bundle.toString(), "-o", first.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));
    assertEquals(0, Wheeler.execute(
        new String[] {"site", "--bundle", bundle.toString(), "-o", second.toString()},
        new PrintStream(new ByteArrayOutputStream()),
        new PrintStream(new ByteArrayOutputStream())));

    assertEquals(
        Files.readString(first.resolve("publication-manifest.json")),
        Files.readString(second.resolve("publication-manifest.json")));
    assertTrue(Files.readString(first.resolve("publication-manifest.json"))
        .contains(DocumentationBundleReader.read(bundle).identity()));
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
