package com.manoj.tasksmr.model;

import com.manoj.tasksmr.enums.TaskStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "task_status_history")
@Getter
@Setter
@NoArgsConstructor
public class TaskStatusHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;

    // columnDefinition pins these to VARCHAR — see the comment on Task.status for why
    // (avoids a native MySQL ENUM column that Hibernate never widens for new constants).
    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status", columnDefinition = "VARCHAR(30)")
    private TaskStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false, columnDefinition = "VARCHAR(30)")
    private TaskStatus newStatus;

    @CreationTimestamp
    @Column(name = "changed_at", nullable = false, updatable = false)
    private LocalDateTime changedAt;
}
