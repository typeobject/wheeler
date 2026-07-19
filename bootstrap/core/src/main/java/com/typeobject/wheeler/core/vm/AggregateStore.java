package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Deterministic intern tables for immutable aggregate VM values. */
final class AggregateStore {
  static final int MAX_VALUES_PER_KIND = 65_535;

  record Counts(int records, int variants, int arrays, int slices) {}

  private final List<RecordValue> records = new ArrayList<>();
  private final Map<RecordValue, Integer> recordHandles = new LinkedHashMap<>();
  private final List<VariantValue> variants = new ArrayList<>();
  private final Map<VariantValue, Integer> variantHandles = new LinkedHashMap<>();
  private final List<ArrayValue> arrays = new ArrayList<>();
  private final Map<ArrayValue, Integer> arrayHandles = new LinkedHashMap<>();
  private final List<SliceValue> slices = new ArrayList<>();
  private final Map<SliceValue, Integer> sliceHandles = new LinkedHashMap<>();

  Counts counts() {
    return new Counts(records.size(), variants.size(), arrays.size(), slices.size());
  }

  void rewind(Counts counts) {
    trim(records, recordHandles, counts.records());
    trim(variants, variantHandles, counts.variants());
    trim(arrays, arrayHandles, counts.arrays());
    trim(slices, sliceHandles, counts.slices());
  }

  int intern(RecordValue value) {
    return intern(records, recordHandles, value, "record");
  }

  int intern(VariantValue value) {
    return intern(variants, variantHandles, value, "variant");
  }

  int intern(ArrayValue value) {
    return intern(arrays, arrayHandles, value, "array");
  }

  int intern(SliceValue value) {
    return intern(slices, sliceHandles, value, "slice");
  }

  boolean fullForNew(RecordValue value) {
    return !recordHandles.containsKey(value) && records.size() >= MAX_VALUES_PER_KIND;
  }

  boolean fullForNew(VariantValue value) {
    return !variantHandles.containsKey(value) && variants.size() >= MAX_VALUES_PER_KIND;
  }

  boolean fullForNew(ArrayValue value) {
    return !arrayHandles.containsKey(value) && arrays.size() >= MAX_VALUES_PER_KIND;
  }

  boolean fullForNew(SliceValue value) {
    return !sliceHandles.containsKey(value) && slices.size() >= MAX_VALUES_PER_KIND;
  }

  RecordValue record(long handle) {
    return require(records, handle, "record");
  }

  VariantValue variant(long handle) {
    return require(variants, handle, "variant");
  }

  ArrayValue array(long handle) {
    return require(arrays, handle, "array");
  }

  SliceValue slice(long handle) {
    return require(slices, handle, "slice");
  }

  List<RecordValue> records() {
    return List.copyOf(records);
  }

  List<VariantValue> variants() {
    return List.copyOf(variants);
  }

  List<ArrayValue> arrays() {
    return List.copyOf(arrays);
  }

  List<SliceValue> slices() {
    return List.copyOf(slices);
  }

  private static <T> int intern(
      List<T> values, Map<T, Integer> handles, T value, String description) {
    Integer handle = handles.get(value);
    if (handle != null) {
      return handle;
    }
    if (values.size() >= MAX_VALUES_PER_KIND) {
      throw new VmTrap("Too many distinct " + description + " values");
    }
    values.add(value);
    int created = values.size();
    handles.put(value, created);
    return created;
  }

  private static <T> T require(List<T> values, long handle, String description) {
    if (handle <= 0 || handle > values.size()) {
      throw new VmTrap("Invalid " + description + " handle " + handle);
    }
    return values.get(Math.toIntExact(handle - 1));
  }

  private static <T> void trim(List<T> values, Map<T, Integer> handles, int size) {
    while (values.size() > size) {
      handles.remove(values.removeLast());
    }
  }
}
