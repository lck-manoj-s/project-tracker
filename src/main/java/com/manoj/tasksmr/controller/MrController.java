package com.manoj.tasksmr.controller;

import com.manoj.tasksmr.dto.MrFilterDTO;
import com.manoj.tasksmr.enums.DeploymentStatus;
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

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.List;
import java.util.stream.Collectors;


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

    /** Products with their own dedicated tab that filters by exact product match. */
    private static final List<Product> TABBED_PRODUCTS = List.of(Product.PAYROLL, Product.BOOKS);

    /**
     * The "Other MRs" tab is scoped to exactly this product for now, rather than being a
     * catch-all for everything outside TABBED_PRODUCTS (which is how it worked before, and
     * how the mr/list.jsp per-row product badge / showProductBadge plumbing still supports
     * it being made a catch-all again). Revisit this if/when a product beyond Spend needs
     * its own visibility here — see listOtherMrs() and tabForProduct() below.
     */
    private static final Product OTHER_TAB_PRODUCT = Product.SPEND;

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
            @RequestParam(required = false) String deployment,
            @RequestParam(required = false) String canIgnore,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listMrs(Product.PAYROLL, null, "payroll", "/mrs/payroll",
                hasParentMr, parentMrProduct, mrLinked, merged, deployment,
                canIgnore, page, model);
    }

    @GetMapping("/books")
    public String listBooksMrs(
            @RequestParam(required = false) String hasParentMr,
            @RequestParam(required = false) String parentMrProduct,
            @RequestParam(required = false) String mrLinked,
            @RequestParam(required = false) String merged,
            @RequestParam(required = false) String deployment,
            @RequestParam(required = false) String canIgnore,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listMrs(Product.BOOKS, null, "books", "/mrs/books",
                hasParentMr, parentMrProduct, mrLinked, merged, deployment,
                canIgnore, page, model);
    }

    /**
     * "Other MRs" tab — for now, an exact-match tab scoped to OTHER_TAB_PRODUCT (Spend), not
     * a catch-all. showProductBadge will be false here, same as Payroll/Books, since exactly
     * one product is shown.
     */
    @GetMapping("/other")
    public String listOtherMrs(
            @RequestParam(required = false) String hasParentMr,
            @RequestParam(required = false) String parentMrProduct,
            @RequestParam(required = false) String mrLinked,
            @RequestParam(required = false) String merged,
            @RequestParam(required = false) String deployment,
            @RequestParam(required = false) String canIgnore,
            @RequestParam(defaultValue = "0") int page,
            Model model) {
        return listMrs(OTHER_TAB_PRODUCT, null, "other", "/mrs/other",
                hasParentMr, parentMrProduct, mrLinked, merged, deployment,
                canIgnore, page, model);
    }

    /**
     * Shared list-page builder for all three tabs. Exactly one of {@code exactProduct} /
     * {@code excludeProducts} is populated by the callers above: the Payroll/Books tabs pass
     * an exact product, the Other tab passes the exclusion list instead.
     */
    private String listMrs(Product exactProduct, List<Product> excludeProducts, String activeTab, String baseUrl,
            String hasParentMr, String parentMrProduct, String mrLinked,
            String merged, String deployment,
            String canIgnore, int page, Model model) {

        // Default canIgnore to "false" (exclude canIgnore MRs); "all" means no filter
        String effectiveCanIgnore = notBlank(canIgnore) ? canIgnore : "false";
        // Default merged to "all" (no filter); "false" = active/non-merged only; "true" = merged only
        String effectiveMerged = notBlank(merged) ? merged : "all";
        // Default deployment to "notIdc" (hide MRs already at IDC); "local"/"pre"/"idc" = exact stage only
        String effectiveDeployment = notBlank(deployment) ? deployment : "notIdc";

        MrFilterDTO filter = buildFilter(exactProduct, excludeProducts,
                hasParentMr, parentMrProduct, mrLinked, effectiveMerged, effectiveDeployment,
                effectiveCanIgnore);

        Page<MergeRequest> mrPage = mrService.getFilteredMrsPaged(filter, page, MR_PAGE_SIZE);

        model.addAttribute("mrs",           mrPage.getContent());
        model.addAttribute("currentPage",   mrPage.getNumber());
        model.addAttribute("totalPages",    mrPage.getTotalPages());
        model.addAttribute("totalElements", mrPage.getTotalElements());

        // MR serial numbers that have at least one child MR — drives the "view children" button
        // on parent rows. Computed from all MRs (not just this page) so it stays correct.
        Set<Long> parentIdsWithChildren = mrService.getAllMrs().stream()
                .map(MergeRequest::getParentMr)
                .filter(Objects::nonNull)
                .map(MergeRequest::getMrSerialNumber)
                .collect(Collectors.toSet());
        model.addAttribute("parentIdsWithChildren", parentIdsWithChildren);

        model.addAttribute("activeTab",       activeTab);
        // A tab with no single exact product (i.e. "Other") can mix products in one table,
        // so its rows need their own product badge to stay legible.
        model.addAttribute("showProductBadge", exactProduct == null);
        model.addAttribute("baseUrl",        baseUrl);
        model.addAttribute("mrLinkedValues", MrLinked.values());
        model.addAttribute("products",       Product.values());

        model.addAttribute("hasParentMr",     hasParentMr);
        model.addAttribute("parentMrProduct", parentMrProduct);
        model.addAttribute("mrLinked",        mrLinked);
        model.addAttribute("merged",          effectiveMerged);
        model.addAttribute("deployment",      effectiveDeployment);
        model.addAttribute("canIgnore",       effectiveCanIgnore);

        return "mr/list";
    }

    /**
     * Which tab a given product's MRs live under. Only Payroll/Books/Spend currently map to a
     * real tab; anything else falls back to "other" so we never construct a broken redirect —
     * but since "other" is now Spend-specific rather than a catch-all, a hypothetical future
     * product beyond these three wouldn't actually show up on the tab it's redirected to.
     * Rework this (and OTHER_TAB_PRODUCT above) if that's ever needed.
     */
    private String tabForProduct(Product product) {
        if (TABBED_PRODUCTS.contains(product)) return product.name().toLowerCase();
        return "other";
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
     * it does NOT carry the task link, so in edit mode we apply the form fields onto the
     * persisted entity rather than saving {@code form} directly.
     * Otherwise every edit (e.g. changing the URL) would silently unlink it from its task.
     * The pipeline stage IS taken from the form (the form always carries the MR's current
     * stage as its preselected value), and {@code MrService.saveMr} records the transition
     * in mr_status_history if it changed — same tracking as clicking a pipeline stage badge.
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

        boolean isEdit = form.getMrSerialNumber() != null;
        MergeRequest mr = isEdit
                ? mrService.getMrById(form.getMrSerialNumber()).orElse(form)
                : form;

        mr.setMr(form.getMr());
        mr.setName(form.getName());
        mr.setProduct(form.getProduct());
        mr.setCanIgnore(form.getCanIgnore());
        mr.setDeploymentStatus(form.getDeploymentStatus());
        mr.setMrLinked(form.getMrLinked());
        mr.setStatus(form.getStatus());
        mr.setParentMr(parentMrId != null ? mrService.getMrById(parentMrId).orElse(null) : null);

        MergeRequest saved = mrService.saveMr(mr);
        ra.addFlashAttribute("successMessage", isEdit ? "MR updated successfully." : "MR created successfully.");
        return "redirect:/mrs/" + tabForProduct(saved.getProduct());
    }

    @PostMapping("/delete/{id}")
    public String deleteMr(@PathVariable Long id, RedirectAttributes ra) {
        String tab = mrService.getMrById(id)
                .map(mr -> tabForProduct(mr.getProduct()))
                .orElse("payroll");
        mrService.deleteMr(id);
        ra.addFlashAttribute("successMessage", "MR deleted successfully.");
        return "redirect:/mrs/" + tab;
    }

    private static final Set<String> PLAIN_TOGGLE_FIELDS = Set.of("canIgnore");

    /**
     * Inline boolean toggle for canIgnore — called via AJAX. Returns {field, newValue}.
     * Pipeline stage changes go through /status/{status}; deployment stage changes go
     * through /deployment/{status} — neither is a plain boolean toggle.
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
     * Sets the MR's deployment stage directly (clicking any deployment badge jumps to that
     * stage — forward or backward). No history tracking, unlike the pipeline status.
     */
    @PostMapping("/{id}/deployment/{status}")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> setDeploymentStatus(
            @PathVariable Long id,
            @PathVariable String status) {

        DeploymentStatus target;
        try {
            target = DeploymentStatus.valueOf(status);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }

        DeploymentStatus newStatus = mrService.updateDeploymentStatus(id, target);

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
        response.put("selectedId", mr.getMrSerialNumber());
        response.put("chain", chain);
        return ResponseEntity.ok(response);
    }

    /**
     * JSON endpoint for the parent's "children" panel — the mirror of {@link #getMrChain}.
     * Returns the given MR first (the selected column), followed by every MR whose parentMr
     * is this MR, ordered by serial number.
     */
    @GetMapping("/{id}/children")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> getMrChildren(@PathVariable Long id) {
        MergeRequest parent = mrService.getMrById(id)
                .orElseThrow(() -> new IllegalArgumentException("MR not found: " + id));

        List<Map<String, Object>> columns = new ArrayList<>();
        columns.add(mrToMap(parent));
        mrService.getAllMrs().stream()
                .filter(m -> m.getParentMr() != null && Objects.equals(m.getParentMr().getMrSerialNumber(), id))
                .sorted(Comparator.comparing(MergeRequest::getMrSerialNumber))
                .forEach(m -> columns.add(mrToMap(m)));

        Map<String, Object> response = new HashMap<>();
        response.put("mrSerialNumber", parent.getMrSerialNumber());
        response.put("selectedId", parent.getMrSerialNumber());
        response.put("chain", columns);
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
        m.put("productBadgeClass", mr.getProduct().getBadgeClass());
        m.put("mrLinked",        mr.getMrLinked().getDisplayName());
        m.put("createdAt",       mr.getCreatedAt() != null ? mr.getCreatedAt().toString().substring(0, 16).replace('T', ' ') : null);
        m.put("stepNew",         mr.getStepNew());
        m.put("stepReviewed",    mr.getStepReviewed());
        m.put("stepDiCompleted", mr.getStepDiCompleted());
        m.put("stepGtm",         mr.getStepGtm());
        m.put("stepRtm",         mr.getStepRtm());
        m.put("stepMerged",      mr.getStepMerged());
        m.put("deployLocal",     mr.getDeployLocal());
        m.put("deployPre",       mr.getDeployPre());
        m.put("deployIdc",       mr.getDeployIdc());
        m.put("movedToLocalAt",  formatTimestamp(mr.getMovedToLocalAt()));
        m.put("movedToPreAt",    formatTimestamp(mr.getMovedToPreAt()));
        m.put("movedToIdcAt",    formatTimestamp(mr.getMovedToIdcAt()));
        return m;
    }

    /** Formats a LocalDateTime as "yyyy-MM-dd HH:mm" for JSON/tooltip display, or null. */
    private static String formatTimestamp(java.time.LocalDateTime dt) {
        return dt != null ? dt.toString().substring(0, 16).replace('T', ' ') : null;
    }

    private void populateFormModel(Model model, MergeRequest mr, boolean isEdit) {
        MrFilterDTO allFilter = new MrFilterDTO();
        List<MergeRequest> allMrs = mrService.getFilteredMrs(allFilter);

        model.addAttribute("mr",             mr);
        model.addAttribute("products",       Product.values());
        model.addAttribute("mrLinkedValues", MrLinked.values());
        model.addAttribute("mrStatusValues", MrStatus.values());
        model.addAttribute("deploymentStatusValues", DeploymentStatus.values());
        model.addAttribute("allMrs",         allMrs);
        model.addAttribute("isEdit",         isEdit);
    }

    private MrFilterDTO buildFilter(Product exactProduct, List<Product> excludeProducts,
            String hasParentMr, String parentMrProduct, String mrLinked,
            String merged, String deployment,
            String canIgnore) {

        MrFilterDTO f = new MrFilterDTO();
        f.setProduct(exactProduct);
        f.setExcludedProducts(excludeProducts);
        if (notBlank(hasParentMr))     f.setHasParentMr(Boolean.valueOf(hasParentMr));
        if (notBlank(parentMrProduct)) f.setParentMrProduct(Product.valueOf(parentMrProduct));
        if (notBlank(mrLinked))        f.setMrLinked(MrLinked.valueOf(mrLinked));

        if (notBlank(merged) && !"all".equals(merged)) {
            // "all" (default) = no filter; "false" = active only; "true" = merged only
            f.setStepMerged(Boolean.valueOf(merged));
        }

        // "notIdc" (default) = hide MRs already at IDC; "local"/"pre"/"idc" = exact stage only
        if (notBlank(deployment)) {
            switch (deployment) {
                case "local"  -> f.setDeploymentStatusEquals(DeploymentStatus.LOCAL);
                case "pre"    -> f.setDeploymentStatusEquals(DeploymentStatus.PRE);
                case "idc"    -> f.setDeploymentStatusEquals(DeploymentStatus.IDC);
                case "notIdc" -> f.setExcludeDeploymentIdc(true);
                default -> { /* unrecognized value — no deployment filter applied */ }
            }
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
