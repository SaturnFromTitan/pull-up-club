part of "workout_database.dart";

/// Schema migrations for [WorkoutDatabase], kept in a dedicated file so that
/// each step stays small and readable as the app grows.
extension WorkoutDatabaseMigrations on WorkoutDatabase {
  /// Migration to schema version 2.
  ///
  /// - Adds nullable `number` column to `workout_sets`
  /// - Backfills values based on `id` ordering per workout
  /// - Recreates table to make `number` non-nullable
  Future<void> migrateToVersion2(final Migrator m) async {
    WorkoutDatabase._logger.info("Applying migration to version 2");

    // Add number column to workout_sets table as nullable first (for migration safety)
    await customStatement("ALTER TABLE workout_sets ADD COLUMN number INTEGER");
    WorkoutDatabase._logger.info(
      "Added number column to workout_sets table (nullable)",
    );

    // Set number values: for each workout, order sets by id and assign numbers starting from 1
    // We'll use a subquery to assign sequential numbers based on id ordering
    await customStatement("""
      UPDATE workout_sets
      SET number = (
        SELECT COUNT(*) + 1
        FROM workout_sets ws2
        WHERE ws2.workout_id = workout_sets.workout_id
          AND ws2.id < workout_sets.id
      )
    """);
    WorkoutDatabase._logger.info("Populated number values for workout sets");

    // Now make number non-nullable by recreating the table
    // Step 1: Create new table with non-nullable number
    await customStatement("""
      CREATE TABLE workout_sets_new (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        number INTEGER NOT NULL,
        group_number INTEGER NOT NULL,
        target_reps INTEGER,
        completed_reps INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
      )
    """);

    // Step 2: Copy data from old table to new table
    await customStatement("""
      INSERT INTO workout_sets_new (
        id, workout_id, number, group_number, target_reps, completed_reps
      )
      SELECT
        id, workout_id, COALESCE(number, 1) as number, group_number, target_reps, completed_reps
      FROM workout_sets
    """);

    // Step 3: Drop old table and rename new table
    await customStatement("DROP TABLE workout_sets");
    await customStatement("ALTER TABLE workout_sets_new RENAME TO workout_sets");

    WorkoutDatabase._logger.info("Migration to version 2 completed");
  }

  /// Migration to schema version 3.
  ///
  /// - Recreates `workouts` to make `end` non-nullable
  /// - Backfills `end` with `start` for absolute safety
  Future<void> migrateToVersion3(final Migrator m) async {
    WorkoutDatabase._logger.info("Applying migration to version 3");

    // Make end column non-nullable by recreating the workouts table
    // Step 1: Create new table with non-nullable end
    await customStatement("""
      CREATE TABLE workouts_new (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_type TEXT NOT NULL,
        max_groups INTEGER NOT NULL,
        start INTEGER NOT NULL,
        end INTEGER NOT NULL
      )
    """);

    // Step 2: Copy data from old table to new table, setting end to start for null values
    // this is just a precaution for absolute safety - in reality end will always be set
    await customStatement("""
      INSERT INTO workouts_new (
        id, workout_type, max_groups, start, end
      )
      SELECT
        id, workout_type, max_groups, start, COALESCE(end, start) as end
      FROM workouts
    """);

    // Step 3: Drop old table and rename new table
    await customStatement("DROP TABLE workouts");
    await customStatement("ALTER TABLE workouts_new RENAME TO workouts");

    WorkoutDatabase._logger.info("Migration to version 3 completed");
  }

  /// Migration to schema version 4.
  ///
  /// - Adds `server_id` and `deleted_at` columns needed for cloud sync
  Future<void> migrateToVersion4(final Migrator m) async {
    WorkoutDatabase._logger.info("Applying migration to version 4");

    // Add columns which are needed for the cloud sync
    // Add server_id column
    await m.addColumn(workouts, workouts.serverId);
    WorkoutDatabase._logger.info("Added server_id column to workouts table");
    // Add deleted_at column for soft deletes
    await m.addColumn(workouts, workouts.deletedAt);
    WorkoutDatabase._logger.info("Added deleted_at column to workouts table");

    WorkoutDatabase._logger.info("Migration to version 4 completed");
  }

  /// Migration to schema version 5.
  ///
  /// - Adds indexes for common query patterns
  Future<void> migrateToVersion5(final Migrator m) async {
    WorkoutDatabase._logger.info("Applying migration to version 5");

    // Add indexes for common query patterns
    // Index for getAllNonDeletedWorkouts: WHERE deletedAt IS NULL ORDER BY end
    await customStatement(
      "CREATE INDEX IF NOT EXISTS idx_workouts_deleted_at_end ON workouts(deleted_at, end)",
    );
    WorkoutDatabase._logger.info("Created index idx_workouts_deleted_at_end");

    // Index for getWorkoutsForSync: WHERE serverId IS NULL OR serverId IN (...) ORDER BY end
    await customStatement(
      "CREATE INDEX IF NOT EXISTS idx_workouts_server_id_end ON workouts(server_id, end)",
    );
    WorkoutDatabase._logger.info("Created index idx_workouts_server_id_end");

    // Index for loadRelatedWorkoutSets: WHERE workoutId IN (...) ORDER BY workoutId, number
    await customStatement(
      "CREATE INDEX IF NOT EXISTS idx_workout_sets_workout_id_number ON workout_sets(workout_id, number)",
    );
    WorkoutDatabase._logger.info("Created index idx_workout_sets_workout_id_number");

    WorkoutDatabase._logger.info("Migration to version 5 completed");
  }

  /// Migration to schema version 6.
  ///
  /// - Adds `idempotency_key` column to `workouts` and `workout_sets` tables
  /// - Creates unique indexes on `idempotency_key` columns
  Future<void> migrateToVersion6(final Migrator m) async {
    WorkoutDatabase._logger.info("Applying migration to version 6");

    // Add idempotency_key column to workouts table as nullable first
    await customStatement("ALTER TABLE workouts ADD COLUMN idempotency_key TEXT");
    WorkoutDatabase._logger.info(
      "Added idempotency_key column to workouts table (nullable)",
    );

    // Generate UUIDs for existing workouts using a simpler approach
    // SQLite doesn't have a built-in UUID function, so we'll generate a simple unique string
    // For existing rows, we'll use a combination of id and timestamp
    await customStatement("""
      UPDATE workouts
      SET idempotency_key = lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6)))
      WHERE idempotency_key IS NULL
    """);
    WorkoutDatabase._logger.info("Generated idempotency keys for existing workouts");

    // Now make idempotency_key non-nullable by recreating the workouts table
    // Step 1: Create new table with non-nullable idempotency_key
    await customStatement("""
      CREATE TABLE workouts_new (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        workout_type TEXT NOT NULL,
        max_groups INTEGER NOT NULL,
        start INTEGER NOT NULL,
        end INTEGER NOT NULL,
        deleted_at INTEGER,
        idempotency_key TEXT NOT NULL
      )
    """);

    // Step 2: Copy data from old table to new table
    await customStatement("""
      INSERT INTO workouts_new (
        id, server_id, workout_type, max_groups, start, end, deleted_at, idempotency_key
      )
      SELECT
        id, server_id, workout_type, max_groups, start, end, deleted_at,
        COALESCE(idempotency_key, lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6)))) as idempotency_key
      FROM workouts
    """);

    // Step 3: Drop old table and rename new table
    await customStatement("DROP TABLE workouts");
    await customStatement("ALTER TABLE workouts_new RENAME TO workouts");

    // Recreate indexes
    await customStatement(
      "CREATE INDEX IF NOT EXISTS idx_workouts_deleted_at_end ON workouts(deleted_at, end)",
    );
    await customStatement(
      "CREATE INDEX IF NOT EXISTS idx_workouts_server_id_end ON workouts(server_id, end)",
    );
    // Create unique index on idempotency_key
    await customStatement(
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_workouts_idempotency_key ON workouts(idempotency_key)",
    );
    WorkoutDatabase._logger.info("Created unique index on workouts.idempotency_key");

    // Add idempotency_key column to workout_sets table as nullable first
    await customStatement("ALTER TABLE workout_sets ADD COLUMN idempotency_key TEXT");
    WorkoutDatabase._logger.info(
      "Added idempotency_key column to workout_sets table (nullable)",
    );

    // Generate UUIDs for existing workout sets
    await customStatement("""
      UPDATE workout_sets
      SET idempotency_key = lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6)))
      WHERE idempotency_key IS NULL
    """);
    WorkoutDatabase._logger.info(
      "Generated idempotency keys for existing workout sets",
    );

    // Now make idempotency_key non-nullable by recreating the workout_sets table
    // Step 1: Create new table with non-nullable idempotency_key
    await customStatement("""
      CREATE TABLE workout_sets_new (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        number INTEGER NOT NULL,
        group_number INTEGER NOT NULL,
        target_reps INTEGER,
        completed_reps INTEGER NOT NULL,
        idempotency_key TEXT NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
      )
    """);

    // Step 2: Copy data from old table to new table
    await customStatement("""
      INSERT INTO workout_sets_new (
        id, workout_id, number, group_number, target_reps, completed_reps, idempotency_key
      )
      SELECT
        id, workout_id, number, group_number, target_reps, completed_reps,
        COALESCE(idempotency_key, lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', abs(random()) % 4 + 1, 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6)))) as idempotency_key
      FROM workout_sets
    """);

    // Step 3: Drop old table and rename new table
    await customStatement("DROP TABLE workout_sets");
    await customStatement("ALTER TABLE workout_sets_new RENAME TO workout_sets");

    // Recreate index
    await customStatement(
      "CREATE INDEX IF NOT EXISTS idx_workout_sets_workout_id_number ON workout_sets(workout_id, number)",
    );
    // Create unique index on idempotency_key
    await customStatement(
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_workout_sets_idempotency_key ON workout_sets(idempotency_key)",
    );
    WorkoutDatabase._logger.info(
      "Created unique index on workout_sets.idempotency_key",
    );

    WorkoutDatabase._logger.info("Migration to version 6 completed");
  }
}
