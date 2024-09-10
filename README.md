# zsh-copilot

Get suggestions **truly** in your shell. No `suggest` bullshit. Just press `CTRL + Z` and get your suggestion.

![Demo](out.mp4)

## Installation

### Dependencies

Please make sure you have the following dependencies installed:
* zsh-autosuggestions
* jq
* curl
* Docker (for running Ollama in a container)

### Plugin Installation

```bash
git clone https://github.com/YourUsername/zsh-copilot.git ~/.zsh-copilot
echo "source ~/.zsh-copilot/zsh-copilot.plugin.zsh" >> ~/.zshrc
```

### Ollama Setup with Docker

This version of zsh-copilot uses Ollama, which should be run in a Docker container. Here's how to set it up:

1. Pull the Ollama Docker image:
   ```bash
   docker pull ollama/ollama
   ```

2. Run the Ollama container:
   ```bash
   docker run -d --name ollama -p 11434:11434 -v ollama:/root/.ollama ollama/ollama
   ```

3. Pull the llama3 model (or any other model you want to use):
   ```bash
   docker exec -it ollama ollama pull llama3
   ```

## Configuration

By default, the plugin will use the "llama3" model with Ollama. You can configure the following environment variables in your `~/.zshrc`:

```bash
export ZSH_COPILOT_OLLAMA_URL="http://localhost:11434"  # Ollama API URL
export ZSH_COPILOT_OLLAMA_MODEL="llama3"  # Ollama model to use
export ZSH_COPILOT_KEY="^z"  # Key to trigger suggestions (default: CTRL+Z)
export ZSH_COPILOT_SEND_CONTEXT=true  # Whether to send context information to the model
export ZSH_COPILOT_DEBUG=false  # Enable debug mode
```

If you're running Ollama on a different machine or port, adjust the `ZSH_COPILOT_OLLAMA_URL` accordingly.

To see available configurations, run:

```bash
zsh-copilot --help
```

## Usage

Type in your command or your message and press `CTRL + Z` (or your configured key) to get your suggestion!

## Differences from Original Version

This fork uses Ollama instead of the OpenAI API, which means:
- No API key is required
- You can use it with locally running models in a Docker container
- You have more control over the model and can easily switch between different models

## Troubleshooting

If you encounter any issues:

1. Make sure the Ollama Docker container is running:
   ```bash
   docker ps | grep ollama
   ```
   If it's not running, start it with:
   ```bash
   docker start ollama
   ```

2. Check that the Ollama API URL is correct (default is http://localhost:11434)
3. Verify that the model you're trying to use is available in your Ollama container:
   ```bash
   docker exec -it ollama ollama list
   ```
4. Enable debug mode by setting `export ZSH_COPILOT_DEBUG=true` and check the log file at `/tmp/zsh-copilot.log`

If problems persist, please open an issue on the GitHub repository.
