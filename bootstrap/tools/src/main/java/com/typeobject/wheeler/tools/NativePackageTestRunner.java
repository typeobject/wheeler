package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifest.Target;
import com.typeobject.wheeler.tools.LockedPackageSet.NativeArchiveSources;
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
  private static final int MAX_CASES = 255;
  private static final int MAX_DEPENDENCY_CONSTANTS = 256;
  private static final int MAX_DEPENDENCY_FUNCTIONS = 23;
  private static final int MAX_SOURCES = 8;
  private static final int MAX_PLAN_BYTES = 32_768;
  private static final int MAX_SOURCE_BYTES = MAX_PLAN_BYTES;
  private static final int COMPACT_OUTPUT_BYTES = 39;
  private static final int MAX_CASE_RESULT_BYTES = 5_345;
  private static final String RUNNER_IDENTITY = "0".repeat(63) + "1";
  private static Program jsonRenderer;
  private static Program junitRenderer;
  private static Program packageReportReducer;
  private static Program reportRowReducer;
  private static Program runner;
  private static Program terminalRenderer;
  private static Path runnerRoot;

  record Result(
      List<String> identities,
      String packageIdentity,
      TestReport report,
      byte[] json,
      byte[] junit,
      byte[] terminal,
      int selected,
      int passed,
      int failed) {
    Result {
      identities = List.copyOf(identities);
      json = json.clone();
      junit = junit.clone();
      terminal = terminal.clone();
    }

    @Override
    public byte[] json() {
      return json.clone();
    }

    @Override
    public byte[] junit() {
      return junit.clone();
    }

    @Override
    public byte[] terminal() {
      return terminal.clone();
    }
  }

  private record NativeRows(List<TestReport.CaseResult> cases, byte[] bytes) {
    NativeRows {
      cases = List.copyOf(cases);
      bytes = bytes.clone();
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
    java.util.ArrayList<List<NativeArchiveSources>> externalSources = new java.util.ArrayList<>();
    LockedPackageSet lockedPackages = null;
    for (Target target : testTargets) {
      if (!target.modular()
          || target.sources().isEmpty()
          || target.sources().size() > MAX_SOURCES) {
        return Optional.empty();
      }
      Set<String> imported = externalImports(packageRoot, target);
      if (7 < imported.size()) {
        return Optional.empty();
      }
      List<NativeArchiveSources> externalArchives = List.of();
      if (!imported.isEmpty()) {
        Path vendor = packageRoot.resolve(LockedPackageSet.VENDOR_DIRECTORY);
        if (!Files.isDirectory(vendor, LinkOption.NOFOLLOW_LINKS)
            || Files.isSymbolicLink(vendor)) {
          return Optional.empty();
        }
        if (lockedPackages == null) {
          lockedPackages = LockedPackageSet.load(packageRoot, manifest);
        }
        externalArchives = lockedPackages.fixedNativeArchives(imported);
        if (externalArchives.isEmpty()) {
          return Optional.empty();
        }
        for (NativeArchiveSources archive : externalArchives) {
          for (var entry : archive.entries()) {
            if (!fixedSourceProfile(entry.text())) {
              return Optional.empty();
            }
          }
        }
      }
      int externalSourceCount = externalArchives.stream()
          .mapToInt(archive -> archive.entries().size()).sum();
      if (MAX_SOURCES < target.sources().size() + externalSourceCount) {
        return Optional.empty();
      }
      byte[] plan = sourcePlan(packageRoot, target, externalArchives);
      if (plan.length > MAX_PLAN_BYTES || !fixedImportProfile(packageRoot, target)) {
        return Optional.empty();
      }
      plans.add(plan);
      externalSources.add(externalArchives);
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
            externalSources.get(index),
            shardIndex,
            shardCount,
            Set.of(selectedTag),
            252);
        byte[] probeOutput = execute(
            nativeRunner, probeInput, COMPACT_OUTPUT_BYTES);
        if (unsigned16(probeOutput, 32) > 0) {
          found = true;
        }
      }
      if (!found) {
        throw new PackageFormatException("Unknown test tags: " + selectedTag);
      }
    }

    java.util.ArrayList<Integer> outputCapacities = new java.util.ArrayList<>();
    int discoveredCases = 0;
    for (int index = 0; index < testTargets.size(); index++) {
      byte[] countInput = transport(
          packageRoot,
          manifest,
          testTargets.get(index),
          plans.get(index),
          externalSources.get(index),
          shardIndex,
          shardCount,
          selectedTags,
          252);
      byte[] countOutput = execute(
          nativeRunner, countInput, COMPACT_OUTPUT_BYTES);
      int caseCount = unsigned16(countOutput, 32);
      discoveredCases = Math.addExact(discoveredCases, caseCount);
      outputCapacities.add(Math.addExact(43, Math.multiplyExact(caseCount, MAX_CASE_RESULT_BYTES)));
    }
    if (discoveredCases > MAX_CASES) {
      return Optional.empty();
    }

    java.util.ArrayList<String> identities = new java.util.ArrayList<>();
    ByteArrayOutputStream combinedRows = new ByteArrayOutputStream();
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
          externalSources.get(index),
          shardIndex,
          shardCount,
          selectedTags,
          testTargets.size() > 1 ? 253 : 254);
      byte[] output = execute(
          nativeRunner, input, outputCapacities.get(index));
      identities.add(HexFormat.of().formatHex(output, 0, 32));
      NativeRows targetRows = readNativeRows(output);
      combinedRows.writeBytes(targetRows.bytes());
      packageRows.writeBytes(java.util.Arrays.copyOf(output, 38));
      selected = Math.addExact(selected, unsigned16(output, 32));
      passed = Math.addExact(passed, unsigned16(output, 34));
      failed = Math.addExact(failed, unsigned16(output, 36));
    }
    byte[] packageOutput = execute(
        nativePackageReducer, packageRows.toByteArray(), 38);
    if (selected != unsigned16(packageOutput, 32)
        || passed != unsigned16(packageOutput, 34)
        || failed != unsigned16(packageOutput, 36)) {
      throw new PackageFormatException("Native package test reduction changed summary counts");
    }
    ByteArrayOutputStream rowInput = new ByteArrayOutputStream();
    rowInput.write(selected % 256);
    rowInput.write(selected / 256);
    writeLittle32(rowInput, combinedRows.size());
    rowInput.writeBytes(combinedRows.toByteArray());
    byte[] reducedRows;
    if (selected == 0) {
      reducedRows = new byte[36];
      byte[] emptyIdentity = HexFormat.of().parseHex(identities.getFirst());
      System.arraycopy(emptyIdentity, 0, reducedRows, 0, emptyIdentity.length);
    } else {
      reducedRows = execute(
          reportRowReducer,
          rowInput.toByteArray(),
          36 + combinedRows.size());
    }
    NativeRows packageNativeRows = readReducedRows(reducedRows, selected);
    TestReport report = new TestReport(packageNativeRows.cases(), RUNNER_IDENTITY);
    byte[] json = renderAdapter(
        jsonRenderer,
        manifest.name(),
        selected,
        passed,
        failed,
        reducedRows,
        packageNativeRows.bytes());
    byte[] junit = renderAdapter(
        junitRenderer,
        manifest.name(),
        selected,
        passed,
        failed,
        reducedRows,
        packageNativeRows.bytes());
    byte[] terminal = renderAdapter(
        terminalRenderer,
        manifest.name(),
        selected,
        passed,
        failed,
        reducedRows,
        packageNativeRows.bytes());
    return Optional.of(new Result(
        identities,
        HexFormat.of().formatHex(packageOutput, 0, 32),
        report,
        json,
        junit,
        terminal,
        selected,
        passed,
        failed));
  }

  private static byte[] execute(Program program, byte[] input, int outputCapacity) {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program, input, outputCapacity);
    while (machine.status() != MachineStatus.HALTED) {
      machine.stepWithoutRewindHistory();
    }
    return machine.hostOutput();
  }

  private static byte[] renderAdapter(
      Program renderer,
      String subject,
      int selected,
      int passed,
      int failed,
      byte[] reducedRows,
      byte[] rows) {
    byte[] subjectBytes = subject.getBytes(StandardCharsets.UTF_8);
    if (subjectBytes.length > 255) {
      throw new PackageFormatException("Native test subject exceeds 255 bytes");
    }
    ByteArrayOutputStream input = new ByteArrayOutputStream();
    input.writeBytes(java.util.Arrays.copyOf(reducedRows, 32));
    writeLittle16(input, subjectBytes.length);
    input.writeBytes(subjectBytes);
    writeLittle16(input, selected);
    writeLittle16(input, passed);
    writeLittle16(input, failed);
    writeLittle32(input, rows.length);
    input.writeBytes(rows);
    int capacity = Math.addExact(
        512,
        Math.addExact(Math.multiplyExact(rows.length, 2), Math.multiplyExact(selected, 256)));
    return execute(renderer, input.toByteArray(), capacity);
  }

  private static NativeRows readNativeRows(byte[] output) throws IOException {
    if (output.length < 43) {
      throw new PackageFormatException("Native test row publication is truncated");
    }
    int rowBytes = ByteBuffer.wrap(output, 39, 4).order(ByteOrder.LITTLE_ENDIAN).getInt();
    if (rowBytes < 0 || output.length != 43 + rowBytes) {
      throw new PackageFormatException("Native test row publication has a bad boundary");
    }
    int expectedCases = unsigned16(output, 32);
    NativeRows rows = parseRows(output, 43, rowBytes, expectedCases);
    requireReportIdentity(output, rows.cases());
    return rows;
  }

  private static NativeRows readReducedRows(byte[] output, int expectedCases)
      throws IOException {
    if (output.length < 36) {
      throw new PackageFormatException("Native package rows are truncated");
    }
    int rowBytes = ByteBuffer.wrap(output, 32, 4).order(ByteOrder.LITTLE_ENDIAN).getInt();
    if (rowBytes < 0 || output.length != 36 + rowBytes) {
      throw new PackageFormatException("Native package rows have a bad boundary");
    }
    NativeRows rows = parseRows(output, 36, rowBytes, expectedCases);
    requireReportIdentity(output, rows.cases());
    return rows;
  }

  private static NativeRows parseRows(
      byte[] output, int rowStart, int rowBytes, int expectedCases) {
    java.util.ArrayList<TestReport.CaseResult> cases = new java.util.ArrayList<>();
    String previousIdentity = null;
    int cursor = rowStart;
    int end = rowStart + rowBytes;
    while (cursor < end) {
      String[] fields = new String[10];
      for (int field = 0; field < fields.length; field++) {
        if (end - cursor < 2) {
          throw new PackageFormatException("Native test row field is truncated");
        }
        int length = unsigned16(output, cursor);
        cursor += 2;
        if (length > end - cursor) {
          throw new PackageFormatException("Native test row value is truncated");
        }
        fields[field] = new String(output, cursor, length, StandardCharsets.UTF_8);
        cursor += length;
      }
      if (end - cursor < 17) {
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
      if (previousIdentity != null && previousIdentity.compareTo(fields[3]) >= 0) {
        throw new PackageFormatException("Native test rows are not in canonical order");
      }
      previousIdentity = fields[3];
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
    if (cursor != end || cases.size() != expectedCases) {
      throw new PackageFormatException("Native test rows disagree with their count");
    }
    return new NativeRows(cases, java.util.Arrays.copyOfRange(output, rowStart, end));
  }

  private static void requireReportIdentity(
      byte[] output, List<TestReport.CaseResult> cases) throws IOException {
    TestReport report = new TestReport(cases, RUNNER_IDENTITY);
    String publishedIdentity = HexFormat.of().formatHex(output, 0, 32);
    if (!publishedIdentity.equals(report.identity())) {
      throw new PackageFormatException("Native test rows disagree with the report identity");
    }
  }

  private static synchronized Program runner(Path conformanceRoot) throws IOException {
    Path canonical = conformanceRoot.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (runner == null || !canonical.equals(runnerRoot)) {
      PackageProject project = PackageProject.load(canonical);
      runner = project.compileRunnable("nativetestrunner");
      packageReportReducer = project.compileRunnable("nativetestpackagereportidentity");
      jsonRenderer = project.compileRunnable("nativetestreportjson");
      junitRenderer = project.compileRunnable("nativetestreportjunit");
      reportRowReducer = project.compileRunnable("nativetestreportrows");
      terminalRenderer = project.compileRunnable("nativetestreportterminal");
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
      if (!fixedSourceProfile(text)) {
        return false;
      }
    }
    return true;
  }

  static boolean fixedSourceProfile(String text) {
    int constants = occurrences(text, "public const long ");
    int functions = occurrences(text, "public long ")
        + occurrences(text, "public boolean ");
    boolean product = 0 < constants || 0 < functions;
    return product
        && constants <= MAX_DEPENDENCY_CONSTANTS
        && functions <= MAX_DEPENDENCY_FUNCTIONS
        && !text.contains("test void ") && !text.contains("entry void ");
  }

  private static int occurrences(String text, String value) {
    int count = 0;
    int offset = text.indexOf(value);
    while (offset >= 0) {
      count++;
      offset = text.indexOf(value, offset + value.length());
    }
    return count;
  }

  private static Set<String> externalImports(Path root, Target target) throws IOException {
    Set<String> modules = new HashSet<>();
    for (String source : target.sources()) {
      for (String line : Files.readAllLines(root.resolve(source), StandardCharsets.UTF_8)) {
        String text = line.strip();
        if (text.startsWith("module ") && text.endsWith(";")) {
          modules.add(text.substring(7, text.length() - 1));
        }
      }
    }
    Set<String> external = new java.util.TreeSet<>();
    for (String source : target.sources()) {
      for (String line : Files.readAllLines(root.resolve(source), StandardCharsets.UTF_8)) {
        String text = line.strip();
        if (text.startsWith("import ") && text.endsWith(";")) {
          String imported = text.substring(7, text.length() - 1);
          if (!modules.contains(imported)) {
            external.add(imported);
          }
        }
      }
    }
    return Set.copyOf(external);
  }

  private static byte[] sourcePlan(
      Path root, Target target, List<NativeArchiveSources> externalArchives) throws IOException {
    java.util.TreeMap<String, byte[]> sources = new java.util.TreeMap<>();
    for (String source : target.sources()) {
      Path file = root.resolve(source).normalize();
      if (!file.startsWith(root)
          || !Files.isRegularFile(file, LinkOption.NOFOLLOW_LINKS)
          || Files.isSymbolicLink(file)) {
        throw new IOException("Native test source is not a physical package file: " + source);
      }
      byte[] text = Files.readAllBytes(file);
      if (text.length > MAX_SOURCE_BYTES) {
        throw new IOException("Native test source exceeds 32,768 bytes: " + source);
      }
      sources.put(source, text);
    }
    for (NativeArchiveSources selected : externalArchives) {
      for (var entry : selected.entries()) {
        String path = "dependencies/" + selected.packageName() + "/" + entry.path();
        if (sources.put(path, entry.text().getBytes(StandardCharsets.UTF_8)) != null) {
          throw new PackageFormatException("Duplicate native test source " + path);
        }
      }
    }
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    writeBig32(output, sources.size());
    for (var source : sources.entrySet()) {
      byte[] path = source.getKey().getBytes(StandardCharsets.UTF_8);
      writeBig32(output, path.length);
      output.writeBytes(path);
      writeBig32(output, source.getValue().length);
      output.writeBytes(source.getValue());
    }
    return output.toByteArray();
  }

  private static byte[] transport(
      Path root,
      PackageManifest manifest,
      Target target,
      byte[] sourcePlan,
      List<NativeArchiveSources> externalArchives,
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
    output.write(externalArchives.size());
    for (NativeArchiveSources selected : externalArchives) {
      writeShortText(output, selected.packageName());
      writeLittleBytes(output, selected.archive());
    }
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

  private static void writeLittle16(ByteArrayOutputStream output, int value) {
    if (value < 0 || value > 65_535) {
      throw new IllegalArgumentException("Value is outside unsigned 16-bit range");
    }
    output.write(value);
    output.write(value >>> 8);
  }

  private static void writeLittle32(ByteArrayOutputStream output, int value) {
    output.writeBytes(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
        .putInt(value).array());
  }

  private static void writeBig32(ByteArrayOutputStream output, int value) {
    output.writeBytes(ByteBuffer.allocate(4).putInt(value).array());
  }

  private static int unsigned16(byte[] input, int offset) {
    return Byte.toUnsignedInt(input[offset]) + Byte.toUnsignedInt(input[offset + 1]) * 256;
  }
}
