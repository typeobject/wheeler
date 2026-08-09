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
      classical class Root { private record Local(long value) {} private long use(Box value, long number) { Local item = new Local(number); long extracted = item.value; return 7; } }
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
    assertEquals(3, machine.global("localValueCarrierLocal"));
    assertEquals(3, machine.global("localValueProductLocal"));
    assertEquals(3, machine.global("derivedDestinationLocal"));
    assertEquals(1, machine.global("derivedArgumentLocal"));
    assertEquals(0, machine.global("derivedOperationFunction"));
    assertEquals(2, machine.global("secondOperationOrdinal"));
    assertEquals(0, machine.global("derivedConstructorTarget"));
    assertEquals(0, machine.global("derivedProjectionTarget"));
    assertEquals(2, machine.global("supplementalInstructionCount"));
    assertEquals(72, machine.global("supplementalLength"));
    assertEquals(5, machine.global("composedInstructionCount"));
    assertEquals(1, machine.global("firstArtifactSelector"));
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
    int localAggregateNameStart = SOURCE.indexOf("Local(long");
    int localMemberNameStart = SOURCE.indexOf("value)");
    int declarationEnd = declarationStart
        + "private record Local(long value) {}".length();
    int referenceStart = SOURCE.indexOf("Box");
    int localValueReferenceStart = SOURCE.indexOf("Local item");
    int localConstructorReferenceStart = SOURCE.indexOf("Local(number)");
    int operationStart = SOURCE.indexOf("new Local(number)");
    int argumentStart = SOURCE.indexOf("number)", operationStart);
    int projectionOwnerStart = SOURCE.indexOf("item.value");
    int projectionMemberStart = projectionOwnerStart + "item.".length();
    int callableBodyStart = SOURCE.indexOf("{ Local item");
    int callableBodyEnd = SOURCE.indexOf("}", callableBodyStart) + 1;
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.aggregate_compiled_callable_bodies"));
    sources.put("AggregateAwareSourceProductExample.w", """
        module example.aggregate_aware_source_product;

        import wheeler.compiler.closure.aggregate_compiled_callable_bodies;

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
          state long derivedDestinationLocal = 0;
          state long derivedArgumentLocal = 0;
          state long derivedOperationFunction = 0;
          state long secondOperationOrdinal = -1;
          state long derivedConstructorTarget = -1;
          state long derivedProjectionTarget = -1;
          state long supplementalInstructionCount = 0;
          state long supplementalLength = 0;
          state long composedInstructionCount = 0;
          state long firstArtifactSelector = -1;
          state long firstSourceStatementStart = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 2367520, /* allocations= */ 38);
            words localAggregates = allocate(rows, /* length= */ 832);
            words localCases = allocate(rows, /* length= */ 640);
            words localMembers = allocate(rows, /* length= */ 2048);
            words operations = allocate(rows, /* length= */ 2048);
            words arguments = allocate(rows, /* length= */ 4096);
            words localReferences = allocate(rows, /* length= */ 1536);
            words localProjections = allocate(rows, /* length= */ 4096);
            words localCarriers = allocate(rows, /* length= */ 2048);
            words localCallableBodyStarts = allocate(rows, /* length= */ 4096);
            words localCallableBodyLengths = allocate(rows, /* length= */ 4096);
            words localStatements = allocate(rows, /* length= */ 24576);
            words localValues = allocate(rows, /* length= */ 7168);
            words localFunctionLocals = allocate(rows, /* length= */ 64);
            words localDestinations = allocate(rows, /* length= */ 256);
            words localOwners = allocate(rows, /* length= */ 256);
            words localArgumentLocals = allocate(rows, /* length= */ 1024);
            words localPlacements = allocate(rows, /* length= */ 768);
            words localConstructorTargets = allocate(rows, /* length= */ 768);
            words localProjectionTargets = allocate(rows, /* length= */ 1024);
            words localResolvedOperations = allocate(rows, /* length= */ 1536);
            bytes supplementalCode = allocateBytes(rows, /* length= */ 12288);
            words composedFunctions = allocate(rows, /* length= */ 640);
            words composedInstructions = allocate(rows, /* length= */ 24576);
            words artifactSelectors = allocate(rows, /* length= */ 4096);
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
            set(localAggregates, 64, %d);
            set(localAggregates, 128, 5);
            set(localAggregates, 320, 0);
            set(localAggregates, 384, 1);
            set(localAggregates, 512, %d);
            set(localAggregates, 768, %d);
            set(localMembers, 0, 0);
            set(localMembers, 256, -1);
            set(localMembers, 512, %d);
            set(localMembers, 768, 5);
            set(operations, 0, 1);
            set(operations, 1, 3);
            set(operations, 256, %d);
            set(operations, 512, 5);
            set(operations, 257, %d);
            set(operations, 513, 4);
            set(operations, 769, %d);
            set(operations, 1025, 5);
            set(operations, 1280, %d);
            set(operations, 1536, 17);
            set(operations, 1281, %d);
            set(operations, 1537, 10);
            set(operations, 1793, 1);
            set(arguments, 0, 0);
            set(arguments, 1024, 0);
            set(arguments, 2048, %d);
            set(arguments, 3072, 6);
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
            AggregateCompiledCallableBody compiled = compileAggregateSourceModuleProductWithImports(
              input,
              /* sourceStart= */ 0,
              /* sourceLength= */ %d,
              /* aggregateCount= */ 1,
              localAggregates,
              /* localCaseCount= */ 0,
              localCases,
              /* localMemberCount= */ 1,
              localMembers,
              /* operationCount= */ 2,
              operations,
              /* argumentCount= */ 1,
              arguments,
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
              localDestinations,
              localOwners,
              localArgumentLocals,
              localPlacements,
              localConstructorTargets,
              localProjectionTargets,
              localResolvedOperations,
              supplementalCode,
              composedFunctions,
              composedInstructions,
              artifactSelectors,
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
            localValueProductLocal = localValues[3074];
            derivedDestinationLocal = localDestinations[0];
            derivedArgumentLocal = localArgumentLocals[0];
            derivedOperationFunction = localPlacements[0];
            secondOperationOrdinal = localPlacements[513];
            derivedConstructorTarget = localConstructorTargets[256];
            derivedProjectionTarget = localProjectionTargets[769];
            supplementalInstructionCount = compiled.supplementalInstructionCount;
            supplementalLength = compiled.supplementalLength;
            composedInstructionCount = compiled.composedInstructionCount;
            firstArtifactSelector = artifactSelectors[0];
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
            drop(artifactSelectors);
            drop(composedInstructions);
            drop(composedFunctions);
            drop(supplementalCode);
            drop(localResolvedOperations);
            drop(localProjectionTargets);
            drop(localConstructorTargets);
            drop(localPlacements);
            drop(localArgumentLocals);
            drop(localOwners);
            drop(localDestinations);
            drop(localFunctionLocals);
            drop(localValues);
            drop(localStatements);
            drop(localCallableBodyLengths);
            drop(localCallableBodyStarts);
            drop(localCarriers);
            drop(localProjections);
            drop(localReferences);
            drop(arguments);
            drop(operations);
            drop(localMembers);
            drop(localCases);
            drop(localAggregates);
            drop(rows);
          }
        }
        """.formatted(
            callableBodyStart,
            callableBodyEnd - callableBodyStart,
            localAggregateNameStart,
            declarationStart,
            declarationEnd,
            localMemberNameStart,
            localConstructorReferenceStart,
            projectionOwnerStart,
            projectionMemberStart,
            operationStart,
            projectionOwnerStart,
            argumentStart,
            localValueReferenceStart,
            localConstructorReferenceStart,
            referenceStart,
            importedKind,
            SOURCE.length()));
    return new com.typeobject.wheeler.compiler.WheelerCompiler().compileModuleFiles(
        sources, "example.aggregate_aware_source_product");
  }
}
