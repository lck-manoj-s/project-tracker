<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>

<c:if test="${not empty successMessage}">
    <span id="flashSuccessMsg" data-message="${fn:escapeXml(successMessage)}" hidden></span>
    <script>
    document.addEventListener('DOMContentLoaded', function () {
        var el = document.getElementById('flashSuccessMsg');
        if (el) showToast(el.dataset.message, 'success');
    });
    </script>
</c:if>

<style>
  .day-toggle {
      cursor: pointer;
      background: #f8f9fa;
      color: #212529;
      border-bottom: 1px solid #e9ecef;
      border-radius: .375rem .375rem 0 0;
  }

  .ts-row-open { background: rgba(255,193,7,.06); }
  .ts-row:hover { background: #f8f9fa; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="mb-0"><i class="bi bi-stopwatch me-2"></i>Time Sheet</h4>
    <a href="/timesheet/new" class="btn btn-primary btn-sm">
        <i class="bi bi-plus-lg me-1"></i>Add Entry
    </a>
</div>

<%-- ── Summary cards ────────────────────────────────────────────────── --%>
<div class="row g-2 mb-3">
    <div class="col-6 col-md-3">
        <div class="card shadow-sm text-center py-2" style="border-top:3px solid #4f46e5;">
            <div class="fw-bold" style="font-size:1.4rem;">${todayLabel}</div>
            <div class="text-muted" style="font-size:.72rem;">Logged Today</div>
        </div>
    </div>
    <div class="col-6 col-md-3">
        <div class="card shadow-sm text-center py-2" style="border-top:3px solid #ffc107;">
            <div class="fw-bold" style="font-size:1.4rem;">${weekLabel}</div>
            <div class="text-muted" style="font-size:.72rem;">Logged This Week</div>
        </div>
    </div>
</div>

<%-- ── This week ────────────────────────────────────────────────────── --%>
<div class="filter-card p-3 mb-3">
    <form method="get" action="/timesheet" class="row g-2 align-items-end">
        <div class="col-auto">
            <span class="fw-semibold"><i class="bi bi-calendar-week me-1 text-primary"></i>Week of ${weekRangeLabel}</span>
        </div>
        <div class="col-auto ms-auto">
            <label class="filter-label d-block">Task</label>
            <div class="position-relative">
                <div class="input-group input-group-sm">
                    <input type="text" id="filterTaskText" class="form-control form-control-sm"
                           placeholder="All tasks" autocomplete="off" style="min-width:220px;"/>
                    <button type="button" class="btn btn-outline-secondary" id="filterTaskClear" title="Clear"><i class="bi bi-x-lg"></i></button>
                </div>
                <input type="hidden" name="taskId" id="filterTaskId" value="${taskId}"/>
                <ul id="filterTaskList" class="list-group position-absolute shadow"
                    style="z-index:1050;max-height:220px;overflow-y:auto;display:none;top:100%;left:0;min-width:280px;"></ul>
            </div>
        </div>
        <div class="col-auto d-flex gap-2">
            <button type="submit" class="btn btn-sm btn-outline-primary">
                <i class="bi bi-funnel me-1"></i>Filter
            </button>
            <a href="/timesheet" class="btn btn-sm btn-outline-secondary">
                <i class="bi bi-x-circle me-1"></i>Clear
            </a>
        </div>
    </form>
</div>
<div class="text-muted small mb-3">
    <i class="bi bi-info-circle me-1"></i>Only this week's entries are shown here. Use the export below to pull older data.
</div>

<%-- ── Day-grouped list ─────────────────────────────────────────────── --%>
<c:choose>
    <c:when test="${empty dayGroups}">
        <div class="card shadow-sm">
            <div class="card-body text-center text-muted py-4">
                <i class="bi bi-inbox me-1"></i>No time sheet entries for this week yet
            </div>
        </div>
    </c:when>
    <c:otherwise>
        <c:forEach var="group" items="${dayGroups}" varStatus="gs">
            <div class="card shadow-sm mb-3">
                <div class="d-flex justify-content-between align-items-center py-3 px-3 day-toggle"
                     data-bs-toggle="collapse" data-bs-target="#dayBody${gs.index}" role="button"
                     aria-expanded="${group.isToday ? 'true' : 'false'}" aria-controls="dayBody${gs.index}">
                    <span class="d-flex align-items-center gap-2 fw-bold">
                        <i class="bi bi-calendar3 text-primary"></i>${group.dateLabel}
                        <c:if test="${group.isToday}"><span class="badge bg-primary rounded-pill">Today</span></c:if>
                        <c:if test="${group.hasOpenEntry}">
                            <span class="badge bg-warning text-dark rounded-pill">
                                <i class="bi bi-exclamation-triangle me-1"></i>Missing end time
                            </span>
                        </c:if>
                    </span>
                    <span class="d-flex align-items-center gap-2">
                        <span class="badge bg-secondary rounded-pill" style="font-size:.8rem;">${fn:length(group.entries)} Logs</span>
                        <span class="badge bg-dark rounded-pill" style="font-size:.8rem;">${group.totalLabel}</span>
                    </span>
                </div>
                <div class="collapse ${group.isToday ? 'show' : ''}" id="dayBody${gs.index}">
                    <ul class="list-group list-group-flush">
                        <c:forEach var="e" items="${group.entries}">
                            <li class="list-group-item ts-row d-flex justify-content-between align-items-center py-3 px-3 ${e.endTime == null ? 'ts-row-open' : ''}">
                                <div class="me-3" style="min-width:0;">
                                    <div class="fw-semibold small text-truncate">${e.activity}</div>
                                    <c:if test="${e.task != null}">
                                        <a href="/tasks/edit/${e.task.taskId}" class="text-muted text-decoration-none text-truncate d-block" style="font-size:.72rem;">
                                            Task #${e.task.taskId} · ${fn:substring(e.task.description, 0, fn:length(e.task.description) > 40 ? 40 : fn:length(e.task.description))}${fn:length(e.task.description) > 40 ? '…' : ''}
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
                                    <span class="d-flex align-items-center gap-1">
                                        <a href="/timesheet/edit/${e.id}" class="btn btn-sm btn-outline-secondary py-0 px-1"><i class="bi bi-pencil" style="font-size:.7rem;"></i></a>
                                        <form action="/timesheet/delete/${e.id}" method="post" class="d-inline"
                                              onsubmit="return confirm('Delete this entry?')">
                                            <button type="submit" class="btn btn-sm btn-outline-danger py-0 px-1"><i class="bi bi-trash" style="font-size:.7rem;"></i></button>
                                        </form>
                                    </span>
                                </div>
                            </li>
                        </c:forEach>
                    </ul>
                </div>
            </div>
        </c:forEach>
    </c:otherwise>
</c:choose>

<%-- ── Export to CSV ───────────────────────────────────────────────── --%>
<div class="card shadow-sm mb-4">
    <div class="card-header py-2">
        <span class="fw-semibold"><i class="bi bi-file-earmark-spreadsheet me-1 text-success"></i>Export to CSV</span>
    </div>
    <div class="card-body">
        <form method="get" action="/timesheet/export" class="row g-2 align-items-end">
            <div class="col-auto">
                <label class="filter-label d-block">From</label>
                <input type="date" name="fromDate" class="form-control form-control-sm" max="${todayDate}"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">To</label>
                <input type="date" name="toDate" class="form-control form-control-sm" max="${todayDate}"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">Task</label>
                <div class="position-relative">
                    <div class="input-group input-group-sm">
                        <input type="text" id="exportTaskText" class="form-control form-control-sm"
                               placeholder="All tasks" autocomplete="off" style="min-width:220px;"/>
                        <button type="button" class="btn btn-outline-secondary" id="exportTaskClear" title="Clear"><i class="bi bi-x-lg"></i></button>
                    </div>
                    <input type="hidden" name="taskId" id="exportTaskId"/>
                    <ul id="exportTaskList" class="list-group position-absolute shadow"
                        style="z-index:1050;max-height:220px;overflow-y:auto;display:none;top:100%;left:0;min-width:280px;"></ul>
                </div>
            </div>
            <div class="col-auto">
                <button type="submit" class="btn btn-sm btn-success">
                    <i class="bi bi-download me-1"></i>Export CSV
                </button>
            </div>
            <div class="col-12">
                <span class="text-muted small">Leave From/To blank to export all entries, including past weeks.</span>
            </div>
        </form>
    </div>
</div>

<script>
function initTaskTypeahead(textId, hiddenId, listId, clearId, data, initialId) {
    var txt   = document.getElementById(textId);
    var hid   = document.getElementById(hiddenId);
    var list  = document.getElementById(listId);
    var clear = document.getElementById(clearId);

    function makeDisplay(t) { return '#' + t.id + ' — ' + t.description; }

    function renderList(q) {
        list.innerHTML = '';
        var lower = q ? q.toLowerCase() : '';
        var matches = q
            ? data.filter(function (t) {
                return String(t.id).indexOf(lower) !== -1
                    || (t.description && t.description.toLowerCase().indexOf(lower) !== -1);
              })
            : [];
        if (!matches.length) { list.style.display = 'none'; return; }
        matches.forEach(function (t) {
            var li = document.createElement('li');
            li.className = 'list-group-item list-group-item-action py-2';
            li.style.cursor = 'pointer';
            li.textContent = makeDisplay(t);
            li.addEventListener('mousedown', function (e) {
                e.preventDefault();
                txt.value = makeDisplay(t);
                hid.value = t.id;
                list.style.display = 'none';
            });
            list.appendChild(li);
        });
        list.style.display = 'block';
    }

    txt.addEventListener('input', function () { hid.value = ''; renderList(this.value); });
    txt.addEventListener('focus', function () { if (this.value) renderList(this.value); });
    txt.addEventListener('blur',  function () { setTimeout(function () { list.style.display = 'none'; }, 200); });
    clear.addEventListener('click', function () { txt.value = ''; hid.value = ''; list.style.display = 'none'; txt.focus(); });

    if (initialId) {
        var match = data.filter(function (t) { return String(t.id) === String(initialId); })[0];
        if (match) { txt.value = makeDisplay(match); hid.value = match.id; }
    }
}

var timesheetTasksData = [
    <c:forEach var="t" items="${tasks}" varStatus="s">
        {id: ${t.taskId}, description: '${fn:replace(t.description, "'", "\\'")}'}${!s.last ? ',' : ''}
    </c:forEach>
];

initTaskTypeahead('filterTaskText', 'filterTaskId', 'filterTaskList', 'filterTaskClear', timesheetTasksData, '${taskId}');
initTaskTypeahead('exportTaskText', 'exportTaskId', 'exportTaskList', 'exportTaskClear', timesheetTasksData, '');
</script>

<%@include file="../layout/footer.jsp" %>
