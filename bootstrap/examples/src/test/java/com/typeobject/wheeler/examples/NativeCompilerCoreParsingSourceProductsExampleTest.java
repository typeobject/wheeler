package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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
    Program compiledProgram = program(
        firstBody,
        matchingClose(source, firstBody) - firstBody + 1,
        secondBody,
        matchingClose(source, secondBody) - secondBody + 1,
        limitName);
    VirtualMachine machine = new VirtualMachine(
        compiledProgram, source.getBytes(StandardCharsets.UTF_8), 262_144);

    try {
      CompilerMachineRunner.runWithoutRewindHistory(machine);
    } catch (RuntimeException exception) {
      var frame = machine.snapshot().selectedFrames().getLast();
      throw new AssertionError(
          compiledProgram.functions().get(frame.functionId()).name()
              + " instruction=" + frame.programCounter(),
          exception);
    }

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
    assertEquals(1, machine.global("valid"));
    assertEquals(25, machine.global("statementCount"));
    assertEquals(7, machine.global("blockCount"));
    assertEquals(2, machine.global("loopCount"));
    assertEquals(15, machine.global("valueCount"));
    assertEquals(38, machine.global("firstProductLocalCount"));
    assertEquals(23, machine.global("secondProductLocalCount"));
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

  private static Program program(
      int firstBody,
      int firstLength,
      int secondBody,
      int secondLength,
      int limitName) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_statement_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_value_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_body_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.resolved_loop_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_instruction_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.loop_local_type_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.direct_statement_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_source_composition"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_module_product_artifact"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_body_archive"));
    CoreSources.addBinaryClosure(sources);
    sources.put("FixedBinary.w", CoreSources.read("encoding/FixedBinary.w"));
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.put("CoreParsingSourceProductsExample.w", """
        module example.core_parsing_source_products;

        import wheeler.compiler.closure.callable_source_composition;
        import wheeler.compiler.closure.compiled_body_archive;
        import wheeler.compiler.closure.direct_statement_products;
        import wheeler.compiler.closure.loop_instruction_products;
        import wheeler.compiler.closure.loop_local_type_products;
        import wheeler.compiler.closure.resolved_loop_body_products;
        import wheeler.compiler.closure.resolved_loop_products;
        import wheeler.compiler.closure.source_loop_products;
        import wheeler.compiler.closure.source_module_product_artifact;
        import wheeler.compiler.closure.source_product_artifact;
        import wheeler.compiler.closure.source_statement_products;
        import wheeler.compiler.closure.source_value_products;
        import wheeler.core.encoding.binary;

        classical class CoreParsingSourceProductsExample {
          state long valid = 0;
          state long blockValid = 0;
          state long loopValid = 0;
          state long valueValid = 0;
          state long bodyValid = 0;
          state long resolvedValid = 0;
          state long codeValid = 0;
          state long typesValid = 0;
          state long directValid = 0;
          state long compositionValid = 0;
          state long artifactValid = 0;
          state long instructionCount = 0;
          state long codeLength = 0;
          state long typeCount = 0;
          state long directInstructionCount = 0;
          state long directLength = 0;
          state long directTypeCount = 0;
          state long directOutputStart = 0;
          state long directTypeOutputStart = 0;
          state long composedInstructionCount = 0;
          state long composedLength = 0;
          state long composedTypeCount = 0;
          state long composedOutputStart = 0;
          state long composedTypeOutputStart = 0;
          state long artifactLength = 0;
          state long artifactOutputStart = 0;
          state long archivedArtifactCount = 0;
          state long archivedArtifactBytes = 0;
          state long statementCount = 0;
          state long blockCount = 0;
          state long loopCount = 0;
          state long valueCount = 0;
          state long firstProductLocalCount = 0;
          state long secondProductLocalCount = 0;
          state long kindLocal = 0;
          state long emitLocal = 0;
          state long secondReadLocal = 0;
          state long secondWriteLocal = 0;
          state long bodyFailure = 0;
          state long bodyCount = 0;
          state long nestedCount = 0;
          state long firstLimit = 0;
          state long secondLimit = 0;
          state long firstLoopOwner = 0;
          state long secondLoopOwner = 0;

          entry void main(borrow utf8 input, borrow mut bytes output) {
            region products = new region(/* bytes= */ 19711008, /* allocations= */ 43);
            words bodyStarts = allocate(products, /* length= */ 4096);
            words bodyLengths = allocate(products, /* length= */ 4096);
            words blocks = allocate(products, /* length= */ 6144);
            words statements = allocate(products, /* length= */ 28672);
            words conditions = allocate(products, /* length= */ 1536);
            words loops = allocate(products, /* length= */ 2304);
            words values = allocate(products, /* length= */ 7168);
            words functionLocalCounts = allocate(products, /* length= */ 64);
            words bodyRows = allocate(products, /* length= */ 20480);
            words nestedRows = allocate(products, /* length= */ 20480);
            words resolvedConditions = allocate(products, /* length= */ 1536);
            words resolvedLoops = allocate(products, /* length= */ 2304);
            words symbolOwners = allocate(products, /* length= */ 16384);
            words symbolStarts = allocate(products, /* length= */ 16384);
            words symbolLengths = allocate(products, /* length= */ 16384);
            words symbolTypes = allocate(products, /* length= */ 16384);
            words symbolValues = allocate(products, /* length= */ 16384);
            words symbolResolved = allocate(products, /* length= */ 16384);
            words loopLocalBases = allocate(products, /* length= */ 256);
            words loopInstructionStarts = allocate(products, /* length= */ 256);
            words loopWindowRows = allocate(products, /* length= */ 768);
            words typeRows = allocate(products, /* length= */ 12288);
            words callableReturnLocals = allocate(products, /* length= */ 64);
            words directRows = allocate(products, /* length= */ 28672);
            words directTypes = allocate(products, /* length= */ 12288);
            bytes directCode = allocateBytes(products, /* length= */ 262144);
            words signatureTypes = allocate(products, /* length= */ 12288);
            words composedCallables = allocate(products, /* length= */ 320);
            words composedTypes = allocate(products, /* length= */ 12288);
            bytes composedCode = allocateBytes(products, /* length= */ 262144);
            bytes strings = allocateBytes(products, /* length= */ 32768);
            words stringStarts = allocate(products, /* length= */ 256);
            words stringLengths = allocate(products, /* length= */ 256);
            words parameterCounts = allocate(products, /* length= */ 64);
            words functionNameIds = allocate(products, /* length= */ 64);
            bytes artifact = allocateBytes(products, /* length= */ 32768);
            bytes identity = allocateBytes(products, /* length= */ 32);
            words modulePublished = allocate(products, /* length= */ 512);
            words moduleArtifactRanks = allocate(products, /* length= */ 512);
            words artifactStarts = allocate(products, /* length= */ 512);
            words artifactLengths = allocate(products, /* length= */ 512);
            bytes bodyArchive = allocateBytes(products, /* length= */ 16777216);
            words unused = allocate(products, /* length= */ 1);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(bodyStarts, 1, %d);
            set(bodyLengths, 1, %d);
            set(symbolOwners, 0, 0);
            set(symbolStarts, 0, %d);
            set(symbolLengths, 0, 19);
            set(symbolTypes, 0, 1);
            set(symbolValues, 0, 4096);
            set(symbolResolved, 0, 1);
            set(loopLocalBases, 0, 8);
            set(loopLocalBases, 1, 9);
            set(loopInstructionStarts, 0, 4);
            set(loopInstructionStarts, 1, 4);
            set(callableReturnLocals, 0, 43);
            set(callableReturnLocals, 1, 31);
            set(signatureTypes, 0, 0);
            set(signatureTypes, 4096, 0);
            set(signatureTypes, 8192, 10);
            set(signatureTypes, 1, 0);
            set(signatureTypes, 4097, 1);
            set(signatureTypes, 8193, 10);
            set(signatureTypes, 2, 0);
            set(signatureTypes, 4098, 2);
            set(signatureTypes, 8194, 10);
            set(signatureTypes, 3, 0);
            set(signatureTypes, 4099, 3);
            set(signatureTypes, 8195, 1);
            set(signatureTypes, 4, 1);
            set(signatureTypes, 4100, 0);
            set(signatureTypes, 8196, 10);
            set(signatureTypes, 5, 1);
            set(signatureTypes, 4101, 1);
            set(signatureTypes, 8197, 10);
            set(signatureTypes, 6, 1);
            set(signatureTypes, 4102, 2);
            set(signatureTypes, 8198, 10);
            set(signatureTypes, 7, 1);
            set(signatureTypes, 4103, 3);
            set(signatureTypes, 8199, 1);
            set(signatureTypes, 8, 1);
            set(signatureTypes, 4104, 4);
            set(signatureTypes, 8200, 1);
            writeAscii(strings, 0, "$library");
            writeAscii(strings, 8, "CoreParsing");
            writeAscii(strings, 19, "wheeler.compiler.core_parsing::compactCompilerTokens");
            writeAscii(strings, 71, "wheeler.compiler.core_parsing::discardLeadingTokens");
            set(stringStarts, 0, 0);
            set(stringLengths, 0, 8);
            set(stringStarts, 1, 8);
            set(stringLengths, 1, 11);
            set(stringStarts, 2, 19);
            set(stringLengths, 2, 52);
            set(stringStarts, 3, 71);
            set(stringLengths, 3, 51);
            set(parameterCounts, 0, 4);
            set(parameterCounts, 1, 5);
            set(functionNameIds, 0, 2);
            set(functionNameIds, 1, 3);
            SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
              input, 0, 0, 2, bodyStarts, bodyLengths, blocks
            );
            SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
              input,
              blockPlan.blockCount,
              blocks,
              statements,
              conditions,
              loops
            );
            SourceValueProductPlan valuePlan = materializeSourceValueProducts(
              input,
              0,
              0,
              2,
              bodyStarts,
              loopPlan.statementCount,
              statements,
              /* statementStartRow= */ 12288,
              /* statementLengthRow= */ 16384,
              values,
              functionLocalCounts
            );
            if (blockPlan.valid) {
              blockValid = 1;
            }
            if (loopPlan.valid) {
              loopValid = 1;
            }
            if (valuePlan.valid) {
              valueValid = 1;
            }
            ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
              input,
              loopPlan.statementCount,
              statements,
              valuePlan.valueCount,
              values,
              bodyRows,
              nestedRows
            );
            if (bodyPlan.valid) {
              bodyValid = 1;
            }
            ResolvedLoopProductPlan resolvedPlan = materializeResolvedLoopProducts(
              input,
              0,
              0,
              loopPlan.loopCount,
              conditions,
              loops,
              valuePlan.valueCount,
              values,
              1,
              symbolOwners,
              symbolStarts,
              symbolLengths,
              symbolTypes,
              symbolValues,
              symbolResolved,
              resolvedConditions,
              resolvedLoops
            );
            if (resolvedPlan.valid) {
              resolvedValid = 1;
            }
            DirectStatementPlan directPlan = materializeDirectStatementProducts(
              input,
              loopPlan.statementCount,
              statements,
              valuePlan.valueCount,
              values,
              callableReturnLocals,
              directRows,
              directTypes,
              directCode
            );
            if (directPlan.valid) {
              directValid = 1;
            }
            LoopInstructionProductPlan codePlan = writeLoopInstructionProducts(
              resolvedPlan.loopCount,
              resolvedConditions,
              resolvedLoops,
              loopPlan.statementCount,
              statements,
              blockPlan.blockCount,
              blocks,
              bodyPlan.bodyCount,
              bodyRows,
              bodyPlan.nestedCount,
              nestedRows,
              loopLocalBases,
              loopInstructionStarts,
              loopWindowRows,
              output
            );
            if (codePlan.valid) {
              codeValid = 1;
            }
            LoopLocalTypePlan typePlan = materializeLoopLocalTypeProducts(
              resolvedPlan.loopCount,
              resolvedLoops,
              loopPlan.statementCount,
              statements,
              bodyPlan.bodyCount,
              bodyRows,
              bodyPlan.nestedCount,
              nestedRows,
              loopLocalBases,
              typeRows
            );
            if (typePlan.valid) {
              typesValid = 1;
            }
            CallableSourceCompositionPlan compositionPlan = composeCallableSourceProducts(
              2,
              loopPlan.statementCount,
              statements,
              directPlan.productCount,
              directRows,
              directCode,
              resolvedPlan.loopCount,
              resolvedLoops,
              loopWindowRows,
              output,
              9,
              signatureTypes,
              directPlan.typeCount,
              directTypes,
              typePlan.typeCount,
              typeRows,
              composedCallables,
              composedTypes,
              composedCode
            );
            if (compositionPlan.valid) {
              compositionValid = 1;
            }
            SourceProductArtifactPlan artifactPlan = publishClassicalSourceModuleArtifact(
              2,
              composedCallables,
              parameterCounts,
              functionNameIds,
              compositionPlan.typeCount,
              composedTypes,
              composedCode,
              compositionPlan.length,
              strings,
              /* stringBytes= */ 122,
              /* stringCount= */ 4,
              stringStarts,
              stringLengths,
              artifact,
              identity
            );
            if (0 < artifactPlan.length) {
              artifactValid = 1;
            }
            CompiledBodyArchivePlan archivePlan = appendCompiledBodyArtifact(
              artifact,
              artifactPlan.length,
              /* moduleOwner= */ 0,
              /* artifactCount= */ 0,
              /* archiveBytes= */ 0,
              modulePublished,
              moduleArtifactRanks,
              artifactStarts,
              artifactLengths,
              bodyArchive
            );
            if (archivePlan.artifactCount == 1) {
              archivedArtifactCount = archivePlan.artifactCount;
              archivedArtifactBytes = archivePlan.archiveBytes;
            }
            if (blockPlan.valid) {
              if (loopPlan.valid) {
                if (valuePlan.valid) {
                  if (bodyPlan.valid) {
                    if (resolvedPlan.valid) {
                      if (codePlan.valid) {
                        if (typePlan.valid) {
                          if (directPlan.valid) {
                            if (compositionPlan.valid) {
                              if (0 < artifactPlan.length) {
                                valid = 1;
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            statementCount = loopPlan.statementCount;
            blockCount = blockPlan.blockCount;
            loopCount = loopPlan.loopCount;
            valueCount = valuePlan.valueCount;
            firstProductLocalCount = functionLocalCounts[0];
            secondProductLocalCount = functionLocalCounts[1];
            kindLocal = values[3078];
            emitLocal = values[3079];
            secondReadLocal = values[3085];
            secondWriteLocal = values[3086];
            bodyFailure = bodyPlan.failureStatement;
            bodyCount = bodyPlan.bodyCount;
            nestedCount = bodyPlan.nestedCount;
            firstLimit = resolvedLoops[1024];
            secondLimit = resolvedLoops[1025];
            firstLoopOwner = loops[0];
            secondLoopOwner = loops[1];
            instructionCount = codePlan.instructionCount;
            codeLength = codePlan.length;
            typeCount = typePlan.typeCount;
            directInstructionCount = directPlan.instructionCount;
            directLength = directPlan.length;
            directTypeCount = directPlan.typeCount;
            composedInstructionCount = compositionPlan.instructionCount;
            composedLength = compositionPlan.length;
            composedTypeCount = compositionPlan.typeCount;
            artifactLength = artifactPlan.length;
            long type = 0;
            long outputCursor = codePlan.length;
            while (type < typePlan.typeCount) limit 4096 {
              setByte(output, outputCursor, typeRows[type]);
              setByte(output, outputCursor + 1, typeRows[4096 + type]);
              setByte(output, outputCursor + 2, typeRows[8192 + type]);
              outputCursor += 3;
              type += 1;
            }
            directOutputStart = outputCursor;
            long directByte = 0;
            while (directByte < directPlan.length) limit 262144 {
              setByte(output, outputCursor, directCode[directByte]);
              outputCursor += 1;
              directByte += 1;
            }
            directTypeOutputStart = outputCursor;
            long directType = 0;
            while (directType < directPlan.typeCount) limit 4096 {
              setByte(output, outputCursor, directTypes[directType]);
              setByte(output, outputCursor + 1, directTypes[4096 + directType]);
              setByte(output, outputCursor + 2, directTypes[8192 + directType]);
              outputCursor += 3;
              directType += 1;
            }
            composedOutputStart = outputCursor;
            long composedByte = 0;
            while (composedByte < compositionPlan.length) limit 262144 {
              setByte(output, outputCursor, composedCode[composedByte]);
              outputCursor += 1;
              composedByte += 1;
            }
            composedTypeOutputStart = outputCursor;
            long composedType = 0;
            while (composedType < compositionPlan.typeCount) limit 4096 {
              setByte(output, outputCursor, composedTypes[composedType]);
              setByte(output, outputCursor + 1, composedTypes[4096 + composedType]);
              setByte(output, outputCursor + 2, composedTypes[8192 + composedType]);
              outputCursor += 3;
              composedType += 1;
            }
            artifactOutputStart = outputCursor;
            long artifactByte = 0;
            while (artifactByte < artifactPlan.length) limit 32768 {
              setByte(output, outputCursor, artifact[artifactByte]);
              outputCursor += 1;
              artifactByte += 1;
            }
            setOutputLength(output, outputCursor);
            drop(unused);
            drop(bodyArchive);
            drop(artifactLengths);
            drop(artifactStarts);
            drop(moduleArtifactRanks);
            drop(modulePublished);
            drop(identity);
            drop(artifact);
            drop(functionNameIds);
            drop(parameterCounts);
            drop(stringLengths);
            drop(stringStarts);
            drop(strings);
            drop(composedCode);
            drop(composedTypes);
            drop(composedCallables);
            drop(signatureTypes);
            drop(directCode);
            drop(directTypes);
            drop(directRows);
            drop(callableReturnLocals);
            drop(typeRows);
            drop(loopWindowRows);
            drop(loopInstructionStarts);
            drop(loopLocalBases);
            drop(symbolResolved);
            drop(symbolValues);
            drop(symbolTypes);
            drop(symbolLengths);
            drop(symbolStarts);
            drop(symbolOwners);
            drop(resolvedLoops);
            drop(resolvedConditions);
            drop(nestedRows);
            drop(bodyRows);
            drop(functionLocalCounts);
            drop(values);
            drop(loops);
            drop(conditions);
            drop(statements);
            drop(blocks);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(products);
          }
        }
        """.formatted(firstBody, firstLength, secondBody, secondLength, limitName));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.core_parsing_source_products");
  }

  private static long unsigned(byte[] bytes, int offset, int width) {
    long value = 0;
    for (int index = width - 1; index >= 0; index--) {
      value = value * 256 + Byte.toUnsignedInt(bytes[offset + index]);
    }
    return value;
  }

  private static int matchingClose(String source, int open) {
    int depth = 0;
    for (int cursor = open; cursor < source.length(); cursor++) {
      if (source.charAt(cursor) == '{') {
        depth += 1;
      }
      if (source.charAt(cursor) == '}') {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }
    }
    throw new IllegalArgumentException("unbalanced source");
  }
}
