//! Links two direct scalar-helper owners in canonical root-import order.

module wheeler.compiler.multiple_imported_helpers;

import wheeler.compiler.compiler_core;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class MultipleImportedHelpers {
  private CoreCompilation compileOwnedHelpers(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan firstPlan,
    LinkPlan secondPlan
  ) {
    return compileMinimalCoreWithHelperImports(
      source,
      output,
      firstPlan.linkedOwnerStart,
      firstPlan.linkedOwnerLength,
      firstPlan.importedHelperCount,
      secondPlan.linkedOwnerStart,
      secondPlan.linkedOwnerLength,
      secondPlan.importedHelperCount
    );
  }

  /// Links two direct helper modules and preserves both canonical function owners.
  public CoreCompilation compileTwoHelperOwners(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planResolvedHelperImport(
      firstSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    LinkPlan secondPlan = planResolvedHelperImport(
      secondSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    boolean firstIsEarlier = firstPlan.linkedOwnerStart < secondPlan.linkedOwnerStart;
    LinkPlan laterPlan = firstPlan;
    if (firstIsEarlier) {
      laterPlan = secondPlan;
    }

    region laterArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes laterBytes = allocateBytes(laterArena, laterPlan.linkedLength);
    long laterWritten = 0;
    if (firstIsEarlier) {
      laterWritten = writeConstantImport(secondSource, rootSource, laterPlan, laterBytes);
    } else {
      laterWritten = writeConstantImport(firstSource, rootSource, laterPlan, laterBytes);
    }

    assert(laterWritten == laterPlan.linkedLength);
    utf8 laterLinkedSource = freezeUtf8(laterBytes);
    LinkPlan earlierPlan = new LinkPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false);
    if (firstIsEarlier) {
      earlierPlan = planResolvedHelperImport(
        firstSource,
        laterLinkedSource,
        /* expectedImportCount= */ 2
      );
    } else {
      earlierPlan = planResolvedHelperImport(
        secondSource,
        laterLinkedSource,
        /* expectedImportCount= */ 2
      );
    }

    if (earlierPlan.valid) {} else {
      assert(0 == 1);
    }

    region earlierArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes earlierBytes = allocateBytes(earlierArena, earlierPlan.linkedLength);
    long earlierWritten = 0;
    if (firstIsEarlier) {
      earlierWritten = writeConstantImport(
        firstSource,
        laterLinkedSource,
        earlierPlan,
        earlierBytes
      );
    } else {
      earlierWritten = writeConstantImport(
        secondSource,
        laterLinkedSource,
        earlierPlan,
        earlierBytes
      );
    }

    assert(earlierWritten == earlierPlan.linkedLength);
    utf8 linkedSource = freezeUtf8(earlierBytes);
    CoreCompilation compiled = compileOwnedHelpers(linkedSource, output, earlierPlan, laterPlan);
    drop(linkedSource);
    drop(earlierArena);
    drop(laterLinkedSource);
    drop(laterArena);
    return compiled;
  }
}
