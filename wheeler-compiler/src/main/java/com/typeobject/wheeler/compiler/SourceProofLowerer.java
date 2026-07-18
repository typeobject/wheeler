package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.core.proof.ProofCertificate;
import com.typeobject.wheeler.core.proof.ProofRule;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Resolves the finite source theorem forms to canonical rule certificates. */
final class SourceProofLowerer {
  private SourceProofLowerer() {}

  static List<ProofCertificate> classical(
      SourceProgram source,
      Map<String, Integer> functions,
      Map<String, Boolean> reversibleFunctions,
      boolean classicalEntry) {
    List<ProofCertificate> result = new ArrayList<>();
    Set<String> names = new HashSet<>();
    for (SourceModel.ProofDeclaration proof : source.proofs()) {
      boolean classicalRule = proof.rule().equals("inverse") || proof.rule().equals("steps");
      if (!classicalRule) {
        if (classicalEntry) {
          throw new CompilerException(
              proof.line(), proof.rule() + " theorem requires a unitary circuit");
        }
        continue;
      }
      Integer function = functions.get(proof.subject());
      requireUniqueName(proof, names);
      if (function == null) {
        throw new CompilerException(proof.line(), "theorem requires a declared function");
      }
      if (proof.rule().equals("inverse")
          && !reversibleFunctions.getOrDefault(proof.subject(), false)) {
        throw new CompilerException(
            proof.line(), "inverse theorem requires a reversible function");
      }
      if (proof.rule().equals("steps") && (proof.argument() == null || proof.argument() <= 0)) {
        throw new CompilerException(proof.line(), "step theorem requires a positive bound");
      }
      ProofRule rule = proof.rule().equals("inverse")
          ? ProofRule.GENERATED_INVERSE : ProofRule.STATIC_STEP_BOUND;
      long argument = proof.argument() == null ? -1 : proof.argument();
      result.add(new ProofCertificate(
          result.size(), proof.name(), rule, function, argument));
    }
    return List.copyOf(result);
  }

  static List<ProofCertificate> quantum(
      SourceProgram source,
      List<ProofCertificate> classicalProofs,
      Map<String, Integer> circuitIds) {
    List<ProofCertificate> result = new ArrayList<>(classicalProofs);
    Set<String> names = new HashSet<>();
    classicalProofs.forEach(proof -> names.add(proof.name()));
    for (SourceModel.ProofDeclaration proof : source.proofs()) {
      if (proof.rule().equals("inverse") || proof.rule().equals("steps")) {
        continue;
      }
      Integer circuit = circuitIds.get(proof.subject());
      Integer related = proof.relatedSubject() == null
          ? null : circuitIds.get(proof.relatedSubject());
      requireUniqueName(proof, names);
      if (circuit == null || (proof.rule().equals("equivalent") && related == null)) {
        throw new CompilerException(
            proof.line(), proof.rule() + " theorem requires declared unitary circuits");
      }
      ProofRule rule = proof.rule().equals("adjoint")
          ? ProofRule.GENERATED_ADJOINT : ProofRule.CIRCUIT_EQUIVALENCE;
      result.add(new ProofCertificate(
          result.size(), proof.name(), rule, circuit, related == null ? -1 : related));
    }
    return List.copyOf(result);
  }

  private static void requireUniqueName(
      SourceModel.ProofDeclaration proof, Set<String> names) {
    if (!names.add(proof.name())) {
      throw new CompilerException(proof.line(), "duplicate theorem: " + proof.name());
    }
  }
}
