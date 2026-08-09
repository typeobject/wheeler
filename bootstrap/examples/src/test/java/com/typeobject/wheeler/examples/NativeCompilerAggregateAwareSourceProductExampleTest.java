package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for aggregate-aware complete source-product compilation. */
final class NativeCompilerAggregateAwareSourceProductExampleTest {
  private static final String SOURCE = """
      classical class Root { private record Local(long value) {} private long use(Box value) { Local item = new Local(7); return 7; } }
      """.strip();

  @Test
  void compilesPrimitiveBodiesAfterNominalValidationWithoutRetainingScaffolding()
      throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(/* importedKind= */ 1), SOURCE.getBytes(StandardCharsets.US_ASCII), 32_768);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("published"));
    assertEquals(2, machine.global("functionCount"));
    assertEquals(1, machine.global("projectionCount"));
    assertEquals(1, machine.global("carrierProjectionCount"));
    assertEquals(9, machine.global("projectionOwner"));
    assertEquals(268_435_457, machine.global("projectionSourceCode"));
    assertEquals(3, machine.global("projectionTarget"));
    assertEquals(9, machine.global("carrierOwner"));
    assertEquals(0, machine.global("carrierFunction"));
    assertEquals(0, machine.global("carrierLocal"));
    assertEquals(3, machine.global("carrierTarget"));
    assertEquals(1, machine.global("localValueCarrierRole"));
    assertEquals(2, machine.global("localConstructorCarrierRole"));
    assertEquals(2, machine.global("localValueCarrierLocal"));
    assertEquals(2, machine.global("localValueProductLocal"));
    assertEquals(SOURCE.indexOf("Local item"), machine.global("firstSourceStatementStart"));
    Program product = new BytecodeReader().read(machine.hostOutput());
    assertEquals(2, product.functions().size());
    assertEquals(0, product.recordTypes().size());
    assertEquals(0, product.variantTypes().size());
  }

  @Test
  void rejectsAKindMismatchBeforeArtifactOrProjectionPublication() throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        program(/* importedKind= */ 4), SOURCE.getBytes(StandardCharsets.US_ASCII), 32_768);

    assertThrows(
        VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  private static Program program(int importedKind) throws Exception {
    int declarationStart = SOURCE.indexOf("private record");
    int declarationEnd = declarationStart
        + "private record Local(long value) {}".length();
    int referenceStart = SOURCE.indexOf("Box");
    int localValueReferenceStart = SOURCE.indexOf("Local item");
    int localConstructorReferenceStart = SOURCE.indexOf("Local(7)");
    int operationStart = SOURCE.indexOf("new Local(7)");
    int callableBodyStart = SOURCE.indexOf("{ Local item");
    int callableBodyEnd = SOURCE.indexOf("}", callableBodyStart) + 1;
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_callable_bodies"));
    sources.put("AggregateAwareSourceProductExample.w", """
        module example.aggregate_aware_source_product;

        import wheeler.compiler.closure.compiled_callable_bodies;

        classical class AggregateAwareSourceProductExample {
          state long published = 0;
          state long functionCount = 0;
          state long projectionCount = 0;
          state long carrierProjectionCount = 0;
          state long projectionOwner = 0;
          state long projectionSourceCode = 0;
          state long projectionTarget = 0;
          state long carrierOwner = 0;
          state long carrierFunction = 0;
          state long carrierLocal = 0;
          state long carrierTarget = 0;
          state long localValueCarrierRole = 0;
          state long localConstructorCarrierRole = 0;
          state long localValueCarrierLocal = 0;
          state long localValueProductLocal = 0;
          state long firstSourceStatementStart = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 2021408, /* allocations= */ 24);
            words localAggregates = allocate(rows, /* length= */ 832);
            words operations = allocate(rows, /* length= */ 2048);
            words localReferences = allocate(rows, /* length= */ 1536);
            words localProjections = allocate(rows, /* length= */ 4096);
            words localCarriers = allocate(rows, /* length= */ 2048);
            words localCallableBodyStarts = allocate(rows, /* length= */ 4096);
            words localCallableBodyLengths = allocate(rows, /* length= */ 4096);
            words localStatements = allocate(rows, /* length= */ 24576);
            words localValues = allocate(rows, /* length= */ 7168);
            words localFunctionLocals = allocate(rows, /* length= */ 64);
            words references = allocate(rows, /* length= */ 256);
            words carrierFunctions = allocate(rows, /* length= */ 64);
            words carrierLocals = allocate(rows, /* length= */ 64);
            words importedAggregates = allocate(rows, /* length= */ 36864);
            words projections = allocate(rows, /* length= */ 49152);
            words carrierProjections = allocate(rows, /* length= */ 65536);
            words calls = allocate(rows, /* length= */ 1024);
            words effects = allocate(rows, /* length= */ 4096);
            words firstParameters = allocate(rows, /* length= */ 4096);
            words parameterCounts = allocate(rows, /* length= */ 4096);
            words resultTypes = allocate(rows, /* length= */ 4096);
            words parameterTypes = allocate(rows, /* length= */ 16384);
            words parameterModes = allocate(rows, /* length= */ 16384);
            bytes identity = allocateBytes(rows, /* length= */ 32);
            set(localCallableBodyStarts, 0, %d);
            set(localCallableBodyLengths, 0, %d);
            set(localAggregates, 0, 1);
            set(localAggregates, 512, %d);
            set(localAggregates, 768, %d);
            set(operations, 0, 1);
            set(operations, 256, %d);
            set(operations, 512, 5);
            set(operations, 1280, %d);
            set(operations, 1536, 12);
            set(localReferences, 0, 0);
            set(localReferences, 1, 0);
            set(localReferences, 512, %d);
            set(localReferences, 513, %d);
            set(localReferences, 1024, 5);
            set(localReferences, 1025, 5);
            set(localProjections, 0, 91);
            set(references, 0, %d);
            set(references, 64, 3);
            set(references, 128, 3);
            set(references, 192, 1);
            set(importedAggregates, 3, %d);
            CompiledCallableBody compiled = compileAggregateSourceModuleProductWithImports(
              input,
              /* sourceStart= */ 0,
              /* sourceLength= */ %d,
              /* aggregateCount= */ 1,
              localAggregates,
              /* operationCount= */ 1,
              operations,
              /* localNominalReferenceCount= */ 2,
              localReferences,
              localProjections,
              localCarriers,
              /* firstLocalCallable= */ 0,
              /* localCallableCount= */ 1,
              localCallableBodyStarts,
              localCallableBodyLengths,
              localStatements,
              localValues,
              localFunctionLocals,
              /* moduleOwner= */ 9,
              /* firstRecordTypeId= */ 1,
              /* firstVariantTypeId= */ 0,
              /* nominalReferenceCount= */ 1,
              references,
              carrierFunctions,
              carrierLocals,
              importedAggregates,
              projections,
              carrierProjections,
              /* callCount= */ 0,
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
            functionCount = compiled.functionCount;
            projectionCount = 1;
            carrierProjectionCount = 1;
            projectionOwner = projections[0];
            projectionSourceCode = projections[16384];
            projectionTarget = projections[32768];
            carrierOwner = carrierProjections[0];
            carrierFunction = carrierProjections[16384];
            carrierLocal = carrierProjections[32768];
            carrierTarget = carrierProjections[49152];
            localValueCarrierRole = localProjections[512];
            localConstructorCarrierRole = localProjections[513];
            localValueCarrierLocal = localProjections[1536];
            localValueProductLocal = localValues[3073];
            firstSourceStatementStart = localStatements[16384];
            published = 1;
            setOutputLength(output, compiled.length);
            drop(identity);
            drop(parameterModes);
            drop(parameterTypes);
            drop(resultTypes);
            drop(parameterCounts);
            drop(firstParameters);
            drop(effects);
            drop(calls);
            drop(carrierProjections);
            drop(projections);
            drop(importedAggregates);
            drop(carrierLocals);
            drop(carrierFunctions);
            drop(references);
            drop(localFunctionLocals);
            drop(localValues);
            drop(localStatements);
            drop(localCallableBodyLengths);
            drop(localCallableBodyStarts);
            drop(localCarriers);
            drop(localProjections);
            drop(localReferences);
            drop(operations);
            drop(localAggregates);
            drop(rows);
          }
        }
        """.formatted(
            callableBodyStart,
            callableBodyEnd - callableBodyStart,
            declarationStart,
            declarationEnd,
            localConstructorReferenceStart,
            operationStart,
            localValueReferenceStart,
            localConstructorReferenceStart,
            referenceStart,
            importedKind,
            SOURCE.length()));
    return new com.typeobject.wheeler.compiler.WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_aware_source_product");
  }
}
