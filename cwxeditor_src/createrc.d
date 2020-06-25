
module createrc;

import std.ascii;
import std.exception;
import std.file;
import std.string;

void main() {
	auto ver = import("@version.txt").splitLines()[0];
	.enforce(ver.startsWith("Version."));
	auto vers = ver["Version.".length .. $].split(".");
	auto majorVer = vers[0];
	auto minorVer = vers[1];
	auto rc = [
		`1 RT_MANIFEST "cwxeditor.exe.manifest"`,
		`ID_APP ICON "cwxeditor.ico"`,
	    ``,
		`1 VERSIONINFO`,
		`FILEVERSION ` ~ majorVer ~ `,` ~ minorVer ~ `,0,0`,
		`BEGIN`,
		`    BLOCK "StringFileInfo"`,
		`    BEGIN`,
		`        BLOCK "041104b0"`,
		`        BEGIN`,
		`            VALUE "CompanyName", "CWXEditor Developers.\0"`,
		`            VALUE "FileDescription", "Scenario Editor for WSN and CardWirth 1.28-1.50.\0"`,
		`            VALUE "InternalName", "CWXEditor\0"`,
		`            VALUE "LegalCopyright", "See Also: editor_history.txt\0"`,
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
