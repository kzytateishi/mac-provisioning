#!/bin/bash
# playbook の後に、パスワードの入力や GUI の操作が要る設定を順に片付ける。
# Ansible の中では入力待ちで止まるので、playbook とは分けている。
#
#   task post-setup
#
# 済んでいる項目は飛ばすので、何度実行してもよい。
set -euo pipefail

log() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
skip() { printf '\033[0;90m--- %s (済み)\033[0m\n' "$*"; }
# GUI の操作は済んだかを判定できないので、やるかどうかを聞く
confirm() {
  local reply
  read -r -p "$1 [y/N] " reply
  [[ $reply =~ ^[Yy]$ ]]
}
settings() { open "x-apple.systempreferences:$1"; }

# ---------------------------------------------------------------- SSH
SSH_KEY="$HOME/.ssh/id_rsa"
# ssh-add -l は agent に繋がらないと 2 を返す (鍵が無いだけなら 1)。
# SSH で入ったセッションや古い SSH_AUTH_SOCK を持つ tmux で起きるので、止めずに次へ進む
ssh_agent_status=0
ssh-add -l >/dev/null 2>&1 || ssh_agent_status=$?
if [ "$ssh_agent_status" -eq 2 ]; then
  log "ssh-agent に接続できないので飛ばします (Mac の画面で開いたターミナル、tmux の外で実行し直す)"
elif ssh-add -l 2>/dev/null | grep -q "$SSH_KEY"; then
  skip "SSH 鍵をキーチェーンに登録"
elif [ -f "$SSH_KEY" ]; then
  log "SSH 鍵をキーチェーンに登録します (パスフレーズを入力)"
  ssh-add --apple-use-keychain "$SSH_KEY"
else
  log "$SSH_KEY が無いので飛ばします (Dropbox の同期を確認)"
fi

# ---------------------------------------------------------------- atuin
# ログイン済みなら atuin status に Username が出る
if atuin status 2>/dev/null | grep -q "^Username:"; then
  skip "atuin にログイン"
else
  # 鍵を空欄にすると新しい鍵が作られ、サーバーの履歴と鍵が食い違って同期できなくなる。
  # 必ず 1Password に保管した鍵 (同期できているマシンの `atuin key` と同じもの) を貼る
  log "atuin にログインします (鍵は 1Password から貼る。空欄で Enter しない。認証はブラウザで Atuin Hub)"
  atuin login
  atuin sync
fi

# ---------------------------------------------------------------- FileVault
if fdesetup status | grep -q "FileVault is On"; then
  skip "FileVault"
else
  log "FileVault を有効にします。表示される復旧キーは 1Password に保管する"
  sudo fdesetup enable -user "$USER"
fi

# ---------------------------------------------------------------- ロック画面
if sysadminctl -screenLock status 2>&1 | grep -q "delay is 5 seconds"; then
  skip "スクリーンセーバ開始後 5 秒でパスワードを要求"
else
  log "スクリーンセーバ開始後 5 秒でパスワードを要求します (ログインパスワードを入力)"
  sysadminctl -screenLock 5 -password -
fi

# ---------------------------------------------------------------- GUI
if confirm "スクリーンセーバを選びますか?"; then
  settings com.apple.ScreenSaver-Settings.extension
  read -r -p "選んだら Enter: "
fi

if confirm "Apple Watch でのロック解除を設定しますか?"; then
  log "「Apple Watch」のスイッチを入れる"
  settings com.apple.Touch-ID-Settings.extension
  read -r -p "設定したら Enter: "
fi

# ---------------------------------------------------------------- Karabiner
# 設定は dotfiles の symlink で読まれるが、ドライバと入力監視の許可は手で出すしかない。
# 入力監視は判定できないので、ドライバが有効かどうかで済みとみなす。
if systemextensionsctl list 2>/dev/null | grep -q "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice.*\[activated enabled\]"; then
  skip "Karabiner のドライバと入力監視の許可"
else
  log "Karabiner-Elements を開いて、出てくる案内に沿って許可する"
  log "  1. 一般 > ログイン項目と機能拡張 > ドライバ機能拡張 で .Karabiner-VirtualHIDDevice-Manager を許可"
  log "  2. プライバシーとセキュリティ > 入力監視 で karabiner_grabber と Karabiner-Core-Service を許可"
  open -a Karabiner-Elements
  read -r -p "許可したら Enter: "
fi

# ---------------------------------------------------------------- Raycast
# 設定は Raycast Pro の Cloud Sync で戻す。サインイン状態は判定できないので聞く。
# Cloud Sync に乗らない設定は dotfiles の Raycast.rayconfig (Export Settings & Data) から取り込む
if confirm "Raycast にサインインして Cloud Sync を有効にしますか?"; then
  log "Settings > Account でサインインし、Settings > Cloud Sync で右上のトグルをオンにする"
  open -a Raycast
  read -r -p "有効にしたら Enter: "
fi

if confirm "Cloud Sync に乗らない設定を Raycast.rayconfig から取り込みますか?"; then
  log "取り込みの画面でパスワードを入れて Import"
  open "$HOME/workspace/dotfiles/Raycast.rayconfig"
  read -r -p "取り込んだら Enter: "
fi

# 拡張は Cloud Sync で同期されても Mac ごとに有効化が要る

if grep -qs '"name": *"paste-as-plain-text"' "$HOME"/.config/raycast/extensions/*/package.json; then
  skip "Raycast の拡張 Paste as Plain Text"
else
  log "Paste as Plain Text の Install Extension を押す"
  open "https://www.raycast.com/koinzhang/paste-as-plain-text"
  read -r -p "入れたら Enter: "
fi

# ---------------------------------------------------------------- CleanShot X
# 設定とショートカットは playbook で書く。ライセンスと権限は判定できないので聞く
if confirm "CleanShot X のライセンスと権限を設定しますか?"; then
  log "  1. CleanShot X > Settings > Account でサインインしてライセンスを有効にする"
  log "  2. プライバシーとセキュリティ > 画面収録とシステムオーディオ録音 で CleanShot X を許可"
  log "  3. プライバシーとセキュリティ > アクセシビリティ で CleanShot X を許可 (スクロールキャプチャに要る)"
  open -a "CleanShot X"
  read -r -p "設定したら Enter: "
fi

# Cursor のプロファイルは取り込むコマンドが無いので、手で Import Profile する
CURSOR_PROFILE="$HOME/Dropbox/05_Dev/settings/kzy.code-profile"
if confirm "Cursor のプロファイルを取り込みますか?"; then
  log "Settings > Profiles > Import Profile... で $CURSOR_PROFILE を選ぶ"
  open -a Cursor
  read -r -p "取り込んだら Enter: "
fi

log "post-setup が終わりました"
