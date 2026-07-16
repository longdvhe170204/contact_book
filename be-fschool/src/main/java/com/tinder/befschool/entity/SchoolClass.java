package com.tinder.befschool.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "school_classes", uniqueConstraints = {
        @UniqueConstraint(name = "uk_school_class_code_year", columnNames = {"code", "school_year"})
})
public class SchoolClass {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 30)
    private String code;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "grade_level", nullable = false)
    private Integer gradeLevel;

    @Column(name = "school_year", nullable = false, length = 9)
    private String schoolYear;

    @Column(name = "homeroom_teacher_id")
    private Long homeroomTeacherId;

    @Column(name = "maximum_students")
    private Integer maximumStudents;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SchoolClassStatus status = SchoolClassStatus.ACTIVE;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void prePersist() {
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void preUpdate() { updatedAt = LocalDateTime.now(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public Integer getGradeLevel() { return gradeLevel; }
    public void setGradeLevel(Integer gradeLevel) { this.gradeLevel = gradeLevel; }
    public String getSchoolYear() { return schoolYear; }
    public void setSchoolYear(String schoolYear) { this.schoolYear = schoolYear; }
    public Long getHomeroomTeacherId() { return homeroomTeacherId; }
    public void setHomeroomTeacherId(Long homeroomTeacherId) { this.homeroomTeacherId = homeroomTeacherId; }
    public Integer getMaximumStudents() { return maximumStudents; }
    public void setMaximumStudents(Integer maximumStudents) { this.maximumStudents = maximumStudents; }
    public SchoolClassStatus getStatus() { return status; }
    public void setStatus(SchoolClassStatus status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
