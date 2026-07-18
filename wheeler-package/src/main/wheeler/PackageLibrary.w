//! Exports the bounded Wheeler package codecs and their content-identity machinery.

//!

//! Consumers import focused modules; this entryless root proves that the complete package graph

//! closes under its exact manifest and locked compiler dependency.

module wheeler.packages.library;
import wheeler.packages.archive;
import wheeler.packages.emitter;
import wheeler.packages.lock;
import wheeler.packages.plan;
import wheeler.packages.workspace;
classical class PackageLibrary {}
