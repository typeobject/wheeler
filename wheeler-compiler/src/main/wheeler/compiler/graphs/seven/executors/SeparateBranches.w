//! Resolves uneven and forked seven-module branches beside direct root imports.

module wheeler.compiler.graphs.seven.executors.separate_branches;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.seven.separate;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenSeparateBranchGraphs {
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_IMPORTS = 4;

  private SevenSeparateCompilation compileOrderedLongShortChains(
    borrow utf8 longLeafSource,
    borrow utf8 middleSource,
    borrow utf8 longDependentSource,
    borrow utf8 shortLeafSource,
    borrow utf8 shortDependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region middleArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedMiddleSource = linkSevenPrivateConstant(
      longLeafSource,
      middleSource,
      SINGLE_IMPORT,
      middleArena
    );
    region longArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedLongDependentSource = linkSevenPrivateResolvedConstant(
      linkedMiddleSource,
      longDependentSource,
      SINGLE_IMPORT,
      longArena
    );
    region shortArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedShortDependentSource = linkSevenPrivateConstant(
      shortLeafSource,
      shortDependentSource,
      SINGLE_IMPORT,
      shortArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedLongDependentSource,
      rootSource,
      FOUR_IMPORTS,
      rootArena
    );
    region shortRootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkSevenResolvedConstant(
      linkedShortDependentSource,
      firstLinkedRootSource,
      FOUR_IMPORTS,
      shortRootArena
    );
    region firstDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 thirdLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      secondLinkedRootSource,
      FOUR_IMPORTS,
      firstDirectArena
    );
    region secondDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      thirdLinkedRootSource,
      FOUR_IMPORTS,
      secondDirectArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(secondDirectArena);
    drop(thirdLinkedRootSource);
    drop(firstDirectArena);
    drop(secondLinkedRootSource);
    drop(shortRootArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedShortDependentSource);
    drop(shortArena);
    drop(linkedLongDependentSource);
    drop(longArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return new SevenSeparateCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles planned long and short chains beside two direct root imports.
  public SevenSeparateCompilation compileSevenLongShortChainsAndDirects(
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
    utf8 longLeafSource = copySelectedSource(
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
    utf8 longDependentSource = copySelectedSource(
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
    utf8 shortLeafSource = copySelectedSource(
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
    utf8 shortDependentSource = copySelectedSource(
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
    utf8 firstDirectSource = copySelectedSource(
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
    utf8 secondDirectSource = copySelectedSource(
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
    SevenSeparateCompilation compiled = compileOrderedLongShortChains(
      longLeafSource,
      middleSource,
      longDependentSource,
      shortLeafSource,
      shortDependentSource,
      firstDirectSource,
      secondDirectSource,
      rootSource,
      output
    );
    drop(secondDirectSource);
    drop(seventhArena);
    drop(firstDirectSource);
    drop(sixthArena);
    drop(shortDependentSource);
    drop(fifthArena);
    drop(shortLeafSource);
    drop(fourthArena);
    drop(longDependentSource);
    drop(thirdArena);
    drop(middleSource);
    drop(secondArena);
    drop(longLeafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenSeparateCompilation compileOrderedForkChain(
    borrow utf8 firstForkLeafSource,
    borrow utf8 secondForkLeafSource,
    borrow utf8 forkDependentSource,
    borrow utf8 chainLeafSource,
    borrow utf8 chainDependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstForkArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedForkSource = linkSevenPrivateConstant(
      firstForkLeafSource,
      forkDependentSource,
      TWO_IMPORTS,
      firstForkArena
    );
    region secondForkArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedForkSource = linkSevenPrivateConstant(
      secondForkLeafSource,
      firstLinkedForkSource,
      TWO_IMPORTS,
      secondForkArena
    );
    region chainArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedChainSource = linkSevenPrivateConstant(
      chainLeafSource,
      chainDependentSource,
      SINGLE_IMPORT,
      chainArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedForkSource,
      rootSource,
      FOUR_IMPORTS,
      rootArena
    );
    region chainRootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedRootSource = linkSevenResolvedConstant(
      linkedChainSource,
      firstLinkedRootSource,
      FOUR_IMPORTS,
      chainRootArena
    );
    region firstDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 thirdLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      secondLinkedRootSource,
      FOUR_IMPORTS,
      firstDirectArena
    );
    region secondDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      thirdLinkedRootSource,
      FOUR_IMPORTS,
      secondDirectArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(secondDirectArena);
    drop(thirdLinkedRootSource);
    drop(firstDirectArena);
    drop(secondLinkedRootSource);
    drop(chainRootArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedChainSource);
    drop(chainArena);
    drop(linkedForkSource);
    drop(secondForkArena);
    drop(firstLinkedForkSource);
    drop(firstForkArena);
    return new SevenSeparateCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one fork and one chain beside two direct root imports.
  public SevenSeparateCompilation compileSevenForkChainAndDirects(
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
    utf8 firstForkLeafSource = copySelectedSource(
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
    utf8 secondForkLeafSource = copySelectedSource(
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
    utf8 forkDependentSource = copySelectedSource(
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
    utf8 chainLeafSource = copySelectedSource(
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
    utf8 chainDependentSource = copySelectedSource(
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
    utf8 firstDirectSource = copySelectedSource(
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
    utf8 secondDirectSource = copySelectedSource(
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
    SevenSeparateCompilation compiled = compileOrderedForkChain(
      firstForkLeafSource,
      secondForkLeafSource,
      forkDependentSource,
      chainLeafSource,
      chainDependentSource,
      firstDirectSource,
      secondDirectSource,
      rootSource,
      output
    );
    drop(secondDirectSource);
    drop(seventhArena);
    drop(firstDirectSource);
    drop(sixthArena);
    drop(chainDependentSource);
    drop(fifthArena);
    drop(chainLeafSource);
    drop(fourthArena);
    drop(forkDependentSource);
    drop(thirdArena);
    drop(secondForkLeafSource);
    drop(secondArena);
    drop(firstForkLeafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenSeparateCompilation compileOrderedTwoLongChains(
    borrow utf8 firstLeafSource,
    borrow utf8 firstMiddleSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondLeafSource,
    borrow utf8 secondMiddleSource,
    borrow utf8 secondDependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedFirstMiddleSource = linkSevenPrivateConstant(
      firstLeafSource,
      firstMiddleSource,
      SINGLE_IMPORT,
      firstMiddleArena
    );
    region firstDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedFirstDependentSource = linkSevenPrivateResolvedConstant(
      linkedFirstMiddleSource,
      firstDependentSource,
      SINGLE_IMPORT,
      firstDependentArena
    );
    region secondMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSecondMiddleSource = linkSevenPrivateConstant(
      secondLeafSource,
      secondMiddleSource,
      SINGLE_IMPORT,
      secondMiddleArena
    );
    region secondDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSecondDependentSource = linkSevenPrivateResolvedConstant(
      linkedSecondMiddleSource,
      secondDependentSource,
      SINGLE_IMPORT,
      secondDependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedFirstDependentSource,
      rootSource,
      THREE_IMPORTS,
      rootArena
    );
    region secondRootArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedRootSource = linkSevenResolvedConstant(
      linkedSecondDependentSource,
      firstLinkedRootSource,
      THREE_IMPORTS,
      secondRootArena
    );
    region directArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenDirectConstant(
      directSource,
      secondLinkedRootSource,
      THREE_IMPORTS,
      directArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(directArena);
    drop(secondLinkedRootSource);
    drop(secondRootArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedSecondDependentSource);
    drop(secondDependentArena);
    drop(linkedSecondMiddleSource);
    drop(secondMiddleArena);
    drop(linkedFirstDependentSource);
    drop(firstDependentArena);
    drop(linkedFirstMiddleSource);
    drop(firstMiddleArena);
    return new SevenSeparateCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles two planned three-module chains beside one direct root import.
  public SevenSeparateCompilation compileSevenTwoLongChainsAndDirect(
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
    utf8 firstMiddleSource = copySelectedSource(
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
    utf8 firstDependentSource = copySelectedSource(
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
    utf8 secondLeafSource = copySelectedSource(
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
    utf8 secondMiddleSource = copySelectedSource(
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
    utf8 secondDependentSource = copySelectedSource(
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
    utf8 directSource = copySelectedSource(
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
    SevenSeparateCompilation compiled = compileOrderedTwoLongChains(
      firstLeafSource,
      firstMiddleSource,
      firstDependentSource,
      secondLeafSource,
      secondMiddleSource,
      secondDependentSource,
      directSource,
      rootSource,
      output
    );
    drop(directSource);
    drop(seventhArena);
    drop(secondDependentSource);
    drop(sixthArena);
    drop(secondMiddleSource);
    drop(fifthArena);
    drop(secondLeafSource);
    drop(fourthArena);
    drop(firstDependentSource);
    drop(thirdArena);
    drop(firstMiddleSource);
    drop(secondArena);
    drop(firstLeafSource);
    drop(firstArena);
    return compiled;
  }
}
