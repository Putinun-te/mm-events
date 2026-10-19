package com.concert.repository;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationInfo;
import org.flywaydb.core.api.MigrationState;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ScriptUtils;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The migrations in src/main/resources/db/migration on a real MySQL 8:
 * an empty database gets every version, and a database that Hibernate created
 * before Flyway existed is adopted at version 1 and receives only the later ones.
 * (The Spring Boot ITs then run with ddl-auto=validate, which checks the result
 * against the entities.)
 */
@Testcontainers
class FlywayMigrationIT {

    @Container
    private static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.0");

    private DataSource dataSource;

    @BeforeEach
    void emptyDatabase() {
        dataSource = new DriverManagerDataSource(MYSQL.getJdbcUrl(), MYSQL.getUsername(), MYSQL.getPassword());
        flyway().clean();
    }

    private Flyway flyway() {
        return Flyway.configure()
                .dataSource(dataSource)
                .locations("classpath:db/migration")
                .baselineOnMigrate(true)
                .baselineVersion("1")
                .cleanDisabled(false)
                .load();
    }

    private static List<String> versions(MigrationInfo[] infos, MigrationState state) {
        return Arrays.stream(infos)
                .filter(info -> info.getState() == state)
                .map(info -> info.getVersion().getVersion())
                .toList();
    }

    private boolean indexExists(String table, String index) throws Exception {
        try (Connection connection = dataSource.getConnection();
             ResultSet rows = connection.getMetaData().getIndexInfo(MYSQL.getDatabaseName(), null, table, false, false)) {
            while (rows.next()) {
                if (index.equals(rows.getString("INDEX_NAME"))) {
                    return true;
                }
            }
            return false;
        }
    }

    @Test
    void emptyDatabase_getsEveryMigration() throws Exception {
        flyway().migrate();

        MigrationInfo[] applied = flyway().info().applied();
        assertThat(versions(applied, MigrationState.SUCCESS)).containsExactly("1", "2", "3");
        assertThat(indexExists("bookings", "idx_bookings_event_status")).isTrue();
        assertThat(indexExists("revoked_tokens", "PRIMARY")).isTrue();
    }

    @Test
    void databaseCreatedByHibernate_isBaselinedAndGetsOnlyTheNewMigrations() throws Exception {
        try (Connection connection = dataSource.getConnection()) {
            ScriptUtils.executeSqlScript(connection, new ClassPathResource("flyway/legacy-hibernate-schema.sql"));
        }

        flyway().migrate();

        MigrationInfo[] applied = flyway().info().applied();
        assertThat(versions(applied, MigrationState.BASELINE)).containsExactly("1");
        assertThat(versions(applied, MigrationState.SUCCESS)).containsExactly("2", "3");
        assertThat(indexExists("bookings", "idx_bookings_event_status")).isTrue();
        assertThat(indexExists("revoked_tokens", "PRIMARY")).isTrue();
    }

    @Test
    void migrating_twice_changesNothing() {
        flyway().migrate();

        assertThat(flyway().migrate().migrationsExecuted).isZero();
        assertThat(flyway().validateWithResult().validationSuccessful).isTrue();
    }
}
