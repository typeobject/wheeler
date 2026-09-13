package com.typeobject.wheeler.examples.aggregate;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RecordValue;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import com.typeobject.wheeler.examples.CoreSources;
import com.typeobject.wheeler.examples.globals.NativeGlobalExecutionAssertions;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.UnaryOperator;
import org.junit.jupiter.api.Test;

/** Checks counted compilation of private aggregate views without accepting attached claims. */
class NativeAggregatePrimitiveCompilerExampleTest {
  private static final int ARTIFACT_BYTES = 32_768;
  private static final int SOURCE_BYTES = 32_768;
  private static final int IDENTIFIER_BYTES = 256;
  private static final int IDENTITY_BYTES = 32;
  private static final int SENTINEL = 211;
  private static final byte[] PREFIX = "outside café 𝄞\n".getBytes(StandardCharsets.UTF_8);
  private static final String MODULE = "example.primitive";
  private static final String CLASS = "Primitive";
  private record Scalar(String name, long value) {}
  private record Fixture(Program driver, VirtualMachine machine) {}

  @Test
  void compilesEntriesOnEitherSideOfAContextualHelperAndCurrentGlobals() throws Exception {
    String helper = "long entry() { return BASE; }";
    String entry = "entry void main() { long carrier = 0; observed = entry(); assert(observed == BASE); }";
    for (int target : List.of(1, 3)) {
      for (String members : List.of(helper + entry, entry + helper)) {
        String source = source("state long observed = 0; const long BASE = 7; " + members);
        Program oracle = new WheelerCompiler().compileModuleFiles(Map.of("Primitive.w", source), MODULE);
        check(source, target, oracle, List.of(new Scalar("BASE", 7)));
      }
    }
  }

  @Test
  void preservesLibraryIntentAndEmptyTerminalCallableProducts() throws Exception {
    for (String members : List.of("", "state long observed = 3;", "long entry() { return 7; }")) {
      String source = source(members);
      Program oracle = new WheelerCompiler().compileLibraryModuleFiles(Map.of("Primitive.w", source), MODULE);
      check(source, 2, oracle, List.of());
    }
  }

  @Test
  void fillsTheSourceAndCallableNameWindowsAtTheFinalFunctionBound() throws Exception {
    int functionCapacity = nativeFunctionCapacity();
    int libraryEntryFunctions = 1;
    StringBuilder members = new StringBuilder();
    for (int function = 0; function < functionCapacity - libraryEntryFunctions; function++) {
      String name = function == 0 ? "helper" + "a".repeat(IDENTIFIER_BYTES - "helper".length()) : "helper" + function;
      members.append("long ").append(name).append("() { return 7; }");
    }
    String qualifier = "m".repeat(IDENTIFIER_BYTES);
    String unpadded = source(members.toString()).replace("module " + MODULE + ";", "module " + qualifier + ";");
    int commentDelimiters = "/* */".length();
    int padding = SOURCE_BYTES - unpadded.getBytes(StandardCharsets.UTF_8).length - commentDelimiters;
    String selected = unpadded.substring(0, unpadded.length() - 1) + "/* " + "x".repeat(padding) + "*/}";
    assertEquals(SOURCE_BYTES, selected.getBytes(StandardCharsets.UTF_8).length);
    Program oracle = new WheelerCompiler().compileLibraryModuleFiles(Map.of("Primitive.w", selected), qualifier);
    assertEquals(functionCapacity, oracle.functions().size());
    check(selected, 2, oracle, List.of());
    rejected(selected + " ", 2);
    rejected(source(members + "long overflow() { return 7; }"), 2);
    rejected(source("long " + "a".repeat(IDENTIFIER_BYTES + 1) + "() { return 7; }"), 2);
    rejected(source("").replace("module " + MODULE + ";", "module " + qualifier + "m;"), 2);
  }

  @Test
  void validatesTheFullScalarPacketIncludingItsLastUnusedRow() throws Exception {
    String selected = source("");
    Program oracle = new WheelerCompiler().compileLibraryModuleFiles(Map.of("Primitive.w", selected), MODULE);
    int nameStart = PREFIX.length
        + selected.substring(0, selected.indexOf(CLASS)).getBytes(StandardCharsets.UTF_8).length;
    String prepare = """
        set(constants, 0, MAX_CONSTANT_PRODUCTS);
        long scalar = 0;
        while (scalar < MAX_CONSTANT_PRODUCTS) limit MAX_CONSTANT_PRODUCTS {
          long base = CONSTANT_PRODUCT_HEADER_ROWS + scalar * CONSTANT_PRODUCT_COLUMNS;
          set(constants, base + CONSTANT_NAME_START, %d);
          set(constants, base + CONSTANT_NAME_LENGTH, 1);
          set(constants, base + CONSTANT_TYPE, CONSTANT_SIGNED);
          set(constants, base + CONSTANT_VALUE, scalar);
          set(constants, base + CONSTANT_RESOLVED, 1);
          set(nameStarts, scalar, %d);
          scalar += 1;
        }
        """.formatted(nameStart, nameStart);
    UnaryOperator<String> fullPacket = driver -> {
      String count = "0, constants, source, nameStarts";
      assertTrue(driver.contains(count));
      return driver.replace(count, "MAX_CONSTANT_PRODUCTS, constants, source, nameStarts")
          .replace("phase = 1;", prepare + "phase = 1;");
    };
    check(selected, 2, oracle, List.of(), fullPacket);
    rejected(selected, 2, driver -> fullPacket.apply(driver)
        .replace("set(constants, 0, MAX_CONSTANT_PRODUCTS);", "set(constants, 0, MAX_CONSTANT_PRODUCTS + 1);")
        .replace("MAX_CONSTANT_PRODUCTS, constants, source, nameStarts",
            "MAX_CONSTANT_PRODUCTS + 1, constants, source, nameStarts"));
    rejected(selected, 2, driver -> fullPacket.apply(driver).replace("phase = 1;", """
        long finalScalar = CONSTANT_PRODUCT_HEADER_ROWS + (MAX_CONSTANT_PRODUCTS - 1) * CONSTANT_PRODUCT_COLUMNS;
        set(constants, finalScalar + CONSTANT_RESOLVED, /* invalid flag= */ 2);
        phase = 1;
        """));
  }

  private static int nativeFunctionCapacity() throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.opcodes"));
    modules.put("Limit.w", """
        module example.primitive_limit;
        import wheeler.compiler.opcodes;
        classical class Limit {
          state long capacity = INTERPRETER_FUNCTION_COUNT;
          entry void main() {}
        }
        """);
    Program program = new WheelerCompiler().compileModuleFiles(modules, "example.primitive_limit");
    return Math.toIntExact(program.globals().getFirst().initialValue());
  }

  @Test
  void rejectsAttachedClaimsWhetherTheirPrimitiveBoundPassesOrFails() throws Exception {
    for (int bound : List.of(1, 8)) {
      rejected(source("entry void main() { long carrier = 0; } theorem Bound proves steps(main, "
          + bound + ");"), 1);
    }
  }

  @Test
  void rejectsUnjoinedTypesEffectsAndEntryIntentWithoutPublishing() throws Exception {
    rejected(source("record Pair(long value) {} Pair helper() { return new Pair(7); }"), 2);
    rejected(source("test void helper() {}"), 2);
    rejected(source("entry void main() {}"), 2);
    rejected(source("void helper() {}"), 1);
    rejected(source("entry void main() {}"), 0);
  }

  private static void check(String source, int target, Program oracle, List<Scalar> scalars) throws Exception {
    check(source, target, oracle, scalars, UnaryOperator.identity());
  }

  private static void check(String source, int target, Program oracle, List<Scalar> scalars,
      UnaryOperator<String> change) throws Exception {
    byte[] expected = new BytecodeWriter().write(oracle);
    Fixture fixture = fixture(source, target, scalars, change);
    VirtualMachine machine = fixture.machine();
    List<Integer> borrowed = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    while (machine.global("phase") != 1) machine.stepWithoutRewindHistory();
    MachineSnapshot before = machine.snapshot();
    try {
      while (machine.global("phase") != 2) machine.stepWithoutRewindHistory();
    } catch (VmTrap trap) {
      List<RecordValue> records = machine.snapshot().records();
      var frames = machine.snapshot().selectedFrames().stream().map(frame ->
          fixture.driver().functions().get(frame.functionId()).name() + "@" + frame.programCounter()).toList();
      throw new AssertionError("sourceBytes=" + source.getBytes(StandardCharsets.UTF_8).length + " " + frames
          + "\n" + records.subList(Math.max(0, records.size() - 10), records.size()), trap);
    }
    MachineSnapshot after = machine.snapshot();
    assertEquals(expected.length, machine.global("artifactLength"));
    assertEquals(oracle.functions().size(), machine.global("functionCount"));
    byte[] output = machine.hostOutput();
    assertArrayEquals(expected, Arrays.copyOf(output, expected.length));
    for (int offset = expected.length; offset < ARTIFACT_BYTES; offset++) {
      assertEquals(SENTINEL, Byte.toUnsignedInt(output[offset]), "artifact tail " + offset);
    }
    assertEquals(before.buffers().getFirst(), after.buffers().getFirst(), "input bytes");
    for (int buffer = borrowed.size(); buffer < before.buffers().size() - 1; buffer++) {
      assertEquals(before.buffers().get(buffer), after.buffers().get(buffer), "constant input " + buffer);
    }
    BufferValue identity = after.buffers().get(before.buffers().size() - 1);
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(expected);
    for (int offset = 0; offset < digest.length; offset++) {
      assertEquals(Byte.toUnsignedLong(digest[offset]), identity.elements().get(offset), "identity " + offset);
    }
    assertPrivateCleanup(after, before.regions().stream().map(RegionValue::id).toList());
    while (machine.status() == MachineStatus.RUNNING) machine.step();
    assertEquals(MachineStatus.HALTED, machine.status());
    assertPrivateCleanup(machine.snapshot(), borrowed);
    if (target != 2) {
      NativeGlobalExecutionAssertions.assertEntryExecution(Arrays.copyOf(output, expected.length), oracle, false);
    }
  }

  private static void rejected(String source, int target) throws Exception {
    rejected(source, target, UnaryOperator.identity());
  }

  private static void rejected(String source, int target, UnaryOperator<String> change) throws Exception {
    VirtualMachine machine = fixture(source, target, List.of(), change).machine();
    while (machine.global("phase") != 1) machine.stepWithoutRewindHistory();
    MachineSnapshot before = machine.snapshot();
    VmTrap trap = assertThrows(VmTrap.class, () -> {
      while (machine.status() != MachineStatus.HALTED) machine.stepWithoutRewindHistory();
    });
    assertEquals(VmTrap.Code.ASSERTION, trap.code());
    assertEquals(1, machine.global("phase"));
    assertEquals(0, machine.global("artifactLength"));
    assertEquals(0, machine.global("functionCount"));
    for (int buffer = 0; buffer < before.buffers().size(); buffer++) {
      assertEquals(before.buffers().get(buffer), machine.snapshot().buffers().get(buffer), "borrowed buffer " + buffer);
    }
  }

  private static void assertPrivateCleanup(MachineSnapshot snapshot, List<Integer> survivingRegions) {
    for (var buffer : snapshot.buffers()) {
      if (!survivingRegions.contains(buffer.regionId())) assertTrue(buffer.dropped(), "buffer " + buffer.id());
    }
    for (var region : snapshot.regions()) {
      if (!survivingRegions.contains(region.id())) assertTrue(region.dropped(), "region " + region.id());
    }
  }

  private static String source(String members) {
    return "module " + MODULE + "; classical class " + CLASS + " { " + members + " }";
  }

  private static Fixture fixture(String source, int target, List<Scalar> scalars,
      UnaryOperator<String> change) throws Exception {
    byte[] selected = source.getBytes(StandardCharsets.UTF_8);
    byte[] input = new byte[PREFIX.length + selected.length + PREFIX.length];
    System.arraycopy(PREFIX, 0, input, 0, PREFIX.length);
    System.arraycopy(selected, 0, input, PREFIX.length, selected.length);
    System.arraycopy(PREFIX, 0, input, PREFIX.length + selected.length, PREFIX.length);
    int classStart = PREFIX.length + source.substring(0, source.indexOf(CLASS)).getBytes(StandardCharsets.UTF_8).length;
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.aggregate_primitive_compiler"));
    CoreSources.addBinaryClosure(modules);
    modules.put("Sha256.w", Files.readString(Path.of("../wheeler-core/src/main/wheeler/crypto/Sha256.w")));
    StringBuilder values = new StringBuilder("set(constants, 0, " + scalars.size() + ");\n");
    for (int row = 0; row < scalars.size(); row++) {
      Scalar scalar = scalars.get(row);
      int name = PREFIX.length + source.substring(0, source.indexOf(scalar.name())).getBytes(StandardCharsets.UTF_8).length;
      String base = "(CONSTANT_PRODUCT_HEADER_ROWS + " + row + " * CONSTANT_PRODUCT_COLUMNS)";
      values.append("set(constants, " + base + " + CONSTANT_NAME_START, " + name + ");\n")
          .append("set(constants, " + base + " + CONSTANT_NAME_LENGTH, " + scalar.name().length() + ");\n")
          .append("set(constants, " + base + " + CONSTANT_TYPE, CONSTANT_SIGNED);\n")
          .append("set(constants, " + base + " + CONSTANT_VALUE, " + scalar.value() + ");\n")
          .append("set(constants, " + base + " + CONSTANT_RESOLVED, 1);\n")
          .append("set(nameStarts, " + row + ", " + name + ");\n");
    }
    String driverSource = """
        module example.primitive_driver;
        import wheeler.compiler.closure.aggregate_primitive_compiler;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.constant_product_schema;
        classical class PrimitiveDriver {
          private const long ARTIFACT_BYTES = 32768;
          private const long IDENTITY_BYTES = 32;
          private const long WORD_BYTES = 8;
          private const long METADATA_BYTES = (CONSTANT_PRODUCT_ROWS + MAX_CONSTANT_PRODUCTS) * WORD_BYTES
            + IDENTITY_BYTES;
          private const long METADATA_BUFFERS = 2 + 1;
          state long phase = 0;
          state long artifactLength = 0;
          state long functionCount = 0;
          entry void main(borrow byteview source, borrow mut bytes output) {
            region arena = new region(/* bytes= */ METADATA_BYTES, /* allocations= */ METADATA_BUFFERS);
            words constants = allocate(arena, CONSTANT_PRODUCT_ROWS);
            words nameStarts = allocate(arena, MAX_CONSTANT_PRODUCTS);
            bytes identity = allocateBytes(arena, IDENTITY_BYTES);
            long filled = 0;
            while (filled < ARTIFACT_BYTES) limit ARTIFACT_BYTES {
              setByte(output, filled, 211);
              if (filled < IDENTITY_BYTES) { setByte(identity, filled, 211); }
              filled += 1;
            }
            VALUES
            phase = 1;
            SourceProductArtifactPlan result = compileAggregatePrimitiveSource(
              TARGET, source, SOURCE_START, SOURCE_LENGTH, CLASS_START, CLASS_LENGTH,
              CONSTANT_COUNT, constants, source, nameStarts, output, identity
            );
            artifactLength = result.length;
            functionCount = result.functionCount;
            phase = 2;
            drop(identity);
            drop(nameStarts);
            drop(constants);
            drop(arena);
          }
        }
        """.replace("VALUES", values).replace("CONSTANT_COUNT", Integer.toString(scalars.size()))
        .replace("TARGET", Integer.toString(target)).replace("SOURCE_START", Integer.toString(PREFIX.length))
        .replace("SOURCE_LENGTH", Integer.toString(selected.length)).replace("CLASS_START", Integer.toString(classStart))
        .replace("CLASS_LENGTH", Integer.toString(CLASS.length()));
    modules.put("Driver.w", change.apply(driverSource));
    Program driver = new WheelerCompiler().compileModuleFiles(modules, "example.primitive_driver");
    assertFalse(driver.functions().stream().anyMatch(function -> function.name().contains("compileMinimal")));
    return new Fixture(driver, VirtualMachine.withBinaryInput(driver, input, ARTIFACT_BYTES));
  }
}
