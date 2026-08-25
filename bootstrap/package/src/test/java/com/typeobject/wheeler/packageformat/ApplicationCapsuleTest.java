package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Application capsule framing, identity, ownership, and rejection evidence. */
final class ApplicationCapsuleTest {
  @Test
  void roundTripsOneCanonicalAlignedCapsule() {
    ApplicationCapsule first = capsule(entries(false));
    ApplicationCapsule second = capsule(entries(true));
    byte[] bytes = first.canonicalBytes();
    ApplicationCapsule decoded = ApplicationCapsule.parse(bytes);

    assertArrayEquals(first.canonicalBytes(), second.canonicalBytes());
    assertEquals(first.identity(), decoded.identity());
    assertEquals(
        "393cbf9eb8c023ee47302b5f932a9c5ac2d63b02b2dc19c0e1983639e84b5dd7",
        first.identity());
    assertEquals(root(), decoded.root());
    assertEquals(receipts(), decoded.receipts());
    assertEquals(first.entries(), decoded.entries());
    assertEquals(4176, bytes.length);
    assertEquals(717, littleInt(bytes, 12));
    assertEquals(bytes.length, littleInt(bytes, 8));
    assertEquals(1, littleInt(bytes, 16));
    assertEquals(3, littleInt(bytes, 20));

    int wbcOffset = indexOf(bytes, wbcBytes());
    int resourceOffset = indexOf(bytes, resourceBytes());
    assertEquals(0, wbcOffset % 4096);
    assertEquals(0, resourceOffset % 64);
    assertTrue(wbcOffset >= littleInt(bytes, 12));
    assertTrue(resourceOffset > wbcOffset);

    byte[] owned = decoded.entries().getFirst().bytes();
    owned[0] ^= 1;
    byte[] returnedCapsule = decoded.canonicalBytes();
    returnedCapsule[0] ^= 1;
    assertArrayEquals(wbcBytes(), decoded.entries().getFirst().bytes());
    assertArrayEquals(bytes, decoded.canonicalBytes());
  }

  @Test
  void everyRootReceiptAndEntryClassEntersIdentity() {
    ApplicationCapsule baseline = capsule(entries(false));
    ApplicationCapsule changedResource = capsule(List.of(
        wbc(),
        new CapsuleEntry(
            CapsuleEntry.Kind.RESOURCE,
            "resources/banner.txt",
            64,
            CapsuleEntry.REQUIRED,
            "changed".getBytes(StandardCharsets.UTF_8)),
        provenance()));
    CapsuleRoot aotRoot = new CapsuleRoot(
        hash(1),
        "app",
        "bin/app.wbc",
        "wheeler.app::main",
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        hash(6),
        hash(7),
        NativeImagePlan.RuntimeMode.AOT,
        List.of("io:stderr/1", "io:stdout/1"));
    ApplicationCapsule changedMode = new ApplicationCapsule(aotRoot, receipts(), entries(false));
    CapsulePackageReceipt changedReceipt = new CapsulePackageReceipt(
        hash(8),
        "wheeler.app@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(12),
        "app",
        hash(1));
    ApplicationCapsule changedPrev =
        new ApplicationCapsule(root(), List.of(changedReceipt), entries(false));

    assertNotEquals(baseline.identity(), changedResource.identity());
    assertNotEquals(baseline.identity(), changedMode.identity());
    assertNotEquals(baseline.identity(), changedPrev.identity());
  }

  @Test
  void rejectsMalformedNoncanonicalAndCorruptedTransports() {
    byte[] canonical = capsule(entries(false)).canonicalBytes();

    byte[] badMagic = canonical.clone();
    badMagic[0] ^= 1;
    byte[] badLength = canonical.clone();
    putInt(badLength, 8, canonical.length - 1);
    byte[] reserved = canonical.clone();
    reserved[24] = 1;
    byte[] damagedEntry = canonical.clone();
    damagedEntry[indexOf(canonical, resourceBytes())] ^= 1;
    byte[] nonzeroPadding = canonical.clone();
    nonzeroPadding[indexOf(canonical, wbcBytes()) - 1] = 1;
    int rootName = indexOf(canonical, "bin/app.wbc".getBytes(StandardCharsets.UTF_8), 300);
    byte[] missingStartup = canonical.clone();
    missingStartup[rootName - 17] = CapsuleEntry.REQUIRED;
    byte[] unknownKind = canonical.clone();
    unknownKind[rootName - 18] = 99;
    byte[] unknownFlags = canonical.clone();
    unknownFlags[rootName - 17] = 4;
    byte[] badAlignment = canonical.clone();
    putInt(badAlignment, rootName - 14, 3);
    byte[] excessEntryLength = canonical.clone();
    putInt(excessEntryLength, rootName - 6, 16 * 1024 * 1024 + 1);
    byte[] malformedUtf8 = canonical.clone();
    int resourceName = indexOf(
        canonical, "resources/banner.txt".getBytes(StandardCharsets.UTF_8), 300);
    malformedUtf8[resourceName] = (byte) 0xc0;
    byte[] overlapping = canonical.clone();
    putInt(overlapping, rootName - 10, indexOf(canonical, resourceBytes()));
    int provenanceName = indexOf(
        canonical, "meta/provenance.yaml".getBytes(StandardCharsets.UTF_8), 300);
    byte[] reordered = canonical.clone();
    byte[] rootDescriptor = Arrays.copyOfRange(canonical, rootName - 18, resourceName - 18);
    byte[] resourceDescriptor =
        Arrays.copyOfRange(canonical, resourceName - 18, provenanceName - 18);
    System.arraycopy(resourceDescriptor, 0, reordered, rootName - 18, resourceDescriptor.length);
    System.arraycopy(
        rootDescriptor,
        0,
        reordered,
        rootName - 18 + resourceDescriptor.length,
        rootDescriptor.length);
    byte[] trailing = Arrays.copyOf(canonical, canonical.length + 1);

    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(badMagic));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(badLength));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(reserved));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(damagedEntry));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(nonzeroPadding));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(missingStartup));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(unknownKind));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(unknownFlags));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(badAlignment));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(excessEntryLength));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(malformedUtf8));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(overlapping));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(reordered));
    assertThrows(PackageFormatException.class, () -> ApplicationCapsule.parse(trailing));
  }

  @Test
  void rejectsInvalidBindingsAndEntryMetadata() {
    CapsuleEntry resource = new CapsuleEntry(
        CapsuleEntry.Kind.RESOURCE,
        "resources/banner.txt",
        64,
        CapsuleEntry.REQUIRED,
        resourceBytes());

    assertThrows(
        PackageFormatException.class,
        () -> new ApplicationCapsule(root(), receipts(), List.of(resource)));
    assertThrows(
        PackageFormatException.class,
        () -> new ApplicationCapsule(root(), receipts(), List.of(wbc(), resource, resource)));
    assertThrows(
        PackageFormatException.class,
        () -> new ApplicationCapsule(root(), List.of(receipts().getFirst(), receipts().getFirst()),
            entries(false)));
    assertThrows(
        PackageFormatException.class,
        () -> new CapsuleEntry(CapsuleEntry.Kind.WBC, "../app.wbc", 1,
            CapsuleEntry.STARTUP, wbcBytes()));
    assertThrows(
        PackageFormatException.class,
        () -> new CapsuleEntry(CapsuleEntry.Kind.WBC, "bin/app.wbc", 3,
            CapsuleEntry.STARTUP, wbcBytes()));
    assertThrows(
        PackageFormatException.class,
        () -> new CapsuleEntry(CapsuleEntry.Kind.RESOURCE, "resource", 1,
            CapsuleEntry.STARTUP, resourceBytes()));
    assertThrows(
        PackageFormatException.class,
        () -> new CapsuleRoot(
            hash(1), "app", "bin/app.wbc", "wheeler.app::main", hash(2), hash(3), hash(4),
            hash(5), hash(6), hash(7), NativeImagePlan.RuntimeMode.EMBEDDED_VM,
            List.of("io:stdout/1", "io:stderr/1")));
  }

  @Test
  void admitsExactEntryAndReceiptBounds() {
    ArrayList<CapsuleEntry> entries = new ArrayList<>();
    entries.add(wbc());
    for (int index = 1; index < ApplicationCapsule.MAX_ENTRIES; index++) {
      entries.add(new CapsuleEntry(
          CapsuleEntry.Kind.RESOURCE,
          "resources/entry-" + index,
          1,
          0,
          new byte[] {(byte) index}));
    }
    ArrayList<CapsulePackageReceipt> receipts = new ArrayList<>();
    receipts.add(receipts().getFirst());
    for (int index = 1; index < ApplicationCapsule.MAX_RECEIPTS; index++) {
      receipts.add(new CapsulePackageReceipt(
          hash(1000 + index),
          "dependency.package" + index + "@1.0.0",
          hash(2000 + index),
          "release",
          hash(3000 + index),
          hash(4000 + index),
          "library",
          hash(5000 + index)));
    }
    ApplicationCapsule terminal = new ApplicationCapsule(root(), receipts, entries);

    assertEquals(ApplicationCapsule.MAX_ENTRIES, terminal.entries().size());
    assertEquals(ApplicationCapsule.MAX_RECEIPTS, terminal.receipts().size());
    assertEquals(
        terminal.identity(),
        ApplicationCapsule.parse(terminal.canonicalBytes()).identity());

    entries.add(new CapsuleEntry(
        CapsuleEntry.Kind.RESOURCE, "resources/overflow", 1, 0, new byte[] {1}));
    assertThrows(
        PackageFormatException.class,
        () -> new ApplicationCapsule(root(), receipts, entries));
    receipts.add(new CapsulePackageReceipt(
        hash(9001), "overflow.package@1.0.0", hash(9002), "release", hash(9003),
        hash(9004), "library", hash(9005)));
    assertThrows(
        PackageFormatException.class,
        () -> new ApplicationCapsule(root(), receipts, terminal.entries()));
  }

  private static ApplicationCapsule capsule(List<CapsuleEntry> entries) {
    return new ApplicationCapsule(root(), receipts(), entries);
  }

  private static CapsuleRoot root() {
    return new CapsuleRoot(
        hash(1),
        "app",
        "bin/app.wbc",
        "wheeler.app::main",
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        hash(6),
        hash(7),
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        List.of("io:stderr/1", "io:stdout/1"));
  }

  private static List<CapsulePackageReceipt> receipts() {
    return List.of(new CapsulePackageReceipt(
        hash(8),
        "wheeler.app@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "app",
        hash(1)));
  }

  private static List<CapsuleEntry> entries(boolean reverse) {
    return reverse
        ? List.of(provenance(), resource(), wbc())
        : List.of(wbc(), resource(), provenance());
  }

  private static CapsuleEntry wbc() {
    return new CapsuleEntry(
        CapsuleEntry.Kind.WBC,
        "bin/app.wbc",
        4096,
        CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
        wbcBytes());
  }

  private static CapsuleEntry resource() {
    return new CapsuleEntry(
        CapsuleEntry.Kind.RESOURCE,
        "resources/banner.txt",
        64,
        CapsuleEntry.REQUIRED,
        resourceBytes());
  }

  private static CapsuleEntry provenance() {
    return new CapsuleEntry(
        CapsuleEntry.Kind.PROVENANCE,
        "meta/provenance.yaml",
        1,
        CapsuleEntry.REQUIRED,
        "schema: 1\n".getBytes(StandardCharsets.UTF_8));
  }

  private static byte[] wbcBytes() {
    return new byte[] {'W', 'B', 'C', 1};
  }

  private static byte[] resourceBytes() {
    return "hello\n".getBytes(StandardCharsets.UTF_8);
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }

  private static int littleInt(byte[] bytes, int offset) {
    return ByteBuffer.wrap(bytes, offset, Integer.BYTES).order(ByteOrder.LITTLE_ENDIAN).getInt();
  }

  private static void putInt(byte[] bytes, int offset, int value) {
    ByteBuffer.wrap(bytes, offset, Integer.BYTES).order(ByteOrder.LITTLE_ENDIAN).putInt(value);
  }

  private static int indexOf(byte[] haystack, byte[] needle) {
    return indexOf(haystack, needle, 0);
  }

  private static int indexOf(byte[] haystack, byte[] needle, int start) {
    outer:
    for (int index = start; index <= haystack.length - needle.length; index++) {
      for (int element = 0; element < needle.length; element++) {
        if (haystack[index + element] != needle[element]) {
          continue outer;
        }
      }
      return index;
    }
    throw new AssertionError("Fixture bytes not found");
  }
}
