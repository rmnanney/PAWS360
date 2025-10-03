-- Read-only replica initialization
-- This is a basic setup for the read replica

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Grant read-only access to readonly user
GRANT CONNECT ON DATABASE paws360_dev TO readonly;
GRANT USAGE ON SCHEMA paws360 TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA paws360 TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA paws360 GRANT SELECT ON TABLES TO readonly;