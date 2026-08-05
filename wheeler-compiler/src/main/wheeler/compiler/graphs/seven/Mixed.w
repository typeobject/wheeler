//! Resolves one seven-module chain edge beside five direct root imports.

module wheeler.compiler.graphs.seven.mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenMixedGraph {
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long FIVE_IMPORTS = 5;
  private const long SIX_IMPORTS = 6;

  /// Carries one mixed seven-module compilation.
  public record SevenMixedCompilation(long length, long codeStart) {}

  private utf8 linkPrivateConstant(
    borrow utf8 importedSource,
    borrow utf8 dependentSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateConstantImport(
      importedSource,
      dependentSource,
      expectedImportCount
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, dependentSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  private utf8 linkResolvedConstant(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planResolvedConstantImport(importedSource, rootSource, expectedImportCount);
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  private utf8 linkDirectConstant(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planConstantImport(importedSource, rootSource, expectedImportCount);
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  private SevenMixedCompilation compileOrderedChainAndDirects(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 fourthDirectSource,
    borrow utf8 fifthDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedDependentSource = linkPrivateConstant(
      leafSource,
      dependentSource,
      SINGLE_IMPORT,
      dependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkResolvedConstant(
      linkedDependentSource,
      rootSource,
      SIX_IMPORTS,
      rootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      SIX_IMPORTS,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      SIX_IMPORTS,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkDirectConstant(
      thirdDirectSource,
      thirdLinkedRootSource,
      SIX_IMPORTS,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fifthLinkedRootSource = linkDirectConstant(
      fourthDirectSource,
      fourthLinkedRootSource,
      SIX_IMPORTS,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkDirectConstant(
      fifthDirectSource,
      fifthLinkedRootSource,
      SIX_IMPORTS,
      fifthArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(fifthArena);
    drop(fifthLinkedRootSource);
    drop(fourthArena);
    drop(fourthLinkedRootSource);
    drop(thirdArena);
    drop(thirdLinkedRootSource);
    drop(secondArena);
    drop(secondLinkedRootSource);
    drop(firstArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return new SevenMixedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned chain edge beside five direct root imports.
  public SevenMixedCompilation compileSevenChainAndDirects(
    SevenGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 leafSource = copySelectedSevenSource(
      plan.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 dependentSource = copySelectedSevenSource(
      plan.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstDirectSource = copySelectedSevenSource(
      plan.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondDirectSource = copySelectedSevenSource(
      plan.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdDirectSource = copySelectedSevenSource(
      plan.fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fifthArena
    );
    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthDirectSource = copySelectedSevenSource(
      plan.sixth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      sixthArena
    );
    region seventhArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fifthDirectSource = copySelectedSevenSource(
      plan.seventh,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      seventhArena
    );
    SevenMixedCompilation compiled = compileOrderedChainAndDirects(
      leafSource,
      dependentSource,
      firstDirectSource,
      secondDirectSource,
      thirdDirectSource,
      fourthDirectSource,
      fifthDirectSource,
      rootSource,
      output
    );
    drop(fifthDirectSource);
    drop(seventhArena);
    drop(fourthDirectSource);
    drop(sixthArena);
    drop(thirdDirectSource);
    drop(fifthArena);
    drop(secondDirectSource);
    drop(fourthArena);
    drop(firstDirectSource);
    drop(thirdArena);
    drop(dependentSource);
    drop(secondArena);
    drop(leafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenMixedCompilation compileOrderedForkAndDirects(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 fourthDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedDependentSource = linkPrivateConstant(
      firstLeafSource,
      dependentSource,
      TWO_IMPORTS,
      firstLeafArena
    );
    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedDependentSource = linkPrivateConstant(
      secondLeafSource,
      firstLinkedDependentSource,
      TWO_IMPORTS,
      secondLeafArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkResolvedConstant(
      linkedDependentSource,
      rootSource,
      FIVE_IMPORTS,
      rootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      FIVE_IMPORTS,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      FIVE_IMPORTS,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkDirectConstant(
      thirdDirectSource,
      thirdLinkedRootSource,
      FIVE_IMPORTS,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkDirectConstant(
      fourthDirectSource,
      fourthLinkedRootSource,
      FIVE_IMPORTS,
      fourthArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(fourthArena);
    drop(fourthLinkedRootSource);
    drop(thirdArena);
    drop(thirdLinkedRootSource);
    drop(secondArena);
    drop(secondLinkedRootSource);
    drop(firstArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(secondLeafArena);
    drop(firstLinkedDependentSource);
    drop(firstLeafArena);
    return new SevenMixedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned two-leaf fork beside four direct root imports.
  public SevenMixedCompilation compileSevenForkAndDirects(
    SevenGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLeafSource = copySelectedSevenSource(
      plan.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLeafSource = copySelectedSevenSource(
      plan.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 dependentSource = copySelectedSevenSource(
      plan.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstDirectSource = copySelectedSevenSource(
      plan.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondDirectSource = copySelectedSevenSource(
      plan.fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fifthArena
    );
    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdDirectSource = copySelectedSevenSource(
      plan.sixth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      sixthArena
    );
    region seventhArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthDirectSource = copySelectedSevenSource(
      plan.seventh,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      seventhArena
    );
    SevenMixedCompilation compiled = compileOrderedForkAndDirects(
      firstLeafSource,
      secondLeafSource,
      dependentSource,
      firstDirectSource,
      secondDirectSource,
      thirdDirectSource,
      fourthDirectSource,
      rootSource,
      output
    );
    drop(fourthDirectSource);
    drop(seventhArena);
    drop(thirdDirectSource);
    drop(sixthArena);
    drop(secondDirectSource);
    drop(fifthArena);
    drop(firstDirectSource);
    drop(fourthArena);
    drop(dependentSource);
    drop(thirdArena);
    drop(secondLeafSource);
    drop(secondArena);
    drop(firstLeafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenMixedCompilation compileOrderedPairsAndDirects(
    borrow utf8 firstLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondLeafSource,
    borrow utf8 secondDependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 firstLinkedDependentSource = linkPrivateConstant(
      firstLeafSource,
      firstDependentSource,
      SINGLE_IMPORT,
      firstDependentArena
    );
    region secondDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedDependentSource = linkPrivateConstant(
      secondLeafSource,
      secondDependentSource,
      SINGLE_IMPORT,
      secondDependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkResolvedConstant(
      firstLinkedDependentSource,
      rootSource,
      FIVE_IMPORTS,
      rootArena
    );
    region secondRootArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedRootSource = linkResolvedConstant(
      secondLinkedDependentSource,
      firstLinkedRootSource,
      FIVE_IMPORTS,
      secondRootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkDirectConstant(
      firstDirectSource,
      secondLinkedRootSource,
      FIVE_IMPORTS,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkDirectConstant(
      secondDirectSource,
      thirdLinkedRootSource,
      FIVE_IMPORTS,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkDirectConstant(
      thirdDirectSource,
      fourthLinkedRootSource,
      FIVE_IMPORTS,
      thirdArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(thirdArena);
    drop(fourthLinkedRootSource);
    drop(secondArena);
    drop(thirdLinkedRootSource);
    drop(firstArena);
    drop(secondLinkedRootSource);
    drop(secondRootArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(secondLinkedDependentSource);
    drop(secondDependentArena);
    drop(firstLinkedDependentSource);
    drop(firstDependentArena);
    return new SevenMixedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles two planned constant chains beside three direct root imports.
  public SevenMixedCompilation compileSevenPairsAndDirects(
    SevenGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLeafSource = copySelectedSevenSource(
      plan.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstDependentSource = copySelectedSevenSource(
      plan.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLeafSource = copySelectedSevenSource(
      plan.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondDependentSource = copySelectedSevenSource(
      plan.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstDirectSource = copySelectedSevenSource(
      plan.fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fifthArena
    );
    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondDirectSource = copySelectedSevenSource(
      plan.sixth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      sixthArena
    );
    region seventhArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdDirectSource = copySelectedSevenSource(
      plan.seventh,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      seventhArena
    );
    SevenMixedCompilation compiled = compileOrderedPairsAndDirects(
      firstLeafSource,
      firstDependentSource,
      secondLeafSource,
      secondDependentSource,
      firstDirectSource,
      secondDirectSource,
      thirdDirectSource,
      rootSource,
      output
    );
    drop(thirdDirectSource);
    drop(seventhArena);
    drop(secondDirectSource);
    drop(sixthArena);
    drop(firstDirectSource);
    drop(fifthArena);
    drop(secondDependentSource);
    drop(fourthArena);
    drop(secondLeafSource);
    drop(thirdArena);
    drop(firstDependentSource);
    drop(secondArena);
    drop(firstLeafSource);
    drop(firstArena);
    return compiled;
  }
}
