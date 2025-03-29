# `ctxhist`

> **過去のコマンドを、その場所で再現**  
> 実行したディレクトリを記憶する **履歴拡張ツール**

---

## 🧠 なにこれ？

`ctxhist` は、ただの履歴ではなく  
**「いつ・どこで・何をしたか」** を記録し、  
過去に実行した場所で再度実行できる **履歴拡張ツール** です。  

⚠️ `fzf`に依存しています。  
fzf はインタラクティブな検索ツールです（補完・履歴検索に便利）  
ctxhist ではこれを使って過去の履歴を選択できます。

---

## 🔥 デモ
**過去** に **あの場所** で打った**コマンド**をもう一度。

![demo.gif](./demo.gif)

この例では…

1. `/home/demo/work/project1` にいます  
1. `Ctrl-g Ctrl-r` を押して、fzf から過去の `project2`で実行した`cargo run` を選択  
1. 自動で `cur=$PWD; cd /home/demo/work/project2 && cargo run; cd "$cur"` が入力されます  
1. 実行するとその場所で実行し、元の場所に戻ります
1. `Ctrl-g Ctrl-a` を押して、fzf から過去の `project2`で実行した`cargo run` を選択  
1. 自動で `cd /home/demo/work/project2 && cargo run` が入力されます  
1. 実行するとその場所で実行し、その場所に留まります。

---

## 😮 従来の履歴との違い

| 特徴                     | 通常の履歴 (`history` / `Ctrl-r`) | `ctxhist`                        |
|--------------------------|-----------------------------|-------------------------------|
| コマンド検索             | ✅（fzfと併用で可能）            | ✅（fzf連携）                  |
| 実行ディレクトリの記録   | ❌                            | ✅（毎回ログに記録）            |
| 自動ディレクトリ移動     | ❌                            | ✅（stay/restoreで切替）       |
| 重複除去 + 行数制限管理  | ❌ （設定による）             | ✅                             |

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

## ⌨️ モードについて
#### モード比較

| モード     | 説明                             | 例                                      |
|------------|----------------------------------|------------------------------------------|
| `stay`     | 実行後、そのディレクトリに滞在   | `cd ~/proj && docker up` → proj に残る   |
| `restore`  | 実行後、元のディレクトリに戻る   | `cur=$PWD; cd ~/proj && docker up; cd "$cur"`   |

---

## 📂 履歴ログの構造

保存先：`$CTXHIST_LOG_FILE`（デフォルト：`~/.config/.ctxhist.log`）

```
YYYY-MM-DD HH:MM:SS | /path/to/dir | command here
```

---

## 🐚 対応シェルについて
現在、`ctxhist` は **Bash 専用** です。  
**Zsh** には**まだ対応していません** が、今後対応を検討しています。  
  
**Zsh** をお使いの場合、キーバインドやスクリプトの読み込みが正しく**動作しない**可能性があります。

---

## ⚙️ インストール手順

### 1. `fzf` をインストール

```bash
sudo apt install fzf
```

### 2. スクリプト配置 & `.bashrc` に追加

```bash
git clone --depth 1 https://github.com/nakkiy/ctxhist.git ~/.ctxhist
```

`.bashrc` に追記

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

## ⚙️ アンインストール手順

### 1. `.ctxhist.log` 削除

```bash
rm  ~/.ctxhist.log
```

### 2. スクリプト削除 & `.bashrc` 編集

```bash
rm -r ~/.ctxhist
```

インストール時に`.bashrc` に追記した内容を削除

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

### 3. `fzf` アンインストール(任意)

```bash
sudo apt remove fzf
```

---

## ⚙️ 設定可能な環境変数

| 変数名                    | 説明                           | デフォルト値              |
|---------------------------|--------------------------------|----------------------------|
| `CTXHIST_LOG_FILE`          | 履歴ログファイルの保存先        | `~/.ctxhist.log`            |
| `CTXHIST_MAX_LINES`         | ログの最大行数                 | `10000`                   |
| `CTXHIST_EXCLUDE_CMDS`      | 除外コマンド（空白区切り）      | 例: `"ls cd"`             |
| `CTXHIST_BINDKEY_*`         | キーバインド設定               | `\C-g\C-a` など           |

---

## 💬 フィードバック募集中！

気づいたこと・ご意見・改善案などありましたら、[Issue](https://github.com/nakkiy/ctxhist/issues/1) でお気軽にお知らせください！

- 実際に使ってみた感想
- バグ報告や挙動の違和感
- 改善してほしい点や新機能の提案

日本語・英語どちらでも歓迎です 🙌

---

## 🧩 今後の展望

- zsh plugin化してOh-My-Zshに対応するかも

---

## 📄 ライセンス

[MIT License](LICENSE-MIT)
