package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.TaskFilterDTO;
import com.manoj.tasksmr.dto.TaskSaveResult;
import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.enums.TaskStatus;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import com.manoj.tasksmr.model.TaskStatusHistory;
import com.manoj.tasksmr.repository.MergeRequestRepository;
import com.manoj.tasksmr.repository.TaskRepository;
import com.manoj.tasksmr.repository.TaskStatusHistoryRepository;
import com.manoj.tasksmr.specification.TaskSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class TaskServiceImpl implements TaskService {

    private final TaskRepository               taskRepository;
    private final TaskStatusHistoryRepository  taskStatusHistoryRepository;
    private final MergeRequestRepository       mergeRequestRepository;

    @Override
    @Transactional(readOnly = true)
    public List<Task> getAllTasks() {
        return taskRepository.findAll();
    }

    @Override
    @Transactional(readOnly = true)
    public List<Task> getFilteredTasks(TaskFilterDTO filter) {
        return taskRepository.findAll(TaskSpecification.withFilters(filter));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<Task> getFilteredTasks(TaskFilterDTO filter, Pageable pageable) {
        return taskRepository.findAll(TaskSpecification.withFilters(filter), pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Task> getTaskById(Long id) {
        return taskRepository.findById(id);
    }

    @Override
    public Task saveTask(Task task) {
        // Capture existing status before saving (null if this is a new task)
        TaskStatus previousStatus = null;
        if (task.getTaskId() != null) {
            previousStatus = taskRepository.findById(task.getTaskId())
                    .map(Task::getStatus).orElse(null);
        }

        Task saved = taskRepository.save(task);

        // Record initial status (new task) or a status transition
        if (previousStatus == null || previousStatus != saved.getStatus()) {
            TaskStatusHistory history = new TaskStatusHistory();
            history.setTask(saved);
            history.setPreviousStatus(previousStatus);
            history.setNewStatus(saved.getStatus());
            taskStatusHistoryRepository.save(history);
        }

        return saved;
    }

    @Override
    public TaskSaveResult saveTaskWithMrs(Task task, List<Long> mrIds) {
        List<String> errors = new ArrayList<>();
        List<MergeRequest> targetMrs = new ArrayList<>();

        if (mrIds != null) {
            // De-dup while preserving order
            Set<Long> seen = new LinkedHashSet<>(mrIds.stream().filter(java.util.Objects::nonNull).toList());
            for (Long id : seen) {
                MergeRequest mr = mergeRequestRepository.findById(id).orElse(null);
                if (mr == null) continue;
                boolean assignedElsewhere = mr.getTask() != null
                        && (task.getTaskId() == null || !mr.getTask().getTaskId().equals(task.getTaskId()));
                if (assignedElsewhere) {
                    errors.add("MR #" + mr.getMrNumber() + " is already assigned to Task #"
                            + mr.getTask().getTaskId() + ".");
                } else {
                    targetMrs.add(mr);
                }
            }
        }

        if (!errors.isEmpty()) {
            return new TaskSaveResult(null, errors);
        }

        Task saved = saveTask(task);

        // Unlink MRs previously assigned to this task but no longer selected
        List<MergeRequest> currentlyLinked = mergeRequestRepository.findByTask(saved);
        Set<Long> targetIds = targetMrs.stream().map(MergeRequest::getMrSerialNumber).collect(Collectors.toSet());
        for (MergeRequest mr : currentlyLinked) {
            if (!targetIds.contains(mr.getMrSerialNumber())) {
                mr.setTask(null);
                mergeRequestRepository.save(mr);
            }
        }

        // Link the target MRs
        for (MergeRequest mr : targetMrs) {
            mr.setTask(saved);
            mergeRequestRepository.save(mr);
        }

        return new TaskSaveResult(saved, List.of());
    }

    @Override
    public void deleteTask(Long id) {
        taskRepository.deleteById(id);
    }

    // Statuses eligible to auto-advance to DONE once all of a task's linked MRs are
    // merged/ignorable. MR_CREATED is the "normal" path; REWORKING and HALTED also
    // auto-advance so a task doesn't get stuck needing a manual move to Done just
    // because it was mid-rework or halted when its MRs happened to merge.
    private static final java.util.Set<TaskStatus> AUTO_TRANSITION_ELIGIBLE =
            java.util.Set.of(TaskStatus.MR_CREATED, TaskStatus.REWORKING, TaskStatus.HALTED);

    @Override
    public void autoTransitionIfMerged(MergeRequest savedMr) {
        Task task = savedMr.getTask();
        if (task == null) return;
        TaskStatus previousStatus = task.getStatus();
        if (!AUTO_TRANSITION_ELIGIBLE.contains(previousStatus)) return;

        List<MergeRequest> linkedMrs = mergeRequestRepository.findByTask(task);
        if (linkedMrs.isEmpty()) return;

        boolean allDone = linkedMrs.stream()
                .allMatch(mr -> mr.getStatus() == MrStatus.MERGED || Boolean.TRUE.equals(mr.getCanIgnore()));

        if (allDone) {
            task.setStatus(TaskStatus.DONE);
            Task savedTask = taskRepository.save(task);
            TaskStatusHistory history = new TaskStatusHistory();
            history.setTask(savedTask);
            history.setPreviousStatus(previousStatus);
            history.setNewStatus(TaskStatus.DONE);
            taskStatusHistoryRepository.save(history);
        }
    }
}
