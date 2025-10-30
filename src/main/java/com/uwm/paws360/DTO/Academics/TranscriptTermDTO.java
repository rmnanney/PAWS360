package com.uwm.paws360.DTO.Academics;

import java.util.List;

public record TranscriptTermDTO(
        String termLabel,
        Double gpa,
        Integer credits,
        List<TranscriptCourseDTO> courses
) {}

