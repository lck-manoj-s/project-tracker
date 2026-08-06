package com.manoj.tasksmr.enums;

/**
 * Current deployment stage of a MergeRequest — a single current-value status
 * (mirrors MrStatus), NOT tracked via history (deployment progress isn't
 * analysed the way pipeline-stage durations are).
 *
 * Declaration order matters: it defines the deployment sequence used for
 * "has this MR reached environment X yet" comparisons (ordinal-based) —
 * Local -> Pre -> IDC.
 */
public enum DeploymentStatus {
    NONE("Not Deployed"),
    LOCAL("Local"),
    PRE("Pre"),
    IDC("IDC");

    private final String displayName;

    DeploymentStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
