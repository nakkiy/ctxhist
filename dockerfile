# ファイル名: Dockerfile
FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# 必要ツールのインストール
RUN apt-get update && \
    apt-get install -y \
        bash \
        curl \
        git \
        fzf \
        asciinema \
        nodejs \
        npm \
        locales && \
    apt-get clean

# 日本語ロケールを有効化（必要なら）
RUN sed -i 's/# ja_JP.UTF-8/ja_JP.UTF-8/' /etc/locale.gen && \
    locale-gen ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# svg-term-cli（agg）をインストール
RUN npm install -g svg-term-cli

# ユーザー作成
RUN useradd -ms /bin/bash demo
USER demo
WORKDIR /home/demo

# histx ファイルを配置
RUN mkdir -p ~/.histx
COPY histx.bash ~/.histx/histx.bash

# ダミー履歴ファイルを用意
RUN mkdir -p ~/demo_project/src/feature && \
    echo "2025-03-26 10:00:00 | /home/demo/demo_project-A/src/feature | cargo build" > ~/.config/histx.log && \
    echo "2025-03-26 10:01:00 | /home/demo/demo_project-A/src/feature | git status" >> ~/.config/histx.log && \
    echo "2025-03-26 10:02:00 | /home/demo/demo_project-B/src/feature | cargo build" > ~/.config/histx.log && \
    echo "2025-03-26 10:03:00 | /home/demo/demo_project-B/src/feature | git status" >> ~/.config/histx.log

# bashrc に histx を読み込ませる
RUN echo '\
export HISTX_LOG_FILE="$HOME/.config/histx.log"\n\
export HISTX_MAX_LINES=10000\n\
export HISTX_BINDKEY_STAY='\''\C-g\C-a'\''\n\
export HISTX_BINDKEY_RESTORE='\''\C-g\C-r'\''\n\
export HISTX_BINDKEY_SUBDIR_STAY='\''\C-o\C-a'\''\n\
export HISTX_BINDKEY_SUBDIR_RESTORE='\''\C-o\C-r'\''\n\
source ~/.histx/histx.bash\n' >> ~/.bashrc
