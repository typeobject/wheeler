//! Provides deterministic operations over caller-owned bounded signed maps.

module wheeler.core.collections.long_map;
classical class LongMap {
    /// Inserts or replaces one key and returns the stored value.
    public long putAndGet(longmap values, long key, long value) {
        put(values, key, value);
        return mapGet(values, key);
    }

    /// Reports whether caller-owned map storage contains `key`.
    public boolean containsKey(longmap values, long key) {
        return mapHas(values, key);
    }
}
