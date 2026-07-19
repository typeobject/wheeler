//! Exports the bounded compiler, verifier, and scanner as one entryless dependency graph.

module wheeler.compiler.library;

import wheeler.compiler.codegen;
import wheeler.compiler.parser;
import wheeler.compiler.string_table;
import wheeler.compiler.verifier;

classical class CompilerLibrary {}
