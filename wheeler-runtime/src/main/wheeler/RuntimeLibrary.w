//! Exports the bounded Wheeler-native canonical-bytecode interpreter.

//!

//! Verification remains a dependency rather than a suggestion: callers cannot import the

//! transition loop while quietly leaving artifact checks in another postcode.

module wheeler.runtime.library;
import wheeler.runtime.interpreter;
classical class RuntimeLibrary {}
