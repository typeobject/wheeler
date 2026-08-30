package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Native examples for package-manifest sequence brackets. */
final class NativeCompilerPackageManifestBracketsExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_brackets";

  @Test
  void executesOpeningClosingAndKindChecks() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestBracketsExample.w", """
        module example.package_manifest_brackets;

        import wheeler.compiler.packages.manifest_brackets;

        classical class PackageManifestBracketsExample {
          entry void main(borrow utf8 source) {
            region tokens = new region(/* bytes= */ 128, /* allocations= */ 2);
            words kinds = allocate(tokens, /* length= */ 4);
            words starts = allocate(tokens, /* length= */ 4);
            set(kinds, 0, 3);
            set(kinds, 1, 3);
            set(kinds, 3, 3);
            set(starts, 1, 1);
            set(starts, 2, 3);
            set(starts, 3, 4);
            assert(manifestOpenBracketAt(source, kinds, starts, 0));
            assert(manifestCloseBracketAt(source, kinds, starts, 1));
            assert(manifestCloseBracketAt(source, kinds, starts, 0) == false);
            assert(manifestOpenBracketAt(source, kinds, starts, 1) == false);
            assert(manifestOpenBracketAt(source, kinds, starts, 2) == false);
            assert(manifestCloseBracketAt(source, kinds, starts, 3));
            drop(starts);
            drop(kinds);
            drop(tokens);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_brackets");

    new VirtualMachine(program, "[] x]".getBytes(StandardCharsets.US_ASCII)).run();
  }
}
