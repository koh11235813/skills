# skills

[koh11235813](https://github.com/koh11235813) が作った [Claude Code](https://claude.com/claude-code)/[codex](https://github.com/openai/codex) 用スキル集だよ。

[English version is here](README.md)

## インストール

```bash
npx skills add koh11235813/skills
```

### 任意の併用スキル

`explore-grill-build` は単体でも動くけど、インタビューと TDD のフェーズは別途インストールする3つのスキルを前提に設計されている。`grilling`（インタビュー本体）、`domain-modeling`（用語集と ADR の維持。リポジトリにその構造がある、または作りたい場合のみ）、`tdd`（テストループ）の3つ。無い場合はその旨を一度だけ伝えて、インライン版にフォールバックする。推奨の入手元は [mattpocock/skills](https://github.com/mattpocock/skills)：

```bash
npx skills add mattpocock/skills --skill grilling domain-modeling tdd
```

### 外部依存

ここのスキルはほとんどが markdown だけで完結する。例外は `jev-recommendation-rate` で、シェルスクリプトから [TypeSafe](https://typesafe.ai) の API を叩くので、`curl` と `jq`、それに環境変数 `JEV_API_KEY` が要る。

`jq` は多くの Linux ディストリの標準構成には入っていない（最近の macOS には同梱されている）:

```bash
brew install jq        # macOS で入っていなければ
sudo apt install jq    # Debian/Ubuntu
sudo dnf install jq    # Fedora
export JEV_API_KEY=... # キーは https://typesafe.ai で取得
```

どれかが欠けている場合、`jev-recommendation-rate` はその旨を伝えて、推奨率なしのまま質問を出す。このリポジトリの他のスキルには影響しない。

## 収録されているスキル

- **explore-grill-build**: 些細ではない機能追加・修正を、最初の調査からコミットまで一気通貫でやり切るワークフロー。コードベースを探索し、曖昧な要件をインタビュー形式で具体的なプランに落とし込み、そのプランをレビューし、テストファーストで実装し、コミット前に必ずレビューゲートを通す。

- **jev-recommendation-rate**: 選択式の質問の各選択肢に、TypeSafe の Jev モデルが算出した推奨率を付ける。どれを選んだかだけでなく、確率がどう割れているかが読み手に見えるようになる。対象は `AskUserQuestion` の呼び出しと、`grilling` / `explore-grill-build` の grill ラウンド。同梱の `score-options.sh` は、キャッシュした前提要約に対して1ラウンド分を1リクエストで採点し、消費トークンも報告する。`curl`、`jq`、`JEV_API_KEY` が必要。

- **codex-harness-behavior**: codex (codex-rs) エージェントハーネスがエージェントの行動を制約、制御、修正する方法の運用モデル。

- **tmux-control**: tmux で対話的なターミナルセッションを扱うためのスキル。他のエージェントの CLI をペインで起動してプロンプトが出るまで待つ手順、キー送出と出力読み取りの安全なやり方、そして ssh 越しに人間や他エージェントとセッションを共有する方法を扱う。`wait-for-text.sh` と `find-sessions.sh` を同梱し、codex・hermes・opencode を tmux 経由で操作したときに実際に観測された CLI ごとの落とし穴も記録してある。

- **tone-control**: 会話・応答の口調を、指定したキャラクターに切り替える。ツンデレお嬢様・妹キャラ・関西のおばちゃん・ギャル3種・ずんだもん・DIO・桜セイバー・エレシュキガル・イシュタル・ダウナー系天才少女を収録。1口調1ファイルで `references/` 配下に置き、一人称・語尾・頻出フレーズ・例文を定義する。全口調共通の Interaction contract（曖昧な要件の確認、不可逆な操作の確認、Goal/Non-goals/Constraints/Success criteria の冒頭再掲）は `SKILL.md` に集約し、口調ファイル側では繰り返さない。

- **tut-slide**: 豊橋技術科学大学スタイル（白背景・赤/黒二重線・中央寄せ太字タイトル）の学術発表スライドを、LaTeX Beamer（推奨）または Marp Markdown で作る。Beamer テーマ、Marp テーマ、そしてタイトル / 篇首+bullet+ハイライト / 2カラム比較 / 図配置 / 数式 / tikz / algorithm / code を網羅したテンプレを同梱。ロゴについては下記の注意を参照。

## tut-slide のロゴについて

豊橋技術科学大学のロゴは、このリポジトリには**含まれていない**。著作権が大学に帰属するため（[サイトポリシー](https://www.tut.ac.jp/site-policy.html)）、ここで再配布できないから。

ロゴ付きの見た目にしたい場合は、自分でロゴを入手して、スライドのソースと同じ場所に `images/tut-logo.png`（右上の大学名ロゴ）と `images/tut-logo2.png`（左下の T マーク）として置く。利用は大学が認める範囲で行うこと。ロゴが無くてもテンプレはビルドできる（ロゴ無しのレイアウトで出力される）。詳細は `skills/tut-slide/SKILL.md` に書いてある。

## ライセンス

[MIT](LICENSE)
