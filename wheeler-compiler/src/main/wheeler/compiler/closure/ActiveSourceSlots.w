//! Owns bounded generation-checked storage for active linked closure sources.

module wheeler.compiler.closure.active_source_slots;

classical class ActiveSourceSlots {
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long MAX_SLOT_GENERATION = 1000000;
  private const long ASCII_BYTE_LIMIT = 128;
  private const long SLOT_METADATA_COLUMNS = 4;
  private const long WORD_BYTES = 8;
  /// Names the fixed number of concurrently active linked-source owners.
  public const long ACTIVE_SOURCE_SLOT_COUNT = 8;
  /// Names the complete mutable linked-source storage capacity.
  public const long ACTIVE_SOURCE_SLOT_BYTES = ACTIVE_SOURCE_SLOT_COUNT * MAX_SOURCE_BYTES;
  /// Counts storage and its four metadata buffers.
  public const long ACTIVE_SOURCE_SLOT_BUFFERS = 1 + SLOT_METADATA_COLUMNS;
  /// Names storage plus the owner, generation, length, and live columns.
  public const long ACTIVE_SOURCE_SLOT_ARENA_BYTES = ACTIVE_SOURCE_SLOT_BYTES
    + SLOT_METADATA_COLUMNS * ACTIVE_SOURCE_SLOT_COUNT * WORD_BYTES;

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

    if (handle.owner < 0) {
      return false;
    }

    if (handle.owner < MAX_LOCAL_MODULES) {} else {
      return false;
    }

    if (handle.generation < 1) {
      return false;
    }

    if (MAX_SLOT_GENERATION < handle.generation) {
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

  private boolean sourceFits(borrow byteview source, long start, long length) {
    if (start < 0) {
      return false;
    }

    if (bufferLength(source) < start) {
      return false;
    }

    if (bufferLength(source) - start < length) {
      return false;
    }

    if (0 < length) {} else {
      return false;
    }

    if (length < MAX_SOURCE_BYTES + 1) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < length) limit MAX_SOURCE_BYTES {
      if (source[start + cursor] < ASCII_BYTE_LIMIT) {} else {
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
        assert(-1 < generations[slot]);
        assert(generations[slot] < MAX_SLOT_GENERATION);
        long generation = generations[slot] + 1;
        ActiveSourceHandle handle = new ActiveSourceHandle(slot, generation, owner);
        ActiveSourceAcquireResult result = new ActiveSourceAcquireResult.Value(handle);
        set(generations, slot, generation);
        set(owners, slot, owner);
        set(lengths, slot, 0);
        set(live, slot, 1);
        return result;
      }

      slot += 1;
    }

    return new ActiveSourceAcquireResult.Full(owner);
  }

  /// Publishes one complete immutable ASCII byte range under a current slot lease.
  public boolean publishActiveSource(
    ActiveSourceHandle handle,
    borrow byteview source,
    long sourceStart,
    long sourceLength,
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

    if (sourceFits(source, sourceStart, sourceLength)) {} else {
      return false;
    }

    long oldLength = lengths[handle.slot];
    if (oldLength < 0) {
      return false;
    }

    if (MAX_SOURCE_BYTES < oldLength) {
      return false;
    }

    long slotStart = handle.slot * MAX_SOURCE_BYTES;
    long cursor = 0;
    while (cursor < sourceLength) limit MAX_SOURCE_BYTES {
      setByte(storage, slotStart + cursor, source[sourceStart + cursor]);
      cursor += 1;
    }

    while (cursor < oldLength) limit MAX_SOURCE_BYTES {
      setByte(storage, slotStart + cursor, 0);
      cursor += 1;
    }

    set(lengths, handle.slot, sourceLength);
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
