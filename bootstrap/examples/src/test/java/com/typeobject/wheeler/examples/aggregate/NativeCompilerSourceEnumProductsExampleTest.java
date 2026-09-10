package com.typeobject.wheeler.examples.aggregate;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerMachineRunner;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Enum declarations must enter aggregate products as canonically ordered empty-payload variants. */
final class NativeCompilerSourceEnumProductsExampleTest {
  private static final int MAX_AGGREGATES = 64;
  private static final int MAX_CASES = 128;
  private static final int MAX_MEMBERS = 256;
  private static final int AGGREGATE_COLUMNS = 13;
  private static final int CASE_COLUMNS = 5;
  private static final int MEMBER_COLUMNS = 8;
  private static final int AGGREGATE_ROWS = MAX_AGGREGATES * AGGREGATE_COLUMNS;
  private static final int CASE_ROWS = MAX_CASES * CASE_COLUMNS;
  private static final int MEMBER_ROWS = MAX_MEMBERS * MEMBER_COLUMNS;
  private static final int OUTPUT_BYTES = (AGGREGATE_ROWS + CASE_ROWS + MEMBER_ROWS) * Long.BYTES;
  private static final long VARIANT_KIND = 4;
  private static final long SENTINEL = 211;
  private static Program compiled;

  @Test
  void publishesEnumCasesInStageZeroOrderWithoutSortingOrdinaryVariants() throws Exception {
    String source = """
        classical class Enums {
          public enum flag {
            case Zebra;
            // café 𝄞
            case Alpha;
            case Alpine;
          }
          private variant Choice { case Zebra(); case Alpha(); }
          entry void main() {}
        }
        """;
    Program reference = new WheelerCompiler().compile(source);
    assertEquals(List.of("Alpha", "Alpine", "Zebra"), reference.variantTypes().stream()
        .filter(type -> type.name().equals("flag")).findFirst().orElseThrow()
        .cases().stream().map(row -> row.name()).toList());
    assertEquals(List.of("Zebra", "Alpha"), reference.variantTypes().stream()
        .filter(type -> type.name().equals("Choice")).findFirst().orElseThrow()
        .cases().stream().map(row -> row.name()).toList());
    long[] aggregates = blank(AGGREGATE_ROWS, MAX_AGGREGATES, AGGREGATE_COLUMNS, 2);
    long[] cases = blank(CASE_ROWS, MAX_CASES, CASE_COLUMNS, 5);
    long[] members = blank(MEMBER_ROWS, MAX_MEMBERS, MEMBER_COLUMNS, 0);
    aggregate(aggregates, source, 0, "public enum flag", "flag", 0, 3, 1);
    aggregate(aggregates, source, 1, "private variant Choice", "Choice", 3, 2, 0);
    List<String> enumNames = reference.variantTypes().stream()
        .filter(type -> type.name().equals("flag")).findFirst().orElseThrow()
        .cases().stream().map(row -> row.name()).toList();
    for (int row = 0; row < enumNames.size(); row++) {
      caseRow(cases, source, row, 0, source.indexOf("case " + enumNames.get(row)) + "case ".length(),
          enumNames.get(row).length());
    }
    int variantStart = source.indexOf("variant Choice");
    caseRow(cases, source, 3, 1, source.indexOf("case Zebra", variantStart) + "case ".length(), 5);
    caseRow(cases, source, 4, 1, source.indexOf("case Alpha", variantStart) + "case ".length(), 5);
    assertProduct(source, 2, 5, 0, encode(aggregates, cases, members), true);
  }

  @Test
  void resolvesAForwardEnumFieldWithoutInventingPayloadMembers() throws Exception {
    String source = """
        module example.references;
        classical class References {
          record Box(flag value) {}
          enum flag { case Ready; }
          entry void main() {}
        }
        """;
    Program reference = new WheelerCompiler().compileModuleFiles(
        Map.of("References.w", source), "example.references");
    assertEquals(ValueType.variant(0), reference.recordTypes().getFirst().fields().getFirst().type());
    long[] aggregates = blank(AGGREGATE_ROWS, MAX_AGGREGATES, AGGREGATE_COLUMNS, 2);
    long[] cases = blank(CASE_ROWS, MAX_CASES, CASE_COLUMNS, 1);
    long[] members = blank(MEMBER_ROWS, MAX_MEMBERS, MEMBER_COLUMNS, 1);
    aggregate(aggregates, source, 0, "record Box", "Box", 0, 0, 0);
    aggregates[0] = 1;
    aggregates[6 * MAX_AGGREGATES] = 1;
    aggregate(aggregates, source, 1, "enum flag", "flag", 0, 1, 0);
    aggregates[5 * MAX_AGGREGATES + 1] = 1;
    caseRow(cases, source, 0, 1, source.indexOf("case Ready") + "case ".length(), "Ready".length());
    cases[3 * MAX_CASES] = 1;
    long[] member = {0, -1, source.indexOf("value"), "value".length(),
        source.indexOf("flag value"), "flag".length(), 1, 1};
    for (int column = 0; column < member.length; column++) {
      members[column * MAX_MEMBERS] = member[column];
    }
    assertProduct(source, 2, 1, 1, encode(aggregates, cases, members), true);
  }

  @Test
  void admitsTheCaseCeilingAndRejectsItsFirstExcessWithoutPublishingRows() throws Exception {
    for (String kind : List.of("enum", "variant")) {
      String source = cases(kind, MAX_CASES);
      new WheelerCompiler().compile(source);
      long[] aggregates = blank(AGGREGATE_ROWS, MAX_AGGREGATES, AGGREGATE_COLUMNS, 1);
      long[] caseRows = blank(CASE_ROWS, MAX_CASES, CASE_COLUMNS, MAX_CASES);
      long[] members = blank(MEMBER_ROWS, MAX_MEMBERS, MEMBER_COLUMNS, 0);
      aggregate(aggregates, source, 0, kind + " Flags", "Flags", 0, MAX_CASES, 0);
      for (int row = 0; row < MAX_CASES; row++) {
        String name = String.format(java.util.Locale.ROOT, "Case%03d", row);
        caseRow(caseRows, source, row, 0, source.indexOf("case " + name) + "case ".length(),
            name.length());
      }
      assertProduct(source, 1, MAX_CASES, 0, encode(aggregates, caseRows, members), false);
      String excess = cases(kind, MAX_CASES + 1);
      // Stage 0 has a wider case profile. Native rejection is a local product bound.
      new WheelerCompiler().compile(excess);
      assertRejected(excess, false);
    }
  }

  @Test
  void admitsEveryAggregateRowAndRejectsTheFirstExcessEnum() throws Exception {
    for (int count : new int[] {MAX_AGGREGATES, MAX_AGGREGATES + 1}) {
      StringBuilder declarations = new StringBuilder("classical class Enums { ");
      for (int row = 0; row < count; row++) {
        declarations.append("enum Flag").append(row).append(" { case Ready; } ");
      }
      String source = declarations.append("entry void main() {} }").toString();
      new WheelerCompiler().compile(source);
      if (count > MAX_AGGREGATES) {
        assertRejected(source, false);
        continue;
      }
      long[] aggregates = blank(AGGREGATE_ROWS, MAX_AGGREGATES, AGGREGATE_COLUMNS, count);
      long[] cases = blank(CASE_ROWS, MAX_CASES, CASE_COLUMNS, count);
      long[] members = blank(MEMBER_ROWS, MAX_MEMBERS, MEMBER_COLUMNS, 0);
      for (int row = 0; row < count; row++) {
        String name = "Flag" + row;
        String declaration = "enum " + name + " {";
        aggregate(aggregates, source, row, declaration, name, row, 1, 0);
        int start = source.indexOf("case Ready", source.indexOf(declaration)) + "case ".length();
        caseRow(cases, source, row, row, start, "Ready".length());
      }
      assertProduct(source, count, count, 0, encode(aggregates, cases, members), false);
    }
  }

  @Test
  void boundsCopiedEnumAndCaseNamesAtTheLastAdmittedByte() throws Exception {
    int maximumNameBytes = 256;
    String name = "A".repeat(maximumNameBytes);
    String lastByte = "A".repeat(maximumNameBytes - 1) + "B";
    String source = "classical class Names { enum " + name + " { case " + lastByte
        + "; case " + name + "; } entry void main() {} }";
    new WheelerCompiler().compile(source);
    long[] aggregates = blank(AGGREGATE_ROWS, MAX_AGGREGATES, AGGREGATE_COLUMNS, 1);
    long[] cases = blank(CASE_ROWS, MAX_CASES, CASE_COLUMNS, 2);
    long[] members = blank(MEMBER_ROWS, MAX_MEMBERS, MEMBER_COLUMNS, 0);
    aggregate(aggregates, source, 0, "enum " + name, name, 0, 2, 0);
    caseRow(cases, source, 0, 0, source.indexOf("case " + name) + "case ".length(), name.length());
    caseRow(cases, source, 1, 0, source.indexOf("case " + lastByte) + "case ".length(), lastByte.length());
    assertProduct(source, 1, 2, 0, encode(aggregates, cases, members), true);
    for (String keyword : List.of("enum", "case")) {
      String excess = source.replace(keyword + " " + name, keyword + " " + name + "A");
      new WheelerCompiler().compile(excess);
      assertRejected(excess, true);
    }
  }

  @Test
  void rejectsMalformedEnumAndEmptyVariantDeclarationsAndRewinds() throws Exception {
    for (String declaration : List.of(
        "enum Flags {}", "variant Flags {}", "enum Flags { case Same; case Same; }",
        "enum Flags { case Value(); }", "enum Flags { case Value(long value); }",
        "enum Flags { case Value }", "enum Flags { Value; }",
        "enum Flags { case One; } variant Flags { case Two(); }")) {
      String source = "classical class Rejected { " + declaration + " entry void main() {} }";
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compile(source), declaration);
      assertRejected(source, true);
    }
  }

  private static void assertProduct(
      String source, int aggregates, int cases, int members, byte[] expected, boolean rewind)
      throws Exception {
    VirtualMachine machine = machine(source);
    var initial = machine.snapshot();
    run(machine, rewind);
    assertEquals(1, machine.global("valid"));
    assertEquals(aggregates, machine.global("aggregateCount"));
    assertEquals(cases, machine.global("caseCount"));
    assertEquals(members, machine.global("memberCount"));
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(initial.buffers().getFirst(), machine.snapshot().buffers().getFirst());
    if (rewind) {
      var terminal = machine.snapshot();
      rewind(machine);
      assertEquals(initial, machine.snapshot());
      machine.run();
      assertEquals(terminal, machine.snapshot());
    }
  }

  private static void assertRejected(String source, boolean rewind) throws Exception {
    VirtualMachine machine = machine(source);
    var initial = machine.snapshot();
    run(machine, rewind);
    assertEquals(0, machine.global("valid"));
    assertArrayEquals(encode(blank(AGGREGATE_ROWS, MAX_AGGREGATES, AGGREGATE_COLUMNS, 0),
        blank(CASE_ROWS, MAX_CASES, CASE_COLUMNS, 0),
        blank(MEMBER_ROWS, MAX_MEMBERS, MEMBER_COLUMNS, 0)), machine.hostOutput());
    assertEquals(initial.buffers().getFirst(), machine.snapshot().buffers().getFirst());
    if (rewind) {
      var terminal = machine.snapshot();
      rewind(machine);
      assertEquals(initial, machine.snapshot());
      machine.run();
      assertEquals(terminal, machine.snapshot());
    }
  }

  private static void run(VirtualMachine machine, boolean history) {
    if (history) {
      machine.run();
    } else {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    }
  }

  private static void rewind(VirtualMachine machine) {
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
  }

  private static String cases(String kind, int count) {
    StringBuilder source = new StringBuilder("classical class Boundary { " + kind + " Flags { ");
    for (int row = 0; row < count; row++) {
      int sourceOrdinal = kind.equals("enum") ? count - row - 1 : row;
      source.append(String.format(java.util.Locale.ROOT, "case Case%03d", sourceOrdinal));
      source.append(kind.equals("enum") ? "; " : "(); ");
    }
    return source.append("} entry void main() {} }").toString();
  }

  private static long[] blank(int rows, int stride, int columns, int count) {
    long[] result = new long[rows];
    Arrays.fill(result, SENTINEL);
    for (int column = 0; column < columns; column++) {
      Arrays.fill(result, column * stride, column * stride + count, 0);
    }
    return result;
  }

  private static void aggregate(long[] rows, String source, int row,
      String declaration, String name, int firstCase, int caseCount, int visibility) {
    int start = source.indexOf(declaration);
    int end = source.indexOf('}', start) + 1;
    long[] values = {VARIANT_KIND, byteOffset(source, source.indexOf(name, start)), name.length(),
        firstCase, caseCount, 0, 0, visibility, byteOffset(source, start), 0, 0, 0,
        byteOffset(source, end)};
    for (int column = 0; column < values.length; column++) {
      rows[column * MAX_AGGREGATES + row] = values[column];
    }
  }

  private static void caseRow(
      long[] rows, String source, int row, int owner, int characterStart, int length) {
    assertEquals("case ", source.substring(characterStart - "case ".length(), characterStart));
    rows[row] = owner;
    rows[MAX_CASES + row] = byteOffset(source, characterStart);
    rows[2 * MAX_CASES + row] = length;
  }

  private static int byteOffset(String source, int characterOffset) {
    return source.substring(0, characterOffset).getBytes(StandardCharsets.UTF_8).length;
  }

  private static byte[] encode(long[] aggregates, long[] cases, long[] members) {
    ByteBuffer output = ByteBuffer.allocate(OUTPUT_BYTES).order(ByteOrder.LITTLE_ENDIAN);
    for (long[] table : List.of(aggregates, cases, members)) {
      for (long cell : table) {
        output.putLong(cell);
      }
    }
    return output.array();
  }

  private static VirtualMachine machine(String source) throws Exception {
    if (compiled == null) {
      var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
          "wheeler.compiler.closure.source_aggregate_products"));
      sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.encoding"));
      sources.put("EnumProducts.w", driver());
      compiled = new WheelerCompiler().compileModuleFiles(sources, "example.enum_products");
    }
    return new VirtualMachine(compiled, source.getBytes(StandardCharsets.UTF_8), OUTPUT_BYTES);
  }

  private static String driver() {
    return """
        module example.enum_products;
        import wheeler.compiler.closure.source_aggregate_products;
        import wheeler.compiler.encoding;
        classical class EnumProducts {
          private const long AGGREGATE_ROWS = 64 * 13;
          private const long CASE_ROWS = 128 * 5;
          private const long MEMBER_ROWS = 256 * 8;
          private const long WORD_BYTES = 8;
          private const long TOTAL_ROWS = AGGREGATE_ROWS + CASE_ROWS + MEMBER_ROWS;
          private const long TABLE_BYTES = TOTAL_ROWS * WORD_BYTES;
          private const long TABLE_COUNT = 3;
          private const long SENTINEL = 211;
          state long valid = 0;
          state long aggregateCount = 0;
          state long caseCount = 0;
          state long memberCount = 0;
          private void fill(borrow mut words rows) {
            long row = 0;
            while (row < bufferLength(rows)) limit TOTAL_ROWS {
              set(rows, row, SENTINEL);
              row += 1;
            }
          }
          private long emit(borrow mut words rows, borrow mut bytes output, long start) {
            long row = 0;
            long cursor = start;
            while (row < bufferLength(rows)) limit TOTAL_ROWS {
              cursor = writeSignedLittleEndian(output, cursor, rows[row], WORD_BYTES);
              row += 1;
            }
            return cursor;
          }
          entry void main(borrow utf8 source, borrow mut bytes output) {
            region tables = new region(TABLE_BYTES, TABLE_COUNT);
            words aggregates = allocate(tables, AGGREGATE_ROWS);
            words cases = allocate(tables, CASE_ROWS);
            words members = allocate(tables, MEMBER_ROWS);
            fill(aggregates); fill(cases); fill(members);
            SourceAggregateProductPlan plan = materializeSourceAggregateProducts(
              source, aggregates, cases, members);
            if (plan.valid) { valid = 1; }
            aggregateCount = plan.aggregateCount;
            caseCount = plan.caseCount;
            memberCount = plan.memberCount;
            long cursor = emit(aggregates, output, 0);
            cursor = emit(cases, output, cursor);
            cursor = emit(members, output, cursor);
            setOutputLength(output, cursor);
            drop(members); drop(cases); drop(aggregates); drop(tables);
          }
        }
        """;
  }
}
