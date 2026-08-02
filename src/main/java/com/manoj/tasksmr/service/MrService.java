package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.enums.MrStatus;
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

    /**
     * Sets the MR's current pipeline stage (clicking a pipeline step in the UI jumps directly
     * to that stage — forward or backward) and records the transition in mr_status_history
     * so per-stage durations can be reconstructed later. No-op (no history row) if the
     * requested status equals the current one. Returns the MR's status after the update.
     */
    MrStatus updateStatus(Long mrId, MrStatus newStatus);
}
