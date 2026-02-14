# LanguageConfiguration（言語設定）

## 概要

音声認識の対象言語を管理するドメインモデル。現時点では日本語と英語の2言語に限定し、ユーザーが複数言語を同時に選択して認識対象とすることができる。

対応ユーザーストーリー: **US-005**（認識言語の設定 — 複数言語対応）

---

## コンポーネント種別

**エンティティ（Entity）**

---

## 属性

| 属性名 | 型 | 説明 |
|---|---|---|
| enabledLanguages | Language のセット（値オブジェクト） | 現在有効な認識対象言語のセット |

---

## 値オブジェクト

### Language（言語）

RecognitionResult で定義した Language 値オブジェクトと共有。

| 値 | 説明 |
|---|---|
| Japanese | 日本語 |
| English | 英語 |

---

## 振る舞い

| メソッド | 説明 | 事前条件 | 事後条件 |
|---|---|---|---|
| addLanguage(language) | 認識対象に言語を追加する | language がサポート対象言語であること | enabledLanguages に言語が追加される |
| removeLanguage(language) | 認識対象から言語を削除する | enabledLanguages に language が含まれていること。削除後に少なくとも1言語が残ること | enabledLanguages から言語が削除される |
| getEnabledLanguages() | 現在有効な言語のリストを返す | — | enabledLanguages のセットを返す |
| isMultiLanguageEnabled() | 複数言語が有効かどうかを判定する | — | enabledLanguages のサイズが2以上なら true を返す |

---

## ドメインイベント

| イベント名 | 発生タイミング | ペイロード | 備考 |
|---|---|---|---|
| LanguageAdded | addLanguage() 実行時 | 追加された言語 | 音声認識エンジンの言語設定を更新 |
| LanguageRemoved | removeLanguage() 実行時 | 削除された言語 | 音声認識エンジンの言語設定を更新 |

---

## ビジネスルール

1. サポート対象言語は日本語（Japanese）と英語（English）の2言語のみ
2. 少なくとも1つの言語が常に有効でなければならない（全言語の削除は不可）
3. 同一言語の重複追加は不可
4. 複数言語が選択されている場合、音声認識エンジンは日英混合認識モードで動作する
