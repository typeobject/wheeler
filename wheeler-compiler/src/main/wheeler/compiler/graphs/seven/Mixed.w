//! Resolves one seven-module chain edge beside five direct root imports.

module wheeler.compiler.graphs.seven.mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.plan_shapes;
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
    utf8 linkedDependentSource = linkSevenPrivateConstant(
      leafSource,
      dependentSource,
      SINGLE_IMPORT,
      dependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedDependentSource,
      rootSource,
      SIX_IMPORTS,
      rootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      SIX_IMPORTS,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      SIX_IMPORTS,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkSevenDirectConstant(
      thirdDirectSource,
      thirdLinkedRootSource,
      SIX_IMPORTS,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fifthLinkedRootSource = linkSevenDirectConstant(
      fourthDirectSource,
      fourthLinkedRootSource,
      SIX_IMPORTS,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenDirectConstant(
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
    utf8 leafSource = copySelectedSource(
      plan.first,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 dependentSource = copySelectedSource(
      plan.second,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 firstDirectSource = copySelectedSource(
      plan.third,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 secondDirectSource = copySelectedSource(
      plan.fourth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 thirdDirectSource = copySelectedSource(
      plan.fifth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 fourthDirectSource = copySelectedSource(
      plan.sixth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 fifthDirectSource = copySelectedSource(
      plan.seventh,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 firstLinkedDependentSource = linkSevenPrivateConstant(
      firstLeafSource,
      dependentSource,
      TWO_IMPORTS,
      firstLeafArena
    );
    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedDependentSource = linkSevenPrivateConstant(
      secondLeafSource,
      firstLinkedDependentSource,
      TWO_IMPORTS,
      secondLeafArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedDependentSource,
      rootSource,
      FIVE_IMPORTS,
      rootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      FIVE_IMPORTS,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      FIVE_IMPORTS,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkSevenDirectConstant(
      thirdDirectSource,
      thirdLinkedRootSource,
      FIVE_IMPORTS,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenDirectConstant(
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
    utf8 firstLeafSource = copySelectedSource(
      plan.first,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 secondLeafSource = copySelectedSource(
      plan.second,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 dependentSource = copySelectedSource(
      plan.third,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 firstDirectSource = copySelectedSource(
      plan.fourth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 secondDirectSource = copySelectedSource(
      plan.fifth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 thirdDirectSource = copySelectedSource(
      plan.sixth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 fourthDirectSource = copySelectedSource(
      plan.seventh,
      GRAPH_SOURCE_COUNT_SEVEN,
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

  private SevenMixedCompilation compileOrderedLongChainAndDirects(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 fourthDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region middleArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedMiddleSource = linkSevenPrivateConstant(
      leafSource,
      middleSource,
      SINGLE_IMPORT,
      middleArena
    );
    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedDependentSource = linkSevenPrivateResolvedConstant(
      linkedMiddleSource,
      dependentSource,
      SINGLE_IMPORT,
      dependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedDependentSource,
      rootSource,
      FIVE_IMPORTS,
      rootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      FIVE_IMPORTS,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      FIVE_IMPORTS,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkSevenDirectConstant(
      thirdDirectSource,
      thirdLinkedRootSource,
      FIVE_IMPORTS,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenDirectConstant(
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
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return new SevenMixedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned three-module chain beside four direct root imports.
  public SevenMixedCompilation compileSevenLongChainAndDirects(
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
    utf8 leafSource = copySelectedSource(
      plan.first,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 middleSource = copySelectedSource(
      plan.second,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 dependentSource = copySelectedSource(
      plan.third,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 firstDirectSource = copySelectedSource(
      plan.fourth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 secondDirectSource = copySelectedSource(
      plan.fifth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 thirdDirectSource = copySelectedSource(
      plan.sixth,
      GRAPH_SOURCE_COUNT_SEVEN,
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
    utf8 fourthDirectSource = copySelectedSource(
      plan.seventh,
      GRAPH_SOURCE_COUNT_SEVEN,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      seventhArena
    );
    SevenMixedCompilation compiled = compileOrderedLongChainAndDirects(
      leafSource,
      middleSource,
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
    drop(middleSource);
    drop(secondArena);
    drop(leafSource);
    drop(firstArena);
    return compiled;
  }

}
