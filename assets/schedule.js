(() => {
  const sections = [...document.querySelectorAll("section.schedule-week")];
  if (!sections.length) return;

  const now = new Date();
  const date = Object.fromEntries(
    new Intl.DateTimeFormat("en-CA", {
      timeZone: "Europe/Copenhagen",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    })
      .formatToParts(now)
      .map(({ type, value }) => [type, value]),
  );
  const today = `${date.year}-${date.month}-${date.day}`;
  const weeks = sections.map((section) => {
    const heading = section.querySelector("h3");
    const dates = heading.querySelector(".schedule-week-dates");
    const details = document.createElement("details");
    const summary = document.createElement("summary");
    const content = document.createElement("div");
    content.className = "schedule-week-content";

    // The section keeps its ID so existing links and the table of contents work.
    heading.classList.remove("anchored");
    heading.querySelector(".anchorjs-link")?.remove();
    summary.append(heading);
    content.append(...section.childNodes);
    details.append(summary, content);
    section.append(details);
    section.classList.add("is-collapsible");
    return {
      section,
      heading,
      details,
      start: dates?.dataset.weekStart,
      end: Date.parse(dates?.dataset.weekEnd),
    };
  });
  const active = weeks.find((week) => week.end > now.getTime());
  for (const week of weeks) {
    // Once the published schedule has ended, show all materials for review.
    week.details.open =
      !active || week === active || !Number.isFinite(week.end);
  }

  const controls = document.createElement("nav");
  controls.className = "schedule-controls";
  controls.setAttribute("aria-label", "Schedule controls");
  if (active) {
    const upcoming = today < active.start;
    active.section.classList.add("is-current");
    const badge = document.createElement("span");
    badge.className = "schedule-week-badge";
    badge.textContent = upcoming ? "Up next" : "This week";
    active.heading.append(badge);

    const jump = document.createElement("a");
    jump.href = `#${active.section.id}`;
    jump.textContent = upcoming
      ? "Jump to upcoming week"
      : "Jump to current week";
    controls.append(jump);
  }
  const expand = document.createElement("button");
  expand.type = "button";
  expand.className = "btn btn-outline-primary btn-sm";
  const updateExpand = () => {
    expand.textContent = weeks.every((week) => week.details.open)
      ? "Collapse all"
      : "Expand all";
  };
  expand.addEventListener("click", () => {
    const open = !weeks.every((week) => week.details.open);
    weeks.forEach((week) => {
      week.details.open = open;
    });
    updateExpand();
  });
  weeks.forEach((week) =>
    week.details.addEventListener("toggle", updateExpand),
  );
  updateExpand();
  controls.append(expand);
  sections[0].before(controls);

  const openTarget = (hash, scroll = false) => {
    let id;
    try {
      id = decodeURIComponent(hash.slice(1));
    } catch {
      return;
    }
    const target = document.getElementById(id);
    const week = weeks.find((week) => week.section.contains(target));
    if (!week) return;
    week.details.open = true;
    if (scroll) requestAnimationFrame(() => target.scrollIntoView());
  };
  // Expand before Quarto handles a link's scroll, including links to old lectures.
  document.addEventListener(
    "click",
    (event) => {
      if (
        event.button !== 0 ||
        event.ctrlKey ||
        event.metaKey ||
        event.shiftKey ||
        event.altKey
      )
        return;
      const link = event.target.closest("a[href]");
      if (!link || link.target === "_blank") return;
      const url = new URL(link.href, location.href);
      const pagePath = (path) => path.replace(/index\.html$/, "");
      if (
        url.origin === location.origin &&
        pagePath(url.pathname) === pagePath(location.pathname)
      ) {
        openTarget(url.hash);
        // Quarto may shorten index.html links to the directory URL.
        if (url.hash && url.pathname !== location.pathname) {
          event.preventDefault();
          location.hash = url.hash;
        }
      }
    },
    true,
  );
  window.addEventListener("hashchange", () => openTarget(location.hash, true));
  openTarget(location.hash, true);

  let beforePrint;
  window.addEventListener("beforeprint", () => {
    beforePrint = weeks.map((week) => week.details.open);
    weeks.forEach((week) => {
      week.details.open = true;
    });
  });
  window.addEventListener("afterprint", () => {
    if (beforePrint) {
      weeks.forEach((week, index) => {
        week.details.open = beforePrint[index];
      });
    }
  });
})();
