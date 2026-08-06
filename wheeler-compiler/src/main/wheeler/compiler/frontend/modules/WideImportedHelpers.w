//! Links five direct scalar-helper owners in canonical root-import order.

module wheeler.compiler.wide_imported_helpers;

import wheeler.compiler.compiler_core;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class WideImportedHelpers {
  private LinkPlan helperPlanAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource
  ) {
    if (source == 0) {
      return planResolvedHelperImport(firstSource, rootSource, /* expectedImportCount= */ 5);
    }

    if (source == 1) {
      return planResolvedHelperImport(secondSource, rootSource, /* expectedImportCount= */ 5);
    }

    if (source == 2) {
      return planResolvedHelperImport(thirdSource, rootSource, /* expectedImportCount= */ 5);
    }

    if (source == 3) {
      return planResolvedHelperImport(fourthSource, rootSource, /* expectedImportCount= */ 5);
    }

    return planResolvedHelperImport(fifthSource, rootSource, /* expectedImportCount= */ 5);
  }

  private long writeHelperAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    LinkPlan plan,
    borrow mut bytes output
  ) {
    if (source == 0) {
      return writeConstantImport(firstSource, rootSource, plan, output);
    }

    if (source == 1) {
      return writeConstantImport(secondSource, rootSource, plan, output);
    }

    if (source == 2) {
      return writeConstantImport(thirdSource, rootSource, plan, output);
    }

    if (source == 3) {
      return writeConstantImport(fourthSource, rootSource, plan, output);
    }

    return writeConstantImport(fifthSource, rootSource, plan, output);
  }

  private long importRank(
    long source,
    long firstStart,
    long secondStart,
    long thirdStart,
    long fourthStart,
    long fifthStart
  ) {
    long selected = firstStart;
    if (source == 1) {
      selected = secondStart;
    }

    if (source == 2) {
      selected = thirdStart;
    }

    if (source == 3) {
      selected = fourthStart;
    }

    if (source == 4) {
      selected = fifthStart;
    }

    long rank = 0;
    if (firstStart < selected) {
      rank += 1;
    }

    if (secondStart < selected) {
      rank += 1;
    }

    if (thirdStart < selected) {
      rank += 1;
    }

    if (fourthStart < selected) {
      rank += 1;
    }

    if (fifthStart < selected) {
      rank += 1;
    }

    return rank;
  }

  private long sourceAtRank(
    long rank,
    long firstRank,
    long secondRank,
    long thirdRank,
    long fourthRank
  ) {
    if (firstRank == rank) {
      return 0;
    }

    if (secondRank == rank) {
      return 1;
    }

    if (thirdRank == rank) {
      return 2;
    }

    if (fourthRank == rank) {
      return 3;
    }

    return 4;
  }

  private HelperOwner owner(LinkPlan plan) {
    return importedHelperOwner(
      plan.linkedOwnerStart,
      plan.linkedOwnerLength,
      plan.importedHelperCount
    );
  }

  private CoreCompilation compileOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan,
    LinkPlan thirdPlan,
    LinkPlan fourthPlan,
    LinkPlan fifthPlan
  ) {
    HelperOwners owners = fiveHelperOwners(
      owner(firstPlan),
      owner(secondPlan),
      owner(thirdPlan),
      owner(fourthPlan),
      owner(fifthPlan)
    );
    return compileMinimalCoreWithHelperOwners(source, output, owners);
  }

  /// Links five direct helper modules independent of source-frame order.
  public CoreCompilation compileFiveHelperOwners(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstInputPlan = helperPlanAt(
      0,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    LinkPlan secondInputPlan = helperPlanAt(
      1,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    LinkPlan thirdInputPlan = helperPlanAt(
      2,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    LinkPlan fourthInputPlan = helperPlanAt(
      3,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    LinkPlan fifthInputPlan = helperPlanAt(
      4,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    if (firstInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (secondInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (thirdInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (fourthInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (fifthInputPlan.valid) {} else {
      assert(0 == 1);
    }

    long firstRank = importRank(
      0,
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart,
      fifthInputPlan.linkedOwnerStart
    );
    long secondRank = importRank(
      1,
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart,
      fifthInputPlan.linkedOwnerStart
    );
    long thirdRank = importRank(
      2,
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart,
      fifthInputPlan.linkedOwnerStart
    );
    long fourthRank = importRank(
      3,
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart,
      fifthInputPlan.linkedOwnerStart
    );
    long fifth = sourceAtRank(4, firstRank, secondRank, thirdRank, fourthRank);
    long fourth = sourceAtRank(3, firstRank, secondRank, thirdRank, fourthRank);
    long third = sourceAtRank(2, firstRank, secondRank, thirdRank, fourthRank);
    long second = sourceAtRank(1, firstRank, secondRank, thirdRank, fourthRank);
    long first = sourceAtRank(0, firstRank, secondRank, thirdRank, fourthRank);

    LinkPlan fifthPlan = helperPlanAt(
      fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeHelperAt(
      fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 fifthLinkedSource = freezeUtf8(fifthBytes);

    LinkPlan fourthPlan = helperPlanAt(
      fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthLinkedSource
    );
    if (fourthPlan.valid) {} else {
      assert(0 == 1);
    }

    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthPlan.linkedLength);
    long fourthWritten = writeHelperAt(
      fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthLinkedSource,
      fourthPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthPlan.linkedLength);
    utf8 fourthLinkedSource = freezeUtf8(fourthBytes);

    LinkPlan thirdPlan = helperPlanAt(
      third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fourthLinkedSource
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
    }

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeHelperAt(
      third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fourthLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);

    LinkPlan secondPlan = helperPlanAt(
      second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      thirdLinkedSource
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeHelperAt(
      second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      thirdLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan firstPlan = helperPlanAt(
      first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      secondLinkedSource
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeHelperAt(
      first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      secondLinkedSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 linkedSource = freezeUtf8(firstBytes);
    CoreCompilation compiled = compileOwnedHelpers(
      linkedSource,
      output,
      firstPlan,
      secondPlan,
      thirdPlan,
      fourthPlan,
      fifthPlan
    );
    drop(linkedSource);
    drop(firstArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(fourthLinkedSource);
    drop(fourthArena);
    drop(fifthLinkedSource);
    drop(fifthArena);
    return compiled;
  }
}
