package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for compiling imported primitive signatures without dependency bodies. */
final class NativeCompilerImportedCallableStubsExampleTest {
  @Test
  void compilesCallsAgainstSignatureOnlyRecursiveStubs() throws Exception {
    String localSignature = "public long run(long value) ";
    String localBody = "{ return helper(value); }";
    String importedSignature = "public long helper(long value)";
    byte[] input = (localSignature + localBody + importedSignature)
        .getBytes(StandardCharsets.US_ASCII);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(localSignature, localBody, importedSignature), input, 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("retainedFunctionCount"));
    assertEquals(2, machine.global("excludedFunctionCount"));
    Program product = new BytecodeReader().read(machine.hostOutput());
    assertEquals(3, product.functions().size());
    FunctionBody run = product.functions().stream()
        .filter(function -> function.name().endsWith("::run"))
        .findFirst()
        .orElseThrow();
    FunctionBody helper = product.functions().stream()
        .filter(function -> function.name().endsWith("::helper"))
        .findFirst()
        .orElseThrow();
    Instruction importedCall = run.forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.CALL_VALUE)
        .findFirst()
        .orElseThrow();
    assertEquals(helper.id(), importedCall.operands().get(0));
    Instruction stubCall = helper.forward().stream()
        .filter(instruction -> instruction.opcode() == Opcode.CALL_VALUE)
        .findFirst()
        .orElseThrow();
    assertEquals(helper.id(), stubCall.operands().get(0));
  }

  private static Program program(
      String localSignature, String localBody, String importedSignature) throws Exception {
    int localBodyStart = localSignature.length();
    int importedSignatureStart = localBodyStart + localBody.length();
    int importedNameStart = importedSignatureStart + importedSignature.indexOf("helper");
    int importedResultStart = importedSignatureStart + importedSignature.indexOf("long");
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_callable_bodies"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_callable_stubs"));
    sources.put("ImportedCallableStubsExample.w", """
        module example.imported_callable_stubs;

        import wheeler.compiler.closure.compiled_callable_bodies;
        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.imported_callable_stubs;

        classical class ImportedCallableStubsExample {
          state long retainedFunctionCount = 0;
          state long excludedFunctionCount = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 537632, /* allocations= */ 14);
            words calls = allocate(rows, /* length= */ 1024);
            words owners = allocate(rows, /* length= */ 4096);
            words signatureStarts = allocate(rows, /* length= */ 4096);
            words signatureLengths = allocate(rows, /* length= */ 4096);
            words bodyStarts = allocate(rows, /* length= */ 4096);
            words bodyLengths = allocate(rows, /* length= */ 4096);
            words nameStarts = allocate(rows, /* length= */ 4096);
            words nameLengths = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words resultStarts = allocate(rows, /* length= */ 4096);
            words resultLengths = allocate(rows, /* length= */ 4096);
            words functionRows = allocate(rows, /* length= */ 640);
            words instructionRows = allocate(rows, /* length= */ 24576);
            bytes identity = allocateBytes(rows, /* length= */ 32);
            set(calls, 768, 1);
            set(owners, 0, 0);
            set(signatureStarts, 0, 0);
            set(signatureLengths, 0, %d);
            set(bodyStarts, 0, %d);
            set(bodyLengths, 0, %d);
            set(signatureStarts, 1, %d);
            set(signatureLengths, 1, %d);
            set(nameStarts, 1, %d);
            set(nameLengths, 1, 6);
            set(parameterCounts, 0, 1);
            set(parameterCounts, 1, 1);
            set(resultStarts, 1, %d);
            set(resultLengths, 1, 4);
            CompiledCallableBody compiled = compileCallableModuleProductWithImports(
              input,
              /* owner= */ 0,
              /* firstCallable= */ 0,
              /* callableCount= */ 1,
              owners,
              signatureStarts,
              signatureLengths,
              bodyStarts,
              bodyLengths,
              /* callCount= */ 1,
              calls,
              nameStarts,
              nameLengths,
              parameterCounts,
              resultStarts,
              resultLengths,
              output,
              identity
            );
            CompiledFunctionPlan functions = indexCompiledFunctionProducts(
              output,
              compiled.length,
              functionRows,
              instructionRows
            );
            RetainedFunctionProduct retained = retainLocalFunctionProduct(
              /* localFunctionCount= */ 1,
              functions.functionCount,
              functions.instructionCount,
              instructionRows
            );
            retainedFunctionCount = retained.functionCount;
            excludedFunctionCount = retained.excludedFunctionCount;
            setOutputLength(output, compiled.length);
            drop(identity);
            drop(instructionRows);
            drop(functionRows);
            drop(resultLengths);
            drop(resultStarts);
            drop(parameterCounts);
            drop(nameLengths);
            drop(nameStarts);
            drop(bodyLengths);
            drop(bodyStarts);
            drop(signatureLengths);
            drop(signatureStarts);
            drop(owners);
            drop(calls);
            drop(rows);
          }
        }
        """.formatted(
          localSignature.length(),
          localBodyStart,
          localBody.length(),
          importedSignatureStart,
          importedSignature.length(),
          importedNameStart,
          importedResultStart
        ));
    return new WheelerCompiler().compileModuleFiles(sources, "example.imported_callable_stubs");
  }
}
