package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.CompilerException;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.SemanticCoverage;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import com.typeobject.wheeler.runtime.quantum.StateVectorTarget;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Stream;

/** Capability-minimal host adapter for one local Wheeler package directory. */
final class PackageProject {
  static final String MANIFEST_NAME = "wheeler.package";

  private final Path root;
  private final PackageManifest manifest;

  private PackageProject(Path root, PackageManifest manifest) {
    this.root = root;
    this.manifest = manifest;
  }

  static PackageProject load(Path requestedRoot) throws IOException {
    Path root = requestedRoot.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!Files.isDirectory(root, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(root)) {
      throw new IOException("Package root is not a physical directory: " + requestedRoot);
    }
    Path manifestPath = root.resolve(MANIFEST_NAME);
    if (!Files.isRegularFile(manifestPath, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(manifestPath)) {
      throw new IOException("Missing physical " + MANIFEST_NAME + " in " + root);
    }
    PackageManifest manifest = new PackageManifestParser().parse(Files.readAllBytes(manifestPath));
    return new PackageProject(root, manifest);
  }

  PackageManifest manifest() {
    return manifest;
  }

  void check() throws IOException {
    LockedPackageSet dependencies = dependencies();
    if (dependencies != null) {
      dependencies.check();
    }
    WheelerCompiler compiler = new WheelerCompiler();
    Map<String, String> linkedModules = dependencies == null
        ? Map.of() : dependencies.moduleSources();
    for (PackageManifest.Target target : manifest.targets()) {
      compileTarget(compiler, target, linkedModules);
    }
  }

  Program compileRunnable(String targetName) throws IOException {
    LockedPackageSet dependencies = dependencies();
    if (dependencies != null) {
      dependencies.check();
    }
    PackageManifest.Target selected = manifest.targets().stream()
        .filter(target -> target.name().equals(targetName))
        .findFirst()
        .orElseThrow(() -> new PackageFormatException("Unknown package target " + targetName));
    if (selected.kind() == TargetKind.LIBRARY) {
      throw new PackageFormatException(
          "Target is not directly runnable: " + selected.name());
    }
    return compileTarget(
        new WheelerCompiler(), selected,
        dependencies == null ? Map.of() : dependencies.moduleSources());
  }

  TestReport test() throws IOException {
    LockedPackageSet dependencies = dependencies();
    if (dependencies != null) {
      dependencies.check();
    }
    WheelerCompiler compiler = new WheelerCompiler();
    BytecodeWriter writer = new BytecodeWriter();
    Map<String, String> linkedModules = dependencies == null
        ? Map.of() : dependencies.moduleSources();
    List<TestReport.CaseResult> cases = new ArrayList<>();
    for (PackageManifest.Target target : manifest.targets()) {
      if (!target.test()) {
        continue;
      }
      String sourceIdentity = sha256(readPlanInput(target));
      List<CompiledCase> compiled;
      try {
        compiled = compileTestCases(compiler, target, linkedModules);
      } catch (CompilerException exception) {
        String caseIdentity = TestReport.caseIdentity(
            manifest.identity(), target.name(), sourceIdentity);
        cases.add(TestReport.fail(
            manifest.name(), manifest.version(), target.name(), caseIdentity,
            sourceIdentity, "", "WTEST001", exception.getMessage()));
        continue;
      }
      for (CompiledCase compiledCase : compiled) {
        String caseName = compiledCase.name().isEmpty()
            ? target.name() : target.name() + "::" + compiledCase.name();
        String caseIdentity = TestReport.caseIdentity(
            manifest.identity(), caseName, sourceIdentity);
        Program program = compiledCase.program();
        String artifactIdentity = sha256(writer.write(program));
        try {
          WheelerRuntime runtime = new WheelerRuntime();
          SemanticCoverage coverage = new SemanticCoverage();
          ExecutionResult execution = program.kind() == ProgramKind.CLASSICAL
              ? runtime.executeObserved(program, coverage)
              : runtime.execute(program, new StateVectorTarget());
          String coverageIdentity = program.kind() == ProgramKind.CLASSICAL
              ? coverage.identity() : "";
          cases.add(TestReport.pass(
              manifest.name(), manifest.version(), caseName, caseIdentity,
              sourceIdentity, artifactIdentity, execution, coverageIdentity));
        } catch (VmTrap exception) {
          cases.add(TestReport.fail(
              manifest.name(), manifest.version(), caseName, caseIdentity,
              sourceIdentity, artifactIdentity, "WTEST002", exception.getMessage()));
        }
      }
    }
    return new TestReport(cases);
  }

  Map<String, byte[]> compile() throws IOException {
    LockedPackageSet dependencies = dependencies();
    WheelerCompiler compiler = new WheelerCompiler();
    Map<String, byte[]> artifacts = new TreeMap<>();
    if (dependencies != null) {
      artifacts.putAll(dependencies.compile());
    }
    Map<String, String> linkedModules = dependencies == null
        ? Map.of() : dependencies.moduleSources();
    for (PackageManifest.Target target : manifest.targets()) {
      artifacts.put(
          target.name() + ".wbc",
          new BytecodeWriter().write(compileTarget(compiler, target, linkedModules)));
    }
    return Map.copyOf(artifacts);
  }

  void build(Path requestedOutput) throws IOException {
    Path output = requestedOutput.toAbsolutePath().normalize();
    Files.createDirectories(output);
    if (!Files.isDirectory(output) || Files.isSymbolicLink(output)) {
      throw new IOException("Build output is not a physical directory: " + output);
    }
    for (Map.Entry<String, byte[]> artifact : compile().entrySet()) {
      writeAtomically(output.resolve(artifact.getKey()), artifact.getValue());
    }
  }

  List<BuildPlan.Node> planNodes(
      String memberName, boolean grantRequestedCapabilities) throws IOException {
    LockedPackageSet dependencies = dependencies();
    List<BuildPlan.Node> nodes = new ArrayList<>();
    List<BuildPlan.PackageInput> inputs = List.of();
    if (dependencies != null) {
      nodes.addAll(dependencies.planNodes(memberName, grantRequestedCapabilities));
      inputs = dependencies.rootInputs(manifest);
    }
    for (PackageManifest.Target target : manifest.targets()) {
      nodes.add(BuildPlan.Node.create(
          manifest.name(),
          manifest.version(),
          manifest.identity(),
          target.name(),
          target.kind(),
          sha256(readPlanInput(target)),
          memberName + "/" + target.name() + ".wbc",
          inputs,
          manifest.capabilities(),
          BuildPlan.ExecutionLimits.DEFAULT,
          grantRequestedCapabilities ? manifest.capabilities() : List.of()));
    }
    return List.copyOf(nodes);
  }

  byte[] archive() throws IOException {
    Map<String, byte[]> entries = new TreeMap<>();
    for (PackageManifest.Target target : manifest.targets()) {
      for (String source : target.sources()) {
        entries.put(source, readSource(source));
      }
    }
    return new PackageArchive().encode(manifest, entries);
  }

  void clean() throws IOException {
    cleanOutput(defaultBuildDirectory());
  }

  Path defaultBuildDirectory() {
    return root.resolve("out");
  }

  Path defaultArchivePath() {
    return root.resolve(manifest.name() + "-" + manifest.version() + ".wpk");
  }

  private LockedPackageSet dependencies() throws IOException {
    return manifest.dependencies().isEmpty() ? null : LockedPackageSet.load(root, manifest);
  }

  private List<CompiledCase> compileTestCases(
      WheelerCompiler compiler,
      PackageManifest.Target target,
      Map<String, String> linkedModules) throws IOException {
    if (!target.modular()) {
      List<WheelerCompiler.TestCase> declarations = compiler.compileTests(source(target.root()));
      if (!declarations.isEmpty()) {
        return declarations.stream()
            .map(test -> new CompiledCase(test.name(), test.program()))
            .toList();
      }
    }
    return List.of(new CompiledCase("", compileTarget(compiler, target, linkedModules)));
  }

  private Program compileTarget(
      WheelerCompiler compiler,
      PackageManifest.Target target,
      Map<String, String> linkedModules) throws IOException {
    if (!target.modular()) {
      if (target.kind() == TargetKind.LIBRARY) {
        throw new PackageFormatException(
            "Library target must declare an exact module source set: " + target.name());
      }
      return compiler.compile(source(target.root()));
    }
    Map<String, String> sources = TargetSourceSet.strictText(
        target, targetEntries(target, false));
    return target.kind() == TargetKind.LIBRARY
        ? compiler.compilePackageLibraryModuleFiles(sources, linkedModules, target.module())
        : compiler.compilePackageModuleFiles(sources, linkedModules, target.module());
  }

  private record CompiledCase(String name, Program program) {
    private CompiledCase {
      if (name == null || program == null) {
        throw new IllegalArgumentException("Compiled test case is incomplete");
      }
    }
  }

  private byte[] readPlanInput(PackageManifest.Target target) throws IOException {
    byte[] input = TargetSourceSet.canonicalInput(target, targetEntries(target, true));
    if (input.length > BuildPlan.ExecutionLimits.DEFAULT.maxInputBytes()) {
      throw new PackageFormatException("Target module sources exceed the build input limit: "
          + target.name());
    }
    return input;
  }

  private Map<String, byte[]> targetEntries(
      PackageManifest.Target target, boolean enforcePlanLimit) throws IOException {
    Map<String, byte[]> entries = new TreeMap<>();
    for (String logicalPath : target.sources()) {
      byte[] source = readSource(logicalPath);
      if (enforcePlanLimit
          && source.length > BuildPlan.ExecutionLimits.DEFAULT.maxInputBytes()) {
        throw new PackageFormatException(
            "Target source exceeds the build input limit: " + logicalPath);
      }
      entries.put(logicalPath, source);
    }
    return Map.copyOf(entries);
  }

  private byte[] readSource(String logicalPath) throws IOException {
    return Files.readAllBytes(source(logicalPath));
  }

  private Path source(String logicalPath) throws IOException {
    Path current = root;
    for (String component : logicalPath.split("/")) {
      current = current.resolve(component);
      if (Files.isSymbolicLink(current)) {
        throw new IOException("Target source crosses a symbolic link: " + logicalPath);
      }
    }
    Path source = current.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!source.startsWith(root)
        || !Files.isRegularFile(source, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(source)) {
      throw new IOException("Target source is not a physical package file: " + logicalPath);
    }
    return source;
  }

  static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  static void cleanOutput(Path output) throws IOException {
    Path normalized = output.toAbsolutePath().normalize();
    if (!Files.exists(normalized, LinkOption.NOFOLLOW_LINKS)) {
      return;
    }
    if (!Files.isDirectory(normalized, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(normalized)) {
      throw new IOException("Build output is not a physical directory: " + normalized);
    }
    List<Path> paths;
    try (Stream<Path> entries = Files.walk(normalized)) {
      paths = entries.sorted(java.util.Comparator.reverseOrder()).toList();
    }
    for (Path path : paths) {
      if (Files.isSymbolicLink(path)) {
        throw new IOException("Refusing to clean symbolic link: " + path);
      }
    }
    for (Path path : paths) {
      Files.delete(path);
    }
  }

  static void writeAtomically(Path destination, byte[] bytes) throws IOException {
    Path absolute = destination.toAbsolutePath().normalize();
    Path parent = absolute.getParent();
    if (parent == null) {
      throw new IOException("Output has no parent: " + destination);
    }
    Files.createDirectories(parent);
    Path temporary = Files.createTempFile(parent, ".wheeler-", ".tmp");
    try {
      Files.write(temporary, bytes);
      try {
        Files.move(
            temporary,
            absolute,
            StandardCopyOption.ATOMIC_MOVE,
            StandardCopyOption.REPLACE_EXISTING);
      } catch (java.nio.file.AtomicMoveNotSupportedException exception) {
        Files.move(temporary, absolute, StandardCopyOption.REPLACE_EXISTING);
      }
    } finally {
      Files.deleteIfExists(temporary);
    }
  }
}
