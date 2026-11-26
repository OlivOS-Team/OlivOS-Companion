#!/usr/bin/env python3
"""Summarize Flutter lcov coverage as JSON and Markdown."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def _relative_path(path: str, root: Path) -> str:
    try:
        return str(Path(path).resolve().relative_to(root.resolve()))
    except (OSError, ValueError):
        return path


def _parse_lcov(path: Path, root: Path) -> list[dict]:
    records: list[dict] = []
    current: dict | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("SF:"):
            current = {
                "file": _relative_path(line[3:], root),
                "lines": {},
                "branches": {},
                "line_total": None,
                "line_hit": None,
                "branch_total": None,
                "branch_hit": None,
            }
            continue
        if current is None:
            continue
        if line.startswith("LF:"):
            current["line_total"] = int(line[3:])
        elif line.startswith("LH:"):
            current["line_hit"] = int(line[3:])
        elif line.startswith("BRF:"):
            current["branch_total"] = int(line[4:])
        elif line.startswith("BRH:"):
            current["branch_hit"] = int(line[4:])
        elif line.startswith("DA:"):
            fields = line[3:].split(",")
            if len(fields) >= 2:
                current["lines"][int(fields[0])] = int(fields[1])
        elif line.startswith("BRDA:"):
            fields = line[5:].split(",")
            if len(fields) >= 4:
                branch_id = tuple(fields[:3])
                current["branches"][branch_id] = fields[3]
        elif line == "end_of_record":
            records.append(current)
            current = None

    if current is not None:
        records.append(current)
    return records


def _file_summary(record: dict) -> dict:
    lines = record["lines"]
    branches = record["branches"]
    line_total = record["line_total"]
    line_hit = record["line_hit"]
    if line_total is None:
        line_total = len(lines)
    if line_hit is None:
        line_hit = sum(1 for count in lines.values() if count > 0)

    branch_total = record["branch_total"]
    branch_hit = record["branch_hit"]
    if branch_total is None:
        branch_total = len(branches)
    if branch_hit is None:
        branch_hit = sum(
            1 for taken in branches.values() if taken not in ("-", "0")
        )

    missing_lines = sorted(line for line, count in lines.items() if count == 0)
    missing_branches = sum(
        1 for taken in branches.values() if taken in ("-", "0")
    )
    return {
        "covered_lines": line_hit,
        "num_statements": line_total,
        "covered_branches": branch_hit,
        "num_branches": branch_total,
        "missing_lines": len(missing_lines),
        "missing_branches": missing_branches,
        "missing_line_numbers": missing_lines,
    }


def _percentage(covered: int, total: int) -> float | None:
    if total <= 0:
        return None
    return round(covered / total * 100, 2)


def _load(lcov_path: Path, root: Path) -> dict:
    files = {}
    for record in _parse_lcov(lcov_path, root):
        files[record["file"]] = _file_summary(record)

    covered_lines = sum(item["covered_lines"] for item in files.values())
    total_lines = sum(item["num_statements"] for item in files.values())
    covered_branches = sum(item["covered_branches"] for item in files.values())
    total_branches = sum(item["num_branches"] for item in files.values())

    return {
        "totals": {
            "covered_lines": covered_lines,
            "num_statements": total_lines,
            "covered_branches": covered_branches,
            "num_branches": total_branches,
            "lines": _percentage(covered_lines, total_lines),
            "branches": _percentage(covered_branches, total_branches),
        },
        "files": {
            path: {"summary": summary} for path, summary in files.items()
        },
    }


def _markdown(data: dict) -> str:
    totals = data["totals"]
    lines = totals["lines"]
    branches = totals["branches"]
    lines_text = (
        "**{:.2f}%** ({}/{})".format(
            lines, totals["covered_lines"], totals["num_statements"]
        )
        if lines is not None
        else "-"
    )
    branches_text = (
        "**{:.2f}%** ({}/{})".format(
            branches, totals["covered_branches"], totals["num_branches"]
        )
        if branches is not None
        else "-"
    )

    report = [
        "## 测试覆盖率",
        "",
        f"- 行覆盖率：{lines_text}",
        f"- 分支覆盖率：{branches_text}",
    ]
    if branches is None:
        report.append("  - 当前 Flutter 覆盖率报告未包含分支数据。")
    report.append("")

    files = sorted(
        data["files"].items(),
        key=lambda item: item[1]["summary"]["missing_lines"],
        reverse=True,
    )
    if files:
        report.extend(
            [
                "| 文件 | 行覆盖率 | 未覆盖行 | 分支覆盖率 |",
                "| --- | ---: | ---: | ---: |",
            ]
        )
        for path, details in files[:20]:
            summary = details["summary"]
            file_lines = _percentage(
                summary["covered_lines"], summary["num_statements"]
            )
            file_branches = _percentage(
                summary["covered_branches"], summary["num_branches"]
            )
            report.append(
                "| `{}` | {} | {} | {} |".format(
                    path.replace("|", "\\|"),
                    f"{file_lines:.2f}%" if file_lines is not None else "-",
                    summary["missing_lines"],
                    f"{file_branches:.2f}%"
                    if file_branches is not None
                    else "-",
                )
            )
        if len(files) > 20:
            report.extend(["", f"另有 {len(files) - 20} 个文件未展开。"])
    else:
        report.append("没有可读取的覆盖率记录。")

    report.extend(
        [
            "",
            "HTML 报告和 `lcov.info` 可在 CI 的 `coverage` artifact 中下载。",
        ]
    )
    return "\n".join(report) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lcov", type=Path, help="flutter test --coverage output")
    parser.add_argument("--json", dest="json_path", type=Path)
    parser.add_argument("--markdown", dest="markdown_path", type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()

    if not args.lcov.is_file():
        raise SystemExit(f"coverage file not found: {args.lcov}")

    data = _load(args.lcov, args.root)
    markdown = _markdown(data)

    if args.json_path:
        args.json_path.parent.mkdir(parents=True, exist_ok=True)
        args.json_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    if args.markdown_path:
        args.markdown_path.parent.mkdir(parents=True, exist_ok=True)
        args.markdown_path.write_text(markdown, encoding="utf-8")

    print(markdown, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
