package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Canonical immutable repository snapshot tests. */
final class RepositorySnapshotTest {
  private static final String A = "aa".repeat(32);
  private static final String B = "bb".repeat(32);
  private static final String C = "cc".repeat(32);
  private static final String D = "dd".repeat(32);

  @Test
  void sortsAndRoundTripsExactCoordinateMappings() {
    RepositorySnapshot snapshot = new RepositorySnapshot(List.of(
        new RepositorySnapshot.Entry("demo.tool", "2.0.0", C, D),
        new RepositorySnapshot.Entry("demo.base", "1.0.0", A, B)));

    RepositorySnapshot decoded = RepositorySnapshot.parse(snapshot.canonicalBytes());

    assertEquals(snapshot, decoded);
    assertEquals("demo.base", decoded.releases().getFirst().name());
    assertEquals(64, decoded.identity().length());
  }

  @Test
  void rejectsDuplicateCoordinatesAndNoncanonicalOrder() {
    assertThrows(PackageFormatException.class, () -> new RepositorySnapshot(List.of(
        new RepositorySnapshot.Entry("demo.base", "1.0.0", A, B),
        new RepositorySnapshot.Entry("demo.base", "1.0.0", C, D))));

    RepositorySnapshot snapshot = new RepositorySnapshot(List.of(
        new RepositorySnapshot.Entry("demo.base", "1.0.0", A, B),
        new RepositorySnapshot.Entry("demo.tool", "2.0.0", C, D)));
    String reversed = snapshot.canonicalText()
        .replace("demo.base", "demo.swap")
        .replace("demo.tool", "demo.base")
        .replace("demo.swap", "demo.tool");
    assertThrows(PackageFormatException.class, () ->
        RepositorySnapshot.parse(reversed.getBytes(StandardCharsets.UTF_8)));
  }

  @Test
  void emptySnapshotHasOneCanonicalIdentity() {
    RepositorySnapshot snapshot = new RepositorySnapshot(List.of());

    assertEquals("schema: 1\nreleases: []\n", snapshot.canonicalText());
    assertEquals(snapshot, RepositorySnapshot.parse(snapshot.canonicalBytes()));
  }
}
