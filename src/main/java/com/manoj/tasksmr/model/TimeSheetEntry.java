package com.manoj.tasksmr.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * A single logged activity — "what I did, and from when to when." Optionally linked to
 * the Task the activity was performed for. {@code endTime} is optional — an entry can be
 * logged as "in progress" (started, not yet finished) and closed out later via edit.
 */
@Entity
@Table(name = "time_sheet_entries")
@Getter
@Setter
@NoArgsConstructor
public class TimeSheetEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "activity", nullable = false, columnDefinition = "TEXT")
    private String activity;

    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    @Column(name = "entry_date", nullable = false)
    private LocalDate entryDate;

    @DateTimeFormat(iso = DateTimeFormat.ISO.TIME)
    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    /** Optional — null means the activity is still in progress (not yet closed out). */
    @DateTimeFormat(iso = DateTimeFormat.ISO.TIME)
    @Column(name = "end_time")
    private LocalTime endTime;

    /** Optional — the task this activity was performed for. */
    @ManyToOne
    @JoinColumn(name = "task_id")
    private Task task;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    /**
     * Minutes between start and end time. Assumes both fall on the same day (entryDate) —
     * entries don't span midnight.
     */
    @Transient
    public long getDurationMinutes() {
        if (startTime == null || endTime == null) return 0;
        return Duration.between(startTime, endTime).toMinutes();
    }

    /** Human-readable duration, e.g. "1h 30m", "45m", "2h" — or "In progress" if not yet closed out. */
    @Transient
    public String getDurationLabel() {
        if (endTime == null) return "In progress";
        long mins = getDurationMinutes();
        if (mins <= 0) return "0m";
        long h = mins / 60;
        long m = mins % 60;
        if (h > 0 && m > 0) return h + "h " + m + "m";
        if (h > 0) return h + "h";
        return m + "m";
    }
}
