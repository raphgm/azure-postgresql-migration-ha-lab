-- Role-scoped database access instead of every application connecting
-- as the server admin. Passwords are NULL here because auth happens via
-- Microsoft Entra tokens (see entra-admin-setup.sh) -- adjust if your
-- environment still needs password auth for a given role.

CREATE ROLE app_readwrite WITH LOGIN;
GRANT CONNECT ON DATABASE production_db TO app_readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;

CREATE ROLE reporting_readonly WITH LOGIN;
GRANT CONNECT ON DATABASE production_db TO reporting_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO reporting_readonly;

-- An application that only needs to read and write its own tables
-- should connect as app_readwrite, never as the server admin.
