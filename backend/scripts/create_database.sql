-- SmartCoco — database bootstrap (run as the postgres superuser)
--
-- pgAdmin 4:  right-click the "postgres" database -> Query Tool -> paste -> F5
-- psql     :  psql -U postgres -h localhost -d postgres -f create_database.sql
--
-- Note: the API creates its own tables on start-up, so nothing else is needed.

-- 1) Application role (safe to re-run: it just resets the password).
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smartcoco') THEN
        CREATE ROLE smartcoco LOGIN PASSWORD 'smartcoco';
    ELSE
        ALTER ROLE smartcoco WITH LOGIN PASSWORD 'smartcoco';
    END IF;
END
$$;

-- 2) Application database owned by that role.
--    (If it already exists PostgreSQL reports an error — that is fine.)
CREATE DATABASE smartcoco
    OWNER smartcoco
    ENCODING 'UTF8';

-- 3) Optional sanity check.
--    SELECT datname, pg_catalog.pg_get_userbyid(datdba) AS owner
--    FROM pg_database WHERE datname = 'smartcoco';
