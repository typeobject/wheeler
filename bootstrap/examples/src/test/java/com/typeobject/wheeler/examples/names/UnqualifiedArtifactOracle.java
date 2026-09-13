package com.typeobject.wheeler.examples.names;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.proof.ProofCertificate;

/** Removes only an oracle module's semantic name prefix, preserving code and descriptors. */
public final class UnqualifiedArtifactOracle {
  private UnqualifiedArtifactOracle() {}

  /** Retains every artifact field except the selected callable and proof name qualifiers. */
  public static Program withoutModule(Program qualified, String module) {
    var functions = qualified.functions().stream().map(function -> new FunctionBody(
        function.id(), unqualify(function.name(), module), function.coherent(), function.parameterCount(),
        function.localTypes(), function.resultType(), function.implicitResultSlot(),
        function.forward(), function.inverse())).toList();
    var proofs = qualified.proofCertificates().stream().map(proof -> new ProofCertificate(
        proof.id(), unqualify(proof.name(), module), proof.rule(), proof.subjectId(), proof.argument())).toList();
    return new Program(qualified.name(), qualified.kind(), qualified.entryFunctionId(), qualified.globals(),
        qualified.recordTypes(), qualified.variantTypes(), qualified.arrayTypes(), qualified.sliceTypes(),
        functions, proofs, qualified.quantumRegisters(), qualified.quantumCircuits(), qualified.workflow(),
        qualified.requiredInstructionExtensions(), qualified.maxHistoryRecords(), qualified.maxSteps());
  }

  private static String unqualify(String name, String module) {
    String prefix = module + "::";
    return name.startsWith(prefix) ? name.substring(prefix.length()) : name;
  }
}
