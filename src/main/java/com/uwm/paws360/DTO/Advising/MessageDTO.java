package com.uwm.paws360.DTO.Advising;

import java.time.OffsetDateTime;

public record MessageDTO(
        Long id,
        Integer studentId,
        Integer advisorId,
        String advisorName,
        String sender,
        String content,
        OffsetDateTime sentAt
) {}

