//! Preserves the bounded compiler API over the lowering core and graph compiler.

module wheeler.compiler.driver;

import wheeler.compiler.closure.active_source_slots;
import wheeler.compiler.closure.archive_module_sources;
import wheeler.compiler.closure.archive_sources;
import wheeler.compiler.closure.counted_constant_executor;
import wheeler.compiler.closure.module_manifest;
import wheeler.compiler.closure.module_symbols;
import wheeler.compiler.closure.package_target;
import wheeler.compiler.closure.plan;
import wheeler.compiler.closure.scalar_module_identities;
import wheeler.compiler.closure.schedule;
import wheeler.compiler.closure.small_executor;
import wheeler.compiler.compiler_core;
import wheeler.compiler.compiler_graphs;

classical class CompilerDriver {
  /// Carries the exact bounds of one verified compiler artifact.
  public record Compilation(long length, long codeStart) {}

  private Compilation publicCompilation(GraphCompilation compiled) {
    return new Compilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one bounded bootstrap source into caller-owned artifact storage.
  public Compilation compileMinimal(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new Compilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one root with one direct scalar-constant module.
  public Compilation compileMinimalWithConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    return publicCompilation(compileGraphWithConstantImport(importedSource, rootSource, output));
  }

  /// Compiles a two-module constant graph and its root.
  public Compilation compileMinimalWithConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    return publicCompilation(
      compileGraphWithConstantImports(
        firstImportedSource,
        secondImportedSource,
        rootSource,
        output
      )
    );
  }

  /// Compiles a three-module constant graph and its root.
  public Compilation compileMinimalWithThreeConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    return publicCompilation(
      compileGraphWithThreeConstantImports(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        rootSource,
        output
      )
    );
  }

  /// Compiles a supported four-module constant graph and its root.
  public Compilation compileMinimalWithFourConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    return publicCompilation(
      compileGraphWithFourConstantImports(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      )
    );
  }

  /// Compiles one supported six-module scalar-constant graph and its root.
  public Compilation compileMinimalWithSixConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    return publicCompilation(
      compileGraphWithSixConstantImports(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        rootSource,
        output
      )
    );
  }

  /// Compiles one supported seven-module scalar-constant graph and its root.
  public Compilation compileMinimalWithSevenConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 seventhImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    return publicCompilation(
      compileGraphWithSevenConstantImports(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      )
    );
  }

  /// Compiles one supported five-module constant graph and its root.
  public Compilation compileMinimalWithFiveConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    return publicCompilation(
      compileGraphWithFiveConstantImports(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        rootSource,
        output
      )
    );
  }
}
