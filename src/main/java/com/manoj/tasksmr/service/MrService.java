package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.model.MergeRequest;
import org.springframework.data.domain.Page;

import java.util.List;
import java.util.Optional;

public interface MrService {
    List<MergeRequest> getAllMrs();
    List<MergeRequest> getFilteredMrs(MrFilterDTO filter);
    Page<MergeRequest> getFilteredMrsPaged(MrFilterDTO filter, int page, int size);
    Optional<MergeRequest> getMrById(Long id);
    MergeRequest saveMr(MergeRequest mr);
    void deleteMr(Long id);
    /** Returns an existing MR with this URL (if any) so the caller can detect duplicate URLs. */
    Optional<MergeRequest> findByUrl(String mrUrl);
}
