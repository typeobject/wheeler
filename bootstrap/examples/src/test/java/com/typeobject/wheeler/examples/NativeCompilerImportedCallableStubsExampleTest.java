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
    String local = """
        classical class Root {
          public long run(long value) {
            return helper(value);
          }
        }
        """;
    String signature = "public long helper(long value)";
    byte[] input = (local + signature).getBytes(StandardCharsets.US_ASCII);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(local.length(), signature), input, 1_048_576);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("retainedFunctionCount"));
    assertEquals(2, machine.global("excludedFunctionCount"));
    Program product = new BytecodeReader().read(machine.hostOutput());
    assertEquals(3, product.functions().size());
    FunctionBody run = product.functions().stream()
        .filter(function -> function.name().equals("run"))
        .findFirst()
        .orElseThrow();
    FunctionBody helper = product.functions().stream()
        .filter(function -> function.name().equals("helper"))
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

  private static Program program(int localLength, String signature) throws Exception {
    int signatureStart = localLength;
    int nameStart = signatureStart + signature.indexOf("helper");
    int resultStart = signatureStart + signature.indexOf("long");
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_callable_stubs"));
    sources.putAll(CompilerSources.moduleClosure("wheeler.compiler.compiler_core"));
    sources.put("ImportedCallableStubsExample.w", """
        module example.imported_callable_stubs;

        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.imported_callable_stubs;
        import wheeler.compiler.compiler_core;

        classical class ImportedCallableStubsExample {
          state long retainedFunctionCount = 0;
          state long excludedFunctionCount = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 439296, /* allocations= */ 10);
            words calls = allocate(rows, /* length= */ 1024);
            words signatureStarts = allocate(rows, /* length= */ 4096);
            words signatureLengths = allocate(rows, /* length= */ 4096);
            words nameStarts = allocate(rows, /* length= */ 4096);
            words nameLengths = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words resultStarts = allocate(rows, /* length= */ 4096);
            words resultLengths = allocate(rows, /* length= */ 4096);
            words functionRows = allocate(rows, /* length= */ 640);
            words instructionRows = allocate(rows, /* length= */ 24576);
            set(calls, 768, 0);
            set(signatureStarts, 0, %d);
            set(signatureLengths, 0, %d);
            set(nameStarts, 0, %d);
            set(nameLengths, 0, 6);
            set(parameterCounts, 0, 1);
            set(resultStarts, 0, %d);
            set(resultLengths, 0, 4);
            region productArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
            bytes productSource = allocateBytes(productArena, /* length= */ 32768);
            ImportedCallableStubPlan product = writeImportedCallableStubs(
              input,
              /* sourceStart= */ 0,
              /* sourceLength= */ %d,
              /* callCount= */ 1,
              calls,
              signatureStarts,
              signatureLengths,
              nameStarts,
              nameLengths,
              parameterCounts,
              resultStarts,
              resultLengths,
              productSource
            );
            assert(product.stubCount == 1);
            region exactArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
            bytes exactSource = allocateBytes(exactArena, product.length);
            long sourceByte = 0;
            while (sourceByte < product.length) limit 32768 {
              setByte(exactSource, sourceByte, productSource[sourceByte]);
              sourceByte += 1;
            }
            utf8 source = freezeUtf8(exactSource);
            CoreCompilation compiled = compileMinimalCore(source, output);
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
            drop(source);
            drop(exactArena);
            drop(productSource);
            drop(productArena);
            drop(instructionRows);
            drop(functionRows);
            drop(resultLengths);
            drop(resultStarts);
            drop(parameterCounts);
            drop(nameLengths);
            drop(nameStarts);
            drop(signatureLengths);
            drop(signatureStarts);
            drop(calls);
            drop(rows);
          }
        }
        """.formatted(
          signatureStart,
          signature.length(),
          nameStart,
          resultStart,
          localLength
        ));
    return new WheelerCompiler().compileModuleFiles(sources, "example.imported_callable_stubs");
  }
}
