---
marp: true
theme: toyohashi
paginate: true
math: katex
---

<!--
Toyohashi Tech Marp slide template
Build:
  npx @marp-team/marp-cli template.md --pdf --allow-local-files \
    --theme-set theme.css --output template.pdf

Notes:
- Requires theme.css in the same directory (or pass --theme-set path).
- ./images/tut-logo.png and ./images/tut-logo2.png are optional (unbranded without them).
- Marp CLI strips inline `style` attributes — only `class` survives. Size
  figures with the theme's modifier classes: .figbox / .figbox.tall /
  .figbox.short (short = wide-and-low, pushed to the bottom of the slide).
- For high-end LaTeX content (tikz / algorithm / advanced math), prefer the
  LaTeX Beamer template — render such content to PNG and embed here.
-->


<!-- _class: lead -->
<!-- _paginate: false -->

# スライドタイトル

## サブタイトル（任意）

発表者名 / 2026-07-24

---

## 篇首タイトル

- イーハトーヴのすきとおった風、夏でも底に冷たさをもつ青いそら
- うつくしい森で飾られたモリーオ市、郊外のぎらぎら光る草の波

<div class="down-arrow">↓</div>

<div class="highlight-box">
ここに結論となる強調文を入れる
</div>

---

## 2カラム比較

<div class="cols">
<div>

### 左タイトル

- よだかは、実にみにくい鳥です
- 顔は、ところどころ、味噌をつけたようにまだら
- くちばしは、ひらたくて、耳までさけています

</div>
<div>

### 右タイトル

- 足はまるでよぼよぼで、一間とも歩けません
- 他の鳥は、よだかの顔を見ただけでも、いやになる

</div>
</div>

---

## 両カラム図パターン

<div class="cols">
<div class="figbox">図（左）</div>
<div class="figbox">図（右）</div>
</div>

---

## 左説明 / 右図パターン

<div class="cols">
<div>

- ざしき童子（ぼっこ）というのは、
- このような子供のことをいうのです
- いかにも、うるさく、そうぞうしく…

</div>
<div class="figbox tall">図</div>
</div>

---

## 横広×縦小の図は下配置

- 横に広く縦が短い図（横長グラフ・タイムライン）は
- スライドタイトル・二重線との干渉を避けるため下側に配置する

<div class="figbox short">
横広×縦小の図（例：タイムライン）
</div>

---

## 数式スライド

$$
\mathcal{L}(\theta) = -\sum_{i=1}^{N} \log p_\theta(y_i \mid x_i)
$$

$$
\nabla_\theta \mathcal{L} = -\sum_{i=1}^{N} \nabla_\theta \log p_\theta(y_i \mid x_i)
$$

<div class="highlight-box">
強調したい結論をハイライトボックスに入れる
</div>

---

## コードブロックの例

```c
int main(void) {
    return 0;
}
```

<!--
tikz / algorithm を使いたい場合は素直に LaTeX Beamer テンプレを使うか、
LaTeX で単体 PDF/PNG を出してから ![](image.png) で埋め込む。
-->
