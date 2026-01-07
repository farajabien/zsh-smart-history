# Smart History (Zsh Plugin) 🧠

A lightweight, "smart" history search for Zsh that ranks suggestions by **frequency of use** rather than just recency. The more you use a command, the higher it ranks when you press the **Up** arrow.

## Features

- **Frequency-Based Ranking**: Prioritizes commands you use most often.
- **Context Aware**: Type a prefix (e.g., `npm`) and press **Up** to see your most frequent `npm` commands.
- **Self-Learning**: Automatically tracks usage stats in `~/.zsh_cmd_frequency_log` as you work.
- **Zero Config**: Works out of the box with standard Zsh keybindings.

## Installation

### Manual Installation

1.  **Clone or Download** this repository.
2.  **Source the script** in your `~/.zshrc`:

    ```zsh
    # Example: if you cloned it to ~/.zsh_plugins/smart-history
    source ~/.zsh_plugins/smart-history/zsh-smart-history.plugin.zsh
    ```

3.  **Restart Zsh**:
    ```zsh
    source ~/.zshrc
    ```

### Seeding with existing history

To make it useful immediately, you can "feed" it your existing Zsh history so it knows what you like:

```zsh
# Run this once in your terminal
fc -ln 1 | while read -r line; do echo "$line" >> ~/.zsh_cmd_frequency_log; done
```

## Usage

- **Up Arrow**: Search history (ranked by frequency).
- **Type + Up Arrow**: Search for commands starting with what you typed.

## How it works

1.  **Tracking**: Hooks into `preexec` to increment a counter for every command you run.
2.  **Storage**: Saves stats to `~/.zsh_cmd_frequency_log` (simple text format).
3.  **Widget**: Replaces the standard Up-arrow widget to fetch, sort, and display commands based on the log data.

## License

MIT
