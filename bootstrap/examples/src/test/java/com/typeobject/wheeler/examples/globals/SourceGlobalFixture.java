package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Runs the native state binder and compares every caller cell with a separate source oracle. */
final class SourceGlobalFixture {
  static final int GLOBALS = 8;
  static final int COLUMNS = 3;
  static final int NAME_WIDTH = 256;
  static final int TOKENS = 4096;
  static final int PREFIX = 2;
  static final int TAIL = 3;
  static final int MODULE_RANGE_WORDS = 2;
  static final int FRONT_COLUMNS = 2;
  static final int FRONT_ROWS = MODULE_RANGE_WORDS + GLOBALS * FRONT_COLUMNS;
  static final int MODULE_WORDS = FRONT_ROWS + TAIL;
  static final int CONSTANT_COUNT = 2;
  static final int CONSTANT_COLUMNS = 7;
  static final int CONSTANT_WORDS = 1 + CONSTANT_COUNT * CONSTANT_COLUMNS;
  private static final String CONSTANT_TEXT = "LIMITexample.valuesLOCALexample.globals";
  static final int CONSTANT_NAME_BYTES = CONSTANT_TEXT.getBytes(StandardCharsets.UTF_8).length + TAIL;
  static final int NAME_BYTES = PREFIX + GLOBALS * NAME_WIDTH + TAIL;
  static final int PRODUCT_WORDS = PREFIX + GLOBALS * COLUMNS + TAIL;
  static final int CALLER_BUFFERS = 8;
  static final int CALLER_BYTES = (TOKENS * 3 + MODULE_WORDS + CONSTANT_WORDS + PRODUCT_WORDS)
      * Long.BYTES + NAME_BYTES + CONSTANT_NAME_BYTES;
  static final long SENTINEL = 211;
  private static Program driver;

  private SourceGlobalFixture() {}

  static String source(String members) {
    return "module example.globals; import example.values; classical class Globals {\n"
        + "const long LOCAL = 9;\n" + members + "\n}\n";
  }

  static List<Global> oracle(String source) {
    return new WheelerCompiler().compileLibraryModuleFiles(Map.of("Globals.w", source,
        "Values.w", "module example.values; classical class Values { public const long LIMIT = 3; }"),
        "example.globals").globals();
  }

  static VirtualMachine machine(String source) throws Exception {
    return new VirtualMachine(program(), source.getBytes(StandardCharsets.UTF_8));
  }

  static void prepare(VirtualMachine machine) {
    long steps = 0;
    while (machine.global("prepared") == 0 && steps < driver.maxSteps()) {
      machine.step();
      steps++;
    }
    assertEquals(1, machine.global("prepared"));
  }

  static void run(VirtualMachine machine, boolean history) {
    long steps = 0;
    while (machine.global("completed") == 0 && steps < driver.maxSteps()) {
      if (history) machine.step();
      else machine.stepWithoutRewindHistory();
      steps++;
    }
    assertEquals(1, machine.global("completed"));
  }

  static void finish(VirtualMachine machine, boolean history) {
    long steps = 0;
    while (machine.status() != MachineStatus.HALTED && steps < driver.maxSteps()) {
      if (history) machine.step();
      else machine.stepWithoutRewindHistory();
      steps++;
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    var snapshot = machine.snapshot();
    int inputRegion = snapshot.buffers().getFirst().regionId();
    for (var region : snapshot.regions()) {
      if (region.id() != inputRegion) assertTrue(region.dropped());
    }
  }

  static void assertCaller(VirtualMachine machine, String source, List<Global> expected,
      boolean accepted, boolean complete) {
    assertEquals(complete ? 1 : 0, machine.global("completed"));
    if (complete) {
      assertEquals(accepted ? 1 : 0, machine.global("accepted"));
      assertEquals(expected.size(), machine.global("count"));
      assertEquals(expected.stream().mapToInt(g -> g.name().length()).sum(),
          machine.global("nameBytes"));
    }
    var snapshot = machine.snapshot();
    int caller = snapshot.regions().stream()
        .filter(row -> row.maxBytes() == CALLER_BYTES && row.maxObjects() == CALLER_BUFFERS)
        .findFirst().orElseThrow().id();
    var buffers = snapshot.buffers().stream().filter(row -> row.regionId() == caller).toList();
    assertEquals(CALLER_BUFFERS, buffers.size());
    if (complete) {
      for (var buffer : buffers) assertEquals(false, buffer.dropped());
      for (int token = 0; token < 3; token++) {
        assertArrayEquals(new long[TOKENS], cells(buffers.get(token)));
      }
      long[] moduleRows = new long[MODULE_WORDS];
      Arrays.fill(moduleRows, FRONT_ROWS, MODULE_WORDS, SENTINEL);
      assertArrayEquals(moduleRows, cells(buffers.get(3)));
    }
    assertArrayEquals(new long[] {2, 0, 5, 1, 3, 1, 5, 14, 19, 5, 1, 9, 1, 24, 15},
        cells(buffers.get(4)));
    byte[] constantText = CONSTANT_TEXT.getBytes(StandardCharsets.UTF_8);
    long[] constantNames = new long[CONSTANT_NAME_BYTES];
    for (int i = 0; i < constantText.length; i++) constantNames[i] = Byte.toUnsignedInt(constantText[i]);
    assertArrayEquals(constantNames, cells(buffers.get(5)));
    long[] names = new long[NAME_BYTES];
    long[] products = new long[PRODUCT_WORDS];
    Arrays.fill(names, SENTINEL);
    Arrays.fill(products, SENTINEL);
    int cursor = PREFIX;
    for (int global = 0; global < expected.size(); global++) {
      Global value = expected.get(global);
      products[PREFIX + global] = cursor;
      products[PREFIX + GLOBALS + global] = value.name().length();
      products[PREFIX + GLOBALS * 2 + global] = value.initialValue();
      for (byte scalar : value.name().getBytes(StandardCharsets.UTF_8)) {
        names[cursor++] = Byte.toUnsignedInt(scalar);
      }
    }
    assertArrayEquals(names, cells(buffers.get(6)));
    assertArrayEquals(products, cells(buffers.get(7)));
    byte[] inputBytes = source.getBytes(StandardCharsets.UTF_8);
    long[] input = new long[inputBytes.length];
    for (int i = 0; i < input.length; i++) input[i] = Byte.toUnsignedInt(inputBytes[i]);
    assertArrayEquals(input, cells(snapshot.buffers().getFirst()));
  }

  private static long[] cells(BufferValue buffer) {
    return buffer.elements().stream().mapToLong(Long::longValue).toArray();
  }

  private static Program program() throws Exception {
    if (driver != null) return driver;
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_global_products"));
    sources.put("Driver.w", """
        module example.global_products;
        import wheeler.compiler.closure.source_global_products;
        import wheeler.compiler.closure.source_global_schema;
        import wheeler.compiler.compiler_token_limits;
        import wheeler.compiler.constant_product_schema;
        classical class Driver {
          const long PREFIX = 2;
          const long TAIL = 3;
          const long MODULE_WORDS = SOURCE_GLOBAL_FRONT_ROWS + TAIL;
          const long CONSTANT_COUNT = 2;
          const long CONSTANT_WORDS = CONSTANT_PRODUCT_HEADER_ROWS
            + CONSTANT_COUNT * CONSTANT_PRODUCT_COLUMNS;
          const long LIMIT_NAME_BYTES = 5;
          const long VALUE_MODULE_BYTES = 14;
          const long LOCAL_NAME_BYTES = 5;
          const long LOCAL_MODULE_BYTES = 15;
          const long LOCAL_NAME_START = LIMIT_NAME_BYTES + VALUE_MODULE_BYTES;
          const long LOCAL_MODULE_START = LOCAL_NAME_START + LOCAL_NAME_BYTES;
          const long CONSTANT_NAMES = LOCAL_MODULE_START + LOCAL_MODULE_BYTES + TAIL;
          const long NAME_BYTES = PREFIX + SOURCE_GLOBAL_NAMES + TAIL;
          const long PRODUCT_WORDS = PREFIX + SOURCE_GLOBAL_ROWS + TAIL;
          const long TOKEN_COLUMNS = 3;
          const long WORD_BYTES = 8;
          const long CALLER_BUFFERS = TOKEN_COLUMNS + 5;
          const long CALLER_WORDS = MAX_COMPILER_TOKENS * TOKEN_COLUMNS
            + MODULE_WORDS + CONSTANT_WORDS + PRODUCT_WORDS;
          const long CALLER_BYTES = CALLER_WORDS * WORD_BYTES + NAME_BYTES + CONSTANT_NAMES;
          const long SENTINEL = 211;
          state long prepared = 0;
          state long accepted = 0;
          state long count = -1;
          state long nameBytes = -1;
          state long completed = 0;
          entry void main(borrow utf8 source) {
            region caller = new region(CALLER_BYTES, CALLER_BUFFERS);
            words kinds = allocate(caller, MAX_COMPILER_TOKENS);
            words starts = allocate(caller, MAX_COMPILER_TOKENS);
            words lengths = allocate(caller, MAX_COMPILER_TOKENS);
            words moduleRange = allocate(caller, MODULE_WORDS);
            words constants = allocate(caller, CONSTANT_WORDS);
            bytes constantNames = allocateBytes(caller, CONSTANT_NAMES);
            bytes names = allocateBytes(caller, NAME_BYTES);
            words products = allocate(caller, PRODUCT_WORDS);
            writeAscii(constantNames, 0, "LIMITexample.valuesLOCALexample.globals");
            set(constants, 0, CONSTANT_COUNT);
            long firstRow = CONSTANT_PRODUCT_HEADER_ROWS;
            set(constants, firstRow + CONSTANT_NAME_START, 0);
            set(constants, firstRow + CONSTANT_NAME_LENGTH, LIMIT_NAME_BYTES);
            set(constants, firstRow + CONSTANT_TYPE, CONSTANT_SIGNED);
            set(constants, firstRow + CONSTANT_VALUE, 3);
            set(constants, firstRow + CONSTANT_RESOLVED, 1);
            set(constants, firstRow + CONSTANT_MODULE_START, LIMIT_NAME_BYTES);
            set(constants, firstRow + CONSTANT_MODULE_LENGTH, VALUE_MODULE_BYTES);
            long secondRow = firstRow + CONSTANT_PRODUCT_COLUMNS;
            set(constants, secondRow + CONSTANT_NAME_START, LOCAL_NAME_START);
            set(constants, secondRow + CONSTANT_NAME_LENGTH, LOCAL_NAME_BYTES);
            set(constants, secondRow + CONSTANT_TYPE, CONSTANT_SIGNED);
            set(constants, secondRow + CONSTANT_VALUE, 9);
            set(constants, secondRow + CONSTANT_RESOLVED, 1);
            set(constants, secondRow + CONSTANT_MODULE_START, LOCAL_MODULE_START);
            set(constants, secondRow + CONSTANT_MODULE_LENGTH, LOCAL_MODULE_BYTES);
            long moduleCell = 0;
            while (moduleCell < MODULE_WORDS) limit MODULE_WORDS {
              set(moduleRange, moduleCell, SENTINEL);
              moduleCell += 1;
            }
            long nameCell = 0;
            while (nameCell < NAME_BYTES) limit NAME_BYTES {
              setByte(names, nameCell, SENTINEL);
              nameCell += 1;
            }
            long productCell = 0;
            while (productCell < PRODUCT_WORDS) limit PRODUCT_WORDS {
              set(products, productCell, SENTINEL);
              productCell += 1;
            }
            prepared = 1;
            SourceGlobalPlan plan = materializeSourceGlobalProducts(
              source, constantNames, constants, kinds, starts, lengths, moduleRange,
              PREFIX, names, PREFIX, products);
            count = plan.globalCount;
            nameBytes = plan.nameBytes;
            if (plan.valid) { accepted = 1; }
            completed = 1;
            drop(products); drop(names); drop(constantNames); drop(constants);
            drop(moduleRange); drop(lengths); drop(starts); drop(kinds); drop(caller);
          }
        }
        """);
    driver = new WheelerCompiler().compileModuleFiles(sources, "example.global_products");
    return driver;
  }
}
