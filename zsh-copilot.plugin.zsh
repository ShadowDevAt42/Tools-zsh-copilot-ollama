# Configuration variables
(( ! ${+ZSH_COPILOT_KEY} )) &&
    typeset -g ZSH_COPILOT_KEY='^z'

(( ! ${+ZSH_COPILOT_SEND_CONTEXT} )) &&
    typeset -g ZSH_COPILOT_SEND_CONTEXT=true

(( ! ${+ZSH_COPILOT_DEBUG} )) &&
    typeset -g ZSH_COPILOT_DEBUG=false

# Ollama configuration
(( ! ${+ZSH_COPILOT_OLLAMA_URL} )) &&
    typeset -g ZSH_COPILOT_OLLAMA_URL="http://localhost:11434"

(( ! ${+ZSH_COPILOT_OLLAMA_MODEL} )) &&
    typeset -g ZSH_COPILOT_OLLAMA_MODEL="llama3"

# System prompt
read -r -d '' SYSTEM_PROMPT <<- EOM
  You are a shell command assistant. Your task is to either complete the command or provide a new command that you think the user is trying to type.
  If you return a completely new command for the user, prefix it with an equal sign (=).
  If you return a completion for the user's command, prefix it with a plus sign (+).
  MAKE SURE TO ONLY INCLUDE THE REST OF THE COMPLETION!!!
  Do not write any leading or trailing characters except if required for the completion to work.
  Only respond with either a completion or a new command, not both.
  Your response may only start with either a plus sign or an equal sign.
  Your response MAY NOT start with both! This means that your response IS NOT ALLOWED to start with '+=' or '=+'.
  Do not provide explanations or additional information.
  Your response will be run in the user's shell.
  Make sure input is escaped correctly if needed.
  Your input should be able to run without any modifications to it.
EOM

if [[ "$OSTYPE" == "darwin"* ]]; then
    SYSTEM="Your system is ${$(sw_vers | xargs | sed 's/ /./g')}."
else 
    SYSTEM="Your system is ${$(cat /etc/*-release | xargs | sed 's/ /,/g')}."
fi

function _suggest_ai() {
    if [[ "$ZSH_COPILOT_SEND_CONTEXT" == 'true' ]]; then
        local PROMPT="$SYSTEM_PROMPT 
            Context: You are user $(whoami) with id $(id) in directory $(pwd). 
            Your shell is $(echo $SHELL) and your terminal is $(echo $TERM) running on $(uname -a).
            $SYSTEM"
    fi
    
    # Get input
    local input=$(echo "${BUFFER:0:$CURSOR}" | tr '\n' ';')
    input=$(echo "$input" | sed 's/"/\\"/g')

    _zsh_autosuggest_clear
    zle -R "Thinking..."

    PROMPT=$(echo "$PROMPT" | tr -d '\n')

    local data="{
        \"model\": \"$ZSH_COPILOT_OLLAMA_MODEL\",
        \"prompt\": \"$PROMPT\n\nUser: $input\nPlease provide a single command suggestion, prefixed with '=' for a new command or '+' for a completion. Do not provide explanations.\",
        \"stream\": false
    }"

    local response=$(curl "${ZSH_COPILOT_OLLAMA_URL}/api/generate" \
        --silent \
        -H "Content-Type: application/json" \
        -d "$data")

    # Clean the response to remove all control characters
    local cleaned_response=$(echo "$response" | tr -d '\000-\037')

    # Try to parse with jq, if it fails, use grep as a fallback
    local full_message=$(echo "$cleaned_response" | jq -r '.response // empty' 2>/dev/null)
    if [[ -z "$full_message" ]]; then
        full_message=$(echo "$cleaned_response" | grep -oP '(?<="response":")[^"]*')
    fi

    if [[ -z "$full_message" ]]; then
        zle -R "Error: Unable to parse AI response"
        return 1
    fi

    # Extract the first line of the message
    local message=$(echo "$full_message" | head -n 1)

    local first_char=${message:0:1}
    local suggestion=${message:1}
    
    if [[ "$ZSH_COPILOT_DEBUG" == 'true' ]]; then
        touch /tmp/zsh-copilot.log
        echo "$(date);INPUT:$input;RESPONSE:$cleaned_response;FIRST_CHAR:$first_char;SUGGESTION:$suggestion:DATA:$data" >> /tmp/zsh-copilot.log
    fi

    if [[ "$first_char" == '=' ]]; then
        # Reset user input
        BUFFER=""
        CURSOR=0
        zle -U "$suggestion"
    elif [[ "$first_char" == '+' ]]; then
        _zsh_autosuggest_suggest "$suggestion"
    else
        # If no prefix, treat as a new command
        BUFFER=""
        CURSOR=0
        zle -U "$message"
    fi
}

function zsh-copilot() {
    echo "ZSH Copilot is now active. Press $ZSH_COPILOT_KEY to get suggestions."
    echo ""
    echo "Configurations:"
    echo "    - ZSH_COPILOT_KEY: Key to press to get suggestions (default: ^z, value: $ZSH_COPILOT_KEY)."
    echo "    - ZSH_COPILOT_SEND_CONTEXT: If \`true\`, zsh-copilot will send context information (whoami, shell, pwd, etc.) to the AI model (default: true, value: $ZSH_COPILOT_SEND_CONTEXT)."
    echo "    - ZSH_COPILOT_OLLAMA_URL: URL of the Ollama API (default: http://localhost:11434, value: $ZSH_COPILOT_OLLAMA_URL)."
    echo "    - ZSH_COPILOT_OLLAMA_MODEL: Ollama model to use (default: llama3, value: $ZSH_COPILOT_OLLAMA_MODEL)."
}

zle -N _suggest_ai
bindkey $ZSH_COPILOT_KEY _suggest_ai
