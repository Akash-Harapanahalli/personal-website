// Shared Typst template for the CV and the Resume.
// Both `cv.typ` and `resume.typ` import `render-cv` from here.
// Reads structured data from ../_data/cv.yml.
//
// Design goals (in order):
//   1. Maximum parseability — single column, real headings, real text (no glyphs as paths),
//      right-aligned dates via grid() instead of \hfill whitespace tricks.
//   2. Visually similar to the prior LaTeX layout.
//   3. Single source: CV vs Resume diverge only through the `resume` flag on each entry.

// One row of "left text — — — right date". Inherits global block spacing.
#let dated(left-body, right-body) = grid(
  columns: (1fr, auto),
  column-gutter: 1em,
  left-body,
  align(right)[#right-body],
)

// A section header: open extra space above to separate sections, and a small
// gap between the heading text and the underline beneath it.
#let section(title) = block(above: 1.2em, below: 0.6em, {
  text(weight: "bold", size: 11.5pt, upper(title))
  v(-0.1em)
  line(length: 100%, stroke: 0.5pt)
})

// Convert markdown-style `[label](url)` into Typst `#link("url")[label]` calls,
// then evaluate the string as Typst markup so *bold*, _italic_, and `code` work.
#let md-to-content(s) = {
  let converted = s.replace(
    regex("\[([^\]]+)\]\(([^)]+)\)"),
    m => "#link(\"" + m.captures.at(1) + "\")[" + m.captures.at(0) + "]"
  )
  eval(converted, mode: "markup")
}

#let bullets(items, tight: false) = block(above: 0.75em, list(
  tight: false,
  indent: 0pt,
  body-indent: 0.5em,
  spacing: 0.7em,
  ..items.map(md-to-content)
))

// Site base URL used to expand relative links (e.g. /presentations/...)
// into absolute URLs so they resolve when the PDF is opened standalone.
#let SITE = "https://akashhara.com"

#let absolutize(url) = {
  if url.starts-with("/") { SITE + url } else { url }
}

// Link keys that hyperlink the publication title (not shown as visible chips).
#let TITLE_LINK_KEYS = ("doi", "arxiv", "proceedings")

#let link-list(links) = {
  // Render a dict of { kind: url } as " [kind] [kind] ..."
  if links == none or links.len() == 0 { return [] }
  let parts = ()
  for (k, v) in links.pairs() {
    if k in TITLE_LINK_KEYS { continue }
    parts.push([\[#link(absolutize(v))[#k]\]])
  }
  parts.join(" ")
}

#let pub-authors(authors) = {
  // Bold the user's own name to make it easy to scan.
  let me = ("A. Harapanahalli", "A. Harapanahalli*")
  authors.map(a => if a in me { strong(a) } else { a }).join(", ")
}

#let pub-entry(label, p) = {
  // One publication entry. `label` is e.g. "[P1]" or "[1]". The label sits
  // in its own column so wrapped citation lines hang-indent under the text.
  // The title hyperlinks to the arxiv abstract (if present), matching the
  // original LaTeX/website behavior.
  let venue = if "year" in p { p.venue + ", " + str(p.year) } else { p.venue }
  let note = if "note" in p { [ *#p.note* ] } else { [] }
  let lk = p.at("links", default: (:))
  let title-link = none
  for k in TITLE_LINK_KEYS {
    if title-link == none and k in lk { title-link = lk.at(k) }
  }
  let title-body = [#p.title]
  let title = if title-link != none { link(title-link)[#title-body] } else { title-body }
  block(below: 0.5em, grid(
    columns: (auto, 1fr),
    column-gutter: 0.4em,
    [#label],
    [#pub-authors(p.authors), "#title" _#emph(venue)_. #note #link-list(p.at("links", default: (:)))],
  ))
}

#let render-publications-cv(pubs) = {
  // CV mode: three sections (Preprints / Journals / Conferences),
  // numbered [P1], [J1], [C1] in source order (newest-first).
  let by-type = (
    preprint: pubs.filter(p => p.type == "preprint"),
    journal: pubs.filter(p => p.type == "journal"),
    conference: pubs.filter(p => p.type == "conference"),
  )
  let labels = (preprint: "P", journal: "J", conference: "C")
  let titles = (
    preprint: "Preprints",
    journal: "Journal Articles",
    conference: "Conference Papers and Abstracts",
  )
  for kind in ("preprint", "journal", "conference") {
    let items = by-type.at(kind)
    if items.len() == 0 { continue }
    block(above: 0.9em, below: 0.25em, text(style: "italic", weight: "bold", titles.at(kind)))
    // Match etaremune / existing website convention: newest listed first,
    // numbered with the highest label. So [PN] is newest, [P1] is oldest.
    for (i, p) in items.enumerate() {
      pub-entry("[" + labels.at(kind) + str(items.len() - i) + "]", p)
    }
  }
}

#let render-publications-resume(pubs) = {
  // Resume mode: one combined list of publications flagged `resume: true`,
  // numbered [1] [2] ... in source order.
  let selected = pubs.filter(p => p.at("resume", default: false))
  for (i, p) in selected.enumerate() {
    pub-entry("[" + str(selected.len() - i) + "]", p)
  }
}

#let render-cv(mode: "cv") = {
  let data = yaml("../_data/cv.yml")
  let is-resume = mode == "resume"

  set document(
    title: data.profile.name + " — " + if is-resume { "Resume" } else { "CV" },
    author: data.profile.name,
  )
  set page(paper: "us-letter", margin: 0.65in)
  set text(font: ("Noto Sans", "DejaVu Sans"), size: 10pt)
  set par(justify: false, leading: 0.55em)
  // Tight, consistent block spacing across the document. Sections explicitly
  // open more space above their heading.
  set block(spacing: 0.5em)
  show link: it => underline(text(fill: blue, it))

  // ----------------------- Header -----------------------
  align(center, block(below: 0.85em, text(size: 18pt, weight: "bold", upper(data.profile.name))))
  let contact-bits = (
    data.profile.phone,
    ..data.profile.locations,
    data.profile.citizenship,
    link("mailto:" + data.profile.email)[#data.profile.email],
    link(data.profile.links.website)[#data.profile.links.website.replace("https://", "")],
    link(data.profile.links.github)[github.com/Akash-Harapanahalli],
    link(data.profile.links.scholar)[Google Scholar],
  )
  if is-resume {
    contact-bits = (link(data.profile.links.cv_html)[Full CV],) + contact-bits
  }
  align(center)[
    #contact-bits.join("  \u{22C4}  ")
  ]
  v(0.3em)

  // ----------------------- Summary -----------------------
  if "summary" in data {
    section("Summary")
    par(justify: true, md-to-content(data.summary.trim()))
  }

  // ----------------------- Current Position (CV only) -----------------------
  if not is-resume {
    section("Current Position")
    [*#data.current_position.institution* — #data.current_position.location \ ]
    dated(
      [#data.current_position.title, #data.current_position.department],
      [#data.current_position.start - #data.current_position.end],
    )
  }

  // ----------------------- Education -----------------------
  section("Education")
  for school in data.education {
    [*#school.institution* — #school.location]
    block(above: 0.75em, list(
      tight: false,
      indent: 0pt,
      body-indent: 0.5em,
      spacing: 0.7em,
      ..school.degrees.map(d => grid(
        columns: (1fr, auto),
        column-gutter: 1em,
        [*#d.degree* — GPA: #d.gpa],
        align(right)[#d.start - #d.end],
      ))
    ))
  }

  // ----------------------- Technical Skills -----------------------
  if "skills" in data and data.skills.len() > 0 {
    section("Technical Skills")
    for s in data.skills {
      grid(
        columns: (auto, 1fr),
        column-gutter: 0.6em,
        [*#s.category:*],
        [#s.items.join(", ")],
      )
    }
  }

  // ----------------------- Experience (Research) -----------------------
  section("Research Experience")
  for e in data.experience {
    if is-resume and not e.at("resume", default: true) { continue }
    if not is-resume and not e.at("cv", default: true) { continue }
    let org-link = if "org_url" in e { link(e.org_url)[#e.org] } else { [#e.org] }
    dated([*#e.role* — #org-link], [#e.start - #e.end])
    if "summary" in e {
      md-to-content(e.summary)
      if "philosophy" in e {
        linebreak()
        emph[Research Philosophy:]
        [ ]
        md-to-content(e.philosophy)
      }
    }
    bullets(e.bullets, tight: is-resume)
    v(0.3em)
  }

  // ----------------------- Publications -----------------------
  let pub-section-title = if is-resume { "Selected Publications" } else { "Publications" }
  section[#pub-section-title  [#link(data.profile.links.scholar)[Google Scholar]]]
  emph[\* indicates equal contribution]
  if is-resume {
    render-publications-resume(data.publications)
  } else {
    render-publications-cv(data.publications)
  }

  // ----------------------- Honors and Awards -----------------------
  section("Honors and Awards")
  for h in data.honors {
    let show-it = if is-resume { h.at("resume", default: false) } else { h.at("cv", default: true) }
    if not show-it { continue }
    let left = if "org" in h { [*#h.title* — #h.org] } else { [*#h.title*] }
    dated(left, [#h.date])
  }

  // ----------------------- Academic Service -----------------------
  section("Academic Service")
  for r in data.service.roles {
    let title-block = if "link" in r {
      [*#r.title* \[#link(r.link)[link]\]]
    } else { [*#r.title*] }
    let date = if "date" in r { r.date } else { r.start + " - " + r.end }
    dated(title-block, [#date])
  }
  if is-resume {
    // Inline single-line summary, as in the LaTeX resume
    [*Reviewer for* ]
    data.service.reviewer.map(rv => rv.venue + " (" + rv.years + ")").join(", ")
  } else {
    [*Reviewer for the following venues:*]
    list(
      tight: false,
      indent: 0pt,
      body-indent: 0.5em,
      spacing: 0.4em,
      ..data.service.reviewer.map(rv => [
        #grid(columns: (1fr, auto), [#rv.venue], align(right)[#rv.years])
      ])
    )
  }

  // ----------------------- Teaching & Professional -----------------------
  let teach-title = if is-resume {
    [Teaching and Professional Experience  [#link(data.profile.links.portfolio)[Portfolio]]]
  } else {
    [Teaching and Professional Experience]
  }
  section[#teach-title]
  for t in data.teaching_professional {
    let show-it = if is-resume { t.at("resume", default: true) } else { t.at("cv", default: true) }
    if not show-it { continue }
    dated([*#t.role* — #t.org], [#t.start - #t.end])
    bullets(t.bullets, tight: is-resume)
    v(0.3em)
  }

  // ----------------------- Projects -----------------------
  let any-projects = data.projects.any(p =>
    if is-resume { p.at("resume", default: false) } else { p.at("cv", default: true) }
  )
  if any-projects {
    let proj-title = if is-resume {
      [Other Projects]
    } else {
      [Other Experiences and Projects  [#link(data.profile.links.portfolio)[Portfolio]]]
    }
    section[#proj-title]
    for p in data.projects {
      let show-it = if is-resume { p.at("resume", default: false) } else { p.at("cv", default: true) }
      if not show-it { continue }
      let title-block = [*#p.title* #link-list(p.at("links", default: (:)))]
      dated(title-block, [#p.start - #p.end])
      bullets(p.bullets, tight: is-resume)
      v(0.3em)
    }
  }
}
