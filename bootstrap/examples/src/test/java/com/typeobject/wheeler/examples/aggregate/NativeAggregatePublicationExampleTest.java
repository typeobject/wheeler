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
      "resultTypes", "parameterTypes", "parameterModes", "identity");
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
    Program program = markedProgram(1);
    FunctionBody compiler = program.functions().stream()
        .filter(function -> function.name().equals(OWNER + "::compileAggregateSourceModuleProductWithImports"))
        .findFirst().orElseThrow();
    int reportInstruction = -1;
    for (int index = 0; index < compiler.forward().size(); index++) {
      var instruction = compiler.forward().get(index);
      if (instruction.opcode() == Opcode.RECORD_NEW) reportInstruction = index;
    }
    assertTrue(reportInstruction > 0);
    int beforeReport = reportInstruction - 1;
    boolean[] ready = {false};
    var machine = VirtualMachine.withBinaryInput(program, SOURCE.getBytes(StandardCharsets.US_ASCII), SOURCE_BYTES,
        observation -> ready[0] = observation.functionId() == compiler.id()
            && observation.instructionIndex() == beforeReport);
    List<Integer> borrowedRegions = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    // This fixture's host ABI installs input first and output second.
    assertEquals(2, machine.snapshot().buffers().size());
    BufferValue output = machine.snapshot().buffers().getLast();
    assertEquals(SOURCE_BYTES, output.length());
    int outputBuffer = output.id();
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    MachineSnapshot prepared = machine.snapshot();
    while (!ready[0]) machine.stepWithoutRewindHistory();
    MachineSnapshot privateProducts = machine.snapshot();
    assertCallerUnchanged(prepared, privateProducts);
    assertEquals(prepared.globals(), privateProducts.globals());
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
    int sourceIdentities = peakSourceBuffers + 1;
    int bufferIdentities = wordBuffers + codeBuffers + sourceIdentities;
    assertEquals(bufferIdentities, staged.size());
    assertEquals(bufferIdentities, privateProducts.regions().get(stagingRegion).maxObjects());

    while (machine.global("completed") == 0) machine.step();
    MachineSnapshot published = machine.snapshot();
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
    while (machine.status() != MachineStatus.HALTED) machine.step();
    MachineSnapshot halted = machine.snapshot();
    assertTrue(halted.buffers().stream().filter(buffer -> !borrowedRegions.contains(buffer.regionId()))
        .allMatch(BufferValue::dropped));
    assertTrue(halted.regions().stream().filter(region -> !borrowedRegions.contains(region.id()))
        .allMatch(RegionValue::dropped));
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(privateProducts, machine.snapshot());
    while (machine.status() != MachineStatus.HALTED) machine.step();
    assertEquals(halted, machine.snapshot());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(privateProducts, machine.snapshot());
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

  private static void finish(VirtualMachine machine) {
    while (machine.status() != MachineStatus.HALTED) machine.step();
  }

  private static void assertCallerUnchanged(MachineSnapshot prepared, MachineSnapshot actual) {
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

  private static String mark(String source) {
    StringBuilder initialize = new StringBuilder();
    for (Window window : WORD_WINDOWS) initialize.append("markWords(").append(window.caller()).append(");\n");
    initialize.append("markBytes(output); markBytes(identity); markBytes(supplementalCode);\n");
    String helpers = """
        void markWords(borrow mut words data) {
          long row = 0;
          while (row < bufferLength(data)) limit 65536 { set(data, row, 211); row += 1; }
        }
        void markBytes(borrow mut bytes data) {
          long byte = 0;
          while (byte < bufferLength(data)) limit 32768 { setByte(data, byte, 211); byte += 1; }
        }
        """;
    return source.replace("entry void main(", helpers + "entry void main(")
        .replace("prepared = 1;", initialize + "prepared = 1;");
  }
}
