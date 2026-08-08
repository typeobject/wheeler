package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.SourceModuleInspection;
import com.typeobject.wheeler.packageformat.BootstrapModuleManifest;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageManifestParser;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Builds bounded package fixtures for counted scalar module products. */
final class NativeCompilerProductFixtures {
  private NativeCompilerProductFixtures() {}

  static Fixture expressions() throws Exception {
    Map<String, byte[]> sources = new LinkedHashMap<>();
    sources.put("src/A.w", bytes(
        "module product.a; classical class A { public const long A = 5; }"));
    sources.put("src/B.w", bytes(
        "module product.b; import product.a; classical class B { "
            + "public const long B = A * 2 + 1; }"));
    sources.put("src/C.w", bytes(
        "module product.c; import product.b; classical class C { "
            + "public const long C = (B - 1) / 2; }"));
    sources.put("src/D.w", bytes(
        "module product.d; import product.a; import product.c; classical class D { "
            + "public const boolean D = A < C; }"));
    sources.put("src/E.w", bytes(
        "module product.e; import product.d; classical class E { "
            + "public const boolean E = !D; }"));
    sources.put("src/F.w", bytes(
        "module product.f; import product.a; import product.e; classical class F { "
            + "public const boolean F = product.e::E == true; }"));
    sources.put("src/G.w", bytes(
        "module product.g; import product.f; classical class G { "
            + "public const boolean G = F; }"));
    sources.put("src/Root.w", bytes(
        "module product.root; import product.g; classical class Root { "
            + "public const boolean ROOT = G; }"));
    return fixture("demo.products", "src/Root.w", "product.root", "src", sources);
  }

  static Fixture ambiguous() throws Exception {
    Map<String, byte[]> sources = new LinkedHashMap<>();
    sources.put("src/Left.w", bytes(
        "module ambiguity.left; classical class Left { public const long X = 1; }"));
    sources.put("src/Right.w", bytes(
        "module ambiguity.right; classical class Right { public const long X = 2; }"));
    sources.put("src/Root.w", bytes(
        "module ambiguity.root; import ambiguity.left; import ambiguity.right; "
            + "classical class Root { public const long ROOT = X; }"));
    return fixture("demo.ambiguity", "src/Root.w", "ambiguity.root", "src", sources);
  }

  static Fixture executableQualifiedValues() throws Exception {
    Map<String, byte[]> sources = new LinkedHashMap<>();
    sources.put("src/Values.w", bytes(
        "module product.values; classical class Values { "
            + "public const long NEGATIVE = -42; public const boolean READY = true; }"));
    sources.put("src/Root.w", bytes(
        "module product.root; import product.values; classical class Root { "
            + "state long outcome = 0; entry void main() { "
            + "outcome += product.values::NEGATIVE; assert(product.values::READY); } }"));
    return fixture(
        "demo.qualified.values",
        "src/Root.w",
        "product.root",
        "src",
        sources);
  }

  static Fixture executableForwardingChain(int dependencyCount) throws Exception {
    Map<String, byte[]> sources = forwardingSources(dependencyCount);
    String imported = "forward.n%03d".formatted(dependencyCount - 1);
    sources.put("src/forward/Root.w", bytes((
        "module forward.root; import %s; classical class Root { "
            + "state long outcome = 0; entry void main() { outcome += V%03d; } }")
                .formatted(imported, dependencyCount - 1)));
    return fixture(
        "demo.forward.executable",
        "src/forward/Root.w",
        "forward.root",
        "src/forward",
        sources);
  }

  static Fixture forwardingChain(int count) throws Exception {
    Map<String, byte[]> sources = forwardingSources(count);
    String root = "src/forward/n%03d.w".formatted(count - 1);
    String module = "forward.n%03d".formatted(count - 1);
    return fixture("demo.forward", root, module, "src/forward", sources);
  }

  private static Map<String, byte[]> forwardingSources(int count) {
    Map<String, byte[]> sources = new LinkedHashMap<>();
    for (int index = 0; index < count; index++) {
      String name = "forward.n%03d".formatted(index);
      String path = "src/forward/n%03d.w".formatted(index);
      String imported = index == 0 ? "" : " import forward.n%03d;".formatted(index - 1);
      String expression = index == 0 ? "41" : "V%03d".formatted(index - 1);
      sources.put(path, bytes(
          "module %s;%s classical class Node%03d { public const long V%03d = %s; }"
              .formatted(name, imported, index, index, expression)));
    }
    return sources;
  }

  private static Fixture fixture(
      String packageName,
      String root,
      String rootModule,
      String selector,
      Map<String, byte[]> sources) throws Exception {
    MessageDigest sha256 = MessageDigest.getInstance("SHA-256");
    List<BootstrapModuleManifest.Module> modules = new ArrayList<>();
    for (Map.Entry<String, byte[]> entry : sources.entrySet()) {
      SourceModuleInspection.Header header = SourceModuleInspection.inspect(entry.getValue());
      modules.add(new BootstrapModuleManifest.Module(
          header.name(),
          entry.getKey(),
          HexFormat.of().formatHex(sha256.digest(entry.getValue())),
          header.imports()));
    }
    BootstrapModuleManifest manifest = new BootstrapModuleManifest(
        "bootstrap-1", rootModule, List.of(), modules);
    String packageText = """
        schema: 1
        package:
          name: "%s"
          version: "1.0.0"
          profile: "bootstrap-1"
        targets:
          - kind: "tool"
            name: "compiler"
            root: "%s"
            module: "%s"
            sources:
              - "%s"
            test: false
        dependencies: []
        capabilities: []
        """.formatted(packageName, root, rootModule, selector);
    byte[] archive = new PackageArchive().encode(
        new PackageManifestParser().parse(packageText), sources);
    return new Fixture(archive, manifest, Map.copyOf(sources));
  }

  private static byte[] bytes(String source) {
    return source.getBytes(StandardCharsets.UTF_8);
  }

  record Fixture(
      byte[] archive,
      BootstrapModuleManifest manifest,
      Map<String, byte[]> sources) {}
}
