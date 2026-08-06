package com.manoj.tasksmr.enums;

public enum Product {
    BOOKS("Books", "bg-info text-dark"),
    PAYROLL("Payroll", "bg-warning text-dark"),
    SPEND("Spend", "bg-primary text-white");
    // Adding a new product here is enough for it to show up everywhere Product.values()
    // is already used (MR product dropdown, filters, etc.) and it lands in the MR module's
    // "Other MRs" tab automatically — no new tab/route needed for it. Give it its own
    // badgeClass above so it renders with a distinct color rather than falling back to
    // some other product's.

    private final String displayName;
    private final String badgeClass;

    Product(String displayName, String badgeClass) {
        this.displayName = displayName;
        this.badgeClass = badgeClass;
    }

    public String getDisplayName() {
        return displayName;
    }

    /**
     * Bootstrap badge classes (background + text color) for rendering this product as a
     * colored badge — MR list/chain panel, task MR panel. Centralized here so a new product
     * only needs one line added above instead of a ternary edited in every view.
     */
    public String getBadgeClass() {
        return badgeClass;
    }
}
