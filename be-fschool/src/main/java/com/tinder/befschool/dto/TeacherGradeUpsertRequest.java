package com.tinder.befschool.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public class TeacherGradeUpsertRequest {

    @NotNull
    private Long studentId;

    @NotNull
    private Integer semester;

    @NotBlank
    private String subject;

    private Long subjectId;

    private List<Double> tx15;

    private List<Double> tx1tiet;

    private Double giuaKy;

    private Double cuoiKy;

    private Double average;

    public Long getStudentId() {
        return studentId;
    }

    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public Integer getSemester() {
        return semester;
    }

    public void setSemester(Integer semester) {
        this.semester = semester;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public Long getSubjectId() {
        return subjectId;
    }

    public void setSubjectId(Long subjectId) {
        this.subjectId = subjectId;
    }

    public List<Double> getTx15() {
        return tx15;
    }

    public void setTx15(List<Double> tx15) {
        this.tx15 = tx15;
    }

    public List<Double> getTx1tiet() {
        return tx1tiet;
    }

    public void setTx1tiet(List<Double> tx1tiet) {
        this.tx1tiet = tx1tiet;
    }

    public Double getGiuaKy() {
        return giuaKy;
    }

    public void setGiuaKy(Double giuaKy) {
        this.giuaKy = giuaKy;
    }

    public Double getCuoiKy() {
        return cuoiKy;
    }

    public void setCuoiKy(Double cuoiKy) {
        this.cuoiKy = cuoiKy;
    }

    public Double getAverage() {
        return average;
    }

    public void setAverage(Double average) {
        this.average = average;
    }
}
