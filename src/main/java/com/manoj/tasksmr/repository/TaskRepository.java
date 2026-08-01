package com.manoj.tasksmr.repository;

import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long>, JpaSpecificationExecutor<Task> {
    Optional<Task> findByPayrollMr(MergeRequest mr);
    Optional<Task> findByBooksMr(MergeRequest mr);
}
