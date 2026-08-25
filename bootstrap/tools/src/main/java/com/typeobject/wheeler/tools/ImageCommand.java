package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.core.bytecode.BytecodeFormat;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.ElfImage;
import com.typeobject.wheeler.packageformat.MachOImage;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.packageformat.NativeImageSigningRecord;
import com.typeobject.wheeler.packageformat.PeImage;
import com.typeobject.wheeler.packageformat.PlatformAbi;
import com.typeobject.wheeler.packageformat.UnsignedNativeImageRecord;
import com.typeobject.wheeler.runtime.ApplicationCapsuleVerifier;
import com.typeobject.wheeler.runtime.LinuxX8664EntryShim;
import com.typeobject.wheeler.runtime.LinuxX8664ScalarAotCompiler;
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

/** Builds, inspects, and verifies canonical capsule and native images without execution. */
final class ImageCommand {
  private ImageCommand() {}

  static int execute(String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length < 2) {
      return usage(error);
    }
    return switch (args[1]) {
      case "inspect", "verify" -> capsule(args, out, error);
      case "runtime-elf-x86-64" -> publishLinuxRuntime(args, out, error);
      case "runtime-elf-x86-64-aot" -> publishLinuxScalarAot(args, out, error);
      case "record-elf" -> recordNativeOutput(args, out, error, NativeFormat.ELF);
      case "record-macho" -> recordNativeOutput(args, out, error, NativeFormat.MACH_O);
      case "record-pe" -> recordNativeOutput(args, out, error, NativeFormat.PE);
      case "record-signing" -> recordNativeSigning(args, out, error);
      case "build-elf" -> buildNative(args, out, error, NativeFormat.ELF);
      case "inspect-elf" -> inspectNative(args, out, error, NativeFormat.ELF);
      case "verify-elf" -> verifyNative(args, out, error, NativeFormat.ELF);
      case "build-macho" -> buildNative(args, out, error, NativeFormat.MACH_O);
      case "inspect-macho" -> inspectNative(args, out, error, NativeFormat.MACH_O);
      case "verify-macho" -> verifyNative(args, out, error, NativeFormat.MACH_O);
      case "build-pe" -> buildNative(args, out, error, NativeFormat.PE);
      case "inspect-pe" -> inspectNative(args, out, error, NativeFormat.PE);
      case "verify-pe" -> verifyNative(args, out, error, NativeFormat.PE);
      default -> usage(error);
    };
  }

  private static int publishLinuxRuntime(
      String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length != 4 || !args[2].equals("-o")) {
      return usage(error);
    }
    byte[] runtime = LinuxX8664EntryShim.runtimeText();
    Path output = Path.of(args[3]);
    PackageProject.writeAtomically(output, runtime);
    out.println("wrote x86-64 Linux entry shim " + output + " ("
        + runtime.length + " bytes, " + LinuxX8664EntryShim.runtimeIdentity() + ")");
    return 0;
  }

  private static int publishLinuxScalarAot(
      String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length != 5 || !args[3].equals("-o")) {
      return usage(error);
    }
    byte[] artifact = readPhysical(
        Path.of(args[2]), BytecodeFormat.MAX_ARTIFACT_BYTES, "portable WBC artifact");
    LinuxX8664ScalarAotCompiler.LoweredRuntime lowered =
        LinuxX8664ScalarAotCompiler.lower(artifact);
    Path output = Path.of(args[4]);
    PackageProject.writeAtomically(output, lowered.runtimeText());
    out.println("wrote x86-64 Linux scalar AOT runtime " + output + " ("
        + lowered.runtimeText().length + " bytes, " + lowered.runtimeIdentity()
        + ", WBC " + lowered.portableArtifact()
        + ", status " + lowered.processStatus()
        + (lowered.writesApplicationOutput()
            ? ", output " + lowered.applicationOutput().length + " bytes" : "")
        + ")");
    return 0;
  }

  private static int recordNativeOutput(
      String[] args,
      PrintStream out,
      PrintStream error,
      NativeFormat format) throws IOException {
    if (args.length != 9
        || !args[3].equals("--plan")
        || !args[5].equals("--abi")
        || !args[7].equals("-o")) {
      return usage(error);
    }
    byte[] image = readPhysical(
        Path.of(args[2]), format.maximumImageBytes, format.label + " image");
    NativeImagePlan plan = NativeImagePlan.parse(readPhysical(
        Path.of(args[4]), 16 * 1024, "native image plan"));
    PlatformAbi abi = PlatformAbi.parse(readPhysical(
        Path.of(args[6]), 16 * 1024, "platform ABI"));
    if (plan.format() != format.planFormat) {
      throw new IllegalArgumentException("Native output record format does not match its plan");
    }
    UnsignedNativeImageRecord record = UnsignedNativeImageRecord.from(image, plan, abi);
    Path output = Path.of(args[8]);
    PackageProject.writeAtomically(output, record.canonicalBytes());
    out.println("wrote unsigned " + format.label + " record " + output
        + " (" + record.identity() + ", PREV " + record.prev() + ")");
    return 0;
  }

  private static int recordNativeSigning(
      String[] args, PrintStream out, PrintStream error) throws IOException {
    if (args.length != 17
        || !args[3].equals("--unsigned")
        || !args[5].equals("--method")
        || !args[7].equals("--distribution")
        || !args[9].equals("--signature")
        || !args[11].equals("--signer")
        || !args[13].equals("--tool")
        || !args[15].equals("-o")) {
      return usage(error);
    }
    UnsignedNativeImageRecord unsigned = UnsignedNativeImageRecord.parse(readPhysical(
        Path.of(args[2]), UnsignedNativeImageRecord.MAX_RECORD_BYTES,
        "unsigned native image record"));
    byte[] unsignedImage = readPhysical(
        Path.of(args[4]), 64 * 1024 * 1024, "unsigned native image");
    NativeImageSigningRecord.SigningMethod method = signingMethod(args[6]);
    byte[] distribution = readPhysical(
        Path.of(args[8]), NativeImageSigningRecord.MAX_DISTRIBUTION_BYTES,
        "signed distribution artifact");
    byte[] signature = readPhysical(
        Path.of(args[10]), NativeImageSigningRecord.MAX_SIGNATURE_BYTES,
        "native image signature evidence");
    NativeImageSigningRecord record = NativeImageSigningRecord.create(
        unsigned,
        unsignedImage,
        method,
        distribution,
        signature,
        args[12],
        args[14]);
    Path output = Path.of(args[16]);
    PackageProject.writeAtomically(output, record.canonicalBytes());
    out.println("wrote native image signing record " + output
        + " (" + record.identity() + ", unsigned PREV " + record.unsignedPrev() + ")");
    return 0;
  }

  private static NativeImageSigningRecord.SigningMethod signingMethod(String value) {
    for (NativeImageSigningRecord.SigningMethod method
        : NativeImageSigningRecord.SigningMethod.values()) {
      if (method.wireName().equals(value)) {
        return method;
      }
    }
    throw new IllegalArgumentException("Unknown native image signing method " + value);
  }

  private static int capsule(String[] args, PrintStream out, PrintStream error)
      throws IOException {
    if (args.length != 3) {
      return usage(error);
    }
    ApplicationCapsule capsule = ApplicationCapsule.parse(readPhysical(
        Path.of(args[2]), ApplicationCapsule.MAX_CAPSULE_BYTES, "application capsule"));
    if (args[1].equals("inspect")) {
      out.print(render(capsule));
      return 0;
    }
    int verifiedWbc = ApplicationCapsuleVerifier.verify(capsule).programs().size();
    out.println("verified capsule " + capsule.identity()
        + " (" + capsule.entries().size() + " entries, " + verifiedWbc + " WBC artifacts)");
    return 0;
  }

  private static int buildNative(
      String[] args,
      PrintStream out,
      PrintStream error,
      NativeFormat format) throws IOException {
    if (args.length != 13
        || !args[3].equals("--runtime")
        || !args[5].equals("--entry")
        || !args[7].equals("--plan")
        || !args[9].equals("--abi")
        || !args[11].equals("-o")) {
      return usage(error);
    }
    ApplicationCapsule capsule = ApplicationCapsule.parse(readPhysical(
        Path.of(args[2]), ApplicationCapsule.MAX_CAPSULE_BYTES, "application capsule"));
    ApplicationCapsuleVerifier.verify(capsule);
    byte[] runtime = readPhysical(
        Path.of(args[4]), format.maximumRuntimeBytes, format.label + " runtime text");
    NativeImagePlan plan = NativeImagePlan.parse(readPhysical(
        Path.of(args[8]), 16 * 1024, "native image plan"));
    PlatformAbi abi = PlatformAbi.parse(readPhysical(
        Path.of(args[10]), 16 * 1024, "platform ABI"));
    int entry = nonnegativeInteger(args[6], format.label + " runtime entry");
    byte[] image = switch (format) {
      case ELF -> ElfImage.build(plan, abi, capsule, runtime, entry);
      case MACH_O -> MachOImage.build(plan, abi, capsule, runtime, entry);
      case PE -> PeImage.build(plan, abi, capsule, runtime, entry);
    };
    VerifiedNativeImage verified = verifyNativeBytes(image, plan, abi, format);
    Path output = Path.of(args[12]);
    PackageProject.writeExecutableAtomically(output, image);
    out.println("wrote " + output + " (" + image.length + " bytes, PREV "
        + verified.prev() + ")");
    return 0;
  }

  private static int inspectNative(
      String[] args,
      PrintStream out,
      PrintStream error,
      NativeFormat format) throws IOException {
    NativeInput input = nativeInput(args, error, format);
    if (input == null) {
      return 2;
    }
    VerifiedNativeImage verified = verifyNativeBytes(
        input.image(), input.plan(), input.abi(), format);
    out.print("{\n"
        + "  \"format\": " + quote(format.keyword) + ",\n"
        + "  \"prev\": " + quote(verified.prev()) + ",\n"
        + "  \"plan\": " + quote(verified.planIdentity()) + ",\n"
        + "  \"capsule\": " + quote(verified.capsule().identity()) + ",\n"
        + "  \"bytes\": " + input.image().length + ",\n"
        + "  \"runtime-bytes\": " + verified.runtimeBytes() + ",\n"
        + "  \"runtime-entry-offset\": " + verified.runtimeEntryOffset() + ",\n"
        + "  \"capsule-offset\": " + verified.capsuleOffset() + "\n"
        + "}\n");
    return 0;
  }

  private static int verifyNative(
      String[] args,
      PrintStream out,
      PrintStream error,
      NativeFormat format) throws IOException {
    NativeInput input = nativeInput(args, error, format);
    if (input == null) {
      return 2;
    }
    VerifiedNativeImage verified = verifyNativeBytes(
        input.image(), input.plan(), input.abi(), format);
    int wbc = ApplicationCapsuleVerifier.verify(verified.capsule()).programs().size();
    out.println("verified " + format.label + " " + verified.prev() + " (plan "
        + verified.planIdentity() + ", capsule " + verified.capsule().identity()
        + ", " + wbc + " WBC artifacts)");
    return 0;
  }

  private static NativeInput nativeInput(
      String[] args,
      PrintStream error,
      NativeFormat format) throws IOException {
    if (args.length != 7 || !args[3].equals("--plan") || !args[5].equals("--abi")) {
      usage(error);
      return null;
    }
    byte[] image = readPhysical(
        Path.of(args[2]), format.maximumImageBytes, format.label + " image");
    NativeImagePlan plan = NativeImagePlan.parse(readPhysical(
        Path.of(args[4]), 16 * 1024, "native image plan"));
    PlatformAbi abi = PlatformAbi.parse(readPhysical(
        Path.of(args[6]), 16 * 1024, "platform ABI"));
    return new NativeInput(image, plan, abi);
  }

  private static VerifiedNativeImage verifyNativeBytes(
      byte[] image,
      NativeImagePlan plan,
      PlatformAbi abi,
      NativeFormat format) {
    return switch (format) {
      case ELF -> {
        ElfImage.VerifiedImage verified = ElfImage.verify(image, plan, abi);
        yield new VerifiedNativeImage(
            verified.prev(),
            verified.planIdentity(),
            verified.capsule(),
            verified.runtimeText().length,
            verified.runtimeEntryOffset(),
            verified.capsuleOffset());
      }
      case MACH_O -> {
        MachOImage.VerifiedImage verified = MachOImage.verify(image, plan, abi);
        yield new VerifiedNativeImage(
            verified.prev(),
            verified.planIdentity(),
            verified.capsule(),
            verified.runtimeText().length,
            verified.runtimeEntryOffset(),
            verified.capsuleOffset());
      }
      case PE -> {
        PeImage.VerifiedImage verified = PeImage.verify(image, plan, abi);
        yield new VerifiedNativeImage(
            verified.prev(),
            verified.planIdentity(),
            verified.capsule(),
            verified.runtimeText().length,
            verified.runtimeEntryOffset(),
            verified.capsuleOffset());
      }
    };
  }

  private static byte[] readPhysical(Path path, int maximumBytes, String description)
      throws IOException {
    if (!Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(path)) {
      throw new IOException(description + " must be one bounded physical file: " + path);
    }
    Set<OpenOption> options = Set.of(StandardOpenOption.READ, LinkOption.NOFOLLOW_LINKS);
    try (SeekableByteChannel channel = Files.newByteChannel(path, options)) {
      long size = channel.size();
      if (size < 0 || size > maximumBytes) {
        throw new IOException(description + " is oversized: " + path);
      }
      ByteBuffer bytes = ByteBuffer.allocate(Math.toIntExact(size));
      while (bytes.hasRemaining() && channel.read(bytes) >= 0) {
        // The physical file owns the exact bounded read.
      }
      ByteBuffer extra = ByteBuffer.allocate(1);
      if (bytes.hasRemaining() || channel.read(extra) >= 0) {
        throw new IOException(description + " changed while being read: " + path);
      }
      return bytes.array();
    }
  }

  private static int nonnegativeInteger(String value, String description) {
    try {
      int result = Integer.parseInt(value);
      if (result < 0) {
        throw new NumberFormatException();
      }
      return result;
    } catch (NumberFormatException exception) {
      throw new IllegalArgumentException(description + " must be a nonnegative integer", exception);
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
    error.println("   or: wheeler image runtime-elf-x86-64 -o <runtime.bin>");
    error.println("   or: wheeler image runtime-elf-x86-64-aot <root.wbc>"
        + " -o <runtime.bin>");
    error.println("   or: wheeler image <record-elf|record-macho|record-pe> <application>"
        + " --plan <plan.yaml> --abi <abi.yaml> -o <unsigned-record.yaml>");
    error.println("   or: wheeler image record-signing <unsigned-record.yaml>"
        + " --unsigned <application> --method <method> --distribution <artifact>"
        + " --signature <evidence> --signer <identity> --tool <identity>"
        + " -o <signing-record.yaml>");
    error.println("   or: wheeler image <build-elf|build-macho|build-pe> <application.capsule>"
        + " --runtime <runtime.bin> --entry <offset> --plan <plan.yaml>"
        + " --abi <abi.yaml> -o <application>");
    error.println("   or: wheeler image"
        + " <inspect-elf|inspect-macho|inspect-pe|verify-elf|verify-macho|verify-pe>"
        + " <application> --plan <plan.yaml> --abi <abi.yaml>");
    return 2;
  }

  private enum NativeFormat {
    ELF(
        "elf", "ELF", PlatformAbi.Format.ELF,
        ElfImage.MAX_RUNTIME_BYTES, ElfImage.MAX_IMAGE_BYTES),
    MACH_O(
        "mach-o", "Mach-O", PlatformAbi.Format.MACH_O,
        MachOImage.MAX_RUNTIME_BYTES, MachOImage.MAX_IMAGE_BYTES),
    PE(
        "pe", "PE", PlatformAbi.Format.PE_COFF,
        PeImage.MAX_RUNTIME_BYTES, PeImage.MAX_IMAGE_BYTES);

    private final String keyword;
    private final String label;
    private final PlatformAbi.Format planFormat;
    private final int maximumRuntimeBytes;
    private final int maximumImageBytes;

    NativeFormat(
        String keyword,
        String label,
        PlatformAbi.Format planFormat,
        int maximumRuntimeBytes,
        int maximumImageBytes) {
      this.keyword = keyword;
      this.label = label;
      this.planFormat = planFormat;
      this.maximumRuntimeBytes = maximumRuntimeBytes;
      this.maximumImageBytes = maximumImageBytes;
    }
  }

  private record NativeInput(
      byte[] image,
      NativeImagePlan plan,
      PlatformAbi abi) {}

  private record VerifiedNativeImage(
      String prev,
      String planIdentity,
      ApplicationCapsule capsule,
      int runtimeBytes,
      int runtimeEntryOffset,
      int capsuleOffset) {}
}
