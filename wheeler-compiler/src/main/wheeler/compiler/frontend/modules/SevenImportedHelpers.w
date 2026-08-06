//! Links seven direct scalar-helper owners in canonical root-import order.

module wheeler.compiler.seven_imported_helpers;

import wheeler.compiler.compiler_core;
import wheeler.compiler.helper_owners;
import wheeler.compiler.helper_source_order;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class SevenImportedHelpers {
  private LinkPlan helperPlanAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource
  ) {
    if (source == 0) {
      return planResolvedHelperImport(firstSource, rootSource, /* expectedImportCount= */ 7);
    }

    if (source == 1) {
      return planResolvedHelperImport(secondSource, rootSource, /* expectedImportCount= */ 7);
    }

    if (source == 2) {
      return planResolvedHelperImport(thirdSource, rootSource, /* expectedImportCount= */ 7);
    }

    if (source == 3) {
      return planResolvedHelperImport(fourthSource, rootSource, /* expectedImportCount= */ 7);
    }

    if (source == 4) {
      return planResolvedHelperImport(fifthSource, rootSource, /* expectedImportCount= */ 7);
    }

    if (source == 5) {
      return planResolvedHelperImport(sixthSource, rootSource, /* expectedImportCount= */ 7);
    }

    return planResolvedHelperImport(seventhSource, rootSource, /* expectedImportCount= */ 7);
  }

  private long writeHelperAt(
    long source,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
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

    if (source == 4) {
      return writeConstantImport(fifthSource, rootSource, plan, output);
    }

    if (source == 5) {
      return writeConstantImport(sixthSource, rootSource, plan, output);
    }

    return writeConstantImport(seventhSource, rootSource, plan, output);
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
    LinkPlan fifthPlan,
    LinkPlan sixthPlan,
    LinkPlan seventhPlan
  ) {
    HelperOwners owners = sevenHelperOwners(
      owner(firstPlan),
      owner(secondPlan),
      owner(thirdPlan),
      owner(fourthPlan),
      owner(fifthPlan),
      owner(sixthPlan),
      owner(seventhPlan)
    );
    return compileMinimalCoreWithHelperOwners(source, output, owners);
  }

  /// Links seven direct helper modules independent of source-frame order.
  public CoreCompilation compileSevenHelperOwners(
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
    LinkPlan firstInputPlan = helperPlanAt(
      0,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    LinkPlan secondInputPlan = helperPlanAt(
      1,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    LinkPlan thirdInputPlan = helperPlanAt(
      2,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    LinkPlan fourthInputPlan = helperPlanAt(
      3,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    LinkPlan fifthInputPlan = helperPlanAt(
      4,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    LinkPlan sixthInputPlan = helperPlanAt(
      5,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    LinkPlan seventhInputPlan = helperPlanAt(
      6,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
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

    if (sixthInputPlan.valid) {} else {
      assert(0 == 1);
    }

    if (seventhInputPlan.valid) {} else {
      assert(0 == 1);
    }

    long[7] ownerStarts = new long[7](
      firstInputPlan.linkedOwnerStart,
      secondInputPlan.linkedOwnerStart,
      thirdInputPlan.linkedOwnerStart,
      fourthInputPlan.linkedOwnerStart,
      fifthInputPlan.linkedOwnerStart,
      sixthInputPlan.linkedOwnerStart,
      seventhInputPlan.linkedOwnerStart
    );
    long firstOwner = helperSourceAtRank(0, ownerStarts, 7);
    long secondOwner = helperSourceAtRank(1, ownerStarts, 7);
    long thirdOwner = helperSourceAtRank(2, ownerStarts, 7);
    long fourthOwner = helperSourceAtRank(3, ownerStarts, 7);
    long fifthOwner = helperSourceAtRank(4, ownerStarts, 7);
    long sixthOwner = helperSourceAtRank(5, ownerStarts, 7);
    long seventhOwner = helperSourceAtRank(6, ownerStarts, 7);
    LinkPlan seventhPlan = helperPlanAt(
      seventhOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    if (seventhPlan.valid) {} else {
      assert(0 == 1);
    }

    region seventhArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes seventhBytes = allocateBytes(seventhArena, seventhPlan.linkedLength);
    long seventhWritten = writeHelperAt(
      seventhOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource,
      seventhPlan,
      seventhBytes
    );
    assert(seventhWritten == seventhPlan.linkedLength);
    utf8 seventhLinkedSource = freezeUtf8(seventhBytes);

    LinkPlan sixthPlan = helperPlanAt(
      sixthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      seventhLinkedSource
    );
    if (sixthPlan.valid) {} else {
      assert(0 == 1);
    }

    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes sixthBytes = allocateBytes(sixthArena, sixthPlan.linkedLength);
    long sixthWritten = writeHelperAt(
      sixthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      seventhLinkedSource,
      sixthPlan,
      sixthBytes
    );
    assert(sixthWritten == sixthPlan.linkedLength);
    utf8 sixthLinkedSource = freezeUtf8(sixthBytes);

    LinkPlan fifthPlan = helperPlanAt(
      fifthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      sixthLinkedSource
    );
    if (fifthPlan.valid) {} else {
      assert(0 == 1);
    }

    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeHelperAt(
      fifthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      sixthLinkedSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 fifthLinkedSource = freezeUtf8(fifthBytes);

    LinkPlan fourthPlan = helperPlanAt(
      fourthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fifthLinkedSource
    );
    if (fourthPlan.valid) {} else {
      assert(0 == 1);
    }

    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthPlan.linkedLength);
    long fourthWritten = writeHelperAt(
      fourthOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fifthLinkedSource,
      fourthPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthPlan.linkedLength);
    utf8 fourthLinkedSource = freezeUtf8(fourthBytes);

    LinkPlan thirdPlan = helperPlanAt(
      thirdOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fourthLinkedSource
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
    }

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeHelperAt(
      thirdOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fourthLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);

    LinkPlan secondPlan = helperPlanAt(
      secondOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      thirdLinkedSource
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeHelperAt(
      secondOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      thirdLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan firstPlan = helperPlanAt(
      firstOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      secondLinkedSource
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeHelperAt(
      firstOwner,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
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
      fifthPlan,
      sixthPlan,
      seventhPlan
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
    drop(sixthLinkedSource);
    drop(sixthArena);
    drop(seventhLinkedSource);
    drop(seventhArena);
    return compiled;
  }
}
