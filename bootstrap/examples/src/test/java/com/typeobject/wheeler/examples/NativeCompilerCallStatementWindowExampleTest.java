package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.bytecode.Program;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Complete source windows, not a call-name match, authorize ordinary call widths. */
final class NativeCompilerCallStatementWindowExampleTest {
  private static final String OWNER = "wheeler.compiler.closure.source_call_argument_products";
  private static final String CALL = "remote";

  @Test
  void acceptsOnlyCompleteCallReturnAndScalarDeclarationWindowsAndRewinds() throws Exception {
    for (String prefix : List.of("", "return ", "long result = ", "boolean result = ")) {
      int head = prefix.isEmpty() ? 0 : prefix.startsWith("return") ? 1 : 3;
      for (String qualifier : List.of("", "dep.alpha::")) {
        String statement = prefix + qualifier + "remote(/* é */ value, flag);";
        check(statement, head, 2, true);
      }
    }
  }

  @Test
  void rejectsPrefixesSuffixesAndArgumentExpressionsWithoutChangingColumns() throws Exception {
    for (String statement : List.of(
        "return ::remote(value);", "return dep.::remote(value);", "return dep alpha::remote(value);",
        "return dep:::remote(value);", "return + dep::remote(value);",
        "return remote(value) + value;", "return remote(value); extra;", "return remote(value);  ",
        "return remote(value + value);", "return remote(1);", "return remote(value,);",
        "return remote(value)", "return (remote(value));")) {
      check(statement, 1, 1, false);
    }
    check("long result = remote(value) + value;", 3, 1, false);
    check("boolean result == remote(value);", 3, 1, false);
    check("remote(value) + value;", 0, 1, false);
  }

  @Test
  void checksArityBeforeCalculatingTheLastToken() throws Exception {
    for (int arity : new int[] {0, 1, 64, 65}) {
      String arguments = IntStream.range(0, arity).mapToObj(index -> "p" + index)
          .collect(Collectors.joining(", "));
      check("return dep.alpha::remote(" + arguments + ");", 1, arity, arity <= 64);
    }
    String statement = "return remote(value);";
    String normal = invocation("count", "0", Integer.toString(bytes(statement)),
        Integer.toString(bytes(statement.substring(0, statement.indexOf(CALL)))), "6", "1", "1");
    var program = program("""
        assert(%s);
        assert(%s == false);
        assert(%s == false);
        """.formatted(normal, normal.replace(", 1, 1)", ", -1, 1)"),
            normal.replace(", 1, 1)", ", 9223372036854775807, 1)")));
    NativeSourceFrontFixture.check(program, statement, machine -> {});
  }

  @Test
  void acceptsTheLastCompleteTokenWindowAndRejectsCountedExcess() throws Exception {
    String statement = "return remote();";
    String source = ";".repeat(4091) + statement;
    String call = invocation("count", "4091", Integer.toString(bytes(statement)),
        Integer.toString(4091 + statement.indexOf(CALL)), "6", "0", "1");
    NativeSourceFrontFixture.check(program("assert(count == 4096); assert(" + call + ");\n"
        + "assert(" + call.replace("lengths, count,", "lengths, 4097,") + " == false);"),
        source, machine -> {});
  }

  @Test
  void rejectsInvalidCountsExtentsAndHeadShapesBeforeReading() throws Exception {
    String source = "return remote(value);";
    StringBuilder checks = new StringBuilder();
    for (String[] row : List.of(
        new String[] {"-1", "0", "21", "7", "6", "1", "1"},
        new String[] {"4097", "0", "21", "7", "6", "1", "1"},
        new String[] {"count", "-1", "21", "7", "6", "1", "1"},
        new String[] {"count", "9223372036854775807", "21", "7", "6", "1", "1"},
        new String[] {"count", "0", "-1", "7", "6", "1", "1"},
        new String[] {"count", "0", "9223372036854775807", "7", "6", "1", "1"},
        new String[] {"count", "0", "21", "-1", "6", "1", "1"},
        new String[] {"count", "0", "21", "9223372036854775807", "6", "1", "1"},
        new String[] {"count", "0", "21", "7", "9223372036854775807", "1", "1"},
        new String[] {"count", "0", "21", "7", "0", "1", "1"},
        new String[] {"count", "0", "21", "7", "6", "1", "2"},
        new String[] {"count", "0", "21", "7", "6", "1", "9223372036854775807"})) {
      checks.append("assert(").append(invocation(row[0], row[1], row[2], row[3], row[4], row[5], row[6]))
          .append(" == false);\n");
    }
    NativeSourceFrontFixture.check(program(checks.toString()), source, machine -> {});
  }

  @Test
  void rejectsUnconsumedRowsInsideTheStatementWindow() throws Exception {
    String source = "return remote(value) + value;";
    String call = invocation("count", "0", Integer.toString(bytes(source)), "7", "6", "1", "1");
    String body = "long oldStart = starts[5]; set(starts, 5, " + (bytes(source) - 1)
        + "); assert(" + call + " == false); set(starts, 5, oldStart);";
    NativeSourceFrontFixture.check(program(body), source, machine -> {});
  }

  @Test
  void rejectsEachShortColumnAndMalformedRetainedCoordinate() throws Exception {
    String call = invocation("count", "0", "21", "7", "6", "1", "1");
    String body = """
        region shortArena = new region(/* bytes= */ 32760, /* allocations= */ 1);
        words shortColumn = allocate(shortArena, 4095);
        assert(%s == false);
        assert(%s == false);
        assert(%s == false);
        drop(shortColumn);
        drop(shortArena);
        assert(%s);
        long oldStart = starts[2];
        set(starts, 2, -1);
        assert(%s == false);
        set(starts, 2, oldStart);
        long oldLength = lengths[2];
        set(lengths, 2, 2);
        assert(%s == false);
        set(lengths, 2, oldLength);
        oldStart = starts[3];
        oldLength = lengths[3];
        set(starts, 3, 7);
        set(lengths, 3, 6);
        assert(%s == false);
        set(starts, 3, oldStart);
        set(lengths, 3, oldLength);
        assert(%s);
        """.formatted(call.replace("source, kinds,", "source, shortColumn,"),
            call.replace("kinds, starts,", "kinds, shortColumn,"),
            call.replace("starts, lengths,", "starts, shortColumn,"), call, call, call, call, call);
    NativeSourceFrontFixture.check(program(body), "return remote(value);", machine -> {});
  }

  @Test
  void preservesAllValueAndFrameProductsWhenAReturnWindowRejects() throws Exception {
    String source = "classical class Calls { public long recurse(long number) { "
        + "return recurse(number) + number; } }";
    int bodyStart = source.indexOf('{', source.indexOf("recurse("));
    int bodyLength = source.indexOf('}', bodyStart) - bodyStart + 1;
    String body = """
        region products = new region(/* bytes= */ 395776, /* allocations= */ 8);
        words bodies = allocate(products, 4096);
        words bodyLengths = allocate(products, 4096);
        words statements = allocate(products, 24576);
        words calls = allocate(products, 1024);
        words callStatements = allocate(products, 256);
        words values = allocate(products, 7168);
        words functionLocals = allocate(products, 64);
        words statementLocals = allocate(products, 8192);
        set(bodies, 0, %d);
        set(bodyLengths, 0, %d);
        SourceStatementProductPlan statementsPlan = materializeSourceStatementProducts(
          source, 0, 0, 1, bodies, bodyLengths, statements
        );
        assert(statementsPlan.valid);
        assert(statementsPlan.statementCount == 1);
        set(calls, 0, %d);
        set(calls, 256, 7);
        set(calls, 512, 1);
        long cell = 0;
        while (cell < 8192) limit 8192 {
          set(statementLocals, cell, -7);
          if (cell < 7168) { set(values, cell, -9); }
          if (cell < 64) { set(functionLocals, cell, -11); }
          cell += 1;
        }
        SourceValueProductPlan valuesPlan = materializeSourceValueProductsWithCalls(
          source, 0, 0, 1, 0, bodies, 1, statements, 16384, 20480,
          1, calls, callStatements, values, functionLocals, statementLocals
        );
        assert(valuesPlan.valid == false);
        cell = 0;
        while (cell < 8192) limit 8192 {
          assert(statementLocals[cell] == -7);
          if (cell < 7168) { assert(values[cell] == -9); }
          if (cell < 64) { assert(functionLocals[cell] == -11); }
          cell += 1;
        }
        drop(statementLocals);
        drop(functionLocals);
        drop(values);
        drop(callStatements);
        drop(calls);
        drop(statements);
        drop(bodyLengths);
        drop(bodies);
        drop(products);
        """.formatted(bodyStart, bodyLength, source.lastIndexOf("recurse"));
    Program program = NativeSourceFrontFixture.program(List.of(OWNER,
        "wheeler.compiler.closure.source_statement_products",
        "wheeler.compiler.closure.source_value_products"), 4096, "", body);
    NativeSourceFrontFixture.check(program, source, machine -> {});
  }

  private static void check(String statement, int head, int arity, boolean valid) throws Exception {
    String source = "/* é */ ; " + statement + "\n;";
    int start = bytes("/* é */ ; ");
    int name = bytes(source.substring(0, source.indexOf(CALL)));
    String call = invocation("count", "1", Integer.toString(bytes(statement)),
        Integer.toString(name), "6", Integer.toString(arity), Integer.toString(head));
    NativeSourceFrontFixture.check(program("assert(starts[1] == " + start + ");\nassert(" + call
        + " == " + valid + ");"), source, machine -> assertEquals(7, machine.snapshot().buffers().size()));
  }

  private static Program program(String body) throws Exception {
    return NativeSourceFrontFixture.program(List.of(OWNER), 4096, "", body);
  }

  private static String invocation(String count, String first, String length, String name,
      String nameLength, String arity, String head) {
    return "sourceCallStatementValid(source, kinds, starts, lengths, " + count + ", " + first
        + ", " + length + ", " + name + ", " + nameLength + ", " + arity + ", " + head + ")";
  }

  private static int bytes(String value) {
    return value.getBytes(StandardCharsets.UTF_8).length;
  }
}
