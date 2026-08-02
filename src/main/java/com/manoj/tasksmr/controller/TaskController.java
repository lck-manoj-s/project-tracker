package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.dto.TaskFilterDTO;
import com.manoj.tasksmr.dto.TaskSaveResult;
import com.manoj.tasksmr.enums.Priority;
import com.manoj.tasksmr.enums.TaskStatus;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.model.Task;
import com.manoj.tasksmr.service.MrService;
import com.manoj.tasksmr.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;
    private final MrService   mrService;

    private static final int PAGE_SIZE = 10;

    @GetMapping
    public String listActiveTasks(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String priority,
            @RequestParam(required = false) String mrPresence,
            @RequestParam(required = false) String allDiCompleted,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listTasksForTab("active", status, priority, mrPresence, allDiCompleted, page, model);
    }

    @GetMapping("/completed")
    public String listCompletedTasks(
            @RequestParam(required = false) String priority,
            @RequestParam(required = false) String mrPresence,
            @RequestParam(required = false) String allDiCompleted,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listTasksForTab("completed", null, priority, mrPresence, allDiCompleted, page, model);
    }

    private String listTasksForTab(String tab, String status, String priority,
            String mrPresence, String allDiCompleted, int page, Model model) {

        TaskFilterDTO filter = new TaskFilterDTO();
        if ("completed".equals(tab)) {
            filter.setStatus(TaskStatus.DONE);
        } else {
            // Active tab: null/empty = all non-Done; specific value = exact status
            if (status == null || status.isEmpty()) {
                filter.setExcludeDone(true);
            } else {
                filter.setStatus(TaskStatus.valueOf(status));
            }
        }
        if (priority != null && !priority.isEmpty())          filter.setPriority(Priority.valueOf(priority));
        if (mrPresence != null && !mrPresence.isEmpty())      filter.setMrPresence(mrPresence);
        if (allDiCompleted != null && !allDiCompleted.isEmpty()) filter.setAllDiCompleted(Boolean.valueOf(allDiCompleted));

        Page<Task> taskPage = taskService.getFilteredTasks(filter, PageRequest.of(page, PAGE_SIZE));

        // Active tab: status options exclude DONE. Completed tab: no status filter shown.
        TaskStatus[] statusOptions = "active".equals(tab)
                ? Arrays.stream(TaskStatus.values())
                        .filter(s -> s != TaskStatus.DONE)
                        .toArray(TaskStatus[]::new)
                : new TaskStatus[0];

        model.addAttribute("tasks",                  taskPage.getContent());
        model.addAttribute("currentPage",            taskPage.getNumber());
        model.addAttribute("totalPages",             taskPage.getTotalPages());
        model.addAttribute("totalElements",          taskPage.getTotalElements());
        model.addAttribute("tab",                    tab);
        model.addAttribute("baseUrl",                "completed".equals(tab) ? "/tasks/completed" : "/tasks");
        model.addAttribute("taskStatuses",           statusOptions);
        model.addAttribute("priorities",             Priority.values());
        model.addAttribute("selectedStatus",         status);
        model.addAttribute("selectedPriority",       priority);
        model.addAttribute("selectedMrPresence",     mrPresence);
        model.addAttribute("selectedAllDiCompleted", allDiCompleted);

        return "tasks/list";
    }

    @GetMapping("/new")
    public String newTaskForm(Model model) {
        populateFormModel(model, new Task(), false);
        // errorMessage may be present as a flash attribute from a failed save
        return "tasks/form";
    }

    @GetMapping("/edit/{id}")
    public String editTaskForm(@PathVariable Long id, Model model) {
        Task task = taskService.getTaskById(id)
                .orElseThrow(() -> new IllegalArgumentException("Task not found: " + id));
        populateFormModel(model, task, true);
        return "tasks/form";
    }

    /**
     * Save task. MRs are submitted as a list of ids (mrIds) — any number, any product mix —
     * rather than via @ModelAttribute binding, since Spring cannot auto-resolve entity FK
     * collections from plain numeric form values without a custom converter.
     */
    @PostMapping("/save")
    public String saveTask(
            @ModelAttribute Task task,
            @RequestParam(required = false) List<Long> mrIds,
            RedirectAttributes ra) {

        TaskSaveResult result = taskService.saveTaskWithMrs(task, mrIds);

        if (result.hasErrors()) {
            ra.addFlashAttribute("errorMessage", String.join(" ", result.errors()));
            String redirect = task.getTaskId() != null
                    ? "redirect:/tasks/edit/" + task.getTaskId()
                    : "redirect:/tasks/new";
            return redirect;
        }

        return "redirect:/tasks";
    }

    @PostMapping("/delete/{id}")
    public String deleteTask(@PathVariable Long id) {
        taskService.deleteTask(id);
        return "redirect:/tasks";
    }

    /**
     * JSON endpoint for the inline MR panel.
     * Returns all MRs linked to a given task (any product, any count).
     */
    @GetMapping("/{id}/mrs")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getTaskMrs(@PathVariable Long id) {
        Task task = taskService.getTaskById(id)
                .orElseThrow(() -> new IllegalArgumentException("Task not found: " + id));

        Map<String, Object> response = new HashMap<>();
        response.put("taskId",      task.getTaskId());
        response.put("description", task.getDescription());
        response.put("mrs", task.getMergeRequests() == null ? List.of()
                : task.getMergeRequests().stream().map(this::mrToMap).toList());
        return ResponseEntity.ok(response);
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private void populateFormModel(Model model, Task task, boolean isEdit) {
        // All MRs available for selection: unassigned MRs, plus any already linked to this task.
        List<MergeRequest> allMrs = mrService.getFilteredMrs(new MrFilterDTO());
        List<MergeRequest> availableMrs = allMrs.stream()
                .filter(mr -> mr.getTask() == null
                        || (task.getTaskId() != null && mr.getTask().getTaskId().equals(task.getTaskId())))
                .toList();

        model.addAttribute("task",         task);
        model.addAttribute("taskStatuses", TaskStatus.values());
        model.addAttribute("priorities",   Priority.values());
        model.addAttribute("availableMrs", availableMrs);
        model.addAttribute("isEdit",       isEdit);
    }

    /** Converts a MergeRequest to a plain Map for JSON serialisation in the panel endpoint. */
    private Map<String, Object> mrToMap(MergeRequest mr) {
        if (mr == null) return null;
        Map<String, Object> m = new HashMap<>();
        m.put("mrSerialNumber",  mr.getMrSerialNumber());
        m.put("mrNumber",        mr.getMrNumber());
        m.put("mr",              mr.getMr());
        m.put("name",            mr.getName());
        m.put("product",         mr.getProduct().getDisplayName());
        m.put("mrLinked",        mr.getMrLinked().getDisplayName());
        m.put("createdAt",       mr.getCreatedAt() != null ? mr.getCreatedAt().toString().substring(0, 16).replace('T', ' ') : null);
        m.put("stepNew",         mr.getStepNew());
        m.put("stepReviewed",    mr.getStepReviewed());
        m.put("stepDiCompleted", mr.getStepDiCompleted());
        m.put("stepGtm",         mr.getStepGtm());
        m.put("stepRtm",         mr.getStepRtm());
        m.put("stepMerged",      mr.getStepMerged());
        return m;
    }
}
