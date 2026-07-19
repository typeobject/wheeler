package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Canonical build-output mapping and quarantine schema tests. */
final class BuildOutputRecordTest {
  @Test
  void outputRecordRoundTripsExactCanonicalYaml() {
    BuildOutputRecord record = new BuildOutputRecord(
        "a".repeat(64), "b".repeat(64), 512);

    assertEquals(record, BuildOutputRecord.parse(record.canonicalBytes()));
    assertEquals(record.canonicalText(), new String(record.canonicalBytes(), StandardCharsets.UTF_8));
  }

  @Test
  void outputRecordRejectsUnknownFieldsAndInvalidBounds() {
    BuildOutputRecord record = new BuildOutputRecord(
        "a".repeat(64), "b".repeat(64), 512);
    String unknown = record.canonicalText() + "perhaps: true\n";

    assertThrows(PackageFormatException.class, () ->
        BuildOutputRecord.parse(unknown.getBytes(StandardCharsets.UTF_8)));
    assertThrows(PackageFormatException.class, () ->
        new BuildOutputRecord("a".repeat(64), "b".repeat(64), 0));
    assertThrows(PackageFormatException.class, () ->
        new BuildOutputQuarantine(
            "a".repeat(64), "b".repeat(64), "b".repeat(64), 512));
  }
}
