//! Exports the verified bounded interpreter; unchecked artifacts may loiter elsewhere.

module wheeler.runtime.library;

import wheeler.runtime.bootstrap_coverage_fragments;
import wheeler.runtime.coverage_reducer;
import wheeler.runtime.interpreter;
import wheeler.runtime.io.lifecycle;
import wheeler.runtime.io.portable;
import wheeler.runtime.io.receipts;

classical class RuntimeLibrary {}
