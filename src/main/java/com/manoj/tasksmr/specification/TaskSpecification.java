package com.manoj.tasksmr.specification;

import com.manoj.tasksmr.dto.TaskFilterDTO;
import com.manoj.tasksmr.model.Task;
import jakarta.persistence.criteria.*;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

/**
 * JPA Specification builder for Task filtering.
 * To add a new filter: add a field to TaskFilterDTO and add a predicate block below.
 */
public class TaskSpecification {

    private TaskSpecification() {}

    public static Specification<Task> withFilters(TaskFilterDTO filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filter 1: by status (exact match) or excludeDone (default active view)
            if (filter.getStatus() != null) {
                predicates.add(cb.equal(root.get("status"), filter.getStatus()));
            } else if (Boolean.TRUE.equals(filter.getExcludeDone())) {
                predicates.add(cb.notEqual(root.get("status"), com.manoj.tasksmr.enums.TaskStatus.DONE));
            }

            // Filter 2: by priority
            if (filter.getPriority() != null) {
                predicates.add(cb.equal(root.get("priority"), filter.getPriority()));
            }

            // Filter 3: MR presence — FK is null/non-null, no string check needed
            if (filter.getMrPresence() != null) {
                switch (filter.getMrPresence()) {
                    case "PAYROLL_ONLY" -> predicates.add(cb.and(
                            cb.isNotNull(root.get("payrollMr")),
                            cb.isNull(root.get("booksMr"))
                    ));
                    case "BOOKS_ONLY" -> predicates.add(cb.and(
                            cb.isNull(root.get("payrollMr")),
                            cb.isNotNull(root.get("booksMr"))
                    ));
                    case "BOTH" -> predicates.add(cb.and(
                            cb.isNotNull(root.get("payrollMr")),
                            cb.isNotNull(root.get("booksMr"))
                    ));
                    case "NONE" -> predicates.add(cb.and(
                            cb.isNull(root.get("payrollMr")),
                            cb.isNull(root.get("booksMr"))
                    ));
                    default -> { /* no filter */ }
                }
            }

            // Filter 4: all associated MRs have DI completed (stepDiCompleted boolean)
            if (filter.getAllDiCompleted() != null) {
                Predicate hasMr = cb.or(
                        cb.isNotNull(root.get("payrollMr")),
                        cb.isNotNull(root.get("booksMr"))
                );
                boolean diDone = Boolean.TRUE.equals(filter.getAllDiCompleted());
                Predicate payrollOk = cb.or(
                        cb.isNull(root.get("payrollMr")),
                        cb.equal(root.get("payrollMr").get("stepDiCompleted"), diDone)
                );
                Predicate booksOk = cb.or(
                        cb.isNull(root.get("booksMr")),
                        cb.equal(root.get("booksMr").get("stepDiCompleted"), diDone)
                );
                predicates.add(cb.and(hasMr, payrollOk, booksOk));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
