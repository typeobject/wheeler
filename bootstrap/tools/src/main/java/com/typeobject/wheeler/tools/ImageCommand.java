package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.runtime.ApplicationCapsuleVerifier;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.ByteBuffer;
import java.nio.channels.SeekableByteChannel;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.List;
import java.util.Set;

/** Inspects and verifies canonical application capsules without executing them. */
final class ImageCommand {
  private ImageCommand() {}

  static int execute(String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length != 3 || !args[1].equals("inspect") && !args[1].equals("verify")) {
      return usage(error);
    }
    Path path = Path.of(args[2]);
    ApplicationCapsule capsule = ApplicationCapsule.parse(readCapsule(path));
    if (args[1].equals("inspect")) {
      out.print(render(capsule));
      return 0;
    }
    int verifiedWbc = ApplicationCapsuleVerifier.verify(capsule).programs().size();
    out.println("verified capsule " + capsule.identity()
        + " (" + capsule.entries().size() + " entries, " + verifiedWbc + " WBC artifacts)");
    return 0;
  }

  private static byte[] readCapsule(Path path) throws IOException {
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(path)) {
      throw new IOException(
          "Application capsule must be one bounded physical file: " + path);
    }
    Set<OpenOption> options = Set.of(StandardOpenOption.READ, LinkOption.NOFOLLOW_LINKS);
    try (SeekableByteChannel channel = Files.newByteChannel(path, options)) {
      long size = channel.size();
      if (size < 0 || size > ApplicationCapsule.MAX_CAPSULE_BYTES) {
        throw new IOException("Application capsule is oversized: " + path);
      }
      ByteBuffer bytes = ByteBuffer.allocate(Math.toIntExact(size));
      while (bytes.hasRemaining() && channel.read(bytes) >= 0) {
        // The physical file owns the exact bounded read.
      }
      ByteBuffer extra = ByteBuffer.allocate(1);
      if (bytes.hasRemaining() || channel.read(extra) >= 0) {
        throw new IOException("Application capsule changed while being read: " + path);
      }
      return bytes.array();
    }
  }

  private static String render(ApplicationCapsule capsule) {
    CapsuleRoot root = capsule.root();
    StringBuilder output = new StringBuilder();
    output.append("{\n")
        .append("  \"schema\": 1,\n")
        .append("  \"identity\": ").append(quote(capsule.identity())).append(",\n")
        .append("  \"bytes\": ").append(capsule.canonicalBytes().length).append(",\n")
        .append("  \"root\": {\n")
        .append("    \"package-instance\": ").append(quote(root.packageInstance())).append(",\n")
        .append("    \"target\": ").append(quote(root.target())).append(",\n")
        .append("    \"wbc\": ").append(quote(root.rootWbc())).append(",\n")
        .append("    \"entry\": ").append(quote(root.entryFunction())).append(",\n")
        .append("    \"runtime-mode\": ").append(quote(root.runtimeMode().wireName())).append(",\n")
        .append("    \"runtime-profile\": ").append(quote(root.runtimeProfile())).append(",\n")
        .append("    \"bytecode-profile\": ").append(quote(root.bytecodeProfile())).append(",\n")
        .append("    \"proof-profile\": ").append(quote(root.proofProfile())).append(",\n")
        .append("    \"target-profile\": ").append(quote(root.targetProfile())).append(",\n")
        .append("    \"platform-abi\": ").append(quote(root.platformAbi())).append(",\n")
        .append("    \"execution-limits\": ").append(quote(root.executionLimits())).append(",\n")
        .append("    \"capabilities\": ");
    appendStrings(output, root.requiredCapabilities());
    output.append("\n  },\n  \"receipts\": [");
    for (int index = 0; index < capsule.receipts().size(); index++) {
      CapsulePackageReceipt receipt = capsule.receipts().get(index);
      output.append(index == 0 ? "\n" : ",\n")
          .append("    {\"coordinate\": ").append(quote(receipt.coordinate()))
          .append(", \"variant\": ").append(quote(receipt.variant()))
          .append(", \"instance\": ").append(quote(receipt.instance()))
          .append(", \"repository-snapshot\": ").append(quote(receipt.repositorySnapshot()))
          .append(", \"rrev\": ").append(quote(receipt.rrev()))
          .append(", \"build-input\": ").append(quote(receipt.buildInput()))
          .append(", \"prev\": ").append(quote(receipt.prev()))
          .append(", \"selected-export\": ").append(quote(receipt.selectedExport()))
          .append('}');
    }
    output.append("\n  ],\n  \"entries\": [");
    for (int index = 0; index < capsule.entries().size(); index++) {
      CapsuleEntry entry = capsule.entries().get(index);
      output.append(index == 0 ? "\n" : ",\n")
          .append("    {\"kind\": ").append(quote(keyword(entry.kind())))
          .append(", \"name\": ").append(quote(entry.name()))
          .append(", \"identity\": ").append(quote(entry.identity()))
          .append(", \"bytes\": ").append(entry.bytes().length)
          .append(", \"alignment\": ").append(entry.alignment())
          .append(", \"flags\": ").append(entry.flags()).append('}');
    }
    return output.append("\n  ]\n}\n").toString();
  }

  private static void appendStrings(StringBuilder output, List<String> values) {
    output.append('[');
    for (int index = 0; index < values.size(); index++) {
      if (index > 0) {
        output.append(", ");
      }
      output.append(quote(values.get(index)));
    }
    output.append(']');
  }

  private static String quote(String value) {
    StringBuilder result = new StringBuilder(value.length() + 2).append('"');
    value.codePoints().forEach(codePoint -> {
      switch (codePoint) {
        case '"' -> result.append("\\\"");
        case '\\' -> result.append("\\\\");
        case '\b' -> result.append("\\b");
        case '\f' -> result.append("\\f");
        case '\n' -> result.append("\\n");
        case '\r' -> result.append("\\r");
        case '\t' -> result.append("\\t");
        default -> {
          if (codePoint < 0x20) {
            result.append("\\u%04x".formatted(codePoint));
          } else {
            result.appendCodePoint(codePoint);
          }
        }
      }
    });
    return result.append('"').toString();
  }

  private static String keyword(CapsuleEntry.Kind kind) {
    return switch (kind) {
      case WBC -> "wbc";
      case RESOURCE -> "resource";
      case PROOF -> "proof";
      case NATIVE_PROVIDER -> "native-provider";
      case PROVENANCE -> "provenance";
    };
  }

  private static int usage(PrintStream error) {
    error.println("Usage: wheeler image <inspect|verify> <application.capsule>");
    return 2;
  }
}
