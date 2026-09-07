package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;

/** Source framing must preserve logical path order before build and case identities bind it. */
final class TargetSourceSetTest {
  @Test
  void framesCompleteSortedSourcesAcrossInputOrdersAndOverlappingSelectors() throws Exception {
    Map<String, byte[]> selected = sources();
    byte[] expected = framed(selected);
    String sourceIdentity = digest(expected);
    String caseIdentity = TestReport.caseIdentity("0".repeat(64), "tests::check", sourceIdentity);
    var paths = new ArrayList<>(selected.keySet());
    List<List<String>> selectors = List.of(
        List.of("src"), List.of("src", "src/Root.w"), List.copyOf(paths));
    for (int rotation = 0; rotation < paths.size(); rotation++) {
      Collections.rotate(paths, 1);
      Map<String, byte[]> entries = new LinkedHashMap<>();
      for (String path : paths) {
        entries.put(path, selected.get(path));
      }
      entries.put("src/notes.txt", new byte[] {1});
      entries.put("src-other/Decoy.w", new byte[] {2});
      for (List<String> selection : selectors) {
        Target target = new Target(TargetKind.TOOL, "tests", "src/Root.w", "test.root", selection);
        byte[] actual = TargetSourceSet.canonicalInput(target, entries);
        assertArrayEquals(expected, actual);
        assertEquals(sourceIdentity, digest(actual));
        assertEquals(caseIdentity,
            TestReport.caseIdentity("0".repeat(64), "tests::check", digest(actual)));
        assertEquals(selected.size(), TargetSourceSet.strictText(target, entries).size());
      }
    }
  }

  @Test
  void keepsTheInputIdentityAcrossFreshVirtualMachines() throws Exception {
    List<String> roots = new ArrayList<>();
    for (Class<?> type : List.of(TargetSourceSetTest.class, TargetSourceSet.class, Target.class)) {
      roots.add(Path.of(type.getProtectionDomain().getCodeSource().getLocation().toURI()).toString());
    }
    String expected = digest(framed(sources()));
    for (int attempt = 0; attempt < 4; attempt++) {
      Process process = new ProcessBuilder(
          Path.of(System.getProperty("java.home"), "bin", "java").toString(),
          "-Xmx128m", "-XX:ActiveProcessorCount=2",
          "-cp", String.join(File.pathSeparator, roots), TargetSourceSetTest.class.getName())
          .redirectErrorStream(true).start();
      try {
        assertTrue(process.waitFor(20, TimeUnit.SECONDS), "source identity worker timed out");
        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        assertEquals(0, process.exitValue(), output);
        assertEquals(expected, output.strip());
      } finally {
        process.destroyForcibly();
      }
    }
  }

  /** Runs the encoding in a fresh JVM without relying on its immutable-map iteration seed. */
  public static void main(String[] args) throws Exception {
    Target target = new Target(TargetKind.TOOL, "tests", "src/Root.w", "test.root", List.of("src"));
    System.out.println(digest(TargetSourceSet.canonicalInput(target, sources())));
  }

  @Test
  void preservesNonmodularBytesWithoutSourceSetFraming() {
    byte[] source = "classical class Root {}\n".getBytes(StandardCharsets.UTF_8);
    Target target = new Target(TargetKind.TOOL, "root", "src/Root.w");
    assertArrayEquals(source, TargetSourceSet.canonicalInput(target,
        Map.of("src/Root.w", source, "src/Other.w", new byte[] {1})));
  }

  @Test
  void rejectsMissingRootsAndMalformedText() {
    Target target = new Target(TargetKind.TOOL, "root", "src/Root.w", "test.root", List.of("src"));
    assertThrows(PackageFormatException.class,
        () -> TargetSourceSet.canonicalInput(target, Map.of("src/Other.w", new byte[0])));
    assertThrows(PackageFormatException.class,
        () -> TargetSourceSet.strictText(target, Map.of("src/Root.w", new byte[] {(byte) 0xff})));
  }

  private static Map<String, byte[]> sources() {
    Map<String, byte[]> result = new TreeMap<>();
    result.put("src/Root.w", "// root λ\n".getBytes(StandardCharsets.UTF_8));
    for (int index = 0; index < 32; index++) {
      String path = "src/parts/Part" + index + ".w";
      result.put(path, ("// " + index + " π\n").getBytes(StandardCharsets.UTF_8));
    }
    return result;
  }

  private static byte[] framed(Map<String, byte[]> sources) throws Exception {
    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
    try (DataOutputStream output = new DataOutputStream(bytes)) {
      output.writeInt(sources.size());
      for (String path : sources.keySet().stream().sorted().toList()) {
        byte[] name = path.getBytes(StandardCharsets.UTF_8);
        byte[] source = sources.get(path);
        output.writeInt(name.length);
        output.write(name);
        output.writeInt(source.length);
        output.write(source);
      }
    }
    return bytes.toByteArray();
  }

  private static String digest(byte[] bytes) throws Exception {
    return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
  }
}
