package com.uwm.paws360.DTO.Advising;

public record AdvisorDTO(
        Integer advisorId,
        String name,
        String title,
        String department,
        String email,
        String phone,
        String officeLocation,
        String availability
) {}

