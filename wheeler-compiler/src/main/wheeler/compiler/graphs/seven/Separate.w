//! Resolves separate seven-module constant chains beside direct root imports.

module wheeler.compiler.graphs.seven.separate;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenSeparateGraphs {
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long FOUR_IMPORTS = 4;
  private const long FIVE_IMPORTS = 5;

  /// Carries one compilation of separate seven-module branches.
  public record SevenSeparateCompilation(long length, long codeStart) {}

  private SevenSeparateCompilation compileOrderedPairsAndDirects(
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
    utf8 firstLinkedDependentSource = linkSevenPrivateConstant(
      firstLeafSource,
      firstDependentSource,
      SINGLE_IMPORT,
      firstDependentArena
    );
    region secondDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedDependentSource = linkSevenPrivateConstant(
      secondLeafSource,
      secondDependentSource,
      SINGLE_IMPORT,
      secondDependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      firstLinkedDependentSource,
      rootSource,
      FIVE_IMPORTS,
      rootArena
    );
    region secondRootArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedRootSource = linkSevenResolvedConstant(
      secondLinkedDependentSource,
      firstLinkedRootSource,
      FIVE_IMPORTS,
      secondRootArena
    );
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      secondLinkedRootSource,
      FIVE_IMPORTS,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      thirdLinkedRootSource,
      FIVE_IMPORTS,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenDirectConstant(
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
    return new SevenSeparateCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles two planned constant chains beside three direct root imports.
  public SevenSeparateCompilation compileSevenPairsAndDirects(
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
    SevenSeparateCompilation compiled = compileOrderedPairsAndDirects(
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

  private SevenSeparateCompilation compileOrderedThreeChainsAndDirect(
    borrow utf8 firstLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondLeafSource,
    borrow utf8 secondDependentSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 thirdDependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 firstLinkedDependentSource = linkSevenPrivateConstant(
      firstLeafSource,
      firstDependentSource,
      SINGLE_IMPORT,
      firstDependentArena
    );
    region secondDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedDependentSource = linkSevenPrivateConstant(
      secondLeafSource,
      secondDependentSource,
      SINGLE_IMPORT,
      secondDependentArena
    );
    region thirdDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 thirdLinkedDependentSource = linkSevenPrivateConstant(
      thirdLeafSource,
      thirdDependentSource,
      SINGLE_IMPORT,
      thirdDependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      firstLinkedDependentSource,
      rootSource,
      FOUR_IMPORTS,
      rootArena
    );
    region secondRootArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedRootSource = linkSevenResolvedConstant(
      secondLinkedDependentSource,
      firstLinkedRootSource,
      FOUR_IMPORTS,
      secondRootArena
    );
    region thirdRootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedRootSource = linkSevenResolvedConstant(
      thirdLinkedDependentSource,
      secondLinkedRootSource,
      FOUR_IMPORTS,
      thirdRootArena
    );
    region directArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenDirectConstant(
      directSource,
      thirdLinkedRootSource,
      FOUR_IMPORTS,
      directArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(directArena);
    drop(thirdLinkedRootSource);
    drop(thirdRootArena);
    drop(secondLinkedRootSource);
    drop(secondRootArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(thirdLinkedDependentSource);
    drop(thirdDependentArena);
    drop(secondLinkedDependentSource);
    drop(secondDependentArena);
    drop(firstLinkedDependentSource);
    drop(firstDependentArena);
    return new SevenSeparateCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles three planned constant chains beside one direct root import.
  public SevenSeparateCompilation compileSevenThreeChainsAndDirect(
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
    utf8 thirdLeafSource = copySelectedSevenSource(
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
    utf8 thirdDependentSource = copySelectedSevenSource(
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
    utf8 directSource = copySelectedSevenSource(
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
    SevenSeparateCompilation compiled = compileOrderedThreeChainsAndDirect(
      firstLeafSource,
      firstDependentSource,
      secondLeafSource,
      secondDependentSource,
      thirdLeafSource,
      thirdDependentSource,
      directSource,
      rootSource,
      output
    );
    drop(directSource);
    drop(seventhArena);
    drop(thirdDependentSource);
    drop(sixthArena);
    drop(thirdLeafSource);
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
    utf8 longLeafSource = copySelectedSevenSource(
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
    utf8 middleSource = copySelectedSevenSource(
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
    utf8 longDependentSource = copySelectedSevenSource(
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
    utf8 shortLeafSource = copySelectedSevenSource(
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
    utf8 shortDependentSource = copySelectedSevenSource(
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
    utf8 firstDirectSource = copySelectedSevenSource(
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
    utf8 secondDirectSource = copySelectedSevenSource(
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
    utf8 firstForkLeafSource = copySelectedSevenSource(
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
    utf8 secondForkLeafSource = copySelectedSevenSource(
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
    utf8 forkDependentSource = copySelectedSevenSource(
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
    utf8 chainLeafSource = copySelectedSevenSource(
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
    utf8 chainDependentSource = copySelectedSevenSource(
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
    utf8 firstDirectSource = copySelectedSevenSource(
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
    utf8 secondDirectSource = copySelectedSevenSource(
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
}
