package com.manoj.tasksmr.model;

import com.manoj.tasksmr.enums.Priority;
import com.manoj.tasksmr.enums.Product;
import com.manoj.tasksmr.enums.TaskStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "tasks")
@Getter
@Setter
@NoArgsConstructor
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "task_id")
    private Long taskId;

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    /**
     * MRs linked to this task — any number, irrespective of product.
     * Owning side is MergeRequest.task (task_id FK on merge_requests).
     * EAGER so JSPs/controllers can read it outside an explicit transaction
     * (consistent with this app's simple, non-lazy style elsewhere).
     */
    @OneToMany(mappedBy = "task", fetch = FetchType.EAGER)
    private List<MergeRequest> mergeRequests;

    /** Convenience: linked MRs for a given product (e.g. for legacy-style payroll/books display). */
    @Transient
    public List<MergeRequest> getMrsByProduct(Product product) {
        return mergeRequests == null ? List.of()
                : mergeRequests.stream().filter(mr -> mr.getProduct() == product).toList();
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false)
    private Priority priority = Priority.LOW;

    @Column(name = "due_date")
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    private LocalDate dueDate;

    /*
     * columnDefinition pins this to a plain VARCHAR, same fix as MergeRequest.product.
     * Without it, Hibernate 6 generates a native MySQL ENUM(...) column listing only the
     * constants that existed when the column was first created, and ddl-auto=update never
     * widens it when the Java enum gains a new constant (e.g. REWORKING, HALTED) — causing
     * a "Data truncated for column" SQLException the first time a row uses the new value.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, columnDefinition = "VARCHAR(30)")
    private TaskStatus status = TaskStatus.YET_TO_START;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
