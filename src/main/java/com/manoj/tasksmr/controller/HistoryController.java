package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.enums.DeploymentStatus;
import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.enums.Product;
import com.manoj.tasksmr.enums.TaskStatus;
import com.manoj.tasksmr.model.DeploymentStatusHistory;
import com.manoj.tasksmr.model.MrStatusHistory;
import com.manoj.tasksmr.model.TaskStatusHistory;
import com.manoj.tasksmr.repository.DeploymentStatusHistoryRepository;
import com.manoj.tasksmr.repository.MrStatusHistoryRepository;
import com.manoj.tasksmr.repository.TaskStatusHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Objects;
import java.util.stream.Stream;

@Controller
@RequiredArgsConstructor
public class HistoryController {

    private final TaskStatusHistoryRepository       taskStatusHistoryRepo;
    private final MrStatusHistoryRepository         mrStatusHistoryRepo;
    private final DeploymentStatusHistoryRepository deploymentStatusHistoryRepo;

    private static final int PAGE_SIZE = 25;

    @GetMapping("/history")
    public String history(
            @RequestParam(defaultValue = "tasks") String tab,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(required = false) Long   taskId,
            @RequestParam(required = false) String prevStatus,
            @RequestParam(required = false) String newStatus,
            @RequestParam(required = false) Long   mrId,
            @RequestParam(required = false) String product,
            @RequestParam(required = false) String prevMrStatus,
            @RequestParam(required = false) String newMrStatus,
            @RequestParam(required = false) String prevDeployStatus,
            @RequestParam(required = false) String newDeployStatus,
            @RequestParam(required = false) String mrName,
            @RequestParam(required = false) String taskDescription,
            Model model) {

        if ("mrs".equals(tab)) {
            return mrHistory(page, mrId, product, prevMrStatus, newMrStatus, mrName, model);
        }
        if ("deployment".equals(tab)) {
            return deploymentHistory(page, mrId, product, prevDeployStatus, newDeployStatus, mrName, model);
        }
        return taskHistory(page, taskId, prevStatus, newStatus, taskDescription, model);
    }

    private String taskHistory(int page, Long taskId, String prevStatus, String newStatus, String taskDescription, Model model) {
        TaskStatus prev = parseEnum(TaskStatus.class, prevStatus);
        TaskStatus next = parseEnum(TaskStatus.class, newStatus);
        String     desc = normalize(taskDescription);

        Stream<TaskStatusHistory> stream = taskStatusHistoryRepo.findAllOrderByChangedAtDesc().stream();
        if (taskId != null) stream = stream.filter(h -> Objects.equals(h.getTask().getTaskId(), taskId));
        if (prev   != null) stream = stream.filter(h -> h.getPreviousStatus() == prev);
        if (next   != null) stream = stream.filter(h -> h.getNewStatus()      == next);
        if (desc   != null) stream = stream.filter(h -> containsIgnoreCase(h.getTask().getDescription(), desc));
        List<TaskStatusHistory> filtered = stream.toList();

        addPageAttrs(model, filtered, page);
        model.addAttribute("taskHistory",      slice(filtered, page));
        model.addAttribute("taskStatusValues", TaskStatus.values());
        model.addAttribute("taskId",           taskId);
        model.addAttribute("tab",        "tasks");
        model.addAttribute("prevStatus", prevStatus);
        model.addAttribute("newStatus",  newStatus);
        model.addAttribute("taskDescription", taskDescription);
        return "history/list";
    }

    private String mrHistory(int page, Long mrId, String product, String prevMrStatus, String newMrStatus, String mrName, Model model) {
        MrStatus prev = parseEnum(MrStatus.class, prevMrStatus);
        MrStatus next = parseEnum(MrStatus.class, newMrStatus);
        Product  prod = parseEnum(Product.class, product);
        String   name = normalize(mrName);

        Stream<MrStatusHistory> stream = mrStatusHistoryRepo.findAllOrderByChangedAtDesc().stream();
        if (mrId != null) stream = stream.filter(h -> h.getMergeRequest().getMr().contains(Long.toString(mrId)));
        if (prod != null) stream = stream.filter(h -> h.getMergeRequest().getProduct() == prod);
        if (prev != null) stream = stream.filter(h -> h.getPreviousStatus() == prev);
        if (next != null) stream = stream.filter(h -> h.getNewStatus()      == next);
        if (name != null) stream = stream.filter(h -> containsIgnoreCase(h.getMergeRequest().getName(), name));
        List<MrStatusHistory> filtered = stream.toList();

        addPageAttrs(model, filtered, page);
        model.addAttribute("mrHistory",      slice(filtered, page));
        model.addAttribute("mrStatusValues", MrStatus.values());
        model.addAttribute("products",       Product.values());
        model.addAttribute("mrId",           mrId);
        model.addAttribute("tab",          "mrs");
        model.addAttribute("product",      product);
        model.addAttribute("prevMrStatus", prevMrStatus);
        model.addAttribute("newMrStatus",  newMrStatus);
        model.addAttribute("mrName",       mrName);
        return "history/list";
    }

    private String deploymentHistory(int page, Long mrId, String product, String prevDeployStatus, String newDeployStatus, String mrName, Model model) {
        DeploymentStatus prev = parseEnum(DeploymentStatus.class, prevDeployStatus);
        DeploymentStatus next = parseEnum(DeploymentStatus.class, newDeployStatus);
        Product          prod = parseEnum(Product.class, product);
        String           name = normalize(mrName);

        Stream<DeploymentStatusHistory> stream = deploymentStatusHistoryRepo.findAllOrderByChangedAtDesc().stream();
        if (mrId != null) stream = stream.filter(h -> h.getMergeRequest().getMr().contains(Long.toString(mrId)));
        if (prod != null) stream = stream.filter(h -> h.getMergeRequest().getProduct() == prod);
        if (prev != null) stream = stream.filter(h -> h.getPreviousStatus() == prev);
        if (next != null) stream = stream.filter(h -> h.getNewStatus()      == next);
        if (name != null) stream = stream.filter(h -> containsIgnoreCase(h.getMergeRequest().getName(), name));
        List<DeploymentStatusHistory> filtered = stream.toList();

        addPageAttrs(model, filtered, page);
        model.addAttribute("deploymentHistory",      slice(filtered, page));
        model.addAttribute("deploymentStatusValues", DeploymentStatus.values());
        model.addAttribute("products",               Product.values());
        model.addAttribute("mrId",             mrId);
        model.addAttribute("tab",              "deployment");
        model.addAttribute("product",          product);
        model.addAttribute("prevDeployStatus", prevDeployStatus);
        model.addAttribute("newDeployStatus",  newDeployStatus);
        model.addAttribute("mrName",           mrName);
        return "history/list";
    }

    private <T> List<T> slice(List<T> list, int page) {
        int start = page * PAGE_SIZE;
        int end   = Math.min(start + PAGE_SIZE, list.size());
        return start < list.size() ? list.subList(start, end) : List.of();
    }

    private void addPageAttrs(Model model, List<?> filtered, int page) {
        int total      = filtered.size();
        int totalPages = total == 0 ? 1 : (int) Math.ceil((double) total / PAGE_SIZE);
        model.addAttribute("currentPage",   page);
        model.addAttribute("totalPages",    totalPages);
        model.addAttribute("totalElements", total);
    }

    private <E extends Enum<E>> E parseEnum(Class<E> type, String value) {
        if (value == null || value.isBlank()) return null;
        try { return Enum.valueOf(type, value); }
        catch (IllegalArgumentException e) { return null; }
    }

    /** Trims and lower-cases a filter value, or returns null if blank (meaning "no filter"). */
    private String normalize(String value) {
        return (value == null || value.isBlank()) ? null : value.trim().toLowerCase();
    }

    /** Case-insensitive substring match; false if haystack is null. needle is expected pre-lowercased. */
    private boolean containsIgnoreCase(String haystack, String needle) {
        return haystack != null && haystack.toLowerCase().contains(needle);
    }
}
