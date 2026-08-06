<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tasks &amp; MR Tracker</title>
    <link rel="icon" type="image/svg+xml" href="/favicon.svg"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* ── Design tokens ─────────────────────────────────────────────────
           Single source of truth for color/spacing/typography — every page
           inherits from here instead of patching its own one-off values. */
        :root {
            --bs-primary:            #4f46e5;
            --bs-primary-rgb:        79, 70, 229;
            --bs-link-color:         #4f46e5;
            --bs-link-color-rgb:     79, 70, 229;
            --bs-link-hover-color:   #4338ca;
            --bs-link-hover-color-rgb: 67, 56, 202;
            --bs-border-radius:      .625rem;
            --bs-border-radius-sm:   .4rem;
            --bs-border-radius-lg:   .875rem;
            --bs-border-color:       #e5e7eb;
            --app-surface:           #ffffff;
            --app-bg:                #f5f6fa;
            --app-text:              #1e2333;
            --app-text-muted:        #57606f;
            --app-thead-bg:          #f8fafc;
            --app-thead-color:       #475569;
            --app-shadow-sm:         0 1px 2px rgba(16,24,40,.04), 0 1px 3px rgba(16,24,40,.08);
            --app-brand-dark:        #312e81;
        }

        body {
            background-color: var(--app-bg);
            color: var(--app-text);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-size: .9375rem;
            font-weight: 500;
        }
        /* Inter reads visibly lighter than a system font at the same nominal weight —
           500 as the body default (instead of 400) keeps small UI text legible. Bootstrap's
           .btn hardcodes its own 400, so it needs an explicit bump to match. */
        .btn { font-weight: 500; }
        h1, h2, h3, h4, h5, h6 { font-weight: 700; letter-spacing: -.01em; color: var(--app-text); }
        /* A heading's own color always wins over an inherited one — so a heading inside a
           dark, white-text header (card-header.bg-dark.text-white) needs to be told
           explicitly to stay white, or the rule above makes it invisible against the dark
           background. */
        .text-white, .text-white h1, .text-white h2, .text-white h3,
        .text-white h4, .text-white h5, .text-white h6 { color: #fff !important; }
        .text-muted { color: var(--app-text-muted) !important; }

        /* ── App shell — left sidebar nav, no top bar ────────────────────────────────
           .app-shell is the flex row (sidebar + main content). Sidebar defaults to
           collapsed (icon-only); .app-sidebar.expanded widens it and reveals labels/
           group headers/shortcut hints — toggled by the JS below and remembered in
           localStorage across page loads (each nav click is a full page load in this
           app, so without that the sidebar would snap back to collapsed every time).

           The sidebar is a single flex column divided by .side-divider rules into
           sections — brand, the 6 page links (grouped under small headers when
           expanded), search + quick-create, the "this week" widget, and the collapse
           toggle — so its height is used edge-to-edge instead of bunching everything
           at the top and leaving the rest blank. */
        .app-shell { display: flex; align-items: stretch; min-height: 100vh; }
        .app-sidebar {
            width: 60px;
            flex-shrink: 0;
            position: sticky;
            top: 0;
            height: 100vh;
            background: var(--app-surface);
            border-right: 1px solid var(--bs-border-color);
            display: flex;
            flex-direction: column;
            padding: .75rem .5rem;
            transition: width .15s ease;
            overflow-x: hidden;
            overflow-y: auto;
        }
        /* Absorbs leftover vertical space — there are two of these (after the main page
           links, and after the quick-create actions) so extra room on a tall viewport
           splits into a couple of modest gaps instead of one giant gap in a single
           spot. Collapsed mode has far less content than expanded (no text, no group
           headers), so this matters most there. */
        .side-spacer { flex: 1 1 auto; min-height: .5rem; }
        .app-sidebar.expanded { width: 212px; }
        .side-divider { border: none; border-top: 1px solid var(--bs-border-color); margin: .6rem 0; flex-shrink: 0; }
        .sidebar-brand {
            display: flex;
            align-items: center;
            gap: .6rem;
            padding: .3rem .4rem;
            white-space: nowrap;
            flex-shrink: 0;
        }
        .brand-mark {
            width: 30px; height: 30px;
            border-radius: .55rem;
            background: var(--bs-primary);
            color: #fff;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 1rem;
            flex-shrink: 0;
        }
        .sidebar-brand .brand-text { font-weight: 700; letter-spacing: -.01em; color: var(--app-text); opacity: 0; transition: opacity .1s ease; }
        .app-sidebar.expanded .sidebar-brand .brand-text { opacity: 1; }

        .nav-group { display: flex; flex-direction: column; gap: .35rem; }
        .group-label {
            font-size: .66rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .06em;
            color: var(--app-text-muted);
            padding: .5rem .45rem .15rem;
            white-space: nowrap;
            display: none;
        }
        .app-sidebar.expanded .group-label { display: block; }

        .side-link, .action-btn {
            display: flex;
            align-items: center;
            gap: .7rem;
            padding: .55rem .45rem;
            border-radius: var(--bs-border-radius-sm);
            color: var(--app-text-muted);
            font-weight: 500;
            font-size: .85rem;
            white-space: nowrap;
            transition: background-color .15s ease, color .15s ease;
            border: none;
            background: transparent;
            width: 100%;
            text-align: left;
        }
        .side-link i, .action-btn i { font-size: 1.1rem; flex-shrink: 0; width: 1.1rem; text-align: center; }
        .side-link .side-label, .action-btn .side-label,
        .side-link .side-shortcut { opacity: 0; transition: opacity .1s ease; }
        .side-link .side-shortcut { margin-left: auto; font-size: .68rem; color: var(--app-text-muted); }
        .app-sidebar.expanded .side-link .side-label,
        .app-sidebar.expanded .side-link .side-shortcut,
        .app-sidebar.expanded .action-btn .side-label { opacity: 1; }
        .side-link:hover, .action-btn:hover { background: var(--app-bg); color: var(--app-text); }
        .side-link.active { background: rgba(79,70,229,.1); color: var(--bs-primary); }

        /* Colored icon badges — shared by the 6 page links and the 3 quick-create actions,
           so every sidebar icon reads as bold/filled rather than a thin outline glyph,
           regardless of whether Bootstrap Icons has a "-fill" variant for it. Each item
           gets its own color so they stay distinguishable at a glance, collapsed or not.
           Indigo is deliberately NOT used here — it's reserved for the active-page pill
           (.side-link.active below) so that signal stays unambiguous. */
        .action-icon {
            width: 1.5rem; height: 1.5rem;
            border-radius: .4rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            color: #fff;
        }
        .action-icon i { font-size: .82rem; width: auto; }
        .side-link.nav-dashboard .action-icon { background: #D4537E; }
        .side-link.nav-tasks     .action-icon { background: #378ADD; }
        .side-link.nav-mrs       .action-icon { background: #7F77DD; }
        .side-link.nav-activity  .action-icon { background: #BA7517; }
        .side-link.nav-timesheet .action-icon { background: #1D9E75; }
        .side-link.nav-reports   .action-icon { background: #D85A30; }
        .action-btn.action-task .action-icon { background: var(--bs-primary); }
        .action-btn.action-mr   .action-icon { background: #378ADD; }
        .action-btn.action-time .action-icon { background: #1D9E75; }

        #searchTrigger .side-label { color: var(--app-text-muted); }

        .week-widget {
            flex-shrink: 0;
            padding: .6rem .5rem;
            text-align: center;
        }
        .week-widget .week-label {
            font-size: .68rem;
            color: var(--app-text-muted);
            white-space: nowrap;
            opacity: 0;
            transition: opacity .1s ease;
        }
        .app-sidebar.expanded .week-widget .week-label { opacity: 1; text-align: left; }
        .app-sidebar.expanded .week-widget { text-align: left; }
        .week-widget .week-value { font-size: .95rem; font-weight: 700; color: var(--app-text); }

        .sidebar-toggle {
            flex-shrink: 0;
        }
        .sidebar-toggle i { font-size: 1.1rem; flex-shrink: 0; width: 1.1rem; text-align: center; }

        .app-main { flex: 1; min-width: 0; display: flex; flex-direction: column; }

        /* ── Cards ───────────────────────────────────────────────────────── */
        .card { border: none; box-shadow: var(--app-shadow-sm); }
        .shadow-sm { box-shadow: var(--app-shadow-sm) !important; }
        .filter-card { background: var(--app-surface); border-radius: var(--bs-border-radius); box-shadow: var(--app-shadow-sm); }
        /* Form/panel headers (card-header.bg-dark) match the navbar's brand indigo instead
           of Bootstrap's plain near-black — scoped to card-header so it doesn't recolor the
           unrelated bg-dark badges used for MR numbers. */
        .card-header.bg-dark { background-color: var(--app-brand-dark) !important; }

        /* ── Tables — floating rows ─────────────────────────────────────────
           No grid lines anywhere. Each body row is its own rounded, lightly
           shadowed "card" with a visible gap to the next — separation comes
           from whitespace/shadow rather than borders, and the shadow lifts
           slightly on hover instead of a background tint. Header stays plain
           (no card treatment) so it reads as a label row, not another row. */
        .table thead th {
            background: transparent;
            color: var(--app-thead-color);
            border: none;
            white-space: nowrap;
            font-size: .72rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .04em;
            padding-bottom: .5rem;
        }
        .table-bordered {
            border: 0;
            border-collapse: separate;
            border-spacing: 0 .5rem;
        }
        .table-bordered > tbody > tr > * {
            border: none !important;
            background-color: var(--app-surface);
            box-shadow: 0 1px 2px rgba(16,24,40,.05), 0 1px 3px rgba(16,24,40,.06);
            /* Bootstrap's .table defaults cells to vertical-align: top (inherited from
               tbody), which some pages compensated for with an align-middle class on every
               <td> and some didn't — fixing it once here covers every bordered table either
               way, whether or not that per-cell class is present. */
            vertical-align: middle;
        }
        .table-bordered > tbody > tr > *:first-child {
            border-top-left-radius: var(--bs-border-radius-sm);
            border-bottom-left-radius: var(--bs-border-radius-sm);
        }
        .table-bordered > tbody > tr > *:last-child {
            border-top-right-radius: var(--bs-border-radius-sm);
            border-bottom-right-radius: var(--bs-border-radius-sm);
        }
        .table-sm > :not(caption) > * > * {
            padding-top: .65rem;
            padding-bottom: .65rem;
            padding-left: 1rem;
        }
        .table-hover > tbody > tr:hover > * {
            box-shadow: 0 3px 8px rgba(16,24,40,.12), 0 1px 3px rgba(16,24,40,.08);
        }
        /* Breathing room so the floating rows don't sit flush against the containing
           card's own edge/shadow — only ever wraps these tables in this app. */
        .table-responsive { padding: .5rem; }

        /* ── Tabs (underline style, no boxed pills) ─────────────────────── */
        .nav-tabs { border-bottom: 1px solid var(--bs-border-color); }
        .nav-tabs .nav-link { border: none; color: var(--app-text-muted); font-weight: 500; }
        .nav-tabs .nav-link:hover { border-color: transparent; color: var(--app-text); }
        .nav-tabs .nav-link.active {
            color: var(--bs-primary);
            background: transparent;
            border: none;
            border-bottom: 2px solid var(--bs-primary);
        }

        .badge { font-weight: 600; letter-spacing: .01em; }

        .badge-link a { color: inherit; text-decoration: none; }
        .badge-link a:hover { text-decoration: underline; }
        .bool-yes { color: #198754; font-weight: 600; }
        .bool-no  { color: #adb5bd; }
        .filter-label { font-size: .8rem; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; color: var(--app-text-muted); }
        .copy-mr-btn { background: transparent; border: none; padding: 0 0 0 3px; line-height: 1;
                       color: #adb5bd; cursor: pointer; vertical-align: middle; }
        .copy-mr-btn:hover { color: #495057; }
        .copy-mr-btn i { font-size: .72rem; }

        /* ── Sidebar search trigger (opens #searchOverlay) + overlay ──────────────── */
        #searchTrigger kbd {
            background: var(--app-bg);
            border: 1px solid var(--bs-border-color);
            color: var(--app-text-muted);
            font-size: .68rem;
            padding: .1rem .3rem;
            border-radius: .3rem;
            margin-left: auto;
            opacity: 0;
            transition: opacity .1s ease;
        }
        .app-sidebar.expanded #searchTrigger kbd { opacity: 1; }
        #searchOverlay {
            background: rgba(17, 19, 34, .55);
            z-index: 1090;
        }
        #searchBox {
            width: 560px;
            max-width: 90vw;
            border-radius: var(--bs-border-radius-lg);
            overflow: hidden;
            box-shadow: 0 20px 48px rgba(0,0,0,.28);
        }
        #searchInput { font-size: 1rem; }
        #searchResults { max-height: 360px; overflow-y: auto; }
        #searchResults .list-group-item-action { cursor: pointer; }
        #searchResults .list-group-item-action.active-row {
            background: var(--app-bg);
            border-color: var(--bs-border-color);
        }
    </style>
    <script>
    /** Builds and shows a Bootstrap toast in the shared #toastStack container.
     *  variant: 'success' | 'danger' | 'warning' (defaults to 'success'). */
    function showToast(message, variant) {
        variant = variant || 'success';
        var iconMap = { success: 'bi-check-circle-fill', danger: 'bi-exclamation-triangle-fill', warning: 'bi-exclamation-circle-fill' };
        var icon = iconMap[variant] || 'bi-info-circle-fill';

        var toastEl = document.createElement('div');
        toastEl.className = 'toast align-items-center text-bg-' + variant + ' border-0';
        toastEl.setAttribute('role', 'alert');
        toastEl.setAttribute('aria-live', 'assertive');
        toastEl.setAttribute('aria-atomic', 'true');

        var flex = document.createElement('div');
        flex.className = 'd-flex';

        var body = document.createElement('div');
        body.className = 'toast-body';
        var iconEl = document.createElement('i');
        iconEl.className = 'bi ' + icon + ' me-2';
        body.appendChild(iconEl);
        body.appendChild(document.createTextNode(message));

        var closeBtn = document.createElement('button');
        closeBtn.type = 'button';
        closeBtn.className = 'btn-close btn-close-white me-2 m-auto';
        closeBtn.setAttribute('data-bs-dismiss', 'toast');
        closeBtn.setAttribute('aria-label', 'Close');

        flex.appendChild(body);
        flex.appendChild(closeBtn);
        toastEl.appendChild(flex);

        var stack = document.getElementById('toastStack');
        stack.appendChild(toastEl);

        var toast = new bootstrap.Toast(toastEl, { delay: 4000 });
        toastEl.addEventListener('hidden.bs.toast', function () { toastEl.remove(); });
        toast.show();
    }

    function copyMr(btn) {
        var text = btn.getAttribute('data-mr');
        navigator.clipboard.writeText(text).then(function () {
            var icon = btn.querySelector('i');
            icon.className = 'bi bi-check-lg';
            btn.style.color = '#198754';
            setTimeout(function () {
                icon.className = 'bi bi-clipboard';
                btn.style.color = '';
            }, 1500);
        });
    }
    </script>
</head>
<body>
<div id="toastStack" class="toast-container position-fixed top-0 end-0 p-3" style="z-index:1080;"></div>
<%-- App shell: sidebar (collapsed by default) + main column (no top bar — search and
     quick actions live in the sidebar itself). Closed in footer.jsp — .app-shell/
     .app-main must stay balanced with the closing tags there.

     The sidebar fills its full height on purpose, in distinct sections separated by
     .side-divider rules, instead of bunching the 6 page links at the top and leaving
     everything below blank: brand -> grouped page links -> search + quick-create ->
     this-week total -> collapse toggle. --%>
<div class="app-shell">
    <aside class="app-sidebar" id="appSidebar">
        <a class="sidebar-brand text-decoration-none" href="/">
            <span class="brand-mark"><i class="bi bi-kanban-fill"></i></span>
            <span class="brand-text">Tasks &amp; MR Tracker</span>
        </a>
        <hr class="side-divider">

        <div class="nav-group">
            <span class="group-label">Overview</span>
            <a class="side-link nav-dashboard ${pageContext.request.servletPath == '/' or pageContext.request.servletPath == '/dashboard' ? 'active' : ''}" href="/dashboard" title="Dashboard (Ctrl+1)">
                <span class="action-icon"><i class="bi bi-house-fill"></i></span>
                <span class="side-label">Dashboard</span>
                <span class="side-shortcut">1</span>
            </a>

            <span class="group-label">Work</span>
            <a class="side-link nav-tasks ${pageContext.request.servletPath.startsWith('/tasks') ? 'active' : ''}" href="/tasks" title="Tasks (Ctrl+2)">
                <span class="action-icon"><i class="bi bi-check2-square"></i></span>
                <span class="side-label">Tasks</span>
                <span class="side-shortcut">2</span>
            </a>
            <a class="side-link nav-mrs ${pageContext.request.servletPath.startsWith('/mrs') ? 'active' : ''}" href="/mrs" title="Merge Requests (Ctrl+3)">
                <span class="action-icon"><i class="bi bi-git"></i></span>
                <span class="side-label">Merge Requests</span>
                <span class="side-shortcut">3</span>
            </a>

            <span class="group-label">Tracking</span>
            <a class="side-link nav-activity ${pageContext.request.servletPath.startsWith('/history') ? 'active' : ''}" href="/history" title="Activity (Ctrl+4)">
                <span class="action-icon"><i class="bi bi-activity"></i></span>
                <span class="side-label">Activities</span>
                <span class="side-shortcut">4</span>
            </a>
            <a class="side-link nav-timesheet ${pageContext.request.servletPath.startsWith('/timesheet') && !pageContext.request.servletPath.startsWith('/timesheet/report') ? 'active' : ''}" href="/timesheet" title="Timers (Ctrl+5)">
                <span class="action-icon"><i class="bi bi-stopwatch-fill"></i></span>
                <span class="side-label">Time Sheet</span>
                <span class="side-shortcut">5</span>
            </a>

            <span class="group-label">Reports</span>
            <a class="side-link nav-reports ${pageContext.request.servletPath.startsWith('/timesheet/report') ? 'active' : ''}" href="/timesheet/report" title="Reports (Ctrl+6)">
                <span class="action-icon"><i class="bi bi-bar-chart-fill"></i></span>
                <span class="side-label">Reports</span>
                <span class="side-shortcut">6</span>
            </a>
        </div>

        <div class="side-spacer"></div>
        <hr class="side-divider">

        <div class="nav-group">
            <span class="group-label">Utilities</span>
            <button type="button" id="searchTrigger" class="side-link">
                <i class="bi bi-search"></i>
                <span class="side-label">Search...</span>
                <kbd>Ctrl K</kbd>
            </button>
            <a class="action-btn action-task" href="/tasks/new" title="New task (Ctrl+T)">
                <span class="action-icon"><i class="bi bi-check-lg"></i></span>
                <span class="side-label">New task</span>
            </a>
            <a class="action-btn action-mr" href="/mrs/new" title="New MR (Ctrl+M)">
                <span class="action-icon"><i class="bi bi-git"></i></span>
                <span class="side-label">New MR</span>
            </a>
            <a class="action-btn action-time" href="/timesheet/new" title="Add time entry (Ctrl+L)">
                <span class="action-icon"><i class="bi bi-clock-history"></i></span>
                <span class="side-label">Add time entry</span>
            </a>
        </div>

        <div class="side-spacer"></div>
        <hr class="side-divider">

        <div class="week-widget">
            <div class="week-label">This week</div>
            <div class="week-value" id="weekHoursValue">&nbsp;</div>
        </div>

        <hr class="side-divider">
        <button type="button" class="sidebar-toggle side-link" id="sidebarToggle" title="Expand sidebar">
            <i class="bi bi-chevron-right" id="sidebarToggleIcon"></i>
            <span class="side-label">Collapse</span>
        </button>
    </aside>

    <div class="app-main">
<%-- ── Search overlay — tasks &amp; MRs only (same /search endpoint the old inline
     search box used), no navigation commands mixed in. ────────────────────── --%>
<div id="searchOverlay" class="position-fixed top-0 start-0 w-100 h-100 d-none">
    <div class="d-flex justify-content-center" style="padding-top:12vh;">
        <div id="searchBox" class="bg-white">
            <div class="p-2 border-bottom">
                <input type="text" id="searchInput" class="form-control border-0 shadow-none"
                       placeholder="Search tasks &amp; MRs" autocomplete="off">
            </div>
            <div id="searchResults" class="list-group list-group-flush"></div>
        </div>
    </div>
</div>

<script>
(function () {
    // ── Sidebar collapse/expand — collapsed (icon-only) by default. The choice is
    // remembered in localStorage because every nav link here is a normal page load
    // (not a SPA route change), so without persisting it the sidebar would reset to
    // collapsed every time the user clicks a link.
    var sidebar     = document.getElementById('appSidebar');
    var sideToggle  = document.getElementById('sidebarToggle');
    var sideToggleIcon = document.getElementById('sidebarToggleIcon');

    function applySidebarState(expanded) {
        sidebar.classList.toggle('expanded', expanded);
        sideToggleIcon.className = expanded ? 'bi bi-chevron-left' : 'bi bi-chevron-right';
        sideToggle.title = expanded ? 'Collapse sidebar' : 'Expand sidebar';
    }

    applySidebarState(localStorage.getItem('sidebarExpanded') === 'true');

    sideToggle.addEventListener('click', function () {
        var expanded = !sidebar.classList.contains('expanded');
        applySidebarState(expanded);
        localStorage.setItem('sidebarExpanded', expanded);
    });

    // ── "This week" sidebar widget — just the actual hours logged so far this week,
    // no target/progress bar (no such concept exists elsewhere in the app).
    fetch('/timesheet/current-week-summary')
        .then(function (r) { return r.json(); })
        .then(function (data) {
            document.getElementById('weekHoursValue').textContent = data.label || '0m';
        })
        .catch(function () {
            document.getElementById('weekHoursValue').textContent = '—';
        });

    var overlay = document.getElementById('searchOverlay');
    var input   = document.getElementById('searchInput');
    var results = document.getElementById('searchResults');
    var trigger = document.getElementById('searchTrigger');
    var debounceTimer  = null;
    var currentRequest = 0;
    var activeIndex    = -1;

    function escapeHtml(s) {
        var div = document.createElement('div');
        div.textContent = s == null ? '' : s;
        return div.innerHTML;
    }

    function openSearch() {
        overlay.classList.remove('d-none');
        input.value = '';
        results.innerHTML = '';
        input.focus();
    }

    function closeSearch() {
        overlay.classList.add('d-none');
    }

    function iconFor(type) { return type === 'task' ? 'bi-list-task' : 'bi-git'; }

    function renderResults(items, query) {
        activeIndex = -1;
        if (!items.length) {
            results.innerHTML = '<div class="list-group-item text-muted small">No matches for "' + escapeHtml(query) + '"</div>';
            return;
        }
        results.innerHTML = items.map(function (r) {
            return '<a href="' + r.url + '" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center py-2">'
                 + '<span><i class="bi ' + iconFor(r.type) + ' me-2 text-muted"></i>' + escapeHtml(r.label)
                 + (r.sublabel ? '<span class="d-block text-muted ms-4" style="font-size:.75rem;">' + escapeHtml(r.sublabel) + '</span>' : '')
                 + '</span></a>';
        }).join('');
    }

    function setActive(idx) {
        var rows = results.querySelectorAll('.list-group-item-action');
        if (!rows.length) return;
        if (activeIndex >= 0 && rows[activeIndex]) rows[activeIndex].classList.remove('active-row');
        activeIndex = (idx + rows.length) % rows.length;
        rows[activeIndex].classList.add('active-row');
        rows[activeIndex].scrollIntoView({ block: 'nearest' });
    }

    trigger.addEventListener('click', openSearch);

    input.addEventListener('input', function () {
        var q = input.value.trim();
        if (!q) { results.innerHTML = ''; return; }
        clearTimeout(debounceTimer);
        var requestId = ++currentRequest;
        debounceTimer = setTimeout(function () {
            fetch('/search?q=' + encodeURIComponent(q))
                .then(function (r) { return r.json(); })
                .then(function (data) {
                    if (requestId !== currentRequest) return; // stale response, a newer keystroke already fired
                    renderResults(data.results || [], q);
                })
                .catch(function () { results.innerHTML = ''; });
        }, 250);
    });

    input.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') { closeSearch(); return; }
        if (e.key === 'ArrowDown') { e.preventDefault(); setActive(activeIndex + 1); return; }
        if (e.key === 'ArrowUp')   { e.preventDefault(); setActive(activeIndex - 1); return; }
        if (e.key === 'Enter') {
            var rows = results.querySelectorAll('.list-group-item-action');
            var target = activeIndex >= 0 ? rows[activeIndex] : rows[0];
            if (target) window.location.href = target.getAttribute('href');
        }
    });

    overlay.addEventListener('click', function (e) {
        if (e.target === overlay) closeSearch();
    });

    // ── Global keyboard shortcuts — Ctrl (not Cmd/Meta) only, no Shift ───
    // Dropped the Shift modifier: Ctrl+Shift+<letter> collided with keys already mapped
    // elsewhere (Ulla). Everything below is now plain Ctrl+<key>.
    // Ctrl+K opens search. Ctrl+<letter> creates a Task/MR/Time entry. Ctrl+<number> jumps
    // straight to a page. All are suppressed while typing in a field so they never hijack
    // normal text/number entry in a form.
    var CREATE_SHORTCUTS = { t: '/tasks/new', m: '/mrs/new', l: '/timesheet/new' };
    var PAGE_SHORTCUTS = {
        Digit1: '/dashboard', Digit2: '/tasks', Digit3: '/mrs',
        Digit4: '/history',   Digit5: '/timesheet', Digit6: '/timesheet/report'
    };
    // Q/W/E jump to the 1st/2nd/3rd sub-page of whichever of Tasks/Merge Requests/Activity
    // you're currently on (same three keys reused per section, since only one section's
    // sub-pages are ever relevant at a time).
    var SUBPAGE_SHORTCUTS = [
        { prefix: '/tasks',   urls: ['/tasks', '/tasks/completed', '/tasks/parked'] },
        { prefix: '/mrs',     urls: ['/mrs/payroll', '/mrs/books', '/mrs/other'] },
        { prefix: '/history', urls: ['/history?tab=tasks', '/history?tab=mrs', '/history?tab=deployment'] }
    ];
    var SUBPAGE_INDEX = { q: 0, w: 1, e: 2 };

    document.addEventListener('keydown', function (e) {
        if (!e.ctrlKey || e.shiftKey || e.altKey || e.metaKey) return;

        if (e.key.toLowerCase() === 'k') {
            e.preventDefault();
            if (overlay.classList.contains('d-none')) openSearch(); else closeSearch();
            return;
        }

        var tag = (e.target.tagName || '').toLowerCase();
        var typing = tag === 'input' || tag === 'textarea' || tag === 'select' || e.target.isContentEditable;
        if (typing) return;

        var key = e.key.toLowerCase();
        if (key in SUBPAGE_INDEX) {
            var section = SUBPAGE_SHORTCUTS.find(function (s) { return window.location.pathname.indexOf(s.prefix) === 0; });
            if (section) { e.preventDefault(); window.location.href = section.urls[SUBPAGE_INDEX[key]]; }
            return;
        }

        var createUrl = CREATE_SHORTCUTS[key];
        // e.code (e.g. "Digit1") is used instead of e.key because on some layouts e.key can
        // report a shifted/alternate symbol for digit keys — e.code reports the physical key.
        var pageUrl = PAGE_SHORTCUTS[e.code];
        if (createUrl) { e.preventDefault(); window.location.href = createUrl; }
        else if (pageUrl) { e.preventDefault(); window.location.href = pageUrl; }
    });
})();
</script>
<%-- pt-4 (1.5rem) replaces the breathing room the old top navbar's mb-4 used to give
     page content before the sidebar existed — every page gets it from here, no
     per-page changes needed. --%>
<div class="container-fluid px-4 pt-4 pb-5">
