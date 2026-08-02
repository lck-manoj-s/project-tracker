<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="mb-0"><i class="bi bi-clock-history me-2"></i>Audit History</h4>
</div>

<%-- ── Tabs ──────────────────────────────────────────────────────────── --%>
<ul class="nav nav-tabs mb-3">
    <li class="nav-item">
        <a class="nav-link ${tab == 'tasks' ? 'active' : ''}" href="/history?tab=tasks">
            <i class="bi bi-list-task me-1"></i>Tasks
        </a>
    </li>
    <li class="nav-item">
        <a class="nav-link ${tab == 'mrs' ? 'active' : ''}" href="/history?tab=mrs">
            <i class="bi bi-git me-1"></i>Merge Requests
        </a>
    </li>
</ul>

<%-- ── TASK HISTORY ────────────────────────────────────────────────── --%>
<c:if test="${tab == 'tasks'}">

    <div class="filter-card p-3 mb-3">
        <form method="get" action="/history" class="row g-2 align-items-end">
            <input type="hidden" name="tab" value="tasks"/>
            <div class="col-auto">
                <label class="filter-label d-block">Task #</label>
                <input type="number" name="taskId" class="form-control form-control-sm" style="width:100px;"
                       value="${taskId}" placeholder="e.g. 42"/>
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
                <table class="table table-hover table-bordered table-sm mb-0">
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
                                            <a href="/tasks/edit/${h.task.taskId}" class="fw-semibold text-decoration-none">#${h.task.taskId}</a>
                                        </td>
                                        <td class="align-middle small text-muted" style="max-width:280px;">
                                            <span class="d-inline-block text-truncate" style="max-width:270px;" title="${h.task.description}">${h.task.description}</span>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.previousStatus != null}">
                                                    <span class="badge bg-light text-dark border">${h.previousStatus.displayName}</span>
                                                </c:when>
                                                <c:otherwise><span class="text-muted small">— (new)</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.newStatus.name() == 'YET_TO_START'}"><span class="badge bg-danger">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'IDENTIFYING_ISSUE'}"><span class="badge bg-warning text-dark">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'FIXING'}"><span class="badge bg-info text-dark">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'MR_CREATED'}"><span class="badge bg-primary">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'DONE'}"><span class="badge bg-success">${h.newStatus.displayName}</span></c:when>
                                                <c:otherwise><span class="badge bg-secondary">${h.newStatus.displayName}</span></c:otherwise>
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
        <div class="card-footer d-flex justify-content-between align-items-center">
            <span class="text-muted small">
                Showing ${taskHistory.size()} of ${totalElements} entries
                &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
            </span>
            <c:if test="${totalPages > 1}">
                <nav><ul class="pagination pagination-sm mb-0">
                    <li class="page-item ${currentPage == 0 ? 'disabled' : ''}">
                        <c:url var="p0" value="/history">
                            <c:param name="tab" value="tasks"/>
                            <c:if test="${taskId != null}"><c:param name="taskId" value="${taskId}"/></c:if>
                            <c:if test="${not empty prevStatus}"><c:param name="prevStatus" value="${prevStatus}"/></c:if>
                            <c:if test="${not empty newStatus}"><c:param name="newStatus" value="${newStatus}"/></c:if>
                            <c:param name="page" value="${currentPage - 1}"/>
                        </c:url>
                        <a class="page-link" href="${p0}"><i class="bi bi-chevron-left"></i></a>
                    </li>
                    <c:forEach begin="0" end="${totalPages - 1}" var="pg">
                        <li class="page-item ${pg == currentPage ? 'active' : ''}">
                            <c:url var="pp" value="/history">
                                <c:param name="tab" value="tasks"/>
                                <c:if test="${taskId != null}"><c:param name="taskId" value="${taskId}"/></c:if>
                                <c:if test="${not empty prevStatus}"><c:param name="prevStatus" value="${prevStatus}"/></c:if>
                                <c:if test="${not empty newStatus}"><c:param name="newStatus" value="${newStatus}"/></c:if>
                                <c:param name="page" value="${pg}"/>
                            </c:url>
                            <a class="page-link" href="${pp}">${pg + 1}</a>
                        </li>
                    </c:forEach>
                    <li class="page-item ${currentPage + 1 >= totalPages ? 'disabled' : ''}">
                        <c:url var="p1" value="/history">
                            <c:param name="tab" value="tasks"/>
                            <c:if test="${taskId != null}"><c:param name="taskId" value="${taskId}"/></c:if>
                            <c:if test="${not empty prevStatus}"><c:param name="prevStatus" value="${prevStatus}"/></c:if>
                            <c:if test="${not empty newStatus}"><c:param name="newStatus" value="${newStatus}"/></c:if>
                            <c:param name="page" value="${currentPage + 1}"/>
                        </c:url>
                        <a class="page-link" href="${p1}"><i class="bi bi-chevron-right"></i></a>
                    </li>
                </ul></nav>
            </c:if>
        </div>
    </div>
</c:if>

<%-- ── MR HISTORY ──────────────────────────────────────────────────── --%>
<c:if test="${tab == 'mrs'}">

    <div class="filter-card p-3 mb-3">
        <form method="get" action="/history" class="row g-2 align-items-end">
            <input type="hidden" name="tab" value="mrs"/>
            <div class="col-auto">
                <label class="filter-label d-block">MR #</label>
                <input type="number" name="mrId" class="form-control form-control-sm" style="width:100px;"
                       value="${mrId}" placeholder="e.g. 42"/>
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
                <table class="table table-hover table-bordered table-sm mb-0">
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
                                            <span class="badge ${h.mergeRequest.product.name() == 'PAYROLL' ? 'bg-warning text-dark' : 'bg-info text-dark'} me-1">${h.mergeRequest.product.displayName}</span>
                                            <a href="${h.mergeRequest.mr}" target="_blank" class="fw-semibold text-decoration-none">${h.mergeRequest.mrNumber}</a>
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
                                                    <span class="badge bg-light text-dark border">${h.previousStatus.displayName}</span>
                                                </c:when>
                                                <c:otherwise><span class="text-muted small">— (new)</span></c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${h.newStatus.name() == 'NEW'}"><span class="badge bg-secondary">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'REVIEWED'}"><span class="badge bg-info text-dark">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'DI_COMPLETED'}"><span class="badge bg-primary">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'GTM'}"><span class="badge bg-warning text-dark">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'RTM'}"><span class="badge bg-dark">${h.newStatus.displayName}</span></c:when>
                                                <c:when test="${h.newStatus.name() == 'MERGED'}"><span class="badge bg-success">${h.newStatus.displayName}</span></c:when>
                                                <c:otherwise><span class="badge bg-secondary">${h.newStatus.displayName}</span></c:otherwise>
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
        <div class="card-footer d-flex justify-content-between align-items-center">
            <span class="text-muted small">
                Showing ${mrHistory.size()} of ${totalElements} entries
                &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
            </span>
            <c:if test="${totalPages > 1}">
                <nav><ul class="pagination pagination-sm mb-0">
                    <li class="page-item ${currentPage == 0 ? 'disabled' : ''}">
                        <c:url var="mp0" value="/history">
                            <c:param name="tab" value="mrs"/>
                            <c:if test="${mrId != null}"><c:param name="mrId" value="${mrId}"/></c:if>
                            <c:if test="${not empty product}"><c:param name="product" value="${product}"/></c:if>
                            <c:if test="${not empty prevMrStatus}"><c:param name="prevMrStatus" value="${prevMrStatus}"/></c:if>
                            <c:if test="${not empty newMrStatus}"><c:param name="newMrStatus" value="${newMrStatus}"/></c:if>
                            <c:param name="page" value="${currentPage - 1}"/>
                        </c:url>
                        <a class="page-link" href="${mp0}"><i class="bi bi-chevron-left"></i></a>
                    </li>
                    <c:forEach begin="0" end="${totalPages - 1}" var="pg">
                        <li class="page-item ${pg == currentPage ? 'active' : ''}">
                            <c:url var="mpp" value="/history">
                                <c:param name="tab" value="mrs"/>
                                <c:if test="${mrId != null}"><c:param name="mrId" value="${mrId}"/></c:if>
                                <c:if test="${not empty product}"><c:param name="product" value="${product}"/></c:if>
                                <c:if test="${not empty prevMrStatus}"><c:param name="prevMrStatus" value="${prevMrStatus}"/></c:if>
                                <c:if test="${not empty newMrStatus}"><c:param name="newMrStatus" value="${newMrStatus}"/></c:if>
                                <c:param name="page" value="${pg}"/>
                            </c:url>
                            <a class="page-link" href="${mpp}">${pg + 1}</a>
                        </li>
                    </c:forEach>
                    <li class="page-item ${currentPage + 1 >= totalPages ? 'disabled' : ''}">
                        <c:url var="mp1" value="/history">
                            <c:param name="tab" value="mrs"/>
                            <c:if test="${mrId != null}"><c:param name="mrId" value="${mrId}"/></c:if>
                            <c:if test="${not empty product}"><c:param name="product" value="${product}"/></c:if>
                            <c:if test="${not empty prevMrStatus}"><c:param name="prevMrStatus" value="${prevMrStatus}"/></c:if>
                            <c:if test="${not empty newMrStatus}"><c:param name="newMrStatus" value="${newMrStatus}"/></c:if>
                            <c:param name="page" value="${currentPage + 1}"/>
                        </c:url>
                        <a class="page-link" href="${mp1}"><i class="bi bi-chevron-right"></i></a>
                    </li>
                </ul></nav>
            </c:if>
        </div>
    </div>
</c:if>

<%@include file="../layout/footer.jsp" %>
