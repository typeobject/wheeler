package com.typeobject.wheeler.examples.constants;

import static com.typeobject.wheeler.examples.constants.ScopedConstantFixture.*;
import static org.junit.jupiter.api.Assertions.*;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerMachineRunner;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Checks complete scalar detachment, qualified lookup, and atomic rejection. */
final class NativeScopedConstantProductsExampleTest {
  private static final int CALLER_BUFFERS = 8;
  private static final int NAME_BUFFER = 2;
  private static final int PRODUCT_BUFFER = 4;

  @ParameterizedTest
  @MethodSource("expressions")
  void evaluatesQualifiedProductsAfterDetachment(String expression, long valid, long value)
      throws Exception {
    if (valid == 0) {
      assertThrows(CompilerException.class, () -> oracle(expression));
    } else {
      var oracle = new VirtualMachine(oracle(expression));
      oracle.run();
      assertEquals(value, oracle.global("observed"));
    }
    check(fixture(ordinary("", expression)), true, valid, value);
  }

  static Stream<Arguments> expressions() {
    return Stream.of(
        Arguments.of("pkg.left::BOUND + 1", 1L, 8L),
        Arguments.of("pkg.right::BOUND + 1", 1L, 12L),
        Arguments.of("pkg.left::BOUND + pkg.right::BOUND", 1L, 18L),
        Arguments.of("BOUND", 0L, 0L),
        Arguments.of("pkg.missing::BOUND", 0L, 0L));
  }

  @ParameterizedTest
  @ValueSource(strings = {"", "set(raw, 0, 0);"})
  void publishesAnEmptyCountWithoutWritingNamesOrTableTails(String mutation) throws Exception {
    var input = new Input(new byte[0], new byte[0], List.of(), TAIL, 2 * TAIL,
        HEADER + TAIL, mutation, "", 1);
    check(fixture(input), true, 0, 0);
  }

  @ParameterizedTest
  @ValueSource(longs = {Long.MIN_VALUE, Long.MAX_VALUE})
  void retainsBothSignedExtremes(long value) throws Exception {
    var input = new Input(new byte[] {'N'}, new byte[0],
        List.of(new Product(0, 1, 1, value, 1, 0, 0)), TAIL, 2 * TAIL + 1,
        HEADER + COLUMNS + TAIL, "", "N", 1);
    check(fixture(input), true, 1, value);
  }

  @Test
  void retainsBooleanAndUnresolvedProductsWithoutResolvingThem() throws Exception {
    check(fixture(new Input(new byte[] {'N'}, new byte[0],
        List.of(new Product(0, 1, 2, 1, 1, 0, 0)), 0, 1,
        HEADER + COLUMNS, "", "N", 1)), true, 1, 1);
    check(fixture(new Input(new byte[] {'N'}, new byte[0],
        List.of(new Product(0, 1, 1, Long.MIN_VALUE, 0, 0, 0)), 0, 1,
        HEADER + COLUMNS, "", "N", 1)), true, 0, 0);
  }

  @Test
  void admitsMaximumWidthNamesAndAnExactOutputExtent() throws Exception {
    byte[] name = "N".repeat(MAX_NAME).getBytes(StandardCharsets.US_ASCII);
    var input = new Input(name, name, List.of(new Product(0, MAX_NAME, 1, 7, 1, 0, MAX_NAME)),
        TAIL, TAIL + MAX_NAME * 2, HEADER + COLUMNS, "", "", 1);
    check(fixture(input), true, 0, 0);
  }

  @Test
  void admitsTheTerminalProductCountWithoutRetainingHistory() throws Exception {
    var input = new Input(new byte[] {'N'}, new byte[0],
        List.of(new Product(0, 1, 1, 7, 1, 0, 0)), TAIL, MAX_PRODUCTS + TAIL,
        HEADER + MAX_PRODUCTS * COLUMNS, "", "", MAX_PRODUCTS);
    check(fixture(input), false, 0, 0);
  }

  @ParameterizedTest
  @ValueSource(ints = {0, 1})
  void enforcesTheAggregateNameByteBudgetWithoutRetainingHistory(int prefix) throws Exception {
    byte[] name = "N".repeat(MAX_NAME).getBytes(StandardCharsets.US_ASCII);
    int copies = MAX_NAMES / (MAX_NAME * 2);
    var input = new Input(name, name,
        List.of(new Product(0, MAX_NAME, 1, 7, 1, 0, MAX_NAME)), prefix, MAX_NAMES,
        HEADER + copies * COLUMNS, "", "", copies);
    if (prefix == 0) check(fixture(input), false, 0, 0);
    else reject(fixture(input), false);
  }

  @Test
  void rejectsTheFirstExcessNameWithCompleteSourceAndOutputWindows() throws Exception {
    byte[] name = "N".repeat(MAX_NAME + 1).getBytes(StandardCharsets.US_ASCII);
    reject(fixture(new Input(name, new byte[0],
        List.of(new Product(0, name.length, 1, 7, 1, 0, 0)), 0, name.length,
        HEADER + COLUMNS, "", "", 1)), true);
    reject(fixture(new Input(new byte[] {'N'}, name,
        List.of(new Product(0, 1, 1, 7, 1, 0, name.length)), 0, name.length + 1,
        HEADER + COLUMNS, "", "", 1)), true);
  }

  @Test
  void doesNotHideDuplicateQualifiedProductsFromTheLookupOwner() throws Exception {
    byte[] qualifier = "pkg.left".getBytes(StandardCharsets.US_ASCII);
    check(fixture(new Input(new byte[] {'N'}, qualifier,
        List.of(new Product(0, 1, 1, 7, 1, 0, qualifier.length)), 0,
        2 * (1 + qualifier.length), HEADER + 2 * COLUMNS, "", "pkg.left::N", 2)), true, 0, 0);
  }

  @ParameterizedTest
  @MethodSource("rejections")
  void rejectsBeforeChangingAnyCallerProduct(String mutation) throws Exception {
    reject(fixture(ordinary(mutation, "")), true);
  }

  static Stream<String> rejections() {
    String second = "CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_PRODUCT_COLUMNS";
    return Stream.of(
        "requested = -1;", "requested = MAX_CONSTANT_PRODUCTS + 1;",
        "requested = 9223372036854775807;", "set(raw, 0, 1);",
        "outputStart = -1;", "outputStart = NAME_BYTES + 1;",
        "outputStart = 9223372036854775807;", "outputStart = NAME_BYTES;",
        "set(raw, " + second + " + CONSTANT_NAME_START, -1);",
        "set(raw, " + second + " + CONSTANT_NAME_START, 9223372036854775807);",
        "set(raw, " + second + " + CONSTANT_NAME_LENGTH, -1);",
        "set(raw, " + second + " + CONSTANT_NAME_LENGTH, 0);",
        "set(raw, " + second + " + CONSTANT_NAME_LENGTH, MAX_CONSTANT_NAME_BYTES + 1);",
        "set(raw, " + second + " + CONSTANT_MODULE_START, -1);",
        "set(raw, " + second + " + CONSTANT_MODULE_START, 9223372036854775807);",
        "set(raw, " + second + " + CONSTANT_MODULE_LENGTH, -1);",
        "set(raw, " + second + " + CONSTANT_MODULE_LENGTH, MAX_CONSTANT_NAME_BYTES + 1);",
        "set(raw, " + second + " + CONSTANT_TYPE, 0);",
        "set(raw, " + second + " + CONSTANT_TYPE, 3);",
        "set(raw, " + second + " + CONSTANT_RESOLVED, -1);",
        "set(raw, " + second + " + CONSTANT_RESOLVED, 2);",
        "set(raw, " + second + " + CONSTANT_TYPE, CONSTANT_BOOLEAN);",
        "setByte(spellings, raw[" + second + "], 0);",
        "setByte(spellings, raw[" + second + "], 48);",
        "setByte(spellings, raw[" + second + "], 128);",
        "setByte(qualifiers, raw[" + second + " + CONSTANT_MODULE_START], 46);");
  }

  @Test
  void rejectsShortMetadataAndANameExtentMissingItsLastByte() throws Exception {
    Input input = ordinary("", "");
    reject(fixture(new Input(input.spellings(), input.qualifiers(), input.products(), input.prefix(),
        input.nameCapacity(), HEADER + 2 * COLUMNS - 1, "", "", 1)), true);
    reject(fixture(new Input(input.spellings(), input.qualifiers(), input.products(), input.prefix(),
        input.nameCapacity(), HEADER + 3 * COLUMNS,
        "requested = PRODUCT_COUNT + 1; set(raw, 0, requested);", "", 1)), true);
    int copied = copiedBytes(input);
    reject(fixture(new Input(input.spellings(), input.qualifiers(), input.products(), input.prefix(),
        input.prefix() + copied - 1, input.rowCapacity(), "", "", 1)), true);
  }

  private static void check(Fixture fixture, boolean history, long valid, long value) {
    VirtualMachine machine = fixture.machine();
    MachineSnapshot initial = machine.snapshot();
    until(machine, "prepared", history);
    MachineSnapshot prepared = machine.snapshot();
    until(machine, "published", history);
    MachineSnapshot published = machine.snapshot();
    assertEquals(prepared.regions(), published.regions(), "copier allocated or changed caller regions");
    assertEquals(prepared.buffers().size(), published.buffers().size(), "copier allocated buffers");
    int base = prepared.buffers().size() - CALLER_BUFFERS;
    for (int index = 0; index < prepared.buffers().size(); index++) {
      if (index != base + NAME_BUFFER && index != base + PRODUCT_BUFFER) {
        assertEquals(prepared.buffers().get(index), published.buffers().get(index), "input " + index);
      }
    }
    compareProducts(fixture.input(), published, base);
    assertEquals(fixture.input().count(), machine.global("productCount"));
    assertEquals(copiedBytes(fixture.input()), machine.global("nameBytes"));
    until(machine, "completed", history);
    assertEquals(valid, machine.global("valid"));
    if (valid != 0) assertEquals(value, machine.global("value"));
    compareProducts(fixture.input(), machine.snapshot(), base);
    if (history) machine.run();
    else CompilerMachineRunner.runWithoutRewindHistory(machine);
    MachineSnapshot completed = machine.snapshot();
    assertEquals(initial.buffers(), completed.buffers().subList(0, initial.buffers().size()));
    assertEquals(initial.regions(), completed.regions().subList(0, initial.regions().size()));
    assertTrue(completed.buffers().subList(initial.buffers().size(), completed.buffers().size())
        .stream().allMatch(buffer -> buffer.dropped()));
    assertTrue(completed.regions().subList(initial.regions().size(), completed.regions().size())
        .stream().allMatch(region -> region.dropped()));
    if (history) {
      rewind(machine, initial);
      machine.run();
      assertEquals(completed, machine.snapshot());
      rewind(machine, initial);
    } else assertEquals(0, machine.historySize());
  }

  private static void compareProducts(Input input, MachineSnapshot snapshot, int base) {
    long[] names = new long[input.nameCapacity()];
    long[] rows = new long[input.rowCapacity()];
    Arrays.fill(names, SENTINEL);
    Arrays.fill(rows, SENTINEL);
    rows[0] = input.count();
    int cursor = input.prefix();
    int index = 0;
    for (int repeat = 0; repeat < input.repeat(); repeat++) {
      for (Product product : input.products()) {
        int row = HEADER + index++ * COLUMNS;
        long[] cells = product.cells();
        System.arraycopy(cells, 0, rows, row, COLUMNS);
        rows[row] = cursor;
        for (int offset = 0; offset < product.length(); offset++) {
          names[cursor++] = Byte.toUnsignedInt(input.spellings()[(int) product.start() + offset]);
        }
        rows[row + QUALIFIER_START] = cursor;
        for (int offset = 0; offset < product.qualifierLength(); offset++) {
          names[cursor++] = Byte.toUnsignedInt(input.qualifiers()[(int) product.qualifierStart() + offset]);
        }
      }
    }
    assertArrayEquals(names, snapshot.buffers().get(base + NAME_BUFFER).elements().stream()
        .mapToLong(Long::longValue).toArray());
    assertArrayEquals(rows, snapshot.buffers().get(base + PRODUCT_BUFFER).elements().stream()
        .mapToLong(Long::longValue).toArray());
  }

  private static void reject(Fixture fixture, boolean history) {
    VirtualMachine machine = fixture.machine();
    MachineSnapshot initial = machine.snapshot();
    until(machine, "prepared", history);
    MachineSnapshot prepared = machine.snapshot();
    if (history) assertThrows(VmTrap.class, machine::run);
    else assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    MachineSnapshot rejected = machine.snapshot();
    assertEquals(0, machine.global("published"));
    assertEquals(-1, machine.global("productCount"));
    assertEquals(-1, machine.global("nameBytes"));
    assertEquals(prepared.buffers(), rejected.buffers());
    assertEquals(prepared.regions(), rejected.regions());
    if (history) {
      rewind(machine, initial);
      assertThrows(VmTrap.class, machine::run);
      assertEquals(rejected, machine.snapshot());
      rewind(machine, initial);
    } else assertEquals(0, machine.historySize());
  }

  private static int copiedBytes(Input input) {
    return input.repeat() * input.products().stream()
        .mapToInt(product -> (int) (product.length() + product.qualifierLength())).sum();
  }

  private static com.typeobject.wheeler.core.bytecode.Program oracle(String expression) {
    return new WheelerCompiler().compileModuleFiles(Map.of(
        "Left.w", "module pkg.left; classical class Left { public const long BOUND = 7; }",
        "Right.w", "module pkg.right; classical class Right { public const long BOUND = 11; }",
        "Oracle.w", """
            module fixture.scope;
            import pkg.left;
            import pkg.right;
            classical class Oracle {
              const long EXPECTED = %s;
              state long observed = 0;
              entry void main() { observed = EXPECTED; }
            }
            """.formatted(expression)), "fixture.scope");
  }

  private static void until(VirtualMachine machine, String global, boolean history) {
    while (machine.global(global) == 0) {
      if (history) machine.step();
      else machine.stepWithoutRewindHistory();
    }
  }

  private static void rewind(VirtualMachine machine, MachineSnapshot expected) {
    while (machine.historySize() != 0) machine.rewindOne();
    assertEquals(expected, machine.snapshot());
  }
}
