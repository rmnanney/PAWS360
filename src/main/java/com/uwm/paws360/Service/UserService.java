package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.User.*;
import com.uwm.paws360.Entity.UserTypes.*;
import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.JPARepository.User.*;
import com.uwm.paws360.Entity.Base.EmergencyContact;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.beans.factory.annotation.Value;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Set;

@Service
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final AdvisorRepository advisorRepository;
    private final CounselorRepository counselorRepository;
    private final FacultyRepository facultyRepository;
    private final InstructorRepository instructorRepository;
    private final MentorRepository mentorRepository;
    private final ProfessorRepository professorRepository;
    private final StudentRepository studentRepository;
    private final TARepository taRepository;
    private final AddressRepository addressRepository;
    private final EmergencyContactRepository emergencyContactRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Value("${app.upload-dir:uploads}")
    private String uploadDir;

    private static final Set<String> ALLOWED_IMAGE_TYPES = Set.of(
            "image/png", "image/jpeg", "image/jpg", "image/webp"
    );

    public UserService(UserRepository userRepository, AdvisorRepository advisorRepository,
                       CounselorRepository counselorRepository, FacultyRepository facultyRepository,
                       InstructorRepository instructorRepository, MentorRepository mentorRepository,
                       ProfessorRepository professorRepository, StudentRepository studentRepository,
                       TARepository taRepository, AddressRepository addressRepository,
                       EmergencyContactRepository emergencyContactRepository
    ) {
        this.userRepository = userRepository;
        this.advisorRepository = advisorRepository;
        this.counselorRepository = counselorRepository;
        this.facultyRepository = facultyRepository;
        this.instructorRepository = instructorRepository;
        this.mentorRepository = mentorRepository;
        this.professorRepository = professorRepository;
        this.studentRepository = studentRepository;
        this.taRepository = taRepository;
        this.addressRepository = addressRepository;
        this.emergencyContactRepository = emergencyContactRepository;
    }

    public UserResponseDTO createUser(CreateUserDTO user){
        Users newUser = new Users(
                user.firstname(),
                user.middlename(),
                user.lastname(),
                user.dob(),
                user.email(),
                hashIfNeeded(user.password()),
                user.countryCode(),
                user.phone(),
                user.status(),
                user.role(),
                user.ssn(),
                user.ethnicity(),
                user.nationality(),
                user.gender()
        );

        if (user.addresses() != null) {
            for (var addrDto : user.addresses()) {
                Address addr = new Address();
                addr.setUser(newUser);
                addr.setAddress_type(addrDto.address_type());
                addr.setFirstname(newUser.getFirstname());
                addr.setLastname(newUser.getLastname());
                addr.setStreet_address_1(addrDto.street_address_1());
                addr.setStreet_address_2(addrDto.street_address_2());
                addr.setPo_box(addrDto.po_box());
                addr.setCity(addrDto.city());
                addr.setUs_state(addrDto.us_states());
                addr.setZipcode(addrDto.zipcode());
                newUser.getAddresses().add(addr);
            }
        }

        userRepository.save(newUser);
        switch(newUser.getRole()){
            case ADVISOR: {
                Advisor newAdvisor = new Advisor(newUser);
                advisorRepository.save(newAdvisor);
                break;
            }
            case COUNSELOR: {
                Counselor newCounselor = new Counselor(newUser);
                counselorRepository.save(newCounselor);
                break;
            }
            case FACULTY: {
                Faculty newFaculty = new Faculty(newUser);
                facultyRepository.save(newFaculty);
                break;
            }
            case INSTRUCTOR: {
                Instructor newInstructor = new Instructor(newUser);
                instructorRepository.save(newInstructor);
                break;
            }
            case MENTOR: {
                Mentor newMentor = new Mentor(newUser);
                mentorRepository.save(newMentor);
                break;
            }
            case PROFESSOR: {
                Professor newProfessor = new Professor(newUser);
                professorRepository.save(newProfessor);
                break;
            }
            case STUDENT: {
                Student newStudent = new Student(newUser);
                studentRepository.save(newStudent);
                break;
            }
            case TA: {
                TA newTA = new TA(newUser);
                taRepository.save(newTA);
                break;
            }
            default: {
                break;
            }
        }

        return toUserResponseDTO(newUser);
    }

    public UserResponseDTO editUser(EditUserRequestDTO userDTO){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(userDTO.email());
        if(user == null) return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
        user.setFirstname(userDTO.firstname());
        user.setMiddlename(userDTO.middlename());
        user.setLastname(userDTO.lastname());
        user.setDob(userDTO.dob());
        user.setSocialsecurity(userDTO.ssn());
        user.setEthnicity(userDTO.ethnicity());
        user.setGender(userDTO.gender());
        user.setNationality(userDTO.nationality());
        user.setPassword(hashIfNeeded(userDTO.password()));
        user.setCountryCode(userDTO.countryCode());
        user.setPhone(userDTO.phone());
        // Keep address contact names in sync with user name changes
        if (user.getAddresses() != null) {
            for (Address addr : user.getAddresses()) {
                if (addr != null) {
                    addr.setFirstname(user.getFirstname());
                    addr.setLastname(user.getLastname());
                }
            }
        }
        userRepository.save(user);
        return toUserResponseDTO(user);
    }

    // Lookup: resolve Student.id by user email (returns -1 if not found or not a student)
    public int getStudentIdByEmail(String email) {
        Users user = userRepository.findUsersByEmailIgnoreCase(email);
        if (user == null) return -1;
        return studentRepository.findByUser(user)
                .map(Student::getId)
                .orElse(-1);
    }

    public boolean deleteUser(DeleteUserRequestDTO deleteUserRequestDTO){
        Users user = userRepository.findUsersByEmailIgnoreCase(deleteUserRequestDTO.email());
        if(user == null) return false;
        // Remove role records first to satisfy FK constraints
        advisorRepository.deleteByUser(user);
        counselorRepository.deleteByUser(user);
        facultyRepository.deleteByUser(user);
        instructorRepository.deleteByUser(user);
        mentorRepository.deleteByUser(user);
        professorRepository.deleteByUser(user);
        studentRepository.deleteByUser(user);
        taRepository.deleteByUser(user);
        // Addresses are cascaded from Users (orphanRemoval = true)
        userRepository.delete(user);
        return true;
    }

    // Address management
    public UserResponseDTO addAddress(AddAddressRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
        Address addr = new Address();
        addr.setUser(user);
        addr.setAddress_type(dto.address().address_type());
        addr.setFirstname(user.getFirstname());
        addr.setLastname(user.getLastname());
        addr.setStreet_address_1(dto.address().street_address_1());
        addr.setStreet_address_2(dto.address().street_address_2());
        addr.setPo_box(dto.address().po_box());
        addr.setCity(dto.address().city());
        addr.setUs_state(dto.address().us_states());
        addr.setZipcode(dto.address().zipcode());
        user.getAddresses().add(addr);
        userRepository.save(user);
        return toUserResponseDTO(user);
    }

    public UserResponseDTO editAddress(EditAddressRequestDTO dto){
        Optional<Address> addressOpt = addressRepository.findById(dto.address_id());
        if (addressOpt.isEmpty()) return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
        Address addr = addressOpt.get();
        addr.setAddress_type(dto.address().address_type());
        addr.setStreet_address_1(dto.address().street_address_1());
        addr.setStreet_address_2(dto.address().street_address_2());
        addr.setPo_box(dto.address().po_box());
        addr.setCity(dto.address().city());
        addr.setUs_state(dto.address().us_states());
        addr.setZipcode(dto.address().zipcode());
        addressRepository.save(addr);
        return toUserResponseDTO(addr.getUser());
    }

    public boolean deleteAddress(DeleteAddressRequestDTO dto){
        Optional<Address> addressOpt = addressRepository.findById(dto.address_id());
        if (addressOpt.isEmpty()) return false;
        addressRepository.delete(addressOpt.get());
        return true;
    }

    public List<AddressDTO> listAddresses(ListAddressesRequestDTO dto){
        Users user = userRepository.findUsersByEmailIgnoreCase(dto.email());
        if (user == null) return List.of();
        return toAddressDTOs(user.getAddresses());
    }

    public UserResponseDTO getUser(GetUserRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
        return toUserResponseDTO(user);
    }

    // Preferences
    public UserPreferencesResponseDTO getPreferences(String email){
        Users user = userRepository.findUsersByEmailIgnoreCase(email);
        if (user == null) return new UserPreferencesResponseDTO(
                com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance.RESTRICTED,
                false, false, true, true, false
        );
        return new UserPreferencesResponseDTO(
                user.getFerpa_compliance(),
                user.isFerpa_directory_opt_in(),
                user.isPhoto_release_opt_in(),
                user.isContact_by_phone(),
                user.isContact_by_email(),
                user.isContact_by_mail()
        );
    }

    public UserPreferencesResponseDTO updatePreferences(UpdatePrivacyRequestDTO dto){
        Users user = userRepository.findUsersByEmailIgnoreCase(dto.email());
        if (user == null) return getPreferences("non-existent");
        user.setFerpa_compliance(dto.ferpa_compliance());
        user.setFerpa_directory_opt_in(Boolean.TRUE.equals(dto.ferpaDirectory()));
        user.setPhoto_release_opt_in(Boolean.TRUE.equals(dto.photoRelease()));
        user.setContact_by_phone(Boolean.TRUE.equals(dto.contactByPhone()));
        user.setContact_by_email(Boolean.TRUE.equals(dto.contactByEmail()));
        user.setContact_by_mail(Boolean.TRUE.equals(dto.contactByMail()));
        userRepository.save(user);
        return getPreferences(user.getEmail());
    }

    public boolean updateContactInfo(UpdateContactInfoRequestDTO dto){
        Users user = userRepository.findUsersByEmailIgnoreCase(dto.email());
        if (user == null) return false;
        if (dto.phone() != null) {
            String p = dto.phone().trim();
            if (p.isEmpty()) return false;
            user.setPhone(p);
        }
        if (dto.alternatePhone() != null) {
            String ap = dto.alternatePhone().trim();
            user.setAlternatePhone(ap.isEmpty() ? null : ap);
        }
        if (dto.alternateEmail() != null) {
            String ae = dto.alternateEmail().trim();
            user.setAlternateEmail(ae.isEmpty() ? null : ae);
        }
        if (dto.newEmail() != null) {
            String ne = dto.newEmail().trim();
            if (!ne.isEmpty()) {
                Users existing = userRepository.findUsersByEmailLikeIgnoreCase(ne);
                if (existing != null && existing.getId() != user.getId()) {
                    return false;
                }
                user.setEmail(ne);
            }
        }
        userRepository.save(user);
        return true;
    }

    public UserResponseDTO updatePersonalDetails(UpdatePersonalDetailsRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
        if (dto.firstname() != null) {
            if (dto.firstname().trim().isEmpty()) return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
            user.setFirstname(dto.firstname().trim());
        }
        if (dto.middlename() != null) {
            user.setMiddlename(dto.middlename().trim());
        }
        if (dto.lastname() != null) {
            if (dto.lastname().trim().isEmpty()) return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
            user.setLastname(dto.lastname().trim());
        }
        if (dto.preferredName() != null) {
            String pn = dto.preferredName().trim();
            user.setPreferred_name(pn.isEmpty() ? null : pn);
        }
        if (dto.ethnicity() != null) user.setEthnicity(dto.ethnicity());
        if (dto.gender() != null) user.setGender(dto.gender());
        if (dto.nationality() != null) user.setNationality(dto.nationality());
        if (dto.dob() != null) {
            java.time.LocalDate min = java.time.LocalDate.of(1900,1,1);
            java.time.LocalDate now = java.time.LocalDate.now();
            if (dto.dob().isBefore(min) || dto.dob().isAfter(now)) {
                return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
            }
            user.setDob(dto.dob());
        }
        if (dto.ssn() != null) {
            String digits = dto.ssn().trim();
            if (!digits.matches("^\\d{9}$")) {
                return new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, List.of());
            }
            user.setSocialsecurity(digits);
        }
        if (dto.profilePictureUrl() != null) {
            String url = dto.profilePictureUrl().trim();
            user.setProfilePictureUrl(url.isEmpty() ? null : url);
        }
        userRepository.save(user);
        return toUserResponseDTO(user);
    }

    // Emergency contacts
    public List<EmergencyContactDTO> listEmergencyContacts(String email){
        Users user = userRepository.findUsersByEmailIgnoreCase(email);
        if (user == null) return List.of();
        return emergencyContactRepository.findByUser(user).stream().map(this::toEmergencyDTO).toList();
    }

    public EmergencyContactDTO upsertEmergencyContact(UpsertEmergencyContactRequestDTO dto){
        Users user = userRepository.findUsersByEmailIgnoreCase(dto.email());
        if (user == null) return null;
        EmergencyContact ec;
        if (dto.contact_id() != null){
            ec = emergencyContactRepository.findById(dto.contact_id()).orElse(null);
            if (ec == null) return null;
        } else {
            ec = new EmergencyContact();
            ec.setUser(user);
        }
        ec.setName(dto.name());
        ec.setRelationship(dto.relationship());
        ec.setEmail(dto.contact_email());
        ec.setPhone(dto.phone());
        ec.setStreet_address_1(dto.street_address_1());
        ec.setStreet_address_2(dto.street_address_2());
        ec.setCity(dto.city());
        ec.setUs_state(dto.us_states());
        ec.setZipcode(dto.zipcode());
        emergencyContactRepository.save(ec);
        return toEmergencyDTO(ec);
    }

    public boolean deleteEmergencyContact(DeleteEmergencyContactRequestDTO dto){
        var found = emergencyContactRepository.findById(dto.contact_id());
        if (found.isEmpty()) return false;
        emergencyContactRepository.delete(found.get());
        return true;
    }

    public String uploadProfilePicture(String email, MultipartFile file) throws Exception {
        if (file == null || file.isEmpty()) return null;
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(email);
        if (user == null) return null;

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase())) {
            throw new IllegalArgumentException("Unsupported image type");
        }

        String ext;
        switch (contentType.toLowerCase()){
            case "image/png": ext = ".png"; break;
            case "image/jpeg":
            case "image/jpg": ext = ".jpg"; break;
            case "image/webp": ext = ".webp"; break;
            default: ext = ""; break;
        }

        Path base = Paths.get(uploadDir).toAbsolutePath().normalize();
        Path dir = base.resolve("profile-pictures");
        Files.createDirectories(dir);

        String filename = "user-" + user.getId() + "-" + System.currentTimeMillis() + ext;
        Path target = dir.resolve(filename);
        try (InputStream in = file.getInputStream()){
            Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
        }

        // delete previously stored file if it was in our uploads directory
        String old = user.getProfilePictureUrl();
        if (old != null && old.startsWith("/uploads/")){
            try {
                // expected format: /uploads/profile-pictures/<name>
                Path oldPath = dir.resolve(Paths.get(old).getFileName());
                Files.deleteIfExists(oldPath);
            } catch (Exception ignore) {}
        }

        String publicUrl = "/uploads/profile-pictures/" + filename;
        user.setProfilePictureUrl(publicUrl);
        userRepository.save(user);
        return publicUrl;
    }

    private EmergencyContactDTO toEmergencyDTO(EmergencyContact c){
        return new EmergencyContactDTO(
                c.getId(), c.getName(), c.getRelationship(), c.getEmail(), c.getPhone(),
                c.getStreet_address_1(), c.getStreet_address_2(), c.getCity(), c.getUs_state(), c.getZipcode()
        );
    }

    public SsnLast4ResponseDTO getSsnLast4(String email){
        Users user = userRepository.findUsersByEmailIgnoreCase(email);
        if (user == null || user.getSocialsecurity() == null) return new SsnLast4ResponseDTO("***-**-****", null);
        String ssn = user.getSocialsecurity();
        String last4 = ssn.length() >= 4 ? ssn.substring(ssn.length() - 4) : null;
        String masked = last4 != null ? ("***-**-" + last4) : "***-**-****";
        return new SsnLast4ResponseDTO(masked, last4);
    }

    public List<Role> listRoles(ListRolesRequestDTO dto){
        Users user = userRepository.findUsersByEmailIgnoreCase(dto.email());
        if (user == null) return List.of();
        List<Role> roles = new ArrayList<>();
        if (user.getRole() != null) roles.add(user.getRole());
        if (advisorRepository.findByUser(user).isPresent()) roles.add(Role.ADVISOR);
        if (counselorRepository.findByUser(user).isPresent()) roles.add(Role.COUNSELOR);
        if (facultyRepository.findByUser(user).isPresent()) roles.add(Role.FACULTY);
        if (instructorRepository.findByUser(user).isPresent()) roles.add(Role.INSTRUCTOR);
        if (mentorRepository.findByUser(user).isPresent()) roles.add(Role.MENTOR);
        if (professorRepository.findByUser(user).isPresent()) roles.add(Role.PROFESSOR);
        if (studentRepository.findByUser(user).isPresent()) roles.add(Role.STUDENT);
        if (taRepository.findByUser(user).isPresent()) roles.add(Role.TA);
        return roles;
    }

    // Role management
    public boolean assignRole(ModifyRoleRequestDTO dto){
        Users user = userRepository.findUsersByEmailIgnoreCase(dto.email());
        if (user == null) return false;
        switch (dto.role()){
            case ADVISOR: {
                if (advisorRepository.findByUser(user).isEmpty()) advisorRepository.save(new Advisor(user));
                break;
            }
            case COUNSELOR: {
                if (counselorRepository.findByUser(user).isEmpty()) counselorRepository.save(new Counselor(user));
                break;
            }
            case FACULTY: {
                if (facultyRepository.findByUser(user).isEmpty()) facultyRepository.save(new Faculty(user));
                break;
            }
            case INSTRUCTOR: {
                if (instructorRepository.findByUser(user).isEmpty()) instructorRepository.save(new Instructor(user));
                break;
            }
            case MENTOR: {
                if (mentorRepository.findByUser(user).isEmpty()) mentorRepository.save(new Mentor(user));
                break;
            }
            case PROFESSOR: {
                if (professorRepository.findByUser(user).isEmpty()) professorRepository.save(new Professor(user));
                break;
            }
            case STUDENT: {
                if (studentRepository.findByUser(user).isEmpty()) studentRepository.save(new Student(user));
                break;
            }
            case TA: {
                if (taRepository.findByUser(user).isEmpty()) taRepository.save(new TA(user));
                break;
            }
            default: {
                break;
            }
        }
        return true;
    }

    public boolean removeRole(ModifyRoleRequestDTO dto){
        Users user = userRepository.findUsersByEmailIgnoreCase(dto.email());
        if (user == null) return false;
        switch (dto.role()){
            case ADVISOR: { advisorRepository.deleteByUser(user); break; }
            case COUNSELOR: { counselorRepository.deleteByUser(user); break; }
            case FACULTY: { facultyRepository.deleteByUser(user); break; }
            case INSTRUCTOR: { instructorRepository.deleteByUser(user); break; }
            case MENTOR: { mentorRepository.deleteByUser(user); break; }
            case PROFESSOR: { professorRepository.deleteByUser(user); break; }
            case STUDENT: { studentRepository.deleteByUser(user); break; }
            case TA: { taRepository.deleteByUser(user); break; }
            default: { break; }
        }
        return true;
    }

    // Helpers
    private String hashIfNeeded(String raw){
        if (raw == null) return null;
        if (isBCrypt(raw)) return raw;
        return passwordEncoder.encode(raw);
    }

    private boolean isBCrypt(String value){
        return value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$");
    }

    private UserResponseDTO toUserResponseDTO(Users user){
        return new UserResponseDTO(
                user.getId(),
                user.getEmail(),
                user.getAlternateEmail(),
                user.getFirstname(),
                user.getPreferred_name(),
                user.getLastname(),
                user.getRole(),
                user.getEthnicity(),
                user.getGender(),
                user.getNationality(),
                user.getStatus(),
                user.getDob(),
                user.getCountryCode(),
                user.getPhone(),
                user.getAlternatePhone(),
                user.getProfilePictureUrl(),
                toAddressDTOs(user.getAddresses())
        );
    }

    private List<AddressDTO> toAddressDTOs(List<Address> addresses){
        List<AddressDTO> list = new ArrayList<>();
        if (addresses == null) return list;
        for (Address a : addresses){
            list.add(new AddressDTO(
                    a.getId(),
                    a.getAddress_type(),
                    a.getStreet_address_1(),
                    a.getStreet_address_2(),
                    a.getPo_box(),
                    a.getCity(),
                    a.getUs_state(),
                    a.getZipcode()
            ));
        }
        return list;
    }
}
