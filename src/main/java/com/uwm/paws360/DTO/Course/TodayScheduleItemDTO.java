package com.uwm.paws360.DTO.Course;

import java.time.LocalTime;

public record TodayScheduleItemDTO(
        String courseCode,
        String title,
        LocalTime startTime,
        LocalTime endTime,
        String room
) {}

