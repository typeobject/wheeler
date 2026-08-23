//! Exports the verified bounded interpreter; unchecked artifacts may loiter elsewhere.

module wheeler.runtime.library;

import wheeler.runtime.artifact_execution;
import wheeler.runtime.artifact_metadata;
import wheeler.runtime.bootstrap_coverage_fragments;
import wheeler.runtime.coverage_reducer;
import wheeler.runtime.interpreter;
import wheeler.runtime.io.lifecycle;
import wheeler.runtime.io.portable;
import wheeler.runtime.io.receipts;
import wheeler.runtime.testing.runners.test_runner;
import wheeler.runtime.testing.runners.test_source_compilation;
import wheeler.runtime.testing.runners.test_source_tests;
import wheeler.runtime.testing.test_artifact_execution_identity;
import wheeler.runtime.testing.test_artifact_report;
import wheeler.runtime.testing.test_case_identity;
import wheeler.runtime.testing.test_coverage_identity;
import wheeler.runtime.testing.test_execution_identity;
import wheeler.runtime.testing.test_identity_text;
import wheeler.runtime.testing.test_package_report_identity;
import wheeler.runtime.testing.test_report_identity;
import wheeler.runtime.testing.test_report_json;
import wheeler.runtime.testing.test_shard;
import wheeler.runtime.testing.test_summary;

classical class RuntimeLibrary {}
