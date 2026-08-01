package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.enums.Product;
import com.manoj.tasksmr.enums.TaskStatus;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import com.manoj.tasksmr.model.TaskStatusHistory;
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
                .filter(t -> t.getPayrollMr() == null && t.getBooksMr() == null)
                .toList();

        // DI pending = at least one MR not yet having stepDiCompleted checked
        List<Task> tasksDiPending = allTasks.stream()
                .filter(t -> t.getStatus() != TaskStatus.DONE && t.getStatus() != TaskStatus.PAUSED)
                .filter(t -> t.getPayrollMr() != null || t.getBooksMr() != null)
                .filter(t -> (t.getPayrollMr() != null && !Boolean.TRUE.equals(t.getPayrollMr().getStepDiCompleted()))
                          || (t.getBooksMr()   != null && !Boolean.TRUE.equals(t.getBooksMr().getStepDiCompleted())))
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

        // Attention blocks — based on step booleans
        List<MergeRequest> mrsNotReviewed = allActiveMrs.stream()
                .filter(mr -> !Boolean.TRUE.equals(mr.getStepWaiting())).toList();
        List<MergeRequest> mrsReadyForGtm = allActiveMrs.stream()
                .filter(mr -> Boolean.TRUE.equals(mr.getStepDiCompleted()) && !Boolean.TRUE.equals(mr.getStepGtm())).toList();
        List<MergeRequest> mrsReadyForRtm = allActiveMrs.stream()
                .filter(mr -> Boolean.TRUE.equals(mr.getStepGtm()) && !Boolean.TRUE.equals(mr.getStepRtm())).toList();
        List<MergeRequest> mrsNotMerged   = allActiveMrs.stream()
                .filter(mr -> !Boolean.TRUE.equals(mr.getStepMerged())).toList();

        // MR pipeline step counts — canIgnore excluded (how many MRs have each step checked)
        long payrollWaiting     = countStep(payrollMrsActive, "stepWaiting");
        long payrollReviewed    = countStep(payrollMrsActive, "stepReviewed");
        long payrollDiScheduled = countStep(payrollMrsActive, "stepDiScheduled");
        long payrollDiCompleted = countStep(payrollMrsActive, "stepDiCompleted");
        long payrollGtm         = countStep(payrollMrsActive, "stepGtm");
        long payrollRtm         = countStep(payrollMrsActive, "stepRtm");
        long payrollMerged      = countStep(payrollMrsActive, "stepMerged");

        long booksWaiting     = countStep(booksMrsActive, "stepWaiting");
        long booksReviewed    = countStep(booksMrsActive, "stepReviewed");
        long booksDiScheduled = countStep(booksMrsActive, "stepDiScheduled");
        long booksDiCompleted = countStep(booksMrsActive, "stepDiCompleted");
        long booksGtm         = countStep(booksMrsActive, "stepGtm");
        long booksRtm         = countStep(booksMrsActive, "stepRtm");
        long booksMerged      = countStep(booksMrsActive, "stepMerged");

        // ── Task history data ──────────────────────────────────────────────
        List<TaskStatusHistory> allTaskHistory = taskStatusHistoryRepo.findAllOrderByChangedAtDesc();

        Map<Long, List<TaskStatusHistory>> taskHistoryMap = allTaskHistory.stream()
                .collect(Collectors.groupingBy(h -> h.getTask().getTaskId()));

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

        // ── Stale MRs (active non-merged, no toggle > STALE_DAYS) ─────────
        // Uses lastModifiedAt (updated on every toggle); falls back to createdAt for legacy rows.
        List<Map<String, Object>> staleMrs = new ArrayList<>();
        for (MergeRequest mr : allActiveMrs) {
            if (Boolean.TRUE.equals(mr.getStepMerged())) continue;
            LocalDateTime lastChange = mr.getLastModifiedAt() != null
                    ? mr.getLastModifiedAt()
                    : mr.getCreatedAt();
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

        // ── MRs waiting longest for thumbs up (stepWaiting not checked) ───
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
        model.addAttribute("payrollWaiting",     payrollWaiting);
        model.addAttribute("payrollReviewed",    payrollReviewed);
        model.addAttribute("payrollDiScheduled", payrollDiScheduled);
        model.addAttribute("payrollDiCompleted", payrollDiCompleted);
        model.addAttribute("payrollGtm",         payrollGtm);
        model.addAttribute("payrollRtm",         payrollRtm);
        model.addAttribute("payrollMerged",      payrollMerged);
        model.addAttribute("booksWaiting",     booksWaiting);
        model.addAttribute("booksReviewed",    booksReviewed);
        model.addAttribute("booksDiScheduled", booksDiScheduled);
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

        return "dashboard";
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private long countStep(List<MergeRequest> mrs, String step) {
        return switch (step) {
            case "stepWaiting"     -> mrs.stream().filter(mr -> Boolean.TRUE.equals(mr.getStepWaiting())).count();
            case "stepReviewed"    -> mrs.stream().filter(mr -> Boolean.TRUE.equals(mr.getStepReviewed())).count();
            case "stepDiScheduled" -> mrs.stream().filter(mr -> Boolean.TRUE.equals(mr.getStepDiScheduled())).count();
            case "stepDiCompleted" -> mrs.stream().filter(mr -> Boolean.TRUE.equals(mr.getStepDiCompleted())).count();
            case "stepGtm"         -> mrs.stream().filter(mr -> Boolean.TRUE.equals(mr.getStepGtm())).count();
            case "stepRtm"         -> mrs.stream().filter(mr -> Boolean.TRUE.equals(mr.getStepRtm())).count();
            case "stepMerged"      -> mrs.stream().filter(mr -> Boolean.TRUE.equals(mr.getStepMerged())).count();
            default -> 0L;
        };
    }

    /** Derives a human-readable pipeline stage from the highest checked step boolean. */
    private String deriveStageLabel(MergeRequest mr) {
        if (Boolean.TRUE.equals(mr.getStepMerged()))      return "Merged";
        if (Boolean.TRUE.equals(mr.getStepRtm()))         return "RTM Obtained";
        if (Boolean.TRUE.equals(mr.getStepGtm()))         return "GTM Obtained";
        if (Boolean.TRUE.equals(mr.getStepDiCompleted())) return "DI Completed";
        if (Boolean.TRUE.equals(mr.getStepDiScheduled())) return "DI Scheduled";
        if (Boolean.TRUE.equals(mr.getStepReviewed()))    return "Reviewed";
        if (Boolean.TRUE.equals(mr.getStepWaiting()))     return "Waiting (Thumbs Up)";
        return "Not Started";
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
