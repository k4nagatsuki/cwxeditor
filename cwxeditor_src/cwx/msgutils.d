
module cwx.msgutils;

import cwx.utils;
import cwx.imagesize;

import std.conv;
import std.exception;
import std.path;
import std.uni;
import std.utf;
import std.algorithm;
import std.string;
import std.ascii;
import std.array;
static import std.algorithm;

/// "font_X.bmp"から"X"の部分を抽出する。
dchar decodeFontPath(string path) { mixin(S_TRACE);
	enforce(path.isSPFontFile);
	auto dpath = to!dstring(path["font_".length .. $].stripExtension());
	enforce(1 == dpath.length);
	return std.uni.toUpper(dpath[0]);
}
/// cを"font_X.bmp"等に変換する。
string encodeFontPath(dchar c, string ext) { mixin(S_TRACE);
	return ("font_" ~ to!string(c)).setExtension(ext);
}

/// テキストの中で使用されているフラグ・ステップ・画像パス・名前を置換し、
/// 変換後のテキスト、及び外部イメージと色変更記号の位置を返す。
string formatMsg(in string text,
		string delegate(string) getFlag,
		string delegate(string) getStep,
		string delegate(char) getName,
		bool delegate(string) hasMaterial,
		out string[size_t] fonts,
		out char[size_t] colors) { mixin(S_TRACE);
	return formatMsgImpl(text, getFlag, getStep, getName, hasMaterial, fonts, colors, true);
}
/// ditto
string simpleFormatMsg(in string text, string[string] flags, string[string] steps, string[char] names) { mixin(S_TRACE);
	string[size_t] fonts;
	char[size_t] colors;
	return formatMsgImpl(text, (string path) { mixin(S_TRACE);
			foreach (f, v; flags) { mixin(S_TRACE);
				if (f == path) { mixin(S_TRACE);
					return v;
				}
			}
			return null;
		}, (string path) { mixin(S_TRACE);
			foreach (f, v; steps) { mixin(S_TRACE);
				if (f == path) { mixin(S_TRACE);
					return v;
				}
			}
			return null;
		}, delegate string (char name) { mixin(S_TRACE);
			auto dc = std.ascii.toUpper(name);
			foreach (c, v; names) { mixin(S_TRACE);
				if (std.ascii.toUpper(c) == dc) { mixin(S_TRACE);
					return v;
				}
			}
			return "#" ~ name;
		}, (c) => false, fonts, colors, false);
}
private string formatMsgImpl(in string text,
		string delegate(string) getFlag,
		string delegate(string) getStep,
		string delegate(char) getName,
		bool delegate(string) hasMaterial,
		out string[size_t] fonts,
		out char[size_t] colors,
		bool full) { mixin(S_TRACE);
	dchar[] result;
	dstring dtext = to!dstring(text);
	for (size_t i = 0; i < dtext.length; i++) { mixin(S_TRACE);
		dchar c = dtext[i];
		bool flag_step(string delegate(string) get, dchar cc) { mixin(S_TRACE);
			ptrdiff_t next = .countUntil(dtext[i + 1 .. $], cc);
			if (next < 0) return false;
			dstring fl = dtext[i + 1 .. i + 1 + next];
			auto val = get(to!string(fl));
			if (val is null) { mixin(S_TRACE);
				if (!full) { mixin(S_TRACE);
					// 選択肢などでは最初の1文字が欠ける
					c = dchar.init;
				}
				return false;
			}
			i = i + 1 + next;
			result ~= to!dstring(val);
			return true;
		}
		switch (c) {
		case '#':
			if (i + 1 == dtext.length) goto default;
			if ('\n' == dtext[i + 1]) goto default;
			auto nc = std.ascii.toUpper(dtext[i + 1]);
			if (full) { mixin(S_TRACE);
				string path = encodeFontPath(dtext[i + 1], ".bmp");
				if (hasMaterial && hasMaterial(path)) { mixin(S_TRACE);
					fonts[result.length] = path;
				} else { mixin(S_TRACE);
					switch (nc) {
					case 'M', 'R', 'U', 'C', 'I', 'T', 'Y':
						result ~= to!dstring(getName(cast(char)nc));
						i++;
						continue;
					default:
						if (!hasMaterial) { mixin(S_TRACE);
							fonts[result.length] = path;
						}
						break;
					}
				}
			} else { mixin(S_TRACE);
				switch (nc) {
				case 'M', 'R', 'U', 'T', 'Y':
					result ~= to!dstring(getName(cast(char) nc));
					i++;
					continue;
				default:
					break;
				}
			}
			goto default;
		case '%':
			if (!flag_step(getFlag, '%')) goto default;
			break;
		case '$':
			if (!flag_step(getStep, '$')) goto default;
			break;
		case '&':
			if (!full) goto default;
			if (i + 1 == dtext.length) goto default;
			if ('\n' == dtext[i + 1]) goto default;
			if (.isASCII(dtext[i + 1])) { mixin(S_TRACE);
				auto nc = std.ascii.toUpper(dtext[i + 1]);
				colors[result.length] = cast(char)nc;
			}
			goto default;
		default:
			if (c !is dchar.init) result ~= c;
			break;
		}
	}
	return to!string(assumeUnique(result));
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	string[size_t] rFonts;
	char[size_t] rColors;
	string result = formatMsg("%flag1%, %flag2%, $step1$, $step2$, &R, &W, #m, #r, #v, #+", (string flag) { mixin(S_TRACE);
		if ("flag1" == flag) return "f1test";
		return "f2";
	}, (string step) { mixin(S_TRACE);
		if ("step1" == step) return "s1test";
		return " ";
	}, (char name) { mixin(S_TRACE);
		if (name == 'R') return "R_test";
		return "";
	}, null, rFonts, rColors);
	assert (result == "f1test, f2, s1test,  , &R, &W, , R_test, #v, #+", result);
	assert (rFonts == [cast(size_t) 41:"font_v.bmp", cast(size_t) 45:"font_+.bmp"]);
	assert (rColors == [cast(size_t) 23:'R', cast(size_t) 27:'W'], .text(rColors));
}
/// BUG: 信じがたい事にstd.algorithm.sortはchar[]のソートができない(dmd 2.072)
void sortChars(char[] chars) {
	char[][] ss;
	foreach (c; chars) ss ~= [c];
	std.algorithm.sort(ss);
	foreach (i, ref c; chars) c = ss[i][0];
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	char[] a = "abdfqweafjp".dup;
	sortChars(a);
	assert (a == "aabdeffjpqw");
}
/// テキストの中で使用されているフラグ・ステップ・画像パスを抽出する。
void textUseItems(in string text,
		out string[] flags, out string[] steps, out string[] fonts, out char[] colors) { mixin(S_TRACE);
	string[size_t] rFonts;
	char[size_t] rColors;
	formatMsg(text, (string flag) { mixin(S_TRACE);
		flags ~= flag;
		return "";
	}, (string step) { mixin(S_TRACE);
		steps ~= step;
		return "";
	}, (char name) { mixin(S_TRACE);
		return "";
	}, null, rFonts, rColors);
	fonts = rFonts.values;
	colors = rColors.values;
	.sortChars(colors);
	colors = to!(char[])(colors.uniq().array());
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	string[] flags, steps, fonts;
	char[] colors;
	textUseItems("#M#R#U#C#I#T#Yaaa$test$$あああ\t2$$#tes%t3$%tes#t%#a#Z#1#2#33d$dd%aaa%%#%#;%vv%#表%#", flags, steps, fonts, colors);
	assert(std.algorithm.sort(flags).array() == std.algorithm.sort(["tes#t", "aaa", "#", "vv"]).array(), .text(flags));
	assert(std.algorithm.sort(steps).array() == std.algorithm.sort(["test", "あああ\t2", "#tes%t3"]).array(), .text(steps));
	assert(std.algorithm.sort(fonts).array() == std.algorithm.sort(["font_a.bmp", "font_Z.bmp", "font_1.bmp", "font_2.bmp", "font_3.bmp", "font_;.bmp", "font_表.bmp"]).array(), .text(fonts));
}

private void replOn(ref dstring dtext, ref dstring buf, ref size_t i, dstring dold, dstring dnew, dchar targC) { mixin(S_TRACE);
	ptrdiff_t next = .countUntil(dtext[i + 1 .. $], targC);
	if (next >= 0) { mixin(S_TRACE);
		next = i + 1 + next;
		if (dtext[i + 1 .. next] == dold) { mixin(S_TRACE);
			buf ~= [targC] ~ dnew ~ [targC];
		} else { mixin(S_TRACE);
			buf ~= dtext[i .. next + 1];
		}
		if (next < dtext.length) { mixin(S_TRACE);
			dtext = dtext[next .. $];
			i = 0;
		}
	} else { mixin(S_TRACE);
		buf ~= dtext[i];
	}
}
private void replOff(ref dstring dtext, ref dstring buf, ref size_t i, dchar targC) { mixin(S_TRACE);
	ptrdiff_t next = .countUntil(dtext[i + 1 .. $], targC);
	if (next >= 0) { mixin(S_TRACE);
		next = i + 1 + next;
		buf ~= [targC] ~ dtext[i + 1 .. next] ~ [targC];
		if (next < dtext.length) { mixin(S_TRACE);
			dtext = dtext[next .. $];
			i = 0;
		}
	} else { mixin(S_TRACE);
		buf ~= dtext[i];
	}
}
private string replTextFlagStep(char Ch1, char Ch2)
		(string text, string oldFlag, string newFlag) { mixin(S_TRACE);
	dstring dtext = toUTF32(text);
	dstring dold = toUTF32(oldFlag);
	dstring dnew = toUTF32(newFlag);
	dstring buf;
	for (size_t i; i < dtext.length; i++) { mixin(S_TRACE);
		dchar c = dtext[i];
		switch (c) {
		case '#':
			buf ~= c;
			if (i + 1 < dtext.length) { mixin(S_TRACE);
				buf ~= dtext[i + 1];
				i++;
			}
			break;
		case Ch1:
			replOn(dtext, buf, i, dold, dnew, Ch1);
			break;
		case Ch2:
			replOff(dtext, buf, i, Ch2);
			break;
		default:
			buf ~= c;
			break;
		}
	}
	return toUTF8(buf);
}
/// テキストの中で使用されているフラグのパスを置換する。
/// Params:
/// text = テキスト。
/// oldFlag = 置換前のフラグパス。
/// newFlag = 置換後のフラグパス。
string replTextUseFlag(string text, string oldFlag, string newFlag) { mixin(S_TRACE);
	return replTextFlagStep!('%', '$')(text, oldFlag, newFlag);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert(replTextUseFlag("「%置 換 前%」", "置 換 前", "置 換 後") == "「%置 換 後%」");
	assert(replTextUseFlag("aaa%aaa%$%置換前%$%置換前%a#%置換前%%aa$%置換前%", "置換前", "置換no後")
		== "aaa%aaa%$%置換前%$%置換no後%a#%置換前%%aa$%置換no後%");
}
/// テキストの中で使用されているステップのパスを置換する。
/// Params:
/// text = テキスト。
/// oldStep = 置換前のステップパス。
/// newStep = 置換後のステップパス。
string replTextUseStep(string text, string oldStep, string newStep) { mixin(S_TRACE);
	return replTextFlagStep!('$', '%')(text, oldStep, newStep);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert(replTextUseStep("「$置 換 前$」", "置 換 前", "置 換 後") == "「$置 換 後$」");
	assert(replTextUseStep("aaa$aaa$%$置換前$%$置換前$a#$置換前$$aa%$置換前$", "置換前", "置換no後")
		== "aaa$aaa$%$置換前$%$置換no後$a#$置換前$$aa%$置換no後$");
}
/// テキスト中で使用されている画像か。
@property
bool isSPFontFile(string file) { mixin(S_TRACE);
	dstring dFile = toUTF32(.toLower(file.baseName()));
	if (dFile.length != 10) return false;
	if (!startsWith(dFile, "font_"d)) return false;
	if (!endsWith(dFile, ".bmp"d)) return false;
	return true;
}
/// テキストの中で使用されている画像のパスを置換する。
/// Params:
/// text = テキスト。
/// oldFont = 置換前の画像パス。
/// newFont = 置換後の画像パス。
string replTextUseFont(string text, string oldFont, string newFont)
in { mixin(S_TRACE);
	dstring dold = toUTF32(.toLower(oldFont.baseName()));
	dstring dnew = toUTF32(.toLower(newFont.baseName()));
	assert(startsWith(dold, "font_"d), .text(dold));
	assert(endsWith(dold, ".bmp"d), .text(dold));
} body { mixin(S_TRACE);
	if (!oldFont.isSPFontFile) return text;
	if (!newFont.isSPFontFile) return text;

	dstring dtext = toUTF32(text);
	dchar dnew = toUTF32(newFont.baseName())[5];
	dchar dold = toUTF32(oldFont.baseName())[5];
	dstring buf;
	for (size_t i; i < dtext.length; i++) { mixin(S_TRACE);
		dchar c = dtext[i];
		switch (c) {
		case '#':
			buf ~= c;
			if (i + 1 < dtext.length) { mixin(S_TRACE);
				if (.toLower([dtext[i + 1]]) == .toLower([dold])) { mixin(S_TRACE);
					buf ~= dnew;
				} else { mixin(S_TRACE);
					buf ~= dtext[i + 1];
				}
				i++;
			}
			break;
		case '%':
			replOff(dtext, buf, i, '%');
			break;
		case '$':
			replOff(dtext, buf, i, '$');
			break;
		default:
			buf ~= c;
			break;
		}
	}
	return toUTF8(buf);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert(replTextUseFont("#a#置$#置$#b%#置%#置", "font_置.bmp", "Font_換.bmp")
		== "#a#換$#置$#b%#置%#換");
	assert(replTextUseFont("#a#c$#c$#b%#C%#C", "fonT_c.bmp", "font_F.Bmp")
		== "#a#F$#c$#b%#C%#F");
}
/// textのstart .. end範囲内の色をcolorにする。
/// %%・$$区間は通常のテキストとして扱う。
dstring putColor(dstring text, dchar color, size_t start, size_t end) { mixin(S_TRACE);
	if (start == end) { mixin(S_TRACE);
		return text[0u .. start] ~ cast(dchar) '&' ~ color ~ text[end .. $];
	}
	dchar defColor = 'W';
	if (start >= 1) { mixin(S_TRACE);
		l: foreach_reverse (i, dchar c; text[1u .. start]) { mixin(S_TRACE);
			switch (c) {
			case 'W', 'R', 'B', 'G', 'Y':
			case 'O', 'P', 'L', 'D': // CardWirth 1.50
				if (text[i] == '&') { mixin(S_TRACE);
					defColor = c;
					break l;
				}
				break;
			default:
			}
		}
	}
	if (defColor == color) return text;
	return text[0u .. start] ~ cast(dchar) '&' ~ color
		~ text[start .. end] ~ cast(dchar) '&' ~ defColor ~ text[end .. $];
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (putColor("テストテスト"d, 'R', 1, 4) == "テ&Rストテ&Wスト"d);
	assert (putColor("テストテスト"d, 'B', 2, 5) == "テス&Bトテス&Wト"d);
	assert (putColor("&Rテストテスト"d, 'Y', 4, 7) == "&Rテス&Yトテス&Rト"d);
	assert (putColor("テストテスト"d, 'B', 2, 2) == "テス&Bトテスト"d);
}
