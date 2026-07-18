package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Bounded region and owned-buffer state with explicit rewind deltas. */
final class OwnedStore {
  static final int MAX_REGIONS = 65_535;
  static final int MAX_BUFFERS = 65_535;
  static final long MAX_REGION_BYTES = 1L << 30;

  record Change(
      int previousRegionCount,
      int previousBufferCount,
      int changedRegion,
      RegionValue previousRegion,
      int changedBuffer,
      BufferValue previousBuffer) {
    static Change mark(OwnedStore store) {
      return new Change(store.regions.size(), store.buffers.size(), -1, null, -1, null);
    }

    Change region(int index, RegionValue value) {
      return new Change(
          previousRegionCount, previousBufferCount, index, value,
          changedBuffer, previousBuffer);
    }

    Change buffer(int index, BufferValue value) {
      return new Change(
          previousRegionCount, previousBufferCount, changedRegion, previousRegion,
          index, value);
    }
  }

  record Allocation(long handle, Change change) {}

  private final List<RegionValue> regions = new ArrayList<>();
  private final List<BufferValue> buffers = new ArrayList<>();

  Change mark() {
    return Change.mark(this);
  }

  Allocation createRegion(long maxBytes, int maxObjects, Change change) {
    validateRegionLimits(maxBytes, maxObjects);
    if (regions.size() >= MAX_REGIONS) {
      throw new VmTrap("Region table limit exceeded");
    }
    int id = regions.size();
    regions.add(new RegionValue(id, maxBytes, maxObjects, 0, 0, false));
    return new Allocation(id + 1L, change);
  }

  Allocation allocate(long regionHandle, int length, Change change) {
    RegionValue region = requireLiveRegion(regionHandle);
    long bytes = Math.multiplyExact((long) length, Long.BYTES);
    if (length <= 0
        || bytes > region.maxBytes() - region.usedBytes()
        || region.liveObjects() >= region.maxObjects()
        || buffers.size() >= MAX_BUFFERS) {
      throw new VmTrap("Region allocation limit exceeded");
    }
    int regionIndex = region.id();
    Change updated = change.region(regionIndex, region);
    regions.set(regionIndex, new RegionValue(
        region.id(), region.maxBytes(), region.maxObjects(),
        region.usedBytes() + bytes, region.liveObjects() + 1, false));
    int id = buffers.size();
    buffers.add(new BufferValue(
        id, region.id(), Collections.nCopies(length, 0L), false));
    return new Allocation(id + 1L, updated);
  }

  long get(long bufferHandle, int index) {
    BufferValue buffer = requireLiveBuffer(bufferHandle);
    checkIndex(buffer, index);
    requireLiveRegion(buffer.regionId() + 1L);
    return buffer.elements().get(index);
  }

  Change set(long bufferHandle, int index, long value, Change change) {
    BufferValue buffer = requireLiveBuffer(bufferHandle);
    checkIndex(buffer, index);
    requireLiveRegion(buffer.regionId() + 1L);
    List<Long> elements = new ArrayList<>(buffer.elements());
    elements.set(index, value);
    buffers.set(buffer.id(), new BufferValue(
        buffer.id(), buffer.regionId(), elements, false));
    return change.buffer(buffer.id(), buffer);
  }

  Change dropBuffer(long bufferHandle, Change change) {
    BufferValue buffer = requireLiveBuffer(bufferHandle);
    RegionValue region = requireLiveRegion(buffer.regionId() + 1L);
    long bytes = Math.multiplyExact((long) buffer.elements().size(), Long.BYTES);
    Change updated = change.region(region.id(), region).buffer(buffer.id(), buffer);
    buffers.set(buffer.id(), new BufferValue(
        buffer.id(), buffer.regionId(), buffer.elements(), true));
    regions.set(region.id(), new RegionValue(
        region.id(), region.maxBytes(), region.maxObjects(),
        region.usedBytes() - bytes, region.liveObjects() - 1, false));
    return updated;
  }

  Change dropRegion(long regionHandle, Change change) {
    RegionValue region = requireLiveRegion(regionHandle);
    if (region.liveObjects() != 0 || region.usedBytes() != 0) {
      throw new VmTrap("Cannot drop a region with live buffers");
    }
    regions.set(region.id(), new RegionValue(
        region.id(), region.maxBytes(), region.maxObjects(), 0, 0, true));
    return change.region(region.id(), region);
  }

  void validateRegionLimits(long maxBytes, int maxObjects) {
    if (maxBytes <= 0 || maxBytes > MAX_REGION_BYTES
        || maxObjects <= 0 || maxObjects > MAX_BUFFERS
        || regions.size() >= MAX_REGIONS) {
      throw new VmTrap("Invalid region limits");
    }
  }

  void validateAllocation(long regionHandle, int length) {
    RegionValue region = requireLiveRegion(regionHandle);
    long bytes;
    try {
      bytes = Math.multiplyExact((long) length, Long.BYTES);
    } catch (ArithmeticException exception) {
      throw new VmTrap("Region allocation limit exceeded");
    }
    if (length <= 0
        || bytes > region.maxBytes() - region.usedBytes()
        || region.liveObjects() >= region.maxObjects()
        || buffers.size() >= MAX_BUFFERS) {
      throw new VmTrap("Region allocation limit exceeded");
    }
  }

  void validateGet(long bufferHandle, int index) {
    BufferValue buffer = requireLiveBuffer(bufferHandle);
    checkIndex(buffer, index);
    requireLiveRegion(buffer.regionId() + 1L);
  }

  void validateDropBuffer(long bufferHandle) {
    BufferValue buffer = requireLiveBuffer(bufferHandle);
    requireLiveRegion(buffer.regionId() + 1L);
  }

  void validateDropRegion(long regionHandle) {
    RegionValue region = requireLiveRegion(regionHandle);
    if (region.liveObjects() != 0 || region.usedBytes() != 0) {
      throw new VmTrap("Cannot drop a region with live buffers");
    }
  }

  void rewind(Change change) {
    while (buffers.size() > change.previousBufferCount()) {
      buffers.removeLast();
    }
    while (regions.size() > change.previousRegionCount()) {
      regions.removeLast();
    }
    if (change.changedBuffer() >= 0) {
      buffers.set(change.changedBuffer(), change.previousBuffer());
    }
    if (change.changedRegion() >= 0) {
      regions.set(change.changedRegion(), change.previousRegion());
    }
  }

  List<RegionValue> regions() {
    return List.copyOf(regions);
  }

  List<BufferValue> buffers() {
    return List.copyOf(buffers);
  }

  private RegionValue requireLiveRegion(long handle) {
    if (handle <= 0 || handle > regions.size()) {
      throw new VmTrap("Invalid region handle " + handle);
    }
    RegionValue region = regions.get(Math.toIntExact(handle - 1));
    if (region.dropped()) {
      throw new VmTrap("Use after region drop");
    }
    return region;
  }

  private BufferValue requireLiveBuffer(long handle) {
    if (handle <= 0 || handle > buffers.size()) {
      throw new VmTrap("Invalid buffer handle " + handle);
    }
    BufferValue buffer = buffers.get(Math.toIntExact(handle - 1));
    if (buffer.dropped()) {
      throw new VmTrap("Use after buffer drop");
    }
    return buffer;
  }

  private static void checkIndex(BufferValue buffer, int index) {
    if (index < 0 || index >= buffer.elements().size()) {
      throw new VmTrap("Buffer index out of bounds: " + index);
    }
  }
}
