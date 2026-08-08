package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for generation-checked active linked-source storage. */
final class NativeCompilerActiveSourceSlotsExampleTest {
  @Test
  void rejectsStaleLeasesAndBoundsTheActiveLinkedSourceFrontier() throws Exception {
    Program program = program();
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, new byte[0], 6);

    machine.run();

    assertArrayEquals(new byte[] {1, 120, 121, 122, 2, 1}, machine.hostOutput());
    assertEquals(1, machine.global("published"));
    String source = CompilerSources.read("compiler/closure/ActiveSourceSlots.w");
    assertTrue(source.contains("public const long ACTIVE_SOURCE_SLOT_COUNT = 8;"));
    assertTrue(source.contains("public const long ACTIVE_SOURCE_SLOT_BYTES = 262144;"));
    assertTrue(source.contains("public const long ACTIVE_SOURCE_SLOT_ARENA_BYTES = 262464;"));
  }

  @Test
  void admitsThirtyTwoKiBAndRejectsTheNextByteBeforePublication() throws Exception {
    Program program = capacityProgram();
    byte[] boundary = new byte[32_768];
    java.util.Arrays.fill(boundary, (byte) 'a');
    VirtualMachine accepted = VirtualMachine.withBinaryInput(program, boundary, 1);
    CompilerMachineRunner.runWithoutRewindHistory(accepted);
    assertArrayEquals(new byte[] {1}, accepted.hostOutput());

    byte[] oversized = new byte[32_769];
    java.util.Arrays.fill(oversized, (byte) 'a');
    VirtualMachine rejected = VirtualMachine.withBinaryInput(program, oversized, 1);
    CompilerMachineRunner.runWithoutRewindHistory(rejected);
    assertArrayEquals(new byte[1], rejected.hostOutput());
  }

  private static Program capacityProgram() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "ActiveSourceSlots.w",
        CompilerSources.read("compiler/closure/ActiveSourceSlots.w"));
    sources.put("ActiveSourceCapacityExample.w", """
        module example.active_source_capacity;

        import wheeler.compiler.closure.active_source_slots;

        classical class ActiveSourceCapacityExample {
          entry void main(borrow byteview input, borrow mut bytes output) {
            region slots = new region(
              /* bytes= */ ACTIVE_SOURCE_SLOT_ARENA_BYTES,
              /* allocations= */ 6
            );
            bytes storage = allocateBytes(slots, ACTIVE_SOURCE_SLOT_BYTES);
            words owners = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            words generations = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            words lengths = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            words live = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            assert(initializeActiveSourceSlots(storage, owners, generations, lengths, live));
            region sourceArena = new region(/* bytes= */ 32769, /* allocations= */ 1);
            bytes sourceBytes = allocateBytes(sourceArena, bufferLength(input));
            long cursor = 0;
            while (cursor < bufferLength(input)) limit 32769 {
              setByte(sourceBytes, cursor, input[cursor]);
              cursor += 1;
            }
            utf8 source = freezeUtf8(sourceBytes);
            ActiveSourceHandle selected = new ActiveSourceHandle(0, 0, 0);
            ActiveSourceAcquireResult acquired = acquireActiveSourceSlot(
              0,
              storage,
              owners,
              generations,
              lengths,
              live
            );
            match (acquired) {
              case ActiveSourceAcquireResult.Value(ActiveSourceHandle handle) {
                selected = handle;
              }
              case ActiveSourceAcquireResult.Full(long owner) {
                assert(owner < 0);
              }
            }
            if (publishActiveSource(
              selected,
              source,
              storage,
              owners,
              generations,
              lengths,
              live
            )) {
              setByte(output, 0, 1);
            }
            drop(source);
            drop(sourceArena);
            drop(live);
            drop(lengths);
            drop(generations);
            drop(owners);
            drop(storage);
            drop(slots);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(
        sources,
        "example.active_source_capacity");
  }

  private static Program program() throws Exception {
    Map<String, String> sources = new LinkedHashMap<>();
    sources.put(
        "ActiveSourceSlots.w",
        CompilerSources.read("compiler/closure/ActiveSourceSlots.w"));
    sources.put("ActiveSourceSlotsExample.w", """
        module example.active_source_slots;

        import wheeler.compiler.closure.active_source_slots;

        classical class ActiveSourceSlotsExample {
          state long published = 0;

          entry void main(borrow byteview input, borrow mut bytes output) {
            assert(bufferLength(input) == 0);
            region slots = new region(
              /* bytes= */ ACTIVE_SOURCE_SLOT_ARENA_BYTES,
              /* allocations= */ 6
            );
            bytes storage = allocateBytes(slots, ACTIVE_SOURCE_SLOT_BYTES);
            words owners = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            words generations = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            words lengths = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            words live = allocate(slots, ACTIVE_SOURCE_SLOT_COUNT);
            assert(initializeActiveSourceSlots(storage, owners, generations, lengths, live));

            region payloads = new region(/* bytes= */ 29, /* allocations= */ 5);
            bytes firstBytes = allocateBytes(payloads, /* length= */ 10);
            writeAscii(firstBytes, 0, "abcdefghij");
            utf8 firstSource = freezeUtf8(firstBytes);
            bytes secondBytes = allocateBytes(payloads, /* length= */ 3);
            writeAscii(secondBytes, 0, "xyz");
            utf8 secondSource = freezeUtf8(secondBytes);
            bytes firstCopy = allocateBytes(payloads, /* length= */ 10);
            bytes secondCopy = allocateBytes(payloads, /* length= */ 3);
            bytes staleCopy = allocateBytes(payloads, /* length= */ 3);
            setByte(staleCopy, 0, 9);
            setByte(staleCopy, 1, 9);
            setByte(staleCopy, 2, 9);

            ActiveSourceHandle first = new ActiveSourceHandle(0, 0, 0);
            ActiveSourceAcquireResult firstResult = acquireActiveSourceSlot(
              3,
              storage,
              owners,
              generations,
              lengths,
              live
            );
            match (firstResult) {
              case ActiveSourceAcquireResult.Value(ActiveSourceHandle firstHandle) {
                first = firstHandle;
              }
              case ActiveSourceAcquireResult.Full(long firstOwner) {
                assert(firstOwner < 0);
              }
            }
            assert(publishActiveSource(
              first,
              firstSource,
              storage,
              owners,
              generations,
              lengths,
              live
            ));
            assert(copyActiveSource(
              first,
              storage,
              owners,
              generations,
              lengths,
              live,
              firstCopy
            ));
            assert(firstCopy[0] == 97);
            assert(firstCopy[9] == 106);
            assert(releaseActiveSource(
              first,
              storage,
              owners,
              generations,
              lengths,
              live
            ));
            assert(activeSourceLength(first, owners, generations, lengths, live) == -1);
            assert(copyActiveSource(
              first,
              storage,
              owners,
              generations,
              lengths,
              live,
              staleCopy
            ) == false);
            assert(staleCopy[0] == 9);
            assert(staleCopy[2] == 9);

            ActiveSourceHandle second = new ActiveSourceHandle(0, 0, 0);
            ActiveSourceAcquireResult secondResult = acquireActiveSourceSlot(
              4,
              storage,
              owners,
              generations,
              lengths,
              live
            );
            match (secondResult) {
              case ActiveSourceAcquireResult.Value(ActiveSourceHandle secondHandle) {
                second = secondHandle;
              }
              case ActiveSourceAcquireResult.Full(long secondOwner) {
                assert(secondOwner < 0);
              }
            }
            assert(second.slot == first.slot);
            assert(second.generation == first.generation + 1);
            assert(publishActiveSource(
              second,
              secondSource,
              storage,
              owners,
              generations,
              lengths,
              live
            ));
            assert(copyActiveSource(
              second,
              storage,
              owners,
              generations,
              lengths,
              live,
              secondCopy
            ));
            assert(publishActiveSource(
              first,
              firstSource,
              storage,
              owners,
              generations,
              lengths,
              live
            ) == false);
            assert(activeSourceLength(second, owners, generations, lengths, live) == 3);
            assert(storage[second.slot * 32768 + 3] == 0);

            long acquired = 1;
            while (acquired < ACTIVE_SOURCE_SLOT_COUNT) limit ACTIVE_SOURCE_SLOT_COUNT {
              ActiveSourceAcquireResult more = acquireActiveSourceSlot(
                acquired + 10,
                storage,
                owners,
                generations,
                lengths,
                live
              );
              match (more) {
                case ActiveSourceAcquireResult.Value(ActiveSourceHandle moreHandle) {
                  assert(-1 < moreHandle.slot);
                  acquired += 1;
                }
                case ActiveSourceAcquireResult.Full(long moreOwner) {
                  assert(moreOwner < 0);
                }
              }
            }
            ActiveSourceAcquireResult full = acquireActiveSourceSlot(
              99,
              storage,
              owners,
              generations,
              lengths,
              live
            );
            long fullSeen = 0;
            match (full) {
              case ActiveSourceAcquireResult.Value(ActiveSourceHandle fullHandle) {
                assert(fullHandle.slot < 0);
              }
              case ActiveSourceAcquireResult.Full(long finalOwner) {
                assert(finalOwner == 99);
                fullSeen = 1;
              }
            }

            setByte(output, 0, 1);
            setByte(output, 1, secondCopy[0]);
            setByte(output, 2, secondCopy[1]);
            setByte(output, 3, secondCopy[2]);
            setByte(output, 4, second.generation);
            setByte(output, 5, fullSeen);
            published = 1;
            drop(staleCopy);
            drop(secondCopy);
            drop(firstCopy);
            drop(secondSource);
            drop(firstSource);
            drop(payloads);
            drop(live);
            drop(lengths);
            drop(generations);
            drop(owners);
            drop(storage);
            drop(slots);
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(sources, "example.active_source_slots");
  }
}
