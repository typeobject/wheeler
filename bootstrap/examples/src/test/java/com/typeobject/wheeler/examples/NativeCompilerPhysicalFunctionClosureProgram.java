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
    sources.put("PhysicalFunctionClosure.w", """
        module example.physical_function_closure;

        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.counted_function_products;
        import wheeler.compiler.closure.imported_callable_stubs;

        classical class PhysicalFunctionClosure {
          state long published = 0;
          state long productCount = 0;
          state long functionCount = 0;
          state long instructionCount = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            assert(bufferLength(input) < 16777217);
            assert(ARTIFACT_COUNT * 6 < bufferLength(input) + 1);
            region products = new region(/* bytes= */ 10027008, /* allocations= */ 7);
            bytes artifact = allocateBytes(products, /* length= */ 1048576);
            words localFunctionRows = allocate(products, /* length= */ 640);
            words localInstructionRows = allocate(products, /* length= */ 24576);
            words moduleFirstFunctions = allocate(products, /* length= */ 512);
            words moduleFunctionCounts = allocate(products, /* length= */ 512);
            words closureFunctionRows = allocate(products, /* length= */ 49152);
            words closureInstructionRows = allocate(products, /* length= */ 917504);
            long metadata = bufferLength(input) - ARTIFACT_COUNT * 6;
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
                functionCount += window.functionCount;
                instructionCount += window.instructionCount;
                productCount += 1;
              }
              artifactStart += artifactLength;
              product += 1;
            }
            assert(artifactStart == metadata);
            published = 1;
            setByte(output, 0, 1);
            drop(closureInstructionRows);
            drop(closureFunctionRows);
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
