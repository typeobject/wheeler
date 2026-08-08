//! Owns bounded generation-checked storage for active linked closure sources.

module wheeler.compiler.closure.active_source_slots;

classical class ActiveSourceSlots {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long MAX_SLOT_GENERATION = 1000000;
  /// Names the fixed number of concurrently active linked-source owners.
  public const long ACTIVE_SOURCE_SLOT_COUNT = 8;
  /// Names the complete mutable linked-source storage capacity.
  public const long ACTIVE_SOURCE_SLOT_BYTES = 262144;
  /// Names storage plus five eight-word metadata columns.
  public const long ACTIVE_SOURCE_SLOT_ARENA_BYTES = 262464;

  /// Identifies one slot lease. Generation changes whenever the slot is reused.
  public record ActiveSourceHandle(long slot, long generation, long owner) {}

  /// Defines acquisition success and bounded-capacity exhaustion.
  public variant ActiveSourceAcquireResult {
    case Value(ActiveSourceHandle handle);
    case Full(long owner);
  }

  private boolean columnsValid(
    borrow mut bytes storage,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words lengths,
    borrow mut words live
  ) {
    if (bufferLength(storage) == ACTIVE_SOURCE_SLOT_BYTES) {} else {
      return false;
    }

    if (bufferLength(owners) == ACTIVE_SOURCE_SLOT_COUNT) {} else {
      return false;
    }

    if (bufferLength(generations) == ACTIVE_SOURCE_SLOT_COUNT) {} else {
      return false;
    }

    if (bufferLength(lengths) == ACTIVE_SOURCE_SLOT_COUNT) {} else {
      return false;
    }

    return bufferLength(live) == ACTIVE_SOURCE_SLOT_COUNT;
  }

  private boolean handleValid(
    ActiveSourceHandle handle,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words live
  ) {
    if (-1 < handle.slot) {} else {
      return false;
    }

    if (handle.slot < ACTIVE_SOURCE_SLOT_COUNT) {} else {
      return false;
    }

    if (live[handle.slot] == 1) {} else {
      return false;
    }

    if (owners[handle.slot] == handle.owner) {} else {
      return false;
    }

    return generations[handle.slot] == handle.generation;
  }

  private boolean sourceFits(borrow utf8 source) {
    long length = bufferLength(source);
    if (0 < length) {} else {
      return false;
    }

    if (length < MAX_SOURCE_BYTES + 1) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      if (utf8Width(source, cursor) == 1) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  /// Initializes empty slot metadata after validating every storage extent.
  public boolean initializeActiveSourceSlots(
    borrow mut bytes storage,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words lengths,
    borrow mut words live
  ) {
    if (columnsValid(storage, owners, generations, lengths, live)) {} else {
      return false;
    }

    long slot = 0;
    while (slot < ACTIVE_SOURCE_SLOT_COUNT) limit ACTIVE_SOURCE_SLOT_COUNT {
      set(owners, slot, -1);
      set(generations, slot, 0);
      set(lengths, slot, 0);
      set(live, slot, 0);
      slot += 1;
    }

    return true;
  }

  /// Acquires the lowest free slot and advances its bounded generation.
  public ActiveSourceAcquireResult acquireActiveSourceSlot(
    long owner,
    borrow mut bytes storage,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words lengths,
    borrow mut words live
  ) {
    assert(columnsValid(storage, owners, generations, lengths, live));
    assert(-1 < owner);
    assert(owner < MAX_LOCAL_MODULES);
    long slot = 0;
    while (slot < ACTIVE_SOURCE_SLOT_COUNT) limit ACTIVE_SOURCE_SLOT_COUNT {
      if (live[slot] == 0) {
        long generation = generations[slot] + 1;
        assert(generation < MAX_SLOT_GENERATION + 1);
        set(generations, slot, generation);
        set(owners, slot, owner);
        set(lengths, slot, 0);
        set(live, slot, 1);
        ActiveSourceHandle handle = new ActiveSourceHandle(slot, generation, owner);
        return new ActiveSourceAcquireResult.Value(handle);
      }

      slot += 1;
    }

    return new ActiveSourceAcquireResult.Full(owner);
  }

  /// Publishes one validated ASCII source under a current slot lease.
  public boolean publishActiveSource(
    ActiveSourceHandle handle,
    borrow utf8 source,
    borrow mut bytes storage,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words lengths,
    borrow mut words live
  ) {
    if (columnsValid(storage, owners, generations, lengths, live)) {} else {
      return false;
    }

    if (handleValid(handle, owners, generations, live)) {} else {
      return false;
    }

    if (sourceFits(source)) {} else {
      return false;
    }

    long oldLength = lengths[handle.slot];
    long slotStart = handle.slot * MAX_SOURCE_BYTES;
    long cursor = 0;
    while (cursor < bufferLength(source)) limit MAX_SOURCE_BYTES {
      setByte(storage, slotStart + cursor, utf8Scalar(source, cursor));
      cursor += 1;
    }

    while (cursor < oldLength) limit MAX_SOURCE_BYTES {
      setByte(storage, slotStart + cursor, 0);
      cursor += 1;
    }

    set(lengths, handle.slot, bufferLength(source));
    return true;
  }

  /// Returns a current published source length or minus one for a stale lease.
  public long activeSourceLength(
    ActiveSourceHandle handle,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words lengths,
    borrow mut words live
  ) {
    if (handleValid(handle, owners, generations, live)) {} else {
      return -1;
    }

    return lengths[handle.slot];
  }

  /// Copies one current exact-length source without mutating output on rejection.
  public boolean copyActiveSource(
    ActiveSourceHandle handle,
    borrow mut bytes storage,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words lengths,
    borrow mut words live,
    borrow mut bytes output
  ) {
    if (columnsValid(storage, owners, generations, lengths, live)) {} else {
      return false;
    }

    if (handleValid(handle, owners, generations, live)) {} else {
      return false;
    }

    long length = lengths[handle.slot];
    if (0 < length) {} else {
      return false;
    }

    if (bufferLength(output) == length) {} else {
      return false;
    }

    long slotStart = handle.slot * MAX_SOURCE_BYTES;
    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      setByte(output, cursor, storage[slotStart + cursor]);
      cursor += 1;
    }

    return true;
  }

  /// Releases one current lease and destroys its published source bytes.
  public boolean releaseActiveSource(
    ActiveSourceHandle handle,
    borrow mut bytes storage,
    borrow mut words owners,
    borrow mut words generations,
    borrow mut words lengths,
    borrow mut words live
  ) {
    if (columnsValid(storage, owners, generations, lengths, live)) {} else {
      return false;
    }

    if (handleValid(handle, owners, generations, live)) {} else {
      return false;
    }

    long length = lengths[handle.slot];
    long slotStart = handle.slot * MAX_SOURCE_BYTES;
    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      setByte(storage, slotStart + cursor, 0);
      cursor += 1;
    }

    set(owners, handle.slot, -1);
    set(lengths, handle.slot, 0);
    set(live, handle.slot, 0);
    return true;
  }
}
