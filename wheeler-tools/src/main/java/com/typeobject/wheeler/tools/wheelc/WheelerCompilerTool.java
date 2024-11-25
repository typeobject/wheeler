package com.typeobject.wheeler.tools.wheelc;

import com.typeobject.wheeler.compiler.CompilerOptions;
import com.typeobject.wheeler.compiler.WheelerCompiler;
import java.io.File;
import java.util.List;
import java.util.concurrent.Callable;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

@Command(
        name = "wheelc",
        description = "Compiles Wheeler source files",
        mixinStandardHelpOptions = true,
        version = "wheelc 1.0"
)
public class WheelerCompilerTool implements Callable<Integer> {

  @Option(
          names = {"--print-ast"},
          description = "Print the AST for each source file"
  )
  private boolean printAST;

  @Parameters(
          paramLabel = "FILES",
          description = "Wheeler source files to compile"
  )
  private List<File> sourceFiles;

  @Override
  public Integer call() {
    CompilerOptions options = new CompilerOptions();
    options.setPrintAST(printAST);

    WheelerCompiler compiler = new WheelerCompiler(options);

    // Process each source file
    for (File sourceFile : sourceFiles) {
      String sourcePath = sourceFile.getAbsolutePath();
      boolean success = compiler.compile(sourcePath, sourcePath);
      if (!success) {
        return 1; // Return non-zero exit code on failure
      }
    }

    return 0; // Return zero on success
  }

  public static void main(String[] args) {
    int exitCode = new CommandLine(new WheelerCompilerTool()).execute(args);
    System.exit(exitCode);
  }
}