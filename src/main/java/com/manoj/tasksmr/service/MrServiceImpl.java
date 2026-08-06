package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.enums.DeploymentStatus;
import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.model.DeploymentStatusHistory;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.MrStatusHistory;
import com.manoj.tasksmr.repository.DeploymentStatusHistoryRepository;
import com.manoj.tasksmr.repository.MergeRequestRepository;
import com.manoj.tasksmr.repository.MrStatusHistoryRepository;
import com.manoj.tasksmr.specification.MrSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class MrServiceImpl implements MrService {

    private final MergeRequestRepository            mrRepository;
    private final MrStatusHistoryRepository         mrStatusHistoryRepository;
    private final DeploymentStatusHistoryRepository deploymentStatusHistoryRepository;
    private final TaskService                       taskService;

    @Override
    @Transactional(readOnly = true)
    public List<MergeRequest> getAllMrs() {
        List<MergeRequest> list = new ArrayList<>(mrRepository.findAll());
        list.sort(MR_NUMBER_ORDER);
        return list;
    }

    @Override
    @Transactional(readOnly = true)
    public List<MergeRequest> getFilteredMrs(MrFilterDTO filter) {
        List<MergeRequest> list = new ArrayList<>(mrRepository.findAll(MrSpecification.withFilters(filter)));
        list.sort(MR_NUMBER_ORDER);
        return list;
    }

    /**
     * Sort by the numeric MR number extracted from the URL (e.g. "152865" from ".../152865").
     * Non-numeric suffixes fall to the end; ties break on mrSerialNumber.
     */
    private static final Comparator<MergeRequest> MR_NUMBER_ORDER = Comparator
            .comparingLong((MergeRequest mr) -> {
                try { return Long.parseLong(mr.getMrNumber()); }
                catch (Exception e) { return Long.MAX_VALUE; }
            })
            .thenComparingLong(MergeRequest::getMrSerialNumber);

    @Override
    @Transactional(readOnly = true)
    public Page<MergeRequest> getFilteredMrsPaged(MrFilterDTO filter, int page, int size) {
        List<MergeRequest> sorted = getFilteredMrs(filter);
        int total = sorted.size();
        int start = page * size;
        int end   = Math.min(start + size, total);
        List<MergeRequest> content = start < total ? sorted.subList(start, end) : List.of();
        return new PageImpl<>(content, PageRequest.of(page, size), total);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<MergeRequest> getMrById(Long id) {
        return mrRepository.findById(id);
    }

    /**
     * Saves an MR (create or edit form submit). If the pipeline status carried on
     * {@code mr} differs from what's persisted (or this is a new MR), records the
     * transition in mr_status_history — mirrors TaskServiceImpl.saveTask, so status
     * changes made from the form are tracked the same way as ones made by clicking
     * a pipeline stage badge.
     */
    @Override
    public MergeRequest saveMr(MergeRequest mr) {
        MrStatus previousStatus = null;
        DeploymentStatus previousDeploymentStatus = null;
        if (mr.getMrSerialNumber() != null) {
            Optional<MergeRequest> existing = mrRepository.findById(mr.getMrSerialNumber());
            previousStatus = existing.map(MergeRequest::getStatus).orElse(null);
            previousDeploymentStatus = existing.map(MergeRequest::getDeploymentStatus).orElse(null);
            // Carry forward the existing stage timestamps — the edit form only submits
            // the current deploymentStatus, so without this a save would wipe them out.
            existing.ifPresent(current -> {
                mr.setMovedToLocalAt(current.getMovedToLocalAt());
                mr.setMovedToPreAt(current.getMovedToPreAt());
                mr.setMovedToIdcAt(current.getMovedToIdcAt());
            });
        }
        applyDeploymentTimestamps(mr, mr.getDeploymentStatus());

        MergeRequest saved = mrRepository.save(mr);

        if (previousStatus == null || previousStatus != saved.getStatus()) {
            MrStatusHistory history = new MrStatusHistory();
            history.setMergeRequest(saved);
            history.setPreviousStatus(previousStatus);
            history.setNewStatus(saved.getStatus());
            mrStatusHistoryRepository.save(history);
        }

        if (previousDeploymentStatus == null || previousDeploymentStatus != saved.getDeploymentStatus()) {
            DeploymentStatusHistory deployHistory = new DeploymentStatusHistory();
            deployHistory.setMergeRequest(saved);
            deployHistory.setPreviousStatus(previousDeploymentStatus);
            deployHistory.setNewStatus(saved.getDeploymentStatus());
            deploymentStatusHistoryRepository.save(deployHistory);
        }

        taskService.autoTransitionIfMerged(saved);
        return saved;
    }

    @Override
    public void deleteMr(Long id) {
        mrRepository.deleteById(id);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<MergeRequest> findByUrl(String mrUrl) {
        return mrRepository.findByMr(mrUrl);
    }

    @Override
    public MrStatus updateStatus(Long mrId, MrStatus newStatus) {
        MergeRequest mr = mrRepository.findById(mrId)
                .orElseThrow(() -> new IllegalArgumentException("MR not found: " + mrId));

        MrStatus previousStatus = mr.getStatus();
        if (previousStatus == newStatus) {
            return previousStatus; // no-op, nothing to record
        }

        mr.setStatus(newStatus);
        MergeRequest saved = mrRepository.save(mr);
        taskService.autoTransitionIfMerged(saved);

        MrStatusHistory history = new MrStatusHistory();
        history.setMergeRequest(saved);
        history.setPreviousStatus(previousStatus);
        history.setNewStatus(newStatus);
        mrStatusHistoryRepository.save(history);

        return newStatus;
    }

    @Override
    public DeploymentStatus updateDeploymentStatus(Long mrId, DeploymentStatus newStatus) {
        MergeRequest mr = mrRepository.findById(mrId)
                .orElseThrow(() -> new IllegalArgumentException("MR not found: " + mrId));

        DeploymentStatus previousStatus = mr.getDeploymentStatus();
        if (previousStatus == newStatus) {
            return previousStatus; // no-op, nothing to record
        }

        mr.setDeploymentStatus(newStatus);
        applyDeploymentTimestamps(mr, newStatus);
        MergeRequest saved = mrRepository.save(mr);

        DeploymentStatusHistory history = new DeploymentStatusHistory();
        history.setMergeRequest(saved);
        history.setPreviousStatus(previousStatus);
        history.setNewStatus(newStatus);
        deploymentStatusHistoryRepository.save(history);

        return newStatus;
    }

    /**
     * Stamps movedTo{Stage}At the first time the MR reaches that stage. Since deployment
     * is a strict sequential progression, jumping straight to a later stage (e.g. NONE -> IDC)
     * also stamps every intermediate stage that doesn't already have a timestamp — we don't
     * know exactly when Local/Pre happened, so "now" is the best available answer. Timestamps
     * are never cleared when the MR is moved backward.
     */
    private void applyDeploymentTimestamps(MergeRequest mr, DeploymentStatus newStatus) {
        if (newStatus == null) return;
        LocalDateTime now = LocalDateTime.now();
        if (newStatus.ordinal() >= DeploymentStatus.LOCAL.ordinal() && mr.getMovedToLocalAt() == null) {
            mr.setMovedToLocalAt(now);
        }
        if (newStatus.ordinal() >= DeploymentStatus.PRE.ordinal() && mr.getMovedToPreAt() == null) {
            mr.setMovedToPreAt(now);
        }
        if (newStatus.ordinal() >= DeploymentStatus.IDC.ordinal() && mr.getMovedToIdcAt() == null) {
            mr.setMovedToIdcAt(now);
        }
    }
}
