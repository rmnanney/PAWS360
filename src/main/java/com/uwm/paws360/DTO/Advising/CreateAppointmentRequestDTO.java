package com.uwm.paws360.DTO.Advising;

import com.uwm.paws360.Entity.Advising.AdvisorAppointment;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;

public record CreateAppointmentRequestDTO(
        @NotNull Integer advisorId,
        @NotNull OffsetDateTime scheduledAt,
        AdvisorAppointment.AppointmentType type,
        String location,
        AdvisorAppointment.AppointmentStatus status,
        String notes
) {}

