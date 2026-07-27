//! Exposes the bounded Wheeler compiler as an executable package target.

module wheeler.compiler.main;

import wheeler.compiler.driver;

classical class MinimalCompiler {
  state long finalCursor = 0;
  state long codeStart = 0;
  state long verification = 0;
  state long diagnosticStage = 0;

  /// Compiles one host source into canonical caller-owned artifact bytes.
  ///
  /// - Effects: Mutates compiler state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes output) {
    Compilation compiled = compileMinimal(source, output);
    finalCursor = compiled.length;
    codeStart = compiled.codeStart;
    verification = 1;
    setOutputLength(output, compiled.length);
  }
}
