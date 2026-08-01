package com.manoj.tasksmr.enums;

public enum MrLinked {
    NOT_REQUIRED("Not Required"),
    NOT_LINKED("Not Linked"),
    LINKED("Linked");

    private final String displayName;

    MrLinked(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
