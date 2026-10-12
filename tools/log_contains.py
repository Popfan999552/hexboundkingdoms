#!/usr/bin/env python3
"""Portable text-log matching; CI runners need only Python, not ripgrep."""
from pathlib import Path
import re,sys
text=Path(sys.argv[2]).read_text(errors='replace')
raise SystemExit(0 if re.search(sys.argv[1],text,re.MULTILINE) else 1)
