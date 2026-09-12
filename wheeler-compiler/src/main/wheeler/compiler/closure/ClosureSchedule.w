//! Stages validated closure sources in leaf-first order through active slot leases.

module wheeler.compiler.closure.schedule;

import wheeler.compiler.closure.active_source_slots;
import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.plan;

classical class ClosureSchedules {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long SCHEDULE_COLUMNS = 2;
  private const long WORD_BYTES = 8;
  private const long SCHEDULE_ARENA_BYTES = SCHEDULE_COLUMNS * MAX_LOCAL_MODULES * WORD_BYTES;

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
    CountedClosurePlan plan,
    borrow mut words leafFirstOrder,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut words moduleSlots,
    borrow mut words moduleGenerations
  ) {
    requireMetadata(0 < plan.moduleCount);
    requireMetadata(plan.moduleCount < MAX_LOCAL_MODULES + 1);
    requireMetadata(plan.moduleCount < bufferLength(leafFirstOrder) + 1);
    requireMetadata(plan.moduleCount < bufferLength(sourceStarts) + 1);
    requireMetadata(plan.moduleCount < bufferLength(sourceLengths) + 1);
    requireMetadata(plan.moduleCount < bufferLength(moduleSlots) + 1);
    requireMetadata(plan.moduleCount < bufferLength(moduleGenerations) + 1);
    region slotArena = new region(
      /* bytes= */ ACTIVE_SOURCE_SLOT_ARENA_BYTES,
      /* allocations= */ ACTIVE_SOURCE_SLOT_BUFFERS
    );
    bytes storage = allocateBytes(slotArena, ACTIVE_SOURCE_SLOT_BYTES);
    words owners = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words generations = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words lengths = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words live = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    assert(initializeActiveSourceSlots(storage, owners, generations, lengths, live));
    region scheduleArena = new region(
      /* bytes= */ SCHEDULE_ARENA_BYTES,
      /* allocations= */ SCHEDULE_COLUMNS
    );
    words scratchSlots = allocate(scheduleArena, MAX_LOCAL_MODULES);
    words scratchGenerations = allocate(scheduleArena, MAX_LOCAL_MODULES);

    long checked = 0;
    while (checked < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long checkedModule = leafFirstOrder[checked];
      requireMetadata(-1 < checkedModule);
      requireMetadata(checkedModule < plan.moduleCount);
      requireMetadata(scratchGenerations[checkedModule] == 0);
      set(scratchGenerations, checkedModule, 1);
      checked += 1;
    }

    long position = 0;
    long finalGeneration = 0;
    while (position < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long module = leafFirstOrder[position];
      requireMetadata(-1 < module);
      requireMetadata(module < plan.moduleCount);
      long sourceStart = sourceStarts[module];
      long sourceLength = sourceLengths[module];
      requireMetadata(0 < sourceLength);
      requireMetadata(sourceLength < MAX_SOURCE_BYTES + 1);
      requireMetadata(-1 < sourceStart);
      requireMetadata(sourceStart < bufferLength(archive) + 1);
      requireMetadata(sourceLength < bufferLength(archive) - sourceStart + 1);
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
          requireMetadata(owner < 0);
        }
      }

      requireMetadata(
        publishActiveSource(
          selected,
          archive,
          sourceStart,
          sourceLength,
          storage,
          owners,
          generations,
          lengths,
          live
        )
      );
      requireMetadata(
        activeSourceLength(selected, owners, generations, lengths, live) == sourceLength
      );
      set(scratchSlots, module, selected.slot);
      set(scratchGenerations, module, selected.generation);
      finalGeneration = selected.generation;
      requireMetadata(
        releaseActiveSource(selected, storage, owners, generations, lengths, live)
      );
      position += 1;
    }

    ClosureSourceSchedule result = new ClosureSourceSchedule(
      plan.moduleCount,
      /* peakActiveSources= */ 1,
      finalGeneration
    );
    long publishedModule = 0;
    while (publishedModule < plan.moduleCount) limit MAX_LOCAL_MODULES {
      set(moduleSlots, publishedModule, scratchSlots[publishedModule]);
      set(moduleGenerations, publishedModule, scratchGenerations[publishedModule]);
      publishedModule += 1;
    }

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
