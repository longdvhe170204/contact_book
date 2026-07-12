package com.tinder.befschool.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@Entity
@Table(name = "grades")
public class Grade extends Auditable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull
    @Column(name = "student_id")
    private Long studentId;

    @Column(name = "class_name")
    private String className;

    @Column(name = "teacher_id")
    private Long teacherId;

    @NotBlank
    private String subject;

    @NotNull
    private Integer semester;

    @Column(columnDefinition = "TEXT")
    private String tx15; // JSON array string

    @Column(columnDefinition = "TEXT")
    private String tx1tiet; // JSON array string

    private Double giuaKy;

    private Double cuoiKy;

    private Double average;

    // getters and setters

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getStudentId() {
        return studentId;
    }

    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public String getClassName() {
        return className;
    }

    public void setClassName(String className) {
        this.className = className;
    }

    public Long getTeacherId() {
        return teacherId;
    }

    public void setTeacherId(Long teacherId) {
        this.teacherId = teacherId;
    }

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public Integer getSemester() {
        return semester;
    }

    public void setSemester(Integer semester) {
        this.semester = semester;
    }

    public String getTx15() {
        return tx15;
    }

    public void setTx15(String tx15) {
        this.tx15 = tx15;
    }

    public String getTx1tiet() {
        return tx1tiet;
    }

    public void setTx1tiet(String tx1tiet) {
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
