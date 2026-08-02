package com.manoj.tasksmr.repository;

import com.manoj.tasksmr.model.Task;
import com.manoj.tasksmr.model.TaskStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface TaskStatusHistoryRepository extends JpaRepository<TaskStatusHistory, Long> {
    List<TaskStatusHistory> findByTaskOrderByChangedAtAsc(Task task);

    @Query("SELECT h FROM TaskStatusHistory h JOIN FETCH h.task t LEFT JOIN FETCH t.mergeRequests ORDER BY h.changedAt DESC")
    List<TaskStatusHistory> findAllOrderByChangedAtDesc();
}
