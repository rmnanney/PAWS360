package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Common.DomainValueDTO;
import com.uwm.paws360.Entity.EntityDomains.User.Ethnicity;
import com.uwm.paws360.Entity.EntityDomains.User.Gender;
import com.uwm.paws360.Entity.EntityDomains.User.Nationality;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/domains")
public class DomainController {

    @GetMapping("/genders")
    public ResponseEntity<List<DomainValueDTO>> genders(){
        List<DomainValueDTO> list = Arrays.stream(Gender.values())
                .map(g -> new DomainValueDTO(g.name(), g.getLabel(), null))
                .collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }

    @GetMapping("/ethnicities")
    public ResponseEntity<List<DomainValueDTO>> ethnicities(){
        List<DomainValueDTO> list = Arrays.stream(Ethnicity.values())
                .map(e -> new DomainValueDTO(e.name(), e.getLabel(), null))
                .collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }

    @GetMapping("/nationalities")
    public ResponseEntity<List<DomainValueDTO>> nationalities(){
        List<DomainValueDTO> list = Arrays.stream(Nationality.values())
                .map(n -> new DomainValueDTO(n.name(), n.getLabel(), n.getCode()))
                .collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }

    @GetMapping("/us-states")
    public ResponseEntity<List<DomainValueDTO>> usStates(){
        List<DomainValueDTO> list = Arrays.stream(US_States.values())
                .map(s -> new DomainValueDTO(s.name(), s.getLabel(), null))
                .collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }
}

