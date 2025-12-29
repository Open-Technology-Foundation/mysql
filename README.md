# MySQL Utilities

Bash utilities for MySQL database inspection with formatted output, colorization, and export options.

## Overview

Three cascading utilities provide progressive levels of detail:

```
mysql.databases → mysql.tables → mysql.display-structure
```

| Tool | Description |
|------|-------------|
| `mysql.databases` | List databases, or cascade to tables/structure |
| `mysql.tables` | List tables in a database, or show table structure |
| `mysql.display-structure` | Display detailed table structure with formatting |

## Quick Start

```bash
# List all databases
mysql.databases

# List tables in a database
mysql.databases mydb
mysql.tables mydb

# Show table structure
mysql.databases mydb users
mysql.tables mydb users
mysql.display-structure mydb users
```

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

# Export formats
mysql.display-structure mydb users -f json
mysql.display-structure mydb users -f json -o structure.json
mysql.display-structure mydb users -f csv

# Disable colors
mysql.display-structure mydb users -n

# Pipe mode (from mysql output)
mysql mydb -e 'SHOW COLUMNS FROM users' | mysql.display-structure
```

## Options

All three utilities share a common set of options:

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file (default: ~/.my.cnf) |
| `-c, --columns COLS` | Comma-separated list of columns to display |
| `-f, --format FMT` | Output format: table (default), json, csv |
| `-s, --stats` | Show table statistics (row count, size, indexes) |
| `-n, --no-color` | Disable colorized output |
| `-o, --output FILE` | Write output to file |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

Additional option for `mysql.display-structure`:

| Option | Description |
|--------|-------------|
| `-N, --no-cache` | Disable caching of table information |

## MySQL Authentication

### Default Behavior

Scripts use the MySQL client's default authentication, typically `~/.my.cnf`.

### Using Alternate Profiles

Use `-p/--profile` to specify a different MySQL config file:

```bash
mysql.databases -p ~/.mysql/prod.cnf
mysql.tables -p ~/.mysql/prod.cnf mydb
mysql.display-structure -p ~/.mysql/prod.cnf mydb users
```

### Environment Variables

Set `PROFILE` for session-wide configuration:

```bash
export PROFILE=~/.mysql/prod.cnf
mysql.databases
mysql.tables mydb
mysql.display-structure mydb users
```

Set `DATABASE` to avoid repeating the database name:

```bash
export DATABASE=mydb
mysql.tables
mysql.display-structure users
```

## Output Formats

### Table (default)

Formatted ASCII table with colorized output:
- **Key column**: Primary keys highlighted
- **Type column**: Data types color-coded
- **Null column**: YES/NO indicators
- **Extra column**: auto_increment, etc.

### JSON

```bash
mysql.display-structure mydb users -f json
```

Outputs structured JSON with field definitions.

### CSV

```bash
mysql.display-structure mydb users -f csv
```

Standard CSV format suitable for spreadsheet import.

## Installation

```bash
# Make scripts executable
chmod +x mysql.display-structure mysql.databases mysql.tables

# Enable bash completion (add to ~/.bashrc for persistence)
source mysql.bash_completion
```

## Bash Completion

The completion script provides:
- Option completion (`-p`, `--profile`, etc.)
- Database name completion
- Table name completion
- Format completion (`table`, `json`, `csv`)
- File completion for `-p` and `-o` options

## Dependencies

- MySQL client (`mysql` command)
- `jq` (required for JSON output only)
- Bash 5.2+

#fin
