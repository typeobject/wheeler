//! Resolves six-module forests whose root owns three separate branches.

module wheeler.compiler.graphs.six.separate;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class SixSeparateGraph {
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;

  /// Carries one separate-branch six-module compilation.
  public record SixSeparateCompilation(long length, long codeStart) {}

  /// Compiles one two-leaf fork beside one chain and one direct import.
  public SixSeparateCompilation compileSixForkChainAndDirectIfOrdered(
    borrow utf8 firstForkLeafSource,
    borrow utf8 secondForkLeafSource,
    borrow utf8 forkDependentSource,
    borrow utf8 chainLeafSource,
    borrow utf8 chainDependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstForkPlan = planPrivateConstantImport(
      firstForkLeafSource,
      forkDependentSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    assert(firstForkPlan.valid);
    region firstForkArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstForkBytes = allocateBytes(firstForkArena, firstForkPlan.linkedLength);
    long firstForkWritten = writeConstantImport(
      firstForkLeafSource,
      forkDependentSource,
      firstForkPlan,
      firstForkBytes
    );
    assert(firstForkWritten == firstForkPlan.linkedLength);
    utf8 firstLinkedForkSource = freezeUtf8(firstForkBytes);

    LinkPlan secondForkPlan = planPrivateConstantImport(
      secondForkLeafSource,
      firstLinkedForkSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    assert(secondForkPlan.valid);
    region secondForkArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondForkBytes = allocateBytes(secondForkArena, secondForkPlan.linkedLength);
    long secondForkWritten = writeConstantImport(
      secondForkLeafSource,
      firstLinkedForkSource,
      secondForkPlan,
      secondForkBytes
    );
    assert(secondForkWritten == secondForkPlan.linkedLength);
    utf8 linkedForkSource = freezeUtf8(secondForkBytes);

    LinkPlan chainPlan = planPrivateConstantImport(
      chainLeafSource,
      chainDependentSource,
      /* expectedImportCount= */ 1
    );
    assert(chainPlan.valid);
    region chainArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes chainBytes = allocateBytes(chainArena, chainPlan.linkedLength);
    long chainWritten = writeConstantImport(
      chainLeafSource,
      chainDependentSource,
      chainPlan,
      chainBytes
    );
    assert(chainWritten == chainPlan.linkedLength);
    utf8 linkedChainSource = freezeUtf8(chainBytes);

    LinkPlan forkRootPlan = planResolvedConstantImport(
      linkedForkSource,
      rootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(forkRootPlan.valid);
    region forkRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes forkRootBytes = allocateBytes(forkRootArena, forkRootPlan.linkedLength);
    long forkRootWritten = writeConstantImport(
      linkedForkSource,
      rootSource,
      forkRootPlan,
      forkRootBytes
    );
    assert(forkRootWritten == forkRootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(forkRootBytes);

    LinkPlan chainRootPlan = planResolvedConstantImport(
      linkedChainSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(chainRootPlan.valid);
    region chainRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes chainRootBytes = allocateBytes(chainRootArena, chainRootPlan.linkedLength);
    long chainRootWritten = writeConstantImport(
      linkedChainSource,
      firstLinkedRootSource,
      chainRootPlan,
      chainRootBytes
    );
    assert(chainRootWritten == chainRootPlan.linkedLength);
    utf8 secondLinkedRootSource = freezeUtf8(chainRootBytes);

    LinkPlan directPlan = planConstantImport(
      directSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(directPlan.valid);
    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, directPlan.linkedLength);
    long finalWritten = writeConstantImport(
      directSource,
      secondLinkedRootSource,
      directPlan,
      finalBytes
    );
    assert(finalWritten == directPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(secondLinkedRootSource);
    drop(chainRootArena);
    drop(firstLinkedRootSource);
    drop(forkRootArena);
    drop(linkedChainSource);
    drop(chainArena);
    drop(linkedForkSource);
    drop(secondForkArena);
    drop(firstLinkedForkSource);
    drop(firstForkArena);
    return new SixSeparateCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles three independent chains imported directly by the root.
  public SixSeparateCompilation compileSixThreeChainsIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondLeafSource,
    borrow utf8 secondDependentSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 thirdDependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstChainPlan = planPrivateConstantImport(
      firstLeafSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    assert(firstChainPlan.valid);
    region firstChainArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstChainBytes = allocateBytes(firstChainArena, firstChainPlan.linkedLength);
    long firstChainWritten = writeConstantImport(
      firstLeafSource,
      firstDependentSource,
      firstChainPlan,
      firstChainBytes
    );
    assert(firstChainWritten == firstChainPlan.linkedLength);
    utf8 linkedFirstChainSource = freezeUtf8(firstChainBytes);

    LinkPlan secondChainPlan = planPrivateConstantImport(
      secondLeafSource,
      secondDependentSource,
      /* expectedImportCount= */ 1
    );
    assert(secondChainPlan.valid);
    region secondChainArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondChainBytes = allocateBytes(secondChainArena, secondChainPlan.linkedLength);
    long secondChainWritten = writeConstantImport(
      secondLeafSource,
      secondDependentSource,
      secondChainPlan,
      secondChainBytes
    );
    assert(secondChainWritten == secondChainPlan.linkedLength);
    utf8 linkedSecondChainSource = freezeUtf8(secondChainBytes);

    LinkPlan thirdChainPlan = planPrivateConstantImport(
      thirdLeafSource,
      thirdDependentSource,
      /* expectedImportCount= */ 1
    );
    assert(thirdChainPlan.valid);
    region thirdChainArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes thirdChainBytes = allocateBytes(thirdChainArena, thirdChainPlan.linkedLength);
    long thirdChainWritten = writeConstantImport(
      thirdLeafSource,
      thirdDependentSource,
      thirdChainPlan,
      thirdChainBytes
    );
    assert(thirdChainWritten == thirdChainPlan.linkedLength);
    utf8 linkedThirdChainSource = freezeUtf8(thirdChainBytes);

    LinkPlan firstRootPlan = planResolvedConstantImport(
      linkedFirstChainSource,
      rootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(firstRootPlan.valid);
    region firstRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstRootBytes = allocateBytes(firstRootArena, firstRootPlan.linkedLength);
    long firstRootWritten = writeConstantImport(
      linkedFirstChainSource,
      rootSource,
      firstRootPlan,
      firstRootBytes
    );
    assert(firstRootWritten == firstRootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(firstRootBytes);

    LinkPlan secondRootPlan = planResolvedConstantImport(
      linkedSecondChainSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(secondRootPlan.valid);
    region secondRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondRootBytes = allocateBytes(secondRootArena, secondRootPlan.linkedLength);
    long secondRootWritten = writeConstantImport(
      linkedSecondChainSource,
      firstLinkedRootSource,
      secondRootPlan,
      secondRootBytes
    );
    assert(secondRootWritten == secondRootPlan.linkedLength);
    utf8 secondLinkedRootSource = freezeUtf8(secondRootBytes);

    LinkPlan thirdRootPlan = planResolvedConstantImport(
      linkedThirdChainSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(thirdRootPlan.valid);
    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, thirdRootPlan.linkedLength);
    long finalWritten = writeConstantImport(
      linkedThirdChainSource,
      secondLinkedRootSource,
      thirdRootPlan,
      finalBytes
    );
    assert(finalWritten == thirdRootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(secondLinkedRootSource);
    drop(secondRootArena);
    drop(firstLinkedRootSource);
    drop(firstRootArena);
    drop(linkedThirdChainSource);
    drop(thirdChainArena);
    drop(linkedSecondChainSource);
    drop(secondChainArena);
    drop(linkedFirstChainSource);
    drop(firstChainArena);
    return new SixSeparateCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles a three-module chain beside a two-module chain and one direct import.
  public SixSeparateCompilation compileSixLongAndShortChainsIfOrdered(
    borrow utf8 longLeafSource,
    borrow utf8 middleSource,
    borrow utf8 longDependentSource,
    borrow utf8 shortLeafSource,
    borrow utf8 shortDependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan longLeafPlan = planPrivateConstantImport(
      longLeafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    assert(longLeafPlan.valid);
    region longLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes longLeafBytes = allocateBytes(longLeafArena, longLeafPlan.linkedLength);
    long longLeafWritten = writeConstantImport(
      longLeafSource,
      middleSource,
      longLeafPlan,
      longLeafBytes
    );
    assert(longLeafWritten == longLeafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(longLeafBytes);

    LinkPlan longDependentPlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      longDependentSource,
      /* expectedImportCount= */ 1
    );
    assert(longDependentPlan.valid);
    region longDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes longDependentBytes = allocateBytes(longDependentArena, longDependentPlan.linkedLength);
    long longDependentWritten = writeConstantImport(
      linkedMiddleSource,
      longDependentSource,
      longDependentPlan,
      longDependentBytes
    );
    assert(longDependentWritten == longDependentPlan.linkedLength);
    utf8 linkedLongSource = freezeUtf8(longDependentBytes);

    LinkPlan shortPlan = planPrivateConstantImport(
      shortLeafSource,
      shortDependentSource,
      /* expectedImportCount= */ 1
    );
    assert(shortPlan.valid);
    region shortArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes shortBytes = allocateBytes(shortArena, shortPlan.linkedLength);
    long shortWritten = writeConstantImport(
      shortLeafSource,
      shortDependentSource,
      shortPlan,
      shortBytes
    );
    assert(shortWritten == shortPlan.linkedLength);
    utf8 linkedShortSource = freezeUtf8(shortBytes);

    LinkPlan longRootPlan = planResolvedConstantImport(
      linkedLongSource,
      rootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(longRootPlan.valid);
    region longRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes longRootBytes = allocateBytes(longRootArena, longRootPlan.linkedLength);
    long longRootWritten = writeConstantImport(
      linkedLongSource,
      rootSource,
      longRootPlan,
      longRootBytes
    );
    assert(longRootWritten == longRootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(longRootBytes);

    LinkPlan shortRootPlan = planResolvedConstantImport(
      linkedShortSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(shortRootPlan.valid);
    region shortRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes shortRootBytes = allocateBytes(shortRootArena, shortRootPlan.linkedLength);
    long shortRootWritten = writeConstantImport(
      linkedShortSource,
      firstLinkedRootSource,
      shortRootPlan,
      shortRootBytes
    );
    assert(shortRootWritten == shortRootPlan.linkedLength);
    utf8 secondLinkedRootSource = freezeUtf8(shortRootBytes);

    LinkPlan directPlan = planConstantImport(
      directSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    assert(directPlan.valid);
    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, directPlan.linkedLength);
    long finalWritten = writeConstantImport(
      directSource,
      secondLinkedRootSource,
      directPlan,
      finalBytes
    );
    assert(finalWritten == directPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(secondLinkedRootSource);
    drop(shortRootArena);
    drop(firstLinkedRootSource);
    drop(longRootArena);
    drop(linkedShortSource);
    drop(shortArena);
    drop(linkedLongSource);
    drop(longDependentArena);
    drop(linkedMiddleSource);
    drop(longLeafArena);
    return new SixSeparateCompilation(compiled.length, compiled.codeStart);
  }
}
