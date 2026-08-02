package com.manoj.tasksmr.enums;

/**
 * Current pipeline stage of a MergeRequest — a single current-value status
 * (mirrors TaskStatus), tracked over time via MrStatusHistory.
 *
 * Declaration order matters: it defines the pipeline sequence used for
 * "has this MR reached stage X yet" comparisons (ordinal-based).
 */
public enum MrStatus {
    NEW("New"),
    REVIEWED("Reviewed"),
    DI_COMPLETED("DI Completed"),
    GTM("GTM"),
    RTM("RTM"),
    MERGED("Merged");

    private final String displayName;

    MrStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
