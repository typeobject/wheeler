package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Repository;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Transport;
import java.io.PrintStream;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;

/** Implements atomic ordered-repository policy updates under the XDG config root. */
final class RepositoryCommand {
  private RepositoryCommand() {}

  static int execute(String[] args, PrintStream out, PrintStream error) throws Exception {
    return execute(args, out, error, XdgPaths.system());
  }

  static int execute(
      String[] args, PrintStream out, PrintStream error, XdgPaths paths) throws Exception {
    for (String diagnostic : paths.diagnostics()) {
      error.println("wheeler: " + diagnostic);
    }
    if (args.length < 2) {
      return usage(error);
    }
    RepositoryPolicy current = RepositoryPolicyStore.load(paths);
    return switch (args[1]) {
      case "list" -> list(args, current, out, error);
      case "add" -> add(args, current, paths, out, error);
      case "remove" -> remove(args, current, paths, out, error);
      case "enable" -> enabled(args, current, paths, out, error, true);
      case "disable" -> enabled(args, current, paths, out, error, false);
      case "move" -> move(args, current, paths, out, error);
      default -> usage(error);
    };
  }

  private static int list(
      String[] args, RepositoryPolicy policy, PrintStream out, PrintStream error) {
    if (args.length != 2) {
      return usage(error);
    }
    out.print(policy.canonicalText());
    return 0;
  }

  private static int add(
      String[] args,
      RepositoryPolicy current,
      XdgPaths paths,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length < 5) {
      return usage(error);
    }
    List<String> namespaces = args.length == 5
        ? List.of("*")
        : List.copyOf(Arrays.asList(args).subList(5, args.length));
    Repository added = new Repository(
        args[2], args[3], Transport.FILE, Path.of(args[4]).toString(), true, namespaces);
    RepositoryPolicy changed = current.add(added);
    RepositoryPolicyStore.write(paths, changed);
    out.println("added repository " + added.alias() + " at position "
        + (changed.repositories().size() - 1));
    return 0;
  }

  private static int remove(
      String[] args,
      RepositoryPolicy current,
      XdgPaths paths,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length != 3) {
      return usage(error);
    }
    RepositoryPolicyStore.write(paths, current.remove(args[2]));
    out.println("removed repository " + args[2]);
    return 0;
  }

  private static int enabled(
      String[] args,
      RepositoryPolicy current,
      XdgPaths paths,
      PrintStream out,
      PrintStream error,
      boolean enabled) throws Exception {
    if (args.length != 3) {
      return usage(error);
    }
    RepositoryPolicyStore.write(paths, current.enabled(args[2], enabled));
    out.println((enabled ? "enabled" : "disabled") + " repository " + args[2]);
    return 0;
  }

  private static int move(
      String[] args,
      RepositoryPolicy current,
      XdgPaths paths,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length != 4) {
      return usage(error);
    }
    RepositoryPolicyStore.write(paths, current.moveBefore(args[2], args[3]));
    out.println("moved repository " + args[2] + " before " + args[3]);
    return 0;
  }

  private static int usage(PrintStream error) {
    error.println("Usage: wheeler repository list");
    error.println(
        "       wheeler repository add <alias> <identity> <absolute-directory> [namespace ...]");
    error.println("       wheeler repository remove <alias>");
    error.println("       wheeler repository enable|disable <alias>");
    error.println("       wheeler repository move <alias> <before-alias|last>");
    return 2;
  }
}
