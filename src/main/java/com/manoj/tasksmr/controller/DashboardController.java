package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.enums.Product;
import com.manoj.tasksmr.enums.TaskStatus;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.MrStatusHistory;
import com.manoj.tasksmr.model.Task;
import com.manoj.tasksmr.model.TaskStatusHistory;
import com.manoj.tasksmr.repository.MrStatusHistoryRepository;
import com.manoj.tasksmr.repository.TaskStatusHistoryRepository;
import com.manoj.tasksmr.service.MrService;
import com.manoj.tasksmr.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Controller
@RequiredArgsConstructor
public class DashboardController {

    private final TaskService taskService;
    private final MrService   mrService;
    private final TaskStatusHistoryRepository taskStatusHistoryRepo;
    private final MrStatusHistoryRepository   mrStatusHistoryRepo;

    private static final int STALE_DAYS = 3;

    @GetMapping("/dashboard")
    public String dashboard(Model model) {

        // ── All tasks ──────────────────────────────────────────────────────
        List<Task> allTasks = taskService.getAllTasks();

        long yetToStart       = allTasks.stream().filter(t -> t.getStatus() == TaskStatus.YET_TO_START).count();
        long identifyingIssue = allTasks.stream().filter(t -> t.getStatus() == TaskStatus.IDENTIFYING_ISSUE).count();
        long fixing           = allTasks.stream().filter(t -> t.getStatus() == TaskStatus.FIXING).count();
        long mrCreated        = allTasks.stream().filter(t -> t.getStatus() == TaskStatus.MR_CREATED).count();
        long done             = allTasks.stream().filter(t -> t.getStatus() == TaskStatus.DONE).count();
        long paused           = allTasks.stream().filter(t -> t.getStatus() == TaskStatus.PAUSED).count();

        List<Task> tasksNoMr = allTasks.stream()
                .filter(t -> t.getStatus() != TaskStatus.PAUSED && t.getStatus() != TaskStatus.DONE)
                .filter(t -> t.getMergeRequests() == null || t.getMergeRequests().isEmpty())
                .toList();

        // DI pending = has at least one MR, and at least one linked MR not yet DI-completed
        List<Task> tasksDiPending = allTasks.stream()
                .filter(t -> t.getStatus() != TaskStatus.DONE && t.getStatus() != TaskStatus.PAUSED)
                .filter(t -> t.getMergeRequests() != null && !t.getMergeRequests().isEmpty())
                .filter(t -> t.getMergeRequests().stream()
                        .anyMatch(mr -> !Boolean.TRUE.equals(mr.getStepDiCompleted())))
                .toList();

        // ── All MRs — single DB load, partitioned in-memory ───────────────
        List<MergeRequest> allMrs = mrService.getAllMrs();
        List<MergeRequest> payrollMrs = allMrs.stream().filter(mr -> mr.getProduct() == Product.PAYROLL).toList();
        List<MergeRequest> booksMrs   = allMrs.stream().filter(mr -> mr.getProduct() == Product.BOOKS).toList();

        // For charts and attention blocks: exclude canIgnore MRs
        List<MergeRequest> payrollMrsActive = payrollMrs.stream().filter(mr -> !mr.getCanIgnore()).toList();
        List<MergeRequest> booksMrsActive   = booksMrs.stream().filter(mr -> !mr.getCanIgnore()).toList();

        List<MergeRequest> allActiveMrs = allMrs.stream()
                .filter(mr -> !mr.getCanIgnore())
                .toList();

        // Attention blocks — based on current pipeline stage (MrStatus)
        List<MergeRequest> mrsNotReviewed = allActiveMrs.stream()
                .filter(mr -> mr.getStatus().ordinal() < MrStatus.REVIEWED.ordinal()).toList();
        List<MergeRequest> mrsReadyForGtm = allActiveMrs.stream()
                .filter(mr -> mr.getStatus() == MrStatus.DI_COMPLETED).toList();
        List<MergeRequest> mrsReadyForRtm = allActiveMrs.stream()
                .filter(mr -> mr.getStatus() == MrStatus.GTM).toList();
        List<MergeRequest> mrsNotMerged   = allActiveMrs.stream()
                .filter(mr -> mr.getStatus() != MrStatus.MERGED).toList();

        // MR pipeline step counts — canIgnore excluded (how many MRs have reached each stage or beyond)
        long payrollNew         = countStep(payrollMrsActive, MrStatus.NEW);
        long payrollReviewed    = countStep(payrollMrsActive, MrStatus.REVIEWED);
        long payrollDiCompleted = countStep(payrollMrsActive, MrStatus.DI_COMPLETED);
        long payrollGtm         = countStep(payrollMrsActive, MrStatus.GTM);
        long payrollRtm         = countStep(payrollMrsActive, MrStatus.RTM);
        long payrollMerged      = countStep(payrollMrsActive, MrStatus.MERGED);

        long booksNew         = countStep(booksMrsActive, MrStatus.NEW);
        long booksReviewed    = countStep(booksMrsActive, MrStatus.REVIEWED);
        long booksDiCompleted = countStep(booksMrsActive, MrStatus.DI_COMPLETED);
        long booksGtm         = countStep(booksMrsActive, MrStatus.GTM);
        long booksRtm         = countStep(booksMrsActive, MrStatus.RTM);
        long booksMerged      = countStep(booksMrsActive, MrStatus.MERGED);

        // ── Task history data ──────────────────────────────────────────────
        List<TaskStatusHistory> allTaskHistory = taskStatusHistoryRepo.findAllOrderByChangedAtDesc();

        Map<Long, List<TaskStatusHistory>> taskHistoryMap = allTaskHistory.stream()
                .collect(Collectors.groupingBy(h -> h.getTask().getTaskId()));

        // ── MR history data ─────────────────────────────────────────────────
        List<MrStatusHistory> allMrHistory = mrStatusHistoryRepo.findAllOrderByChangedAtDesc();
        Map<Long, List<MrStatusHistory>> mrHistoryMap = allMrHistory.stream()
                .collect(Collectors.groupingBy(h -> h.getMergeRequest().getMrSerialNumber()));

        // ── Recent task activity (last 10 task status changes) ────────────
        List<Map<String, Object>> recentTaskActivity = new ArrayList<>();
        for (TaskStatusHistory h : allTaskHistory.stream().limit(10).toList()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("entityLabel",    "Task #" + h.getTask().getTaskId());
            item.put("entityDesc",     truncate(h.getTask().getDescription(), 50));
            item.put("entityUrl",      "/tasks/edit/" + h.getTask().getTaskId());
            item.put("previousStatus", h.getPreviousStatus() != null ? h.getPreviousStatus().getDisplayName() : null);
            item.put("newStatus",      h.getNewStatus().getDisplayName());
            item.put("timeAgo",        timeAgo(h.getChangedAt()));
            recentTaskActivity.add(item);
        }

        // ── Stale tasks (active, no status change for > STALE_DAYS days) ───
        LocalDateTime staleThreshold = LocalDateTime.now().minusDays(STALE_DAYS);
        List<Map<String, Object>> staleTasks = new ArrayList<>();

        for (Task t : allTasks) {
            if (t.getStatus() == TaskStatus.DONE || t.getStatus() == TaskStatus.PAUSED) continue;
            List<TaskStatusHistory> hist = taskHistoryMap.getOrDefault(t.getTaskId(), List.of());
            LocalDateTime lastChange = hist.isEmpty() ? t.getCreatedAt() : hist.get(0).getChangedAt();
            if (lastChange != null && lastChange.isBefore(staleThreshold)) {
                long daysSince = ChronoUnit.DAYS.between(lastChange, LocalDateTime.now());
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("taskId",      t.getTaskId());
                item.put("description", truncate(t.getDescription(), 55));
                item.put("status",      t.getStatus().getDisplayName());
                item.put("statusKey",   t.getStatus().name());
                item.put("daysSince",   daysSince);
                item.put("priority",    t.getPriority().getDisplayName());
                item.put("priorityKey", t.getPriority().name());
                staleTasks.add(item);
            }
        }
        staleTasks.sort(Comparator.comparingLong(m -> -((long) m.get("daysSince"))));

        // ── Stale MRs (active non-merged, no status change for > STALE_DAYS) ───
        // Mirrors stale-task logic: last change = most recent mr_status_history row,
        // falling back to createdAt if the MR has never transitioned.
        List<Map<String, Object>> staleMrs = new ArrayList<>();
        for (MergeRequest mr : allActiveMrs) {
            if (mr.getStatus() == MrStatus.MERGED) continue;
            List<MrStatusHistory> hist = mrHistoryMap.getOrDefault(mr.getMrSerialNumber(), List.of());
            LocalDateTime lastChange = hist.isEmpty() ? mr.getCreatedAt() : hist.get(0).getChangedAt();
            if (lastChange == null) continue;
            if (lastChange.isBefore(staleThreshold)) {
                long daysSince = ChronoUnit.DAYS.between(lastChange, LocalDateTime.now());
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("mrSerialNumber", mr.getMrSerialNumber());
                item.put("mrNumber",       mr.getMrNumber());
                item.put("mrUrl",          mr.getMr());
                item.put("name",           mr.getName() != null ? mr.getName() : "");
                item.put("product",        mr.getProduct().getDisplayName());
                item.put("productKey",     mr.getProduct().name());
                item.put("stage",          deriveStageLabel(mr));
                item.put("daysSince",      daysSince);
                staleMrs.add(item);
            }
        }
        staleMrs.sort(Comparator.comparingLong(m -> -((long) m.get("daysSince"))));

        // ── MRs waiting longest to be reviewed (status still NEW) ─────────
        List<Map<String, Object>> mrsWaitingLongest = new ArrayList<>();
        for (MergeRequest mr : mrsNotReviewed) {
            LocalDateTime waitSince = mr.getCreatedAt();
            long waitDays = waitSince != null
                    ? ChronoUnit.DAYS.between(waitSince, LocalDateTime.now())
                    : -1L;
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("mrSerialNumber", mr.getMrSerialNumber());
            item.put("mrNumber",       mr.getMrNumber());
            item.put("mrUrl",          mr.getMr());
            item.put("name",           mr.getName());
            item.put("product",        mr.getProduct().getDisplayName());
            item.put("productKey",     mr.getProduct().name());
            item.put("waitDays",       waitDays);
            item.put("waitLabel",      waitDays >= 0 ? waitDays + "d" : "?");
            mrsWaitingLongest.add(item);
        }
        mrsWaitingLongest.sort((a, b) -> {
            long da = (long) a.get("waitDays"), db = (long) b.get("waitDays");
            if (da < 0 && db < 0) return 0;
            if (da < 0) return 1;
            if (db < 0) return -1;
            return Long.compare(db, da);
        });

        // ── Average time per task status (from history transitions) ───────
        Map<TaskStatus, List<Long>> statusDurations = new EnumMap<>(TaskStatus.class);
        for (TaskStatus s : TaskStatus.values()) statusDurations.put(s, new ArrayList<>());

        for (Task t : allTasks) {
            List<TaskStatusHistory> hist = taskHistoryMap.getOrDefault(t.getTaskId(), List.of());
            // reverse to get asc order for time-between-transitions
            List<TaskStatusHistory> histAsc = new ArrayList<>(hist);
            Collections.reverse(histAsc);
            for (int i = 0; i < histAsc.size() - 1; i++) {
                TaskStatus status = histAsc.get(i).getNewStatus();
                long hours = ChronoUnit.HOURS.between(
                        histAsc.get(i).getChangedAt(), histAsc.get(i + 1).getChangedAt());
                statusDurations.get(status).add(Math.max(hours, 0));
            }
            // Current status: add time from last change to now (if not DONE)
            if (!histAsc.isEmpty()) {
                TaskStatusHistory last = histAsc.get(histAsc.size() - 1);
                if (last.getNewStatus() != TaskStatus.DONE) {
                    long hours = ChronoUnit.HOURS.between(last.getChangedAt(), LocalDateTime.now());
                    statusDurations.get(last.getNewStatus()).add(Math.max(hours, 0));
                }
            }
        }

        List<Map<String, Object>> avgStatusData = new ArrayList<>();
        for (TaskStatus s : new TaskStatus[]{
                TaskStatus.YET_TO_START, TaskStatus.IDENTIFYING_ISSUE,
                TaskStatus.FIXING, TaskStatus.MR_CREATED, TaskStatus.PAUSED}) {
            List<Long> durations = statusDurations.get(s);
            double avgHours = durations.isEmpty() ? 0
                    : durations.stream().mapToLong(Long::longValue).average().orElse(0);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label",   s.getDisplayName());
            item.put("hours",   Math.round(avgHours * 10.0) / 10.0);
            item.put("display", durations.isEmpty() ? "—" : formatDuration(avgHours));
            item.put("count",   durations.size());
            avgStatusData.add(item);
        }

        // ── Average time spent in each MR pipeline stage ───────────────────
        // Mirrors avgStatusData for tasks, but driven by mr_status_history transitions
        // now that MR status is a single current-value enum (MrStatus) instead of
        // independent checklist booleans. allMrHistory/mrHistoryMap were built above
        // alongside the task history data.
        Map<MrStatus, List<Long>> mrStatusDurations = new EnumMap<>(MrStatus.class);
        for (MrStatus s : MrStatus.values()) mrStatusDurations.put(s, new ArrayList<>());

        for (MergeRequest mr : allMrs) {
            List<MrStatusHistory> hist = mrHistoryMap.getOrDefault(mr.getMrSerialNumber(), List.of());
            List<MrStatusHistory> histAsc = new ArrayList<>(hist);
            Collections.reverse(histAsc);
            for (int i = 0; i < histAsc.size() - 1; i++) {
                MrStatus status = histAsc.get(i).getNewStatus();
                long hours = ChronoUnit.HOURS.between(
                        histAsc.get(i).getChangedAt(), histAsc.get(i + 1).getChangedAt());
                mrStatusDurations.get(status).add(Math.max(hours, 0));
            }
            // Current status: time from last transition (or creation, if never transitioned) to now,
            // unless it's already MERGED (a terminal state, like DONE for tasks).
            MrStatus currentStatus = mr.getStatus();
            if (currentStatus != MrStatus.MERGED) {
                LocalDateTime since = histAsc.isEmpty() ? mr.getCreatedAt() : histAsc.get(histAsc.size() - 1).getChangedAt();
                if (since != null) {
                    long hours = ChronoUnit.HOURS.between(since, LocalDateTime.now());
                    mrStatusDurations.get(currentStatus).add(Math.max(hours, 0));
                }
            }
        }

        List<Map<String, Object>> avgMrStageData = new ArrayList<>();
        for (MrStatus s : new MrStatus[]{
                MrStatus.NEW, MrStatus.REVIEWED, MrStatus.DI_COMPLETED, MrStatus.GTM, MrStatus.RTM}) {
            List<Long> durations = mrStatusDurations.get(s);
            double avgHours = durations.isEmpty() ? 0
                    : durations.stream().mapToLong(Long::longValue).average().orElse(0);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("label",   s.getDisplayName());
            item.put("hours",   Math.round(avgHours * 10.0) / 10.0);
            item.put("display", durations.isEmpty() ? "—" : formatDuration(avgHours));
            item.put("count",   durations.size());
            avgMrStageData.add(item);
        }

        // ── Recent MR activity (last 10 MR status changes) — mirrors recentTaskActivity ──
        List<Map<String, Object>> recentMrActivity = new ArrayList<>();
        for (MrStatusHistory h : allMrHistory.stream().limit(10).toList()) {
            MergeRequest mr = h.getMergeRequest();
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("entityLabel",    mr.getProduct().getDisplayName() + " MR " + mr.getMrNumber());
            item.put("entityDesc",     mr.getName() != null ? truncate(mr.getName(), 50) : "");
            item.put("entityUrl",      "/mrs/edit/" + mr.getMrSerialNumber());
            item.put("productKey",     mr.getProduct().name());
            item.put("previousStatus", h.getPreviousStatus() != null ? h.getPreviousStatus().getDisplayName() : null);
            item.put("newStatus",      h.getNewStatus().getDisplayName());
            item.put("timeAgo",        timeAgo(h.getChangedAt()));
            recentMrActivity.add(item);
        }

        // ── Model ──────────────────────────────────────────────────────────
        // Totals
        model.addAttribute("totalTasks",       allTasks.size());
        model.addAttribute("totalMrs",              payrollMrs.size() + booksMrs.size());
        model.addAttribute("totalPayrollMrs",       payrollMrs.size());
        model.addAttribute("totalBooksMrs",         booksMrs.size());
        // active (non-canIgnore) totals for chart legend
        model.addAttribute("totalPayrollMrsActive", payrollMrsActive.size());
        model.addAttribute("totalBooksMrsActive",   booksMrsActive.size());

        // Task status counts
        model.addAttribute("yetToStart",       yetToStart);
        model.addAttribute("identifyingIssue", identifyingIssue);
        model.addAttribute("fixing",           fixing);
        model.addAttribute("mrCreated",        mrCreated);
        model.addAttribute("done",             done);
        model.addAttribute("paused",           paused);

        // Task attention
        model.addAttribute("tasksNoMr",        tasksNoMr);
        model.addAttribute("tasksDiPending",   tasksDiPending);

        // MR distribution
        model.addAttribute("payrollNew",         payrollNew);
        model.addAttribute("payrollReviewed",    payrollReviewed);
        model.addAttribute("payrollDiCompleted", payrollDiCompleted);
        model.addAttribute("payrollGtm",         payrollGtm);
        model.addAttribute("payrollRtm",         payrollRtm);
        model.addAttribute("payrollMerged",      payrollMerged);
        model.addAttribute("booksNew",         booksNew);
        model.addAttribute("booksReviewed",    booksReviewed);
        model.addAttribute("booksDiCompleted", booksDiCompleted);
        model.addAttribute("booksGtm",         booksGtm);
        model.addAttribute("booksRtm",         booksRtm);
        model.addAttribute("booksMerged",      booksMerged);

        // MR attention
        model.addAttribute("mrsNotReviewed",  mrsNotReviewed);
        model.addAttribute("mrsNotMerged",    mrsNotMerged);
        model.addAttribute("mrsReadyForGtm",  mrsReadyForGtm);
        model.addAttribute("mrsReadyForRtm",  mrsReadyForRtm);

        // New components
        model.addAttribute("recentTaskActivity", recentTaskActivity);
        model.addAttribute("staleTasks",         staleTasks);
        model.addAttribute("staleMrs",           staleMrs);
        model.addAttribute("mrsWaitingLongest",  mrsWaitingLongest);
        model.addAttribute("avgStatusData",      avgStatusData);
        model.addAttribute("avgMrStageData",     avgMrStageData);
        model.addAttribute("recentMrActivity",   recentMrActivity);

        return "dashboard";
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /** Counts MRs whose current status has reached or passed the given pipeline stage. */
    private long countStep(List<MergeRequest> mrs, MrStatus stage) {
        return mrs.stream().filter(mr -> mr.getStatus().ordinal() >= stage.ordinal()).count();
    }

    /** Human-readable label for the MR's current pipeline stage. */
    private String deriveStageLabel(MergeRequest mr) {
        return mr.getStatus().getDisplayName();
    }

    private String timeAgo(LocalDateTime dt) {
        if (dt == null) return "?";
        long minutes = ChronoUnit.MINUTES.between(dt, LocalDateTime.now());
        if (minutes < 1)  return "just now";
        if (minutes < 60) return minutes + "m ago";
        long hours = ChronoUnit.HOURS.between(dt, LocalDateTime.now());
        if (hours < 24)   return hours + "h ago";
        long days = ChronoUnit.DAYS.between(dt, LocalDateTime.now());
        return days + "d ago";
    }

    private String formatDuration(double hours) {
        if (hours < 1)  return "< 1h";
        if (hours < 24) return Math.round(hours) + "h";
        double days = hours / 24.0;
        if (days < 7)   return String.format("%.1fd", days);
        return Math.round(days / 7) + "w";
    }

    private String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max - 1) + "…";
    }
}
