package com.manoj.tasksmr.dto;

import com.manoj.tasksmr.model.Task;

import java.util.List;

/**
 * Result of saving a task together with its MR assignments.
 * If {@code errors} is non-empty, nothing was persisted — the caller should
 * show the errors and let the user retry (e.g. an MR was already assigned
 * to a different task).
 */
public record TaskSaveResult(Task task, List<String> errors) {

    public boolean hasErrors() {
        return errors != null && !errors.isEmpty();
    }
}
