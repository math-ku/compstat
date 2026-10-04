import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from urllib.parse import quote


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "check-repository-links.py"
SOURCE_URL = "https://github.com/math-ku/compstat/blob/main/slides/lecture1.qmd"


class RepositoryLinkCheckTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.repository = Path(self.temporary_directory.name)
        self.site = self.repository / "_site"
        self.site.mkdir()

    def check(self, html):
        (self.site / "index.html").write_text(html, encoding="utf-8")
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(self.site), str(self.repository)],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_existing_repository_source_link_passes(self):
        source = self.repository / "slides" / "lecture1.qmd"
        source.parent.mkdir()
        source.touch()

        result = self.check(f'<a href="{SOURCE_URL}">source</a>')

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_repository_source_link_fails(self):
        result = self.check(f'<a href="{SOURCE_URL}">source</a>')

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("slides/lecture1.qmd", result.stderr)

    def test_encoded_absolute_path_fails(self):
        source = self.repository / "lecture1.qmd"
        source.touch()
        encoded_path = quote(str(source), safe="")
        url = f"https://github.com/math-ku/compstat/blob/main/{encoded_path}"

        result = self.check(f'<a href="{url}">source</a>')

        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
