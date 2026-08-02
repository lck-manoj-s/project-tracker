package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.TaskFilterDTO;
import com.manoj.tasksmr.dto.TaskSaveResult;
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

    /**
     * Saves a task and (re)assigns the given MRs (any product mix, any count) to it.
     * Validates that none of the requested MRs already belong to a different task;
     * if any do, nothing is persisted and the conflicts are returned in the result.
     */
    TaskSaveResult saveTaskWithMrs(Task task, List<Long> mrIds);

    /**
     * Called after an MR is saved/toggled. If the MR's task is in MR_CREATED status and
     * ALL of that task's associated MRs are now merged (or marked can-ignore), the task
     * is automatically moved to DONE.
     */
    void autoTransitionIfMerged(MergeRequest savedMr);
}
