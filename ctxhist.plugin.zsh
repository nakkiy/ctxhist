# ========================
# ctxhist.zsh - Zsh-compatible version of ctxhist.bash
# ========================

# --- User-configurable variables ---
CTXHIST_LOG_FILE="${CTXHIST_LOG_FILE:-$HOME/.ctxhist_log}"
CTXHIST_MAX_LINES="${CTXHIST_MAX_LINES:-10000}"
CTXHIST_BINDKEY_STAY="${CTXHIST_BINDKEY_STAY:-^G^A}"
CTXHIST_BINDKEY_RESTORE="${CTXHIST_BINDKEY_RESTORE:-^G^R}"
CTXHIST_BINDKEY_SUBDIR_STAY="${CTXHIST_BINDKEY_SUBDIR_STAY:-^O^A}"
CTXHIST_BINDKEY_SUBDIR_RESTORE="${CTXHIST_BINDKEY_SUBDIR_RESTORE:-^O^R}"

# --- Function to log commands ---
function _ctxhist_log {
  local last_cmd
  last_cmd=$(fc -ln -1)
  [[ -z "$last_cmd" ]] && return

  local first_word="${last_cmd%% *}"
  for cmd in $CTXHIST_EXCLUDE_CMDS; do
    [[ "$first_word" == "$cmd" ]] && return
  done

  case "$last_cmd" in
    "cur=\$PWD;"* ) return ;;
  esac

  local dir="$PWD"
  local time="$(date '+%F %T')"
  local new_line="$time | $dir | $last_cmd"

  if [[ -f "$CTXHIST_LOG_FILE" ]]; then
    grep -vF "| $dir | $last_cmd" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" && mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi

  echo "$new_line" >> "$CTXHIST_LOG_FILE"

  local line_count=$(wc -l < "$CTXHIST_LOG_FILE" 2>/dev/null)
  if [[ "$line_count" -gt "$CTXHIST_MAX_LINES" ]]; then
    tail -n "$CTXHIST_MAX_LINES" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" && mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi
}

# Hook into Zsh's precmd (before prompt)
autoload -Uz add-zsh-hook
add-zsh-hook precmd _ctxhist_log

# --- FZF-based selection ---
function _ctxhist_select {
  local pattern=""
  [[ "$1" == "." ]] && pattern="$(realpath "$PWD")"

  local entries
  if [[ -n "$pattern" ]]; then
    entries=$(grep "| $pattern" "$CTXHIST_LOG_FILE" | grep -F "$pattern")
  else
    entries=$(cat "$CTXHIST_LOG_FILE")
  fi

  local selected
  selected=$(echo "$entries" | tac | fzf)
  [[ -z "$selected" ]] && return 1

  CTXHIST_SELECTED_DIR=$(echo "$selected" | cut -d'|' -f2 | xargs)
  CTXHIST_SELECTED_CMD=$(echo "$selected" | cut -d'|' -f3- | xargs)
}

function _ctxhist_append_log_entry {
  [[ -z "$CTXHIST_SELECTED_DIR" || -z "$CTXHIST_SELECTED_CMD" ]] && return

  local time="$(date '+%F %T')"
  local new_line="$time | $CTXHIST_SELECTED_DIR | $CTXHIST_SELECTED_CMD"

  if [[ -f "$CTXHIST_LOG_FILE" ]]; then
    grep -vF "| $CTXHIST_SELECTED_DIR | $CTXHIST_SELECTED_CMD" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" &&
    mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi

  echo "$new_line" >> "$CTXHIST_LOG_FILE"

  local line_count=$(wc -l < "$CTXHIST_LOG_FILE" 2>/dev/null)
  if [[ "$line_count" -gt "$CTXHIST_MAX_LINES" ]]; then
    tail -n "$CTXHIST_MAX_LINES" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" &&
    mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi
}

# --- Mode functions wrapped as ZLE widgets ---
function ctxhist_insert_stay {
  _ctxhist_select || return
  LBUFFER="cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD"
  _ctxhist_append_log_entry
}

function ctxhist_insert_restore {
  _ctxhist_select || return
  LBUFFER="cur=\$PWD; cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD; cd \"\$cur\""
  _ctxhist_append_log_entry
}

function ctxhist_insert_subdir_stay {
  _ctxhist_select "." || return
  LBUFFER="cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD"
  _ctxhist_append_log_entry
}

function ctxhist_insert_subdir_restore {
  _ctxhist_select "." || return
  LBUFFER="cur=\$PWD; cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD; cd \"\$cur\""
  _ctxhist_append_log_entry
}

# --- Bind keys using ZLE + bindkey ---
zle -N ctxhist_insert_stay
zle -N ctxhist_insert_restore
zle -N ctxhist_insert_subdir_stay
zle -N ctxhist_insert_subdir_restore

bindkey "$CTXHIST_BINDKEY_STAY" ctxhist_insert_stay
bindkey "$CTXHIST_BINDKEY_RESTORE" ctxhist_insert_restore
bindkey "$CTXHIST_BINDKEY_SUBDIR_STAY" ctxhist_insert_subdir_stay
bindkey "$CTXHIST_BINDKEY_SUBDIR_RESTORE" ctxhist_insert_subdir_restore
