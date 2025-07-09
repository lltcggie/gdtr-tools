# Godot Translation Tools

## Introduction

Godotエンジンの翻訳機能を使用しているゲームを翻訳するためのツール。

このモジュールに含まれている機能:

- PCK/EXEから翻訳csvの復元
- 翻訳csvをPCK/EXEへ埋め込み

このモジュールはGodot 4.xをサポートしている。

## Installation

対象のゲームが暗号化されていない場合はこちらからダウンロード可能: https://github.com/lltcggie/gdtr-tools/releases

暗号化されている場合はキーを指定してビルドを行う必要がある。

※対象のゲームが暗号化されている場合は製作者の意思を尊重してキーをなるべく隠ぺいするためビルドを必須とする仕組みにしている。

## Build

### 下準備

Godot Engineのビルド環境が必要。

公式ドキュメントに従ってsconsとコンパイラをインストールする。
(今のところコンパイラで動作を確認したのはVisual Studio Community 2022のみ)

https://docs.godotengine.org/ja/4.x/contributing/development/compiling/introduction_to_the_buildsystem.html
https://docs.godotengine.org/ja/4.x/contributing/development/compiling/compiling_for_windows.html

### このツールのビルド

翻訳したいゲームが暗号化されていると仮定する。

1. 対象ゲームの暗号化キーを特定する。
2. `_build.bat` を開き `SCRIPT_AES256_ENCRYPTION_KEY` の値を特定した暗号化キーに置き換える。
3. `_build.bat` を実行する。
4. `modules\gdtr\standalone\.export\gdtr-tools.exe` が生成される。

## Usage

このツールはCLIのみをサポートしている。

```bash
gdtr-tools.exe <main_command> [options]
```
```
Main commands:
--extract-translation=<GAME_PCK/EXE/APK/DIR>    Extract translations csv on the specified PCK, APK, EXE.
--replace-translation=<GAME_PCK/EXE/APK>        Replace and add translations on the specified PCK, APK, or EXE.

Extract Translations Options:
--output=<DIR>                 Output directory, defaults to <NAME_extracted>, or the project directory if one of specified
--translation-hint-file=<FILE> Hint file to recover translation keys
--old-translation-csv=<FILE>   Old translation csv file to sort keys and translation keys (can be repeated)

Replace Translations Options:
--translation-csv=<SRC_FILE>=<DEST_FILE>    The csv file to replace/add the translation (e.g. "/path/to/file.csv=res://file.csv") (can be repeated)
--patch-file=<SRC_FILE>=<DEST_FILE>      	The file to patch the PCK with (e.g. "/path/to/file.ttf=res://file.ttf") (can be repeated)
```

## 想定している使用方法

- 対象ゲームのpckが `Game.pck.org` というパスにあると仮定する。(元のpckを上書きしないように `Game.pck` からリネームしたと仮定する)
- 対象ゲームの翻訳csvが `translation.csv` であると仮定する。
- 対象ゲームの.translationファイルが `res://translation.en.translation` に存在すると仮定する。

### 初回

---

最初に翻訳csvを復元して `extract` フォルダへ出力する。
```bash
gdtr-tools.exe "--extract-translation=Game.pck.org" "--output=extract"
```

`extract/translation.csv` に翻訳csvが出力される。が、おそらくキーの多くが `<!MissingKey:` で始まっていると思われる。これはキーの復元に失敗している。キーの復元に失敗したテキストはゲームに翻訳が反映されないのでできる限り復元できるようにする必要がある。

より多くのキーを復元するにはキーのヒントを与える必要がある。ヒントは以下のようにして与えることが出来る。復元に失敗していたキーがヒントに含まれていれば復元に成功するようになる。
```bash
gdtr-tools.exe "--extract-translation=Game.pck.org" "--output=extract" --translation-hint-file=trans_hint.txt
```

`trans_hint.txt` の例
```
skill.fire.name
skill.fire.description
skill.ice.name
skill.ice.description
```

ヒントファイル作成補助のため、extract-translation実行時に翻訳csvだけではなく以下のテキストファイルも出力される。

- `all_resource_strings.txt` 全リソースに含まれる文字列
- `tr_use_script_strings.txt` `tr()` を使用しているスクリプトに含まれる文字列

主なキーの復元に失敗している原因はキーを実行時に生成していることなので、 `tr_use_script_strings.txt` はかなり参考になるはず。

gdsdecompなどを使用してスクリプトを復元して `tr()` を使用している箇所の周辺を追うのも有効。

---

可能な限りキーを復元できた `translation.csv` が出力できたら `ja` 列を足すなどして訳文を追加する。

翻訳した `translation.csv` を `Game.pck.org` と同じフォルダに置く。

さらに `tr()` を通してはいないがボタンなど翻訳できるテキストを `add_translation.csv` として用意したとする。
(ちなみにこれらのテキストを `translation.csv` に含めないのは、含めてしまうと下記の `更新があった場合` に必ず削除された文章として認識されてしまうため)

`add_translation.csv` の例
```
key,en,ja
Save,Save,セーブ
Music,Music,音楽
```

用意した翻訳csvを組み込んだpckを生成する。
```bash
gdtr-tools.exe "--replace-translation=Game.pck.org" "--output=Game.pck" --translation-csv=translation.csv=res://translation.csv --translation-csv=add_translation.csv=res://add_translation.csv
```

フォントを差し替える必要がある場合は以下のように差し替え可能。例えば差し替え先のフォントが `res://font/file.ttf` にある場合はこのようなコマンドになる。
```bash
gdtr-tools.exe "--replace-translation=Game.pck.org" "--output=Game.pck" --translation-csv=translation.csv=res://translation.csv --translation-csv=add_translation.csv=res://add_translation.csv --patch-file=file.ttf=res://font/file.ttf
```

---

差し替え後にゲームを動かすと翻訳されているはず。キーの復元に失敗したテキストは `skill.fire.name` のようにキーが表示されるようになる。そのようなテキストを見かけた場合はキーをヒントファイルに追加してextract-translationを再度実行すれば翻訳できるようになるはず。

### 更新があった場合

対象ゲームが更新された場合、以下のようにすることで更新に追従するためのcsvを生成できる。ここでの `translation.csv` は更新前に作成された翻訳csv。(--old-translation-csvで指定したcsvのキーはヒントとして自動的に使用されるため--translation-hint-fileの指定は不要。ただし新しく復元に失敗したキーが出てきた場合は--translation-hint-fileで新たにヒントを与える必要がある)
```bash
gdtr-tools.exe "--extract-translation=Game.pck.org" "--output=extract" --old-translation-csv=translation.csv
```

このコマンドを実行すると `extract\translation_diff_fmt.csv` が生成される。これは `extract\translation.csv` にさらに更新に追従するための情報が入ったフォーマットになっている。

- 並び順が `translation.csv` を尊重したものになっている。
  - 以前から存在しているキーは先頭から `translation.csv` と同じ順番で並ぶ。
  - 追加されたキーは以前から存在していたキー群の下に追加される。
- 例えば原文がenの場合、 `old_en,is_add_en,is_update_en,is_remove_en` 列が追加されている。
  - `old_en`: 更新前の英文。
  - `is_add_en`: 今回の更新で追加された場合は `1` そうでない場合は空
  - `is_update_en`: 今回の更新で文章が変更された場合は `1` そうでない場合は空
  - `is_remove_en`: 今回の更新で削除された場合は `1` そうでない場合は空

## 作成した翻訳の配布
想定している使用方法通りであれば、例えば以下のファイル構成をゲームがあるフォルダにコピーする形で配布できる。ここではフォントも差し替えると仮定する。

- gdtr-tools.exe
- translation.bat
- translation.csv
- add_translation.csv
- file.ttf

`translation.bat` の中身
```bash
@echo off
cd /d "%~dp0"
gdtr-tools.exe "--replace-translation=Game.pck" "--output=Game.pck" --translation-csv=translation.csv=res://translation.csv --translation-csv=add_translation.csv=res://add_translation.csv
if %errorlevel% neq 0 (
  echo Error
  exit /b %errorlevel%
)
```

## License

The source code is licensed under MIT license.

このツールはGodot Engineを元に作成している: https://github.com/godotengine/godot
