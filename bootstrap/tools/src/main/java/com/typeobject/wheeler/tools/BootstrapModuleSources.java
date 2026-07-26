package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageManifest;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Derives and verifies bootstrap module graphs from exact compiler package sources. */
final class BootstrapModuleSources {
  private BootstrapModuleSources() {}

  static BootstrapModuleManifest derive(DecodedPackage sourcePackage) throws IOException {
    return derive(sourcePackage.manifest().profile(), inspect(sourcePackage));
  }

  private static BootstrapModuleManifest derive(String profile, Inspected inspected) {
    Set<String> localNames = inspected.byName().keySet();
    Set<String> externals = new HashSet<>();
    List<BootstrapModuleManifest.Module> modules = new ArrayList<>();
    for (Source source : inspected.sources()) {
      for (String imported : source.header().imports()) {
        if (!localNames.contains(imported)) {
          externals.add(imported);
        }
      }
      modules.add(new BootstrapModuleManifest.Module(
          source.header().name(), source.path(), sha256(source.bytes()), source.header().imports()));
    }
    return new BootstrapModuleManifest(
        profile,
        inspected.target().module(),
        List.copyOf(externals),
        modules);
  }

  static void verify(
      DecodedPackage sourcePackage, BootstrapModuleManifest manifest) throws IOException {
    Inspected inspected = inspect(sourcePackage);
    if (!inspected.target().module().equals(manifest.root())) {
      throw new IOException("Bootstrap module root does not match the compiler target");
    }
    if (inspected.sources().size() != manifest.modules().size()) {
      throw new IOException("Compiler target module count differs from the manifest");
    }
    for (BootstrapModuleManifest.Module module : manifest.modules()) {
      Source source = inspected.byName().get(module.name());
      if (source == null || !source.path().equals(module.source())) {
        throw new IOException("Bootstrap module is absent or has a different source: "
            + module.name());
      }
      if (!sha256(source.bytes()).equals(module.identity())) {
        throw new IOException("Bootstrap module source is stale: " + module.source());
      }
      if (!source.header().imports().equals(module.imports())) {
        throw new IOException("Bootstrap module header differs from manifest: " + module.source());
      }
    }
    BootstrapModuleManifest derived = derive(sourcePackage.manifest().profile(), inspected);
    if (!derived.externals().equals(manifest.externals())) {
      throw new IOException("Bootstrap external module set differs from source imports");
    }
  }

  private static Inspected inspect(DecodedPackage sourcePackage) throws IOException {
    PackageManifest.Target target = compilerTarget(sourcePackage);
    Map<String, byte[]> entries = sourcePackage.entries();
    List<Source> sources = new ArrayList<>();
    Map<String, Source> byName = new HashMap<>();
    for (Map.Entry<String, byte[]> entry : entries.entrySet()) {
      String path = entry.getKey();
      if (!path.endsWith(".w") || !selectedBy(path, target.sources())) {
        continue;
      }
      SourceModuleInspection.Header header;
      try {
        header = SourceModuleInspection.inspect(entry.getValue());
      } catch (RuntimeException exception) {
        throw new IOException("Cannot inspect bootstrap module " + path, exception);
      }
      Source source = new Source(path, entry.getValue(), header);
      if (byName.put(header.name(), source) != null) {
        throw new IOException("Duplicate compiler module " + header.name());
      }
      sources.add(source);
    }
    if (sources.isEmpty()) {
      throw new IOException("Compiler target selects no Wheeler modules");
    }
    return new Inspected(target, List.copyOf(sources), Map.copyOf(byName));
  }

  private static PackageManifest.Target compilerTarget(DecodedPackage sourcePackage)
      throws IOException {
    PackageManifest.Target target = sourcePackage.manifest().targets().stream()
        .filter(candidate -> candidate.kind() == PackageManifest.TargetKind.TOOL)
        .filter(candidate -> candidate.name().equals("compiler"))
        .findFirst()
        .orElseThrow(() -> new IOException("Compiler package has no compiler tool target"));
    if (!target.modular()) {
      throw new IOException("Compiler tool target is not modular");
    }
    return target;
  }

  private static boolean selectedBy(String path, List<String> selectors) {
    for (String selector : selectors) {
      if (path.equals(selector) || path.startsWith(selector + "/")) {
        return true;
      }
    }
    return false;
  }

  private static String sha256(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private record Source(String path, byte[] bytes, SourceModuleInspection.Header header) {
    private Source {
      bytes = bytes.clone();
    }

    @Override
    public byte[] bytes() {
      return bytes.clone();
    }
  }

  private record Inspected(
      PackageManifest.Target target, List<Source> sources, Map<String, Source> byName) {}
}
