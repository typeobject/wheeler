package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Compares retained call products without reopening imported dependency source. */
final class NativeRetainedCallFixture {
  static final String MODULE = "example.structured_call";

  private NativeRetainedCallFixture() {}

  static String source(String parameters, String result, String body) {
    return "module " + MODULE + ";\nclassical class StructuredCall {\npublic " + result
        + " recurse(" + parameters + ") {\n" + body + "\n}\n}\n";
  }

  static Program assertLocal(String source, int[] types) throws Exception {
    Probe probe = machine(source, false, types, types, 1, 0);
    VirtualMachine machine = probe.machine();
    run(probe, source);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredCall.w", source), MODULE);
    assertEquals(1, machine.global("valid"));
    assertArrayEquals(new BytecodeWriter().write(expected), machine.hostOutput());
    return new BytecodeReader().read(machine.hostOutput());
  }

  static Program assertImported(String source, String target, int[] types, int resultType)
      throws Exception {
    Probe probe = machine(source, true, types, types, resultType, 0);
    VirtualMachine machine = probe.machine();
    run(probe, source);
    String localSource = source.replace(target + "(", "recurse(");
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredCall.w", localSource), MODULE);
    FunctionBody wanted = expected.functions().getFirst();
    int arity = types.length;
    List<ValueType> stubTypes = new ArrayList<>(wanted.localTypes().subList(0, arity));
    List<Instruction> stubCode;
    if (resultType == 0) {
      stubCode = List.of(Instruction.of(Opcode.RETURN));
    } else if (resultType == 1) {
      stubTypes.add(ValueType.SIGNED);
      stubCode = List.of(
          Instruction.of(Opcode.LOCAL_CONST, arity, 0),
          Instruction.of(Opcode.RETURN_VALUE, arity));
    } else {
      // Stubs synthesize a comparison, not a source Boolean literal.
      stubTypes.addAll(List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN));
      stubCode = List.of(
          Instruction.of(Opcode.LOCAL_CONST, arity, 0),
          Instruction.of(Opcode.LOCAL_CONST, arity + 1, 0),
          Instruction.of(Opcode.LOCAL_EQ, arity + 2, arity, arity + 1),
          Instruction.of(Opcode.RETURN_VALUE, arity + 2));
    }
    FunctionBody stub = new FunctionBody(
        1, "~00", false, arity, stubTypes, wanted.resultType(), false, stubCode, List.of());
    assertEquals(2, expected.functions().size());
    Program imported = new Program(expected.name(), 2, expected.globals(), List.of(
        relocate(wanted, 0), stub, relocate(expected.functions().getLast(), 2)));
    assertEquals(1, machine.global("valid"));
    assertArrayEquals(new BytecodeWriter().write(imported), machine.hostOutput());
    assertEquals(1, machine.global("relocationCount"));
    assertEquals(42, machine.global("relocationIdentityByte"));
    assertEquals(0, machine.global("relocationOwner"));
    assertEquals(1, machine.global("relocationTarget"));
    int callInstruction = 0;
    while (!wanted.forward().get(callInstruction).opcode().form().roles()
        .contains(OperandRole.FUNCTION)) {
      callInstruction++;
    }
    assertEquals(callInstruction, machine.global("relocationInstruction"));
    return new BytecodeReader().read(machine.hostOutput());
  }

  private static void run(Probe probe, String source) {
    try {
      CompilerMachineRunner.runWithoutRewindHistory(probe.machine());
    } catch (VmTrap failure) {
      var frame = probe.machine().snapshot().selectedFrames().getLast();
      String location = probe.program().function(frame.functionId()).name()
          + "[" + frame.programCounter() + "]";
      throw new AssertionError(location + "\n" + source, failure);
    }
  }

  private static FunctionBody relocate(FunctionBody function, int id) {
    return new FunctionBody(id, function.name(), function.coherent(), function.parameterCount(),
        function.localTypes(), function.resultType(), function.implicitResultSlot(),
        function.forward().stream().map(instruction -> rebind(instruction, 0, 1)).toList(),
        function.inverse().stream().map(instruction -> rebind(instruction, 0, 1)).toList());
  }

  private static Instruction rebind(Instruction instruction, long from, long to) {
    int operand = instruction.opcode().form().roles().indexOf(OperandRole.FUNCTION);
    if (operand < 0) {
      return instruction;
    }
    List<Long> operands = new ArrayList<>(instruction.operands());
    assertEquals(from, operands.set(operand, to));
    return new Instruction(instruction.opcode(), operands);
  }

  static void assertRejected(
      String source, boolean imported, int[] callerTypes, int[] targetTypes,
      int resultType, int effect) throws Exception {
    VirtualMachine machine = machine(source, imported, callerTypes, targetTypes, resultType, effect).machine();
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("artifactLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
    var snapshot = machine.snapshot();
    var publicationRegions = snapshot.regions().stream()
        .filter(region -> region.maxBytes() == 32800 && region.maxObjects() == 2).toList();
    assertFalse(publicationRegions.isEmpty());
    // Publication storage precedes compiler staging and must remain untouched.
    int region = publicationRegions.getFirst().id();
    var publication = snapshot.buffers().stream()
        .filter(buffer -> buffer.regionId() == region).toList();
    assertEquals(List.of(32768, 32), publication.stream().map(buffer -> buffer.length()).toList());
    for (var buffer : publication) {
      assertFalse(buffer.dropped());
      for (long cell : buffer.elements()) {
        assertEquals(0, cell, "unpublished artifact or identity");
      }
    }
  }

  private record Probe(Program program, VirtualMachine machine) {}

  private static Probe machine(
      String source, boolean imported, int[] callerTypes, int[] targetTypes,
      int resultType, int effect) throws Exception {
    int bodyOpen = source.indexOf('{', source.indexOf("recurse("));
    int bodyClose = SourceRanges.matchingClose(source, bodyOpen) + 1;
    int bodyStart = source.substring(0, bodyOpen).getBytes(StandardCharsets.UTF_8).length;
    int bodyLength = source.substring(bodyOpen, bodyClose).getBytes(StandardCharsets.UTF_8).length;
    Program driver = StructuredCallSourceProductDriver.driverWithParameters(
        bodyStart, bodyLength, callerTypes, imported, targetTypes, resultType, effect,
        StructuredCallSourceProductDriver.SymbolProduct.none());
    return new Probe(driver, new VirtualMachine(driver, source.getBytes(StandardCharsets.UTF_8), 32_768));
  }
}
