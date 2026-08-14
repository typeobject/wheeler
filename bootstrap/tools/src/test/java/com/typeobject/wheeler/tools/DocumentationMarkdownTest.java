package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.PackageFormatException;

import java.util.Map;
import org.junit.jupiter.api.Test;

/** Focused safety and presentation checks for the fixed inert Markdown profile. */
class DocumentationMarkdownTest {
  @Test
  void rendersSupportedStructureAndEscapesExecutableMarkup() {
    DocumentationMarkdown renderer = new DocumentationMarkdown(Map.of(
        "guide.md", """
            ---
            title: Guide
            sidebar_position: 1
            description: Metadata is data, not a paragraph.
            ---
            # Guide

            Read [**important details**](reference/details.md#answer), **pay attention**, and *read carefully*.
            This is __strong too__, _italic too_, and ***both together***, but snake_case stays plain.

            <script>alert('no')</script>

            | Name | Value |
            | --- | --- |
            | answer | `42` |

            ```wheeler
            assert(value < 43);
            ```
            """,
        "reference/details.md", """
            # Details

            ## Answer

            Still forty-two.
            """));

    DocumentationMarkdown.Page guide = renderer.pages().stream()
        .filter(page -> page.source().equals("guide.md"))
        .findFirst().orElseThrow();
    String html = renderer.render(guide);

    assertTrue(html.contains("<a href=\"reference/details.html#answer\">"
        + "<strong>important details</strong></a>"));
    assertTrue(html.contains("<strong>pay attention</strong>"));
    assertTrue(html.contains("<em>read carefully</em>"));
    assertTrue(html.contains("<strong>strong too</strong>"));
    assertTrue(html.contains("<em>italic too</em>"));
    assertTrue(html.contains("<strong><em>both together</em></strong>"));
    assertTrue(html.contains("snake_case stays plain"));
    assertTrue(html.contains("&lt;script&gt;alert('no')&lt;/script&gt;"));
    assertTrue(html.contains("<table><tr><th>Name</th><th>Value</th></tr>"));
    assertTrue(html.contains("<div class=\"code-block\"><button class=\"copy-code\""));
    assertTrue(html.contains("aria-label=\"Copy code to clipboard\">Copy</button>"));
    assertTrue(html.contains("<pre><code class=\"language-wheeler\">"));
    assertTrue(html.contains("<script src=\"copy.js\" defer></script>"));
    assertFalse(html.contains("<script>"));
    assertFalse(html.contains("sidebar_position"));
    assertFalse(html.contains("Metadata is data"));
    assertFalse(html.contains("reversible classical/quantum systems"));
  }

  @Test
  void indexMdxControlsSidebarChildrenAndCanHideAWholeSection() {
    DocumentationMarkdown renderer = new DocumentationMarkdown(Map.of(
        "examples.md", "# Executable examples\n",
        "archive/index.mdx", """
            ---
            title: Private archive
            sidebar: false
            sidebar_children: false
            ---
            # Private archive
            """,
        "archive/old.md", "# Old note\n",
        "intro.md", """
            ---
            title: What Is Wheeler?
            sidebar_position: 1
            ---
            # What Is Wheeler?
            """,
        "decisions/index.mdx", """
            ---
            title: Published decisions
            sidebar_position: 1
            sidebar_children: false
            ---
            # Published decisions
            """,
        "decisions/first.md", "# First decision\n",
        "reference/bytecode.md", "# Wheeler bytecode format\n",
        "reference/language-profile.md", "# Wheeler source language profile\n",
        "tutorials/index.mdx", "# Home Was the Easy Part\n"));

    DocumentationMarkdown.Page introduction = renderer.pages().stream()
        .filter(page -> page.source().equals("intro.md"))
        .findFirst().orElseThrow();
    String html = renderer.render(introduction);

    int manual = html.indexOf("<section><h2>manual</h2>");
    int story = html.indexOf("<section><h2>story</h2>");
    int reference = html.indexOf("<section><h2>reference</h2>");
    int decisions = html.indexOf("<section><h2>decisions</h2>");
    assertTrue(manual >= 0 && manual < story && story < reference
        && reference < decisions);
    assertEqualsOnce(html, "<section><h2>manual</h2>");
    assertTrue(html.indexOf(">What Is Wheeler?</a>")
        < html.indexOf(">Executable examples</a>"));
    assertTrue(html.indexOf(">Wheeler source language profile</a>")
        < html.indexOf(">Wheeler bytecode format</a>"));
    assertTrue(html.contains(">Published decisions</a>"));
    assertFalse(html.contains(">First decision</a>"));
    assertFalse(html.contains("<section><h2>archive</h2>"));
    assertFalse(html.contains(">Old note</a>"));
    assertEquals("decisions/index.html", renderer.pages().stream()
        .filter(page -> page.source().equals("decisions/index.mdx"))
        .findFirst().orElseThrow().output());
    assertEquals("archive/index.html", renderer.pages().stream()
        .filter(page -> page.source().equals("archive/index.mdx"))
        .findFirst().orElseThrow().output());
  }

  @Test
  void validatesCompleteOrderedTutorialMetadata() {
    Map<String, String> sources = new java.util.LinkedHashMap<>();
    sources.put("tutorials/index.mdx", "# Tutorial\n");
    for (int step = 0; step <= 93; step++) {
      sources.put("tutorials/%02d.md".formatted(step), """
          ---
          tutorial_id: T%02d
          tutorial_steps: T%02d
          tutorial_part: part
          tutorial_order: %d
          tutorial_kind: exact
          tutorial_source: fixture
          tutorial_expectation: pass
          tutorial_evidence: execution
          ---
          # Step %02d
          """.formatted(step, step, step, step));
    }
    DocumentationMarkdown valid = new DocumentationMarkdown(sources);
    assertEquals(95, valid.pages().size());

    Map<String, String> duplicate = new java.util.LinkedHashMap<>(sources);
    duplicate.put("tutorials/93.md", duplicate.get("tutorials/93.md")
        .replace("tutorial_id: T93", "tutorial_id: T92"));
    PackageFormatException exception = assertThrows(
        PackageFormatException.class, () -> new DocumentationMarkdown(duplicate));
    assertTrue(exception.getMessage().contains("Duplicate tutorial identity"));
  }

  @Test
  void supportsIndexMarkdownAndRejectsRouteOrSidebarMetadataConflicts() {
    DocumentationMarkdown renderer = new DocumentationMarkdown(Map.of(
        "guide/index.md", "# Guide\n",
        "guide/lesson.mdx", "# Lesson\n"));
    assertEquals("guide/index.html", renderer.pages().stream()
        .filter(page -> page.source().equals("guide/index.md"))
        .findFirst().orElseThrow().output());
    assertEquals("guide/lesson.html", renderer.pages().stream()
        .filter(page -> page.source().equals("guide/lesson.mdx"))
        .findFirst().orElseThrow().output());

    assertThrows(PackageFormatException.class, () -> new DocumentationMarkdown(Map.of(
        "guide/index.md", "# Markdown index\n",
        "guide/index.mdx", "# MDX index\n")));
    assertThrows(PackageFormatException.class, () -> new DocumentationMarkdown(Map.of(
        "guide.md", "---\nsidebar_children: false\n---\n# Guide\n")));
    assertThrows(PackageFormatException.class, () -> new DocumentationMarkdown(Map.of(
        "guide/index.mdx", "---\nsidebar: sometimes\n---\n# Guide\n")));
  }

  @Test
  void rejectsUnclosedFrontMatter() {
    assertThrows(PackageFormatException.class, () -> new DocumentationMarkdown(Map.of(
        "broken.md", "---\ntitle: Broken\n# Broken\n")));
  }

  private static void assertEqualsOnce(String text, String value) {
    int first = text.indexOf(value);
    assertTrue(first >= 0);
    assertTrue(text.indexOf(value, first + value.length()) < 0);
  }
}
