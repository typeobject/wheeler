package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for target-aligned direct-dependency qualifiers. */
final class NativeCompilerImportedCallQualifierProductsExampleTest {
  @Test
  void copiesCanonicalQualifiersAndRanks() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(15, machine.global("nameBytes"));
    assertEquals(97, machine.global("firstName"));
    assertEquals(103, machine.global("secondName"));
    assertEquals(2, machine.global("firstRank"));
    assertEquals(5, machine.global("secondRank"));
  }

  @Test
  void rejectsOneRankWithTwoModuleOwnersAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(99, machine.global("firstName"));
    assertEquals(98, machine.global("firstRank"));
  }

  private static Program program(boolean duplicateRank) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.imported_call_qualifier_products"));
    sources.put("ImportedCallQualifierProductsExample.w", """
        module example.imported_call_qualifier_products;

        import wheeler.compiler.closure.imported_call_qualifier_products;

        classical class ImportedCallQualifierProductsExample {
          state long valid = 0;
          state long nameBytes = 0;
          state long firstName = 0;
          state long secondName = 0;
          state long firstRank = 0;
          state long secondRank = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region source = new region(/* bytes= */ 303119, /* allocations= */ 5);
            words targets = allocate(source, /* length= */ 32768);
            words owners = allocate(source, /* length= */ 4096);
            bytes moduleNames = allocateBytes(source, /* length= */ 15);
            words moduleNameStarts = allocate(source, /* length= */ 512);
            words moduleNameLengths = allocate(source, /* length= */ 512);
            set(targets, 0, 3);
            set(targets, 1, 7);
            set(targets, 4096, 2);
            set(targets, 4097, SECOND_RANK);
            set(owners, 3, 1);
            set(owners, 7, 2);
            writeAscii(moduleNames, 0, "alpha.betagamma");
            set(moduleNameLengths, 1, 10);
            set(moduleNameStarts, 2, 10);
            set(moduleNameLengths, 2, 5);
            region output = new region(/* bytes= */ 1146880, /* allocations= */ 4);
            bytes qualifierNames = allocateBytes(output, /* length= */ 1048576);
            words qualifierStarts = allocate(output, /* length= */ 4096);
            words qualifierLengths = allocate(output, /* length= */ 4096);
            words qualifierRanks = allocate(output, /* length= */ 4096);
            setByte(qualifierNames, 0, 99);
            set(qualifierRanks, 0, 98);
            ImportedCallQualifierPlan plan = materializeImportedCallQualifierProducts(
              /* targetCount= */ 2,
              targets,
              owners,
              moduleNames,
              moduleNameStarts,
              moduleNameLengths,
              qualifierNames,
              qualifierStarts,
              qualifierLengths,
              qualifierRanks
            );
            if (plan.valid) {
              valid = 1;
            }
            nameBytes = plan.nameBytes;
            firstName = qualifierNames[0];
            secondName = qualifierNames[10];
            firstRank = qualifierRanks[0];
            secondRank = qualifierRanks[1];
            drop(qualifierRanks);
            drop(qualifierLengths);
            drop(qualifierStarts);
            drop(qualifierNames);
            drop(output);
            drop(moduleNameLengths);
            drop(moduleNameStarts);
            drop(moduleNames);
            drop(owners);
            drop(targets);
            drop(source);
          }
        }
        """.replace("SECOND_RANK", duplicateRank ? "2" : "5"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.imported_call_qualifier_products");
  }
}
