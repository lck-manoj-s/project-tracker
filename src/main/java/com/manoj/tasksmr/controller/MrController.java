package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.enums.MrLinked;
import com.manoj.tasksmr.enums.MrStatus;
import com.manoj.tasksmr.enums.Product;
import com.manoj.tasksmr.model.MergeRequest;
import com.manoj.tasksmr.service.MrService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.propertyeditors.StringTrimmerEditor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;

import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Map;
import java.util.Set;
import java.util.List;


@Controller
@RequestMapping("/mrs")
@RequiredArgsConstructor
public class MrController {

    private final MrService mrService;

    /** Convert empty strings to null — prevents ConversionFailedException on empty enum selects */
    @InitBinder
    public void initBinder(WebDataBinder binder) {
        binder.registerCustomEditor(String.class, new StringTrimmerEditor(true));
    }

    private static final int MR_PAGE_SIZE = 10;

    /** /mrs → redirect to Payroll tab */
    @GetMapping
    public String redirectToPayroll() {
        return "redirect:/mrs/payroll";
    }

    @GetMapping("/payroll")
    public String listPayrollMrs(
            @RequestParam(required = false) String hasParentMr,
            @RequestParam(required = false) String parentMrProduct,
            @RequestParam(required = false) String mrLinked,
            @RequestParam(required = false) String merged,
            @RequestParam(required = false) String canIgnore,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listMrsForProduct(Product.PAYROLL, "/mrs/payroll",
                hasParentMr, parentMrProduct, mrLinked, merged,
                canIgnore, page, model);
    }

    @GetMapping("/books")
    public String listBooksMrs(
            @RequestParam(required = false) String hasParentMr,
            @RequestParam(required = false) String parentMrProduct,
            @RequestParam(required = false) String mrLinked,
            @RequestParam(required = false) String merged,
            @RequestParam(required = false) String canIgnore,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listMrsForProduct(Product.BOOKS, "/mrs/books",
                hasParentMr, parentMrProduct, mrLinked, merged,
                canIgnore, page, model);
    }

    private String listMrsForProduct(Product product, String baseUrl,
            String hasParentMr, String parentMrProduct, String mrLinked,
            String merged,
            String canIgnore, int page, Model model) {

        // Default canIgnore to "false" (exclude canIgnore MRs); "all" means no filter
        String effectiveCanIgnore = notBlank(canIgnore) ? canIgnore : "false";
        // Default merged to "false" (show only active/non-merged); "all" = no filter; "true" = merged only
        String effectiveMerged = notBlank(merged) ? merged : "false";

        MrFilterDTO filter = buildFilter(product,
                hasParentMr, parentMrProduct, mrLinked, effectiveMerged,
                effectiveCanIgnore);

        Page<MergeRequest> mrPage = mrService.getFilteredMrsPaged(filter, page, MR_PAGE_SIZE);

        model.addAttribute("mrs",           mrPage.getContent());
        model.addAttribute("currentPage",   mrPage.getNumber());
        model.addAttribute("totalPages",    mrPage.getTotalPages());
        model.addAttribute("totalElements", mrPage.getTotalElements());

        model.addAttribute("product",        product);
        model.addAttribute("baseUrl",        baseUrl);
        model.addAttribute("mrLinkedValues", MrLinked.values());
        model.addAttribute("products",       Product.values());

        model.addAttribute("hasParentMr",     hasParentMr);
        model.addAttribute("parentMrProduct", parentMrProduct);
        model.addAttribute("mrLinked",        mrLinked);
        model.addAttribute("merged",          effectiveMerged);
        model.addAttribute("canIgnore",       effectiveCanIgnore);

        return "mr/list";
    }

    @GetMapping("/new")
    public String newMrForm(Model model) {
        populateFormModel(model, new MergeRequest(), false);
        return "mr/form";
    }

    @GetMapping("/edit/{id}")
    public String editMrForm(@PathVariable Long id, Model model) {
        MergeRequest mr = mrService.getMrById(id)
                .orElseThrow(() -> new IllegalArgumentException("MR not found: " + id));
        populateFormModel(model, mr, true);
        return "mr/form";
    }

    /**
     * Save MR. Note: {@code form} is a fresh object bound only from this form's fields —
     * it does NOT carry status, task link, or step history, so in edit mode we apply the
     * form fields onto the persisted entity rather than saving {@code form} directly.
     * Otherwise every edit (e.g. changing the URL) would silently reset the MR's pipeline
     * stage back to NEW and unlink it from its task.
     */
    @PostMapping("/save")
    public String saveMr(
            @ModelAttribute MergeRequest form,
            @RequestParam(required = false) Long parentMrId,
            RedirectAttributes ra) {

        // Duplicate URL check
        if (form.getMr() != null && !form.getMr().isBlank()) {
            mrService.findByUrl(form.getMr().trim()).ifPresent(existing -> {
                if (!existing.getMrSerialNumber().equals(form.getMrSerialNumber())) {
                    ra.addFlashAttribute("errorMessage",
                        "MR URL already exists (MR #" + existing.getMrSerialNumber() + "). Please use a unique URL.");
                }
            });
        }

        if (ra.getFlashAttributes().containsKey("errorMessage")) {
            String redirect = form.getMrSerialNumber() != null
                    ? "redirect:/mrs/edit/" + form.getMrSerialNumber()
                    : "redirect:/mrs/new";
            return redirect;
        }

        MergeRequest mr = form.getMrSerialNumber() != null
                ? mrService.getMrById(form.getMrSerialNumber()).orElse(form)
                : form;

        mr.setMr(form.getMr());
        mr.setName(form.getName());
        mr.setProduct(form.getProduct());
        mr.setCanIgnore(form.getCanIgnore());
        mr.setMrLinked(form.getMrLinked());
        mr.setParentMr(parentMrId != null ? mrService.getMrById(parentMrId).orElse(null) : null);

        MergeRequest saved = mrService.saveMr(mr);
        return "redirect:/mrs/" + saved.getProduct().name().toLowerCase();
    }

    @PostMapping("/delete/{id}")
    public String deleteMr(@PathVariable Long id) {
        String product = mrService.getMrById(id)
                .map(mr -> mr.getProduct().name().toLowerCase())
                .orElse("payroll");
        mrService.deleteMr(id);
        return "redirect:/mrs/" + product;
    }

    private static final Set<String> PLAIN_TOGGLE_FIELDS = Set.of("canIgnore");

    /**
     * Inline boolean toggle for deployment/canIgnore flags — called via AJAX.
     * Returns {field, newValue}. Pipeline stage changes go through /status/{status} instead.
     */
    @PostMapping("/{id}/toggle/{field}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> toggleField(
            @PathVariable Long id,
            @PathVariable String field) {

        if (!PLAIN_TOGGLE_FIELDS.contains(field)) {
            return ResponseEntity.badRequest().build();
        }

        MergeRequest mr = mrService.getMrById(id)
                .orElseThrow(() -> new IllegalArgumentException("MR not found: " + id));
        boolean newValue = doToggle(mr, field);
        mrService.saveMr(mr);

        Map<String, Object> response = new HashMap<>();
        response.put("field",    field);
        response.put("newValue", newValue);
        return ResponseEntity.ok(response);
    }

    /**
     * Sets the MR's pipeline stage directly (clicking any stage badge in the pipeline UI
     * jumps to that stage — forward or backward). Records the transition in mr_status_history
     * for per-stage duration tracking. Returns the resulting status (name + display label).
     */
    @PostMapping("/{id}/status/{status}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> setStatus(
            @PathVariable Long id,
            @PathVariable String status) {

        MrStatus target;
        try {
            target = MrStatus.valueOf(status);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }

        MrStatus newStatus = mrService.updateStatus(id, target);

        Map<String, Object> response = new HashMap<>();
        response.put("status",      newStatus.name());
        response.put("displayName", newStatus.getDisplayName());
        return ResponseEntity.ok(response);
    }

    /**
     * JSON endpoint for the inline parent-chain panel — mirrors the task page's
     * per-task MR panel. Returns the given MR plus every ancestor MR (parentMr,
     * parentMr.parentMr, ...), ordered oldest-ancestor-first so the clicked MR
     * is always the last (rightmost) column.
     */
    @GetMapping("/{id}/chain")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getMrChain(@PathVariable Long id) {
        MergeRequest mr = mrService.getMrById(id)
                .orElseThrow(() -> new IllegalArgumentException("MR not found: " + id));

        LinkedList<Map<String, Object>> chain = new LinkedList<>();
        Set<Long> seen = new HashSet<>();
        MergeRequest current = mr;
        while (current != null && seen.add(current.getMrSerialNumber())) {
            chain.addFirst(mrToMap(current));
            current = current.getParentMr();
        }

        Map<String, Object> response = new HashMap<>();
        response.put("mrSerialNumber", mr.getMrSerialNumber());
        response.put("chain", chain);
        return ResponseEntity.ok(response);
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    /** Converts a MergeRequest to a plain Map for JSON serialisation — mirrors TaskController.mrToMap. */
    private Map<String, Object> mrToMap(MergeRequest mr) {
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

    private void populateFormModel(Model model, MergeRequest mr, boolean isEdit) {
        MrFilterDTO allFilter = new MrFilterDTO();
        List<MergeRequest> allMrs = mrService.getFilteredMrs(allFilter);

        model.addAttribute("mr",             mr);
        model.addAttribute("products",       Product.values());
        model.addAttribute("mrLinkedValues", MrLinked.values());
        model.addAttribute("allMrs",         allMrs);
        model.addAttribute("isEdit",         isEdit);
    }

    private MrFilterDTO buildFilter(Product product,
            String hasParentMr, String parentMrProduct, String mrLinked,
            String merged,
            String canIgnore) {

        MrFilterDTO f = new MrFilterDTO();
        f.setProduct(product);
        if (notBlank(hasParentMr))     f.setHasParentMr(Boolean.valueOf(hasParentMr));
        if (notBlank(parentMrProduct)) f.setParentMrProduct(Product.valueOf(parentMrProduct));
        if (notBlank(mrLinked))        f.setMrLinked(MrLinked.valueOf(mrLinked));

        if (notBlank(merged) && !"all".equals(merged)) {
            // "false" (default) = active only; "true" = merged only
            f.setStepMerged(Boolean.valueOf(merged));
        }

        if (notBlank(canIgnore) && !"all".equals(canIgnore)) f.setCanIgnore(Boolean.valueOf(canIgnore));
        return f;
    }

    private boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    /** Toggle a single plain boolean field (canIgnore) on the MR and return the new value. */
    private boolean doToggle(MergeRequest mr, String field) {
        return switch (field) {
            case "canIgnore" -> { boolean v = !mr.getCanIgnore(); mr.setCanIgnore(v); yield v; }
            default -> throw new IllegalArgumentException("Unknown field: " + field);
        };
    }
}
