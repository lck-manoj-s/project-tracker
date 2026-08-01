package com.manoj.tasksmr.dto;

import com.manoj.tasksmr.enums.MrLinked;
import com.manoj.tasksmr.enums.Product;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

/**
 * DTO for filtering MergeRequests.
 * Add new filter fields here as the application grows.
 */
@Getter
@Setter
@NoArgsConstructor
public class MrFilterDTO {

    /** Filter by product */
    private Product product;

    /**
     * Filter by parent MR presence:
     *  true  = has parent MR
     *  false = has no parent MR
     *  null  = no filter
     */
    private Boolean hasParentMr;

    /** Filter by parent MR product */
    private Product parentMrProduct;

    /** Filter by mrLinked status */
    private MrLinked mrLinked;

    /**
     * When true, show only non-merged MRs (stepMerged = false). Default "active" view.
     * Mutually exclusive with stepMerged.
     */
    private Boolean excludeMerged;

    /**
     * Exact filter on the stepMerged boolean.
     * null = no filter; true = only merged; false = only non-merged.
     * Takes precedence over excludeMerged when set.
     */
    private Boolean stepMerged;

    /** Deployment boolean filters */
    private Boolean movedToLocal;
    private Boolean movedToPre;
    private Boolean movedToIdc;
    private Boolean canIgnore;
}
