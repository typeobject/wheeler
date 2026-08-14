package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/** Compiles, executes, and replays exact Wheeler examples from maintained manuals. */
final class DocumentationExampleRunner {
  private static final int MAX_EXAMPLES = 256;
  private static final int MAX_SOURCE_BYTES = 32_768;
  private static final int MAX_OUTPUT_BYTES = 4_096;
  private static final Pattern NAME = Pattern.compile("[a-z][a-z0-9-]{0,63}");
  private static final Pattern RESULT_RECORD = Pattern.compile(
      "\\{\\\"artifact\\\":\\\"[0-9a-f]{64}\\\","
          + "\\\"id\\\":\\\"example:[a-zA-Z0-9._/-]+#[a-z][a-z0-9-]{0,63}\\\","
          + "\\\"output\\\":\\\"[0-9a-f]{0,8192}\\\","
          + "\\\"result\\\":\\\"[0-9a-f]{64}\\\","
          + "\\\"source\\\":\\\"[0-9a-f]{64}\\\"}");

  record Manual(String page, String logicalPath, String text) {}

  record Result(
      String id,
      String owner,
      String source,
      String sourceIdentity,
      String artifactIdentity,
      String resultIdentity,
      String outputHex) {}

  private DocumentationExampleRunner() {}

  /** Returns validated results in canonical example-identity order. */
  static List<Result> run(List<Manual> manuals) {
    List<Result> results = new ArrayList<>();
    for (Manual manual : manuals) {
      String[] lines = manual.text().split("\\R", -1);
      String inertFence = null;
      for (int line = 0; line < lines.length; line++) {
        String header = lines[line].strip();
        if (inertFence != null) {
          if (header.startsWith(inertFence)) {
            inertFence = null;
          }
          continue;
        }
        if (!header.startsWith("```wheeler-exact")) {
          inertFence = fenceMarker(header);
          continue;
        }
        Header parsed = parseHeader(header, manual.logicalPath(), line + 1);
        StringBuilder source = new StringBuilder();
        int openingLine = line + 1;
        line++;
        while (line < lines.length && !lines[line].strip().equals("```")) {
          source.append(lines[line]).append('\n');
          line++;
        }
        if (line == lines.length) {
          fail(manual.logicalPath(), openingLine, "unclosed exact Wheeler example");
        }
        byte[] sourceBytes = source.toString().getBytes(StandardCharsets.UTF_8);
        if (sourceBytes.length == 0 || sourceBytes.length > MAX_SOURCE_BYTES) {
          fail(manual.logicalPath(), openingLine, "example source extent is out of bounds");
        }
        if (results.size() == MAX_EXAMPLES) {
          fail(manual.logicalPath(), openingLine, "documentation example count exceeds 256");
        }
        String id = "example:" + manual.page() + "#" + parsed.name();
        if (results.stream().anyMatch(result -> result.id().equals(id))) {
          fail(manual.logicalPath(), openingLine, "duplicate example identity " + id);
        }
        results.add(execute(
            id,
            "manual:" + manual.page(),
            manual.logicalPath() + ":" + openingLine,
            source.toString(),
            parsed.expected(),
            openingLine));
      }
    }
    results.sort(java.util.Comparator.comparing(Result::id));
    return List.copyOf(results);
  }

  /** Emits exact result identities as canonical JSON. */
  static String canonicalJson(List<Result> results) {
    StringBuilder json = new StringBuilder(
        "{\"profile\":\"wheeler-documentation-examples-1\",\"results\":[");
    for (int index = 0; index < results.size(); index++) {
      if (index > 0) {
        json.append(',');
      }
      Result result = results.get(index);
      json.append("{\"artifact\":").append(quote(result.artifactIdentity()))
          .append(",\"id\":").append(quote(result.id()))
          .append(",\"output\":").append(quote(result.outputHex()))
          .append(",\"result\":").append(quote(result.resultIdentity()))
          .append(",\"source\":").append(quote(result.sourceIdentity()))
          .append('}');
    }
    return json.append("]}\n").toString();
  }

  /** Rejects malformed or noncanonical profile-1 example result rows. */
  static void validateCanonicalJson(String json) {
    String prefix =
        "{\"profile\":\"wheeler-documentation-examples-1\",\"results\":[";
    String suffix = "]}\n";
    if (!json.startsWith(prefix) || !json.endsWith(suffix)) {
      throw new PackageFormatException("Malformed documentation example result framing");
    }
    String records = json.substring(prefix.length(), json.length() - suffix.length());
    String previous = null;
    int cursor = 0;
    int count = 0;
    while (cursor < records.length()) {
      var matcher = RESULT_RECORD.matcher(records);
      matcher.region(cursor, records.length());
      if (!matcher.lookingAt()) {
        throw new PackageFormatException("Malformed documentation example result row");
      }
      String row = matcher.group();
      int idStart = row.indexOf("example:");
      int idEnd = row.indexOf('\"', idStart);
      String id = row.substring(idStart, idEnd);
      if (previous != null && previous.compareTo(id) >= 0) {
        throw new PackageFormatException(
            "Documentation example identities are duplicated or unordered");
      }
      previous = id;
      count++;
      if (count > MAX_EXAMPLES) {
        throw new PackageFormatException("Documentation example count exceeds 256");
      }
      cursor = matcher.end();
      if (cursor < records.length()) {
        if (records.charAt(cursor) != ',') {
          throw new PackageFormatException("Malformed documentation example separator");
        }
        cursor++;
      }
    }
  }

  private static Result execute(
      String id,
      String owner,
      String location,
      String source,
      byte[] expected,
      int line) {
    try {
      String module = com.typeobject.wheeler.compiler.SourceDocumentation.extract(source).module();
      if (module.isEmpty()) {
        fail(location, line, "exact example requires one named module");
      }
      var program = new WheelerCompiler().compileModuleFiles(
          Map.of("DocumentationExample.w", source), module);
      byte[] artifact = new BytecodeWriter().write(program);
      byte[] first = execute(program, expected.length);
      byte[] replay = execute(program, expected.length);
      if (!Arrays.equals(first, replay)) {
        fail(location, line, "exact example replay differs from its first execution");
      }
      if (!Arrays.equals(expected, first)) {
        fail(location, line,
            "exact example output is " + HexFormat.of().formatHex(first)
                + ", expected " + HexFormat.of().formatHex(expected));
      }
      String sourceIdentity = sha256(source.getBytes(StandardCharsets.UTF_8));
      String artifactIdentity = sha256(artifact);
      byte[] resultInput = (sourceIdentity + "\0" + artifactIdentity + "\0"
          + HexFormat.of().formatHex(first)).getBytes(StandardCharsets.UTF_8);
      String resultIdentity = digest("wheeler-documentation-example-result-1", resultInput);
      return new Result(
          id,
          owner,
          location,
          sourceIdentity,
          artifactIdentity,
          resultIdentity,
          HexFormat.of().formatHex(first));
    } catch (PackageFormatException exception) {
      throw exception;
    } catch (RuntimeException exception) {
      throw new PackageFormatException(
          "Documentation example failed at " + location + ": " + exception.getMessage(),
          exception);
    }
  }

  private static byte[] execute(
      com.typeobject.wheeler.core.bytecode.Program program, int outputBytes) {
    VirtualMachine machine = new VirtualMachine(program, new byte[0], outputBytes);
    machine.run();
    return machine.hostOutput();
  }

  private static String fenceMarker(String line) {
    if (!(line.startsWith("```") || line.startsWith("~~~"))) {
      return null;
    }
    char marker = line.charAt(0);
    int length = 0;
    while (length < line.length() && line.charAt(length) == marker) {
      length++;
    }
    return line.substring(0, length);
  }

  private static Header parseHeader(String header, String path, int line) {
    String[] fields = header.split(" +");
    if (fields.length != 3
        || !fields[1].startsWith("name=")
        || !fields[2].startsWith("output=")) {
      fail(path, line, "exact example header requires name and lowercase hexadecimal output");
    }
    String name = fields[1].substring(5);
    String output = fields[2].substring(7);
    if (!NAME.matcher(name).matches()
        || output.length() > MAX_OUTPUT_BYTES * 2
        || (output.length() & 1) != 0
        || !output.matches("[0-9a-f]*")) {
      fail(path, line, "exact example name or output is not canonical and bounded");
    }
    return new Header(name, HexFormat.of().parseHex(output));
  }

  private static String digest(String domain, byte[] bytes) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      digest.update(domain.getBytes(StandardCharsets.UTF_8));
      digest.update((byte) 0);
      return HexFormat.of().formatHex(digest.digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String quote(String value) {
    return '"' + value.replace("\\", "\\\\").replace("\"", "\\\"") + '"';
  }

  private static void fail(String path, int line, String message) {
    throw new PackageFormatException(path + ":" + line + ": " + message);
  }

  private record Header(String name, byte[] expected) {}
}
