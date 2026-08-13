package com.typeobject.wheeler.tools;

/** Renders one reduced test report without changing its semantic outcomes. */
final class TestReportRenderer {
  enum Format {
    TERMINAL("terminal"),
    JSON("json"),
    JUNIT_XML("junit-xml");

    private final String argument;

    Format(String argument) {
      this.argument = argument;
    }

    static Format parse(String value) {
      for (Format candidate : values()) {
        if (candidate.argument.equals(value)) {
          return candidate;
        }
      }
      throw new IllegalArgumentException(
          "Test report format must be terminal, json, or junit-xml: " + value);
    }
  }

  private TestReportRenderer() {}

  static String render(TestReport report, String subject, Format format) {
    return switch (format) {
      case TERMINAL -> terminal(report, subject);
      case JSON -> json(report, subject);
      case JUNIT_XML -> junitXml(report, subject);
    };
  }

  private static String terminal(TestReport report, String subject) {
    StringBuilder output = new StringBuilder();
    for (TestReport.CaseResult result : report.cases()) {
      output.append(result.status().name()).append(' ')
          .append(result.packageName()).append("::").append(result.targetName()).append(' ')
          .append(result.caseIdentity()).append(" assertions ").append(result.assertions());
      if (!result.coverageIdentity().isEmpty()) {
        output.append(" coverage ").append(result.coverageIdentity());
      }
      if (!result.diagnosticCode().isEmpty()) {
        output.append(' ').append(result.diagnosticCode()).append(' ')
            .append(result.diagnosticMessage());
      }
      output.append('\n');
    }
    return output.append("tested ").append(subject).append(" (")
        .append(report.selected()).append(" cases, ")
        .append(report.passed()).append(" passed, ")
        .append(report.failed()).append(" failed, report ")
        .append(report.identity()).append(")\n").toString();
  }

  private static String json(TestReport report, String subject) {
    StringBuilder output = new StringBuilder();
    output.append("{\"schema\":\"wheeler.test-report-adapter/1\",\"report\":");
    appendJsonString(output, report.identity());
    output.append(",\"subject\":");
    appendJsonString(output, subject);
    output.append(",\"selected\":").append(report.selected())
        .append(",\"passed\":").append(report.passed())
        .append(",\"failed\":").append(report.failed())
        .append(",\"cases\":[");
    for (int index = 0; index < report.cases().size(); index++) {
      if (index > 0) {
        output.append(',');
      }
      appendJsonCase(output, report.cases().get(index));
    }
    return output.append("]}\n").toString();
  }

  private static void appendJsonCase(StringBuilder output, TestReport.CaseResult result) {
    output.append("{\"package\":");
    appendJsonString(output, result.packageName());
    output.append(",\"version\":");
    appendJsonString(output, result.packageVersion());
    output.append(",\"target\":");
    appendJsonString(output, result.targetName());
    output.append(",\"case\":");
    appendJsonString(output, result.caseIdentity());
    output.append(",\"source\":");
    appendJsonString(output, result.sourceIdentity());
    output.append(",\"artifact\":");
    appendJsonString(output, result.artifactIdentity());
    output.append(",\"status\":");
    appendJsonString(output, result.status().name());
    output.append(",\"diagnostic_code\":");
    appendJsonString(output, result.diagnosticCode());
    output.append(",\"diagnostic_message\":");
    appendJsonString(output, result.diagnosticMessage());
    output.append(",\"assertions\":").append(result.assertions())
        .append(",\"workflow_steps\":").append(result.workflowSteps())
        .append(",\"execution\":");
    appendJsonString(output, result.executionIdentity());
    output.append(",\"coverage\":");
    appendJsonString(output, result.coverageIdentity());
    output.append('}');
  }

  private static void appendJsonString(StringBuilder output, String value) {
    output.append('"');
    for (int index = 0; index < value.length(); index++) {
      char scalar = value.charAt(index);
      switch (scalar) {
        case '"' -> output.append("\\\"");
        case '\\' -> output.append("\\\\");
        case '\b' -> output.append("\\b");
        case '\f' -> output.append("\\f");
        case '\n' -> output.append("\\n");
        case '\r' -> output.append("\\r");
        case '\t' -> output.append("\\t");
        default -> {
          if (scalar < 0x20 || scalar > 0x7e) {
            output.append("\\u%04x".formatted((int) scalar));
          } else {
            output.append(scalar);
          }
        }
      }
    }
    output.append('"');
  }

  private static String junitXml(TestReport report, String subject) {
    StringBuilder output = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
        .append("<testsuite name=\"");
    appendXml(output, subject);
    output.append("\" tests=\"").append(report.selected())
        .append("\" failures=\"").append(report.failed())
        .append("\" skipped=\"0\" wheeler-report=\"").append(report.identity())
        .append("\">\n");
    for (TestReport.CaseResult result : report.cases()) {
      output.append("  <testcase classname=\"");
      appendXml(output, result.packageName());
      output.append("\" name=\"");
      appendXml(output, result.targetName());
      output.append("\" assertions=\"").append(result.assertions())
          .append("\" wheeler-case=\"").append(result.caseIdentity())
          .append("\" wheeler-source=\"").append(result.sourceIdentity())
          .append("\" wheeler-artifact=\"").append(result.artifactIdentity())
          .append("\" wheeler-execution=\"").append(result.executionIdentity())
          .append("\" wheeler-coverage=\"").append(result.coverageIdentity())
          .append("\" workflow-steps=\"").append(result.workflowSteps()).append('"');
      if (result.status() == TestReport.Status.PASS) {
        output.append("/>\n");
      } else {
        output.append(">\n    <failure type=\"");
        appendXml(output, result.diagnosticCode());
        output.append("\" message=\"");
        appendXml(output, result.diagnosticMessage());
        output.append("\"/>\n  </testcase>\n");
      }
    }
    return output.append("</testsuite>\n").toString();
  }

  private static void appendXml(StringBuilder output, String value) {
    for (int offset = 0; offset < value.length();) {
      int scalar = value.codePointAt(offset);
      offset += Character.charCount(scalar);
      switch (scalar) {
        case '&' -> output.append("&amp;");
        case '<' -> output.append("&lt;");
        case '>' -> output.append("&gt;");
        case '"' -> output.append("&quot;");
        case '\'' -> output.append("&apos;");
        default -> {
          boolean allowed = scalar == 0x9 || scalar == 0xa || scalar == 0xd
              || 0x20 <= scalar && scalar <= 0xd7ff
              || 0xe000 <= scalar && scalar <= 0xfffd
              || 0x10000 <= scalar && scalar <= 0x10ffff;
          output.appendCodePoint(allowed ? scalar : 0xfffd);
        }
      }
    }
  }
}
