<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="layout/header.jsp" %>

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
    <li class="nav-item" role="presentation">
        <button class="nav-link" id="timesheet-tab" data-bs-toggle="tab"
                data-bs-target="#timesheetPane" type="button" role="tab">
            <i class="bi bi-stopwatch me-1"></i>Time Sheet
            <span class="badge bg-secondary ms-1">${totalTimeSheetEntries}</span>
        </button>
    </li>
</ul>

<div class="tab-content">

<%-- ══════════════════════════════════════════════════════════════════════ --%>
<%-- ── TASKS TAB ───────────────────────────────────────────────────────── --%>
<%-- ══════════════════════════════════════════════════════════════════════ --%>
<div class="tab-pane fade show active" id="tasksPane" role="tabpanel">

    <%-- Task status breakdown — one row of equal-width labeled blocks (count is always
         big/bold and legible, unlike the proportional bar this replaces). flex-nowrap keeps
         it a single row; overflow-x:auto is only a fallback for very narrow viewports.
         To add a new status: add one block below with its color. --%>
    <div class="card shadow-sm mb-3">
        <div class="card-body py-3">
            <div class="d-flex justify-content-between align-items-center mb-2">
                <span class="fw-semibold"><i class="bi bi-list-task me-1"></i>Tasks by Status</span>
                <span><span class="fw-bold" style="font-size:1.25rem;">${totalTasks}</span>
                    <span class="text-muted small ms-1">total</span></span>
            </div>
            <div class="d-flex flex-nowrap gap-2" style="overflow-x:auto;">
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #dc3545 !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${yetToStart}</div>
                    <div class="text-muted" style="font-size:.65rem;">Yet to Start</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #fd7e14 !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${identifyingIssue}</div>
                    <div class="text-muted" style="font-size:.65rem;">Identifying</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #0dcaf0 !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${fixing}</div>
                    <div class="text-muted" style="font-size:.65rem;">Fixing</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #4f46e5 !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${mrCreated}</div>
                    <div class="text-muted" style="font-size:.65rem;">MR Created</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #6f42c1 !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${reworking}</div>
                    <div class="text-muted" style="font-size:.65rem;">Reworking</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #adb5bd !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${halted}</div>
                    <div class="text-muted" style="font-size:.65rem;">Halted</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #198754 !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${done}</div>
                    <div class="text-muted" style="font-size:.65rem;">Done</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #6c757d !important;min-width:84px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${paused}</div>
                    <div class="text-muted" style="font-size:.65rem;">Paused</div>
                </div>
            </div>
        </div>
    </div>

    <%-- Row: DI Pending | Stale Tasks (equal height) --%>
    <div class="row g-3 mb-3">

        <%-- DI Pending --%>
        <div class="col-lg-6 d-flex flex-column">
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
                                            <c:forEach var="mr" items="${t.mergeRequests}">
                                                <span class="badge ${mr.product.badgeClass}" style="font-size:.62rem;">${mr.product.displayName} MR #${mr.mrSerialNumber}</span>
                                            </c:forEach>
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
        <div class="col-lg-6 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center fw-semibold py-2 small">
                    <span>
                        <i class="bi bi-hourglass text-warning me-1"></i>Stale Tasks
                        <span class="text-muted fw-normal ms-1">&gt; 3 days no change</span>
                    </span>
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
                                                <c:when test="${st.statusKey == 'REWORKING'}"><span class="badge bg-dark" style="font-size:.6rem;">${st.status}</span></c:when>
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
                    <i class="bi bi-stopwatch me-1 text-primary"></i>Avg Time Spent
                </div>
                <div class="card-body p-2" style="position:relative;height:300px;">
                    <canvas id="avgTimeChart"></canvas>
                </div>
            </div>
        </div>

    </div>

    <%-- Row: tasks completed per month --%>
    <div class="row g-3 mb-3">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-graph-up me-1 text-success"></i>Tasks Completed per Month
                    <span class="text-muted fw-normal ms-1">(last 6 months)</span>
                </div>
                <div class="card-body p-2" style="position:relative;height:260px;">
                    <canvas id="tasksCompletedChart"></canvas>
                </div>
            </div>
        </div>
    </div>

</div><%-- /tasksPane --%>

<%-- ══════════════════════════════════════════════════════════════════════ --%>
<%-- ── MRS TAB ─────────────────────────────────────────────────────────── --%>
<%-- ══════════════════════════════════════════════════════════════════════ --%>
<div class="tab-pane fade" id="mrsPane" role="tabpanel">

    <%-- MR breakdown by product — same single-row labeled-block pattern as the Tasks tab.
         To add a new product: add one block below with its badge color. --%>
    <div class="card shadow-sm mb-3">
        <div class="card-body py-3">
            <div class="d-flex justify-content-between align-items-center mb-2">
                <span class="fw-semibold"><i class="bi bi-git me-1"></i>MRs by Product</span>
                <span><span class="fw-bold" style="font-size:1.25rem;">${totalMrs}</span>
                    <span class="text-muted small ms-1">total</span></span>
            </div>
            <div class="d-flex flex-nowrap gap-2" style="overflow-x:auto;">
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #ffc107 !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${totalPayrollMrs}</div>
                    <div class="text-muted" style="font-size:.68rem;">Payroll</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #0dcaf0 !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${totalBooksMrs}</div>
                    <div class="text-muted" style="font-size:.68rem;">Books</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #0d6efd !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${totalOtherMrs}</div>
                    <div class="text-muted" style="font-size:.68rem;">Spend</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #212529 !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${ignorableMrs}</div>
                    <div class="text-muted" style="font-size:.68rem;">Ignorable</div>
                </div>
            </div>
        </div>
    </div>

    <%-- Attention blocks row 1 --%>
    <div class="row g-3 mb-3">

        <div class="col-lg-6">
            <div class="card shadow-sm h-100 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small">
                    <span><i class="bi bi-eye-slash text-danger me-1"></i>Waiting for Review <span class="text-muted fw-normal">(longest first)</span></span>
                    <span class="d-flex align-items-center gap-2">
                        <button id="copyReviewAll" class="btn btn-sm btn-outline-danger py-0" ${empty mrsWaitingLongest ? 'disabled' : ''}>
                            <i class="bi bi-clipboard me-1"></i>Copy All
                        </button>
                        <span class="badge bg-secondary">${mrsWaitingLongest.size()}</span>
                    </span>
                </div>
                <div class="card-body p-0" style="max-height:260px;overflow-y:auto;">
                    <c:choose>
                        <c:when test="${empty mrsWaitingLongest}">
                            <p class="text-muted text-center py-3 mb-0 small"><i class="bi bi-check2-all me-1"></i>All reviewed</p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush" id="reviewList">
                                <c:forEach var="mr" items="${mrsWaitingLongest}">
                                    <li class="list-group-item d-flex justify-content-between align-items-center py-2 px-3"
                                        data-mr-number="${mr.mrNumber}" data-mr-url="${mr.mrUrl}">
                                        <span class="small">
                                            <span class="badge ${mr.productBadgeClass} me-1" style="font-size:.65rem;">${mr.product}</span>
                                            <a href="${mr.mrUrl}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                            <button class="copy-mr-btn ms-1" data-mr="${mr.mrNumber}" data-url="${mr.mrUrl}" onclick="copyMrMd(this)"><i class="bi bi-clipboard"></i></button>
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
                                            <span class="badge ${mr.product.badgeClass} me-1" style="font-size:.65rem;">${mr.product.displayName}</span>
                                            <a href="${mr.mr}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                            <c:if test="${not empty mr.name}"><span class="text-muted ms-1">— ${mr.name}</span></c:if>
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
                                            <span class="badge ${mr.product.badgeClass} me-1" style="font-size:.65rem;">${mr.product.displayName}</span>
                                            <a href="${mr.mr}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                            <button class="copy-mr-btn ms-1" data-mr="${mr.mrNumber}" data-url="${mr.mr}" onclick="copyMrMd(this)"><i class="bi bi-clipboard"></i></button>
                                            <c:if test="${not empty mr.name}"><span class="text-muted ms-1">— ${mr.name}</span></c:if>
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
                                            <span class="badge ${mr.product.badgeClass} me-1" style="font-size:.65rem;">${mr.product.displayName}</span>
                                            <a href="${mr.mr}" target="_blank" class="text-decoration-none fw-semibold">${mr.mrNumber}</a>
                                            <button class="copy-mr-btn ms-1" data-mr="${mr.mrNumber}" data-url="${mr.mr}" onclick="copyMrMd(this)"><i class="bi bi-clipboard"></i></button>
                                            <c:if test="${not empty mr.name}"><span class="text-muted ms-1">— ${mr.name}</span></c:if>
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

    <%-- Row: Pipeline chart | Avg Time Spent chart — equal halves --%>
    <div class="row g-3 mb-3">

        <div class="col-lg-6 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-bar-chart-fill me-1 text-primary"></i>Pipeline Stages
                    <span class="text-muted fw-normal ms-1 d-block d-xl-inline">(canIgnore excluded — Payroll: ${totalPayrollMrsActive} | Books: ${totalBooksMrsActive})</span>
                </div>
                <div class="card-body p-2" style="position:relative;height:280px;">
                    <canvas id="mrStatusChart"></canvas>
                </div>
            </div>
        </div>

        <div class="col-lg-6 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-stopwatch me-1 text-primary"></i>Avg Time Spent
                    <span class="text-muted fw-normal ms-1 d-block d-xl-inline">(time spent in each pipeline stage, across all MRs)</span>
                </div>
                <div class="card-body p-2" style="position:relative;height:280px;">
                    <canvas id="avgMrStepChart"></canvas>
                </div>
            </div>
        </div>

    </div>

    <%-- Row: Recent MR Activity | Stale MRs — equal halves --%>
    <div class="row g-3 mb-3">

        <div class="col-lg-6 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1 overflow-hidden">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-clock-history me-1 text-primary"></i>Recent MR Activity
                    <span class="text-muted fw-normal ms-1">(last 10)</span>
                </div>
                <div class="card-body p-0" style="max-height:340px;overflow-y:auto;">
                    <c:choose>
                        <c:when test="${empty recentMrActivity}">
                            <p class="text-muted text-center py-4 mb-0 small"><i class="bi bi-inbox me-1"></i>No activity yet</p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush">
                                <c:forEach var="item" items="${recentMrActivity}">
                                    <li class="list-group-item py-2 px-3">
                                        <div class="d-flex align-items-start gap-2">
                                            <span class="mt-1"><i class="bi bi-git text-primary small"></i></span>
                                            <div class="flex-grow-1" style="min-width:0;">
                                                <div class="d-flex justify-content-between align-items-center">
                                                    <span class="small">
                                                        <span class="badge ${item.productBadgeClass} me-1" style="font-size:.65rem;">${item.product}</span>
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

        <div class="col-lg-6 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1 overflow-hidden">
                <div class="card-header d-flex justify-content-between align-items-center fw-semibold py-2 small">
                    <span>
                        <i class="bi bi-hourglass text-warning me-1"></i>Stale MRs
                        <span class="text-muted fw-normal ms-1">&gt; 3 days no change</span>
                    </span>
                    <span class="badge bg-secondary ms-1">${staleMrs.size()}</span>
                </div>
                <div class="card-body p-0 d-flex flex-column" style="overflow-y:auto;max-height:340px;">
                    <c:choose>
                        <c:when test="${empty staleMrs}">
                            <p class="text-muted text-center py-3 mb-0 small flex-grow-1 d-flex align-items-center justify-content-center">
                                <i class="bi bi-check2-circle me-1"></i>No stale MRs
                            </p>
                        </c:when>
                        <c:otherwise>
                            <ul class="list-group list-group-flush flex-grow-1">
                                <c:forEach var="sm" items="${staleMrs}">
                                    <li class="list-group-item d-flex justify-content-between align-items-center py-2 px-3">
                                        <span class="small">
                                            <span class="badge ${sm.productBadgeClass} me-1" style="font-size:.65rem;">${sm.product}</span>
                                            <a href="${sm.mrUrl}" target="_blank" class="fw-semibold text-decoration-none">${sm.mrNumber}</a>
                                            <span class="badge bg-secondary ms-1" style="font-size:.6rem;">${sm.stage}</span>
                                            <c:if test="${not empty sm.name}"><span class="text-muted ms-1">— ${sm.name}</span></c:if>
                                        </span>
                                        <span class="d-flex align-items-center gap-1">
                                            <span class="badge bg-danger text-nowrap" style="font-size:.65rem;">${sm.daysSince}d</span>
                                            <a href="/mrs/edit/${sm.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1"><i class="bi bi-pencil" style="font-size:.65rem;"></i></a>
                                        </span>
                                    </li>
                                </c:forEach>
                            </ul>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>

    <%-- Row: MRs merged per month --%>
    <div class="row g-3 mb-3">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-graph-up me-1 text-success"></i>MRs Merged per Month
                    <span class="text-muted fw-normal ms-1">(last 6 months)</span>
                </div>
                <div class="card-body p-2" style="position:relative;height:260px;">
                    <canvas id="mrsMergedChart"></canvas>
                </div>
            </div>
        </div>
    </div>

</div><%-- /mrsPane --%>

<%-- ══════════════════════════════════════════════════════════════════════ --%>
<%-- ── TIME SHEET TAB ──────────────────────────────────────────────────── --%>
<%-- ══════════════════════════════════════════════════════════════════════ --%>
<div class="tab-pane fade" id="timesheetPane" role="tabpanel">

    <%-- Time Sheet summary — same single-row labeled-block pattern as Tasks/MR tabs. --%>
    <div class="card shadow-sm mb-3">
        <div class="card-body py-3">
            <div class="d-flex justify-content-between align-items-center mb-2">
                <span class="fw-semibold"><i class="bi bi-stopwatch me-1"></i>Time Sheet Summary</span>
                <span><span class="fw-bold" style="font-size:1.25rem;">${totalTimeSheetEntries}</span>
                    <span class="text-muted small ms-1">entries</span></span>
            </div>
            <div class="d-flex flex-nowrap gap-2" style="overflow-x:auto;">
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #198754 !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${totalLoggedLabel}</div>
                    <div class="text-muted" style="font-size:.68rem;">Total Logged</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #ffc107 !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${weekLoggedLabel}</div>
                    <div class="text-muted" style="font-size:.68rem;">This Week</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #4f46e5 !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${todayLoggedLabel}</div>
                    <div class="text-muted" style="font-size:.68rem;">Today</div>
                </div>
                <div class="flex-fill text-center rounded py-2 border shadow-sm" style="border-top:3px solid #dc3545 !important;min-width:110px;">
                    <div class="fw-bold" style="font-size:1.3rem;">${openTimeSheetEntries}</div>
                    <div class="text-muted" style="font-size:.68rem;">Missing End Time</div>
                </div>
            </div>
        </div>
    </div>

    <%-- Row: Hours by Task | Daily Trend --%>
    <div class="row g-3 mb-3">

        <div class="col-lg-6 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-bar-chart-fill me-1 text-primary"></i>Hours by Task
                    <span class="text-muted fw-normal ms-1">(top 10)</span>
                </div>
                <div class="card-body p-2" style="position:relative;height:320px;">
                    <c:choose>
                        <c:when test="${empty hoursByTask}">
                            <p class="text-muted text-center py-4 mb-0 small"><i class="bi bi-inbox me-1"></i>No time sheet entries yet</p>
                        </c:when>
                        <c:otherwise>
                            <canvas id="hoursByTaskChart"></canvas>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>

        <div class="col-lg-6 d-flex flex-column">
            <div class="card shadow-sm flex-grow-1">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-graph-up me-1 text-success"></i>Daily Trend
                    <span class="text-muted fw-normal ms-1">(last 14 days)</span>
                </div>
                <div class="card-body p-2" style="position:relative;height:320px;">
                    <canvas id="dailyTrendChart"></canvas>
                </div>
            </div>
        </div>

    </div>

    <%-- Row: Hours by Task — This Week --%>
    <div class="row g-3 mb-3">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header fw-semibold py-2 small">
                    <i class="bi bi-calendar-week me-1 text-warning"></i>Hours by Task — This Week
                    <span class="text-muted fw-normal ms-1">(Week of ${weekRangeLabel})</span>
                </div>
                <div class="card-body p-2" style="position:relative;height:300px;">
                    <c:choose>
                        <c:when test="${empty hoursByTaskThisWeek}">
                            <p class="text-muted text-center py-4 mb-0 small"><i class="bi bi-inbox me-1"></i>No time sheet entries logged this week yet</p>
                        </c:when>
                        <c:otherwise>
                            <canvas id="hoursByTaskWeekChart"></canvas>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>

    <%-- Row: Daily hours for a picked task --%>
    <div class="row g-3 mb-3">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header d-flex justify-content-between align-items-center py-2 small flex-wrap gap-2">
                    <span class="fw-semibold"><i class="bi bi-search me-1 text-primary"></i>Daily Hours for a Task</span>
                    <div class="position-relative" style="max-width:380px;width:100%;">
                        <div class="input-group input-group-sm">
                            <input type="text" id="taskDailyText" class="form-control form-control-sm"
                                   placeholder="${empty taskDailyBreakdown ? 'No tasks with logged time yet' : 'Type to search for a task…'}"
                                   autocomplete="off" ${empty taskDailyBreakdown ? 'disabled' : ''}/>
                            <button type="button" class="btn btn-outline-secondary" id="taskDailyClear" title="Clear" ${empty taskDailyBreakdown ? 'disabled' : ''}><i class="bi bi-x-lg"></i></button>
                        </div>
                        <input type="hidden" id="taskDailySelect"/>
                        <ul id="taskDailyList" class="list-group position-absolute w-100 shadow"
                            style="z-index:1050;max-height:220px;overflow-y:auto;display:none;top:100%;left:0;"></ul>
                    </div>
                </div>
                <div class="card-body p-2" style="position:relative;height:300px;">
                    <c:choose>
                        <c:when test="${empty taskDailyBreakdown}">
                            <p class="text-muted text-center py-4 mb-0 small"><i class="bi bi-inbox me-1"></i>No time sheet entries linked to a task yet</p>
                        </c:when>
                        <c:otherwise>
                            <canvas id="taskDailyChart"></canvas>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>

</div><%-- /timesheetPane --%>
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
            labels: ['New','Reviewed','DI Done','GTM','RTM','Merged'],
            datasets: [
                {
                    label: 'Payroll (${totalPayrollMrsActive})',
                    data: [${payrollNew},${payrollReviewed},${payrollDiCompleted},${payrollGtm},${payrollRtm},${payrollMerged}],
                    backgroundColor:'rgba(255,193,7,.75)', borderColor:'rgba(255,193,7,1)', borderWidth:1, borderRadius:3
                },
                {
                    label: 'Books (${totalBooksMrsActive})',
                    data: [${booksNew},${booksReviewed},${booksDiCompleted},${booksGtm},${booksRtm},${booksMerged}],
                    backgroundColor:'rgba(13,202,240,.75)', borderColor:'rgba(13,202,240,1)', borderWidth:1, borderRadius:3
                }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            scales: {
                y: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                x: { grid:{ display:false }, ticks:{ font:{size:11} } }
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
                backgroundColor: ['rgba(173,181,189,.75)','rgba(253,126,20,.75)','rgba(13,202,240,.75)','rgba(79,70,229,.75)','rgba(108,117,125,.75)'],
                borderColor:     ['#adb5bd','#fd7e14','#0dcaf0','#4f46e5','#6c757d'],
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

    // Avg time per MR pipeline stage — horizontal bar
    var mrStepLabels   = [<c:forEach var="s" items="${avgMrStageData}" varStatus="vs">'${s.label}'${!vs.last?',':''}</c:forEach>];
    var mrStepHours     = [<c:forEach var="s" items="${avgMrStageData}" varStatus="vs">${s.hours}${!vs.last?',':''}</c:forEach>];
    var mrStepDisplays = [<c:forEach var="s" items="${avgMrStageData}" varStatus="vs">'${s.display}'${!vs.last?',':''}</c:forEach>];
    var mrStepCounts   = [<c:forEach var="s" items="${avgMrStageData}" varStatus="vs">${s.count}${!vs.last?',':''}</c:forEach>];

    new Chart(document.getElementById('avgMrStepChart'), {
        type: 'bar',
        data: {
            labels: mrStepLabels,
            datasets: [{
                label: 'Avg lead time',
                data: mrStepHours,
                backgroundColor: 'rgba(25,135,84,.75)',
                borderColor: '#198754',
                borderWidth: 1, borderRadius: 3
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
                    var cnt = mrStepCounts[c.dataIndex];
                    return ' Avg: ' + mrStepDisplays[c.dataIndex] + ' (' + cnt + ' MR' + (cnt!==1?'s':'') + ')';
                }}},
                datalabels: {
                    anchor:'end', align:'end', color:'#6c757d', font:{size:10},
                    formatter: function(v,c){ return mrStepDisplays[c.dataIndex] !== '—' ? mrStepDisplays[c.dataIndex] : ''; }
                }
            }
        }
    });

    // Tasks completed per month — last 6 months
    var tasksCompletedLabels = [<c:forEach var="m" items="${tasksCompletedByMonth}" varStatus="vs">'${m.label}'${!vs.last?',':''}</c:forEach>];
    var tasksCompletedCounts = [<c:forEach var="m" items="${tasksCompletedByMonth}" varStatus="vs">${m.count}${!vs.last?',':''}</c:forEach>];

    new Chart(document.getElementById('tasksCompletedChart'), {
        type: 'bar',
        data: {
            labels: tasksCompletedLabels,
            datasets: [{
                label: 'Tasks completed',
                data: tasksCompletedCounts,
                backgroundColor: 'rgba(25,135,84,.75)',
                borderColor: '#198754',
                borderWidth: 1, borderRadius: 3,
                maxBarThickness: 60
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            scales: {
                y: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                x: { grid:{ display:false }, ticks:{ font:{size:12} } }
            },
            plugins: {
                legend: { display:false },
                tooltip: { callbacks: { label: function(c) { return ' ' + c.parsed.y + ' completed'; } } },
                datalabels: { anchor:'end', align:'end', color:'#6c757d', font:{size:11},
                    formatter: function(v) { return v > 0 ? v : ''; } }
            }
        }
    });

    // MRs merged per month — last 6 months
    var mrsMergedLabels = [<c:forEach var="m" items="${mrsMergedByMonth}" varStatus="vs">'${m.label}'${!vs.last?',':''}</c:forEach>];
    var mrsMergedCounts = [<c:forEach var="m" items="${mrsMergedByMonth}" varStatus="vs">${m.count}${!vs.last?',':''}</c:forEach>];

    new Chart(document.getElementById('mrsMergedChart'), {
        type: 'bar',
        data: {
            labels: mrsMergedLabels,
            datasets: [{
                label: 'MRs merged',
                data: mrsMergedCounts,
                backgroundColor: 'rgba(79,70,229,.75)',
                borderColor: '#4f46e5',
                borderWidth: 1, borderRadius: 3,
                maxBarThickness: 60
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            scales: {
                y: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                x: { grid:{ display:false }, ticks:{ font:{size:12} } }
            },
            plugins: {
                legend: { display:false },
                tooltip: { callbacks: { label: function(c) { return ' ' + c.parsed.y + ' merged'; } } },
                datalabels: { anchor:'end', align:'end', color:'#6c757d', font:{size:11},
                    formatter: function(v) { return v > 0 ? v : ''; } }
            }
        }
    });
    // Hours by task — horizontal bar
    var hoursByTaskLabels = [<c:forEach var="h" items="${hoursByTask}" varStatus="vs">'${fn:replace(h.label, "'", "\\'")}'${!vs.last?',':''}</c:forEach>];
    var hoursByTaskHours  = [<c:forEach var="h" items="${hoursByTask}" varStatus="vs">${h.hours}${!vs.last?',':''}</c:forEach>];

    var hoursByTaskCanvas = document.getElementById('hoursByTaskChart');
    if (hoursByTaskCanvas) {
        new Chart(hoursByTaskCanvas, {
            type: 'bar',
            data: {
                labels: hoursByTaskLabels,
                datasets: [{
                    label: 'Hours',
                    data: hoursByTaskHours,
                    backgroundColor: 'rgba(79,70,229,.75)',
                    borderColor: '#4f46e5',
                    borderWidth: 1, borderRadius: 3
                }]
            },
            options: {
                indexAxis: 'y',
                responsive: true, maintainAspectRatio: false,
                scales: {
                    x: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, title:{ display:true, text:'Hours', font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                    y: { grid:{ display:false }, ticks:{ font:{size:11} } }
                },
                plugins: {
                    legend: { display:false },
                    tooltip: { callbacks: { label: function(c) { return ' ' + c.parsed.x + 'h'; } } },
                    datalabels: { anchor:'end', align:'end', color:'#6c757d', font:{size:10},
                        formatter: function(v) { return v > 0 ? v + 'h' : ''; } }
                }
            }
        });
    }

    // Hours by task — this week only
    var hoursByTaskWeekLabels = [<c:forEach var="h" items="${hoursByTaskThisWeek}" varStatus="vs">'${fn:replace(h.label, "'", "\\'")}'${!vs.last?',':''}</c:forEach>];
    var hoursByTaskWeekHours  = [<c:forEach var="h" items="${hoursByTaskThisWeek}" varStatus="vs">${h.hours}${!vs.last?',':''}</c:forEach>];

    var hoursByTaskWeekCanvas = document.getElementById('hoursByTaskWeekChart');
    if (hoursByTaskWeekCanvas) {
        new Chart(hoursByTaskWeekCanvas, {
            type: 'bar',
            data: {
                labels: hoursByTaskWeekLabels,
                datasets: [{
                    label: 'Hours',
                    data: hoursByTaskWeekHours,
                    backgroundColor: 'rgba(255,193,7,.75)',
                    borderColor: '#ffc107',
                    borderWidth: 1, borderRadius: 3,
                    maxBarThickness: 50
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, title:{ display:true, text:'Hours', font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                    x: { grid:{ display:false }, ticks:{ font:{size:11} } }
                },
                plugins: {
                    legend: { display:false },
                    tooltip: { callbacks: { label: function(c) { return ' ' + c.parsed.y + 'h'; } } },
                    datalabels: { anchor:'end', align:'end', color:'#6c757d', font:{size:10},
                        formatter: function(v) { return v > 0 ? v + 'h' : ''; } }
                }
            }
        });
    }

    // Daily hours for a picked task — data for every task that has logged time,
    // keyed by taskId; the dropdown below picks which one renders.
    var taskDailyData = {};
    <c:forEach var="t" items="${taskDailyBreakdown}">
    taskDailyData[${t.taskId}] = {
        labels: [<c:forEach var="d" items="${t.days}" varStatus="vs">'${d.label}'${!vs.last?',':''}</c:forEach>],
        hours:  [<c:forEach var="d" items="${t.days}" varStatus="vs">${d.hours}${!vs.last?',':''}</c:forEach>]
    };
    </c:forEach>

    var taskDailyCanvas = document.getElementById('taskDailyChart');
    var taskDailyChart  = null;

    function renderTaskDailyChart(taskId) {
        var data = taskDailyData[taskId] || { labels: [], hours: [] };
        if (taskDailyChart) {
            taskDailyChart.data.labels = data.labels;
            taskDailyChart.data.datasets[0].data = data.hours;
            taskDailyChart.update();
            return;
        }
        taskDailyChart = new Chart(taskDailyCanvas, {
            type: 'bar',
            data: {
                labels: data.labels,
                datasets: [{
                    label: 'Hours',
                    data: data.hours,
                    backgroundColor: 'rgba(111,66,193,.75)',
                    borderColor: '#6f42c1',
                    borderWidth: 1, borderRadius: 3,
                    maxBarThickness: 50
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, title:{ display:true, text:'Hours', font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                    x: { grid:{ display:false }, ticks:{ font:{size:10} } }
                },
                plugins: {
                    legend: { display:false },
                    tooltip: { callbacks: { label: function(c) { return ' ' + c.parsed.y + 'h'; } } },
                    datalabels: { anchor:'end', align:'end', color:'#6c757d', font:{size:10},
                        formatter: function(v) { return v > 0 ? v + 'h' : ''; } }
                }
            }
        });
    }

    // Typeahead data: {id, label} for every task with logged time — same search pattern
    // used for the Parent MR / Time Sheet task pickers, so this list stays usable as it grows.
    var taskDailyPickerData = [
        <c:forEach var="t" items="${taskDailyBreakdown}" varStatus="vs">
        {id: ${t.taskId}, label: '${fn:replace(t.taskLabel, "'", "\\'")}'}${!vs.last?',':''}
        </c:forEach>
    ];

    var taskDailyTextInput = document.getElementById('taskDailyText');
    var taskDailyHiddenId  = document.getElementById('taskDailySelect');
    var taskDailyListEl    = document.getElementById('taskDailyList');
    var taskDailyClearBtn  = document.getElementById('taskDailyClear');

    function renderTaskDailyList(q) {
        taskDailyListEl.innerHTML = '';
        var lower = q ? q.toLowerCase() : '';
        var matches = q
            ? taskDailyPickerData.filter(function (t) {
                return String(t.id).indexOf(lower) !== -1 || t.label.toLowerCase().indexOf(lower) !== -1;
              })
            : [];
        if (!matches.length) { taskDailyListEl.style.display = 'none'; return; }
        matches.forEach(function (t) {
            var li = document.createElement('li');
            li.className = 'list-group-item list-group-item-action py-2';
            li.style.cursor = 'pointer';
            li.textContent = t.label;
            li.addEventListener('mousedown', function (e) {
                e.preventDefault();
                taskDailyTextInput.value = t.label;
                taskDailyHiddenId.value  = t.id;
                taskDailyListEl.style.display = 'none';
                renderTaskDailyChart(t.id);
            });
            taskDailyListEl.appendChild(li);
        });
        taskDailyListEl.style.display = 'block';
    }

    if (taskDailyCanvas && taskDailyTextInput) {
        taskDailyTextInput.addEventListener('input', function () { renderTaskDailyList(this.value); });
        taskDailyTextInput.addEventListener('focus', function () { if (this.value) renderTaskDailyList(this.value); });
        taskDailyTextInput.addEventListener('blur',  function () { setTimeout(function () { taskDailyListEl.style.display = 'none'; }, 200); });
        taskDailyClearBtn.addEventListener('click', function () {
            taskDailyTextInput.value = '';
            taskDailyHiddenId.value  = '';
            taskDailyListEl.style.display = 'none';
            taskDailyTextInput.focus();
        });

        // Default to the first task, same starting behavior as the old dropdown
        if (taskDailyPickerData.length) {
            taskDailyTextInput.value = taskDailyPickerData[0].label;
            taskDailyHiddenId.value  = taskDailyPickerData[0].id;
            renderTaskDailyChart(taskDailyPickerData[0].id);
        }
    }

    // Daily hours trend — last 14 days
    var dailyTrendLabels = [<c:forEach var="d" items="${dailyHoursTrend}" varStatus="vs">'${d.label}'${!vs.last?',':''}</c:forEach>];
    var dailyTrendHours  = [<c:forEach var="d" items="${dailyHoursTrend}" varStatus="vs">${d.hours}${!vs.last?',':''}</c:forEach>];

    new Chart(document.getElementById('dailyTrendChart'), {
        type: 'bar',
        data: {
            labels: dailyTrendLabels,
            datasets: [{
                label: 'Hours logged',
                data: dailyTrendHours,
                backgroundColor: 'rgba(25,135,84,.75)',
                borderColor: '#198754',
                borderWidth: 1, borderRadius: 3,
                maxBarThickness: 40
            }]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            scales: {
                y: { beginAtZero:true, ticks:{ precision:0, font:{size:12} }, title:{ display:true, text:'Hours', font:{size:12} }, grid:{ color:'rgba(0,0,0,.05)' } },
                x: { grid:{ display:false }, ticks:{ font:{size:10} } }
            },
            plugins: {
                legend: { display:false },
                tooltip: { callbacks: { label: function(c) { return ' ' + c.parsed.y + 'h logged'; } } },
                datalabels: { anchor:'end', align:'end', color:'#6c757d', font:{size:10},
                    formatter: function(v) { return v > 0 ? v + 'h' : ''; } }
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

var copyReviewBtn = document.getElementById('copyReviewAll');
if (copyReviewBtn) {
    copyReviewBtn.addEventListener('click', function () {
        var lines = ["Need review for the MRs:\n"];
        document.querySelectorAll('#reviewList li').forEach(function(li){
            lines.push('[' + li.dataset.mrNumber + '](' + li.dataset.mrUrl + ')\n');
        });
        navigator.clipboard.writeText(lines.join('\n')).then(function(){
            copyReviewBtn.innerHTML = '<i class="bi bi-clipboard-check me-1"></i>Copied!';
            setTimeout(function(){ copyReviewBtn.innerHTML = '<i class="bi bi-clipboard me-1"></i>Copy All'; }, 2000);
        });
    });
}
</script>

<%@include file="layout/footer.jsp" %>
