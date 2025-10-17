PAWS360 Seeding with Postman

Overview
- The Postman collection `postman/PAWS360-Seed.postman_collection.json` seeds the API with:
  - 20 users for each Role (11 roles → 220 total)
  - UWM buildings (list included), each with 15 classrooms
  - 15 courses per Department enum
  - 1 lecture + 2 labs per course
  - Staff assigned to each lecture and lab
  - Students enrolled in 4 courses (with labs where applicable)

Prerequisites
- Run the PAWS360 Spring Boot app locally on `http://localhost:8080` (or change `baseUrl` in the environment).
- Ensure the database is reachable and empty or ready for idempotent inserts.

How to Run
1) In Postman, import both files:
   - Collection: `postman/PAWS360-Seed.postman_collection.json`
   - Environment: `postman/PAWS360-Local.postman_environment.json`
2) Select the `PAWS360 Local` environment.
3) Open the collection and run the single request:
   - Seed Database (All-in-One)
4) Watch the Postman Console for progress logs. A summary is stored in the env var `seed_summary` upon completion.

Notes
- The script uses only the public endpoints found in the repository controllers (`/users`, `/courses`, `/enrollments`).
- Staff assignment validates the primary `Users.role` field, so staff users are created with appropriate roles.
- If you re-run the collection against an already seeded DB, some creates may fail due to unique constraints; that’s expected and safe.
