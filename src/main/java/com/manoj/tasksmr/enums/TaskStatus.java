package com.manoj.tasksmr.enums;

public enum TaskStatus {
    YET_TO_START("Yet to Start"),
    IDENTIFYING_ISSUE("Identifying Issue"),
    FIXING("Fixing"),
    MR_CREATED("MR Created"),
    DONE("Done"),
    PAUSED("Paused");

    private final String displayName;

    TaskStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
