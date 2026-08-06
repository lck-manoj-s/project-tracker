package com.manoj.tasksmr.service;

import com.manoj.tasksmr.model.TimeSheetEntry;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface TimeSheetService {
    List<TimeSheetEntry> getAllEntries();
    List<TimeSheetEntry> getEntriesForDateRange(LocalDate from, LocalDate to);
    Optional<TimeSheetEntry> getEntryById(Long id);
    TimeSheetEntry saveEntry(TimeSheetEntry entry);
    void deleteEntry(Long id);
}
