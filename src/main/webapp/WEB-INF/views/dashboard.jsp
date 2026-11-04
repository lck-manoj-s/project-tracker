<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="layout/header.jsp" %>

<link rel="stylesheet" href="/css/lists.css">

<h4 class="mb-3"><i class="bi bi-speedometer2 me-2"></i>Dashboard</h4>

<%-- ── Summary numbers (single row) ─────────────────────────────────── --%>
<div class="row row-cols-2 row-cols-md-5 g-2 mb-3">
    <div class="col">
        <div class="card shadow-sm text-center py-2 h-100" style="border-top:3px solid #4f46e5;">
            <div class="fw-bold" style="font-size:1.4rem;">${totalTasks}</div>
            <div class="text-muted" style="font-size:.72rem;">Total Tasks</div>
        </div>
    </div>
    <div class="col">
        <div class="card shadow-sm text-center py-2 h-100" style="border-top:3px solid #0d6efd;">
            <div class="fw-bold" style="font-size:1.4rem;">${totalMrs}</div>
            <div class="text-muted" style="font-size:.72rem;">Total MRs</div>
        </div>
    </div>
    <div class="col">
        <div class="card shadow-sm text-center py-2 h-100" style="border-top:3px solid #adb5bd;">
            <div class="fw-bold" style="font-size:1.4rem;">${ignorableMrs}</div>
            <div class="text-muted" style="font-size:.72rem;">Ignorable MRs</div>
        </div>
    </div>
    <div class="col">
        <div class="card shadow-sm text-center py-2 h-100" style="border-top:3px solid #ffc107;">
            <div class="fw-bold" style="font-size:1.4rem;">${todayLoggedLabel}</div>
            <div class="text-muted" style="font-size:.72rem;">Today Hours</div>
        </div>
    </div>
    <div class="col">
        <div class="card shadow-sm text-center py-2 h-100" style="border-top:3px solid #198754;">
            <div class="fw-bold" style="font-size:1.4rem;">${totalLoggedLabel}</div>
            <div class="text-muted" style="font-size:.72rem;">Total Logged</div>
        </div>
    </div>
</div>

<%-- ── Row: Tasks / MR breakdown (tabbed) | Completed & merged per month ── --%>
<div class="row g-3 mb-3">

    <div class="col-lg-6">
        <div class="card shadow-sm h-100">
            <div class="card-body">
                <div class="segmented mb-3" role="tablist">
                    <button type="button" class="segmented-item active" data-dash-tab="tasks">
                        <i class="bi bi-list-task"></i>Tasks
                    </button>
                    <button type="button" class="segmented-item" data-dash-tab="mrs">
                        <i class="bi bi-git"></i>Merge requests
                    </button>
                </div>

                <%-- Tasks: grouped by status (same bar layout as MRs) --%>
                <div data-dash-pane="tasks">
                    <div class="section-label">By status</div>
                    <c:forEach var="s" items="${taskByStatus}">
                        <c:set var="tPct" value="${totalTasks > 0 ? s.count * 100.0 / totalTasks : 0}"/>
                        <div class="d-flex align-items-center gap-2 mb-2 small">
                            <span style="width:110px;" class="text-muted">${s.label}</span>
                            <div class="flex-fill rounded" style="height:8px;background:#e1e5f2;">
                                <div class="rounded" style="width:${tPct}%;height:8px;background:#0d6efd;"></div>
                            </div>
                            <span class="fw-semibold" style="width:28px;text-align:right;">${s.count}</span>
                        </div>
                    </c:forEach>
                </div>

                <%-- MRs: grouped by status, then by product --%>
                <div data-dash-pane="mrs" hidden>
                    <div class="section-label">By status</div>
                    <c:forEach var="s" items="${mrByStatus}">
                        <c:set var="sPct" value="${totalMrs > 0 ? s.count * 100.0 / totalMrs : 0}"/>
                        <div class="d-flex align-items-center gap-2 mb-2 small">
                            <span style="width:110px;" class="text-muted">${s.label}</span>
                            <div class="flex-fill rounded" style="height:8px;background:#e1e5f2;">
                                <div class="rounded" style="width:${sPct}%;height:8px;background:#0d6efd;"></div>
                            </div>
                            <span class="fw-semibold" style="width:28px;text-align:right;">${s.count}</span>
                        </div>
                    </c:forEach>

                    <div class="section-label mt-3">By product</div>
                    <c:forEach var="p" items="${mrByProduct}">
                        <c:set var="pPct" value="${totalMrs > 0 ? p.count * 100.0 / totalMrs : 0}"/>
                        <div class="d-flex align-items-center gap-2 mb-2 small">
                            <span style="width:110px;" class="text-muted">${p.label}</span>
                            <div class="flex-fill rounded" style="height:8px;background:#e1e5f2;">
                                <div class="rounded" style="width:${pPct}%;height:8px;background:#0d6efd;"></div>
                            </div>
                            <span class="fw-semibold" style="width:28px;text-align:right;">${p.count}</span>
                        </div>
                    </c:forEach>
                </div>
            </div>
        </div>
    </div>

    <div class="col-lg-6">
        <div class="card shadow-sm h-100">
            <div class="card-body">
                <div class="section-label">Completed &amp; merged per month <span class="fw-normal text-lowercase">(last 6 months)</span></div>
                <div style="position:relative;height:270px;">
                    <canvas id="monthlyOutputChart"></canvas>
                </div>
            </div>
        </div>
    </div>

</div>

<%-- ── Timesheet charts (unchanged) ─────────────────────────────────── --%>
<div class="section-label mt-4 mb-2"><i class="bi bi-stopwatch me-1"></i>Time Sheet</div>

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


<%-- ── Charts ───────────────────────────────────────────────────────────── --%>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/chartjs-plugin-datalabels/2.2.0/chartjs-plugin-datalabels.min.js"></script>
<script>
(function () {
    Chart.register(ChartDataLabels);

    // Tasks completed + MRs merged per month — two series in one chart
    var monthLabels = [<c:forEach var="m" items="${tasksCompletedByMonth}" varStatus="vs">'${m.label}'${!vs.last?',':''}</c:forEach>];
    var tasksDone   = [<c:forEach var="m" items="${tasksCompletedByMonth}" varStatus="vs">${m.count}${!vs.last?',':''}</c:forEach>];
    var mrsMerged   = [<c:forEach var="m" items="${mrsMergedByMonth}" varStatus="vs">${m.count}${!vs.last?',':''}</c:forEach>];

    new Chart(document.getElementById('monthlyOutputChart'), {
        type: 'bar',
        data: {
            labels: monthLabels,
            datasets: [
                { label: 'Tasks completed', data: tasksDone, backgroundColor: 'rgba(13,110,253,.75)', borderColor: '#0d6efd', borderWidth: 1, borderRadius: 3, maxBarThickness: 40 },
                { label: 'MRs merged',      data: mrsMerged, backgroundColor: 'rgba(29,158,117,.75)', borderColor: '#1D9E75', borderWidth: 1, borderRadius: 3, maxBarThickness: 40 }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false,
            scales: {
                y: { beginAtZero: true, ticks: { precision: 0, font: { size: 12 } }, grid: { color: 'rgba(0,0,0,.05)' } },
                x: { grid: { display: false }, ticks: { font: { size: 11 } } }
            },
            plugins: {
                legend: { position: 'bottom', labels: { padding: 10, font: { size: 12 }, boxWidth: 14 } },
                datalabels: { display: false }
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
                    backgroundColor: 'rgba(13,110,253,.75)',
                    borderColor: '#0d6efd',
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
                    backgroundColor: 'rgba(55,138,221,.75)',
                    borderColor: '#378ADD',
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
                    backgroundColor: 'rgba(15,110,86,.75)',
                    borderColor: '#0F6E56',
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
                backgroundColor: 'rgba(29,158,117,.75)',
                borderColor: '#1D9E75',
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
(function () {
    var tabs = document.querySelectorAll('[data-dash-tab]');
    tabs.forEach(function (btn) {
        btn.addEventListener('click', function () {
            var key = btn.dataset.dashTab;
            tabs.forEach(function (b) { b.classList.toggle('active', b === btn); });
            document.querySelectorAll('[data-dash-pane]').forEach(function (p) {
                p.hidden = p.dataset.dashPane !== key;
            });
        });
    });
})();
</script>

<%@include file="layout/footer.jsp" %>
