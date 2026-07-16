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
    List<Schedule> findByTeacherIdAndDayOfWeekOrderByPeriodAsc(Long teacherId, Integer dayOfWeek);
    boolean existsByTeacherIdAndClassNameAndSubject(Long teacherId, String className, String subject);

    List<Schedule> findBySchoolYearAndSemesterOrderByDayOfWeekAscPeriodAsc(
            String schoolYear, Integer semester);
    List<Schedule> findBySchoolYearAndSemesterAndClassIdOrderByDayOfWeekAscPeriodAsc(
            String schoolYear, Integer semester, Long classId);

    boolean existsByClassIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
            Long classId, String schoolYear, Integer semester, Integer dayOfWeek, String period);
    boolean existsByTeacherIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
            Long teacherId, String schoolYear, Integer semester, Integer dayOfWeek, String period);
    boolean existsByRoomIgnoreCaseAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
            String room, String schoolYear, Integer semester, Integer dayOfWeek, String period);

    boolean existsByClassIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
            Long classId, String schoolYear, Integer semester, Integer dayOfWeek, String period, Long id);
    boolean existsByTeacherIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
            Long teacherId, String schoolYear, Integer semester, Integer dayOfWeek, String period, Long id);
    boolean existsByRoomIgnoreCaseAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
            String room, String schoolYear, Integer semester, Integer dayOfWeek, String period, Long id);

    @Query("select distinct s.className from Schedule s where s.teacherId = :teacherId order by s.className")
    List<String> findDistinctClassNamesByTeacherId(@Param("teacherId") Long teacherId);

    @Query("select distinct s.teacherId from Schedule s where s.className = :className")
    List<Long> findDistinctTeacherIdsByClassName(@Param("className") String className);
}
