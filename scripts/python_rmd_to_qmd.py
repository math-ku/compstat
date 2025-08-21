import re
import sys


def is_list_item(line):
    stripped = line.strip()
    return (
        stripped.startswith("- ")
        or stripped.startswith("* ")
        or re.match(r"^\d+\.\s", stripped)
    )


def keep_only_title_in_yaml(lines, new_title=None):
    out = []
    in_yaml = False
    yaml_lines = []
    yaml_end = None
    for i, line in enumerate(lines):
        if i == 0 and line.strip() == "---":
            in_yaml = True
            yaml_lines.append(line)
            continue
        if in_yaml:
            if line.strip() == "---":
                yaml_end = i
                break
            yaml_lines.append(line)
        else:
            break
    # Extract title
    title = None
    for l in yaml_lines:
        m = re.match(r"\s*title\s*:\s*(.*)", l)
        if m:
            title = m.group(1).strip()
            break
    if new_title is not None:
        title = new_title
    # Compose new YAML
    out.append("---\n")
    if title:
        out.append(f"title: {title}\n")
    out.append("---\n")
    # Add rest of lines after YAML
    if yaml_end is not None:
        out.extend(lines[yaml_end + 1 :])
    else:
        out.extend(lines)
    return out


def fix_r_file_paths(lines):
    # Replace file.path(...) and read_table("data/xxx") with here::here(...)
    out = []
    for line in lines:
        # Replace file.path("data", ...) or file.path("images", ...) with here::here(...)
        line = re.sub(
            r'file\.path\((["\'](?:data|images)["\'],\s*[^)]*)\)',
            r"here::here(\1)",
            line,
        )
        # Replace read_table("data/xxx") or read_csv("data/xxx") with read_table(here::here("data", "xxx"))
        line = re.sub(
            r'(read_table|read_csv|read_delim)\(\s*["\'](data|images)/([^"\']+)["\']',
            r'\1(here::here("\2", "\3")',
            line,
        )
        # Replace source("R/xxx.R"...) with source(here::here("R/xxx.R")...)
        line = re.sub(
            r'source\((["\']R/[^"\']+["\'])',
            r"source(here::here(\1)",
            line,
        )
        out.append(line)
    return out


def fix_md_image_paths(lines):
    # Only replace in markdown image links
    out = []
    for line in lines:
        # Replace images/ or data/ with ../images/ or ../data/ in markdown image links
        line = re.sub(r"!\[([^\]]*)\]\((images/)", r"![\1](../images/", line)
        line = re.sub(r"!\[([^\]]*)\]\((data/)", r"![\1](../data/", line)
        out.append(line)
    return out


def remove_knitr_setup(lines):
    out = []
    n = len(lines)
    i = 0
    while i < n:
        # Remove knitr::knit_hooks$set(crop = knitr::hook_pdfcrop)
        if "knitr::knit_hooks$set(crop = knitr::hook_pdfcrop)" in lines[i]:
            i += 1
            continue
        # Remove knitr::opts_chunk$set( ... )
        if re.match(r"\s*knitr::opts_chunk\$set\s*\(", lines[i]):
            i += 1
            # Skip all lines until a line that contains only ')' (possibly with whitespace)
            while i < n and not re.match(r"^\s*\)\s*$", lines[i]):
                i += 1
            # Skip the closing parenthesis line as well
            i += 1
            continue
        out.append(lines[i])
        i += 1
    return out


def process_lines(lines):
    out = []
    n = len(lines)
    i = 0
    while i < n:
        line = lines[i]
        if line.strip() == "--":
            prev = lines[i - 1] if i > 0 else ""
            next = lines[i + 1] if i + 1 < n else ""
            if is_list_item(prev) or is_list_item(next):
                # Remove -- between list items
                i += 1
                continue
            elif prev.strip() == "" and next.strip() == "":
                # Replace -- surrounded by blank lines with . . .
                out.append(". . .\n")
                i += 1
                continue
        out.append(line)
        i += 1
    return out


def compact_lists(lines):
    out = []
    n = len(lines)
    i = 0
    while i < n:
        line = lines[i]
        out.append(line)
        # If this is a list item and the next line is blank and the line after that is a list item, skip the blank line
        if is_list_item(line):
            if i + 2 < n and lines[i + 1].strip() == "" and is_list_item(lines[i + 2]):
                i += 1  # skip the blank line
        i += 1
    return out


def is_left_column(line):
    return line.strip() in (".pull-left[", ".two-column-left[")


def is_right_column(line):
    return line.strip() in (".pull-right[", ".two-column-right[")


def is_slide_break(line):
    return line.strip() in ("--", ". . .")


def collect_block(lines, start):
    content = []
    i = start
    while i < len(lines) and lines[i].strip() != "]":
        content.append(lines[i])
        i += 1
    return content, i + 1 if i < len(lines) else i


def convert_pull_columns(lines):
    out = []
    i = 0
    n = len(lines)
    left_block = None
    while i < n:
        if is_left_column(lines[i]):
            left_content, next_i = collect_block(lines, i + 1)
            left_block = left_content
            i = next_i
            # Skip any slide breaks or blank lines between columns
            while i < n and (is_slide_break(lines[i]) or lines[i].strip() == ""):
                i += 1
            # If next is right column, handle as pair
            if i < n and is_right_column(lines[i]):
                right_content, next_i = collect_block(lines, i + 1)
                out.append(":::: {.columns}\n\n")
                out.append('::: {.column width="50%"}\n')
                out.extend(left_block)
                out.append("\n:::\n")
                out.append('\n::: {.column width="50%"}\n')
                out.extend(right_content)
                out.append("\n:::\n")
                out.append("\n::::\n\n")
                left_block = None
                i = next_i
            else:
                # No right column follows, flush left as single column
                out.append(":::: {.columns}\n\n")
                out.append('::: {.column width="50%"}\n')
                out.extend(left_block)
                out.append("\n:::\n")
                out.append('\n::: {.column width="50%"}\n')
                out.append("\n:::\n")
                out.append("\n::::\n\n")
                left_block = None
        elif is_right_column(lines[i]):
            right_content, next_i = collect_block(lines, i + 1)
            out.append(":::: {.columns}\n\n")
            out.append('::: {.column width="50%"}\n')
            out.append("\n:::\n")
            out.append('\n::: {.column width="50%"}\n')
            out.extend(right_content)
            out.append("\n:::\n")
            out.append("\n::::\n\n")
            i = next_i
        else:
            out.append(lines[i])
            i += 1
    # Flush any remaining left block at the end
    if left_block:
        out.append(":::: {.columns}\n\n")
        out.append('::: {.column width="50%"}\n')
        out.extend(left_block)
        out.append("\n:::\n")
        out.append('\n::: {.column width="50%"}\n')
        out.append("\n:::\n")
        out.append("\n::::\n\n")
    return out


def convert_sidenotes(lines):
    out = []
    n = len(lines)
    i = 0
    while i < n:
        if lines[i].strip() == "???":
            out.append("::: {.notes}\n")
            i += 1
            # Collect lines until next slide delimiter or end of file
            while i < n and not lines[i].strip().startswith("---"):
                out.append(lines[i])
                i += 1
            out.append(":::\n\n")
        else:
            out.append(lines[i])
            i += 1
    return out


def convert_knitr_images(lines):
    out = []
    n = len(lines)
    i = 0
    while i < n:
        chunk_start = re.match(r"^```{r([^}]*)}", lines[i])
        if chunk_start:
            chunk_opts = chunk_start.group(1)
            # Look ahead for knitr::include_graphics
            j = i + 1
            found = False
            while j < n and not lines[j].strip().startswith("```"):
                if "knitr::include_graphics" in lines[j]:
                    found = True
                    break
                j += 1
            if found:
                # Extract width/height if present
                width_match = re.search(
                    r'out\.width\s*=\s*["\']?([\d\.]+%)["\']?', chunk_opts
                )
                height_match = re.search(
                    r'out\.height\s*=\s*["\']?([\d\.]+)["\']?', chunk_opts
                )
                width_str = f"{{width={width_match.group(1)}}}" if width_match else ""
                height_str = (
                    f"{{height={height_match.group(1)}}}" if height_match else ""
                )
                # Extract image path
                img_line = lines[j].strip()
                m = re.search(r"knitr::include_graphics\((.*)\)", img_line)
                if m:
                    path_expr = m.group(1)
                    path_match = re.search(r"file\.path\((.*?)\)", path_expr)
                    if path_match:
                        parts = [
                            p.strip().strip('"').strip("'")
                            for p in path_match.group(1).split(",")
                        ]
                        img_path = "/".join(parts)
                    else:
                        img_path = path_expr.strip().strip('"').strip("'")
                    # Compose markdown image
                    # Prefer width if both present
                    size_str = width_str or height_str
                    out.append(f"![]({img_path}){size_str}\n")
                    # Skip to end of chunk
                    while j < n and not lines[j].strip().startswith("```"):
                        j += 1
                    i = j + 1
                    continue
        out.append(lines[i])
        i += 1
    return out


def comment_out_patterns(lines):
    patterns = [
        r'testthat::test_dir\("tests"\)',
    ]
    out = []
    compiled = [re.compile(p) for p in patterns]
    for line in lines:
        if any(p.search(line) for p in compiled):
            # Comment out the line if not already commented
            if not line.lstrip().startswith("#"):
                out.append("# " + line)
            else:
                out.append(line)
        else:
            out.append(line)
    return out


def remove_patterns(lines):
    patterns = [
        r"^xaringanExtra\:\:",
    ]
    out = []
    compiled = [re.compile(p) for p in patterns]
    for line in lines:
        if any(p.match(line) for p in compiled):
            continue  # Skip lines that match any pattern
        out.append(line)
    return out


def convert_footnotes(lines):
    out = []
    n = len(lines)
    i = 0
    while i < n:
        if lines[i].strip().startswith(".footnote["):
            # Start collecting footnote content
            content = []
            line = lines[i]
            # Handle possible content on the same line
            start = line.find("[") + 1
            if line.rstrip().endswith("]") and start < len(line.rstrip()) - 1:
                # Single-line footnote
                content.append(line[start:-1].strip())
                i += 1
            else:
                # Multi-line footnote
                if start < len(line):
                    content.append(line[start:].rstrip())
                i += 1
                while i < n and not lines[i].strip().endswith("]"):
                    content.append(lines[i].rstrip())
                    i += 1
                if i < n:
                    # Add last line without the closing ]
                    end = lines[i].rfind("]")
                    if end != -1:
                        content.append(lines[i][:end].rstrip())
                    i += 1
            # Join and format as markdown footnote
            out.append("^[" + "\n".join(content).strip() + "]\n")
        else:
            out.append(lines[i])
            i += 1
    return out


def convert_rmd_to_qmd(rmd_path, qmd_path):
    with open(rmd_path, "r") as infile:
        lines = infile.readlines()

    lines = keep_only_title_in_yaml(lines)
    lines = convert_sidenotes(lines)

    # Remove YAML 'class:' lines and slide breaks
    out_lines = []
    in_yaml = False
    for i, line in enumerate(lines):
        if i == 0 and line.strip() == "---":
            in_yaml = True
            out_lines.append(line)
            continue

        if in_yaml:
            out_lines.append(line)
            if line.strip() == "---":
                in_yaml = False
            continue

        if line.strip() == "---":
            continue

        if line.strip().startswith("class:"):
            continue

        out_lines.append(line)

    out_lines = remove_patterns(out_lines)
    out_lines = comment_out_patterns(out_lines)
    out_lines = process_lines(out_lines)
    out_lines = compact_lists(out_lines)
    out_lines = convert_pull_columns(out_lines)
    out_lines = convert_knitr_images(out_lines)
    out_lines = remove_knitr_setup(out_lines)
    out_lines = fix_r_file_paths(out_lines)
    out_lines = fix_md_image_paths(out_lines)
    out_lines = convert_footnotes(out_lines)

    with open(qmd_path, "w") as outfile:
        outfile.writelines(out_lines)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python rmd_to_qmd.py input.Rmd output.qmd")
        sys.exit(1)
    convert_rmd_to_qmd(sys.argv[1], sys.argv[2])
