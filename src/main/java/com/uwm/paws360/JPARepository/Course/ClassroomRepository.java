package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.Classroom;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ClassroomRepository extends JpaRepository<Classroom, Long> {
    Optional<Classroom> findByBuildingIdAndRoomNumberIgnoreCase(Long buildingId, String roomNumber);
}
