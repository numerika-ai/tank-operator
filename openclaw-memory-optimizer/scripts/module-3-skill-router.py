#!/usr/bin/env python3
"""
Module 3: Skill Router
Routes queries to relevant skills using keyword matching (no LLM, stdlib only).
Usage: python3 module-3-skill-router.py "query text" [skills.json]
       python3 module-3-skill-router.py --scan /path/to/skills/dir "query text"
"""

import json
import os
import re
import sys
from collections import Counter
from pathlib import Path


def extract_skill_meta(skill_dir: str) -> list[dict]:
    """Scan a directory of skills and extract name + description from SKILL.md frontmatter."""
    skills = []
    skill_path = Path(skill_dir)
    for skill_md in skill_path.rglob("SKILL.md"):
        try:
            text = skill_md.read_text(encoding="utf-8")
            # Parse YAML frontmatter
            if text.startswith("---"):
                end = text.index("---", 3)
                front = text[3:end]
                name = ""
                desc = ""
                for line in front.strip().split("\n"):
                    if line.startswith("name:"):
                        name = line.split(":", 1)[1].strip().strip('"\'')
                    elif line.startswith("description:"):
                        desc = line.split(":", 1)[1].strip().strip('"\'')
                if name:
                    skills.append({
                        "name": name,
                        "description": desc,
                        "path": str(skill_md.parent)
                    })
        except Exception:
            continue
    return skills


def tokenize(text: str) -> list[str]:
    """Simple tokenizer: lowercase, split on non-alphanumeric."""
    return [w for w in re.split(r'[^a-z0-9]+', text.lower()) if len(w) > 2]


def score_skill(query_tokens: list[str], skill: dict) -> float:
    """Score a skill against query using bag-of-words overlap."""
    skill_text = f"{skill['name']} {skill.get('description', '')}"
    skill_tokens = tokenize(skill_text)
    if not skill_tokens:
        return 0.0

    query_counter = Counter(query_tokens)
    skill_counter = Counter(skill_tokens)

    # Count overlapping tokens (weighted by frequency in query)
    overlap = 0
    for token, count in query_counter.items():
        if token in skill_counter:
            overlap += min(count, skill_counter[token])

    # Normalize by query length
    if not query_tokens:
        return 0.0
    return overlap / len(query_tokens)


def route(query: str, skills: list[dict], top_k: int = 5) -> list[dict]:
    """Route a query to the most relevant skills."""
    query_tokens = tokenize(query)
    scored = []
    for skill in skills:
        score = score_skill(query_tokens, skill)
        if score > 0:
            scored.append({**skill, "score": round(score, 3)})

    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored[:top_k]


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 module-3-skill-router.py \"query\" [skills.json]")
        print("       python3 module-3-skill-router.py --scan /path/to/skills \"query\"")
        sys.exit(1)

    # Parse args
    if sys.argv[1] == "--scan":
        if len(sys.argv) < 4:
            print("Usage: --scan /path/to/skills \"query\"")
            sys.exit(1)
        skills = extract_skill_meta(sys.argv[2])
        query = sys.argv[3]
    elif len(sys.argv) >= 3 and os.path.isfile(sys.argv[2]):
        query = sys.argv[1]
        with open(sys.argv[2]) as f:
            skills = json.load(f)
    else:
        query = sys.argv[1]
        # Try default path
        default_path = os.path.expanduser("~/.openclaw/workspace/skills.json")
        if os.path.isfile(default_path):
            with open(default_path) as f:
                skills = json.load(f)
        else:
            print("No skills.json found. Use --scan or provide path.")
            sys.exit(1)

    results = route(query, skills)

    print(f"# Skill Router Results")
    print(f"")
    print(f"**Query:** {query}")
    print(f"**Matches:** {len(results)}")
    print(f"")

    if results:
        print("| Rank | Skill | Score | Description |")
        print("|------|-------|-------|-------------|")
        for i, r in enumerate(results, 1):
            desc = r.get("description", "")[:60]
            print(f"| {i} | {r['name']} | {r['score']} | {desc} |")
    else:
        print("No matching skills found.")


if __name__ == "__main__":
    main()
