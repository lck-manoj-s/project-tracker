package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.TaskFilterDTO;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

public interface TaskService {
    List<Task> getAllTasks();
    List<Task> getFilteredTasks(TaskFilterDTO filter);
    Page<Task> getFilteredTasks(TaskFilterDTO filter, Pageable pageable);
    Optional<Task> getTaskById(Long id);
    Task saveTask(Task task);
    void deleteTask(Long id);
    /** Returns the task already using this MR (if any), so the caller can detect conflicts. */
    Optional<Task> findTaskUsingPayrollMr(MergeRequest mr);
    Optional<Task> findTaskUsingBooksMr(MergeRequest mr);

    /**
     * Called after an MR is saved. If any task in MR_CREATED status has this MR assigned
     * and ALL its associated MRs are now merged, the task is automatically moved to DONE.
     */
    void autoTransitionIfMerged(MergeRequest savedMr);
}
