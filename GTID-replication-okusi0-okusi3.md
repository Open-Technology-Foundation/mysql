# GTID Replication: okusi0 → okusi3 (okusinet)

Real-time MySQL 8.0 GTID-based replication for the `okusinet` database.
Replaces the previous unreliable rsync+inotify sync mechanism.

## Overview

| Detail | okusi0 (source) | okusi3 (replica) |
|--------|-----------------|------------------|
| Role | Canonical / read-write | Read-only webserver |
| MySQL version | 8.0.45 | 8.0.45 |
| IP address | 192.168.1.153 | 192.168.1.154 |
| server_id | 1 | 3 |
| okusinet | 54 tables + 5 views (339 MB) | Synced from okusi0 |
| Engines | 33 MyISAM, 15 InnoDB, 1 MEMORY | Synced from okusi0 |

## Pre-flight Checklist

- [ ] Both servers running MySQL 8.0.45
- [ ] `log_bin` enabled on both (already ON)
- [ ] `binlog_format = ROW` on both (already ROW)
- [ ] Network connectivity: okusi3 can reach okusi0:3306
- [ ] Schedule a low-traffic maintenance window for the initial dump

## Phase 1 — Configure okusi0 (Source)

### 1.1 Set server_id

Edit `/etc/mysql/mysql.conf.d/mysqld.cnf` on okusi0:

```ini
[mysqld]
server_id = 1
```

This makes the default explicit. No restart is needed if it was already 1:

```bash
ok0 "mysql -e \"SHOW VARIABLES LIKE 'server_id'\""
```

### 1.2 Enable GTID (online, no restart)

GTID can be enabled at runtime in MySQL 8.0 using the stepped approach.
Run each statement on okusi0 and wait before proceeding to the next.

```sql
-- Step 1: Warn about non-GTID-safe statements
SET PERSIST enforce_gtid_consistency = WARN;
```

Check the error log for warnings. Fix any non-GTID-safe statements before continuing:

```bash
ok0 "tail -50 /var/log/mysql/error.log | grep -i gtid"
```

Common non-GTID-safe patterns to look for:
- `CREATE TABLE ... SELECT`
- `CREATE TEMPORARY TABLE` inside transactions
- Transactions mixing InnoDB and non-InnoDB updates

```sql
-- Step 2: Enforce GTID consistency
SET PERSIST enforce_gtid_consistency = ON;

-- Step 3: Allow both anonymous and GTID transactions
SET PERSIST gtid_mode = OFF_PERMISSIVE;

-- Step 4: Allow only GTID transactions (anonymous still accepted)
SET PERSIST gtid_mode = ON_PERMISSIVE;
```

Wait until all anonymous transactions have completed:

```sql
SHOW STATUS LIKE 'Ongoing_anonymous_transaction_count';
```

Repeat until the count is `0`, then:

```sql
-- Step 5: Require GTID for all transactions
SET PERSIST gtid_mode = ON;
```

### 1.3 Create replication user

Using IP address because okusi3 has `skip-name-resolve` enabled:

```sql
CREATE USER 'replicator'@'192.168.1.154' IDENTIFIED BY '<password>';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'192.168.1.154';
FLUSH PRIVILEGES;
```

▲ Replace `<password>` with a strong password. Store it securely.

### 1.4 Verify source configuration

```sql
SHOW VARIABLES LIKE 'gtid_mode';          -- ON
SHOW VARIABLES LIKE 'enforce_gtid%';      -- ON
SHOW VARIABLES LIKE 'server_id';          -- 1
SHOW MASTER STATUS\G
```

The `SHOW MASTER STATUS` output should include an `Executed_Gtid_Set` value.

## Phase 2 — Initial Sync (Full Dump)

### 2.1 Dump okusinet from okusi0

```bash
ok0 "mysqldump --databases okusinet \
  --set-gtid-purged=ON \
  --routines --triggers --events \
  --single-transaction \
  --lock-tables \
  --quick \
  > /tmp/okusinet-initial.sql"
```

| Flag | Purpose |
|------|---------|
| `--set-gtid-purged=ON` | Embeds GTID position so the replica knows where to start |
| `--single-transaction` | Consistent snapshot for InnoDB tables (no locks) |
| `--lock-tables` | Brief read lock for MyISAM tables |
| `--routines` | Include stored procedures and functions |
| `--triggers` | Include triggers |
| `--events` | Include scheduled events |
| `--quick` | Row-by-row retrieval, avoids buffering large tables |

◉ The dump includes a `DROP DATABASE IF EXISTS` / `CREATE DATABASE` block,
so it will fully replace the diverged copy on okusi3.

### 2.2 Transfer to okusi3

```bash
ok0 "scp /tmp/okusinet-initial.sql okusi3:/tmp/"
```

### 2.3 Restore on okusi3

```bash
ok3 "mysql < /tmp/okusinet-initial.sql"
```

This replaces okusi3's diverged `okusinet` (44 tables) with an exact copy
from okusi0 (54 tables + 5 views, 339 MB).

### 2.4 Verify restore

```bash
ok3 "mysql okusinet -e \"SELECT COUNT(*) AS tables FROM information_schema.tables WHERE table_schema = 'okusinet' AND table_type = 'BASE TABLE'\""
```

Should return `54`.

## Phase 3 — Configure okusi3 (Replica)

### 3.1 Set unique server_id

Edit `/etc/mysql/mysql.conf.d/mysqld.cnf` on okusi3:

```ini
[mysqld]
server_id = 3
```

Apply without restart:

```sql
SET PERSIST server_id = 3;
```

Verify:

```bash
ok3 "mysql -e \"SHOW VARIABLES LIKE 'server_id'\""
```

### 3.2 Enable GTID (online, no restart)

Same stepped process as okusi0:

```sql
SET PERSIST enforce_gtid_consistency = WARN;
-- Check error log, fix any issues
SET PERSIST enforce_gtid_consistency = ON;
SET PERSIST gtid_mode = OFF_PERMISSIVE;
SET PERSIST gtid_mode = ON_PERMISSIVE;
```

Wait for anonymous transactions to drain:

```sql
SHOW STATUS LIKE 'Ongoing_anonymous_transaction_count';
-- Repeat until 0
```

```sql
SET PERSIST gtid_mode = ON;
```

### 3.3 Enable read-only mode

Prevent any application writes to the replica:

```sql
SET PERSIST read_only = ON;
SET PERSIST super_read_only = ON;
```

▲ `super_read_only` blocks writes even from users with SUPER privilege.
The replication SQL thread is exempt and can still apply changes.

### 3.4 Configure replication channel

```sql
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = '192.168.1.153',
  SOURCE_USER = 'replicator',
  SOURCE_PASSWORD = '<password>',
  SOURCE_AUTO_POSITION = 1,
  GET_SOURCE_PUBLIC_KEY = 1;
```

| Parameter | Purpose |
|-----------|---------|
| `SOURCE_AUTO_POSITION = 1` | Use GTID for automatic positioning (no manual BINLOG_FILE/POS) |
| `GET_SOURCE_PUBLIC_KEY = 1` | Required for caching_sha2_password authentication |

### 3.5 Start replication

```sql
START REPLICA;
```

### 3.6 Verify replication status

```sql
SHOW REPLICA STATUS\G
```

Check these fields:

| Field | Expected |
|-------|----------|
| `Replica_IO_Running` | Yes |
| `Replica_SQL_Running` | Yes |
| `Seconds_Behind_Source` | 0 |
| `Last_IO_Error` | (empty) |
| `Last_SQL_Error` | (empty) |
| `Retrieved_Gtid_Set` | Non-empty |
| `Executed_Gtid_Set` | Matches source |

## Phase 4 — Verification

### 4.1 Test replication (insert)

On okusi0:

```sql
USE okusinet;
CREATE TABLE _replication_test (id INT PRIMARY KEY, ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO _replication_test (id) VALUES (1);
```

On okusi3 (within seconds):

```sql
SELECT * FROM okusinet._replication_test;
```

Should return the row inserted on okusi0.

### 4.2 Test read-only enforcement

On okusi3:

```sql
INSERT INTO okusinet._replication_test (id) VALUES (999);
```

Should fail with: `ERROR 1290: The MySQL server is running with the --super-read-only option`.

### 4.3 Clean up test table

On okusi0:

```sql
DROP TABLE okusinet._replication_test;
```

The drop replicates automatically to okusi3.

### 4.4 Compare table counts

```bash
ok0 "mysql okusinet -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='okusinet' AND table_type='BASE TABLE'\""
ok3 "mysql okusinet -e \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='okusinet' AND table_type='BASE TABLE'\""
```

Both should return `54`.

## Phase 5 — Monitoring

### 5.1 Replication health check script

Create `/usr/local/bin/check-replication` on okusi3:

```bash
#!/usr/bin/env bash
set -euo pipefail

declare -- status
status=$(mysql -e "SHOW REPLICA STATUS\G" 2>/dev/null)

declare -- io_running sql_running lag
io_running=$(grep -oP 'Replica_IO_Running: \K\S+' <<< "$status")
sql_running=$(grep -oP 'Replica_SQL_Running: \K\S+' <<< "$status")
lag=$(grep -oP 'Seconds_Behind_Source: \K\S+' <<< "$status")

if [[ $io_running != "Yes" || $sql_running != "Yes" ]]; then
  echo "✗ Replication BROKEN — IO: ${io_running}, SQL: ${sql_running}" >&2
  exit 1
fi

if [[ $lag != "NULL" ]] && (( lag > 300 )); then
  echo "▲ Replication lag: ${lag}s" >&2
  exit 1
fi

echo "✓ Replication OK (lag: ${lag}s)"
```

### 5.2 Cron schedule

On okusi3, add to root's crontab:

```
*/5 * * * * /usr/local/bin/check-replication || logger -t replication "Replication alert on okusi3"
```

## Known Considerations

### MyISAM Tables

33 of 54 tables use MyISAM. Replication works correctly with MyISAM, but:
- MyISAM is not crash-safe — an unclean shutdown could corrupt tables
- `--lock-tables` in the dump provides consistency for MyISAM
- Consider migrating critical tables to InnoDB over time

### MEMORY Table (emailaddresses)

The `emailaddresses` table uses the MEMORY engine:
- Table contents are lost on MySQL restart (by design)
- After a restart, the replica receives the `CREATE TABLE` via replication but the table is empty
- The source must re-populate it, and those INSERT statements replicate normally
- This matches current behavior — no special handling needed

### Replication Scope

This configuration replicates **all databases** by default. To restrict to `okusinet` only,
add a replication filter on okusi3:

```sql
CHANGE REPLICATION SOURCE TO ... FOR CHANNEL '';
CHANGE REPLICATION FILTER REPLICATE_DO_DB = (okusinet);
```

▲ Only add filters if other databases on okusi0 should NOT replicate.

### Network Interruptions

GTID replication with `SOURCE_AUTO_POSITION = 1` automatically resumes
from the correct position after network interruptions. No manual intervention needed.

### Retiring the rsync+inotify Service

After replication is confirmed working, disable the old sync mechanism:

```bash
ok3 "systemctl stop okusinet-sync && systemctl disable okusinet-sync"
```

▲ Verify the service name — check with `systemctl list-units | grep -i sync` first.

## Quick Reference

```bash
# Check replication status
ok3 "mysql -e \"SHOW REPLICA STATUS\\G\""

# Check GTID mode on both servers
ok0 "mysql -e \"SHOW VARIABLES LIKE 'gtid_mode'\""
ok3 "mysql -e \"SHOW VARIABLES LIKE 'gtid_mode'\""

# Stop/start replication on okusi3
ok3 "mysql -e \"STOP REPLICA\""
ok3 "mysql -e \"START REPLICA\""

# Check replication lag
ok3 "mysql -e \"SHOW REPLICA STATUS\\G\" | grep Seconds_Behind"

# View replication errors
ok3 "mysql -e \"SHOW REPLICA STATUS\\G\" | grep -E 'Last.*Error'"
```

---

*Created: 2026-02-18*

#fin
