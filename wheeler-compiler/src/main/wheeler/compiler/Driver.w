//! Preserves the bounded compiler API over the lowering core and graph compiler.

module wheeler.compiler.driver;

import wheeler.compiler.closure.active_source_slots;
import wheeler.compiler.closure.aggregate_dependency_products;
import wheeler.compiler.closure.aggregate_descriptor_rows;
import wheeler.compiler.closure.aggregate_identities;
import wheeler.compiler.closure.aggregate_loan_verifier;
import wheeler.compiler.closure.aggregate_operand_relocations;
import wheeler.compiler.closure.aggregate_type_resolution;
import wheeler.compiler.closure.archive_module_sources;
import wheeler.compiler.closure.archive_sources;
import wheeler.compiler.closure.callable_dependency_products;
import wheeler.compiler.closure.callable_function_rows;
import wheeler.compiler.closure.callable_identities;
import wheeler.compiler.closure.canonical_product_emitter;
import wheeler.compiler.closure.compiled_aggregate_layouts;
import wheeler.compiler.closure.compiled_body_archive;
import wheeler.compiler.closure.compiled_callable_bodies;
import wheeler.compiler.closure.compiled_function_names;
import wheeler.compiler.closure.compiled_function_products;
import wheeler.compiler.closure.compiled_global_products;
import wheeler.compiler.closure.compiled_proof_products;
import wheeler.compiler.closure.compiled_string_products;
import wheeler.compiler.closure.counted_aggregate_layouts;
import wheeler.compiler.closure.counted_constant_executor;
import wheeler.compiler.closure.counted_function_products;
import wheeler.compiler.closure.function_product_identities;
import wheeler.compiler.closure.identity_relocation_emitter;
import wheeler.compiler.closure.imported_call_relocations;
import wheeler.compiler.closure.instruction_ownership_products;
import wheeler.compiler.closure.linked_aggregate_sections;
import wheeler.compiler.closure.linked_container;
import wheeler.compiler.closure.linked_function_section;
import wheeler.compiler.closure.linked_instruction_code;
import wheeler.compiler.closure.linked_local_types;
import wheeler.compiler.closure.linked_manifest_section;
import wheeler.compiler.closure.linked_proof_section;
import wheeler.compiler.closure.linked_string_section;
import wheeler.compiler.closure.local_call_relocations;
import wheeler.compiler.closure.module_callables;
import wheeler.compiler.closure.module_manifest;
import wheeler.compiler.closure.module_symbols;
import wheeler.compiler.closure.ownership_product_identities;
import wheeler.compiler.closure.package_target;
import wheeler.compiler.closure.plan;
import wheeler.compiler.closure.relocation_identities;
import wheeler.compiler.closure.scalar_module_identities;
import wheeler.compiler.closure.schedule;
import wheeler.compiler.closure.small_executor;
import wheeler.compiler.closure.source_call_products;
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
