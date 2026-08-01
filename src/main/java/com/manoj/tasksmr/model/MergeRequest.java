package com.manoj.tasksmr.model;

import com.manoj.tasksmr.enums.MrLinked;
import com.manoj.tasksmr.enums.Product;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

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

    @Enumerated(EnumType.STRING)
    @Column(name = "mr_linked", nullable = false)
    private MrLinked mrLinked = MrLinked.NOT_LINKED;

    @Column(name = "moved_to_local", nullable = false)
    private Boolean movedToLocal = false;

    @Column(name = "moved_to_pre", nullable = false)
    private Boolean movedToPre = false;

    @Column(name = "moved_to_idc", nullable = false)
    private Boolean movedToIdc = false;

    @Column(name = "can_ignore", nullable = false)
    private Boolean canIgnore = false;

    // ── Independent pipeline checklist steps ─────────────────────────────────
    // Each is toggled independently — no dependency between steps.
    // Separate from mrStatus (which is used for stale tracking / dashboard counts).
    @Column(name = "step_waiting",      nullable = false) private Boolean stepWaiting      = false;
    @Column(name = "step_reviewed",     nullable = false) private Boolean stepReviewed     = false;
    @Column(name = "step_di_scheduled", nullable = false) private Boolean stepDiScheduled  = false;
    @Column(name = "step_di_completed", nullable = false) private Boolean stepDiCompleted  = false;
    @Column(name = "step_gtm",          nullable = false) private Boolean stepGtm          = false;
    @Column(name = "step_rtm",          nullable = false) private Boolean stepRtm          = false;
    @Column(name = "step_merged",       nullable = false) private Boolean stepMerged       = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "last_modified_at")
    private LocalDateTime lastModifiedAt;

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

    private static String extractLastSegment(String url) {
        if (url == null || url.isBlank()) return null;
        String trimmed = url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
        int idx = trimmed.lastIndexOf('/');
        return idx >= 0 ? trimmed.substring(idx + 1) : trimmed;
    }
}
