---
name: tut-slide
description: 豊橋技術科学大学テーマ（白背景・赤/黒二重線・右上大学名ロゴ・左下Tマーク）の学術発表スライドを LaTeX Beamer（推奨）または Marp Markdown で作成する。全レイアウトパターン（タイトル / 篇首+bullet+ハイライト+↓フロー / 2カラム比較 / 図配置3種 / 数式・tikz・algorithm・code）を網羅したテンプレを同梱。/tut-slide 呼び出し時、または「豊橋技科大 スライド」「TUT スライド」「Beamer 学会発表テンプレ」「豊橋技科大 プレゼン」等のキーワード時に使用する。
---

# tut-slide

豊橋技術科学大学の学術発表スタイル（白背景・赤/黒二重線・右上に大学名ロゴ・左下に T マーク・中央寄せの太字タイトル・`・` bullet）のスライドを作るための skill。

- **主推奨**: LaTeX Beamer（LuaLaTeX + luatexja）— 数式・tikz・algorithm・コードなど技術要素まで綺麗に描ける
- **オプション**: Marp Markdown — ブラウザ / VSCode 拡張ですぐ確認したい場合、または Beamer を避けたい場合

`references/` に両方のテーマ本体とテンプレを同梱している。ワークフローは独立（共通中間形式からの変換はしない）。

## ⚠️ ロゴ画像は同梱していない（各自で用意する）

豊橋技術科学大学のロゴの著作権は大学に帰属するため（[サイトポリシー](https://www.tut.ac.jp/site-policy.html)）、**この skill にロゴ画像は含まれていない**。使う人が自分で用意する必要がある。

作業ディレクトリに `images/` を作り、以下の 2 ファイルを置く：

| ファイル名 | 用途 | 推奨 |
|---|---|---|
| `images/tut-logo.png` | 右上の大学名ロゴ（「国立大学法人 豊橋技術科学大学」） | 横長・背景透過 PNG |
| `images/tut-logo2.png` | 左下の T マーク | 正方形に近い・背景透過 PNG |

入手先は大学公式サイト・学内配布のスライドテンプレ・研究室の既存資料など。**学内利用の範囲で使うこと。** 学外への配布物にそのまま載せる場合は大学の規程を確認する。

ロゴが無くてもビルドは通る（LaTeX 側は `\IfFileExists` でスキップ、Marp 側は CSS 背景が空になるだけ）。その場合はロゴ無しのレイアウトとして出力される。

別の場所にロゴを置きたい場合は、`template.tex` の `\usetheme{Toyohashi}` の後に上書きする：

```latex
\renewcommand{\tutlogomain}{path/to/logo.png}
\renewcommand{\tutlogomark}{path/to/mark.png}
```

## クイックスタート（LaTeX Beamer / 推奨）

1. 作業ディレクトリに以下をコピー：
   - `references/template.tex`
   - `references/beamerthemeToyohashi.sty`
2. `images/` を作り、上記のロゴ 2 枚を自分で配置（省略可）
3. `template.tex` を編集（`\title{...}`、`\author{...}`、各フレーム内容を書き換え）
4. ビルド：
   ```bash
   latexmk -lualatex template.tex
   ```
   Fallback（`latexmk` が無い環境）：
   ```bash
   lualatex -interaction=nonstopmode template.tex
   ```

**注意**: 初回コンパイルは luatexja のフォントキャッシュ生成で 10–30 秒かかる。

## クイックスタート（Marp）

1. 作業ディレクトリに以下をコピー：
   - `references/template.md`
   - `references/theme.css`
2. `images/` を作り、上記のロゴ 2 枚を自分で配置（省略可）
3. `template.md` を編集
4. ビルド：
   ```bash
   npx @marp-team/marp-cli template.md --pdf --allow-local-files \
     --theme-set theme.css --output template.pdf
   ```

## フォント方針

- **LaTeX 側**: `template.tex` に、macOS の Hiragino Kaku Gothic ProN が使える環境ではそれを優先し、無ければ `luatexja-preset` の HaranoAjiGothic に自動フォールバックする `\IfFontExistsTF` 分岐を埋め込み済み。別フォントを使いたい場合は `\setmainjfont` の指定を書き換える。
- **Marp 側**: CSS で `Hiragino Kaku Gothic ProN` → `Yu Gothic` → `Noto Sans CJK JP` → `IPAexGothic` の順にシステムフォントをフォールバック。

## レイアウトパターン一覧

テンプレには以下のパターンを 1 スライドずつ含む。編集時はコメントで区切っているので、不要なものは削除、必要なら複製して増やす。

| # | パターン | LaTeX | Marp |
|---|---|---|---|
| 1 | タイトルスライド | `\maketitle` | `<!-- _class: lead -->` |
| 2 | 篇首 + bullet + ハイライト + ↓フロー | `frame` + `itemize` + `tuthighlight`（tcolorbox）+ tikz矢印 | `<div class="highlight-box">` + `<div class="down-arrow">↓</div>` |
| 3 | 2カラム比較 | `columns` / `column` | `<div class="cols">` |
| 4 | 両カラム図 | `columns` + `tikzpicture` | `<div class="cols">` + `![](img)` |
| 5 | 左説明 / 右図 | `columns` (0.5 / 0.48) | `<div class="cols">` |
| 6 | 横広×縦小の図（下配置） | `\vfill` + `center` | `<div class="figbox short">`（`margin-top: auto`） |
| 7 | 数式 | `align`（amsmath） | `$$ ... $$`（KaTeX） |
| 8 | tikz 図 | `tikzpicture` | Marp では画像化を推奨 |
| 9 | algorithm | `algorithm2e` | Marp では画像化を推奨 |
| 10 | コードブロック | `listings`（デフォルト）または `minted`（要 `-shell-escape`） | ` ```lang ` |

## 図配置ガイド

- 通常は 2 カラム（左説明 / 右図）または右上ロゴを避けた 2 カラムに図を並べる
- **横広×縦小の図**（横長グラフ・タイムラインなど）は、上部に置くとタイトル・二重線と干渉するため、`\vfill` でスライド下側に押し出して配置する
- 縦長の図は右カラムに置き、左に説明文を書く

### Marp 側の注意

**Marp CLI は inline `style` 属性を削除する**（`class` だけ通る）。サイズ指定は `theme.css` の修飾クラスで行う：

| クラス | 高さ | 用途 |
|---|---|---|
| `figbox` | 240px | 標準の図枠 |
| `figbox tall` | 300px | 縦長の図 |
| `figbox short` | 130px + `margin-top: auto` | 横広×縦小の図をスライド下端へ（LaTeX の `\vfill` 相当） |

独自サイズが要るときは inline style ではなく `theme.css` にクラスを追加する。

## 高度な要素（LaTeX でのみ推奨）

- 数式（`\begin{align} ... \end{align}`）
- tikz 図（フロー図・ネットワーク図・状態遷移図）
- `algorithm2e` による疑似コード
- コード表示（`listings` はシンプル・ポータブル、`minted` はハイライトが強力だが `-shell-escape` 必要）

Marp でこれらを使いたい場合は、LaTeX で単体 PDF/PNG を出力してから `![](image.png)` で埋め込む。

## 注意事項

- **ロゴのライセンス**: 上記のとおりロゴ画像は同梱していない。著作権は豊橋技術科学大学に帰属する（[サイトポリシー](https://www.tut.ac.jp/site-policy.html)）ため、各自で入手し、学内利用の範囲で使うこと。ロゴを含んだ成果物を再配布する場合は大学の規程を確認する。
- **minted 使用時**: Python の Pygments と `-shell-escape` オプションが必要。`latexmk -lualatex -shell-escape template.tex` のように叩く。回避したい場合はテンプレのデフォルトである `listings` を使う。
- **Marp の tikz/algorithm**: Marp は KaTeX 数式まで native サポート。tikz や algorithm を使いたい場合は素直に LaTeX Beamer 版を選ぶこと。
