//! Links one or two direct helper owners beside direct constant owners.

module wheeler.compiler.graphs.direct.mixed_four;

import wheeler.compiler.canonical_helper_linking;
import wheeler.compiler.compiler_core;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class MixedFourDirectGraph {
  private const long DIRECT_IMPORT_COUNT = 4;

  /// Carries compilation bounds for one admitted mixed four-owner graph.
  public record MixedFourCompilation(long length, long codeStart) {}

  private MixedFourCompilation invalidCompilation() {
    return new MixedFourCompilation(0, 0);
  }

  private HelperOwner helperOwner(LinkPlan plan) {
    return importedHelperOwner(
      plan.linkedOwnerStart,
      plan.linkedOwnerLength,
      plan.importedHelperCount
    );
  }

  private MixedFourCompilation compileOneHelper(
    borrow utf8 helperSource,
    borrow utf8 firstConstantSource,
    borrow utf8 secondConstantSource,
    borrow utf8 thirdConstantSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan helperPlan = planResolvedHelperImport(
      helperSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (helperPlan.valid) {} else {
      return invalidCompilation();
    }

    region helperArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes helperBytes = allocateBytes(helperArena, helperPlan.linkedLength);
    long helperWritten = writeCanonicalHelperImport(
      helperSource,
      rootSource,
      helperPlan,
      helperBytes
    );
    assert(helperWritten == helperPlan.linkedLength);
    utf8 helperLinkedRoot = freezeUtf8(helperBytes);

    LinkPlan firstPlan = planConstantImport(
      firstConstantSource,
      helperLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (firstPlan.valid) {} else {
      drop(helperLinkedRoot);
      drop(helperArena);
      return invalidCompilation();
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstConstantSource,
      helperLinkedRoot,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedRoot = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondConstantSource,
      firstLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (secondPlan.valid) {} else {
      drop(firstLinkedRoot);
      drop(firstArena);
      drop(helperLinkedRoot);
      drop(helperArena);
      return invalidCompilation();
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondConstantSource,
      firstLinkedRoot,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedRoot = freezeUtf8(secondBytes);

    LinkPlan thirdPlan = planConstantImport(
      thirdConstantSource,
      secondLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (thirdPlan.valid) {} else {
      drop(secondLinkedRoot);
      drop(secondArena);
      drop(firstLinkedRoot);
      drop(firstArena);
      drop(helperLinkedRoot);
      drop(helperArena);
      return invalidCompilation();
    }

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      thirdConstantSource,
      secondLinkedRoot,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 linkedRoot = freezeUtf8(thirdBytes);
    CoreCompilation compiled = compileMinimalCoreWithHelperOwner(
      linkedRoot,
      output,
      helperPlan.linkedOwnerStart,
      helperPlan.linkedOwnerLength,
      helperPlan.importedHelperCount
    );
    drop(linkedRoot);
    drop(thirdArena);
    drop(secondLinkedRoot);
    drop(secondArena);
    drop(firstLinkedRoot);
    drop(firstArena);
    drop(helperLinkedRoot);
    drop(helperArena);
    return new MixedFourCompilation(compiled.length, compiled.codeStart);
  }

  private MixedFourCompilation compileTwoHelpers(
    borrow utf8 firstHelperSource,
    borrow utf8 secondHelperSource,
    borrow utf8 firstConstantSource,
    borrow utf8 secondConstantSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstInputPlan = planResolvedHelperImport(
      firstHelperSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    LinkPlan secondInputPlan = planResolvedHelperImport(
      secondHelperSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (firstInputPlan.valid) {} else {
      return invalidCompilation();
    }

    if (secondInputPlan.valid) {} else {
      return invalidCompilation();
    }

    boolean firstIsEarlier = firstInputPlan.linkedOwnerStart < secondInputPlan.linkedOwnerStart;
    LinkPlan laterPlan = firstInputPlan;
    if (firstIsEarlier) {
      laterPlan = secondInputPlan;
    }

    region laterArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes laterBytes = allocateBytes(laterArena, laterPlan.linkedLength);
    long laterWritten = 0;
    if (firstIsEarlier) {
      laterWritten = writeCanonicalHelperImport(
        secondHelperSource,
        rootSource,
        laterPlan,
        laterBytes
      );
    } else {
      laterWritten = writeCanonicalHelperImport(
        firstHelperSource,
        rootSource,
        laterPlan,
        laterBytes
      );
    }

    assert(laterWritten == laterPlan.linkedLength);
    utf8 laterLinkedRoot = freezeUtf8(laterBytes);
    LinkPlan earlierPlan = firstInputPlan;
    if (firstIsEarlier) {
      earlierPlan = planResolvedHelperImport(
        firstHelperSource,
        laterLinkedRoot,
        /* expectedImportCount= */ DIRECT_IMPORT_COUNT
      );
    } else {
      earlierPlan = planResolvedHelperImport(
        secondHelperSource,
        laterLinkedRoot,
        /* expectedImportCount= */ DIRECT_IMPORT_COUNT
      );
    }

    if (earlierPlan.valid) {} else {
      drop(laterLinkedRoot);
      drop(laterArena);
      return invalidCompilation();
    }

    region earlierArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes earlierBytes = allocateBytes(earlierArena, earlierPlan.linkedLength);
    long earlierWritten = 0;
    if (firstIsEarlier) {
      earlierWritten = writeCanonicalHelperImport(
        firstHelperSource,
        laterLinkedRoot,
        earlierPlan,
        earlierBytes
      );
    } else {
      earlierWritten = writeCanonicalHelperImport(
        secondHelperSource,
        laterLinkedRoot,
        earlierPlan,
        earlierBytes
      );
    }

    assert(earlierWritten == earlierPlan.linkedLength);
    utf8 helpersLinkedRoot = freezeUtf8(earlierBytes);
    LinkPlan firstConstantPlan = planConstantImport(
      firstConstantSource,
      helpersLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (firstConstantPlan.valid) {} else {
      drop(helpersLinkedRoot);
      drop(earlierArena);
      drop(laterLinkedRoot);
      drop(laterArena);
      return invalidCompilation();
    }

    region firstConstantArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes firstConstantBytes = allocateBytes(firstConstantArena, firstConstantPlan.linkedLength);
    long firstConstantWritten = writeConstantImport(
      firstConstantSource,
      helpersLinkedRoot,
      firstConstantPlan,
      firstConstantBytes
    );
    assert(firstConstantWritten == firstConstantPlan.linkedLength);
    utf8 firstConstantLinkedRoot = freezeUtf8(firstConstantBytes);

    LinkPlan secondConstantPlan = planConstantImport(
      secondConstantSource,
      firstConstantLinkedRoot,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (secondConstantPlan.valid) {} else {
      drop(firstConstantLinkedRoot);
      drop(firstConstantArena);
      drop(helpersLinkedRoot);
      drop(earlierArena);
      drop(laterLinkedRoot);
      drop(laterArena);
      return invalidCompilation();
    }

    region secondConstantArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes secondConstantBytes = allocateBytes(
      secondConstantArena,
      secondConstantPlan.linkedLength
    );
    long secondConstantWritten = writeConstantImport(
      secondConstantSource,
      firstConstantLinkedRoot,
      secondConstantPlan,
      secondConstantBytes
    );
    assert(secondConstantWritten == secondConstantPlan.linkedLength);
    utf8 linkedRoot = freezeUtf8(secondConstantBytes);
    HelperOwners owners = twoHelperOwners(helperOwner(earlierPlan), helperOwner(laterPlan));
    CoreCompilation compiled = compileMinimalCoreWithHelperOwners(linkedRoot, output, owners);
    drop(linkedRoot);
    drop(secondConstantArena);
    drop(firstConstantLinkedRoot);
    drop(firstConstantArena);
    drop(helpersLinkedRoot);
    drop(earlierArena);
    drop(laterLinkedRoot);
    drop(laterArena);
    return new MixedFourCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one or two helper owners beside constants in any frame order.
  public MixedFourCompilation compileMixedFourDirectGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstHelper = planResolvedHelperImport(
      firstSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    LinkPlan secondHelper = planResolvedHelperImport(
      secondSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    LinkPlan thirdHelper = planResolvedHelperImport(
      thirdSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    LinkPlan fourthHelper = planResolvedHelperImport(
      fourthSource,
      rootSource,
      /* expectedImportCount= */ DIRECT_IMPORT_COUNT
    );
    if (firstHelper.valid) {
      if (secondHelper.valid) {
        return compileTwoHelpers(
          firstSource,
          secondSource,
          thirdSource,
          fourthSource,
          rootSource,
          output
        );
      }

      if (thirdHelper.valid) {
        return compileTwoHelpers(
          firstSource,
          thirdSource,
          secondSource,
          fourthSource,
          rootSource,
          output
        );
      }

      if (fourthHelper.valid) {
        return compileTwoHelpers(
          firstSource,
          fourthSource,
          secondSource,
          thirdSource,
          rootSource,
          output
        );
      }

      return compileOneHelper(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        rootSource,
        output
      );
    }

    if (secondHelper.valid) {
      if (thirdHelper.valid) {
        return compileTwoHelpers(
          secondSource,
          thirdSource,
          firstSource,
          fourthSource,
          rootSource,
          output
        );
      }

      if (fourthHelper.valid) {
        return compileTwoHelpers(
          secondSource,
          fourthSource,
          firstSource,
          thirdSource,
          rootSource,
          output
        );
      }

      return compileOneHelper(
        secondSource,
        firstSource,
        thirdSource,
        fourthSource,
        rootSource,
        output
      );
    }

    if (thirdHelper.valid) {
      if (fourthHelper.valid) {
        return compileTwoHelpers(
          thirdSource,
          fourthSource,
          firstSource,
          secondSource,
          rootSource,
          output
        );
      }

      return compileOneHelper(
        thirdSource,
        firstSource,
        secondSource,
        fourthSource,
        rootSource,
        output
      );
    }

    if (fourthHelper.valid) {
      return compileOneHelper(
        fourthSource,
        firstSource,
        secondSource,
        thirdSource,
        rootSource,
        output
      );
    }

    return invalidCompilation();
  }
}
