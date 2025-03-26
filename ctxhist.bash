# ========================
# ctxhist.bash - Bash + fzf 文脈付きコマンド履歴プラグイン
# ========================

# --- ユーザー設定（環境変数で上書き可能） ---
CTXHIST_LOG_FILE="${CTXHIST_LOG_FILE:-$HOME/.ctxhist_log}"     # ログファイルのパス
CTXHIST_MAX_LINES="${CTXHIST_MAX_LINES:-10000}"                # 保持する最大行数
CTXHIST_BINDKEY_STAY="${CTXHIST_BINDKEY_STAY:-\\C-g\\C-a}"     # 全履歴 + stay モードのキーバインド
CTXHIST_BINDKEY_RESTORE="${CTXHIST_BINDKEY_RESTORE:-\\C-g\\C-r}" # 全履歴 + restore モードのキーバインド
CTXHIST_BINDKEY_SUBDIR_STAY="${CTXHIST_BINDKEY_SUBDIR_STAY:-\\C-o\\C-a}"   # カレント以下 + stay
CTXHIST_BINDKEY_SUBDIR_RESTORE="${CTXHIST_BINDKEY_SUBDIR_RESTORE:-\\C-o\\C-r}" # カレント以下 + restore

# --- コマンド実行時に履歴を記録する関数 ---
_ctxhist_log() {
  local last_cmd
  # 最後に実行されたコマンドを取得（historyコマンドから整形）
  last_cmd=$(HISTTIMEFORMAT= builtin history 1 | sed 's/^[ ]*[0-9]\+[ ]*//')
  [[ -z "$last_cmd" ]] && return

  # 除外コマンド（先頭ワード一致で除外）
  local first_word="${last_cmd%% *}"
  for cmd in $CTXHIST_EXCLUDE_CMDS; do
    if [[ "$first_word" == "$cmd" ]]; then
      return
    fi
  done

  # ツール内部で生成される一時コマンドはログに残さない
  case "$last_cmd" in
    "cur=\$PWD;"* ) return ;;
  esac

  # ログに記録するディレクトリと時刻を取得
  local dir="${CTXHIST_PREV_PWD:-$PWD}"
  local time="$(date '+%F %T')"
  local new_line="$time | $dir | $last_cmd"

  # 重複除去：同じディレクトリ+コマンドを事前に削除
  if [[ -f "$CTXHIST_LOG_FILE" ]]; then
    grep -vF "| $dir | $last_cmd" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" && mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi

  # ログに追記
  echo "$new_line" >> "$CTXHIST_LOG_FILE"

  # ログが長すぎる場合は末尾だけ残す
  local line_count
  line_count=$(wc -l < "$CTXHIST_LOG_FILE" 2>/dev/null)
  if [[ "$line_count" -gt "$CTXHIST_MAX_LINES" ]]; then
    tail -n "$CTXHIST_MAX_LINES" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" && mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi
}

# --- プロンプトごとにログ記録を挿入（冪等） ---
case "$PROMPT_COMMAND" in
  *_ctxhist_log*) ;;  # すでに登録済みならスキップ
  *) PROMPT_COMMAND='_ctxhist_log; '"$PROMPT_COMMAND" ;;
esac

# --- fzfで履歴から1件選択（対象：全体またはカレント以下） ---
_ctxhist_select() {
  local pattern=""
  if [[ "$1" == "." ]]; then
    pattern="$(realpath "$PWD")"
  elif [[ -n "$1" ]]; then
    pattern="$(realpath "$1")"
  fi

  # 条件に合うログを抽出
  local entries
  if [[ -n "$pattern" ]]; then
    entries=$(grep "| $pattern" "$CTXHIST_LOG_FILE" | grep -F "$pattern")
  else
    entries=$(cat "$CTXHIST_LOG_FILE")
  fi

  # fzfで選択
  local selected
  selected=$(echo "$entries" | tac | fzf)
  [[ -z "$selected" ]] && return 1

  # ディレクトリ・コマンドを抽出してグローバル変数に格納
  CTXHIST_SELECTED_DIR=$(echo "$selected" | cut -d'|' -f2 | xargs)
  CTXHIST_SELECTED_CMD=$(echo "$selected" | cut -d'|' -f3- | xargs)
}

# --- 選択コマンドをログに再追加（最新化） ---
_ctxhist_append_log_entry() {
  [[ -z "$CTXHIST_SELECTED_DIR" || -z "$CTXHIST_SELECTED_CMD" ]] && return
  local time="$(date '+%F %T')"
  local new_line="$time | $CTXHIST_SELECTED_DIR | $CTXHIST_SELECTED_CMD"

  # 既存の重複を除去してから追記
  if [[ -f "$CTXHIST_LOG_FILE" ]]; then
    grep -vF "| $CTXHIST_SELECTED_DIR | $CTXHIST_SELECTED_CMD" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" &&
    mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi

  echo "$new_line" >> "$CTXHIST_LOG_FILE"

  # 最大行数制限
  local line_count
  line_count=$(wc -l < "$CTXHIST_LOG_FILE" 2>/dev/null)
  if [[ "$line_count" -gt "$CTXHIST_MAX_LINES" ]]; then
    tail -n "$CTXHIST_MAX_LINES" "$CTXHIST_LOG_FILE" > "${CTXHIST_LOG_FILE}.tmp" &&
    mv "${CTXHIST_LOG_FILE}.tmp" "$CTXHIST_LOG_FILE"
  fi
}

# === 各モードごとの挿入関数 ===

# --- 全履歴 + stay モード（移動してそのまま） ---
ctxhist_insert_stay() {
  _ctxhist_select || return
  READLINE_LINE="cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD"
  READLINE_POINT=${#READLINE_LINE}
  _ctxhist_append_log_entry
}

# --- 全履歴 + restore モード（一時的に移動して戻る） ---
ctxhist_insert_restore() {
  _ctxhist_select || return
  READLINE_LINE="cur=\$PWD; cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD; cd \"\$cur\""
  READLINE_POINT=${#READLINE_LINE}
  _ctxhist_append_log_entry
}

# --- カレント以下 + stay モード ---
ctxhist_insert_subdir_stay() {
  _ctxhist_select "." || return
  READLINE_LINE="cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD"
  READLINE_POINT=${#READLINE_LINE}
  _ctxhist_append_log_entry
}

# --- カレント以下 + restore モード ---
ctxhist_insert_subdir_restore() {
  _ctxhist_select "." || return
  READLINE_LINE="cur=\$PWD; cd \"$CTXHIST_SELECTED_DIR\" && $CTXHIST_SELECTED_CMD; cd \"\$cur\""
  READLINE_POINT=${#READLINE_LINE}
  _ctxhist_append_log_entry
}

# --- Bashのキーバインドに各関数を登録 ---
bind -x "\"$CTXHIST_BINDKEY_STAY\":ctxhist_insert_stay"
bind -x "\"$CTXHIST_BINDKEY_RESTORE\":ctxhist_insert_restore"
bind -x "\"$CTXHIST_BINDKEY_SUBDIR_STAY\":ctxhist_insert_subdir_stay"
bind -x "\"$CTXHIST_BINDKEY_SUBDIR_RESTORE\":ctxhist_insert_subdir_restore"
