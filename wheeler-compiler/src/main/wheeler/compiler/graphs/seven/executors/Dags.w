//! Resolves admitted seven-module constant DAGs.

module wheeler.compiler.graphs.seven.executors.dags;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenDagGraphs {
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long FOUR_IMPORTS = 4;

  /// Carries private seven-module DAG compilation bounds.
  public record SevenDagCompilation(long length, long codeStart) {}

  private SevenDagCompilation compileOrderedSharedDiamond(
    borrow utf8 sharedSource,
    borrow utf8 firstMiddleSource,
    borrow utf8 secondMiddleSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedFirstMiddleSource = linkSevenPrivateConstant(
      sharedSource,
      firstMiddleSource,
      SINGLE_IMPORT,
      firstMiddleArena
    );
    region secondMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSecondMiddleSource = linkSevenPrivateConstant(
      sharedSource,
      secondMiddleSource,
      SINGLE_IMPORT,
      secondMiddleArena
    );
    region firstDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 firstLinkedDependentSource = linkSevenPrivateResolvedConstant(
      linkedFirstMiddleSource,
      dependentSource,
      TWO_IMPORTS,
      firstDependentArena
    );
    region secondDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedDependentSource = linkSevenSharedResolvedConstant(
      linkedSecondMiddleSource,
      firstLinkedDependentSource,
      TWO_IMPORTS,
      secondDependentArena
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
    drop(secondDependentArena);
    drop(firstLinkedDependentSource);
    drop(firstDependentArena);
    drop(linkedSecondMiddleSource);
    drop(secondMiddleArena);
    drop(linkedFirstMiddleSource);
    drop(firstMiddleArena);
    return new SevenDagCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned shared diamond beside three direct root imports.
  public SevenDagCompilation compileSevenSharedDiamondAndDirects(
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
    utf8 sharedSource = copySelectedSevenSource(
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
    utf8 firstMiddleSource = copySelectedSevenSource(
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
    utf8 secondMiddleSource = copySelectedSevenSource(
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
    utf8 dependentSource = copySelectedSevenSource(
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
    SevenDagCompilation compiled = compileOrderedSharedDiamond(
      sharedSource,
      firstMiddleSource,
      secondMiddleSource,
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
    drop(secondMiddleSource);
    drop(thirdArena);
    drop(firstMiddleSource);
    drop(secondArena);
    drop(sharedSource);
    drop(firstArena);
    return compiled;
  }
}
