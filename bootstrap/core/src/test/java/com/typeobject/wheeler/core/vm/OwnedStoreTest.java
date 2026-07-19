package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

/** Conformance tests for affine owned storage, borrows, mutation, and deterministic maps. */
class OwnedStoreTest {
  @Test
  void boundedMapSupportsZeroKeysUpdatesMembershipAndRewind() {
    OwnedStore store = new OwnedStore();
    OwnedStore.Allocation region = store.createRegion(48, 1, store.mark());
    OwnedStore.Allocation map = store.allocate(
        region.handle(), 2, BufferKind.LONG_MAP, store.mark());
    store.mapPut(map.handle(), 0, 5, store.mark());
    OwnedStore.Change second = store.mapPut(map.handle(), 7, 9, store.mark());

    assertTrue(store.mapHas(map.handle(), 0));
    assertTrue(store.mapHas(map.handle(), 7));
    assertFalse(store.mapHas(map.handle(), 3));
    assertEquals(5, store.mapGet(map.handle(), 0));
    assertEquals(9, store.mapGet(map.handle(), 7));

    OwnedStore.Change update = store.mapPut(map.handle(), 0, 11, store.mark());
    assertEquals(11, store.mapGet(map.handle(), 0));
    store.rewind(update);
    assertEquals(5, store.mapGet(map.handle(), 0));

    assertThrows(VmTrap.class, () -> store.mapPut(map.handle(), 8, 13, store.mark()));
    assertFalse(store.mapHas(map.handle(), 8));

    store.rewind(second);
    assertFalse(store.mapHas(map.handle(), 7));
  }

  @Test
  void freezingUtf8RejectsMalformedBytesPreventsMutationAndRewinds() {
    OwnedStore store = new OwnedStore();
    OwnedStore.Allocation region = store.createRegion(3, 1, store.mark());
    OwnedStore.Allocation bytes = store.allocate(
        region.handle(), 3, BufferKind.BYTES, store.mark());
    store.set(bytes.handle(), 0, 65, BufferKind.BYTES, store.mark());
    store.set(bytes.handle(), 1, 0xe2, BufferKind.BYTES, store.mark());
    assertThrows(VmTrap.class, () -> store.freezeUtf8(bytes.handle(), store.mark()));

    store.set(bytes.handle(), 1, 0xc2, BufferKind.BYTES, store.mark());
    store.set(bytes.handle(), 2, 0xa2, BufferKind.BYTES, store.mark());
    OwnedStore.Change freeze = store.freezeUtf8(bytes.handle(), store.mark());
    assertEquals(2, Utf8.analyze(store.utf8Bytes(bytes.handle())).scalarCount());
    assertThrows(VmTrap.class, () ->
        store.set(bytes.handle(), 0, 66, BufferKind.BYTES, store.mark()));

    store.rewind(freeze);
    store.set(bytes.handle(), 0, 66, BufferKind.BYTES, store.mark());
    assertEquals(66, store.get(bytes.handle(), 0, BufferKind.BYTES));
  }

  @Test
  void absentMapLookupAndWrongBufferKindsTrap() {
    OwnedStore store = new OwnedStore();
    OwnedStore.Allocation region = store.createRegion(32, 2, store.mark());
    OwnedStore.Allocation map = store.allocate(
        region.handle(), 1, BufferKind.LONG_MAP, store.mark());
    OwnedStore.Allocation words = store.allocate(
        region.handle(), 1, BufferKind.WORDS, store.mark());

    assertThrows(VmTrap.class, () -> store.mapGet(map.handle(), 1));
    assertThrows(VmTrap.class, () -> store.mapHas(words.handle(), 1));
  }
}
