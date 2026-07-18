//! Exports the bounded Wheeler compiler, verifier, interpreter, scanner, and binary substrate.

//!

//! This root gives the package one closed entryless module graph. Consumers still import the

//! focused module they need; dragging in this aggregator would be poor dependency hygiene.

module wheeler.compiler.library;
import wheeler.compiler.codegen;
import wheeler.compiler.parser;
import wheeler.compiler.string_table;
import wheeler.compiler.verifier;
classical class CompilerLibrary {}
