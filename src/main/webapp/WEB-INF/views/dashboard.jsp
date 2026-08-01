<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@include file="layout/header.jsp" %>
<style>
  @media (min-width:992px) { .row-cols-lg-7 > * { flex: 0 0 auto; width: 14.2857%; } }
</style>

<h4 class="mb-3"><i class="bi bi-speedometer2 me-2"></i>Dashboard</h4>

<%-- ── Tabs ──────────────────────────────────────────────────────────── --%>
<ul class="nav nav-tabs mb-4" id="dashTabs" role="tablist">
    <li class="nav-item" role="presentation">
        <button class="nav-link active" id="tasks-tab" data-bs-toggle="tab"
                data-bs-target="#tasksPane" type="button" role="tab">
            <i class="bi bi-list-task me-1"></i>Tasks
            <span class="badge bg-secondary ms-1">${totalTasks}</span>
        </button>
    </li>
    <li class="nav-item" role="presentation">
        <button class="nav-link" id="mrs-tab" data-bs-toggle="tab"
                data-bs-target="#mrsPane" type="button" role="tab">
            <i class="bi bi-git me-1"></i>Merge Requests
            <span class="badge bg-secondary ms-1">${totalMrs}</span>
        </button>
    </li>
</ul>

<div class="tab-content">

<%-- ══════════════════════════════════════════════════════════════════════ --%>
<%-- ── TASKS TAB ───────────────────────────────────────────────────────── --%>
<%-- ══════════════════════════════════════════════════════════════════════ --%>
<div class="tab-pane fade show active" id="tasksPane" role="tabpanel">

    <%-- Task stat cards — 7 across one line --%>
    <div class="row g-2 mb-3 row-cols-2 row-cols-sm-4 row-cols-lg-7">
        <div class="col">
            <div class="card shadow-sm text-center py-2">
                <div class="fw-bold" style="font-size:1.5rem;">${totalTasks}</div>
                <div class="text-muted" style="font-size:.7rem;">All</div>
            </div>
        </div>
        <div class="col">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #dc3545;">
                <div class="fw-bold" style="font-size:1.5rem;">${yetToStart}</div>
                <div class="text-muted" style="font-size:.7rem;">Yet to Start</div>
            </div>
        </div>
        <div class="col">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #fd7e14;">
                <div class="fw-bold" style="font-size:1.5rem;">${identifyingIssue}</div>
                <div class="text-muted" style="font-size:.7rem;">Identifying</div>
            </div>
        </div>
        <div class="col">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #0dcaf0;">
                <div class="fw-bold" style="font-size:1.5rem;">${fixing}</div>
                <div class="text-muted" style="font-size:.7rem;">Fixing</div>
            </div>
        </div>
        <div class="col">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #0d6efd;">
                <div class="fw-bold" style="font-size:1.5rem;">${mrCreated}</div>
                <div class="text-muted" style="font-size:.7rem;">MR Created</div>
            </div>
        </div>
        <div class="col">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #198754;">
                <div class="fw-bold" style="font-size:1.5rem;">${done}</div>
                <div class="text-muted" style="font-size:.7rem;">Done</div>
            </div>
        </div>
        <div class="col">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #6c757d;">
                <div class="fw-bold" style="font-size:1.5rem;">${paused}</div>
                <div class="text-muted" style="font-size:.7rem;">Paused</div>
            </div>
        </div>
    </div>

    <%-- Row: No MR | DI Pending | Stale Tasks (equal height) --%>
    <div class="row g-3 mb-3">

        <%-- No MR --%>
        <div class="col-lg-4 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small">
                    <span><i class="bi bi-exclamation-circle-fill text-warning me-1"></i>No MR</span>
                    <span class="badge bg-secondary">${tasksNoMr.size()}</span>
                </div>
                <div class="card-body p-0 d-flex flex-column" style="overflow-y:auto;max-height:260px;">
                    <c:choose>
                        <c:when test="${empty tasksNoMr}">
                            <p class="text-muted text-center py-3 mb-0 small flex-grow-1 d-flex align-items-center justify-content-center">
                                <i class="bi bi-check2-all me-1"></i>All have MRs
                            </p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush flex-grow-1">
                                <c:forEach var="t" items="${tasksNoMr}">
                                    <li class="list-group-item d-flex justify-content-between align-items-center py-1 px-2">
                                        <span class="text-truncate me-2 small" style="max-width:72%">
                                            <a href="/tasks/edit/${t.taskId}" class="text-decoration-none fw-semibold">#${t.taskId}</a>
                                            <span class="ms-1 text-muted">${t.description}</span>
                                        </span>
                                        <span class="badge ${t.priority.name() == 'HIGH' ? 'bg-danger' : t.priority.name() == 'MEDIUM' ? 'bg-warning text-dark' : 'bg-secondary'}" style="font-size:.65rem;">${t.priority}</span>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

        <%-- DI Pending --%>
        <div class="col-lg-4 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small">
                    <span><i class="bi bi-hourglass-split text-info me-1"></i>DI Pending</span>
                    <span class="badge bg-secondary">${tasksDiPending.size()}</span>
                </div>
                <div class="card-body p-0 d-flex flex-column" style="overflow-y:auto;max-height:260px;">
                    <c:choose>
                        <c:when test="${empty tasksDiPending}">
                            <p class="text-muted text-center py-3 mb-0 small flex-grow-1 d-flex align-items-center justify-content-center">
                                <i class="bi bi-check2-all me-1"></i>All DIs done
                            </p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush flex-grow-1">
                                <c:forEach var="t" items="${tasksDiPending}">
                                    <li class="list-group-item py-2 px-2">
                                        <div class="d-flex justify-content-between align-items-start">
                                            <span class="small">
                                                <a href="/tasks/edit/${t.taskId}" class="text-decoration-none fw-semibold">#${t.taskId}</a>
                                                <span class="ms-1 text-muted">${t.description}</span>
                                            </span>
                                        </div>
                                        <div class="mt-1 d-flex gap-1 flex-wrap">
                                            <c:if test="${t.payrollMr != null}">
                                                <span class="badge bg-warning text-dark" style="font-size:.62rem;">Payroll MR #${t.payrollMr.mrSerialNumber}</span>
                                            </c:if>
                                            <c:if test="${t.booksMr != null}">
                                                <span class="badge bg-info text-dark" style="font-size:.62rem;">Books MR #${t.booksMr.mrSerialNumber}</span>
                                            </c:if>
                                        </div>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

        <%-- Stale Tasks --%>
        <div class="col-lg-4 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1 overflow-hidden">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-hourglass text-warning me-1"></i>Stale Tasks
                    <span class="text-muted fw-normal ms-1">&gt; 3 days no change</span>
                    <span class="badge bg-secondary ms-1">${staleTasks.size()}</span>
                </div>
                <div class="card-body p-0 d-flex flex-column" style="overflow-y:auto;max-height:260px;">
                    <c:choose>
                        <c:when test="${empty staleTasks}">
                            <p class="text-muted text-center py-3 mb-0 small flex-grow-1 d-flex align-items-center justify-content-center">
                                <i class="bi bi-check2-circle me-1"></i>No stale tasks
                            </p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush flex-grow-1">
                                <c:forEach var="st" items="${staleTasks}">
                                    <li class="list-group-item py-1 px-2">
                                        <div class="d-flex justify-content-between align-items-start">
                                            <span class="small">
                                                <a href="/tasks/edit/${st.taskId}" class="fw-semibold text-decoration-none">#${st.taskId}</a>
                                                <span class="text-muted ms-1">${st.description}</span>
                                            </span>
                                            <span class="badge bg-danger ms-2 text-nowrap" style="font-size:.65rem;">${st.daysSince}d</span>
                                        </div>
                                        <div class="mt-1 d-flex gap-1">
                                            <c:choose>
                                                <c:when test="${st.statusKey == 'YET_TO_START'}"><span class="badge bg-danger" style="font-size:.6rem;">${st.status}</span></c:when>
                                                <c:when test="${st.statusKey == 'IDENTIFYING_ISSUE'}"><span class="badge bg-warning text-dark" style="font-size:.6rem;">${st.status}</span></c:when>
                                                <c:when test="${st.statusKey == 'FIXING'}"><span class="badge bg-info text-dark" style="font-size:.6rem;">${st.status}</span></c:when>
                                                <c:when test="${st.statusKey == 'MR_CREATED'}"><span class="badge bg-primary" style="font-size:.6rem;">${st.status}</span></c:when>
                                                <c:otherwise><span class="badge bg-secondary" style="font-size:.6rem;">${st.status}</span></c:otherwise>
                                            </c:choose>
                                            <span class="badge ${st.priorityKey == 'HIGH' ? 'bg-danger' : st.priorityKey == 'MEDIUM' ? 'bg-warning text-dark' : 'bg-secondary'}" style="font-size:.6rem;">${st.priority}</span>
                                        </div>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

    </div>

    <%-- Row: recent activity + avg time chart --%>
    <div class="row g-3 mb-3">

        <div class="col-lg-7">
            <div class="card shadow-sm h-100">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-clock-history me-1 text-primary"></i>Recent Task Changes
                    <span class="text-muted fw-normal ms-1">(last 10)</span>
                </div>
                <div class="card-body p-0" style="max-height:340px;overflow-y:auto;">
                    <c:choose>
                        <c:when test="${empty recentTaskActivity}">
                            <p class="text-muted text-center py-4 mb-0 small"><i class="bi bi-inbox me-1"></i>No activity yet</p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush">
                                <c:forEach var="item" items="${recentTaskActivity}">
                                    <li class="list-group-item py-2 px-3">
                                        <div class="d-flex align-items-start gap-2">
                                            <span class="mt-1"><i class="bi bi-list-task text-primary small"></i></span>
                                            <div class="flex-grow-1" style="min-width:0;">
                                                <div class="d-flex justify-content-between align-items-center">
                                                    <span class="small">
                                                        <a href="${item.entityUrl}" class="fw-semibold text-decoration-none">${item.entityLabel}</a>
                                                        <c:if test="${not empty item.entityDesc}">
                                                            <span class="text-muted ms-1">${item.entityDesc}</span>
                                                        </c:if>
                                                    </span>
                                                    <span class="text-muted text-nowrap ms-2" style="font-size:.7rem;">${item.timeAgo}</span>
                                                </div>
                                                <div class="mt-1">
                                                    <c:choose>
                                                        <c:when test="${not empty item.previousStatus}">
                                                            <span class="badge bg-light text-dark border" style="font-size:.65rem;">${item.previousStatus}</span>
                                                            <i class="bi bi-arrow-right mx-1 text-muted" style="font-size:.65rem;"></i>
                                                            <span class="badge bg-primary" style="font-size:.65rem;">${item.newStatus}</span>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <span class="text-muted" style="font-size:.65rem;">Created as</span>
                                                            <span class="badge bg-primary ms-1" style="font-size:.65rem;">${item.newStatus}</span>
                                                        </c:otherwise>
                                                    </c:choose>
                                                </div>
                                            </div>
                                        </div>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="card shadow-sm h-100">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-stopwatch me-1 text-primary"></i>Avg Time per Status
                </div>
                <div class="card-body p-2" style="position:relative;height:300px;">
                    <canvas id="avgTimeChart"></canvas>
                </div>
            </div>
        </div>

    </div>

</div><%-- /tasksPane --%>

<%-- ══════════════════════════════════════════════════════════════════════ --%>
<%-- ── MRS TAB ─────────────────────────────────────────────────────────── --%>
<%-- ══════════════════════════════════════════════════════════════════════ --%>
<div class="tab-pane fade" id="mrsPane" role="tabpanel">

    <%-- MR stat cards --%>
    <div class="row g-2 mb-3">
        <div class="col-6 col-md-4">
            <div class="card shadow-sm text-center py-2">
                <div class="fw-bold" style="font-size:1.6rem;">${totalMrs}</div>
                <div class="text-muted" style="font-size:.72rem;">Total MRs</div>
            </div>
        </div>
        <div class="col-6 col-md-4">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #ffc107;">
                <div class="fw-bold" style="font-size:1.6rem;">${totalPayrollMrs}</div>
                <div class="text-muted" style="font-size:.72rem;"><span class="badge bg-warning text-dark">Payroll</span></div>
            </div>
        </div>
        <div class="col-6 col-md-4">
            <div class="card shadow-sm text-center py-2" style="border-top:3px solid #0dcaf0;">
                <div class="fw-bold" style="font-size:1.6rem;">${totalBooksMrs}</div>
                <div class="text-muted" style="font-size:.72rem;"><span class="badge bg-info text-dark">Books</span></div>
            </div>
        </div>
    </div>

    <%-- MR pipeline bar chart --%>
    <div class="card shadow-sm mb-3">
        <div class="card-header fw-semibold py-2 small">
            <i class="bi bi-bar-chart-fill me-1 text-primary"></i>Pipeline Step Completion
            <span class="text-muted fw-normal ms-1">(MRs with each step checked — canIgnore excluded — Payroll: ${totalPayrollMrsActive} &nbsp;|&nbsp; Books: ${totalBooksMrsActive})</span>
        </div>
        <div class="card-body p-2" style="position:relative;height:180px;">
            <canvas id="mrStatusChart"></canvas>
        </div>
    </div>

    <%-- Stale MRs --%>
    <div class="row g-3 mb-3">
        <div class="col-lg-4 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1 overflow-hidden">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-hourglass text-warning me-1"></i>Stale MRs
                    <span class="text-muted fw-normal ms-1">&gt; 3 days no change</span>
                    <span class="badge bg-secondary ms-1">${staleMrs.size()}</span>
                </div>
                <div class="card-body p-0 d-flex flex-column" style="overflow-y:auto;max-height:280px;">
                    <c:choose>
                        <c:when test="${empty staleMrs}">
                            <p class="text-muted text-center py-3 mb-0 small flex-grow-1 d-flex align-items-center justify-content-center">
                                <i class="bi bi-check2-circle me-1"></i>No stale MRs
                            </p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush flex-grow-1">
                                <c:forEach var="sm" items="${staleMrs}">
                                    <li class="list-group-item py-1 px-2">
                                        <div class="d-flex justify-content-between align-items-start">
                                            <span class="small">
                                                <span class="badge ${sm.productKey == 'PAYROLL' ? 'bg-warning text-dark' : 'bg-info text-dark'} me-1" style="font-size:.6rem;">${sm.product}</span>
                                                <a href="${sm.mrUrl}" target="_blank" class="fw-semibold text-decoration-none">${sm.mrNumber}</a>
                                                <c:if test="${not empty sm.name}"><span class="text-muted ms-1">— ${sm.name}</span></c:if>
                                            </span>
                                            <span class="badge bg-danger ms-2 text-nowrap" style="font-size:.65rem;">${sm.daysSince}d</span>
                                        </div>
                                        <div class="mt-1 d-flex gap-1">
                                            <span class="badge bg-secondary" style="font-size:.6rem;">${sm.stage}</span>
                                            <a href="/mrs/edit/${sm.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1 ms-auto"><i class="bi bi-pencil" style="font-size:.65rem;"></i></a>
                                        </div>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

    </div>

    <%-- Attention blocks row 1 --%>
    <div class="row g-3 mb-3">

        <div class="col-lg-6">
            <div class="card shadow-sm h-100 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small">
                    <span><i class="bi bi-eye-slash text-danger me-1"></i>Waiting for thumbs up <span class="text-muted fw-normal">(longest first)</span></span>
                    <span class="badge bg-secondary">${mrsWaitingLongest.size()}</span>
                </div>
                <div class="card-body p-0" style="max-height:260px;overflow-y:auto;">
                    <c:choose>
                        <c:when test="${empty mrsWaitingLongest}">
                            <p class="text-muted text-center py-3 mb-0 small"><i class="bi bi-check2-all me-1"></i>All reviewed</p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush">
                                <c:forEach var="mr" items="${mrsWaitingLongest}">
                                    <li class="list-group-item d-flex justify-content-between align-items-center py-2 px-3">
                                        <span class="small">
                                            <span class="badge ${mr.productKey == 'PAYROLL' ? 'bg-warning text-dark' : 'bg-info text-dark'} me-1" style="font-size:.65rem;">${mr.product}</span>
                                            <a href="${mr.mrUrl}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                            <c:if test="${not empty mr.name}"><span class="text-muted ms-1">— ${mr.name}</span></c:if>
                                        </span>
                                        <span class="d-flex align-items-center gap-1">
                                            <span class="badge ${mr.waitDays >= 5 ? 'bg-danger' : mr.waitDays >= 2 ? 'bg-warning text-dark' : 'bg-success'}" style="font-size:.65rem;">${mr.waitLabel}</span>
                                            <a href="/mrs/edit/${mr.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1"><i class="bi bi-pencil" style="font-size:.7rem;"></i></a>
                                        </span>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

        <div class="col-lg-6">
            <div class="card shadow-sm h-100 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small">
                    <span><i class="bi bi-patch-check text-success me-1"></i>Ready for GTM</span>
                    <span class="d-flex align-items-center gap-2">
                        <button id="copyGtmAll" class="btn btn-sm btn-outline-success py-0" ${empty mrsReadyForGtm ? 'disabled' : ''}>
                            <i class="bi bi-clipboard me-1"></i>Copy All
                        </button>
                        <span class="badge bg-secondary">${mrsReadyForGtm.size()}</span>
                    </span>
                </div>
                <div class="card-body p-0" style="max-height:260px;overflow-y:auto;">
                    <c:choose>
                        <c:when test="${empty mrsReadyForGtm}">
                            <p class="text-muted text-center py-3 mb-0 small"><i class="bi bi-check2-all me-1"></i>None pending GTM</p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush" id="gtmList">
                                <c:forEach var="mr" items="${mrsReadyForGtm}">
                                    <li class="list-group-item d-flex justify-content-between align-items-center py-2 px-3 small"
                                        data-mr-number="${mr.mrNumber}" data-mr-url="${mr.mr}">
                                        <span>
                                            <span class="badge ${mr.product.name() == 'PAYROLL' ? 'bg-warning text-dark' : 'bg-info text-dark'} me-1" style="font-size:.65rem;">${mr.product.displayName}</span>
                                            <a href="${mr.mr}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                        </span>
                                        <a href="/mrs/edit/${mr.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1"><i class="bi bi-pencil" style="font-size:.7rem;"></i></a>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

    </div>

    <%-- Attention blocks row 2 --%>
    <div class="row g-3 mb-3">

        <div class="col-lg-6">
            <div class="card shadow-sm h-100 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small">
                    <span><i class="bi bi-patch-check-fill text-primary me-1"></i>Ready for RTM</span>
                    <span class="badge bg-secondary">${mrsReadyForRtm.size()}</span>
                </div>
                <div class="card-body p-0" style="max-height:260px;overflow-y:auto;">
                    <c:choose>
                        <c:when test="${empty mrsReadyForRtm}">
                            <p class="text-muted text-center py-3 mb-0 small"><i class="bi bi-check2-all me-1"></i>None pending RTM</p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush">
                                <c:forEach var="mr" items="${mrsReadyForRtm}">
                                    <li class="list-group-item d-flex justify-content-between align-items-center py-2 px-3 small">
                                        <span>
                                            <span class="badge ${mr.product.name() == 'PAYROLL' ? 'bg-warning text-dark' : 'bg-info text-dark'} me-1" style="font-size:.65rem;">${mr.product.displayName}</span>
                                            <a href="${mr.mr}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                            <button class="copy-mr-btn ms-1" data-mr="${mr.mrNumber}" data-url="${mr.mr}" onclick="copyMrMd(this)"><i class="bi bi-clipboard"></i></button>
                                        </span>
                                        <a href="/mrs/edit/${mr.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1"><i class="bi bi-pencil" style="font-size:.7rem;"></i></a>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

        <div class="col-lg-6">
            <div class="card shadow-sm h-100 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small">
                    <span><i class="bi bi-git text-secondary me-1"></i>Not yet merged</span>
                    <span class="badge bg-secondary">${mrsNotMerged.size()}</span>
                </div>
                <div class="card-body p-0" style="max-height:260px;overflow-y:auto;">
                    <c:choose>
                        <c:when test="${empty mrsNotMerged}">
                            <p class="text-muted text-center py-3 mb-0 small"><i class="bi bi-check2-all me-1"></i>All merged</p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush">
                                <c:forEach var="mr" items="${mrsNotMerged}">
                                    <li class="list-group-item d-flex justify-content-between align-items-center py-2 px-3 small">
                                        <span>
                                            <span class="badge ${mr.product.name() == 'PAYROLL' ? 'bg-warning text-dark' : 'bg-info text-dark'} me-1" style="font-size:.65rem;">${mr.product.displayName}</span>
                                            <a href="${mr.mr}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                            <button class="copy-mr-btn ms-1" data-mr="${mr.mrNumber}" data-url="${mr.mr}" onclick="copyMrMd(this)"><i class="bi bi-clipboard"></i></button>
                                        </span>
                                        <a href="/mrs/edit/${mr.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1"><i class="bi bi-pencil" style="font-size:.7rem;"></i></a>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

    </div>

</div><%-- /mrsPane --%>
</div><%-- /tab-content --%>

<%-- ── Charts ───────────────────────────────────────────────────────────── --%>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/chartjs-plugin-datalabels/2.2.0/chartjs-plugin-datalabels.min.js"></script>
<script>
(function () {
    Chart.register(ChartDataLabels);

    // MR pipeline bar
    new Chart(document.getElementById('mrStatusChart'), {
        type: 'bar',
        data: {
            labels: ['Waiting','Reviewed','DI Sched','DI Done','GTM','RTM','Merged'],
            datasets: [
                {
                    label: 'Payroll (${totalPayrollMrsActive})',
                    data: [${payrollWaiting},${payrollReviewed},${payrollDiScheduled},${payrollDiCompleted},${payrollGtm},${payrollRtm},${payrollMerged}],
                    backgroundColor:'rgba(255,193,7,.75)', borderColor:'rgba(255,193,7,1)', borderWidth:1, borderRadius:3
                },
                {
                    label: 'Books (${totalBooksMrsActive})',
                    data: [${booksWaiting},${booksReviewed},${booksDiScheduled},${booksDiCompleted},${booksGtm},${booksRtm},${booksMerged}],
                    backgroundColor:'rgba(13,202,240,.75)', borderColor:'rgba(13,202,240,1)', borderWidth:1, borderRadius:3
                }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            scales: {
                y: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                x: { grid:{ display:false }, ticks:{ font:{size:12} } }
            },
            plugins: {
                legend: { position:'bottom', labels:{ padding:10, font:{size:12}, boxWidth:14 } },
                datalabels: { display:false }
            }
        }
    });

    // Avg time horizontal bar
    var avgLabels   = [<c:forEach var="s" items="${avgStatusData}" varStatus="vs">'${s.label}'${!vs.last?',':''}</c:forEach>];
    var avgHours    = [<c:forEach var="s" items="${avgStatusData}" varStatus="vs">${s.hours}${!vs.last?',':''}</c:forEach>];
    var avgDisplays = [<c:forEach var="s" items="${avgStatusData}" varStatus="vs">'${s.display}'${!vs.last?',':''}</c:forEach>];
    var avgCounts   = [<c:forEach var="s" items="${avgStatusData}" varStatus="vs">${s.count}${!vs.last?',':''}</c:forEach>];

    new Chart(document.getElementById('avgTimeChart'), {
        type: 'bar',
        data: {
            labels: avgLabels,
            datasets: [{
                label: 'Avg time',
                data: avgHours,
                backgroundColor: ['rgba(173,181,189,.75)','rgba(253,126,20,.75)','rgba(13,202,240,.75)','rgba(13,110,253,.75)','rgba(108,117,125,.75)'],
                borderColor:     ['#adb5bd','#fd7e14','#0dcaf0','#0d6efd','#6c757d'],
                borderWidth:1, borderRadius:3
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true, maintainAspectRatio: false,
            scales: {
                x: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, title:{ display:true, text:'Hours', font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                y: { grid:{ display:false }, ticks:{ font:{size:12} } }
            },
            plugins: {
                legend: { display:false },
                tooltip: { callbacks: { label: function(c) {
                    var cnt = avgCounts[c.dataIndex];
                    return ' Avg: ' + avgDisplays[c.dataIndex] + ' (' + cnt + ' sample' + (cnt!==1?'s':'') + ')';
                }}},
                datalabels: {
                    anchor:'end', align:'end', color:'#6c757d', font:{size:10},
                    formatter: function(v,c){ return avgDisplays[c.dataIndex] !== '—' ? avgDisplays[c.dataIndex] : ''; }
                }
            }
        }
    });
})();
</script>

<script>
function copyMrMd(btn) {
    navigator.clipboard.writeText(btn.dataset.mr).then(function () {
        var i = btn.querySelector('i');
        i.className = 'bi bi-clipboard-check';
        setTimeout(function(){ i.className = 'bi bi-clipboard'; }, 2000);
    });
}
var copyGtmBtn = document.getElementById('copyGtmAll');
if (copyGtmBtn) {
    copyGtmBtn.addEventListener('click', function () {
        var lines = ["Need GTM for the MRs:\n"];
        document.querySelectorAll('#gtmList li').forEach(function(li){
            lines.push('[' + li.dataset.mrNumber + '](' + li.dataset.mrUrl + ')\n');
        });
        navigator.clipboard.writeText(lines.join('\n')).then(function(){
            copyGtmBtn.innerHTML = '<i class="bi bi-clipboard-check me-1"></i>Copied!';
            setTimeout(function(){ copyGtmBtn.innerHTML = '<i class="bi bi-clipboard me-1"></i>Copy All'; }, 2000);
        });
    });
}
</script>

<%@include file="layout/footer.jsp" %>
