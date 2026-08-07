//! Links one two-module chain whose leaf remains a direct root import.

module wheeler.compiler.graphs.two_redundant;

import wheeler.compiler.compiler_core;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class RedundantTwoGraph {
  /// Carries one redundant two-module graph compilation result.
  public record RedundantTwoCompilation(long length, long codeStart) {}

  private RedundantTwoCompilation compileGraphSource(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan plan,
    boolean importedHelpers
  ) {
    if (importedHelpers) {
      HelperOwner imported = importedHelperOwner(
        plan.linkedOwnerStart,
        plan.linkedOwnerLength,
        plan.importedHelperCount
      );
      CoreCompilation compiledHelpers = compileMinimalCoreWithHelperOwners(
        source,
        output,
        oneHelperOwner(imported)
      );
      return new RedundantTwoCompilation(compiledHelpers.length, compiledHelpers.codeStart);
    }

    CoreCompilation compiled = compileMinimalCore(source, output);
    return new RedundantTwoCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles a chain after retaining the same leaf as one direct root import.
  public RedundantTwoCompilation compileRedundantTwoGraph(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan dependencyPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependencyPlan.valid) {} else {
      assert(0 == 1);
    }

    region linkedDependencyArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes linkedDependencyBytes = allocateBytes(
      linkedDependencyArena,
      dependencyPlan.linkedLength
    );
    long dependencyWritten = writeConstantImport(
      leafSource,
      dependentSource,
      dependencyPlan,
      linkedDependencyBytes
    );
    assert(dependencyWritten == dependencyPlan.linkedLength);
    utf8 linkedDependency = freezeUtf8(linkedDependencyBytes);

    LinkPlan leafPlan = planConstantImport(leafSource, rootSource, /* expectedImportCount= */ 2);
    if (leafPlan.valid) {} else {
      assert(0 == 1);
    }

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, leafPlan.linkedLength);
    long rootWritten = writeConstantImport(leafSource, rootSource, leafPlan, rootBytes);
    assert(rootWritten == leafPlan.linkedLength);
    utf8 linkedRoot = freezeUtf8(rootBytes);

    LinkPlan dependentPlan = planSharedResolvedPublicConstantImport(
      linkedDependency,
      linkedRoot,
      /* expectedImportCount= */ 2
    );
    boolean importedHelpers = false;
    if (dependentPlan.valid) {} else {
      dependentPlan = planSharedResolvedHelperImport(
        linkedDependency,
        linkedRoot,
        /* expectedImportCount= */ 2
      );
      importedHelpers = dependentPlan.valid;
    }

    if (dependentPlan.valid) {} else {
      assert(0 == 1);
    }

    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, dependentPlan.linkedLength);
    long finalWritten = writeConstantImport(
      linkedDependency,
      linkedRoot,
      dependentPlan,
      finalBytes
    );
    assert(finalWritten == dependentPlan.linkedLength);
    utf8 finalSource = freezeUtf8(finalBytes);
    RedundantTwoCompilation compiled = compileGraphSource(
      finalSource,
      output,
      dependentPlan,
      importedHelpers
    );

    drop(finalSource);
    drop(finalArena);
    drop(linkedRoot);
    drop(rootArena);
    drop(linkedDependency);
    drop(linkedDependencyArena);
    return compiled;
  }
}
