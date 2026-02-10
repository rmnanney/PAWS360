package com.uwm.paws360;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.beans.factory.annotation.Autowired;

@Component
public class DatabaseInitializer implements ApplicationListener<ApplicationReadyEvent> {

    private static final Logger log = LoggerFactory.getLogger(DatabaseInitializer.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private DataSource dataSource;

    // path to the import SQL file (project-root relative by default)
    @Value("${paws360.courses.sql.path:database/courses_inserts.sql}")
    private String coursesSqlPath;

    @Override
    public void onApplicationEvent(ApplicationReadyEvent event) {
        try {
            // check whether the courses table exists
            Integer tableCount = jdbcTemplate.queryForObject(
                    "select count(*) from information_schema.tables where table_schema='public' and table_name='courses'",
                    Integer.class);

            if (tableCount == null || tableCount == 0) {
                log.info("courses table does not exist yet; skipping automatic import (Hibernate may create the table later). If you want automatic creation, consider enabling schema.sql or running the import after startup.");
                return;
            }

            Integer rowCount = jdbcTemplate.queryForObject("select count(*) from public.courses", Integer.class);
            if (rowCount != null && rowCount > 0) {
                log.info("courses table already populated ({} rows) — skipping import.", rowCount);
                return;
            }

            Resource resource = new FileSystemResource(coursesSqlPath);
            if (!resource.exists()) {
                log.warn("courses SQL file not found at {} — skipping import.", coursesSqlPath);
                return;
            }

            log.info("Found {} and courses table empty — importing SQL. This may take a while.", coursesSqlPath);
            ResourceDatabasePopulator populator = new ResourceDatabasePopulator(resource);
            populator.setContinueOnError(true);
            populator.execute(dataSource);

            // advance sequence to max(course_id)
            try {
                jdbcTemplate.execute("SELECT pg_catalog.setval('public.courses_course_id_seq', COALESCE((SELECT MAX(course_id) FROM public.courses), 1), true);");
            } catch (Exception ex) {
                log.warn("Failed to set sequence value for courses_course_id_seq: {}", ex.getMessage());
            }

            Integer after = jdbcTemplate.queryForObject("select count(*) from public.courses", Integer.class);
            log.info("Import finished; courses table now contains {} rows.", after != null ? after : "unknown");

        } catch (Exception e) {
            log.warn("Automatic courses import failed or was skipped: {}", e.getMessage());
        }
    }
}
