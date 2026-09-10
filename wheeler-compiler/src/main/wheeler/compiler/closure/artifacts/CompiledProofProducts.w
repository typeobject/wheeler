//! Decodes optional proof certificates into counted closure product rows.

module wheeler.compiler.closure.compiled_proof_products;

import wheeler.compiler.closure.classical_proof_products;
import wheeler.core.encoding.binary;

classical class CompiledProofProducts {
  private const long MAX_MODULES = 512;
  private const long MAX_FUNCTIONS = 4096;
  private const long MAX_STRINGS = 16384;
  private const long MAX_SECTIONS = 64;
  private const long NATIVE_WORD_BYTES = 8;
  private const long STAGING_BYTES = CLASSICAL_PROOF_ROWS * NATIVE_WORD_BYTES;

  private record ProofSection(boolean present, long start, long length) {}

  private ProofSection proofSection(borrow byteview artifact, long artifactLength) {
    assert(39 < artifactLength);
    assert(artifactLength < bufferLength(artifact) + 1);
    assert(artifact[0] == 87);
    assert(artifact[1] == 72);
    assert(artifact[2] == 69);
    assert(artifact[3] == 69);
    assert(artifact[4] == 76);
    assert(artifact[5] == 66);
    assert(artifact[6] == 67);
    assert(artifact[7] == 0);
    assert(readUnsigned(artifact, 8, 2) == 1);
    assert(readUnsigned(artifact, 10, 2) == 0);
    assert(readUnsigned(artifact, 16, 8) == artifactLength);
    long sectionCount = readUnsigned(artifact, 24, 4);
    assert(5 < sectionCount);
    assert(sectionCount < MAX_SECTIONS + 1);
    assert(readUnsigned(artifact, 28, 4) == 32);
    assert(readUnsigned(artifact, 32, 8) == 40);
    long previousType = 0;
    long previousEnd = 40 + sectionCount * 32;
    long selectedStart = 0;
    long selectedLength = 0;
    boolean present = false;
    long section = 0;
    while (section < sectionCount) limit MAX_SECTIONS {
      long directory = 40 + section * 32;
      long type = readUnsigned(artifact, directory, 4);
      long start = readUnsigned(artifact, directory + 8, 8);
      long length = readUnsigned(artifact, directory + 16, 8);
      assert(previousType < type);
      assert(readUnsigned(artifact, directory + 4, 4) == 1);
      assert(readUnsigned(artifact, directory + 24, 4) == 8);
      assert(readUnsigned(artifact, directory + 28, 4) == 0);
      assert(start % 8 == 0);
      assert(previousEnd < start + 1);
      assert(start < artifactLength + 1);
      assert(length < artifactLength - start + 1);
      previousType = type;
      previousEnd = start + length;
      if (type == 10) {
        present = true;
        selectedStart = start;
        selectedLength = length;
      }

      section += 1;
    }

    return new ProofSection(present, selectedStart, selectedLength);
  }

  /// Appends one optional source-local proof window without retaining artifact offsets.
  public long appendCompiledProofProducts(
    borrow byteview artifact,
    long artifactLength,
    long moduleOwner,
    long moduleStringBase,
    long moduleStringCount,
    long firstFunction,
    long functionCount,
    long closureProofCount,
    borrow mut words proofRows
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < MAX_MODULES);
    assert(-1 < moduleStringBase);
    assert(moduleStringBase < MAX_STRINGS + 1);
    assert(-1 < moduleStringCount);
    assert(moduleStringCount < MAX_STRINGS - moduleStringBase + 1);
    assert(-1 < firstFunction);
    assert(firstFunction < MAX_FUNCTIONS + 1);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS - firstFunction + 1);
    assert(-1 < closureProofCount);
    assert(closureProofCount < MAX_CLASSICAL_PROOFS + 1);
    assert(bufferLength(proofRows) == CLASSICAL_PROOF_ROWS);
    ProofSection proofs = proofSection(artifact, artifactLength);
    if (proofs.present == false) {
      return closureProofCount;
    }

    assert(PROOF_WORD_BYTES < proofs.length + 1);
    long proofCount = readUnsigned(artifact, proofs.start, PROOF_WORD_BYTES);
    assert(0 < proofCount);
    assert(proofCount < MAX_CLASSICAL_PROOFS - closureProofCount + 1);
    assert(proofs.length == PROOF_WORD_BYTES + proofCount * CLASSICAL_PROOF_DESCRIPTOR_BYTES);

    region staging = new region(
      /* bytes= */ STAGING_BYTES,
      /* allocations= */ CLASSICAL_PROOF_COLUMNS
    );
    words names = allocate(staging, MAX_CLASSICAL_PROOFS);
    words rules = allocate(staging, MAX_CLASSICAL_PROOFS);
    words subjects = allocate(staging, MAX_CLASSICAL_PROOFS);
    words argumentsLow = allocate(staging, MAX_CLASSICAL_PROOFS);
    words argumentsHigh = allocate(staging, MAX_CLASSICAL_PROOFS);
    words owners = allocate(staging, MAX_CLASSICAL_PROOFS);
    long proof = 0;
    while (proof < proofCount) limit MAX_CLASSICAL_PROOFS {
      long descriptor = proofs.start + PROOF_WORD_BYTES + proof * CLASSICAL_PROOF_DESCRIPTOR_BYTES;
      assert(readUnsigned(artifact, descriptor, PROOF_WORD_BYTES) == proof);
      long name = readUnsigned(artifact, descriptor + PROOF_WORD_BYTES, PROOF_WORD_BYTES);
      long rule = readUnsigned(artifact, descriptor + PROOF_WORD_BYTES * 2, PROOF_WORD_BYTES);
      long subject = readUnsigned(artifact, descriptor + PROOF_WORD_BYTES * 3, PROOF_WORD_BYTES);
      long low = readUnsigned(artifact, descriptor + PROOF_WORD_BYTES * 4, PROOF_WORD_BYTES);
      long high = readUnsigned(artifact, descriptor + PROOF_WORD_BYTES * 5, PROOF_WORD_BYTES);
      assert(name < moduleStringCount);
      assert(classicalProofArgumentValid(rule, low, high));
      assert(subject < functionCount);
      set(names, proof, moduleStringBase + name);
      set(rules, proof, rule);
      set(subjects, proof, firstFunction + subject);
      set(argumentsLow, proof, low);
      set(argumentsHigh, proof, high);
      set(owners, proof, moduleOwner);
      proof += 1;
    }

    proof = 0;
    while (proof < proofCount) limit MAX_CLASSICAL_PROOFS {
      long target = closureProofCount + proof;
      set(proofRows, target, owners[proof]);
      set(proofRows, PROOF_NAME_ROW + target, names[proof]);
      set(proofRows, PROOF_RULE_ROW + target, rules[proof]);
      set(proofRows, PROOF_SUBJECT_ROW + target, subjects[proof]);
      set(proofRows, PROOF_ARGUMENT_LOW_ROW + target, argumentsLow[proof]);
      set(proofRows, PROOF_ARGUMENT_HIGH_ROW + target, argumentsHigh[proof]);
      proof += 1;
    }

    drop(owners);
    drop(argumentsHigh);
    drop(argumentsLow);
    drop(subjects);
    drop(rules);
    drop(names);
    drop(staging);
    return closureProofCount + proofCount;
  }
}
