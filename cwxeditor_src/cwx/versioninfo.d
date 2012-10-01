
module cwx.versioninfo;

import std.string;
import std.conv;

shared const string APP_VERSION = splitLines!string(import("@version.txt"))[0];
shared const ulong APP_VERSION_NUM = to!ulong(splitLines!string(import("@version.txt"))[1]);
shared const string APP_WEB_SITE_URI =  splitLines!string(import("@version.txt"))[2];
