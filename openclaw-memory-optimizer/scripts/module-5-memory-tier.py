#!/usr/bin/env python3
"""
Module 5: Memory Tier Manager
Classifies memory entries into hot/warm/cold based on importance × recency.
Usage: python3 module-5-memory-tier.py /path/to/workspace [--apply]
Default: --dry-run (report only)
"""

import os
import sys
from datetime import datetime, timedelta
from pathlib import Path


def get_file_age_days(filepath: str) -> float:
    """Get file age in days based on modification time."""
    mtime = os.path.getmtime(filepath)
    age = datetime.now() - datetime.fromtimestamp(mtime)
    return age.total_seconds() / 86400


def classify_tier(age_days: float, size_bytes: int, is_today: bool, is_yesterday: bool) -> str:
    """Classify a memory file into hot/warm/cold tier."""
    if is_today or is_yesterday:
        return "HOT"
    elif age_days <= 7:
        return "WARM"
    elif age_days <= 30:
        return "COLD"
    else:
        return "ARCHIVE"


def scan_memory(workspace: str) -> list[dict]:
    """Scan memory directory and classify files."""
    memory_dir = Path(workspace) / "memory"
    entries = []

    if not memory_dir.exists():
        return entries

    today = datetime.now().strftime("%Y-%m-%d")
    yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")

    for md_file in sorted(memory_dir.glob("*.md")):
        name = md_file.stem
        size = md_file.stat().st_size
        age = get_file_age_days(str(md_file))
        is_today = name == today
        is_yest = name == yesterday
        tier = classify_tier(age, size, is_today, is_yest)

        entries.append({
            "file": md_file.name,
            "size": size,
            "age_days": round(age, 1),
            "tier": tier,
            "load_at_boot": tier == "HOT",
        })

    return entries


def scan_workspace_files(workspace: str) -> list[dict]:
    """Scan workspace-level memory files."""
    ws = Path(workspace)
    files = []

    memory_md = ws / "MEMORY.md"
    if memory_md.exists():
        files.append({
            "file": "MEMORY.md",
            "size": memory_md.stat().st_size,
            "tier": "WARM",
            "note": "Load in main session only",
            "load_at_boot": False,
        })

    return files


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 module-5-memory-tier.py /path/to/workspace [--apply]")
        sys.exit(1)

    workspace = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "--dry-run"

    entries = scan_memory(workspace)
    ws_files = scan_workspace_files(workspace)

    total_size = sum(e["size"] for e in entries)
    hot_size = sum(e["size"] for e in entries if e["tier"] == "HOT")
    warm_size = sum(e["size"] for e in entries if e["tier"] == "WARM")
    cold_size = sum(e["size"] for e in entries if e["tier"] in ("COLD", "ARCHIVE"))

    print("# Memory Tier Report")
    print("")
    print(f"**Workspace:** `{workspace}`")
    print(f"**Mode:** {mode}")
    print(f"**Date:** {datetime.now().isoformat()}")
    print("")

    # Daily memory files
    if entries:
        print("## Daily Memory Files")
        print("")
        print("| File | Size | Age (days) | Tier | Boot? |")
        print("|------|------|-----------|------|-------|")
        for e in entries:
            boot = "✅" if e["load_at_boot"] else "—"
            print(f"| {e['file']} | {e['size']}B | {e.get('age_days', '—')} | {e['tier']} | {boot} |")
        print("")

    # Workspace memory files
    if ws_files:
        print("## Workspace Memory Files")
        print("")
        for f in ws_files:
            print(f"- **{f['file']}**: {f['size']}B — {f['tier']} ({f.get('note', '')})")
        print("")

    # Summary
    print("## Summary")
    print("")
    print(f"- **Total memory:** {total_size}B across {len(entries)} daily files")
    print(f"- **HOT (load at boot):** {hot_size}B ({len([e for e in entries if e['tier'] == 'HOT'])} files)")
    print(f"- **WARM (on-demand):** {warm_size}B ({len([e for e in entries if e['tier'] == 'WARM'])} files)")
    print(f"- **COLD/ARCHIVE:** {cold_size}B ({len([e for e in entries if e['tier'] in ('COLD', 'ARCHIVE')])} files)")
    print("")

    if total_size > 0:
        boot_pct = (hot_size / total_size * 100) if total_size else 0
        print(f"**Boot load ratio:** {boot_pct:.0f}% of memory loaded at start")
    print("")

    print("## Recommendations")
    print("")
    if cold_size > 50000:
        print("- 🔴 Large cold archive. Consider consolidating old daily notes into MEMORY.md")
    if hot_size > 10000:
        print("- 🟡 Hot tier is large. Review today/yesterday notes for unnecessary detail")
    if not ws_files:
        print("- 💡 No MEMORY.md found. Create one for curated long-term memory (main session only)")
    print("- Load only HOT tier at boot. Access WARM/COLD via memory_recall or explicit read")


if __name__ == "__main__":
    main()
