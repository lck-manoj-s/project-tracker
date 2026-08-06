package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import com.manoj.tasksmr.service.MrService;
import com.manoj.tasksmr.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Backs the global navbar search box. Searches across ALL tasks and MRs regardless of
 * status/merge state (unlike the list pages, which default to hiding completed/merged
 * items) — reuses the existing unfiltered {@link TaskService#getAllTasks()} and
 * {@link MrService#getAllMrs()} accessors and matches in memory, which is fine at this
 * app's scale.
 */
@RestController
@RequiredArgsConstructor
public class SearchController {

    private static final int MAX_RESULTS = 20;

    private final TaskService taskService;
    private final MrService   mrService;

    @GetMapping("/search")
    public Map<String, Object> search(@RequestParam(required = false) String q) {
        List<Map<String, Object>> results = new ArrayList<>();
        Map<String, Object> response = new HashMap<>();
        response.put("results", results);

        if (q == null || q.isBlank()) {
            return response;
        }
        String needle = q.trim().toLowerCase();

        for (Task t : taskService.getAllTasks()) {
            if (results.size() >= MAX_RESULTS) break;
            if (matchesTask(t, needle)) {
                results.add(taskResult(t));
            }
        }

        for (MergeRequest mr : mrService.getAllMrs()) {
            if (results.size() >= MAX_RESULTS) break;
            if (matchesMr(mr, needle)) {
                results.add(mrResult(mr));
            }
        }

        return response;
    }

    private boolean matchesTask(Task t, String needle) {
        return (t.getTaskId() != null && String.valueOf(t.getTaskId()).contains(needle))
                || containsIgnoreCase(t.getDescription(), needle);
    }

    private boolean matchesMr(MergeRequest mr, String needle) {
        return containsIgnoreCase(mr.getMrNumber(), needle)
                || containsIgnoreCase(mr.getName(), needle)
                || containsIgnoreCase(mr.getMr(), needle);
    }

    private boolean containsIgnoreCase(String haystack, String needle) {
        return haystack != null && haystack.toLowerCase().contains(needle);
    }

    private Map<String, Object> taskResult(Task t) {
        Map<String, Object> m = new HashMap<>();
        m.put("type",     "task");
        m.put("id",       t.getTaskId());
        m.put("label",    "Task #" + t.getTaskId() + " — " + truncate(t.getDescription(), 70));
        m.put("sublabel", t.getStatus() != null ? t.getStatus().getDisplayName() : "");
        m.put("url",      "/tasks/edit/" + t.getTaskId());
        return m;
    }

    private Map<String, Object> mrResult(MergeRequest mr) {
        Map<String, Object> m = new HashMap<>();
        String label = "MR " + mr.getMrNumber();
        if (mr.getName() != null && !mr.getName().isBlank()) {
            label += " — " + truncate(mr.getName(), 60);
        }
        String sublabel = (mr.getProduct() != null ? mr.getProduct().getDisplayName() : "")
                + (mr.getStatus() != null ? " · " + mr.getStatus().getDisplayName() : "");

        m.put("type",     "mr");
        m.put("id",       mr.getMrSerialNumber());
        m.put("label",    label);
        m.put("sublabel", sublabel);
        m.put("url",      "/mrs/edit/" + mr.getMrSerialNumber());
        return m;
    }

    private String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() > max ? s.substring(0, max) + "…" : s;
    }
}
