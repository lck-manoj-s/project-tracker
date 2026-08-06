package com.manoj.tasksmr.specification;

import com.manoj.tasksmr.dto.TaskFilterDTO;
import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.enums.Product;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import jakarta.persistence.criteria.*;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * JPA Specification builder for Task filtering.
 * To add a new filter: add a field to TaskFilterDTO and add a predicate block below.
 *
 * Note: since a task can now have any number of MRs (any product mix) rather than a
 * fixed payrollMr/booksMr pair, MR-related filters below use correlated subqueries
 * over MergeRequest (owning side of the task_id FK) instead of simple FK-null checks.
 */
public class TaskSpecification {

    private TaskSpecification() {}

    public static Specification<Task> withFilters(TaskFilterDTO filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filter 1: by status (exact match), statusIn (membership — e.g. the Halted/Paused
            // "parked" tab), or excludeDone (default "All Active" view). Exact match always wins;
            // "All Active" also excludes PAUSED and HALTED — neither is actively being worked,
            // so they shouldn't clutter the default list. All three stay reachable via the exact
            // status choice or statusIn (Filter 1's other branches above still return them on demand).
            if (filter.getStatus() != null) {
                predicates.add(cb.equal(root.get("status"), filter.getStatus()));
            } else if (filter.getStatusIn() != null && !filter.getStatusIn().isEmpty()) {
                predicates.add(root.get("status").in(filter.getStatusIn()));
            } else if (Boolean.TRUE.equals(filter.getExcludeDone())) {
                predicates.add(cb.notEqual(root.get("status"), com.manoj.tasksmr.enums.TaskStatus.DONE));
                predicates.add(cb.notEqual(root.get("status"), com.manoj.tasksmr.enums.TaskStatus.PAUSED));
                predicates.add(cb.notEqual(root.get("status"), com.manoj.tasksmr.enums.TaskStatus.HALTED));
            }

            // Filter 2: by priority
            if (filter.getPriority() != null) {
                predicates.add(cb.equal(root.get("priority"), filter.getPriority()));
            }

            // Filter 3: MR presence — based on which products have >=1 MR linked to this task
            if (filter.getMrPresence() != null) {
                Predicate hasPayroll = cb.greaterThan(mrCount(root, query, cb, Product.PAYROLL, null, false), 0L);
                Predicate hasBooks   = cb.greaterThan(mrCount(root, query, cb, Product.BOOKS, null, false), 0L);

                switch (filter.getMrPresence()) {
                    case "PAYROLL_ONLY" -> predicates.add(cb.and(hasPayroll, cb.not(hasBooks)));
                    case "BOOKS_ONLY"   -> predicates.add(cb.and(cb.not(hasPayroll), hasBooks));
                    case "BOTH"         -> predicates.add(cb.and(hasPayroll, hasBooks));
                    case "NONE"         -> predicates.add(cb.and(cb.not(hasPayroll), cb.not(hasBooks)));
                    default -> { /* no filter */ }
                }
            }

            // Filter 4: ALL associated MRs (any product) have reached (or not reached) the
            // DI_COMPLETED pipeline stage, and the task has at least one MR. Since status is
            // a sequential enum rather than a boolean column, "reached DI_COMPLETED" means
            // status IN {stages with ordinal >= DI_COMPLETED}.
            if (filter.getAllDiCompleted() != null) {
                boolean diDone = Boolean.TRUE.equals(filter.getAllDiCompleted());
                List<MrStatus> reached = statusesAtOrAfter(MrStatus.DI_COMPLETED);

                Expression<Long> totalMrs   = mrCount(root, query, cb, null, null, false);
                // "mismatched" = MRs that do NOT satisfy the requested DI-completed state
                Expression<Long> mismatched = mrCount(root, query, cb, null, reached, !diDone);

                predicates.add(cb.and(
                        cb.greaterThan(totalMrs, 0L),
                        cb.equal(mismatched, 0L)
                ));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    /** All MrStatus values whose ordinal is >= the given stage's ordinal (i.e. "reached or past"). */
    private static List<MrStatus> statusesAtOrAfter(MrStatus stage) {
        return Arrays.stream(MrStatus.values()).filter(s -> s.ordinal() >= stage.ordinal()).toList();
    }

    /**
     * Counts MRs linked to the current task row, optionally filtered by product and/or
     * membership in a set of statuses (with {@code negateStatusIn} to invert that check).
     * Pass {@code null} for product/statuses to skip that part of the filter.
     */
    private static Expression<Long> mrCount(
            Root<Task> taskRoot, CriteriaQuery<?> query, CriteriaBuilder cb,
            Product product, List<MrStatus> statuses, boolean negateStatusIn) {

        Subquery<Long> sub = query.subquery(Long.class);
        Root<MergeRequest> mrRoot = sub.from(MergeRequest.class);
        sub.select(cb.count(mrRoot));

        List<Predicate> subPredicates = new ArrayList<>();
        subPredicates.add(cb.equal(mrRoot.get("task"), taskRoot));
        if (product != null) {
            subPredicates.add(cb.equal(mrRoot.get("product"), product));
        }
        if (statuses != null) {
            Predicate statusIn = mrRoot.get("status").in(statuses);
            subPredicates.add(negateStatusIn ? cb.not(statusIn) : statusIn);
        }
        sub.where(cb.and(subPredicates.toArray(new Predicate[0])));

        return sub;
    }
}
