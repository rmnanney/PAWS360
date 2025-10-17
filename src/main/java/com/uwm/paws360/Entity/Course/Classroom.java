package com.uwm.paws360.Entity.Course;

import com.uwm.paws360.Entity.EntityDomains.RoomType;
import jakarta.persistence.*;

import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "classrooms", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "building_id", "room_number" })
})
public class Classroom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "classroom_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "building_id", nullable = false)
    private Building building;

    @Column(name = "room_number", nullable = false, length = 20)
    private String roomNumber;

    @Column(name = "capacity")
    private Integer capacity;

    @Enumerated(EnumType.STRING)
    @Column(name = "room_type", length = 30)
    private RoomType roomType = RoomType.GENERAL_PURPOSE;

    @ElementCollection(fetch = FetchType.EAGER)
<<<<<<< ours
<<<<<<< ours
    @CollectionTable(name = "classroom_features", schema = "paws360", joinColumns = @JoinColumn(name = "classroom_id"))
=======
    @CollectionTable(name = "classroom_features", joinColumns = @JoinColumn(name = "classroom_id"))
>>>>>>> theirs
=======
    @CollectionTable(name = "classroom_features", joinColumns = @JoinColumn(name = "classroom_id"))
>>>>>>> theirs
    @Column(name = "feature", length = 80)
    private Set<String> features = new HashSet<>();

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public Classroom() {
    }

    public Classroom(Building building, String roomNumber, Integer capacity, RoomType roomType, Set<String> features) {
        this.building = building;
        this.roomNumber = roomNumber;
        this.capacity = capacity;
        this.roomType = roomType;
        if (features != null) {
            this.features = new HashSet<>(features);
        }
    }

    @PrePersist
    public void onCreate() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Building getBuilding() {
        return building;
    }

    public void setBuilding(Building building) {
        this.building = building;
    }

    public String getRoomNumber() {
        return roomNumber;
    }

    public void setRoomNumber(String roomNumber) {
        this.roomNumber = roomNumber;
    }

    public Integer getCapacity() {
        return capacity;
    }

    public void setCapacity(Integer capacity) {
        this.capacity = capacity;
    }

    public RoomType getRoomType() {
        return roomType;
    }

    public void setRoomType(RoomType roomType) {
        this.roomType = roomType;
    }

    public Set<String> getFeatures() {
        return features;
    }

    public void setFeatures(Set<String> features) {
        this.features = features == null ? new HashSet<>() : new HashSet<>(features);
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
