<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@include file="layout/header.jsp" %>

<div class="row justify-content-center mt-5">
    <div class="col-md-6 text-center">
        <div class="card shadow-sm border-0">
            <div class="card-body py-5">
                <div style="font-size: 5rem; line-height: 1;" class="mb-3 text-secondary">
                    <c:choose>
                        <c:when test="${status == 404}">&#128269;</c:when>
                        <c:when test="${status == 403}">&#128274;</c:when>
                        <c:otherwise>&#9888;</c:otherwise>
                    </c:choose>
                </div>
                <h1 class="display-4 fw-bold text-danger mb-1">${status}</h1>
                <h4 class="mb-3">${errorTitle}</h4>
                <p class="text-muted mb-4">${errorDetail}</p>
                <a href="/tasks" class="btn btn-primary">
                    <i class="bi bi-house-door me-1"></i>Back to Tasks
                </a>
            </div>
        </div>
    </div>
</div>

<%@include file="layout/footer.jsp" %>
