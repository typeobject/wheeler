package com.typeobject.wheeler.examples.entries;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeFormat;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import com.typeobject.wheeler.examples.CoreSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Native verification selects entry roles from the manifest rather than descriptor positions. */
final class NativeEntryVerificationExampleTest {
  private static final int MANIFEST_SECTION = 0;
  private static final int FUNCTION_SECTION = 4;
  private static final int CODE_SECTION = 5;
  private static final int PROOF_SECTION = 6;
  private static final int DESCRIPTOR_FIELDS = 10;
  private static final int DESCRIPTOR_BYTES = DESCRIPTOR_FIELDS * Integer.BYTES;
  private static final int ENTRY_FIELD = Integer.BYTES;
  private static final int PARAMETER_FIELD = 7 * Integer.BYTES;

  @Test
  void verifiesCallsAndInverseCallsToTheFinalHelper() throws Exception {
    Program verifier = verifier();
    var covered = EnumSet.noneOf(Opcode.class);
    for (String earlier : List.of("", "void earlier() {} ")) {
      for (String[] fixture : List.of(
          new String[] {"step(); reverse { step(); }", "rev void step() { observed += 1; }"},
          new String[] {"long result = value(7); observed = result;", "long value(long n) { return n; }"},
          new String[] {"touch(7);", "void touch(long n) { observed = n; }"},
          new String[] {"long result = value(7); observed = result;", "rev long value(long n) { return n; }"})) {
        byte[] artifact = compile("state long observed = 0; " + earlier + "entry void main() { "
            + fixture[0] + " } " + fixture[1]);
        Program reference = new BytecodeReader().read(artifact);
        assertEquals(earlier.isEmpty() ? 0 : 1, reference.entryFunctionId());
        verify(verifier, artifact, true);
        for (Opcode opcode : List.of(Opcode.CALL, Opcode.UNCALL, Opcode.CALL_VALUE,
            Opcode.CALL_VOID, Opcode.CALL_RESULT_SLOT)) {
          int instruction = instruction(artifact, opcode);
          if (instruction < 0) continue;
          covered.add(opcode);
          rejectCallOperands(verifier, artifact, opcode, instruction, reference);
          byte[] invalid = artifact.clone();
          view(invalid).putLong(instruction + BytecodeFormat.INSTRUCTION_HEADER_SIZE, reference.functions().size());
          rejected(verifier, invalid);
          if (opcode == Opcode.CALL_RESULT_SLOT) {
            byte[] inverse = artifact.clone();
            view(inverse).putShort(instruction, (short) Opcode.UNCALL_RESULT_SLOT.code());
            new BytecodeReader().read(inverse);
            verify(verifier, inverse, true);
            covered.add(Opcode.UNCALL_RESULT_SLOT);
            rejectCallOperands(verifier, inverse, Opcode.UNCALL_RESULT_SLOT, instruction, reference);
            view(inverse).putLong(instruction + BytecodeFormat.INSTRUCTION_HEADER_SIZE, reference.functions().size());
            rejected(verifier, inverse);
          }
        }
      }
    }
    assertEquals(EnumSet.of(Opcode.CALL, Opcode.UNCALL, Opcode.CALL_VALUE, Opcode.CALL_VOID,
        Opcode.CALL_RESULT_SLOT, Opcode.UNCALL_RESULT_SLOT), covered);
  }

  @Test
  void rejectsFinalTargetSignatureInverseAndLoanTypeMismatches() throws Exception {
    Program verifier = verifier();
    byte[] artifact = compile("rev void marker() {} entry void main() { marker(); reverse { marker(); } touch(7); } "
        + "void touch(long n) {}");
    int last = new BytecodeReader().read(artifact).functions().size() - 1;
    for (Opcode opcode : List.of(Opcode.CALL, Opcode.UNCALL)) {
      byte[] invalid = artifact.clone();
      view(invalid).putLong(instruction(artifact, opcode) + BytecodeFormat.INSTRUCTION_HEADER_SIZE, last);
      rejected(verifier, invalid);
    }
    byte[] loan = compile("entry void main(borrow utf8 input) { long n = 0; touch(input); } "
        + "void touch(borrow utf8 source) {}");
    verify(verifier, loan, true);
    Program reference = new BytecodeReader().read(loan);
    int signed = reference.function(reference.entryFunctionId()).localTypes().indexOf(ValueType.SIGNED);
    assertTrue(signed >= 0);
    view(loan).putLong(instruction(loan, Opcode.CALL_VOID) + BytecodeFormat.INSTRUCTION_HEADER_SIZE + Long.BYTES, signed);
    rejected(verifier, loan);
  }

  @Test
  void verifiesEntryAndLaterHelperClaimsFromActualCode() throws Exception {
    Program verifier = verifier();
    for (String members : List.of(
        "entry void main() {} void after() {} theorem Bound proves steps(main, 1);",
        "entry void main() {} void after() {} theorem Bound proves steps(after, 1);",
        "void before() {} entry void main() {} theorem Bound proves steps(main, 1);")) {
      byte[] artifact = compile(members);
      verify(verifier, artifact, true);
      int certificate = section(artifact, PROOF_SECTION) + Integer.BYTES;
      byte[] badSubject = artifact.clone();
      view(badSubject).putInt(certificate + 2 * Integer.BYTES, new BytecodeReader().read(artifact).functions().size());
      rejected(verifier, badSubject);
      byte[] falseBound = artifact.clone();
      view(falseBound).putLong(certificate + 4 * Integer.BYTES, 0);
      rejected(verifier, falseBound);
    }
  }

  @Test
  void verifiesEveryHostLoanShapeAndRejectsMalformedEntryDescriptors() throws Exception {
    Program verifier = verifier();
    for (String signature : List.of("", "borrow utf8 input", "borrow byteview input", "borrow mut bytes output",
        "borrow utf8 input, borrow mut bytes output", "borrow byteview input, borrow mut bytes output")) {
      byte[] artifact = compile("entry void main(" + signature + ") {} void after() {}");
      verify(verifier, artifact, true);
      for (int entry : new int[] {-1, 1, 2}) {
        byte[] invalid = artifact.clone();
        view(invalid).putInt(section(invalid, MANIFEST_SECTION) + ENTRY_FIELD, entry);
        rejected(verifier, invalid);
      }
    }
    byte[] artifact = compile("entry void main(borrow utf8 input, borrow mut bytes output) { long n = 0; } void after() {}");
    int functions = section(artifact, FUNCTION_SECTION);
    int descriptor = functions + Integer.BYTES;
    int types = descriptor + new BytecodeReader().read(artifact).functions().size() * DESCRIPTOR_BYTES;
    for (int type : new int[] {ValueType.SIGNED.code(), ValueType.UTF8.code(), ValueType.BYTES_BORROW.code()}) {
      byte[] invalid = artifact.clone();
      view(invalid).putInt(types, type);
      rejected(verifier, invalid);
    }
    byte[] excess = artifact.clone();
    view(excess).putInt(descriptor + PARAMETER_FIELD, 3);
    rejected(verifier, excess);
  }

  private static void rejectCallOperands(
      Program verifier, byte[] artifact, Opcode opcode, int instruction, Program reference) {
    int operands = instruction + BytecodeFormat.INSTRUCTION_HEADER_SIZE;
    if (opcode == Opcode.CALL) return;
    byte[] badRole = artifact.clone();
    view(badRole).putLong(operands, reference.entryFunctionId());
    rejected(verifier, badRole);
    if (opcode == Opcode.UNCALL) return;
    int locals = reference.function(reference.entryFunctionId()).localTypes().size();
    for (int operand : new int[] {1, 2}) {
      byte[] invalid = artifact.clone();
      view(invalid).putLong(operands + operand * Long.BYTES, operand == 1 ? locals : 0);
      rejected(verifier, invalid);
    }
    if (opcode != Opcode.CALL_VOID) {
      byte[] invalid = artifact.clone();
      view(invalid).putLong(operands + 3 * Long.BYTES, locals);
      rejected(verifier, invalid);
    }
  }

  private static void rejected(Program verifier, byte[] artifact) {
    assertThrows(BytecodeException.class, () -> new BytecodeReader().read(artifact));
    verify(verifier, artifact, false);
  }

  private static void verify(Program verifier, byte[] artifact, boolean valid) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(verifier, artifact);
    var before = machine.snapshot();
    machine.run();
    var after = machine.snapshot();
    assertEquals(valid ? 1 : 0, machine.global("verification"));
    assertEquals(before.buffers(), after.buffers());
    assertEquals(before.regions(), after.regions());
    int steps = machine.historySize();
    assertTrue(steps > 0);
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    machine.run();
    assertEquals(after, machine.snapshot());
  }

  private static int instruction(byte[] artifact, Opcode opcode) {
    ByteBuffer data = view(artifact);
    int cursor = section(artifact, CODE_SECTION);
    int directory = BytecodeFormat.HEADER_SIZE + CODE_SECTION * BytecodeFormat.DIRECTORY_ENTRY_SIZE;
    int end = cursor + Math.toIntExact(data.getLong(directory + BytecodeFormat.DIRECTORY_SECTION_OFFSET + Long.BYTES));
    while (cursor < end) {
      if (Short.toUnsignedInt(data.getShort(cursor)) == opcode.code()) return cursor;
      cursor += data.getInt(cursor + Short.BYTES * 2);
    }
    return -1;
  }

  private static int section(byte[] artifact, int ordinal) {
    int directory = BytecodeFormat.HEADER_SIZE + ordinal * BytecodeFormat.DIRECTORY_ENTRY_SIZE;
    return Math.toIntExact(view(artifact).getLong(directory + BytecodeFormat.DIRECTORY_SECTION_OFFSET));
  }

  private static ByteBuffer view(byte[] artifact) {
    return ByteBuffer.wrap(artifact).order(ByteOrder.LITTLE_ENDIAN);
  }

  private static byte[] compile(String members) {
    return new WheelerCompiler().compileToBytecode("classical class EntryVerification { " + members + " }");
  }

  private static Program verifier() throws Exception {
    var modules = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.verifier"));
    CoreSources.addBinaryClosure(modules);
    modules.put("EntryVerifier.w", """
        module example.entry_verifier;
        import wheeler.compiler.verifier;
        classical class EntryVerifier {
          state long verification = 0;
          entry void main(borrow byteview artifact) {
            verification = verifyArtifact(artifact, bufferLength(artifact));
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(modules, "example.entry_verifier");
  }
}
