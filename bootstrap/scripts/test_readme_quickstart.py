"""Check quickstart fence selection and final-output matching without launching a build."""

import importlib.util
from pathlib import Path
import unittest


SPEC = importlib.util.spec_from_file_location(
    "readme_quickstart", Path(__file__).with_name("check-readme-quickstart.py")
)
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class QuickstartContractTest(unittest.TestCase):
    def test_selects_one_named_nonempty_fence(self):
        fence = "<!-- command -->\n```bash\n./bootstrap/gradlew\n```"
        self.assertEqual("./bootstrap/gradlew", CHECK.fenced_section(fence, "command", "bash"))
        for invalid in ["", fence + "\n" + fence, fence.replace("./bootstrap/gradlew", "")]:
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                CHECK.fenced_section(invalid, "command", "bash")

    def test_checks_complete_final_lines_after_wrapper_progress(self):
        expected = ["example halted", "value = 0"]
        self.assertTrue(CHECK.final_output_matches("example halted\nvalue = 0\n", expected))
        self.assertTrue(CHECK.final_output_matches(
            "Downloading Gradle\nexample halted\nvalue = 0\n", expected
        ))
        for output in [
            "",
            "example halted\n",
            "example halted\nvalue = 1\n",
            "example halted\nvalue = 0\ntrailing output\n",
        ]:
            with self.subTest(output=output):
                self.assertFalse(CHECK.final_output_matches(output, expected))
        self.assertFalse(CHECK.final_output_matches("", []))


if __name__ == "__main__":
    unittest.main()
