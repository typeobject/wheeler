package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
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
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(false, false, false), artifact, 1);

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
    assertEquals(borrows + creates + moves + drops, machine.global("sourceCoordinateCount"));
    assertEquals(borrows, machine.global("boundaryCoordinateCount"));
    assertEquals(1, machine.global("coordinateValid"));
    assertEquals(1, machine.global("ownershipAgreement"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void derivesCreationFromASupplementalArtifactSelector() throws Exception {
    byte[] supplemental = ByteBuffer.allocate(40).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) 0x0500).putShort((short) 4).putInt(40)
        .putLong(3).putLong(0).putLong(1).putLong(1)
        .array();
    VirtualMachine machine = VirtualMachine.withBinaryInput(composedDecoder(), supplemental);

    machine.run();

    assertEquals(1, machine.global("eventCount"));
    assertEquals(5, machine.global("eventKind"));
    assertEquals(3, machine.global("destination"));
  }

  @Test
  void rejectsInvalidInstructionRangesBeforePublication() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(true, false, false), artifact, 1);

    assertThrows(VmTrap.class, machine::run);
    assertEquals(0, machine.global("published"));
  }

  @Test
  void rejectsInvalidPlannedOwnershipCoordinatesAtomically() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    VirtualMachine machine = VirtualMachine.withBinaryInput(decoder(false, true, false), artifact, 1);

    machine.run();

    assertEquals(0, machine.global("coordinateValid"));
    assertEquals(77, machine.global("firstCoordinate"));
    assertEquals(1, machine.global("published"));
  }

  @Test
  void rejectsSourceAndDecodedOwnershipDisagreement() throws Exception {
    byte[] artifact = new BytecodeWriter().write(product());
    VirtualMachine machine = VirtualMachine.withBinaryInput(
        decoder(false, false, true), artifact, 1);

    machine.run();

    assertEquals(1, machine.global("coordinateValid"));
    assertEquals(0, machine.global("ownershipAgreement"));
    assertEquals(1, machine.global("published"));
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

  private static Program composedDecoder() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.putAll(CompilerSources.moduleClosure(
        "wheeler.compiler.closure.instruction_ownership_products"));
    sources.put("ComposedInstructionOwnershipExample.w", """
        module example.composed_instruction_ownership;

        import wheeler.compiler.closure.instruction_ownership_products;

        classical class ComposedInstructionOwnershipExample {
          state long eventCount = 0;
          state long eventKind = 0;
          state long destination = -1;

          entry void main(borrow byteview source) {
            region rows = new region(/* bytes= */ 557056, /* allocations= */ 3);
            words instructions = allocate(rows, /* length= */ 24576);
            words selectors = allocate(rows, /* length= */ 4096);
            words events = allocate(rows, /* length= */ 40960);
            set(instructions, 0, 0);
            set(instructions, 4096, 0);
            set(instructions, 8192, 0);
            set(instructions, 12288, 0x0500);
            set(selectors, 0, 1);
            eventCount = deriveComposedInstructionOwnershipProducts(
              source,
              source,
              /* instructionCount= */ 1,
              instructions,
              selectors,
              events
            );
            eventKind = events[0];
            destination = events[24576];
            drop(events);
            drop(selectors);
            drop(instructions);
            drop(rows);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.composed_instruction_ownership");
  }

  private static Program decoder(
      boolean malformed,
      boolean malformedCoordinates,
      boolean ownershipMismatch) throws Exception {
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
          state long sourceCoordinateCount = 0;
          state long boundaryCoordinateCount = 0;
          state long coordinateValid = 0;
          state long firstCoordinate = 77;
          state long ownershipAgreement = 0;
          state long published = 0;

          entry void main(borrow byteview source, borrow mut bytes output) {
            region rows = new region(/* bytes= */ 1119232, /* allocations= */ 7);
            words functions = allocate(rows, /* length= */ 640);
            words instructions = allocate(rows, /* length= */ 24576);
            words events = allocate(rows, /* length= */ 40960);
            words instructionStatements = allocate(rows, /* length= */ 4096);
            words instructionPlannedRows = allocate(rows, /* length= */ 4096);
            words ownershipCoordinates = allocate(rows, /* length= */ 32768);
            words sourceOwnershipCoordinates = allocate(rows, /* length= */ 32768);
            CompiledFunctionPlan plan = indexCompiledFunctionProducts(
              source,
              bufferLength(source),
              functions,
              instructions
            );
            MALFORMED_ARTIFACT
            set(ownershipCoordinates, 0, 77);
            eventCount = deriveInstructionOwnershipProducts(
              source,
              plan.instructionCount,
              instructions,
              events
            );
            long instruction = 0;
            while (instruction < plan.instructionCount) limit 4096 {
              set(instructionStatements, instruction, instruction);
              set(instructionPlannedRows, instruction, instruction + 10);
              instruction += 1;
            }
            MALFORMED_COORDINATES
            OwnershipCoordinatePlan coordinatePlan = bindInstructionOwnershipCoordinates(
              eventCount,
              plan.instructionCount,
              events,
              instructionStatements,
              instructionPlannedRows,
              ownershipCoordinates
            );
            if (coordinatePlan.valid) {
              coordinateValid = 1;
            }
            firstCoordinate = ownershipCoordinates[0];
            long sourceEvent = 0;
            while (sourceEvent < eventCount) limit 8192 {
              if (events[sourceEvent] == 3) {
                set(sourceOwnershipCoordinates, sourceEvent, -1);
                set(
                  sourceOwnershipCoordinates,
                  8192 + sourceEvent,
                  events[8192 + sourceEvent]
                );
              } else {
                set(sourceOwnershipCoordinates, sourceEvent, events[8192 + sourceEvent]);
                set(
                  sourceOwnershipCoordinates,
                  8192 + sourceEvent,
                  events[8192 + sourceEvent] + 10
                );
              }
              set(
                sourceOwnershipCoordinates,
                16384 + sourceEvent,
                events[24576 + sourceEvent]
              );
              set(
                sourceOwnershipCoordinates,
                24576 + sourceEvent,
                events[32768 + sourceEvent]
              );
              sourceEvent += 1;
            }
            OWNERSHIP_MISMATCH
            if (coordinatePlan.valid) {
              if (
                ownershipCoordinatesAgree(
                  eventCount,
                  sourceOwnershipCoordinates,
                  ownershipCoordinates
                )
              ) {
                ownershipAgreement = 1;
              }
            }
            long event = 0;
            while (event < eventCount) limit 8192 {
              if (events[event] == 1) {
                moveCount += 1;
              }
              if (coordinatePlan.valid) {
                if (events[event] == 3) {
                  assert(ownershipCoordinates[event] == -1);
                  assert(ownershipCoordinates[8192 + event] == events[8192 + event]);
                  boundaryCoordinateCount += 1;
                } else {
                  assert(ownershipCoordinates[event] == events[8192 + event]);
                  assert(ownershipCoordinates[8192 + event] == events[8192 + event] + 10);
                  assert(ownershipCoordinates[16384 + event] == events[24576 + event]);
                  assert(ownershipCoordinates[24576 + event] == events[32768 + event]);
                  sourceCoordinateCount += 1;
                }
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
            drop(sourceOwnershipCoordinates);
            drop(ownershipCoordinates);
            drop(instructionPlannedRows);
            drop(instructionStatements);
            drop(events);
            drop(instructions);
            drop(functions);
            drop(rows);
          }
        }
        """.replace(
            "MALFORMED_ARTIFACT",
            malformed
                ? "long bad = 0; while (bad < plan.instructionCount) limit 4096 { "
                    + "set(instructions, 8192 + bad, -1); bad += 1; }"
                : "")
            .replace(
                "MALFORMED_COORDINATES",
                malformedCoordinates
                    ? "long badCoordinate = 0; while (badCoordinate < plan.instructionCount) "
                        + "limit 4096 { set(instructionPlannedRows, badCoordinate, 32768); "
                        + "badCoordinate += 1; }"
                    : "")
            .replace(
                "OWNERSHIP_MISMATCH",
                ownershipMismatch
                    ? "set(sourceOwnershipCoordinates, 8192, "
                        + "sourceOwnershipCoordinates[8192] + 1);"
                    : ""));
    return new WheelerCompiler().compileModuleFiles(
        sources, "example.instruction_ownership_products");
  }
}
