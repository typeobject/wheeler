package com.typeobject.wheeler.core.bytecode;

import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

/** Canonical nominal record descriptor with ordered typed fields. */
public record RecordType(int id, String name, List<Field> fields) {
  public RecordType {
    if (id < 0 || id > 0x0fff_ffff || name == null || name.isBlank()
        || fields.isEmpty() || fields.size() > 65_535) {
      throw new IllegalArgumentException("Invalid record type descriptor");
    }
    fields = List.copyOf(fields);
    Set<String> names = new HashSet<>();
    for (Field field : fields) {
      if (!names.add(field.name())) {
        throw new IllegalArgumentException("Duplicate record field " + field.name());
      }
    }
  }

  public record Field(String name, ValueType type) {
    public Field {
      if (name == null || name.isBlank()) {
        throw new IllegalArgumentException("Invalid record field name");
      }
      Objects.requireNonNull(type, "type");
    }
  }
}
