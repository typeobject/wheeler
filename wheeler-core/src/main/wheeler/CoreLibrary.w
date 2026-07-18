//! Exports Wheeler's allocation-free core collection substrate.

//!

//! The root is entryless and intentionally dull: core code earns dependencies one reviewed

//! module at a time instead of acquiring a prelude with opinions and a mortgage.

module wheeler.core.library;
import wheeler.core.collections.fixed_longs;
import wheeler.core.collections.long_map;
import wheeler.core.collections.queue;
classical class CoreLibrary {}
