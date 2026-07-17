package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.Function;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.compiler.SourceModel.State;
import com.typeobject.wheeler.compiler.SourceModel.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Parser for the deliberately small, executable Wheeler source profile. */
final class SourceParser {
  private static final Pattern IDENTIFIER = Pattern.compile("[A-Za-z_][A-Za-z0-9_]*");
  private static final Pattern STATE = Pattern.compile("state\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*(\\S+)");
  private static final Pattern REV_FUNCTION = Pattern.compile(
      "rev(?:\\s+(coherent))?\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{");
  private static final Pattern FUNCTION = Pattern.compile("fn\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{");

  SourceProgram parse(String source) {
    String name = null;
    String kind = null;
    boolean versionSeen = false;
    List<State> states = new ArrayList<>();
    List<Function> functions = new ArrayList<>();
    FunctionBuilder current = null;

    String[] lines = source.split("\\R", -1);
    for (int index = 0; index < lines.length; index++) {
      int lineNumber = index + 1;
      String line = stripComment(lines[index]).trim();
      if (line.isEmpty()) {
        continue;
      }
      if (current != null) {
        if (line.equals("}")) {
          functions.add(current.build());
          current = null;
        } else {
          current.statements.add(parseStatement(line, lineNumber));
        }
        continue;
      }

      if (line.equals("wheeler 1")) {
        if (versionSeen) {
          fail(lineNumber, "duplicate language version");
        }
        versionSeen = true;
      } else if (line.startsWith("program ")) {
        if (name != null) {
          fail(lineNumber, "duplicate program declaration");
        }
        name = identifier(line.substring("program ".length()).trim(), lineNumber);
      } else if (line.startsWith("kind ")) {
        if (kind != null) {
          fail(lineNumber, "duplicate kind declaration");
        }
        kind = line.substring("kind ".length()).trim().toLowerCase(Locale.ROOT);
        if (!SetOfKinds.contains(kind)) {
          fail(lineNumber, "kind must be classical, quantum, or hybrid");
        }
      } else {
        Matcher state = STATE.matcher(line);
        Matcher reversible = REV_FUNCTION.matcher(line);
        Matcher function = FUNCTION.matcher(line);
        if (state.matches()) {
          states.add(new State(state.group(1), parseInteger(state.group(2), lineNumber), lineNumber));
        } else if (line.equals("entry {")) {
          current = new FunctionBuilder("main", true, false, false, lineNumber);
        } else if (reversible.matches()) {
          current = new FunctionBuilder(
              reversible.group(2), false, true, reversible.group(1) != null, lineNumber);
        } else if (function.matches()) {
          current = new FunctionBuilder(function.group(1), false, false, false, lineNumber);
        } else {
          fail(lineNumber, "unexpected declaration: " + line);
        }
      }
    }

    if (current != null) {
      fail(current.line, "unclosed function body");
    }
    if (!versionSeen) {
      fail(1, "expected 'wheeler 1'");
    }
    if (name == null || kind == null) {
      fail(1, "program and kind declarations are required");
    }
    long entryCount = functions.stream().filter(Function::entry).count();
    if (entryCount != 1) {
      fail(1, "exactly one entry block is required");
    }
    return new SourceProgram(name, kind, states, functions);
  }

  private static Statement parseStatement(String line, int lineNumber) {
    if (line.endsWith(";")) {
      line = line.substring(0, line.length() - 1).trim();
    }
    List<String> words = Arrays.stream(line.split("[\\s,]+"))
        .filter(word -> !word.isEmpty())
        .toList();
    if (words.isEmpty()) {
      fail(lineNumber, "empty statement");
    }
    return new Statement(words.getFirst().toLowerCase(Locale.ROOT), words.subList(1, words.size()), lineNumber);
  }

  static long parseInteger(String text, int line) {
    try {
      boolean negative = text.startsWith("-");
      String magnitude = negative ? text.substring(1) : text;
      int radix = 10;
      if (magnitude.startsWith("0x")) {
        radix = 16;
        magnitude = magnitude.substring(2);
      } else if (magnitude.startsWith("0b")) {
        radix = 2;
        magnitude = magnitude.substring(2);
      }
      long value = Long.parseLong(magnitude.replace("_", ""), radix);
      return negative ? Math.negateExact(value) : value;
    } catch (ArithmeticException | NumberFormatException exception) {
      throw new CompilerException(line, "invalid 64-bit integer: " + text);
    }
  }

  private static String identifier(String text, int line) {
    if (!IDENTIFIER.matcher(text).matches()) {
      fail(line, "invalid identifier: " + text);
    }
    return text;
  }

  private static String stripComment(String line) {
    int comment = line.indexOf("//");
    return comment < 0 ? line : line.substring(0, comment);
  }

  private static void fail(int line, String message) {
    throw new CompilerException(line, message);
  }

  private static final class FunctionBuilder {
    private final String name;
    private final boolean entry;
    private final boolean reversible;
    private final boolean coherent;
    private final int line;
    private final List<Statement> statements = new ArrayList<>();

    private FunctionBuilder(
        String name, boolean entry, boolean reversible, boolean coherent, int line) {
      this.name = name;
      this.entry = entry;
      this.reversible = reversible;
      this.coherent = coherent;
      this.line = line;
    }

    private Function build() {
      return new Function(name, entry, reversible, coherent, statements, line);
    }
  }

  private static final class SetOfKinds {
    private static boolean contains(String value) {
      return value.equals("classical") || value.equals("quantum") || value.equals("hybrid");
    }
  }
}
