package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.schedule.LegacyScheduleResponse;
import com.tinder.befschool.service.PrmCompatibilityService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Student schedule endpoints kept exactly as the current PRM ApiService expects. */
@RestController
@RequestMapping("/api/schedules")
public class PrmScheduleController {
    private final PrmCompatibilityService service;

    public PrmScheduleController(PrmCompatibilityService service) {
        this.service = service;
    }

    @GetMapping("/class/{className}")
    public ResponseEntity<ApiResponse<List<LegacyScheduleResponse>>> byClass(@PathVariable String className) {
        return ok(service.findClassSchedules(className));
    }

    @GetMapping("/class/{className}/day/{dayOfWeek}")
    public ResponseEntity<ApiResponse<List<LegacyScheduleResponse>>> byClassAndDay(
            @PathVariable String className,
            @PathVariable Integer dayOfWeek) {
        return ok(service.findClassSchedulesByPrmDay(className, dayOfWeek));
    }

    private ResponseEntity<ApiResponse<List<LegacyScheduleResponse>>> ok(List<LegacyScheduleResponse> data) {
        return ResponseEntity.ok(new ApiResponse<>(true, data, "Lấy thời khóa biểu thành công"));
    }
}
