package com.tinder.befschool.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.List;

public class AttendanceRequest {

    @NotNull
    private String className;

    @NotBlank
    private String subject;

    @NotNull
    private LocalDate date;

    @NotNull
    private List<AttendanceRecord> records;

    public String getClassName() { return className; }
    public void setClassName(String className) { this.className = className; }

    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public List<AttendanceRecord> getRecords() { return records; }
    public void setRecords(List<AttendanceRecord> records) { this.records = records; }

    public static class AttendanceRecord {
        @NotNull
        private Long studentId;

        @NotBlank
        private String status; // PRESENT, ABSENT, LATE

        private String note;

        public Long getStudentId() { return studentId; }
        public void setStudentId(Long studentId) { this.studentId = studentId; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public String getNote() { return note; }
        public void setNote(String note) { this.note = note; }
    }
}
