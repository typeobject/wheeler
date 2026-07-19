package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.packageformat.BootstrapManifest.DiverseDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.OrdinaryDerivation;
import com.typeobject.wheeler.packageformat.BootstrapManifest.Source;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

/** Canonical bootstrap evidence schema tests. */
final class BootstrapManifestTest {
  private static final String A = "00".repeat(32);
  private static final String B = "11".repeat(32);
  private static final String C = "22".repeat(32);
  private static final String D = "33".repeat(32);
  private static final String E = "44".repeat(32);
  private static final String F = "55".repeat(32);
  private static final String G = "66".repeat(32);
  private static final String H = "77".repeat(32);
  private static final String I = "88".repeat(32);
  private static final String J = "99".repeat(32);
  private static final String K = "aa".repeat(32);
  private static final String L = "bb".repeat(32);
  private static final String M = "cc".repeat(32);
  private static final String N = "dd".repeat(32);

  @Test
  void roundTripsCanonicalFixedPointAndDiverseEvidence() {
    BootstrapManifest manifest = manifest();
    BootstrapManifest decoded = new BootstrapManifestParser().parse(manifest.canonicalBytes());

    assertEquals(manifest, decoded);
    assertEquals(manifest.canonicalText(), decoded.canonicalText());
    assertEquals(64, manifest.identity().length());
  }

  @Test
  void rejectsClaimsWithoutByteIdenticalDerivations() {
    Source source = new Source(A, B, C, "bootstrap-1", D, E);
    OrdinaryDerivation ordinary = new OrdinaryDerivation(F, G, H, I, J, J, K);

    assertThrows(PackageFormatException.class, () -> new BootstrapManifest(
        source, new OrdinaryDerivation(F, G, H, I, J, L, K),
        new DiverseDerivation(L, M, H, I, J, K), N));
    assertThrows(PackageFormatException.class, () -> new BootstrapManifest(
        source, ordinary, new DiverseDerivation(L, M, H, I, L, K), N));
    assertThrows(PackageFormatException.class, () -> new BootstrapManifest(
        source, ordinary, new DiverseDerivation(L, M, H, I, J, L), N));
    assertThrows(PackageFormatException.class, () -> new BootstrapManifest(
        source, ordinary, new DiverseDerivation(F, M, H, I, J, K), N));
    assertThrows(PackageFormatException.class, () -> new BootstrapManifest(
        source, ordinary, new DiverseDerivation(L, G, H, I, J, K), N));
  }

  @Test
  void rejectsUnknownFieldsAndNoncanonicalIdentities() {
    String unknown = manifest().canonicalText().replace(
        "  artifact-set: \"" + N + "\"\n",
        "  artifact-set: \"" + N + "\"\n  perhaps: false\n");
    assertThrows(PackageFormatException.class, () ->
        new BootstrapManifestParser().parse(unknown.getBytes(StandardCharsets.UTF_8)));
    assertThrows(PackageFormatException.class, () ->
        new Source("ABC", B, C, "bootstrap-1", D, E));
  }

  private static BootstrapManifest manifest() {
    return new BootstrapManifest(
        new Source(A, B, C, "bootstrap-1", D, E),
        new OrdinaryDerivation(F, G, H, I, J, J, K),
        new DiverseDerivation(L, M, H, I, J, K),
        N);
  }
}
