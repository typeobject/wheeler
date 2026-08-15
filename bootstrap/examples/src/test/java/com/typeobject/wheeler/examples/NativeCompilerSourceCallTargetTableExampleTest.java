package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for dense local and imported source-call target tables. */
final class NativeCompilerSourceCallTargetTableExampleTest {
  @Test
  void joinsLocalAndImportedTargetProducts() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(2, machine.global("targetCount"));
    assertEquals(2, machine.global("parameterCount"));
    assertEquals(6, machine.global("nameBytes"));
    assertEquals(98, machine.global("importedName"));
    assertEquals(2, machine.global("importedType"));
    assertEquals(2, machine.global("importedResult"));
    assertEquals(22, machine.global("importedIdentity"));
    assertEquals(7, machine.global("dependencyRank"));
    assertEquals(1, machine.global("dependencyTarget"));
  }

  @Test
  void rejectsMalformedImportedResultsAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(99, machine.global("importedName"));
    assertEquals(98, machine.global("importedType"));
    assertEquals(97, machine.global("dependencyTarget"));
  }

  private static Program program(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_call_target_table"));
    sources.put("SourceCallTargetTableExample.w", """
        module example.source_call_target_table;

        import wheeler.compiler.closure.source_call_target_table;

        classical class SourceCallTargetTableExample {
          state long valid = 0;
          state long targetCount = 0;
          state long parameterCount = 0;
          state long nameBytes = 0;
          state long importedName = 0;
          state long importedType = 0;
          state long importedResult = 0;
          state long importedIdentity = 0;
          state long dependencyRank = 0;
          state long dependencyTarget = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region rows = new region(/* bytes= */ 1181328, /* allocations= */ 14);
            bytes localNames = allocateBytes(rows, /* length= */ 3);
            words localNameStarts = allocate(rows, /* length= */ 4096);
            words localNameLengths = allocate(rows, /* length= */ 4096);
            words localParameterStarts = allocate(rows, /* length= */ 4096);
            words localParameterCounts = allocate(rows, /* length= */ 4096);
            words localParameterTypes = allocate(rows, /* length= */ 16384);
            words localResultTypes = allocate(rows, /* length= */ 4096);
            bytes localIdentities = allocateBytes(rows, /* length= */ 131072);
            words importedRows = allocate(rows, /* length= */ 32768);
            words importedParameterRows = allocate(rows, /* length= */ 32768);
            bytes importedNames = allocateBytes(rows, /* length= */ 3);
            bytes importedIdentities = allocateBytes(rows, /* length= */ 131072);
            words small = allocate(rows, /* length= */ 3);
            words unused = allocate(rows, /* length= */ 1);
            writeAscii(localNames, 0, "foo");
            writeAscii(importedNames, 0, "bar");
            set(localNameLengths, 0, 3);
            set(localParameterCounts, 0, 1);
            set(localParameterTypes, 0, 1);
            set(localResultTypes, 0, 1);
            setByte(localIdentities, 0, 11);
            set(importedRows, 4096, 7);
            set(importedRows, 12288, 3);
            set(importedRows, 20480, 1);
            set(importedRows, 24576, IMPORTED_RESULT);
            set(importedParameterRows, 0, 2);
            setByte(importedIdentities, 0, 22);
            region output = new region(/* bytes= */ 1540096, /* allocations= */ 9);
            bytes targetNames = allocateBytes(output, /* length= */ 1048576);
            words targetNameStarts = allocate(output, /* length= */ 4096);
            words targetNameLengths = allocate(output, /* length= */ 4096);
            words targetParameterStarts = allocate(output, /* length= */ 4096);
            words targetParameterCounts = allocate(output, /* length= */ 4096);
            words targetParameterTypes = allocate(output, /* length= */ 16384);
            words targetResultTypes = allocate(output, /* length= */ 4096);
            bytes targetIdentities = allocateBytes(output, /* length= */ 131072);
            words dependencyRows = allocate(output, /* length= */ 8192);
            setByte(targetNames, 3, 99);
            set(targetParameterTypes, 1, 98);
            set(dependencyRows, 4096, 97);
            SourceCallTargetTablePlan plan = materializeSourceCallTargetTable(
              /* localCount= */ 1,
              localNames,
              localNameStarts,
              localNameLengths,
              localParameterStarts,
              localParameterCounts,
              localParameterTypes,
              localResultTypes,
              localIdentities,
              /* importedCount= */ 1,
              importedRows,
              importedParameterRows,
              importedNames,
              importedIdentities,
              targetNames,
              targetNameStarts,
              targetNameLengths,
              targetParameterStarts,
              targetParameterCounts,
              targetParameterTypes,
              targetResultTypes,
              targetIdentities,
              dependencyRows
            );
            if (plan.valid) {
              valid = 1;
            }
            targetCount = plan.targetCount;
            parameterCount = plan.parameterCount;
            nameBytes = plan.nameBytes;
            importedName = targetNames[3];
            importedType = targetParameterTypes[1];
            importedResult = targetResultTypes[1];
            importedIdentity = targetIdentities[32];
            dependencyRank = dependencyRows[0];
            dependencyTarget = dependencyRows[4096];
            drop(dependencyRows);
            drop(targetIdentities);
            drop(targetResultTypes);
            drop(targetParameterTypes);
            drop(targetParameterCounts);
            drop(targetParameterStarts);
            drop(targetNameLengths);
            drop(targetNameStarts);
            drop(targetNames);
            drop(output);
            drop(unused);
            drop(small);
            drop(importedIdentities);
            drop(importedNames);
            drop(importedParameterRows);
            drop(importedRows);
            drop(localIdentities);
            drop(localResultTypes);
            drop(localParameterTypes);
            drop(localParameterCounts);
            drop(localParameterStarts);
            drop(localNameLengths);
            drop(localNameStarts);
            drop(localNames);
            drop(rows);
          }
        }
        """.replace("IMPORTED_RESULT", malformed ? "9" : "2"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_call_target_table");
  }
}
