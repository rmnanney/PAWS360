#!/usr/bin/env python3
"""
Parse git history and generate CONTRIBUTOR_WORK_HISTORY.md
"""

import subprocess
import sys
import os
from collections import defaultdict, Counter
from datetime import datetime
import re

REPO_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_FILE = os.path.join(REPO_PATH, "CONTRIBUTOR_WORK_HISTORY.md")

GIT_LOG_CMD = [
    "git",
    "-C",
    REPO_PATH,
    "log",
    "--all",
    "--pretty=format:===COMMIT===%n%H|%an|%ae|%ad|%s",
    "--date=short",
    "--name-only",
]


def run(cmd):
    return subprocess.check_output(cmd, text=True, encoding="utf-8", errors="ignore")


def parse_git_log(output):
    authors = defaultdict(lambda: {
        "names": Counter(),
        "email": None,
        "commits": 0,
        "first_commit": None,
        "last_commit": None,
        "files": set(),
        "folders": Counter(),
        "messages": Counter(),
        "extensions": Counter(),
        "features": Counter(),
    })

    total_commits = 0

    for section in output.split("===COMMIT==="):
        section = section.strip()
        if not section:
            continue
        lines = section.splitlines()
        header = lines[0]
        files = [l.strip() for l in lines[1:] if l.strip()]
        try:
            commit_hash, author_name, author_email, date_str, message = header.split("|", 4)
            # normalize email and group by it to avoid duplicate entries for different name spellings
            email_match = re.search(r"[\w.+\-]+@[\w.\-]+\.[\w]+", author_email)
            if email_match:
                author_key = email_match.group(0).lower()
            else:
                author_key = author_email.strip().lower().rstrip('.')
        except ValueError:
            # header doesn't match pattern; skip
            continue
        total_commits += 1
        a = authors[author_key]
        # record name frequency
        a['names'][author_name] += 1
        a["email"] = author_key
        a["commits"] += 1
        date = datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
        if a["first_commit"] is None or date < a["first_commit"]:
            a["first_commit"] = date
        if a["last_commit"] is None or date > a["last_commit"]:
            a["last_commit"] = date
        if message:
            a["messages"][message] += 1
            # detect likely feature/implementation messages
            msg_l = message.lower()
            # expanded keyword list (conventional commits and common verbs)
            feature_keywords = [
                "feat:", "feature", "implement", "implemented", "implementing",
                "add", "added", "adding", "create", "created", "creating",
                "backend for", "frontend", "api", "endpoint", "connect", "connected",
                "integrate", "integrated", "migrate", "migrated", "support", "enable",
                "introduce", "introducing", "initial push", "initial commit", "entities",
                "wire", "setup", "setup", "configure", "integration", "hookup", "connect",
                "transcript", "advising", "finances", "login", "authentication", "auth",
            ]

            # detect JIRA/SCRUM IDs (e.g. SCRUM-123 or PROJ-456) and include them in features
            jira_match = re.findall(r"(SCRUM|JIRA|PROJ|T)\-?\d+", message, flags=re.I)

            matched = any(k in msg_l for k in feature_keywords)
            if matched:
                short = message.strip()
                if len(short) > 120:
                    short = short[:117] + "..."
                if jira_match:
                    short = ("[" + ",".join(sorted(set(jira_match))) + "] ") + short
                a["features"][short] += 1
            else:
                # if message didn't match feature keywords, attempt to infer feature from files touched
                if files:
                    # collect top-level areas touched in this commit
                    areas = []
                    for f in files:
                        if not f:
                            continue
                        top = f.split('/')[0]
                        areas.append(top)
                    areas = [a0 for a0 in dict.fromkeys(areas) if a0]
                    if areas:
                        short = "Touched areas: " + ", ".join(areas[:6])
                        # append a short sample file to hint at area
                        sample = files[0]
                        short = short + " (e.g. " + sample + ")"
                        a["features"][short] += 1
        for f in files:
            if not f:
                continue
            a["files"].add(f)
            folder = os.path.dirname(f) or "."
            a["folders"][folder] += 1
            _, ext = os.path.splitext(f)
            if ext:
                a["extensions"][ext] += 1

    return authors, total_commits


def format_author_summary(data):
    name = data.get('names').most_common(1)[0][0] if data.get('names') else 'unknown'
    lines = []
    lines.append(f"### {name}  ")

    # Priority 1: Key functionality introduced
    top_features = data.get('features').most_common(8)
    if top_features:
        lines.append(f"- Key functionality introduced:")
        for feat, cnt in top_features:
            lines.append(f"  - {feat} — {cnt} commit{'s' if cnt!=1 else ''}")
        lines.append("")

    # contact and activity
    lines.append(f"- Email: `{data['email']}`  ")
    lines.append(f"- Commits: **{data['commits']}**  ")
    lines.append(f"- Active: {data['first_commit']} → {data['last_commit']}  ")

    # Top folders
    top_folders = data['folders'].most_common(6)
    if top_folders:
        lines.append(f"- Top areas edited:")
        for folder, count in top_folders:
            lines.append(f"  - `{folder}` — {count} commits")

    # Top file extensions
    top_exts = data['extensions'].most_common(6)
    if top_exts:
        lines.append(f"- Common file types:")
        for ext, count in top_exts:
            lines.append(f"  - `{ext}` — {count} files")

    # sample messages
    sample_msgs = [m for m, _ in data['messages'].most_common(6)]
    if sample_msgs:
        lines.append(f"- Example commit messages:")
        for m in sample_msgs:
            lines.append(f"  - {m}")

    lines.append("\n")
    return "\n".join(lines)


def generate_markdown(authors, total_commits):
    header = [
        "# Contributor Work History\n",
        f"Generated on: {datetime.utcnow().date()}\n",
        f"Total commits parsed: **{total_commits}**\n",
        f"Total contributors: **{len(authors)}**\n",
        "\n---\n",
        "\n> *Note: This file is auto-generated by `scripts/generate_contributor_summary.py` using `git log --all`.\n> Grouping is done by author email; duplicate emails or names are merged accordingly.*\n",
    ]

    # Sort authors by commit count
    sorted_auths = sorted(authors.items(), key=lambda kv: kv[1]['commits'], reverse=True)

    for _, data in sorted_auths:
        header.append(format_author_summary(data))

    return "\n".join(header)


def main():
    print("Running git log -- this may take a moment...")
    output = run(GIT_LOG_CMD)
    authors, total_commits = parse_git_log(output)
    md = generate_markdown(authors, total_commits)

    with open(OUT_FILE, 'w', encoding='utf-8') as f:
        f.write(md)

    print(f"Generated contributor summary at: {OUT_FILE}")


if __name__ == '__main__':
    main()
