package com.uwm.paws360.DTO.Academics;

import java.util.List;

public record TranscriptResponseDTO(
        List<TranscriptTermDTO> terms
) {}

