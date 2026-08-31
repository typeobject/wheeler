package com.typeobject.wheeler.examples;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Native examples for package-manifest source selectors. */
final class NativeCompilerPackageManifestSelectorsExampleTest {
  private static final String MODULE = "wheeler.compiler.packages.manifest_selectors";
  private static final String SELECTORS =
      "\"src\" \"src/Main.w\" \"src/Main.w\" \"src\" \"lib\" \"srcx/Main.w\"";

  @Test
  void executesEqualDirectoryLongerMismatchAndDelimiterChecks() throws Exception {
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure(MODULE));
    sources.put("PackageManifestSelectorsExample.w", """
        module example.package_manifest_selectors;

        import wheeler.compiler.packages.manifest_selectors;

        classical class PackageManifestSelectorsExample {
          entry void main(borrow utf8 source) {
            assert(manifestSelectorRangeCoversRoot(source, 1, 3, 7, 10));
            assert(manifestSelectorRangeCoversRoot(source, 20, 10, 33, 3) == false);
            assert(manifestSelectorRangeCoversRoot(source, 33, 3, 1, 3));
            assert(manifestSelectorRangeCoversRoot(source, 39, 3, 7, 10) == false);
            assert(manifestSelectorRangeCoversRoot(source, 1, 3, 45, 11) == false);
          }
        }
        """);
    var program = new WheelerCompiler().compileModuleFiles(
        sources, "example.package_manifest_selectors");

    new VirtualMachine(program, SELECTORS.getBytes(StandardCharsets.US_ASCII)).run();
  }
}
