# skills

[koh11235813](https://github.com/koh11235813) が作った [Claude Code](https://claude.com/claude-code)/[codex](https://github.com/openai/codex) 用スキル集だよ。

[English version is here](README.md)

## インストール

```bash
npx skills add koh11235813/skills
```

## 収録されているスキル

- **explore-grill-build** — 些細ではない機能追加・修正を、最初の調査からコミットまで一気通貫でやり切るワークフロー。コードベースを探索し、曖昧な要件をインタビュー形式で具体的なプランに落とし込み、そのプランをレビューし、テストファーストで実装し、コミット前に必ずレビューゲートを通す。

- **codex-harness-behavior** - codex (codex-rs) エージェントハーネスがエージェントの行動を制約、制御、修正する方法の運用モデル。

- **tut-slide** — 豊橋技術科学大学スタイル（白背景・赤/黒二重線・中央寄せ太字タイトル）の学術発表スライドを、LaTeX Beamer（推奨）または Marp Markdown で作る。Beamer テーマ、Marp テーマ、そしてタイトル / 篇首+bullet+ハイライト / 2カラム比較 / 図配置 / 数式 / tikz / algorithm / code を網羅したテンプレを同梱。ロゴについては下記の注意を参照。

## tut-slide のロゴについて

豊橋技術科学大学のロゴは、このリポジトリには**含まれていない**。著作権が大学に帰属するため（[サイトポリシー](https://www.tut.ac.jp/site-policy.html)）、ここで再配布できないから。

ロゴ付きの見た目にしたい場合は、自分でロゴを入手して、スライドのソースと同じ場所に `images/tut-logo.png`（右上の大学名ロゴ）と `images/tut-logo2.png`（左下の T マーク）として置く。利用は大学が認める範囲で行うこと。ロゴが無くてもテンプレはビルドできる（ロゴ無しのレイアウトで出力される）。詳細は `skills/tut-slide/SKILL.md` に書いてある。

## ライセンス

[MIT](LICENSE)
