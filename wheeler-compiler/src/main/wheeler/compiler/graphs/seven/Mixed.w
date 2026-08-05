//! Resolves one seven-module chain edge beside five direct root imports.

module wheeler.compiler.graphs.seven.mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenMixedGraph {
  private const long SINGLE_IMPORT = 1;
  private const long SIX_IMPORTS = 6;

  /// Carries one mixed seven-module compilation.
  public record SevenMixedCompilation(long length, long codeStart) {}

  private utf8 linkPrivateConstant(
    borrow utf8 importedSource,
    borrow utf8 dependentSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateConstantImport(
      importedSource,
      dependentSource,
      /* expectedImportCount= */ SINGLE_IMPORT
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
    borrow mut region arena
  ) {
    LinkPlan plan = planResolvedConstantImport(
      importedSource,
      rootSource,
      /* expectedImportCount= */ SIX_IMPORTS
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  private utf8 linkDirectConstant(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planConstantImport(
      importedSource,
      rootSource,
      /* expectedImportCount= */ SIX_IMPORTS
    );
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
    utf8 linkedDependentSource = linkPrivateConstant(leafSource, dependentSource, dependentArena);
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkResolvedConstant(
      linkedDependentSource,
      rootSource,
      rootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkDirectConstant(
      thirdDirectSource,
      thirdLinkedRootSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fifthLinkedRootSource = linkDirectConstant(
      fourthDirectSource,
      fourthLinkedRootSource,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkDirectConstant(
      fifthDirectSource,
      fifthLinkedRootSource,
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
}
