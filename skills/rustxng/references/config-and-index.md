# Settings files and the local index

## Settings files

Pass one with `rustxng -c FILE` or `SEARXNG_SETTINGS_PATH`. Precedence is CLI flags, then environment variables, then the file, then the embedded defaults.

**Start from a full copy of the repository's [`settings.toml`](https://github.com/sahenjp/RustXNG/blob/main/settings.toml) and edit it.** A file containing only the keys you care about resets the other settings, including those in sections it never mentions, to built-in defaults that can differ from the embedded `settings.toml`. A file holding just two `[search]` keys moved `default_locale` from `en` to an empty string and, going by the source, shrank `cache.max_bytes` from 32 MB to 8 MB. Search results stayed within run-to-run noise in that test, and the engine list, which is merged separately, stayed intact. After starting with any file, compare against what you expect:

```bash
curl -fsS http://127.0.0.1:8888/config | jq '{default_locale, limiter}'
```

Settings worth knowing, under `[search]` unless noted:

| Key | Default | Effect |
| --- | --- | --- |
| `raw_content_limit` | 5 | How many top results get page text. The only way to raise that count. |
| `local_index_path` | empty | Directory of a local index. Relative paths resolve against the server's working directory. |
| `local_index_merge` | `true` | `false` keeps the index open but leaves it out of ranking. |
| `idle_timeout` under `[server]` | 0 | Same as `RUSTXNG_IDLE_TIMEOUT`, and the variable wins. 0 never exits. |

## Local index

An experimental BM25 index (Tantivy) of pages you crawl yourself, merged into upstream results. RustXNG's own benchmark ([docs/LOCAL-INDEX.md](https://github.com/sahenjp/RustXNG/blob/main/docs/LOCAL-INDEX.md)) gained a few points of accuracy at 5,000 pages and nothing beyond that, even at 127,000 pages, so build one for a corpus upstream engines miss rather than to improve results in general.

`rustxng-index` has no `--help`: that prints `unknown command`, and running it with no arguments prints only the subcommand list. These are all its flags:

| Flag | Applies to | Default | Notes |
| --- | --- | --- | --- |
| `--seeds FILE` | `crawl` | none | One URL per line. |
| `--out DIR`, `--index DIR` | all | `index-data` | Interchangeable names for the same option. |
| `--max-pages N` | `crawl` | 500 | |
| `--max-depth N` | `crawl` | 2 | |
| `--workers N` | `crawl` | 4 | Clamped to 1 through 32. |
| `--delay-ms N` | `crawl` | 500 | Interval per host. |
| `--sitemaps` | `crawl` | off | Also seeds from sitemaps. |
| `--limit N` | `search` | 10 | |

```bash
printf 'https://doc.rust-lang.org/book/\n' > seeds.txt
rustxng-index crawl --seeds seeds.txt --out ./index-data --max-pages 500
rustxng-index stats --index ./index-data
rustxng-index search --index ./index-data "ownership and borrowing" --limit 5
```

The crawl respects `robots.txt` and follows only same-host links. Crawling into an existing index adds new URLs and skips known ones, so pages that changed keep their old text. The project's own run took 12.5 minutes for 5,000 pages with 8 workers.

### Using it from the server

A crawl alone changes nothing: the server reads an index only when `local_index_path` names it. The upstream doc's remark that an `index-data/` directory is picked up automatically does not hold, since an existing directory is ignored while the setting is empty.

Set `local_index_path` in a full settings copy as described above, restart, then confirm the merge. A merged hit lists `local_index` in `engines`:

```bash
curl -fsS -G http://127.0.0.1:8888/search --data-urlencode 'q=ownership and borrowing' -d format=json \
  | jq '[.results[] | select(.engines | index("local_index")) | .url]'
```

A request naming exactly one engine skips the merge. A wrong path fails quietly, so this check is what proves the index is live: a missing path logs a warning and the server runs without an index, while an existing directory that holds no index is opened as a new empty one, with no warning and with index files written into it.
