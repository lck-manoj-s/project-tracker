package com.manoj.tasksmr.model;

import com.manoj.tasksmr.enums.MrStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Audit trail of MergeRequest status transitions — mirrors TaskStatusHistory.
 * Lets the dashboard compute how much time an MR spent in each pipeline stage.
 */
@Entity
@Table(name = "mr_status_history")
@Getter
@Setter
@NoArgsConstructor
public class MrStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "mr_id", nullable = false)
    private MergeRequest mergeRequest;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status")
    private MrStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false)
    private MrStatus newStatus;

    @CreationTimestamp
    @Column(name = "changed_at", nullable = false, updatable = false)
    private LocalDateTime changedAt;
}
