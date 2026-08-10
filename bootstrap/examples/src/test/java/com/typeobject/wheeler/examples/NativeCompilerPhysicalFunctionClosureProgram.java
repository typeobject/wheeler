package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import java.io.IOException;
import java.util.LinkedHashMap;

/** Builds counted closure function windows from archived physical module products. */
final class NativeCompilerPhysicalFunctionClosureProgram {
  private NativeCompilerPhysicalFunctionClosureProgram() {}

  static Program program(int artifactCount) throws IOException {
    LinkedHashMap<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.counted_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_callable_stubs"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.linked_instruction_code"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.opcodes"));
    sources.put("PhysicalFunctionClosure.w", """
        module example.physical_function_closure;

        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.counted_function_products;
        import wheeler.compiler.closure.imported_callable_stubs;
        import wheeler.compiler.closure.linked_instruction_code;
        import wheeler.compiler.opcodes;
        import wheeler.core.encoding.binary;

        classical class PhysicalFunctionClosure {
          state long published = 0;
          state long productCount = 0;
          state long functionCount = 0;
          state long instructionCount = 0;
          state long validatedRelocationCount = 0;
          state long unresolvedTargetCount = 0;
          state long relocatedTargetCount = 0;
          state long linkedCodeLength = 0;

          private boolean callOpcode(long opcode) {
            boolean call = opcode == OPCODE_CALL;
            if (opcode == OPCODE_UNCALL) {
              call = true;
            }
            if (opcode == OPCODE_CALL_VALUE) {
              call = true;
            }
            if (opcode == OPCODE_CALL_VOID) {
              call = true;
            }
            if (opcode == OPCODE_CALL_RESULT_SLOT) {
              call = true;
            }
            if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
              call = true;
            }
            return call;
          }

          entry void main(borrow byteview input, borrow mut bytes output) {
            assert(bufferLength(input) < 16777217);
            assert(ARTIFACT_COUNT * 6 < bufferLength(input) + 1);
            region products = new region(/* bytes= */ 11141120, /* allocations= */ 13);
            bytes artifact = allocateBytes(products, /* length= */ 1048576);
            words localFunctionRows = allocate(products, /* length= */ 640);
            words localInstructionRows = allocate(products, /* length= */ 24576);
            words moduleFirstFunctions = allocate(products, /* length= */ 512);
            words moduleFunctionCounts = allocate(products, /* length= */ 512);
            words moduleLocalFunctionCounts = allocate(products, /* length= */ 512);
            words closureFunctionRows = allocate(products, /* length= */ 49152);
            words closureInstructionRows = allocate(products, /* length= */ 917504);
            words productFirstInstructions = allocate(products, /* length= */ 512);
            words productInstructionCounts = allocate(products, /* length= */ 512);
            words artifactStarts = allocate(products, /* length= */ 512);
            words artifactLengths = allocate(products, /* length= */ 512);
            words resolvedCallTargets = allocate(products, /* length= */ 131072);
            long relocationCount = input[bufferLength(input) - 2] * 256
              + input[bufferLength(input) - 1];
            assert(relocationCount < 2049);
            long metadata = bufferLength(input)
              - ARTIFACT_COUNT * 6
              - relocationCount * 6
              - 2;
            long artifactStart = 0;
            long product = 0;
            while (product < ARTIFACT_COUNT) limit 512 {
              long metadataStart = metadata + product * 6;
              long owner = input[metadataStart] * 256 + input[metadataStart + 1];
              long artifactLength = input[metadataStart + 2] * 65536
                + input[metadataStart + 3] * 256
                + input[metadataStart + 4];
              long localFunctionCount = input[metadataStart + 5];
              assert(-1 < owner);
              assert(owner < 512);
              assert(-1 < artifactLength);
              assert(artifactLength < bufferLength(artifact) + 1);
              assert(artifactStart + artifactLength < metadata + 1);
              set(artifactStarts, product, artifactStart);
              set(artifactLengths, product, artifactLength);
              set(moduleLocalFunctionCounts, owner, localFunctionCount);
              long artifactByte = 0;
              while (artifactByte < artifactLength) limit 1048576 {
                setByte(artifact, artifactByte, input[artifactStart + artifactByte]);
                artifactByte += 1;
              }
              CompiledFunctionPlan decoded = indexCompiledFunctionProducts(
                artifact,
                artifactLength,
                localFunctionRows,
                localInstructionRows
              );
              if (0 < localFunctionCount) {
                RetainedFunctionProduct retained = retainLocalFunctionProduct(
                  localFunctionCount,
                  decoded.functionCount,
                  decoded.instructionCount,
                  localInstructionRows
                );
                CountedFunctionWindow window = appendFunctionProduct(
                  owner,
                  product,
                  retained.functionCount,
                  retained.instructionCount,
                  localFunctionRows,
                  localInstructionRows,
                  functionCount,
                  instructionCount,
                  moduleFirstFunctions,
                  moduleFunctionCounts,
                  closureFunctionRows,
                  closureInstructionRows
                );
                assert(window.firstFunction == functionCount);
                assert(window.firstInstruction == instructionCount);
                set(productFirstInstructions, product, window.firstInstruction);
                set(productInstructionCounts, product, window.instructionCount);
                functionCount += window.functionCount;
                instructionCount += window.instructionCount;
                productCount += 1;
              }
              artifactStart += artifactLength;
              product += 1;
            }
            assert(artifactStart == metadata);
            long relocationStart = metadata + ARTIFACT_COUNT * 6;
            long relocation = 0;
            long previousClosureInstruction = -1;
            while (relocation < relocationCount) limit 2048 {
              long frame = relocationStart + relocation * 6;
              long relocationProduct = input[frame];
              long localInstruction = input[frame + 1] * 256 + input[frame + 2];
              long targetOwner = input[frame + 3] * 256 + input[frame + 4];
              long targetLocal = input[frame + 5];
              assert(relocationProduct < ARTIFACT_COUNT);
              assert(localInstruction < productInstructionCounts[relocationProduct]);
              assert(targetOwner < 512);
              assert(targetLocal < moduleLocalFunctionCounts[targetOwner]);
              long closureInstruction = productFirstInstructions[relocationProduct]
                + localInstruction;
              assert(previousClosureInstruction < closureInstruction);
              previousClosureInstruction = closureInstruction;
              assert(callOpcode(closureInstructionRows[524288 + closureInstruction]));
              long caller = closureInstructionRows[closureInstruction];
              long callerOwner = closureFunctionRows[caller];
              long callerArtifact = closureInstructionRows[262144 + closureInstruction];
              long callerStart = artifactStarts[callerArtifact]
                + closureInstructionRows[393216 + closureInstruction];
              long unresolvedTarget = readUnsigned(input, callerStart + 8, 8);
              assert(moduleLocalFunctionCounts[callerOwner] < unresolvedTarget + 1);
              relocation += 1;
            }
            validatedRelocationCount = relocation;
            long unresolvedCallCount = 0;
            long instruction = 0;
            while (instruction < instructionCount) limit 131072 {
              if (callOpcode(closureInstructionRows[524288 + instruction])) {
                long localCaller = closureInstructionRows[instruction];
                long localOwner = closureFunctionRows[localCaller];
                long localArtifact = closureInstructionRows[262144 + instruction];
                long localStart = artifactStarts[localArtifact]
                  + closureInstructionRows[393216 + instruction];
                long localTarget = readUnsigned(input, localStart + 8, 8);
                if (moduleLocalFunctionCounts[localOwner] < localTarget + 1) {
                  unresolvedCallCount += 1;
                }
              }
              instruction += 1;
            }
            unresolvedTargetCount = unresolvedCallCount;
            assert(unresolvedCallCount == relocationCount);
            instruction = 0;
            while (instruction < instructionCount) limit 131072 {
              if (callOpcode(closureInstructionRows[524288 + instruction])) {
                long selectedCaller = closureInstructionRows[instruction];
                long selectedCallerOwner = closureFunctionRows[selectedCaller];
                long selectedArtifact = closureInstructionRows[262144 + instruction];
                long selectedStart = artifactStarts[selectedArtifact]
                  + closureInstructionRows[393216 + instruction];
                long selectedLocalTarget = readUnsigned(input, selectedStart + 8, 8);
                if (selectedLocalTarget < moduleLocalFunctionCounts[selectedCallerOwner]) {
                  set(
                    resolvedCallTargets,
                    instruction,
                    moduleFirstFunctions[selectedCallerOwner] + selectedLocalTarget
                  );
                }
              }
              instruction += 1;
            }
            relocation = 0;
            while (relocation < relocationCount) limit 2048 {
              long selectedFrame = relocationStart + relocation * 6;
              long selectedProduct = input[selectedFrame];
              long selectedInstruction = input[selectedFrame + 1] * 256
                + input[selectedFrame + 2];
              long selectedOwner = input[selectedFrame + 3] * 256
                + input[selectedFrame + 4];
              long selectedLocal = input[selectedFrame + 5];
              long selectedClosureInstruction = productFirstInstructions[selectedProduct]
                + selectedInstruction;
              long selectedTarget = moduleFirstFunctions[selectedOwner] + selectedLocal;
              set(resolvedCallTargets, selectedClosureInstruction, selectedTarget);
              relocation += 1;
            }
            relocatedTargetCount = relocation;
            linkedCodeLength = emitResolvedLinkedInstructionCodeAt(
              input,
              metadata,
              artifactStarts,
              artifactLengths,
              functionCount,
              instructionCount,
              closureInstructionRows,
              resolvedCallTargets,
              output,
              /* outputStart= */ 0
            );
            assert(relocatedTargetCount == relocationCount);
            published = 1;
            setOutputLength(output, linkedCodeLength);
            drop(resolvedCallTargets);
            drop(artifactLengths);
            drop(artifactStarts);
            drop(productInstructionCounts);
            drop(productFirstInstructions);
            drop(closureInstructionRows);
            drop(closureFunctionRows);
            drop(moduleLocalFunctionCounts);
            drop(moduleFunctionCounts);
            drop(moduleFirstFunctions);
            drop(localInstructionRows);
            drop(localFunctionRows);
            drop(artifact);
            drop(products);
          }
        }
        """.replace("ARTIFACT_COUNT", Integer.toString(artifactCount)));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.physical_function_closure");
  }
}
