//! Resolves serial seven-module constant DAGs.

module wheeler.compiler.graphs.seven.executors.serial_dags;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenSerialDagGraphs {
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;

  /// Carries private serial seven-module DAG compilation bounds.
  public record SevenSerialDagCompilation(long length, long codeStart) {}

  private SevenSerialDagCompilation compileOrderedSerialDiamonds(
    borrow utf8 firstSharedSource,
    borrow utf8 firstMiddleSource,
    borrow utf8 secondMiddleSource,
    borrow utf8 secondSharedSource,
    borrow utf8 thirdMiddleSource,
    borrow utf8 fourthMiddleSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedFirstMiddleSource = linkSevenPrivateConstant(
      firstSharedSource,
      firstMiddleSource,
      SINGLE_IMPORT,
      firstMiddleArena
    );
    region secondMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSecondMiddleSource = linkSevenPrivateConstant(
      firstSharedSource,
      secondMiddleSource,
      SINGLE_IMPORT,
      secondMiddleArena
    );
    region firstSharedJoinArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 firstLinkedSharedSource = linkSevenPrivateResolvedConstant(
      linkedFirstMiddleSource,
      secondSharedSource,
      TWO_IMPORTS,
      firstSharedJoinArena
    );
    region secondSharedJoinArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSecondSharedSource = linkSevenSharedResolvedConstant(
      linkedSecondMiddleSource,
      firstLinkedSharedSource,
      TWO_IMPORTS,
      secondSharedJoinArena
    );
    region thirdMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedThirdMiddleSource = linkSevenPrivateResolvedConstant(
      linkedSecondSharedSource,
      thirdMiddleSource,
      SINGLE_IMPORT,
      thirdMiddleArena
    );
    region fourthMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedFourthMiddleSource = linkSevenPrivateResolvedConstant(
      linkedSecondSharedSource,
      fourthMiddleSource,
      SINGLE_IMPORT,
      fourthMiddleArena
    );
    region firstDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 firstLinkedDependentSource = linkSevenPrivateResolvedConstant(
      linkedThirdMiddleSource,
      dependentSource,
      TWO_IMPORTS,
      firstDependentArena
    );
    region secondDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedDependentSource = linkSevenSharedResolvedConstant(
      linkedFourthMiddleSource,
      firstLinkedDependentSource,
      TWO_IMPORTS,
      secondDependentArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkSevenResolvedConstant(
      linkedDependentSource,
      rootSource,
      SINGLE_IMPORT,
      rootArena
    );
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(secondDependentArena);
    drop(firstLinkedDependentSource);
    drop(firstDependentArena);
    drop(linkedFourthMiddleSource);
    drop(fourthMiddleArena);
    drop(linkedThirdMiddleSource);
    drop(thirdMiddleArena);
    drop(linkedSecondSharedSource);
    drop(secondSharedJoinArena);
    drop(firstLinkedSharedSource);
    drop(firstSharedJoinArena);
    drop(linkedSecondMiddleSource);
    drop(secondMiddleArena);
    drop(linkedFirstMiddleSource);
    drop(firstMiddleArena);
    return new SevenSerialDagCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles two planned serial diamonds spanning all seven imported modules.
  public SevenSerialDagCompilation compileSevenSerialDiamonds(
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
    utf8 firstSharedSource = copySelectedSource(
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
    utf8 secondMiddleSource = copySelectedSource(
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
    utf8 secondSharedSource = copySelectedSource(
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
    utf8 thirdMiddleSource = copySelectedSource(
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
    utf8 fourthMiddleSource = copySelectedSource(
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
    utf8 dependentSource = copySelectedSource(
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
    SevenSerialDagCompilation compiled = compileOrderedSerialDiamonds(
      firstSharedSource,
      firstMiddleSource,
      secondMiddleSource,
      secondSharedSource,
      thirdMiddleSource,
      fourthMiddleSource,
      dependentSource,
      rootSource,
      output
    );
    drop(dependentSource);
    drop(seventhArena);
    drop(fourthMiddleSource);
    drop(sixthArena);
    drop(thirdMiddleSource);
    drop(fifthArena);
    drop(secondSharedSource);
    drop(fourthArena);
    drop(secondMiddleSource);
    drop(thirdArena);
    drop(firstMiddleSource);
    drop(secondArena);
    drop(firstSharedSource);
    drop(firstArena);
    return compiled;
  }
}
