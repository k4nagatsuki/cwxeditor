
module cwx.cwl;

import core.thread;

import std.stream;
import std.c.string;

import std.array;
import std.conv;
import std.file;
import std.path;
import std.math;
import std.string;
import std.regex;
import std.utf;

import cwx.binary;
import cwx.summary;
import cwx.card;
import cwx.coupon;
import cwx.flag;
import cwx.area;
import cwx.background;
import cwx.motion;
import cwx.event;
import cwx.types;
import cwx.utils;
import cwx.sjis;
import cwx.xml;
import cwx.path;
import cwx.skin;
import cwx.imagesize;
import cwx.structs;
import cwx.system;

import std.algorithm : min;

private bool sWith(string f, string s, out ulong id) { mixin(S_TRACE);
	if (!fnstartsWith(f, s)) return false;
	if (!fnendsWith(f, ".wid")) return false;
	auto n = f[s.length .. $ - ".wid".length];
	if (!.isNumeric(n)) return false;
	id = to!(ulong)(n);
	return true;
}
private string encodePathLegacy(string path) { mixin(S_TRACE);
	// エフェクトブースターは'/'区切りのパスを受け付けない
	return isBinImg(path) ? path : replace(path, dirSeparator, "\\");
}
private string decodePathLegacy(string path) { mixin(S_TRACE);
	return isBinImg(path) ? path : replace(path, "\\", dirSeparator);
}

private struct RData {
	const System sys;
	bool cardOnly;
	string sPath;
	string skin;
	int dataVersion;
	this (const System sys, bool cardOnly, string sPath, string skin) { mixin(S_TRACE);
		this.sys = sys;
		this.cardOnly = cardOnly;
		this.sPath = sPath;
		this.skin = skin;
		this.dataVersion = 0;
	}
}
/// 4.0形式のCardWirthシナリオを読込む。
/// Params:
/// newName = シナリオ名。null以外が指定された場合、
///           Summary.wsmが存在しない際はこの名前で新規に作成する。
Summary loadLScenario(string p, string skin, const System sys, in LoadOption opt, string newName = null) { mixin(S_TRACE);
	auto sPath = p;
	string summPath = std.path.buildPath(p, "Summary.wsm");
	Summary summ;
	RData* d;
	ulong startAreaId;
	if (.exists(summPath)) { mixin(S_TRACE);
		d = new RData(sys, opt.cardOnly, sPath, skin);
		{ mixin(S_TRACE);
			auto bytes = ByteIO(readBinary(summPath));
			summ = loadSummary(*d, bytes, startAreaId);
		}
	} else { mixin(S_TRACE);
		if (!newName) throw new SummaryException("Not Scenario: " ~ p);
		d = new RData(sys, opt.cardOnly, sPath, skin);
		summ = new Summary(newName, d.skin, d.sPath, false, true);
	}
	class Load {
		Area[] areas;
		Battle[] battles;
		Package[] packages;
		CastCard[] casts;
		SkillCard[] skills;
		ItemCard[] items;
		BeastCard[] beasts;
		InfoCard[] infos;
		string[] files;
		ulong wait = 0L;
		void load() { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Classic Load Thread");
			}
			foreach (file; this.files) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto bytes = readBinary(file);
					auto f = ByteIO(bytes);
					scope (exit) f.dispose();
					auto base = baseName(file);
					if (opt.processFunc) opt.processFunc(summ.scenarioName, base);
					ulong id;
					if (!d.cardOnly) { mixin(S_TRACE);
						if (sWith(base, "Area", id)) { mixin(S_TRACE);
							areas ~= .loadArea(*d, f, id);
						}
						if (sWith(base, "Battle", id)) { mixin(S_TRACE);
							battles ~= .loadBattle(*d, f, id);
						}
						if (sWith(base, "Package", id)) { mixin(S_TRACE);
							packages ~= .loadPackage(*d, f, id);
						}
					}
					if (sWith(base, "Mate", id)) { mixin(S_TRACE);
						casts ~= .loadCast(*d, f, id);
					}
					if (sWith(base, "Skill", id)) { mixin(S_TRACE);
						skills ~= .loadSkill(*d, f, id);
					}
					if (sWith(base, "Item", id)) { mixin(S_TRACE);
						items ~= .loadItem(*d, f, id);
					}
					if (sWith(base, "Beast", id)) { mixin(S_TRACE);
						beasts ~= .loadBeast(*d, f, id);
					}
					if (sWith(base, "Info", id)) { mixin(S_TRACE);
						infos ~= .loadInfo(*d, f, id);
					}
				} catch (Exception e) {
					debugln(file ~ " - " ~ e.msg);
					throw e;
				}
			}
			version (Console) {
				debug std.stdio.writeln("Exit Classic Load Thread");
			}
		}
	}
	if (opt.summaryOnly) return summ;
	auto load1 = new Load;
	auto load2 = new Load;
	foreach (file; clistdir(sPath)) { mixin(S_TRACE);
		if (cfnmatch(extension(file), ".wid")) { mixin(S_TRACE);
			file = std.path.buildPath(sPath, file);
			auto size = std.file.getSize(file);
			if (load1.wait < load2.wait) { mixin(S_TRACE);
				load1.files ~= file;
				load1.wait += size;
			} else { mixin(S_TRACE);
				load2.files ~= file;
				load2.wait += size;
			}
		}
	}
	if (opt.doubleIO) { mixin(S_TRACE);
		auto thr = new core.thread.Thread(&load2.load);
		thr.start();
		load1.load();
		thr.join();
	} else { mixin(S_TRACE);
		load1.load();
		load2.load();
	}
	Area[] areas = load1.areas ~ load2.areas;
	Battle[] battles = load1.battles ~ load2.battles;
	Package[] packages = load1.packages ~ load2.packages;
	CastCard[] casts = load1.casts ~ load2.casts;
	SkillCard[] skills = load1.skills ~ load2.skills;
	ItemCard[] items = load1.items ~ load2.items;
	BeastCard[] beasts = load1.beasts ~ load2.beasts;
	InfoCard[] infos = load1.infos ~ load2.infos;
	foreach (a; areas.sort) summ.add(a, false);
	foreach (a; battles.sort) summ.add(a, false);
	foreach (a; packages.sort) summ.add(a, false);
	foreach (a; casts.sort) summ.add(a, false);
	foreach (a; skills.sort) summ.add(a, false);
	foreach (a; items.sort) summ.add(a, false);
	foreach (a; beasts.sort) summ.add(a, false);
	foreach (a; infos.sort) summ.add(a, false);
	loadComment(summ);
	loadImageRef(summ);
	loadCardRef(summ);
	loadTemplate(summ);
	summ.startArea = startAreaId;
	summ.resetChanged();
	return summ;
}

/// 拡張情報"Comment.wex"を読み込む。
void loadComment(Summary summ) { mixin(S_TRACE);
	string file = summ.scenarioPath.buildPath("Comment.wex");
	if (!.exists(file)) return;
	auto node = XNode.parse(readText(file));
	if ("comments" == node.name) { mixin(S_TRACE);
		node.onTag["comment"] = (ref XNode node) { mixin(S_TRACE);
			string path = node.attr("path", false, INVALID_CWX_PATH);
			if (INVALID_CWX_PATH == path) return;
			auto ct = cast(Content) summ.findCWXPath(path);
			if (!ct) return;
			ct.comment = node.value;
		};
		node.parse();
	}
}
/// 拡張情報"ImageRef.wex"を読み込む。
void loadImageRef(Summary summ) { mixin(S_TRACE);
	string file = summ.scenarioPath.buildPath("ImageRef.wex");
	if (!.exists(file)) return;
	auto node = XNode.parse(readText(file));
	if ("imageRefs" == node.name) { mixin(S_TRACE);
		node.onTag["imageRef"] = (ref XNode node) { mixin(S_TRACE);
			string path = node.attr("path", false, INVALID_CWX_PATH);
			if (INVALID_CWX_PATH == path) return;
			auto cp = summ.findCWXPath(path);
			auto card = cast(Card) cp;
			if (card) { mixin(S_TRACE);
				card.path = decodePath(node.value);
			}
			auto mCard = cast(MenuCard) cp;
			if (mCard) { mixin(S_TRACE);
				mCard.path = decodePath(node.value);
			}
			auto summ2 = cast(Summary) cp;
			if (summ2) { mixin(S_TRACE);
				summ2.imagePath = decodePath(node.value);
			}
		};
		node.parse();
	}
}
/// 拡張情報"CardRef.wex"を読み込む。
void loadCardRef(Summary summ) { mixin(S_TRACE);
	string file = summ.scenarioPath.buildPath("CardRef.wex");
	if (!.exists(file)) return;
	auto node = XNode.parse(readText(file));
	if ("cardRefs" == node.name) { mixin(S_TRACE);
		node.onTag["maxNest"] = (ref XNode node) { mixin(S_TRACE);
			string path = node.attr("path", false, INVALID_CWX_PATH);
			if (INVALID_CWX_PATH == path) return;
			auto m = cast(Motion) summ.findCWXPath(path);
			if (!m) return;
			string value = node.value;
			try { mixin(S_TRACE);
				m.maxNest = .to!uint(value);
			} catch (ConvException e) {
				debugln(e);
			}
		};
		node.onTag["cardRef"] = (ref XNode node) { mixin(S_TRACE);
			string path = node.attr("path", false, INVALID_CWX_PATH);
			if (INVALID_CWX_PATH == path) return;
			auto cp = summ.findCWXPath(path);
			string value = node.value;
			try { mixin(S_TRACE);
				auto id = .to!ulong(value);
				auto skill = cast(SkillCard) cp;
				if (skill) { mixin(S_TRACE);
					bool hold = skill.hold;
					skill.clearData();
					skill.linkId = id;
					skill.hold = hold;
				}
				auto item = cast(ItemCard) cp;
				if (item) { mixin(S_TRACE);
					bool hold = item.hold;
					item.clearData();
					item.linkId = id;
					item.hold = hold;
				}
				auto beast = cast(BeastCard) cp;
				if (beast) { mixin(S_TRACE);
					beast.clearData();
					beast.linkId = id;
				}
			} catch (ConvException e) {
				debugln(e);
			}
		};
		node.parse();
	}
}
/// 拡張情報"Template.wex"を読み込む。
void loadTemplate(Summary summ) { mixin(S_TRACE);
	string file = summ.scenarioPath.buildPath("Template.wex");
	if (!.exists(file)) return;
	auto node = XNode.parse(readText(file));
	if ("templates" == node.name) { mixin(S_TRACE);
		node.onTag["eventTemplates"] = (ref XNode node) { mixin(S_TRACE);
			EvTemplate[] tmpls;
			node.onTag["eventTemplate"] = (ref XNode node) { mixin(S_TRACE);
				EvTemplate tmpl;
				tmpl.fromNode(node);
				tmpls ~= tmpl;
			};
			node.parse();
			summ.eventTemplates = tmpls;
		};
		node.parse();
	}
}

/// fileのIDと型を返す。
TypeInfo getType(string file, out ulong id) { mixin(S_TRACE);
	file = baseName(file);
	bool chk(string prefix) { mixin(S_TRACE);
		ulong idl;
		auto r = sWith(file, prefix, idl);
		id = idl;
		return r;
	}
	if (chk("Area")) return typeid(Area);
	if (chk("Battle")) return typeid(Battle);
	if (chk("Package")) return typeid(Package);
	if (chk("Mate")) return typeid(CastCard);
	if (chk("Skill")) return typeid(SkillCard);
	if (chk("Item")) return typeid(ItemCard);
	if (chk("Beast")) return typeid(BeastCard);
	if (chk("Info")) return typeid(InfoCard);
	return null;
}

private Target toTargetT(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0, -1: // 稀に-1になっている事がある(CardWirth Editorでは空欄)
		return Target(Target.M.SELECTED, false);
	case 1: return Target(Target.M.RANDOM, false);
	case 2: return Target(Target.M.UNSELECTED, false);
	default: throw new SummaryException("Unknown target T: " ~ to!(string)(b));
	}
}
private Target toTargetE(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Target(Target.M.SELECTED, false);
	case 1: return Target(Target.M.RANDOM, false);
	case 2: return Target(Target.M.PARTY, false);
	case 3: return Target(Target.M.SELECTED, true);
	case 4: return Target(Target.M.RANDOM, true);
	case 5: return Target(Target.M.PARTY, true);
	case 6: return Target(Target.M.PARTY, false);
	default: throw new SummaryException("Unknown target A: " ~ to!(string)(b));
	}
}
private alias toTargetE toTargetA;

private EffectType toEffectType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return EffectType.PHYSIC;
	case 1: return EffectType.MAGIC;
	case 2: return EffectType.MAGICAL_PHYSIC;
	case 3: return EffectType.PHYSICAL_MAGIC;
	case 4: return EffectType.NONE;
	default: throw new SummaryException("Unknown effect type: " ~ to!(string)(b));
	}
}
private Resist toResist(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Resist.AVOID;
	case 1: return Resist.RESIST;
	case 2: return Resist.UNFAIL;
	default: throw new SummaryException("Unknown resist: " ~ to!(string)(b));
	}
}
private CardVisual toCardVisual(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return CardVisual.NONE;
	case 1: return CardVisual.REVERSE;
	case 2: return CardVisual.HORIZONTAL;
	case 3: return CardVisual.VERTICAL;
	default: throw new SummaryException("Unknown card visual: " ~ to!(string)(b));
	}
}
private Range toRange(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Range.SELECTED;
	case 1: return Range.RANDOM;
	case 2: return Range.PARTY;
	case 3: return Range.BACKPACK;
	case 4: return Range.PARTY_AND_BACKPACK;
	case 5: return Range.FIELD;
	default: throw new SummaryException("Unknown range: " ~ to!(string)(b));
	}
}
/// CardWirth 1.50
private Range toKeyCodeRange(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Range.SELECTED;
	case 1: return Range.RANDOM;
	case 2: return Range.BACKPACK;
	case 3: return Range.PARTY_AND_BACKPACK;
	default: throw new SummaryException("Unknown range: " ~ to!(string)(b));
	}
}
/// CardWirth Extender 1.30～
private Range toCouponRange(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Range.SELECTED;
	case 1: return Range.RANDOM;
	case 2: return Range.PARTY;
	case 3: return Range.FIELD;
	default: throw new SummaryException("Unknown range: " ~ to!(string)(b));
	}
}
/// CardWirth Extender 1.30～
private CastRange[] toCastRanges(byte b) { mixin(S_TRACE);
	CastRange[] r;
	if (b & 0b0001) r ~= CastRange.PARTY;
	if (b & 0b0010) r ~= CastRange.ENEMY;
	if (b & 0b0100) r ~= CastRange.NPC;
	return r;
}
/// CardWirth 1.50
private EffectCardType toEffectCardType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return EffectCardType.ALL;
	case 1: return EffectCardType.SKILL;
	case 2: return EffectCardType.ITEM;
	case 3: return EffectCardType.BEAST;
	default: throw new SummaryException("Unknown range: " ~ to!(string)(b));
	}
}
/// CardWirth 1.50
private Comparison4 toComparison4(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Comparison4.Eq;
	case 1: return Comparison4.Ne;
	case 2: return Comparison4.Lt;
	case 3: return Comparison4.Gt;
	default: throw new SummaryException("Unknown 4 way comparison value: " ~ to!(string)(b));
	}
}
/// CardWirth 1.50
private Comparison3 toComparison3(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Comparison3.Eq;
	case 1: return Comparison3.Lt;
	case 2: return Comparison3.Gt;
	default: throw new SummaryException("Unknown 3 way comparison value: " ~ to!(string)(b));
	}
}
/// CardWirth 1.50
private BorderingType toBorderingType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return BorderingType.Outline;
	case 1: return BorderingType.Inline;
	default: throw new SummaryException("Unknown bordering type value: " ~ to!(string)(b));
	}
}
/// CardWirth 1.50
private BlendMode toBlendMode(byte b, out bool mask) { mixin(S_TRACE);
	mask = false;
	switch (b) {
	case 0: return BlendMode.Normal;
	case 1: mask = true; return BlendMode.Normal;
	case 2: return BlendMode.Add;
	case 3: return BlendMode.Subtract;
	case 4: return BlendMode.Multiply;
	default: throw new SummaryException("Unknown blend mode value: " ~ to!(string)(b));
	}
}
/// CardWirth 1.50
private GradientDir toGradientDir(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return GradientDir.None;
	case 1: return GradientDir.LeftToRight;
	case 2: return GradientDir.TopToBottom;
	default: throw new SummaryException("Unknown gradient direction value: " ~ to!(string)(b));
	}
}
/// CardWirth 1.60
private CoordinateType toCoordinateType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return CoordinateType.Absolute;
	case 1: return CoordinateType.Relative;
	case 2: return CoordinateType.Percentage;
	default: throw new SummaryException("Unknown coordinate type value: " ~ to!(string)(b));
	}
}
private Status toStatus(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Status.ACTIVE;
	case 1: return Status.INACTIVE;
	case 2: return Status.ALIVE;
	case 3: return Status.DEAD;
	case 4: return Status.FINE;
	case 5: return Status.INJURED;
	case 6: return Status.HEAVY_INJURED;
	case 7: return Status.UNCONSCIOUS;
	case 8: return Status.POISON;
	case 9: return Status.SLEEP;
	case 10: return Status.BIND;
	case 11: return Status.PARALYZE;
	case 12: return Status.CONFUSE;
	case 13: return Status.OVERHEAT;
	case 14: return Status.BRAVE;
	case 15: return Status.PANIC;
	case 16: return Status.SILENCE;
	case 17: return Status.FACE_UP;
	case 18: return Status.ANTI_MAGIC;
	case 19: return Status.UP_ACTION;
	case 20: return Status.UP_AVOID;
	case 21: return Status.UP_RESIST;
	case 22: return Status.UP_DEFENSE;
	case 23: return Status.DOWN_ACTION;
	case 24: return Status.DOWN_AVOID;
	case 25: return Status.DOWN_RESIST;
	case 26: return Status.DOWN_DEFENSE;
	default: throw new SummaryException("Unknown status: " ~ to!(string)(b));
	}
}
private Element toElement(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Element.ALL;
	case 1: return Element.HEALTH;
	case 2: return Element.MIND;
	case 3: return Element.MIRACLE;
	case 4: return Element.MAGIC;
	case 5: return Element.FIRE;
	case 6: return Element.ICE;
	default: throw new SummaryException("Unknown element: " ~ to!(string)(b));
	}
}
private DamageType toDamageType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return DamageType.LEVEL_RATIO;
	case 1: return DamageType.NORMAL;
	case 2: return DamageType.MAX;
	default: throw new SummaryException("Unknown damage type: " ~ to!(string)(b));
	}
}
private Physical toPhysical(uint b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Physical.DEX;
	case 1: return Physical.AGL;
	case 2: return Physical.INT;
	case 3: return Physical.STR;
	case 4: return Physical.VIT;
	case 5: return Physical.MIN;
	default: throw new SummaryException("Unknown pysical: " ~ to!(string)(b));
	}
}
private Mental toMental(int b) { mixin(S_TRACE);
	switch (b) {
	case 1: return Mental.AGGRESSIVE;
	case 2: return Mental.CHEERFUL;
	case 3: return Mental.BRAVE;
	case 4: return Mental.CAUTIOUS;
	case 5: return Mental.TRICKISH;
	case -1: return Mental.UNAGGRESSIVE;
	case -2: return Mental.UNCHEERFUL;
	case -3: return Mental.UNBRAVE;
	case -4: return Mental.UNCAUTIOUS;
	case -5: return Mental.UNTRICKISH;
	default: throw new SummaryException("Unknown mental: " ~ to!(string)(b));
	}
}
private Mentality toMentality(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Mentality.NORMAL;
	case 1: return Mentality.SLEEP;
	case 2: return Mentality.CONFUSE;
	case 3: return Mentality.OVERHEAT;
	case 4: return Mentality.BRAVE;
	case 5: return Mentality.PANIC;
	default: throw new SummaryException("Unknown mentality: " ~ to!(string)(b));
	}
}
private CardTarget toCardTarget(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return CardTarget.NONE;
	case 1: return CardTarget.USER;
	case 2: return CardTarget.PARTY;
	case 3: return CardTarget.ENEMY;
	case 4: return CardTarget.BOTH;
	default: throw new SummaryException("Unknown card target: " ~ to!(string)(b));
	}
}
private Premium toPremium(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Premium.NORMAL;
	case 1: return Premium.RARE;
	case 2: return Premium.PREMIUM;
	default: throw new SummaryException("Unknown card premium: " ~ to!(string)(b));
	}
}
private bool readBool(ref ByteIO f) { mixin(S_TRACE);
	return f.readByte ? true : false;
}
private string readExImage(in RData d, ref ByteIO f) { mixin(S_TRACE);
	return readStringImpl(d, f, () => cast(uint)f.readExInt);
}
private string readImage(in RData d, ref ByteIO f) { mixin(S_TRACE);
	return readStringImpl(d, f, &f.readUIntL);
}
private string readStringImpl(in RData d, ref ByteIO f, uint delegate() readSize) { mixin(S_TRACE);
	uint len = readSize();
	if (!len) return "";
	ubyte[] img = f.read(len);
	if (endsWith(img, cast(ubyte[]) B_IMG_REF)) { mixin(S_TRACE);
		size_t index = size_t.max;
		foreach_reverse (i, c; img[0 .. $ - B_IMG_REF.length]) { mixin(S_TRACE);
			if (c == '\0') { mixin(S_TRACE);
				index = i + 1;
				break;
			}
		}
		if (index != size_t.max) { mixin(S_TRACE);
			auto s = cast(string) img[index .. $ - B_IMG_REF.length];
			if (.exists(std.path.buildPath(d.sPath, s))) { mixin(S_TRACE);
				return s;
			} else { mixin(S_TRACE);
				return bImgToStr(img[0 .. index - 1]);
			}
		}
	}
	return bImgToStr(img);
}
private string readExString(ref ByteIO f, bool lns = false, bool cutText = false) { mixin(S_TRACE);
	return readStringImpl(f, lns, cutText, () => cast(uint)f.readExInt);
}
private string readString(ref ByteIO f, bool lns = false, bool cutText = false) { mixin(S_TRACE);
	return readStringImpl(f, lns, cutText, &f.readUIntL);
}
private string readStringImpl(ref ByteIO f, bool lns, bool cutText, uint delegate() readSize) { mixin(S_TRACE);
	uint len = readSize();
	if (!len) return "";
	string str = cast(string) f.read(len);
	if (!lns && str[$ - 1] == '\0') str = str[0 .. $ - 1];
	int zi = indexOf(str, '\0');
	if (-1 != zi) str = str[zi + 1 .. $];
	try { mixin(S_TRACE);
		str = touni(str);
	} catch (Exception e) {
		debugln(e);
		str = touni(str, false);
	}
	if (cutText) { mixin(S_TRACE);
		str = str.length > "TEXT\r\n".length ? str["TEXT\r\n".length .. $] : "";
	}
	str = replace(str, "\r\n", "\n");
	return str;
}
private string readString(ref ByteIO f, ref string[string] addInfo, bool lns = false, bool cutText = false) { mixin(S_TRACE);
	uint len = f.readUIntL;
	if (!len) return "";
	string str = cast(string) f.read(len);
	if (!lns && str[$ - 1] == '\0') str = str[0 .. $ - 1];
	while (true) { mixin(S_TRACE);
		int zi = indexOf(str, '\0');
		if (-1 == zi) break;
		string info = touni(str[zi + 1 .. $]);
		info = replace(info, "\r\n", "\n");
		str = str[0 .. zi];

		zi = indexOf(info, ':');
		string key, value;
		if (-1 == zi) { mixin(S_TRACE);
			key = info;
			value = "";
		} else { mixin(S_TRACE);
			key = info[0 .. zi];
			value = info[zi + 1 .. $];
		}
		addInfo[key] = value;
	}
	str = touni(str);
	if (cutText) { mixin(S_TRACE);
		str = str.length > "TEXT\r\n".length ? str["TEXT\r\n".length .. $] : "";
	}
	str = replace(str, "\r\n", "\n");
	return str;
}
private string[] readStrings(ref ByteIO f) { mixin(S_TRACE);
	auto str = readString(f, true);
	return str.length ? splitLines!string(str) : cast(string[]) [];
}
private Summary loadSummary(ref RData d, ref ByteIO f, out ulong startAreaId) { mixin(S_TRACE);
	string img = readImage(d, f);
	byte b;
	auto summ = new Summary(readString(f), d.skin, d.sPath, false, true);
	summ.imagePath = img;
	summ.desc = readString(f, true);
	summ.author = readString(f);
	if (d.cardOnly) return summ;
	summ.rCoupons = readStrings(f);
	summ.rCouponNum = f.readUIntL;
	auto area = f.readUIntL;
	if (area < 19999) { mixin(S_TRACE);
		d.dataVersion = 0;
	} else if (area < 39999) { mixin(S_TRACE);
		d.dataVersion = 2;
		startAreaId = area - 20000u;
	} else { mixin(S_TRACE);
		d.dataVersion = 4;
		startAreaId = area - 40000u;
	}
	FlagDir flagsParent(string path) { mixin(S_TRACE);
		FlagDir dir = summ.flagDirRoot;
		string par = FlagDir.up(path);
		if (par.length) { mixin(S_TRACE);
			string[] spPath = std.string.split(par, "\\")[0u .. $ - 1u];
			while (spPath.length) { mixin(S_TRACE);
				auto sub = dir.getSubDir(spPath[0u]);
				if (!sub) { mixin(S_TRACE);
					sub = new FlagDir(spPath[0u]);
					if (!dir.add(sub)) throw new SummaryException("Invalid flag and step directory: " ~ path);
				}
				dir = sub;
				spPath = spPath[1u .. $];
			}
		}
		return dir;
	}
	uint stepNum = f.readUIntL;
	for (uint i = 0u; i < stepNum; i++) { mixin(S_TRACE);
		string path = readString(f);
		uint sel = f.readUIntL;
		string[] vals;
		vals.length = 10u;
		for (uint j = 0u; j < 10u; j++) { mixin(S_TRACE);
			vals[j] = readString(f);
		}
		if (!flagsParent(path).add(new Step(FlagDir.basename(path), vals, sel))) { mixin(S_TRACE);
			throw new SummaryException("Invalid step path: " ~ path);
		}
	}
	summ.flagDirRoot.sortSteps(true);
	uint flagNum = f.readUIntL;
	for (uint i = 0u; i < flagNum; i++) { mixin(S_TRACE);
		string path = readString(f);
		bool sel = readBool(f);
		string on = readString(f);
		string off = readString(f);
		if (!flagsParent(path).add(new Flag(FlagDir.basename(path), on, off, sel))) { mixin(S_TRACE);
			throw new SummaryException("Invalid flag path: " ~ path);
		}
	}
	summ.flagDirRoot.sortFlags(true);
	summ.flagDirRoot.sortSubDirs(true);
	f.readUIntL;
	if (d.dataVersion != 0) { mixin(S_TRACE);
		summ.levelMin = f.readUIntL;
		summ.levelMax = f.readUIntL;
	}
	return summ;
}
private Motion readMotion(ref RData d, ref ByteIO f, size_t index) { mixin(S_TRACE);
	byte tType = f.readByte;
	if (d.dataVersion > 2) { mixin(S_TRACE);
		f.readByte;
		f.readByte;
		f.readByte;
		f.readByte;
		f.readByte;
	}
	byte elb = f.readByte;
	auto el = toElement(elb);
	byte type;
	if (tType == 8) { mixin(S_TRACE);
		type = 0u;
	} else { mixin(S_TRACE);
		type = f.readByte;
	}
	switch (tType) {
	case 0, 1: { mixin(S_TRACE);
		byte dmgTypB = f.readByte;
		auto dmgTyp = toDamageType(dmgTypB);
		uint val = f.readUIntL;
		Motion m;
		if (tType == 0u) { mixin(S_TRACE);
			switch (type) {
			case 0: m = new Motion(MType.HEAL, el); break;
			case 1: m = new Motion(MType.DAMAGE, el); break;
			case 2: m = new Motion(MType.ABSORB, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		} else { mixin(S_TRACE);
			switch (type) {
			case 0: m = new Motion(MType.PARALYZE, el); break;
			case 1: m = new Motion(MType.DIS_PARALYZE, el); break;
			case 2: m = new Motion(MType.POISON, el); break;
			case 3: m = new Motion(MType.DIS_POISON, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		}
		m.damageType = dmgTyp;
		m.uValue = val;
		return m;
	}
	case 2: { mixin(S_TRACE);
		switch (type) {
		case 0: return new Motion(MType.GET_SKILL_POWER, el);
		case 1: return new Motion(MType.LOSE_SKILL_POWER, el);
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 3, 4: { mixin(S_TRACE);
		uint rnd;
		if (d.dataVersion > 2) { mixin(S_TRACE);
			rnd = f.readUIntL;
		} else { mixin(S_TRACE);
			rnd = 10;
		}
		Motion m;
		if (tType == 3u) { mixin(S_TRACE);
			switch (type) {
			case 0: m = new Motion(MType.SLEEP, el); break;
			case 1: m = new Motion(MType.CONFUSE, el); break;
			case 2: m = new Motion(MType.OVERHEAT, el); break;
			case 3: m = new Motion(MType.BRAVE, el); break;
			case 4: m = new Motion(MType.PANIC, el); break;
			case 5: m = new Motion(MType.NORMAL, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		} else { mixin(S_TRACE);
			switch (type) {
			case 0: m = new Motion(MType.BIND, el); break;
			case 1: m = new Motion(MType.DIS_BIND, el); break;
			case 2: m = new Motion(MType.SILENCE, el); break;
			case 3: m = new Motion(MType.DIS_SILENCE, el); break;
			case 4: m = new Motion(MType.FACE_UP, el); break;
			case 5: m = new Motion(MType.FACE_DOWN, el); break;
			case 6: m = new Motion(MType.ANTI_MAGIC, el); break;
			case 7: m = new Motion(MType.DIS_ANTI_MAGIC, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		}
		if (m.detail.use(MArg.ROUND)) m.round = rnd;
		return m;
	}
	case 5: { mixin(S_TRACE);
		uint val = f.readUIntL;
		uint rnd;
		if (d.dataVersion > 2) { mixin(S_TRACE);
			rnd = f.readUIntL;
		} else { mixin(S_TRACE);
			rnd = 10;
		}
		Motion m;
		switch (type) {
		case 0: m = new Motion(MType.ENHANCE_ACTION, el); break;
		case 1: m = new Motion(MType.ENHANCE_AVOID, el); break;
		case 2: m = new Motion(MType.ENHANCE_RESIST, el); break;
		case 3: m = new Motion(MType.ENHANCE_DEFENSE, el); break;
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
		m.round = rnd;
		m.aValue = val;
		return m;
	}
	case 6: { mixin(S_TRACE);
		switch (type) {
		case 0: return new Motion(MType.VANISH_TARGET, el);
		case 1: return new Motion(MType.VANISH_CARD, el);
		case 2: return new Motion(MType.VANISH_BEAST, el);
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 7: { mixin(S_TRACE);
		switch (type) {
		case 0: return new Motion(MType.DEAL_ATTACK_CARD, el);
		case 1: return new Motion(MType.DEAL_POWERFUL_ATTACK_CARD, el);
		case 2: return new Motion(MType.DEAL_CRITICAL_ATTACK_CARD, el);
		case 3: return new Motion(MType.DEAL_FEINT_CARD, el);
		case 4: return new Motion(MType.DEAL_DEFENSE_CARD, el);
		case 5: return new Motion(MType.DEAL_DISTANCE_CARD, el);
		case 6: return new Motion(MType.DEAL_CONFUSE_CARD, el);
		case 7: return new Motion(MType.DEAL_SKILL_CARD, el);
		case 8: return new Motion(MType.CANCEL_ACTION, el); // CardWirth 1.50
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 8: { mixin(S_TRACE);
		BeastCard beast = null;
		uint bNum = f.readUIntL; // 常に0か1のはず
		for (uint i = 0u; i < bNum ; i++) { mixin(S_TRACE);
			auto d2 = d;
			// d.dataVersionを上書きしない
			beast = loadBeast(d2, f, 1);
		}
		auto m = new Motion(MType.SUMMON_BEAST, el);
		m.newBeast = beast;
		return m;
	}
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private Content readContent(ref RData d, ref ByteIO f, size_t index) { mixin(S_TRACE);
	byte type = f.readByte;
	string[string] info;
	string name = readString(f, info, false, false);
	uint cNum;
	if (d.dataVersion <= 2) { mixin(S_TRACE);
		cNum = f.readUIntL;
	} else { mixin(S_TRACE);
		cNum = f.readUIntL - 40000u;
	}
	Content[] childs;
	childs.length = cNum;
	for (uint i = 0u; i < cNum; i++) { mixin(S_TRACE);
		childs[i] = readContent(d, f, i);
	}
	Content e;
	switch (type) {
	case 0:
		e = new Content(CType.START, name);
		break;
	case 1:
		e = new Content(CType.LINK_START, name);
		e.start = readString(f);
		break;
	case 2:
		e = new Content(CType.START_BATTLE, name);
		e.battle = f.readUIntL;
		break;
	case 3:
		e = new Content(CType.END, name);
		e.complete = readBool(f);
		break;
	case 4:
		e = new Content(CType.END_BAD_END, name);
		break;
	case 5:
		e = new Content(CType.CHANGE_AREA, name);
		e.area = f.readUIntL;
		e.transition = Transition.DEFAULT;
		e.transitionSpeed = 5u;
		break;
	case 6: { mixin(S_TRACE);
		string msgPath = readString(f);
		Talker msgTalker;
		switch (msgPath) {
		case "": msgTalker = Talker.NARRATION; break;
		case "??Selected": msgTalker = Talker.SELECTED; break;
		case "??Unselected": msgTalker = Talker.UNSELECTED; break;
		case "??Random": msgTalker = Talker.RANDOM; break;
		case "??Card": msgTalker = Talker.CARD; break;
		default: msgTalker = Talker.IMAGE;
		}
		e = new Content(CType.TALK_MESSAGE, name);
		auto s = readString(f, true);
		e.text = s;
		e.talkerC = msgTalker;
		e.cardPath = msgTalker != Talker.IMAGE ? "" : decodePathLegacy(msgPath);
		break;
	}
	case 7:
		e = new Content(CType.PLAY_BGM, name);
		e.bgmPath = decodePathLegacy(readString(f));
		break;
	case 8: { mixin(S_TRACE);
		BgImage[] bgImgs = readBgImages(d, f, false);
		e = new Content(CType.CHANGE_BG_IMAGE, name);
		e.backs = bgImgs;
		e.transition = Transition.DEFAULT;
		e.transitionSpeed = 5u;
		break;
	}
	case 9:
		e = new Content(CType.PLAY_SOUND, name);
		e.soundPath = decodePathLegacy(readString(f));
		break;
	case 10:
		e = new Content(CType.WAIT, name);
		e.wait = f.readUIntL;
		break;
	case 11: { mixin(S_TRACE);
		uint effLev = f.readUIntL;
		byte effTarget = f.readByte;
		if (effTarget == 2) effTarget = 6;
		byte effType = f.readByte;
		byte effResist = f.readByte;
		int effSuc = f.readIntL;
		string sp = readString(f);
		string effSePath = sp == "（なし）" ? "" : decodePathLegacy(sp);
		byte effVis = f.readByte;
		uint effMotionNum = f.readUIntL;
		Motion[] effMotions;
		effMotions.length = effMotionNum;
		for (uint i = 0u; i < effMotionNum; i++) { mixin(S_TRACE);
			effMotions[i] = readMotion(d, f, i);
		}
		e = new Content(CType.EFFECT, name);
		e.signedLevel = effLev;
		e.targetNS = toTargetE(effTarget);
		e.effectType = toEffectType(effType);
		e.resist = toResist(effResist);
		e.successRate = effSuc;
		e.soundPath = effSePath;
		e.cardVisual = toCardVisual(effVis);
		e.motions = effMotions;
		break;
	}
	case 12: { mixin(S_TRACE);
		bool brMemAll = readBool(f);
		bool brMemRnd = readBool(f);
		e = new Content(CType.BRANCH_SELECT, name);
		e.targetAll = brMemAll;
		e.random = brMemRnd;
		break;
	}
	case 13: { mixin(S_TRACE);
		uint val = f.readUIntL;
		byte targ = f.readByte;
		uint phy = f.readUIntL;
		int mtl = f.readIntL;
		e = new Content(CType.BRANCH_ABILITY, name);
		e.targetS = toTargetA(targ);
		e.mental = toMental(mtl);
		e.physical = toPhysical(phy);
		e.signedLevel = val;
		break;
	}
	case 14:
		e = new Content(CType.BRANCH_RANDOM, name);
		e.percent = f.readUIntL;
		break;
	case 15:
		e = new Content(CType.BRANCH_FLAG, name);
		e.flag = readString(f);
		break;
	case 16: { mixin(S_TRACE);
		string flag = readString(f);
		bool val = readBool(f);
		e = new Content(CType.SET_FLAG, name);
		e.flag = flag;
		e.flagValue = val;
		break;
	}
	case 17:
		e = new Content(CType.BRANCH_MULTI_STEP, name);
		e.step = readString(f);
		break;
	case 18: { mixin(S_TRACE);
		string step = readString(f);
		uint val = f.readUIntL;
		e = new Content(CType.SET_STEP, name);
		e.step = step;
		e.stepValue = val;
		break;
	}
	case 19:
		e = new Content(CType.BRANCH_CAST, name);
		e.casts = f.readUIntL;
		break;
	case 20: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.BRANCH_ITEM, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.BRANCH_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 21: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.BRANCH_SKILL, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.BRANCH_SKILL, name);
		e.skill = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 22:
		e = new Content(CType.BRANCH_INFO, name);
		e.info = f.readUIntL;
		break;
	case 23: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.BRANCH_BEAST, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.BRANCH_BEAST, name);
		e.beast = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 24:
		e = new Content(CType.BRANCH_MONEY, name);
		e.money = f.readUIntL;
		break;
	case 25: { mixin(S_TRACE);
		string coupon = readString(f);
		f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.BRANCH_COUPON, name);
		e.coupon = coupon;
		e.range = toCouponRange(rng);
		break;
	}
	case 26:
		e = new Content(CType.GET_CAST, name);
		e.casts = f.readUIntL;
		break;
	case 27: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.GET_ITEM, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.GET_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 28: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.GET_SKILL, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.GET_SKILL, name);
		e.skill = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 29:
		e = new Content(CType.GET_INFO, name);
		e.info = f.readUIntL;
		break;
	case 30: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.GET_BEAST, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.GET_BEAST, name);
		e.beast = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 31:
		e = new Content(CType.GET_MONEY, name);
		e.money = f.readUIntL;
		break;
	case 32: { mixin(S_TRACE);
		string coupon = readString(f);
		int val = f.readIntL;
		byte rng = f.readByte;
		e = new Content(CType.GET_COUPON, name);
		e.coupon = coupon;
		e.range = toRange(rng);
		e.couponValue = val;
		break;
	}
	case 33:
		e = new Content(CType.LOSE_CAST, name);
		e.casts = f.readUIntL;
		break;
	case 34: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.LOSE_ITEM, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.LOSE_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 35: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.LOSE_SKILL, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.LOSE_SKILL, name);
		e.skill = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 36:
		e = new Content(CType.LOSE_INFO, name);
		e.info = f.readUIntL;
		break;
	case 37: { mixin(S_TRACE);
		ulong id = f.readUIntL;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			e = new Content(CType.LOSE_BEAST, name);
			e.item = id;
			e.range = Range.PARTY_AND_BACKPACK;
			e.cardNumber = 1;
			break;
		}
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.LOSE_BEAST, name);
		e.beast = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 38:
		e = new Content(CType.LOSE_MONEY, name);
		e.money = f.readUIntL;
		break;
	case 39: { mixin(S_TRACE);
		string coupon = readString(f);
		f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.LOSE_COUPON, name);
		e.coupon = coupon;
		e.range = toRange(rng);
		break;
	}
	case 40: { mixin(S_TRACE);
		byte targ = f.readByte;
		Talker t;
		Coupon[] coupons = [];
		int initValue = 0;
		if (3 == targ) { mixin(S_TRACE);
			t = Talker.VALUED;
			uint cpNum = f.readUIntL;
			foreach (i; 0 .. cpNum) { mixin(S_TRACE);
				coupons ~= new Coupon(readString(f), f.readIntL);
			}
			if (coupons.length && coupons[0].name == "") { mixin(S_TRACE);
				initValue = coupons[0].value;
				coupons = coupons[1 .. $];
			}
		} else { mixin(S_TRACE);
			switch (toTargetT(targ).m) {
			case Target.M.SELECTED: t = Talker.SELECTED; break;
			case Target.M.UNSELECTED: t = Talker.UNSELECTED; break;
			case Target.M.RANDOM: t = Talker.RANDOM; break;
			default: throw new SummaryException("Unknown talker: " ~ to!(string)(targ));
			}
		}
		uint dlgNum = f.readUIntL;
		SDialog[] dlgs;
		for (uint i = 0u; i < dlgNum; i++) { mixin(S_TRACE);
			string[] cps = readStrings(f);
			string text = readString(f, true);
			dlgs ~= new SDialog(text, cps);
		}
		e = new Content(CType.TALK_DIALOG, name);
		e.talkerNC = t;
		e.dialogs = dlgs;
		e.coupons = coupons;
		e.initValue = initValue;
		break;
	}
	case 41:
		e = new Content(CType.SET_STEP_UP, name);
		e.step = readString(f);
		break;
	case 42:
		e = new Content(CType.SET_STEP_DOWN, name);
		e.step = readString(f);
		break;
	case 43:
		e = new Content(CType.REVERSE_FLAG, name);
		e.flag = readString(f);
		break;
	case 44: { mixin(S_TRACE);
		string step = readString(f);
		uint val = f.readUIntL;
		e = new Content(CType.BRANCH_STEP, name);
		e.step = step;
		e.stepValue = val;
		break;
	}
	case 45:
		e = new Content(CType.ELAPSE_TIME, name);
		break;
	case 46: { mixin(S_TRACE);
		bool avg = readBool(f);
		uint val = f.readUIntL;
		e = new Content(CType.BRANCH_LEVEL, name);
		e.average = avg;
		e.unsignedLevel = val;
		break;
	}
	case 47: { mixin(S_TRACE);
		byte stat = f.readByte;
		byte targ = f.readByte;
		e = new Content(CType.BRANCH_STATUS, name);
		e.targetNS = toTargetA(targ);
		e.status = toStatus(stat);
		break;
	}
	case 48:
		e = new Content(CType.BRANCH_PARTY_NUMBER, name);
		e.partyNumber = f.readUIntL;
		break;
	case 49:
		e = new Content(CType.SHOW_PARTY, name);
		break;
	case 50:
		e = new Content(CType.HIDE_PARTY, name);
		break;
	case 51:
		e = new Content(CType.EFFECT_BREAK, name);
		break;
	case 52:
		e = new Content(CType.CALL_START, name);
		e.start = readString(f);
		break;
	case 53:
		e = new Content(CType.LINK_PACKAGE, name);
		e.packages = f.readUIntL;
		break;
	case 54:
		e = new Content(CType.CALL_PACKAGE, name);
		e.packages = f.readUIntL;
		break;
	case 55:
		e = new Content(CType.BRANCH_AREA, name);
		break;
	case 56:
		e = new Content(CType.BRANCH_BATTLE, name);
		break;
	case 57:
		e = new Content(CType.BRANCH_COMPLETE_STAMP, name);
		e.completeStamp = readString(f);
		break;
	case 58:
		e = new Content(CType.GET_COMPLETE_STAMP, name);
		e.completeStamp = readString(f);
		break;
	case 59:
		e = new Content(CType.LOSE_COMPLETE_STAMP, name);
		e.completeStamp = readString(f);
		break;
	case 60:
		e = new Content(CType.BRANCH_GOSSIP, name);
		e.gossip = readString(f);
		break;
	case 61:
		e = new Content(CType.GET_GOSSIP, name);
		e.gossip = readString(f);
		break;
	case 62:
		e = new Content(CType.LOSE_GOSSIP, name);
		e.gossip = readString(f);
		break;
	case 63:
		e = new Content(CType.BRANCH_IS_BATTLE, name);
		break;
	case 64:
		e = new Content(CType.REDISPLAY, name);
		e.transition = Transition.DEFAULT;
		e.transitionSpeed = 5u;
		break;
	case 65:
		e = new Content(CType.CHECK_FLAG, name);
		e.flag = readString(f);
		break;
	case 66:
		e = new Content(CType.SUBSTITUTE_STEP, name);
		e.step = readString(f);
		e.step2 = readString(f);
		break;
	case 67:
		e = new Content(CType.SUBSTITUTE_FLAG, name);
		e.flag = readString(f);
		e.flag2 = readString(f);
		break;
	case 68:
		e = new Content(CType.BRANCH_STEP_CMP, name);
		e.step = readString(f);
		e.step2 = readString(f);
		break;
	case 69:
		e = new Content(CType.BRANCH_FLAG_CMP, name);
		e.flag = readString(f);
		e.flag2 = readString(f);
		break;
	case 70:
		e = new Content(CType.BRANCH_RANDOM_SELECT, name);
		e.castRange = toCastRanges(f.readByte);
		ubyte style = f.readUByte;
		if (style & 0b01) { mixin(S_TRACE);
			e.levelMin = f.readUIntL;
			e.levelMax = f.readUIntL;
		} else { mixin(S_TRACE);
			e.levelMin = 0;
			e.levelMax = 0;
		}
		if (style & 0b10) { mixin(S_TRACE);
			e.status = toStatus(f.readByte);
		} else { mixin(S_TRACE);
			e.status = Status.NONE;
		}
		break;
	case 71:
		e = new Content(CType.BRANCH_KEY_CODE, name);
		e.keyCodeRange = toKeyCodeRange(f.readByte);
		e.effectCardType = toEffectCardType(f.readByte);
		e.keyCode = readString(f);
		break;
	case 72:
		e = new Content(CType.CHECK_STEP, name);
		e.step = readString(f);
		e.stepValue = f.readUIntL;
		e.comparison4 = toComparison4(f.readByte);
		break;
	case 73:
		e = new Content(CType.BRANCH_ROUND, name);
		e.comparison3 = toComparison3(f.readByte);
		e.round = f.readUIntL;
		break;
	case 74:
		e = new Content(CType.MOVE_BG_IMAGE, name);
		e.cellName = readExString(f);
		ubyte ctrl = f.readUByte;
		if (ctrl & 0b01) { mixin(S_TRACE);
			e.positionType = toCoordinateType(f.readByte);
			e.x = f.readExInt;
			e.y = f.readExInt;
		}
		if (ctrl & 0b10) { mixin(S_TRACE);
			e.sizeType = toCoordinateType(f.readByte);
			e.width = f.readExInt;
			e.height = f.readExInt;
		}
		e.transition = Transition.DEFAULT;
		e.transitionSpeed = 5u;
		break;
	case 75:
		e = new Content(CType.LOSE_BG_IMAGE, name);
		e.cellName = readExString(f);
		e.transition = Transition.DEFAULT;
		e.transitionSpeed = 5u;
		break;
	case 76:
		e = new Content(CType.REPLACE_BG_IMAGE, name);
		e.cellName = readExString(f);
		e.backs = readBgImages(d, f, false, true);
		e.transition = Transition.DEFAULT;
		e.transitionSpeed = 5u;
		break;
	default: throw new SummaryException("Unknown content type: " ~ to!(string)(type));
	}
	if (e.detail.owner) { mixin(S_TRACE);
		foreach (c; childs) { mixin(S_TRACE);
			e.add(null, c);
		}
	}
	auto p = "comment" in info;
	if (p) { mixin(S_TRACE);
		e.comment = *p;
	}
	return e;
}
private EventTree readCEventTree(ref RData d, ref ByteIO f, size_t index) { mixin(S_TRACE);
	auto tree = new EventTree("");
	auto dest = tree.starts[0u];
	uint cNum = f.readUIntL;
	for (uint i = 0u; i < cNum; i++) { mixin(S_TRACE);
		tree.add(readContent(d, f, i));
	}
	tree.remove(dest);
	return tree;
}
private EventTree readEventTree(ref RData d, ref ByteIO f, bool enemyCard, size_t index) { mixin(S_TRACE);
	auto tree = new EventTree("");
	auto dest = tree.starts[0u];
	uint cNum = f.readUIntL;
	for (uint i = 0u; i < cNum; i++) { mixin(S_TRACE);
		tree.add(readContent(d, f, i));
	}
	tree.remove(dest);
	uint igNum = f.readUIntL;
	for (uint i = 0u; i < igNum; i++) { mixin(S_TRACE);
		int ig = f.readIntL;
		if (ig < 0) { mixin(S_TRACE);
			tree.addRound(-ig);
		} else { mixin(S_TRACE);
			switch (ig) {
			case 1: tree.enter = true; break;
			case 2: tree.escape = true; break;
			case 3: tree.lose = true; break;
			case 4: tree.everyRound = true; break;
			case 5: tree.round0 = true; break;
			default: throw new SummaryException("Unknown ignition: " ~ to!(string)(ig));
			}
		}
	}
	auto keyCodes = readStrings(f);
	if (keyCodes.length && "MatchingType=All" == keyCodes[0]) { mixin(S_TRACE);
		// CardWirth 1.50
		tree.keyCodeMatchingType = KeyCodeMatchingType.And;
		keyCodes = keyCodes[1 .. $];
	}
	FKeyCode[] kcArray;
	foreach (keyCode; keyCodes) { mixin(S_TRACE);
		auto kind = d.sys.fireKeyCodeKindRef(keyCode);
		kcArray ~= FKeyCode(keyCode, kind);
	}
	tree.keyCodes = kcArray;
	return tree;
}
private BgImage readBgImage(in RData d, ref ByteIO f, bool area, size_t index) { mixin(S_TRACE);
	int x = f.readIntL;
	int y = f.readIntL;
	int w = f.readUIntL;
	uint dataVersion = 0;
	if (70000u <= w) { mixin(S_TRACE);
		w -= 70000u;
		dataVersion = 7;
	} else if (60000u <= w) { mixin(S_TRACE);
		w -= 60000u;
		dataVersion = 6;
	} else if (40000u <= w) { mixin(S_TRACE);
		w -= 40000u;
		dataVersion = 4;
	}
	int h = f.readUIntL;
	if (dataVersion <= 4) { mixin(S_TRACE);
		string imgPath = decodePathLegacy(readString(f));
		bool mask = readBool(f);
		if (dataVersion <= 2) { mixin(S_TRACE);
			return new ImageCell(imgPath, "", x, y, w, h, mask);
		}
		string flag = readString(f);
		f.readByte;
		return new ImageCell(imgPath, flag, x, y, w, h, mask);
	} else { mixin(S_TRACE);
		byte type = f.readByte;
		switch (type) {
		case 0:
			// イメージセル
			bool mask = readBool(f);
			bool foreground = readBool(f);
			bool included = readBool(f);
			string imgPath;
			if (included) { mixin(S_TRACE);
				imgPath = readExImage(d, f);
			} else { mixin(S_TRACE);
				imgPath = readString(f);
			}
			string flag = readString(f);
			f.readByte; // 不明(0)
			string cellName = readExString(f);
			auto cell = new ImageCell(imgPath, flag, x, y, w, h, mask);
			cell.foreground = foreground;
			cell.cellName = cellName;
			return cell;
		case 2:
			// テキストセル
			bool mask = readBool(f);
			bool foreground = false;
			if (7 <= dataVersion) { mixin(S_TRACE);
				foreground = readBool(f);
			}
			string text = readString(f);
			string fontName = readString(f);
			uint size = f.readUIntL;
			auto r = f.readUByte;
			auto g = f.readUByte;
			auto b = f.readUByte;
			auto a = f.readUByte;
			auto color = CRGB(r, g, b, a);
			ubyte style = f.readUByte;
			bool bold      = (style & 0b0000001) != 0;
			bool italic    = (style & 0b0000010) != 0;
			bool underline = (style & 0b0000100) != 0;
			bool strike    = (style & 0b0001000) != 0;
			bool bordering = (style & 0b0010000) != 0;
			bool vertical  = (style & 0b0100000) != 0;
			auto borderingType = BorderingType.None;
			auto borderingColor = CRGB(255, 255, 255, 255);
			uint borderingWidth = 1;
			if (bordering) { mixin(S_TRACE);
				borderingType = toBorderingType(f.readByte);
				r = f.readUByte;
				g = f.readUByte;
				b = f.readUByte;
				a = f.readUByte;
				borderingColor = CRGB(r, g, b, a);
				borderingWidth = f.readUIntL;
			}
			f.readByte; // 不明(100)
			f.readUIntL; // 不明(0)
			f.readUIntL; // 不明(0)
			f.readByte; // 不明(縦書き時:2,他:0)
			string flag = readString(f);
			f.readByte; // 不明(0)
			string cellName = "";
			if (7 <= dataVersion) { mixin(S_TRACE);
				cellName = readExString(f);
			}
			auto cell = new TextCell(text, fontName, size, color, bold, italic, underline, strike, vertical,
				borderingType, borderingColor, borderingWidth, flag, x, y, w, h, mask);
			cell.foreground = foreground;
			cell.cellName = cellName;
			return cell;
		case 3:
			// カラーセル
			bool mask = false;
			bool foreground = false;
			if (7 <= dataVersion) { mixin(S_TRACE);
				mask = readBool(f);
				foreground = readBool(f);
			}
			auto blend = toBlendMode(f.readByte, mask);
			auto gradient = toGradientDir(f.readByte);
			auto b = f.readUByte;
			auto g = f.readUByte;
			auto r = f.readUByte;
			auto a = f.readUByte;
			auto color1 = CRGB(r, g, b, a);
			auto color2 = CRGB(0, 0, 0, 255);
			if (gradient !is GradientDir.None) { mixin(S_TRACE);
				b = f.readUByte;
				g = f.readUByte;
				r = f.readUByte;
				a = f.readUByte;
				color2 = CRGB(r, g, b, a);
			}
			string flag = readString(f);
			f.readByte; // 不明(0)
			string cellName = "";
			if (7 <= dataVersion) { mixin(S_TRACE);
				cellName = readExString(f);
			}
			auto cell = new ColorCell(blend, gradient, color1, color2, flag, x, y, w, h, mask);
			cell.foreground = foreground;
			cell.cellName = cellName;
			return cell;
		case 4:
			bool mask = readBool(f);
			bool foreground = false;
			if (7 <= dataVersion) { mixin(S_TRACE);
				foreground = readBool(f);
			}
			ubyte pcNumber = f.readUByte;
			string flag = readString(f);
			f.readByte; // 不明(0)
			string cellName = "";
			if (7 <= dataVersion) { mixin(S_TRACE);
				cellName = readExString(f);
			}
			auto cell = new PCCell(pcNumber, flag, x, y, w, h, mask);
			cell.foreground = foreground;
			cell.cellName = cellName;
			return cell;
		default:
			throw new SummaryException("Unknown cell type: " ~ to!string(type));
		}
	}
}
private BgImage[] readBgImages(in RData d, ref ByteIO f, bool area, bool replBgImg = false) { mixin(S_TRACE);
	BgImage[] bgImgs;
	if (replBgImg) { mixin(S_TRACE);
		bgImgs.length = f.readUByte;
	} else { mixin(S_TRACE);
		bgImgs.length = f.readUIntL;
	}
	for (uint i = 0u; i < bgImgs.length; i++) { mixin(S_TRACE);
		bgImgs[i] = readBgImage(d, f, area, i);
	}
	if (replBgImg) return bgImgs;
	if (!bgImgs.length) return bgImgs;
	auto b = cast(ImageCell) bgImgs[0u];
	if (b && b.path == "" && b.flag == ""
			&& b.x == 0 && b.y == 0 && b.width == 632 && b.height == 420 && !b.mask) { mixin(S_TRACE);
		// クラシックなエンジンでは必ず1枚以上の背景画像が必要であるため、
		// ダミーのイメージが挿入されている
		return bgImgs[1u .. $];
	} else { mixin(S_TRACE);
		return bgImgs;
	}
}
private void readAreaHeader(ref RData d, ref ByteIO f, out ulong id, out string name) { mixin(S_TRACE);
	f.readByte;
	byte b = f.readByte;
	if (b == 'B') { mixin(S_TRACE);
		f.read(69);
		name = readString(f);
		auto idl = f.readUIntL;
		if (idl < 19999) { mixin(S_TRACE);
			d.dataVersion = 0;
			id = idl;
		} else { mixin(S_TRACE);
			d.dataVersion = 2;
			id = idl - 20000u;
		}
	} else { mixin(S_TRACE);
		d.dataVersion = 4;
		f.readByte;
		f.readByte;
		f.readByte;
		name = readString(f);
		id = f.readUIntL - 40000u;
	}
}
private Area loadArea(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	ulong id;
	string name;
	readAreaHeader(d, f, id, name);
	auto a = new Area(id, name);
	uint evtNum = f.readUIntL;
	for (uint i = 0; i < evtNum; i++) { mixin(S_TRACE);
		a.add(readEventTree(d, f, false, i));
	}
	a.spAuto = !readBool(f);
	uint cNum = f.readUIntL;
	for (uint i = 0; i < cNum; i++) { mixin(S_TRACE);
		f.readByte;
		string img = readImage(d, f);
		string cName = readString(f);
		f.readUIntL;
		string desc = readString(f);
		uint cEvtNum = f.readUIntL;
		EventTree[] trees;
		trees.length = cEvtNum;
		for (uint j = 0; j < cEvtNum; j++) { mixin(S_TRACE);
			trees[j] = readEventTree(d, f, false, j);
		}
		string flag = readString(f);
		real scale = f.readUIntL / 100.0;
		int x = f.readIntL;
		int y = f.readIntL;
		string imgPath;
		uint pcNum = 0;
		if (d.dataVersion <= 2) { mixin(S_TRACE);
			imgPath = "";
		} else { mixin(S_TRACE);
			imgPath = decodePathLegacy(readString(f));
			if (isNumeric(imgPath)) { mixin(S_TRACE);
				// PC画像
				try { mixin(S_TRACE);
					pcNum = .to!int(imgPath);
					if (0 != pcNum) imgPath = "";
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		auto c = new MenuCard(cName, imgPath.length ? imgPath : img, desc, flag, x, y, scale);
		c.pcNumber = pcNum;
		foreach (tree; trees) { mixin(S_TRACE);
			c.add(tree);
		}
		a.append(c);
	}
	foreach (bg; readBgImages(d, f, true)) { mixin(S_TRACE);
		a.append(bg);
	}
	return a;
}
private Battle loadBattle(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	ulong id;
	string name;
	readAreaHeader(d, f, id, name);
	auto r = new Battle(id, name, "");
	uint evtNum = f.readUIntL;
	for (uint i = 0u; i < evtNum; i++) { mixin(S_TRACE);
		r.add(readEventTree(d, f, false, i));
	}
	r.spAuto = !readBool(f);
	uint cNum = f.readUIntL;
	for (uint i = 0u; i < cNum; i++) { mixin(S_TRACE);
		ulong cId = f.readUIntL;
		uint cEvtNum = f.readUIntL;
		EventTree[] cTrees;
		cTrees.length = cEvtNum;
		for (uint j = 0u; j < cEvtNum; j++) { mixin(S_TRACE);
			cTrees[j] = readEventTree(d, f, true, j);
		}
		string flag = readString(f);
		real scale = f.readUIntL / 100.0;
		int x = f.readIntL;
		int y = f.readIntL;
		bool escape = readBool(f);
		auto c = new EnemyCard(cId, escape, flag, x, y, scale);
		foreach (tree; cTrees) { mixin(S_TRACE);
			c.add(tree);
		}
		r.append(c);
	}
	if (d.dataVersion > 0) { mixin(S_TRACE);
		r.music = decodePathLegacy(readString(f));
	} else { mixin(S_TRACE);
		r.music = "DefBattle.mid";
	}
	return r;
}
private Package loadPackage(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	f.readUIntL;
	string name = readString(f);
	ulong id = f.readUIntL;
	auto r = new Package(id, name);
	uint evtNum = f.readUIntL;
	for (uint i = 0u; i < evtNum; i++) { mixin(S_TRACE);
		r.add(readCEventTree(d, f, i));
	}
	return r;
}
private CastCard loadCast(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	f.readByte;
	string img = readImage(d, f);
	string name = readString(f);
	ulong idl = f.readUIntL;
	ulong id;
	if (idl < 19999) { mixin(S_TRACE);
		d.dataVersion = 0;
		id = idl;
	} else if (idl < 39999) { mixin(S_TRACE);
		d.dataVersion = 2;
		id = idl - 20000;
	} else { mixin(S_TRACE);
		d.dataVersion = 4;
		id = idl - 40000;
	}
	auto r = new CastCard(id, name, img, "", 1u, 1u);
	r.weaponResist = readBool(f);
	r.magicResist = readBool(f);
	r.undead = readBool(f);
	r.automaton = readBool(f);
	r.unholy = readBool(f);
	r.constructure = readBool(f);
	r.resist(Element.FIRE, readBool(f));
	r.resist(Element.ICE, readBool(f));
	r.weakness(Element.FIRE, readBool(f));
	r.weakness(Element.ICE, readBool(f));
	r.level = f.readUIntL;
	f.readUIntL; // 所持金。現行エンジンでは未使用
	r.desc = readString(f, true, true);
	r.life = f.readUIntL;
	r.lifeMax = f.readUIntL;
	r.paralyze = f.readUIntL;
	r.poison = f.readUIntL;
	r.defaultEnhance(Enhance.AVOID, f.readUIntL);
	r.defaultEnhance(Enhance.RESIST, f.readUIntL);
	r.defaultEnhance(Enhance.DEFENSE, f.readUIntL);
	r.physical(Physical.DEX, f.readUIntL);
	r.physical(Physical.AGL, f.readUIntL);
	r.physical(Physical.INT, f.readUIntL);
	r.physical(Physical.STR, f.readUIntL);
	r.physical(Physical.VIT, f.readUIntL);
	r.physical(Physical.MIN, f.readUIntL);
	r.mental(Mental.AGGRESSIVE, f.readIntL);
	r.mental(Mental.CHEERFUL, f.readIntL);
	r.mental(Mental.BRAVE, f.readIntL);
	r.mental(Mental.CAUTIOUS, f.readIntL);
	r.mental(Mental.TRICKISH, f.readIntL);
	r.mentality = toMentality(f.readByte);
	r.mentalityRound = f.readUIntL;
	r.bindRound = f.readUIntL;
	r.silenceRound = f.readUIntL;
	r.faceUpRound = f.readUIntL;
	r.antiMagicRound = f.readUIntL;
	r.enhance(Enhance.ACTION, f.readUIntL);
	r.enhanceRound(Enhance.ACTION, f.readUIntL);
	r.enhance(Enhance.AVOID, f.readUIntL);
	r.enhanceRound(Enhance.AVOID, f.readUIntL);
	r.enhance(Enhance.RESIST, f.readUIntL);
	r.enhanceRound(Enhance.RESIST, f.readUIntL);
	r.enhance(Enhance.DEFENSE, f.readUIntL);
	r.enhanceRound(Enhance.DEFENSE, f.readUIntL);
	uint itmNum = f.readUIntL;
	for (uint i = 0u; i < itmNum; i++) { mixin(S_TRACE);
		r.add(loadItem(d, f, i + 1));
	}
	uint sklNum = f.readUIntL;
	for (uint i = 0u; i < sklNum; i++) { mixin(S_TRACE);
		r.add(loadSkill(d, f, i + 1));
	}
	uint bstNum = f.readUIntL;
	for (uint i = 0u; i < bstNum; i++) { mixin(S_TRACE);
		r.add(loadBeast(d, f, i + 1));
	}
	if (d.dataVersion > 0) { mixin(S_TRACE);
		uint cpnNum = f.readUIntL;
		Coupon[] cpns;
		cpns.length = cpnNum;
		for (uint i = 0u; i < cpnNum; i++) { mixin(S_TRACE);
			string coupon = readString(f);
			int val = f.readIntL;
			cpns[i] = new Coupon(coupon, val);
		}
		r.coupons = cpns;
	}
	return r;
}
private C readEffCard(C)(ref RData d, ref ByteIO f) { mixin(S_TRACE);
	f.readByte;
	string img = readImage(d, f);
	string name = readString(f);
	ulong idl = f.readUIntL;
	ulong id;
	if (idl < 19999) { mixin(S_TRACE);
		d.dataVersion = 0;
		id = idl;
	} else if (idl < 39999) { mixin(S_TRACE);
		d.dataVersion = 2;
		id = idl - 20000;
	} else { mixin(S_TRACE);
		d.dataVersion = 4;
		id = idl - 40000;
	}
	string desc = readString(f);
	auto r = new C(id, name, img, desc);
	r.physical = toPhysical(f.readUIntL);
	r.mental = toMental(f.readIntL);
	r.spell = readBool(f);
	r.allRange = readBool(f);
	r.target = toCardTarget(f.readByte);
	r.effectType = toEffectType(f.readByte);
	r.resist = toResist(f.readByte);
	r.successRate = f.readIntL;
	r.visual = toCardVisual(f.readByte);
	uint mNum = f.readUIntL;
	Motion[] motions;
	motions.length = mNum;
	for (uint i = 0u; i < mNum; i++) { mixin(S_TRACE);
		motions[i] = readMotion(d, f, i);
	}
	r.motions = motions;
	r.enhance(Enhance.AVOID, f.readIntL);
	r.enhance(Enhance.RESIST, f.readIntL);
	r.enhance(Enhance.DEFENSE, f.readIntL);
	string sp1 = readString(f);
	r.soundPath1 = sp1 == "（なし）" ? "" : decodePathLegacy(sp1);
	string sp2 = readString(f);
	r.soundPath2 = sp2 == "（なし）" ? "" : decodePathLegacy(sp2);
	string[] keyCodes;
	keyCodes.length = 5u;
	for (uint i = 0u; i < 5u; i++) { mixin(S_TRACE);
		keyCodes[i] = readString(f);
	}
	r.keyCodes = keyCodes;
	if (d.dataVersion > 0) { mixin(S_TRACE);
		r.premium = toPremium(f.readByte);
	}
	if (d.dataVersion > 2) { mixin(S_TRACE);
		r.scenario = readString(f);
		r.author = readString(f);
		uint evtNum = f.readUIntL;
		for (uint i = 0u; i < evtNum; i++) { mixin(S_TRACE);
			r.add(readCEventTree(d, f, i));
		}
	}
	return r;
}
private SkillCard loadSkill(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto r = readEffCard!(SkillCard)(d, f);
	if (d.dataVersion > 2) { mixin(S_TRACE);
		r.hold = readBool(f);
	}
	r.level = f.readUIntL;
	r.useLimit = f.readUIntL;
	return r;
}
private ItemCard loadItem(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto r = readEffCard!(ItemCard)(d, f);
	if (d.dataVersion > 2) { mixin(S_TRACE);
		r.hold = readBool(f);
	}
	r.useLimit = f.readUIntL;
	r.useLimitMax = f.readUIntL;
	r.price = f.readUIntL;
	r.enhanceOwner(Enhance.AVOID, f.readUIntL);
	r.enhanceOwner(Enhance.RESIST, f.readUIntL);
	r.enhanceOwner(Enhance.DEFENSE, f.readUIntL);
	return r;
}
private BeastCard loadBeast(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto r = readEffCard!(BeastCard)(d, f);
	if (d.dataVersion > 2) { mixin(S_TRACE);
		readBool(f); // Hold
	}
	r.useLimit = f.readUIntL;
	return r;
}
private InfoCard loadInfo(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	f.readByte;
	string img = readImage(d, f);
	string name = readString(f);
	ulong idl = f.readUIntL;
	ulong id;
	if (idl < 19999) { mixin(S_TRACE);
		d.dataVersion = 0;
		id = idl;
	} else if (idl < 39999) { mixin(S_TRACE);
		d.dataVersion = 2;
		id = idl - 20000;
	} else { mixin(S_TRACE);
		d.dataVersion = 4;
		id = idl - 40000;
	}
	string desc = readString(f);
	return new InfoCard(id, name, img, desc);
}

struct SData {
	const System sys;
	string sPath;
	const Skin skin;
	bool saveInnerImagePath;
	SkillCard delegate(ulong) skill;
	ItemCard delegate(ulong) item;
	BeastCard delegate(ulong) beast;
	const(SaveOption) opt;
	string[string] comment;
	string[string] imageRef;
	ulong[string] cardRef;
	uint[string] maxNest;
	uint[ulong] nestCount; /// 召喚獣カードのCWXパスとネストされた回数。
}
/// 4.0形式のCardWirthシナリオを保存する。
void saveLScenario(Summary summ, const Skin skin, const System sys, in SaveOption opt) { mixin(S_TRACE);
	auto d = SData(sys, summ.scenarioPath, skin, opt.saveInnerImagePath, &summ.skill, &summ.item, &summ.beast, opt);
	class Save {
		Area[] areas;
		Battle[] battles;
		Package[] packages;
		CastCard[] casts;
		SkillCard[] skills;
		ItemCard[] items;
		BeastCard[] beasts;
		InfoCard[] infos;
		string[] wids;
		void save() { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Classic Load Thread");
			}
			foreach (a; areas) { mixin(S_TRACE);
				auto file = "~Area" ~ to!(string)(a.id) ~ ".wid";
				ByteIO f;
				writeArea(d, f, a);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			foreach (a; battles) { mixin(S_TRACE);
				auto file = "~Battle" ~ to!(string)(a.id) ~ ".wid";
				ByteIO f;
				writeBattle(d, f, a);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			foreach (a; packages) { mixin(S_TRACE);
				auto file = "~Package" ~ to!(string)(a.id) ~ ".wid";
				ByteIO f;
				writePackage(d, f, a);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			foreach (c; casts) { mixin(S_TRACE);
				auto file = "~Mate" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeCast(d, f, c);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			foreach (c; skills) { mixin(S_TRACE);
				auto file = "~Skill" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeSkill(d, f, c);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			foreach (c; items) { mixin(S_TRACE);
				auto file = "~Item" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeItem(d, f, c);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			foreach (c; beasts) { mixin(S_TRACE);
				auto file = "~Beast" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeBeast(d, f, c);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			foreach (c; infos) { mixin(S_TRACE);
				auto file = "~Info" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeInfo(d, f, c);
				std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
				f.dispose();
				wids ~= file;
			}
			version (Console) {
				debug std.stdio.writeln("Exit Classic Save Thread");
			}
		}
		void rename() { mixin(S_TRACE);
			foreach (file; wids) { mixin(S_TRACE);
				std.file.rename(std.path.buildPath(d.sPath, file), std.path.buildPath(d.sPath, file[1u .. $]));
			}
		}
	}
	auto save1 = new Save;
	auto save2 = new Save;
	{ mixin(S_TRACE);
		auto file = "~Summary.wsm";
		ByteIO f;
		writeSummary(d, f, summ);
		std.file.write(std.path.buildPath(d.sPath, file), f.bytes);
		save1.wids ~= file;
	}
	save1.areas = summ.areas[0 .. $ / 2];
	save2.areas = summ.areas[$ / 2 .. $];
	save1.battles = summ.battles[0 .. $ / 2];
	save2.battles = summ.battles[$ / 2 .. $];
	save1.packages = summ.packages[0 .. $ / 2];
	save2.packages = summ.packages[$ / 2 .. $];
	save1.casts = summ.casts[0 .. $ / 2];
	save2.casts = summ.casts[$ / 2 .. $];
	save1.skills = summ.skills[0 .. $ / 2];
	save2.skills = summ.skills[$ / 2 .. $];
	save1.items = summ.items[0 .. $ / 2];
	save2.items = summ.items[$ / 2 .. $];
	save1.beasts = summ.beasts[0 .. $ / 2];
	save2.beasts = summ.beasts[$ / 2 .. $];
	save1.infos = summ.infos[0 .. $ / 2];
	save2.infos = summ.infos[$ / 2 .. $];
	if (opt.doubleIO) { mixin(S_TRACE);
		auto thr = new core.thread.Thread(&save2.save);
		thr.start();
		save1.save();
		thr.join();
	} else { mixin(S_TRACE);
		save1.save();
		save2.save();
	}

	string[] renames;
	string comment = saveComment(d);
	if (comment.length) { mixin(S_TRACE);
		auto file = "~Comment.wex";
		std.file.write(d.sPath.buildPath(file), cast(immutable byte[])comment);
		renames ~= file;
	}
	string imageRef = saveImageRef(d);
	if (imageRef.length) { mixin(S_TRACE);
		auto file = "~ImageRef.wex";
		std.file.write(d.sPath.buildPath(file), cast(immutable byte[])imageRef);
		renames ~= file;
	}
	string cardRef = saveCardRef(d);
	if (cardRef.length) { mixin(S_TRACE);
		auto file = "~CardRef.wex";
		std.file.write(d.sPath.buildPath(file), cast(immutable byte[])cardRef);
		renames ~= file;
	}
	string templates = saveTemplate(summ);
	if (templates.length) { mixin(S_TRACE);
		auto file = "~Template.wex";
		std.file.write(d.sPath.buildPath(file), cast(immutable byte[])templates);
		renames ~= file;
	}

	auto sysFName = .regex!(dstring)("^(((Area|Battle|Package|Mate|Skill|Item|Beast|Info)[0-9]+\\.wid)|((Comment|ImageRef|CardRef|Template)\\.wex))$"d);
	bool canBackup = opt.backup && (!opt.backupDir.exists() || opt.backupDir.isDir());
	if (canBackup) { mixin(S_TRACE);
		foreach (file; clistdir(opt.backupDir)) { mixin(S_TRACE);
			delAll(opt.backupDir.buildPath(file));
		}
	}
	foreach (file; clistdir(d.sPath)) { mixin(S_TRACE);
		if (cfnmatch(file, "Summary.wsm")
				|| !std.regex.match(toUTF32(file), sysFName).empty) { mixin(S_TRACE);
			scope path = std.path.buildPath(d.sPath, file);
			if (canBackup) { mixin(S_TRACE);
				if (!opt.backupDir.exists()) opt.backupDir.mkdirRecurse();
				path.copy(opt.backupDir.buildPath(file));
			}
			preRemove(path);
			std.file.remove(path);
		}
	}
	save1.rename();
	save2.rename();
	foreach (file; renames) { mixin(S_TRACE);
		std.file.rename(std.path.buildPath(d.sPath, file), std.path.buildPath(d.sPath, file[1u .. $]));
	}
}

/// 拡張情報"Comment.wex"を保存する。
string saveComment(in SData d) { mixin(S_TRACE);
	if (!d.comment.length) return "";
	auto node = XNode.create("comments");
	node.newAttr("dataVersion", 1);
	foreach (cwxPath, comment; d.comment) { mixin(S_TRACE);
		auto e = node.newElement("comment", comment);
		e.newAttr("path", cwxPath);
	}
	return node.text;
}
/// 拡張情報"ImageRef.wex"を保存する。
string saveImageRef(in SData d) { mixin(S_TRACE);
	if (!d.saveInnerImagePath) return "";
	if (!d.imageRef.length) return "";
	auto node = XNode.create("imageRefs");
	node.newAttr("dataVersion", 1);
	foreach (cwxPath, imgPath; d.imageRef) { mixin(S_TRACE);
		auto e = node.newElement("imageRef", encodePath(imgPath));
		e.newAttr("path", cwxPath);
	}
	return node.text;
}
/// 拡張情報"CardRef.wex"を保存する。
string saveCardRef(in SData d) { mixin(S_TRACE);
	if (!d.cardRef.length && !d.maxNest.length) return "";
	auto node = XNode.create("cardRefs");
	node.newAttr("dataVersion", 1);
	foreach (cwxPath, maxNest; d.maxNest) { mixin(S_TRACE);
		auto e = node.newElement("maxNest", .text(maxNest));
		e.newAttr("path", cwxPath);
	}
	foreach (cwxPath, linkId; d.cardRef) { mixin(S_TRACE);
		auto e = node.newElement("cardRef", .text(linkId));
		e.newAttr("path", cwxPath);
	}
	return node.text;
}
/// 拡張情報"Template.wex"を保存する。
string saveTemplate(in Summary summ) { mixin(S_TRACE);
	if (!summ.eventTemplates.length) return "";
	auto node = XNode.create("templates");
	node.newAttr("dataVersion", 1);
	auto e = node.newElement("eventTemplates");
	foreach (t; summ.eventTemplates) { mixin(S_TRACE);
		t.toNode(e);
	}
	return node.text;
}

private byte fromTargetT(Target v) { mixin(S_TRACE);
	switch (v.m) {
	case Target.M.SELECTED: return 0;
	case Target.M.RANDOM: return 1;
	case Target.M.UNSELECTED: return 2;
	default: throw new SummaryException("Unknown target T value: " ~ to!(string)(cast(int) v.m));
	}
}
private byte fromTargetE(Target v) { mixin(S_TRACE);
	if (v.m == Target.M.UNSELECTED) throw new SummaryException("Unknown target E value with sleep: " ~ to!(string)(cast(int) v.m));
	switch (v.m) {
	case Target.M.SELECTED: return 0;
	case Target.M.RANDOM: return 1;
	case Target.M.PARTY: return 6;
	default: throw new SummaryException("Unknown target E value: " ~ to!(string)(cast(int) v.m));
	}
}
private byte fromTargetA(Target v) { mixin(S_TRACE);
	if (v.m == Target.M.UNSELECTED) throw new SummaryException("Unknown target A value with sleep: " ~ to!(string)(cast(int) v.m));
	if (v.sleep) { mixin(S_TRACE);
		switch (v.m) {
		case Target.M.SELECTED: return 3;
		case Target.M.RANDOM: return 4;
		case Target.M.PARTY: return 5;
		default: throw new SummaryException("Unknown target A value with sleep: " ~ to!(string)(cast(int) v.m));
		}
	} else { mixin(S_TRACE);
		switch (v.m) {
		case Target.M.SELECTED: return 0;
		case Target.M.RANDOM: return 1;
		case Target.M.PARTY: return 2;
		default: throw new SummaryException("Unknown target A value: " ~ to!(string)(cast(int) v.m));
		}
	}
}

private byte fromEffectType(EffectType v) { mixin(S_TRACE);
	switch (v) {
	case EffectType.PHYSIC: return 0;
	case EffectType.MAGIC: return 1;
	case EffectType.MAGICAL_PHYSIC: return 2;
	case EffectType.PHYSICAL_MAGIC: return 3;
	case EffectType.NONE: return 4;
	default: throw new SummaryException("Unknown effect type value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromResist(Resist v) { mixin(S_TRACE);
	switch (v) {
	case Resist.AVOID: return 0;
	case Resist.RESIST: return 1;
	case Resist.UNFAIL: return 2;
	default: throw new SummaryException("Unknown resist value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromCardVisual(CardVisual v) { mixin(S_TRACE);
	switch (v) {
	case CardVisual.NONE: return 0;
	case CardVisual.REVERSE: return 1;
	case CardVisual.HORIZONTAL: return 2;
	case CardVisual.VERTICAL: return 3;
	default: throw new SummaryException("Unknown card visual value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromRange(Range v) { mixin(S_TRACE);
	switch (v) {
	case Range.SELECTED: return 0;
	case Range.RANDOM: return 1;
	case Range.PARTY: return 2;
	case Range.BACKPACK: return 3;
	case Range.PARTY_AND_BACKPACK: return 4;
	case Range.FIELD: return 5;
	default: throw new SummaryException("Unknown range value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth 1.50
private byte fromKeyCodeRange(Range v) { mixin(S_TRACE);
	switch (v) {
	case Range.SELECTED: return 0;
	case Range.RANDOM: return 1;
	case Range.BACKPACK: return 2;
	case Range.PARTY_AND_BACKPACK: return 3;
	default: throw new SummaryException("Unknown range value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth Extender 1.30～
private byte fromCouponRange(Range v) { mixin(S_TRACE);
	switch (v) {
	case Range.SELECTED: return 0;
	case Range.RANDOM: return 1;
	case Range.PARTY: return 2;
	case Range.FIELD: return 3;
	default: throw new SummaryException("Unknown range value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth Extender 1.30～
private byte fromCastRanges(in CastRange[] v) { mixin(S_TRACE);
	byte r = 0;
	foreach (e; v) { mixin(S_TRACE);
		switch (e) {
		case CastRange.PARTY: r |= 0b0001; break;
		case CastRange.ENEMY: r |= 0b0010; break;
		case CastRange.NPC:   r |= 0b0100; break;
		default: throw new SummaryException("Unknown cast range value: " ~ to!(string)(cast(int) e));
		}
	}
	return r;
}
/// CardWirth 1.50
private byte fromEffectCardType(EffectCardType v) { mixin(S_TRACE);
	switch (v) {
	case EffectCardType.ALL: return 0;
	case EffectCardType.SKILL: return 1;
	case EffectCardType.ITEM: return 2;
	case EffectCardType.BEAST: return 3;
	default: throw new SummaryException("Unknown range value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth 1.50
private byte fromComparison4(Comparison4 v) { mixin(S_TRACE);
	switch (v) {
	case Comparison4.Eq: return 0;
	case Comparison4.Ne: return 1;
	case Comparison4.Lt: return 2;
	case Comparison4.Gt: return 3;
	default: throw new SummaryException("Unknown 4 way comparison value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth 1.50
private byte fromComparison3(Comparison3 v) { mixin(S_TRACE);
	switch (v) {
	case Comparison3.Eq: return 0;
	case Comparison3.Lt: return 1;
	case Comparison3.Gt: return 2;
	default: throw new SummaryException("Unknown 3 way comparison value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth 1.50
private byte fromBorderingType(BorderingType v) { mixin(S_TRACE);
	switch (v) {
	case BorderingType.Outline: return 0;
	case BorderingType.Inline: return 1;
	default: throw new SummaryException("Unknown bordering type value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth 1.50
private byte fromBlendMode(BlendMode v, bool mask) { mixin(S_TRACE);
	if (mask) return 1;
	switch (v) {
	case BlendMode.Normal: return 0;
	case BlendMode.Add: return 2;
	case BlendMode.Subtract: return 3;
	case BlendMode.Multiply: return 4;
	default: throw new SummaryException("Unknown blend mode value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth 1.50
private byte fromGradientDir(GradientDir v) { mixin(S_TRACE);
	switch (v) {
	case GradientDir.None: return 0;
	case GradientDir.LeftToRight: return 1;
	case GradientDir.TopToBottom: return 2;
	default: throw new SummaryException("Unknown gradient direction value: " ~ to!(string)(cast(int) v));
	}
}
/// CardWirth 1.60
private byte fromCoordinateType(CoordinateType v) { mixin(S_TRACE);
	switch (v) {
	case CoordinateType.Absolute: return 0;
	case CoordinateType.Relative: return 1;
	case CoordinateType.Percentage: return 2;
	default: throw new SummaryException("Unknown coordinate type value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromStatus(Status v) { mixin(S_TRACE);
	switch (v) {
	case Status.ACTIVE: return 0;
	case Status.INACTIVE: return 1;
	case Status.ALIVE: return 2;
	case Status.DEAD: return 3;
	case Status.FINE: return 4;
	case Status.INJURED: return 5;
	case Status.HEAVY_INJURED: return 6;
	case Status.UNCONSCIOUS: return 7;
	case Status.POISON: return 8;
	case Status.SLEEP: return 9;
	case Status.BIND: return 10;
	case Status.PARALYZE: return 11;
	case Status.CONFUSE: return 12;
	case Status.OVERHEAT: return 13;
	case Status.BRAVE: return 14;
	case Status.PANIC: return 15;
	case Status.SILENCE: return 16;
	case Status.FACE_UP: return 17;
	case Status.ANTI_MAGIC: return 18;
	case Status.UP_ACTION: return 19;
	case Status.UP_AVOID: return 20;
	case Status.UP_RESIST: return 21;
	case Status.UP_DEFENSE: return 22;
	case Status.DOWN_ACTION: return 23;
	case Status.DOWN_AVOID: return 24;
	case Status.DOWN_RESIST: return 25;
	case Status.DOWN_DEFENSE: return 26;
	default: throw new SummaryException("Unknown status value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromElement(Element v) { mixin(S_TRACE);
	switch (v) {
	case Element.ALL: return 0;
	case Element.HEALTH: return 1;
	case Element.MIND: return 2;
	case Element.MIRACLE: return 3;
	case Element.MAGIC: return 4;
	case Element.FIRE: return 5;
	case Element.ICE: return 6;
	default: throw new SummaryException("Unknown element value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromDamageType(DamageType v) { mixin(S_TRACE);
	switch (v) {
	case DamageType.LEVEL_RATIO: return 0;
	case DamageType.NORMAL: return 1;
	case DamageType.MAX: return 2;
	default: throw new SummaryException("Unknown damage type value: " ~ to!(string)(cast(int) v));
	}
}
private uint fromPhysical(Physical v) { mixin(S_TRACE);
	switch (v) {
	case Physical.DEX: return 0;
	case Physical.AGL: return 1;
	case Physical.INT: return 2;
	case Physical.STR: return 3;
	case Physical.VIT: return 4;
	case Physical.MIN: return 5;
	default: throw new SummaryException("Unknown pysical value: " ~ to!(string)(cast(int) v));
	}
}
private int fromMental(Mental v) { mixin(S_TRACE);
	switch (v) {
	case Mental.AGGRESSIVE: return 1;
	case Mental.CHEERFUL: return 2;
	case Mental.BRAVE: return 3;
	case Mental.CAUTIOUS: return 4;
	case Mental.TRICKISH: return 5;
	case Mental.UNAGGRESSIVE: return -1;
	case Mental.UNCHEERFUL: return -2;
	case Mental.UNBRAVE: return -3;
	case Mental.UNCAUTIOUS: return -4;
	case Mental.UNTRICKISH: return -5;
	default: throw new SummaryException("Unknown mental value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromMentality(Mentality v) { mixin(S_TRACE);
	switch (v) {
	case Mentality.NORMAL: return 0;
	case Mentality.SLEEP: return 1;
	case Mentality.CONFUSE: return 2;
	case Mentality.OVERHEAT: return 3;
	case Mentality.BRAVE: return 4;
	case Mentality.PANIC: return 5;
	default: throw new SummaryException("Unknown mentality value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromCardTarget(CardTarget v) { mixin(S_TRACE);
	switch (v) {
	case CardTarget.NONE: return 0;
	case CardTarget.USER: return 1;
	case CardTarget.PARTY: return 2;
	case CardTarget.ENEMY: return 3;
	case CardTarget.BOTH: return 4;
	default: throw new SummaryException("Unknown card target value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromPremium(Premium v) { mixin(S_TRACE);
	switch (v) {
	case Premium.NORMAL: return 0;
	case Premium.RARE: return 1;
	case Premium.PREMIUM: return 2;
	default: throw new SummaryException("Unknown card premium value: " ~ to!(string)(cast(int) v));
	}
}
private const B_IMG_REF = ":INNER_BINARY_IMAGE";
private void writeBool(ref ByteIO f, bool b) { mixin(S_TRACE);
	f.writeL(cast(byte) (b ? 1 : 0));
}
private void writeExImage(ref SData d, ref ByteIO f, CWXPath cp, string imgPath) { mixin(S_TRACE);
	writeImageImpl(d, f, cp, imgPath, (val) => f.writeExInt(val));
}
private void writeImage(ref SData d, ref ByteIO f, CWXPath cp, string imgPath) { mixin(S_TRACE);
	writeImageImpl(d, f, cp, imgPath, &f.writeL);
}
private void writeImageImpl(ref SData d, ref ByteIO f, CWXPath cp, string imgPath, void delegate(uint) writeSize) { mixin(S_TRACE);
	if (!imgPath.length) { mixin(S_TRACE);
		writeSize(cast(uint)0);
		return;
	}
	ubyte[] bytes;
	if (isBinImg(imgPath)) { mixin(S_TRACE);
		bytes = cast(ubyte[]) strToBImg(imgPath);
	} else { mixin(S_TRACE);
		auto path = d.skin.findImagePath(imgPath, d.sPath);
		if (exists(path)) { mixin(S_TRACE);
			bytes = cast(ubyte[])readBinary(path);
		}
		if (d.saveInnerImagePath) { mixin(S_TRACE);
			d.imageRef[cp.cwxPath(true)] = encodePathLegacy(imgPath);
		}
	}
	writeSize(cast(uint)bytes.length);
	f.write(bytes);
}
private void writeExString(ref ByteIO f, string str, bool lns = false, bool cutText = false) { mixin(S_TRACE);
	writeStringImpl(f, str, lns, cutText, (val) => f.writeExInt(val));
}
private void writeString(ref ByteIO f, string str, bool lns = false, bool cutText = false) { mixin(S_TRACE);
	writeStringImpl(f, str, lns, cutText, &f.writeL);
}
private void writeStringImpl(ref ByteIO f, string str, bool lns, bool cutText, void delegate(uint) writeSize) { mixin(S_TRACE);
	str = replace(str, "\n", "\r\n");
	if (cutText) { mixin(S_TRACE);
		str = "TEXT\r\n" ~ str;
	}
	if (str.length) { mixin(S_TRACE);
		str = tosjis(str);
		if (!lns) str ~= "\0";
		writeSize(cast(uint) str.length);
		f.writeL(cast(ubyte[]) str);
	} else { mixin(S_TRACE);
		if (lns) { mixin(S_TRACE);
			writeSize(cast(uint) 0);
		} else { mixin(S_TRACE);
			writeSize(cast(uint) 1);
			f.writeL(cast(char) 0x0);
		}
	}
}
private void writeStrings(ref ByteIO f, string[] strs) { mixin(S_TRACE);
	if (strs.length) { mixin(S_TRACE);
		auto s = std.string.join(strs, "\n");
		if (s.length && s[$ - 1] != '\n') s ~= '\n';
		writeString(f,  s, true);
	} else { mixin(S_TRACE);
		f.writeL(cast(uint) 0);
	}
}

private void writeSummary(ref SData d, ref ByteIO f, Summary summ) { mixin(S_TRACE);
	writeImage(d, f, summ, summ.imagePath);
	writeString(f, summ.scenarioName);
	writeString(f, summ.desc, true);
	writeString(f, summ.author);
	writeStrings(f, summ.rCoupons);
	f.writeL(cast(uint) summ.rCouponNum);
	f.writeL(cast(uint) (summ.startArea + 40000u));
	auto steps = summ.flagDirRoot.allSteps;
	f.writeL(cast(uint) steps.length);
	foreach (step; steps) { mixin(S_TRACE);
		writeString(f, step.path);
		f.writeL(cast(uint) step.select);
		for (uint i = 0u; i < 10u; i++) { mixin(S_TRACE);
			if (i < step.count) { mixin(S_TRACE);
				writeString(f, step.getValue(i));
			} else { mixin(S_TRACE);
				writeString(f, "Step - " ~ to!(string)(i + 1u));
			}
		}
	}
	auto flags = summ.flagDirRoot.allFlags;
	f.writeL(cast(uint) flags.length);
	foreach (flag; flags) { mixin(S_TRACE);
		writeString(f, flag.path);
		writeBool(f, flag.onOff);
		writeString(f, flag.on);
		writeString(f, flag.off);
	}
	f.writeL(cast(uint) 0u);
	f.writeL(cast(uint) summ.levelMin);
	f.writeL(cast(uint) summ.levelMax);
}
private void writeMotion(ref SData d, ref ByteIO f, Motion m) { mixin(S_TRACE);
	byte tType;
	byte type;
	switch (m.type) {
	case MType.HEAL:
		tType = 0;
		type = 0;
		break;
	case MType.DAMAGE:
		tType = 0;
		type = 1;
		break;
	case MType.ABSORB:
		tType = 0;
		type = 2;
		break;
	case MType.PARALYZE:
		tType = 1;
		type = 0;
		break;
	case MType.DIS_PARALYZE:
		tType = 1;
		type = 1;
		break;
	case MType.POISON:
		tType = 1;
		type = 2;
		break;
	case MType.DIS_POISON:
		tType = 1;
		type = 3;
		break;
	case MType.GET_SKILL_POWER:
		tType = 2;
		type = 0;
		break;
	case MType.LOSE_SKILL_POWER:
		tType = 2;
		type = 1;
		break;
	case MType.SLEEP:
		tType = 3;
		type = 0;
		break;
	case MType.CONFUSE:
		tType = 3;
		type = 1;
		break;
	case MType.OVERHEAT:
		tType = 3;
		type = 2;
		break;
	case MType.BRAVE:
		tType = 3;
		type = 3;
		break;
	case MType.PANIC:
		tType = 3;
		type = 4;
		break;
	case MType.NORMAL:
		tType = 3;
		type = 5;
		break;
	case MType.BIND:
		tType = 4;
		type = 0;
		break;
	case MType.DIS_BIND:
		tType = 4;
		type = 1;
		break;
	case MType.SILENCE:
		tType = 4;
		type = 2;
		break;
	case MType.DIS_SILENCE:
		tType = 4;
		type = 3;
		break;
	case MType.FACE_UP:
		tType = 4;
		type = 4;
		break;
	case MType.FACE_DOWN:
		tType = 4;
		type = 5;
		break;
	case MType.ANTI_MAGIC:
		tType = 4;
		type = 6;
		break;
	case MType.DIS_ANTI_MAGIC:
		tType = 4;
		type = 7;
		break;
	case MType.ENHANCE_ACTION:
		tType = 5;
		type = 0;
		break;
	case MType.ENHANCE_AVOID:
		tType = 5;
		type = 1;
		break;
	case MType.ENHANCE_RESIST:
		tType = 5;
		type = 2;
		break;
	case MType.ENHANCE_DEFENSE:
		tType = 5;
		type = 3;
		break;
	case MType.VANISH_TARGET:
		tType = 6;
		type = 0;
		break;
	case MType.VANISH_CARD:
		tType = 6;
		type = 1;
		break;
	case MType.VANISH_BEAST:
		tType = 6;
		type = 2;
		break;
	case MType.DEAL_ATTACK_CARD:
		tType = 7;
		type = 0;
		break;
	case MType.DEAL_POWERFUL_ATTACK_CARD:
		tType = 7;
		type = 1;
		break;
	case MType.DEAL_CRITICAL_ATTACK_CARD:
		tType = 7;
		type = 2;
		break;
	case MType.DEAL_FEINT_CARD:
		tType = 7;
		type = 3;
		break;
	case MType.DEAL_DEFENSE_CARD:
		tType = 7;
		type = 4;
		break;
	case MType.DEAL_DISTANCE_CARD:
		tType = 7;
		type = 5;
		break;
	case MType.DEAL_CONFUSE_CARD:
		tType = 7;
		type = 6;
		break;
	case MType.DEAL_SKILL_CARD:
		tType = 7;
		type = 7;
		break;
	case MType.SUMMON_BEAST:
		tType = 8;
		type = 0;
		break;
	case MType.CANCEL_ACTION: // CardWirth 1.50
		tType = 7;
		type = 8;
		break;
	default: assert (0);
	}
	f.write(tType);
	f.writeL(cast(byte) 0x8);
	f.writeL(cast(byte) 0x4);
	f.writeL(cast(byte) 0x0);
	f.writeL(cast(byte) 0x0);
	f.writeL(cast(byte) 0x0);
	f.write(fromElement(m.element));
	if (tType != 8) { mixin(S_TRACE);
		f.write(type);
	}
	switch (tType) {
	case 0, 1:
		f.write(fromDamageType(m.damageType));
		f.writeL(cast(uint) m.uValue);
		break;
	case 2:
		break;
	case 3, 4:
		f.writeL(cast(uint) m.detail.use(MArg.ROUND) ? m.round : 0xA);
		break;
	case 5:
		f.writeL(cast(uint) m.aValue);
		f.writeL(cast(uint) m.round);
		break;
	case 6, 7:
		break;
	case 8:
		if (Motion.maxNest_init != m.maxNest) { mixin(S_TRACE);
			d.maxNest[m.cwxPath(true)] = m.maxNest;
		}
		auto beast = m.beast;
		if (beast) { mixin(S_TRACE);
			if (0 != beast.linkId) { mixin(S_TRACE);
				// FIXME: リンクに失敗する
//				auto nestCount = d.nestCount.get(beast.linkId, 0) + 1;
				auto p = beast.linkId in d.nestCount;
				uint nestCount = p ? *p : 0;
				nestCount++;

				d.nestCount[beast.linkId] = nestCount;
				if (nestCount <= m.maxNest) { mixin(S_TRACE);
					f.writeL(cast(uint) 0x1);
					writeBeast(d, f, beast);
				} else { mixin(S_TRACE);
					f.writeL(cast(uint) 0x0);
				}
				if (1 >= nestCount) { mixin(S_TRACE);
					d.nestCount.remove(beast.linkId);
				} else { mixin(S_TRACE);
					d.nestCount[beast.linkId] = nestCount - 1;
				}
			} else { mixin(S_TRACE);
				f.writeL(cast(uint) 0x1);
				writeBeast(d, f, beast);
			}
		} else { mixin(S_TRACE);
			f.writeL(cast(uint) 0x0);
		}
		break;
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private void writeContent(ref SData d, ref ByteIO f, Content e) { mixin(S_TRACE);
	auto dt = e.detail;
	void wb(byte type) { mixin(S_TRACE);
		f.write(type);
		string name = e.name;
		writeString(f, name);
		if (e.comment.length) { mixin(S_TRACE);
			d.comment[e.cwxPath(true)] = e.comment;
		}
		if (dt.owner) { mixin(S_TRACE);
			f.writeL(cast(uint) 40000 + e.next.length);
			foreach (child; e.next) { mixin(S_TRACE);
				writeContent(d, f, child);
			}
		} else { mixin(S_TRACE);
			f.writeL(cast(uint) 40000);
		}
	}
	if (e.type is CType.START) { mixin(S_TRACE);
		wb(0);
	} else if (e.type is CType.LINK_START) { mixin(S_TRACE);
		wb(1);
		writeString(f, e.start);
	} else if (e.type is CType.START_BATTLE) { mixin(S_TRACE);
		wb(2);
		f.writeL(cast(uint) e.battle);
	} else if (e.type is CType.END) { mixin(S_TRACE);
		wb(3);
		writeBool(f, e.complete);
	} else if (e.type is CType.END_BAD_END) { mixin(S_TRACE);
		wb(4);
	} else if (e.type is CType.CHANGE_AREA) { mixin(S_TRACE);
		wb(5);
		f.writeL(cast(uint) e.area);
	} else if (e.type is CType.TALK_MESSAGE) { mixin(S_TRACE);
		wb(6);
		string path;
		switch (e.talkerC) {
		case Talker.NARRATION: path = ""; break;
		case Talker.SELECTED: path = "??Selected"; break;
		case Talker.UNSELECTED: path = "??Unselected"; break;
		case Talker.RANDOM: path = "??Random"; break;
		case Talker.CARD: path = "??Card"; break;
		case Talker.IMAGE: path = encodePathLegacy(e.cardPath); break;
		default: assert (0, "event 6");
		}
		writeString(f, path);
		writeString(f, lastRet(e.text), true);
	} else if (e.type is CType.PLAY_BGM) { mixin(S_TRACE);
		wb(7);
		writeString(f, encodePathLegacy(e.bgmPath));
	} else if (e.type is CType.CHANGE_BG_IMAGE) { mixin(S_TRACE);
		wb(8);
		writeBgImages(d, f, e.backs);
	} else if (e.type is CType.PLAY_SOUND) { mixin(S_TRACE);
		wb(9);
		writeString(f, encodePathLegacy(e.soundPath));
	} else if (e.type is CType.WAIT) { mixin(S_TRACE);
		wb(10);
		f.writeL(cast(uint) e.wait);
	} else if (e.type is CType.EFFECT) { mixin(S_TRACE);
		wb(11);
		f.writeL(cast(int) e.signedLevel);
		byte targ = fromTargetE(e.targetNS);
		if (targ == 6) targ = 2;
		f.write(targ);
		f.write(fromEffectType(e.effectType));
		f.write(fromResist(e.resist));
		f.writeL(cast(int) e.successRate);
		writeString(f, e.soundPath.length ? encodePathLegacy(e.soundPath) : "（なし）");
		f.write(fromCardVisual(e.cardVisual));
		f.writeL(cast(uint) e.motions.length);
		foreach (m; e.motions) { mixin(S_TRACE);
			writeMotion(d, f, m);
		}
	} else if (e.type is CType.BRANCH_SELECT) { mixin(S_TRACE);
		wb(12);
		writeBool(f, e.targetAll);
		writeBool(f, e.random);
	} else if (e.type is CType.BRANCH_ABILITY) { mixin(S_TRACE);
		wb(13);
		f.writeL(cast(int) e.signedLevel);
		f.write(fromTargetA(e.targetS));
		f.writeL(cast(uint) fromPhysical(e.physical));
		f.writeL(cast(int) fromMental(e.mental));
	} else if (e.type is CType.BRANCH_RANDOM) { mixin(S_TRACE);
		wb(14);
		f.writeL(cast(uint) e.percent);
	} else if (e.type is CType.BRANCH_FLAG) { mixin(S_TRACE);
		wb(15);
		writeString(f, e.flag);
	} else if (e.type is CType.SET_FLAG) { mixin(S_TRACE);
		wb(16);
		writeString(f, e.flag);
		writeBool(f, e.flagValue);
	} else if (e.type is CType.BRANCH_MULTI_STEP) { mixin(S_TRACE);
		wb(17);
		writeString(f, e.step);
	} else if (e.type is CType.SET_STEP) { mixin(S_TRACE);
		wb(18);
		writeString(f, e.step);
		f.writeL(cast(uint) e.stepValue);
	} else if (e.type is CType.BRANCH_CAST) { mixin(S_TRACE);
		wb(19);
		f.writeL(cast(uint) e.casts);
	} else if (e.type is CType.BRANCH_ITEM) { mixin(S_TRACE);
		wb(20);
		f.writeL(cast(uint) e.item);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_SKILL) { mixin(S_TRACE);
		wb(21);
		f.writeL(cast(uint) e.skill);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_INFO) { mixin(S_TRACE);
		wb(22);
		f.writeL(cast(uint) e.info);
	} else if (e.type is CType.BRANCH_BEAST) { mixin(S_TRACE);
		wb(23);
		f.writeL(cast(uint) e.beast);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_MONEY) { mixin(S_TRACE);
		wb(24);
		f.writeL(cast(uint) e.money);
	} else if (e.type is CType.BRANCH_COUPON) { mixin(S_TRACE);
		wb(25);
		writeString(f, e.coupon);
		f.writeL(cast(int) 0x0);
		f.write(fromCouponRange(e.range));
	} else if (e.type is CType.GET_CAST) { mixin(S_TRACE);
		wb(26);
		f.writeL(cast(uint) e.casts);
	} else if (e.type is CType.GET_ITEM) { mixin(S_TRACE);
		wb(27);
		f.writeL(cast(uint) e.item);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_SKILL) { mixin(S_TRACE);
		wb(28);
		f.writeL(cast(uint) e.skill);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_INFO) { mixin(S_TRACE);
		wb(29);
		f.writeL(cast(uint) e.info);
	} else if (e.type is CType.GET_BEAST) { mixin(S_TRACE);
		wb(30);
		f.writeL(cast(uint) e.beast);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_MONEY) { mixin(S_TRACE);
		wb(31);
		f.writeL(cast(uint) e.money);
	} else if (e.type is CType.GET_COUPON) { mixin(S_TRACE);
		wb(32);
		writeString(f, e.coupon);
		f.writeL(cast(int) e.couponValue);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_CAST) { mixin(S_TRACE);
		wb(33);
		f.writeL(cast(uint) e.casts);
	} else if (e.type is CType.LOSE_ITEM) { mixin(S_TRACE);
		wb(34);
		f.writeL(cast(uint) e.item);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_SKILL) { mixin(S_TRACE);
		wb(35);
		f.writeL(cast(uint) e.skill);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_INFO) { mixin(S_TRACE);
		wb(36);
		f.writeL(cast(uint) e.info);
	} else if (e.type is CType.LOSE_BEAST) { mixin(S_TRACE);
		wb(37);
		f.writeL(cast(uint) e.beast);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_MONEY) { mixin(S_TRACE);
		wb(38);
		f.writeL(cast(uint) e.money);
	} else if (e.type is CType.LOSE_COUPON) { mixin(S_TRACE);
		wb(39);
		writeString(f, e.coupon);
		f.writeL(cast(int) 0x0);
		f.write(fromRange(e.range));
	} else if (e.type is CType.TALK_DIALOG) { mixin(S_TRACE);
		wb(40);
		switch (e.talkerNC) {
		case Talker.SELECTED: f.writeL(cast(byte) 0); break;
		case Talker.RANDOM: f.writeL(cast(byte) 1); break;
		case Talker.UNSELECTED: f.writeL(cast(byte) 2); break;
		case Talker.VALUED: f.writeL(cast(byte) 3); break;
		default: throw new SummaryException("Unknown talker value: " ~ to!(string)(cast(int) e.talkerNC));
		}
		if (Talker.VALUED == e.talkerNC) { mixin(S_TRACE);
			if (0 == e.initValue) { mixin(S_TRACE);
				f.writeL(cast(uint) e.coupons.length);
			} else { mixin(S_TRACE);
				f.writeL(cast(uint) e.coupons.length + 1);
				writeString(f, "");
				f.writeL(cast(int) e.initValue);
			}
			foreach (c; e.coupons) { mixin(S_TRACE);
				writeString(f, c.name);
				f.writeL(cast(int) c.value);
			}
		}
		f.writeL(cast(uint) e.dialogs.length);
		foreach (dlg; e.dialogs) { mixin(S_TRACE);
			writeStrings(f, dlg.rCoupons);
			writeString(f, lastRet(dlg.text), true);
		}
	} else if (e.type is CType.SET_STEP_UP) { mixin(S_TRACE);
		wb(41);
		writeString(f, e.step);
	} else if (e.type is CType.SET_STEP_DOWN) { mixin(S_TRACE);
		wb(42);
		writeString(f, e.step);
	} else if (e.type is CType.REVERSE_FLAG) { mixin(S_TRACE);
		wb(43);
		writeString(f, e.flag);
	} else if (e.type is CType.BRANCH_STEP) { mixin(S_TRACE);
		wb(44);
		writeString(f, e.step);
		f.writeL(cast(uint) e.stepValue);
	} else if (e.type is CType.ELAPSE_TIME) { mixin(S_TRACE);
		wb(45);
	} else if (e.type is CType.BRANCH_LEVEL) { mixin(S_TRACE);
		wb(46);
		writeBool(f, e.average);
		f.writeL(cast(uint) e.unsignedLevel);
	} else if (e.type is CType.BRANCH_STATUS) { mixin(S_TRACE);
		wb(47);
		f.write(fromStatus(e.status));
		f.write(fromTargetA(e.targetNS));
	} else if (e.type is CType.BRANCH_PARTY_NUMBER) { mixin(S_TRACE);
		wb(48);
		f.writeL(cast(uint) e.partyNumber);
	} else if (e.type is CType.SHOW_PARTY) { mixin(S_TRACE);
		wb(49);
	} else if (e.type is CType.HIDE_PARTY) { mixin(S_TRACE);
		wb(50);
	} else if (e.type is CType.EFFECT_BREAK) { mixin(S_TRACE);
		wb(51);
	} else if (e.type is CType.CALL_START) { mixin(S_TRACE);
		wb(52);
		writeString(f, e.start);
	} else if (e.type is CType.LINK_PACKAGE) { mixin(S_TRACE);
		wb(53);
		f.writeL(cast(uint) e.packages);
	} else if (e.type is CType.CALL_PACKAGE) { mixin(S_TRACE);
		wb(54);
		f.writeL(cast(uint) e.packages);
	} else if (e.type is CType.BRANCH_AREA) { mixin(S_TRACE);
		wb(55);
	} else if (e.type is CType.BRANCH_BATTLE) { mixin(S_TRACE);
		wb(56);
	} else if (e.type is CType.BRANCH_COMPLETE_STAMP) { mixin(S_TRACE);
		wb(57);
		writeString(f, e.completeStamp);
	} else if (e.type is CType.GET_COMPLETE_STAMP) { mixin(S_TRACE);
		wb(58);
		writeString(f, e.completeStamp);
	} else if (e.type is CType.LOSE_COMPLETE_STAMP) { mixin(S_TRACE);
		wb(59);
		writeString(f, e.completeStamp);
	} else if (e.type is CType.BRANCH_GOSSIP) { mixin(S_TRACE);
		wb(60);
		writeString(f, e.gossip);
	} else if (e.type is CType.GET_GOSSIP) { mixin(S_TRACE);
		wb(61);
		writeString(f, e.gossip);
	} else if (e.type is CType.LOSE_GOSSIP) { mixin(S_TRACE);
		wb(62);
		writeString(f, e.gossip);
	} else if (e.type is CType.BRANCH_IS_BATTLE) { mixin(S_TRACE);
		wb(63);
	} else if (e.type is CType.REDISPLAY) { mixin(S_TRACE);
		wb(64);
	} else if (e.type is CType.CHECK_FLAG) { mixin(S_TRACE);
		wb(65);
		writeString(f, e.flag);
	} else if (e.type is CType.SUBSTITUTE_STEP) { mixin(S_TRACE);
		wb(66);
		writeString(f, e.step);
		writeString(f, e.step2);
	} else if (e.type is CType.SUBSTITUTE_FLAG) { mixin(S_TRACE);
		wb(67);
		writeString(f, e.flag);
		writeString(f, e.flag2);
	} else if (e.type is CType.BRANCH_STEP_CMP) { mixin(S_TRACE);
		wb(68);
		writeString(f, e.step);
		writeString(f, e.step2);
	} else if (e.type is CType.BRANCH_FLAG_CMP) { mixin(S_TRACE);
		wb(69);
		writeString(f, e.flag);
		writeString(f, e.flag2);
	} else if (e.type is CType.BRANCH_RANDOM_SELECT) { mixin(S_TRACE);
		wb(70);
		f.write(fromCastRanges(e.castRange));
		ubyte style = 0b00;
		if (0 < e.levelMax) { mixin(S_TRACE);
			style |= 0b01;
		}
		if (e.status !is Status.NONE) { mixin(S_TRACE);
			style |= 0b10;
		}
		f.write(style);
		if (style & 0b01) { mixin(S_TRACE);
			f.writeL(e.levelMin);
			f.writeL(e.levelMax);
		}
		if (style & 0b10) { mixin(S_TRACE);
			f.write(fromStatus(e.status));
		}
	} else if (e.type is CType.BRANCH_KEY_CODE) { mixin(S_TRACE);
		wb(71);
		f.write(fromKeyCodeRange(e.keyCodeRange));
		f.write(fromEffectCardType(e.effectCardType));
		writeString(f, e.keyCode);
	} else if (e.type is CType.CHECK_STEP) { mixin(S_TRACE);
		wb(72);
		writeString(f, e.step);
		f.writeL(cast(uint) e.stepValue);
		f.write(fromComparison4(e.comparison4));
	} else if (e.type is CType.BRANCH_ROUND) { mixin(S_TRACE);
		wb(73);
		f.write(fromComparison3(e.comparison3));
		f.writeL(cast(uint) e.round);
	} else if (e.type is CType.MOVE_BG_IMAGE) { mixin(S_TRACE);
		wb(74);
		writeString(f, e.cellName);
		ubyte ctrl = 0b00;
		if (e.positionType !is CoordinateType.None) { mixin(S_TRACE);
			ctrl |= 0b01;
		}
		if (e.sizeType !is CoordinateType.None) { mixin(S_TRACE);
			ctrl |= 0b10;
		}
		f.write(ctrl);
		if (e.positionType !is CoordinateType.None) { mixin(S_TRACE);
			f.write(fromCoordinateType(e.positionType));
			f.writeExInt(e.x);
			f.writeExInt(e.y);
		}
		if (e.sizeType !is CoordinateType.None) { mixin(S_TRACE);
			f.write(fromCoordinateType(e.sizeType));
			f.writeExInt(e.width);
			f.writeExInt(e.height);
		}
	} else if (e.type is CType.LOSE_BG_IMAGE) { mixin(S_TRACE);
		wb(75);
		writeString(f, e.cellName);
	} else if (e.type is CType.REPLACE_BG_IMAGE) { mixin(S_TRACE);
		wb(76);
		writeString(f, e.cellName);
		f.write(cast(ubyte).min(255, e.backs.length));
		writeBgImages(d, f, e.backs.length <= 255 ? e.backs : e.backs[0..256]);
	} else { mixin(S_TRACE);
		assert (0, "event");
	}
}
private void writeCEventTree(ref SData d, ref ByteIO f, EventTree tree) { mixin(S_TRACE);
	f.writeL(cast(uint) tree.starts.length);
	foreach (evt; tree.starts) { mixin(S_TRACE);
		writeContent(d, f, evt);
	}
}
private void writeEventTree(ref SData d, ref ByteIO f, EventTree tree) { mixin(S_TRACE);
	f.writeL(cast(uint) tree.starts.length);
	foreach (evt; tree.starts) { mixin(S_TRACE);
		writeContent(d, f, evt);
	}
	int[] igs;
	if (tree.fireEnter) igs ~= 1;
	if (tree.fireEscape) igs ~= 2;
	if (tree.fireLose) igs ~= 3;
	if (tree.fireEveryRound) igs ~= 4;
	if (tree.fireRound0) igs ~= 5;
	foreach (rnd; tree.rounds) { mixin(S_TRACE);
		igs ~= -(cast(int) rnd);
	}
	f.writeL(cast(uint) igs.length);
	foreach (ig; igs) { mixin(S_TRACE);
		f.writeL(cast(int) ig);
	}
	string[] keyCodes;
	foreach (keyCode; tree.keyCodes) { mixin(S_TRACE);
		keyCodes ~= d.sys.convFireKeyCode(keyCode.keyCode, keyCode.kind);
	}
	if (KeyCodeMatchingType.And is tree.keyCodeMatchingType) { mixin(S_TRACE);
		// CardWirth 1.50
		writeStrings(f, ["MatchingType=All"] ~ keyCodes);
	} else { mixin(S_TRACE);
		writeStrings(f, keyCodes);
	}
}
private void writeBgImage(ref SData d, ref ByteIO f, BgImage b) { mixin(S_TRACE);
	auto ic = cast(ImageCell) b;
	if (ic) { mixin(S_TRACE);
		bool included = isBinImg(ic.path);
		if (included || ic.foreground || ic.cellName != "") { mixin(S_TRACE);
			f.writeL(cast(int)ic.x);
			f.writeL(cast(int)ic.y);
			f.writeL(cast(uint)ic.width + 70000u);
			f.writeL(cast(uint)ic.height);
			f.write(cast(byte)0);
			writeBool(f, ic.mask);
			writeBool(f, ic.foreground);
			writeBool(f, included);
			if (included) { mixin(S_TRACE);
				writeExImage(d, f, ic, ic.path);
			} else { mixin(S_TRACE);
				writeString(f, encodePathLegacy(ic.path));
			}
			writeString(f, ic.flag);
			f.writeL(cast(byte) 0x0);
			writeExString(f, ic.cellName);
		} else { mixin(S_TRACE);
			f.writeL(cast(int) ic.x);
			f.writeL(cast(int) ic.y);
			f.writeL(cast(uint) ic.width + 40000u);
			f.writeL(cast(uint) ic.height);
			writeString(f, encodePathLegacy(ic.path));
			writeBool(f, ic.mask);
			writeString(f, ic.flag);
			f.writeL(cast(byte) 0x0);
		}
	}
	auto tc = cast(TextCell) b;
	if (tc) { mixin(S_TRACE);
		f.writeL(cast(int) tc.x);
		f.writeL(cast(int) tc.y);
		if (tc.foreground || tc.cellName != "") {
			f.writeL(cast(uint)tc.width + 70000u);
		} else {
			f.writeL(cast(uint)tc.width + 60000u);
		}
		f.writeL(cast(uint) tc.height);
		f.write(cast(byte) 2);
		writeBool(f, tc.mask);
		if (tc.foreground || tc.cellName != "") {
			writeBool(f, tc.foreground);
		}
		writeString(f, tc.text);
		writeString(f, tc.fontName);
		f.writeL(cast(uint) tc.size);
		auto color = tc.color;
		f.write(cast(ubyte) color.r);
		f.write(cast(ubyte) color.g);
		f.write(cast(ubyte) color.b);
		f.write(cast(ubyte) color.a);
		bool bordering = tc.borderingType !is BorderingType.None;
		ubyte style = 0;
		if (tc.bold)      style |= 0b0000001;
		if (tc.italic)    style |= 0b0000010;
		if (tc.underline) style |= 0b0000100;
		if (tc.strike)    style |= 0b0001000;
		if (bordering)    style |= 0b0010000;
		if (tc.vertical)  style |= 0b0100000;
		f.write(style);

		if (bordering) { mixin(S_TRACE);
			f.write(fromBorderingType(tc.borderingType));
			auto bColor = tc.borderingColor;
			f.write(cast(ubyte) bColor.r);
			f.write(cast(ubyte) bColor.g);
			f.write(cast(ubyte) bColor.b);
			f.write(cast(ubyte) bColor.a);
			f.writeL(cast(uint) tc.borderingWidth);
		}
		f.write(cast(byte) 100);
		f.writeL(cast(uint) 0);
		f.writeL(cast(uint) 0);
		f.write(cast(byte) (tc.vertical ? 2 : 0));

		writeString(f, tc.flag);
		f.writeL(cast(byte) 0x0);
		if (tc.foreground || tc.cellName != "") {
			writeExString(f, tc.cellName);
		}
	}
	auto cc = cast(ColorCell) b;
	if (cc) { mixin(S_TRACE);
		f.writeL(cast(int) cc.x);
		f.writeL(cast(int) cc.y);
		if (cc.foreground || cc.cellName != "") {
			f.writeL(cast(uint)cc.width + 70000u);
		} else {
			f.writeL(cast(uint)cc.width + 60000u);
		}
		f.writeL(cast(uint) cc.height);
		f.write(cast(byte) 3);
		if (cc.foreground || cc.cellName != "") {
			writeBool(f, cc.mask);
			writeBool(f, cc.foreground);
		}
		f.write(fromBlendMode(cc.blendMode, cc.mask));
		f.write(fromGradientDir(cc.gradientDir));
		auto color1 = cc.color1;
		f.write(cast(ubyte) color1.b);
		f.write(cast(ubyte) color1.g);
		f.write(cast(ubyte) color1.r);
		f.write(cast(ubyte) color1.a);
		if (cc.gradientDir !is GradientDir.None) { mixin(S_TRACE);
			auto color2 = cc.color2;
			f.write(cast(ubyte) color2.b);
			f.write(cast(ubyte) color2.g);
			f.write(cast(ubyte) color2.r);
			f.write(cast(ubyte) color2.a);
		}
		writeString(f, cc.flag);
		f.writeL(cast(byte) 0x0);
		if (cc.foreground || cc.cellName != "") {
			writeExString(f, cc.cellName);
		}
	}
}
private void writeBgImages(ref SData d, ref ByteIO f, BgImage[] backs) { mixin(S_TRACE);
	auto b = backs.length ? cast(ImageCell) backs[0] : null;
	if (b && b.path != "" && b.flag == "" && b.x == 0 && b.y == 0
			&& b.width == 632 && b.height == 420 && !b.mask) { mixin(S_TRACE);
		f.writeL(cast(uint) backs.length);
	} else { mixin(S_TRACE);
		f.writeL(cast(uint) backs.length + 1u);
		writeBgImage(d, f, new ImageCell("", "", 0, 0, 632, 420, false));
	}
	foreach (back; backs) { mixin(S_TRACE);
		writeBgImage(d, f, back);
	}
}
private void writeArea(ref SData d, ref ByteIO f, Area a) { mixin(S_TRACE);
	f.writeL(cast(byte) 0x0);
	f.writeL(cast(uint) 0x0);
	writeString(f, a.name);
	f.writeL(cast(uint) (a.id + 40000u));
	f.writeL(cast(uint) a.trees.length);
	foreach (tree; a.trees) { mixin(S_TRACE);
		writeEventTree(d, f, tree);
	}
	writeBool(f, !a.spAuto);
	f.writeL(cast(uint) a.cards.length);
	foreach (c; a.cards) { mixin(S_TRACE);
		f.writeL(cast(byte) 0x0);
		bool saveBinImg;
		if (isBinImg(c.path)) { mixin(S_TRACE);
			writeImage(d, f, c, c.path);
			saveBinImg = true;
		} else { mixin(S_TRACE);
			if (".bmp" == .toLower(c.path.extension())) { mixin(S_TRACE);
				writeImage(d, f, c, "");
				saveBinImg = false;
			} else { mixin(S_TRACE);
				// Bitmapへの変換が行われた場合は必ずパスを保存する
				d.imageRef[c.cwxPath(true)] = encodePathLegacy(c.path);
				writeImage(d, f, c, c.path);
				saveBinImg = true;
			}
		}
		writeString(f, c.name);
		f.writeL(cast(byte) 0x40);
		f.writeL(cast(byte) 0x9C);
		f.writeL(cast(byte) 0x0);
		f.writeL(cast(byte) 0x0);
		writeString(f, c.desc);
		f.writeL(cast(uint) c.trees.length);
		foreach (tree; c.trees) { mixin(S_TRACE);
			writeEventTree(d, f, tree);
		}
		writeString(f, c.flag);
		f.writeL(cast(uint) rndtol(c.scale * 100.0));
		f.writeL(cast(int) c.x);
		f.writeL(cast(int) c.y);
		if (0 == c.pcNumber) { mixin(S_TRACE);
			writeString(f, saveBinImg ? "" : encodePathLegacy(c.path));
		} else { mixin(S_TRACE);
			writeString(f, .text(c.pcNumber));
		}
	}
	writeBgImages(d, f, a.backs);
}
private void writeBattle(ref SData d, ref ByteIO f, Battle a) { mixin(S_TRACE);
	f.writeL(cast(byte) 0x1);
	f.writeL(cast(uint) 0x0);
	writeString(f, a.name);
	f.writeL(cast(uint) (a.id + 40000u));
	f.writeL(cast(uint) a.trees.length);
	foreach (tree; a.trees) { mixin(S_TRACE);
		writeEventTree(d, f, tree);
	}
	writeBool(f, !a.spAuto);
	f.writeL(cast(uint) a.cards.length);
	foreach (c; a.cards) { mixin(S_TRACE);
		f.writeL(cast(uint) c.id);
		f.writeL(cast(uint) c.trees.length);
		foreach (tree; c.trees) { mixin(S_TRACE);
			writeEventTree(d, f, tree);
		}
		writeString(f, c.flag);
		f.writeL(cast(uint) rndtol(c.scale * 100.0));
		f.writeL(cast(int) c.x);
		f.writeL(cast(int) c.y);
		writeBool(f, c.escape);
	}
	writeString(f, encodePathLegacy(a.music));
}
private void writePackage(ref SData d, ref ByteIO f, Package a) { mixin(S_TRACE);
	f.writeL(cast(uint) 0x4);
	writeString(f, a.name);
	f.writeL(cast(uint) a.id);
	f.writeL(cast(uint) a.trees.length);
	foreach (tree; a.trees) { mixin(S_TRACE);
		writeCEventTree(d, f, tree);
	}
}
private void writeCast(ref SData d, ref ByteIO f, CastCard c) { mixin(S_TRACE);
	f.writeL(cast(byte) 0x2);
	writeImage(d, f, c, c.path);
	writeString(f, c.name);
	f.writeL(cast(uint) (c.id + 40000u));
	writeBool(f, c.weaponResist);
	writeBool(f, c.magicResist);
	writeBool(f, c.undead);
	writeBool(f, c.automaton);
	writeBool(f, c.unholy);
	writeBool(f, c.constructure);
	writeBool(f, c.resist(Element.FIRE));
	writeBool(f, c.resist(Element.ICE));
	writeBool(f, c.weakness(Element.FIRE));
	writeBool(f, c.weakness(Element.ICE));
	f.writeL(cast(uint) c.level);
	f.writeL(cast(uint) 0u); // 所持金。現行エンジンでは未使用
	writeString(f, c.desc, true, true);
	f.writeL(cast(uint) c.life);
	f.writeL(cast(uint) c.lifeMax);
	f.writeL(cast(uint) c.paralyze);
	f.writeL(cast(uint) c.poison);
	f.writeL(cast(int) c.defaultEnhance(Enhance.AVOID));
	f.writeL(cast(int) c.defaultEnhance(Enhance.RESIST));
	f.writeL(cast(int) c.defaultEnhance(Enhance.DEFENSE));
	f.writeL(cast(uint) c.physical(Physical.DEX));
	f.writeL(cast(uint) c.physical(Physical.AGL));
	f.writeL(cast(uint) c.physical(Physical.INT));
	f.writeL(cast(uint) c.physical(Physical.STR));
	f.writeL(cast(uint) c.physical(Physical.VIT));
	f.writeL(cast(uint) c.physical(Physical.MIN));
	f.writeL(cast(int) c.mental(Mental.AGGRESSIVE));
	f.writeL(cast(int) c.mental(Mental.CHEERFUL));
	f.writeL(cast(int) c.mental(Mental.BRAVE));
	f.writeL(cast(int) c.mental(Mental.CAUTIOUS));
	f.writeL(cast(int) c.mental(Mental.TRICKISH));
	f.write(fromMentality(c.mentality));
	f.writeL(cast(uint) c.mentalityRound);
	f.writeL(cast(uint) c.bindRound);
	f.writeL(cast(uint) c.silenceRound);
	f.writeL(cast(uint) c.faceUpRound);
	f.writeL(cast(uint) c.antiMagicRound);
	foreach (enh; [Enhance.ACTION, Enhance.AVOID, Enhance.RESIST, Enhance.DEFENSE]) { mixin(S_TRACE);
		int val = c.enhance(enh);
		uint round = c.enhanceRound(enh);
		if (!val) round = 0;
		f.writeL(val);
		f.writeL(round);
	}
	f.writeL(cast(uint) c.items.length);
	foreach (cc; c.items) { mixin(S_TRACE);
		writeItem(d, f, cc);
	}
	f.writeL(cast(uint) c.skills.length);
	foreach (cc; c.skills) { mixin(S_TRACE);
		writeSkill(d, f, cc);
	}
	f.writeL(cast(uint) c.beasts.length);
	foreach (cc; c.beasts) { mixin(S_TRACE);
		writeBeast(d, f, cc);
	}
	f.writeL(cast(uint) c.coupons.length);
	foreach (cc; c.coupons) { mixin(S_TRACE);
		writeString(f, cc.coupon);
		f.writeL(cast(int) cc.value);
	}
}
private void writeEffCard(ref SData d, ref ByteIO f, EffectCard c, byte type, ulong id) { mixin(S_TRACE);
	f.write(type);
	writeImage(d, f, c, c.path);
	writeString(f, c.name);
	f.writeL(cast(uint) (id + 40000u));
	writeString(f, c.desc);
	f.writeL(cast(uint) fromPhysical(c.physical));
	f.writeL(cast(int) fromMental(c.mental));
	writeBool(f, c.spell);
	writeBool(f, c.allRange);
	f.write(fromCardTarget(c.target));
	f.write(fromEffectType(c.effectType));
	f.write(fromResist(c.resist));
	f.writeL(cast(int) c.successRate);
	f.write(fromCardVisual(c.visual));
	f.writeL(cast(uint) c.motions.length);
	foreach (m; c.motions) { mixin(S_TRACE);
		writeMotion(d, f, m);
	}
	f.writeL(cast(int) c.enhance(Enhance.AVOID));
	f.writeL(cast(int) c.enhance(Enhance.RESIST));
	f.writeL(cast(int) c.enhance(Enhance.DEFENSE));
	writeString(f, c.soundPath1.length ? encodePathLegacy(c.soundPath1) : "（なし）");
	writeString(f, c.soundPath2.length ? encodePathLegacy(c.soundPath2) : "（なし）");
	for (uint i = 0u; i < 5u; i++) { mixin(S_TRACE);
		if (i < c.keyCodes.length) { mixin(S_TRACE);
			writeString(f, c.keyCodes[i]);
		} else { mixin(S_TRACE);
			writeString(f, "");
		}
	}
	f.write(fromPremium(c.premium));
	writeString(f, c.scenario);
	writeString(f, c.author);
	f.writeL(cast(uint) c.trees.length);
	foreach (tree; c.trees) { mixin(S_TRACE);
		writeCEventTree(d, f, tree);
	}
}
private void writeSkill(ref SData d, ref ByteIO f, SkillCard c) { mixin(S_TRACE);
	ulong id = c.id;
	ulong linkId = c.linkId;
	bool hold = c.hold;
	if (0 != c.linkId) { mixin(S_TRACE);
		d.cardRef[c.cwxPath(true)] = linkId;
		c = d.skill(c.linkId);
		if (!c) c = new SkillCard(id, "", "", "");
	}
	writeEffCard(d, f, c, 0x5, id);
	writeBool(f, hold);
	f.writeL(cast(uint) c.level);
	f.writeL(cast(uint) c.useLimit);
}
private void writeItem(ref SData d, ref ByteIO f, ItemCard c) { mixin(S_TRACE);
	ulong id = c.id;
	ulong linkId = c.linkId;
	bool hold = c.hold;
	if (0 != c.linkId) { mixin(S_TRACE);
		d.cardRef[c.cwxPath(true)] = linkId;
		c = d.item(c.linkId);
		if (!c) c = new ItemCard(id, "", "", "");
	}
	writeEffCard(d, f, c, 0x3, id);
	writeBool(f, hold);
	f.writeL(cast(uint) c.useLimit);
	f.writeL(cast(uint) c.useLimitMax);
	f.writeL(cast(uint) c.price);
	f.writeL(cast(int) c.enhanceOwner(Enhance.AVOID));
	f.writeL(cast(int) c.enhanceOwner(Enhance.RESIST));
	f.writeL(cast(int) c.enhanceOwner(Enhance.DEFENSE));
}
private void writeBeast(ref SData d, ref ByteIO f, BeastCard c) { mixin(S_TRACE);
	ulong id = c.id;
	ulong linkId = c.linkId;
	if (0 != c.linkId) { mixin(S_TRACE);
		d.cardRef[c.cwxPath(true)] = linkId;
		c = d.beast(c.linkId);
		if (!c) c = new BeastCard(id, "", "", "");
	}
	writeEffCard(d, f, c, 0x6, id);
	writeBool(f, false); // Hold
	f.writeL(cast(uint) c.useLimit);
}
private void writeInfo(ref SData d, ref ByteIO f, InfoCard c) { mixin(S_TRACE);
	f.writeL(cast(byte) 0x4);
	writeImage(d, f, c, c.path);
	writeString(f, c.name);
	f.writeL(cast(uint) (c.id + 40000u));
	writeString(f, c.desc);
}
