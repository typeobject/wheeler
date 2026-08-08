//! Emits and publishes one canonical container from final counted semantic products.

module wheeler.compiler.closure.canonical_product_emitter;

import wheeler.compiler.closure.compiled_function_names;
import wheeler.compiler.closure.linked_aggregate_sections;
import wheeler.compiler.closure.linked_container;
import wheeler.compiler.closure.linked_function_section;
import wheeler.compiler.closure.linked_manifest_section;
import wheeler.compiler.closure.linked_proof_section;
import wheeler.compiler.closure.linked_string_section;
import wheeler.compiler.verifier;

classical class CanonicalProductEmitter {
  private const long MAX_CODE_BYTES = 4194304;

  /// Reports the unaligned section archive extent and canonical section count.
  public record CanonicalProductSections(long length, long sectionCount) {}

  /// Emits final semantic sections without publishing the container output.
  ///
  /// The caller may drop source artifacts and large product windows after this call. It then
  /// invokes `publishCanonicalProductContainer` with only this section archive and directory.
  public CanonicalProductSections emitCanonicalProductSections(
    borrow byteview rootArtifact,
    long rootArtifactLength,
    long rootModule,
    long rootStringBase,
    long rootStringCount,
    borrow byteview stringArchive,
    long stringArchiveBytes,
    long closureStringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words finalStringRows,
    borrow mut words moduleFirstFunctions,
    borrow mut words moduleFunctionCounts,
    long globalCount,
    borrow mut words globalRows,
    long aggregateCount,
    long caseCount,
    borrow mut words moduleStringBases,
    borrow mut words aggregateRows,
    borrow mut words caseRows,
    borrow mut words memberRows,
    borrow mut words finalDescriptorRows,
    long functionCount,
    borrow mut words closureFunctionRows,
    borrow mut words closureFunctionNameRows,
    borrow mut words finalFunctionNameIds,
    long linkedTypeCount,
    borrow mut words linkedTypes,
    borrow byteview linkedCode,
    long linkedCodeBytes,
    long proofCount,
    borrow mut words proofRows,
    borrow mut words sectionTypes,
    borrow mut words sectionStarts,
    borrow mut words sectionLengths,
    borrow mut bytes sectionArchive
  ) {
    assert(-1 < linkedCodeBytes);
    assert(linkedCodeBytes < MAX_CODE_BYTES + 1);
    assert(linkedCodeBytes < bufferLength(linkedCode) + 1);
    assert(23 < bufferLength(sectionArchive));

    long cursor = 24;
    set(sectionTypes, 1, 2);
    set(sectionStarts, 1, cursor);
    long stringBytes = emitLinkedStringSectionAt(
      stringArchive,
      stringArchiveBytes,
      closureStringCount,
      stringStarts,
      stringLengths,
      finalStringRows,
      sectionArchive,
      cursor
    );
    set(sectionLengths, 1, stringBytes);
    cursor += stringBytes;
    resolveLinkedFunctionNameIds(
      functionCount,
      closureStringCount,
      closureFunctionNameRows,
      finalStringRows,
      finalFunctionNameIds
    );

    set(sectionTypes, 0, 1);
    set(sectionStarts, 0, 0);
    long manifestBytes = emitLinkedManifestSection(
      rootArtifact,
      rootArtifactLength,
      rootModule,
      rootStringBase,
      rootStringCount,
      closureStringCount,
      finalStringRows,
      moduleFirstFunctions,
      moduleFunctionCounts,
      sectionArchive,
      /* outputStart= */ 0
    );
    set(sectionLengths, 0, manifestBytes);

    set(sectionTypes, 2, 3);
    set(sectionStarts, 2, cursor);
    long typeBytes = emitLinkedTypeSection(
      globalCount,
      globalRows,
      aggregateCount,
      closureStringCount,
      moduleStringBases,
      finalStringRows,
      aggregateRows,
      memberRows,
      finalDescriptorRows,
      sectionArchive,
      cursor
    );
    set(sectionLengths, 2, typeBytes);
    cursor += typeBytes;

    set(sectionTypes, 3, 4);
    set(sectionStarts, 3, cursor);
    long variantBytes = emitLinkedVariantSection(
      aggregateCount,
      caseCount,
      closureStringCount,
      moduleStringBases,
      finalStringRows,
      aggregateRows,
      caseRows,
      memberRows,
      finalDescriptorRows,
      sectionArchive,
      cursor
    );
    set(sectionLengths, 3, variantBytes);
    cursor += variantBytes;

    set(sectionTypes, 4, 5);
    set(sectionStarts, 4, cursor);
    long functionBytes = emitLinkedFunctionSectionAt(
      functionCount,
      closureFunctionRows,
      closureStringCount,
      finalFunctionNameIds,
      linkedTypeCount,
      linkedTypes,
      linkedCodeBytes,
      sectionArchive,
      cursor
    );
    set(sectionLengths, 4, functionBytes);
    cursor += functionBytes;

    set(sectionTypes, 5, 6);
    set(sectionStarts, 5, cursor);
    assert(linkedCodeBytes < bufferLength(sectionArchive) - cursor + 1);
    long codeByte = 0;
    while (codeByte < linkedCodeBytes) limit MAX_CODE_BYTES {
      setByte(sectionArchive, cursor + codeByte, linkedCode[codeByte]);
      codeByte += 1;
    }

    set(sectionLengths, 5, linkedCodeBytes);
    cursor += linkedCodeBytes;

    long sectionCount = 6;
    if (0 < proofCount) {
      set(sectionTypes, 6, 10);
      set(sectionStarts, 6, cursor);
      long proofBytes = emitLinkedProofSection(
        proofCount,
        functionCount,
        closureStringCount,
        proofRows,
        finalStringRows,
        sectionArchive,
        cursor
      );
      set(sectionLengths, 6, proofBytes);
      cursor += proofBytes;
      sectionCount = 7;
    }

    return new CanonicalProductSections(cursor, sectionCount);
  }

  /// Assembles and semantically verifies a section archive before length publication.
  public long publishCanonicalProductContainer(
    borrow byteview sectionArchive,
    CanonicalProductSections sections,
    borrow mut words sectionTypes,
    borrow mut words sectionStarts,
    borrow mut words sectionLengths,
    borrow mut bytes output
  ) {
    long artifactBytes = emitCanonicalContainer(
      sectionArchive,
      sections.length,
      sections.sectionCount,
      sectionTypes,
      sectionStarts,
      sectionLengths,
      output
    );
    assert(verifyArtifact(output, artifactBytes) == 1);
    return artifactBytes;
  }
}
