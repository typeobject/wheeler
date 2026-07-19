package com.typeobject.wheeler.core.vm;

/** Immutable snapshot of one bounded owned allocation region. */
public record RegionValue(
    int id,
    long maxBytes,
    int maxObjects,
    long usedBytes,
    int liveObjects,
    boolean dropped) {
  public RegionValue {
    if (id < 0 || maxBytes <= 0 || maxObjects <= 0
        || usedBytes < 0 || usedBytes > maxBytes
        || liveObjects < 0 || liveObjects > maxObjects) {
      throw new IllegalArgumentException("Invalid region value");
    }
  }
}
