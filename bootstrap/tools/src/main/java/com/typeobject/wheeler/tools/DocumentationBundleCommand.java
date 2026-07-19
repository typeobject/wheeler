package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.SourceDocumentation;
import com.typeobject.wheeler.compiler.SourceDocumentation.Declaration;
import com.typeobject.wheeler.compiler.SourceDocumentation.FileDocumentation;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Builds the first deterministic renderer-neutral documentation bundle. */
final class DocumentationBundleCommand {
  private static final int MAX_FILES = 65_535;
  private static final int MAX_BYTES = 16 * 1024 * 1024;
  private static final Pattern MARKDOWN_LINK = Pattern.compile("\\]\\(([^)\\s]+)\\)");
  private static final Pattern HEADING = Pattern.compile("^(#{1,6})[ \\t]+(.+?)[ \\t]*#*$");

  private DocumentationBundleCommand() {}

  /** Parses explicit roots and atomically emits a validated bundle directory. */
  static int execute(String[] args, PrintStream out, PrintStream error) throws Exception {
    Arguments parsed = Arguments.parse(args, error);
    if (parsed == null) {
      return 2;
    }
    List<Input> manuals = collect(parsed.manualRoot(), ".md");
    List<Input> wheeler = new ArrayList<>();
    for (Path root : parsed.wheelerRoots()) {
      wheeler.addAll(collect(root, ".w"));
    }
    wheeler.sort(Comparator.comparing(Input::logicalPath));
    rejectDuplicateLogicalPaths(wheeler, "Wheeler");
    Bundle bundle = build(manuals, wheeler);
    publish(parsed.output(), bundle.files());
    out.println("documented " + bundle.nodes() + " nodes into " + parsed.output()
        + " (" + bundle.identity() + ")");
    return 0;
  }

  private static Bundle build(List<Input> manuals, List<Input> wheeler) {
    List<Node> nodes = new ArrayList<>();
    Map<String, String> pages = new LinkedHashMap<>();
    for (Input manual : manuals) {
      String page = stripSuffix(manual.logicalPath(), ".md");
      String title = title(manual.text(), manual.logicalPath());
      String id = "manual:" + page;
      nodes.add(new Node(id, "manual", title, manual.logicalPath(), summary(manual.text())));
      for (Heading heading : headings(manual)) {
        nodes.add(new Node(
            id + "#" + heading.anchor(),
            "manual-heading",
            heading.title(),
            manual.logicalPath() + ":" + heading.line(),
            ""));
      }
      pages.put("pages/" + manual.logicalPath(), manual.text());
    }
    for (Input source : wheeler) {
      List<SourceDocumentation.Diagnostic> diagnostics = SourceDocumentation.checkFile(source.text());
      if (!diagnostics.isEmpty()) {
        var first = diagnostics.getFirst();
        throw new PackageFormatException(first.code() + " " + source.logicalPath() + ":"
            + first.line() + ":" + first.column() + " " + first.message());
      }
      FileDocumentation documentation = SourceDocumentation.extract(source.text());
      String owner = documentation.module().isEmpty()
          ? "source/" + stripSuffix(source.logicalPath(), ".w")
          : documentation.module();
      for (Declaration declaration : documentation.declarations()) {
        nodes.add(new Node(
            "wheeler:" + owner + "#" + declaration.name(),
            "wheeler-api",
            declaration.name(),
            source.logicalPath() + ":" + declaration.line(),
            declaration.summary()));
      }
    }
    nodes.sort(Comparator.comparing(Node::id));
    rejectDuplicateNodes(nodes);

    Map<String, String> files = new LinkedHashMap<>();
    files.put("nodes.json", nodesJson(nodes));
    files.put("edges.json", edgesJson(documentationEdges(manuals, nodes)));
    files.put("navigation.json", navigationJson(nodes));
    files.put("search.json", searchJson(nodes));
    pages.forEach(files::put);
    String manifest = manifestJson(files, manuals, wheeler);
    files.put("manifest.json", manifest);
    return new Bundle(Map.copyOf(files), nodes.size(), sha256(manifest.getBytes(StandardCharsets.UTF_8)));
  }

  private static List<Input> collect(Path root, String suffix) throws IOException {
    Path normalized = root.toAbsolutePath().normalize();
    if (!Files.isDirectory(normalized, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(normalized)) {
      throw new IOException("Documentation root is not a physical directory: " + root);
    }
    List<Path> paths;
    try (var walk = Files.walk(normalized)) {
      paths = walk.filter(path -> !path.equals(normalized))
          .sorted(Comparator.comparing(path -> normalized.relativize(path).toString()))
          .toList();
    }
    List<Input> result = new ArrayList<>();
    for (Path path : paths) {
      if (Files.isSymbolicLink(path)) {
        throw new IOException("Documentation input contains a symbolic link: " + path);
      }
      if (Files.isDirectory(path, LinkOption.NOFOLLOW_LINKS)) {
        continue;
      }
      if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)) {
        throw new IOException("Documentation input is not a regular file: " + path);
      }
      if (!path.getFileName().toString().endsWith(suffix)) {
        continue;
      }
      if (result.size() == MAX_FILES) {
        throw new IOException("Documentation input exceeds " + MAX_FILES + " files");
      }
      String logical = normalized.relativize(path).toString().replace(path.getFileSystem()
          .getSeparator(), "/");
      result.add(new Input(logical, readStrict(path)));
    }
    return List.copyOf(result);
  }

  private static String readStrict(Path path) throws IOException {
    byte[] bytes = Files.readAllBytes(path);
    if (bytes.length > MAX_BYTES) {
      throw new IOException("Documentation input exceeds " + MAX_BYTES + " bytes: " + path);
    }
    try {
      return StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(java.nio.ByteBuffer.wrap(bytes)).toString();
    } catch (CharacterCodingException exception) {
      throw new IOException("Documentation input is not strict UTF-8: " + path, exception);
    }
  }

  private static void publish(Path output, Map<String, String> files) throws IOException {
    Path target = output.toAbsolutePath().normalize();
    if (Files.exists(target, LinkOption.NOFOLLOW_LINKS)) {
      throw new IOException("Documentation output already exists: " + output);
    }
    Path parent = target.getParent();
    if (parent == null || !Files.isDirectory(parent, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(parent)) {
      throw new IOException("Documentation output parent is not a physical directory: " + output);
    }
    Path stage = Files.createTempDirectory(parent, ".wheeler-docs-");
    boolean published = false;
    try {
      for (Map.Entry<String, String> file : files.entrySet().stream()
          .sorted(Map.Entry.comparingByKey()).toList()) {
        Path destination = stage.resolve(file.getKey()).normalize();
        if (!destination.startsWith(stage)) {
          throw new IOException("Documentation output escapes staging root");
        }
        Files.createDirectories(destination.getParent());
        Files.writeString(destination, file.getValue(), StandardCharsets.UTF_8);
      }
      try {
        Files.move(stage, target, StandardCopyOption.ATOMIC_MOVE);
      } catch (AtomicMoveNotSupportedException exception) {
        throw new IOException("Documentation publication requires atomic directory move", exception);
      }
      published = true;
    } finally {
      if (!published) {
        deleteTree(stage);
      }
    }
  }

  private static void deleteTree(Path root) throws IOException {
    if (!Files.exists(root, LinkOption.NOFOLLOW_LINKS)) {
      return;
    }
    try (var walk = Files.walk(root)) {
      for (Path path : walk.sorted(Comparator.reverseOrder()).toList()) {
        Files.delete(path);
      }
    }
  }

  private static String nodesJson(List<Node> nodes) {
    StringBuilder json = new StringBuilder("{\"nodes\":[");
    for (int index = 0; index < nodes.size(); index++) {
      if (index > 0) {
        json.append(',');
      }
      Node node = nodes.get(index);
      json.append("{\"id\":").append(quote(node.id()))
          .append(",\"kind\":").append(quote(node.kind()))
          .append(",\"source\":").append(quote(node.source()))
          .append(",\"summary\":").append(quote(node.summary()))
          .append(",\"title\":").append(quote(node.title())).append('}');
    }
    return json.append("]}\n").toString();
  }

  private static List<Edge> documentationEdges(List<Input> manuals, List<Node> nodes) {
    Set<String> identities = new TreeSet<>();
    nodes.forEach(node -> identities.add(node.id()));
    Set<Edge> edges = new TreeSet<>(Comparator.comparing(Edge::source)
        .thenComparing(Edge::target));
    for (Input manual : manuals) {
      String source = "manual:" + stripSuffix(manual.logicalPath(), ".md");
      Matcher matcher = MARKDOWN_LINK.matcher(manual.text());
      while (matcher.find()) {
        String link = matcher.group(1);
        String target;
        if (link.startsWith("manual:") || link.startsWith("wheeler:")) {
          target = link;
        } else {
          target = relativeManualTarget(manual.logicalPath(), link);
          if (target == null) {
            continue;
          }
        }
        if (!identities.contains(target)) {
          throw new PackageFormatException(
              "Missing documentation link " + target + " from " + source);
        }
        edges.add(new Edge(source, target));
      }
    }
    return List.copyOf(edges);
  }

  private static String relativeManualTarget(String sourcePath, String link) {
    if (link.contains(":")) {
      return null;
    }
    int separator = link.indexOf('#');
    String path = separator < 0 ? link : link.substring(0, separator);
    String anchor = separator < 0 ? "" : link.substring(separator + 1);
    if ((!path.isEmpty() && !path.endsWith(".md")) || link.indexOf('#', separator + 1) >= 0) {
      return null;
    }
    Path source = Path.of(sourcePath);
    Path parent = source.getParent();
    Path resolved = path.isEmpty()
        ? source
        : (parent == null ? Path.of(path) : parent.resolve(path)).normalize();
    String logical = resolved.toString().replace(resolved.getFileSystem().getSeparator(), "/");
    if (resolved.isAbsolute() || logical.equals("..") || logical.startsWith("../")) {
      throw new PackageFormatException(
          "Relative documentation link escapes the manual root: " + link + " from " + sourcePath);
    }
    String target = "manual:" + stripSuffix(logical, ".md");
    if (!anchor.isEmpty()) {
      if (!anchor.equals(canonicalAnchor(anchor))) {
        throw new PackageFormatException(
            "Documentation heading link is not canonical: " + link + " from " + sourcePath);
      }
      target += "#" + anchor;
    }
    return target;
  }

  private static String edgesJson(List<Edge> edges) {
    StringBuilder json = new StringBuilder("{\"edges\":[");
    for (int index = 0; index < edges.size(); index++) {
      if (index > 0) {
        json.append(',');
      }
      Edge edge = edges.get(index);
      json.append("{\"kind\":\"links-to\",\"source\":")
          .append(quote(edge.source())).append(",\"target\":")
          .append(quote(edge.target())).append('}');
    }
    return json.append("]}\n").toString();
  }

  private static String navigationJson(List<Node> nodes) {
    return "{\"nodes\":[" + nodes.stream().filter(node -> node.kind().equals("manual"))
        .map(node -> quote(node.id())).reduce((left, right) -> left + "," + right).orElse("")
        + "]}\n";
  }

  private static String searchJson(List<Node> nodes) {
    StringBuilder json = new StringBuilder("{\"entries\":[");
    for (int index = 0; index < nodes.size(); index++) {
      if (index > 0) {
        json.append(',');
      }
      Node node = nodes.get(index);
      json.append("{\"id\":").append(quote(node.id()))
          .append(",\"text\":").append(quote(
              (node.title() + " " + node.summary()).toLowerCase(java.util.Locale.ROOT)))
          .append('}');
    }
    return json.append("]}\n").toString();
  }

  private static String manifestJson(
      Map<String, String> files, List<Input> manuals, List<Input> wheeler) {
    StringBuilder json = new StringBuilder("{\"files\":[");
    boolean first = true;
    for (Map.Entry<String, String> file : files.entrySet().stream()
        .sorted(Map.Entry.comparingByKey()).toList()) {
      if (!first) {
        json.append(',');
      }
      first = false;
      json.append("{\"path\":").append(quote(file.getKey()))
          .append(",\"sha256\":").append(quote(sha256(
              file.getValue().getBytes(StandardCharsets.UTF_8)))).append('}');
    }
    json.append("],\"manualSources\":").append(manuals.size())
        .append(",\"profile\":\"wheeler-doc-bundle-1\",\"wheelerSources\":")
        .append(wheeler.size()).append("}\n");
    return json.toString();
  }

  private static String title(String markdown, String path) {
    for (String line : markdown.split("\\R")) {
      if (line.startsWith("# ") && line.length() > 2) {
        return line.substring(2).trim();
      }
    }
    throw new PackageFormatException("Manual page requires one '# ' title: " + path);
  }

  private static String summary(String markdown) {
    boolean titleSeen = false;
    for (String line : markdown.split("\\R")) {
      if (!titleSeen) {
        titleSeen = line.startsWith("# ");
      } else if (!line.isBlank() && !line.startsWith("#")) {
        return line.trim();
      }
    }
    return "";
  }

  private static List<Heading> headings(Input manual) {
    List<Heading> result = new ArrayList<>();
    Map<String, Integer> occurrences = new LinkedHashMap<>();
    boolean fenced = false;
    String[] lines = manual.text().split("\\R", -1);
    for (int index = 0; index < lines.length; index++) {
      String stripped = lines[index].stripLeading();
      if (stripped.startsWith("```") || stripped.startsWith("~~~")) {
        fenced = !fenced;
        continue;
      }
      if (fenced) {
        continue;
      }
      Matcher matcher = HEADING.matcher(lines[index]);
      if (!matcher.matches()) {
        continue;
      }
      String title = matcher.group(2).trim();
      String base = canonicalAnchor(title);
      if (base.isEmpty()) {
        throw new PackageFormatException(
            "Manual heading has an empty canonical identity: "
                + manual.logicalPath() + ":" + (index + 1));
      }
      int occurrence = occurrences.merge(base, 1, Math::addExact) - 1;
      String anchor = occurrence == 0 ? base : base + "-" + occurrence;
      result.add(new Heading(anchor, title, index + 1));
      if (result.size() > 10_000) {
        throw new PackageFormatException(
            "Manual exceeds 10,000 headings: " + manual.logicalPath());
      }
    }
    return List.copyOf(result);
  }

  private static String canonicalAnchor(String title) {
    StringBuilder result = new StringBuilder();
    boolean separator = false;
    for (int codePoint : title.toLowerCase(java.util.Locale.ROOT).codePoints().toArray()) {
      if (Character.isLetterOrDigit(codePoint) || codePoint == '_') {
        if (separator && !result.isEmpty() && result.charAt(result.length() - 1) != '-') {
          result.append('-');
        }
        separator = false;
        result.appendCodePoint(codePoint);
      } else if (Character.isWhitespace(codePoint) || codePoint == '-') {
        separator = true;
      }
    }
    return result.toString();
  }

  private static void rejectDuplicateLogicalPaths(List<Input> inputs, String kind) {
    for (int index = 1; index < inputs.size(); index++) {
      if (inputs.get(index - 1).logicalPath().equals(inputs.get(index).logicalPath())) {
        throw new PackageFormatException("Duplicate " + kind + " documentation path "
            + inputs.get(index).logicalPath());
      }
    }
  }

  private static void rejectDuplicateNodes(List<Node> nodes) {
    for (int index = 1; index < nodes.size(); index++) {
      if (nodes.get(index - 1).id().equals(nodes.get(index).id())) {
        throw new PackageFormatException("Duplicate documentation node " + nodes.get(index).id());
      }
    }
  }

  private static String quote(String value) {
    StringBuilder result = new StringBuilder("\"");
    value.codePoints().forEach(codePoint -> {
      switch (codePoint) {
        case '"' -> result.append("\\\"");
        case '\\' -> result.append("\\\\");
        case '\n' -> result.append("\\n");
        case '\r' -> result.append("\\r");
        case '\t' -> result.append("\\t");
        default -> {
          if (codePoint < 0x20) {
            result.append(String.format(java.util.Locale.ROOT, "\\u%04x", codePoint));
          } else {
            result.appendCodePoint(codePoint);
          }
        }
      }
    });
    return result.append('"').toString();
  }

  private static String stripSuffix(String value, String suffix) {
    return value.substring(0, value.length() - suffix.length());
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private record Input(String logicalPath, String text) {}

  private record Node(String id, String kind, String title, String source, String summary) {}

  private record Edge(String source, String target) {}

  private record Heading(String anchor, String title, int line) {}

  private record Bundle(Map<String, String> files, int nodes, String identity) {}

  private record Arguments(Path manualRoot, List<Path> wheelerRoots, Path output) {
    private static Arguments parse(String[] args, PrintStream error) {
      if (args.length < 6 || !args[0].equals("docs")) {
        return usage(error);
      }
      Path manuals = Path.of(args[1]);
      List<Path> wheeler = new ArrayList<>();
      Path output = null;
      int index = 2;
      while (index < args.length) {
        if (args[index].equals("--wheeler") && index + 1 < args.length) {
          wheeler.add(Path.of(args[index + 1]));
          index += 2;
        } else if (args[index].equals("-o") && index + 1 < args.length && output == null) {
          output = Path.of(args[index + 1]);
          index += 2;
        } else {
          return usage(error);
        }
      }
      if (wheeler.isEmpty() || output == null) {
        return usage(error);
      }
      return new Arguments(manuals, List.copyOf(wheeler), output);
    }

    private static Arguments usage(PrintStream error) {
      error.println("Usage: wheeler docs <manual-dir> --wheeler <source-dir>... -o <bundle-dir>");
      return null;
    }
  }
}
