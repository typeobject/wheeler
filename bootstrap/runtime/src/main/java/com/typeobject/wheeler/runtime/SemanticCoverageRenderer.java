package com.typeobject.wheeler.runtime;

import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;

/** Presentation adapters for typed transition coverage with explicit unsupported dimensions. */
public final class SemanticCoverageRenderer {
  private static final String UNSUPPORTED =
      "source-lines,source-branches,proof-obligations,quantum-state,empirical-targets";

  /** Supported presentation formats; none changes semantic coverage identity. */
  public enum Format {
    TERMINAL,
    JSON,
    LCOV,
    COBERTURA,
    WEBSITE
  }

  private SemanticCoverageRenderer() {}

  /** Renders one deterministic adapter and discloses every unavailable dimension. */
  public static String render(SemanticCoverage coverage, String subject, Format format) {
    Objects.requireNonNull(coverage, "coverage");
    Objects.requireNonNull(subject, "subject");
    Objects.requireNonNull(format, "format");
    TreeMap<SemanticCoverage.Point, Long> points = new TreeMap<>(coverage.points());
    return switch (format) {
      case TERMINAL -> terminal(coverage, subject, points);
      case JSON -> json(coverage, subject, points);
      case LCOV -> lcov(coverage, subject, points);
      case COBERTURA -> cobertura(coverage, subject, points);
      case WEBSITE -> website(coverage, subject, points);
    };
  }

  private static String terminal(
      SemanticCoverage coverage,
      String subject,
      Map<SemanticCoverage.Point, Long> points) {
    StringBuilder output = new StringBuilder("coverage ")
        .append(subject).append(" profile wheeler-transition-coverage-1 identity ")
        .append(coverage.identity()).append('\n')
        .append("unsupported ").append(UNSUPPORTED).append('\n');
    points.forEach((point, count) -> output.append(point.direction()).append(' ')
        .append(point.function()).append(':').append(point.instruction()).append(' ')
        .append(point.opcode()).append(' ').append(point.branch()).append(' ')
        .append(count).append('\n'));
    return output.toString();
  }

  private static String json(
      SemanticCoverage coverage,
      String subject,
      Map<SemanticCoverage.Point, Long> points) {
    StringBuilder output = new StringBuilder("{\"schema\":\"wheeler-coverage-adapter/1\"")
        .append(",\"subject\":").append(quote(subject))
        .append(",\"identity\":\"").append(coverage.identity()).append('"')
        .append(",\"unsupported\":[");
    appendUnsupportedJson(output);
    output.append("],\"points\":[");
    int index = 0;
    for (Map.Entry<SemanticCoverage.Point, Long> entry : points.entrySet()) {
      if (index++ > 0) {
        output.append(',');
      }
      SemanticCoverage.Point point = entry.getKey();
      output.append("{\"direction\":").append(quote(point.direction()))
          .append(",\"function\":").append(point.function())
          .append(",\"instruction\":").append(point.instruction())
          .append(",\"opcode\":").append(quote(point.opcode()))
          .append(",\"branch\":").append(quote(point.branch()))
          .append(",\"count\":").append(entry.getValue()).append('}');
    }
    return output.append("]}\n").toString();
  }

  private static String lcov(
      SemanticCoverage coverage,
      String subject,
      Map<SemanticCoverage.Point, Long> points) {
    StringBuilder output = new StringBuilder("TN:").append(safeLine(subject)).append('\n')
        .append("# wheeler-report:").append(coverage.identity()).append('\n')
        .append("# wheeler-unsupported:").append(UNSUPPORTED).append('\n');
    int priorFunction = -1;
    for (Map.Entry<SemanticCoverage.Point, Long> entry : points.entrySet()) {
      SemanticCoverage.Point point = entry.getKey();
      if (point.function() != priorFunction) {
        if (priorFunction != -1) {
          output.append("end_of_record\n");
        }
        output.append("SF:wheeler-bytecode/function-").append(point.function()).append('\n');
        priorFunction = point.function();
      }
      output.append("DA:").append(point.instruction() + 1).append(',')
          .append(entry.getValue()).append('\n');
    }
    if (priorFunction != -1) {
      output.append("end_of_record\n");
    }
    return output.toString();
  }

  private static String cobertura(
      SemanticCoverage coverage,
      String subject,
      Map<SemanticCoverage.Point, Long> points) {
    StringBuilder output = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
        .append("<coverage wheeler-profile=\"wheeler-transition-coverage-1\"")
        .append(" wheeler-report=\"").append(coverage.identity()).append('"')
        .append(" wheeler-subject=\"").append(xml(subject)).append('"')
        .append(" wheeler-unsupported=\"").append(UNSUPPORTED).append("\">\n")
        .append("  <packages><package name=\"wheeler-bytecode\"><classes>\n");
    for (Map.Entry<SemanticCoverage.Point, Long> entry : points.entrySet()) {
      SemanticCoverage.Point point = entry.getKey();
      output.append("    <class name=\"function-").append(point.function())
          .append("\" filename=\"wheeler-bytecode/function-").append(point.function())
          .append("\"><lines><line number=\"").append(point.instruction() + 1)
          .append("\" hits=\"").append(entry.getValue()).append("\"/></lines></class>\n");
    }
    return output.append("  </classes></package></packages>\n</coverage>\n").toString();
  }

  private static String website(
      SemanticCoverage coverage,
      String subject,
      Map<SemanticCoverage.Point, Long> points) {
    StringBuilder output = new StringBuilder("<!doctype html><html><head>")
        .append("<meta charset=\"utf-8\"/><meta name=\"wheeler-coverage-profile\"")
        .append(" content=\"wheeler-transition-coverage-1\"/></head><body><main>")
        .append("<h1>").append(html(subject)).append("</h1><p>Report ")
        .append(coverage.identity()).append("</p><p data-unsupported=\"")
        .append(UNSUPPORTED).append("\">Unsupported dimensions: ")
        .append(UNSUPPORTED).append("</p><table><thead><tr><th>Direction</th>")
        .append("<th>Function</th><th>Instruction</th><th>Opcode</th><th>Branch</th>")
        .append("<th>Hits</th></tr></thead><tbody>");
    points.forEach((point, count) -> output.append("<tr><td>").append(html(point.direction()))
        .append("</td><td>").append(point.function()).append("</td><td>")
        .append(point.instruction()).append("</td><td>").append(html(point.opcode()))
        .append("</td><td>").append(html(point.branch())).append("</td><td>")
        .append(count).append("</td></tr>"));
    return output.append("</tbody></table></main></body></html>\n").toString();
  }

  private static void appendUnsupportedJson(StringBuilder output) {
    String[] dimensions = UNSUPPORTED.split(",");
    for (int index = 0; index < dimensions.length; index++) {
      if (index > 0) {
        output.append(',');
      }
      output.append(quote(dimensions[index]));
    }
  }

  private static String quote(String value) {
    StringBuilder output = new StringBuilder("\"");
    for (int index = 0; index < value.length(); index++) {
      char scalar = value.charAt(index);
      if (scalar == '"' || scalar == '\\') {
        output.append('\\');
      }
      output.append(scalar < 0x20 ? '?' : scalar);
    }
    return output.append('"').toString();
  }

  private static String xml(String value) {
    return value.replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&apos;");
  }

  private static String html(String value) {
    return xml(value);
  }

  private static String safeLine(String value) {
    return value.replace('\r', ' ').replace('\n', ' ');
  }
}
