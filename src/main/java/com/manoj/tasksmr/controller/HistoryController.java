package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.enums.Product;
import com.manoj.tasksmr.enums.TaskStatus;
import com.manoj.tasksmr.model.MrStatusHistory;
import com.manoj.tasksmr.model.TaskStatusHistory;
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

    private final TaskStatusHistoryRepository taskStatusHistoryRepo;
    private final MrStatusHistoryRepository   mrStatusHistoryRepo;

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
            Model model) {

        if ("mrs".equals(tab)) {
            return mrHistory(page, mrId, product, prevMrStatus, newMrStatus, model);
        }
        return taskHistory(page, taskId, prevStatus, newStatus, model);
    }

    private String taskHistory(int page, Long taskId, String prevStatus, String newStatus, Model model) {
        TaskStatus prev = parseEnum(TaskStatus.class, prevStatus);
        TaskStatus next = parseEnum(TaskStatus.class, newStatus);

        Stream<TaskStatusHistory> stream = taskStatusHistoryRepo.findAllOrderByChangedAtDesc().stream();
        if (taskId != null) stream = stream.filter(h -> Objects.equals(h.getTask().getTaskId(), taskId));
        if (prev   != null) stream = stream.filter(h -> h.getPreviousStatus() == prev);
        if (next   != null) stream = stream.filter(h -> h.getNewStatus()      == next);
        List<TaskStatusHistory> filtered = stream.toList();

        addPageAttrs(model, filtered, page);
        model.addAttribute("taskHistory",      slice(filtered, page));
        model.addAttribute("taskStatusValues", TaskStatus.values());
        model.addAttribute("taskId",           taskId);
        model.addAttribute("tab",        "tasks");
        model.addAttribute("prevStatus", prevStatus);
        model.addAttribute("newStatus",  newStatus);
        return "history/list";
    }

    private String mrHistory(int page, Long mrId, String product, String prevMrStatus, String newMrStatus, Model model) {
        MrStatus prev = parseEnum(MrStatus.class, prevMrStatus);
        MrStatus next = parseEnum(MrStatus.class, newMrStatus);
        Product  prod = parseEnum(Product.class, product);

        Stream<MrStatusHistory> stream = mrStatusHistoryRepo.findAllOrderByChangedAtDesc().stream();
        if (mrId != null) stream = stream.filter(h -> Objects.equals(h.getMergeRequest().getMrSerialNumber(), mrId));
        if (prod != null) stream = stream.filter(h -> h.getMergeRequest().getProduct() == prod);
        if (prev != null) stream = stream.filter(h -> h.getPreviousStatus() == prev);
        if (next != null) stream = stream.filter(h -> h.getNewStatus()      == next);
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
}
