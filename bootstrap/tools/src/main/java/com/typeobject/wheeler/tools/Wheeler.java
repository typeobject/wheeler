package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.Disassembler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.packageformat.BuildPlan;
import com.typeobject.wheeler.packageformat.BuildPlanCodec;
import com.typeobject.wheeler.packageformat.PackageArchive;
import com.typeobject.wheeler.packageformat.PackageArchive.DecodedPackage;
import com.typeobject.wheeler.packageformat.PackageLock;
import com.typeobject.wheeler.packageformat.PackageLockParser;
import com.typeobject.wheeler.packageformat.PackageResolver;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.WheelerRuntime;
import com.typeobject.wheeler.runtime.quantum.OpenQasm3Emitter;
import com.typeobject.wheeler.runtime.quantum.QuantumTask;
import com.typeobject.wheeler.runtime.quantum.QuantumTaskBuilder;
import com.typeobject.wheeler.runtime.quantum.StateVectorTarget;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/** Unified stage-0 command for Wheeler artifacts and local packages. */
public final class Wheeler {
  private Wheeler() {}

  public static void main(String[] args) {
    try {
      int status = execute(args, System.out, System.err);
      if (status != 0) {
        System.exit(status);
      }
    } catch (Exception exception) {
      System.err.println("wheeler: " + exception.getMessage());
      System.exit(1);
    }
  }

  static int execute(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length == 0) {
      usage(error);
      return 2;
    }
    return switch (args[0]) {
      case "run" -> run(args, out, error);
      case "compile" -> compile(args, out, error);
      case "check" -> check(args, out, error);
      case "check-docs" -> DocumentationCommand.execute(
          args, System.in, out, error);
      case "docs" -> DocumentationBundleCommand.execute(args, out, error);
      case "site" -> DocumentationSiteCommand.execute(args, out, error);
      case "format" -> FormatCommand.execute(args, System.in, out, error);
      case "build" -> build(args, out, error);
      case "test" -> test(args, out, error);
      case "clean" -> clean(args, out, error);
      case "package" -> packageProject(args, out, error);
      case "verify" -> verify(args, out, error);
      case "disassemble" -> disassemble(args, out, error);
      case "qasm" -> qasm(args, out, error);
      case "resolve" -> resolve(args, out, error);
      case "verify-lock" -> verifyLock(args, out, error);
      case "vendor" -> vendor(args, out, error);
      case "publish" -> publish(args, out, error);
      case "fetch" -> fetch(args, out, error);
      case "plan" -> plan(args, out, error);
      case "verify-plan" -> verifyPlan(args, out, error);
      case "execute-plan" -> executePlan(args, out, error);
      case "manifest-artifacts" -> ArtifactSetManifest.execute(args, out, error);
      default -> {
        error.println("Unknown Wheeler command: " + args[0]);
        usage(error);
        yield 2;
      }
    };
  }

  private static int run(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length < 2) {
      return runUsage(error);
    }
    Program program;
    int option;
    Path artifact = Path.of(args[1]);
    if (Files.isRegularFile(artifact, LinkOption.NOFOLLOW_LINKS)
        && !Files.isSymbolicLink(artifact)) {
      program = new BytecodeReader().read(Files.readAllBytes(artifact));
      option = 2;
    } else if (args.length >= 4 && args[2].equals("--target")) {
      program = PackageProject.load(artifact).compileRunnable(args[3]);
      option = 4;
    } else {
      return runUsage(error);
    }

    byte[] input = null;
    boolean binaryInput = false;
    Path output = null;
    int outputBytes = -1;
    while (option < args.length) {
      if (option + 1 >= args.length) {
        return runUsage(error);
      }
      String name = args[option];
      String value = args[option + 1];
      if (name.equals("--input") && input == null) {
        input = readInput(Path.of(value));
      } else if (name.equals("--input-bytes") && input == null) {
        input = readInput(Path.of(value));
        binaryInput = true;
      } else if (name.equals("--output") && output == null) {
        output = Path.of(value);
      } else if (name.equals("--output-bytes") && outputBytes < 0) {
        outputBytes = parseOutputBytes(value);
      } else {
        return runUsage(error);
      }
      option += 2;
    }
    if ((output == null) != (outputBytes < 0)) {
      return runUsage(error);
    }

    WheelerRuntime runtime = new WheelerRuntime();
    ExecutionResult result = binaryInput
        ? runtime.executeBinaryInput(program, input, outputBytes)
        : runtime.execute(program, new StateVectorTarget(), input, outputBytes);
    if (output != null) {
      PackageProject.writeAtomically(output, result.output());
    }
    printExecution(program, result, out);
    return 0;
  }

  private static int runUsage(PrintStream error) {
    error.println("Usage: wheeler run <program.wbc>"
        + " | <package-directory> --target <target>"
        + " [--input <utf8-file> | --input-bytes <binary-file>]"
        + " [--output <file> --output-bytes <count>]");
    return 2;
  }

  private static int parseOutputBytes(String value) {
    try {
      int result = Integer.parseInt(value);
      if (result <= 0 || result > 16 * 1024 * 1024) {
        throw new NumberFormatException();
      }
      return result;
    } catch (NumberFormatException exception) {
      throw new IllegalArgumentException(
          "Output capacity must be between 1 and 16777216 bytes", exception);
    }
  }

  private static byte[] readInput(Path requested) throws Exception {
    if (!Files.isRegularFile(requested, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(requested)
        || Files.size(requested) > 16L * 1024 * 1024) {
      throw new IOException("Host input must be a physical file of at most 16 MiB: " + requested);
    }
    return Files.readAllBytes(requested);
  }

  private static void printExecution(
      Program program, ExecutionResult result, PrintStream out) {
    out.println(program.name() + " (" + program.kind().name().toLowerCase()
        + ") halted after " + result.workflowSteps() + " steps");
    result.globals().forEach((name, value) -> out.println(name + " = " + value));
    if (!result.measurements().isEmpty()) {
      out.println("measurements = " + result.measurements());
    }
  }

  private static int compile(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2 && args.length != 4) {
      error.println("Usage: wheeler compile <source.w> [-o output.wbc]");
      return 2;
    }
    Path source = Path.of(args[1]);
    Path output;
    if (args.length == 4) {
      if (!args[2].equals("-o")) {
        error.println("Expected -o before output path");
        return 2;
      }
      output = Path.of(args[3]);
    } else {
      output = replaceExtension(source, ".wbc");
    }
    byte[] bytecode = new WheelerCompiler().compileToBytecode(source);
    PackageProject.writeAtomically(output, bytecode);
    out.println("wrote " + output + " (" + bytecode.length + " bytes)");
    return 0;
  }

  private static int check(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2) {
      error.println("Usage: wheeler check <package-directory>");
      return 2;
    }
    Path root = Path.of(args[1]);
    if (WorkspaceProject.exists(root)) {
      WorkspaceProject workspace = WorkspaceProject.load(root);
      workspace.check();
      out.println("checked workspace " + workspace.manifest().name()
          + " (" + workspace.targetCount() + " targets)");
    } else {
      PackageProject project = PackageProject.load(root);
      project.check();
      out.println("checked " + project.manifest().name()
          + " " + project.manifest().version()
          + " (" + project.manifest().targets().size() + " targets)");
    }
    return 0;
  }

  private static int build(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (!packageArguments(args, error, "build")) {
      return 2;
    }
    Path root = Path.of(args[1]);
    if (WorkspaceProject.exists(root)) {
      WorkspaceProject workspace = WorkspaceProject.load(root);
      Path output = args.length == 4 ? Path.of(args[3]) : workspace.defaultBuildDirectory();
      workspace.build(output);
      out.println("built workspace " + workspace.manifest().name() + " into " + output);
    } else {
      PackageProject project = PackageProject.load(root);
      Path output = args.length == 4 ? Path.of(args[3]) : project.defaultBuildDirectory();
      project.build(output);
      out.println("built " + project.manifest().name() + " into " + output);
    }
    return 0;
  }

  private static int test(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2) {
      error.println("Usage: wheeler test <package-or-workspace-directory>");
      return 2;
    }
    Path root = Path.of(args[1]);
    TestReport report;
    String name;
    if (WorkspaceProject.exists(root)) {
      WorkspaceProject workspace = WorkspaceProject.load(root);
      report = workspace.test();
      name = "workspace " + workspace.manifest().name();
    } else {
      PackageProject project = PackageProject.load(root);
      report = project.test();
      name = project.manifest().name();
    }
    for (TestReport.CaseResult result : report.cases()) {
      out.println(result.status().name() + " " + result.packageName() + "::"
          + result.targetName() + " " + result.caseIdentity()
          + " assertions " + result.assertions()
          + (result.coverageIdentity().isEmpty() ? ""
              : " coverage " + result.coverageIdentity())
          + (result.diagnosticCode().isEmpty() ? ""
              : " " + result.diagnosticCode() + " " + result.diagnosticMessage()));
    }
    out.println("tested " + name + " (" + report.selected() + " cases, "
        + report.passed() + " passed, " + report.failed() + " failed, report "
        + report.identity() + ")");
    return report.successful() ? 0 : 1;
  }

  private static int clean(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2) {
      error.println("Usage: wheeler clean <package-or-workspace-directory>");
      return 2;
    }
    Path root = Path.of(args[1]);
    String name;
    if (WorkspaceProject.exists(root)) {
      WorkspaceProject workspace = WorkspaceProject.load(root);
      workspace.clean();
      name = "workspace " + workspace.manifest().name();
    } else {
      PackageProject project = PackageProject.load(root);
      project.clean();
      name = project.manifest().name();
    }
    out.println("cleaned " + name);
    return 0;
  }

  private static int packageProject(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (!packageArguments(args, error, "package")) {
      return 2;
    }
    PackageProject project = PackageProject.load(Path.of(args[1]));
    Path output = args.length == 4 ? Path.of(args[3]) : project.defaultArchivePath();
    byte[] archive = project.archive();
    PackageProject.writeAtomically(output, archive);
    DecodedPackage decoded = new PackageArchive().decode(archive);
    out.println("packaged " + decoded.manifest().name() + " as " + output
        + " (" + decoded.identity() + ")");
    return 0;
  }

  private static int verify(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2) {
      error.println("Usage: wheeler verify <package.wpk>");
      return 2;
    }
    DecodedPackage archive = new PackageArchive().decode(Files.readAllBytes(Path.of(args[1])));
    out.println(archive.manifest().name() + " " + archive.manifest().version()
        + " " + archive.identity());
    return 0;
  }

  private static int resolve(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length < 4) {
      resolveUsage(error);
      return 2;
    }
    Path packageRoot = Path.of(args[1]);
    Path catalog = null;
    Path output = packageRoot.resolve("wheeler.lock");
    boolean outputSpecified = false;
    boolean development = false;
    for (int index = 2; index < args.length; index++) {
      switch (args[index]) {
        case "--catalog" -> {
          if (catalog != null || index + 1 >= args.length) {
            resolveUsage(error);
            return 2;
          }
          catalog = Path.of(args[++index]);
        }
        case "-o" -> {
          if (outputSpecified || index + 1 >= args.length) {
            resolveUsage(error);
            return 2;
          }
          outputSpecified = true;
          output = Path.of(args[++index]);
        }
        case "--development" -> {
          if (development) {
            resolveUsage(error);
            return 2;
          }
          development = true;
        }
        default -> {
          error.println("Unknown resolve option: " + args[index]);
          resolveUsage(error);
          return 2;
        }
      }
    }
    if (catalog == null) {
      resolveUsage(error);
      return 2;
    }
    PackageProject project = PackageProject.load(packageRoot);
    PackageLock lock = new PackageResolver(PackageCatalog.load(catalog))
        .resolve(project.manifest(), development);
    PackageProject.writeAtomically(
        output, lock.canonicalText().getBytes(StandardCharsets.UTF_8));
    out.println("resolved " + lock.entries().size() + " packages into " + output
        + " (" + lock.identity() + ")");
    return 0;
  }

  private static int verifyLock(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2) {
      error.println("Usage: wheeler verify-lock <wheeler.lock>");
      return 2;
    }
    PackageLock lock = new PackageLockParser().parse(Files.readAllBytes(Path.of(args[1])));
    out.println("lock " + lock.entries().size() + " packages " + lock.identity());
    return 0;
  }

  private static int vendor(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 6 || !args[2].equals("--catalog") || !args[4].equals("-o")) {
      error.println(
          "Usage: wheeler vendor <wheeler.lock> --catalog <archive-directory>"
              + " -o <vendor-directory>");
      return 2;
    }
    PackageLock lock = new PackageLockParser().parse(Files.readAllBytes(Path.of(args[1])));
    int packages = PackageVendor.vendor(lock, Path.of(args[3]), Path.of(args[5]));
    out.println("vendored " + packages + " packages into " + args[5]
        + " (" + lock.identity() + ")");
    return 0;
  }

  private static int publish(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 4 || !args[2].equals("--registry")) {
      error.println("Usage: wheeler publish <package.wpk> --registry <directory>");
      return 2;
    }
    PackageRegistry registry = PackageRegistry.open(Path.of(args[3]));
    DecodedPackage published = registry.publish(Files.readAllBytes(Path.of(args[1])));
    out.println("published " + published.manifest().name() + " "
        + published.manifest().version() + " (" + published.identity() + ")");
    return 0;
  }

  private static int fetch(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 7 || !args[3].equals("--registry") || !args[5].equals("-o")) {
      error.println(
          "Usage: wheeler fetch <package> <version> --registry <directory> -o <package.wpk>");
      return 2;
    }
    byte[] bytes = PackageRegistry.open(Path.of(args[4])).fetch(args[1], args[2]);
    PackageProject.writeAtomically(Path.of(args[6]), bytes);
    DecodedPackage fetched = new PackageArchive().decode(bytes);
    out.println("fetched " + fetched.manifest().name() + " "
        + fetched.manifest().version() + " (" + fetched.identity() + ")");
    return 0;
  }

  private static int plan(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length < 2) {
      planUsage(error);
      return 2;
    }
    Path output = null;
    boolean grantRequested = false;
    for (int index = 2; index < args.length; index++) {
      switch (args[index]) {
        case "--grant-requested" -> {
          if (grantRequested) {
            planUsage(error);
            return 2;
          }
          grantRequested = true;
        }
        case "-o" -> {
          if (output != null || index + 1 >= args.length) {
            planUsage(error);
            return 2;
          }
          output = Path.of(args[++index]);
        }
        default -> {
          error.println("Unknown plan option: " + args[index]);
          planUsage(error);
          return 2;
        }
      }
    }
    WorkspaceProject workspace = WorkspaceProject.load(Path.of(args[1]));
    if (output == null) {
      output = workspace.defaultPlanPath();
    }
    BuildPlanCodec codec = new BuildPlanCodec();
    byte[] encoded = codec.encode(
        workspace.plan(Stage0CompilerIdentity.current(), grantRequested));
    PackageProject.writeAtomically(output, encoded);
    out.println("planned " + workspace.targetCount() + " targets into " + output
        + " (" + codec.identity(encoded) + ")");
    return 0;
  }

  private static int verifyPlan(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2) {
      error.println("Usage: wheeler verify-plan <wheeler.plan>");
      return 2;
    }
    byte[] encoded = Files.readAllBytes(Path.of(args[1]));
    BuildPlanCodec codec = new BuildPlanCodec();
    BuildPlan plan = codec.decode(encoded);
    out.println("plan " + plan.nodes().size() + " targets " + codec.identity(encoded));
    return 0;
  }

  private static int executePlan(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 5 || !args[3].equals("-o")) {
      error.println(
          "Usage: wheeler execute-plan <workspace-directory> <wheeler.plan> -o <output>");
      return 2;
    }
    WorkspaceProject workspace = WorkspaceProject.load(Path.of(args[1]));
    BuildPlan plan = new BuildPlanCodec().decode(Files.readAllBytes(Path.of(args[2])));
    Path output = Path.of(args[4]);
    BuildPlanExecutor.execute(workspace, plan, output);
    out.println("executed " + plan.nodes().size() + " planned targets into " + output);
    return 0;
  }

  private static int disassemble(
      String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 2) {
      error.println("Usage: wheeler disassemble <program.wbc>");
      return 2;
    }
    Program program = new BytecodeReader().read(Files.readAllBytes(Path.of(args[1])));
    out.print(new Disassembler().disassemble(program));
    return 0;
  }

  private static int qasm(String[] args, PrintStream out, PrintStream error) throws Exception {
    if (args.length != 3) {
      error.println("Usage: wheeler qasm <program.wbc> <output.qasm>");
      return 2;
    }
    Program program = new BytecodeReader().read(Files.readAllBytes(Path.of(args[1])));
    byte[] qasm = new OpenQasm3Emitter().emit(singleQuantumTask(program))
        .getBytes(StandardCharsets.UTF_8);
    PackageProject.writeAtomically(Path.of(args[2]), qasm);
    out.println("wrote " + args[2]);
    return 0;
  }

  private static QuantumTask singleQuantumTask(Program program) {
    Map<Integer, QuantumTaskBuilder> pending = new HashMap<>();
    QuantumTask result = null;
    for (var step : program.workflow()) {
      switch (step.opcode()) {
        case PREPARE -> pending.put(
            Math.toIntExact(step.first()),
            new QuantumTaskBuilder(program, Math.toIntExact(step.first()), step.second()));
        case APPLY, UNAPPLY -> {
          int circuit = Math.toIntExact(step.first());
          int register = program.quantumCircuit(circuit).registerId();
          QuantumTaskBuilder builder = pending.get(register);
          if (builder == null) {
            throw new IllegalArgumentException("Circuit is applied before register preparation");
          }
          builder.apply(circuit, step.opcode() == WorkflowOpcode.UNAPPLY);
        }
        case MEASURE -> {
          int register = Math.toIntExact(step.first());
          if (result != null || pending.get(register) == null) {
            throw new IllegalArgumentException(
                "qasm requires exactly one static quantum submission");
          }
          result = pending.remove(register).build(1, 0);
        }
        case CLASSICAL_CALL, CLASSICAL_UNCALL, EXPECT, COMMIT, HALT -> {
          // Classical workflow edges do not change the static quantum task.
        }
      }
    }
    if (result == null || !pending.isEmpty()) {
      throw new IllegalArgumentException(
          "qasm requires one complete prepare/measure quantum submission");
    }
    return result;
  }

  private static boolean packageArguments(
      String[] args, PrintStream error, String command) {
    if (args.length != 2 && args.length != 4) {
      error.println("Usage: wheeler " + command + " <package-directory> [-o output]");
      return false;
    }
    if (args.length == 4 && !args[2].equals("-o")) {
      error.println("Expected -o before output path");
      return false;
    }
    return true;
  }

  private static Path replaceExtension(Path source, String extension) {
    String name = source.getFileName().toString();
    int dot = name.lastIndexOf('.');
    String base = dot < 0 ? name : name.substring(0, dot);
    return source.resolveSibling(base + extension);
  }

  private static void resolveUsage(PrintStream error) {
    error.println(
        "Usage: wheeler resolve <package-directory> --catalog <archive-directory>"
            + " [-o wheeler.lock] [--development]");
  }

  private static void planUsage(PrintStream error) {
    error.println(
        "Usage: wheeler plan <workspace-directory>"
            + " [--grant-requested] [-o wheeler.plan]");
  }

  private static void usage(PrintStream error) {
    error.println(
        "Usage: wheeler <run|compile|check|check-docs|docs|site|format|build|test|clean|package|verify|resolve|verify-lock|vendor|"
            + "publish|fetch|plan|verify-plan|execute-plan|manifest-artifacts|"
            + "disassemble|qasm> ...");
  }
}
