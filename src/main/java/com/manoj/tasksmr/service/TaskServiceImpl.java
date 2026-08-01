package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.TaskFilterDTO;
import com.manoj.tasksmr.enums.TaskStatus;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import com.manoj.tasksmr.model.TaskStatusHistory;
import com.manoj.tasksmr.repository.TaskRepository;
import com.manoj.tasksmr.repository.TaskStatusHistoryRepository;
import com.manoj.tasksmr.specification.TaskSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional
public class TaskServiceImpl implements TaskService {

    private final TaskRepository               taskRepository;
    private final TaskStatusHistoryRepository  taskStatusHistoryRepository;

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
    public void deleteTask(Long id) {
        taskRepository.deleteById(id);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Task> findTaskUsingPayrollMr(MergeRequest mr) {
        return taskRepository.findByPayrollMr(mr);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Task> findTaskUsingBooksMr(MergeRequest mr) {
        return taskRepository.findByBooksMr(mr);
    }

    @Override
    public void autoTransitionIfMerged(MergeRequest savedMr) {
        // Collect tasks that reference this MR (as payroll or books)
        Set<Task> candidates = new LinkedHashSet<>();
        taskRepository.findByPayrollMr(savedMr).ifPresent(candidates::add);
        taskRepository.findByBooksMr(savedMr).ifPresent(candidates::add);

        for (Task task : candidates) {
            // Only auto-transition tasks currently in MR_CREATED
            if (task.getStatus() != TaskStatus.MR_CREATED) continue;

            MergeRequest p = task.getPayrollMr();
            MergeRequest b = task.getBooksMr();

            boolean hasMr       = p != null || b != null;
            boolean payrollDone = p == null || Boolean.TRUE.equals(p.getStepMerged()) || Boolean.TRUE.equals(p.getCanIgnore());
            boolean booksDone   = b == null || Boolean.TRUE.equals(b.getStepMerged()) || Boolean.TRUE.equals(b.getCanIgnore());

            if (hasMr && payrollDone && booksDone) {
                task.setStatus(TaskStatus.DONE);
                Task savedTask = taskRepository.save(task);
                // Record the auto-transition in history
                TaskStatusHistory history = new TaskStatusHistory();
                history.setTask(savedTask);
                history.setPreviousStatus(TaskStatus.MR_CREATED);
                history.setNewStatus(TaskStatus.DONE);
                taskStatusHistoryRepository.save(history);
            }
        }
    }
}
