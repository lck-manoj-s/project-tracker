package com.manoj.tasksmr.model;

import com.manoj.tasksmr.enums.DeploymentStatus;
import com.manoj.tasksmr.enums.MrLinked;
import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.enums.Product;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "merge_requests")
@Getter
@Setter
@NoArgsConstructor
public class MergeRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "mr_serial_number")
    private Long mrSerialNumber;

    @Column(name = "mr", nullable = false)
    private String mr;

    @Column(name = "name")
    private String name;

    /*
     * columnDefinition pins this to a plain VARCHAR. Without it, Hibernate 6 generates a
     * native MySQL ENUM(...) column listing only the constants that existed in the Product
     * enum at the time the column was first created. ddl-auto=update never widens an
     * existing column's allowed values when the Java enum gains a new constant (e.g. SPEND),
     * so MySQL rejects/truncates any row using a value outside that original list. VARCHAR
     * has no such constraint, so future products never need a matching DB migration.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "product", nullable = false, columnDefinition = "VARCHAR(30)")
    private Product product;

    @ManyToOne
    @JoinColumn(name = "parent_mr_id")
    private MergeRequest parentMr;

    /**
     * The task this MR is linked to, if any. A task may have many MRs (any product mix),
     * but each MR belongs to at most one task — so the FK lives here, not on Task.
     */
    @ManyToOne
    @JoinColumn(name = "task_id")
    private Task task;

    @Enumerated(EnumType.STRING)
    @Column(name = "mr_linked", nullable = false)
    private MrLinked mrLinked = MrLinked.NOT_LINKED;

    @Column(name = "can_ignore", nullable = false)
    private Boolean canIgnore = false;

    /**
     * Current deployment stage — a single current-value status (like {@code status}),
     * shown in Local -> Pre -> IDC order wherever the MR is editable. Deployment is
     * treated as a strict, sequential progression (reaching IDC implies Local and Pre
     * were reached too), same modeling as the pipeline stage.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "deployment_status", nullable = false)
    private DeploymentStatus deploymentStatus = DeploymentStatus.NONE;

    /**
     * Current pipeline stage — a single current-value status (like Task.status),
     * tracked over time via MrStatusHistory. Pipeline stages are sequential
     * (see MrStatus for the declared order).
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private MrStatus status = MrStatus.NEW;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // ── Deployment stage timestamps ───────────────────────────────────────────
    // Set once, the first time the MR reaches each deployment stage (via the
    // badge click endpoint or the edit form). Not cleared if the MR is later
    // moved backward, so these always answer "when did this MR first reach
    // stage X" even if its current deploymentStatus has since regressed.
    @Column(name = "moved_to_local_at")
    private LocalDateTime movedToLocalAt;

    @Column(name = "moved_to_pre_at")
    private LocalDateTime movedToPreAt;

    @Column(name = "moved_to_idc_at")
    private LocalDateTime movedToIdcAt;

    /** Returns the last path segment of mr URL (e.g. "152865"). */
    @Transient
    public String getMrNumber() {
        return extractLastSegment(mr);
    }

    /** Returns the MR number of the parent MR, or null if none linked. */
    @Transient
    public String getParentMrNumber() {
        return parentMr != null ? parentMr.getMrNumber() : null;
    }

    // ── Pipeline step view helpers ────────────────────────────────────────────
    // Derived from `status`: a step is "done" once the current status has
    // reached or passed it. These exist so the existing pipeline UI (which
    // renders one badge per stage) keeps working unchanged — it reads these
    // like it used to read independent booleans, but they now all move
    // together as `status` advances (or is set back) as a single value.
    @Transient public boolean isStageReached(MrStatus stage) { return status != null && status.ordinal() >= stage.ordinal(); }
    @Transient public boolean getStepNew()         { return isStageReached(MrStatus.NEW); }
    @Transient public boolean getStepReviewed()    { return isStageReached(MrStatus.REVIEWED); }
    @Transient public boolean getStepDiCompleted() { return isStageReached(MrStatus.DI_COMPLETED); }
    @Transient public boolean getStepGtm()         { return isStageReached(MrStatus.GTM); }
    @Transient public boolean getStepRtm()         { return isStageReached(MrStatus.RTM); }
    @Transient public boolean getStepMerged()      { return isStageReached(MrStatus.MERGED); }

    // ── Deployment step view helpers ──────────────────────────────────────────
    // Derived from `deploymentStatus`, same ordinal-comparison pattern as the
    // pipeline steps above (NONE -> LOCAL -> PRE -> IDC).
    @Transient public boolean isDeployStageReached(DeploymentStatus stage) { return deploymentStatus != null && deploymentStatus.ordinal() >= stage.ordinal(); }
    @Transient public boolean getDeployLocal() { return isDeployStageReached(DeploymentStatus.LOCAL); }
    @Transient public boolean getDeployPre()   { return isDeployStageReached(DeploymentStatus.PRE); }
    @Transient public boolean getDeployIdc()   { return isDeployStageReached(DeploymentStatus.IDC); }

    /** Returns the recorded first-reached timestamp for a deployment stage, or null if not reached yet. */
    @Transient
    public LocalDateTime getDeployStageTimestamp(DeploymentStatus stage) {
        return switch (stage) {
            case LOCAL -> movedToLocalAt;
            case PRE   -> movedToPreAt;
            case IDC   -> movedToIdcAt;
            case NONE  -> null;
        };
    }

    private static String extractLastSegment(String url) {
        if (url == null || url.isBlank()) return null;
        String trimmed = url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
        int idx = trimmed.lastIndexOf('/');
        return idx >= 0 ? trimmed.substring(idx + 1) : trimmed;
    }
}
