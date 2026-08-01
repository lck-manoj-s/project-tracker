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
    <style>
        body { background-color: #f8f9fa; }
        .navbar-brand { font-weight: 700; }
        .filter-card { background: #fff; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
        .table th { background-color: #343a40; color: #fff; white-space: nowrap; }
        .badge-link a { color: inherit; text-decoration: none; }
        .badge-link a:hover { text-decoration: underline; }
        .bool-yes { color: #198754; font-weight: 600; }
        .bool-no  { color: #adb5bd; }
        .filter-label { font-size: .8rem; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; color: #6c757d; }
        .copy-mr-btn { background: transparent; border: none; padding: 0 0 0 3px; line-height: 1;
                       color: #adb5bd; cursor: pointer; vertical-align: middle; }
        .copy-mr-btn:hover { color: #495057; }
        .copy-mr-btn i { font-size: .72rem; }
    </style>
    <script>
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
<nav class="navbar navbar-expand-lg navbar-dark bg-dark mb-4">
    <div class="container-fluid">
        <a class="navbar-brand" href="/"><i class="bi bi-kanban-fill me-2"></i>Tasks &amp; MR Tracker</a>
        <div class="navbar-nav ms-3">
            <a class="nav-link ${pageContext.request.servletPath == '/' or pageContext.request.servletPath == '/dashboard' ? 'active' : ''}" href="/dashboard">
                <i class="bi bi-speedometer2 me-1"></i>Dashboard
            </a>
            <a class="nav-link ${pageContext.request.servletPath.startsWith('/tasks') ? 'active' : ''}" href="/tasks">
                <i class="bi bi-list-task me-1"></i>Tasks
            </a>
            <a class="nav-link ${pageContext.request.servletPath.startsWith('/mrs') ? 'active' : ''}" href="/mrs">
                <i class="bi bi-git me-1"></i>Merge Requests
            </a>
            <a class="nav-link ${pageContext.request.servletPath.startsWith('/history') ? 'active' : ''}" href="/history">
                <i class="bi bi-clock-history me-1"></i>History
            </a>
        </div>
    </div>
</nav>
<div class="container-fluid px-4 pb-5">
