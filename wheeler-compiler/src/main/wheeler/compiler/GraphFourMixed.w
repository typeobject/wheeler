//! Resolves bounded four-module trees with one transitive chain beside one direct module.

module wheeler.compiler.compiler_graph_four_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerGraphFourMixed {
  /// Carries private mixed four-module compilation bounds.
  public record MixedFourCompilation(long length, long codeStart) {}

  private MixedFourCompilation compileMixedSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new MixedFourCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one exact planned chain beside one direct import.
  public MixedFourCompilation compileChainAndDirectIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new MixedFourCompilation(0, 0);
    }

    region middleArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, leafPlan.linkedLength);
    long middleWritten = writeConstantImport(leafSource, middleSource, leafPlan, middleBytes);
    assert(middleWritten == leafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(middleBytes);

    LinkPlan dependentPlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependentPlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(middleArena);
      return new MixedFourCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, dependentPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      linkedMiddleSource,
      dependentSource,
      dependentPlan,
      dependentBytes
    );
    assert(dependentWritten == dependentPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new MixedFourCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      rootPlan,
      rootBytes
    );
    assert(rootWritten == rootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(rootBytes);

    LinkPlan directPlan = planConstantImport(
      directSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ 2
    );
    if (directPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new MixedFourCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, directPlan.linkedLength);
    long finalWritten = writeConstantImport(
      directSource,
      firstLinkedRootSource,
      directPlan,
      finalBytes
    );
    assert(finalWritten == directPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    MixedFourCompilation compiled = compileMixedSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return compiled;
  }

}
