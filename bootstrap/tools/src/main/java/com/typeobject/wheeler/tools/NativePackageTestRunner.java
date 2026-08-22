package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Comparator;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/** Invokes native source discovery, compilation, and reporting for the fixed package profile. */
final class NativePackageTestRunner {
  private static final int MAX_SOURCES = 8;
  private static final int MAX_SOURCE_BYTES = 4_096;
  private static final int MAX_PLAN_BYTES = 32_768;
  private static final int OUTPUT_BYTES = 342_123;
  private static final String RUNNER_IDENTITY = "0".repeat(63) + "1";
  private static Program packageReportReducer;
  private static Program runner;
  private static Path runnerRoot;

  record Result(
      List<String> identities,
      String packageIdentity,
      TestReport report,
      int selected,
      int passed,
      int failed) {
    Result {
      identities = List.copyOf(identities);
    }
  }

  private NativePackageTestRunner() {}

  static Optional<Result> run(
      Path packageRoot,
      PackageManifest manifest,
      int shardIndex,
      int shardCount,
      Set<String> selectedTags) throws IOException {
    List<Target> testTargets = manifest.targets().stream().filter(Target::test).toList();
    if (testTargets.isEmpty()) {
      return Optional.empty();
    }
    java.util.ArrayList<byte[]> plans = new java.util.ArrayList<>();
    for (Target target : testTargets) {
      if (!target.modular()
          || target.sources().isEmpty()
          || target.sources().size() > MAX_SOURCES) {
        return Optional.empty();
      }
      byte[] plan = sourcePlan(packageRoot, target);
      if (plan.length > MAX_PLAN_BYTES
          || !fixedImportProfile(packageRoot, target)
          || !localImportProfile(packageRoot, target)) {
        return Optional.empty();
      }
      plans.add(plan);
    }

    Optional<Path> conformance = findConformancePackage(packageRoot);
    if (conformance.isEmpty()) {
      return Optional.empty();
    }

    Program nativeRunner = runner(conformance.orElseThrow());
    Program nativePackageReducer = packageReportReducer;
    for (String selectedTag : selectedTags.stream().sorted().toList()) {
      boolean found = false;
      for (int index = 0; index < testTargets.size(); index++) {
        byte[] probeInput = transport(
            packageRoot,
            manifest,
            testTargets.get(index),
            plans.get(index),
            shardIndex,
            shardCount,
            Set.of(selectedTag),
            252);
        byte[] probeOutput = new WheelerRuntime()
            .executeBinaryInput(nativeRunner, probeInput, OUTPUT_BYTES)
            .output();
        if (unsigned16(probeOutput, 32) > 0) {
          found = true;
        }
      }
      if (!found) {
        throw new PackageFormatException("Unknown test tags: " + selectedTag);
      }
    }

    java.util.ArrayList<String> identities = new java.util.ArrayList<>();
    java.util.ArrayList<TestReport.CaseResult> nativeCases = new java.util.ArrayList<>();
    ByteArrayOutputStream packageRows = new ByteArrayOutputStream();
    packageRows.write(testTargets.size());
    int selected = 0;
    int passed = 0;
    int failed = 0;
    for (int index = 0; index < testTargets.size(); index++) {
      byte[] input = transport(
          packageRoot,
          manifest,
          testTargets.get(index),
          plans.get(index),
          shardIndex,
          shardCount,
          selectedTags,
          testTargets.size() > 1 ? 253 : 254);
      byte[] output = new WheelerRuntime()
          .executeBinaryInput(nativeRunner, input, OUTPUT_BYTES)
          .output();
      identities.add(HexFormat.of().formatHex(output, 0, 32));
      nativeCases.addAll(readNativeCases(output));
      packageRows.writeBytes(java.util.Arrays.copyOf(output, 38));
      selected = Math.addExact(selected, unsigned16(output, 32));
      passed = Math.addExact(passed, unsigned16(output, 34));
      failed = Math.addExact(failed, unsigned16(output, 36));
    }
    byte[] packageOutput = new WheelerRuntime()
        .executeBinaryInput(nativePackageReducer, packageRows.toByteArray(), 38)
        .output();
    if (selected != unsigned16(packageOutput, 32)
        || passed != unsigned16(packageOutput, 34)
        || failed != unsigned16(packageOutput, 36)) {
      throw new PackageFormatException("Native package test reduction changed summary counts");
    }
    return Optional.of(new Result(
        identities,
        HexFormat.of().formatHex(packageOutput, 0, 32),
        new TestReport(nativeCases, RUNNER_IDENTITY),
        selected,
        passed,
        failed));
  }

  private static List<TestReport.CaseResult> readNativeCases(byte[] output) throws IOException {
    if (output.length < 43) {
      throw new PackageFormatException("Native test row publication is truncated");
    }
    int rowBytes = ByteBuffer.wrap(output, 39, 4).order(ByteOrder.LITTLE_ENDIAN).getInt();
    if (rowBytes < 0 || output.length != 43 + rowBytes) {
      throw new PackageFormatException("Native test row publication has a bad boundary");
    }
    int expectedCases = unsigned16(output, 32);
    java.util.ArrayList<TestReport.CaseResult> cases = new java.util.ArrayList<>();
    int cursor = 43;
    while (cursor < output.length) {
      String[] fields = new String[10];
      for (int field = 0; field < fields.length; field++) {
        if (output.length - cursor < 2) {
          throw new PackageFormatException("Native test row field is truncated");
        }
        int length = unsigned16(output, cursor);
        cursor += 2;
        if (length > output.length - cursor) {
          throw new PackageFormatException("Native test row value is truncated");
        }
        fields[field] = new String(output, cursor, length, StandardCharsets.UTF_8);
        cursor += length;
      }
      if (output.length - cursor < 17) {
        throw new PackageFormatException("Native test row outcome is truncated");
      }
      int status = Byte.toUnsignedInt(output[cursor]);
      long assertions = ByteBuffer.wrap(output, cursor + 1, 8)
          .order(ByteOrder.LITTLE_ENDIAN).getLong();
      long workflowSteps = ByteBuffer.wrap(output, cursor + 9, 8)
          .order(ByteOrder.LITTLE_ENDIAN).getLong();
      cursor += 17;
      if (status > 1) {
        throw new PackageFormatException("Native test row has an unknown status");
      }
      cases.add(new TestReport.CaseResult(
          fields[0],
          fields[1],
          fields[2],
          fields[3],
          fields[4],
          fields[5],
          status == 0 ? TestReport.Status.PASS : TestReport.Status.FAIL,
          fields[6],
          fields[7],
          assertions,
          workflowSteps,
          fields[8],
          fields[9]));
    }
    if (cases.size() != expectedCases) {
      throw new PackageFormatException("Native test rows disagree with the summary count");
    }
    List<TestReport.CaseResult> published = List.copyOf(cases);
    TestReport targetReport = new TestReport(published, RUNNER_IDENTITY);
    String publishedIdentity = HexFormat.of().formatHex(output, 0, 32);
    if (!publishedIdentity.equals(targetReport.identity())) {
      throw new PackageFormatException("Native test rows disagree with the report identity");
    }
    return published;
  }

  private static synchronized Program runner(Path conformanceRoot) throws IOException {
    Path canonical = conformanceRoot.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (runner == null || !canonical.equals(runnerRoot)) {
      PackageProject project = PackageProject.load(canonical);
      runner = project.compileRunnable("nativetestrunner");
      packageReportReducer = project.compileRunnable("nativetestpackagereportidentity");
      runnerRoot = canonical;
    }
    return runner;
  }

  private static boolean fixedImportProfile(Path root, Target target) throws IOException {
    for (String source : target.sources()) {
      if (source.equals(target.root())) {
        continue;
      }
      String text = Files.readString(root.resolve(source), StandardCharsets.UTF_8);
      int declaration = text.indexOf("public const long ");
      if (declaration < 0 || text.indexOf("public const long ", declaration + 1) >= 0) {
        return false;
      }
      if (text.indexOf('(') >= 0 || text.contains("test void ") || text.contains("entry void ")) {
        return false;
      }
    }
    return true;
  }

  private static boolean localImportProfile(Path root, Target target) throws IOException {
    Set<String> modules = new HashSet<>();
    for (String source : target.sources()) {
      for (String line : Files.readAllLines(root.resolve(source), StandardCharsets.UTF_8)) {
        String text = line.strip();
        if (text.startsWith("module ") && text.endsWith(";")) {
          modules.add(text.substring(7, text.length() - 1));
        }
      }
    }
    for (String source : target.sources()) {
      for (String line : Files.readAllLines(root.resolve(source), StandardCharsets.UTF_8)) {
        String text = line.strip();
        if (text.startsWith("import ") && text.endsWith(";")) {
          if (!modules.contains(text.substring(7, text.length() - 1))) {
            return false;
          }
        }
      }
    }
    return true;
  }

  private static byte[] sourcePlan(Path root, Target target) throws IOException {
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    List<String> sources = target.sources().stream().sorted().toList();
    writeBig32(output, sources.size());
    for (String source : sources) {
      byte[] path = source.getBytes(StandardCharsets.UTF_8);
      Path file = root.resolve(source).normalize();
      if (!file.startsWith(root)
          || !Files.isRegularFile(file, LinkOption.NOFOLLOW_LINKS)
          || Files.isSymbolicLink(file)) {
        throw new IOException("Native test source is not a physical package file: " + source);
      }
      byte[] text = Files.readAllBytes(file);
      if (text.length > MAX_SOURCE_BYTES) {
        throw new IOException("Native test source exceeds 4,096 bytes: " + source);
      }
      writeBig32(output, path.length);
      output.writeBytes(path);
      writeBig32(output, text.length);
      output.writeBytes(text);
    }
    return output.toByteArray();
  }

  private static byte[] transport(
      Path root,
      PackageManifest manifest,
      Target target,
      byte[] sourcePlan,
      int shardIndex,
      int shardCount,
      Set<String> selectedTags,
      int descriptorMode) throws IOException {
    if (shardIndex < 0 || shardIndex >= shardCount || shardCount < 1 || shardCount > 65_535) {
      throw new IllegalArgumentException("Invalid native test shard");
    }
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) shardIndex).putShort((short) shardCount).array());
    writeShortText(output, manifest.name());
    writeShortText(output, manifest.version());
    writeShortText(output, target.name());
    byte[] manifestBytes = Files.readAllBytes(root.resolve(PackageProject.MANIFEST_NAME));
    writeLittleBytes(output, manifestBytes);
    writeLittleBytes(output, packageLock(root, manifest, manifestBytes));
    writeLittleBytes(output, sourcePlan);
    List<String> tags = selectedTags.stream().sorted(Comparator.naturalOrder()).toList();
    if (tags.size() > 64) {
      throw new IllegalArgumentException("Native test selection exceeds 64 tags");
    }
    output.write(tags.size());
    for (String tag : tags) {
      writeShortText(output, tag);
    }
    output.write(descriptorMode);
    return output.toByteArray();
  }

  private static Optional<Path> findConformancePackage(Path packageRoot) {
    Path cursor = packageRoot.toAbsolutePath().normalize();
    while (cursor != null) {
      Path candidate = cursor.resolve("wheeler-conformance");
      if (Files.isRegularFile(candidate.resolve(PackageProject.MANIFEST_NAME))) {
        return Optional.of(candidate);
      }
      cursor = cursor.getParent();
    }
    cursor = Path.of("").toAbsolutePath().normalize();
    while (cursor != null) {
      Path candidate = cursor.resolve("wheeler-conformance");
      if (Files.isRegularFile(candidate.resolve(PackageProject.MANIFEST_NAME))) {
        return Optional.of(candidate);
      }
      cursor = cursor.getParent();
    }
    return Optional.empty();
  }

  private static byte[] packageLock(
      Path root, PackageManifest manifest, byte[] manifestBytes) throws IOException {
    if (manifest.dependencies().isEmpty()) {
      return emptyLock(manifestBytes);
    }
    Path lock = root.resolve(PackageLock.FILE_NAME);
    if (!Files.isRegularFile(lock, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(lock)) {
      throw new IOException("Native dependency test requires a physical package lock");
    }
    return Files.readAllBytes(lock);
  }

  private static byte[] emptyLock(byte[] manifest) {
    try {
      String identity = HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(manifest));
      return ("schema: 3\nroot: \"" + identity + "\"\npackages: []\n")
          .getBytes(StandardCharsets.UTF_8);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static void writeShortText(ByteArrayOutputStream output, String text) {
    byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
    if (bytes.length < 1 || bytes.length > 255) {
      throw new IllegalArgumentException("Native test text is outside the one-byte frame");
    }
    output.write(bytes.length);
    output.writeBytes(bytes);
  }

  private static void writeLittleBytes(ByteArrayOutputStream output, byte[] bytes) {
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(bytes.length).array());
    output.writeBytes(bytes);
  }

  private static void writeBig32(ByteArrayOutputStream output, int value) {
    output.writeBytes(ByteBuffer.allocate(4).putInt(value).array());
  }

  private static int unsigned16(byte[] input, int offset) {
    return Byte.toUnsignedInt(input[offset]) + Byte.toUnsignedInt(input[offset + 1]) * 256;
  }
}
