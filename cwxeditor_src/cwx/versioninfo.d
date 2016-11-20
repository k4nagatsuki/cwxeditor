
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
immutable LATEST_VERSION = "2";
/// 標準で選択されるデータバージョン。
immutable DEFAULT_VERSION = "1";
/// 対応するWSNデータバージョン。
immutable VERSIONS = [
	"2",
	"1",
	"",
];
/// WSNデータバージョン名。
immutable VERSION_NAMES = [
	"Wsn.2(α)",
	"Wsn.1",
	"Wsn.0",
];
/// WSNデータバージョンに対応するエンジン名。
immutable ENGINES = [
	"CardWirthPy 2(α)",
	"CardWirthPy 1",
	"CardWirthPy 0.12.3",
];

/// 指定されたデータバージョンverがシナリオのdataVersion以下か。
static bool isTargetVersion(string dataVersion, string ver) {
	static ptrdiff_t[string] VER_TABLE;
	synchronized {
		if (VER_TABLE.length == 0) {
			foreach (i, v; VERSIONS) {
				VER_TABLE[v] = VERSIONS.length - i;
			}
		}
	}
	return VER_TABLE.get(ver, int.min) <= VER_TABLE.get(dataVersion, int.max);
}
