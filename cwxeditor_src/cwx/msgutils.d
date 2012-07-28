
module cwx.msgutils;

import cwx.utils;

import std.conv;
import std.exception;
import std.path;
import std.uni;
import std.utf;
import std.algorithm;
import std.string;

/// "font_X.bmp"から"X"の部分を抽出する。
dchar decodeFontPath(string path) {
	enforce(istartsWith(path, "font_"));
	auto dpath = to!dstring(path["font_".length .. $].stripExtension());
	enforce(1 == dpath.length);
	return std.uni.toUpper(dpath[0]);
}
/// cを"font_X.bmp"等に変換する。
string encodeFontPath(dchar c, string ext) {
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
		out char[size_t] colors) {
	dchar[] result;
	dstring dtext = to!dstring(text);
	for (size_t i = 0; i < dtext.length; i++) {
		dchar c = dtext[i];
		bool flag_step(string delegate(string) get, dchar c) {
			int next = .countUntil(dtext[i + 1 .. $], c);
			if (next < 0) return false;
			dstring fl = dtext[i + 1 .. i + 1 + next];
			i = i + 1 + next;
			result ~= to!dstring(get(to!string(fl)));
			return true;
		}
		switch (c) {
		case '#':
			if (i + 1 == dtext.length) goto default;
			if ('\n' == dtext[i + 1]) goto default;
			auto nc = std.ascii.toUpper(dtext[i + 1]);
			switch (nc) {
			case 'M', 'R', 'U', 'C', 'I', 'T', 'Y':
				result ~= to!dstring(getName(cast(char) nc));
				i++;
				continue;
			default:
				string path = encodeFontPath(dtext[i + 1], ".bmp");
				if (!hasMaterial || hasMaterial(path)) {
					fonts[result.length] = path;
				}
				break;
			}
			goto default;
		case '%':
			if (!flag_step(getFlag, '%')) goto default;
			break;
		case '$':
			if (!flag_step(getStep, '$')) goto default;
			break;
		case '&':
			if (i + 1 == dtext.length) goto default;
			if ('\n' == dtext[i + 1]) goto default;
			auto nc = std.ascii.toUpper(dtext[i + 1]);
			switch (nc) {
			case 'W', 'R', 'B', 'G', 'Y':
				colors[result.length] = cast(char) nc;
				break;
			default:
				break;
			}
			goto default;
		default:
			result ~= c;
			break;
		}
	}
	return to!string(assumeUnique(result));
} unittest {
	debug mixin(UTPerf);
	string[size_t] rFonts;
	char[size_t] rColors;
	string result = formatMsg("%flag1%, %flag2%, $step1$, $step2$, &R, &W, #m, #r, #v, #+", (string flag) {
		if ("flag1" == flag) return "f1test";
		return "f2";
	}, (string step) {
		if ("step1" == step) return "s1test";
		return " ";
	}, (char name) {
		if (name == 'R') return "R_test";
		return "";
	}, null, rFonts, rColors);
	assert (result == "f1test, f2, s1test,  , &R, &W, , R_test, #v, #+", result);
	assert (rFonts == [cast(size_t) 41:"font_v.bmp", cast(size_t) 45:"font_+.bmp"]);
	assert (rColors == [cast(size_t) 23:'R', cast(size_t) 27:'W'], .text(rColors));
}
/// テキストの中で使用されているフラグ・ステップ・画像パスを抽出する。
void textUseItems(in string text,
		out string[] flags, out string[] steps, out string[] fonts) {
	string[size_t] rFonts;
	char[size_t] rColors;
	formatMsg(text, (string flag) {
		flags ~= flag;
		return "";
	}, (string step) {
		steps ~= step;
		return "";
	}, (char name) {
		return "";
	}, null, rFonts, rColors);
	fonts = rFonts.values;
} unittest {
	debug mixin(UTPerf);
	string[] flags, steps, fonts;
	textUseItems("#M#R#U#C#I#T#Yaaa$test$$あああ\t2$$#tes%t3$%tes#t%#a#Z#1#2#33d$dd%aaa%%#%#;%vv%#表%#", flags, steps, fonts);
	assert(flags.sort == ["tes#t", "aaa", "#", "vv"].sort, .text(flags));
	assert(steps.sort == ["test", "あああ\t2", "#tes%t3"].sort, .text(steps));
	assert(fonts.sort == ["font_a.bmp", "font_Z.bmp", "font_1.bmp", "font_2.bmp", "font_3.bmp", "font_;.bmp", "font_表.bmp"].sort, .text(fonts));
}

private void __replOn(ref dstring dtext, ref dstring buf, ref size_t i, dstring dold, dstring dnew, dchar targC) {
	int next = .countUntil(dtext[i + 1 .. $], targC);
	if (next >= 0) {
		next = i + 1 + next;
		if (dtext[i + 1 .. next] == dold) {
			buf ~= [targC] ~ dnew ~ [targC];
		} else {
			buf ~= dtext[i .. next + 1];
		}
		if (next < dtext.length) {
			dtext = dtext[next .. $];
			i = 0;
		}
	} else {
		buf ~= dtext[i];
	}
}
private void __replOff(ref dstring dtext, ref dstring buf, ref size_t i, dchar targC) {
	int next = .countUntil(dtext[i + 1 .. $], targC);
	if (next >= 0) {
		next = i + 1 + next;
		buf ~= [targC] ~ dtext[i + 1 .. next] ~ [targC];
		if (next < dtext.length) {
			dtext = dtext[next .. $];
			i = 0;
		}
	} else {
		buf ~= dtext[i];
	}
}
private string __replTextFlagStep(char Ch1, char Ch2)
		(string text, string oldFlag, string newFlag) {
	dstring dtext = toUTF32(text);
	dstring dold = toUTF32(oldFlag);
	dstring dnew = toUTF32(newFlag);
	dstring buf;
	for (size_t i; i < dtext.length; i++) {
		dchar c = dtext[i];
		switch (c) {
		case '#':
			buf ~= c;
			if (i + 1 < dtext.length) {
				buf ~= dtext[i + 1];
				i++;
			}
			break;
		case Ch1:
			__replOn(dtext, buf, i, dold, dnew, Ch1);
			break;
		case Ch2:
			__replOff(dtext, buf, i, Ch2);
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
string replTextUseFlag(string text, string oldFlag, string newFlag) {
	return __replTextFlagStep!('%', '$')(text, oldFlag, newFlag);
} unittest {
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
string replTextUseStep(string text, string oldStep, string newStep) {
	return __replTextFlagStep!('$', '%')(text, oldStep, newStep);
} unittest {
	debug mixin(UTPerf);
	assert(replTextUseStep("「$置 換 前$」", "置 換 前", "置 換 後") == "「$置 換 後$」");
	assert(replTextUseStep("aaa$aaa$%$置換前$%$置換前$a#$置換前$$aa%$置換前$", "置換前", "置換no後")
		== "aaa$aaa$%$置換前$%$置換no後$a#$置換前$$aa%$置換no後$");
}
/// テキストの中で使用されている画像のパスを置換する。
/// Params:
/// text = テキスト。
/// oldFont = 置換前の画像パス。
/// newFont = 置換後の画像パス。
string replTextUseFont(string text, string oldFont, string newFont)
in {
	dstring dold = toUTF32(.toLower(oldFont.baseName()));
	dstring dnew = toUTF32(.toLower(newFont.baseName()));
	assert(dold.length == 10, .text(dold));
	assert(startsWith(dold, "font_"d));
	assert(endsWith(dold, ".bmp"d));
	assert(dnew.length == 10, .text(dnew));
	assert(startsWith(dnew, "font_"d));
	assert(endsWith(dnew, ".bmp"d));
} body {
	dstring dtext = toUTF32(text);
	dchar dold = toUTF32(oldFont.baseName())[5];
	dchar dnew = toUTF32(newFont.baseName())[5];
	dstring buf;
	for (size_t i; i < dtext.length; i++) {
		dchar c = dtext[i];
		switch (c) {
		case '#':
			buf ~= c;
			if (i + 1 < dtext.length) {
				if (.toLower([dtext[i + 1]]) == .toLower([dold])) {
					buf ~= dnew;
				} else {
					buf ~= dtext[i + 1];
				}
				i++;
			}
			break;
		case '%':
			__replOff(dtext, buf, i, '%');
			break;
		case '$':
			__replOff(dtext, buf, i, '$');
			break;
		default:
			buf ~= c;
			break;
		}
	}
	return toUTF8(buf);
} unittest {
	debug mixin(UTPerf);
	assert(replTextUseFont("#a#置$#置$#b%#置%#置", "font_置.bmp", "Font_換.bmp")
		== "#a#換$#置$#b%#置%#換");
	assert(replTextUseFont("#a#c$#c$#b%#C%#C", "fonT_c.bmp", "font_F.Bmp")
		== "#a#F$#c$#b%#C%#F");
}
/// textのstart .. end範囲内の色をcolorにする。
/// %%・$$区間は通常のテキストとして扱う。
dstring putColor(dstring text, dchar color, size_t start, size_t end) {
	if (start == end) {
		return text[0u .. start] ~ cast(dchar) '&' ~ color ~ text[end .. $];
	}
	dchar defColor = 'W';
	if (start >= 1) {
		l: foreach_reverse (i, dchar c; text[1u .. start]) {
			switch (c) {
			case 'W', 'R', 'B', 'G', 'Y':
				if (text[i] == '&') {
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
} unittest {
	debug mixin(UTPerf);
	assert (putColor("テストテスト"d, 'R', 1, 4) == "テ&Rストテ&Wスト"d);
	assert (putColor("テストテスト"d, 'B', 2, 5) == "テス&Bトテス&Wト"d);
	assert (putColor("&Rテストテスト"d, 'Y', 4, 7) == "&Rテス&Yトテス&Rト"d);
	assert (putColor("テストテスト"d, 'B', 2, 2) == "テス&Bトテスト"d);
}
