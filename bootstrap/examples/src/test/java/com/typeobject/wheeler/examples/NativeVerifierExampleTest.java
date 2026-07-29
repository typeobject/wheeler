package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Conformance tests for Wheeler-native canonical bytecode verification. */
class NativeVerifierExampleTest {
  @Test
  void wheelerVerifiesACanonicalBinaryArtifactAndRewinds() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    var modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.verifier"));
    modules.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    modules.put("NativeVerifier.w", Files.readString(root.resolve("NativeVerifier.w")));
    var verifier = new WheelerCompiler().compileModuleFiles(
        modules, "examples.compiler.native_verifier");
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] artifact = compiler.compileToBytecode(
        "classical class NativeSubject { state long value = 4; "
            + "entry void main() { value += 3; assert(value == 7); } }");
    VirtualMachine machine = VirtualMachine.withBinaryInput(verifier, artifact);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("verification"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] binaryInputArtifact = compiler.compileToBytecode(
        "classical class BinarySubject { state long length = 0; "
            + "entry void main(borrow byteview source) { length = bufferLength(source); } }");
    VirtualMachine binaryInputVerification = VirtualMachine.withBinaryInput(
        verifier, binaryInputArtifact);
    binaryInputVerification.run();
    assertEquals(1, binaryInputVerification.global("verification"));

    byte[] logicalNegationArtifact = compiler.compileToBytecode(
        "classical class NegationSubject { state long selected = 0; "
            + "entry void main() { boolean enabled = !false; "
            + "if (enabled) { selected = 1; } } }");
    VirtualMachine logicalNegationVerification = VirtualMachine.withBinaryInput(
        verifier, logicalNegationArtifact);
    logicalNegationVerification.run();
    assertEquals(1, logicalNegationVerification.global("verification"));

    byte[] doneArtifact = compiler.compileToBytecode(
        "classical class DoneSubject { record Receipt(Done completion) {} "
            + "Done complete() { return done; } entry void main() { "
            + "Receipt receipt = new Receipt(complete()); } }");
    VirtualMachine doneVerification = VirtualMachine.withBinaryInput(verifier, doneArtifact);
    doneVerification.run();
    assertEquals(1, doneVerification.global("verification"));

    byte[] slotArtifact = compiler.compileToBytecode(
        "classical class SlotSubject { Slot<Slot<long>> nested() { "
            + "return new Slot<Slot<long>>.Holding(new Slot<long>.Vacant()); } "
            + "Slot<long[2]> pair() { return new Slot<long[2]>.Holding("
            + "new long[2](2, 3)); } entry void main() { "
            + "Slot<Slot<long>> value = nested(); Slot<long[2]> values = pair(); } }");
    VirtualMachine slotVerification = VirtualMachine.withBinaryInput(verifier, slotArtifact);
    slotVerification.run();
    assertEquals(1, slotVerification.global("verification"));

    byte[] resultSlotArtifact = compiler.compileToBytecode(
        "classical class ReversibleResultSubject { rev long minusOne() { return -1; } "
            + "theorem minusOneInverse proves inverse(minusOne); entry void main() { "
            + "long value = minusOne(); assert(value == -1); } }");
    VirtualMachine resultSlotVerification = VirtualMachine.withBinaryInput(
        verifier, resultSlotArtifact);
    resultSlotVerification.run();
    assertEquals(1, resultSlotVerification.global("verification"));

    byte[] malformedResultSlot = resultSlotArtifact.clone();
    int resultTransition = instructionOffset(malformedResultSlot, 0x0207);
    malformedResultSlot[resultTransition] = 0;
    malformedResultSlot[resultTransition + 1] = 4;
    VirtualMachine rejectedResultSlot = VirtualMachine.withBinaryInput(
        verifier, malformedResultSlot);
    assertThrows(VmTrap.class, rejectedResultSlot::run);

    byte[] invalidDone = doneArtifact.clone();
    int doneConstant = instructionOffset(invalidDone, 0x0400);
    invalidDone[doneConstant + 16] = 1;
    VirtualMachine rejectedDone = VirtualMachine.withBinaryInput(verifier, invalidDone);
    assertThrows(VmTrap.class, rejectedDone::run);

    byte[] malformed = artifact.clone();
    malformed[0] = 0;
    VirtualMachine rejected = VirtualMachine.withBinaryInput(verifier, malformed);
    assertThrows(VmTrap.class, rejected::run);
  }

  private static int instructionOffset(byte[] artifact, int expectedOpcode) {
    ByteBuffer bytes = ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
    int directory = 40 + 5 * 32;
    int cursor = Math.toIntExact(bytes.getLong(directory + 8));
    int end = cursor + Math.toIntExact(bytes.getLong(directory + 16));
    while (cursor < end) {
      int opcode = Short.toUnsignedInt(bytes.getShort(cursor));
      if (opcode == expectedOpcode) {
        return cursor;
      }
      cursor += bytes.getInt(cursor + 4);
    }
    throw new AssertionError("missing opcode " + expectedOpcode);
  }
}
