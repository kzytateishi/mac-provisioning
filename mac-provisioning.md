# 環境

# アプリ内の切り替えのショートカットキーを変更する

* [システム環境設定...] > [キーボード] > [ショートカット] > [キーボード] > [次のウィンドウを操作対象にする] をダブルクリックして Option + Tab キーを押す。

# スクリーンセーバーを設定する
* [システム環境設定...] > [デスクトップとスクリーンセーバ] > [スクリーンセーバ] で好きなものを選択する
* [システム環境設定...] > [セキュリティとプライバシー] で [開始後] を 5秒後 に変更する

# Apple Watchでロック解除できる設定を有効にする
[システム環境設定...] > [セキュリティとプライバシー] > [Apple Watchを使ってアプリケーションとこのMacのロックを解除] にチェックする

# Homebrew のインストール

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Dropboxをインストールしてログインする

# 必要なアプリをインストールする

```
$ brew install ansible
$ cd mac-provisioning
$ ansible-playbook -i hosts -vv localhost.yml
$ brew install --cask xquartz wireshark zoom karabiner-elements docker google-japanese-ime
$ ssh-add --apple-use-keychain ~/.ssh/id_rsa
```

# iterm2
[Settings] > [Preferences] > [Load preferences from a custom folder or URL] にチェックを入れる。
[Settings] > [Preferences] > [Load preferences from a custom folder or URL] ~/workspace/dotfiles を選択する。

# Cursor

* [Settings] > [Profiles] > [Import Profile...] から以下のプロファイルを取り込む
  * ~/Dropbox/dev/cursor.code-profile

# Raycast

* ~/workspace/dotfiles/Raycast.rayconfig をインポートする

https://www.raycast.com/koinzhang/paste-as-plain-text

# BitBar

* ~/Dropbox/dev/bitbar/plugin.sh を設定する

# Zinit

zinit self-update

# tmux

* git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


# atuin

## ログイン
atuin login -u username

## 暗号化キーを生成
atuin key

## 同期
atuin sync

# Error対応
compaudit
chmod 755 xxx


brew reinstall openjdk
sudo ln -sfn $(brew --prefix)/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk

sudo mdutil -a -i off
