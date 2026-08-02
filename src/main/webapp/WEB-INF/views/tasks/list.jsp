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
            <table class="table table-hover table-bordered table-sm mb-0" id="tasksTable">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Description</th>
                        <th>MRs</th>
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
                                <td colspan="7" class="text-center text-muted py-4">
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
                                            <c:when test="${empty task.mergeRequests}">
                                                <span class="text-muted small">&#8212;</span>
                                            </c:when>
                                            <c:otherwise>
                                                <div class="d-flex flex-wrap gap-1">
                                                    <c:forEach var="mr" items="${task.mergeRequests}">
                                                        <a href="${mr.mr}" target="_blank"
                                                           class="badge ${mr.product.name() == 'PAYROLL' ? 'bg-warning text-dark' : 'bg-info text-dark'} text-decoration-none"
                                                           onclick="event.stopPropagation()">
                                                            <i class="bi bi-box-arrow-up-right me-1"></i>${mr.mrNumber}
                                                        </a>
                                                    </c:forEach>
                                                </div>
                                            </c:otherwise>
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
                    <tr id="panelHeadRow">
                        <th style="width:130px;">Field</th>
                        <!-- MR columns filled by JS -->
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
    const panelHead = document.getElementById('panelHeadRow');

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

    function productBadgeClass(product) {
        return product === 'Payroll' ? 'bg-warning text-dark' : 'bg-info text-dark';
    }

    function renderPanel(data) {
        document.getElementById('panelTaskId').textContent   = data.taskId;
        document.getElementById('panelTaskDesc').textContent = data.description;

        var mrs = data.mrs || [];

        // Header: one column per linked MR (product-colored)
        panelHead.innerHTML = '<th style="width:130px;">Field</th>' + mrs.map(function (mr) {
            return '<th><span class="badge ' + productBadgeClass(mr.product) + ' me-1">' + mr.product + '</span> MR</th>';
        }).join('');

        if (!mrs.length) {
            panelBody.innerHTML = '<tr><td colspan="2" class="text-center text-muted py-3">No MRs linked to this task</td></tr>';
            panel.style.display = 'block';
            panel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            return;
        }

        var rows = [
            { label: 'MR',         fn: mrLinkCell },
            { label: 'Name',       fn: nameCell },
            { label: 'Pipeline',   fn: pipeline },
            { label: 'Linked',     fn: linkedBadge },
            { label: 'Created',    fn: createdCell }
        ];

        panelBody.innerHTML = rows.map(function (r) {
            var cells = mrs.map(function (mr) {
                return '<td class="align-middle">' + (r.fn(mr) || na()) + '</td>';
            }).join('');
            return '<tr><td class="fw-semibold text-nowrap align-middle">' + r.label + '</td>' + cells + '</tr>';
        }).join('');

        // Wire up pipeline step clicks — clicking a stage jumps the MR directly to it
        panelBody.querySelectorAll('.pipeline-step').forEach(function (s) {
            s.addEventListener('click', function (e) {
                e.stopPropagation();
                var container = s.closest('.panel-steps');
                var mrId      = container.dataset.mrId;
                var status    = s.dataset.status;
                var prevStatus = 'NEW';
                PIPELINE_STAGES.forEach(function (st) {
                    var el = container.querySelector('[data-status="' + st + '"]');
                    if (el && el.classList.contains('ps-done')) prevStatus = st;
                });

                applyPipelineStatus(container, status); // optimistic
                fetch('/mrs/' + mrId + '/status/' + status, { method: 'POST' })
                    .then(function (r) { if (!r.ok) throw new Error('Update failed'); return r.json(); })
                    .then(function (d) { applyPipelineStatus(container, d.status); })
                    .catch(function () { applyPipelineStatus(container, prevStatus); });
            });
        });

        panel.style.display = 'block';
        panel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    function applyStep(el, isDone) {
        el.classList.toggle('ps-done', isDone);
        el.classList.toggle('ps-todo', !isDone);
    }

    // Pipeline stage order — used to redraw an entire MR's badges from a single status value
    var PIPELINE_STAGES = ['NEW', 'REVIEWED', 'DI_COMPLETED', 'GTM', 'RTM', 'MERGED'];

    function applyPipelineStatus(container, status) {
        var idx = PIPELINE_STAGES.indexOf(status);
        container.querySelectorAll('.pipeline-step').forEach(function (s) {
            applyStep(s, PIPELINE_STAGES.indexOf(s.dataset.status) <= idx);
        });
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
            { status: 'NEW',          label: 'N',   title: 'New',                   val: mr.stepNew },
            { status: 'REVIEWED',     label: 'R',   title: 'Reviewed',              val: mr.stepReviewed },
            { status: 'DI_COMPLETED', label: 'DI',  title: 'DI Completed',          val: mr.stepDiCompleted },
            { status: 'GTM',          label: 'GTM', title: 'GTM',                   val: mr.stepGtm },
            { status: 'RTM',          label: 'RTM', title: 'RTM',                   val: mr.stepRtm },
            { status: 'MERGED',       label: 'M',   title: 'Merged',                val: mr.stepMerged }
        ];
        var html = '<div class="panel-steps" data-mr-id="' + mr.mrSerialNumber + '">';
        steps.forEach(function(s, i) {
            if (i > 0) html += arrow();
            html += '<span class="ps pipeline-step ' + (s.val ? 'ps-done' : 'ps-todo') + '" '
                  + 'data-status="' + s.status + '" style="cursor:pointer;" title="' + s.title + '">'
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

    function createdCell(mr) {
        if (!mr || !mr.createdAt) return null;
        return '<span class="text-muted small">' + mr.createdAt + '</span>';
    }

}());
</script>

<%@include file="../layout/footer.jsp" %>
