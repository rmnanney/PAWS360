package com.uwm.paws360.DTO.Course;

import com.uwm.paws360.Entity.EntityDomains.RoomType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record ClassroomDTO(
        @NotNull(message = "Building id is required")
        Long buildingId,

        @NotBlank(message = "Room number is required")
        @Size(max = 20, message = "Room number cannot exceed 20 characters")
        String roomNumber,

        @Min(value = 1, message = "Capacity must be at least 1")
        Integer capacity,

        RoomType roomType,

        Set<@Size(max = 80, message = "Feature label cannot exceed 80 characters") String> features
) {
}
