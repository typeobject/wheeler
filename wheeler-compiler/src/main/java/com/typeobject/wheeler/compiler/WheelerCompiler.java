package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.ClassicalLowerer.ClassicalContent;
import com.typeobject.wheeler.compiler.SourceModel.SourceProgram;
import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeVerifier;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Compiler for Wheeler's executable source profile. */
public final class WheelerCompiler {
  public Program compile(String source) {
    SourceProgram parsed = new SourceParser().parse(source);
    boolean classical = parsed.kind().equals("classical");
    if (classical && (!parsed.quantumRegisters().isEmpty() || !parsed.circuits().isEmpty())) {
      throw new CompilerException(1, "classical programs cannot declare qregs or circuits");
    }
    ClassicalContent classicalContent = new ClassicalLowerer().lower(parsed, classical);
    Program program = classical
        ? Program.classical(
            parsed.name(),
            classicalContent.entryId(),
            classicalContent.globals(),
            classicalContent.recordTypes(),
            classicalContent.variantTypes(),
            classicalContent.arrayTypes(),
            classicalContent.sliceTypes(),
            classicalContent.functions(),
            classicalContent.proofs())
        : new QuantumLowerer().lower(parsed, classicalContent);
    try {
      BytecodeVerifier.verify(program);
    } catch (BytecodeException exception) {
      for (SourceModel.ProofDeclaration proof : parsed.proofs()) {
        if (exception.getMessage().startsWith("Proof " + proof.name() + " failed:")) {
          throw new CompilerException(proof.line(), exception.getMessage());
        }
      }
      for (SourceModel.Function function : parsed.functions()) {
        if (exception.getMessage().startsWith(function.name() + "[")) {
          throw new CompilerException(function.line(), exception.getMessage());
        }
      }
      throw exception;
    }
    return program;
  }

  public Program compile(Path source) throws IOException {
    if (Files.size(source) > SourceLexer.MAX_SOURCE_BYTES) {
      throw new CompilerException(1, "source exceeds the 64 MiB input limit");
    }
    return compile(Files.readString(source));
  }

  public byte[] compileToBytecode(String source) {
    return new BytecodeWriter().write(compile(source));
  }

  public byte[] compileToBytecode(Path source) throws IOException {
    return new BytecodeWriter().write(compile(source));
  }
}
