package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
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
    requireDependencyFree("check");
    WheelerCompiler compiler = new WheelerCompiler();
    for (PackageManifest.Target target : manifest.targets()) {
      compiler.compile(source(target));
    }
  }

  Program compileRunnable(String targetName) throws IOException {
    requireDependencyFree("run");
    PackageManifest.Target selected = manifest.targets().stream()
        .filter(target -> target.name().equals(targetName))
        .findFirst()
        .orElseThrow(() -> new PackageFormatException("Unknown package target " + targetName));
    if (selected.kind() == TargetKind.LIBRARY || selected.kind() == TargetKind.TEST) {
      throw new PackageFormatException(
          "Target is not directly runnable: " + selected.name());
    }
    return new WheelerCompiler().compile(source(selected));
  }

  int test() throws IOException {
    requireDependencyFree("test");
    WheelerCompiler compiler = new WheelerCompiler();
    WheelerRuntime runtime = new WheelerRuntime();
    int executed = 0;
    for (PackageManifest.Target target : manifest.targets()) {
      if (target.kind() == TargetKind.TEST) {
        runtime.execute(compiler.compile(source(target)), new StateVectorTarget());
        executed++;
      }
    }
    return executed;
  }

  Map<String, byte[]> compile() throws IOException {
    requireDependencyFree("build");
    WheelerCompiler compiler = new WheelerCompiler();
    Map<String, byte[]> artifacts = new TreeMap<>();
    for (PackageManifest.Target target : manifest.targets()) {
      artifacts.put(target.name() + ".wbc", compiler.compileToBytecode(source(target)));
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

  List<BuildPlan.Node> planNodes(String memberName) throws IOException {
    requireDependencyFree("plan");
    List<BuildPlan.Node> nodes = new ArrayList<>();
    for (PackageManifest.Target target : manifest.targets()) {
      nodes.add(BuildPlan.Node.create(
          manifest.name(),
          manifest.version(),
          manifest.identity(),
          target.name(),
          target.kind(),
          sha256(Files.readAllBytes(source(target))),
          memberName + "/" + target.name() + ".wbc",
          List.of(),
          manifest.capabilities()));
    }
    return List.copyOf(nodes);
  }

  byte[] archive() throws IOException {
    Map<String, byte[]> entries = new TreeMap<>();
    for (PackageManifest.Target target : manifest.targets()) {
      entries.put(target.root(), Files.readAllBytes(source(target)));
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

  private void requireDependencyFree(String operation) {
    if (!manifest.dependencies().isEmpty()) {
      throw new PackageFormatException(
          "Cannot " + operation + " " + manifest.name()
              + " without locked dependency loading");
    }
  }

  private Path source(PackageManifest.Target target) throws IOException {
    Path current = root;
    for (String component : target.root().split("/")) {
      current = current.resolve(component);
      if (Files.isSymbolicLink(current)) {
        throw new IOException("Target root crosses a symbolic link: " + target.root());
      }
    }
    Path source = current.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!source.startsWith(root)
        || !Files.isRegularFile(source, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(source)) {
      throw new IOException("Target root is not a physical package file: " + target.root());
    }
    return source;
  }

  private static String sha256(byte[] bytes) {
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
