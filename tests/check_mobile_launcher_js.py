#!/usr/bin/env python3
"""Extract and syntax-check the inline JavaScript in the Vampire OS launcher."""
from html.parser import HTMLParser
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "mobile" / "experience.html"


class InlineScripts(HTMLParser):
    def __init__(self):
        super().__init__()
        self.scripts = []
        self.current = None

    def handle_starttag(self, tag, attrs):
        if tag.lower() == "script":
            attributes = dict(attrs)
            if "src" not in attributes:
                self.current = []

    def handle_data(self, data):
        if self.current is not None:
            self.current.append(data)

    def handle_endtag(self, tag):
        if tag.lower() == "script" and self.current is not None:
            self.scripts.append("".join(self.current))
            self.current = None


parser = InlineScripts()
parser.feed(SOURCE.read_text(encoding="utf-8"))
if len(parser.scripts) != 1:
    raise SystemExit(f"Expected exactly one inline launcher script, found {len(parser.scripts)}")

with tempfile.NamedTemporaryFile(mode="w", suffix=".js", encoding="utf-8") as source:
    source.write(parser.scripts[0])
    source.flush()
    subprocess.run(["node", "--check", source.name], check=True)

print("Vampire OS launcher inline JavaScript syntax passed.")
