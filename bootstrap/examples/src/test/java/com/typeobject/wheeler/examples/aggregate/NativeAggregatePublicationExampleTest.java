package com.typeobject.wheeler.examples.aggregate;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Checks aggregate publication transport, allocation order, and complete caller preservation. */
final class NativeAggregatePublicationExampleTest {
  private static final int SOURCE_BYTES = 32_768;
  private static final String OWNER = "wheeler.compiler.closure.aggregate_compiled_callable_bodies";
  private static final String SOURCE = NativeCompilerAggregateAwareSourceProductExampleTest.SOURCE;
  private static final List<String> CALLER_BUFFERS = List.of(
      "localAggregates", "localCases", "localMembers", "operations", "arguments", "localReferences",
      "localProjections", "localCarriers", "localCallableBodyStarts", "localCallableBodyLengths",
      "localStatements", "localValues", "localFunctionLocals", "localDestinations", "localOwners",
      "localArgumentLocals", "localPlacements", "localConstructorTargets", "localProjectionTargets",
      "localResolvedOperations", "supplementalCode", "composedFunctions", "composedInstructions",
      "artifactSelectors", "references", "carrierFunctions", "carrierLocals", "importedAggregates",
      "projections", "carrierProjections", "calls", "effects", "firstParameters", "parameterCounts",
      "resultTypes", "parameterTypes", "parameterModes", "identity", "scalars", "scalarNameStarts", "scalarNames");
  private record Window(String caller, String staged, int count, int stride, int columns) {}
  private static final List<Window> WORD_WINDOWS = List.of(
      new Window("localProjections", "stagedLocalProjections", 4, 512, 8),
      new Window("localCarriers", "stagedLocalCarriers", 4, 512, 4),
      new Window("localStatements", "stagedStatements", 5, 4096, 6),
      new Window("localValues", "stagedValues", 6, 1024, 7),
      new Window("localFunctionLocals", "stagedLocalCounts", 1, 64, 1),
      new Window("localDestinations", "stagedDestinations", 4, 256, 1),
      new Window("localOwners", "stagedOwners", 4, 256, 1),
      new Window("localArgumentLocals", "stagedArguments", 2, 1024, 1),
      new Window("localPlacements", "stagedPlacements", 4, 256, 3),
      new Window("localConstructorTargets", "stagedConstructorTargets", 4, 256, 3),
      new Window("localProjectionTargets", "stagedProjectionTargets", 4, 256, 4),
      new Window("localResolvedOperations", "stagedResolvedOperations", 4, 256, 6),
      new Window("composedFunctions", "stagedComposedFunctions", 2, 64, 10),
      new Window("composedInstructions", "stagedComposedInstructions", 7, 4096, 6),
      new Window("artifactSelectors", "stagedArtifactSelectors", 7, 4096, 1),
      new Window("projections", "stagedProjections", 1, 16384, 3),
      new Window("carrierProjections", "stagedCarrierProjections", 1, 16384, 4));

  @Test
  void allocatesTheReportBeforePublishingAndReplaysEveryRowByteAndCleanup() throws Exception {
    checkPublicationReplay(OWNER + "::compileAggregateSourceModuleProductWithImports");
  }

  @Test
  void replaysCountedPrimitivePublicationThroughCompositionAndCallerCleanup() throws Exception {
    checkPublicationReplay("wheeler.compiler.closure.source_product_artifact::publishSourceProductArtifact");
  }

  private static void checkPublicationReplay(String checkpointOwner) throws Exception {
    Program program = markedProgram(1);
    FunctionBody compiler = program.functions().stream()
        .filter(function -> function.name().equals(OWNER + "::compileAggregateSourceModuleProductWithImports"))
        .findFirst().orElseThrow();
    int beforeReport = finalReportInstruction(compiler) - 1;
    FunctionBody checkpointFunction = program.functions().stream()
        .filter(function -> function.name().equals(checkpointOwner)).findFirst().orElseThrow();
    int beforeCheckpoint = finalReportInstruction(checkpointFunction) - 1;
    boolean[] ready = {false, false};
    var machine = VirtualMachine.withBinaryInput(program, SOURCE.getBytes(StandardCharsets.US_ASCII), SOURCE_BYTES,
        observation -> {
          ready[0] = observation.functionId() == compiler.id() && observation.instructionIndex() == beforeReport;
          ready[1] = observation.functionId() == checkpointFunction.id()
              && observation.instructionIndex() == beforeCheckpoint;
        });
    List<Integer> borrowedRegions = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    // This fixture's host ABI installs input first and output second.
    assertEquals(2, machine.snapshot().buffers().size());
    BufferValue output = machine.snapshot().buffers().getLast();
    assertEquals(SOURCE_BYTES, output.length());
    int outputBuffer = output.id();
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    MachineSnapshot prepared = machine.snapshot();
    while (!ready[1]) machine.stepWithoutRewindHistory();
    MachineSnapshot checkpoint = machine.snapshot();
    assertCallerUnchanged(prepared, checkpoint);
    assertEquals(prepared.globals(), checkpoint.globals());
    while (!ready[0]) machine.step();
    MachineSnapshot privateProducts = machine.snapshot();
    assertCallerUnchanged(prepared, privateProducts);
    assertEquals(prepared.globals(), privateProducts.globals());
    while (machine.global("completed") == 0) machine.step();
    MachineSnapshot published = machine.snapshot();
    assertPublishedBuffers(prepared, privateProducts, published, outputBuffer);
    while (machine.status() != MachineStatus.HALTED) machine.step();
    MachineSnapshot halted = machine.snapshot();
    assertTrue(halted.buffers().stream().filter(buffer -> !borrowedRegions.contains(buffer.regionId()))
        .allMatch(BufferValue::dropped));
    assertTrue(halted.regions().stream().filter(region -> !borrowedRegions.contains(region.id()))
        .allMatch(RegionValue::dropped));
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(checkpoint, machine.snapshot());
    while (machine.status() != MachineStatus.HALTED) machine.step();
    assertEquals(halted, machine.snapshot());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(checkpoint, machine.snapshot());
  }

  static void assertPublishedBuffers(MachineSnapshot prepared, MachineSnapshot privateProducts,
      MachineSnapshot published, int outputBuffer) throws Exception {
    int stagingRegion = prepared.regions().size();
    Map<String, BufferValue> caller = namedBuffers(CALLER_BUFFERS, prepared,
        prepared.regions().getLast().id());
    Map<String, BufferValue> staged = namedBuffers(stagingBufferNames(), privateProducts, stagingRegion);
    int wordCells = staged.values().stream().filter(buffer -> buffer.kind() == BufferKind.WORDS)
        .mapToInt(BufferValue::length).sum();
    int codeBytes = SOURCE_BYTES + 12_288 + 32;
    int peakSourceBuffers = 7;
    assertEquals(wordCells * Long.BYTES + peakSourceBuffers * SOURCE_BYTES + codeBytes,
        privateProducts.regions().get(stagingRegion).maxBytes());
    int wordBuffers = 5 + 2 + 6 + 6 + 8 + 2;
    int codeBuffers = 3;
    int bufferIdentities = wordBuffers + codeBuffers + peakSourceBuffers;
    assertEquals(bufferIdentities, staged.size());
    assertEquals(bufferIdentities, privateProducts.regions().get(stagingRegion).maxObjects());
    Map<Integer, List<Long>> expected = new LinkedHashMap<>();
    for (BufferValue buffer : prepared.buffers()) expected.put(buffer.id(), new ArrayList<>(buffer.elements()));
    for (Window window : WORD_WINDOWS) {
      copyWindow(expected.get(caller.get(window.caller()).id()), staged.get(window.staged()), window);
    }
    byte[] stagedBytes = bytes(staged.get("stagedArtifact"));
    int artifactLength = Math.toIntExact(ByteBuffer.wrap(stagedBytes).order(ByteOrder.LITTLE_ENDIAN).getLong(16));
    byte[] artifact = Arrays.copyOf(stagedBytes, artifactLength);
    Program primitive = new BytecodeReader().read(artifact);
    assertArrayEquals(artifact, new BytecodeWriter().write(primitive));
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(artifact), bytes(staged.get("stagedIdentity")));
    copyWindow(expected.get(outputBuffer), staged.get("stagedArtifact"),
        new Window("output", "", artifactLength, SOURCE_BYTES, 1));
    copyWindow(expected.get(caller.get("identity").id()), staged.get("stagedIdentity"),
        new Window("identity", "", 32, 32, 1));
    copyWindow(expected.get(caller.get("supplementalCode").id()), staged.get("stagedSupplementalCode"),
        new Window("supplementalCode", "", 160, 12_288, 1));
    for (BufferValue previous : prepared.buffers()) {
      BufferValue actual = published.buffers().get(previous.id());
      assertEquals(new BufferValue(previous.id(), previous.regionId(), previous.kind(), previous.length(),
          expected.get(previous.id()), previous.dropped()), actual, "caller buffer " + previous.id());
    }
    var report = published.records().get(privateProducts.records().size());
    assertEquals(List.of((long) artifactLength, 2L,
        (long) primitive.functions().stream().mapToInt(FunctionBody::localCount).max().orElseThrow(),
        4L, 160L, 7L), report.fields());
  }

  static int finalReportInstruction(FunctionBody function) {
    int report = -1;
    for (int index = 0; index < function.forward().size(); index++) {
      if (function.forward().get(index).opcode() == Opcode.RECORD_NEW) report = index;
    }
    assertTrue(report > 0, function.name());
    return report;
  }

  @Test
  void replaysLateNominalRejectionWithoutChangingAnyPreparedCallerBuffer() throws Exception {
    Program program = markedProgram(4);
    int nominal = program.functions().stream()
        .filter(function -> function.name().endsWith("::writeImportedNominalReferences"))
        .mapToInt(FunctionBody::id).findFirst().orElseThrow();
    boolean[] entered = {false};
    var machine = VirtualMachine.withBinaryInput(program, SOURCE.getBytes(StandardCharsets.US_ASCII), SOURCE_BYTES,
        observation -> entered[0] = observation.functionId() == nominal);
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    MachineSnapshot prepared = machine.snapshot();
    while (!entered[0]) machine.stepWithoutRewindHistory();
    MachineSnapshot before = machine.snapshot();
    VmTrap first = assertThrows(VmTrap.class, () -> finish(machine));
    assertEquals(VmTrap.Code.ASSERTION, first.code());
    MachineSnapshot rejected = machine.snapshot();
    assertCallerUnchanged(prepared, rejected);
    assertEquals(prepared.globals(), rejected.globals());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    VmTrap replay = assertThrows(VmTrap.class, () -> finish(machine));
    assertEquals(first.code(), replay.code());
    assertEquals(rejected, machine.snapshot());
  }

  @Test
  void rejectsPrimitiveIntentAndEveryActiveScalarRowWithoutPublishing() throws Exception {
    List<java.util.function.UnaryOperator<String>> changes = List.of(
        source -> source.replace("PACKAGE_TARGET_LIBRARY,", "PACKAGE_TARGET_DEPLOYABLE,"),
        source -> source.replace("/* constantCount= */ 0,", "/* constantCount= */ 1,"),
        source -> source.replace("/* constantCount= */ 0,", "/* constantCount= */ 1,")
            .replace("prepared = 1;", """
                set(scalars, 0, 1);
                set(scalars, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_NAME_START, 0);
                set(scalars, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_NAME_LENGTH, 1);
                set(scalars, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_TYPE, CONSTANT_SIGNED);
                set(scalars, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_VALUE, 7);
                set(scalars, CONSTANT_PRODUCT_HEADER_ROWS + CONSTANT_RESOLVED, /* invalid flag= */ 2);
                setByte(scalarNames, 0, /* ASCII_A= */ 65);
                prepared = 1;
                """));
    for (var change : changes) {
      Program program = NativeCompilerAggregateAwareSourceProductExampleTest.program(1,
          source -> change.apply(mark(source)));
      int primitive = program.functions().stream()
          .filter(function -> function.name().endsWith("::compileAggregatePrimitiveSource"))
          .mapToInt(FunctionBody::id).findFirst().orElseThrow();
      boolean[] entered = {false};
      var machine = VirtualMachine.withBinaryInput(program, SOURCE.getBytes(StandardCharsets.US_ASCII), SOURCE_BYTES,
          observation -> { if (observation.functionId() == primitive) entered[0] = true; });
      while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
      MachineSnapshot prepared = machine.snapshot();
      VmTrap trap = assertThrows(VmTrap.class, () -> {
        while (machine.status() != MachineStatus.HALTED) machine.stepWithoutRewindHistory();
      });
      assertEquals(VmTrap.Code.ASSERTION, trap.code());
      assertTrue(entered[0], "the malformed product must reach the counted primitive boundary");
      assertCallerUnchanged(prepared, machine.snapshot());
      assertEquals(prepared.globals(), machine.snapshot().globals());
    }
  }

  @Test
  void rejectsBothCarrierBackingSizesBeforeAllocatingPrivateStorage() throws Exception {
    int carrierCells = 512 * 4;
    for (int length : new int[] {carrierCells - 1, carrierCells + 1}) {
      Program program = NativeCompilerAggregateAwareSourceProductExampleTest.program(1,
          source -> mark(source)
              .replace("const long EXTRA_WORDS = 0;", "const long EXTRA_WORDS = 1;")
              .replace("localCarriers = allocate(rows, /* length= */ 2048)",
                  "localCarriers = allocate(rows, /* length= */ " + length + ")"));
      var machine = VirtualMachine.withBinaryInput(program, SOURCE.getBytes(StandardCharsets.US_ASCII), SOURCE_BYTES);
      while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
      MachineSnapshot prepared = machine.snapshot();
      assertThrows(VmTrap.class, () -> finish(machine));
      MachineSnapshot rejected = machine.snapshot();
      assertCallerUnchanged(prepared, rejected);
      assertEquals(prepared.regions(), rejected.regions());
      assertEquals(prepared.buffers().size(), rejected.buffers().size());
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(prepared, machine.snapshot());
    }
  }

  private static java.util.stream.Stream<Window> publicationWindows() {
    return WORD_WINDOWS.stream().filter(window -> !window.caller().equals("localCarriers"));
  }

  @ParameterizedTest(name = "{0}")
  @MethodSource("publicationWindows")
  void rejectsEveryWordPublicationBackingBeforePrivateAllocation(Window window) throws Exception {
    int cells = window.stride() * window.columns();
    String allocation = window.caller() + " = allocate(rows, /* length= */ " + cells + ")";
    for (int length : new int[] {cells - 1, cells + 1}) {
      Program program = NativeCompilerAggregateAwareSourceProductExampleTest.program(1, source -> {
        String marked = mark(source);
        assertTrue(marked.contains(allocation), allocation);
        return marked.replace("const long EXTRA_WORDS = 0;", "const long EXTRA_WORDS = 1;")
            .replace(allocation, window.caller() + " = allocate(rows, /* length= */ " + length + ")");
      });
      var machine = VirtualMachine.withBinaryInput(program, SOURCE.getBytes(StandardCharsets.US_ASCII), SOURCE_BYTES);
      assertBackingRejectedWithoutAllocation(machine);
    }
  }

  @ParameterizedTest(name = "{0}")
  @ValueSource(strings = {"output", "identity", "supplementalCode"})
  void rejectsEveryBytePublicationBackingBeforePrivateAllocation(String caller) throws Exception {
    for (int excess : new int[] {-1, 1}) {
      Program program = NativeCompilerAggregateAwareSourceProductExampleTest.program(1, source -> {
        String marked = mark(source);
        if (caller.equals("output")) return marked;
        var allocation = java.util.regex.Pattern.compile(java.util.regex.Pattern.quote(caller)
            + " = allocateBytes\\(rows, /\\* length= \\*/ (\\d+)\\)").matcher(marked);
        assertTrue(allocation.find(), caller);
        int length = Integer.parseInt(allocation.group(1));
        return marked.replace("const long EXTRA_WORDS = 0;", "const long EXTRA_WORDS = 1;")
            .replace(allocation.group(), caller + " = allocateBytes(rows, /* length= */ " + (length + excess) + ")");
      });
      int outputBytes = SOURCE_BYTES + (caller.equals("output") ? excess : 0);
      var machine = VirtualMachine.withBinaryInput(program, SOURCE.getBytes(StandardCharsets.US_ASCII), outputBytes);
      assertBackingRejectedWithoutAllocation(machine);
    }
  }

  private static void assertBackingRejectedWithoutAllocation(VirtualMachine machine) {
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    MachineSnapshot prepared = machine.snapshot();
    VmTrap trap = assertThrows(VmTrap.class, () -> {
      while (machine.status() != MachineStatus.HALTED) machine.stepWithoutRewindHistory();
    });
    MachineSnapshot rejected = machine.snapshot();
    assertEquals(VmTrap.Code.ASSERTION, trap.code());
    assertCallerUnchanged(prepared, rejected);
    assertEquals(prepared.globals(), rejected.globals());
    assertEquals(prepared.regions(), rejected.regions());
    assertEquals(prepared.buffers().size(), rejected.buffers().size());
    assertEquals(prepared.records(), rejected.records());
  }

  private static void finish(VirtualMachine machine) {
    while (machine.status() != MachineStatus.HALTED) machine.step();
  }

  static void assertCallerUnchanged(MachineSnapshot prepared, MachineSnapshot actual) {
    for (BufferValue buffer : prepared.buffers()) {
      assertEquals(buffer, actual.buffers().get(buffer.id()), "caller buffer " + buffer.id());
    }
  }

  private static Map<String, BufferValue> namedBuffers(List<String> names, MachineSnapshot snapshot, int region) {
    List<BufferValue> buffers = snapshot.buffers().stream().filter(buffer -> buffer.regionId() == region).toList();
    assertEquals(names.size(), buffers.size());
    Map<String, BufferValue> result = new LinkedHashMap<>();
    for (int index = 0; index < names.size(); index++) result.put(names.get(index), buffers.get(index));
    return result;
  }

  private static List<String> stagingBufferNames() throws Exception {
    String owner = CompilerSources.moduleClosure(OWNER).values().stream()
        .filter(source -> source.contains("module " + OWNER + ";")).findFirst().orElseThrow();
    var allocation = Pattern.compile("(?:words|bytes) (\\w+) = allocate(?:Bytes)?\\(sourceArena,").matcher(owner);
    List<String> names = new ArrayList<>();
    while (allocation.find()) names.add(allocation.group(1));
    return names;
  }

  private static void copyWindow(List<Long> target, BufferValue source, Window window) {
    assertEquals(window.stride() * window.columns(), target.size());
    assertEquals(target.size(), source.length());
    for (int column = 0; column < window.columns(); column++) {
      for (int row = 0; row < window.count(); row++) {
        int cell = column * window.stride() + row;
        target.set(cell, source.elements().get(cell));
      }
    }
  }

  private static byte[] bytes(BufferValue value) {
    byte[] result = new byte[value.length()];
    for (int index = 0; index < result.length; index++) result[index] = value.elements().get(index).byteValue();
    return result;
  }

  private static Program markedProgram(int kind) throws Exception {
    return NativeCompilerAggregateAwareSourceProductExampleTest.program(kind, NativeAggregatePublicationExampleTest::mark);
  }

  static String mark(String source) {
    StringBuilder initialize = new StringBuilder();
    for (Window window : WORD_WINDOWS) initialize.append("markWords(").append(window.caller()).append(");\n");
    initialize.append("markBytes(output); markBytes(identity); markBytes(supplementalCode);\n");
    int largestWordWindow = WORD_WINDOWS.stream().mapToInt(window -> window.stride() * window.columns())
        .max().orElseThrow();
    String helpers = """
        const long MAX_PREPARED_WORDS = %d;
        const long MAX_PREPARED_BYTES = %d;
        void markWords(borrow mut words data) {
          long row = 0;
          while (row < bufferLength(data)) limit MAX_PREPARED_WORDS { set(data, row, 211); row += 1; }
        }
        void markBytes(borrow mut bytes data) {
          long byte = 0;
          while (byte < bufferLength(data)) limit MAX_PREPARED_BYTES { setByte(data, byte, 211); byte += 1; }
        }
        """.formatted(largestWordWindow + 1, SOURCE_BYTES + 1);
    return source.replace("entry void main(", helpers + "entry void main(")
        .replace("prepared = 1;", initialize + "prepared = 1;");
  }
}
