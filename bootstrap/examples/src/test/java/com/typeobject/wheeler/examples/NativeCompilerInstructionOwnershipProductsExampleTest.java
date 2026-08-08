package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Native evidence for ownership products derived from canonical instructions. */
final class NativeCompilerInstructionOwnershipProductsExampleTest {
  private static final Set<Opcode> BORROWS = Set.of(
      Opcode.UTF8_BORROW, Opcode.MAP_BORROW, Opcode.BUFFER_BORROW, Opcode.REGION_BORROW);
  private static final Set<Opcode> CREATES = Set.of(
      Opcode.RECORD_NEW, Opcode.VARIANT_NEW, Opcode.ARRAY_NEW, Opcode.SLICE_NEW,
      Opcode.REGION_NEW, Opcode.WORDS_ALLOC, Opcode.BYTES_ALLOC, Opcode.MAP_ALLOC,
      Opcode.UTF8_FREEZE);
  private static final Set<Opcode> DROPS = Set.of(Opcode.BUFFER_DROP, Opcode.REGION_DROP);

  @Test
  void derivesMovesBalancedLoansCreatesAndDrops() throws Exception {
    Program product = product();
    byte[] artifact = new BytecodeWriter().write(product);
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(false), artifact, 1);

    machine.run();

    long borrows = instructions(product, BORROWS);
    long creates = instructions(product, CREATES);
    long moves = instructions(product, Set.of(Opcode.OWNED_MOVE));
    long drops = instructions(product, DROPS);
    assertEquals(borrows * 2 + creates + moves + drops, machine.global("eventCount"));
    assertEquals(borrows, machine.global("borrowCount"));
    assertEquals(borrows, machine.global("releaseCount"));
    assertEquals(creates, machine.global("createCount"));
    assertEquals(moves, machine.global("moveCount"));
    assertEquals(drops, machine.global("dropCount"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsInvalidInstructionRangesBeforePublication() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(true), artifact, 1);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  private static long instructions(Program product, Set<Opcode> wanted) {
    return product.functions().stream()
        .flatMap(function -> function.forward().stream())
        .filter(instruction -> wanted.contains(instruction.opcode()))
        .count();
  }

  private static Program product() {
    String source = """
        module fixture.instruction_ownership;

        classical class InstructionOwnership {
          private utf8 makeText(borrow mut region arena, long length) {
            bytes output = allocateBytes(arena, length);
            return freezeUtf8(output);
          }

          public utf8 forwardText(borrow mut region arena, long length) {
            return makeText(arena, length);
          }

          public long mutateThenDrop(borrow mut region arena, long index, long value) {
            bytes output = allocateBytes(arena, index);
            setByte(output, index, value);
            drop(output);
            return value;
          }
        }
        """;
    return new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("InstructionOwnership.w", source), "fixture.instruction_ownership");
  }

  private static Program decoder(boolean malformed) throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.compiled_function_products"));
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.instruction_ownership_products"));
    sources.put("InstructionOwnershipProductsExample.w", """
        module example.instruction_ownership_products;

        import wheeler.compiler.closure.compiled_function_products;
        import wheeler.compiler.closure.instruction_ownership_products;

        classical class InstructionOwnershipProductsExample {
          state long eventCount = 0;
          state long borrowCount = 0;
          state long releaseCount = 0;
          state long createCount = 0;
          state long moveCount = 0;
          state long dropCount = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 529408, /* allocations= */ 3);
            words functions = allocate(rows, /* length= */ 640);
            words instructions = allocate(rows, /* length= */ 24576);
            words events = allocate(rows, /* length= */ 40960);
            CompiledFunctionPlan plan = indexCompiledFunctionProducts(
              source,
              bufferLength(source),
              functions,
              instructions
            );
            MALFORMED
            eventCount = deriveInstructionOwnershipProducts(
              source,
              plan.instructionCount,
              instructions,
              events
            );
            long event = 0;
            while (event < eventCount) limit 8192 {
              if (events[event] == 1) {
                moveCount += 1;
              }
              if (events[event] == 2) {
                borrowCount += 1;
              }
              if (events[event] == 3) {
                releaseCount += 1;
              }
              if (events[event] == 4) {
                dropCount += 1;
              }
              if (events[event] == 5) {
                createCount += 1;
              }
              event += 1;
            }
            published = 1;
            setOutputLength(output, 0);
            drop(events);
            drop(instructions);
            drop(functions);
            drop(rows);
          }
        }
        """.replace(
            "MALFORMED",
            malformed
                ? "long bad = 0; while (bad < plan.instructionCount) limit 4096 { "
                    + "set(instructions, 8192 + bad, -1); bad += 1; }"
                : ""));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.instruction_ownership_products");
  }
}
