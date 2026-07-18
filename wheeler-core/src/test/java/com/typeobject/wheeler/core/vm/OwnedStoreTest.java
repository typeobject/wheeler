package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

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
