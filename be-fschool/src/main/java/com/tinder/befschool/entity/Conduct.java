package com.tinder.befschool.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "conduct")
public class Conduct extends Auditable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "student_id", nullable = false)
    private Long studentId;

    @Column(name = "student_name")
    private String studentName;

    @Column(name = "teacher_id")
    private Long teacherId;

    @Column(name = "teacher_name")
    private String teacherName;

    @Column(name = "class_name")
    private String className;

    private Integer month;

    private Integer year;

    // EXCELLENT, GOOD, AVERAGE, WEAK
    @Column(name = "conduct_rating")
    private String conductRating;

    @Column(columnDefinition = "TEXT")
    private String comment;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getStudentId() { return studentId; }
    public void setStudentId(Long studentId) { this.studentId = studentId; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public Long getTeacherId() { return teacherId; }
    public void setTeacherId(Long teacherId) { this.teacherId = teacherId; }

    public String getTeacherName() { return teacherName; }
    public void setTeacherName(String teacherName) { this.teacherName = teacherName; }

    public String getClassName() { return className; }
    public void setClassName(String className) { this.className = className; }

    public Integer getMonth() { return month; }
    public void setMonth(Integer month) { this.month = month; }

    public Integer getYear() { return year; }
    public void setYear(Integer year) { this.year = year; }

    public String getConductRating() { return conductRating; }
    public void setConductRating(String conductRating) { this.conductRating = conductRating; }

    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }
}
