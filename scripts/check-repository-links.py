"""Check rendered links to source files in this repository."""

import argparse
import sys
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlsplit


SOURCE_PREFIX = "https://github.com/math-ku/compstat/blob/main/"
SOURCE_PATH_PREFIX = "/math-ku/compstat/blob/main/"


class SourceLinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name == "href" and value and value.startswith(SOURCE_PREFIX):
                self.links.append(value)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("site", type=Path)
    parser.add_argument("repository", type=Path)
    args = parser.parse_args()

    html_files = sorted(args.site.rglob("*.html"))
    if not html_files:
        parser.error(f"no HTML files found in {args.site}")

    errors = []
    checked = 0
    for html_file in html_files:
        links = SourceLinkParser()
        links.feed(html_file.read_text(encoding="utf-8"))
        for url in links.links:
            checked += 1
            relative = PurePosixPath(
                unquote(urlsplit(url).path.removeprefix(SOURCE_PATH_PREFIX))
            )
            if (
                relative.is_absolute()
                or ".." in relative.parts
                or not (args.repository / relative).is_file()
            ):
                errors.append(f"{html_file}: {relative} ({url})")

    if errors:
        print("Missing repository source files:", file=sys.stderr)
        print("\n".join(errors), file=sys.stderr)
        return 1

    print(f"Checked {checked} repository source links in {len(html_files)} HTML files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
