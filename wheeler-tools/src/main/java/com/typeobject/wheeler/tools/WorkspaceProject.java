package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.packageformat.PackageFormatException;
import com.typeobject.wheeler.packageformat.WorkspaceManifest;
import com.typeobject.wheeler.packageformat.WorkspaceManifestParser;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/** Capability-minimal host adapter for one local Wheeler workspace. */
final class WorkspaceProject {
  static final String MANIFEST_NAME = "wheeler.workspace";

  private final Path root;
  private final WorkspaceManifest manifest;
  private final List<MemberProject> members;

  private WorkspaceProject(
      Path root, WorkspaceManifest manifest, List<MemberProject> members) {
    this.root = root;
    this.manifest = manifest;
    this.members = List.copyOf(members);
  }

  static boolean exists(Path requestedRoot) {
    return Files.isRegularFile(
        requestedRoot.resolve(MANIFEST_NAME), LinkOption.NOFOLLOW_LINKS);
  }

  static WorkspaceProject load(Path requestedRoot) throws IOException {
    Path root = requestedRoot.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!Files.isDirectory(root, LinkOption.NOFOLLOW_LINKS) || Files.isSymbolicLink(root)) {
      throw new IOException("Workspace root is not a physical directory: " + requestedRoot);
    }
    Path manifestPath = root.resolve(MANIFEST_NAME);
    if (!Files.isRegularFile(manifestPath, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(manifestPath)) {
      throw new IOException("Missing physical " + MANIFEST_NAME + " in " + root);
    }
    WorkspaceManifest manifest = new WorkspaceManifestParser().parse(
        Files.readAllBytes(manifestPath));
    List<MemberProject> members = new ArrayList<>();
    for (WorkspaceManifest.Member member : manifest.members()) {
      Path memberRoot = physicalMember(root, member.path());
      PackageProject project = PackageProject.load(memberRoot);
      if (!project.manifest().profile().equals(manifest.profile())) {
        throw new PackageFormatException(
            "Workspace profile " + manifest.profile() + " does not match "
                + member.name() + " profile " + project.manifest().profile());
      }
      members.add(new MemberProject(member.name(), project));
    }
    return new WorkspaceProject(root, manifest, members);
  }

  WorkspaceManifest manifest() {
    return manifest;
  }

  int targetCount() {
    return members.stream().mapToInt(
        member -> member.project().manifest().targets().size()).sum();
  }

  void check() throws IOException {
    for (MemberProject member : members) {
      member.project().check();
    }
  }

  void build(Path requestedOutput) throws IOException {
    Path output = requestedOutput.toAbsolutePath().normalize();
    Files.createDirectories(output);
    if (!Files.isDirectory(output) || Files.isSymbolicLink(output)) {
      throw new IOException("Workspace output is not a physical directory: " + output);
    }
    for (MemberProject member : members) {
      member.project().build(output.resolve(member.name()));
    }
  }

  Path defaultBuildDirectory() {
    return root.resolve("out");
  }

  private static Path physicalMember(Path root, String logicalPath) throws IOException {
    Path current = root;
    for (String component : logicalPath.split("/")) {
      current = current.resolve(component);
      if (Files.isSymbolicLink(current)) {
        throw new IOException("Workspace member crosses a symbolic link: " + logicalPath);
      }
    }
    Path resolved = current.toRealPath(LinkOption.NOFOLLOW_LINKS);
    if (!resolved.startsWith(root)
        || !Files.isDirectory(resolved, LinkOption.NOFOLLOW_LINKS)
        || Files.isSymbolicLink(resolved)) {
      throw new IOException("Workspace member is not a physical directory: " + logicalPath);
    }
    return resolved;
  }

  private record MemberProject(String name, PackageProject project) {}
}
