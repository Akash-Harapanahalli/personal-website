"""Render markdown for the HTML CV page and the publications listing from _data/cv.yml.

The Typst template (_cv.typ) renders the PDFs. This module produces the equivalent
content as markdown for embedding in cv/index.qmd and publications/index.qmd.
"""

from pathlib import Path
import re
import yaml


def _load(path):
    return yaml.safe_load(Path(path).read_text())


def _md_inline_to_html(s):
    """Convert the limited markdown we generate (bold, italic, links, code,
    escaped chars) to inline HTML. Use this so pandoc treats blocks as raw
    HTML and doesn't try to re-parse our nested layout divs.

    Escaped brackets (`\\[` / `\\]`) are stashed BEFORE the link regex runs —
    otherwise `\\[[label](url)\\]` (chip-wrapped links) would let the regex
    swallow the second `[`, corrupting the resulting HTML."""
    s = s.replace("\\[", "\x01").replace("\\]", "\x02").replace("\\*", "\x03")
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", s)
    s = s.replace("\x01", "[").replace("\x02", "]").replace("\x03", "*")
    return s


def _author_md(authors):
    """Bold 'A. Harapanahalli' (with or without '*') in the author list.
    Escape '*' so markdown doesn't treat equal-contribution markers as emphasis.
    """
    def fmt(a):
        escaped = a.replace("*", "\\*")
        if a in ("A. Harapanahalli", "A. Harapanahalli*"):
            return f"**{escaped}**"
        return escaped
    return ", ".join(fmt(a) for a in authors)


# Link keys that hyperlink the publication title (not shown as visible chips).
_TITLE_LINK_KEYS = ("doi", "arxiv", "proceedings")


def _link_list_md(links):
    if not links:
        return ""
    parts = [f"\\[[{kind}]({url})\\]" for kind, url in links.items() if kind not in _TITLE_LINK_KEYS]
    return " " + " ".join(parts) if parts else ""


def _pub_md(p):
    authors = _author_md(p["authors"])
    venue = p.get("venue", "")
    year = p.get("year", "")
    venue_year = f"{venue}, {year}" if year else venue
    note = f" **{p['note']}**" if "note" in p else ""
    links = _link_list_md(p.get("links"))
    lk = p.get("links") or {}
    title_url = next((lk[k] for k in _TITLE_LINK_KEYS if k in lk), None)
    title = f'[{p["title"]}]({title_url})' if title_url else p["title"]
    return f'{authors}, "{title}" *{venue_year}*.{note}{links}'


# ---------------------------------------------------------------------------
# Publications page (preserves existing .preprints / .journals / .conferences
# div classes and CSS counter scheme — the counter-reset value is emitted
# dynamically so adding a publication just updates one YAML entry).
# ---------------------------------------------------------------------------

def render_publications(yaml_path):
    data = _load(yaml_path)
    pubs = data["publications"]
    sections = [
        ("preprint", "Preprints", "preprints", "P"),
        ("journal", "Journal Papers", "journals", "J"),
        ("conference", "Conference Papers", "conferences", "C"),
    ]
    out = []
    for kind, heading, css_class, prefix in sections:
        items = [p for p in pubs if p["type"] == kind]
        if not items:
            continue
        n = len(items)
        # counter-reset to n+1 with -1 increment → first li (newest) gets [PN],
        # last li (oldest) gets [P1]. Matches LaTeX etaremune behavior.
        out.append(
            f'<style>'
            f'.{css_class} ol {{ list-style-type:none; counter-reset:item {n + 1}; padding-left: 2.5em; }}'
            f'.{css_class} ol > li {{ counter-increment:item -1; }}'
            f'.{css_class} ol > li::marker {{ content: "[{prefix}" counter(item) "]  "; }}'
            f'.{css_class} a {{ font-weight: bold; }}'
            f'</style>'
        )
        out.append(f"### {heading}\n")
        out.append(f":::{{.{css_class}}}\n")
        for p in items:
            out.append(f"1. {_pub_md(p)}")
        out.append("\n:::\n")
    out.append("\n\\* *indicates equal contribution*\n")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Full HTML CV page — same content as the PDF, structured as markdown so it
# inherits the site's Cosmo theme.
# ---------------------------------------------------------------------------

def _dated_line(left, right):
    """Two-column row, fully pre-rendered to HTML so pandoc doesn't try to
    re-parse it. The text content stays selectable / extractable."""
    return (
        f'<div class="cv-row">'
        f'<div>{_md_inline_to_html(left)}</div>'
        f'<div class="cv-date">{_md_inline_to_html(right)}</div>'
        f'</div>'
    )


def _bullets(items):
    """Bullet list, pre-rendered to HTML to keep pandoc happy inside divs."""
    inner = "".join(f"<li>{_md_inline_to_html(it)}</li>" for it in items)
    return f'<ul class="cv-bullets">{inner}</ul>'


CV_STYLES = """<style>
.cv-row { display: flex; justify-content: space-between; gap: 1em; align-items: baseline; margin-top: 0.15em; }
.cv-date { white-space: nowrap; color: #555; font-size: 0.95em; }
.cv-bullets { margin-top: 0.25em; margin-bottom: 0.5em; }
.cv-bullets li { margin-bottom: 0.15em; }
.cv-contact { text-align: center; font-size: 0.95em; margin-bottom: 0.5em; }
.cv-downloads { text-align: center; margin-bottom: 1.2em; }
.cv-skill { margin-top: 0.15em; }
</style>"""


def render_cv(yaml_path):
    data = _load(yaml_path)
    out = [CV_STYLES]

    # Header: handled by Quarto title; below it, contact info.
    p = data["profile"]
    contact_parts = [
        p["phone"],
        *p["locations"],
        p["citizenship"],
        _md_inline_to_html(f'[{p["email"]}](mailto:{p["email"]})'),
        _md_inline_to_html(f'[{p["links"]["website"].replace("https://", "")}]({p["links"]["website"]})'),
        _md_inline_to_html(f'[github.com/Akash-Harapanahalli]({p["links"]["github"]})'),
        _md_inline_to_html(f'[Google Scholar]({p["links"]["scholar"]})'),
    ]
    out.append(f'<div class="cv-contact">{" &diams; ".join(contact_parts)}</div>')
    out.append(
        '<div class="cv-downloads">'
        '<a href="/files/AkashHarapanahalliCV.pdf" class="btn btn-primary">Download CV (PDF)</a> '
        '<a href="/files/AkashHarapanahalliResume.pdf" class="btn btn-outline-primary">Download Resume (PDF)</a>'
        '</div>'
    )

    # ----- Summary
    if data.get("summary"):
        out.append("## Summary\n")
        out.append(data["summary"].strip())
        out.append("")

    # ----- Current Position
    cp = data["current_position"]
    out.append("## Current Position\n")
    out.append(f'**{cp["institution"]}** — {cp["location"]}  ')
    out.append(_dated_line(
        f'{cp["title"]}, {cp["department"]}',
        f'{cp["start"]} - {cp["end"]}',
    ))

    # ----- Education
    out.append("\n## Education\n")
    for school in data["education"]:
        out.append(f'**{school["institution"]}** — {school["location"]}\n')
        for d in school["degrees"]:
            out.append(_dated_line(
                f'**{d["degree"]}** — GPA: {d["gpa"]}',
                f'{d["start"]} - {d["end"]}',
            ))

    # ----- Technical Skills
    if data.get("skills"):
        out.append("\n## Technical Skills\n")
        for s in data["skills"]:
            items = ", ".join(s["items"])
            out.append(
                f'<div class="cv-skill"><strong>{s["category"]}:</strong> {items}</div>'
            )

    # ----- Research Experience
    out.append("\n## Research Experience\n")
    for e in data["experience"]:
        if not e.get("cv", True):
            continue
        org = f'[{e["org"]}]({e["org_url"]})' if "org_url" in e else e["org"]
        out.append(_dated_line(
            f'**{e["role"]}** — {org}',
            f'{e["start"]} - {e["end"]}',
        ))
        if "summary" in e:
            out.append(f'\n{e["summary"]}  ')
        if "philosophy" in e:
            out.append(f'*Research Philosophy:* {e["philosophy"]}\n')
        out.append(_bullets(e["bullets"]))
        out.append("")

    # ----- Publications
    out.append(f'\n## Publications [[Google Scholar]({p["links"]["scholar"]})]\n')
    out.append("\\* *indicates equal contribution*\n")
    pubs = data["publications"]
    sections = [
        ("preprint", "Preprints", "preprints", "P"),
        ("journal", "Journal Articles", "journals", "J"),
        ("conference", "Conference Papers and Abstracts", "conferences", "C"),
    ]
    for kind, heading, css_class, prefix in sections:
        items = [pp for pp in pubs if pp["type"] == kind]
        if not items:
            continue
        n = len(items)
        out.append(
            f'<style>'
            f'.cv-{css_class} ol {{ list-style-type:none; counter-reset:item {n + 1}; padding-left: 2.5em; }}'
            f'.cv-{css_class} ol > li {{ counter-increment:item -1; }}'
            f'.cv-{css_class} ol > li::marker {{ content: "[{prefix}" counter(item) "]  "; }}'
            f'</style>'
        )
        out.append(f"\n***{heading}***\n")
        out.append(f":::{{.cv-{css_class}}}\n")
        for pp in items:
            out.append(f"1. {_pub_md(pp)}")
        out.append("\n:::\n")

    # ----- Honors and Awards
    out.append("\n## Honors and Awards\n")
    for h in data["honors"]:
        if not h.get("cv", True):
            continue
        left = f'**{h["title"]}**' + (f' — {h["org"]}' if "org" in h else "")
        out.append(_dated_line(left, h["date"]))

    # ----- Academic Service
    out.append("\n## Academic Service\n")
    for r in data["service"]["roles"]:
        left = f'**{r["title"]}**'
        if "link" in r:
            left += f' \\[[link]({r["link"]})\\]'
        date = r.get("date") or f'{r["start"]} - {r["end"]}'
        out.append(_dated_line(left, date))
    out.append("\n**Reviewer for the following venues:**\n")
    for rv in data["service"]["reviewer"]:
        out.append(_dated_line(rv["venue"], rv["years"]))

    # ----- Teaching & Professional
    out.append(
        f'\n## Teaching and Professional Experience '
        f'[[Portfolio]({p["links"]["portfolio"]})]\n'
    )
    for t in data["teaching_professional"]:
        if not t.get("cv", True):
            continue
        out.append(_dated_line(
            f'**{t["role"]}** — {t["org"]}',
            f'{t["start"]} - {t["end"]}',
        ))
        out.append(_bullets(t["bullets"]))
        out.append("")

    # ----- Projects
    out.append(
        f'\n## Other Experiences and Projects '
        f'[[Portfolio]({p["links"]["portfolio"]})]\n'
    )
    for proj in data["projects"]:
        if not proj.get("cv", True):
            continue
        title = f'**{proj["title"]}**' + _link_list_md(proj.get("links"))
        out.append(_dated_line(title, f'{proj["start"]} - {proj["end"]}'))
        out.append(_bullets(proj["bullets"]))
        out.append("")

    return "\n".join(out)
