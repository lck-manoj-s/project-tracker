package com.manoj.tasksmr.repository;

import com.manoj.tasksmr.model.MergeRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MergeRequestRepository extends JpaRepository<MergeRequest, Long>, JpaSpecificationExecutor<MergeRequest> {
    Optional<MergeRequest> findByMr(String mr);
}
