package com.tinder.befschool.dto;

import java.util.List;

public class ImportSummaryResponse {
    private boolean success;
    private int importedCount;
    private int skippedCount;
    private List<String> skippedPhones;
    private String message;

    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public int getImportedCount() { return importedCount; }
    public void setImportedCount(int importedCount) { this.importedCount = importedCount; }

    public int getSkippedCount() { return skippedCount; }
    public void setSkippedCount(int skippedCount) { this.skippedCount = skippedCount; }

    public List<String> getSkippedPhones() { return skippedPhones; }
    public void setSkippedPhones(List<String> skippedPhones) { this.skippedPhones = skippedPhones; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
