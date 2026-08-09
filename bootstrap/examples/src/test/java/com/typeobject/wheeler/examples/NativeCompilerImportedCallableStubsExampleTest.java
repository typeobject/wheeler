package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for compiling imported primitive signatures without dependency bodies. */
final class NativeCompilerImportedCallableStubsExampleTest {
  @Test
  void compilesCallsAgainstSignatureOnlyRecursiveStubs() throws Exception {
    String localSource = """
        classical class Root {
          public long run(long value) {
            return dependency.helper(value);
          }
        }
        """;
    byte[] input = localSource.getBytes(StandardCharsets.US_ASCII);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(localSource, "long"), input, 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("retainedFunctionCount"));
    assertEquals(2, machine.global("excludedFunctionCount"));
    Program product = new BytecodeReader().read(machine.hostOutput());
    assertEquals(3, product.functions().size());
    FunctionBody run = product.functions().stream()
        .filter(function -> function.name().endsWith("run"))
        .findFirst()
        .orElseThrow();
    FunctionBody helper = product.functions().stream()
        .filter(function -> function.name().endsWith("__wheeler_import_1"))
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

  @Test
  void rejectsGeneratedNameCollisionsBeforePublication() throws Exception {
    String localSource = """
        classical class Root {
          public long __wheeler_import_1(long value) { return value; }
          public long run(long value) { return dependency.helper(value); }
        }
        """;
    byte[] input = localSource.getBytes(StandardCharsets.US_ASCII);
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(localSource, "long"), input, 32_768);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  @Test
  void rejectsUnknownTypeProductsBeforePublication() throws Exception {
    String source = "Mystery";
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(source, source), source.getBytes(StandardCharsets.US_ASCII), 32_768);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
  }

  private static Program program(String localSource, String primitiveType) throws Exception {
    int callStart = localSource.indexOf("dependency.helper");
    int callLength = "dependency.helper".length();
    int primitiveTypeStart = localSource.indexOf(primitiveType);
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.callable_type_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_callable_bodies"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_callable_stubs"));
    sources.put("ImportedCallableStubsExample.w", """
        module example.imported_callable_stubs;

        import wheeler.compiler.closure.callable_type_products;
        import wheeler.compiler.closure.compiled_callable_bodies;
        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.imported_callable_stubs;

        classical class ImportedCallableStubsExample {
          state long retainedFunctionCount = 0;
          state long excludedFunctionCount = 0;
          state long published = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 930848, /* allocations= */ 14);
            words calls = allocate(rows, /* length= */ 1024);
            words effects = allocate(rows, /* length= */ 4096);
            words firstParameters = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words resultStarts = allocate(rows, /* length= */ 4096);
            words resultLengths = allocate(rows, /* length= */ 4096);
            words parameterStarts = allocate(rows, /* length= */ 16384);
            words parameterLengths = allocate(rows, /* length= */ 16384);
            words resultTypes = allocate(rows, /* length= */ 4096);
            words parameterTypes = allocate(rows, /* length= */ 16384);
            words parameterModes = allocate(rows, /* length= */ 16384);
            words functionRows = allocate(rows, /* length= */ 640);
            words instructionRows = allocate(rows, /* length= */ 24576);
            bytes identity = allocateBytes(rows, /* length= */ 32);
            set(calls, 0, %d);
            set(calls, 256, %d);
            set(calls, 768, 1);
            set(firstParameters, 1, 1);
            set(parameterCounts, 0, 1);
            set(parameterCounts, 1, 1);
            set(resultStarts, 0, %d);
            set(resultStarts, 1, %d);
            set(resultLengths, 0, 4);
            set(resultLengths, 1, 4);
            set(parameterStarts, 0, %d);
            set(parameterStarts, 1, %d);
            set(parameterLengths, 0, 4);
            set(parameterLengths, 1, 4);
            CallableTypeProductPlan types = materializePrimitiveCallableTypes(
              input,
              /* callableCount= */ 2,
              /* parameterCount= */ 2,
              resultStarts,
              resultLengths,
              firstParameters,
              parameterCounts,
              parameterStarts,
              parameterLengths,
              parameterModes,
              resultTypes,
              parameterTypes
            );
            assert(types.valid);
            CompiledCallableBody compiled = compileSourceModuleProductWithImports(
              input,
              /* sourceStart= */ 0,
              /* sourceLength= */ %d,
              /* callCount= */ 1,
              calls,
              effects,
              firstParameters,
              parameterCounts,
              resultTypes,
              parameterTypes,
              parameterModes,
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
            published = 1;
            setOutputLength(output, compiled.length);
            drop(identity);
            drop(instructionRows);
            drop(functionRows);
            drop(parameterModes);
            drop(parameterTypes);
            drop(resultTypes);
            drop(parameterLengths);
            drop(parameterStarts);
            drop(resultLengths);
            drop(resultStarts);
            drop(parameterCounts);
            drop(firstParameters);
            drop(effects);
            drop(calls);
            drop(rows);
          }
        }
        """.formatted(
          callStart,
          callLength,
          primitiveTypeStart,
          primitiveTypeStart,
          primitiveTypeStart,
          primitiveTypeStart,
          localSource.length()
        ));
    return new WheelerCompiler().compileModuleFiles(sources, "example.imported_callable_stubs");
  }
}
