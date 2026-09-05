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
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Exact retained-call evidence; the bounded helper compiler has a separate profile. */
final class NativeCompilerEightArgumentSourceProductExampleTest {
  private static final String MODULE = "example.structured_call";
  private static final String PARAMETERS = "long first, boolean flag, borrow utf8 text, "
      + "borrow byteview view, borrow mut words cells, borrow mut bytes data, "
      + "long count, boolean last";
  private static final String ARGUMENTS = "first, flag, text, view, cells, data, count, last";
  private static final int[] TYPES = {1, 2, 8, 13, 10, 11, 1, 2};

  @Test
  void emitsEightArgumentRootValueAndForwardCalls() throws Exception {
    assertLocal("long", "long result = recurse(" + ARGUMENTS + ");\nreturn result;");
    assertLocal("long", "return recurse(" + ARGUMENTS + ");");
  }

  @Test
  void emitsEightArgumentLoopAndGuardedCalls() throws Exception {
    assertLocal("long", """
        long index = 0;
        while (index < 1) limit 1 {
          long result = recurse(ARGUMENTS);
          index += 1;
        }
        return first;
        """.replace("ARGUMENTS", ARGUMENTS));
    assertLocal("boolean", """
        if (recurse(ARGUMENTS)) {
          return false;
        }
        return true;
        """.replace("ARGUMENTS", ARGUMENTS));
  }

  @Test
  void emitsEightArgumentVoidCallsAtRootAndInLoops() throws Exception {
    assertLocal("void", "recurse(" + ARGUMENTS + ");");
    assertLocal("void", """
        long index = 0;
        while (index < 1) limit 1 {
          recurse(ARGUMENTS);
          index += 1;
        }
        """.replace("ARGUMENTS", ARGUMENTS));
  }

  @Test
  void preservesTheExistingArgumentBearingInverseRejection() throws Exception {
    for (int arity : new int[] {1, 8}) {
      String arguments = arity == 1 ? "first" : ARGUMENTS;
      String source = source("rev void", "recurse(" + arguments + ");")
          .replace("\n}\n}\n", "\n}\ntheorem recurseInverse proves inverse(recurse);\n}\n");
      if (arity == 1) {
        source = source.replace(PARAMETERS, "long first");
      }
      int[] types = arity == 1 ? new int[] {1} : TYPES;
      VirtualMachine machine = machine(source, false, types, types, 0, 2);
      assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
      assertUnpublished(machine);
    }
  }

  @Test
  void resolvesEightImportedArgumentsWithoutDependencySource() throws Exception {
    for (String target : List.of("remote", "dep.alpha::remote")) {
      assertImported(target, "long", "long result = CALL;\nreturn result;");
      assertImported(target, "boolean", "boolean result = CALL;\nreturn result;");
      assertImported(target, "long", """
          long index = 0;
          while (index < 1) limit 1 {
            long result = CALL;
            index += 1;
          }
          return first;
          """);
      assertImported(target, "void", "CALL;");
      assertImported(target, "void", """
          long index = 0;
          while (index < 1) limit 1 {
            CALL;
            index += 1;
          }
          """);
    }
  }

  @Test
  void rejectsWrongEighthTypesAndNinthArgumentsBeforePublication() throws Exception {
    String body = "return remote(" + ARGUMENTS + ");";
    int[] wrongTypes = TYPES.clone();
    wrongTypes[7] = 1;
    assertRejected(source("long", body), true, wrongTypes);
    assertRejected(source("long", "return recurse(" + ARGUMENTS + ", first);"), false, TYPES);
    int[] nineTypes = Arrays.copyOf(TYPES, 9);
    nineTypes[8] = 1;
    assertRejected(source("long", "return remote(" + ARGUMENTS + ", first);"), true, nineTypes);
    assertRejected(source("long", "return recurse(" + ARGUMENTS.replace("last", "missing")
        + ");"), false, TYPES);
  }

  private static void assertLocal(String result, String body) throws Exception {
    String source = source(result, body);
    VirtualMachine machine = machine(source, false, TYPES, 1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredCall.w", source), MODULE);
    assertEquals(1, machine.global("valid"));
    assertArrayEquals(new BytecodeWriter().write(expected), machine.hostOutput());
  }

  private static void assertImported(String target, String result, String body) throws Exception {
    String source = source(result, body.replace("CALL", target + "(" + ARGUMENTS + ")"));
    int resultType = switch (result) {
      case "void" -> 0;
      case "boolean" -> 2;
      default -> 1;
    };
    VirtualMachine machine = machine(source, true, TYPES, resultType);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    Program actual = new BytecodeReader().read(machine.hostOutput());
    String localSource = source.replace(target + "(", "recurse(");
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("StructuredCall.w", localSource), MODULE);
    FunctionBody wanted = expected.functions().getFirst();
    FunctionBody retained = actual.functions().getFirst();
    assertEquals(wanted, new FunctionBody(
        retained.id(), retained.name(), retained.coherent(), retained.parameterCount(),
        retained.localTypes(), retained.resultType(), retained.implicitResultSlot(),
        retained.forward().stream().map(instruction -> rebind(instruction, 1, 0)).toList(),
        retained.inverse().stream().map(instruction -> rebind(instruction, 1, 0)).toList()));
    FunctionBody stub = actual.functions().get(1);
    assertEquals(8, stub.parameterCount());
    assertEquals(wanted.localTypes().subList(0, 8), stub.localTypes().subList(0, 8));
    assertEquals(wanted.resultType(), stub.resultType());
    List<ValueType> stubTypes = new ArrayList<>(wanted.localTypes().subList(0, 8));
    List<Instruction> stubCode;
    if (resultType == 0) {
      stubCode = List.of(Instruction.of(Opcode.RETURN));
    } else if (resultType == 1) {
      stubTypes.add(ValueType.SIGNED);
      stubCode = List.of(
          Instruction.of(Opcode.LOCAL_CONST, 8, 0),
          Instruction.of(Opcode.RETURN_VALUE, 8));
    } else {
      // Verifier stubs deliberately synthesize a comparison, not a source Boolean literal.
      stubTypes.addAll(List.of(ValueType.SIGNED, ValueType.SIGNED, ValueType.BOOLEAN));
      stubCode = List.of(
          Instruction.of(Opcode.LOCAL_CONST, 8, 0),
          Instruction.of(Opcode.LOCAL_CONST, 9, 0),
          Instruction.of(Opcode.LOCAL_EQ, 10, 8, 9),
          Instruction.of(Opcode.RETURN_VALUE, 10));
    }
    assertEquals(new FunctionBody(
        1, "~00", false, 8, stubTypes, wanted.resultType(), false, stubCode, List.of()), stub);
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
  }

  private static Instruction rebind(Instruction instruction, long imported, long local) {
    int operand = instruction.opcode().form().roles().indexOf(OperandRole.FUNCTION);
    if (operand < 0) {
      return instruction;
    }
    List<Long> operands = new ArrayList<>(instruction.operands());
    assertEquals(imported, operands.set(operand, local));
    return new Instruction(instruction.opcode(), operands);
  }

  private static void assertRejected(String source, boolean imported, int[] targetTypes)
      throws Exception {
    VirtualMachine machine = machine(source, imported, targetTypes, 1);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertUnpublished(machine);
  }

  private static void assertUnpublished(VirtualMachine machine) {
    assertEquals(0, machine.global("artifactLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
    var snapshot = machine.snapshot();
    var publicationRegions = snapshot.regions().stream()
        .filter(region -> region.maxBytes() == 32800 && region.maxObjects() == 2).toList();
    assertFalse(publicationRegions.isEmpty());
    // The fixture allocates its publication arena before any compiler staging.
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

  private static VirtualMachine machine(
      String source, boolean imported, int[] targetTypes, int resultType)
      throws Exception {
    return machine(source, imported, TYPES, targetTypes, resultType, 0);
  }

  private static VirtualMachine machine(
      String source, boolean imported, int[] callerTypes, int[] targetTypes, int resultType, int effect)
      throws Exception {
    int bodyStart = source.indexOf('{', source.indexOf("recurse("));
    int bodyLength = SourceRanges.matchingClose(source, bodyStart) - bodyStart + 1;
    Program driver = StructuredCallSourceProductDriver.driverWithParameters(
        bodyStart, bodyLength, callerTypes, imported, targetTypes, resultType, effect,
        StructuredCallSourceProductDriver.SymbolProduct.none());
    return new VirtualMachine(driver, source.getBytes(StandardCharsets.UTF_8), 32_768);
  }

  private static String source(String result, String body) {
    return "module " + MODULE + ";\nclassical class StructuredCall {\npublic " + result
        + " recurse(" + PARAMETERS + ") {\n" + body + "\n}\n}\n";
  }
}
