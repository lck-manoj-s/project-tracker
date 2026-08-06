package com.manoj.tasksmr.model;

import com.manoj.tasksmr.enums.DeploymentStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Audit trail of MergeRequest deployment-stage transitions — mirrors MrStatusHistory,
 * but for deploymentStatus instead of the pipeline status. Unlike the movedTo{Stage}At
 * columns on MergeRequest (which only record the first time a stage is reached), this
 * logs every transition, forward or backward, so the History module can show a full
 * audit trail including demotions and re-visits.
 */
@Entity
@Table(name = "deployment_status_history")
@Getter
@Setter
@NoArgsConstructor
public class DeploymentStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "mr_id", nullable = false)
    private MergeRequest mergeRequest;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status")
    private DeploymentStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false)
    private DeploymentStatus newStatus;

    @CreationTimestamp
    @Column(name = "changed_at", nullable = false, updatable = false)
    private LocalDateTime changedAt;
}
