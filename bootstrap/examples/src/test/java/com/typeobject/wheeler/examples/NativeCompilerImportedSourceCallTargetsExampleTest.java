package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for closed imported source-call target views. */
final class NativeCompilerImportedSourceCallTargetsExampleTest {
  @Test
  void ordersImportedTargetsByDependencyRankAndIdentity() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("targetCount"));
    assertEquals(3, machine.global("parameterCount"));
    assertEquals(9, machine.global("nameBytes"));
    assertEquals(1, machine.global("firstCallable"));
    assertEquals(0, machine.global("firstRank"));
    assertEquals(2, machine.global("secondCallable"));
    assertEquals(1, machine.global("secondRank"));
    assertEquals(97, machine.global("firstNameByte"));
    assertEquals(98, machine.global("secondNameByte"));
    assertEquals(1, machine.global("firstParameterType"));
    assertEquals(2, machine.global("secondParameterType"));
    assertEquals(0x11, machine.global("firstIdentityByte"));
    assertEquals(0x22, machine.global("secondIdentityByte"));
  }

  @Test
  void rejectsDuplicateIdentitiesWithoutPublishing() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    CompilerMachineRunner.runWithoutRewindHistory(machine);

    assertEquals(0, machine.global("valid"));
    assertEquals(91, machine.global("firstCallable"));
    assertEquals(92, machine.global("firstNameByte"));
    assertEquals(93, machine.global("firstParameterType"));
    assertEquals(94, machine.global("firstIdentityByte"));
  }

  private static Program program(boolean duplicateIdentity) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_source_call_targets"));
    sources.put("ImportedSourceCallTargetsExample.w", """
        module example.imported_source_call_targets;

        import wheeler.compiler.closure.imported_source_call_targets;

        classical class ImportedSourceCallTargetsExample {
          state long valid = 0;
          state long targetCount = 0;
          state long parameterCount = 0;
          state long nameBytes = 0;
          state long firstCallable = 0;
          state long firstRank = 0;
          state long secondCallable = 0;
          state long secondRank = 0;
          state long firstNameByte = 0;
          state long secondNameByte = 0;
          state long firstParameterType = 0;
          state long secondParameterType = 0;
          state long firstIdentityByte = 0;
          state long secondIdentityByte = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 2408512, /* allocations= */ 17);
            words dependencies = allocate(products, /* length= */ 8192);
            bytes names = allocateBytes(products, /* length= */ 16);
            words nameStarts = allocate(products, /* length= */ 4096);
            words nameLengths = allocate(products, /* length= */ 4096);
            words firstParameters = allocate(products, /* length= */ 4096);
            words parameterCounts = allocate(products, /* length= */ 4096);
            words resultTypes = allocate(products, /* length= */ 4096);
            words effects = allocate(products, /* length= */ 4096);
            words parameterTypes = allocate(products, /* length= */ 16384);
            words parameterModes = allocate(products, /* length= */ 16384);
            bytes identities = allocateBytes(products, /* length= */ 131072);
            words targetRows = allocate(products, /* length= */ 32768);
            words targetParameters = allocate(products, /* length= */ 32768);
            bytes targetNames = allocateBytes(products, /* length= */ 1048576);
            bytes targetIdentities = allocateBytes(products, /* length= */ 131072);
            words unusedA = allocate(products, /* length= */ 1);
            words unusedB = allocate(products, /* length= */ 1);
            writeAscii(names, 0, "alphabeta");
            set(dependencies, 0, 1);
            set(dependencies, 4096, 2);
            set(dependencies, 1, 0);
            set(dependencies, 4097, 1);
            set(nameStarts, 1, 0);
            set(nameLengths, 1, 5);
            set(firstParameters, 1, 0);
            set(parameterCounts, 1, 2);
            set(resultTypes, 1, 1);
            set(effects, 1, 3);
            set(parameterTypes, 0, 1);
            set(parameterTypes, 1, 2);
            set(nameStarts, 2, 5);
            set(nameLengths, 2, 4);
            set(firstParameters, 2, 2);
            set(parameterCounts, 2, 1);
            set(resultTypes, 2, 2);
            set(effects, 2, 4);
            set(parameterTypes, 2, 2);
            long identityByte = 0;
            while (identityByte < 32) limit 32 {
              setByte(identities, 32 + identityByte, 0x11);
              setByte(identities, 64 + identityByte, SECOND_IDENTITY);
              identityByte += 1;
            }
            set(targetRows, 0, 91);
            set(targetParameters, 0, 93);
            setByte(targetNames, 0, 92);
            setByte(targetIdentities, 0, 94);
            ImportedSourceCallTargetPlan plan = materializeImportedSourceCallTargets(
              /* dependencyCount= */ 2,
              dependencies,
              names,
              nameStarts,
              nameLengths,
              firstParameters,
              parameterCounts,
              resultTypes,
              effects,
              parameterTypes,
              parameterModes,
              identities,
              targetRows,
              targetParameters,
              targetNames,
              targetIdentities
            );
            if (plan.valid) {
              valid = 1;
            }
            targetCount = plan.targetCount;
            parameterCount = plan.parameterCount;
            nameBytes = plan.nameBytes;
            firstCallable = targetRows[0];
            firstRank = targetRows[4096];
            secondCallable = targetRows[1];
            secondRank = targetRows[4097];
            firstNameByte = targetNames[0];
            secondNameByte = targetNames[5];
            firstParameterType = targetParameters[0];
            secondParameterType = targetParameters[2];
            firstIdentityByte = targetIdentities[0];
            secondIdentityByte = targetIdentities[32];
            drop(unusedB);
            drop(unusedA);
            drop(targetIdentities);
            drop(targetNames);
            drop(targetParameters);
            drop(targetRows);
            drop(identities);
            drop(parameterModes);
            drop(parameterTypes);
            drop(effects);
            drop(resultTypes);
            drop(parameterCounts);
            drop(firstParameters);
            drop(nameLengths);
            drop(nameStarts);
            drop(names);
            drop(dependencies);
            drop(products);
          }
        }
        """.replace("SECOND_IDENTITY", duplicateIdentity ? "0x11" : "0x22"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.imported_source_call_targets");
  }
}
