package com.manoj.tasksmr.repository;

import com.manoj.tasksmr.model.TimeSheetEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface TimeSheetEntryRepository extends JpaRepository<TimeSheetEntry, Long> {

    @Query("SELECT e FROM TimeSheetEntry e LEFT JOIN FETCH e.task " +
           "ORDER BY e.entryDate DESC, e.startTime DESC")
    List<TimeSheetEntry> findAllOrderByEntryDateDescStartTimeDesc();

    @Query("SELECT e FROM TimeSheetEntry e LEFT JOIN FETCH e.task " +
           "WHERE e.entryDate >= :from AND e.entryDate <= :to " +
           "ORDER BY e.entryDate ASC, e.startTime ASC")
    List<TimeSheetEntry> findByDateRange(@Param("from") LocalDate from, @Param("to") LocalDate to);
}
