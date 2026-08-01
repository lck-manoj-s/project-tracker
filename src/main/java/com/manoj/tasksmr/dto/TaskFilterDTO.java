package com.manoj.tasksmr.dto;

import com.manoj.tasksmr.enums.Priority;
import com.manoj.tasksmr.enums.TaskStatus;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

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
     * Filter by MR presence:
     *  PAYROLL_ONLY  - has payrollMr but no booksMr
     *  BOOKS_ONLY    - has booksMr but no payrollMr
     *  BOTH          - has both
     *  null          - no filter
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
}
