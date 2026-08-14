//! Propagates source-version changes through one bounded dependency graph.
classical class IncrementalDependencyGraph {
  state long sourceVersion = 0;
  state long parseVersion = 0;
  state long codeVersion = 0;
  state long linkVersion = 0;
  state long rebuilds = 0;

  /// Rebuilds each dependent node only when the source version changes.
  void updateSource(long version) {
    if (version != sourceVersion) {
      sourceVersion = version;
      parseVersion = version;
      codeVersion = version;
      linkVersion = version;
      rebuilds += 3;
    }
  }

  /// Applies two distinct updates and one duplicate notification.
  ///
  /// - Effects: Mutates only the declared graph state.
  entry void main() {
    updateSource(1);
    updateSource(1);
    updateSource(2);
    assert(sourceVersion == 2);
    assert(parseVersion == 2);
    assert(codeVersion == 2);
    assert(linkVersion == 2);
    assert(rebuilds == 6);
  }
}
