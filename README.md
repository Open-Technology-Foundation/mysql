# MySQL Utilities

Bash utilities for MySQL database inspection.

## Tools

| Tool | Description |
|------|-------------|
| `mysql.display-structure` | Display table structure with formatting, colors, and export options |
| `mysql.databases` | List all databases |
| `mysql.tables` | List tables, or show table structure if table names provided |

## Usage

### mysql.databases

List all MySQL databases:

```bash
mysql.databases
```

### mysql.tables

List tables in a database, or show table structure:

```bash
# List all tables in database
mysql.tables mydb

# Show structure for specific table(s) (shortcut to mysql.display-structure)
mysql.tables mydb users
mysql.tables mydb users orders products
```

### mysql.display-structure

Display table structure with formatted, colorized output:

```bash
# Single table
mysql.display-structure mydb users

# Multiple tables
mysql.display-structure mydb users orders products

# Filter columns
mysql.display-structure mydb users -c Field,Type,Null

# Show statistics (row count, size, indexes)
mysql.display-structure mydb users -s

# Export to JSON
mysql.display-structure mydb users -f json -o structure.json

# Export to CSV
mysql.display-structure mydb users -f csv

# Pipe mode (from mysql output)
mysql mydb -e 'SHOW COLUMNS FROM users' | mysql.display-structure

# Disable colors
mysql.display-structure mydb users -n
```

#### Options

| Option | Description |
|--------|-------------|
| `-p, --profile FILE` | MySQL config file (default: ~/.my.cnf) |
| `-c, --columns COLS` | Comma-separated list of columns to display |
| `-f, --format FMT` | Output format: table (default), json, csv |
| `-s, --stats` | Show table statistics |
| `-n, --no-color` | Disable colorized output |
| `-o, --output FILE` | Write output to file |
| `-h, --help` | Display help |
| `-V, --version` | Display version |

## Using Alternate MySQL Profiles

By default, scripts use `~/.my.cnf` for MySQL authentication. Use `-p` to specify a different config file:

```bash
# Use production credentials
mysql.databases -p ~/.mysql/prod.cnf
mysql.tables -p ~/.mysql/prod.cnf mydb
mysql.display-structure -p ~/.mysql/prod.cnf mydb users

# Or set via environment variable for session-wide default
export PROFILE=~/.mysql/prod.cnf
mysql.databases
mysql.tables mydb users
```

## Installation

```bash
# Make scripts executable
chmod +x mysql.display-structure mysql.databases mysql.tables

# Optional: Enable bash completion
source mysql.bash_completion
```

## Dependencies

- MySQL client (`mysql` command)
- `jq` (required for JSON output only)

#fin
