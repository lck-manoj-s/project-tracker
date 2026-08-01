<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>

<style>
  .pipeline-steps { display: inline-flex; align-items: center; gap: 2px; flex-wrap: nowrap; }
  .step { display: inline-block; padding: 1px 5px; border-radius: 3px; font-size: .7rem; font-weight: 600;
          white-space: nowrap; border: 1px solid transparent; cursor: pointer; user-select: none; }
  .step:hover { opacity: .8; }
  .step-done  { background: #198754; color: #fff; border-color: #198754; }
  .step-todo  { background: #f8f9fa; color: #adb5bd; border-color: #dee2e6; }
  .step-arrow { color: #adb5bd; font-size: .65rem; }
</style>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="mb-0"><i class="bi bi-git me-2"></i>Merge Requests</h4>
    <a href="/mrs/new" class="btn btn-primary btn-sm">
        <i class="bi bi-plus-lg me-1"></i>Add MR
    </a>
</div>

<%-- ── Product tabs ─────────────────────────────────────────────────── --%>
<ul class="nav nav-tabs mb-3">
    <li class="nav-item">
        <a class="nav-link ${product.name() == 'PAYROLL' ? 'active' : ''}" href="/mrs/payroll">
            <span class="badge bg-warning text-dark me-1">Payroll</span> MRs
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link ${product.name() == 'BOOKS' ? 'active' : ''}" href="/mrs/books">
            <span class="badge bg-info text-dark me-1">Books</span> MRs
        </a>
    </li>
</ul>

<%-- ── Filter ───────────────────────────────────────────────────────── --%>
<div class="filter-card p-3 mb-3">
    <form method="get" action="${baseUrl}" class="row g-2 align-items-end" id="mrFilterForm">

        <div class="col-auto">
            <label class="filter-label d-block">Has Parent MR</label>
            <select name="hasParentMr" class="form-select form-select-sm">
                <option value="">All</option>
                <option value="true"  ${hasParentMr == 'true'  ? 'selected' : ''}>Yes</option>
                <option value="false" ${hasParentMr == 'false' ? 'selected' : ''}>No</option>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">Parent Product</label>
            <select name="parentMrProduct" class="form-select form-select-sm">
                <option value="">All</option>
                <c:forEach var="p" items="${products}">
                    <option value="${p}" ${p.name() == parentMrProduct ? 'selected' : ''}>${p.displayName}</option>
                </c:forEach>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">MR Linked</label>
            <select name="mrLinked" class="form-select form-select-sm">
                <option value="">All</option>
                <c:forEach var="ml" items="${mrLinkedValues}">
                    <option value="${ml}" ${ml.name() == mrLinked ? 'selected' : ''}>${ml.displayName}</option>
                </c:forEach>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">Merged</label>
            <select name="merged" class="form-select form-select-sm">
                <option value="false" ${merged == 'false' || empty merged ? 'selected' : ''}>Active Only</option>
                <option value="all"   ${merged == 'all'   ? 'selected' : ''}>All</option>
                <option value="true"  ${merged == 'true'  ? 'selected' : ''}>Merged Only</option>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">Local</label>
            <select name="movedToLocal" class="form-select form-select-sm">
                <option value="">All</option>
                <option value="true"  ${movedToLocal == 'true'  ? 'selected' : ''}>Yes</option>
                <option value="false" ${movedToLocal == 'false' ? 'selected' : ''}>No</option>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">Pre</label>
            <select name="movedToPre" class="form-select form-select-sm">
                <option value="">All</option>
                <option value="true"  ${movedToPre == 'true'  ? 'selected' : ''}>Yes</option>
                <option value="false" ${movedToPre == 'false' ? 'selected' : ''}>No</option>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">IDC</label>
            <select name="movedToIdc" class="form-select form-select-sm">
                <option value="">All</option>
                <option value="true"  ${movedToIdc == 'true'  ? 'selected' : ''}>Yes</option>
                <option value="false" ${movedToIdc == 'false' ? 'selected' : ''}>No</option>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">Can Ignore</label>
            <select name="canIgnore" class="form-select form-select-sm">
                <option value="all" ${canIgnore == 'all' ? 'selected' : ''}>All</option>
                <option value=""     ${canIgnore == 'false' || empty canIgnore ? 'selected' : ''}>No</option>
                <option value="true" ${canIgnore == 'true'  ? 'selected' : ''}>Yes</option>
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

<%-- ── Table ───────────────────────────────────────────────────────── --%>
<div class="card shadow-sm mb-4">
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover table-bordered table-sm mb-0">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>MR</th>
                        <th>Name</th>
                        <th>Parent MR</th>
                        <th>Pipeline</th>
                        <th>Linked</th>
                        <th>Can Ignore</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:choose>
                        <c:when test="${empty mrs}">
                            <tr><td colspan="9" class="text-center text-muted py-3">
                                <i class="bi bi-inbox me-1"></i>No MRs found
                            </td></tr>
                        </c:when>
                        <c:otherwise>
                            <c:forEach var="mr" items="${mrs}">
                                <tr data-mr-id="${mr.mrSerialNumber}">
                                    <td class="text-muted small align-middle">${mr.mrSerialNumber}</td>
                                    <td class="align-middle">
                                        <a href="${mr.mr}" target="_blank" class="badge bg-dark text-decoration-none">
                                            <i class="bi bi-box-arrow-up-right me-1"></i>${mr.mrNumber}
                                        </a>
                                        <button class="copy-mr-btn" data-mr="${mr.mrNumber}" onclick="copyMr(this)" title="Copy MR number">
                                            <i class="bi bi-clipboard"></i>
                                        </button>
                                    </td>
                                    <td class="align-middle small text-muted">
                                        <c:choose>
                                            <c:when test="${not empty mr.name}">${mr.name}</c:when>
                                            <c:otherwise><span class="text-muted">&#8212;</span></c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="align-middle">
                                        <c:choose>
                                            <c:when test="${mr.parentMr != null}">
                                                <a href="${mr.parentMr.mr}" target="_blank" class="badge bg-secondary text-decoration-none">
                                                    <i class="bi bi-box-arrow-up-right me-1"></i>${mr.parentMrNumber}
                                                    <span class="ms-1 opacity-75">(${mr.parentMr.product.displayName})</span>
                                                </a>
                                                <button class="copy-mr-btn" data-mr="${mr.parentMrNumber}" onclick="copyMr(this)" title="Copy parent MR number">
                                                    <i class="bi bi-clipboard"></i>
                                                </button>
                                            </c:when>
                                            <c:otherwise><span class="text-muted small">&#8212;</span></c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="align-middle">
                                        <%-- Pipeline: each step is an independent toggle --%>
                                        <div class="pipeline-steps">
                                            <span class="step pipeline-step ${mr.stepWaiting     ? 'step-done' : 'step-todo'}" data-field="stepWaiting"     title="Waiting for Thumbs Up">W</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepReviewed    ? 'step-done' : 'step-todo'}" data-field="stepReviewed"    title="Reviewed">R</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepDiScheduled ? 'step-done' : 'step-todo'}" data-field="stepDiScheduled" title="DI Scheduled">DI-S</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepDiCompleted ? 'step-done' : 'step-todo'}" data-field="stepDiCompleted" title="DI Completed">DI</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepGtm         ? 'step-done' : 'step-todo'}" data-field="stepGtm"         title="GTM">GTM</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepRtm         ? 'step-done' : 'step-todo'}" data-field="stepRtm"         title="RTM">RTM</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepMerged      ? 'step-done' : 'step-todo'}" data-field="stepMerged"      title="Merged">M</span>
                                        </div>
                                    </td>
                                    <td class="align-middle">
                                        <span class="badge ${mr.mrLinked.name() == 'LINKED' ? 'bg-success' : mr.mrLinked.name() == 'NOT_LINKED' ? 'bg-danger' : 'bg-secondary'}">
                                            ${mr.mrLinked.displayName}
                                        </span>
                                    </td>
                                    <td class="align-middle">
                                        <span class="step ${mr.canIgnore ? 'step-done' : 'step-todo'}"
                                              data-field="canIgnore"
                                              data-text-true="Yes" data-text-false="No"
                                              title="Click to toggle">
                                            ${mr.canIgnore ? 'Yes' : 'No'}
                                        </span>
                                    </td>
                                    <td class="text-muted small align-middle text-nowrap">
                                        <c:choose>
                                            <c:when test="${mr.createdAt != null}">
                                                ${fn:substring(mr.createdAt.toString(), 8, 10)}-${fn:substring(mr.createdAt.toString(), 5, 7)}-${fn:substring(mr.createdAt.toString(), 0, 4)}
                                                <span class="d-block" style="font-size:.7rem;">${fn:substring(mr.createdAt.toString(), 11, 16)}</span>
                                            </c:when>
                                            <c:otherwise>&#8212;</c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="align-middle">
                                        <a href="/mrs/edit/${mr.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0">
                                            <i class="bi bi-pencil"></i>
                                        </a>
                                        <form action="/mrs/delete/${mr.mrSerialNumber}" method="post" class="d-inline"
                                              onsubmit="return confirm('Delete this MR?')">
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

    <%-- ── Pagination footer ───────────────────────────────────────── --%>
    <div class="card-footer d-flex justify-content-between align-items-center">
        <span class="text-muted small">
            Showing ${mrs.size()} of ${totalElements} MR(s)
            &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
        </span>
        <c:if test="${totalPages > 1}">
            <nav><ul class="pagination pagination-sm mb-0">

                <%-- Previous --%>
                <li class="page-item ${currentPage == 0 ? 'disabled' : ''}">
                    <c:url var="prevUrl" value="${baseUrl}">
                        <c:if test="${not empty hasParentMr}">    <c:param name="hasParentMr"     value="${hasParentMr}"/></c:if>
                        <c:if test="${not empty parentMrProduct}"><c:param name="parentMrProduct" value="${parentMrProduct}"/></c:if>
                        <c:if test="${not empty mrLinked}">       <c:param name="mrLinked"        value="${mrLinked}"/></c:if>
                        <c:if test="${merged != 'false'}">         <c:param name="merged"           value="${merged}"/></c:if>
                        <c:if test="${not empty movedToLocal}">   <c:param name="movedToLocal"    value="${movedToLocal}"/></c:if>
                        <c:if test="${not empty movedToPre}">     <c:param name="movedToPre"      value="${movedToPre}"/></c:if>
                        <c:if test="${not empty movedToIdc}">     <c:param name="movedToIdc"      value="${movedToIdc}"/></c:if>
                        <c:if test="${canIgnore != 'false'}">     <c:param name="canIgnore"       value="${canIgnore}"/></c:if>
                        <c:param name="page" value="${currentPage - 1}"/>
                    </c:url>
                    <a class="page-link" href="${prevUrl}"><i class="bi bi-chevron-left"></i></a>
                </li>

                <%-- Page numbers --%>
                <c:forEach begin="0" end="${totalPages - 1}" var="p">
                    <li class="page-item ${p == currentPage ? 'active' : ''}">
                        <c:url var="pageUrl" value="${baseUrl}">
                            <c:if test="${not empty hasParentMr}">    <c:param name="hasParentMr"     value="${hasParentMr}"/></c:if>
                            <c:if test="${not empty parentMrProduct}"><c:param name="parentMrProduct" value="${parentMrProduct}"/></c:if>
                            <c:if test="${not empty mrLinked}">       <c:param name="mrLinked"        value="${mrLinked}"/></c:if>
                            <c:if test="${merged != 'false'}">         <c:param name="merged"           value="${merged}"/></c:if>
                            <c:if test="${not empty movedToLocal}">   <c:param name="movedToLocal"    value="${movedToLocal}"/></c:if>
                            <c:if test="${not empty movedToPre}">     <c:param name="movedToPre"      value="${movedToPre}"/></c:if>
                            <c:if test="${not empty movedToIdc}">     <c:param name="movedToIdc"      value="${movedToIdc}"/></c:if>
                            <c:if test="${canIgnore != 'false'}">     <c:param name="canIgnore"       value="${canIgnore}"/></c:if>
                            <c:param name="page" value="${p}"/>
                        </c:url>
                        <a class="page-link" href="${pageUrl}">${p + 1}</a>
                    </li>
                </c:forEach>

                <%-- Next --%>
                <li class="page-item ${currentPage + 1 >= totalPages ? 'disabled' : ''}">
                    <c:url var="nextUrl" value="${baseUrl}">
                        <c:if test="${not empty hasParentMr}">    <c:param name="hasParentMr"     value="${hasParentMr}"/></c:if>
                        <c:if test="${not empty parentMrProduct}"><c:param name="parentMrProduct" value="${parentMrProduct}"/></c:if>
                        <c:if test="${not empty mrLinked}">       <c:param name="mrLinked"        value="${mrLinked}"/></c:if>
                        <c:if test="${merged != 'false'}">         <c:param name="merged"           value="${merged}"/></c:if>
                        <c:if test="${not empty movedToLocal}">   <c:param name="movedToLocal"    value="${movedToLocal}"/></c:if>
                        <c:if test="${not empty movedToPre}">     <c:param name="movedToPre"      value="${movedToPre}"/></c:if>
                        <c:if test="${not empty movedToIdc}">     <c:param name="movedToIdc"      value="${movedToIdc}"/></c:if>
                        <c:if test="${canIgnore != 'false'}">     <c:param name="canIgnore"       value="${canIgnore}"/></c:if>
                        <c:param name="page" value="${currentPage + 1}"/>
                    </c:url>
                    <a class="page-link" href="${nextUrl}"><i class="bi bi-chevron-right"></i></a>
                </li>

            </ul></nav>
        </c:if>
    </div>
</div>

<script>
// Strip empty filter params so the URL only contains changed values
document.getElementById('mrFilterForm').addEventListener('submit', function () {
    this.querySelectorAll('select').forEach(function (sel) {
        if (!sel.value) sel.disabled = true;
    });
});

// Pipeline step click — each step is an independent toggle
document.querySelectorAll('.pipeline-step').forEach(function(step) {
    step.addEventListener('click', function(e) {
        e.stopPropagation();
        var mrId    = step.closest('tr').dataset.mrId;
        var field   = step.dataset.field;
        var wasDone = step.classList.contains('step-done');
        // Optimistic update
        step.classList.toggle('step-done', !wasDone);
        step.classList.toggle('step-todo',  wasDone);
        fetch('/mrs/' + mrId + '/toggle/' + field, { method: 'POST' })
            .then(function(r) { return r.json(); })
            .then(function(d) {
                step.classList.toggle('step-done',  d.newValue);
                step.classList.toggle('step-todo',  !d.newValue);
            })
            .catch(function() {
                // Revert on error
                step.classList.toggle('step-done',  wasDone);
                step.classList.toggle('step-todo',  !wasDone);
            });
    });
});

// Deployment and canIgnore boolean toggles — exclude pipeline-step elements
document.querySelectorAll('.step:not(.pipeline-step)[data-field]').forEach(function(step) {
    step.addEventListener('click', function(e) {
        e.stopPropagation();
        var field = step.dataset.field;
        var mrId  = step.closest('tr').dataset.mrId;
        if (!mrId || !field) return;

        var wasDone = step.classList.contains('step-done');
        var applyState = function(isDone) {
            step.classList.toggle('step-done', isDone);
            step.classList.toggle('step-todo', !isDone);
            if (step.dataset.textTrue && step.dataset.textFalse) {
                step.textContent = isDone ? step.dataset.textTrue : step.dataset.textFalse;
            }
        };
        applyState(!wasDone);

        fetch('/mrs/' + mrId + '/toggle/' + field, { method: 'POST' })
            .then(function(r) {
                if (!r.ok) throw new Error('Toggle failed');
                return r.json();
            })
            .then(function(data) { applyState(data.newValue); })
            .catch(function()    { applyState(wasDone); });
    });
});
</script>

<%@include file="../layout/footer.jsp" %>
