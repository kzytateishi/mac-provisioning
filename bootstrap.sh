#!/bin/bash
# 新しい Mac で ansible-playbook が動くところまで持っていき、playbook を実行する。
#
#   curl -fsSL https://raw.githubusercontent.com/kzytateishi/mac-provisioning/main/bootstrap.sh | bash
#   ./bootstrap.sh            # clone 済みならこちら
#   ./bootstrap.sh --tags dock   # 引数は ansible-playbook にそのまま渡す
#
# 冪等なので途中で止まっても再実行すればよい。
set -euo pipefail

REPO="kzytateishi/mac-provisioning"
DEST="$HOME/workspace/mac-provisioning"

log() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf '\033[1;31merror: %s\033[0m\n' "$*" >&2; exit 1; }

# 1. Xcode Command Line Tools (git と clang が要る)
if ! xcode-select -p >/dev/null 2>&1; then
  log "Xcode Command Line Tools をインストールします"
  xcode-select --install
  die "インストールのダイアログが終わったら、もう一度このスクリプトを実行してください"
fi

# 2. Homebrew
if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
  log "Homebrew をインストールします"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. playbook を動かすのに要るもの
log "ansible / gh / go-task をインストールします"
brew install ansible gh go-task

# 4. Dropbox (SSH 鍵と dotfiles の実体が入っている)
if [ ! -d "$HOME/Dropbox/90_Secrets" ]; then
  if [ ! -d /Applications/Dropbox.app ]; then
    log "Dropbox をインストールします"
    brew install --cask dropbox
  fi
  open -a Dropbox || true
  die "Dropbox にログインして同期が終わったら、もう一度このスクリプトを実行してください"
fi

# 5. このリポジトリ
if [ ! -d "$DEST/.git" ]; then
  if ! gh auth status >/dev/null 2>&1; then
    log "GitHub にログインします"
    gh auth login --git-protocol https --web
  fi
  log "$REPO を $DEST に clone します"
  mkdir -p "$(dirname "$DEST")"
  gh repo clone "$REPO" "$DEST"
fi

# 6. 実行
cd "$DEST"
log "sudo が要る cask を入れます (Brewfile.sudo)"
task casks
log "ansible-playbook localhost.yml -K $*"
exec ansible-playbook localhost.yml -K "$@"
