
module cwx.versioninfo;

import std.string;
import std.path;
import std.conv;
import std.ascii;

shared const string APP_VERSION = splitLines!string(import("@version.txt"))[0];
shared const string APP_WEB_SITE_URI =  splitLines!string(import("@version.txt"))[1];
debug {
	version (Console) {
		private const DR = "Debug / Console";
	} else {
		private const DR = "Debug";
	}
} else {
	@property
	private const DR = "Release";
}
shared const string APP_BUILD = "Build: "
		~ __DATE__[7 .. $]
		~ "-" ~ [
			"Jan":"01",
			"Feb":"02",
			"Mar":"03",
			"Apr":"04",
			"May":"05",
			"Jun":"06",
			"Jul":"07",
			"Aug":"08",
			"Sep":"09",
			"Oct":"10",
			"Nov":"11",
			"Dec":"12"
		][__DATE__[0 .. 3]]
		~ "-" ~ (__DATE__[4 .. 5] == " " ? "0" : __DATE__[4 .. 5]) ~ __DATE__[5 .. 6]
		~ " " ~ __TIME__ ~ " "
		~ DR ~ .newline
		~ "Compiled by " ~ __VENDOR__ ~ " " ~ .text(__VERSION__);
