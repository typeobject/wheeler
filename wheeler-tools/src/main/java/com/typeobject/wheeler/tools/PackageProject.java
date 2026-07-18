package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.TreeMap;

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
    WheelerCompiler compiler = new WheelerCompiler();
    for (PackageManifest.Target target : manifest.targets()) {
      compiler.compile(source(target));
    }
  }

  Map<String, byte[]> compile() throws IOException {
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

  byte[] archive() throws IOException {
    Map<String, byte[]> entries = new TreeMap<>();
    for (PackageManifest.Target target : manifest.targets()) {
      entries.put(target.root(), Files.readAllBytes(source(target)));
    }
    return new PackageArchive().encode(manifest, entries);
  }

  Path defaultBuildDirectory() {
    return root.resolve("out");
  }

  Path defaultArchivePath() {
    return root.resolve(manifest.name() + "-" + manifest.version() + ".wpk");
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
