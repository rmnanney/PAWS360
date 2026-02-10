package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.Building;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface BuildingRepository extends JpaRepository<Building, Long> {
    Optional<Building> findByCodeIgnoreCase(String code);
}
