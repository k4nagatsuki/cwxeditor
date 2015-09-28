
module cwx.versioninfo;

import std.string;
import std.conv;

/// CWXEditorのバージョン。
immutable APP_VERSION = splitLines!string(import("@version.txt"))[0];
/// 設定ファイルのバージョン。
immutable APP_VERSION_NUM = to!ulong(splitLines!string(import("@version.txt"))[1]);
/// 公式サイトのURI。
immutable APP_WEB_SITE_URI =  splitLines!string(import("@version.txt"))[2];

/// 最新のWSNデータバージョン。
immutable LATEST_VERSION = "1";
/// 標準で選択されるデータバージョン。
immutable DEFAULT_VERSION = "";
/// 対応するWSNデータバージョン。
immutable VERSIONS = [
	"1",
	"",
];
/// WSNデータバージョン名。
immutable VERSION_NAMES = [
	"Wsn.1",
	"Wsn.0",
];
/// WSNデータバージョンに対応するエンジン名。
immutable ENGINES = [
	"CWPy 0.12.4(α)",
	"CWPy 0.12.3",
];
