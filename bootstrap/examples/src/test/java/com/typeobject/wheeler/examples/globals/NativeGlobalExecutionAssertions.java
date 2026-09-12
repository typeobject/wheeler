package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/** Executes native library helpers and declared entries, including full replay state. */
public final class NativeGlobalExecutionAssertions {
  private static final String RESULT = "__fixture_result";
  private static final int ARGUMENT = 0;
  private static final int RETURNED = ARGUMENT + 1;

  private NativeGlobalExecutionAssertions() {}

  /** Checks state reads and stores with arguments distinct from the declared initializer. */
  public static void assertExecution(
      byte[] artifact, Program oracle, String subjectName, boolean assertionFails) {
    Program nativeProgram = new BytecodeReader().read(artifact);
    for (long argument : new long[] {5, 8}) {
      VirtualMachine expected = new VirtualMachine(withEntry(oracle, subjectName, argument));
      run(expected, oracle.maxSteps(), assertionFails);
      VirtualMachine actual = new VirtualMachine(withEntry(nativeProgram, subjectName, argument));
      var before = actual.snapshot();
      run(actual, nativeProgram.maxSteps(), assertionFails);
      var after = actual.snapshot();
      assertEquals(expected.snapshot(), after);
      for (Global global : oracle.globals()) {
        assertEquals(expected.global(global.name()), actual.global(global.name()));
      }
      assertEquals(expected.global(RESULT), actual.global(RESULT));
      while (actual.historySize() > 0) actual.rewindOne();
      assertEquals(before, actual.snapshot());
      run(actual, nativeProgram.maxSteps(), assertionFails);
      assertEquals(after, actual.snapshot());
      while (actual.historySize() > 0) actual.rewindOne();
      assertEquals(before, actual.snapshot());
    }
  }

  /** Runs the declared entry with matching host loans and unchanged body and manifest selection. */
  public static void assertEntryExecution(byte[] artifact, Program oracle, boolean assertionFails) {
    Program nativeProgram = new BytecodeReader().read(artifact);
    assertTrue(nativeProgram.functions().stream().noneMatch(function -> function.name().equals("$library")));
    VirtualMachine expected = withDeclaredHost(oracle);
    VirtualMachine actual = withDeclaredHost(nativeProgram);
    var before = actual.snapshot();
    run(expected, oracle.maxSteps(), assertionFails);
    run(actual, nativeProgram.maxSteps(), assertionFails);
    var after = actual.snapshot();
    assertEquals(expected.snapshot(), after);
    while (actual.historySize() > 0) actual.rewindOne();
    assertEquals(before, actual.snapshot());
    run(actual, nativeProgram.maxSteps(), assertionFails);
    assertEquals(after, actual.snapshot());
    while (actual.historySize() > 0) actual.rewindOne();
    assertEquals(before, actual.snapshot());
  }

  private static VirtualMachine withDeclaredHost(Program program) {
    FunctionBody entry = program.function(program.entryFunctionId());
    byte[] payload = "café 𝄞".getBytes(StandardCharsets.UTF_8);
    boolean utf8Input = entry.parameterCount() > 0 && entry.localType(0).equals(ValueType.UTF8_BORROW);
    boolean binaryInput = entry.parameterCount() > 0 && entry.localType(0).equals(ValueType.BYTE_VIEW);
    boolean output = entry.parameterCount() > 0
        && entry.localType(entry.parameterCount() - 1).equals(ValueType.BYTES_BORROW);
    byte[] input = utf8Input || binaryInput ? payload : null;
    int outputBytes = output ? payload.length : -1;
    return binaryInput ? VirtualMachine.withBinaryInput(program, input, outputBytes)
        : new VirtualMachine(program, input, outputBytes);
  }

  private static void run(VirtualMachine machine, long limit, boolean assertionFails) {
    long steps = 0;
    while (machine.status() != MachineStatus.HALTED && steps < limit) {
      var before = machine.snapshot();
      int history = machine.historySize();
      try {
        machine.step();
        steps++;
      } catch (VmTrap failure) {
        assertTrue(assertionFails, failure::getMessage);
        assertEquals(VmTrap.Code.ASSERTION, failure.code());
        assertEquals(before, machine.snapshot(), "a rejected assertion cannot publish a transition");
        assertEquals(history, machine.historySize());
        return;
      }
    }
    assertFalse(assertionFails, "the expected assertion must execute and reject");
    assertEquals(MachineStatus.HALTED, machine.status());
  }

  private static Program withEntry(Program module, String subjectName, long argument) {
    FunctionBody subject = module.functions().stream().filter(row -> row.name().equals(subjectName))
        .findFirst().orElseThrow();
    assertEquals(1, subject.parameterCount());
    assertEquals(ValueType.SIGNED, subject.resultType());
    assertTrue(module.globals().stream().noneMatch(global -> global.name().equals(RESULT)));
    var globals = new ArrayList<>(module.globals());
    int resultGlobal = globals.size();
    globals.add(new Global(RESULT, 0));
    var functions = new ArrayList<>(module.functions());
    int entry = module.entryFunctionId();
    FunctionBody library = module.function(entry);
    assertEquals("$library", library.name());
    assertEquals(List.of(Instruction.of(Opcode.HALT)), library.forward());
    functions.set(functions.indexOf(library), new FunctionBody(entry, library.name(), false, 0,
        List.of(ValueType.SIGNED, ValueType.SIGNED), null, List.of(
            Instruction.of(Opcode.LOCAL_CONST, ARGUMENT, argument),
            Instruction.of(Opcode.CALL_VALUE, subject.id(), ARGUMENT, subject.parameterCount(), RETURNED),
            Instruction.of(Opcode.LOCAL_STORE_GLOBAL, resultGlobal, RETURNED),
            Instruction.of(Opcode.HALT)), List.of()));
    Program result = Program.classical(module.name(), entry, globals, module.recordTypes(),
        module.variantTypes(), module.arrayTypes(), module.sliceTypes(), functions,
        module.proofCertificates());
    BytecodeVerifier.verify(result);
    return result;
  }
}
