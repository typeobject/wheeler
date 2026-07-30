//! Resolves bounded constant module graphs before canonical lowering.

module wheeler.compiler.compiler_graphs;

import wheeler.compiler.compiler_core;
import wheeler.compiler.compiler_graph_five;
import wheeler.compiler.compiler_graph_four;
import wheeler.compiler.compiler_graph_six;
import wheeler.compiler.module_linker;

classical class CompilerGraphs {
  /// Carries private graph-compilation bounds across the driver boundary.
  public record GraphCompilation(long length, long codeStart) {}

  private GraphCompilation compileGraphSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one root with one direct scalar-constant module.
  public GraphCompilation compileGraphWithConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan plan = planConstantImport(importedSource, rootSource, /* expectedImportCount= */ 1);
    if (plan.valid) {} else {
      assert(0 == 1);
    }

    region linkedArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    utf8 linkedSource = freezeUtf8(linkedBytes);
    GraphCompilation compiled = compileGraphSource(linkedSource, output);
    drop(linkedSource);
    drop(linkedArena);
    return compiled;
  }

  private GraphCompilation compileConstantChain(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      assert(0 == 1);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, leafPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      leafPlan,
      dependentBytes
    );
    assert(dependentWritten == leafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      assert(0 == 1);
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
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    GraphCompilation compiled = compileGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return compiled;
  }

  /// Compiles one root with two direct modules or one two-edge constant chain.
  public GraphCompilation compileGraphWithConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstChain = planPrivateConstantImport(
      firstImportedSource,
      secondImportedSource,
      /* expectedImportCount= */ 1
    );
    if (firstChain.valid) {
      return compileConstantChain(firstImportedSource, secondImportedSource, rootSource, output);
    }

    LinkPlan secondChain = planPrivateConstantImport(
      secondImportedSource,
      firstImportedSource,
      /* expectedImportCount= */ 1
    );
    if (secondChain.valid) {
      return compileConstantChain(secondImportedSource, firstImportedSource, rootSource, output);
    }

    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstImportedSource,
      rootSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondImportedSource,
      firstLinkedSource,
      /* expectedImportCount= */ 2
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondImportedSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);
    GraphCompilation compiled = compileGraphSource(secondLinkedSource, output);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  private GraphCompilation compileThreeConstantChainIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new GraphCompilation(0, 0);
    }

    region middleArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, leafPlan.linkedLength);
    long middleWritten = writeConstantImport(leafSource, middleSource, leafPlan, middleBytes);
    assert(middleWritten == leafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(middleBytes);

    LinkPlan middlePlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (middlePlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(middleArena);
      return new GraphCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, middlePlan.linkedLength);
    long dependentWritten = writeConstantImport(
      linkedMiddleSource,
      dependentSource,
      middlePlan,
      dependentBytes
    );
    assert(dependentWritten == middlePlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new GraphCompilation(0, 0);
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
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    GraphCompilation compiled = compileGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return compiled;
  }

  private GraphCompilation compileConstantForkIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      dependentSource,
      /* expectedImportCount= */ 2
    );
    if (firstLeafPlan.valid) {} else {
      return new GraphCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstLeafPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstLeafSource,
      dependentSource,
      firstLeafPlan,
      firstBytes
    );
    assert(firstWritten == firstLeafPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedSource,
      /* expectedImportCount= */ 2
    );
    if (secondLeafPlan.valid) {} else {
      drop(firstLinkedSource);
      drop(firstArena);
      return new GraphCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondLeafPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedSource,
      secondLeafPlan,
      secondBytes
    );
    assert(secondWritten == secondLeafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(secondBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new GraphCompilation(0, 0);
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
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    GraphCompilation compiled = compileGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  private GraphCompilation compileMixedConstantsIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new GraphCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, leafPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      leafPlan,
      dependentBytes
    );
    assert(dependentWritten == leafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan dependentPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (dependentPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      return new GraphCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, dependentPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      dependentPlan,
      rootBytes
    );
    assert(rootWritten == dependentPlan.linkedLength);
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
      return new GraphCompilation(0, 0);
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
    GraphCompilation compiled = compileGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return compiled;
  }

  /// Compiles one root with a bounded three-module constant tree.
  public GraphCompilation compileGraphWithThreeConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    GraphCompilation chain = compileThreeConstantChainIfOrdered(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      rootSource,
      output
    );
    if (0 < chain.length) {
      return chain;
    }

    chain = compileThreeConstantChainIfOrdered(
      firstImportedSource,
      thirdImportedSource,
      secondImportedSource,
      rootSource,
      output
    );
    if (0 < chain.length) {
      return chain;
    }

    chain = compileThreeConstantChainIfOrdered(
      secondImportedSource,
      firstImportedSource,
      thirdImportedSource,
      rootSource,
      output
    );
    if (0 < chain.length) {
      return chain;
    }

    chain = compileThreeConstantChainIfOrdered(
      secondImportedSource,
      thirdImportedSource,
      firstImportedSource,
      rootSource,
      output
    );
    if (0 < chain.length) {
      return chain;
    }

    chain = compileThreeConstantChainIfOrdered(
      thirdImportedSource,
      firstImportedSource,
      secondImportedSource,
      rootSource,
      output
    );
    if (0 < chain.length) {
      return chain;
    }

    chain = compileThreeConstantChainIfOrdered(
      thirdImportedSource,
      secondImportedSource,
      firstImportedSource,
      rootSource,
      output
    );
    if (0 < chain.length) {
      return chain;
    }

    GraphCompilation fork = compileConstantForkIfOrdered(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      rootSource,
      output
    );
    if (0 < fork.length) {
      return fork;
    }

    fork = compileConstantForkIfOrdered(
      firstImportedSource,
      thirdImportedSource,
      secondImportedSource,
      rootSource,
      output
    );
    if (0 < fork.length) {
      return fork;
    }

    fork = compileConstantForkIfOrdered(
      secondImportedSource,
      thirdImportedSource,
      firstImportedSource,
      rootSource,
      output
    );
    if (0 < fork.length) {
      return fork;
    }

    GraphCompilation mixed = compileMixedConstantsIfOrdered(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return mixed;
    }

    mixed = compileMixedConstantsIfOrdered(
      firstImportedSource,
      thirdImportedSource,
      secondImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return mixed;
    }

    mixed = compileMixedConstantsIfOrdered(
      secondImportedSource,
      firstImportedSource,
      thirdImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return mixed;
    }

    mixed = compileMixedConstantsIfOrdered(
      secondImportedSource,
      thirdImportedSource,
      firstImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return mixed;
    }

    mixed = compileMixedConstantsIfOrdered(
      thirdImportedSource,
      firstImportedSource,
      secondImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return mixed;
    }

    mixed = compileMixedConstantsIfOrdered(
      thirdImportedSource,
      secondImportedSource,
      firstImportedSource,
      rootSource,
      output
    );
    if (0 < mixed.length) {
      return mixed;
    }

    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ 3
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstImportedSource,
      rootSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondImportedSource,
      firstLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondImportedSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan thirdPlan = planConstantImport(
      thirdImportedSource,
      secondLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
    }

    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      thirdImportedSource,
      secondLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);
    GraphCompilation compiled = compileGraphSource(thirdLinkedSource, output);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  /// Compiles one root with six direct scalar-constant modules.
  public GraphCompilation compileGraphWithSixConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixGraphCompilation compiled = compileSixDirectConstants(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      fifthImportedSource,
      sixthImportedSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one supported five-module scalar-constant graph and its root.
  public GraphCompilation compileGraphWithFiveConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveGraphCompilation compiled = compileFiveConstantGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      fifthImportedSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one root with a supported four-module constant graph.
  public GraphCompilation compileGraphWithFourConstantImports(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FourGraphCompilation compiled = compileFourConstantGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }
}
