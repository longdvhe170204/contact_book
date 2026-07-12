package com.tinder.befschool.repository;

import com.tinder.befschool.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ScheduleRepository extends JpaRepository<Schedule, Long> {
    List<Schedule> findByClassNameOrderByDayOfWeekAscPeriodAsc(String className);

    List<Schedule> findByClassNameAndDayOfWeekOrderByPeriodAsc(String className, Integer dayOfWeek);

    List<Schedule> findByTeacherIdOrderByDayOfWeekAscPeriodAsc(Long teacherId);

    boolean existsByTeacherIdAndClassNameAndSubject(Long teacherId, String className, String subject);

    @Query("select distinct s.className from Schedule s where s.teacherId = :teacherId order by s.className")
    List<String> findDistinctClassNamesByTeacherId(@Param("teacherId") Long teacherId);

    @Query("select distinct s.teacherId from Schedule s where s.className = :className")
    List<Long> findDistinctTeacherIdsByClassName(@Param("className") String className);
}
