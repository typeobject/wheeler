package com.typeobject.wheeler.examples.names;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeFormat;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.InstructionForm;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.vm.BufferKind;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.MachineSnapshot;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.RegionValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.globals.NativeGlobalExecutionAssertions;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Arrays;
import java.util.List;
import java.util.function.UnaryOperator;
import org.junit.jupiter.api.Test;

/** Differential unqualified class artifacts through the shared counted archive compiler. */
final class NativeUnqualifiedArchiveSourceExampleTest {
  @Test
  void emitsUnqualifiedHelpersAndTheActualEntryWithoutSyntheticModuleNames() throws Exception {
    check(UnqualifiedArchiveFixture.fixture("""
        state long observed = 0;
        long helper() { return 7; }
        entry void main() { observed = 7; assert(observed == 7); }
        """, 1, List.of(), UnaryOperator.identity()), true);
  }

  @Test
  void keepsEveryNamePhaseWithinTheActualNativeFrameWidth() throws Exception {
    var fixture = UnqualifiedArchiveFixture.fixture("entry void main() {}", 1, List.of(), UnaryOperator.identity());
    long frameWidth = fixture.driver().globals().stream().filter(global -> global.name().equals("frameCapacity"))
        .findFirst().orElseThrow().initialValue();
    var phases = fixture.driver().functions().stream().filter(function -> function.name().startsWith(
        "wheeler.compiler.closure.source_module_name_products::")).toList();
    assertEquals(4, phases.size());
    for (FunctionBody phase : phases) {
      assertTrue(phase.localCount() <= frameWidth, phase.name() + " has " + phase.localCount() + " locals");
    }
  }

  @Test
  void retainsBareLibraryNamesGlobalsConstantsAndClassicalClaims() throws Exception {
    for (String members : List.of("", "void helper() {}", "long entry() { return 7; }",
        "rev void helper() {} theorem roundTrip proves inverse(helper);",
        "long helper() { return 7; } theorem bound proves steps(helper, 9);")) {
      check(UnqualifiedArchiveFixture.fixture(members, 2, List.of(), UnaryOperator.identity()), false);
    }
    check(UnqualifiedArchiveFixture.fixture("""
        const long BASE = 7;
        state long observed = BASE + 2;
        long helper() { return observed; }
        theorem bound proves steps(helper, BASE);
        """, 2, List.of(new UnqualifiedArchiveFixture.Constant("BASE", 7)), UnaryOperator.identity()), false);
  }

  @Test
  void retainsEntryOrderContextualHelperNamesAndEverySupportedHostLoanSignature() throws Exception {
    for (String parameters : List.of("", "borrow utf8 input", "borrow byteview input",
        "borrow mut bytes output", "borrow utf8 input, borrow mut bytes output",
        "borrow byteview input, borrow mut bytes output")) {
      check(UnqualifiedArchiveFixture.fixture("entry void main(" + parameters + ") {}\n"
          + "long entry() { return 7; }", 3, List.of(), UnaryOperator.identity()), false);
    }
    check(UnqualifiedArchiveFixture.fixture("""
        state long observed = 0;
        entry void main() { long seven = 7; observed = helper(seven); assert(observed == 7); }
        long helper(long value) { return value; }
        """, 1, List.of(), UnaryOperator.identity()), false);
  }

  @Test
  void keepsUnjoinedLiteralCallArgumentsFailClosed() throws Exception {
    reject(UnqualifiedArchiveFixture.fixture("""
        state long observed = 0;
        entry void main() { observed = helper(7); assert(observed == 7); }
        long helper(long value) { return value; }
        """, 1, List.of(), UnaryOperator.identity()), false, false);
  }

  @Test
  void acceptsTerminalEmptyQualifierWindowsWithoutReadingThem() throws Exception {
    for (int target : List.of(1, 2)) {
      String member = target == 1 ? "entry void main() {}" : "long helper() { return 7; }";
      check(UnqualifiedArchiveFixture.fixture(member, target, List.of(), driver -> driver.replace(
          "SOURCE_START + moduleRange[0], moduleRange[1]", "bufferLength(input), 0")), false);
    }
  }

  @Test
  void fitsTheCallableIdentifierAndFullSourceWindowBoundsWithoutHistory() throws Exception {
    var shortSource = UnqualifiedArchiveFixture.fixture("entry void main() {}", 1, List.of(), UnaryOperator.identity());
    int publicationFunctions = Math.toIntExact(shortSource.driver().globals().stream()
        .filter(global -> global.name().equals("functionCapacity")).findFirst().orElseThrow().initialValue());
    StringBuilder members = new StringBuilder("entry void main() {}\n");
    for (int helper = 1; helper < publicationFunctions; helper++) {
      members.append("long helper").append(helper).append("() { return 7; }\n");
    }
    check(UnqualifiedArchiveFixture.fixture(members.toString(), 1, List.of(), UnaryOperator.identity()), false);
    String library = members.toString().replace("entry void main() {}\n", "");
    check(UnqualifiedArchiveFixture.fixture(library, 2, List.of(), UnaryOperator.identity()), false);
    // Callable staging admits 64 rows. The existing verifier admits fewer final functions.
    int callableBound = 64;
    for (int helper = publicationFunctions; helper < callableBound; helper++) {
      members.append("long helper").append(helper).append("() { return 7; }\n");
      if (helper == publicationFunctions || helper == callableBound - 1) {
        reject(UnqualifiedArchiveFixture.fixture(members.toString(), 1, List.of(), UnaryOperator.identity()), false, false);
      }
    }
    reject(UnqualifiedArchiveFixture.fixture(members.toString(), 1, List.of(), driver -> driver.replace(
        "phase = 1;", "callableCount = " + (callableBound + 1) + "; phase = 1;")), false, false);
    String fullName = "long " + "n".repeat(256) + "() { return 7; }";
    check(UnqualifiedArchiveFixture.fixture(fullName, 2, List.of(), UnaryOperator.identity()), false);
    reject(UnqualifiedArchiveFixture.fixture(fullName, 2, List.of(), driver -> driver.replace(
        "phase = 1;", "set(nameLengths, 0, 257); phase = 1;")), false, false);
    int commentDelimiters = "/* */".getBytes(StandardCharsets.UTF_8).length;
    String fullSource = shortSource.source() + "/* " + "x".repeat(UnqualifiedArchiveFixture.SOURCE_BYTES
        - shortSource.source().getBytes(StandardCharsets.UTF_8).length - commentDelimiters) + "*/";
    check(UnqualifiedArchiveFixture.sourceFixture(fullSource, 1, List.of(), UnaryOperator.identity()), false);
  }

  @Test
  void rejectsInvalidQualifierWindowsBeforePrivateStorageAndReplaysRejection() throws Exception {
    for (String range : List.of("-1, 0", "bufferLength(input) + 1, 0", Long.MAX_VALUE + ", 0",
        "0, -1", "0, 257", "0, " + Long.MAX_VALUE)) {
      var fixture = UnqualifiedArchiveFixture.fixture("entry void main() {}", 1, List.of(), driver -> driver.replace(
          "SOURCE_START + moduleRange[0], moduleRange[1]", range));
      reject(fixture, true, true);
    }
  }

  @Test
  void rejectsAnUnqualifiedClaimThatFailsAgainstTheActualCodeWithoutPublishing() throws Exception {
    var fixture = UnqualifiedArchiveFixture.fixture("""
        state long observed = 0;
        entry void main() { observed = 7; }
        theorem bound proves steps(main, 9);
        """, 1, List.of(), UnaryOperator.identity());
    assertTrue(fixture.expected().functions().get(fixture.expected().entryFunctionId()).forward().size() > 1);
    check(fixture, false);
    byte[] rejected = new String(fixture.input(), StandardCharsets.UTF_8)
        .replace("steps(main, 9)", "steps(main, 1)").getBytes(StandardCharsets.UTF_8);
    assertEquals(fixture.input().length, rejected.length);
    Rejection failure = reject(new UnqualifiedArchiveFixture.Fixture(fixture.driver(), fixture.expected(), rejected,
        fixture.source()), false, false);
    assertTrue(failure.trap().getMessage().contains("source_product_artifact::publishSourceProductArtifact"));
    byte[] invalidArtifact = new BytecodeWriter().write(fixture.expected());
    assertEquals(1, fixture.expected().proofCertificates().size());
    int proofHeaderFields = 4; // id, name, rule, subject precede the signed argument.
    int argumentOffset = sectionStart(invalidArtifact, BytecodeFormat.PROOFS)
        + Integer.BYTES + proofHeaderFields * Integer.BYTES;
    ByteBuffer.wrap(invalidArtifact).order(ByteOrder.LITTLE_ENDIAN).putLong(argumentOffset, 1);
    BytecodeException proofFailure = assertThrows(BytecodeException.class, () -> new BytecodeReader().read(invalidArtifact));
    assertTrue(proofFailure.getMessage().contains("declared step bound does not hold"));
    assertTrue(failure.snapshot().buffers().stream().filter(buffer -> !buffer.dropped()
        && buffer.kind() == BufferKind.BYTES && buffer.length() == UnqualifiedArchiveFixture.SOURCE_BYTES).anyMatch(buffer ->
            Arrays.equals(invalidArtifact, Arrays.copyOf(bytes(buffer), invalidArtifact.length))),
        "the failed verifier must receive the actual code and the original unqualified claim");
  }

  /** Captures the rejected instruction and the private container it tried to verify. */
  private record Rejection(VmTrap trap, MachineSnapshot snapshot) {}

  private static Rejection reject(UnqualifiedArchiveFixture.Fixture fixture, boolean replay, boolean beforeStorage) {
    var machine = VirtualMachine.withBinaryInput(fixture.driver(), fixture.input(), UnqualifiedArchiveFixture.SOURCE_BYTES);
    while (machine.global("phase") == 0) machine.stepWithoutRewindHistory();
    MachineSnapshot prepared = machine.snapshot();
    VmTrap trap = assertThrows(VmTrap.class, () -> {
      while (machine.global("phase") == 1 && machine.status() != MachineStatus.HALTED) {
        if (replay) machine.step(); else machine.stepWithoutRewindHistory();
      }
    });
    assertEquals(VmTrap.Code.ASSERTION, trap.code());
    MachineSnapshot rejected = machine.snapshot();
    assertEquals(prepared.globals(), rejected.globals());
    for (BufferValue buffer : prepared.buffers()) {
      assertEquals(buffer, rejected.buffers().get(buffer.id()), "caller buffer " + buffer.id());
    }
    if (beforeStorage) {
      assertEquals(prepared.regions(), rejected.regions());
      assertEquals(prepared.buffers(), rejected.buffers());
    }
    int history = machine.historySize();
    assertThrows(VmTrap.class, () -> { if (replay) machine.step(); else machine.stepWithoutRewindHistory(); });
    assertEquals(history, machine.historySize());
    assertEquals(rejected, machine.snapshot());
    if (replay) {
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(prepared, machine.snapshot());
      assertThrows(VmTrap.class, () -> { while (machine.global("phase") == 1) machine.step(); });
      assertEquals(rejected, machine.snapshot());
    }
    return new Rejection(trap, rejected);
  }

  private static void check(UnqualifiedArchiveFixture.Fixture fixture, boolean replay) throws Exception {
    byte[] expected = new BytecodeWriter().write(fixture.expected());
    assertFalse(fixture.driver().functions().stream().anyMatch(function -> function.name().contains("compileMinimal")));
    FunctionBody publisher = fixture.driver().functions().stream().filter(function -> function.name().equals(
        "wheeler.compiler.closure.source_product_artifact::publishSourceProductArtifact")).findFirst().orElseThrow();
    int recordInstruction = -1;
    for (int index = 0; index < publisher.forward().size(); index++) {
      if (publisher.forward().get(index).opcode() == Opcode.RECORD_NEW) recordInstruction = index;
    }
    assertTrue(recordInstruction > 0);
    int beforeRecord = recordInstruction - 1;
    boolean[] ready = {false};
    var machine = VirtualMachine.withBinaryInput(fixture.driver(), fixture.input(), UnqualifiedArchiveFixture.SOURCE_BYTES,
        observation -> ready[0] = observation.functionId() == publisher.id()
            && observation.instructionIndex() == beforeRecord);
    var borrowed = machine.snapshot().regions().stream().map(RegionValue::id).toList();
    while (machine.global("phase") == 0) machine.stepWithoutRewindHistory();
    MachineSnapshot prepared = machine.snapshot();
    MachineSnapshot checkpoint = prepared;
    if (replay) {
      while (!ready[0]) machine.stepWithoutRewindHistory();
      checkpoint = machine.snapshot();
      assertEquals(prepared.globals(), checkpoint.globals());
      for (BufferValue buffer : prepared.buffers()) {
        assertEquals(buffer, checkpoint.buffers().get(buffer.id()), "before report allocation " + buffer.id());
      }
    }
    while (machine.global("phase") != 2) {
      if (replay) machine.step(); else machine.stepWithoutRewindHistory();
    }
    MachineSnapshot published = machine.snapshot();
    var liveOwned = prepared.regions().stream().filter(region -> !region.dropped()
        && !borrowed.contains(region.id())).toList();
    assertEquals(1, liveOwned.size());
    var callerBuffers = prepared.buffers().stream()
        .filter(buffer -> buffer.regionId() == liveOwned.getFirst().id()).toList();
    long callerBytes = callerBuffers.stream().mapToLong(buffer -> (long) buffer.length() * switch (buffer.kind()) {
      case WORDS -> Long.BYTES;
      case BYTES, UTF8 -> Byte.BYTES;
      default -> throw new AssertionError("unexpected fixture storage: " + buffer.kind());
    }).sum();
    assertEquals(callerBytes, liveOwned.getFirst().maxBytes());
    assertEquals(callerBytes, liveOwned.getFirst().usedBytes());
    assertEquals(callerBuffers.size(), liveOwned.getFirst().maxObjects());
    var globals = new LinkedHashMap<>(prepared.globals());
    globals.put("phase", 2L);
    assertEquals(globals, published.globals());
    BufferValue identity = callerBuffers.get(callerBuffers.size() - 2);
    BufferValue report = callerBuffers.getLast();
    assertEquals(UnqualifiedArchiveFixture.IDENTITY_BYTES, identity.length());
    assertEquals(5, report.length());
    for (BufferValue previous : prepared.buffers()) {
      if (previous.id() != 1 && previous.id() != identity.id() && previous.id() != report.id()) {
        assertEquals(previous, published.buffers().get(previous.id()), "input buffer " + previous.id());
      }
    }
    byte[] output = new byte[UnqualifiedArchiveFixture.SOURCE_BYTES];
    Arrays.fill(output, (byte) UnqualifiedArchiveFixture.SENTINEL);
    System.arraycopy(expected, 0, output, 0, expected.length);
    assertArrayEquals(output, bytes(published.buffers().get(1)));
    assertArrayEquals(MessageDigest.getInstance("SHA-256").digest(expected), bytes(published.buffers().get(identity.id())));
    long calls = fixture.expected().functions().stream().flatMap(function -> function.forward().stream())
        .filter(instruction -> instruction.opcode().form().roles().contains(InstructionForm.OperandRole.FUNCTION)).count();
    assertEquals(List.of((long) expected.length, (long) sectionStart(expected, BytecodeFormat.CODE), (long) fixture.expected().functions().size(),
        (long) fixture.expected().functions().stream().mapToInt(FunctionBody::localCount).max().orElseThrow(), calls),
        published.buffers().get(report.id()).elements());
    while (machine.status() != MachineStatus.HALTED) {
      if (replay) machine.step(); else machine.stepWithoutRewindHistory();
    }
    MachineSnapshot halted = machine.snapshot();
    assertTrue(halted.buffers().stream().filter(buffer -> !borrowed.contains(buffer.regionId())).allMatch(BufferValue::dropped));
    assertTrue(halted.regions().stream().filter(region -> !borrowed.contains(region.id())).allMatch(RegionValue::dropped));
    if (replay) {
      while (machine.historySize() > 0) machine.rewindOne();
      assertEquals(checkpoint, machine.snapshot());
      while (machine.status() != MachineStatus.HALTED) machine.step();
      assertEquals(halted, machine.snapshot());
    }
    if (!fixture.expected().functions().get(fixture.expected().entryFunctionId()).name().equals("$library")) {
      byte[] emitted = Arrays.copyOf(bytes(published.buffers().get(1)), expected.length);
      NativeGlobalExecutionAssertions.assertEntryExecution(emitted, fixture.expected(), false);
    }
  }

  private static byte[] bytes(BufferValue buffer) {
    byte[] bytes = new byte[buffer.length()];
    for (int index = 0; index < bytes.length; index++) bytes[index] = buffer.elements().get(index).byteValue();
    return bytes;
  }

  private static int sectionStart(byte[] artifact, int section) {
    ByteBuffer wire = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int count = wire.getInt(BytecodeFormat.HEADER_SECTION_COUNT_OFFSET);
    int directory = Math.toIntExact(wire.getLong(BytecodeFormat.HEADER_DIRECTORY_OFFSET));
    for (int row = 0; row < count; row++) {
      int entry = directory + row * BytecodeFormat.DIRECTORY_ENTRY_SIZE;
      if (wire.getInt(entry) == section) return Math.toIntExact(wire.getLong(entry + BytecodeFormat.DIRECTORY_SECTION_OFFSET));
    }
    throw new AssertionError("missing section " + section);
  }
}
