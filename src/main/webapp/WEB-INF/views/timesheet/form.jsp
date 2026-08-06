<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>


<%-- Form-page CSS lives in /css/forms.css (not inline) — see that file's
     "Timesheet form" section for these rules. --%>
<link rel="stylesheet" href="/css/forms.css">

<div class="timesheet-form-container">

    <c:if test="${not empty errorMessage}">
        <span id="flashErrorMsg"
              data-message="${fn:escapeXml(errorMessage)}"
              hidden></span>

        <script>
            document.addEventListener('DOMContentLoaded', function () {
                var el = document.getElementById('flashErrorMsg');
                if (el) showToast(el.dataset.message, 'danger');
            });
        </script>
    </c:if>

    <div class="card shadow-sm">

        <%-- Header --%>
        <div class="card-header bg-dark text-white d-flex
                    justify-content-between align-items-center flex-wrap gap-2">

            <h5 class="mb-0">
                <i class="bi bi-${isEdit ? 'pencil-square' : 'plus-circle'} me-2"></i>

                <c:choose>
                    <c:when test="${isEdit}">
                        Edit Time Sheet Entry
                    </c:when>
                    <c:otherwise>
                        New Time Sheet Entry
                    </c:otherwise>
                </c:choose>
            </h5>

            <div class="d-flex gap-2">

                <a href="/timesheet" class="btn btn-sm btn-outline-light">
                    <i class="bi bi-x-lg me-1"></i>
                    Cancel
                </a>

                <button type="submit"
                        form="timesheetForm"
                        class="btn btn-sm btn-primary">

                    <i class="bi bi-check2 me-1"></i>

                    <c:choose>
                        <c:when test="${isEdit}">Update Entry</c:when>
                        <c:otherwise>Add Entry</c:otherwise>
                    </c:choose>

                </button>

            </div>
        </div>

        <div class="card-body">

            <form id="timesheetForm"
                  action="/timesheet/save"
                  method="post">

                <c:if test="${isEdit}">
                    <input type="hidden"
                           name="id"
                           value="${entry.id}"/>
                </c:if>

                <%-- Activity Details --%>
                <div class="timesheet-section-title">
                    <i class="bi bi-card-text me-1"></i>
                    Activity Details
                </div>

                <div class="mb-3">

                    <label class="form-label fw-semibold">
                        Activity <span class="text-danger">*</span>
                    </label>

                    <textarea name="activity"
                              class="form-control"
                              rows="3"
                              placeholder="What did you work on?"
                              required>${entry.activity}</textarea>

                </div>

                <hr class="timesheet-section-divider"/>

                <%-- Time Details --%>
                <div class="timesheet-section-title">
                    <i class="bi bi-clock me-1"></i>
                    Time Details
                </div>

                <div class="row g-3">

                    <div class="col-md-4">

                        <label class="form-label fw-semibold">
                            Date <span class="text-danger">*</span>
                        </label>

                        <input type="date"
                               name="entryDate"
                               class="form-control"
                               value="${entry.entryDate}"
                               max="${todayDate}"
                               required/>

                    </div>

                    <div class="col-md-4">

                        <label class="form-label fw-semibold">
                            Start Time <span class="text-danger">*</span>
                        </label>

                        <input type="time"
                               name="startTime"
                               class="form-control"
                               value="${entry.startTime}"
                               required/>

                    </div>

                    <div class="col-md-4">

                        <label class="form-label fw-semibold">
                            End Time
                            <span class="text-muted fw-normal">
                                (optional)
                            </span>
                        </label>

                        <input type="time"
                               name="endTimeInput"
                               class="form-control"
                               value="${entry.endTime}"/>

                        <div class="form-text">
                            Leave blank if this activity is still in progress.
                        </div>

                    </div>

                </div>

                <hr class="timesheet-section-divider"/>

                <%-- Task Association --%>
                <div class="timesheet-section-title">
                    <i class="bi bi-list-task me-1"></i>
                    Task Association
                </div>

                <div class="timesheet-task-wrapper">

                    <label class="form-label fw-semibold">
                        Task
                        <span class="text-muted fw-normal">(optional)</span>
                    </label>

                    <div class="input-group">

                        <input type="text"
                               id="entryTaskText"
                               class="form-control"
                               placeholder="Type to search for a task..."
                               autocomplete="off"/>

                        <button type="button"
                                class="btn btn-outline-secondary"
                                id="entryTaskClear"
                                title="Clear">

                            <i class="bi bi-x-lg"></i>

                        </button>

                    </div>

                    <input type="hidden"
                           name="taskId"
                           id="entryTaskId"/>

                    <ul id="entryTaskList"
                        class="list-group position-absolute w-100 shadow">
                    </ul>

                    <div class="form-text">
                        Leave blank for — None —.
                    </div>

                </div>

            </form>

        </div>
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

initTaskTypeahead('entryTaskText', 'entryTaskId', 'entryTaskList', 'entryTaskClear', timesheetTasksData, '${entry.task != null ? entry.task.taskId : ""}');
</script>

<%@include file="../layout/footer.jsp" %>
