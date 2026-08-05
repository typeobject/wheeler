package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.Opcode;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** High-signal source readability checks analogous to Error Prone bug patterns. */
class SourceReadabilityTest {
  private static final Pattern ENDIAN_WRITE = Pattern.compile(
      "write(?:Unsigned|Signed)LittleEndian\\(([^()]*)\\)", Pattern.DOTALL);
  private static final Pattern LABELED_INTEGER = Pattern.compile(
      "/\\* [a-z][A-Za-z0-9]*= \\*/\\s*-?[0-9]+");
  private static final Pattern INTEGER = Pattern.compile("-?[0-9]+");
  private static final Pattern JAVA_OPCODE = Pattern.compile(
      "static final int ([A-Z0-9_]+) = (0x[0-9a-f]+);");
  private static final Pattern WHEELER_OPCODE = Pattern.compile(
      "public const long OPCODE_([A-Z0-9_]+) = (0x[0-9a-f]+);");
  private static final Pattern WHEELER_FORM = Pattern.compile(
      "if \\(opcode == OPCODE_([A-Z0-9_]+)\\) \\{\\s+return ([0-9]+);");
  private static final Pattern WHEELER_OPCODE_TEST = Pattern.compile(
      "opcode == OPCODE_([A-Z0-9_]+)");
  private static final Pattern WHEELER_STATEMENT_IDENTITY = Pattern.compile(
      "public const long (STATEMENT_[A-Z0-9_]+) = ([0-9]+);");
  private static final Pattern JAVA_TYPE = Pattern.compile(
      "case ([A-Z0-9_]+) -> ([0-9]+);");
  private static final Pattern WHEELER_TYPE = Pattern.compile(
      "public const long TYPE_([A-Z0-9_]+) = ([0-9]+);");

  @Test
  void reportsOnlyUnlabeledAdjacentEndianLiterals() {
    List<String> diagnostics = new ArrayList<>();
    check(
        Path.of("Broken.w"),
        "cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);\n",
        diagnostics);
    assertEquals(
        List.of("Broken.w:1: WREAD001 adjacent endian literals require value and width labels"),
        diagnostics);

    diagnostics.clear();
    check(
        Path.of("Clear.w"),
        "cursor = writeUnsignedLittleEndian("
            + "output, cursor, /* value= */ 0, /* width= */ 8);\n",
        diagnostics);
    check(
        Path.of("Computed.w"),
        "cursor = writeUnsignedLittleEndian(output, cursor, value, 8);\n",
        diagnostics);
    assertEquals(List.of(), diagnostics);
  }

  @Test
  void reportsRawInstructionForms() {
    List<String> diagnostics = new ArrayList<>();
    check(
        Path.of("Broken.w"),
        "cursor = writeInstructionHeader(output, cursor, OPCODE_HALT, 0);\n",
        diagnostics);
    assertEquals(
        List.of("Broken.w:1: WREAD002 raw instruction form requires a named constant"),
        diagnostics);

    diagnostics.clear();
    check(
        Path.of("Clear.w"),
        "cursor = writeInstructionHeader(\n"
            + "  output, cursor, OPCODE_HALT, INSTRUCTION_FORM_NULLARY\n"
            + ");\n",
        diagnostics);
    assertEquals(List.of(), diagnostics);
  }

  @Test
  void nativeOpcodeIdentitiesMatchTheCanonicalRegistry() throws Exception {
    String javaSource = Files.readString(Path.of(
        "../bootstrap/core/src/main/java/com/typeobject/wheeler/core/bytecode/OpcodeIds.java"));
    String wheelerSource = Files.readString(Path.of(
        "../wheeler-compiler/src/main/wheeler/compiler/ir/Opcodes.w"))
        + Files.readString(Path.of(
            "../wheeler-compiler/src/main/wheeler/compiler/ir/StorageOpcodes.w"));
    var javaOpcodes = opcodeIdentities(JAVA_OPCODE, javaSource);
    var wheelerOpcodes = opcodeIdentities(WHEELER_OPCODE, wheelerSource);

    for (var opcode : wheelerOpcodes.entrySet()) {
      assertEquals(javaOpcodes.get(opcode.getKey()), opcode.getValue(), opcode.getKey());
    }
  }

  @Test
  void nativeScalarTypesMatchTheCanonicalRegistry() throws Exception {
    String javaSource = Files.readString(Path.of(
        "../bootstrap/core/src/main/java/com/typeobject/wheeler/core/bytecode/ValueType.java"));
    String wheelerSource = Files.readString(Path.of(
        "../wheeler-compiler/src/main/wheeler/compiler/ir/TypeCodes.w"));

    assertEquals(
        decimalIdentities(JAVA_TYPE, javaSource),
        decimalIdentities(WHEELER_TYPE, wheelerSource));
  }

  @Test
  void nativeInstructionFormsMatchTheCanonicalRegistry() throws Exception {
    String opcodeSource = Files.readString(Path.of(
        "src/main/wheeler/compiler/ir/Opcodes.w"))
        + Files.readString(Path.of(
            "src/main/wheeler/compiler/ir/StorageOpcodes.w"));
    String formSource = Files.readString(Path.of(
        "src/main/wheeler/compiler/ir/InstructionForms.w"));
    var nativeOpcodes = opcodeIdentities(WHEELER_OPCODE, opcodeSource);
    var nativeForms = nativeInstructionForms(formSource);

    assertEquals(nativeOpcodes.keySet(), nativeForms.keySet());
    for (var form : nativeForms.entrySet()) {
      assertEquals(Opcode.valueOf(form.getKey()).operandCount(), form.getValue(), form.getKey());
    }
  }

  @Test
  void nativeStatementIdentitiesHaveBoundedSingleOwners() throws Exception {
    String tokens = Files.readString(Path.of(
        "src/main/wheeler/compiler/frontend/Tokens.w"));
    String kinds = Files.readString(Path.of(
        "src/main/wheeler/compiler/ir/StatementKinds.w"));
    String loopKinds = Files.readString(Path.of(
        "src/main/wheeler/compiler/syntax/LoopKinds.w"));
    String resolved = Files.readString(Path.of(
        "src/main/wheeler/compiler/ir/ResolvedStatements.w"));

    assertEquals(java.util.Map.of(), statementIdentities(tokens));
    assertEquals(128, statementIdentities(kinds).size());
    assertEquals(6, statementIdentities(loopKinds).size());
    assertEquals(79, statementIdentities(resolved).size());
    assertEquals(213, statementIdentities(kinds + loopKinds + resolved).size());
  }

  @Test
  void maintainedCompilerSourcesPassReadabilityChecks() throws Exception {
    Path root = Path.of("../wheeler-compiler/src/main/wheeler");
    List<String> diagnostics = new ArrayList<>();
    try (var paths = Files.walk(root)) {
      for (Path source : paths.filter(path -> path.toString().endsWith(".w")).sorted().toList()) {
        check(source, Files.readString(source), diagnostics);
      }
    }

    assertEquals(List.of(), diagnostics);
  }

  private static java.util.Map<String, Integer> opcodeIdentities(
      Pattern declaration,
      String source) {
    var result = new java.util.LinkedHashMap<String, Integer>();
    var matches = declaration.matcher(source);
    while (matches.find()) {
      String name = matches.group(1);
      if (result.put(name, Integer.decode(matches.group(2))) != null) {
        throw new AssertionError("Duplicate opcode identity declaration " + name);
      }
    }
    return java.util.Map.copyOf(result);
  }

  private static java.util.Map<String, Integer> decimalIdentities(
      Pattern declaration,
      String source) {
    var result = new java.util.LinkedHashMap<String, Integer>();
    var matches = declaration.matcher(source);
    while (matches.find()) {
      if (result.put(matches.group(1), Integer.parseInt(matches.group(2))) != null) {
        throw new AssertionError("Duplicate scalar type " + matches.group(1));
      }
    }
    return java.util.Map.copyOf(result);
  }

  private static java.util.Map<String, Integer> statementIdentities(String source) {
    var result = new java.util.LinkedHashMap<String, Integer>();
    var matches = WHEELER_STATEMENT_IDENTITY.matcher(source);
    while (matches.find()) {
      String name = matches.group(1);
      if (result.put(name, Integer.parseInt(matches.group(2))) != null) {
        throw new AssertionError("Duplicate statement identity " + name);
      }
    }
    return java.util.Map.copyOf(result);
  }

  private static java.util.Map<String, Integer> nativeInstructionForms(String source) {
    var result = new java.util.LinkedHashMap<String, Integer>();
    var matches = WHEELER_FORM.matcher(source);
    while (matches.find()) {
      String name = matches.group(1);
      if (result.put(name, Integer.parseInt(matches.group(2))) != null) {
        throw new AssertionError("Duplicate native instruction form " + name);
      }
    }
    collectBooleanInstructionForm(source, result, "threeOperandStorageOpcode", 3);
    return java.util.Map.copyOf(result);
  }

  private static void collectBooleanInstructionForm(
      String source,
      java.util.Map<String, Integer> result,
      String method,
      int operandCount) {
    String dispatch = "if (" + method + "(opcode)) {\n      return " + operandCount + ";\n    }";
    if (source.contains(dispatch) == false) {
      throw new AssertionError("Missing native instruction form dispatch " + method);
    }

    int declaration = source.indexOf("private boolean " + method + "(");
    if (declaration < 0) {
      throw new AssertionError("Missing native instruction form classifier " + method);
    }
    int open = source.indexOf('{', declaration);
    int cursor = open + 1;
    int depth = 1;
    while (cursor < source.length() && depth > 0) {
      char scalar = source.charAt(cursor);
      if (scalar == '{') {
        depth++;
      } else if (scalar == '}') {
        depth--;
      }
      cursor++;
    }
    if (depth != 0) {
      throw new AssertionError("Unclosed native instruction form classifier " + method);
    }

    var matches = WHEELER_OPCODE_TEST.matcher(source.substring(open, cursor));
    while (matches.find()) {
      String name = matches.group(1);
      if (result.put(name, operandCount) != null) {
        throw new AssertionError("Duplicate native instruction form " + name);
      }
    }
  }

  private static void check(Path source, String text, List<String> diagnostics) {
    checkInstructionForms(source, text, diagnostics);

    var calls = ENDIAN_WRITE.matcher(text);
    while (calls.find()) {
      String[] arguments = calls.group(1).split(",", -1);
      if (arguments.length != 4) {
        continue;
      }
      String value = arguments[2].trim();
      String width = arguments[3].trim();
      if (!integerArgument(value) || !integerArgument(width)) {
        continue;
      }
      if (!value.matches("/\\* value= \\*/\\s*-?[0-9]+")
          || !width.matches("/\\* width= \\*/\\s*-?[0-9]+")) {
        int line = 1 + text.substring(0, calls.start()).replaceAll("[^\\n]", "").length();
        diagnostics.add(source + ":" + line
            + ": WREAD001 adjacent endian literals require value and width labels");
      }
    }
  }

  private static void checkInstructionForms(
      Path source, String text, List<String> diagnostics) {
    String callPrefix = "writeInstructionHeader(";
    int search = 0;
    while (true) {
      int start = text.indexOf(callPrefix, search);
      if (start < 0) {
        return;
      }

      int cursor = start + callPrefix.length();
      int depth = 1;
      int finalComma = -1;
      while (cursor < text.length() && depth > 0) {
        char scalar = text.charAt(cursor);
        if (scalar == '(') {
          depth++;
        } else if (scalar == ')') {
          depth--;
        } else if (scalar == ',' && depth == 1) {
          finalComma = cursor;
        }
        cursor++;
      }

      if (depth != 0 || finalComma < 0) {
        return;
      }
      String form = text.substring(finalComma + 1, cursor - 1).trim();
      if (INTEGER.matcher(form).matches()) {
        int line = 1 + text.substring(0, start).replaceAll("[^\\n]", "").length();
        diagnostics.add(source + ":" + line
            + ": WREAD002 raw instruction form requires a named constant");
      }
      search = cursor;
    }
  }

  private static boolean integerArgument(String argument) {
    if (INTEGER.matcher(argument).matches()) {
      return true;
    }
    return LABELED_INTEGER.matcher(argument).matches();
  }
}
