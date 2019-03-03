
module cwx.msgutils;

import cwx.imagesize;
import cwx.utils;

import std.conv;
import std.exception;
import std.path;
import std.uni;
import std.utf;
import std.algorithm;
import std.string;
import std.ascii;
import std.array;
import std.regex;
import std.algorithm;
import std.range;

/// "font_X.bmp"から"X"の部分を抽出する。
dchar decodeFontPath(string path) { mixin(S_TRACE);
	enforce(path.isSPFontFile);
	auto dpath = to!dstring(path["font_".length .. $].stripExtension());
	enforce(1 == dpath.length);
	return std.uni.toUpper(dpath[0]);
}
/// cを"font_X.bmp"等に変換する。
string encodeFontPath(dchar c, string ext) { mixin(S_TRACE);
	if (!c.isFileNameChar) return "";
	return ("font_" ~ to!string(c)) ~ ext;
}

/// 状態変数の選択中の値と特殊文字展開の有無。
struct VarValue {
	bool exists; /// 状態変数が存在するか。
	string value = ""; /// 状態変数の値。
	bool expandSPChars = false; /// 特殊文字を展開するか。
}

/// テキストの中で使用されている状態変数・画像パス・名前を置換し、
/// 変換後のテキスト、及び外部イメージと色変更記号の位置を返す。
string formatMsg(string text,
		VarValue delegate(string) getFlag,
		VarValue delegate(string) getStep,
		VarValue delegate(string) getVariant,
		string delegate(char) getName,
		bool delegate(string ver) isTargetVersion,
		string prefixSystemVarName,
		bool delegate(string) hasMaterial,
		out string[size_t] fonts,
		out char[size_t] colors) { mixin(S_TRACE);
	return formatMsgImpl(text, getFlag, getStep, getVariant, getName, isTargetVersion, prefixSystemVarName, hasMaterial, fonts, colors, true, 0, 0);
}
/// ditto
string simpleFormatMsg(in string text, VarValue[string] flags, VarValue[string] steps, VarValue[string] variants,
		VarValue[string] sysSteps, string[char] names,
		bool delegate(string ver) isTargetVersion, string prefixSystemVarName) { mixin(S_TRACE);
	string[size_t] fonts;
	char[size_t] colors;
	return formatMsgImpl(text,
		path => flags.get(path, VarValue(false)),
		(path) { mixin(S_TRACE);
			auto p = path in steps;
			if (p) return *p;
			return sysSteps.get(path.toLower(), VarValue(false));
		},
		path => variants.get(path, VarValue(false)),
		delegate string(char name) { mixin(S_TRACE);
			auto dc = std.ascii.toUpper(name);
			foreach (c, v; names) { mixin(S_TRACE);
				if (std.ascii.toUpper(c) == dc) { mixin(S_TRACE);
					return v;
				}
			}
			return "#" ~ name;
		}, isTargetVersion, "", (c) => false, fonts, colors, false, 0, 0);
}
private string formatMsgImpl(string text,
		VarValue delegate(string) getFlag,
		VarValue delegate(string) getStep,
		VarValue delegate(string) getVariant,
		string delegate(char) getName,
		bool delegate(string ver) isTargetVersion,
		string prefixSystemVarName,
		bool delegate(string) hasMaterial,
		ref string[size_t] fonts,
		ref char[size_t] colors,
		bool full,
		size_t startIndex,
		size_t stack) { mixin(S_TRACE);
	dchar[] result;
	dstring dtext = to!dstring(text);
	for (size_t i = 0; i < dtext.length; i++) { mixin(S_TRACE);
		dchar c = dtext[i];
		bool variable(VarValue delegate(string) get, dchar cc) { mixin(S_TRACE);
			ptrdiff_t next = .countUntil(dtext[i + 1 .. $], cc);
			if (next < 0) return false;
			auto fl = dtext[i + 1 .. i + 1 + next];
			auto fls = to!string(fl);
			auto v = get(fls);
			if (!v.exists) { mixin(S_TRACE);
				if ((!isTargetVersion || isTargetVersion("2")) && c == '$' && prefixSystemVarName != "" && fls.startsWith(prefixSystemVarName)) { mixin(S_TRACE);
					// CardWirth 1.60では、"??"で始まるステップ名は
					// 該当ステップが存在しない場合、空文字列になる
					i = i + 1 + next;
					return true;
				}
				if (!full) { mixin(S_TRACE);
					if (cc == '$' || cc == '%') { mixin(S_TRACE);
						// BUG: 選択肢などでは最初の1文字が欠ける(CardWirth 1.50)
						result ~= fl ~ cc;
					} else { mixin(S_TRACE);
						// コモンは最初の一文字が欠けないようにする
						result ~= cc ~ fl ~ cc;
					}
					i = i + 1 + next;
					return true;
				}
				return false;
			}
			i = i + 1 + next;
			auto s = v.value;
			if (v.expandSPChars && stack == 0) { mixin(S_TRACE);
				s = .formatMsgImpl(s, getFlag, getStep, getVariant, getName, isTargetVersion, prefixSystemVarName,
					hasMaterial, fonts, colors, full, result.length + startIndex, stack + 1);
			}
			result ~= to!dstring(s);
			return true;
		}
		switch (c) {
		case '#':
			if (i + 1 == dtext.length) goto default;
			if ('\n' == dtext[i + 1]) goto default;
			auto nc = std.ascii.toUpper(dtext[i + 1]);
			if (full) { mixin(S_TRACE);
				auto path = encodeFontPath(dtext[i + 1], ".bmp");
				if (path != "") { mixin(S_TRACE);
					if (hasMaterial && hasMaterial(path)) { mixin(S_TRACE);
						fonts[result.length + startIndex] = path;
					} else { mixin(S_TRACE);
						switch (nc) {
						case 'M', 'R', 'U', 'C', 'I', 'T', 'Y':
							result ~= to!dstring(getName(cast(char)nc));
							i++;
							continue;
						default:
							if (!hasMaterial) { mixin(S_TRACE);
								fonts[result.length + startIndex] = path;
							}
							break;
						}
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
			if (!variable(getFlag, '%')) goto default;
			break;
		case '$':
			if (!variable(getStep, '$')) goto default;
			break;
		case '@':
			if (!variable(getVariant, '@')) goto default;
			break;
		case '&':
			if (!full) goto default;
			if (i + 1 == dtext.length) goto default;
			if ('\n' == dtext[i + 1]) goto default;
			if (.isASCII(dtext[i + 1])) { mixin(S_TRACE);
				auto nc = std.ascii.toUpper(dtext[i + 1]);
				colors[result.length + startIndex] = cast(char)nc;
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
		if ("flag1" == flag) return VarValue(true, "f1test");
		return VarValue(true, "f2");
	}, (string step) { mixin(S_TRACE);
		if ("step1" == step) return VarValue(true, "s1test");
		return VarValue(true, " ");
	}, (string variant) { mixin(S_TRACE);
		if ("variant1" == variant) return VarValue(true, "v1test");
		return VarValue(true, " ");
	}, (char name) { mixin(S_TRACE);
		if (name == 'R') return "R_test";
		return "";
	}, ver => true, "??", null, rFonts, rColors);
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
/// テキストの中で使用されている状態変数・画像パスを抽出する。
void textUseItems(string text,
		out string[] flags, out string[] steps, out string[] variables,
		out string[] fonts, out char[] colors) { mixin(S_TRACE);
	string[size_t] rFonts;
	char[size_t] rColors;
	formatMsg(text, (string flag) { mixin(S_TRACE);
		flags ~= flag;
		return VarValue(true);
	}, (string step) { mixin(S_TRACE);
		steps ~= step;
		return VarValue(true);
	}, (string variable) { mixin(S_TRACE);
		variables ~= variable;
		return VarValue(true);
	}, (char name) { mixin(S_TRACE);
		return "";
	}, ver => false, "", null, rFonts, rColors);
	fonts = rFonts.values;
	colors = rColors.values;
	.sortChars(colors);
	colors = to!(char[])(colors.uniq().array());
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	string[] flags, steps, variants, fonts;
	char[] colors;
	textUseItems("#M#R#U#C#I#T#Yaaa$test$$あああ\t2$$#tes%t3$%tes#t%#a#Z#1#2#33d$dd%aaa%%#%#;%vv%#表%#", flags, steps, variants, fonts, colors);
	assert(std.algorithm.sort(flags).array() == std.algorithm.sort(["tes#t", "aaa", "#", "vv"]).array(), .text(flags));
	assert(std.algorithm.sort(steps).array() == std.algorithm.sort(["test", "あああ\t2", "#tes%t3"]).array(), .text(steps));
	assert(std.algorithm.sort(variants).array() == [], .text(variants));
	assert(std.algorithm.sort(fonts).array() == std.algorithm.sort(["font_a.bmp", "font_Z.bmp", "font_1.bmp", "font_2.bmp", "font_3.bmp", "font_;.bmp", "font_表.bmp"]).array(), .text(fonts));
}
/// テキストの中で使用されている選択メンバ名などの特殊文字を抽出する。
char[] namesInText(string text, bool full) { mixin(S_TRACE);
	char[] r;
	string[size_t] fonts;
	char[size_t] colors;
	.formatMsgImpl(text,
		path => VarValue(true),
		path => VarValue(true),
		path => VarValue(true),
		(char name) { mixin(S_TRACE);
			r ~= name;
			return "#" ~ name;
		}, null, "", (c) => false, fonts, colors, full, 0, 0);
	return r;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	auto fonts = .namesInText("#M#R#U#C#I#T#Yaaa$test$$あああ\t2$$#tes%t3$%tes#t%#a#Z#1#2#33d$dd%aaa%%#%#;%vv%#表%#", true);
	assert(fonts == ['M', 'R', 'U', 'C', 'I', 'T', 'Y'], .text(fonts));
	fonts = .namesInText("#M#R#U#C#I#T#Yaaa$test$$あああ\t2$$#tes%t3$%tes#t%#a#Z#1#2#33d$dd%aaa%%#%#;%vv%#表%#", false);
	assert(fonts == ['M', 'R', 'U', 'T', 'Y'], .text(fonts));
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
private string replTextFlagStep(char Ch1, char Ch2, char Ch3)
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
		case Ch3:
			replOff(dtext, buf, i, c);
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
	return replTextFlagStep!('%', '$', '@')(text, oldFlag, newFlag);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert(replTextUseFlag("「%置 換 前%」", "置 換 前", "置 換 後") == "「%置 換 後%」");
	assert(replTextUseFlag("aaa%aaa%$%置換前%$@%置換前%@%置換前%a#%置換前%%aa$%置換前%", "置換前", "置換no後")
		== "aaa%aaa%$%置換前%$@%置換前%@%置換no後%a#%置換前%%aa$%置換no後%");
}
/// テキストの中で使用されているステップのパスを置換する。
/// Params:
/// text = テキスト。
/// oldStep = 置換前のステップパス。
/// newStep = 置換後のステップパス。
string replTextUseStep(string text, string oldStep, string newStep) { mixin(S_TRACE);
	return replTextFlagStep!('$', '%', '@')(text, oldStep, newStep);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert(replTextUseStep("「$置 換 前$」", "置 換 前", "置 換 後") == "「$置 換 後$」");
	assert(replTextUseStep("aaa$aaa$%$置換前$%$置換前$a#$置換前$$aa%$置換前$", "置換前", "置換no後")
		== "aaa$aaa$%$置換前$%$置換no後$a#$置換前$$aa%$置換no後$");
}
/// テキストの中で使用されているコモンのパスを置換する。
/// Params:
/// text = テキスト。
/// oldStep = 置換前のコモンパス。
/// newStep = 置換後のコモンパス。
string replTextUseVariant(string text, string oldVariant, string newVariant) { mixin(S_TRACE);
	return replTextFlagStep!('@', '%', '$')(text, oldVariant, newVariant);
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert(replTextUseVariant("「@置 換 前@」", "置 換 前", "置 換 後") == "「@置 換 後@」");
	assert(replTextUseVariant("aaa@aaa@%@置換前@%$@置換前@$@置換前@a#@置換前@@aa%@置換前@", "置換前", "置換no後")
		== "aaa@aaa@%@置換前@%$@置換前@$@置換no後@a#@置換前@@aa%@置換no後@");
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

/// メッセージのwidthの位置での折り返しを行う。
/// boundaryCheckがtrueの時は、openCharsを行頭禁則、
/// closeCharsを行末禁則文字の集合として禁則処理を行う。
string wrapMsg(string text, size_t width, size_t delegate(string) getWidth,
		bool boundaryCheck, in dchar[] openChars, in dchar[] closeChars, dstring wordRegex,
		ref string[size_t] fonts, ref char[size_t] colors) { mixin(S_TRACE);
	auto re = .regex(wordRegex, "i");
	string[] lines;
	size_t index = 0;
	size_t resultIndex = 0;
	string[size_t] fonts2;
	char[size_t] colors2;
	auto sortedOp = std.algorithm.sort((boundaryCheck ? openChars : []).map!(a => a.to!dstring).array().dup);
	auto sortedCl = std.algorithm.sort((boundaryCheck ? closeChars[] : []).map!(a => a.to!dstring).array().dup);
	foreach (line; text.to!dstring.splitLines()) { mixin(S_TRACE);
		auto wrapped = .wrapMsgImpl(line, width, getWidth, boundaryCheck,
			sortedOp, sortedCl, fonts, colors, fonts2, colors2, index, resultIndex, re);
		lines ~= wrapped.to!string();
		index += line.length + "\n"d.length;
		resultIndex += wrapped.length + "\n"d.length;
	}
	fonts = fonts2;
	colors = colors2;
	return std.array.join(lines, "\n");
} unittest { mixin(S_TRACE);
	mixin (UTPerf);
	size_t width(string s) { mixin(S_TRACE);
		size_t w = 0;
		foreach (dchar c; s) w += c <= 256 ? 1 : 2;
		return w;
	}
	string[size_t] f;
	char[size_t] c;
	auto op = "[\"'"d;
	auto cl = "\"]!?.,。'"d;
	auto wd = "[a-z0-9_]+|[ａ-ｚＡ-Ｚ０-９＿]+|."d;
	assert (wrapMsg("ABC.DEFG.H,IKLM?", 3, &width, true, op, cl, wd, f, c) == "ABC.\nDEF-\nG.H,\nIKL-\nM?");
	assert (wrapMsg("[abc..]\ndefg", 3, &width, true, op, cl, wd, f, c) == "[ab-\nc..]\ndef-\ng");
	assert (wrapMsg("abc..\ndefghij", 3, &width, true, op, cl, wd, f, c) == "abc.\n.\ndef-\nghi-\nj");
	assert (wrapMsg("a bc..", 4, &width, true, op, cl, wd, f, c) == "a \nbc..");
	assert (wrapMsg("a bc....],.\ndef", 4, &width, true, op, cl, wd, f, c) == "a \nbc...\n.],.\ndef");
	assert (wrapMsg("[def]", 4, &width, true, op, cl, wd, f, c) == "[def]");
	assert (wrapMsg("def[ghi]]", 4, &width, true, op, cl, wd, f, c) == "def\n[ghi\n]]");
	assert (wrapMsg("あいうえお。かきくけこ", 11, &width, true, op, cl, wd, f, c) == "あいうえお。\nかきくけこ");
	assert (wrapMsg("あいうえAA。かきくけこ", 9, &width, true, op, cl, wd, f, c) == "あいうえ\nAA。かき\nくけこ");
	assert (wrapMsg("[[[[a", 4, &width, true, op, cl, wd, f, c) == "[[[[\na");
	assert (wrapMsg("\"Let's it go!!\"", 4, &width, true, op, cl, wd, f, c) == "\"Let'\ns it \ngo!!\"");
	assert (wrapMsg("あいうえおA.かきくけこ", 11, &width, true, op, cl, wd, f, c) == "あいうえおA.\nかきくけこ");
	assert (wrapMsg("あいうえおA。かきくけこ", 11, &width, true, op, cl, wd, f, c) == "あいうえお\nA。かきくけ\nこ");
	assert (wrapMsg("ｐｑｒ pqr ＰＱＲ", 6, &width, true, op, cl, wd, f, c) == "ｐｑｒ \npqr \nＰＱＲ");

	f[5] = "#W";
	c[18] = 'L';
	c[24] = 'R';
	f[32] = "#T";
	assert (wrapMsg("CARD #WIRTH SPECIA&L\nCHA&RACTER #TEST!", 8, &width, true, op, cl, wd, f, c)
		== "CARD #W\nIRTH \nSPECIA&L\nCHA&RACTER \n#TEST!");
	assert (f[5] == "#W");
	assert (f[35] == "#T");
	assert (c[20] == 'L');
	assert (c[26] == 'R');

	f = null;
	c = null;
	c[1] = 'R';
	assert (wrapMsg("[&Rabc..]", 3, &width, true, op, cl, wd, f, c) == "[&Rab-\nc..]");
	assert (c[1] == 'R');
	assert (wrapMsg("ab...", 3, &width, true, op, cl, wd, f, c) == "ab..\n.");

	f = null;
	c = null;
	c[4] = 'R';
	assert (wrapMsg("ab..&R.", 3, &width, true, op, cl, wd, f, c) == "ab..\n&R.");
	assert (c[5] == 'R');
}

private dstring wrapMsgImpl(dstring text, size_t width, size_t delegate(string) getWidth,
		bool boundaryCheck, ref SortedRange!(dstring[]) openChars, ref SortedRange!(dstring[]) closeChars,
		ref string[size_t] fonts, ref char[size_t] colors,
		ref string[size_t] fonts2, ref char[size_t] colors2,
		size_t startIndex, size_t resultIndex,
		ref Regex!dchar re) { mixin(S_TRACE);

	dstring[] words2;
	auto index = startIndex;
	auto spc = ""d;
	foreach (cap; text.matchAll(re)) { mixin(S_TRACE);
		auto word = cap.hit;
		if (spc.length) { mixin(S_TRACE);
			words2 ~= spc ~ word[0];
			if (1 < word.length) { mixin(S_TRACE);
				words2 ~= word[1 .. $];
			}
			spc = ""d;
		} else if (index in fonts || index in colors) { mixin(S_TRACE);
			spc = word;
		} else { mixin(S_TRACE);
			words2 ~= word;
		}
		index += word.length;
	}
	assert (!spc.length);

	static struct C {
		size_t index;
		dstring str;
		bool isFont;
		bool isColor;
		@property
		const
		bool isSPC() { mixin(S_TRACE);
			return isFont || isColor;
		}
	}

	C[][] lines = [];
	C[] buf = [];
	size_t bufLen = 0;
	auto hw = getWidth("#");
	index = startIndex;
	foreach (word; words2) { mixin(S_TRACE);
		// 特殊文字か？
		auto isFont = (index in fonts) !is null;
		auto isColor = (index in colors) !is null;

		auto wordLen = getWidth(word.to!string);
		if (width < bufLen + wordLen) { mixin(S_TRACE);
			bool matchOp(in C buf) { mixin(S_TRACE);
				return !buf.isSPC && openChars.contains(buf.str);
			}
			bool matchCl(in C buf) { mixin(S_TRACE);
				return !buf.isSPC && closeChars.contains(buf.str);
			}
			bool matchLast(in C[] bufs, bool delegate(in C buf) matcher) { mixin(S_TRACE);
				foreach (i; 0 .. bufs.length) { mixin(S_TRACE);
					auto buf = bufs[$ - (1 + i)];
					if (buf.isColor) continue;
					return matcher(buf);
				}
				return false;
			}
			/// bufsの末尾部分がopenCharsやcloseCharsに該当する文字ならtrue
			/// ただし色変更の特殊文字は無視する
			bool matchOpLast(in C[] bufs) { mixin(S_TRACE);
				return matchLast(bufs, &matchOp);
			}
			/// ditto
			bool matchClLast(in C[] bufs) { mixin(S_TRACE);
				return matchLast(bufs, &matchCl);
			}

			/// wordを強制的に折り返しながら行に加える。
			void appendWordWrap() { mixin(S_TRACE);
				if (isFont || isColor) return;
				while (width < bufLen + getWidth(word.to!string)) { mixin(S_TRACE);
					auto pos = slicePos(word, width - bufLen, getWidth);
					auto word2 = word[0 .. pos];
					auto word3 = word[pos .. $];
					if (word2.length) word2 ~= "-"d;
					buf ~= C(index, word2, false, false);
					word = word3;
					lines ~= buf;
					buf = [];
					bufLen = 0;
				}
			}
			/// 行末禁止文字の位置まで遡って折り返す。
			void breakBeforeOpenChar(C[] buf2) { mixin(S_TRACE);
				while (buf2.length && matchOpLast(buf2)) { mixin(S_TRACE);
					buf2 = buf2[0 .. $ - 1];
				}
				if (buf2.length) { mixin(S_TRACE);
					auto i = buf2.length;
					lines ~= buf[0 .. i];
					buf = buf[i .. $];
					bufLen = .sum(.map!(s => getWidth(s.str.to!string))(buf));
				} else { mixin(S_TRACE);
					return appendWordWrap();
				}
			}

			if (1 <= buf.length && matchOpLast(buf) && !matchClLast(buf)) { mixin(S_TRACE);
				// 末尾に行末禁止文字があるので折り返し可能な位置まで遡って折り返す
				breakBeforeOpenChar(buf[]);
				wordLen = getWidth(word.to!string);
			} else if (!(word.length == 1 && std.uni.isWhite(word[0]))) { mixin(S_TRACE);
				// 空白文字は行末にいくつでも連ねるのでそれ以外の文字を処理
				if (matchCl(C(index, word, isFont, isColor))) { mixin(S_TRACE);
					if (width < bufLen || (width == bufLen && hw < wordLen)) { mixin(S_TRACE);
						// 行頭禁止文字は1文字まではぶら下げるが、それ以上ある場合は
						// 折り返し可能な位置まで遡って折り返す
						auto buf2 = buf[];
						while (buf2.length && matchClLast(buf2)) { mixin(S_TRACE);
							buf2 = buf2[0 .. $ - 1];
						}
						if (!buf2.length || (buf2.length == 1 && !matchOpLast(buf2))) { mixin(S_TRACE);
							// 折り返し可能な位置が無かった
							lines ~= buf;
							buf = [];
							bufLen = 0;
						} else if (2 <= buf2.length && !matchOpLast(buf2[0 .. $ - 1])) { mixin(S_TRACE);
							// 折り返し可能な位置が見つかった(折り返した箇所に行末禁止文字が無い)
							auto i = buf2.length - 1;
							lines ~= buf[0 .. i];
							buf = buf[i .. $];
							bufLen = .sum(.map!(s => getWidth(s.str.to!string))(buf));
						} else { mixin(S_TRACE);
							// 折り返し可能な位置は行末禁止文字だった
							breakBeforeOpenChar(buf2);
							wordLen = getWidth(word.to!string);
						}
					}
				} else { mixin(S_TRACE);
					// 普通に折り返す
					if (buf.length) { mixin(S_TRACE);
						lines ~= buf;
						buf = [];
						bufLen = 0;
					}
					appendWordWrap();
					wordLen = getWidth(word.to!string);
				}
			}
		}
		if (word.length) { mixin(S_TRACE);
			buf ~= C(index, word, isFont, isColor);
			if (!isColor) { mixin(S_TRACE);
				bufLen += wordLen;
			}
		}
		index += word.length;
	}

	if (buf) { mixin(S_TRACE);
		lines ~= buf;
	}

	dstring[] arr = [];
	foreach (bufs; lines) { mixin(S_TRACE);
		dstring[] line = [];
		foreach (ref c; bufs) { mixin(S_TRACE);
			if (c.isFont) { mixin(S_TRACE);
				 fonts2[resultIndex] = fonts[c.index];
			}
			if (c.isColor) { mixin(S_TRACE);
				 colors2[resultIndex] = colors[c.index];
			}
			line ~= c.str;
			resultIndex += c.str.length;
		}
		arr ~= line.join("");
		resultIndex += "\n"d.length;
	}

	return arr.join("\n");
}

/// sをwidthの位置でスライスする場合のindexを返す。
private size_t slicePos(dstring s, size_t width, size_t delegate(string) getWidth) { mixin(S_TRACE);
	size_t leftLen = 0;
	size_t leftWidth = 0;
	foreach (c; s) { mixin(S_TRACE);
		auto cWidth = getWidth(c.to!string);
		if (width < leftWidth + cWidth) { mixin(S_TRACE);
			break;
		}
		leftLen++;
		leftWidth += cWidth;
	}
	return leftLen;
} unittest { mixin(S_TRACE);
	mixin (UTPerf);
	assert (slicePos("ABC", 2, a => "ABC".countUntil(a) != -1 ? 1 : 2) == 2);
	assert (slicePos("ABCあ", 4, a => "ABC".countUntil(a) != -1 ? 1 : 2) == 3);
}
