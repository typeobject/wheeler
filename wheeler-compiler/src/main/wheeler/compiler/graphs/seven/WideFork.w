//! Resolves one four-leaf constant fork beside two direct root imports.

module wheeler.compiler.graphs.seven.wide_fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenWideForkGraph {
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_IMPORTS = 4;
  private const long FIVE_IMPORTS = 5;

  /// Carries one wide-fork seven-module compilation.
  public record SevenWideForkCompilation(long length, long codeStart) {}

  private SevenWideForkCompilation compileOrderedWideFork(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 fourthLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedDependentSource = linkSevenPrivateConstant(
      firstLeafSource,
      dependentSource,
      FOUR_IMPORTS,
      firstLeafArena
    );
    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedDependentSource = linkSevenPrivateConstant(
      secondLeafSource,
      firstLinkedDependentSource,
      FOUR_IMPORTS,
      secondLeafArena
    );
    region thirdLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedDependentSource = linkSevenPrivateConstant(
      thirdLeafSource,
      secondLinkedDependentSource,
      FOUR_IMPORTS,
      thirdLeafArena
    );
    region fourthLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedDependentSource = linkSevenPrivateConstant(
      fourthLeafSource,
      thirdLinkedDependentSource,
      FOUR_IMPORTS,
      fourthLeafArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedDependentSource,
      rootSource,
      THREE_IMPORTS,
      rootArena
    );
    region firstDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      THREE_IMPORTS,
      firstDirectArena
    );
    region secondDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      THREE_IMPORTS,
      secondDirectArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(secondDirectArena);
    drop(secondLinkedRootSource);
    drop(firstDirectArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(fourthLeafArena);
    drop(thirdLinkedDependentSource);
    drop(thirdLeafArena);
    drop(secondLinkedDependentSource);
    drop(secondLeafArena);
    drop(firstLinkedDependentSource);
    drop(firstLeafArena);
    return new SevenWideForkCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned four-leaf fork beside two direct root imports.
  public SevenWideForkCompilation compileSevenWideForkAndDirects(
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
    utf8 thirdLeafSource = copySelectedSource(
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
    utf8 fourthLeafSource = copySelectedSource(
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
    utf8 dependentSource = copySelectedSource(
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
    SevenWideForkCompilation compiled = compileOrderedWideFork(
      firstLeafSource,
      secondLeafSource,
      thirdLeafSource,
      fourthLeafSource,
      dependentSource,
      firstDirectSource,
      secondDirectSource,
      rootSource,
      output
    );
    drop(secondDirectSource);
    drop(seventhArena);
    drop(firstDirectSource);
    drop(sixthArena);
    drop(dependentSource);
    drop(fifthArena);
    drop(fourthLeafSource);
    drop(fourthArena);
    drop(thirdLeafSource);
    drop(thirdArena);
    drop(secondLeafSource);
    drop(secondArena);
    drop(firstLeafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenWideForkCompilation compileOrderedFiveLeafFork(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 fourthLeafSource,
    borrow utf8 fifthLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedDependentSource = linkSevenPrivateConstant(
      firstLeafSource,
      dependentSource,
      FIVE_IMPORTS,
      firstLeafArena
    );
    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedDependentSource = linkSevenPrivateConstant(
      secondLeafSource,
      firstLinkedDependentSource,
      FIVE_IMPORTS,
      secondLeafArena
    );
    region thirdLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedDependentSource = linkSevenPrivateConstant(
      thirdLeafSource,
      secondLinkedDependentSource,
      FIVE_IMPORTS,
      thirdLeafArena
    );
    region fourthLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 fourthLinkedDependentSource = linkSevenPrivateConstant(
      fourthLeafSource,
      thirdLinkedDependentSource,
      FIVE_IMPORTS,
      fourthLeafArena
    );
    region fifthLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedDependentSource = linkSevenPrivateConstant(
      fifthLeafSource,
      fourthLinkedDependentSource,
      FIVE_IMPORTS,
      fifthLeafArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedDependentSource,
      rootSource,
      TWO_IMPORTS,
      rootArena
    );
    region directArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenDirectConstant(
      directSource,
      firstLinkedRootSource,
      TWO_IMPORTS,
      directArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(directArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(fifthLeafArena);
    drop(fourthLinkedDependentSource);
    drop(fourthLeafArena);
    drop(thirdLinkedDependentSource);
    drop(thirdLeafArena);
    drop(secondLinkedDependentSource);
    drop(secondLeafArena);
    drop(firstLinkedDependentSource);
    drop(firstLeafArena);
    return new SevenWideForkCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned five-leaf fork beside one direct root import.
  public SevenWideForkCompilation compileSevenFiveLeafForkAndDirect(
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
    utf8 thirdLeafSource = copySelectedSource(
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
    utf8 fourthLeafSource = copySelectedSource(
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
    utf8 fifthLeafSource = copySelectedSource(
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
    utf8 dependentSource = copySelectedSource(
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
    SevenWideForkCompilation compiled = compileOrderedFiveLeafFork(
      firstLeafSource,
      secondLeafSource,
      thirdLeafSource,
      fourthLeafSource,
      fifthLeafSource,
      dependentSource,
      directSource,
      rootSource,
      output
    );
    drop(directSource);
    drop(seventhArena);
    drop(dependentSource);
    drop(sixthArena);
    drop(fifthLeafSource);
    drop(fifthArena);
    drop(fourthLeafSource);
    drop(fourthArena);
    drop(thirdLeafSource);
    drop(thirdArena);
    drop(secondLeafSource);
    drop(secondArena);
    drop(firstLeafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenWideForkCompilation compileOrderedThreeLeafFork(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedDependentSource = linkSevenPrivateConstant(
      firstLeafSource,
      dependentSource,
      THREE_IMPORTS,
      firstLeafArena
    );
    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedDependentSource = linkSevenPrivateConstant(
      secondLeafSource,
      firstLinkedDependentSource,
      THREE_IMPORTS,
      secondLeafArena
    );
    region thirdLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedDependentSource = linkSevenPrivateConstant(
      thirdLeafSource,
      secondLinkedDependentSource,
      THREE_IMPORTS,
      thirdLeafArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedRootSource = linkSevenResolvedConstant(
      linkedDependentSource,
      rootSource,
      FOUR_IMPORTS,
      rootArena
    );
    region firstDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedRootSource = linkSevenDirectConstant(
      firstDirectSource,
      firstLinkedRootSource,
      FOUR_IMPORTS,
      firstDirectArena
    );
    region secondDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 thirdLinkedRootSource = linkSevenDirectConstant(
      secondDirectSource,
      secondLinkedRootSource,
      FOUR_IMPORTS,
      secondDirectArena
    );
    region thirdDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedRootSource = linkSevenDirectConstant(
      thirdDirectSource,
      thirdLinkedRootSource,
      FOUR_IMPORTS,
      thirdDirectArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(thirdDirectArena);
    drop(thirdLinkedRootSource);
    drop(secondDirectArena);
    drop(secondLinkedRootSource);
    drop(firstDirectArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(thirdLeafArena);
    drop(secondLinkedDependentSource);
    drop(secondLeafArena);
    drop(firstLinkedDependentSource);
    drop(firstLeafArena);
    return new SevenWideForkCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned three-leaf fork beside three direct root imports.
  public SevenWideForkCompilation compileSevenThreeLeafForkAndDirects(
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
    utf8 thirdLeafSource = copySelectedSource(
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
    utf8 dependentSource = copySelectedSource(
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
    utf8 firstDirectSource = copySelectedSource(
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
    utf8 secondDirectSource = copySelectedSource(
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
    utf8 thirdDirectSource = copySelectedSource(
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
    SevenWideForkCompilation compiled = compileOrderedThreeLeafFork(
      firstLeafSource,
      secondLeafSource,
      thirdLeafSource,
      dependentSource,
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
    drop(dependentSource);
    drop(fourthArena);
    drop(thirdLeafSource);
    drop(thirdArena);
    drop(secondLeafSource);
    drop(secondArena);
    drop(firstLeafSource);
    drop(firstArena);
    return compiled;
  }
}
