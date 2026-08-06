package com.manoj.tasksmr.specification;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.enums.DeploymentStatus;
import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.model.MergeRequest;
import jakarta.persistence.criteria.*;
import jakarta.persistence.criteria.JoinType;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

/**
 * JPA Specification builder for MergeRequest filtering.
 * To add a new filter: add a field to MrFilterDTO and add a predicate block below.
 */
public class MrSpecification {

    private MrSpecification() {}

    public static Specification<MergeRequest> withFilters(MrFilterDTO filter) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Filter 1: by exact product
            if (filter.getProduct() != null) {
                predicates.add(cb.equal(root.get("product"), filter.getProduct()));
            }

            // Filter 1b: exclude specific products — backs the "Other MRs" tab (every
            // product except the ones with their own dedicated tab).
            if (filter.getExcludedProducts() != null && !filter.getExcludedProducts().isEmpty()) {
                predicates.add(cb.not(root.get("product").in(filter.getExcludedProducts())));
            }

            // Filter 2: has parent MR or not (FK null check)
            if (filter.getHasParentMr() != null) {
                if (Boolean.TRUE.equals(filter.getHasParentMr())) {
                    predicates.add(cb.isNotNull(root.get("parentMr")));
                } else {
                    predicates.add(cb.isNull(root.get("parentMr")));
                }
            }

            // Filter 3: by parent MR product — LEFT JOIN so MRs without parent are not excluded
            if (filter.getParentMrProduct() != null) {
                Join<MergeRequest, MergeRequest> parentJoin = root.join("parentMr", JoinType.LEFT);
                predicates.add(cb.equal(parentJoin.get("product"), filter.getParentMrProduct()));
            }

            // Filter 4: by mrLinked
            if (filter.getMrLinked() != null) {
                predicates.add(cb.equal(root.get("mrLinked"), filter.getMrLinked()));
            }

            // Filter 5: merged state — status == MERGED (or != MERGED) rather than a boolean column
            if (filter.getStepMerged() != null) {
                if (Boolean.TRUE.equals(filter.getStepMerged())) {
                    predicates.add(cb.equal(root.get("status"), MrStatus.MERGED));
                } else {
                    predicates.add(cb.notEqual(root.get("status"), MrStatus.MERGED));
                }
            } else if (Boolean.TRUE.equals(filter.getExcludeMerged())) {
                predicates.add(cb.notEqual(root.get("status"), MrStatus.MERGED));
            }

            // Filter 6: deployment stage — exact match (Local/Pre/IDC) or "not in IDC" (default)
            if (filter.getDeploymentStatusEquals() != null) {
                predicates.add(cb.equal(root.get("deploymentStatus"), filter.getDeploymentStatusEquals()));
            } else if (Boolean.TRUE.equals(filter.getExcludeDeploymentIdc())) {
                predicates.add(cb.notEqual(root.get("deploymentStatus"), DeploymentStatus.IDC));
            }

            if (filter.getCanIgnore() != null) {
                predicates.add(cb.equal(root.get("canIgnore"), filter.getCanIgnore()));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
