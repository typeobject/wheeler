//! Decodes optional proof certificates into counted closure product rows.

module wheeler.compiler.closure.compiled_proof_products;

import wheeler.core.encoding.binary;

classical class CompiledProofProducts {
  private const long MAX_MODULES = 512;
  private const long MAX_PROOFS = 4096;
  private const long MAX_SECTIONS = 64;
  private const long PROOF_ROWS = 24576;
  private const long STAGING_BYTES = 196608;

  private record ProofSection(boolean present, long start, long length) {}

  private ProofSection proofSection(borrow byteview artifact, long artifactLength) {
    assert(39 < artifactLength);
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
    assert(-1 < moduleStringCount);
    assert(-1 < firstFunction);
    assert(0 < functionCount);
    assert(-1 < closureProofCount);
    assert(closureProofCount < MAX_PROOFS + 1);
    assert(bufferLength(proofRows) == PROOF_ROWS);
    ProofSection proofs = proofSection(artifact, artifactLength);
    if (proofs.present == false) {
      return closureProofCount;
    }

    assert(3 < proofs.length);
    long proofCount = readUnsigned(artifact, proofs.start, 4);
    assert(proofCount < MAX_PROOFS - closureProofCount + 1);
    assert(proofs.length == 4 + proofCount * 24);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 6);
    words names = allocate(staging, MAX_PROOFS);
    words rules = allocate(staging, MAX_PROOFS);
    words subjects = allocate(staging, MAX_PROOFS);
    words argumentsLow = allocate(staging, MAX_PROOFS);
    words argumentsHigh = allocate(staging, MAX_PROOFS);
    words owners = allocate(staging, MAX_PROOFS);
    long proof = 0;
    while (proof < proofCount) limit MAX_PROOFS {
      long descriptor = proofs.start + 4 + proof * 24;
      assert(readUnsigned(artifact, descriptor, 4) == proof);
      long name = readUnsigned(artifact, descriptor + 4, 4);
      long rule = readUnsigned(artifact, descriptor + 8, 4);
      long subject = readUnsigned(artifact, descriptor + 12, 4);
      assert(name < moduleStringCount);
      assert(0 < rule);
      assert(rule < 3);
      assert(subject < functionCount);
      set(names, proof, moduleStringBase + name);
      set(rules, proof, rule);
      set(subjects, proof, firstFunction + subject);
      set(argumentsLow, proof, readUnsigned(artifact, descriptor + 16, 4));
      set(argumentsHigh, proof, readUnsigned(artifact, descriptor + 20, 4));
      set(owners, proof, moduleOwner);
      proof += 1;
    }

    proof = 0;
    while (proof < proofCount) limit MAX_PROOFS {
      long target = closureProofCount + proof;
      set(proofRows, target, owners[proof]);
      set(proofRows, 4096 + target, names[proof]);
      set(proofRows, 8192 + target, rules[proof]);
      set(proofRows, 12288 + target, subjects[proof]);
      set(proofRows, 16384 + target, argumentsLow[proof]);
      set(proofRows, 20480 + target, argumentsHigh[proof]);
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
