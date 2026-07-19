package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.tools.DocumentationBundleReader.Bundle;
import com.typeobject.wheeler.tools.DocumentationMarkdown.Page;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Zero-configuration Wheeler documentation bundle and static-site publication command. */
final class DocumentationSiteCommand {
  private static final String SITE_PROFILE = "wheeler.doc-site/1";
  private static final String SITE_ORIGIN = "https://wheeler.typeobject.com/";
  private static final List<String> WHEELER_ROOTS = List.of(
      "wheeler-compiler/src/main/wheeler",
      "wheeler-core/src/main/wheeler",
      "wheeler-examples/src/main/wheeler",
      "wheeler-package/src/main/wheeler",
      "wheeler-runtime/src/main/wheeler");
  private static final long MAX_SITE_BYTES = 64L * 1024 * 1024;
  private static final int MAX_SITEMAP_URLS = 50_000;
  private static final long MAX_SITEMAP_BYTES = 50L * 1024 * 1024;

  private DocumentationSiteCommand() {}

  /** Builds the repository's conventional documentation roots into one immutable static site. */
  static int execute(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 3 || !args[1].equals("-o")) {
      error.println("Usage: wheeler site -o <site-directory>");
      return 2;
    }
    Path repository = physicalDirectory(Path.of("."), "repository root");
    Path output = Path.of(args[2]).toAbsolutePath().normalize();
    if (Files.exists(output, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("Documentation site output already exists: " + output);
    }
    Path parent = output.getParent();
    if (parent == null || !Files.isDirectory(parent, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(parent)) {
      throw new IOException("Documentation site parent is not physical: " + output);
    }
    Path bundle = Files.createTempDirectory(parent, ".wheeler-doc-bundle-");
    Files.delete(bundle);
    try {
      buildBundle(repository, bundle, error);
      Site site = render(DocumentationBundleReader.read(bundle));
      publish(output, site.files());
      out.println("published Wheeler documentation site " + site.identity()
          + " into " + output);
      return 0;
    } finally {
      deleteTree(bundle);
    }
  }

  private static void buildBundle(Path repository, Path bundle, PrintStream error)
      throws Exception {
    List<String> arguments = new java.util.ArrayList<>();
    arguments.add("docs");
    arguments.add(repository.resolve("docs/docs").toString());
    for (String root : WHEELER_ROOTS) {
      arguments.add("--wheeler");
      arguments.add(repository.resolve(root).toString());
    }
    arguments.add("-o");
    arguments.add(bundle.toString());
    int status = DocumentationBundleCommand.execute(
        arguments.toArray(String[]::new),
        new PrintStream(new ByteArrayOutputStream()),
        error);
    if (status != 0) {
      throw new IOException("Documentation bundle generation failed with status " + status);
    }
  }

  private static Site render(Bundle bundle) throws IOException {
    DocumentationMarkdown markdown = new DocumentationMarkdown(bundle.pages());
    Map<String, byte[]> files = new LinkedHashMap<>();
    Page introduction = null;
    long bytes = 0;
    for (Page page : markdown.pages()) {
      byte[] rendered = markdown.render(page).getBytes(StandardCharsets.UTF_8);
      files.put(page.output(), rendered);
      bytes = Math.addExact(bytes, rendered.length);
      if (page.source().equals("intro.md")) {
        introduction = page;
      }
    }
    if (introduction == null) {
      throw new IOException("Documentation site has no introduction page");
    }
    byte[] index = markdown.render(introduction).getBytes(StandardCharsets.UTF_8);
    byte[] style = STYLE.getBytes(StandardCharsets.UTF_8);
    files.put("index.html", index);
    files.put("style.css", style);
    files.put(".nojekyll", new byte[0]);
    byte[] sitemap = sitemap(files).getBytes(StandardCharsets.UTF_8);
    files.put("sitemap.xml", sitemap);
    bytes = Math.addExact(bytes, Math.addExact(
        index.length, Math.addExact(style.length, sitemap.length)));
    if (bytes > MAX_SITE_BYTES) {
      throw new IOException("Documentation site exceeds the 64 MiB output limit");
    }
    String renderer = rendererIdentity();
    String publication = publicationManifest(files, bundle.identity(), renderer);
    files.put("publication-manifest.json", publication.getBytes(StandardCharsets.UTF_8));
    String identity = DocumentationBundleReader.sha256(
        publication.getBytes(StandardCharsets.UTF_8));
    return new Site(Map.copyOf(files), identity);
  }

  static String sitemap(Map<String, byte[]> files) throws IOException {
    List<Map.Entry<String, byte[]>> pages = files.entrySet().stream()
        .filter(entry -> entry.getKey().endsWith(".html"))
        .sorted(Map.Entry.comparingByKey())
        .toList();
    if (pages.size() > MAX_SITEMAP_URLS) {
      throw new IOException("Documentation sitemap exceeds 50,000 URLs");
    }
    StringBuilder contentSet = new StringBuilder("wheeler-sitemap-content/1\0");
    for (Map.Entry<String, byte[]> page : pages) {
      contentSet.append(page.getKey()).append('\0')
          .append(DocumentationBundleReader.sha256(page.getValue())).append('\n');
    }
    String identity = DocumentationBundleReader.sha256(
        contentSet.toString().getBytes(StandardCharsets.UTF_8));
    StringBuilder xml = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
        .append("<!-- Wheeler content-set-sha256: ").append(identity).append(" -->\n")
        .append("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");
    for (Map.Entry<String, byte[]> page : pages) {
      xml.append("  <url><loc>")
          .append(DocumentationMarkdown.escape(publicUrl(page.getKey())))
          .append("</loc></url>\n");
    }
    String result = xml.append("</urlset>\n").toString();
    if (result.getBytes(StandardCharsets.UTF_8).length > MAX_SITEMAP_BYTES) {
      throw new IOException("Documentation sitemap exceeds 50 MiB");
    }
    return result;
  }

  private static String publicUrl(String output) {
    if (output.equals("index.html")) {
      return SITE_ORIGIN;
    }
    if (output.endsWith("/index.html")) {
      return SITE_ORIGIN + output.substring(0, output.length() - "index.html".length());
    }
    return SITE_ORIGIN + output;
  }

  private static String publicationManifest(
      Map<String, byte[]> files, String bundleIdentity, String rendererIdentity) {
    StringBuilder json = new StringBuilder("{\"bundleIdentity\":\"")
        .append(bundleIdentity).append("\",\"files\":[");
    int index = 0;
    for (Map.Entry<String, byte[]> file : files.entrySet().stream()
        .sorted(Map.Entry.comparingByKey()).toList()) {
      if (index++ > 0) {
        json.append(',');
      }
      json.append("{\"path\":\"").append(file.getKey())
          .append("\",\"sha256\":\"")
          .append(DocumentationBundleReader.sha256(file.getValue())).append("\"}");
    }
    return json.append("],\"profile\":\"").append(SITE_PROFILE)
        .append("\",\"rendererIdentity\":\"").append(rendererIdentity)
        .append("\"}\n").toString();
  }

  private static String rendererIdentity() throws IOException {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      digest.update("wheeler-doc-renderer-1\0".getBytes(StandardCharsets.UTF_8));
      for (Class<?> type : List.of(
          DocumentationAnchors.class,
          DocumentationBundleReader.class,
          DocumentationMarkdown.class,
          DocumentationSiteCommand.class)) {
        String resource = "/" + type.getName().replace('.', '/') + ".class";
        try (InputStream input = type.getResourceAsStream(resource)) {
          if (input == null) {
            throw new IOException("Documentation renderer class bytes are unavailable: " + resource);
          }
          byte[] bytes = input.readAllBytes();
          digest.update(type.getName().getBytes(StandardCharsets.UTF_8));
          digest.update((byte) 0);
          digest.update(bytes);
        }
      }
      return HexFormat.of().formatHex(digest.digest());
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void publish(Path output, Map<String, byte[]> files) throws IOException {
    Path parent = output.getParent();
    Path stage = Files.createTempDirectory(parent, ".wheeler-doc-site-");
    boolean complete = false;
    try {
      for (Map.Entry<String, byte[]> file : files.entrySet().stream()
          .sorted(Map.Entry.comparingByKey()).toList()) {
        Path destination = stage.resolve(file.getKey()).normalize();
        if (!destination.startsWith(stage)) {
          throw new IOException("Documentation site path escapes staging root");
        }
        Files.createDirectories(destination.getParent());
        Files.write(destination, file.getValue());
      }
      try {
        Files.move(stage, output, StandardCopyOption.ATOMIC_MOVE);
      } catch (AtomicMoveNotSupportedException exception) {
        throw new IOException("Documentation site publication requires atomic move", exception);
      }
      complete = true;
    } finally {
      if (!complete) {
        deleteTree(stage);
      }
    }
  }

  private static Path physicalDirectory(Path requested, String description) throws IOException {
    if (!Files.isDirectory(requested, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(requested)) {
      throw new IOException("Documentation " + description + " is not physical: " + requested);
    }
    return requested.toRealPath(LinkOption.NOFOLLOW_LINKS);
  }

  private static void deleteTree(Path root) throws IOException {
    if (!Files.exists(root, LinkOption.NOFOLLOW_LINKS)) {
      return;
    }
    try (var walk = Files.walk(root)) {
      for (Path path : walk.sorted(Comparator.reverseOrder()).toList()) {
        if (Files.isSymbolicLink(path)) {
          throw new IOException("Refusing to delete symbolic documentation staging path: " + path);
        }
        Files.delete(path);
      }
    }
  }

  private record Site(Map<String, byte[]> files, String identity) {}

  private static final String STYLE = """
      :root { color-scheme: light dark; --ink: #1b2330; --paper: #f8fafc; --line: #cad3df;
        --accent: #3957d6; --code: #edf1f6; }
      @media (prefers-color-scheme: dark) { :root { --ink: #e7edf5; --paper: #111722;
        --line: #344154; --accent: #9eafff; --code: #1c2635; } }
      * { box-sizing: border-box; }
      body { margin: 0; color: var(--ink); background: var(--paper); font: 16px/1.6
        ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
      header { position: sticky; top: 0; z-index: 2; display: flex; gap: 1rem; align-items: baseline;
        padding: .8rem max(1rem, calc((100vw - 92rem) / 2)); border-bottom: 1px solid var(--line);
        background: var(--paper); }
      .brand { color: var(--ink); font-size: 1.35rem; font-weight: 800; text-decoration: none; }
      .layout { display: grid; grid-template-columns: minmax(14rem, 20rem) minmax(0, 60rem);
        gap: 3rem; max-width: 92rem; margin: 0 auto; padding: 2rem 1rem 5rem; }
      nav { position: sticky; top: 5rem; align-self: start; max-height: calc(100vh - 6rem);
        overflow: auto; padding-right: 1rem; }
      nav section { margin-bottom: 1.2rem; }
      nav h2 { margin: 0 0 .35rem; font-size: .78rem; letter-spacing: .08em;
        text-transform: uppercase; }
      nav a { display: block; padding: .22rem .45rem; color: var(--ink); text-decoration: none;
        border-left: 2px solid transparent; }
      nav a:hover, nav a[aria-current=page] { color: var(--accent); border-color: var(--accent); }
      main { min-width: 0; }
      h1 { font-size: clamp(2rem, 5vw, 3.2rem); line-height: 1.12; }
      h2 { margin-top: 2.4rem; border-bottom: 1px solid var(--line); }
      h1, h2, h3, h4 { scroll-margin-top: 5rem; }
      a { color: var(--accent); }
      pre, code { font-family: ui-monospace, SFMono-Regular, Consolas, monospace; background: var(--code); }
      code { padding: .12rem .3rem; border-radius: .25rem; }
      pre { overflow: auto; padding: 1rem; border: 1px solid var(--line); border-radius: .45rem; }
      pre code { padding: 0; }
      table { display: block; overflow-x: auto; width: 100%; border-collapse: collapse; margin: 1rem 0; }
      th, td { padding: .45rem .65rem; border: 1px solid var(--line); text-align: left; vertical-align: top; }
      blockquote, .admonition { margin: 1rem 0; padding: .6rem 1rem; border-left: 4px solid var(--accent);
        background: var(--code); }
      footer { border-top: 1px solid var(--line); padding: 2rem; text-align: center; }
      @media (max-width: 800px) { .layout { display: block; } nav { position: static; max-height: none;
        columns: 2; margin-bottom: 3rem; } }
      """;
}
