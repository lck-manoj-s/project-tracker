package com.manoj.tasksmr.enums;

public enum Product {
    BOOKS("Books"),
    PAYROLL("Payroll");

    private final String displayName;

    Product(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
