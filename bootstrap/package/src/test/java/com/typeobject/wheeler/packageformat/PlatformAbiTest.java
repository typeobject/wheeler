package com.typeobject.wheeler.packageformat;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Canonical platform ABI framing, bounds, and identity evidence. */
final class PlatformAbiTest {
  @Test
  void emitsOneCanonicalBoundedPlatformAbi() throws Exception {
    PlatformAbi abi = baseline();

    assertEquals("""
        schema: 1
        platform-abi:
          format: "elf"
          architecture: "aarch64"
          os-abi: "linux-gnu.2.17"
          pointer-bits: 64
          endianness: "little"
          page-bytes: 4096
          minimum-alignment: 16
          maximum-argument-bytes: 65536
          maximum-io-bytes: 1048576
          maximum-path-bytes: 4096
          maximum-handles: 1024
          maximum-memory-bytes: 1073741824
          cpu-features:
            - "armv8-a"
          baseline-libraries:
            - "libc.so.6"
          services:
            - "capability-file-open"
            - "directory-manifest"
            - "file-atomic-replace"
            - "file-read-at"
            - "memory-protect"
            - "memory-release"
            - "memory-reserve"
            - "process-arguments"
            - "process-exit"
            - "stderr-write"
            - "stdin-read"
            - "stdout-write"
        """, abi.canonicalText());
    assertEquals(
        HexFormat.of().formatHex(
            MessageDigest.getInstance("SHA-256").digest(abi.canonicalBytes())),
        abi.identity());
    assertEquals(
        "3a5f3c8d56a3ce57b02d04cb4f8cbc55d38c5fc4355cb3bf851686f7ae332f6d",
        abi.identity());
    assertEquals(abi.canonicalText(), new String(abi.canonicalBytes(), StandardCharsets.UTF_8));
    assertEquals(abi, PlatformAbi.parse(abi.canonicalBytes()));
    assertEquals(0, PlatformAbi.Status.OK.code());
    assertEquals(8, PlatformAbi.Status.CHANGED.code());
    assertEquals(
        "(u32,u64,mut-span)->(status,u64)",
        PlatformAbi.Service.FILE_READ_AT.signature());
    assertEquals(
        List.of(),
        abi.services().stream()
            .map(PlatformAbi.Service::wireName)
            .filter(name -> name.contains("environment")
                || name.contains("network")
                || name.contains("random"))
            .toList());
  }

  @Test
  void platformBoundsAndServicesEnterIdentity() {
    PlatformAbi baseline = baseline();
    PlatformAbi differentPage = new PlatformAbi(
        baseline.format(),
        baseline.architecture(),
        baseline.osAbi(),
        baseline.pointerBits(),
        baseline.endianness(),
        8192,
        baseline.minimumAlignment(),
        baseline.maximumArgumentBytes(),
        baseline.maximumIoBytes(),
        baseline.maximumPathBytes(),
        baseline.maximumHandles(),
        baseline.maximumMemoryBytes(),
        baseline.cpuFeatures(),
        baseline.baselineLibraries(),
        baseline.services());
    PlatformAbi optionalDeadline = new PlatformAbi(
        baseline.format(),
        baseline.architecture(),
        baseline.osAbi(),
        baseline.pointerBits(),
        baseline.endianness(),
        baseline.pageBytes(),
        baseline.minimumAlignment(),
        baseline.maximumArgumentBytes(),
        baseline.maximumIoBytes(),
        baseline.maximumPathBytes(),
        baseline.maximumHandles(),
        baseline.maximumMemoryBytes(),
        baseline.cpuFeatures(),
        baseline.baselineLibraries(),
        withDeadline(baseline.services()));

    assertNotEquals(baseline.identity(), differentPage.identity());
    assertNotEquals(baseline.identity(), optionalDeadline.identity());
  }

  @Test
  void rejectsAmbientIncompleteAndNoncanonicalProfiles() {
    PlatformAbi baseline = baseline();
    assertThrows(
        PackageFormatException.class,
        () -> new PlatformAbi(
            baseline.format(),
            baseline.architecture(),
            baseline.osAbi(),
            32,
            baseline.endianness(),
            baseline.pageBytes(),
            baseline.minimumAlignment(),
            baseline.maximumArgumentBytes(),
            baseline.maximumIoBytes(),
            baseline.maximumPathBytes(),
            baseline.maximumHandles(),
            baseline.maximumMemoryBytes(),
            baseline.cpuFeatures(),
            baseline.baselineLibraries(),
            baseline.services()));
    assertThrows(
        PackageFormatException.class,
        () -> new PlatformAbi(
            baseline.format(),
            baseline.architecture(),
            baseline.osAbi(),
            baseline.pointerBits(),
            baseline.endianness(),
            6000,
            baseline.minimumAlignment(),
            baseline.maximumArgumentBytes(),
            baseline.maximumIoBytes(),
            baseline.maximumPathBytes(),
            baseline.maximumHandles(),
            baseline.maximumMemoryBytes(),
            baseline.cpuFeatures(),
            baseline.baselineLibraries(),
            baseline.services()));
    assertThrows(
        PackageFormatException.class,
        () -> new PlatformAbi(
            baseline.format(),
            baseline.architecture(),
            baseline.osAbi(),
            baseline.pointerBits(),
            baseline.endianness(),
            baseline.pageBytes(),
            baseline.minimumAlignment(),
            baseline.maximumArgumentBytes(),
            baseline.maximumIoBytes(),
            baseline.maximumPathBytes(),
            baseline.maximumHandles(),
            baseline.maximumMemoryBytes(),
            List.of("z", "a"),
            baseline.baselineLibraries(),
            baseline.services()));
    assertThrows(
        PackageFormatException.class,
        () -> new PlatformAbi(
            baseline.format(),
            baseline.architecture(),
            baseline.osAbi(),
            baseline.pointerBits(),
            baseline.endianness(),
            baseline.pageBytes(),
            baseline.minimumAlignment(),
            baseline.maximumArgumentBytes(),
            baseline.maximumIoBytes(),
            baseline.maximumPathBytes(),
            baseline.maximumHandles(),
            baseline.maximumMemoryBytes(),
            baseline.cpuFeatures(),
            baseline.baselineLibraries(),
            baseline.services().subList(1, baseline.services().size())));
    assertThrows(
        PackageFormatException.class,
        () -> PlatformAbi.parse(baseline.canonicalText()
            .replace("schema: 1", "schema: 2").getBytes(StandardCharsets.UTF_8)));
    assertThrows(
        PackageFormatException.class,
        () -> PlatformAbi.parse((baseline.canonicalText() + "# trailing\n")
            .getBytes(StandardCharsets.UTF_8)));
    assertThrows(
        PackageFormatException.class,
        () -> PlatformAbi.parse(new byte[] {(byte) 0xc3, 0x28}));
    assertThrows(
        PackageFormatException.class,
        () -> PlatformAbi.parse(new byte[16 * 1024 + 1]));
  }

  private static PlatformAbi baseline() {
    return new PlatformAbi(
        PlatformAbi.Format.ELF,
        "aarch64",
        "linux-gnu.2.17",
        64,
        PlatformAbi.Endianness.LITTLE,
        4096,
        16,
        65_536,
        1_048_576,
        4096,
        1024,
        1_073_741_824L,
        List.of("armv8-a"),
        List.of("libc.so.6"),
        List.of(
            PlatformAbi.Service.CAPABILITY_FILE_OPEN,
            PlatformAbi.Service.DIRECTORY_MANIFEST,
            PlatformAbi.Service.FILE_ATOMIC_REPLACE,
            PlatformAbi.Service.FILE_READ_AT,
            PlatformAbi.Service.MEMORY_PROTECT,
            PlatformAbi.Service.MEMORY_RELEASE,
            PlatformAbi.Service.MEMORY_RESERVE,
            PlatformAbi.Service.PROCESS_ARGUMENTS,
            PlatformAbi.Service.PROCESS_EXIT,
            PlatformAbi.Service.STDERR_WRITE,
            PlatformAbi.Service.STDIN_READ,
            PlatformAbi.Service.STDOUT_WRITE));
  }

  private static List<PlatformAbi.Service> withDeadline(List<PlatformAbi.Service> services) {
    ArrayList<PlatformAbi.Service> result = new ArrayList<>(services);
    result.add(7, PlatformAbi.Service.MONOTONIC_DEADLINE);
    return List.copyOf(result);
  }
}
