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
                        <th>Pipeline</th>
                        <th>Linked</th>
                        <c:if test="${canIgnore != 'false'}"><th>Can Ignore</th></c:if>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:choose>
                        <c:when test="${empty mrs}">
                            <tr><td colspan="${canIgnore != 'false' ? 8 : 7}" class="text-center text-muted py-3">
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
                                        <c:if test="${mr.parentMr != null}">
                                            <button type="button" class="badge bg-secondary border-0 mr-chain-btn" data-mr-id="${mr.mrSerialNumber}"
                                                    title="View MR chain (Parent: ${mr.parentMrNumber} · ${mr.parentMr.product.displayName})">
                                                <i class="bi bi-link-45deg"></i>
                                            </button>
                                        </c:if>
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
                                        <%-- Pipeline: a single current stage (mr.status) — clicking a badge jumps the MR to that stage --%>
                                        <div class="pipeline-steps" title="${mr.status.displayName}">
                                            <span class="step pipeline-step ${mr.stepNew         ? 'step-done' : 'step-todo'}" data-status="NEW"          title="New">N</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepReviewed    ? 'step-done' : 'step-todo'}" data-status="REVIEWED"     title="Reviewed">R</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepDiCompleted ? 'step-done' : 'step-todo'}" data-status="DI_COMPLETED" title="DI Completed">DI</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepGtm         ? 'step-done' : 'step-todo'}" data-status="GTM"          title="GTM">GTM</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepRtm         ? 'step-done' : 'step-todo'}" data-status="RTM"          title="RTM">RTM</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step pipeline-step ${mr.stepMerged      ? 'step-done' : 'step-todo'}" data-status="MERGED"       title="Merged">M</span>
                                        </div>
                                    </td>
                                    <td class="align-middle">
                                        <span class="badge ${mr.mrLinked.name() == 'LINKED' ? 'bg-success' : mr.mrLinked.name() == 'NOT_LINKED' ? 'bg-danger' : 'bg-secondary'}">
                                            ${mr.mrLinked.displayName}
                                        </span>
                                    </td>
                                    <c:if test="${canIgnore != 'false'}">
                                        <td class="align-middle">
                                            <span class="step ${mr.canIgnore ? 'step-done' : 'step-todo'}"
                                                  data-field="canIgnore"
                                                  data-text-true="Yes" data-text-false="No"
                                                  title="Click to toggle">
                                                ${mr.canIgnore ? 'Yes' : 'No'}
                                            </span>
                                        </td>
                                    </c:if>
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
                        <c:if test="${canIgnore != 'false'}">     <c:param name="canIgnore"       value="${canIgnore}"/></c:if>
                        <c:param name="page" value="${currentPage + 1}"/>
                    </c:url>
                    <a class="page-link" href="${nextUrl}"><i class="bi bi-chevron-right"></i></a>
                </li>

            </ul></nav>
        </c:if>
    </div>
</div>

<%-- ── MR Chain Panel (hidden until a parent-chain button is clicked) ─── --%>
<div id="mrChainPanel" style="display:none;" class="card shadow-sm my-4 overflow-hidden">
    <div class="card-header bg-dark text-white d-flex justify-content-between align-items-center py-2">
        <span><i class="bi bi-diagram-2 me-2"></i>MR Chain</span>
        <button type="button" class="btn-close btn-close-white btn-sm" onclick="hideChainPanel()"></button>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover table-bordered table-sm mb-0">
                <thead>
                    <tr id="chainPanelHeadRow">
                        <th style="width:130px;">Field</th>
                        <!-- MR columns filled by JS -->
                    </tr>
                </thead>
                <tbody id="chainPanelBody">
                    <!-- filled by JS -->
                </tbody>
            </table>
        </div>
    </div>
</div>

<script>
// Strip empty filter params so the URL only contains changed values
document.getElementById('mrFilterForm').addEventListener('submit', function () {
    this.querySelectorAll('select').forEach(function (sel) {
        if (!sel.value) sel.disabled = true;
    });
});

// Pipeline stage order — used to redraw an entire row's badges from a single status value
var PIPELINE_STAGES = ['NEW', 'REVIEWED', 'DI_COMPLETED', 'GTM', 'RTM', 'MERGED'];

function applyPipelineStatus(container, status) {
    var idx = PIPELINE_STAGES.indexOf(status);
    container.querySelectorAll('.pipeline-step').forEach(function (s) {
        var done = PIPELINE_STAGES.indexOf(s.dataset.status) <= idx;
        s.classList.toggle('step-done', done);
        s.classList.toggle('step-todo', !done);
    });
    container.title = status;
}

// Pipeline step click — jumps the MR directly to the clicked stage (forward or backward)
document.querySelectorAll('.pipeline-step').forEach(function (step) {
    step.addEventListener('click', function (e) {
        e.stopPropagation();
        var row       = step.closest('tr');
        var mrId      = row.dataset.mrId;
        var container = step.closest('.pipeline-steps');
        var status    = step.dataset.status;
        var prevStatus = 'NEW';
        PIPELINE_STAGES.forEach(function (s) {
            if (container.querySelector('[data-status="' + s + '"]').classList.contains('step-done')) prevStatus = s;
        });

        applyPipelineStatus(container, status); // optimistic
        fetch('/mrs/' + mrId + '/status/' + status, { method: 'POST' })
            .then(function (r) { if (!r.ok) throw new Error('Update failed'); return r.json(); })
            .then(function (d) { applyPipelineStatus(container, d.status); })
            .catch(function () { applyPipelineStatus(container, prevStatus || 'NEW'); });
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

// ── MR Chain panel — clicking a parent-MR badge shows this MR plus every
// ancestor MR (parentMr, parentMr.parentMr, ...) as columns, mirroring the
// task page's per-task MR panel.
var chainPanel     = document.getElementById('mrChainPanel');
var chainPanelBody = document.getElementById('chainPanelBody');
var chainPanelHead = document.getElementById('chainPanelHeadRow');

document.querySelectorAll('.mr-chain-btn').forEach(function (btn) {
    btn.addEventListener('click', function (e) {
        e.stopPropagation();
        var mrId = this.dataset.mrId;
        fetch('/mrs/' + mrId + '/chain')
            .then(function (r) { return r.json(); })
            .then(function (data) { renderChainPanel(data); })
            .catch(function () { alert('Could not load MR chain.'); });
    });
});

document.addEventListener('click', function (e) {
    if (!e.target.closest('#mrChainPanel') && !e.target.closest('.mr-chain-btn')) {
        hideChainPanel();
    }
});

window.hideChainPanel = function () { chainPanel.style.display = 'none'; };

function chainProductBadgeClass(product) {
    return product === 'Payroll' ? 'bg-warning text-dark' : 'bg-info text-dark';
}

function chainNa() { return '<span class="text-muted">—</span>'; }

function chainMrLinkCell(mr) {
    return '<a href="' + mr.mr + '" target="_blank" class="badge bg-dark text-decoration-none me-1">'
         + '<i class="bi bi-box-arrow-up-right me-1"></i>' + mr.mrNumber + '</a>'
         + '<a href="/mrs/edit/' + mr.mrSerialNumber + '" class="btn btn-sm btn-outline-secondary py-0" '
         + 'onclick="event.stopPropagation()" title="Edit MR">'
         + '<i class="bi bi-pencil"></i></a>';
}

function chainNameCell(mr) {
    if (!mr.name) return null;
    return '<span class="text-muted small">' + mr.name + '</span>';
}

function chainPipelineCell(mr) {
    var steps = [
        { status: 'NEW',          label: 'N',   title: 'New',          val: mr.stepNew },
        { status: 'REVIEWED',     label: 'R',   title: 'Reviewed',     val: mr.stepReviewed },
        { status: 'DI_COMPLETED', label: 'DI',  title: 'DI Completed', val: mr.stepDiCompleted },
        { status: 'GTM',          label: 'GTM', title: 'GTM',          val: mr.stepGtm },
        { status: 'RTM',          label: 'RTM', title: 'RTM',          val: mr.stepRtm },
        { status: 'MERGED',       label: 'M',   title: 'Merged',       val: mr.stepMerged }
    ];
    var html = '<div class="pipeline-steps" data-mr-id="' + mr.mrSerialNumber + '">';
    steps.forEach(function (s, i) {
        if (i > 0) html += '<span class="step-arrow">›</span>';
        html += '<span class="step pipeline-step ' + (s.val ? 'step-done' : 'step-todo') + '" '
              + 'data-status="' + s.status + '" title="' + s.title + '">' + s.label + '</span>';
    });
    html += '</div>';
    return html;
}

function chainLinkedBadge(mr) {
    var v = mr.mrLinked || '—';
    var cls = v === 'Linked' ? 'bg-success' : v === 'Not Linked' ? 'bg-danger' : 'bg-secondary';
    return '<span class="badge ' + cls + '">' + v + '</span>';
}

function chainCreatedCell(mr) {
    if (!mr.createdAt) return null;
    return '<span class="text-muted small">' + mr.createdAt + '</span>';
}

function renderChainPanel(data) {
    var chain = data.chain || [];

    chainPanelHead.innerHTML = '<th style="width:130px;">Field</th>' + chain.map(function (mr, i) {
        var isSelected = i === chain.length - 1;
        return '<th><span class="badge ' + chainProductBadgeClass(mr.product) + ' me-1">' + mr.product + '</span> MR'
             + (isSelected ? ' <span class="badge bg-dark ms-1">Selected</span>' : '') + '</th>';
    }).join('');

    if (!chain.length) {
        chainPanelBody.innerHTML = '<tr><td colspan="2" class="text-center text-muted py-3">No MR chain</td></tr>';
        chainPanel.style.display = 'block';
        chainPanel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        return;
    }

    var rows = [
        { label: 'MR',       fn: chainMrLinkCell },
        { label: 'Name',     fn: chainNameCell },
        { label: 'Pipeline', fn: chainPipelineCell },
        { label: 'Linked',   fn: chainLinkedBadge },
        { label: 'Created',  fn: chainCreatedCell }
    ];

    chainPanelBody.innerHTML = rows.map(function (r) {
        var cells = chain.map(function (mr) {
            return '<td class="align-middle">' + (r.fn(mr) || chainNa()) + '</td>';
        }).join('');
        return '<tr><td class="fw-semibold text-nowrap align-middle">' + r.label + '</td>' + cells + '</tr>';
    }).join('');

    // Wire up pipeline step clicks within the chain panel — same endpoint as the main table
    chainPanelBody.querySelectorAll('.pipeline-step').forEach(function (s) {
        s.addEventListener('click', function (e) {
            e.stopPropagation();
            var container = s.closest('.pipeline-steps');
            var mrId      = container.dataset.mrId;
            var status    = s.dataset.status;
            var prevStatus = 'NEW';
            PIPELINE_STAGES.forEach(function (st) {
                var el = container.querySelector('[data-status="' + st + '"]');
                if (el && el.classList.contains('step-done')) prevStatus = st;
            });

            applyPipelineStatus(container, status); // optimistic
            fetch('/mrs/' + mrId + '/status/' + status, { method: 'POST' })
                .then(function (r) { if (!r.ok) throw new Error('Update failed'); return r.json(); })
                .then(function (d) { applyPipelineStatus(container, d.status); })
                .catch(function () { applyPipelineStatus(container, prevStatus); });
        });
    });

    chainPanel.style.display = 'block';
    chainPanel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}
</script>

<%@include file="../layout/footer.jsp" %>
