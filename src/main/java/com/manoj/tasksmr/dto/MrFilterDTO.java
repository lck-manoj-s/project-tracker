package com.manoj.tasksmr.dto;

import com.manoj.tasksmr.enums.DeploymentStatus;
import com.manoj.tasksmr.enums.MrLinked;
import com.manoj.tasksmr.enums.Product;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO for filtering MergeRequests.
 * Add new filter fields here as the application grows.
 */
@Getter
@Setter
@NoArgsConstructor
public class MrFilterDTO {

    /** Filter by exact product match. Mutually exclusive with excludedProducts in practice. */
    private Product product;

    /**
     * Excludes these products from the results — backs the MR module's "Other MRs" tab,
     * which shows every product except the ones with their own dedicated tab (currently
     * Payroll and Books). A newly added Product automatically falls into this "other"
     * bucket without any code change here.
     */
    private List<Product> excludedProducts;

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
     * When true, show only MRs whose status isn't MERGED. Default "active" view.
     * Mutually exclusive with stepMerged.
     */
    private Boolean excludeMerged;

    /**
     * Exact filter on MR status == MERGED (kept as a boolean flag for the UI's
     * simple "Active / All / Merged" dropdown, even though status is now an enum).
     * null = no filter; true = only status==MERGED; false = only status!=MERGED.
     * Takes precedence over excludeMerged when set.
     */
    private Boolean stepMerged;

    /**
     * Exact filter on deploymentStatus for the UI's "Local / Pre / IDC / Not in IDC" dropdown.
     * null = no exact-stage filter (falls through to excludeDeploymentIdc below).
     * Set to LOCAL, PRE, or IDC to show only MRs currently at that exact stage.
     */
    private DeploymentStatus deploymentStatusEquals;

    /**
     * When true (and deploymentStatusEquals is null), show only MRs whose deploymentStatus
     * != IDC. This is the "Not in IDC" option and the dropdown's default, so MRs already
     * fully deployed drop out of the list the same way merged MRs used to by default.
     */
    private Boolean excludeDeploymentIdc;

    private Boolean canIgnore;
}
