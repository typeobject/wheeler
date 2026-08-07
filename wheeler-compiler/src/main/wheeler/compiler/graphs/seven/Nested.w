//! Resolves one nested two-leaf constant fork beside three direct root imports.

module wheeler.compiler.graphs.seven.nested;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenNestedGraph {
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_IMPORTS = 4;

  /// Carries one nested seven-module compilation.
  public record SevenNestedCompilation(long length, long codeStart) {}

  private SevenNestedCompilation compileOrderedNestedFork(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedMiddleSource = linkSevenPrivateConstant(
      firstLeafSource,
      middleSource,
      TWO_IMPORTS,
      firstLeafArena
    );
    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedMiddleSource = linkSevenPrivateConstant(
      secondLeafSource,
      firstLinkedMiddleSource,
      TWO_IMPORTS,
      secondLeafArena
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
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(secondLeafArena);
    drop(firstLinkedMiddleSource);
    drop(firstLeafArena);
    return new SevenNestedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned nested two-leaf fork beside three direct root imports.
  public SevenNestedCompilation compileSevenNestedForkAndDirects(
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
    utf8 middleSource = copySelectedSource(
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
    SevenNestedCompilation compiled = compileOrderedNestedFork(
      firstLeafSource,
      secondLeafSource,
      middleSource,
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
    drop(middleSource);
    drop(thirdArena);
    drop(secondLeafSource);
    drop(secondArena);
    drop(firstLeafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenNestedCompilation compileOrderedNestedThreeFork(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedMiddleSource = linkSevenPrivateConstant(
      firstLeafSource,
      middleSource,
      THREE_IMPORTS,
      firstLeafArena
    );
    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedMiddleSource = linkSevenPrivateConstant(
      secondLeafSource,
      firstLinkedMiddleSource,
      THREE_IMPORTS,
      secondLeafArena
    );
    region thirdLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedMiddleSource = linkSevenPrivateConstant(
      thirdLeafSource,
      secondLinkedMiddleSource,
      THREE_IMPORTS,
      thirdLeafArena
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
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(thirdLeafArena);
    drop(secondLinkedMiddleSource);
    drop(secondLeafArena);
    drop(firstLinkedMiddleSource);
    drop(firstLeafArena);
    return new SevenNestedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned nested three-leaf fork beside two direct root imports.
  public SevenNestedCompilation compileSevenNestedThreeForkAndDirects(
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
    utf8 middleSource = copySelectedSource(
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
    SevenNestedCompilation compiled = compileOrderedNestedThreeFork(
      firstLeafSource,
      secondLeafSource,
      thirdLeafSource,
      middleSource,
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
    drop(middleSource);
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
