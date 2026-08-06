package com.manoj.tasksmr.service;

import com.manoj.tasksmr.model.TimeSheetEntry;
import com.manoj.tasksmr.repository.TimeSheetEntryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class TimeSheetServiceImpl implements TimeSheetService {

    private final TimeSheetEntryRepository repository;

    @Override
    @Transactional(readOnly = true)
    public List<TimeSheetEntry> getAllEntries() {
        return repository.findAllOrderByEntryDateDescStartTimeDesc();
    }

    @Override
    @Transactional(readOnly = true)
    public List<TimeSheetEntry> getEntriesForDateRange(LocalDate from, LocalDate to) {
        return repository.findByDateRange(from, to);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<TimeSheetEntry> getEntryById(Long id) {
        return repository.findById(id);
    }

    @Override
    public TimeSheetEntry saveEntry(TimeSheetEntry entry) {
        return repository.save(entry);
    }

    @Override
    public void deleteEntry(Long id) {
        repository.deleteById(id);
    }
}
