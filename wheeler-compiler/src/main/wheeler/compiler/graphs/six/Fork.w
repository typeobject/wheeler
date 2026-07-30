//! Resolves one six-module five-leaf scalar-constant fork.

module wheeler.compiler.graphs.six.fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class SixConstantFork {
  /// Carries one attempted six-module fork compilation.
  public record SixForkCompilation(long length, long codeStart) {}

  private SixForkCompilation compileFiveLeafForkIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 fourthLeafSource,
    borrow utf8 fifthLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planPrivateConstantImport(
      firstLeafSource,
      dependentSource,
      /* expectedImportCount= */ 5
    );
    if (firstPlan.valid) {} else {
      return new SixForkCompilation(0, 0);
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
      /* expectedImportCount= */ 5
    );
    if (secondPlan.valid) {} else {
      drop(firstLinkedSource);
      drop(firstArena);
      return new SixForkCompilation(0, 0);
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
      /* expectedImportCount= */ 5
    );
    if (thirdPlan.valid) {} else {
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new SixForkCompilation(0, 0);
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
      /* expectedImportCount= */ 5
    );
    if (fourthPlan.valid) {} else {
      drop(thirdLinkedSource);
      drop(thirdArena);
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new SixForkCompilation(0, 0);
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
    utf8 fourthLinkedSource = freezeUtf8(fourthBytes);

    LinkPlan fifthPlan = planPrivateConstantImport(
      fifthLeafSource,
      fourthLinkedSource,
      /* expectedImportCount= */ 5
    );
    if (fifthPlan.valid) {} else {
      drop(fourthLinkedSource);
      drop(fourthArena);
      drop(thirdLinkedSource);
      drop(thirdArena);
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new SixForkCompilation(0, 0);
    }

    region fifthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeConstantImport(
      fifthLeafSource,
      fourthLinkedSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(fifthBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(fifthArena);
      drop(fourthLinkedSource);
      drop(fourthArena);
      drop(thirdLinkedSource);
      drop(thirdArena);
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new SixForkCompilation(0, 0);
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
    drop(fifthArena);
    drop(fourthLinkedSource);
    drop(fourthArena);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return new SixForkCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles five leaves through one root-visible dependent independent of source order.
  public SixForkCompilation compileSixConstantFork(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixForkCompilation compiled = compileFiveLeafForkIfOrdered(
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      firstSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveLeafForkIfOrdered(
      firstSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      secondSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveLeafForkIfOrdered(
      firstSource,
      secondSource,
      fourthSource,
      fifthSource,
      sixthSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveLeafForkIfOrdered(
      firstSource,
      secondSource,
      thirdSource,
      fifthSource,
      sixthSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveLeafForkIfOrdered(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      sixthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileFiveLeafForkIfOrdered(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
  }
}
