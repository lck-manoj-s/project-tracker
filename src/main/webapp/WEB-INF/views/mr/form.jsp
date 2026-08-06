<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>


<%-- Form-page CSS lives in /css/forms.css (not inline) — see that file's
     "MR form" section for these rules. --%>
<link rel="stylesheet" href="/css/forms.css">

<div class="mr-form-container">

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
                        Edit MR #${mr.mrSerialNumber}
                    </c:when>
                    <c:otherwise>
                        New Merge Request
                    </c:otherwise>
                </c:choose>
            </h5>

            <div class="d-flex gap-2">
                <a href="/mrs" class="btn btn-sm btn-outline-light">
                    <i class="bi bi-x-lg me-1"></i>Cancel
                </a>

                <button type="submit" form="mrForm"
                        class="btn btn-sm btn-primary">
                    <i class="bi bi-check2 me-1"></i>
                    <c:choose>
                        <c:when test="${isEdit}">Update MR</c:when>
                        <c:otherwise>Create MR</c:otherwise>
                    </c:choose>
                </button>
            </div>
        </div>

        <div class="card-body">

            <form id="mrForm" action="/mrs/save" method="post">

                <c:if test="${isEdit}">
                    <input type="hidden" name="mrSerialNumber"
                           value="${mr.mrSerialNumber}"/>
                </c:if>

                <%-- Basic Information --%>
                <div class="mr-section-title">
                    <i class="bi bi-info-circle me-1"></i>
                    Basic Information
                </div>

                <div class="row g-3">

                    <div class="col-md-6">
                        <label class="form-label fw-semibold">
                            MR URL <span class="text-danger">*</span>
                        </label>
                        <input type="url" name="mr"
                               class="form-control"
                               value="${mr.mr}"
                               placeholder="https://..."
                               required/>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Name</label>
                        <input type="text" name="name"
                               class="form-control"
                               value="${mr.name}"
                               placeholder="Short description (optional)"/>
                    </div>

                    <div class="col-md-2">
                        <label class="form-label fw-semibold">
                            Product <span class="text-danger">*</span>
                        </label>
                        <select name="product" class="form-select" required>
                            <option value="">Select...</option>
                            <c:forEach var="p" items="${products}">
                                <option value="${p}"
                                    ${mr.product == p ? 'selected' : ''}>
                                        ${p.displayName}
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                </div>

                <hr class="mr-section-divider"/>

                <%-- Deployment --%>
                <div class="mr-section-title">
                    <i class="bi bi-cloud-arrow-up me-1"></i>
                    Deployment
                </div>

                <div class="row g-3 align-items-end">

                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            Deployment Status
                        </label>

                        <select name="deploymentStatus" class="form-select">
                            <c:forEach var="ds" items="${deploymentStatusValues}">
                                <option value="${ds}"
                                    ${mr.deploymentStatus == ds ? 'selected' : ''}>
                                        ${ds.displayName}
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <c:if test="${isEdit && (not empty mr.movedToLocalAt || not empty mr.movedToPreAt || not empty mr.movedToIdcAt)}">

                        <div class="col-md-8">
                            <label class="form-label fw-semibold">
                                Deployment History
                            </label>

                            <div class="mr-deployment-history">

                                <c:if test="${not empty mr.movedToLocalAt}">
                                    <div class="mr-deployment-history-item">
                                        <strong>Local:</strong>
                                            ${fn:replace(fn:substring(mr.movedToLocalAt.toString(), 0, 16), 'T', ' ')}
                                    </div>
                                </c:if>

                                <c:if test="${not empty mr.movedToPreAt}">
                                    <div class="mr-deployment-history-item">
                                        <strong>Pre:</strong>
                                            ${fn:replace(fn:substring(mr.movedToPreAt.toString(), 0, 16), 'T', ' ')}
                                    </div>
                                </c:if>

                                <c:if test="${not empty mr.movedToIdcAt}">
                                    <div class="mr-deployment-history-item">
                                        <strong>IDC:</strong>
                                            ${fn:replace(fn:substring(mr.movedToIdcAt.toString(), 0, 16), 'T', ' ')}
                                    </div>
                                </c:if>

                            </div>
                        </div>

                    </c:if>

                </div>

                <hr class="mr-section-divider"/>

                <%-- Workflow --%>
                <div class="mr-section-title">
                    <i class="bi bi-diagram-3 me-1"></i>
                    Workflow
                </div>

                <div class="row g-3 align-items-end">

                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            Pipeline Status
                        </label>

                        <select name="status" class="form-select">
                            <c:forEach var="s" items="${mrStatusValues}">
                                <option value="${s}"
                                    ${mr.status == s ? 'selected' : ''}>
                                        ${s.displayName}
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Linked</label>

                        <select name="mrLinked" class="form-select">
                            <c:forEach var="ml" items="${mrLinkedValues}">
                                <option value="${ml}"
                                    ${mr.mrLinked == ml ? 'selected' : ''}>
                                        ${ml.displayName}
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="col-md-4">
                        <div class="mr-ignore-wrapper">
                            <div class="form-check form-switch">
                                <input class="form-check-input"
                                       type="checkbox"
                                       name="canIgnore"
                                       id="canIgnore"
                                       value="true"
                                ${mr.canIgnore ? 'checked' : ''}/>

                                <label class="form-check-label fw-semibold"
                                       for="canIgnore">
                                    Can Ignore
                                </label>
                            </div>
                        </div>
                    </div>

                </div>

                <hr class="mr-section-divider"/>

                <%-- Parent MR --%>
                <div class="mr-section-title">
                    <i class="bi bi-git me-1"></i>
                    Parent MR
                </div>

                <div class="mr-parent-wrapper">

                    <div class="input-group">

                        <input type="text"
                               id="parentMrText"
                               class="form-control"
                               placeholder="Type MR number..."
                               autocomplete="off"
                               value="${mr.parentMr != null ? mr.parentMr.mrNumber : ''}"/>

                        <button type="button"
                                class="btn btn-outline-secondary"
                                id="parentMrClear"
                                title="Clear">
                            <i class="bi bi-x-lg"></i>
                        </button>

                    </div>

                    <input type="hidden"
                           name="parentMrId"
                           id="parentMrId"
                           value="${mr.parentMr != null ? mr.parentMr.mrSerialNumber : ''}"/>

                    <ul id="parentMrList"
                        class="list-group position-absolute w-100 shadow">
                    </ul>

                </div>

                <div class="form-text mt-1">
                    Type to search for a parent MR.
                </div>

            </form>
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
        var base = mr.number + (mr.name ? ' — ' + mr.name : '');
        return mr.product ? base + ' (' + mr.product + ')' : base;
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

var parentMrData = [
    <c:forEach var="pmr" items="${allMrs}" varStatus="s">
        <c:if test="${not isEdit or pmr.mrSerialNumber != mr.mrSerialNumber}">
            {id: ${pmr.mrSerialNumber}, number: '${pmr.mrNumber}', name: '${fn:replace(pmr.name, "'", "\\'")}', product: '${pmr.product.displayName}'}${!s.last ? ',' : ''}
        </c:if>
    </c:forEach>
];
initMrTypeahead('parentMrText', 'parentMrId', 'parentMrList', 'parentMrClear', parentMrData);
</script>

<%@include file="../layout/footer.jsp" %>
