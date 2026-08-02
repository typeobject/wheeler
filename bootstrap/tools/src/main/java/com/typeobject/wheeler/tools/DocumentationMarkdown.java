package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Fixed safe Markdown-to-HTML renderer for Wheeler's authored manual subset. */
final class DocumentationMarkdown {
  private static final Pattern HEADING = Pattern.compile("^(#{1,6})[ \\t]+(.+?)[ \\t]*#*$");
  private static final Pattern ORDERED = Pattern.compile("^[0-9]+\\.[ \\t]+(.+)$");
  private static final Pattern INLINE = Pattern.compile(
      "`([^`]+)`|\\[([^]\\n]+)]\\(([^)\\s]+)\\)|"
          + "\\*\\*\\*([^*\\n]+)\\*\\*\\*|(?<![A-Za-z0-9])___([^_\\n]+)___(?![A-Za-z0-9])|"
          + "\\*\\*([^*\\n]+)\\*\\*|(?<![A-Za-z0-9])__([^_\\n]+)__(?![A-Za-z0-9])|"
          + "\\*([^*\\n]+)\\*|(?<![A-Za-z0-9])_([^_\\n]+)_(?![A-Za-z0-9])");
  private static final Pattern TABLE_SEPARATOR = Pattern.compile(
      "^\\|?[ \\t]*:?-{3,}:?[ \\t]*(?:\\|[ \\t]*:?-{3,}:?[ \\t]*)+\\|?$");
  private static final Pattern FRONT_MATTER_FIELD = Pattern.compile(
      "^([A-Za-z_][A-Za-z0-9_]*):[ \\t]*(.+)$");
  private static final int NO_SIDEBAR_POSITION = Integer.MAX_VALUE;

  private final List<Page> pages;
  private final Map<String, String> routes;
  private final Map<String, String> manualRoutes;

  DocumentationMarkdown(Map<String, String> sources) {
    List<Page> ordered = new ArrayList<>();
    Map<String, String> routeMap = new LinkedHashMap<>();
    Map<String, String> outputRoutes = new LinkedHashMap<>();
    Map<String, String> manualRouteMap = new LinkedHashMap<>();
    sources.entrySet().stream().sorted(Map.Entry.comparingByKey()).forEach(entry -> {
      String source = entry.getKey();
      String output = outputPath(source);
      if (routeMap.put(source, output) != null) {
        throw new PackageFormatException("Duplicate documentation page " + source);
      }
      String previousSource = outputRoutes.put(output, source);
      if (previousSource != null) {
        throw new PackageFormatException(
            "Documentation pages share route " + output + ": " + previousSource + " and " + source);
      }
      String page = manualPage(source);
      if (manualRouteMap.put(page, output) != null) {
        throw new PackageFormatException("Duplicate documentation page identity manual:" + page);
      }
      Document document = document(entry.getValue(), source);
      ordered.add(new Page(source, title(document.markdown(), source), output,
          document.markdown(), document.sidebarPosition(), document.sidebar(),
          document.sidebarChildren()));
    });
    pages = List.copyOf(ordered);
    routes = Map.copyOf(routeMap);
    manualRoutes = Map.copyOf(manualRouteMap);
  }

  List<Page> pages() {
    return pages;
  }

  List<Page> navigationPages() {
    List<Page> controllingIndexes = pages.stream()
        .filter(page -> !page.sidebarChildren())
        .toList();
    return pages.stream()
        .filter(Page::sidebar)
        .filter(page -> !page.source().equals("proposals/TEMPLATE.md"))
        .filter(page -> controllingIndexes.stream().noneMatch(index ->
            page.source().startsWith(indexPrefix(index.source()))
                && !page.source().equals(index.source())))
        .sorted(Comparator.comparingInt(DocumentationMarkdown::groupOrder)
            .thenComparingInt(DocumentationMarkdown::pageOrder)
            .thenComparing(Page::source))
        .toList();
  }

  /** Renders one complete page with fixed navigation and no executable payload. */
  String render(Page page) {
    StringBuilder html = new StringBuilder(16_384);
    html.append("<!doctype html>\n<html lang=\"en\"><head>\n")
        .append("<meta charset=\"utf-8\">\n")
        .append("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\n")
        .append("<meta http-equiv=\"Content-Security-Policy\" content=\"")
        .append("default-src 'none'; style-src 'self'; script-src 'self'; ")
        .append("img-src 'self' data:; base-uri 'none'; form-action 'none'\">\n")
        .append("<title>").append(escape(page.title())).append(" · Wheeler</title>\n")
        .append("<link rel=\"stylesheet\" href=\"")
        .append(escapeAttribute(relative(page.output(), "style.css")))
        .append("\">\n<script src=\"")
        .append(escapeAttribute(relative(page.output(), "copy.js")))
        .append("\" defer></script>\n</head><body>\n<header><a class=\"brand\" href=\"")
        .append(escapeAttribute(relative(page.output(), "index.html")))
        .append("\">Wheeler</a></header>\n")
        .append("<div class=\"layout\"><nav aria-label=\"Documentation\">\n")
        .append(navigation(page))
        .append("</nav><main>\n")
        .append(body(page))
        .append("</main></div>\n<footer>Generated from the verified Wheeler documentation graph.</footer>\n")
        .append("</body></html>\n");
    return html.toString();
  }

  private String navigation(Page current) {
    StringBuilder html = new StringBuilder();
    String group = null;
    for (Page page : navigationPages()) {
      String nextGroup = group(page);
      if (!nextGroup.equals(group)) {
        if (group != null) {
          html.append("</section>\n");
        }
        group = nextGroup;
        html.append("<section><h2>").append(escape(group)).append("</h2>\n");
      }
      html.append("<a")
          .append(page.source().equals(current.source()) ? " aria-current=\"page\"" : "")
          .append(" href=\"").append(escapeAttribute(relative(current.output(), page.output())))
          .append("\">").append(escape(page.title())).append("</a>\n");
    }
    if (group != null) {
      html.append("</section>\n");
    }
    return html.toString();
  }

  private static int groupOrder(Page page) {
    return switch (group(page)) {
      case "manual" -> 0;
      case "tutorials" -> 1;
      case "reference" -> 2;
      case "proposals" -> 3;
      case "future" -> 4;
      default -> 5;
    };
  }

  private static String group(Page page) {
    return page.source().contains("/")
        ? page.source().substring(0, page.source().indexOf('/')) : "manual";
  }

  private static int pageOrder(Page page) {
    if (page.sidebarPosition() != NO_SIDEBAR_POSITION) {
      return page.sidebarPosition();
    }
    if (page.source().equals("intro.md")) {
      return 0;
    }
    if (page.source().equals("examples.md")) {
      return 10;
    }
    if (isIndexSource(page.source()) && group(page).equals("proposals")) {
      return 0;
    }
    if (page.source().startsWith("proposals/WIP-")) {
      return 100;
    }
    if (page.source().startsWith("reference/")) {
      return switch (page.source()) {
        case "reference/language-profile.md" -> 0;
        case "reference/bytecode.md" -> 10;
        case "reference/virtual-machine.md" -> 20;
        case "reference/packages.md" -> 30;
        case "reference/hybrid-runs.md" -> 40;
        case "reference/quantum-targets.md" -> 50;
        case "reference/coverage.md" -> 60;
        case "reference/development.md" -> 70;
        default -> 100;
      };
    }
    return 100;
  }

  private String body(Page page) {
    String[] lines = page.markdown().split("\\R", -1);
    StringBuilder html = new StringBuilder();
    StringBuilder paragraph = new StringBuilder();
    Map<String, Integer> anchors = new HashMap<>();
    boolean code = false;
    boolean unordered = false;
    boolean ordered = false;
    boolean admonition = false;
    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];
      String trimmed = line.trim();
      if (trimmed.startsWith("```")) {
        flushParagraph(html, paragraph, page);
        unordered = closeList(html, unordered, "ul");
        ordered = closeList(html, ordered, "ol");
        if (code) {
          html.append("</code></pre></div>\n");
          code = false;
        } else {
          String language = trimmed.substring(3).replaceAll("[^A-Za-z0-9_-]", "");
          html.append("<div class=\"code-block\"><button class=\"copy-code\" type=\"button\"")
              .append(" aria-label=\"Copy code to clipboard\">Copy</button><pre><code")
              .append(language.isEmpty() ? "" : " class=\"language-" + language + "\"")
              .append('>');
          code = true;
        }
        continue;
      }
      if (code) {
        html.append(escape(line)).append('\n');
        continue;
      }
      if (trimmed.startsWith(":::")) {
        flushParagraph(html, paragraph, page);
        if (admonition) {
          html.append("</aside>\n");
          admonition = false;
        } else {
          String kind = trimmed.substring(3).replaceAll("[^A-Za-z0-9_-]", "");
          html.append("<aside class=\"admonition\"><strong>")
              .append(escape(kind.isEmpty() ? "note" : kind)).append("</strong>\n");
          admonition = true;
        }
        continue;
      }
      Matcher heading = HEADING.matcher(line);
      if (heading.matches()) {
        flushParagraph(html, paragraph, page);
        unordered = closeList(html, unordered, "ul");
        ordered = closeList(html, ordered, "ol");
        int level = heading.group(1).length();
        String title = heading.group(2).trim();
        String base = DocumentationAnchors.canonical(title);
        int occurrence = anchors.merge(base, 1, Math::addExact) - 1;
        String anchor = occurrence == 0 ? base : base + "-" + occurrence;
        html.append("<h").append(level).append(" id=\"")
            .append(escapeAttribute(anchor)).append("\">")
            .append(inline(title, page)).append("</h").append(level).append(">\n");
        continue;
      }
      if (trimmed.isEmpty()) {
        flushParagraph(html, paragraph, page);
        unordered = closeList(html, unordered, "ul");
        ordered = closeList(html, ordered, "ol");
        continue;
      }
      if (trimmed.equals("---") || trimmed.equals("***")) {
        flushParagraph(html, paragraph, page);
        html.append("<hr>\n");
        continue;
      }
      if (trimmed.startsWith("|") && trimmed.endsWith("|")) {
        flushParagraph(html, paragraph, page);
        unordered = closeList(html, unordered, "ul");
        ordered = closeList(html, ordered, "ol");
        int end = index + 1;
        while (end < lines.length && lines[end].trim().startsWith("|")
            && lines[end].trim().endsWith("|")) {
          end++;
        }
        boolean header = index + 1 < end
            && TABLE_SEPARATOR.matcher(lines[index + 1].trim()).matches();
        html.append("<table>");
        appendTableRow(html, tableCells(trimmed), header, page);
        int row = index + (header ? 2 : 1);
        for (; row < end; row++) {
          if (!TABLE_SEPARATOR.matcher(lines[row].trim()).matches()) {
            appendTableRow(html, tableCells(lines[row].trim()), false, page);
          }
        }
        html.append("</table>\n");
        index = end - 1;
        continue;
      }
      if (trimmed.startsWith("- ")) {
        flushParagraph(html, paragraph, page);
        ordered = closeList(html, ordered, "ol");
        if (!unordered) {
          html.append("<ul>\n");
          unordered = true;
        }
        html.append("<li>").append(inline(trimmed.substring(2), page)).append("</li>\n");
        continue;
      }
      Matcher numbered = ORDERED.matcher(trimmed);
      if (numbered.matches()) {
        flushParagraph(html, paragraph, page);
        unordered = closeList(html, unordered, "ul");
        if (!ordered) {
          html.append("<ol>\n");
          ordered = true;
        }
        html.append("<li>").append(inline(numbered.group(1), page)).append("</li>\n");
        continue;
      }
      if (trimmed.startsWith("> ")) {
        flushParagraph(html, paragraph, page);
        html.append("<blockquote>").append(inline(trimmed.substring(2), page))
            .append("</blockquote>\n");
        continue;
      }
      if (!paragraph.isEmpty()) {
        paragraph.append(' ');
      }
      paragraph.append(trimmed);
    }
    flushParagraph(html, paragraph, page);
    closeList(html, unordered, "ul");
    closeList(html, ordered, "ol");
    if (code) {
      throw new PackageFormatException("Unclosed Markdown code fence in " + page.source());
    }
    if (admonition) {
      throw new PackageFormatException("Unclosed Markdown admonition in " + page.source());
    }
    return html.toString();
  }

  private void flushParagraph(StringBuilder html, StringBuilder paragraph, Page page) {
    if (!paragraph.isEmpty()) {
      html.append("<p>").append(inline(paragraph.toString(), page)).append("</p>\n");
      paragraph.setLength(0);
    }
  }

  private String inline(String text, Page page) {
    StringBuilder html = new StringBuilder();
    Matcher matcher = INLINE.matcher(text);
    int cursor = 0;
    while (matcher.find()) {
      html.append(escape(text.substring(cursor, matcher.start())));
      if (matcher.group(1) != null) {
        html.append("<code>").append(escape(matcher.group(1))).append("</code>");
      } else if (matcher.group(2) != null) {
        html.append("<a href=\"").append(escapeAttribute(href(page, matcher.group(3))))
            .append("\">").append(escape(matcher.group(2))).append("</a>");
      } else if (matcher.group(4) != null || matcher.group(5) != null) {
        String value = matcher.group(4) != null ? matcher.group(4) : matcher.group(5);
        html.append("<strong><em>").append(escape(value)).append("</em></strong>");
      } else if (matcher.group(6) != null || matcher.group(7) != null) {
        String value = matcher.group(6) != null ? matcher.group(6) : matcher.group(7);
        html.append("<strong>").append(escape(value)).append("</strong>");
      } else {
        String value = matcher.group(8) != null ? matcher.group(8) : matcher.group(9);
        html.append("<em>").append(escape(value)).append("</em>");
      }
      cursor = matcher.end();
    }
    return html.append(escape(text.substring(cursor))).toString();
  }

  private String href(Page page, String target) {
    if (target.startsWith("https://") || target.startsWith("http://")
        || target.startsWith("mailto:") || target.startsWith("#")) {
      return target;
    }
    if (target.startsWith("manual:")) {
      String manual = target.substring("manual:".length());
      int hash = manual.indexOf('#');
      String identity = hash < 0 ? manual : manual.substring(0, hash);
      String route = manualRoutes.get(identity);
      if (route == null) {
        throw new PackageFormatException("Unknown manual link " + target);
      }
      return relative(page.output(), route) + (hash < 0 ? "" : manual.substring(hash));
    }
    if (target.startsWith("wheeler:")) {
      return "https://github.com/typeobject/wheeler/search?q="
          + target.substring("wheeler:".length()).replace("#", "%23");
    }
    int hash = target.indexOf('#');
    String path = hash < 0 ? target : target.substring(0, hash);
    String fragment = hash < 0 ? "" : target.substring(hash);
    if (isManualSource(path)) {
      Path source = Path.of(page.source());
      Path resolved = (source.getParent() == null ? Path.of(path) : source.getParent().resolve(path))
          .normalize();
      String logical = logical(resolved);
      String route = routes.get(logical);
      if (route == null) {
        throw new PackageFormatException("Unknown relative manual link " + target);
      }
      return relative(page.output(), route) + fragment;
    }
    Path repositoryPath = Path.of("docs/docs").resolve(page.source()).getParent()
        .resolve(path).normalize();
    return "https://github.com/typeobject/wheeler/blob/master/" + logical(repositoryPath) + fragment;
  }

  private void appendTableRow(
      StringBuilder html, List<String> cells, boolean header, Page page) {
    html.append("<tr>");
    for (String cell : cells) {
      html.append(header ? "<th>" : "<td>").append(inline(cell, page))
          .append(header ? "</th>" : "</td>");
    }
    html.append("</tr>");
  }

  private static List<String> tableCells(String row) {
    String body = row.substring(1, row.length() - 1);
    return java.util.Arrays.stream(body.split("\\|", -1)).map(String::trim).toList();
  }

  private static boolean closeList(StringBuilder html, boolean open, String element) {
    if (open) {
      html.append("</").append(element).append(">\n");
    }
    return false;
  }

  private static String outputPath(String source) {
    if (!isManualSource(source)) {
      throw new PackageFormatException("Documentation page is not Markdown or MDX: " + source);
    }
    Path path = Path.of(source);
    String filename = path.getFileName().toString();
    if (filename.equals("README.md") || filename.equals("index.md")
        || filename.equals("index.mdx")) {
      Path parent = path.getParent();
      return parent == null ? "manual/index.html" : logical(parent.resolve("index.html"));
    }
    return source.substring(0, source.length() - manualSuffix(source).length()) + ".html";
  }

  static String relative(String from, String to) {
    Path source = Path.of(from);
    Path parent = source.getParent();
    Path result = (parent == null ? Path.of("") : parent).relativize(Path.of(to));
    String logical = logical(result);
    return logical.isEmpty() ? Path.of(to).getFileName().toString() : logical;
  }

  private static Document document(String sourceText, String source) {
    String[] lines = sourceText.split("\\R", -1);
    if (lines.length == 0 || !lines[0].equals("---")) {
      return new Document(sourceText, NO_SIDEBAR_POSITION, true, true);
    }
    int closing = 1;
    while (closing < lines.length && !lines[closing].equals("---")) {
      closing++;
    }
    if (closing == lines.length) {
      throw new PackageFormatException("Unclosed Markdown front matter in " + source);
    }
    Map<String, String> fields = new LinkedHashMap<>();
    for (int index = 1; index < closing; index++) {
      Matcher matcher = FRONT_MATTER_FIELD.matcher(lines[index]);
      if (!matcher.matches() || fields.put(matcher.group(1), matcher.group(2).trim()) != null) {
        throw new PackageFormatException("Malformed Markdown front matter in " + source);
      }
    }
    int sidebarPosition = NO_SIDEBAR_POSITION;
    if (fields.containsKey("sidebar_position")) {
      try {
        sidebarPosition = Integer.parseInt(fields.get("sidebar_position"));
      } catch (NumberFormatException exception) {
        throw new PackageFormatException("Invalid sidebar_position in " + source);
      }
      if (sidebarPosition < 0 || sidebarPosition > 1_000_000) {
        throw new PackageFormatException("Invalid sidebar_position in " + source);
      }
    }
    boolean sidebar = booleanField(fields, "sidebar", true, source);
    boolean sidebarChildren = true;
    if (fields.containsKey("sidebar_children")) {
      if (!isIndexSource(source)) {
        throw new PackageFormatException(
            "sidebar_children is valid only on index.md or index.mdx: " + source);
      }
      String value = frontMatterScalar(fields.get("sidebar_children"));
      if (value.equals("true")) {
        sidebarChildren = true;
      } else if (value.equals("false")) {
        sidebarChildren = false;
      } else {
        throw new PackageFormatException("Invalid sidebar_children in " + source);
      }
    }
    String markdown = String.join("\n", java.util.Arrays.copyOfRange(
        lines, Math.min(closing + 1, lines.length), lines.length));
    String headingTitle = title(markdown, source);
    if (fields.containsKey("title")
        && !frontMatterScalar(fields.get("title")).equals(headingTitle)) {
      throw new PackageFormatException("Markdown front-matter title disagrees with heading in "
          + source);
    }
    return new Document(markdown, sidebarPosition, sidebar, sidebarChildren);
  }

  private static boolean booleanField(
      Map<String, String> fields, String field, boolean defaultValue, String source) {
    if (!fields.containsKey(field)) {
      return defaultValue;
    }
    String value = frontMatterScalar(fields.get(field));
    if (value.equals("true")) {
      return true;
    }
    if (value.equals("false")) {
      return false;
    }
    throw new PackageFormatException("Invalid " + field + " in " + source);
  }

  static boolean isManualSource(String source) {
    return source.endsWith(".md") || source.endsWith(".mdx");
  }

  static boolean isIndexSource(String source) {
    String filename = Path.of(source).getFileName().toString();
    return filename.equals("index.md") || filename.equals("index.mdx");
  }

  static String manualPage(String source) {
    return source.substring(0, source.length() - manualSuffix(source).length());
  }

  private static String manualSuffix(String source) {
    if (source.endsWith(".mdx")) {
      return ".mdx";
    }
    if (source.endsWith(".md")) {
      return ".md";
    }
    throw new PackageFormatException("Documentation page is not Markdown or MDX: " + source);
  }

  private static String indexPrefix(String source) {
    if (!isIndexSource(source)) {
      throw new PackageFormatException(
          "sidebar_children is valid only on index.md or index.mdx: " + source);
    }
    Path parent = Path.of(source).getParent();
    return parent == null ? "" : logical(parent) + "/";
  }

  private static String frontMatterScalar(String value) {
    if (value.length() >= 2 && ((value.startsWith("\"") && value.endsWith("\""))
        || (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length() - 1);
    }
    return value;
  }

  private static String title(String markdown, String source) {
    for (String line : markdown.split("\\R")) {
      if (line.startsWith("# ") && line.length() > 2) {
        return line.substring(2).trim();
      }
    }
    throw new PackageFormatException("Documentation page has no title: " + source);
  }

  static String escape(String value) {
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
  }

  private static String escapeAttribute(String value) {
    return escape(value).replace("\"", "&quot;").replace("'", "&#39;");
  }

  private static String logical(Path path) {
    return path.toString().replace(path.getFileSystem().getSeparator(), "/");
  }

  private record Document(
      String markdown, int sidebarPosition, boolean sidebar, boolean sidebarChildren) {}

  record Page(
      String source,
      String title,
      String output,
      String markdown,
      int sidebarPosition,
      boolean sidebar,
      boolean sidebarChildren) {}
}
