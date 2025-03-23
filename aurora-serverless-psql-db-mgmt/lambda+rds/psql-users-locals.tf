locals {
  # To attach a specific role in the specific environment
  env_roles = {
    dev = { dev_users = "ro", devops_users = "rw", admin_users = "admin" }
    stg = { dev_users = "ro", devops_users = "rw", admin_users = "admin" }
    prd = { dev_users = "ro", devops_users = "ro", admin_users = "admin" }
  }

  # List of application user identities
  app_users = {
    dev_users = [
      "dev_user_a",
      "dev_user_b",
      "dev_user_c",
      "dev_user_d"
    ]
    devops_users = [
      "devops_user_a",
      "devops_user_b"
    ]
    admin_users = [
      "admin_user_a",
      "admin_user_b"
    ]
  }

  # Flatten users across all teams, creating a map of username => role
  db_users = merge([
    for team, users in local.app_users : {
      for user in users : user => {
        role = local.env_roles[var.env_name][team]
      }
    }
  ]...)

  rds_database_name = "app"

  # Map of username => role
  sql_users_map = merge([
    for team, users in local.app_users : {
      for user in users : user => {
        role = "${local.rds_database_name}_user_${local.env_roles[var.env_name][team]}"
      }
    }
  ]...)

  # SQL to create read-only role
  sql_create_read_only_role = {
    sql = <<EOF
      DO
      \$\$
      DECLARE
        schema_name TEXT;
      BEGIN
        -- Create the read-only role if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${local.rds_database_name}_user_ro') THEN
          CREATE ROLE ${local.rds_database_name}_user_ro;
          GRANT CONNECT ON DATABASE ${local.rds_database_name} TO ${local.rds_database_name}_user_ro;
        END IF;

        -- Loop through all schemas in the database, excluding system schemas
        FOR schema_name IN 
          SELECT schemata.schema_name
          FROM information_schema.schemata AS schemata
          WHERE schemata.catalog_name = '${local.rds_database_name}'
          AND schemata.schema_name NOT IN ('pg_catalog', 'information_schema') 
        LOOP
          -- Grant USAGE on the schema
          EXECUTE format('GRANT USAGE ON SCHEMA %I TO ${local.rds_database_name}_user_ro;', schema_name);
          
          -- Grant SELECT on all tables in the schema
          EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO ${local.rds_database_name}_user_ro;', schema_name);
        END LOOP;
      END
      \$\$;
    EOF
  }

  # SQL to create read-write role
  sql_create_read_write_role = {
    sql = <<EOF
      DO
      \$\$
      DECLARE
        schema_name TEXT;
      BEGIN
        -- Create the read-write role if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${local.rds_database_name}_user_rw') THEN
          CREATE ROLE ${local.rds_database_name}_user_rw;
          GRANT CONNECT ON DATABASE ${local.rds_database_name} TO ${local.rds_database_name}_user_rw;
        END IF;

        -- Loop through all schemas in the database, excluding system schemas
        FOR schema_name IN 
          SELECT schemata.schema_name
          FROM information_schema.schemata AS schemata
          WHERE schemata.catalog_name = '${local.rds_database_name}'
          AND schemata.schema_name NOT IN ('pg_catalog', 'information_schema') 
        LOOP
          -- Grant USAGE and CREATE on the schema
          EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO ${local.rds_database_name}_user_rw;', schema_name);

          -- Grant CRUD permissions on all existing tables
          EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO ${local.rds_database_name}_user_rw;', schema_name);
        END LOOP;
      END
      \$\$;
    EOF
  }

  # SQL to create admin role
  sql_create_admin_role = {
    sql = <<EOF
      DO
      \$\$
      DECLARE
        schema_name TEXT;
      BEGIN
        -- Create the admin role if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${local.rds_database_name}_user_admin') THEN
          CREATE ROLE ${local.rds_database_name}_user_admin;
          GRANT CONNECT ON DATABASE ${local.rds_database_name} TO ${local.rds_database_name}_user_admin;
        END IF;

        -- Loop through all schemas in the database, excluding system schemas
        FOR schema_name IN 
          SELECT schemata.schema_name
          FROM information_schema.schemata AS schemata
          WHERE schemata.catalog_name = '${local.rds_database_name}'
          AND schemata.schema_name NOT IN ('pg_catalog', 'information_schema') 
        LOOP
          -- Grant USAGE and CREATE on the schema (allowing schema usage and object creation)
          EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO ${local.rds_database_name}_user_admin;', schema_name);

          -- Grant INSERT, UPDATE, DELETE on existing tables in the schema
          EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO ${local.rds_database_name}_user_admin;', schema_name);

          -- Grant full privileges on schema (implicitly includes ability to alter the schema)
          EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA %I TO ${local.rds_database_name}_user_admin;', schema_name);

          -- Grant the ability to drop tables (delete tables) by owning the tables
          EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO ${local.rds_database_name}_user_admin;', schema_name);
        END LOOP;
      END
      \$\$;
    EOF
  }

  # Generate SQL statements to create users and set passwords
  sql_create_user = {
    for user, user_info in local.sql_users_map : user => {
      sql = <<EOF
        DO
        \$\$
        DECLARE 
          user_password TEXT := '${jsondecode(data.aws_secretsmanager_secret_version.rds_user_password[user].secret_string)["password"]}';
        BEGIN         
          -- Create user if it does not exist
          IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '${user}') THEN
              EXECUTE format('CREATE USER %I WITH PASSWORD %L;', '${user}', user_password);
          ELSE
              -- Update password if the user already exists
              EXECUTE format('ALTER USER %I WITH PASSWORD %L;', '${user}', user_password);
          END IF;

          -- Ensure role exists
          IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${user_info.role}') THEN
            RAISE EXCEPTION 'Role ${user_info.role} does not exist';
          END IF;
          
          -- Assign role to the user
          EXECUTE format('GRANT %I TO %I;', '${user_info.role}', '${user}');
        END
        \$\$;
      EOF
    }
  }

  # # List of users to be dropped
  # users_to_drop = [
  #   for user in flatten([for record in module.fetch_existing_sql_users.result.records : [record[0].stringValue]]) : user
  #   if !contains(keys(local.sql_users_map), user)
  # ]

  # # Fetch existing users
  # sql_fetch_existing_users = {
  #   sql = <<EOF
  #     SELECT u.usename
  #     FROM pg_roles r
  #     JOIN pg_auth_members m ON r.oid = m.roleid
  #     JOIN pg_user u ON m.member = u.usesysid
  #     WHERE r.rolname IN ('${local.rds_database_name}_user_ro', '${local.rds_database_name}_user_rw', '${local.rds_database_name}_user_admin')
  #     ORDER BY u.usename;
  #   EOF
  # }

  # # Generate SQL for dropping users that are no longer needed
  # sql_drop_user = {
  #   for user in local.users_to_drop : user => {
  #     sql = <<EOF
  #       DO
  #       \$\$
  #       BEGIN
  #         -- Drop user
  #         EXECUTE format('DROP USER IF EXISTS %I;', '${user}');
  #       END
  #       \$\$;
  #     EOF
  #   }
  # }
}