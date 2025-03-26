# `ctxhist`

> **過去のコマンドを、“その場所・その状況”で完璧に再現**  
> 文脈を記憶する Bash 履歴拡張ツール

---

## 🧠 なにこれ？

`ctxhist` は、ただの履歴ではなく  
**「いつ・どこで・何をしたか」** を記録し、  
その文脈ごと再利用できる **文脈付き履歴機能** です。

---

## 🔥 デモでわかる：cd はもう履歴に要らない

📽️ *以下のGIFをご覧ください*

![demo.gif](demo.gif)

この例では…

1. 現在 `/tmp` にいます  
1. `Ctrl-g Ctrl-a` を押して、fzf から過去の `docker compose up` を選択  
1. 自動で `cd ~/project-b && docker compose up` が入力されます  
1. 実行するとその場所で実行が始まり、**そのままそこに滞在**できます！

ctxhist は、コマンドを「どこで実行したか」も記録しているので、  
実行したいコマンドを選ぶだけで、その場所に移動して実行してくれます。

`restore` モード（`Ctrl-g Ctrl-r`）を使えば、`cur=$PWD; cd ~/project-b && docker compose up; cd "$cur"`となり実行後に元の場所に戻ることも可能です。

---

## 😮 従来の履歴との違い

| 特徴                     | 通常の履歴 (`history` / `Ctrl-r`) | `ctxhist`                        |
|--------------------------|-----------------------------|-------------------------------|
| コマンド検索             | ✅（fzfと併用で可能）            | ✅（fzf連携）                  |
| 実行ディレクトリの記録   | ❌                            | ✅（毎回ログに記録）            |
| 自動ディレクトリ移動     | ❌                            | ✅（stay/restoreで切替）       |
| 重複除去 + 行数制限管理  | ❌                            | ✅                             |

---

## 📦 機能一覧

- `日時 / ディレクトリ / コマンド` を履歴として記録
- `fzf` による全履歴・ディレクトリ別の絞り込み検索
- `stay` / `restore` モードによるディレクトリ移動制御
- ログの重複除去、自動切り詰めによるクリーン管理
- キーバインドで即座に履歴挿入

---

## ⌨️ キーバインド一覧（デフォルト）

| モード     | 全履歴（全ディレクトリ） | サブディレクトリ以下のみ |
|------------|--------------------------|---------------------------|
| **stay**   | `Ctrl-g Ctrl-a`          | `Ctrl-o Ctrl-a`          |
| **restore**| `Ctrl-g Ctrl-r`          | `Ctrl-o Ctrl-r`          |

> 例：`Ctrl-g Ctrl-r` → fzf から履歴選択 → 一時的に移動して実行 → 元の場所へ戻る

環境変数で変更可能（例: `CTXHIST_BINDKEY_STAY`）

---

## 📂 履歴ログの構造

保存先：`$CTXHIST_LOG_FILE`（デフォルト：`~/.ctxhist_log`）

```
YYYY-MM-DD HH:MM:SS | /path/to/dir | command here
```

---

## ⚙️ インストール手順

### 1. `fzf` をインストール

```bash
brew install fzf      # macOS
sudo apt install fzf  # Ubuntu/Debian
```

### 2. スクリプト配置 & `.bashrc` に追加

```bash
git clone --depth 1 https://github.com/nakkiy/ctxhist ~/.ctxhist
```

`.bashrc` に追記：

```bash
export CTXHIST_LOG_FILE="$HOME/.config/ctxhist.log"
export CTXHIST_MAX_LINES=10000
export HISTX_EXCLUDE_CMDS="cd clear ls"
export CTXHIST_BINDKEY_STAY='\C-g\C-a'
export CTXHIST_BINDKEY_RESTORE='\C-g\C-r'
export CTXHIST_BINDKEY_SUBDIR_STAY='\C-o\C-a'
export CTXHIST_BINDKEY_SUBDIR_RESTORE='\C-o\C-r'

source ~/.ctxhist/ctxhist.bash
```

```bash
# 設定反映
source ~/.bashrc
```

---

## ⚙️ 設定可能な環境変数

| 変数名                    | 説明                           | デフォルト値              |
|---------------------------|--------------------------------|----------------------------|
| `CTXHIST_LOG_FILE`          | 履歴ログファイルの保存先        | `~/.ctxhist_log`            |
| `CTXHIST_MAX_LINES`         | ログの最大行数                 | `10000`                   |
| `CTXHIST_EXCLUDE_CMDS`      | 除外コマンド（空白区切り）      | 例: `"ls cd"`             |
| `CTXHIST_BINDKEY_*`         | キーバインド設定               | `\C-g\C-a` など           |

---

## 🧩 今後の展望

- zsh plugin化してOh-My-Zshに対応するかも

---

## 📄 ライセンス

MIT License
