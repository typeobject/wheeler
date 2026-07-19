package com.typeobject.wheeler.packageformat;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Bounded parser and emitter helpers for Wheeler's deliberately small YAML profile.
 *
 * <p>This is not a general YAML library wearing a fake moustache. It accepts only block mappings,
 * block sequences, quoted strings, canonical integers, booleans, and the empty sequence. Schema
 * decoders remain responsible for rejecting unknown fields and invalid value shapes.
 */
final class CanonicalYaml {
  private static final int MAX_DEPTH = 64;
  private static final int MAX_LINES = 100_000;
  private static final int MAX_NODES = 100_000;
  private static final int MAX_SCALAR = 16_384;

  private CanonicalYaml() {}

  static Value parse(String source, String description) {
    if (source.indexOf('\r') >= 0 || source.indexOf('\t') >= 0 || source.indexOf('\0') >= 0) {
      throw new PackageFormatException(description + " contains CR, tab, or NUL");
    }
    String[] physical = source.split("\n", -1);
    if (physical.length > MAX_LINES) {
      throw new PackageFormatException(description + " has too many lines");
    }
    List<Line> lines = new ArrayList<>();
    for (int index = 0; index < physical.length; index++) {
      String text = physical[index];
      if (text.isEmpty() || text.startsWith("#")) {
        continue;
      }
      int spaces = 0;
      while (spaces < text.length() && text.charAt(spaces) == ' ') {
        spaces++;
      }
      if ((spaces & 1) != 0 || spaces == text.length()) {
        throw problem(description, index + 1, "indentation is not two-space canonical");
      }
      String content = text.substring(spaces);
      if (content.startsWith("#")) {
        continue;
      }
      if (content.startsWith("---") || content.startsWith("...") || content.startsWith("%")
          || content.startsWith("&") || content.startsWith("*") || content.startsWith("!")) {
        throw problem(description, index + 1, "unsupported YAML feature");
      }
      lines.add(new Line(spaces, content, index + 1));
    }
    if (lines.isEmpty()) {
      throw new PackageFormatException(description + " is empty");
    }
    Parser parser = new Parser(lines, description);
    Value value = parser.block(lines.getFirst().indent(), 0);
    if (parser.position != lines.size()) {
      throw problem(description, lines.get(parser.position).number(), "unexpected indentation");
    }
    return value;
  }

  static Mapping mapping(Value value, String description) {
    if (value instanceof Mapping mapping) {
      return mapping;
    }
    throw new PackageFormatException("Expected YAML mapping for " + description);
  }

  static Sequence sequence(Value value, String description) {
    if (value instanceof Sequence sequence) {
      return sequence;
    }
    throw new PackageFormatException("Expected YAML sequence for " + description);
  }

  static String string(Value value, String description) {
    if (value instanceof Scalar scalar && scalar.kind() == ScalarKind.STRING) {
      return scalar.text();
    }
    throw new PackageFormatException("Expected quoted YAML string for " + description);
  }

  static int integer(Value value, String description) {
    if (value instanceof Scalar scalar && scalar.kind() == ScalarKind.INTEGER) {
      try {
        return Integer.parseInt(scalar.text());
      } catch (NumberFormatException exception) {
        throw new PackageFormatException("YAML integer is out of range for " + description,
            exception);
      }
    }
    throw new PackageFormatException("Expected YAML integer for " + description);
  }

  static boolean bool(Value value, String description) {
    if (value instanceof Scalar scalar && scalar.kind() == ScalarKind.BOOLEAN) {
      return Boolean.parseBoolean(scalar.text());
    }
    throw new PackageFormatException("Expected YAML boolean for " + description);
  }

  static Value required(Mapping mapping, String key, String description) {
    Value value = mapping.values().get(key);
    if (value == null) {
      throw new PackageFormatException("Missing YAML field " + description + "." + key);
    }
    return value;
  }

  static void fields(Mapping mapping, Set<String> allowed, String description) {
    for (String key : mapping.values().keySet()) {
      if (!allowed.contains(key)) {
        throw new PackageFormatException("Unknown YAML field " + description + "." + key);
      }
    }
  }

  static String quote(String value) {
    StringBuilder result = new StringBuilder(value.length() + 2).append('"');
    for (int index = 0; index < value.length(); index++) {
      char next = value.charAt(index);
      switch (next) {
        case '"' -> result.append("\\\"");
        case '\\' -> result.append("\\\\");
        case '\b' -> result.append("\\b");
        case '\f' -> result.append("\\f");
        case '\n' -> result.append("\\n");
        case '\r' -> result.append("\\r");
        case '\t' -> result.append("\\t");
        default -> {
          if (next < 0x20 || next == 0x7f) {
            result.append(String.format(java.util.Locale.ROOT, "\\u%04x", (int) next));
          } else {
            result.append(next);
          }
        }
      }
    }
    return result.append('"').toString();
  }

  sealed interface Value permits Mapping, Sequence, Scalar {}

  record Mapping(Map<String, Value> values) implements Value {
    Mapping {
      values = Map.copyOf(values);
    }
  }

  record Sequence(List<Value> values) implements Value {
    Sequence {
      values = List.copyOf(values);
    }
  }

  record Scalar(ScalarKind kind, String text) implements Value {}

  enum ScalarKind {
    STRING,
    INTEGER,
    BOOLEAN
  }

  private record Line(int indent, String content, int number) {}

  private static final class Parser {
    private final List<Line> lines;
    private final String description;
    private int position;
    private int nodes;

    private Parser(List<Line> lines, String description) {
      this.lines = lines;
      this.description = description;
    }

    private Value block(int indent, int depth) {
      if (depth > MAX_DEPTH) {
        throw new PackageFormatException(description + " exceeds YAML nesting limit");
      }
      Line line = lines.get(position);
      if (line.indent() != indent) {
        throw problem(description, line.number(), "unexpected indentation");
      }
      return line.content().startsWith("- ")
          ? sequenceBlock(indent, depth)
          : mappingBlock(indent, depth);
    }

    private Value mappingBlock(int indent, int depth) {
      Map<String, Value> values = new LinkedHashMap<>();
      while (position < lines.size()) {
        Line line = lines.get(position);
        if (line.indent() < indent) {
          break;
        }
        if (line.indent() != indent || line.content().startsWith("- ")) {
          throw problem(description, line.number(), "malformed mapping indentation");
        }
        Field field = field(line, line.content());
        position++;
        Value value = field.tail().isEmpty()
            ? child(indent, depth, line, field.key())
            : field.emptySequence() ? new Sequence(List.of()) : scalar(field.tail(), line);
        if (values.put(field.key(), value) != null) {
          throw problem(description, line.number(), "duplicate key " + field.key());
        }
        count(line);
      }
      return new Mapping(values);
    }

    private Value sequenceBlock(int indent, int depth) {
      List<Value> values = new ArrayList<>();
      while (position < lines.size()) {
        Line line = lines.get(position);
        if (line.indent() < indent) {
          break;
        }
        if (line.indent() != indent || !line.content().startsWith("- ")) {
          throw problem(description, line.number(), "malformed sequence indentation");
        }
        String item = line.content().substring(2);
        if (item.isEmpty()) {
          throw problem(description, line.number(), "empty sequence item");
        }
        if (looksLikeField(item)) {
          values.add(sequenceMapping(indent, depth, line, item));
        } else {
          position++;
          values.add(scalar(item, line));
          count(line);
        }
      }
      return new Sequence(values);
    }

    private Value sequenceMapping(int indent, int depth, Line firstLine, String firstContent) {
      Map<String, Value> values = new LinkedHashMap<>();
      Field first = field(firstLine, firstContent);
      position++;
      Value firstValue = first.tail().isEmpty()
          ? child(indent, depth, firstLine, first.key())
          : first.emptySequence() ? new Sequence(List.of()) : scalar(first.tail(), firstLine);
      values.put(first.key(), firstValue);
      count(firstLine);
      int memberIndent = indent + 2;
      while (position < lines.size()) {
        Line line = lines.get(position);
        if (line.indent() <= indent) {
          break;
        }
        if (line.indent() != memberIndent || line.content().startsWith("- ")) {
          throw problem(description, line.number(), "malformed sequence mapping indentation");
        }
        Field field = field(line, line.content());
        position++;
        Value value = field.tail().isEmpty()
            ? child(memberIndent, depth + 1, line, field.key())
            : field.emptySequence() ? new Sequence(List.of()) : scalar(field.tail(), line);
        if (values.put(field.key(), value) != null) {
          throw problem(description, line.number(), "duplicate key " + field.key());
        }
        count(line);
      }
      return new Mapping(values);
    }

    private Value child(int parentIndent, int depth, Line parent, String key) {
      if (position >= lines.size() || lines.get(position).indent() <= parentIndent) {
        throw problem(description, parent.number(), "missing value for " + key);
      }
      if (lines.get(position).indent() != parentIndent + 2) {
        throw problem(description, lines.get(position).number(), "indentation jumps a level");
      }
      return block(parentIndent + 2, depth + 1);
    }

    private Scalar scalar(String source, Line line) {
      if (source.length() > MAX_SCALAR) {
        throw problem(description, line.number(), "scalar exceeds size limit");
      }
      if (source.equals("true") || source.equals("false")) {
        return new Scalar(ScalarKind.BOOLEAN, source);
      }
      if (source.equals("[]")) {
        throw problem(description, line.number(), "empty sequence is not a scalar");
      }
      if (source.matches("0|[1-9][0-9]*")) {
        return new Scalar(ScalarKind.INTEGER, source);
      }
      if (!source.startsWith("\"") || !source.endsWith("\"") || source.length() < 2) {
        throw problem(description, line.number(), "plain, tagged, or composite scalar is forbidden");
      }
      return new Scalar(ScalarKind.STRING, unquote(source, line));
    }

    private String unquote(String source, Line line) {
      StringBuilder value = new StringBuilder(source.length() - 2);
      for (int index = 1; index < source.length() - 1; index++) {
        char next = source.charAt(index);
        if (next == '"') {
          throw problem(description, line.number(), "unescaped quote in string");
        }
        if (next != '\\') {
          value.append(next);
          continue;
        }
        if (++index >= source.length() - 1) {
          throw problem(description, line.number(), "unfinished string escape");
        }
        char escaped = source.charAt(index);
        switch (escaped) {
          case '"', '\\' -> value.append(escaped);
          case 'b' -> value.append('\b');
          case 'f' -> value.append('\f');
          case 'n' -> value.append('\n');
          case 'r' -> value.append('\r');
          case 't' -> value.append('\t');
          case 'u' -> {
            if (index + 4 >= source.length()) {
              throw problem(description, line.number(), "short Unicode escape");
            }
            String digits = source.substring(index + 1, index + 5);
            if (!digits.matches("[0-9A-Fa-f]{4}")) {
              throw problem(description, line.number(), "invalid Unicode escape");
            }
            char decoded = (char) Integer.parseInt(digits, 16);
            if (Character.isSurrogate(decoded)) {
              throw problem(description, line.number(), "surrogate Unicode escape is forbidden");
            }
            value.append(decoded);
            index += 4;
          }
          default -> throw problem(description, line.number(), "unsupported string escape");
        }
      }
      return value.toString();
    }

    private Field field(Line line, String content) {
      int colon = content.indexOf(':');
      if (colon <= 0 || (colon + 1 < content.length() && content.charAt(colon + 1) != ' ')) {
        throw problem(description, line.number(), "malformed mapping field");
      }
      String key = content.substring(0, colon);
      if (!key.matches("[a-z][a-z0-9-]*")) {
        throw problem(description, line.number(), "invalid mapping key " + key);
      }
      String tail = colon + 1 == content.length() ? "" : content.substring(colon + 2);
      if (tail.equals("[]")) {
        return new Field(key, tail, true);
      }
      return new Field(key, tail, false);
    }

    private boolean looksLikeField(String content) {
      int colon = content.indexOf(':');
      return colon > 0 && content.substring(0, colon).matches("[a-z][a-z0-9-]*");
    }

    private void count(Line line) {
      if (++nodes > MAX_NODES) {
        throw problem(description, line.number(), "node limit exceeded");
      }
    }

    private record Field(String key, String tail, boolean emptySequence) {}
  }

  private static PackageFormatException problem(String description, int line, String message) {
    return new PackageFormatException(description + " line " + line + ": " + message);
  }
}
