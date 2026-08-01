<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="mb-0"><i class="bi bi-list-task me-2"></i>Tasks</h4>
    <a href="/tasks/new" class="btn btn-primary btn-sm">
        <i class="bi bi-plus-lg me-1"></i>Add Task
    </a>
</div>

<%-- ── Tabs ──────────────────────────────────────────────────────────── --%>
<ul class="nav nav-tabs mb-3">
    <li class="nav-item">
        <a class="nav-link ${tab == 'active' ? 'active' : ''}" href="/tasks">
            <i class="bi bi-play-circle me-1"></i>Active Tasks
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link ${tab == 'completed' ? 'active' : ''}" href="/tasks/completed">
            <i class="bi bi-check2-circle me-1"></i>Completed Tasks
        </a>
    </li>
</ul>

<%-- ── Filter card (shown for both tabs; status dropdown only on active) --%>
<div class="filter-card p-3 mb-4">
    <form method="get" action="${baseUrl}" class="row g-2 align-items-end" id="taskFilterForm">
        <c:if test="${tab == 'active'}">
            <div class="col-auto">
                <label class="filter-label d-block">Status</label>
                <select name="status" class="form-select form-select-sm">
                    <option value="" ${empty selectedStatus ? 'selected' : ''}>All Active</option>
                    <c:forEach var="s" items="${taskStatuses}">
                        <option value="${s}" ${s.name() == selectedStatus ? 'selected' : ''}>${s.displayName}</option>
                    </c:forEach>
                </select>
            </div>
        </c:if>
        <div class="col-auto">
            <label class="filter-label d-block">Priority</label>
            <select name="priority" class="form-select form-select-sm">
                <option value="">All</option>
                <c:forEach var="p" items="${priorities}">
                    <option value="${p}" ${p.name() == selectedPriority ? 'selected' : ''}>${p.displayName}</option>
                </c:forEach>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">MR Presence</label>
            <select name="mrPresence" class="form-select form-select-sm">
                <option value="">All</option>
                <option value="PAYROLL_ONLY" ${selectedMrPresence == 'PAYROLL_ONLY' ? 'selected' : ''}>Payroll MR Only</option>
                <option value="BOOKS_ONLY"   ${selectedMrPresence == 'BOOKS_ONLY'   ? 'selected' : ''}>Books MR Only</option>
                <option value="BOTH"         ${selectedMrPresence == 'BOTH'         ? 'selected' : ''}>Both MRs</option>
                <option value="NONE"         ${selectedMrPresence == 'NONE'         ? 'selected' : ''}>No MRs</option>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">All MRs DI Completed</label>
            <select name="allDiCompleted" class="form-select form-select-sm">
                <option value="">All</option>
                <option value="true"  ${selectedAllDiCompleted == 'true'  ? 'selected' : ''}>Yes</option>
                <option value="false" ${selectedAllDiCompleted == 'false' ? 'selected' : ''}>No</option>
            </select>
        </div>
        <div class="col-auto d-flex gap-2">
            <button type="submit" class="btn btn-sm btn-outline-primary">
                <i class="bi bi-funnel me-1"></i>Filter
            </button>
            <a href="${baseUrl}" class="btn btn-sm btn-outline-secondary">
                <i class="bi bi-x-circle me-1"></i>Clear
            </a>
        </div>
    </form>
</div>

<%-- ── Tasks Table ──────────────────────────────────────────────────── --%>
<div class="card shadow-sm">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover table-bordered mb-0" id="tasksTable">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Description</th>
                        <th>Payroll MR</th>
                        <th>Books MR</th>
                        <th>Priority</th>
                        <%-- <th>Due Date</th> --%>
                        <th>Status</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:choose>
                        <c:when test="${empty tasks}">
                            <tr>
                                <td colspan="8" class="text-center text-muted py-4">
                                    <i class="bi bi-inbox fs-4 d-block mb-1"></i>No tasks found
                                </td>
                            </tr>
                        </c:when>
                        <c:otherwise>
                            <c:forEach var="task" items="${tasks}">
                                <tr class="task-row" data-task-id="${task.taskId}" style="cursor:pointer;" title="Click to view MR status">
                                    <td class="text-muted small">${task.taskId}</td>
                                    <td>${task.description}</td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${task.payrollMr != null}">
                                                <a href="${task.payrollMr.mr}" target="_blank"
                                                   class="badge bg-warning text-dark text-decoration-none"
                                                   onclick="event.stopPropagation()">
                                                    <i class="bi bi-box-arrow-up-right me-1"></i>${task.payrollMr.mrNumber}
                                                </a>
                                                <button class="copy-mr-btn" data-mr="${task.payrollMr.mrNumber}"
                                                        onclick="event.stopPropagation(); copyMr(this)" title="Copy MR number">
                                                    <i class="bi bi-clipboard"></i>
                                                </button>
                                            </c:when>
                                            <c:otherwise><span class="text-muted small">&#8212;</span></c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${task.booksMr != null}">
                                                <a href="${task.booksMr.mr}" target="_blank"
                                                   class="badge bg-info text-dark text-decoration-none"
                                                   onclick="event.stopPropagation()">
                                                    <i class="bi bi-box-arrow-up-right me-1"></i>${task.booksMr.mrNumber}
                                                </a>
                                                <button class="copy-mr-btn" data-mr="${task.booksMr.mrNumber}"
                                                        onclick="event.stopPropagation(); copyMr(this)" title="Copy MR number">
                                                    <i class="bi bi-clipboard"></i>
                                                </button>
                                            </c:when>
                                            <c:otherwise><span class="text-muted small">&#8212;</span></c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td>
                                        <c:choose>
                                            <c:when test="${task.priority.name() == 'HIGH'}">
                                                <span class="badge bg-danger">${task.priority.displayName}</span>
                                            </c:when>
                                            <c:when test="${task.priority.name() == 'MEDIUM'}">
                                                <span class="badge bg-warning text-dark">${task.priority.displayName}</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-secondary">${task.priority.displayName}</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <%--
                                    <td>
                                        <c:choose>
                                            <c:when test="${not empty task.dueDate}">${fn:substring(task.dueDate, 8, 10)}-${fn:substring(task.dueDate, 5, 7)}-${fn:substring(task.dueDate, 0, 4)}</c:when>
                                            <c:otherwise><span class="text-muted small">&#8212;</span></c:otherwise>
                                        </c:choose>
                                    </td>
                                    --%>
                                    <td>
                                        <c:choose>
                                            <c:when test="${task.status.name() == 'YET_TO_START'}">
                                                <span class="badge bg-danger">${task.status.displayName}</span>
                                            </c:when>
                                            <c:when test="${task.status.name() == 'IDENTIFYING_ISSUE'}">
                                                <span class="badge bg-warning text-dark">${task.status.displayName}</span>
                                            </c:when>
                                            <c:when test="${task.status.name() == 'FIXING'}">
                                                <span class="badge bg-info text-dark">${task.status.displayName}</span>
                                            </c:when>
                                            <c:when test="${task.status.name() == 'MR_CREATED'}">
                                                <span class="badge bg-primary">${task.status.displayName}</span>
                                            </c:when>
                                            <c:when test="${task.status.name() == 'DONE'}">
                                                <span class="badge bg-success">${task.status.displayName}</span>
                                            </c:when>
                                            <c:when test="${task.status.name() == 'PAUSED'}">
                                                <span class="badge bg-secondary">${task.status.displayName}</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-secondary">${task.status.displayName}</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="text-muted small text-nowrap">
                                        <c:choose>
                                            <c:when test="${task.createdAt != null}">
                                                ${fn:substring(task.createdAt.toString(), 8, 10)}-${fn:substring(task.createdAt.toString(), 5, 7)}-${fn:substring(task.createdAt.toString(), 0, 4)}
                                                <span class="d-block" style="font-size:.7rem;">${fn:substring(task.createdAt.toString(), 11, 16)}</span>
                                            </c:when>
                                            <c:otherwise>&#8212;</c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td onclick="event.stopPropagation()">
                                        <a href="/tasks/edit/${task.taskId}" class="btn btn-sm btn-outline-secondary py-0">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form action="/tasks/delete/${task.taskId}" method="post" class="d-inline"
                                              onsubmit="return confirm('Delete this task?')">
                                            <button type="submit" class="btn btn-sm btn-outline-danger py-0">
                                                <i class="bi bi-trash"></i>
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            </c:forEach>
                        </c:otherwise>
                    </c:choose>
                </tbody>
            </table>
        </div>
    </div>
    <div class="card-footer d-flex justify-content-between align-items-center">
        <span class="text-muted small">
            Showing ${tasks.size()} of ${totalElements} task(s)
            &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
        </span>
        <c:if test="${totalPages > 1}">
            <nav>
                <ul class="pagination pagination-sm mb-0">
                    <%-- Previous --%>
                    <li class="page-item ${currentPage == 0 ? 'disabled' : ''}">
                        <c:url var="prevUrl" value="${baseUrl}">
                            <c:if test="${not empty selectedStatus}">       <c:param name="status"         value="${selectedStatus}"/></c:if>
                            <c:if test="${not empty selectedPriority}">     <c:param name="priority"       value="${selectedPriority}"/></c:if>
                            <c:if test="${not empty selectedMrPresence}">   <c:param name="mrPresence"     value="${selectedMrPresence}"/></c:if>
                            <c:if test="${not empty selectedAllDiCompleted}"><c:param name="allDiCompleted" value="${selectedAllDiCompleted}"/></c:if>
                            <c:param name="page" value="${currentPage - 1}"/>
                        </c:url>
                        <a class="page-link" href="${prevUrl}"><i class="bi bi-chevron-left"></i></a>
                    </li>

                    <%-- Page numbers --%>
                    <c:forEach begin="0" end="${totalPages - 1}" var="p">
                        <li class="page-item ${p == currentPage ? 'active' : ''}">
                            <c:url var="pageUrl" value="${baseUrl}">
                                <c:if test="${not empty selectedStatus}">       <c:param name="status"         value="${selectedStatus}"/></c:if>
                                <c:if test="${not empty selectedPriority}">     <c:param name="priority"       value="${selectedPriority}"/></c:if>
                                <c:if test="${not empty selectedMrPresence}">   <c:param name="mrPresence"     value="${selectedMrPresence}"/></c:if>
                                <c:if test="${not empty selectedAllDiCompleted}"><c:param name="allDiCompleted" value="${selectedAllDiCompleted}"/></c:if>
                                <c:param name="page" value="${p}"/>
                            </c:url>
                            <a class="page-link" href="${pageUrl}">${p + 1}</a>
                        </li>
                    </c:forEach>

                    <%-- Next --%>
                    <li class="page-item ${currentPage + 1 >= totalPages ? 'disabled' : ''}">
                        <c:url var="nextUrl" value="${baseUrl}">
                            <c:if test="${not empty selectedStatus}">       <c:param name="status"         value="${selectedStatus}"/></c:if>
                            <c:if test="${not empty selectedPriority}">     <c:param name="priority"       value="${selectedPriority}"/></c:if>
                            <c:if test="${not empty selectedMrPresence}">   <c:param name="mrPresence"     value="${selectedMrPresence}"/></c:if>
                            <c:if test="${not empty selectedAllDiCompleted}"><c:param name="allDiCompleted" value="${selectedAllDiCompleted}"/></c:if>
                            <c:param name="page" value="${currentPage + 1}"/>
                        </c:url>
                        <a class="page-link" href="${nextUrl}"><i class="bi bi-chevron-right"></i></a>
                    </li>
                </ul>
            </nav>
        </c:if>
    </div>
</div>

<%-- ── MR Status Panel (hidden until a task row is clicked) ──────────── --%>
<style>
  .panel-steps { display: inline-flex; align-items: center; gap: 2px; flex-wrap: nowrap; }
  .ps { display: inline-block; padding: 1px 5px; border-radius: 3px; font-size: .7rem;
        font-weight: 600; white-space: nowrap; border: 1px solid transparent; }
  .ps-done { background: #198754; color: #fff; border-color: #198754; }
  .ps-todo { background: #f8f9fa; color: #adb5bd; border-color: #dee2e6; }
  .ps-arrow { color: #adb5bd; font-size: .65rem; }
</style>

<div id="mrPanel" style="display:none;" class="card shadow-sm my-4 overflow-hidden">
    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center py-2">
        <span><i class="bi bi-git me-2"></i>MR Status — Task <strong id="panelTaskId"></strong>: <span id="panelTaskDesc" class="fw-normal fst-italic text-white-50"></span></span>
        <button type="button" class="btn-close btn-close-white btn-sm" onclick="hidePanel()"></button>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover table-bordered table-sm mb-0" id="panelTable">
                <thead>
                    <tr>
                        <th style="width:130px;">Field</th>
                        <th><span class="badge bg-warning text-dark me-1">Payroll</span> MR</th>
                        <th><span class="badge bg-info text-dark me-1">Books</span> MR</th>
                    </tr>
                </thead>
                <tbody id="panelBody">
                    <!-- filled by JS -->
                </tbody>
            </table>
        </div>
    </div>
</div>

<script>
// Strip empty filter params so the URL only contains changed values
document.getElementById('taskFilterForm').addEventListener('submit', function () {
    this.querySelectorAll('select').forEach(function (sel) {
        if (!sel.value) sel.disabled = true;
    });
});

(function () {

    const panel     = document.getElementById('mrPanel');
    const panelBody = document.getElementById('panelBody');

    document.querySelectorAll('.task-row').forEach(function (row) {
        row.addEventListener('click', function () {
            var taskId = this.dataset.taskId;
            fetch('/tasks/' + taskId + '/mrs')
                .then(function (r) { return r.json(); })
                .then(function (data) { renderPanel(data); })
                .catch(function () { alert('Could not load MR details.'); });
        });
    });

    document.addEventListener('click', function (e) {
        if (!e.target.closest('#mrPanel') && !e.target.closest('.task-row')) {
            hidePanel();
        }
    });

    window.hidePanel = function () { panel.style.display = 'none'; };

    function renderPanel(data) {
        document.getElementById('panelTaskId').textContent   = data.taskId;
        document.getElementById('panelTaskDesc').textContent = data.description;

        var p = data.payrollMr;
        var b = data.booksMr;

        var rows = [
            { label: 'MR',         pVal: mrLinkCell(p),   bVal: mrLinkCell(b) },
            { label: 'Name',       pVal: nameCell(p),     bVal: nameCell(b) },
            { label: 'Pipeline',   pVal: pipeline(p),     bVal: pipeline(b) },
            { label: 'Linked',     pVal: linkedBadge(p),  bVal: linkedBadge(b) },
            { label: 'Deployment', pVal: deployment(p),   bVal: deployment(b) },
            { label: 'Created',    pVal: createdCell(p),  bVal: createdCell(b) }
        ];

        panelBody.innerHTML = rows.map(function (r) {
            return '<tr>'
                + '<td class="fw-semibold text-nowrap align-middle">' + r.label + '</td>'
                + '<td class="align-middle">' + (r.pVal || na()) + '</td>'
                + '<td class="align-middle">' + (r.bVal || na()) + '</td>'
                + '</tr>';
        }).join('');

        // Wire up pipeline step clicks — each step is an independent toggle
        panelBody.querySelectorAll('.pipeline-step').forEach(function (s) {
            s.addEventListener('click', function (e) {
                e.stopPropagation();
                var mrId    = s.closest('[data-mr-id]').dataset.mrId;
                var field   = s.dataset.field;
                var wasDone = s.classList.contains('ps-done');
                applyStep(s, !wasDone); // optimistic
                fetch('/mrs/' + mrId + '/toggle/' + field, { method: 'POST' })
                    .then(function (r) { return r.json(); })
                    .then(function (d) { applyStep(s, d.newValue); })
                    .catch(function () { applyStep(s, wasDone); }); // revert on error
            });
        });

        // Wire up deployment toggle clicks
        panelBody.querySelectorAll('.toggle-step').forEach(function (s) {
            s.addEventListener('click', function (e) {
                e.stopPropagation();
                var mrId    = s.dataset.mrId;
                var field   = s.dataset.field;
                var wasDone = s.classList.contains('ps-done');
                applyStep(s, !wasDone);
                fetch('/mrs/' + mrId + '/toggle/' + field, { method: 'POST' })
                    .then(function (r) { return r.json(); })
                    .then(function (d) { applyStep(s, d.newValue); })
                    .catch(function ()  { applyStep(s, wasDone); });
            });
        });

        panel.style.display = 'block';
        panel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    function applyStep(el, isDone) {
        el.classList.toggle('ps-done', isDone);
        el.classList.toggle('ps-todo', !isDone);
    }

    function na() { return '<span class="text-muted">—</span>'; }
    function arrow() { return '<span class="ps-arrow">›</span>'; }

    function nameCell(mr) {
        if (!mr || !mr.name) return null;
        return '<span class="text-muted small">' + mr.name + '</span>';
    }

    function mrLinkCell(mr) {
        if (!mr) return null;
        return '<a href="' + mr.mr + '" target="_blank" class="badge bg-dark text-decoration-none me-1">'
             + '<i class="bi bi-box-arrow-up-right me-1"></i>' + mr.mrNumber + '</a>'
             + '<a href="/mrs/edit/' + mr.mrSerialNumber + '" class="btn btn-sm btn-outline-secondary py-0" '
             + 'onclick="event.stopPropagation()" title="Edit MR">'
             + '<i class="bi bi-pencil"></i></a>';
    }

    function pipeline(mr) {
        if (!mr) return null;
        var steps = [
            { field: 'stepWaiting',     label: 'W',   title: 'Waiting for Thumbs Up', val: mr.stepWaiting },
            { field: 'stepReviewed',    label: 'R',   title: 'Reviewed',              val: mr.stepReviewed },
            { field: 'stepDiScheduled', label: 'DI-S',title: 'DI Scheduled',          val: mr.stepDiScheduled },
            { field: 'stepDiCompleted', label: 'DI',  title: 'DI Completed',          val: mr.stepDiCompleted },
            { field: 'stepGtm',         label: 'GTM', title: 'GTM',                   val: mr.stepGtm },
            { field: 'stepRtm',         label: 'RTM', title: 'RTM',                   val: mr.stepRtm },
            { field: 'stepMerged',      label: 'M',   title: 'Merged',                val: mr.stepMerged }
        ];
        var html = '<div class="panel-steps" data-mr-id="' + mr.mrSerialNumber + '">';
        steps.forEach(function(s, i) {
            if (i > 0) html += arrow();
            html += '<span class="ps pipeline-step ' + (s.val ? 'ps-done' : 'ps-todo') + '" '
                  + 'data-field="' + s.field + '" style="cursor:pointer;" title="' + s.title + '">'
                  + s.label + '</span>';
        });
        html += '</div>';
        return html;
    }

    function linkedBadge(mr) {
        if (!mr) return null;
        var v   = mr.mrLinked || '—';
        var cls = v === 'Linked' ? 'bg-success' : v === 'Not Linked' ? 'bg-danger' : 'bg-secondary';
        return '<span class="badge ' + cls + '">' + v + '</span>';
    }

    function toggleStep(done, label, mrId, field) {
        return '<span class="ps toggle-step ' + (done ? 'ps-done' : 'ps-todo') + '" '
             + 'data-mr-id="' + mrId + '" data-field="' + field + '" '
             + 'style="cursor:pointer;" title="Click to toggle">'
             + label + '</span>';
    }

    function createdCell(mr) {
        if (!mr || !mr.createdAt) return null;
        return '<span class="text-muted small">' + mr.createdAt + '</span>';
    }

    function deployment(mr) {
        if (!mr) return null;
        var id = mr.mrSerialNumber;
        return '<div class="panel-steps">'
            + toggleStep(mr.movedToLocal, 'Local', id, 'movedToLocal') + arrow()
            + toggleStep(mr.movedToPre,   'Pre',   id, 'movedToPre')   + arrow()
            + toggleStep(mr.movedToIdc,   'IDC',   id, 'movedToIdc')
            + '</div>';
    }
}());
</script>

<%@include file="../layout/footer.jsp" %>
