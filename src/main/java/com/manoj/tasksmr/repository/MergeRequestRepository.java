package com.manoj.tasksmr.repository;

import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MergeRequestRepository extends JpaRepository<MergeRequest, Long>, JpaSpecificationExecutor<MergeRequest> {
    Optional<MergeRequest> findByMr(String mr);

    /** All MRs currently linked to the given task, any product. */
    List<MergeRequest> findByTask(Task task);
}
