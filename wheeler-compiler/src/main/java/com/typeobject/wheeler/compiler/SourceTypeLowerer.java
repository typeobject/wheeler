package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.core.bytecode.ArrayType;
import com.typeobject.wheeler.core.bytecode.RecordType;
import com.typeobject.wheeler.core.bytecode.SliceType;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.core.bytecode.VariantType;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Canonical source aggregate descriptor and type-reference construction. */
final class SourceTypeLowerer {
  record LoweredTypes(
      List<RecordType> records,
      List<VariantType> variants,
      List<ArrayType> arrays,
      List<SliceType> slices,
      Map<String, ValueType> references) {}

  LoweredTypes lower(SourceProgram source) {
    List<RecordType> records = records(source);
    List<VariantType> variants = variants(source, records);
    List<ArrayType> arrays = arrays(source, records, variants);
    List<SliceType> slices = slices(source, records, variants, arrays);
    return new LoweredTypes(
        records,
        variants,
        arrays,
        slices,
        references(source, records, variants, arrays, slices));
  }

  static ValueType resolve(String type, int line, Map<String, ValueType> references) {
    ValueType result = references.get(type);
    if (result == null) {
      throw new CompilerException(line, "unsupported value type: " + type);
    }
    return result;
  }

  private static List<RecordType> records(SourceProgram source) {
    List<RecordType> result = new ArrayList<>();
    Map<String, ValueType> types = scalars();
    Set<String> names = new HashSet<>();
    for (SourceModel.RecordDefinition record : source.records()) {
      if (!names.add(record.name())) {
        throw new CompilerException(record.line(), "duplicate record type: " + record.name());
      }
      List<RecordType.Field> fields = record.fields().stream()
          .map(field -> new RecordType.Field(
              field.name(), resolve(field.type(), record.line(), types)))
          .toList();
      RecordType descriptor = new RecordType(result.size(), record.name(), fields);
      result.add(descriptor);
      types.put(record.name(), ValueType.record(descriptor.id()));
    }
    return List.copyOf(result);
  }

  private static List<VariantType> variants(
      SourceProgram source, List<RecordType> records) {
    List<VariantType> result = new ArrayList<>();
    Map<String, ValueType> types = scalars();
    records.forEach(record -> types.put(record.name(), ValueType.record(record.id())));
    for (SourceModel.VariantDefinition variant : source.variants()) {
      List<VariantType.Case> cases = variant.cases().stream()
          .map(variantCase -> new VariantType.Case(
              variantCase.name(),
              variantCase.fields().stream()
                  .map(field -> new RecordType.Field(
                      field.name(), resolve(field.type(), variant.line(), types)))
                  .toList()))
          .toList();
      VariantType descriptor = new VariantType(result.size(), variant.name(), cases);
      result.add(descriptor);
      types.put(variant.name(), ValueType.variant(descriptor.id()));
    }
    return List.copyOf(result);
  }

  private static List<ArrayType> arrays(
      SourceProgram source, List<RecordType> records, List<VariantType> variants) {
    List<ArrayType> result = new ArrayList<>();
    Map<String, ValueType> types = scalars();
    records.forEach(record -> types.put(record.name(), ValueType.record(record.id())));
    variants.forEach(variant -> types.put(variant.name(), ValueType.variant(variant.id())));
    for (SourceModel.ArrayDefinition array : source.arrays()) {
      ValueType element = resolve(array.elementType(), array.line(), types);
      ArrayType descriptor = new ArrayType(result.size(), element, array.length());
      result.add(descriptor);
      types.put(array.name(), ValueType.array(descriptor.id()));
    }
    return List.copyOf(result);
  }

  private static List<SliceType> slices(
      SourceProgram source,
      List<RecordType> records,
      List<VariantType> variants,
      List<ArrayType> arrays) {
    Map<String, ValueType> types = baseReferences(source, records, variants, arrays);
    List<SliceType> result = new ArrayList<>();
    for (SourceModel.SliceDefinition slice : source.slices()) {
      ValueType element = resolve(slice.elementType(), slice.line(), types);
      SliceType descriptor = new SliceType(result.size(), element);
      result.add(descriptor);
      types.put(slice.name(), ValueType.slice(descriptor.id()));
    }
    return List.copyOf(result);
  }

  private static Map<String, ValueType> references(
      SourceProgram source,
      List<RecordType> records,
      List<VariantType> variants,
      List<ArrayType> arrays,
      List<SliceType> slices) {
    Map<String, ValueType> result = baseReferences(source, records, variants, arrays);
    for (int index = 0; index < slices.size(); index++) {
      result.put(source.slices().get(index).name(), ValueType.slice(slices.get(index).id()));
    }
    result.put("region", ValueType.REGION);
    result.put("words", ValueType.WORDS);
    result.put("bytes", ValueType.BYTES);
    result.put("longmap", ValueType.LONG_MAP);
    return Map.copyOf(result);
  }

  private static Map<String, ValueType> baseReferences(
      SourceProgram source,
      List<RecordType> records,
      List<VariantType> variants,
      List<ArrayType> arrays) {
    Map<String, ValueType> result = scalars();
    records.forEach(record -> result.put(record.name(), ValueType.record(record.id())));
    variants.forEach(variant -> result.put(variant.name(), ValueType.variant(variant.id())));
    for (int index = 0; index < arrays.size(); index++) {
      result.put(source.arrays().get(index).name(), ValueType.array(arrays.get(index).id()));
    }
    return result;
  }

  private static Map<String, ValueType> scalars() {
    Map<String, ValueType> result = new LinkedHashMap<>();
    result.put("long", ValueType.SIGNED);
    result.put("boolean", ValueType.BOOLEAN);
    return result;
  }
}
