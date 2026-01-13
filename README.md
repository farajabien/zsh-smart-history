# Smart History (Zsh Plugin) 🧠

A lightweight, "smart" history search for Zsh that ranks suggestions by **frequency of use** then by **recency**. The more you use a command, the higher it ranks when you press the **Up** arrow.

## Features

- **Smart Ranking**: Prioritizes commands by **Frequency** (most used) and then **Recency** (last used).
- **Fuzzy Matching**: Type `gc` to find `git commit`, or `npm s` for `npm run start`. Matches characters in order.
- **Smart Sync**: Automatically picks up commands typed in other open terminals instantaneously.
- **Visual Stats**: View your most used commands with `smart_history_stats`.
- **Self-Learning**: Automatically tracks usage stats in `~/.zsh_cmd_frequency_log`.
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

### Seeding with existing history

To make it useful immediately, "feed" it your existing Zsh history:

```zsh
# Run this once to import your current history
fc -ln 1 | while read -r line; do echo "$line" >> ~/.zsh_cmd_frequency_log; done
```

## Usage

- **Up Arrow**: Search history (ranked by Frequency & Recency).
- **Type + Up Arrow**: Fuzzy search for commands (e.g., `gc` -> `git checkout`).
- **`smart_history_stats`**: Run this command to see a bar chart of your top 20 most frequent commands.

## Troubleshooting

### "add-zsh-hook: command not found"
The plugin attempts to load this automatically. If you see this error, ensure you are using a standard Zsh installation.

### Commands not appearing?
1. Ensure the plugin is sourced in your `.zshrc`.
2. Check if `~/.zsh_cmd_frequency_log` exists and is writable.
3. Run `smart_history_stats` to see if commands are being tracked.

## License
by farajabien 
MIT
