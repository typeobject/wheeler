package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for source ownership coordinates. */
final class NativeCompilerSourceOwnershipProductsExampleTest {
  @Test
  void mapsSourceEffectsThroughPlannedStatementsAndValues() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(false), new byte[0]);

    machine.run();

    assertEquals(1, machine.global("valid"));
    assertEquals(3, machine.global("effectCount"));
    assertEquals(2, machine.global("firstStatement"));
    assertEquals(20, machine.global("firstInstruction"));
    assertEquals(10, machine.global("firstDestination"));
    assertEquals(-1, machine.global("firstSource"));
    assertEquals(3, machine.global("secondStatement"));
    assertEquals(26, machine.global("secondInstruction"));
    assertEquals(13, machine.global("secondDestination"));
    assertEquals(4, machine.global("secondSource"));
    assertEquals(4, machine.global("thirdStatement"));
    assertEquals(30, machine.global("thirdInstruction"));
    assertEquals(-1, machine.global("thirdDestination"));
    assertEquals(13, machine.global("thirdSource"));
  }

  @Test
  void rejectsOutOfRangeSourceEffectsAtomically() throws Exception {
    VirtualMachine machine = new VirtualMachine(program(true), new byte[0]);

    machine.run();

    assertEquals(0, machine.global("valid"));
    assertEquals(0, machine.global("effectCount"));
    assertEquals(77, machine.global("firstStatement"));
  }

  private static Program program(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.source_ownership_products"));
    sources.put("SourceOwnershipProductsExample.w", """
        module example.source_ownership_products;

        import wheeler.compiler.closure.source_ownership_products;

        classical class SourceOwnershipProductsExample {
          state long valid = 0;
          state long effectCount = 0;
          state long firstStatement = 0;
          state long firstInstruction = 0;
          state long firstDestination = 0;
          state long firstSource = 0;
          state long secondStatement = 0;
          state long secondInstruction = 0;
          state long secondDestination = 0;
          state long secondSource = 0;
          state long thirdStatement = 0;
          state long thirdInstruction = 0;
          state long thirdDestination = 0;
          state long thirdSource = 0;

          entry void main(borrow utf8 input) {
            assert(bufferLength(input) == 0);
            region products = new region(/* bytes= */ 761856, /* allocations= */ 7);
            words effects = allocate(products, /* length= */ 40960);
            words sourceOffsets = allocate(products, /* length= */ 8192);
            words statementStarts = allocate(products, /* length= */ 4096);
            words statementWidths = allocate(products, /* length= */ 4096);
            words statementInstructions = allocate(products, /* length= */ 4096);
            words valueStarts = allocate(products, /* length= */ 1024);
            words coordinates = allocate(products, /* length= */ 32768);
            set(statementStarts, 2, 10);
            set(statementWidths, 2, 3);
            set(statementInstructions, 2, 20);
            set(statementStarts, 3, 13);
            set(statementWidths, 3, 1);
            set(statementInstructions, 3, 25);
            set(statementStarts, 4, 14);
            set(statementWidths, 4, 0);
            set(statementInstructions, 4, 30);
            set(valueStarts, 0, 4);
            set(valueStarts, 1, 13);
            set(effects, 0, 5);
            set(effects, 8192, 2);
            set(effects, 16384, 0);
            set(effects, 24576, DESTINATION);
            set(effects, 32768, -1);
            set(effects, 1, 1);
            set(effects, 8193, 3);
            set(effects, 16385, 1);
            set(effects, 24577, 0);
            set(effects, 32769, 0);
            set(sourceOffsets, 1, 0);
            set(effects, 2, 4);
            set(effects, 8194, 4);
            set(effects, 16386, 0);
            set(effects, 24578, -1);
            set(effects, 32770, 1);
            set(sourceOffsets, 2, 0);
            set(coordinates, 0, 77);
            SourceOwnershipPlan plan = materializeSourceOwnershipProducts(
              /* effectCount= */ 3,
              effects,
              sourceOffsets,
              statementStarts,
              statementWidths,
              statementInstructions,
              valueStarts,
              coordinates
            );
            if (plan.valid) {
              valid = 1;
            }
            effectCount = plan.effectCount;
            firstStatement = coordinates[0];
            firstInstruction = coordinates[8192];
            firstDestination = coordinates[16384];
            firstSource = coordinates[24576];
            secondStatement = coordinates[1];
            secondInstruction = coordinates[8193];
            secondDestination = coordinates[16385];
            secondSource = coordinates[24577];
            thirdStatement = coordinates[2];
            thirdInstruction = coordinates[8194];
            thirdDestination = coordinates[16386];
            thirdSource = coordinates[24578];
            drop(coordinates);
            drop(valueStarts);
            drop(statementInstructions);
            drop(statementWidths);
            drop(statementStarts);
            drop(sourceOffsets);
            drop(effects);
            drop(products);
          }
        }
        """.replace("DESTINATION", malformed ? "3" : "0"));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.source_ownership_products");
  }
}
