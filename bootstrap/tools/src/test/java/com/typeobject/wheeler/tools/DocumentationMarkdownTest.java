package com.typeobject.wheeler.tools;

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

            Read [details](reference/details.md#answer) and **pay attention**.

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

    assertTrue(html.contains("href=\"reference/details.html#answer\""));
    assertTrue(html.contains("<strong>pay attention</strong>"));
    assertTrue(html.contains("&lt;script&gt;alert('no')&lt;/script&gt;"));
    assertTrue(html.contains("<table><tr><th>Name</th><th>Value</th></tr>"));
    assertTrue(html.contains("<pre><code class=\"language-wheeler\">"));
    assertFalse(html.contains("<script>"));
    assertFalse(html.contains("sidebar_position"));
    assertFalse(html.contains("Metadata is data"));
    assertFalse(html.contains("reversible classical/quantum systems"));
  }

  @Test
  void ordersOneSidebarByWheelerSectionAndHidesTheProposalTemplate() {
    DocumentationMarkdown renderer = new DocumentationMarkdown(Map.of(
        "examples.md", "# Executable examples\n",
        "future/murphy.md", """
            ---
            title: Murphy
            sidebar_position: 2
            ---
            # Murphy
            """,
        "intro.md", """
            ---
            title: What Is Wheeler?
            sidebar_position: 1
            ---
            # What Is Wheeler?
            """,
        "proposals/README.md", "# Wheeler Improvement Proposals\n",
        "proposals/TEMPLATE.md", "# WIP-XXXX: Short decision title\n",
        "proposals/WIP-0001-first.md", "# WIP-0001: First\n",
        "reference/bytecode.md", "# Wheeler bytecode format\n",
        "reference/language-profile.md", "# Wheeler source language profile\n"));

    DocumentationMarkdown.Page introduction = renderer.pages().stream()
        .filter(page -> page.source().equals("intro.md"))
        .findFirst().orElseThrow();
    String html = renderer.render(introduction);

    int manual = html.indexOf("<section><h2>manual</h2>");
    int reference = html.indexOf("<section><h2>reference</h2>");
    int proposals = html.indexOf("<section><h2>proposals</h2>");
    int future = html.indexOf("<section><h2>future</h2>");
    assertTrue(manual >= 0 && manual < reference && reference < proposals && proposals < future);
    assertEqualsOnce(html, "<section><h2>manual</h2>");
    assertTrue(html.indexOf(">What Is Wheeler?</a>")
        < html.indexOf(">Executable examples</a>"));
    assertTrue(html.indexOf(">Wheeler source language profile</a>")
        < html.indexOf(">Wheeler bytecode format</a>"));
    assertFalse(html.contains("WIP-XXXX: Short decision title"));
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
