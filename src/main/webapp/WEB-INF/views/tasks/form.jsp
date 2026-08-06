<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>


<%-- Form-page CSS lives in /css/forms.css (not inline) — see that file's
     "Task form" section for these rules. --%>
<link rel="stylesheet" href="/css/forms.css">

<div class="task-form-container">

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
                        Edit Task #${task.taskId}
                    </c:when>
                    <c:otherwise>
                        New Task
                    </c:otherwise>
                </c:choose>
            </h5>

            <div class="d-flex gap-2">

                <a href="/tasks" class="btn btn-sm btn-outline-light">
                    <i class="bi bi-x-lg me-1"></i>
                    Cancel
                </a>

                <button type="submit"
                        form="taskForm"
                        class="btn btn-sm btn-primary">

                    <i class="bi bi-check2 me-1"></i>

                    <c:choose>
                        <c:when test="${isEdit}">Update Task</c:when>
                        <c:otherwise>Create Task</c:otherwise>
                    </c:choose>

                </button>

            </div>
        </div>

        <div class="card-body">

            <form id="taskForm" action="/tasks/save" method="post">

                <c:if test="${isEdit}">
                    <input type="hidden"
                           name="taskId"
                           value="${task.taskId}"/>
                </c:if>

                <%-- Task Details --%>
                <div class="task-section-title">
                    <i class="bi bi-card-text me-1"></i>
                    Task Details
                </div>

                <div class="mb-3">

                    <label class="form-label fw-semibold">
                        Description <span class="text-danger">*</span>
                    </label>

                    <textarea name="description"
                              class="form-control"
                              rows="3"
                              required>${task.description}</textarea>

                </div>

                <hr class="task-section-divider"/>

                <%-- Associated Merge Requests --%>
                <div class="task-section-title">
                    <i class="bi bi-git me-1"></i>
                    Associated Merge Requests
                </div>

                <div class="mb-3">

                    <label class="form-label fw-semibold">
                        Merge Requests
                        <span class="text-muted fw-normal">
                            (any number, any product)
                        </span>
                    </label>

                    <div class="task-mr-wrapper">

                        <div class="input-group">

                            <input type="text"
                                   id="mrText"
                                   class="form-control"
                                   placeholder="Type MR number to add..."
                                   autocomplete="off"/>

                        </div>

                        <ul id="mrList"
                            class="list-group position-absolute w-100 shadow">
                        </ul>

                    </div>

                    <div id="mrChips"
                         class="d-flex flex-wrap gap-2 mt-2">
                    </div>

                    <div id="mrIdsContainer"></div>

                </div>

                <hr class="task-section-divider"/>

                <%-- Task Workflow --%>
                <div class="task-section-title">
                    <i class="bi bi-diagram-3 me-1"></i>
                    Task Workflow
                </div>

                <div class="row g-3">

                    <div class="col-md-4">

                        <label class="form-label fw-semibold">
                            Priority
                        </label>

                        <select name="priority" class="form-select">

                            <c:forEach var="p" items="${priorities}">
                                <option value="${p}"
                                    ${task.priority == p ? 'selected' : ''}>
                                        ${p.displayName}
                                </option>
                            </c:forEach>

                        </select>

                    </div>

                    <div class="col-md-4">

                        <label class="form-label fw-semibold">
                            Status
                        </label>

                        <select name="status" class="form-select">

                            <c:forEach var="s" items="${taskStatuses}">
                                <option value="${s}"
                                    ${task.status == s ? 'selected' : ''}>
                                        ${s.displayName}
                                </option>
                            </c:forEach>

                        </select>

                    </div>

                    <div class="col-md-4">

                        <label class="form-label fw-semibold">
                            Due Date
                        </label>

                        <input type="date"
                               name="dueDate"
                               class="form-control"
                               value="${task.dueDate}"/>

                    </div>

                </div>

                <%-- Created Information --%>
                <c:if test="${isEdit && task.createdAt != null}">

                    <hr class="task-section-divider"/>

                    <div class="task-created-info">
                        <i class="bi bi-clock-history me-1"></i>
                        Created:

                        <strong>
                                ${fn:substring(task.createdAt.toString(), 8, 10)}-${fn:substring(task.createdAt.toString(), 5, 7)}-${fn:substring(task.createdAt.toString(), 0, 4)}
                                ${fn:substring(task.createdAt.toString(), 11, 16)}
                        </strong>
                    </div>

                </c:if>

            </form>

        </div>
    </div>
</div>


<script>
// All MRs available for this task (unassigned MRs, plus any already linked to it)
var availableMrs = [
    <c:forEach var="m" items="${availableMrs}" varStatus="s">
        {id: ${m.mrSerialNumber}, number: '${m.mrNumber}', name: '${fn:replace(m.name, "'", "\\'")}', product: '${m.product.displayName}', productKey: '${m.product.name()}', badgeClass: '${m.product.badgeClass}'}${!s.last ? ',' : ''}
    </c:forEach>
];

// MRs already linked to this task (edit mode)
var selectedIds = [
    <c:forEach var="m" items="${task.mergeRequests}" varStatus="s">${m.mrSerialNumber}${!s.last ? ',' : ''}</c:forEach>
];

(function () {
    var txt   = document.getElementById('mrText');
    var list  = document.getElementById('mrList');
    var chips = document.getElementById('mrChips');
    var idsContainer = document.getElementById('mrIdsContainer');

    var byId = {};
    availableMrs.forEach(function (mr) { byId[mr.id] = mr; });

    function renderChips() {
        chips.innerHTML = '';
        idsContainer.innerHTML = '';
        selectedIds.forEach(function (id) {
            var mr = byId[id];
            if (!mr) return;

            var hidden = document.createElement('input');
            hidden.type = 'hidden';
            hidden.name = 'mrIds';
            hidden.value = id;
            idsContainer.appendChild(hidden);

            var chip = document.createElement('span');
            chip.className = 'badge ' + mr.badgeClass + ' d-inline-flex align-items-center gap-1 py-2 px-2';
            chip.innerHTML = '<span>' + mr.number + (mr.name ? ' — ' + mr.name : '') + '</span>'
                + '<i class="bi bi-x-circle-fill ms-1" style="cursor:pointer;" title="Remove"></i>';
            chip.querySelector('i').addEventListener('click', function () {
                selectedIds = selectedIds.filter(function (x) { return x !== id; });
                renderChips();
            });
            chips.appendChild(chip);
        });
    }

    function renderList(q) {
        list.innerHTML = '';
        var lower = q ? q.toLowerCase() : '';
        var matches = q
            ? availableMrs.filter(function (mr) {
                return selectedIds.indexOf(mr.id) === -1
                    && (mr.number.toLowerCase().indexOf(lower) !== -1
                        || (mr.name && mr.name.toLowerCase().indexOf(lower) !== -1));
              })
            : [];
        if (!matches.length) { list.style.display = 'none'; return; }
        matches.forEach(function (mr) {
            var li = document.createElement('li');
            li.className = 'list-group-item list-group-item-action py-2';
            li.style.cursor = 'pointer';
            li.textContent = mr.number + (mr.name ? ' — ' + mr.name : '') + ' (' + mr.product + ')';
            li.addEventListener('mousedown', function (e) {
                e.preventDefault();
                selectedIds.push(mr.id);
                renderChips();
                txt.value = '';
                list.style.display = 'none';
                txt.focus();
            });
            list.appendChild(li);
        });
        list.style.display = 'block';
    }

    txt.addEventListener('input', function () { renderList(this.value); });
    txt.addEventListener('focus', function () { if (this.value) renderList(this.value); });
    txt.addEventListener('blur',  function () { setTimeout(function () { list.style.display = 'none'; }, 200); });

    renderChips();
}());
</script>

<%@include file="../layout/footer.jsp" %>
