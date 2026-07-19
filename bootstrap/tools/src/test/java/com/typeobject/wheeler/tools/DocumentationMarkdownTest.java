package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;
import org.junit.jupiter.api.Test;

/** Focused safety and presentation checks for the fixed inert Markdown profile. */
class DocumentationMarkdownTest {
  @Test
  void rendersSupportedStructureAndEscapesExecutableMarkup() {
    DocumentationMarkdown renderer = new DocumentationMarkdown(Map.of(
        "guide.md", """
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
  }
}
