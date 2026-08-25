//! Stages validated closure sources in leaf-first order through active slot leases.

module wheeler.compiler.closure.schedule;

import wheeler.compiler.closure.active_source_slots;
import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.plan;

classical class ClosureSchedules {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long SCHEDULE_ARENA_BYTES = 8192;
  private const long SOURCE_ARENA_BYTES = 32768;

  /// Summarizes one complete deterministic linked-source staging pass.
  public record ClosureSourceSchedule(
    long moduleCount,
    long peakActiveSources,
    long finalGeneration
  ) {}

  /// Stages each immutable source once in leaf-first order and releases it immediately.
  ///
  /// Module slot and generation columns publish only after the complete pass succeeds.
  public ClosureSourceSchedule stageClosureSources(
    borrow byteview archive,
    borrow byteview manifest,
    CountedClosurePlan plan,
    borrow mut words leafFirstOrder,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut words moduleSlots,
    borrow mut words moduleGenerations
  ) {
    requireMetadata(0 < plan.moduleCount, manifest);
    requireMetadata(plan.moduleCount < MAX_LOCAL_MODULES + 1, manifest);
    region slotArena = new region(
      /* bytes= */ ACTIVE_SOURCE_SLOT_ARENA_BYTES,
      /* allocations= */ 6
    );
    bytes storage = allocateBytes(slotArena, ACTIVE_SOURCE_SLOT_BYTES);
    words owners = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words generations = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words lengths = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words live = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    assert(initializeActiveSourceSlots(storage, owners, generations, lengths, live));
    region scheduleArena = new region(/* bytes= */ SCHEDULE_ARENA_BYTES, /* allocations= */ 2);
    words scratchSlots = allocate(scheduleArena, MAX_LOCAL_MODULES);
    words scratchGenerations = allocate(scheduleArena, MAX_LOCAL_MODULES);

    long position = 0;
    long finalGeneration = 0;
    while (position < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long module = leafFirstOrder[position];
      requireMetadata(-1 < module, manifest);
      requireMetadata(module < plan.moduleCount, manifest);
      long sourceStart = sourceStarts[module];
      long sourceLength = sourceLengths[module];
      requireMetadata(0 < sourceLength, manifest);
      requireMetadata(sourceLength < MAX_SOURCE_BYTES + 1, manifest);
      requireMetadata(-1 < sourceStart, manifest);
      requireMetadata(sourceStart < bufferLength(archive) + 1, manifest);
      requireMetadata(sourceLength < bufferLength(archive) - sourceStart + 1, manifest);
      region sourceArena = new region(/* bytes= */ SOURCE_ARENA_BYTES, /* allocations= */ 1);
      bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
      long cursor = 0;
      while (cursor < sourceLength) limit MAX_SOURCE_BYTES {
        setByte(sourceBytes, cursor, archive[sourceStart + cursor]);
        cursor += 1;
      }

      utf8 source = freezeUtf8(sourceBytes);
      ActiveSourceHandle selected = new ActiveSourceHandle(0, 0, 0);
      ActiveSourceAcquireResult acquired = acquireActiveSourceSlot(
        module,
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
          requireMetadata(owner < 0, manifest);
        }
      }

      requireMetadata(
        publishActiveSource(selected, source, storage, owners, generations, lengths, live),
        manifest
      );
      requireMetadata(
        activeSourceLength(selected, owners, generations, lengths, live) == sourceLength,
        manifest
      );
      set(scratchSlots, module, selected.slot);
      set(scratchGenerations, module, selected.generation);
      finalGeneration = selected.generation;
      requireMetadata(
        releaseActiveSource(selected, storage, owners, generations, lengths, live),
        manifest
      );
      drop(source);
      drop(sourceArena);
      position += 1;
    }

    long publishedModule = 0;
    while (publishedModule < plan.moduleCount) limit MAX_LOCAL_MODULES {
      set(moduleSlots, publishedModule, scratchSlots[publishedModule]);
      set(moduleGenerations, publishedModule, scratchGenerations[publishedModule]);
      publishedModule += 1;
    }

    ClosureSourceSchedule result = new ClosureSourceSchedule(
      plan.moduleCount,
      /* peakActiveSources= */ 1,
      finalGeneration
    );
    drop(scratchGenerations);
    drop(scratchSlots);
    drop(scheduleArena);
    drop(live);
    drop(lengths);
    drop(generations);
    drop(owners);
    drop(storage);
    drop(slotArena);
    return result;
  }
}
