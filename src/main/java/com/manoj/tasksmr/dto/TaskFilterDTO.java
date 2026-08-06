package com.manoj.tasksmr.dto;

import com.manoj.tasksmr.enums.Priority;
import com.manoj.tasksmr.enums.TaskStatus;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO for filtering Tasks.
 * Add new filter fields here as the application grows.
 */
@Getter
@Setter
@NoArgsConstructor
public class TaskFilterDTO {

    /** Filter by task status */
    private TaskStatus status;

    /** Filter by priority */
    private Priority priority;

    /**
     * Filter by which products the task's linked MRs belong to:
     *  PAYROLL_ONLY  - has >=1 Payroll MR and no Books MR
     *  BOOKS_ONLY    - has >=1 Books MR and no Payroll MR
     *  BOTH          - has >=1 of each
     *  NONE          - has no MRs at all
     *  null          - no filter
     * A task may have any number of MRs of either product.
     */
    private String mrPresence;

    /**
     * Filter tasks where ALL associated MRs have diCompleted = true.
     * null = no filter, true = all DI completed, false = not all DI completed
     */
    private Boolean allDiCompleted;

    /**
     * When true, exclude tasks with status = DONE.
     * Used as the default view (active tasks only).
     */
    private Boolean excludeDone;

    /**
     * Filter by membership in a set of statuses (e.g. the Halted/Paused "parked" tab).
     * Only applied when {@code status} is null — an exact status choice always wins.
     */
    private List<TaskStatus> statusIn;
}
