package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import com.typeobject.wheeler.packageformat.PackageManifest;
import com.typeobject.wheeler.packageformat.PackageManifest.Dependency;
import com.typeobject.wheeler.packageformat.PackageManifest.DependencyKind;
import com.typeobject.wheeler.packageformat.PackageManifest.TargetKind;
import com.typeobject.wheeler.packageformat.VersionConstraint;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Stream;

/** Exact offline package inputs loaded from a package-local vendor tree. */
final class LockedPackageSet {
  static final String VENDOR_DIRECTORY = "vendor";

  private final PackageLock lock;
  private final Map<String, DecodedPackage> packages;
  private final List<String> buildOrder;
  private final List<Dependency> rootDependencies;
  private final boolean development;

  private LockedPackageSet(
      PackageLock lock,
      Map<String, DecodedPackage> packages,
      List<String> buildOrder,
      List<Dependency> rootDependencies,
      boolean development) {
    this.lock = lock;
    this.packages = Map.copyOf(packages);
    this.buildOrder = List.copyOf(buildOrder);
    this.rootDependencies = List.copyOf(rootDependencies);
    this.development = development;
  }

  static LockedPackageSet load(Path packageRoot, PackageManifest root) throws IOException {
    Path requested = packageRoot.resolve(VENDOR_DIRECTORY);
    if (!Files.exists(requested, LinkOption.NOFOLLOW_LINKS)) {
      throw new PackageFormatException(
          "Missing locked vendor tree " + VENDOR_DIRECTORY + " for " + root.name());
    }
    Path vendor = requested.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!vendor.startsWith(packageRoot)
        || !Files.isDirectory(vendor, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(vendor)) {
      throw new IOException("Vendor input is not a physical package directory: " + requested);
    }
    Path lockPath = vendor.resolve(PackageLock.FILE_NAME);
    requirePhysicalFile(lockPath, "vendor lock");
    PackageLock lock = new PackageLockParser().parse(Files.readAllBytes(lockPath));
    if (!lock.rootManifestIdentity().equals(root.identity())) {
      throw new PackageFormatException("Lock root does not match " + root.name());
    }

    Map<String, DecodedPackage> packages = new LinkedHashMap<>();
    Set<String> expectedFiles = new TreeSet<>();
    expectedFiles.add(PackageLock.FILE_NAME);
    PackageArchive codec = new PackageArchive();
    for (PackageLock.Entry entry : lock.entries()) {
      String filename = entry.name() + "-" + entry.version() + "-"
          + entry.archiveIdentity() + ".wpk";
      expectedFiles.add(filename);
      Path archivePath = vendor.resolve(filename);
      requirePhysicalFile(archivePath, "locked package");
      byte[] bytes = Files.readAllBytes(archivePath);
      DecodedPackage decoded = codec.decode(bytes);
      if (!decoded.identity().equals(entry.archiveIdentity())
          || !decoded.manifest().identity().equals(entry.manifestIdentity())
          || !decoded.manifest().name().equals(entry.name())
          || !decoded.manifest().version().equals(entry.version())) {
        throw new PackageFormatException("Locked package identity mismatch for " + entry.name());
      }
      if (!decoded.manifest().profile().equals(root.profile())) {
        throw new PackageFormatException(
            "Dependency profile mismatch for " + entry.name());
      }
      packages.put(entry.name(), decoded);
    }
    verifyExactFiles(vendor, expectedFiles);

    boolean normal = graphMatches(root, lock, packages, false);
    boolean development = graphMatches(root, lock, packages, true);
    if (!normal && !development) {
      throw new PackageFormatException("Locked dependency graph does not match package manifests");
    }
    boolean includeDevelopment = !normal && development;
    return new LockedPackageSet(
        lock,
        packages,
        topologicalOrder(root, lock, includeDevelopment),
        root.dependencies(),
        includeDevelopment);
  }

  void check() {
    WheelerCompiler compiler = new WheelerCompiler();
    for (String name : buildOrder) {
      DecodedPackage dependency = packages.get(name);
      Map<String, String> transitiveModules = allModuleSourcesExcept(name);
      Map<String, String> directModules = moduleSourcesFor(
          dependency.manifest().dependencies());
      for (PackageManifest.Target target : dependency.manifest().targets()) {
        compileTarget(compiler, dependency, target, transitiveModules, directModules);
      }
    }
  }

  Map<String, byte[]> compile() {
    WheelerCompiler compiler = new WheelerCompiler();
    Map<String, byte[]> artifacts = new LinkedHashMap<>();
    for (String name : buildOrder) {
      DecodedPackage dependency = packages.get(name);
      Map<String, String> transitiveModules = allModuleSourcesExcept(name);
      Map<String, String> directModules = moduleSourcesFor(
          dependency.manifest().dependencies());
      for (PackageManifest.Target target : dependency.manifest().targets()) {
        artifacts.put(
            "dependencies/" + name + "/" + target.name() + ".wbc",
            new BytecodeWriter().write(
                compileTarget(
                    compiler, dependency, target, transitiveModules, directModules)));
      }
    }
    return Map.copyOf(artifacts);
  }

  Map<String, String> moduleSources() {
    return allModuleSources();
  }

  Map<String, String> directModuleSources() {
    return moduleSourcesFor(rootDependencies);
  }

  private Map<String, String> allModuleSources() {
    return allModuleSourcesExcept(null);
  }

  private Map<String, String> allModuleSourcesExcept(String excludedPackage) {
    Map<String, String> result = new TreeMap<>();
    for (String name : buildOrder) {
      if (!name.equals(excludedPackage)) {
        addLibrarySources(name, packages.get(name), result);
      }
    }
    return Map.copyOf(result);
  }

  private Map<String, String> moduleSourcesFor(List<Dependency> dependencies) {
    Map<String, String> result = new TreeMap<>();
    for (String name : included(dependencies, development).stream()
        .map(Dependency::name).sorted().toList()) {
      DecodedPackage dependency = packages.get(name);
      if (dependency == null) {
        throw new PackageFormatException("Missing direct locked dependency " + name);
      }
      addLibrarySources(name, dependency, result);
    }
    return Map.copyOf(result);
  }

  List<BuildPlan.Node> planNodes(
      String prefix, boolean grantRequestedCapabilities) {
    List<BuildPlan.Node> result = new ArrayList<>();
    Map<String, PackageLock.Entry> locked = lockEntries(lock);
    for (String name : buildOrder) {
      DecodedPackage dependency = packages.get(name);
      List<BuildPlan.PackageInput> inputs = locked.get(name).dependencies().stream()
          .map(locked::get)
          .map(entry -> new BuildPlan.PackageInput(entry.name(), entry.archiveIdentity()))
          .toList();
      for (PackageManifest.Target target : dependency.manifest().targets()) {
        byte[] source = TargetSourceSet.canonicalInput(target, dependency.entries());
        result.add(BuildPlan.Node.create(
            dependency.manifest().name(),
            dependency.manifest().version(),
            dependency.manifest().identity(),
            target.name(),
            target.kind(),
            PackageProject.sha256(source),
            prefix + "/dependencies/" + name + "/" + target.name() + ".wbc",
            inputs,
            dependency.manifest().capabilities(),
            BuildPlan.ExecutionLimits.DEFAULT,
            grantRequestedCapabilities ? dependency.manifest().capabilities() : List.of()));
      }
    }
    return List.copyOf(result);
  }

  List<BuildPlan.PackageInput> rootInputs(PackageManifest root) {
    Map<String, PackageLock.Entry> entries = lockEntries(lock);
    return included(root.dependencies(), development).stream()
        .map(Dependency::name)
        .sorted()
        .map(entries::get)
        .map(entry -> new BuildPlan.PackageInput(entry.name(), entry.archiveIdentity()))
        .toList();
  }

  private static boolean graphMatches(
      PackageManifest root,
      PackageLock lock,
      Map<String, DecodedPackage> packages,
      boolean development) {
    Map<String, PackageLock.Entry> entries = lockEntries(lock);
    if (!dependenciesMatch(root.dependencies(), entries, development)) {
      return false;
    }
    for (PackageLock.Entry entry : lock.entries()) {
      DecodedPackage dependency = packages.get(entry.name());
      List<Dependency> declared = included(dependency.manifest().dependencies(), development);
      List<String> names = declared.stream().map(Dependency::name).sorted().toList();
      if (!names.equals(entry.dependencies()) || !dependenciesMatch(declared, entries, true)) {
        return false;
      }
    }
    Set<String> reachable = new HashSet<>();
    collect(
        included(root.dependencies(), development).stream().map(Dependency::name).toList(),
        entries,
        reachable);
    return reachable.equals(entries.keySet());
  }

  private static boolean dependenciesMatch(
      List<Dependency> dependencies,
      Map<String, PackageLock.Entry> entries,
      boolean includeAll) {
    for (Dependency dependency : includeAll ? dependencies : included(dependencies, false)) {
      PackageLock.Entry selected = entries.get(dependency.name());
      if (selected == null
          || !VersionConstraint.parse(dependency.constraint()).accepts(
              com.typeobject.wheeler.packageformat.SemanticVersion.parse(selected.version()))) {
        return false;
      }
    }
    return true;
  }

  private static List<Dependency> included(
      List<Dependency> dependencies, boolean development) {
    return dependencies.stream()
        .filter(dependency -> development || dependency.kind() != DependencyKind.DEVELOPMENT)
        .toList();
  }

  private static List<String> topologicalOrder(
      PackageManifest root, PackageLock lock, boolean development) {
    Map<String, PackageLock.Entry> entries = lockEntries(lock);
    List<String> result = new ArrayList<>();
    Set<String> complete = new HashSet<>();
    for (String name : included(root.dependencies(), development).stream()
        .map(Dependency::name).sorted().toList()) {
      visit(name, entries, complete, new HashSet<>(), result);
    }
    return List.copyOf(result);
  }

  private static void visit(
      String name,
      Map<String, PackageLock.Entry> entries,
      Set<String> complete,
      Set<String> active,
      List<String> result) {
    if (complete.contains(name)) {
      return;
    }
    if (!active.add(name)) {
      throw new PackageFormatException("Cyclic locked dependency at " + name);
    }
    PackageLock.Entry entry = entries.get(name);
    if (entry == null) {
      throw new PackageFormatException("Missing locked dependency " + name);
    }
    for (String dependency : entry.dependencies()) {
      visit(dependency, entries, complete, active, result);
    }
    active.remove(name);
    complete.add(name);
    result.add(name);
  }

  private static void collect(
      List<String> roots, Map<String, PackageLock.Entry> entries, Set<String> result) {
    for (String name : roots) {
      if (result.add(name)) {
        PackageLock.Entry entry = entries.get(name);
        if (entry != null) {
          collect(entry.dependencies(), entries, result);
        }
      }
    }
  }

  private static Program compileTarget(
      WheelerCompiler compiler,
      DecodedPackage dependency,
      PackageManifest.Target target,
      Map<String, String> linkedModules,
      Map<String, String> directModules) {
    Map<String, String> sources = TargetSourceSet.strictText(target, dependency.entries());
    if (!target.modular()) {
      if (target.kind() == TargetKind.LIBRARY) {
        throw new PackageFormatException(
            "Library target must declare an exact module source set: " + target.name());
      }
      return compiler.compile(sources.get(target.root()));
    }
    compiler.validateDirectPackageImports(sources, directModules);
    return target.kind() == TargetKind.LIBRARY
        ? compiler.compilePackageLibraryModuleFiles(sources, linkedModules, target.module())
        : compiler.compilePackageModuleFiles(sources, linkedModules, target.module());
  }

  private static void addLibrarySources(
      String packageName,
      DecodedPackage dependency,
      Map<String, String> destination) {
    for (PackageManifest.Target target : dependency.manifest().targets()) {
      if (target.kind() != TargetKind.LIBRARY) {
        continue;
      }
      if (!target.modular()) {
        throw new PackageFormatException(
            "Library target must declare an exact module source set: " + target.name());
      }
      TargetSourceSet.strictText(target, dependency.entries()).forEach((path, source) -> {
        String key = "dependencies/" + packageName + "/" + target.name() + "/" + path;
        if (destination.putIfAbsent(key, source) != null) {
          throw new PackageFormatException("Duplicate linked library source " + key);
        }
      });
    }
  }

  private static Map<String, PackageLock.Entry> lockEntries(PackageLock lock) {
    Map<String, PackageLock.Entry> result = new HashMap<>();
    lock.entries().forEach(entry -> result.put(entry.name(), entry));
    return Map.copyOf(result);
  }

  private static void requirePhysicalFile(Path path, String description) throws IOException {
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(path)) {
      throw new IOException("Missing physical " + description + ": " + path);
    }
  }

  private static void verifyExactFiles(Path vendor, Set<String> expected) throws IOException {
    Set<String> actual = new TreeSet<>();
    try (Stream<Path> files = Files.list(vendor)) {
      for (Path file : files.toList()) {
        requirePhysicalFile(file, "vendor input");
        actual.add(file.getFileName().toString());
      }
    }
    if (!actual.equals(expected)) {
      throw new PackageFormatException("Vendor tree does not equal the locked package set");
    }
  }
}
