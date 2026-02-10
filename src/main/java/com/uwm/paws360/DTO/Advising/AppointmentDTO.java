package com.uwm.paws360.DTO.Advising;

import com.uwm.paws360.Entity.Advising.AdvisorAppointment;

import java.time.OffsetDateTime;

public record AppointmentDTO(
        Long id,
        OffsetDateTime scheduledAt,
        String advisorName,
        AdvisorAppointment.AppointmentType type,
        String location,
        AdvisorAppointment.AppointmentStatus status,
        String notes
) {}

