//! Resolves the five-module four-leaf constant fork.

module wheeler.compiler.graphs.five_fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveFork {
  /// Carries private five-module fork compilation bounds.
  public record FiveForkCompilation(long length, long codeStart) {}

  private FiveForkCompilation compileFourLeafForkIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 fourthLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planPrivateConstantImport(
      firstLeafSource,
      dependentSource,
      /* expectedImportCount= */ 4
    );
    if (firstPlan.valid) {} else {
      return new FiveForkCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstLeafSource,
      dependentSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedSource,
      /* expectedImportCount= */ 4
    );
    if (secondPlan.valid) {} else {
      drop(firstLinkedSource);
      drop(firstArena);
      return new FiveForkCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan thirdPlan = planPrivateConstantImport(
      thirdLeafSource,
      secondLinkedSource,
      /* expectedImportCount= */ 4
    );
    if (thirdPlan.valid) {} else {
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new FiveForkCompilation(0, 0);
    }

    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      thirdLeafSource,
      secondLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);

    LinkPlan fourthPlan = planPrivateConstantImport(
      fourthLeafSource,
      thirdLinkedSource,
      /* expectedImportCount= */ 4
    );
    if (fourthPlan.valid) {} else {
      drop(thirdLinkedSource);
      drop(thirdArena);
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new FiveForkCompilation(0, 0);
    }

    region fourthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthPlan.linkedLength);
    long fourthWritten = writeConstantImport(
      fourthLeafSource,
      thirdLinkedSource,
      fourthPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(fourthBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(fourthArena);
      drop(thirdLinkedSource);
      drop(thirdArena);
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new FiveForkCompilation(0, 0);
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
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(fourthArena);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return new FiveForkCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles four leaves through one root-visible dependent.
  public FiveForkCompilation compileFourLeafConstantFork(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveForkCompilation compiled = compileFourLeafForkIfOrdered(
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      firstSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFourLeafForkIfOrdered(
      firstSource,
      thirdSource,
      fourthSource,
      fifthSource,
      secondSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFourLeafForkIfOrdered(
      firstSource,
      secondSource,
      fourthSource,
      fifthSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFourLeafForkIfOrdered(
      firstSource,
      secondSource,
      thirdSource,
      fifthSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileFourLeafForkIfOrdered(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
  }

}
