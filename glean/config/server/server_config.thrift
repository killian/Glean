// @generated SignedSource<<c8d67c46781b4089b9229977c53481ae>>
// DO NOT EDIT THIS FILE MANUALLY!
// This file is a mechanical copy of the version in the configerator repo. To
// modify it, edit the copy in the configerator repo instead and copy it over by
// running the following in your fbcode directory:
//
// configerator-thrift-updater glean/server/server_config.thrift

// Copyright (c) Facebook, Inc. and its affiliates.

namespace hs Glean
namespace java.swift com.facebook.glean.server_config
namespace py glean.server_config
namespace py3 glean
namespace php glean
namespace cpp2 glean.server_config

typedef string RepoName
typedef i64 Seconds

typedef i64 DBVersion (hs.newtype)

// A retention policy for local DBs, specifying when DBs get
// automatically deleted.  The default is to never delete any DBs.
struct Retention {
  1: optional Seconds delete_if_older;
  // If set, DBs older than this value will be deleted.
  5: optional Seconds delete_incomplete_if_older;
  // If set, incomplete DBs older than this value will be deleted.
  2: optional i32 retain_at_least;
  // Retain at least this many DBs. Overrides delete_if_older and
  // retain_at_most. Note: the value here specifies a number of
  // *complete* databases to retain; incomplete or failed databases
  // are not subject to this retention.
  3: optional i32 retain_at_most;
  // If set, and we have more than this many local DBs, the oldest
  // will be deleted.
  4: optional i32 expire_delay;
  // If set, instead of deleting a DB immediately, we keep it in an
  // "expiring" state for this many seconds. In this state, the DB
  // can still be queried as normal, but it will not be suggested to
  // new clients, and it will be removed from the shard map shortly
  // before it is actually deleted.
  6: optional Seconds remote_db_bumps_local_db_after;
// A local DB can be deleted if there is a newer remote DB that is
// at least this old. This is for use in a multi-shard setting
// where we might have old DBs on a server but they won't be
// deleted if the shards holding the newer DBs are on other
// servers; in that case we need some mechanism to eventually
// delete the stale local DB. If not set, we only delete local DBs
// according to delete_if_older and retain_at_most.
}

struct DatabaseRetentionPolicy {
  1: Retention default_retention;
  // Retention to use if not overridden by repos
  2: map<RepoName, Retention> repos = {};
// Retention policy to use per repo name
}

// If restore is enabled, then repos are restored from backup,
// according to the DatabaseRetentionPolicy for the repo name.
// DatabaseBackupPolicy.location is the location to restore from.
struct DatabaseRestorePolicy {
  1: bool enabled = false;
  2: set<RepoName> override = [];
// if enabled is true, this is a blocklist
// if enabled is false, this is an allowlist
}

struct DatabaseClosePolicy {
  1: Seconds close_after = 1800;
// Close any open DBs after this much idle time
}

struct Backup {
  1: string location = "manifold:glean_databases/nodes/dev-backup";
  // Location to restore from or backup to.
  2: i32 delete_after_seconds = 2592000; // 30 days
// Delete backups this many seconds after uploading. 0 = never
}

struct DatabaseBackupPolicy {
  4: set<RepoName> (hs.type = "HashSet") allowed = [];
  // What to back up
  3: string location = "manifold:glean_databases/nodes/dev-backup";
  // Default location to restore from or backup to, unless
  // overridden by an entry in repos below.

  5: map<RepoName, Backup> repos = {};
  // Backup policy to use per DB name

  1: bool enabled = false;
  // DEPRECATED
  2: set<RepoName> override = [];
// DEPRECATED
}

// Server will be serving just a subset of the glean dbs specified in the policy
// Glean dbs are sharded by db name, so the list bellow just represents
// a list of dbs to be served by this server
struct StaticShardsPolicy {
  1: set<RepoName> shards;
}

// Server will serve all known glean dbs
struct NoShardsPolicy {}

// Delegate the sharding allocation to ShardManager
struct ShardManagerPolicy {
  1: i32 nshards;
  // The total number of shards, as specified in the ShardManager spec
  2: string service_name;
  // The Shard Manager service name
  3: string default_domain_id = "default";
}

struct ShardManagerMostRecentPolicy {
  1: ShardManagerPolicy shard_manager_policy;
  2: string most_recent_domain_id;
// The domain id used to track the most recent db instances
// All other db instances should use the default domain id
}

union ShardingPolicy {
  1: StaticShardsPolicy static_assignment;
  2: NoShardsPolicy no_shards;
  3: ShardManagerPolicy shard_manager;
  // A sharding policy for a domain-less Shard Manager spec
  4: ShardManagerMostRecentPolicy shard_manager_most_recent;
// Sharding for all dbs except the most recent instances for each db name
}

// Configeration for Glean Servers
struct Config {
  1: DatabaseRetentionPolicy retention;
  2: DatabaseRestorePolicy restore;
  3: DatabaseClosePolicy close;
  4: DatabaseBackupPolicy backup;
  5: optional Seconds janitor_period;
  // How often to run the janitor, which initiates backup, restore,
  // and deletion operations on databases.  If missing, the janitor
  // will never run and none of these operations will be performed.
  21: Seconds backup_list_sync_period = 300;
  // How often to query for backups. Runs in the janitor so a
  // timespan less than janitor_period will query for backups every
  // janitor run.
  6: optional i64 default_max_results;
  // If the user doesn't suppliy a max_results, then this is what we
  // use. Note: setting this makes it impossible to do a query with
  // unlimited results (which is arguably a good thing).
  18: optional i64 default_max_bytes;
  // If the user doesn't suppliy a max_bytes, then this is what we
  // use. Note: setting this makes it impossible to do a query with
  // unlimited bytes (which is arguably a good thing).
  20: optional i64 default_max_time_ms;
  // If the user doesn't supply a max_time_ms, then this is what we
  // use. Note: setting this makes it impossible to do a query with
  // unlimited time (which is arguably a good thing).
  7: optional i64 query_alloc_limit;
  // An allocation limit to protect the server from bugs and runaway
  // queries.
  8: i32 logging_rate_limit = 50;
  // Max logs/s per method
  9: i32 db_writes_keep = 1200;
  // how long to keep to keep write results for (in seconds)
  10: i32 db_writes_reap = 300;
  // how often to reap writes (in seconds)
  11: i32 db_writer_threads = 48;
  // Number of threads processing write requests from the queue
  12: i32 db_write_queue_limit_mb = 10000;
  // Write queue size limit in MB
  13: i32 db_ptail_checkpoint_bytes = 2000000000;
  14: bool db_ptail_checkpoint_enabled = true;
  // whether and how often to save checkpoints for ptail-based writes
  15: i32 db_rocksdb_cache_mb = 8000;
  // size of shared rocksdb cache in MB (0 means don't have a shared cache)
  16: i32 db_lookup_cache_limit_mb = 1000;
  // lookup cache size limit for each database in MB
  19: optional DBVersion db_create_version;
  // What binary representation to use for newly created databases
  // (nothing means use latest supported).
  22: bool disable_predicate_dependency_checks = false;
  // Disable completed dependencies check in stored predicates derivation
  // process.
  23: bool compact_on_completion = false;
  // Should we compact the DB when it is complete, and before it is backed up?
  // For production use this should normally be true.
  24: bool enable_schema_evolution = true;
  // DEPRECATED
  25: Seconds min_db_age = 0;
  // The minimum age (in seconds) of a DB before we consider listing with
  // GleanService.listDatabases(). The idea here is that if we wait a
  // little while, there's a better chance that the DB will have propagated
  // to all the servers.
  26: ShardingPolicy sharding = {"no_shards": {}};
  // Out of all available and restorable databases, this server may serve
  // only part of them and sharding policy descrbes how the server picks them
  27: bool use_schema_id = true;
  // If true, queries will use schema_id instead of schema_version
  // to resolve the query. Specifically the server will use the
  // first one that exists in the following list:
  //   * schema_id from the UserQuery request
  //   * --schema-id flag passed to the server
  //   * glean.schema_id from the DB
  //   * the latest all.N in the current schema instance

  // If true, enable RocksDB's cache_index_and_filter_blocks
  28: bool db_rocksdb_cache_index_and_filter_blocks = false;

  // If true, a query that specifies a non-existent SchemaId will be
  // rejected.  If false, the query is performed using the DB's
  // schema, which might result in a response that the client doesn't
  // understand, leading to e.g. a deserialization failure.
  29: bool strict_query_schema_id = false;
}
