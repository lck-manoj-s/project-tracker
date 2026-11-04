<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>

<link rel="stylesheet" href="/css/lists.css">
<link rel="stylesheet" href="/css/timesheet.css">

<%-- ── Page header ────────────────────────────────────────────────────── --%>
<div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="mb-0"><i class="bi bi-bar-chart-steps me-2"></i>Weekly Report</h4>
    <a href="/timesheet" class="btn btn-outline-secondary btn-sm">
        <i class="bi bi-stopwatch me-1"></i>Time Sheet
    </a>
</div>

<%-- ── Week navigation ─────────────────────────────────────────────────── --%>
<div class="d-flex align-items-center justify-content-center gap-2 mb-4 flex-wrap">
    <a href="/timesheet/report?weekOffset=${prevOffset}" class="btn-pager">
        <i class="bi bi-chevron-left"></i>Prev
    </a>
    <span class="fw-semibold px-3 text-center" style="min-width:260px;">
        <i class="bi bi-calendar-week me-1 text-primary"></i>${weekRangeLabel}
    </span>
    <c:choose>
        <c:when test="${isCurrentWeek}">
            <span class="btn-pager is-disabled">Next<i class="bi bi-chevron-right"></i></span>
        </c:when>
        <c:otherwise>
            <a href="/timesheet/report?weekOffset=${nextOffset}" class="btn-pager">
                Next<i class="bi bi-chevron-right"></i>
            </a>
        </c:otherwise>
    </c:choose>
    <c:if test="${!isCurrentWeek}">
        <a href="/timesheet/report?weekOffset=0" class="btn-pager ms-2">
            Current Week
        </a>
    </c:if>
</div>

<%-- ── Summary cards ──────────────────────────────────────────────────── --%>
<div class="row g-2 mb-4">
    <div class="col-6 col-md-4">
        <div class="card shadow-sm text-center py-3" style="border-top:3px solid #4f46e5;">
            <div class="fw-bold" style="font-size:1.5rem;">${totalLabel}</div>
            <div class="text-muted" style="font-size:.72rem;">Total Hours Logged</div>
        </div>
    </div>
    <div class="col-6 col-md-4">
        <div class="card shadow-sm text-center py-3" style="border-top:3px solid #10b981;">
            <div class="fw-bold" style="font-size:1.5rem;">${daysLogged}</div>
            <div class="text-muted" style="font-size:.72rem;">Days with Entries</div>
        </div>
    </div>
    <div class="col-6 col-md-4">
        <div class="card shadow-sm text-center py-3" style="border-top:3px solid #f59e0b;">
            <div class="fw-bold" style="font-size:1.5rem;">${taskCount}</div>
            <div class="text-muted" style="font-size:.72rem;">Tasks Worked On</div>
        </div>
    </div>
</div>

<%-- ── Hours by Day chart ──────────────────────────────────────────────── --%>
<div class="card shadow-sm mb-4">
    <div class="card-header py-2 d-flex justify-content-between align-items-center">
        <span class="fw-semibold"><i class="bi bi-bar-chart-fill me-1 text-primary"></i>Hours by Day</span>
        <span class="text-muted small">${totalEntries} log entries</span>
    </div>
    <div class="card-body" style="height:220px; position:relative;">
        <canvas id="hoursChart"></canvas>
    </div>
</div>

<%-- ── Task Breakdown ──────────────────────────────────────────────────── --%>
<c:choose>
    <c:when test="${not empty taskBreakdown}">
        <div class="card shadow-sm mb-4">
            <div class="card-header py-2">
                <span class="fw-semibold"><i class="bi bi-list-check me-1 text-success"></i>Task Breakdown</span>
            </div>
            <div class="table-responsive">
                <table class="table table-sm table-hover mb-0 align-middle">
                    <thead class="table-light">
                        <tr>
                            <th class="ps-3" style="width:55px;">Task</th>
                            <th>Description</th>
                            <th style="width:120px;">Status</th>
                            <th class="text-end pe-3" style="width:90px;">Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="t" items="${taskBreakdown}">
                        <tr>
                            <td class="ps-3">
                                <a href="/tasks/edit/${t.taskId}" class="text-decoration-none fw-semibold small text-primary">#${t.taskId}</a>
                            </td>
                            <td class="small text-truncate" style="max-width:340px;">
                                ${fn:substring(t.description, 0, 80)}${fn:length(t.description) > 80 ? '…' : ''}
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${t.statusName == 'YET_TO_START'}"><span class="pill pill-red"><i class="bi bi-circle"></i>${t.status}</span></c:when>
                                    <c:when test="${t.statusName == 'IDENTIFYING_ISSUE'}"><span class="pill pill-amber"><i class="bi bi-search"></i>${t.status}</span></c:when>
                                    <c:when test="${t.statusName == 'FIXING'}"><span class="pill pill-teal"><i class="bi bi-wrench"></i>${t.status}</span></c:when>
                                    <c:when test="${t.statusName == 'MR_CREATED'}"><span class="pill pill-blue"><i class="bi bi-git"></i>${t.status}</span></c:when>
                                    <c:when test="${t.statusName == 'REWORKING'}"><span class="pill pill-purple"><i class="bi bi-arrow-repeat"></i>${t.status}</span></c:when>
                                    <c:when test="${t.statusName == 'DONE'}"><span class="pill pill-green"><i class="bi bi-check-circle"></i>${t.status}</span></c:when>
                                    <c:otherwise><span class="pill pill-gray"><i class="bi bi-pause-circle"></i>${t.status}</span></c:otherwise>
                                </c:choose>
                            </td>
                            <td class="text-end pe-3 fw-semibold small text-primary">${t.hoursLabel}</td>
                        </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>
    </c:when>
    <c:when test="${totalEntries > 0}">
        <%-- Entries exist but none linked to tasks --%>
        <div class="alert alert-light border small mb-4">
            <i class="bi bi-info-circle me-1"></i>
            ${totalEntries} entries logged this week — none linked to a task.
        </div>
    </c:when>
</c:choose>

<%-- ── Detailed day log ─────────────────────────────────────────────────── --%>
<div class="section-label mb-2"><i class="bi bi-list-ul me-1"></i>Detailed Log</div>

<c:choose>
    <c:when test="${empty dayGroups}">
        <div class="card shadow-sm">
            <div class="card-body text-center text-muted py-5">
                <i class="bi bi-inbox fs-3 d-block mb-2"></i>
                No time sheet entries for this week.<br>
                <c:if test="${isCurrentWeek}">
                    <a href="/timesheet/new" class="btn btn-sm btn-primary mt-3">
                        <i class="bi bi-plus-lg me-1"></i>Add Entry
                    </a>
                </c:if>
            </div>
        </div>
    </c:when>
    <c:otherwise>
        <c:forEach var="group" items="${dayGroups}" varStatus="gs">
            <div class="card shadow-sm mb-3">
                <div class="d-flex justify-content-between align-items-center py-3 px-3 day-toggle"
                     data-bs-toggle="collapse" data-bs-target="#dayBody${gs.index}" role="button"
                     aria-expanded="${gs.index == 0 ? 'true' : 'false'}" aria-controls="dayBody${gs.index}">
                    <span class="d-flex align-items-center gap-2 fw-bold">
                        <i class="bi bi-calendar3 text-primary"></i>${group.dateLabel}
                        <c:if test="${group.isToday}">
                            <span class="pill pill-blue">Today</span>
                        </c:if>
                        <c:if test="${group.hasOpenEntry}">
                            <span class="pill pill-amber">
                                <i class="bi bi-exclamation-triangle"></i>Missing end time
                            </span>
                        </c:if>
                    </span>
                    <span class="d-flex align-items-center gap-2">
                        <span class="pill pill-gray">${fn:length(group.entries)} Logs</span>
                        <span class="pill pill-blue">${group.totalLabel}</span>
                        <i class="bi bi-chevron-down text-muted" style="font-size:.8rem;"></i>
                    </span>
                </div>
                <div class="collapse ${gs.index == 0 ? 'show' : ''}" id="dayBody${gs.index}">
                    <ul class="list-group list-group-flush">
                        <c:forEach var="e" items="${group.entries}">
                            <li class="list-group-item ts-row d-flex justify-content-between align-items-center py-3 px-3 ${e.endTime == null ? 'ts-row-open' : ''}">
                                <div class="me-3" style="min-width:0;">
                                    <div class="fw-semibold small text-truncate">${fn:escapeXml(e.activity)}</div>
                                    <c:if test="${e.task != null}">
                                        <a href="/tasks/edit/${e.task.taskId}"
                                           class="text-muted text-decoration-none text-truncate d-block"
                                           style="font-size:.72rem;">
                                            Task #${e.task.taskId} · ${fn:substring(e.task.description, 0, fn:length(e.task.description) > 50 ? 50 : fn:length(e.task.description))}${fn:length(e.task.description) > 50 ? '…' : ''}
                                        </a>
                                    </c:if>
                                </div>
                                <div class="d-flex align-items-center gap-4 text-nowrap">
                                    <span class="text-muted small">
                                        <c:choose>
                                            <c:when test="${e.endTime != null}">${e.startTime} – ${e.endTime}</c:when>
                                            <c:otherwise>${e.startTime} – …</c:otherwise>
                                        </c:choose>
                                    </span>
                                    <span class="small ${e.endTime == null ? 'text-warning fw-semibold' : 'text-muted'}">
                                        <i class="bi bi-clock me-1"></i>${e.durationLabel}
                                    </span>
                                    <c:if test="${isCurrentWeek}">
                                        <span class="d-flex align-items-center gap-1">
                                            <a href="/timesheet/edit/${e.id}" class="btn btn-sm btn-outline-secondary py-0 px-1">
                                                <i class="bi bi-pencil" style="font-size:.7rem;"></i>
                                            </a>
                                        </span>
                                    </c:if>
                                </div>
                            </li>
                        </c:forEach>
                    </ul>
                </div>
            </div>
        </c:forEach>
    </c:otherwise>
</c:choose>

<script>
(function () {
    var ctx = document.getElementById('hoursChart');
    if (!ctx) return;

    var labels = ${chartLabelsJson};
    var data   = ${chartHoursJson};

    // Highlight today's bar if it falls within this week
    var today = new Date();
    var todayIdx = today.getDay() === 0 ? 6 : today.getDay() - 1; // Mon=0 … Sun=6

    // Today = brand blue (#0d6efd); other days = soft indigo, same family as the app's accents
    var colors = data.map(function (_, i) {
        return i === todayIdx
            ? 'rgba(13,110,253,0.9)'    // brand blue for today
            : 'rgba(79,70,229,0.55)';   // soft indigo for other days
    });
    var borders = data.map(function (_, i) {
        return i === todayIdx ? 'rgba(13,110,253,1)' : 'rgba(79,70,229,1)';
    });

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Hours',
                data: data,
                backgroundColor: colors,
                borderColor: borders,
                borderWidth: 1,
                borderRadius: 5
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: function (ctx) {
                            return ctx.parsed.y === 0 ? 'No entries' : ctx.parsed.y + 'h';
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function (v) { return v + 'h'; },
                        stepSize: 1
                    },
                    grid: { color: 'rgba(0,0,0,.06)' }
                },
                x: {
                    grid: { display: false }
                }
            }
        }
    });
})();
</script>

<%@include file="../layout/footer.jsp" %>
