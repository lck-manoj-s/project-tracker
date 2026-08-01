package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.enums.MrLinked;
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
            @RequestParam(required = false) String movedToLocal,
            @RequestParam(required = false) String movedToPre,
            @RequestParam(required = false) String movedToIdc,
            @RequestParam(required = false) String canIgnore,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listMrsForProduct(Product.PAYROLL, "/mrs/payroll",
                hasParentMr, parentMrProduct, mrLinked, merged,
                movedToLocal, movedToPre, movedToIdc, canIgnore, page, model);
    }

    @GetMapping("/books")
    public String listBooksMrs(
            @RequestParam(required = false) String hasParentMr,
            @RequestParam(required = false) String parentMrProduct,
            @RequestParam(required = false) String mrLinked,
            @RequestParam(required = false) String merged,
            @RequestParam(required = false) String movedToLocal,
            @RequestParam(required = false) String movedToPre,
            @RequestParam(required = false) String movedToIdc,
            @RequestParam(required = false) String canIgnore,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listMrsForProduct(Product.BOOKS, "/mrs/books",
                hasParentMr, parentMrProduct, mrLinked, merged,
                movedToLocal, movedToPre, movedToIdc, canIgnore, page, model);
    }

    private String listMrsForProduct(Product product, String baseUrl,
            String hasParentMr, String parentMrProduct, String mrLinked,
            String merged,
            String movedToLocal, String movedToPre, String movedToIdc,
            String canIgnore, int page, Model model) {

        // Default canIgnore to "false" (exclude canIgnore MRs); "all" means no filter
        String effectiveCanIgnore = notBlank(canIgnore) ? canIgnore : "false";
        // Default merged to "false" (show only active/non-merged); "all" = no filter; "true" = merged only
        String effectiveMerged = notBlank(merged) ? merged : "false";

        MrFilterDTO filter = buildFilter(product,
                hasParentMr, parentMrProduct, mrLinked, effectiveMerged,
                movedToLocal, movedToPre, movedToIdc, effectiveCanIgnore);

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
        model.addAttribute("movedToLocal",    movedToLocal);
        model.addAttribute("movedToPre",      movedToPre);
        model.addAttribute("movedToIdc",      movedToIdc);
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

    @PostMapping("/save")
    public String saveMr(
            @ModelAttribute MergeRequest mr,
            @RequestParam(required = false) Long parentMrId,
            RedirectAttributes ra) {

        // Duplicate URL check
        if (mr.getMr() != null && !mr.getMr().isBlank()) {
            mrService.findByUrl(mr.getMr().trim()).ifPresent(existing -> {
                if (!existing.getMrSerialNumber().equals(mr.getMrSerialNumber())) {
                    ra.addFlashAttribute("errorMessage",
                        "MR URL already exists (MR #" + existing.getMrSerialNumber() + "). Please use a unique URL.");
                }
            });
        }

        if (ra.getFlashAttributes().containsKey("errorMessage")) {
            String redirect = mr.getMrSerialNumber() != null
                    ? "redirect:/mrs/edit/" + mr.getMrSerialNumber()
                    : "redirect:/mrs/new";
            return redirect;
        }

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

    /**
     * Inline boolean toggle for deployment and canIgnore fields — called via AJAX.
     * Returns {field, newValue}.
     */
    @PostMapping("/{id}/toggle/{field}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> toggleField(
            @PathVariable Long id,
            @PathVariable String field) {

        Set<String> allowed = Set.of(
                "movedToLocal", "movedToPre", "movedToIdc", "canIgnore",
                "stepWaiting", "stepReviewed", "stepDiScheduled", "stepDiCompleted",
                "stepGtm", "stepRtm", "stepMerged");
        if (!allowed.contains(field)) {
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

    // ── helpers ──────────────────────────────────────────────────────────────

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
            String movedToLocal, String movedToPre, String movedToIdc,
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

        if (notBlank(movedToLocal))    f.setMovedToLocal(Boolean.valueOf(movedToLocal));
        if (notBlank(movedToPre))      f.setMovedToPre(Boolean.valueOf(movedToPre));
        if (notBlank(movedToIdc))      f.setMovedToIdc(Boolean.valueOf(movedToIdc));
        if (notBlank(canIgnore) && !"all".equals(canIgnore)) f.setCanIgnore(Boolean.valueOf(canIgnore));
        return f;
    }

    private boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    /** Toggle a single boolean field on the MR and return the new value. */
    private boolean doToggle(MergeRequest mr, String field) {
        return switch (field) {
            case "movedToLocal"    -> { boolean v = !mr.getMovedToLocal();    mr.setMovedToLocal(v);    yield v; }
            case "movedToPre"      -> { boolean v = !mr.getMovedToPre();      mr.setMovedToPre(v);      yield v; }
            case "movedToIdc"      -> { boolean v = !mr.getMovedToIdc();      mr.setMovedToIdc(v);      yield v; }
            case "canIgnore"       -> { boolean v = !mr.getCanIgnore();       mr.setCanIgnore(v);       yield v; }
            case "stepWaiting"     -> { boolean v = !mr.getStepWaiting();     mr.setStepWaiting(v);     yield v; }
            case "stepReviewed"    -> { boolean v = !mr.getStepReviewed();    mr.setStepReviewed(v);    yield v; }
            case "stepDiScheduled" -> { boolean v = !mr.getStepDiScheduled(); mr.setStepDiScheduled(v); yield v; }
            case "stepDiCompleted" -> { boolean v = !mr.getStepDiCompleted(); mr.setStepDiCompleted(v); yield v; }
            case "stepGtm"         -> { boolean v = !mr.getStepGtm();         mr.setStepGtm(v);         yield v; }
            case "stepRtm"         -> { boolean v = !mr.getStepRtm();         mr.setStepRtm(v);         yield v; }
            case "stepMerged"      -> { boolean v = !mr.getStepMerged();      mr.setStepMerged(v);      yield v; }
            default -> throw new IllegalArgumentException("Unknown field: " + field);
        };
    }
}
