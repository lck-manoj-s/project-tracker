package com.manoj.tasksmr.repository;

import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.MrStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface MrStatusHistoryRepository extends JpaRepository<MrStatusHistory, Long> {
    List<MrStatusHistory> findByMergeRequestOrderByChangedAtAsc(MergeRequest mergeRequest);

    @Query("SELECT h FROM MrStatusHistory h JOIN FETCH h.mergeRequest ORDER BY h.changedAt DESC")
    List<MrStatusHistory> findAllOrderByChangedAtDesc();
}
