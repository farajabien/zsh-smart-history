# Smart History (Zsh Plugin) 🧠

A lightweight, "smart" history search for Zsh that ranks suggestions by **frequency of use** then by **recency**. The more you use a command, the higher it ranks when you press the **Up** arrow.

## Features

- **Smart Ranking**: Prioritizes commands by **Frequency** (most used) and then **Recency** (last used).
- **Fuzzy Matching**: Type `gc` to find `git commit`, or `npm s` for `npm run start`. Matches characters in order.
- **Instant Cross-Terminal Sync**: Automatically fetches and preserves commands typed in other open terminal windows prior to executing new commands.
- **Timestamped Persistence**: Records Unix epoch timestamps (`<timestamp>|<encoded_cmd>`) for reliable recency and relative time calculations.
- **Enhanced Usage Stats (`smart_history_stats`)**: Displays all ranked commands with visual progress bars, percentage shares, execution counts in parentheses, and relative last used times (e.g. `2m ago`, `1h ago`, `3d ago`).
- **Zero Config**: Works out of the box with standard Zsh keybindings.

## Installation

### Manual Installation

1.  **Clone or Download** this repository.
2.  **Source the script** in your `~/.zshrc`:

    ```zsh
    # Example: if you cloned it to ~/.zsh_plugins/zsh-smart-history
    source ~/.zsh_plugins/zsh-smart-history/zsh-smart-history.plugin.zsh
    ```

3.  **Restart Zsh**:
    ```zsh
    source ~/.zshrc
    ```

### Seeding & Migrating History

To import your existing `.zsh_history` or upgrade a legacy `.zsh_cmd_frequency_log`:

```zsh
# Run the migration script to format history entries with timestamps
zsh migrate_history.zsh
```

## Usage

- **Up Arrow**: Search history (ranked by Frequency & Recency).
- **Type + Up Arrow**: Fuzzy search for commands (e.g., `gc` -> `git checkout`).
- **`smart_history_stats`**: View ranked usage list with progress bars, percentages, execution count `(count)`, and last used timestamps (`smart_history_stats` for all commands, or `smart_history_stats 10` for top 10).

### Example Stats Output

```text
All Commands Ranked by Usage (Total: 45 executions)
----------------------------------------------------------------------------------------------------
Rank | Command                          | Usage Bar              | Count (%)        | Last Used
----------------------------------------------------------------------------------------------------
1    | git status                       | [====================] | (15) (33.3%)     | 2m ago
2    | npm run dev                      | [============        ] | (9)  (20.0%)     | 15m ago
3    | git commit -m "fix"              | [========            ] | (6)  (13.3%)     | 2h ago
----------------------------------------------------------------------------------------------------
```

## Troubleshooting

### "add-zsh-hook: command not found"
The plugin loads this automatically. If you see this error, ensure you are using a standard Zsh installation.

### Commands not appearing?
1. Ensure the plugin is sourced in your `.zshrc`.
2. Check if `~/.zsh_cmd_frequency_log` exists and is writable.
3. Run `smart_history_stats` to inspect recorded entries.

## License
by farajabien 
MIT
