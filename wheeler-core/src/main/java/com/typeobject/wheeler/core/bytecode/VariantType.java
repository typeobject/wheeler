package com.typeobject.wheeler.core.bytecode;

import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Canonical nominal tagged-variant descriptor with ordered cases and payload fields. */
public record VariantType(int id, String name, List<Case> cases) {
  public VariantType {
    if (id < 0 || id > 0x0fff_ffff || name == null || name.isBlank()
        || cases.isEmpty() || cases.size() > 65_535) {
      throw new IllegalArgumentException("Invalid variant type descriptor");
    }
    cases = List.copyOf(cases);
    Set<String> names = new HashSet<>();
    for (Case variantCase : cases) {
      if (!names.add(variantCase.name())) {
        throw new IllegalArgumentException("Duplicate variant case " + variantCase.name());
      }
    }
  }

  public record Case(String name, List<RecordType.Field> fields) {
    public Case {
      if (name == null || name.isBlank() || fields.size() > 65_535) {
        throw new IllegalArgumentException("Invalid variant case");
      }
      fields = List.copyOf(fields);
      Set<String> names = new HashSet<>();
      for (RecordType.Field field : fields) {
        Objects.requireNonNull(field, "field");
        if (!names.add(field.name())) {
          throw new IllegalArgumentException("Duplicate variant payload field " + field.name());
        }
      }
    }
  }
}
