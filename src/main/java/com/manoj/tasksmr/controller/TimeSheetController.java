package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.model.TimeSheetEntry;
import com.manoj.tasksmr.service.TaskService;
import com.manoj.tasksmr.service.TimeSheetService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Controller
@RequestMapping("/timesheet")
@RequiredArgsConstructor
public class TimeSheetController {

    private final TimeSheetService timeSheetService;
    private final TaskService      taskService;

    private static final DateTimeFormatter DAY_LABEL       = DateTimeFormatter.ofPattern("EEE, dd MMM yyyy");
    private static final DateTimeFormatter WEEK_LABEL      = DateTimeFormatter.ofPattern("dd MMM");
    private static final DateTimeFormatter CHART_DAY_LABEL = DateTimeFormatter.ofPattern("EEE d MMM");
    private static final DateTimeFormatter WEEK_YEAR_LABEL = DateTimeFormatter.ofPattern("dd MMM yyyy");

    /**
     * The list page only ever shows the current (Mon–Sun) week — older entries are still in
     * the database, they're just not rendered here. Use the CSV export below to pull any
     * date range, including past weeks.
     */
    @GetMapping
    public String list(
            @RequestParam(required = false) Long taskId,
            Model model) {

        List<TimeSheetEntry> all = timeSheetService.getAllEntries();

        LocalDate today     = LocalDate.now();
        LocalDate weekStart = today.minusDays(today.getDayOfWeek().getValue() - 1L); // Monday
        LocalDate weekEnd   = weekStart.plusDays(6);                                  // Sunday

        // Unfiltered — used only for the "Today" / "This Week" summary totals, which should
        // always reflect everything logged, regardless of the Task filter applied below.
        List<TimeSheetEntry> weekEntriesUnfiltered = all.stream()
                .filter(e -> !e.getEntryDate().isBefore(weekStart) && !e.getEntryDate().isAfter(weekEnd))
                .toList();

        List<TimeSheetEntry> weekEntries = weekEntriesUnfiltered.stream()
                .filter(e -> taskId == null || (e.getTask() != null && Objects.equals(e.getTask().getTaskId(), taskId)))
                .toList();

        // Group by day — `weekEntries` is already ordered entryDate DESC, startTime DESC,
        // so insertion order into this map preserves that day ordering.
        LinkedHashMap<LocalDate, List<TimeSheetEntry>> byDate = new LinkedHashMap<>();
        for (TimeSheetEntry e : weekEntries) {
            byDate.computeIfAbsent(e.getEntryDate(), d -> new ArrayList<>()).add(e);
        }

        List<Map<String, Object>> dayGroups = new ArrayList<>();
        for (LocalDate date : byDate.keySet()) {
            List<TimeSheetEntry> dayEntries = new ArrayList<>(byDate.get(date));
            dayEntries.sort(Comparator.comparing(TimeSheetEntry::getStartTime).reversed()); // latest first within the day

            long totalMinutes  = dayEntries.stream().mapToLong(TimeSheetEntry::getDurationMinutes).sum();
            boolean hasOpenEntry = dayEntries.stream().anyMatch(e -> e.getEndTime() == null);

            Map<String, Object> group = new LinkedHashMap<>();
            group.put("dateLabel",    date.format(DAY_LABEL));
            group.put("totalLabel",   formatMinutes(totalMinutes));
            group.put("isToday",      date.isEqual(today));
            group.put("hasOpenEntry", hasOpenEntry);
            group.put("entries",      dayEntries);
            dayGroups.add(group);
        }

        long todayMinutes = all.stream()
                .filter(e -> e.getEntryDate().isEqual(today))
                .mapToLong(TimeSheetEntry::getDurationMinutes).sum();
        long weekMinutes = weekEntriesUnfiltered.stream()
                .mapToLong(TimeSheetEntry::getDurationMinutes).sum();

        model.addAttribute("dayGroups",      dayGroups);
        model.addAttribute("weekRangeLabel", weekStart.format(WEEK_LABEL) + " – " + weekEnd.format(WEEK_LABEL));
        model.addAttribute("taskId",         taskId);
        model.addAttribute("tasks",          taskService.getAllTasks());
        model.addAttribute("todayLabel",     formatMinutes(todayMinutes));
        model.addAttribute("weekLabel",      formatMinutes(weekMinutes));
        model.addAttribute("todayDate",      today);

        return "timesheet/list";
    }

    /**
     * Small JSON endpoint backing the sidebar's "This week" widget (shown on every page) —
     * same Mon–Sun current-week total already computed inline in {@link #list}, just exposed
     * as JSON instead of baked into a server-rendered page.
     */
    @GetMapping("/current-week-summary")
    @ResponseBody
    public Map<String, Object> currentWeekSummary() {
        LocalDate today     = LocalDate.now();
        LocalDate weekStart = today.minusDays(today.getDayOfWeek().getValue() - 1L); // Monday
        LocalDate weekEnd   = weekStart.plusDays(6);                                  // Sunday

        long weekMinutes = timeSheetService.getEntriesForDateRange(weekStart, weekEnd).stream()
                .mapToLong(TimeSheetEntry::getDurationMinutes).sum();

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("label", formatMinutes(weekMinutes));
        return response;
    }

    /** CSV export — the only way to reach entries outside the current week shown on the list page. */
    @GetMapping("/export")
    public void export(
            @RequestParam(required = false) String fromDate,
            @RequestParam(required = false) String toDate,
            @RequestParam(required = false) Long   taskId,
            HttpServletResponse response) throws IOException {

        LocalDate from = parseDate(fromDate);
        LocalDate to   = parseDate(toDate);

        List<TimeSheetEntry> entries = timeSheetService.getAllEntries().stream()
                .filter(e -> from == null || !e.getEntryDate().isBefore(from))
                .filter(e -> to == null || !e.getEntryDate().isAfter(to))
                .filter(e -> taskId == null || (e.getTask() != null && Objects.equals(e.getTask().getTaskId(), taskId)))
                .sorted(Comparator.comparing(TimeSheetEntry::getEntryDate).thenComparing(TimeSheetEntry::getStartTime))
                .toList();

        String filename = "timesheet_" + (from != null ? from : "all") + "_to_" + (to != null ? to : "all") + ".csv";

        response.setContentType("text/csv;charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");

        PrintWriter writer = response.getWriter();
        writer.write(csvRow("Date", "Start Time", "End Time", "Duration", "Activity", "Task"));
        for (TimeSheetEntry e : entries) {
            writer.write(csvRow(
                    String.valueOf(e.getEntryDate()),
                    String.valueOf(e.getStartTime()),
                    e.getEndTime() != null ? e.getEndTime().toString() : "",
                    e.getDurationLabel(),
                    e.getActivity(),
                    e.getTask() != null ? "#" + e.getTask().getTaskId() + " " + e.getTask().getDescription() : ""
            ));
        }
        writer.flush();
    }

    /** Weekly report — defaults to last week (weekOffset = -1). */
    @GetMapping("/report")
    public String report(
            @RequestParam(defaultValue = "-1") int weekOffset,
            Model model) {

        LocalDate today     = LocalDate.now();
        LocalDate refMonday = today.minusDays(today.getDayOfWeek().getValue() - 1L);
        LocalDate weekStart = refMonday.plusWeeks(weekOffset);
        LocalDate weekEnd   = weekStart.plusDays(6);

        // Clamp: don't allow future weeks
        if (weekOffset > 0) weekOffset = 0;

        List<TimeSheetEntry> entries = timeSheetService.getEntriesForDateRange(weekStart, weekEnd);

        // ── Hours per day (Mon=0 … Sun=6) ────────────────────────────────
        long[] dayMinutes = new long[7];
        for (TimeSheetEntry e : entries) {
            int idx = e.getEntryDate().getDayOfWeek().getValue() - 1;
            dayMinutes[idx] += e.getDurationMinutes();
        }

        // Chart data: one label and one value per day Mon–Sun
        List<String> chartLabels = IntStream.range(0, 7)
                .mapToObj(i -> weekStart.plusDays(i).format(CHART_DAY_LABEL))
                .collect(Collectors.toList());
        List<String> chartHours = IntStream.range(0, 7)
                .mapToObj(i -> {
                    long mins = dayMinutes[i];
                    // Round to 1 decimal place: (mins / 6.0) rounded, then / 10.0
                    return String.valueOf(Math.round(mins / 6.0) / 10.0);
                })
                .collect(Collectors.toList());

        String chartLabelsJson = "[" + chartLabels.stream().map(l -> "\"" + l + "\"").collect(Collectors.joining(",")) + "]";
        String chartHoursJson  = "[" + String.join(",", chartHours) + "]";

        // ── Task breakdown ────────────────────────────────────────────────
        LinkedHashMap<Long, Map<String, Object>> taskAccum = new LinkedHashMap<>();
        for (TimeSheetEntry e : entries) {
            if (e.getTask() == null) continue;
            Long taskId = e.getTask().getTaskId();
            Map<String, Object> t = taskAccum.computeIfAbsent(taskId, id -> {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("taskId",      id);
                m.put("description", e.getTask().getDescription());
                m.put("status",      e.getTask().getStatus().getDisplayName());
                m.put("statusName",  e.getTask().getStatus().name());
                m.put("minutes",     0L);
                return m;
            });
            t.put("minutes", (Long) t.get("minutes") + e.getDurationMinutes());
        }

        List<Map<String, Object>> taskBreakdown = new ArrayList<>(taskAccum.values());
        taskBreakdown.sort(Comparator.comparingLong(t -> -((Long) t.get("minutes"))));
        taskBreakdown.forEach(t -> t.put("hoursLabel", formatMinutes((Long) t.get("minutes"))));

        // ── Day-grouped detail log (desc order for display) ───────────────
        LinkedHashMap<LocalDate, List<TimeSheetEntry>> byDate = new LinkedHashMap<>();
        entries.stream()
               .sorted(Comparator.comparing(TimeSheetEntry::getEntryDate).reversed()
                       .thenComparing(Comparator.comparing(TimeSheetEntry::getStartTime).reversed()))
               .forEach(e -> byDate.computeIfAbsent(e.getEntryDate(), d -> new ArrayList<>()).add(e));

        List<Map<String, Object>> dayGroups = new ArrayList<>();
        for (LocalDate date : byDate.keySet()) {
            List<TimeSheetEntry> dayEntries = byDate.get(date);
            long totalMins  = dayEntries.stream().mapToLong(TimeSheetEntry::getDurationMinutes).sum();
            boolean hasOpen = dayEntries.stream().anyMatch(e -> e.getEndTime() == null);
            Map<String, Object> g = new LinkedHashMap<>();
            g.put("dateLabel",    date.format(DAY_LABEL));
            g.put("totalLabel",   formatMinutes(totalMins));
            g.put("isToday",      date.isEqual(today));
            g.put("hasOpenEntry", hasOpen);
            g.put("entries",      dayEntries);
            dayGroups.add(g);
        }

        long totalMinutes = Arrays.stream(dayMinutes).sum();
        int  daysLogged   = (int) Arrays.stream(dayMinutes).filter(m -> m > 0).count();

        model.addAttribute("weekOffset",     weekOffset);
        model.addAttribute("prevOffset",     weekOffset - 1);
        model.addAttribute("nextOffset",     Math.min(weekOffset + 1, 0));
        model.addAttribute("isCurrentWeek",  weekOffset >= 0);
        model.addAttribute("weekRangeLabel", weekStart.format(WEEK_LABEL) + " – " + weekEnd.format(WEEK_YEAR_LABEL));
        model.addAttribute("totalLabel",     formatMinutes(totalMinutes));
        model.addAttribute("daysLogged",     daysLogged);
        model.addAttribute("taskCount",      taskAccum.size());
        model.addAttribute("chartLabelsJson", chartLabelsJson);
        model.addAttribute("chartHoursJson",  chartHoursJson);
        model.addAttribute("taskBreakdown",   taskBreakdown);
        model.addAttribute("dayGroups",       dayGroups);
        model.addAttribute("totalEntries",    entries.size());

        return "timesheet/report";
    }

    @GetMapping("/new")
    public String newForm(Model model) {
        TimeSheetEntry entry = new TimeSheetEntry();
        entry.setEntryDate(LocalDate.now());
        populateFormModel(model, entry, false);
        return "timesheet/form";
    }

    @GetMapping("/edit/{id}")
    public String editForm(@PathVariable Long id, Model model) {
        TimeSheetEntry entry = timeSheetService.getEntryById(id)
                .orElseThrow(() -> new IllegalArgumentException("Time sheet entry not found: " + id));
        populateFormModel(model, entry, true);
        return "timesheet/form";
    }

    @PostMapping("/save")
    public String save(
            @ModelAttribute TimeSheetEntry form,
            @RequestParam(required = false) Long taskId,
            // Bound as a plain String (not directly onto the entity's LocalTime field) because
            // the field is optional — an empty submitted value would otherwise fail Spring's
            // LocalTime conversion before we ever get a chance to validate it ourselves.
            @RequestParam(required = false) String endTimeInput,
            RedirectAttributes ra) {

        LocalTime endTime = parseTime(endTimeInput);

        LocalDate today = LocalDate.now();
        boolean isToday = form.getEntryDate() != null && form.getEntryDate().isEqual(today);

        String validationError = null;
        if (form.getEntryDate() != null && form.getEntryDate().isAfter(today)) {
            validationError = "Entry date cannot be in the future.";
        } else if (isToday && form.getStartTime() != null && form.getStartTime().isAfter(LocalTime.now())) {
            validationError = "Start time cannot be in the future.";
        } else if (isToday && endTime != null && endTime.isAfter(LocalTime.now())) {
            validationError = "End time cannot be in the future.";
        } else if (form.getStartTime() != null && endTime != null
                && !endTime.isAfter(form.getStartTime())) {
            validationError = "End time must be after start time.";
        }

        if (validationError != null) {
            ra.addFlashAttribute("errorMessage", validationError);
            String redirect = form.getId() != null
                    ? "redirect:/timesheet/edit/" + form.getId()
                    : "redirect:/timesheet/new";
            return redirect;
        }

        boolean isEdit = form.getId() != null;
        TimeSheetEntry entry = isEdit
                ? timeSheetService.getEntryById(form.getId()).orElse(form)
                : form;

        entry.setActivity(form.getActivity());
        entry.setEntryDate(form.getEntryDate());
        entry.setStartTime(form.getStartTime());
        entry.setEndTime(endTime);
        entry.setTask(taskId != null ? taskService.getTaskById(taskId).orElse(null) : null);

        timeSheetService.saveEntry(entry);
        ra.addFlashAttribute("successMessage", isEdit ? "Entry updated successfully." : "Entry added successfully.");
        return "redirect:/timesheet";
    }

    @PostMapping("/delete/{id}")
    public String delete(@PathVariable Long id, RedirectAttributes ra) {
        timeSheetService.deleteEntry(id);
        ra.addFlashAttribute("successMessage", "Entry deleted successfully.");
        return "redirect:/timesheet";
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private void populateFormModel(Model model, TimeSheetEntry entry, boolean isEdit) {
        model.addAttribute("entry",     entry);
        model.addAttribute("isEdit",    isEdit);
        model.addAttribute("tasks",     taskService.getAllTasks());
        model.addAttribute("todayDate", LocalDate.now());
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.isBlank()) return null;
        try { return LocalDate.parse(s); } catch (Exception e) { return null; }
    }

    private LocalTime parseTime(String s) {
        if (s == null || s.isBlank()) return null;
        try { return LocalTime.parse(s); } catch (Exception e) { return null; }
    }

    private String formatMinutes(long minutes) {
        long h = minutes / 60, m = minutes % 60;
        if (h > 0 && m > 0) return h + "h " + m + "m";
        if (h > 0) return h + "h";
        return m + "m";
    }

    private String csvRow(String... fields) {
        return Arrays.stream(fields).map(this::csvEscape).collect(Collectors.joining(",")) + "\n";
    }

    private String csvEscape(String field) {
        if (field == null) return "";
        String escaped = field.replace("\"", "\"\"");
        if (escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") || escaped.contains("\r")) {
            return "\"" + escaped + "\"";
        }
        return escaped;
    }
}
