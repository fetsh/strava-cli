# strava-cli

Command-line interface for Strava API written in OCaml.

## Installation

```bash
opam install . --deps-only
dune build
dune install
```

### Optional: Enable Tab Completion

**Easy Installation (using Makefile):**
```bash
# For Bash (user-level)
make completion-bash
source ~/.bashrc

# For Zsh (user-level)
make completion-zsh
source ~/.zshrc

# For system-wide installation (requires sudo)
make completion-bash-system  # or completion-zsh-system
```

**Manual Installation:**

<details>
<summary>Bash</summary>

```bash
# User-level installation:
mkdir -p ~/.bash_completion.d
cp strava-completion.bash ~/.bash_completion.d/strava
echo "source ~/.bash_completion.d/strava" >> ~/.bashrc
source ~/.bashrc

# System-wide installation:
sudo cp strava-completion.bash /etc/bash_completion.d/strava
```
</details>

<details>
<summary>Zsh</summary>

```bash
# User-level installation:
mkdir -p ~/.zsh/completion
cp strava-completion.zsh ~/.zsh/completion/_strava

# Add to ~/.zshrc if not already present:
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit
source ~/.zshrc

# System-wide installation:
sudo cp strava-completion.zsh /usr/local/share/zsh/site-functions/_strava
```
</details>

**Test it:**
```bash
strava <TAB>              # Shows all commands
strava activity --<TAB>   # Shows --efforts, --raw, --output, --quiet
strava streams 12345 <TAB>  # Shows stream types (heartrate, watts, etc.)
```

## Initial Setup

### 1. Create Strava API Application

1. Go to [https://www.strava.com/settings/api](https://www.strava.com/settings/api)
2. Click "Create an App" (or view existing)
3. Fill in:
   - **Application Name**: `strava-cli` (or any name)
   - **Category**: choose any
   - **Club**: optional
   - **Website**: `http://localhost`
   - **Authorization Callback Domain**: `localhost`
4. Save and note your **Client ID** and **Client Secret**

### 2. Initialize strava-cli

```bash
strava init
```

This will:
1. Ask for your Client ID and Client Secret
2. Open your browser for Strava authorization
3. Start a local server to receive the OAuth callback
4. Store credentials in `~/.config/strava-cli/strava.db`

### 3. Verify Setup

```bash
strava athlete
```

Should display your Strava profile as JSON.

## Usage

### Quick Commands

```bash
# Last activity (full JSON saved to temp file)
strava last

# Last 5 activities
strava last 5

# Today's activities
strava today

# This week's activities
strava week
```

### Athlete

```bash
strava athlete              # Your profile
strava stats                # Your stats (distance, time, etc.)
strava zones                # HR and power zones
```

### Activities

```bash
# List activities
strava activities                          # Recent activities
strava activities --page 2 --per-page 10   # Pagination

# Get activity details
strava activity 12345678                   # Get activity by ID
strava activity 12345678 --efforts         # Include segment efforts

# Activity data
strava streams 12345678 heartrate watts    # Get activity streams
strava laps 12345678                       # Get laps
strava azones 12345678                     # Get zones
strava comments 12345678                   # Get comments
strava kudos 12345678                      # Get kudos
```

Available stream types: `time`, `distance`, `latlng`, `altitude`, `velocity_smooth`, `heartrate`, `cadence`, `watts`, `temp`, `moving`, `grade_smooth`

### Segments

```bash
strava segment 12345                       # Get segment by ID
strava starred                             # Your starred segments
strava starred --page 1 --per-page 20      # Pagination

# Explore segments in area (bounds: SW_LAT,SW_LNG,NE_LAT,NE_LNG)
strava explore --bounds 32.0,34.7,32.2,34.9 --type running
```

### Segment Efforts

```bash
strava efforts --segment 12345             # Your efforts on segment
strava efforts --segment 12345 --start 2024-01-01 --end 2024-12-31
strava effort 987654321                    # Specific effort by ID
```

### Gear & Routes

```bash
strava gear b12345                         # Get gear details
strava routes                              # List your routes
strava routes --page 1 --per-page 10       # Pagination
strava route 12345                         # Get route by ID
```

## Output Options

```bash
strava last                        # Save JSON to /tmp/strava-*.json (default)
strava last --pretty               # Pretty print with tables and emojis
strava last --raw                  # Print JSON to stdout
strava last --output my.json       # Save to specific file
strava last --quiet                # No output, just exit code
```

### Pretty Output Examples

The `--pretty` flag formats output as human-readable tables with emojis:

**Activities:**
```bash
strava activities --pretty --per-page 5
```
```
ID           DATE        TYPE    NAME           DISTANCE  TIME        PACE
-----------  ----------  ------  -------------  --------  ----------  --------
16922800571  2026-01-03  🏃 Run  Lunch Run      26.18 km  2h 18m 46s  5:18 /km
16916981155  2026-01-02  🏃 Run  Night Run      7.52 km   38m 18s     5:05 /km
16911686404  2026-01-02  🏃 Run  Afternoon Run  7.08 km   35m 19s     4:59 /km
```

**Athlete Stats:**
```bash
strava stats --pretty
```
```
📊 Athlete Statistics
=====================

🏃 YTD Runs
-------------
Activities:  5
Distance:    55.41 km
Moving time: 4h 41m 16s
Elevation:   471 m

🏃 Recent Runs (4 weeks)
--------------------------
Activities:  32
Distance:    396.50 km
Moving time: 33h 00m 35s
Elevation:   2741 m

🏃 All Time Runs
------------------
Activities:  1676
Distance:    19680.81 km
Moving time: 1847h 27m 27s
Elevation:   88254 m

🏊 All Time Swims
-------------------
Activities:  451
Distance:    622.27 km
Moving time: 195h 50m 12s
Elevation:   91 m
```

**Activity Details:**
```bash
strava activity 12345678 --pretty
```
```
🏃 Morning Run
==============

🆔 ID:            12345678
📅 Date:          2026-01-03
🏃 Sport:         Run
📏 Distance:      10.5 km
⏱️  Moving time:   45m 30s
⏰ Elapsed time:  48m 15s
⬆️  Elevation:     125 m
🚀 Avg speed:     13.8 km/h
👟 Avg pace:      4:20 /km
❤️  Avg HR:        145 bpm
💓 Max HR:        165 bpm
```

**Athlete Profile with Gear:**
```bash
strava athlete --pretty
```
```
👤 Athlete Profile
==================

Name:     John Doe
Location: San Francisco, USA
Weight:   70.0 kg
Member since: 2018-11-24

🛠️  Gear
=====

ID         TYPE     NAME                        DISTANCE  PRIMARY  RETIRED
---------  -------  --------------------------  --------  -------  -------
b14713521  🚴 Bike  Road Bike Pro               1250.4 km No       No
g15242544  👟 Shoe  Nike Pegasus 40             650.5 km  No       No
g16419603  👟 Shoe  Adidas Ultraboost 22        320.8 km  Yes      No
```

**Gear Details:**
```bash
strava gear g15242544 --pretty
```
```
👟 Nike Pegasus 40
==================

🆔 ID:            g15242544
🏷️  Type:          👟 Shoe
🏭 Brand:         Nike
📦 Model:         Pegasus 40
📏 Distance:      650.5 km
🔔 Alert at:      800 km
```

## jq Examples

Format output as readable tables using `jq`:

### Activities Table

```bash
strava activities --raw --per-page 10 | jq -r '
  "DATE       | TYPE | NAME                          | DISTANCE",
  "-----------|------|-------------------------------|----------",
  (.[] | "\(.start_date_local[0:10]) | \(.sport_type)  | \(.name | .[0:29] + (" " * (29 - (. | length)))) | \((.distance/1000 | . * 100 | round / 100)) km")'
```

Output:
```
DATE       | TYPE | NAME                          | DISTANCE
-----------|------|-------------------------------|----------
2026-01-03 | Run  | Lunch Run                     | 26.18 km
2026-01-02 | Run  | Night Run                     | 7.52 km
2026-01-02 | Run  | Afternoon Run                 | 7.08 km
```

### Detailed Stats with Pace

```bash
strava last 5 --raw | jq -r '
  "ACTIVITY | DATE       | TIME  | DISTANCE | AVG HR | PACE",
  "---------|-----------|-------|----------|--------|--------",
  (.[] | "\(.name | .[0:8]) | \(.start_date_local[0:10]) | \(.start_date_local[11:16]) | \((.distance/1000 | . * 10 | round / 10)) km | \(.average_heartrate // 0 | round)    | \(if .sport_type == "Run" then ((.moving_time / 60) / (.distance / 1000) | . * 10 | round / 10) else "-" end) min/km")'
```

### Total Distance This Week

```bash
strava week --raw | jq '[.[] | .distance] | add / 1000 | round'
```

### Activities by Type

```bash
strava activities --raw --per-page 50 | jq -r '
  group_by(.sport_type) |
  map({type: .[0].sport_type, count: length, distance: (map(.distance) | add / 1000 | round)}) |
  .[] | "\(.type): \(.count) activities, \(.distance) km"'
```

### Extract Specific Fields

```bash
# Just names and dates
strava activities --raw --per-page 5 | jq -r '.[] | "\(.start_date_local[0:10]) - \(.name)"'

# Activity IDs for further processing
strava activities --raw --per-page 5 | jq -r '.[].id'

# Average heart rate for runs
strava activities --raw --per-page 20 | jq '[.[] | select(.sport_type == "Run") | .average_heartrate] | add / length | round'
```

## Credentials

Credentials are stored in SQLite database:
- **Location**: `~/.config/strava-cli/strava.db`
- **Contents**: client_id, client_secret, access_token, refresh_token, expires_at

Tokens are automatically refreshed when expired.

To reset credentials:
```bash
rm ~/.config/strava-cli/strava.db
strava init
```

## Rate Limits

Strava API has rate limits:
- 100 requests per 15 minutes
- 1000 requests per day

The CLI displays rate limit info on 429 errors.

## Scopes

The CLI requests these OAuth scopes:
- `read_all` — read private data
- `activity:read_all` — read all activities including private
- `activity:write` — required for some read endpoints
- `profile:read_all` — read full profile
- `profile:write` — required for some read endpoints

**Note:** This is a read-only CLI. Write scopes are requested because Strava requires them for certain read operations, but no write operations are performed.

## Complete Command Reference

```bash
# Setup
strava init                                # Initialize with API credentials

# Athlete
strava athlete                             # Get profile
strava stats                               # Get activity stats
strava zones                               # Get heart rate/power zones

# Activities
strava activities [--page N] [--per-page N]     # List activities
strava activity <ID> [--efforts]                # Get activity by ID
strava streams <ID> <KEYS...>                   # Get activity streams
strava laps <ID>                                # Get activity laps
strava azones <ID>                              # Get activity zones
strava comments <ID>                            # Get activity comments
strava kudos <ID>                               # Get activity kudos

# Convenience
strava last [N]                            # Last N activities (default: 1)
strava today                               # Today's activities
strava week                                # This week's activities

# Segments
strava segment <ID>                        # Get segment by ID
strava starred [--page N] [--per-page N]   # Get starred segments
strava explore --bounds <BOUNDS> [--type TYPE]  # Explore segments

# Segment Efforts
strava efforts --segment <ID> [--start DATE] [--end DATE]
strava effort <ID>                         # Get effort by ID

# Gear & Routes
strava gear <ID>                           # Get gear by ID
strava routes [--page N] [--per-page N]    # List routes
strava route <ID>                          # Get route by ID

# Output Options (available for all commands)
--pretty                                   # Pretty print with tables and emojis
--raw                                      # Print JSON to stdout
--output <FILE>                            # Save to specific file
--quiet                                    # No output, exit code only
```

**Quick examples:**
```bash
strava activities --pretty              # Beautiful table output with IDs
strava last --pretty                    # Last activity with details
strava last 5 --pretty                  # Last 5 activities table
strava stats --pretty                   # YTD, recent, and all-time stats
strava athlete --pretty                 # Profile with gear table
strava gear <ID> --pretty               # Gear details
```

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

### Quick Start for Contributors

```bash
# Clone and setup
git clone https://github.com/fetsh/strava-cli.git
cd strava-cli
opam install . --deps-only

# Build
dune build

# Run tests
dune exec strava -- --help

# Install locally
dune install
```

### Project Structure

```
strava-cli/
├── bin/main.ml              # CLI entry point
├── lib/
│   ├── db.ml                # SQLite storage
│   ├── auth.ml              # OAuth flow
│   ├── api.ml               # HTTP client
│   ├── commands.ml          # Command implementations
│   └── strava.ml            # Public interface
└── README.md
```

## License

MIT - see [LICENSE](LICENSE) file for details
