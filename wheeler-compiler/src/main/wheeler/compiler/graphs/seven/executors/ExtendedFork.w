//! Resolves extended seven-module constant forks.

module wheeler.compiler.graphs.seven.executors.extended_fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.linking;
import wheeler.compiler.graphs.seven.nested;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenExtendedForkGraphs {
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;

  private SevenNestedCompilation compileOrderedExtendedFork(
    borrow utf8 chainLeafSource,
    borrow utf8 middleSource,
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region chainLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedMiddleSource = linkSevenPrivateConstant(
      chainLeafSource,
      middleSource,
      SINGLE_IMPORT,
      chainLeafArena
    );
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
    region middleArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedDependentSource = linkSevenPrivateResolvedConstant(
      linkedMiddleSource,
      secondLinkedDependentSource,
      THREE_IMPORTS,
      middleArena
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
    drop(middleArena);
    drop(secondLinkedDependentSource);
    drop(secondLeafArena);
    drop(firstLinkedDependentSource);
    drop(firstLeafArena);
    drop(linkedMiddleSource);
    drop(chainLeafArena);
    return new SevenNestedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned extended three-branch fork beside two direct imports.
  public SevenNestedCompilation compileSevenExtendedForkAndDirects(
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
    utf8 chainLeafSource = copySelectedSevenSource(
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
    utf8 firstLeafSource = copySelectedSevenSource(
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
    utf8 secondLeafSource = copySelectedSevenSource(
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
    utf8 dependentSource = copySelectedSevenSource(
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
    SevenNestedCompilation compiled = compileOrderedExtendedFork(
      chainLeafSource,
      middleSource,
      firstLeafSource,
      secondLeafSource,
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
    drop(secondLeafSource);
    drop(fourthArena);
    drop(firstLeafSource);
    drop(thirdArena);
    drop(middleSource);
    drop(secondArena);
    drop(chainLeafSource);
    drop(firstArena);
    return compiled;
  }

  private SevenNestedCompilation compileOrderedLongBranchFork(
    borrow utf8 chainLeafSource,
    borrow utf8 firstMiddleSource,
    borrow utf8 secondMiddleSource,
    borrow utf8 sideLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region chainLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedFirstMiddleSource = linkSevenPrivateConstant(
      chainLeafSource,
      firstMiddleSource,
      SINGLE_IMPORT,
      chainLeafArena
    );
    region firstMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSecondMiddleSource = linkSevenPrivateResolvedConstant(
      linkedFirstMiddleSource,
      secondMiddleSource,
      SINGLE_IMPORT,
      firstMiddleArena
    );
    region sideLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedDependentSource = linkSevenPrivateConstant(
      sideLeafSource,
      dependentSource,
      TWO_IMPORTS,
      sideLeafArena
    );
    region secondMiddleArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedDependentSource = linkSevenPrivateResolvedConstant(
      linkedSecondMiddleSource,
      firstLinkedDependentSource,
      TWO_IMPORTS,
      secondMiddleArena
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
    drop(secondMiddleArena);
    drop(firstLinkedDependentSource);
    drop(sideLeafArena);
    drop(linkedSecondMiddleSource);
    drop(firstMiddleArena);
    drop(linkedFirstMiddleSource);
    drop(chainLeafArena);
    return new SevenNestedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one planned long branch joined with one leaf and two direct imports.
  public SevenNestedCompilation compileSevenLongBranchForkAndDirects(
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
    utf8 chainLeafSource = copySelectedSevenSource(
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
    utf8 sideLeafSource = copySelectedSevenSource(
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
    utf8 dependentSource = copySelectedSevenSource(
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
    SevenNestedCompilation compiled = compileOrderedLongBranchFork(
      chainLeafSource,
      firstMiddleSource,
      secondMiddleSource,
      sideLeafSource,
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
    drop(sideLeafSource);
    drop(fourthArena);
    drop(secondMiddleSource);
    drop(thirdArena);
    drop(firstMiddleSource);
    drop(secondArena);
    drop(chainLeafSource);
    drop(firstArena);
    return compiled;
  }
}
