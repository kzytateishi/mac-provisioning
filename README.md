# mac-provisioning

Ansible で Mac をセットアップする。アプリ・CLI・macOS の設定・ディレクトリ構成・dotfiles の配置まで、
自動化できるものはここで、できないものは下の「手動で行う設定」に書く。

## 新しい Mac で

1. Homebrew をインストールする。<https://brew.sh/ja/>
2. Ansible をインストールする。

   ```sh
   brew install ansible gh go-task
   ```

3. Dropbox をインストールする。

   ```sh
   brew install --cask dropbox
   ```

4. Dropbox にログインする。
5. このリポジトリを clone する。

   ```sh
   gh auth login --git-protocol https --web
   mkdir -p ~/workspace
   gh repo clone kzytateishi/mac-provisioning ~/workspace/mac-provisioning
   ```

6. プロビジョニングを実行する。

   ```sh
   cd ~/workspace/mac-provisioning
   task
   ```

## 2 回目以降

```sh
cd ~/workspace/mac-provisioning
task                       # = ansible-playbook localhost.yml -K
task run -- --tags homebrew,dock   # 部分実行
task check                 # --check --diff で変更予定を見る
task lint                  # yamllint + ansible-lint
```

`-K` は sudo パスワード用(Spotlight、ファイアウォールで使う)。
App Store にサインインしていないときは `--skip-tags mas`。
formula の upgrade を待ちたくないときは `--skip-tags homebrew_upgrade`。

cask(GUI アプリ)の更新は playbook ではやらない。docker-desktop や wireshark の更新は
sudo とターミナルが要るので、手動で実行する:

```sh
brew upgrade --cask
```

## アプリを追加するとき

`brew install` で直接入れず、`roles/homebrew/defaults/main.yml` に足してから playbook で入れる。
cask は `homebrew_cask_packages`、formula は `homebrew_packages`。

```sh
task run -- --tags homebrew
```

公式インストーラなどで先に入れてしまったアプリは、リストに足したうえで既存の app ごと cask に取り込む
(取り込まないと playbook が「既に app がある」で失敗する):

```sh
brew install --cask --adopt <cask>
```

## ロール

| ロール | やること |
| --- | --- |
| `mac_defaults` | DNS、Dock、Finder、トラックパッド、キーボード、スクリーンショット、CleanShot X の `defaults` |
| `homebrew` | tap、formula、cask の追加と upgrade |
| `mas` | App Store アプリ(Final Cut Pro、Amphetamine、Canva、Xcode) |
| `dock` | Dock の並びを `dockutil` で揃える。未インストールのアプリは警告 |
| `display` | 内蔵ディスプレイを「スペースを拡大」にする(`displayplacer`) |
| `log_cleaner` | `~/workspace/**/log/*.log` を毎朝 10 時に空にする LaunchAgent |
| `working_directories` | `~/workspace` と、Dropbox への `~/Documents` `~/Pictures` 配下の symlink。`~/Documents` 配下の構成は個人的なのでリポジトリに置かず、`~/Dropbox/05_Dev/mac-provisioning/working_directories.yml` から読む(書き方は `roles/working_directories/files/working_directories.yml.example`) |
| `zsh` | Zinit と tmux の tpm |
| `ssh` | `~/.ssh` → `~/Dropbox/90_Secrets/ssh` の symlink |
| `dotfiles` | `kzytateishi/dotfiles` を clone して `task install`。Dropbox 管理の `.aws` 等も link。iTerm2 の設定の読み込み先を dotfiles にする |
| `mise` | dotfiles の `~/.config/mise/config.toml` に沿って言語ランタイムを入れる |
| `npm` | npm のグローバルパッケージ(gemini-cli) |
| `grok_cli` | Grok Build CLI とサンドボックスプロファイル |
| `claude_code` | Claude Code のプラグインマーケットプレイス更新 |
| `spotlight` | Spotlight のインデックスを無効化 |
| `macos_security` | ファイアウォールを有効化。FileVault が無効なら警告 |

アプリの一覧は `roles/homebrew/defaults/main.yml`、Dock の並びは `roles/dock/defaults/main.yml`。

## 手動で行う設定

パスワードの入力や GUI の操作が要るものは、playbook の後に `task post-setup` で順に片付ける
(`scripts/post-setup.sh`)。済んでいる項目は飛ばすので、何度実行してもよい。

- SSH 鍵をキーチェーンに登録、atuin にログインして同期
- FileVault を有効にする、スクリーンセーバ開始後 5 秒でパスワードを要求
- スクリーンセーバの選択、Apple Watch でロック解除(設定画面を開く)
- Karabiner のドライバ機能拡張と入力監視の許可(設定は dotfiles の symlink で自動で読まれる)
- Raycast にサインインして Cloud Sync を有効化(Pro)。同期されない設定は `Raycast.rayconfig` から取り込む。拡張 Paste as Plain Text の有効化
- CleanShot X のライセンスの有効化と、画面収録・アクセシビリティの許可
- Cursor のプロファイルの取り込み。取り込むコマンドが無いので、Cursor を開いて
  Settings > Profiles > Import Profile... から `~/Dropbox/05_Dev/settings/kzy.code-profile` を選ぶ

## トラブルシュート

- `compaudit` で insecure directories と言われたら、該当ディレクトリを `chmod 755` する。
- Java が要るときは `brew install openjdk` の後に
  `sudo ln -sfn $(brew --prefix)/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk`。
- `mas install` が失敗するときは App Store にサインインしているか確認する。
- atuin の鍵は 1Password に保管しておく。新しいマシンのログインで鍵を空欄にすると、
  別の鍵が作られて同期できなくなる。
- `atuin sync` が `Wrong encryption key` で失敗するときは、同期できているマシンで `atuin key` を確認し、
  手元で `atuin store purge && atuin store rekey '<鍵>' && atuin sync` を 1 行で実行する。
  コマンドを分けると、間に自動同期が走ってサーバーから読めない記録が戻ってくる。
  サーバーに別の鍵の記録が混ざっていて鍵が手に入らないときは、正とするマシンで
  `atuin store purge && atuin store verify && atuin store push --force` を実行してサーバーを上書きする
  (サーバー上の読めない記録は消える)。
