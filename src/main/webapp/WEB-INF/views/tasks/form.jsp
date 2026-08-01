<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-lg-7">
        <div class="card shadow-sm">
            <div class="card-header bg-dark text-white">
                <h5 class="mb-0">
                    <i class="bi bi-${isEdit ? 'pencil-square' : 'plus-circle'} me-2"></i>
                    <c:choose>
                        <c:when test="${isEdit}">Edit Task #${task.taskId}</c:when>
                        <c:otherwise>New Task</c:otherwise>
                    </c:choose>
                </h5>
            </div>
            <div class="card-body">
                <c:if test="${not empty errorMessage}">
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="bi bi-exclamation-triangle-fill me-2"></i>${errorMessage}
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                </c:if>
                <form action="/tasks/save" method="post">
                    <c:if test="${isEdit}">
                        <input type="hidden" name="taskId" value="${task.taskId}"/>
                    </c:if>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Description <span class="text-danger">*</span></label>
                        <textarea name="description" class="form-control" rows="3" required>${task.description}</textarea>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Payroll MR</label>
                            <div class="position-relative">
                                <div class="input-group">
                                    <input type="text" id="payrollMrText" class="form-control"
                                           placeholder="Type MR number…" autocomplete="off"
                                           value="${task.payrollMr != null ? task.payrollMr.mrNumber : ''}"/>
                                    <button type="button" class="btn btn-outline-secondary" id="payrollMrClear" title="Clear">
                                        <i class="bi bi-x-lg"></i>
                                    </button>
                                </div>
                                <input type="hidden" name="payrollMrId" id="payrollMrId"
                                       value="${task.payrollMr != null ? task.payrollMr.mrSerialNumber : ''}"/>
                                <ul id="payrollMrList" class="list-group position-absolute w-100 shadow"
                                    style="z-index:1050;max-height:200px;overflow-y:auto;display:none;top:100%;left:0;"></ul>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Books MR</label>
                            <div class="position-relative">
                                <div class="input-group">
                                    <input type="text" id="booksMrText" class="form-control"
                                           placeholder="Type MR number…" autocomplete="off"
                                           value="${task.booksMr != null ? task.booksMr.mrNumber : ''}"/>
                                    <button type="button" class="btn btn-outline-secondary" id="booksMrClear" title="Clear">
                                        <i class="bi bi-x-lg"></i>
                                    </button>
                                </div>
                                <input type="hidden" name="booksMrId" id="booksMrId"
                                       value="${task.booksMr != null ? task.booksMr.mrSerialNumber : ''}"/>
                                <ul id="booksMrList" class="list-group position-absolute w-100 shadow"
                                    style="z-index:1050;max-height:200px;overflow-y:auto;display:none;top:100%;left:0;"></ul>
                            </div>
                        </div>
                    </div>

                    <div class="row g-3 mb-3">
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Priority</label>
                            <select name="priority" class="form-select">
                                <c:forEach var="p" items="${priorities}">
                                    <option value="${p}" ${task.priority == p ? 'selected' : ''}>${p.displayName}</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Status</label>
                            <select name="status" class="form-select">
                                <c:forEach var="s" items="${taskStatuses}">
                                    <option value="${s}" ${task.status == s ? 'selected' : ''}>${s.displayName}</option>
                                </c:forEach>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Due Date</label>
                            <input type="date" name="dueDate" class="form-control" value="${task.dueDate}"/>
                        </div>
                    </div>

                    <c:if test="${isEdit && task.createdAt != null}">
                        <div class="mb-3 text-muted small">
                            <i class="bi bi-clock-history me-1"></i>Created:
                            <strong>
                                ${fn:substring(task.createdAt.toString(), 8, 10)}-${fn:substring(task.createdAt.toString(), 5, 7)}-${fn:substring(task.createdAt.toString(), 0, 4)}
                                ${fn:substring(task.createdAt.toString(), 11, 16)}
                            </strong>
                        </div>
                    </c:if>
                    <div class="d-flex gap-2 justify-content-end">
                        <a href="/tasks" class="btn btn-outline-secondary">Cancel</a>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check2 me-1"></i>
                            <c:choose>
                                <c:when test="${isEdit}">Update Task</c:when>
                                <c:otherwise>Create Task</c:otherwise>
                            </c:choose>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
function initMrTypeahead(textId, hiddenId, listId, clearId, data) {
    var txt   = document.getElementById(textId);
    var hid   = document.getElementById(hiddenId);
    var list  = document.getElementById(listId);
    var clear = document.getElementById(clearId);

    function makeDisplay(mr) {
        return mr.name ? mr.number + ' — ' + mr.name : mr.number;
    }

    function renderList(q) {
        list.innerHTML = '';
        var lower = q ? q.toLowerCase() : '';
        var matches = q
            ? data.filter(function(mr) {
                return mr.number.toLowerCase().indexOf(lower) !== -1
                    || (mr.name && mr.name.toLowerCase().indexOf(lower) !== -1);
              })
            : [];
        if (!matches.length) { list.style.display = 'none'; return; }
        matches.forEach(function(mr) {
            var li = document.createElement('li');
            li.className = 'list-group-item list-group-item-action py-2';
            li.style.cursor = 'pointer';
            li.textContent = makeDisplay(mr);
            li.addEventListener('mousedown', function(e) {
                e.preventDefault();
                txt.value = mr.number;
                hid.value = mr.id;
                list.style.display = 'none';
            });
            list.appendChild(li);
        });
        list.style.display = 'block';
    }

    txt.addEventListener('input',  function(){ hid.value = ''; renderList(this.value); });
    txt.addEventListener('focus',  function(){ if (this.value) renderList(this.value); });
    txt.addEventListener('blur',   function(){ setTimeout(function(){ list.style.display = 'none'; }, 200); });
    clear.addEventListener('click', function(){ txt.value = ''; hid.value = ''; list.style.display = 'none'; txt.focus(); });
}

var payrollData = [
    <c:forEach var="pmr" items="${payrollMrs}" varStatus="s">
        {id: ${pmr.mrSerialNumber}, number: '${pmr.mrNumber}', name: '${fn:replace(pmr.name, "'", "\\'")}'}${!s.last ? ',' : ''}
    </c:forEach>
];
var booksData = [
    <c:forEach var="bmr" items="${booksMrs}" varStatus="s">
        {id: ${bmr.mrSerialNumber}, number: '${bmr.mrNumber}', name: '${fn:replace(bmr.name, "'", "\\'")}'}${!s.last ? ',' : ''}
    </c:forEach>
];

initMrTypeahead('payrollMrText', 'payrollMrId', 'payrollMrList', 'payrollMrClear', payrollData);
initMrTypeahead('booksMrText',   'booksMrId',   'booksMrList',   'booksMrClear',   booksData);
</script>

<%@include file="../layout/footer.jsp" %>
