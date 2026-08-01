package com.manoj.tasksmr.service;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.repository.MergeRequestRepository;
import com.manoj.tasksmr.specification.MrSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class MrServiceImpl implements MrService {

    private final MergeRequestRepository mrRepository;
    private final TaskService            taskService;

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

    @Override
    public MergeRequest saveMr(MergeRequest mr) {
        MergeRequest saved = mrRepository.save(mr);
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
}
