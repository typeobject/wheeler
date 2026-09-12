//! Keeps contextual reverse names out of inverse-keyword highlighting.

classical class Context {
  /// Supplies a reversible target for both inverse statement forms.
  ///
  /// - Inverse: Leaves all state unchanged.
  rev void step() {}

  /// Distinguishes the local spelling from contextual inverse keywords.
  ///
  /// - Effects: Updates a local and executes both empty inverse forms.
  entry void main() {
    long reverse = 1;
    //   ^ variable
    reverse -= 1;
    // ^ variable
    reverse step();
    // ^ keyword.control
    reverse {
      // ^ keyword.control
      step();
    }
  }
}
