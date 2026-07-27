package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.RepositoryPolicy;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Repository;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.Transport;
import com.typeobject.wheeler.packageformat.RepositoryPolicy.TrustedKey;
import com.typeobject.wheeler.packageformat.RepositorySnapshot;
import com.typeobject.wheeler.packageformat.RepositorySnapshotSignature;
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
      case "trust" -> trust(args, current, paths, out, error);
      case "untrust" -> untrust(args, current, paths, out, error);
      case "sign" -> sign(args, current, out, error);
      case "verify" -> verify(args, current, out, error);
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
        args[2],
        args[3],
        Transport.FILE,
        Path.of(args[4]).toString(),
        true,
        namespaces,
        List.of());
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

  private static int trust(
      String[] args,
      RepositoryPolicy current,
      XdgPaths paths,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length != 4) {
      return usage(error);
    }
    byte[] encoded = PhysicalEvidenceFile.read(
        Path.of(args[3]), false, 4096, "repository public key").bytes();
    TrustedKey key = TrustedKey.from(RepositorySnapshotSignature.decodePublicKey(encoded));
    RepositoryPolicyStore.write(paths, current.trustKey(args[2], key));
    out.println("trusted repository key " + key.identity() + " for " + args[2]);
    return 0;
  }

  private static int untrust(
      String[] args,
      RepositoryPolicy current,
      XdgPaths paths,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length != 4) {
      return usage(error);
    }
    RepositoryPolicyStore.write(paths, current.untrustKey(args[2], args[3]));
    out.println("removed repository key " + args[3] + " from " + args[2]);
    return 0;
  }

  private static int sign(
      String[] args,
      RepositoryPolicy current,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length != 5) {
      return usage(error);
    }
    Repository repository = signedRepository(current, args[2]);
    var privateKey = RepositorySnapshotSignature.decodePrivateKey(
        PhysicalEvidenceFile.read(
            Path.of(args[3]), false, 4096, "repository private key").bytes());
    var publicKey = RepositorySnapshotSignature.decodePublicKey(
        PhysicalEvidenceFile.read(
            Path.of(args[4]), false, 4096, "repository public key").bytes());
    TrustedKey trusted = TrustedKey.from(publicKey);
    if (!repository.keys().contains(trusted)) {
      throw new PackageFormatException(
          "Repository public key is not trusted for " + repository.alias());
    }
    PackageRegistry registry = PackageRegistry.open(Path.of(repository.location()));
    PackageRegistry.SnapshotView view = registry.snapshot();
    RepositorySnapshot snapshot = registry.snapshotObject(view.identity());
    RepositorySnapshotSignature signature = RepositorySnapshotSignature.sign(
        repository.identity(), snapshot, privateKey, publicKey);
    signature.verify(repository.identity(), snapshot, publicKey);
    registry.writeSignature(signature);
    out.println("signed repository snapshot " + view.identity()
        + " with key " + trusted.identity());
    return 0;
  }

  private static int verify(
      String[] args,
      RepositoryPolicy current,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length != 3) {
      return usage(error);
    }
    Repository repository = signedRepository(current, args[2]);
    if (repository.keys().isEmpty()) {
      throw new PackageFormatException(
          "Repository has no trusted signing keys: " + repository.alias());
    }
    PackageRegistry registry = PackageRegistry.open(Path.of(repository.location()));
    PackageRegistry.SnapshotView view = registry.snapshot();
    RepositoryAccess.requireSnapshotAuthorization(repository, registry, view.identity());
    out.println("verified repository snapshot " + view.identity());
    return 0;
  }

  private static Repository signedRepository(RepositoryPolicy policy, String alias) {
    Repository repository = policy.require(alias);
    if (!repository.enabled() || repository.transport() != Transport.FILE) {
      throw new PackageFormatException(
          "Repository is not an enabled file transport: " + alias);
    }
    return repository;
  }

  private static int usage(PrintStream error) {
    error.println("Usage: wheeler repository list");
    error.println(
        "       wheeler repository add <alias> <identity> <absolute-directory> [namespace ...]");
    error.println("       wheeler repository remove <alias>");
    error.println("       wheeler repository enable|disable <alias>");
    error.println("       wheeler repository move <alias> <before-alias|last>");
    error.println("       wheeler repository trust <alias> <public-x509-der>");
    error.println("       wheeler repository untrust <alias> <key-identity>");
    error.println(
        "       wheeler repository sign <alias> <private-pkcs8-der> <public-x509-der>");
    error.println("       wheeler repository verify <alias>");
    return 2;
  }
}
