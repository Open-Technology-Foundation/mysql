# MySQL Utilities

Bash utilities for MySQL database inspection with formatted output, colorization, and export options.

## Overview

| Tool | Description |
|------|-------------|
| `mysql.databases` | List databases, or cascade to tables/structure |
| `mysql.tables` | List tables in a database, or show table structure |
| `mysql.display-structure` | Display detailed table structure with formatting |
| `mysql.field-comment` | Read or set column comments |
| `mysql.indexes` | Display index information for tables |
| `mysql.size` | Show database and table sizes |
| `mysql.updates` | Show database and table modification timestamps |
| `mysql.status` | Display MySQL server status overview |
| `mysql.users` | List MySQL users with host patterns |
| `mysql.grants` | Show grants for MySQL users |

### Schema Inspection (cascading)

```
mysql.databases → mysql.tables → mysql.display-structure
```

## Quick Start

```bash
# Server status
mysql.status

# List all databases
mysql.databases

# List tables in a database
mysql.tables mydb

# Show table structure
mysql.display-structure mydb users

# List users and their grants
mysql.users
mysql.grants root@localhost

# Database and table sizes
mysql.size
mysql.size mydb

# Table indexes
mysql.indexes mydb users
```

---

## mysql.status

Display MySQL server status overview.

```bash
mysql.status [OPTIONS]
```

**Examples:**

```bash
mysql.status                         # Basic status
mysql.status -v                      # Extended info (InnoDB, locks, etc.)
mysql.status -p ~/.mysql/prod.cnf    # Use alternate profile
```

**Output:**

```
Server:      8.0.35 (MySQL Community Server - GPL)
Uptime:      15 days 4:23:17
Connections: 1,234 (max: 151)
Threads:     5 running, 12 connected
Queries:     1,234,567 (82.3/sec)
Slow:        123
Open tables: 512 / 4000
```

**Options:**

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file |
| `-v, --verbose` | Show extended status (InnoDB, locks, bytes) |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

---

## mysql.users

List MySQL users with host patterns.

```bash
mysql.users [OPTIONS] [PATTERN]
```

**Examples:**

```bash
mysql.users                          # List all users
mysql.users admin                    # Filter by username pattern
mysql.users '%@localhost'            # Filter by user@host pattern
mysql.users -a                       # Show all columns
```

**Options:**

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file |
| `-a, --all` | Show all columns (plugin, locked, expired) |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

---

## mysql.grants

Show grants for MySQL users.

```bash
mysql.grants [OPTIONS] [USER[@HOST]]
```

**Examples:**

```bash
mysql.grants                         # Current user grants
mysql.grants root                    # Grants for root@%
mysql.grants root@localhost          # Grants for root@localhost
mysql.grants 'admin@10.0.0.%'        # Grants with wildcard host
mysql.grants -a                      # All users' grants
```

**Options:**

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file |
| `-a, --all` | Show grants for all users |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

---

## mysql.indexes

Display index information for MySQL tables.

```bash
mysql.indexes [OPTIONS] DATABASE [TABLE...]
```

**Examples:**

```bash
mysql.indexes mydb                   # Show indexes for all tables in mydb
mysql.indexes mydb users             # Show indexes for users table
mysql.indexes mydb users orders      # Show indexes for multiple tables
```

**Options:**

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

---

## mysql.size

Show database and table sizes.

```bash
mysql.size [OPTIONS] [DATABASE] [TABLE...]
```

**Examples:**

```bash
mysql.size                           # Show all database sizes
mysql.size mydb                      # Show table sizes in mydb
mysql.size mydb users                # Show size of users table
mysql.size mydb users orders         # Show size of multiple tables
```

**Options:**

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

---

## mysql.updates

Show database and table modification timestamps using `information_schema.TABLES`.

```bash
mysql.updates [OPTIONS] [DATABASE] [TABLE...]
```

**Examples:**

```bash
mysql.updates                        # Show all database update times
mysql.updates mydb                   # Show table update times in mydb
mysql.updates mydb users             # Show update time of users table
mysql.updates mydb users orders      # Show update time of multiple tables
mysql.updates -f json mydb           # Export as JSON
mysql.updates -a mydb                # Hide relative age column
```

**Output:**

```
=== Table Updates: mydb ===
+-----------+--------+---------------------+--------+---------------------+-------+
| Table     | Engine | Updated             | Age    | Created             |  Rows |
+-----------+--------+---------------------+--------+---------------------+-------+
| users     | MyISAM | 2026-01-17 10:30:45 | 2h ago | 2025-01-01 00:00:00 | 1,234 |
| sessions  | InnoDB | -                   | Never  | 2025-01-01 00:00:00 |45,678 |
+-----------+--------+---------------------+--------+---------------------+-------+
Note: InnoDB tables may show NULL for UPDATE_TIME (MySQL limitation)
```

**Options:**

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file |
| `-f, --format FMT` | Output format: table (default), json, csv |
| `-n, --no-color` | Disable colorized output |
| `-a, --absolute` | Hide relative age column |
| `-o, --output FILE` | Write output to file |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

**Note:** InnoDB tables may show NULL for UPDATE_TIME due to a MySQL limitation. The Engine column helps identify which tables are affected.

---

## mysql.databases

Entry point for database exploration. Cascades to `mysql.tables` when a database is specified.

```bash
mysql.databases [OPTIONS] [DATABASE] [TABLE...]
```

**Examples:**

```bash
mysql.databases                          # List all databases
mysql.databases mydb                     # List tables in mydb
mysql.databases mydb users               # Show structure of users table
mysql.databases mydb users orders        # Show structure of multiple tables
mysql.databases mydb users -f json       # Export structure as JSON
```

---

## mysql.tables

List tables or show table structure. Cascades to `mysql.display-structure` when table names are provided.

```bash
mysql.tables [OPTIONS] DATABASE [TABLE...]
```

**Examples:**

```bash
mysql.tables mydb                        # List all tables
mysql.tables mydb users                  # Show structure of users table
mysql.tables mydb users orders products  # Show multiple tables
mysql.tables mydb users -s               # Include statistics
mysql.tables mydb users -f csv -o out.csv
```

---

## mysql.display-structure

Display detailed table structure with formatted, colorized output.

```bash
mysql.display-structure [OPTIONS] DATABASE TABLE [TABLE...]
```

**Examples:**

```bash
# Basic usage
mysql.display-structure mydb users
mysql.display-structure mydb users orders products

# Filter columns displayed
mysql.display-structure mydb users -c Field,Type,Null

# Show statistics (row count, size, indexes)
mysql.display-structure mydb users -s

# Show column comments
mysql.display-structure mydb users -C

# Export formats
mysql.display-structure mydb users -f json
mysql.display-structure mydb users -f json -o structure.json
mysql.display-structure mydb users -f csv

# Disable colors
mysql.display-structure mydb users -n

# Pipe mode (from mysql output)
mysql mydb -e 'SHOW COLUMNS FROM users' | mysql.display-structure
```

---

## mysql.field-comment

Read or set MySQL column comments.

```bash
mysql.field-comment [OPTIONS] DATABASE TABLE FIELD [COMMENT]
```

**Examples:**

```bash
# Read current comment
mysql.field-comment mydb users email

# Set a comment
mysql.field-comment mydb users email "Primary email address"
mysql.field-comment mydb orders status "Status: 1=pending, 2=shipped, 3=delivered"

# Dry-run (preview SQL without executing)
mysql.field-comment -n mydb users id "User ID"
```

**Options:**

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file |
| `-n, --dry-run` | Show SQL without executing (set mode only) |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

**Notes:**

When setting comments, the following column types are not supported:
- Columns with `ON UPDATE CURRENT_TIMESTAMP`
- Spatial types (geometry, point, polygon, etc.)
- JSON columns
- Generated/virtual columns
- Partitioned tables

---

## Common Options

Options shared by schema inspection utilities (`mysql.databases`, `mysql.tables`, `mysql.display-structure`):

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file (default: ~/.my.cnf) |
| `-c, --columns COLS` | Comma-separated list of columns to display |
| `-f, --format FMT` | Output format: table (default), json, csv |
| `-s, --stats` | Show table statistics (row count, size, indexes) |
| `-C, --comments` | Include column comments in output |
| `-n, --no-color` | Disable colorized output |
| `-o, --output FILE` | Write output to file |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

---

## MySQL Authentication

### Default Behavior

Scripts use the MySQL client's default authentication, typically `~/.my.cnf`.

### Using Alternate Profiles

Use `-p/--profile` to specify a different MySQL config file:

```bash
mysql.status -p ~/.mysql/prod.cnf
mysql.databases -p ~/.mysql/prod.cnf
mysql.users -p ~/.mysql/prod.cnf
mysql.grants -p ~/.mysql/prod.cnf root
```

### Environment Variables

Set `PROFILE` for session-wide configuration:

```bash
export PROFILE=~/.mysql/prod.cnf
mysql.status
mysql.databases
mysql.users
```

---

## Installation

```bash
# Make scripts executable
chmod +x mysql.*

# Optional: Add to PATH via symlink
ln -s "$(pwd)"/mysql.* ~/.local/bin/

# Enable bash completion
source mysql.bash_completion

# For persistent completion, add to ~/.bashrc:
# source /path/to/mysql.bash_completion
```

## Dependencies

- MySQL client (`mysql` command)
- `jq` (required for JSON output only)
- Bash 5.2+

#fin
