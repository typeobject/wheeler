package com.typeobject.wheeler.packageformat;

import com.typeobject.wheeler.packageformat.PackageManifest.Dependency;
import com.typeobject.wheeler.packageformat.PackageManifest.DependencyKind;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/** Deterministic bounded backtracking resolver over immutable available releases. */
public final class PackageResolver {
  private static final int MAX_PACKAGES = 10_000;
  private static final int MAX_WORK_UNITS = 10_000;

  private final Map<String, List<PackageRelease>> available;

  public PackageResolver(Collection<PackageRelease> releases) {
    if (releases.size() > MAX_PACKAGES * 100L) {
      throw new PackageFormatException("Available package catalog is too large");
    }
    Map<String, List<PackageRelease>> grouped = new HashMap<>();
    Set<String> identities = new HashSet<>();
    for (PackageRelease release : releases) {
      String identity = release.manifest().name() + "\u0000" + release.manifest().version();
      if (!identities.add(identity)) {
        throw new PackageFormatException(
            "Catalog contains duplicate package version " + release.manifest().name()
                + " " + release.manifest().version());
      }
      grouped.computeIfAbsent(release.manifest().name(), ignored -> new ArrayList<>())
          .add(release);
    }
    Map<String, List<PackageRelease>> ordered = new TreeMap<>();
    grouped.forEach((name, candidates) -> {
      candidates.sort(Comparator
          .comparing(PackageRelease::semanticVersion)
          .reversed()
          .thenComparing(PackageRelease::archiveIdentity));
      ordered.put(name, List.copyOf(candidates));
    });
    this.available = Map.copyOf(ordered);
  }

  public PackageLock resolve(PackageManifest root, boolean includeDevelopment) {
    Map<String, List<VersionConstraint>> requirements = new TreeMap<>();
    try {
      addDependencies(requirements, root.dependencies(), includeDevelopment, root.name());
    } catch (UnsatisfiedRootCycle exception) {
      throw new PackageFormatException("Root package depends on itself");
    }
    Map<String, PackageRelease> selected = solve(
        requirements,
        new TreeMap<>(),
        includeDevelopment,
        root.name(),
        root.profile(),
        new WorkBudget(),
        0);
    if (selected == null) {
      throw new PackageFormatException(
          "No package solution for profile " + root.profile() + " and "
              + canonicalRequirements(requirements));
    }
    rejectCycles(selected, includeDevelopment);
    List<PackageLock.Entry> entries = new ArrayList<>();
    selected.forEach((name, release) -> {
      List<String> dependencies = release.manifest().dependencies().stream()
          .filter(dependency -> included(dependency.kind(), includeDevelopment))
          .map(Dependency::name)
          .sorted()
          .toList();
      entries.add(new PackageLock.Entry(
          name,
          release.manifest().version(),
          release.archiveIdentity(),
          release.manifest().identity(),
          dependencies));
    });
    return new PackageLock(PackageLock.SCHEMA_VERSION, root.identity(), entries);
  }

  private Map<String, PackageRelease> solve(
      Map<String, List<VersionConstraint>> requirements,
      Map<String, PackageRelease> selected,
      boolean includeDevelopment,
      String rootName,
      String requiredProfile,
      WorkBudget work,
      int depth) {
    work.charge();
    if (depth > MAX_PACKAGES || requirements.size() > MAX_PACKAGES) {
      throw new PackageFormatException("Dependency graph exceeds package limit");
    }
    for (Map.Entry<String, PackageRelease> entry : selected.entrySet()) {
      if (!accepts(
          requirements.getOrDefault(entry.getKey(), List.of()),
          entry.getValue(),
          requiredProfile)) {
        return null;
      }
    }
    String next = requirements.keySet().stream()
        .filter(name -> !selected.containsKey(name))
        .findFirst()
        .orElse(null);
    if (next == null) {
      return Map.copyOf(new TreeMap<>(selected));
    }
    for (PackageRelease candidate : available.getOrDefault(next, List.of())) {
      work.charge();
      if (!accepts(requirements.get(next), candidate, requiredProfile)) {
        continue;
      }
      Map<String, PackageRelease> nextSelected = new TreeMap<>(selected);
      nextSelected.put(next, candidate);
      Map<String, List<VersionConstraint>> nextRequirements = copy(requirements);
      try {
        addDependencies(
            nextRequirements,
            candidate.manifest().dependencies(),
            includeDevelopment,
            rootName);
      } catch (UnsatisfiedRootCycle exception) {
        continue;
      }
      Map<String, PackageRelease> solved = solve(
          nextRequirements,
          nextSelected,
          includeDevelopment,
          rootName,
          requiredProfile,
          work,
          depth + 1);
      if (solved != null) {
        return solved;
      }
    }
    return null;
  }

  private static void addDependencies(
      Map<String, List<VersionConstraint>> requirements,
      List<Dependency> dependencies,
      boolean includeDevelopment,
      String rootName) {
    for (Dependency dependency : dependencies) {
      if (!included(dependency.kind(), includeDevelopment)) {
        continue;
      }
      if (dependency.name().equals(rootName)) {
        throw new UnsatisfiedRootCycle();
      }
      requirements.computeIfAbsent(dependency.name(), ignored -> new ArrayList<>())
          .add(VersionConstraint.parse(dependency.constraint()));
    }
  }

  private static boolean included(DependencyKind kind, boolean includeDevelopment) {
    return kind != DependencyKind.DEVELOPMENT || includeDevelopment;
  }

  private static boolean accepts(
      List<VersionConstraint> requirements,
      PackageRelease candidate,
      String requiredProfile) {
    if (!candidate.manifest().profile().equals(requiredProfile)) {
      return false;
    }
    SemanticVersion version = candidate.semanticVersion();
    return requirements.stream().allMatch(requirement -> requirement.accepts(version));
  }

  private static Map<String, List<VersionConstraint>> copy(
      Map<String, List<VersionConstraint>> source) {
    Map<String, List<VersionConstraint>> copy = new TreeMap<>();
    source.forEach((name, values) -> copy.put(name, new ArrayList<>(values)));
    return copy;
  }

  private static void rejectCycles(
      Map<String, PackageRelease> selected, boolean includeDevelopment) {
    Set<String> complete = new HashSet<>();
    for (String name : selected.keySet()) {
      visit(name, selected, includeDevelopment, complete, new HashSet<>());
    }
  }

  private static void visit(
      String name,
      Map<String, PackageRelease> selected,
      boolean includeDevelopment,
      Set<String> complete,
      Set<String> active) {
    if (complete.contains(name)) {
      return;
    }
    if (!active.add(name)) {
      throw new PackageFormatException("Cyclic package dependency at " + name);
    }
    PackageRelease release = selected.get(name);
    if (release != null) {
      release.manifest().dependencies().stream()
          .filter(dependency -> included(dependency.kind(), includeDevelopment))
          .map(Dependency::name)
          .sorted()
          .forEach(dependency -> visit(
              dependency, selected, includeDevelopment, complete, active));
    }
    active.remove(name);
    complete.add(name);
  }

  private static String canonicalRequirements(
      Map<String, List<VersionConstraint>> requirements) {
    Map<String, List<String>> canonical = new LinkedHashMap<>();
    requirements.forEach((name, values) -> canonical.put(
        name, values.stream().map(VersionConstraint::toString).sorted().toList()));
    return canonical.toString();
  }

  /** Counts deterministic solver-state and candidate visits across the complete search. */
  private static final class WorkBudget {
    private int units;

    private void charge() {
      units++;
      if (units > MAX_WORK_UNITS) {
        throw new PackageFormatException(
            "Resolver work limit exceeded after " + MAX_WORK_UNITS + " units");
      }
    }
  }

  private static final class UnsatisfiedRootCycle extends RuntimeException {
    private static final long serialVersionUID = 1L;
  }
}
