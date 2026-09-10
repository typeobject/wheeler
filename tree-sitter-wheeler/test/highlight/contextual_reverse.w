//! Keeps contextual reverse names out of inverse-keyword highlighting.

classical class Context {
  rev void step() {}

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
