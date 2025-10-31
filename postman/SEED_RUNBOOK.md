PAWS360 Seed Runbook

Prereqs
- Backend running locally at `http://localhost:8080` (Spring Boot, Postgres configured in `src/main/resources/application.yml`).
- Frontend running at `http://localhost:9002` (optional, to visually verify data).
- Postman installed. Use the provided environment `PAWS360 Local` or create an env with `base_url`.

Steps
1) Import `postman/PAWS360_Seed.postman_collection.json`.
2) Import `postman/PAWS360_Local.postman_environment.json` (or set `base_url=http://localhost:8080`).
3) Run the collection top-to-bottom. Requests are ordered:
   - 01 Users: creates advisors, faculty/TA, and multiple students with varied statuses.
   - 02 Programs: creates BSCS program and assigns to students.
   - 03 Catalog: creates building/classroom, courses, sections, assigns staff.
   - 04 Enrollment: enrolls a student, updates current grades, finalizes prior courses for transcript.
   - 05 Advising: assigns a primary advisor and creates an upcoming appointment.
   - 06 Finances: creates a financial account, transactions, aid award, and payment plan.
   - 07 Sanity: verifies academics, finances, requirements, and schedule endpoints.
   - 08 Requirements: attaches degree requirements (core courses) to the BSCS program so the Advising "Degree" tab shows a live breakdown.

Notes
- The collection stores created IDs into Postman environment variables via test scripts.
- Sections include weekday meetings to ensure the Homepage “Today’s Schedule” has data most days.
- Advising page is wired to live data (advisor directory, appointments, and degree requirements breakdown). Requirements derive from degree core courses + completed credits.

Clean-up
- Legacy Java startup seeder has been removed (`src/main/java/com/uwm/paws360/DataSeeder.java`).
- Any SQL seed files under `database/` are no longer required for local flows when using this Postman seed.

Common Issues
- If the backend is not using Java 21 locally, update your JDK or lower the `java.version` in `pom.xml`.
- CORS: backend allows `http://localhost:9002` by default (`WebConfig`). Adjust if using a different port.
