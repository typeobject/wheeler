package com.typeobject.wheeler.examples;

import static com.typeobject.wheeler.examples.SourceRanges.unsigned;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Native evidence for source products derived from the physical CoreParsing module. */
final class NativeCompilerCoreParsingSourceProductsExampleTest {
  private static final String SOURCE_PATH = "compiler/backend/core/CoreParsing.w";

  @Test
  void derivesBothCallableStatementBlockLoopAndValueWindows() throws Exception {
    String source = CompilerSources.read(SOURCE_PATH);
    int firstBody = source.indexOf("{", source.indexOf("compactCompilerTokens("));
    int secondBody = source.indexOf("{", source.indexOf("discardLeadingTokens("));
    int limitName = source.indexOf("limit MAX_COMPILER_TOKENS") + "limit ".length();
    int firstName = source.indexOf("compactCompilerTokens(");
    int secondName = source.indexOf("discardLeadingTokens(");
    Program compiledProgram = NativeCompilerCoreParsingSourceProductsProgram.program(
        firstBody,
        SourceRanges.matchingClose(source, firstBody) - firstBody + 1,
        secondBody,
        SourceRanges.matchingClose(source, secondBody) - secondBody + 1,
        limitName,
        firstName,
        secondName);
    VirtualMachine machine = new VirtualMachine(
        compiledProgram, source.getBytes(StandardCharsets.UTF_8), 262_144);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(1, machine.global("blockValid"));
    assertEquals(1, machine.global("loopValid"));
    assertEquals(1, machine.global("valueValid"));
    assertEquals(11, machine.global("kindLocal"));
    assertEquals(13, machine.global("emitLocal"));
    assertEquals(6, machine.global("secondReadLocal"));
    assertEquals(8, machine.global("secondWriteLocal"));
    assertEquals(-1, machine.global("bodyFailure"));
    assertEquals(1, machine.global("bodyValid"));
    assertEquals(1, machine.global("resolvedValid"));
    assertEquals(1, machine.global("codeValid"));
    assertEquals(1, machine.global("typesValid"));
    assertEquals(1, machine.global("directValid"));
    assertEquals(1, machine.global("compositionValid"));
    assertEquals(1, machine.global("artifactValid"));
    assertEquals(1, machine.global("structuredArtifactValid"));
    assertEquals(1, machine.global("archiveArtifactValid"));
    assertEquals(1, machine.global("valid"));
    assertEquals(25, machine.global("statementCount"));
    assertEquals(7, machine.global("blockCount"));
    assertEquals(2, machine.global("loopCount"));
    assertEquals(15, machine.global("valueCount"));
    assertEquals(42, machine.global("firstProductLocalCount"));
    assertEquals(29, machine.global("secondProductLocalCount"));
    assertEquals(14, machine.global("bodyCount"));
    assertEquals(3, machine.global("nestedCount"));
    assertEquals(4_096, machine.global("firstLimit"));
    assertEquals(4_096, machine.global("secondLimit"));
    assertEquals(0, machine.global("firstLoopOwner"));
    assertEquals(1, machine.global("secondLoopOwner"));
    Program expectedProgram = new WheelerCompiler().compileLibraryModuleFiles(
        CompilerSources.moduleClosure("wheeler.compiler.core_parsing"),
        "wheeler.compiler.core_parsing");
    List<FunctionBody> expectedFunctions = expectedProgram.functions().stream()
        .filter(function -> function.name().startsWith("wheeler.compiler.core_parsing::"))
        .toList();
    int codeCursor = 0;
    int expectedInstructionCount = 0;
    for (FunctionBody function : expectedFunctions) {
      List<Instruction> expectedCode = function.forward().subList(4, function.forward().size() - 2);
      expectedInstructionCount += expectedCode.size();
      int instructionIndex = 4;
      for (Instruction instruction : expectedCode) {
        assertEquals(instruction.opcode().code(), unsigned(machine.hostOutput(), codeCursor, 2));
        for (int operand = 0; operand < instruction.operands().size(); operand++) {
          assertEquals(
              instruction.operands().get(operand).longValue(),
              unsigned(machine.hostOutput(), codeCursor + 8 + operand * 8, 8),
              function.name() + " instruction=" + instructionIndex + " operand=" + operand);
        }
        codeCursor += instruction.encodedLength();
        instructionIndex += 1;
      }
    }
    assertEquals(expectedInstructionCount, machine.global("instructionCount"));
    assertEquals(codeCursor, machine.global("codeLength"));
    int typeCursor = codeCursor;
    int typeCount = 0;
    int[] loopLocalBases = {8, 9};
    for (int owner = 0; owner < expectedFunctions.size(); owner++) {
      List<com.typeobject.wheeler.core.bytecode.ValueType> expectedTypes =
          expectedFunctions.get(owner).localTypes();
      int firstLocal = loopLocalBases[owner];
      for (int local = firstLocal; local < expectedTypes.size() - 1; local++) {
        assertEquals(owner, Byte.toUnsignedInt(machine.hostOutput()[typeCursor]));
        assertEquals(local, Byte.toUnsignedInt(machine.hostOutput()[typeCursor + 1]));
        assertEquals(
            expectedTypes.get(local).code(),
            Byte.toUnsignedInt(machine.hostOutput()[typeCursor + 2]));
        typeCursor += 3;
        typeCount += 1;
      }
    }
    assertEquals(typeCount, machine.global("typeCount"));
    assertEquals(typeCursor, machine.global("directOutputStart"));
    int directCursor = typeCursor;
    int directInstructionCount = 0;
    for (FunctionBody function : expectedFunctions) {
      List<Instruction> directCode = new java.util.ArrayList<>();
      directCode.addAll(function.forward().subList(0, 4));
      directCode.addAll(function.forward().subList(
          function.forward().size() - 2, function.forward().size()));
      for (Instruction instruction : directCode) {
        assertEquals(
            instruction.opcode().code(),
            unsigned(machine.hostOutput(), directCursor, 2));
        for (int operand = 0; operand < instruction.operands().size(); operand++) {
          assertEquals(
              instruction.operands().get(operand).longValue(),
              unsigned(machine.hostOutput(), directCursor + 8 + operand * 8, 8));
        }
        directCursor += instruction.encodedLength();
        directInstructionCount += 1;
      }
    }
    assertEquals(directInstructionCount, machine.global("directInstructionCount"));
    assertEquals(directCursor - typeCursor, machine.global("directLength"));
    assertEquals(directCursor, machine.global("directTypeOutputStart"));
    int directTypeCursor = directCursor;
    int directTypeCount = 0;
    int[][] directLocals = {{4, 5, 6, 7, 43}, {5, 6, 7, 8, 31}};
    for (int owner = 0; owner < directLocals.length; owner++) {
      for (int local : directLocals[owner]) {
        assertEquals(owner, Byte.toUnsignedInt(machine.hostOutput()[directTypeCursor]));
        assertEquals(local, Byte.toUnsignedInt(machine.hostOutput()[directTypeCursor + 1]));
        assertEquals(
            expectedFunctions.get(owner).localTypes().get(local).code(),
            Byte.toUnsignedInt(machine.hostOutput()[directTypeCursor + 2]));
        directTypeCursor += 3;
        directTypeCount += 1;
      }
    }
    assertEquals(directTypeCount, machine.global("directTypeCount"));
    assertEquals(91, machine.global("inactiveFunctionResultType"));
    assertEquals(1, machine.global("directWidthsValid"));
    assertEquals(1, machine.global("loopFrameWidthsValid"));
    assertEquals(1, machine.global("coordinateValid"));
    assertEquals(directTypeCursor, machine.global("composedOutputStart"));
    int composedCursor = directTypeCursor;
    int composedInstructionCount = 0;
    for (FunctionBody function : expectedFunctions) {
      for (Instruction instruction : function.forward()) {
        assertEquals(
            instruction.opcode().code(),
            unsigned(machine.hostOutput(), composedCursor, 2));
        for (int operand = 0; operand < instruction.operands().size(); operand++) {
          assertEquals(
              instruction.operands().get(operand).longValue(),
              unsigned(machine.hostOutput(), composedCursor + 8 + operand * 8, 8));
        }
        composedCursor += instruction.encodedLength();
        composedInstructionCount += 1;
      }
    }
    assertEquals(composedInstructionCount, machine.global("composedInstructionCount"));
    assertEquals(composedCursor - directTypeCursor, machine.global("composedLength"));
    assertEquals(composedCursor, machine.global("composedTypeOutputStart"));

    int composedTypeCursor = composedCursor;
    int composedTypeCount = 0;
    for (int owner = 0; owner < expectedFunctions.size(); owner++) {
      List<com.typeobject.wheeler.core.bytecode.ValueType> types =
          expectedFunctions.get(owner).localTypes();
      for (int local = 0; local < types.size(); local++) {
        assertEquals(owner, Byte.toUnsignedInt(machine.hostOutput()[composedTypeCursor]));
        assertEquals(local, Byte.toUnsignedInt(machine.hostOutput()[composedTypeCursor + 1]));
        assertEquals(
            types.get(local).code(),
            Byte.toUnsignedInt(machine.hostOutput()[composedTypeCursor + 2]));
        composedTypeCursor += 3;
        composedTypeCount += 1;
      }
    }
    assertEquals(composedTypeCount, machine.global("composedTypeCount"));
    assertEquals(composedTypeCursor, machine.global("artifactOutputStart"));

    byte[] expectedArtifact = new BytecodeWriter().write(expectedProgram);
    assertEquals(expectedArtifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("archivedArtifactCount"));
    assertEquals(expectedArtifact.length, machine.global("archivedArtifactBytes"));
    assertArrayEquals(
        expectedArtifact,
        java.util.Arrays.copyOfRange(
            machine.hostOutput(), composedTypeCursor, machine.hostOutput().length));
  }

}
