<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>
<link rel="stylesheet" href="/css/lists.css">

<h4 class="mb-3"><i class="bi bi-clock-history me-2"></i>Audit History</h4>

<%-- ── Tabs ──────────────────────────────────────────────────────────── --%>
<div class="segmented mb-3" role="tablist">
    <a class="segmented-item ${tab == 'tasks' ? 'active' : ''}" href="/history?tab=tasks" role="tab" aria-selected="${tab == 'tasks'}">
        <i class="bi bi-list-task"></i>Tasks
    </a>
    <a class="segmented-item ${tab == 'mrs' ? 'active' : ''}" href="/history?tab=mrs" role="tab" aria-selected="${tab == 'mrs'}">
        <i class="bi bi-git"></i>Merge Requests
    </a>
    <a class="segmented-item ${tab == 'deployment' ? 'active' : ''}" href="/history?tab=deployment" role="tab" aria-selected="${tab == 'deployment'}">
        <i class="bi bi-cloud-arrow-up"></i>Deployment
    </a>
</div>

<%-- ── TASK HISTORY ────────────────────────────────────────────────── --%>
<c:if test="${tab == 'tasks'}">

    <div class="filter-card list-filter p-3 mb-3">
        <form method="get" action="/history" class="row g-2 align-items-end">
            <input type="hidden" name="tab" value="tasks"/>
            <div class="col-auto">
                <label class="filter-label d-block">Task #</label>
                <input type="number" name="taskId" class="form-control form-control-sm" style="width:100px;"
                       value="${taskId}" placeholder="e.g. 42"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">Description</label>
                <input type="text" name="taskDescription" class="form-control form-control-sm" style="width:180px;"
                       value="${taskDescription}" placeholder="e.g. payroll fix"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">Previous Status</label>
                <select name="prevStatus" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="s" items="${taskStatusValues}">
                        <option value="${s.name()}" ${s.name() == prevStatus ? 'selected' : ''}>${s.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">New Status</label>
                <select name="newStatus" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="s" items="${taskStatusValues}">
                        <option value="${s.name()}" ${s.name() == newStatus ? 'selected' : ''}>${s.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto d-flex gap-2">
                <button type="submit" class="btn btn-sm btn-outline-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
                <a href="/history?tab=tasks" class="btn btn-sm btn-outline-secondary"><i class="bi bi-x-circle me-1"></i>Clear</a>
            </div>
        </form>
    </div>

    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover table-bordered table-sm mb-0" id="taskHistoryTable">
                    <thead>
                        <tr>
                            <th>#</th><th>Task</th><th>Description</th>
                            <th>Previous Status</th><th>New Status</th><th>Changed At</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty taskHistory}">
                                <tr><td colspan="6" class="text-center text-muted py-3">
                                    <i class="bi bi-inbox me-1"></i>No task history found
                                </td></tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="h" items="${taskHistory}">
                                    <tr>
                                        <td class="text-muted small align-middle">${h.id}</td>
                                        <td class="align-middle">
                                            <a href="/tasks/edit/${h.task.taskId}" class="pill pill-blue text-decoration-none">#${h.task.taskId}</a>
                                        </td>
                                        <td class="align-middle small text-muted" style="max-width:280px;">
                                            <span class="d-inline-block text-truncate" style="max-width:270px;" title="${h.task.description}">${h.task.description}</span>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.previousStatus != null}">
                                                    <span class="pill pill-gray">${h.previousStatus.displayName}</span>
                                                </c:when>
                                                <c:otherwise><span class="text-muted small">— (new)</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.newStatus.name() == 'YET_TO_START'}"><span class="pill pill-red"><i class="bi bi-circle"></i>${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'IDENTIFYING_ISSUE'}"><span class="pill pill-amber"><i class="bi bi-search"></i>${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'FIXING'}"><span class="pill pill-teal"><i class="bi bi-wrench"></i>${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'MR_CREATED'}"><span class="pill pill-blue"><i class="bi bi-git"></i>${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'REWORKING'}"><span class="pill pill-purple"><i class="bi bi-arrow-repeat"></i>${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'HALTED'}"><span class="pill pill-gray"><i class="bi bi-pause-circle"></i>${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'DONE'}"><span class="pill pill-green"><i class="bi bi-check-circle"></i>${h.newStatus.displayName}</span></c:when>
                                                <c:otherwise><span class="pill pill-gray"><i class="bi bi-circle"></i>${h.newStatus.displayName}</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle text-nowrap small">
                                            ${fn:substring(h.changedAt.toString(), 0, 10)}
                                            <span class="text-muted ms-1">${fn:substring(h.changedAt.toString(), 11, 16)}</span>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="card-footer list-footer d-flex justify-content-between align-items-center">
            <span class="text-muted small">
                Showing ${taskHistory.size()} of ${totalElements} entries
                &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
            </span>
            <c:if test="${totalPages > 1}">
                <div class="d-flex gap-2">
                    <c:choose>
                        <c:when test="${currentPage == 0}">
                            <span class="btn-pager is-disabled"><i class="bi bi-chevron-left"></i>Previous</span>
                        </c:when>
                        <c:otherwise>
                            <c:url var="p0" value="/history">
                                <c:param name="tab" value="tasks"/>
                                <c:if test="${taskId != null}"><c:param name="taskId" value="${taskId}"/></c:if>
                                <c:if test="${not empty prevStatus}"><c:param name="prevStatus" value="${prevStatus}"/></c:if>
                                <c:if test="${not empty newStatus}"><c:param name="newStatus" value="${newStatus}"/></c:if>
                                <c:if test="${not empty taskDescription}"><c:param name="taskDescription" value="${taskDescription}"/></c:if>
                                <c:param name="page" value="${currentPage - 1}"/>
                            </c:url>
                            <a class="btn-pager" href="${p0}"><i class="bi bi-chevron-left"></i>Previous</a>
                        </c:otherwise>
                    </c:choose>
                    <c:choose>
                        <c:when test="${currentPage + 1 >= totalPages}">
                            <span class="btn-pager is-disabled">Next<i class="bi bi-chevron-right"></i></span>
                        </c:when>
                        <c:otherwise>
                            <c:url var="p1" value="/history">
                                <c:param name="tab" value="tasks"/>
                                <c:if test="${taskId != null}"><c:param name="taskId" value="${taskId}"/></c:if>
                                <c:if test="${not empty prevStatus}"><c:param name="prevStatus" value="${prevStatus}"/></c:if>
                                <c:if test="${not empty newStatus}"><c:param name="newStatus" value="${newStatus}"/></c:if>
                                <c:if test="${not empty taskDescription}"><c:param name="taskDescription" value="${taskDescription}"/></c:if>
                                <c:param name="page" value="${currentPage + 1}"/>
                            </c:url>
                            <a class="btn-pager" href="${p1}">Next<i class="bi bi-chevron-right"></i></a>
                        </c:otherwise>
                    </c:choose>
                </div>
            </c:if>
        </div>
    </div>
</c:if>

<%-- ── MR HISTORY ──────────────────────────────────────────────────── --%>
<c:if test="${tab == 'mrs'}">

    <div class="filter-card list-filter p-3 mb-3">
        <form method="get" action="/history" class="row g-2 align-items-end">
            <input type="hidden" name="tab" value="mrs"/>
            <div class="col-auto">
                <label class="filter-label d-block">MR #</label>
                <input type="number" name="mrId" class="form-control form-control-sm" style="width:100px;"
                       value="${mrId}" placeholder="e.g. 42"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">MR Name</label>
                <input type="text" name="mrName" class="form-control form-control-sm" style="width:160px;"
                       value="${mrName}" placeholder="e.g. payroll fix"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">Product</label>
                <select name="product" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="p" items="${products}">
                        <option value="${p.name()}" ${p.name() == product ? 'selected' : ''}>${p.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">Previous Status</label>
                <select name="prevMrStatus" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="s" items="${mrStatusValues}">
                        <option value="${s.name()}" ${s.name() == prevMrStatus ? 'selected' : ''}>${s.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">New Status</label>
                <select name="newMrStatus" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="s" items="${mrStatusValues}">
                        <option value="${s.name()}" ${s.name() == newMrStatus ? 'selected' : ''}>${s.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto d-flex gap-2">
                <button type="submit" class="btn btn-sm btn-outline-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
                <a href="/history?tab=mrs" class="btn btn-sm btn-outline-secondary"><i class="bi bi-x-circle me-1"></i>Clear</a>
            </div>
        </form>
    </div>

    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover table-bordered table-sm mb-0" id="mrHistoryTable">
                    <thead>
                        <tr>
                            <th>#</th><th>MR</th><th>Name</th>
                            <th>Previous Status</th><th>New Status</th><th>Changed At</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty mrHistory}">
                                <tr><td colspan="6" class="text-center text-muted py-3">
                                    <i class="bi bi-inbox me-1"></i>No MR history found
                                </td></tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="h" items="${mrHistory}">
                                    <tr>
                                        <td class="text-muted small align-middle">${h.id}</td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.mergeRequest.product.name() == 'PAYROLL'}"><c:set var="hProd" value="pill-green"/></c:when>
                                                <c:when test="${h.mergeRequest.product.name() == 'BOOKS'}"><c:set var="hProd" value="pill-purple"/></c:when>
                                                <c:when test="${h.mergeRequest.product.name() == 'SPEND'}"><c:set var="hProd" value="pill-pink"/></c:when>
                                                <c:otherwise><c:set var="hProd" value="pill-gray"/></c:otherwise>
                                            </c:choose>
                                            <a href="${h.mergeRequest.mr}" target="_blank" class="pill ${hProd} text-decoration-none">${h.mergeRequest.mrNumber}</a>
                                            <a href="/mrs/edit/${h.mergeRequest.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1 ms-1"><i class="bi bi-pencil" style="font-size:.65rem;"></i></a>
                                        </td>
                                        <td class="align-middle small text-muted" style="max-width:220px;">
                                            <c:choose>
                                                <c:when test="${not empty h.mergeRequest.name}">
                                                    <span class="d-inline-block text-truncate" style="max-width:210px;" title="${h.mergeRequest.name}">${h.mergeRequest.name}</span>
                                                </c:when>
                                                <c:otherwise><span class="text-muted">&#8212;</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.previousStatus != null}">
                                                    <span class="pill pill-gray">${h.previousStatus.displayName}</span>
                                                </c:when>
                                                <c:otherwise><span class="text-muted small">— (new)</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.newStatus.name() == 'NEW'}"><span class="pill pill-gray">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'REVIEWED'}"><span class="pill pill-teal">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'DI_COMPLETED'}"><span class="pill pill-blue">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'GTM'}"><span class="pill pill-amber">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'RTM'}"><span class="pill pill-coral">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'MERGED'}"><span class="pill pill-green">${h.newStatus.displayName}</span></c:when>
                                                <c:otherwise><span class="pill pill-gray">${h.newStatus.displayName}</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle text-nowrap small">
                                            ${fn:substring(h.changedAt.toString(), 0, 10)}
                                            <span class="text-muted ms-1">${fn:substring(h.changedAt.toString(), 11, 16)}</span>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="card-footer list-footer d-flex justify-content-between align-items-center">
            <span class="text-muted small">
                Showing ${mrHistory.size()} of ${totalElements} entries
                &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
            </span>
            <c:if test="${totalPages > 1}">
                <div class="d-flex gap-2">
                    <c:choose>
                        <c:when test="${currentPage == 0}">
                            <span class="btn-pager is-disabled"><i class="bi bi-chevron-left"></i>Previous</span>
                        </c:when>
                        <c:otherwise>
                            <c:url var="mp0" value="/history">
                                <c:param name="tab" value="mrs"/>
                                <c:if test="${mrId != null}"><c:param name="mrId" value="${mrId}"/></c:if>
                                <c:if test="${not empty product}"><c:param name="product" value="${product}"/></c:if>
                                <c:if test="${not empty prevMrStatus}"><c:param name="prevMrStatus" value="${prevMrStatus}"/></c:if>
                                <c:if test="${not empty newMrStatus}"><c:param name="newMrStatus" value="${newMrStatus}"/></c:if>
                                <c:if test="${not empty mrName}"><c:param name="mrName" value="${mrName}"/></c:if>
                                <c:param name="page" value="${currentPage - 1}"/>
                            </c:url>
                            <a class="btn-pager" href="${mp0}"><i class="bi bi-chevron-left"></i>Previous</a>
                        </c:otherwise>
                    </c:choose>
                    <c:choose>
                        <c:when test="${currentPage + 1 >= totalPages}">
                            <span class="btn-pager is-disabled">Next<i class="bi bi-chevron-right"></i></span>
                        </c:when>
                        <c:otherwise>
                            <c:url var="mp1" value="/history">
                                <c:param name="tab" value="mrs"/>
                                <c:if test="${mrId != null}"><c:param name="mrId" value="${mrId}"/></c:if>
                                <c:if test="${not empty product}"><c:param name="product" value="${product}"/></c:if>
                                <c:if test="${not empty prevMrStatus}"><c:param name="prevMrStatus" value="${prevMrStatus}"/></c:if>
                                <c:if test="${not empty newMrStatus}"><c:param name="newMrStatus" value="${newMrStatus}"/></c:if>
                                <c:if test="${not empty mrName}"><c:param name="mrName" value="${mrName}"/></c:if>
                                <c:param name="page" value="${currentPage + 1}"/>
                            </c:url>
                            <a class="btn-pager" href="${mp1}">Next<i class="bi bi-chevron-right"></i></a>
                        </c:otherwise>
                    </c:choose>
                </div>
            </c:if>
        </div>
    </div>
</c:if>

<%-- ── DEPLOYMENT HISTORY ──────────────────────────────────────────── --%>
<c:if test="${tab == 'deployment'}">

    <div class="filter-card list-filter p-3 mb-3">
        <form method="get" action="/history" class="row g-2 align-items-end">
            <input type="hidden" name="tab" value="deployment"/>
            <div class="col-auto">
                <label class="filter-label d-block">MR #</label>
                <input type="number" name="mrId" class="form-control form-control-sm" style="width:100px;"
                       value="${mrId}" placeholder="e.g. 42"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">MR Name</label>
                <input type="text" name="mrName" class="form-control form-control-sm" style="width:160px;"
                       value="${mrName}" placeholder="e.g. payroll fix"/>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">Product</label>
                <select name="product" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="p" items="${products}">
                        <option value="${p.name()}" ${p.name() == product ? 'selected' : ''}>${p.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">Previous Stage</label>
                <select name="prevDeployStatus" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="s" items="${deploymentStatusValues}">
                        <option value="${s.name()}" ${s.name() == prevDeployStatus ? 'selected' : ''}>${s.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto">
                <label class="filter-label d-block">New Stage</label>
                <select name="newDeployStatus" class="form-select form-select-sm">
                    <option value="">All</option>
                    <c:forEach var="s" items="${deploymentStatusValues}">
                        <option value="${s.name()}" ${s.name() == newDeployStatus ? 'selected' : ''}>${s.displayName}</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-auto d-flex gap-2">
                <button type="submit" class="btn btn-sm btn-outline-primary"><i class="bi bi-funnel me-1"></i>Filter</button>
                <a href="/history?tab=deployment" class="btn btn-sm btn-outline-secondary"><i class="bi bi-x-circle me-1"></i>Clear</a>
            </div>
        </form>
    </div>

    <div class="card shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover table-bordered table-sm mb-0" id="deploymentHistoryTable">
                    <thead>
                        <tr>
                            <th>#</th><th>MR</th><th>Name</th>
                            <th>Previous Stage</th><th>New Stage</th><th>Changed At</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty deploymentHistory}">
                                <tr><td colspan="6" class="text-center text-muted py-3">
                                    <i class="bi bi-inbox me-1"></i>No deployment history found
                                </td></tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="h" items="${deploymentHistory}">
                                    <tr>
                                        <td class="text-muted small align-middle">${h.id}</td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.mergeRequest.product.name() == 'PAYROLL'}"><c:set var="hProd" value="pill-green"/></c:when>
                                                <c:when test="${h.mergeRequest.product.name() == 'BOOKS'}"><c:set var="hProd" value="pill-purple"/></c:when>
                                                <c:when test="${h.mergeRequest.product.name() == 'SPEND'}"><c:set var="hProd" value="pill-pink"/></c:when>
                                                <c:otherwise><c:set var="hProd" value="pill-gray"/></c:otherwise>
                                            </c:choose>
                                            <span class="pill ${hProd}">${h.mergeRequest.product.displayName}</span>
                                            <a href="${h.mergeRequest.mr}" target="_blank" class="pill ${hProd} text-decoration-none">${h.mergeRequest.mrNumber}</a>
                                            <a href="/mrs/edit/${h.mergeRequest.mrSerialNumber}" class="btn btn-sm btn-outline-secondary py-0 px-1 ms-1"><i class="bi bi-pencil" style="font-size:.65rem;"></i></a>
                                        </td>
                                        <td class="align-middle small text-muted" style="max-width:220px;">
                                            <c:choose>
                                                <c:when test="${not empty h.mergeRequest.name}">
                                                    <span class="d-inline-block text-truncate" style="max-width:210px;" title="${h.mergeRequest.name}">${h.mergeRequest.name}</span>
                                                </c:when>
                                                <c:otherwise><span class="text-muted">&#8212;</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.previousStatus != null}">
                                                    <span class="pill pill-gray">${h.previousStatus.displayName}</span>
                                                </c:when>
                                                <c:otherwise><span class="text-muted small">— (new)</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.newStatus.name() == 'NONE'}"><span class="pill pill-gray">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'LOCAL'}"><span class="pill pill-teal">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'PRE'}"><span class="pill pill-amber">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'IDC'}"><span class="pill pill-green">${h.newStatus.displayName}</span></c:when>
                                                <c:otherwise><span class="pill pill-gray">${h.newStatus.displayName}</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle text-nowrap small">
                                            ${fn:substring(h.changedAt.toString(), 0, 10)}
                                            <span class="text-muted ms-1">${fn:substring(h.changedAt.toString(), 11, 16)}</span>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="card-footer list-footer d-flex justify-content-between align-items-center">
            <span class="text-muted small">
                Showing ${deploymentHistory.size()} of ${totalElements} entries
                &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
            </span>
            <c:if test="${totalPages > 1}">
                <div class="d-flex gap-2">
                    <c:choose>
                        <c:when test="${currentPage == 0}">
                            <span class="btn-pager is-disabled"><i class="bi bi-chevron-left"></i>Previous</span>
                        </c:when>
                        <c:otherwise>
                            <c:url var="dp0" value="/history">
                                <c:param name="tab" value="deployment"/>
                                <c:if test="${mrId != null}"><c:param name="mrId" value="${mrId}"/></c:if>
                                <c:if test="${not empty product}"><c:param name="product" value="${product}"/></c:if>
                                <c:if test="${not empty prevDeployStatus}"><c:param name="prevDeployStatus" value="${prevDeployStatus}"/></c:if>
                                <c:if test="${not empty newDeployStatus}"><c:param name="newDeployStatus" value="${newDeployStatus}"/></c:if>
                                <c:if test="${not empty mrName}"><c:param name="mrName" value="${mrName}"/></c:if>
                                <c:param name="page" value="${currentPage - 1}"/>
                            </c:url>
                            <a class="btn-pager" href="${dp0}"><i class="bi bi-chevron-left"></i>Previous</a>
                        </c:otherwise>
                    </c:choose>
                    <c:choose>
                        <c:when test="${currentPage + 1 >= totalPages}">
                            <span class="btn-pager is-disabled">Next<i class="bi bi-chevron-right"></i></span>
                        </c:when>
                        <c:otherwise>
                            <c:url var="dp1" value="/history">
                                <c:param name="tab" value="deployment"/>
                                <c:if test="${mrId != null}"><c:param name="mrId" value="${mrId}"/></c:if>
                                <c:if test="${not empty product}"><c:param name="product" value="${product}"/></c:if>
                                <c:if test="${not empty prevDeployStatus}"><c:param name="prevDeployStatus" value="${prevDeployStatus}"/></c:if>
                                <c:if test="${not empty newDeployStatus}"><c:param name="newDeployStatus" value="${newDeployStatus}"/></c:if>
                                <c:if test="${not empty mrName}"><c:param name="mrName" value="${mrName}"/></c:if>
                                <c:param name="page" value="${currentPage + 1}"/>
                            </c:url>
                            <a class="btn-pager" href="${dp1}">Next<i class="bi bi-chevron-right"></i></a>
                        </c:otherwise>
                    </c:choose>
                </div>
            </c:if>
        </div>
    </div>
</c:if>

<%@include file="../layout/footer.jsp" %>
