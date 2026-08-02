package com.manoj.tasksmr.model;

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

    @Enumerated(EnumType.STRING)
    @Column(name = "product", nullable = false)
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

    private static String extractLastSegment(String url) {
        if (url == null || url.isBlank()) return null;
        String trimmed = url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
        int idx = trimmed.lastIndexOf('/');
        return idx >= 0 ? trimmed.substring(idx + 1) : trimmed;
    }
}
