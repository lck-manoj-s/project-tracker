<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@include file="../layout/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-lg-8">
        <div class="card shadow-sm">
            <div class="card-header bg-dark text-white">
                <h5 class="mb-0">
                    <i class="bi bi-${isEdit ? 'pencil-square' : 'plus-circle'} me-2"></i>
                    <c:choose>
                        <c:when test="${isEdit}">Edit MR #${mr.mrSerialNumber}</c:when>
                        <c:otherwise>New Merge Request</c:otherwise>
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
                <form action="/mrs/save" method="post">
                    <c:if test="${isEdit}">
                        <input type="hidden" name="mrSerialNumber" value="${mr.mrSerialNumber}"/>
                    </c:if>

                    <%-- ── MR details ─────────────────────────────────────── --%>
                    <div class="row g-3 mb-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">MR URL <span class="text-danger">*</span></label>
                            <input type="url" name="mr" class="form-control" value="${mr.mr}" placeholder="https://..." required/>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Name</label>
                            <input type="text" name="name" class="form-control" value="${mr.name}" placeholder="Short description (optional)"/>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label fw-semibold">Product <span class="text-danger">*</span></label>
                            <select name="product" class="form-select" required>
                                <option value="">Select...</option>
                                <c:forEach var="p" items="${products}">
                                    <option value="${p}" ${mr.product == p ? 'selected' : ''}>${p.displayName}</option>
                                </c:forEach>
                            </select>
                        </div>
                    </div>
                    <div class="mb-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" name="canIgnore" id="canIgnore" value="true" ${mr.canIgnore ? 'checked' : ''}/>
                            <label class="form-check-label fw-semibold" for="canIgnore">Can Ignore</label>
                        </div>
                    </div>

                    <%-- ── Parent MR (typeahead) ──────────────────────────── --%>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Parent MR</label>
                        <div class="position-relative">
                            <div class="input-group">
                                <input type="text" id="parentMrText" class="form-control"
                                       placeholder="Type MR number…" autocomplete="off"
                                       value="${mr.parentMr != null ? mr.parentMr.mrNumber : ''}"/>
                                <button type="button" class="btn btn-outline-secondary" id="parentMrClear" title="Clear">
                                    <i class="bi bi-x-lg"></i>
                                </button>
                            </div>
                            <input type="hidden" name="parentMrId" id="parentMrId"
                                   value="${mr.parentMr != null ? mr.parentMr.mrSerialNumber : ''}"/>
                            <ul id="parentMrList" class="list-group position-absolute w-100 shadow"
                                style="z-index:1050;max-height:200px;overflow-y:auto;display:none;top:100%;left:0;"></ul>
                        </div>
                        <div class="form-text">Type to search for a parent MR.</div>
                    </div>

                    <hr class="my-4"/>

                    <%-- ── Group 1: Linked ────────────────────────────────── --%>
                    <p class="fw-semibold mb-2 text-uppercase" style="font-size:.8rem;letter-spacing:.05em;color:#6c757d;">
                        <i class="bi bi-link-45deg me-1"></i>Linked
                    </p>
                    <div class="mb-3" style="max-width:220px;">
                        <select name="mrLinked" class="form-select">
                            <c:forEach var="ml" items="${mrLinkedValues}">
                                <option value="${ml}" ${mr.mrLinked == ml ? 'selected' : ''}>${ml.displayName}</option>
                            </c:forEach>
                        </select>
                    </div>

                    <%-- ── Group 3: Deployment ────────────────────────────── --%>
                    <p class="fw-semibold mb-2 text-uppercase" style="font-size:.8rem;letter-spacing:.05em;color:#6c757d;">
                        <i class="bi bi-cloud-upload me-1"></i>Deployment
                    </p>
                    <div class="row g-3 mb-4">
                        <div class="col-6 col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" name="movedToLocal" id="movedToLocal" value="true" ${mr.movedToLocal ? 'checked' : ''}/>
                                <label class="form-check-label" for="movedToLocal">Moved to Local</label>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" name="movedToPre" id="movedToPre" value="true" ${mr.movedToPre ? 'checked' : ''}/>
                                <label class="form-check-label" for="movedToPre">Moved to Pre</label>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" name="movedToIdc" id="movedToIdc" value="true" ${mr.movedToIdc ? 'checked' : ''}/>
                                <label class="form-check-label" for="movedToIdc">Moved to IDC</label>
                            </div>
                        </div>
                    </div>

                    <div class="d-flex gap-2 justify-content-end">
                        <a href="/mrs" class="btn btn-outline-secondary">Cancel</a>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check2 me-1"></i>
                            <c:choose>
                                <c:when test="${isEdit}">Update MR</c:when>
                                <c:otherwise>Create MR</c:otherwise>
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
