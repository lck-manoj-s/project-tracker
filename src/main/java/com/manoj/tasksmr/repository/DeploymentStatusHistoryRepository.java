package com.manoj.tasksmr.repository;

import com.manoj.tasksmr.model.DeploymentStatusHistory;
import com.manoj.tasksmr.model.MergeRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface DeploymentStatusHistoryRepository extends JpaRepository<DeploymentStatusHistory, Long> {
    List<DeploymentStatusHistory> findByMergeRequestOrderByChangedAtAsc(MergeRequest mergeRequest);

    @Query("SELECT h FROM DeploymentStatusHistory h JOIN FETCH h.mergeRequest ORDER BY h.changedAt DESC")
    List<DeploymentStatusHistory> findAllOrderByChangedAtDesc();
}
