package com.typeobject.wheeler.examples.fronts;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Shared callable fronts stage exact coordinates without allocating owned storage. */
final class NativeSourceCallableStagingExampleTest {
  private static final int CALLABLES = 4096;
  private static final int PARAMETERS = 16_384;
  private static final int LOCAL_CALLABLES = 64;
  private static final int SOURCE_BYTES = 32_768;
  private static final int RAW_TOKENS = 4096;
  private static final int MODULES = 512;
  private static final int OWNER = MODULES - 1;
  private static final long SOURCE_START = 19;
  private static final List<String> CALLABLE_COLUMNS = List.of(
      "owners", "visibilities", "nameStarts", "nameLengths", "signatureStarts", "signatureLengths",
      "bodyStarts", "bodyLengths", "counts", "firstParameters", "resultStarts", "resultLengths",
      "effects", "slotWidths");
  private static final List<String> PARAMETER_COLUMNS = List.of("typeStarts", "typeLengths", "modes");
  private static final List<String> TOKEN_COLUMNS = List.of("kinds", "starts", "lengths");

  @Test
  void stagesIntactMixedMembersAndUtf8CoordinatesWithReplay() throws Exception {
    Callable helper = new Callable("long entry()", "long", "entry", "{ return BASE; }", 0, 0, List.of());
    Callable main = new Callable("entry void main()", "void", "main", """
        {
          // Keep café 𝄞 and every nominal operation at the admission boundary.
          test void = new test.Value();
          observed = entry();
          assert(observed == BASE);
        }""", 1, 0, List.of());
    String source = """
        // café 𝄞 before every declaration
        module example.callable_fronts;
        classical class Mixed {
          state long observed = 0;
          const long BASE = 7;
          record Pair(long value) {}
          variant test { case Value(); }
          enum flag { case Ready; }
        """ + helper.text() + "\ntheorem Bound proves steps(entry, 8);\n" + main.text() + "\n}";
    new WheelerCompiler().compileModuleFiles(Map.of("Mixed.w", source), "example.callable_fronts");
    check(source, List.of(helper, main), 7, 3, true);
    String reversed = source.replace(helper.text(), "").replace(main.text(), main.text() + helper.text());
    new WheelerCompiler().compileModuleFiles(Map.of("Mixed.w", reversed), "example.callable_fronts");
    check(reversed, List.of(main, helper), 7, 3, false);
  }

  @Test
  void stagesCanonicalLoansVisibilityAndReversibleResultWindows() throws Exception {
    List<Parameter> loans = List.of(new Parameter("long value", "long", 0),
        new Parameter("borrow utf8 input", "utf8", 1),
        new Parameter("borrow mut bytes output", "bytes", 2));
    Callable ordinary = new Callable("public long copy(" + parameters(loans) + ")", "long", "copy",
        "{ return value; }", 0, 1, loans);
    Callable reversible = new Callable("private rev long undo(long value)", "long", "undo",
        "{ return value; }", 2, 0, List.of(new Parameter("long value", "long", 0)));
    Callable repeated = new Callable("public public static long repeated(long value)", "long", "repeated",
        "{ return value; }", 0, 1, List.of(new Parameter("long value", "long", 0)));
    Callable restore = new Callable("rev void restore()", "void", "restore", "{}", 2, 0, List.of());
    Callable nested = new Callable("void nested()", "void", "nested", "{ reverse { restore(); } }",
        0, 0, List.of());
    List<Callable> callables = List.of(ordinary, reversible, repeated, restore, nested);
    String source = source(callables);
    new WheelerCompiler().compileLibraryModuleFiles(Map.of("Mixed.w", source), "example.callable_fronts");
    check(source, callables, 0, 0, false);
  }

  @Test
  void fillsTerminalCallableAndParameterWindowsWithoutHistory() throws Exception {
    List<Callable> callables = new ArrayList<>();
    for (int index = 0; index < LOCAL_CALLABLES; index++) {
      callables.add(new Callable("void f" + index + "()", "void", "f" + index, "{}", 0, 0, List.of()));
    }
    check(source(callables), callables, CALLABLES - LOCAL_CALLABLES, PARAMETERS, false);
    check(source(List.of()), List.of(), CALLABLES, PARAMETERS, false);
    List<Parameter> parameters = new ArrayList<>();
    for (int index = 0; index < LOCAL_CALLABLES; index++) {
      parameters.add(new Parameter("long p" + index, "long", 0));
    }
    Callable wide = new Callable("void wide(" + parameters(parameters) + ")", "void", "wide", "{}",
        0, 0, parameters);
    check(source(List.of(wide)), List.of(wide), CALLABLES - 1, PARAMETERS - parameters.size(), false);
    callables.add(new Callable("void excess()", "void", "excess", "{}", 0, 0, List.of()));
    rejectFront(source(callables), false);
    parameters.add(new Parameter("long excess", "long", 0));
    rejectFront(source(List.of(new Callable("void wide(" + parameters(parameters) + ")", "void", "wide",
        "{}", 0, 0, parameters))), false);
  }

  @Test
  void rejectsTheFirstCallableAndParameterBeyondTheirClosureWindows() throws Exception {
    List<Parameter> parameters = List.of(new Parameter("long value", "long", 0));
    String source = source(List.of(
        new Callable("long first(long value)", "long", "first", "{ return value; }", 0, 0, parameters),
        new Callable("long second(long value)", "long", "second", "{ return value; }", 0, 0, parameters)));
    for (int[] window : List.of(new int[] {CALLABLES - 1, 0}, new int[] {0, PARAMETERS - 1})) {
      VirtualMachine machine = prepare(program(window[0], window[1], SOURCE_START, OWNER, ""), source);
      var before = machine.snapshot();
      completeStage(machine, false);
      assertEquals(-1, machine.global("result"));
      assertSameStorage(before, machine.snapshot());
      finish(machine, before, false);
    }
  }

  @Test
  void stagesTheLargestSourceAtTheLastRepresentableCoordinate() throws Exception {
    Callable last = new Callable("void last()", "void", "last", "{}", 0, 0, List.of());
    String base = source(List.of(last));
    String source = base + " ".repeat(SOURCE_BYTES - bytes(base));
    long start = Long.MAX_VALUE - SOURCE_BYTES;
    VirtualMachine machine = prepare(program(CALLABLES - 1, PARAMETERS, start, OWNER, ""), source);
    var before = machine.snapshot();
    completeStage(machine, false);
    assertSameStorage(before, machine.snapshot());
    assertEquals(1, machine.global("result"));
    assertProducts(source, List.of(last), CALLABLES - 1, PARAMETERS, start, List.of(OWNER),
        before, machine.snapshot());
    finish(machine, before, false);
    rejectPreflight(program(CALLABLES - 1, PARAMETERS, start + 1, OWNER, ""), source);
  }

  @Test
  void countsCommentsAgainstTheRawTokenArena() throws Exception {
    int moduleNameWords = 2;
    int moduleTokens = 1 + moduleNameWords + (moduleNameWords - 1) + 1;
    int classWords = 3;
    int classBraces = 2;
    int declarationTokens = moduleTokens + classWords + classBraces;
    String source = source(List.of()) + "//x\n".repeat(RAW_TOKENS - declarationTokens);
    check(source, List.of(), CALLABLES, PARAMETERS, false);
    VirtualMachine machine = prepare(program(CALLABLES, PARAMETERS, SOURCE_START, OWNER, ""),
        source + "//one excess raw token\n");
    var before = machine.snapshot();
    completeStage(machine, false);
    int inputAndProducts = 1 + CALLABLE_COLUMNS.size() + PARAMETER_COLUMNS.size();
    assertEquals(before.buffers().subList(0, inputAndProducts),
        machine.snapshot().buffers().subList(0, inputAndProducts));
    assertEquals(-1, machine.global("result"));
    finish(machine, before, false);
  }

  @Test
  void rejectsLaterMalformedFrontsWithoutInventingCallableCounts() throws Exception {
    for (String later : List.of("tetU void bad() {}", "rev test void bad() {}",
        "void bad(borrow long value) {}", "void bad(long value extra) {}", "mystery;",
        "record Pair(long value) {} trailing", "theorem Bound proves steps(ok, );",
        "rev void restore() {} reverse {}")) {
      String source = "module example.callable_fronts; classical class Mixed { void ok() {} " + later + " }";
      assertThrows(CompilerException.class, () -> new WheelerCompiler().compileLibraryModuleFiles(
          Map.of("Mixed.w", source), "example.callable_fronts"), source);
      rejectFront(source, later.equals("tetU void bad() {}"));
    }
  }

  @Test
  void rejectsEveryWrongBackingAndInvalidInitialWindowBeforeStaging() throws Exception {
    String source = source(List.of());
    for (String column : columns()) {
      rejectPreflight(program(0, 0, SOURCE_START, OWNER, column), source);
    }
    for (long first : new long[] {-1, CALLABLES + 1L, Long.MAX_VALUE}) {
      rejectPreflight(program(first, 0, SOURCE_START, OWNER, ""), source);
    }
    for (long first : new long[] {-1, PARAMETERS + 1L, Long.MAX_VALUE}) {
      rejectPreflight(program(0, first, SOURCE_START, OWNER, ""), source);
    }
    for (long start : new long[] {-1, Long.MAX_VALUE}) {
      rejectPreflight(program(0, 0, start, OWNER, ""), source);
    }
    for (long owner : new long[] {-1, MODULES, Long.MAX_VALUE}) {
      rejectPreflight(program(0, 0, SOURCE_START, owner, ""), source);
    }
    Program valid = program(0, 0, SOURCE_START, OWNER, "");
    rejectPreflight(valid, "");
    rejectPreflight(valid, " ".repeat(SOURCE_BYTES + 1));
  }

  @Test
  void publishesOnlyAfterEveryClosureMemberFrontPasses() throws Exception {
    Callable dependency = new Callable("public long value()", "long", "value", "{ return 7; }", 0, 1, List.of());
    Callable helper = new Callable("long entry()", "long", "entry", "{ return value(); }", 0, 0, List.of());
    Callable main = new Callable("entry void main()", "void", "main", "{ assert(entry() == 7); }", 1, 0, List.of());
    String leaf = "module example.dependency; classical class Dependency { " + dependency.text() + " }\n";
    String root = "module example.root; import example.dependency; classical class Root { "
        + "record Pair(long value) {} " + helper.text() + main.text() + " }";
    new WheelerCompiler().compileModuleFiles(Map.of("Leaf.w", leaf, "Root.w", root), "example.root");
    Program program = closureProgram(bytes(leaf), bytes(root));
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, (leaf + root).getBytes(StandardCharsets.UTF_8));
    while (machine.global("phase") != 1) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    completeStage(machine, true);
    var after = machine.snapshot();
    assertEquals(3, machine.global("result"));
    assertEquals(2, machine.global("reportedModules"));
    assertEquals(0, machine.global("reportedParameters"));
    assertEquals(1, machine.global("reportedPeak"));
    assertEquals(2, machine.global("reportedGeneration"));
    int modules = 2;
    int slotBuffers = 5;
    int callableBuffers = 24;
    int sourceBuffers = 1;
    int tokenBuffers = TOKEN_COLUMNS.size();
    assertEquals(slotBuffers + callableBuffers + modules * (sourceBuffers + tokenBuffers),
        after.buffers().size() - before.buffers().size());
    assertEquals(2 + modules * 2, after.regions().size() - before.regions().size());
    long callableArenaWords = MODULES * (3 + 1) + 3072L
        + CALLABLES * (long) CALLABLE_COLUMNS.size() + PARAMETERS * (long) PARAMETER_COLUMNS.size() + 2 + 1;
    long callableArenaBytes = callableArenaWords * Long.BYTES;
    assertEquals(1L, after.regions().stream()
        .filter(region -> region.maxBytes() == callableArenaBytes && region.maxObjects() == callableBuffers).count());
    assertEquals((long) modules, after.regions().stream()
        .filter(region -> region.maxBytes() == (long) RAW_TOKENS * tokenBuffers * Long.BYTES
            && region.maxObjects() == tokenBuffers).count());
    assertProducts(leaf + root, List.of(dependency, helper, main), 0, 0, 0,
        List.of(0, 1, 1), before, after);
    Map<String, List<Long>> moduleProducts = Map.of(
        "moduleFirstCallables", List.of(0L, 1L), "moduleCallableCounts", List.of(1L, 2L),
        "moduleImportedCallableCounts", List.of(0L, 1L), "edgeCallableCounts", List.of(1L));
    List<String> columns = closureColumns();
    for (int column = CALLABLE_COLUMNS.size() + PARAMETER_COLUMNS.size(); column < columns.size(); column++) {
      var expected = new ArrayList<>(before.buffers().get(column + 1).elements());
      List<Long> active = moduleProducts.getOrDefault(columns.get(column), List.of());
      for (int row = 0; row < active.size(); row++) expected.set(row, active.get(row));
      assertEquals(expected, after.buffers().get(column + 1).elements(), columns.get(column));
    }
    assertEquals(before.buffers().getFirst(), after.buffers().getFirst());
    finish(machine, before, true);

    String malformed = root.substring(0, root.length() - 1) + " tetU void bad() {} }";
    VirtualMachine rejected = VirtualMachine.withBinaryInput(closureProgram(bytes(leaf), bytes(malformed)),
        (leaf + malformed).getBytes(StandardCharsets.UTF_8));
    while (rejected.global("phase") != 1) rejected.stepWithoutRewindHistory();
    var prepared = rejected.snapshot();
    VmTrap trap = assertThrows(VmTrap.class, () -> completeStage(rejected, false));
    assertEquals(VmTrap.Code.ASSERTION, trap.code());
    for (var buffer : prepared.buffers()) {
      assertEquals(buffer, rejected.snapshot().buffers().get(buffer.id()), "public buffer " + buffer.id());
    }
    assertEquals(-2, rejected.global("result"));
    assertEquals(1, rejected.global("phase"));
    for (String report : List.of("reportedModules", "reportedParameters", "reportedPeak", "reportedGeneration")) {
      assertEquals(0, rejected.global(report), report);
    }
  }

  private static void rejectPreflight(Program program, String source) {
    VirtualMachine machine = prepare(program, source);
    var before = machine.snapshot();
    VmTrap trap = assertThrows(VmTrap.class, () -> {
      while (machine.global("phase") != 2) machine.stepWithoutRewindHistory();
    });
    assertEquals(VmTrap.Code.ASSERTION, trap.code());
    assertEquals(before.buffers(), machine.snapshot().buffers());
    assertEquals(before.regions(), machine.snapshot().regions());
    assertEquals(-2, machine.global("result"));
    assertEquals(1, machine.global("phase"));
  }

  private static void rejectFront(String source, boolean replay) throws Exception {
    VirtualMachine machine = prepare(program(0, 0, SOURCE_START, OWNER, ""), source);
    var before = machine.snapshot();
    completeStage(machine, replay);
    assertEquals(-1, machine.global("result"), source);
    assertSameStorage(before, machine.snapshot());
    finish(machine, before, replay);
  }

  private static void check(String source, List<Callable> callables, int first, int firstParameter,
      boolean replay) throws Exception {
    VirtualMachine machine = prepare(program(first, firstParameter, SOURCE_START, OWNER, ""), source);
    var before = machine.snapshot();
    completeStage(machine, replay);
    var after = machine.snapshot();
    assertEquals(callables.size(), machine.global("result"));
    assertSameStorage(before, after);
    int parameter = assertProducts(source, callables, first, firstParameter, SOURCE_START,
        callables.stream().map(ignored -> OWNER).toList(), before, after);
    assertEquals((long) parameter, after.buffers().getLast().elements().getFirst());
    String moduleName = "example.callable_fronts";
    assertEquals(List.of((long) bytes(source.substring(0, source.indexOf(moduleName))), (long) bytes(moduleName)),
        after.buffers().get(after.buffers().size() - 2).elements(), "source-relative module pair");
    finish(machine, before, replay);
  }

  private static int assertProducts(String source, List<Callable> callables, int first,
      int firstParameter, long sourceStart, List<Integer> owners,
      MachineSnapshot before, MachineSnapshot after) {
    Map<String, List<Long>> expected = new LinkedHashMap<>();
    List<String> products = new ArrayList<>(CALLABLE_COLUMNS);
    products.addAll(PARAMETER_COLUMNS);
    for (int column = 0; column < products.size(); column++) {
      expected.put(products.get(column), new ArrayList<>(before.buffers().get(column + 1).elements()));
    }
    int parameter = firstParameter;
    for (int local = 0; local < callables.size(); local++) {
      Callable callable = callables.get(local);
      int declaration = source.indexOf(callable.signature());
      int body = source.indexOf(callable.body(), declaration + callable.signature().length());
      int name = declaration + callable.signature().indexOf(callable.name() + "(");
      int result = declaration + callable.signature().indexOf(callable.resultType());
      long[] row = {owners.get(local), callable.exported(), coordinate(source, name, sourceStart), bytes(callable.name()),
          coordinate(source, declaration, sourceStart), bytes(source.substring(declaration, body)),
          coordinate(source, body, sourceStart), bytes(callable.body()), callable.parameters().size(), parameter,
          coordinate(source, result, sourceStart), bytes(callable.resultType()), callable.effect(),
          callable.effect() == 2 && !callable.resultType().equals("void") ? 2 : 0};
      for (int column = 0; column < row.length; column++) {
        expected.get(CALLABLE_COLUMNS.get(column)).set(first + local, row[column]);
      }
      int search = declaration;
      for (Parameter argument : callable.parameters()) {
        int argumentStart = source.indexOf(argument.text(), search);
        int type = argumentStart + argument.text().indexOf(argument.type());
        expected.get("typeStarts").set(parameter, coordinate(source, type, sourceStart));
        expected.get("typeLengths").set(parameter, (long) bytes(argument.type()));
        expected.get("modes").set(parameter, (long) argument.mode());
        parameter++;
        search = argumentStart + argument.text().length();
      }
    }
    for (int column = 0; column < products.size(); column++) {
      assertEquals(expected.get(products.get(column)), after.buffers().get(column + 1).elements(),
          products.get(column));
    }
    return parameter;
  }

  private static void assertSameStorage(MachineSnapshot before, MachineSnapshot after) {
    assertEquals(before.regions(), after.regions());
    assertEquals(before.buffers().size(), after.buffers().size());
    assertEquals(before.buffers().getFirst(), after.buffers().getFirst(), "borrowed UTF-8 input");
    for (int index = 1; index < before.buffers().size(); index++) {
      assertEquals(before.buffers().get(index).id(), after.buffers().get(index).id());
    }
  }

  private static VirtualMachine prepare(Program program, String source) {
    VirtualMachine machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    while (machine.global("phase") != 1) machine.stepWithoutRewindHistory();
    assertEquals(columns().size() + 1, machine.snapshot().buffers().size());
    return machine;
  }

  private static void completeStage(VirtualMachine machine, boolean replay) {
    while (machine.global("phase") != 2) {
      if (replay) machine.step();
      else machine.stepWithoutRewindHistory();
    }
  }

  private static void finish(VirtualMachine machine, MachineSnapshot before, boolean replay) {
    var after = machine.snapshot();
    if (replay) {
      int steps = machine.historySize();
      for (int step = 0; step < steps; step++) machine.rewindOne();
      assertEquals(before, machine.snapshot());
      for (int step = 0; step < steps; step++) machine.step();
      assertEquals(after, machine.snapshot());
    }
    var borrowed = before.regions().stream().filter(row -> row.id() == before.buffers().getFirst().regionId())
        .map(RegionValue::id).toList();
    while (machine.status() == MachineStatus.RUNNING) {
      if (replay) machine.step();
      else machine.stepWithoutRewindHistory();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    assertTrue(machine.snapshot().buffers().stream().filter(row -> !borrowed.contains(row.regionId()))
        .allMatch(row -> row.dropped()));
  }

  private static List<String> columns() {
    var columns = new ArrayList<>(CALLABLE_COLUMNS);
    columns.addAll(PARAMETER_COLUMNS);
    columns.addAll(TOKEN_COLUMNS);
    columns.add("moduleRange");
    columns.add("parameterTotal");
    return columns;
  }

  private static Program program(long first, long parameter, long start, long owner, String shortColumn)
      throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_callable_front_products"));
    modules.put("CallableStaging.w", driver(first, parameter, start, owner, shortColumn));
    return new WheelerCompiler().compileModuleFiles(modules, "example.callable_staging");
  }

  private static String driver(long first, long parameter, long start, long owner, String shortColumn) {
    StringBuilder allocate = new StringBuilder();
    StringBuilder initialize = new StringBuilder();
    StringBuilder drop = new StringBuilder();
    for (String column : columns()) {
      String length = CALLABLE_COLUMNS.contains(column) ? "CALLABLES"
          : PARAMETER_COLUMNS.contains(column) ? "PARAMETERS"
          : TOKEN_COLUMNS.contains(column) ? "TOKENS" : column.equals("moduleRange") ? "2" : "1";
      if (column.equals(shortColumn)) length += length.equals("1") ? " + 1" : " - 1";
      allocate.append("words ").append(column).append(" = allocate(arena, ").append(length).append(");\n");
      if (CALLABLE_COLUMNS.contains(column) || PARAMETER_COLUMNS.contains(column)) {
        initialize.append("fill(").append(column).append(");\n");
      }
      drop.insert(0, "drop(" + column + ");\n");
    }
    return """
        module example.callable_staging;
        import wheeler.compiler.closure.source_callable_front_products;
        classical class CallableStaging {
          private const long CALLABLES = 4096;
          private const long PARAMETERS = 16384;
          private const long TOKENS = 4096;
          private const long CALLABLE_COLUMNS = 14;
          private const long PARAMETER_COLUMNS = 3;
          private const long TOKEN_COLUMNS = 3;
          private const long RANGE_COLUMNS = 2;
          private const long TOTAL_COLUMNS = 1;
          private const long WORD_BYTES = 8;
          private const long EXCESS_BACKING_WORDS = 1;
          private const long ARENA_BYTES = (CALLABLES * CALLABLE_COLUMNS
            + PARAMETERS * PARAMETER_COLUMNS + TOKENS * TOKEN_COLUMNS
            + RANGE_COLUMNS + TOTAL_COLUMNS + EXCESS_BACKING_WORDS) * WORD_BYTES;
          private const long BUFFERS = CALLABLE_COLUMNS + PARAMETER_COLUMNS + TOKEN_COLUMNS + 2;
          state long phase = 0;
          state long result = -2;
          private void fill(borrow mut words rows) {
            long index = 0;
            while (index < bufferLength(rows)) limit PARAMETERS {
              set(rows, index, 211);
              index += 1;
            }
          }
          entry void main(borrow utf8 source) {
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ BUFFERS);
            ALLOCATE
            INITIALIZE
            set(parameterTotal, 0, PARAMETER);
            phase = 1;
            result = stageSourceCallableProducts(source, START, 3, FIRST,
              kinds, starts, lengths, moduleRange, owners, visibilities, nameStarts, nameLengths,
              signatureStarts, signatureLengths, bodyStarts, bodyLengths, counts, firstParameters,
              resultStarts, resultLengths, effects, slotWidths, typeStarts, typeLengths, modes,
              parameterTotal);
            phase = 2;
            DROP
            drop(arena);
          }
        }
        """.replace("ALLOCATE", allocate).replace("INITIALIZE", initialize).replace("DROP", drop)
        .replace("PARAMETER);", parameter + ");").replace("START, 3, FIRST,", start + ", " + owner + ", " + first + ",");
  }

  private static List<String> closureColumns() {
    var columns = new ArrayList<>(CALLABLE_COLUMNS);
    columns.addAll(PARAMETER_COLUMNS);
    columns.addAll(List.of("moduleFirstCallables", "moduleCallableCounts", "moduleImportedCallableCounts",
        "edgeCallableCounts", "sourceStarts", "sourceLengths", "firstImports", "directImportCounts",
        "leafFirstOrder", "edgeTargets"));
    return columns;
  }

  private static Program closureProgram(int firstLength, int secondLength) throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.module_callables"));
    var allocate = new StringBuilder();
    var initialize = new StringBuilder();
    var drop = new StringBuilder();
    for (String column : closureColumns()) {
      String length = CALLABLE_COLUMNS.contains(column) ? "CALLABLES"
          : PARAMETER_COLUMNS.contains(column) ? "PARAMETERS" : column.startsWith("edge") ? "EDGES" : "MODULES";
      allocate.append("words ").append(column).append(" = allocate(arena, ").append(length).append(");\n");
      if (CALLABLE_COLUMNS.contains(column) || PARAMETER_COLUMNS.contains(column)
          || column.startsWith("module") || column.equals("edgeCallableCounts")) {
        initialize.append("fill(").append(column).append(");\n");
      }
      drop.insert(0, "drop(" + column + ");\n");
    }
    modules.put("CallableClosure.w", """
        module example.callable_closure;
        import wheeler.compiler.closure.module_callables;
        import wheeler.compiler.closure.plan;
        classical class CallableClosure {
          private const long CALLABLES = 4096;
          private const long PARAMETERS = 16384;
          private const long MODULES = 512;
          private const long EDGES = 3072;
          private const long CALLABLE_COLUMNS = 14;
          private const long PARAMETER_COLUMNS = 3;
          private const long MODULE_COLUMNS = 3 + 5;
          private const long EDGE_COLUMNS = 1 + 1;
          private const long WORD_BYTES = 8;
          private const long ARENA_BYTES = (CALLABLES * CALLABLE_COLUMNS
            + PARAMETERS * PARAMETER_COLUMNS + MODULES * MODULE_COLUMNS
            + EDGES * EDGE_COLUMNS) * WORD_BYTES;
          private const long BUFFERS = CALLABLE_COLUMNS + PARAMETER_COLUMNS + MODULE_COLUMNS + EDGE_COLUMNS;
          state long phase = 0;
          state long result = -2;
          state long reportedModules = 0;
          state long reportedParameters = 0;
          state long reportedPeak = 0;
          state long reportedGeneration = 0;
          private void fill(borrow mut words rows) {
            long index = 0;
            while (index < bufferLength(rows)) limit PARAMETERS {
              set(rows, index, 211);
              index += 1;
            }
          }
          entry void main(borrow byteview archive) {
            region arena = new region(/* bytes= */ ARENA_BYTES, /* allocations= */ BUFFERS);
            ALLOCATE
            INITIALIZE
            set(sourceLengths, 0, FIRST_LENGTH);
            set(sourceStarts, 1, FIRST_LENGTH);
            set(sourceLengths, 1, SECOND_LENGTH);
            set(directImportCounts, 1, 1);
            set(leafFirstOrder, 1, 1);
            CountedClosurePlan closure = new CountedClosurePlan(2, 0, 1, 1);
            phase = 1;
            CountedModuleCallablePlan plan = indexCountedModuleCallables(
              archive, closure, edgeTargets, firstImports, directImportCounts, leafFirstOrder,
              sourceStarts, sourceLengths, moduleFirstCallables, moduleCallableCounts,
              moduleImportedCallableCounts, edgeCallableCounts, owners, visibilities,
              nameStarts, nameLengths, signatureStarts, signatureLengths, bodyStarts, bodyLengths,
              counts, firstParameters, resultStarts, resultLengths, effects, slotWidths,
              typeStarts, typeLengths, modes);
            result = plan.callableCount;
            reportedModules = plan.moduleCount;
            reportedParameters = plan.parameterCount;
            reportedPeak = plan.peakActiveSources;
            reportedGeneration = plan.finalGeneration;
            phase = 2;
            DROP
            drop(arena);
          }
        }
        """.replace("ALLOCATE", allocate).replace("INITIALIZE", initialize).replace("DROP", drop)
        .replace("FIRST_LENGTH", Integer.toString(firstLength)).replace("SECOND_LENGTH", Integer.toString(secondLength)));
    return new WheelerCompiler().compileModuleFiles(modules, "example.callable_closure");
  }

  private static String source(List<Callable> callables) {
    return "module example.callable_fronts; classical class Mixed { "
        + String.join("\n", callables.stream().map(Callable::text).toList()) + " }";
  }

  private static String parameters(List<Parameter> parameters) {
    return String.join(", ", parameters.stream().map(Parameter::text).toList());
  }

  private static long coordinate(String source, int index, long sourceStart) {
    return sourceStart + bytes(source.substring(0, index));
  }

  private static int bytes(String text) {
    return text.getBytes(StandardCharsets.UTF_8).length;
  }

  private record Callable(String signature, String resultType, String name, String body,
      int effect, int exported, List<Parameter> parameters) {
    String text() { return signature + " " + body; }
  }

  private record Parameter(String text, String type, int mode) {}
}
