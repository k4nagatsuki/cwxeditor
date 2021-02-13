
module createrc;

import std.ascii;
import std.exception;
import std.file;
import std.regex;
import std.string;

void main() {
	auto ver = import("@version.txt").splitLines()[0];
	.enforce(ver.startsWith("Version."));
	auto vers = ver["Version.".length .. $].split(.ctRegex!("[.αβ]"));
	auto majorVer = vers[0];
	auto minorVer = vers[1];
	auto rc = [
		`#define VS_VERSION_INFO 1`,
		`#define RT_MANIFEST 24`,
		``,
		`VS_VERSION_INFO RT_MANIFEST "cwxeditor.exe.manifest"`,
		`ID_APP ICON "cwxeditor.ico"`,
		``,
		`#define VS_FFI_FILEFLAGSMASK 0x0000003FL`,
		`#define VOS_NT_WINDOWS32 0x00040004L`,
		`#define VOS_NT_WINDOWS64 0x00040005L`,
		`#define VFT_APP 0x00000001L`,
		`#define VFT2_UNKNOWN 0x00000000L`,
		``,
		`VS_VERSION_INFO VERSIONINFO`,
		`FILEVERSION ` ~ majorVer ~ `, ` ~ minorVer ~ `, 0, 0`,
		`PRODUCTVERSION ` ~ majorVer ~ `, ` ~ minorVer ~ `, 0, 0`,
		`FILEFLAGSMASK VS_FFI_FILEFLAGSMASK`,
		`FILEFLAGS 0`,
		`#ifdef WIN64`,
		`    FILEOS VOS_NT_WINDOWS64`,
		`#else`,
		`    FILEOS VOS_NT_WINDOWS32`,
		`#endif`,
		`FILETYPE VFT_APP`,
		`FILESUBTYPE VFT2_UNKNOWN`,
		`BEGIN`,
		`    BLOCK "StringFileInfo"`,
		`    BEGIN`,
		`        BLOCK "041104b0"`,
		`        BEGIN`,
		`            VALUE "CompanyName", "CWXEditor Developers.\0"`,
		`            VALUE "FileDescription", "CWXEditor\0"`,
		`            VALUE "InternalName", "CWXEditor\0"`,
		`            VALUE "LegalCopyright", "See Also: editor_license.txt\0"`,
		`            VALUE "OriginalFilename", "cwxeditor.exe\0"`,
		`            VALUE "ProductName", "CWXEditor\0"`,
		`            VALUE "ProductVersion", "` ~ majorVer ~ `.` ~ minorVer ~ `\0"`,
		`        END`,
		`    END`,
		`    BLOCK "VarFileInfo"`,
		`    BEGIN`,
		`        VALUE "Translation", 0x411, 1200`,
		`    END`,
		`END`,
	];
	.write("cwxeditor.rc", rc.join(.newline));
}
