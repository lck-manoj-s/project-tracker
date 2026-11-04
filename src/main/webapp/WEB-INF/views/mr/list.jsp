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

<link rel="stylesheet" href="/css/lists.css">

<h4 class="mb-3"><i class="bi bi-git me-2"></i>Merge Requests</h4>

<%-- ── Product tabs + Add MR (Add MR sits on the right of the tabs row) ─── --%>
<div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
<div class="segmented" role="tablist">
    <%-- Scoped to Spend specifically for now (see MrController.OTHER_TAB_PRODUCT) —
         rename/rework this if it becomes a catch-all again. --%>
    <a class="segmented-item ${activeTab == 'payroll' ? 'active' : ''}" href="/mrs/payroll" role="tab" aria-selected="${activeTab == 'payroll'}">
        Payroll MRs
    </a>
    <a class="segmented-item ${activeTab == 'books' ? 'active' : ''}" href="/mrs/books" role="tab" aria-selected="${activeTab == 'books'}">
        Books MRs
    </a>
    <a class="segmented-item ${activeTab == 'other' ? 'active' : ''}" href="/mrs/other" role="tab" aria-selected="${activeTab == 'other'}">
        Spend MRs
    </a>
</div>
    <a href="/mrs/new" class="btn btn-primary btn-sm add-btn">
        <i class="bi bi-plus-lg me-1"></i>Add MR
    </a>
</div>

<%-- ── Filter ───────────────────────────────────────────────────────── --%>
<div class="filter-card list-filter p-3 mb-3">
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
                <option value="false" ${merged == 'false' ? 'selected' : ''}>Active Only</option>
                <option value="all"   ${merged == 'all' || empty merged ? 'selected' : ''}>All</option>
                <option value="true"  ${merged == 'true'  ? 'selected' : ''}>Merged Only</option>
            </select>
        </div>
        <div class="col-auto">
            <label class="filter-label d-block">Deployment</label>
            <select name="deployment" class="form-select form-select-sm">
                <option value="local"  ${deployment == 'local'  ? 'selected' : ''}>Local</option>
                <option value="pre"    ${deployment == 'pre'    ? 'selected' : ''}>Pre</option>
                <option value="idc"    ${deployment == 'idc'    ? 'selected' : ''}>IDC</option>
                <option value="notIdc" ${deployment == 'notIdc' || empty deployment ? 'selected' : ''}>Not in IDC</option>
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
            <table class="table table-hover table-bordered table-sm mb-0" id="mrsTable">
                <thead>
                    <tr>
                        <th>#</th>
                        <c:if test="${showProductBadge}"><th>Product</th></c:if>
                        <th>MR</th>
                        <th>Name</th>
                        <th>Pipeline</th>
                        <th>Linked</th>
                        <th>Deployment</th>
                        <c:if test="${canIgnore != 'false'}"><th>Can Ignore</th></c:if>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <c:choose>
                        <c:when test="${empty mrs}">
                            <tr><td colspan="${8 + (canIgnore != 'false' ? 1 : 0) + (showProductBadge ? 1 : 0)}" class="text-center text-muted py-3">
                                <i class="bi bi-inbox me-1"></i>No MRs found
                            </td></tr>
                        </c:when>
                        <c:otherwise>
                            <c:forEach var="mr" items="${mrs}">
                                <tr data-mr-id="${mr.mrSerialNumber}">
                                    <td class="text-muted small align-middle">${mr.mrSerialNumber}</td>
                                    <c:if test="${showProductBadge}">
                                        <td class="align-middle">
                                            <c:choose>
                                                <c:when test="${mr.product.name() == 'PAYROLL'}"><c:set var="prodPill" value="pill-green"/></c:when>
                                                <c:when test="${mr.product.name() == 'BOOKS'}"><c:set var="prodPill" value="pill-purple"/></c:when>
                                                <c:when test="${mr.product.name() == 'SPEND'}"><c:set var="prodPill" value="pill-pink"/></c:when>
                                                <c:otherwise><c:set var="prodPill" value="pill-gray"/></c:otherwise>
                                            </c:choose>
                                            <span class="pill ${prodPill}">${mr.product.displayName}</span>
                                        </td>
                                    </c:if>
                                    <td class="align-middle">
                                        <c:choose>
                                            <c:when test="${mr.product.name() == 'PAYROLL'}"><c:set var="mrPill" value="pill-green"/></c:when>
                                            <c:when test="${mr.product.name() == 'BOOKS'}"><c:set var="mrPill" value="pill-purple"/></c:when>
                                            <c:when test="${mr.product.name() == 'SPEND'}"><c:set var="mrPill" value="pill-pink"/></c:when>
                                            <c:otherwise><c:set var="mrPill" value="pill-gray"/></c:otherwise>
                                        </c:choose>
                                        <a href="${mr.mr}" target="_blank" class="pill ${mrPill} text-decoration-none">${mr.mrNumber}</a>
                                        <c:if test="${mr.parentMr != null}">
                                            <button type="button" class="pill pill-gray border-0 mr-chain-btn" data-mr-id="${mr.mrSerialNumber}" data-kind="chain"
                                                    title="View MR chain (Parent: ${mr.parentMrNumber} · ${mr.parentMr.product.displayName})">
                                                <i class="bi bi-link-45deg"></i>
                                            </button>
                                        </c:if>
                                        <c:if test="${parentIdsWithChildren.contains(mr.mrSerialNumber)}">
                                            <button type="button" class="pill pill-gray border-0 mr-chain-btn" data-mr-id="${mr.mrSerialNumber}" data-kind="children"
                                                    title="View child MRs">
                                                <i class="bi bi-diagram-3"></i>
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
                                        <span class="pill ${mr.mrLinked.name() == 'LINKED' ? 'pill-green' : mr.mrLinked.name() == 'NOT_LINKED' ? 'pill-red' : 'pill-gray'}">
                                            ${mr.mrLinked.displayName}
                                        </span>
                                    </td>
                                    <td class="align-middle">
                                        <c:set var="localTitle" value="Local" />
                                        <c:if test="${not empty mr.movedToLocalAt}">
                                            <c:set var="localTitle" value="Local — ${fn:replace(fn:substring(mr.movedToLocalAt.toString(), 0, 16), 'T', ' ')}" />
                                        </c:if>
                                        <c:set var="preTitle" value="Pre" />
                                        <c:if test="${not empty mr.movedToPreAt}">
                                            <c:set var="preTitle" value="Pre — ${fn:replace(fn:substring(mr.movedToPreAt.toString(), 0, 16), 'T', ' ')}" />
                                        </c:if>
                                        <c:set var="idcTitle" value="IDC" />
                                        <c:if test="${not empty mr.movedToIdcAt}">
                                            <c:set var="idcTitle" value="IDC — ${fn:replace(fn:substring(mr.movedToIdcAt.toString(), 0, 16), 'T', ' ')}" />
                                        </c:if>
                                        <div class="pipeline-steps" title="${mr.deploymentStatus.displayName}">
                                            <span class="step deploy-step ${mr.deployLocal ? 'step-done' : 'step-todo'}" data-status="LOCAL" title="${localTitle}">Local</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step deploy-step ${mr.deployPre   ? 'step-done' : 'step-todo'}" data-status="PRE"   title="${preTitle}">Pre</span>
                                            <span class="step-arrow">›</span>
                                            <span class="step deploy-step ${mr.deployIdc   ? 'step-done' : 'step-todo'}" data-status="IDC"   title="${idcTitle}">IDC</span>
                                        </div>
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
    <div class="card-footer list-footer d-flex justify-content-between align-items-center">
        <span class="text-muted small">
            Showing ${mrs.size()} of ${totalElements} MR(s)
            &nbsp;|&nbsp; Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}
        </span>
        <c:if test="${totalPages > 1}">
            <div class="d-flex gap-2">
                <c:choose>
                    <c:when test="${currentPage == 0}">
                        <span class="btn-pager is-disabled"><i class="bi bi-chevron-left"></i>Previous</span>
                    </c:when>
                    <c:otherwise>
                        <c:url var="prevUrl" value="${baseUrl}">
                            <c:if test="${not empty hasParentMr}">    <c:param name="hasParentMr"     value="${hasParentMr}"/></c:if>
                            <c:if test="${not empty parentMrProduct}"><c:param name="parentMrProduct" value="${parentMrProduct}"/></c:if>
                            <c:if test="${not empty mrLinked}">       <c:param name="mrLinked"        value="${mrLinked}"/></c:if>
                            <c:if test="${merged != 'all'}">          <c:param name="merged"           value="${merged}"/></c:if>
                            <c:if test="${deployment != 'notIdc'}">   <c:param name="deployment"      value="${deployment}"/></c:if>
                            <c:if test="${canIgnore != 'false'}">     <c:param name="canIgnore"       value="${canIgnore}"/></c:if>
                            <c:param name="page" value="${currentPage - 1}"/>
                        </c:url>
                        <a class="btn-pager" href="${prevUrl}"><i class="bi bi-chevron-left"></i>Previous</a>
                    </c:otherwise>
                </c:choose>

                <c:choose>
                    <c:when test="${currentPage + 1 >= totalPages}">
                        <span class="btn-pager is-disabled">Next<i class="bi bi-chevron-right"></i></span>
                    </c:when>
                    <c:otherwise>
                        <c:url var="nextUrl" value="${baseUrl}">
                            <c:if test="${not empty hasParentMr}">    <c:param name="hasParentMr"     value="${hasParentMr}"/></c:if>
                            <c:if test="${not empty parentMrProduct}"><c:param name="parentMrProduct" value="${parentMrProduct}"/></c:if>
                            <c:if test="${not empty mrLinked}">       <c:param name="mrLinked"        value="${mrLinked}"/></c:if>
                            <c:if test="${merged != 'all'}">          <c:param name="merged"           value="${merged}"/></c:if>
                            <c:if test="${deployment != 'notIdc'}">   <c:param name="deployment"      value="${deployment}"/></c:if>
                            <c:if test="${canIgnore != 'false'}">     <c:param name="canIgnore"       value="${canIgnore}"/></c:if>
                            <c:param name="page" value="${currentPage + 1}"/>
                        </c:url>
                        <a class="btn-pager" href="${nextUrl}">Next<i class="bi bi-chevron-right"></i></a>
                    </c:otherwise>
                </c:choose>
            </div>
        </c:if>
    </div>
</div>

<%-- ── MR Chain Panel (hidden until a parent-chain button is clicked) ─── --%>
<div id="mrChainPanel" style="display:none;" class="card shadow-sm my-4 overflow-hidden">
    <div class="card-header panel-head d-flex justify-content-between align-items-center py-2">
        <span><i class="bi bi-diagram-2 me-2"></i><span id="chainPanelTitle">MR Chain</span></span>
        <button type="button" class="btn-close btn-sm" onclick="hideChainPanel()"></button>
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

// Deployment stage order — used to redraw an entire row's deployment badges from a single status value
var DEPLOY_STAGES = ['NONE', 'LOCAL', 'PRE', 'IDC'];

function applyDeploymentStatus(container, status) {
    var idx = DEPLOY_STAGES.indexOf(status);
    container.querySelectorAll('.deploy-step').forEach(function (s) {
        var done = DEPLOY_STAGES.indexOf(s.dataset.status) <= idx;
        s.classList.toggle('step-done', done);
        s.classList.toggle('step-todo', !done);
    });
    container.title = status;
}

// Deployment step click — jumps the MR directly to the clicked stage (forward or backward)
document.querySelectorAll('.deploy-step').forEach(function (step) {
    step.addEventListener('click', function (e) {
        e.stopPropagation();
        var row       = step.closest('tr');
        var mrId      = row.dataset.mrId;
        var container = step.closest('.pipeline-steps');
        var status    = step.dataset.status;
        var prevStatus = 'NONE';
        DEPLOY_STAGES.forEach(function (s) {
            var el = container.querySelector('.deploy-step[data-status="' + s + '"]');
            if (el && el.classList.contains('step-done')) prevStatus = s;
        });

        applyDeploymentStatus(container, status); // optimistic
        fetch('/mrs/' + mrId + '/deployment/' + status, { method: 'POST' })
            .then(function (r) { if (!r.ok) throw new Error('Update failed'); return r.json(); })
            .then(function (d) { applyDeploymentStatus(container, d.status); })
            .catch(function () { applyDeploymentStatus(container, prevStatus); });
    });
});

// canIgnore boolean toggle — exclude pipeline-step and deploy-step elements
document.querySelectorAll('.step:not(.pipeline-step):not(.deploy-step)[data-field]').forEach(function(step) {
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

function showChainLoading() {
    chainPanelHead.innerHTML = '<th style="width:130px;">Field</th>';
    chainPanelBody.innerHTML = '<tr><td colspan="2" class="text-center text-muted py-4">'
        + '<span class="spinner-border spinner-border-sm text-primary me-2" role="status"></span>Loading MR chain…</td></tr>';
    chainPanel.style.display = 'block';
    chainPanel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// data-kind="chain"    → this MR's ancestors (its parent, grandparent, ...)
// data-kind="children" → this MR's direct children (MRs whose parent is this one)
document.querySelectorAll('.mr-chain-btn').forEach(function (btn) {
    btn.addEventListener('click', function (e) {
        e.stopPropagation();
        var mrId = this.dataset.mrId;
        var kind = this.dataset.kind === 'children' ? 'children' : 'chain';
        showChainLoading();
        fetch('/mrs/' + mrId + (kind === 'children' ? '/children' : '/chain'))
            .then(function (r) { return r.json(); })
            .then(function (data) { renderChainPanel(data, kind); })
            .catch(function () {
                chainPanelBody.innerHTML = '<tr><td colspan="2" class="text-center text-danger py-4">Could not load MR chain.</td></tr>';
                showToast('Could not load MR chain.', 'danger');
            });
    });
});

document.addEventListener('click', function (e) {
    if (!e.target.closest('#mrChainPanel') && !e.target.closest('.mr-chain-btn')) {
        hideChainPanel();
    }
});

window.hideChainPanel = function () { chainPanel.style.display = 'none'; };

function chainNa() { return '<span class="text-muted">—</span>'; }

// Product pill colors — same mapping as the table and the Tasks page. Unknown products fall back to gray.
var PRODUCT_PILL = { Payroll: 'pill-green', Books: 'pill-purple', Spend: 'pill-pink' };

function chainMrLinkCell(mr) {
    return '<a href="' + mr.mr + '" target="_blank" class="pill pill-gray text-decoration-none me-1">' + mr.mrNumber + '</a>'
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

function chainDeploymentCell(mr) {
    var steps = [
        { status: 'LOCAL', label: 'Local', val: mr.deployLocal, at: mr.movedToLocalAt },
        { status: 'PRE',   label: 'Pre',   val: mr.deployPre,   at: mr.movedToPreAt },
        { status: 'IDC',   label: 'IDC',   val: mr.deployIdc,   at: mr.movedToIdcAt }
    ];
    var html = '<div class="pipeline-steps" data-mr-id="' + mr.mrSerialNumber + '">';
    steps.forEach(function (s, i) {
        if (i > 0) html += '<span class="step-arrow">›</span>';
        var title = s.label + (s.at ? ' — ' + s.at : '');
        html += '<span class="step deploy-step ' + (s.val ? 'step-done' : 'step-todo') + '" '
              + 'data-status="' + s.status + '" title="' + title + '">' + s.label + '</span>';
    });
    html += '</div>';
    return html;
}

function chainLinkedBadge(mr) {
    var v = mr.mrLinked || '—';
    var cls = v === 'Linked' ? 'pill-green' : v === 'Not Linked' ? 'pill-red' : 'pill-gray';
    return '<span class="pill ' + cls + '">' + v + '</span>';
}

function chainCreatedCell(mr) {
    if (!mr.createdAt) return null;
    return '<span class="text-muted small">' + mr.createdAt + '</span>';
}

function renderChainPanel(data, kind) {
    var chain = data.chain || [];
    document.getElementById('chainPanelTitle').textContent = kind === 'children' ? 'Child MRs' : 'MR Chain';

    chainPanelHead.innerHTML = '<th style="width:130px;">Field</th>' + chain.map(function (mr) {
        var isSelected = mr.mrSerialNumber === data.selectedId;
        return '<th><span class="pill ' + (PRODUCT_PILL[mr.product] || 'pill-gray') + ' me-1">' + mr.product + '</span> MR'
             + (isSelected ? ' <span class="pill pill-gray ms-1">Selected</span>' : '') + '</th>';
    }).join('');

    if (!chain.length) {
        chainPanelBody.innerHTML = '<tr><td colspan="2" class="text-center text-muted py-3">No MR chain</td></tr>';
        chainPanel.style.display = 'block';
        chainPanel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        return;
    }

    var rows = [
        { label: 'MR',         fn: chainMrLinkCell },
        { label: 'Name',       fn: chainNameCell },
        { label: 'Pipeline',   fn: chainPipelineCell },
        { label: 'Linked',     fn: chainLinkedBadge },
        { label: 'Deployment', fn: chainDeploymentCell },
        { label: 'Created',    fn: chainCreatedCell }
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

    // Wire up deployment stage clicks within the chain panel — same endpoint as the main table
    chainPanelBody.querySelectorAll('.deploy-step').forEach(function (s) {
        s.addEventListener('click', function (e) {
            e.stopPropagation();
            var container = s.closest('.pipeline-steps');
            var mrId      = container.dataset.mrId;
            var status    = s.dataset.status;
            var prevStatus = 'NONE';
            DEPLOY_STAGES.forEach(function (st) {
                var el = container.querySelector('.deploy-step[data-status="' + st + '"]');
                if (el && el.classList.contains('step-done')) prevStatus = st;
            });

            applyDeploymentStatus(container, status); // optimistic
            fetch('/mrs/' + mrId + '/deployment/' + status, { method: 'POST' })
                .then(function (r) { if (!r.ok) throw new Error('Update failed'); return r.json(); })
                .then(function (d) { applyDeploymentStatus(container, d.status); })
                .catch(function () { applyDeploymentStatus(container, prevStatus); });
        });
    });

    chainPanel.style.display = 'block';
    chainPanel.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}
</script>

<%@include file="../layout/footer.jsp" %>
