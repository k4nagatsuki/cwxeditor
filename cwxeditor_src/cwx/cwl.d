
module cwx.cwl;

import core.thread;

import core.stdc.string;

import std.array;
import std.conv;
import std.file;
import std.math;
import std.path;
import std.regex;
import std.stdio;
import std.string;
import std.utf;

import cwx.area;
import cwx.background;
import cwx.binary;
import cwx.card;
import cwx.coupon;
import cwx.event;
import cwx.filesync;
import cwx.flag;
import cwx.imagesize;
import cwx.motion;
import cwx.msgutils;
import cwx.path;
import cwx.props;
import cwx.sjis;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.utils;
import cwx.xml;

static import std.algorithm;
import std.algorithm : any, map, min;
import std.range : iota;
import std.typecons : Rebindable, Tuple, tuple;

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
	Rebindable!(const(CProps)) prop;
	bool cardOnly;
	string sPath;
	string skinType;
	string skinName;
	uint numberStepToVariantThreshold;
	int dataVersion;
	uint[string] numberSteps;
	bool[string] stepNames;
	this (const(CProps) prop, bool cardOnly, string sPath, string skinType, string skinName, uint numberStepToVariantThreshold) { mixin(S_TRACE);
		this.prop = prop;
		this.cardOnly = cardOnly;
		this.sPath = sPath;
		this.skinType = skinType;
		this.skinName = skinName;
		this.numberStepToVariantThreshold = numberStepToVariantThreshold;
		this.dataVersion = 0;
	}
	this (in RData d) { mixin(S_TRACE);
		this (d.prop, d.cardOnly, d.sPath, d.skinType, d.skinName, d.numberStepToVariantThreshold);
		foreach (key, value; d.numberSteps) numberSteps[key] = value;
		foreach (key, value; d.stepNames) stepNames[key] = value;
	}
}
/// 4.0形式のCardWirthシナリオを読込む。
/// Params:
/// newName = シナリオ名。null以外が指定された場合、
///           Summary.wsmが存在しない際はこの名前で新規に作成する。
Summary loadLScenario(string p, string skinType, string skinName, const CProps prop, in LoadOption opt, out string[] errorFiles, out int dataVersion, string newName = null) { mixin(S_TRACE);
	auto sPath = p;
	string summPath = std.path.buildPath(p, "Summary.wsm");
	Summary summ;
	RData d;
	ulong startAreaId;
	if (.exists(summPath)) { mixin(S_TRACE);
		d = RData(prop, opt.cardOnly, sPath, skinType, skinName, opt.numberStepToVariantThreshold);
		{ mixin(S_TRACE);
			ubyte* ptr = null;
			auto bytes = ByteIO(readBinaryFrom!ubyte(summPath, ptr));
			scope (exit) freeAll(ptr);
			summ = loadSummary(d, bytes, startAreaId);
		}
	} else { mixin(S_TRACE);
		if (!newName) throw new SummaryException("Not Scenario: " ~ p);
		d = RData(prop, opt.cardOnly, sPath, skinType, skinName, opt.numberStepToVariantThreshold);
		summ = new Summary(newName, d.skinType, d.skinName, d.sPath, false, true);
	}
	dataVersion = d.dataVersion;
	class Load {
		RData d;
		Area[] areas;
		Battle[] battles;
		Package[] packages;
		CastCard[] casts;
		SkillCard[] skills;
		ItemCard[] items;
		BeastCard[] beasts;
		InfoCard[] infos;
		string[] files;
		string[] errorFiles;
		ulong wait = 0L;
		this (in RData d) {
			this.d = RData(d);
		}
		void load() { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Classic Load Thread");
			}
			foreach (file; this.files) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					ubyte* ptr = null;
					auto bytes = readBinaryFrom!ubyte(file, ptr);
					scope (exit) freeAll(ptr);
					auto f = ByteIO(bytes);
					scope (exit) f.dispose();
					auto base = baseName(file);
					if (opt.processFunc) opt.processFunc(summ.scenarioName, base);
					ulong id;
					if (!d.cardOnly) { mixin(S_TRACE);
						if (sWith(base, "Area", id)) { mixin(S_TRACE);
							areas ~= .loadArea(d, f, id);
						}
						if (sWith(base, "Battle", id)) { mixin(S_TRACE);
							battles ~= .loadBattle(d, f, id);
						}
						if (sWith(base, "Package", id)) { mixin(S_TRACE);
							packages ~= .loadPackage(d, f, id);
						}
					}
					if (sWith(base, "Mate", id)) { mixin(S_TRACE);
						casts ~= .loadCast(d, f, id);
					}
					if (sWith(base, "Skill", id)) { mixin(S_TRACE);
						skills ~= .loadSkill(d, f, id);
					}
					if (sWith(base, "Item", id)) { mixin(S_TRACE);
						items ~= .loadItem(d, f, id);
					}
					if (sWith(base, "Beast", id)) { mixin(S_TRACE);
						beasts ~= .loadBeast(d, f, id);
					}
					if (sWith(base, "Info", id)) { mixin(S_TRACE);
						infos ~= .loadInfo(d, f, id);
					}
					debug {
						if (f.pointer != bytes.length) { mixin(S_TRACE);
							debugln("Rest bytes: %s(0x%08X < 0x%08X)".format(base, f.pointer, bytes.length));
						}
					}
				} catch (Throwable e) {
					printStackTrace();
					debugln(file ~ " - " ~ e.msg);
					errorFiles ~= file.baseName();
				}
			}
			version (Console) {
				debug std.stdio.writeln("Exit Classic Load Thread");
			}
		}
	}
	if (opt.summaryOnly) return summ;
	auto load1 = new Load(d);
	auto load2 = new Load(d);
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
	foreach (a; std.algorithm.sort(areas)) summ.add(a, false);
	foreach (a; std.algorithm.sort(battles)) summ.add(a, false);
	foreach (a; std.algorithm.sort(packages)) summ.add(a, false);
	foreach (a; std.algorithm.sort(casts)) summ.add(a, false);
	foreach (a; std.algorithm.sort(skills)) summ.add(a, false);
	foreach (a; std.algorithm.sort(items)) summ.add(a, false);
	foreach (a; std.algorithm.sort(beasts)) summ.add(a, false);
	foreach (a; std.algorithm.sort(infos)) summ.add(a, false);
	loadComment(summ);
	loadImageRef(summ);
	loadCardRef(summ);
	loadTemplate(summ);
	summ.startArea = startAreaId;
	summ.resetChanged();
	errorFiles ~= load1.errorFiles;
	errorFiles ~= load2.errorFiles;

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
			auto ct = cast(Content)summ.findCWXPath(path);
			if (!ct) return;
			// BUG: 2.10以前のバグで\rが混在する可能性があるため置換
			auto c = node.value.replace("\r\n", "\n").replace("\r", "");
			if (c != "") { mixin(S_TRACE);
				if (ct.comment.strip() != "") ct.comment = ct.comment ~ "\n";
				ct.comment = ct.comment ~ c;
			}
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
			auto card = cast(Card)cp;
			if (card) { mixin(S_TRACE);
				card.paths = node.value.length ? [new CardImage(decodePath(node.value), CardImagePosition.Default)] : [];
			}
			auto mCard = cast(MenuCard)cp;
			if (mCard) { mixin(S_TRACE);
				mCard.paths = node.value.length ? [new CardImage(decodePath(node.value), CardImagePosition.Default)] : [];
			}
			auto summ2 = cast(Summary)cp;
			if (summ2) { mixin(S_TRACE);
				summ2.imagePaths = node.value.length ? [new CardImage(decodePath(node.value), CardImagePosition.Default)] : [];
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
			auto m = cast(Motion)summ.findCWXPath(path);
			if (!m) return;
			string value = node.value;
			try { mixin(S_TRACE);
				m.maxNest = .to!uint(value);
			} catch (ConvException e) {
				printStackTrace();
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
				auto skill = cast(SkillCard)cp;
				if (skill) { mixin(S_TRACE);
					bool hold = skill.hold;
					skill.clearData();
					skill.linkId = id;
					skill.hold = hold;
				}
				auto item = cast(ItemCard)cp;
				if (item) { mixin(S_TRACE);
					bool hold = item.hold;
					item.clearData();
					item.linkId = id;
					item.hold = hold;
				}
				auto beast = cast(BeastCard)cp;
				if (beast) { mixin(S_TRACE);
					beast.clearData();
					beast.linkId = id;
				}
			} catch (ConvException e) {
				printStackTrace();
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
		return Target(Target.M.Selected, false);
	case 1: return Target(Target.M.Random, false);
	case 2: return Target(Target.M.Unselected, false);
	default: throw new SummaryException("Unknown target T: " ~ to!(string)(b));
	}
}
private Target toTargetA(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Target(Target.M.Selected, false);
	case 1: return Target(Target.M.Random, false);
	case 2: return Target(Target.M.Party, false);
	case 3: return Target(Target.M.Selected, true);
	case 4: return Target(Target.M.Random, true);
	case 5: return Target(Target.M.Party, true);
	case 6: return Target(Target.M.Party, false);
	default: throw new SummaryException("Unknown target A: " ~ to!(string)(b));
	}
}

private EffectType toEffectType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return EffectType.Physic;
	case 1: return EffectType.Magic;
	case 2: return EffectType.MagicalPhysic;
	case 3: return EffectType.PhysicalMagic;
	case 4: return EffectType.None;
	default: throw new SummaryException("Unknown effect type: " ~ to!(string)(b));
	}
}
private Resist toResist(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Resist.Avoid;
	case 1: return Resist.Resist;
	case 2: return Resist.Unfail;
	default: throw new SummaryException("Unknown resist: " ~ to!(string)(b));
	}
}
private CardVisual toCardVisual(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return CardVisual.None;
	case 1: return CardVisual.Reverse;
	case 2: return CardVisual.Horizontal;
	case 3: return CardVisual.Vertical;
	default: throw new SummaryException("Unknown card visual: " ~ to!(string)(b));
	}
}
private Range toRange(in RData d, byte b, Content e, int dataVersion) { mixin(S_TRACE);
	if (7 <= dataVersion) { mixin(S_TRACE);
		switch (b) {
		case 6: // 荷物袋のみ
			//e.comment = .tryFormat(d.prop.msgs.convertFromNextWarning, d.prop.msgs.convertFromNextWarningBackpackOnly);
			b = 3;
			break;
		case 7: // 選択メンバのバックパック
			e.comment = tryFormat(d.prop.msgs.convertFromNextWarning, d.prop.msgs.convertFromNextWarningBackpackOfSelectedMember);
			b = 0;
			break;
		default:
			break;
		}
	}
	switch (b) {
	case 0: return Range.Selected;
	case 1: return Range.Random;
	case 2: return Range.Party;
	case 3: return Range.Backpack;
	case 4: return Range.PartyAndBackpack;
	case 5: return Range.Field;
	default: throw new SummaryException("Unknown range: " ~ to!(string)(b));
	}
}
private Range toRangeE(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Range.Selected;
	case 1: return Range.Random;
	case 2: return Range.Party;
	case 3: return Range.Selected;
	case 4: return Range.Random;
	case 5: return Range.Party;
	case 6: return Range.Party;
	default: throw new SummaryException("Unknown range E: " ~ to!(string)(b));
	}
}
private Range toRangeEffectContent(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Range.Selected;
	case 1: return Range.Random;
	case 2: return Range.Party;
	case 3: return Range.CardTarget;
	default: throw new SummaryException("Unknown range EffectContent: " ~ to!(string)(b));
	}
}
/// CardWirth 1.50
private Range toKeyCodeRange(in RData d, byte b, Content e, int dataVersion) { mixin(S_TRACE);
	if (7 <= dataVersion) { mixin(S_TRACE);
		switch (b) {
		case 4: // 荷物袋のみ
			//e.comment = .tryFormat(d.prop.msgs.convertFromNextWarning, d.prop.msgs.convertFromNextWarningBackpackOnly);
			b = 2;
			break;
		case 5: // 選択メンバのバックパック
			e.comment = tryFormat(d.prop.msgs.convertFromNextWarning, d.prop.msgs.convertFromNextWarningBackpackOfSelectedMember);
			b = 0;
			break;
		default:
			break;
		}
	}
	switch (b) {
	case 0: return Range.Selected;
	case 1: return Range.Random;
	case 2: return Range.Backpack;
	case 3: return Range.PartyAndBackpack;
	default: throw new SummaryException("Unknown range: " ~ to!(string)(b));
	}
}
/// CardWirth Extender 1.30～
private Range toCouponRange(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Range.Selected;
	case 1: return Range.Random;
	case 2: return Range.Party;
	case 3: return Range.Field;
	default: throw new SummaryException("Unknown range: " ~ to!(string)(b));
	}
}
/// CardWirth Extender 1.30～
private CastRange[] toCastRanges(byte b) { mixin(S_TRACE);
	CastRange[] r;
	if (b & 0b0001) r ~= CastRange.Party;
	if (b & 0b0010) r ~= CastRange.Enemy;
	if (b & 0b0100) r ~= CastRange.Npc;
	return r;
}
/// CardWirth 1.50
private EffectCardType toEffectCardType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return EffectCardType.All;
	case 1: return EffectCardType.Skill;
	case 2: return EffectCardType.Item;
	case 3: return EffectCardType.Beast;
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
/// Wsn.1
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
	case 0: return Status.Active;
	case 1: return Status.Inactive;
	case 2: return Status.Alive;
	case 3: return Status.Dead;
	case 4: return Status.Fine;
	case 5: return Status.Injured;
	case 6: return Status.HeavyInjured;
	case 7: return Status.Unconscious;
	case 8: return Status.Poison;
	case 9: return Status.Sleep;
	case 10: return Status.Bind;
	case 11: return Status.Paralyze;
	case 12: return Status.Confuse;
	case 13: return Status.Overheat;
	case 14: return Status.Brave;
	case 15: return Status.Panic;
	case 16: return Status.Silence;
	case 17: return Status.FaceUp;
	case 18: return Status.AntiMagic;
	case 19: return Status.UpAction;
	case 20: return Status.UpAvoid;
	case 21: return Status.UpResist;
	case 22: return Status.UpDefense;
	case 23: return Status.DownAction;
	case 24: return Status.DownAvoid;
	case 25: return Status.DownResist;
	case 26: return Status.DownDefense;
	default: throw new SummaryException("Unknown status: " ~ to!(string)(b));
	}
}
private Element toElement(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Element.All;
	case 1: return Element.Health;
	case 2: return Element.Mind;
	case 3: return Element.Miracle;
	case 4: return Element.Magic;
	case 5: return Element.Fire;
	case 6: return Element.Ice;
	default: throw new SummaryException("Unknown element: " ~ to!(string)(b));
	}
}
private DamageType toDamageType(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return DamageType.LevelRatio;
	case 1: return DamageType.Normal;
	case 2: return DamageType.Max;
	default: throw new SummaryException("Unknown damage type: " ~ to!(string)(b));
	}
}
private Physical toPhysical(uint b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Physical.Dex;
	case 1: return Physical.Agl;
	case 2: return Physical.Int;
	case 3: return Physical.Str;
	case 4: return Physical.Vit;
	case 5: return Physical.Min;
	default: throw new SummaryException("Unknown pysical: " ~ to!(string)(b));
	}
}
private Mental toMental(int b) { mixin(S_TRACE);
	switch (b) {
	case 1: return Mental.Aggressive;
	case 2: return Mental.Cheerful;
	case 3: return Mental.Brave;
	case 4: return Mental.Cautious;
	case 5: return Mental.Trickish;
	case -1: return Mental.Unaggressive;
	case -2: return Mental.Uncheerful;
	case -3: return Mental.Unbrave;
	case -4: return Mental.Uncautious;
	case -5: return Mental.Untrickish;
	default: throw new SummaryException("Unknown mental: " ~ to!(string)(b));
	}
}
private Mentality toMentality(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Mentality.Normal;
	case 1: return Mentality.Sleep;
	case 2: return Mentality.Confuse;
	case 3: return Mentality.Overheat;
	case 4: return Mentality.Brave;
	case 5: return Mentality.Panic;
	default: throw new SummaryException("Unknown mentality: " ~ to!(string)(b));
	}
}
private CardTarget toCardTarget(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return CardTarget.None;
	case 1: return CardTarget.User;
	case 2: return CardTarget.Party;
	case 3: return CardTarget.Enemy;
	case 4: return CardTarget.Both;
	default: throw new SummaryException("Unknown card target: " ~ to!(string)(b));
	}
}
private Premium toPremium(byte b) { mixin(S_TRACE);
	switch (b) {
	case 0: return Premium.Normal;
	case 1: return Premium.Rare;
	case 2: return Premium.Premium;
	default: throw new SummaryException("Unknown card premium: " ~ to!(string)(b));
	}
}
private bool readBool(ref ByteIO f) { mixin(S_TRACE);
	return f.readByte ? true : false;
}
private string readExImage(in RData d, ref ByteIO f) { mixin(S_TRACE);
	return readImageImpl(d, f, () => f.readExUInt());
}
private string readImage(in RData d, ref ByteIO f) { mixin(S_TRACE);
	return readImageImpl(d, f, &f.readUIntL);
}
private string readImageImpl(in RData d, ref ByteIO f, uint delegate() readSize) { mixin(S_TRACE);
	uint len = readSize();
	if (!len) return "";
	auto img = f.read(len);
	if (endsWith(img, cast(ubyte[])B_IMG_REF)) { mixin(S_TRACE);
		size_t index = size_t.max;
		foreach_reverse (i, c; img[0 .. $ - B_IMG_REF.length]) { mixin(S_TRACE);
			if (c == '\0') { mixin(S_TRACE);
				index = i + 1;
				break;
			}
		}
		if (index != size_t.max) { mixin(S_TRACE);
			auto s = cast(string)img[index .. $ - B_IMG_REF.length];
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
	return readStringImpl(f, lns, cutText, () => f.readExUInt());
}
private string readString(ref ByteIO f, bool lns = false, bool cutText = false) { mixin(S_TRACE);
	return readStringImpl(f, lns, cutText, &f.readUIntL);
}
private string readStringImpl(ref ByteIO f, bool lns, bool cutText, uint delegate() readSize) { mixin(S_TRACE);
	uint len = readSize();
	if (!len) return "";
	string str = cast(string)f.read(len);
	if (!lns && str[$ - 1] == '\0') str = str[0 .. $ - 1];
	auto zi = indexOf(str, '\0');
	if (-1 != zi) str = str[zi + 1 .. $];
	try { mixin(S_TRACE);
		str = touni(str);
	} catch (Exception e) {
		printStackTrace();
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
	uint len = f.readUIntL();
	if (!len) return "";
	string str = cast(string)f.read(len);
	if (!lns && str[$ - 1] == '\0') str = str[0 .. $ - 1];
	while (true) { mixin(S_TRACE);
		auto zi = indexOf(str, '\0');
		if (-1 == zi) break;
		string info = touni(str[zi + 1 .. $], false);
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
	str = touni(str, false);
	if (cutText) { mixin(S_TRACE);
		str = str.length > "TEXT\r\n".length ? str["TEXT\r\n".length .. $] : "";
	}
	str = replace(str, "\r\n", "\n");
	return str;
}
private string[] readExStrings(ref ByteIO f) { mixin(S_TRACE);
	auto str = readExString(f, true);
	return str.length ? splitLines(str) : cast(string[]) [];
}
private string[] readStrings(ref ByteIO f) { mixin(S_TRACE);
	auto str = readString(f, true);
	return str.length ? splitLines(str) : cast(string[]) [];
}

private string readSound(in RData d, ref ByteIO f) { mixin(S_TRACE);
	auto type = f.readByte;
	switch (type) {
	case 0: // 無し
		return "";
	case 1: // パス指定
		return readExString(f);
	case 2: // 埋め込み
		auto len = f.readExUInt();
		if (!len) return "";
		auto snd = f.read(len);
		return bSndToStr(snd);
	default:
		throw new Exception("Unknown sound type: %s".format(type));
	}
}

private Summary loadSummary(ref RData d, ref ByteIO f, out ulong startAreaId) { mixin(S_TRACE);
	string img = readImage(d, f);
	auto name = readString(f);
	auto imagePaths = img.length ? [new CardImage(img, CardImagePosition.Default)] : [];
	auto desc = readString(f, true);
	auto author = readString(f);
	auto rCoupons = readStrings(f);
	auto rCouponNum = f.readUIntL;
	auto area = f.readUIntL;
	if (area < 19999) { mixin(S_TRACE);
		d.dataVersion = 0;
	} else if (area < 39999) { mixin(S_TRACE);
		d.dataVersion = 2;
		startAreaId = area - 20000u;
	} else if (area < 69999) { mixin(S_TRACE);
		d.dataVersion = 4;
		startAreaId = area - 40000u;
	} else { mixin(S_TRACE);
		d.dataVersion = 7;
		startAreaId = area - 70000u;
	}
	auto summ = new Summary(name, d.skinType, d.skinName, d.sPath, false, true);
	summ.imagePaths = imagePaths;
	summ.desc = desc;
	summ.author = author;
	if (d.cardOnly) return summ;
	summ.rCoupons = rCoupons;
	summ.rCouponNum = rCouponNum;

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
	if (d.dataVersion < 7) { mixin(S_TRACE);
		uint stepNum = f.readUIntL;
		for (uint i = 0u; i < stepNum; i++) { mixin(S_TRACE);
			string path = readString(f);
			uint sel = f.readUIntL;
			string[] vals;
			vals.length = 10u;
			for (uint j = 0u; j < 10u; j++) { mixin(S_TRACE);
				vals[j] = readString(f);
			}
			if (vals.length <= sel) sel = cast(uint)vals.length - 1;
			if (!flagsParent(path).add(new Step(FlagDir.basename(path), vals, sel))) { mixin(S_TRACE);
				throw new SummaryException("Invalid step path: " ~ path);
			}
		}
		uint flagNum = f.readUIntL;
		for (uint i = 0u; i < flagNum; i++) { mixin(S_TRACE);
			string path = readString(f);
			bool sel = readBool(f);
			string on = readString(f);
			string off = readString(f);
			if (!flagsParent(path).add(new cwx.flag.Flag(FlagDir.basename(path), on, off, sel))) { mixin(S_TRACE);
				throw new SummaryException("Invalid flag path: " ~ path);
			}
		}
		f.readUIntL;
		if (d.dataVersion != 0) { mixin(S_TRACE);
			summ.levelMin = f.readUIntL;
			summ.levelMax = f.readUIntL;
		}
	} else { mixin(S_TRACE);
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		f.readByte; // 不明(0)
		auto stepNum = f.readExUInt;
		for (uint i = 0u; i < stepNum; i++) { mixin(S_TRACE);
			auto path = readExString(f);
			auto type = f.readUByte;
			auto expandVars = (type & 0b10000000) != 0;
			type &= 0b01111111;
			if (expandVars) { mixin(S_TRACE);
				f.readUByte; // 不明(0x02)
			}
			auto valNum = f.readExUInt;
			switch (type) {
			case 1:
				auto vals = new string[valNum];
				for (uint j = 0u; j < valNum; j++) { mixin(S_TRACE);
					vals[j] = readExString(f);
				}
				auto sel = f.readExUInt;
				if (vals.length <= sel) sel = cast(uint)vals.length - 1;
				auto s = new Step(FlagDir.basename(path), vals, sel);
				s.expandSPChars = expandVars;
				if (!flagsParent(path).add(s)) { mixin(S_TRACE);
					throw new SummaryException("Invalid step path: " ~ path);
				}
				break;
			case 2:
				// 値の数の多い数値ステップはコモンに置換する
				auto sel = f.readExUInt;
				if (valNum <= d.numberStepToVariantThreshold) { mixin(S_TRACE);
					auto vals = .iota(0, valNum).map!text().array();
					if (vals.length <= sel) sel = cast(uint)vals.length - 1;
					auto s = new Step(FlagDir.basename(path), vals, sel);
					if (!flagsParent(path).add(s)) { mixin(S_TRACE);
						throw new SummaryException("Invalid step path: " ~ path);
					}
				} else { mixin(S_TRACE);
					auto v = new Variant(FlagDir.basename(path), cast(double)sel);
					if (!flagsParent(path).add(v)) { mixin(S_TRACE);
						throw new SummaryException("Invalid variant path: " ~ path);
					}
					d.numberSteps[path] = valNum;
				}
				break;
			default:
				throw new Exception("Invalid step type: %s".format(type));
			}
			d.stepNames[path] = true;
		}
		foreach (step; summ.flagDirRoot.allSteps) { mixin(S_TRACE);
			if (!step.expandSPChars) continue;
			foreach (i; 0 .. step.count) { mixin(S_TRACE);
				auto value = step.getValue(i);
				foreach (path; d.numberSteps.byKey()) { mixin(S_TRACE);
					value = .replStepToVariantInText(value, path, path);
				}
				step.setValue(i, value);
			}
		}
		auto flagNum = f.readExUInt;
		for (uint i = 0u; i < flagNum; i++) { mixin(S_TRACE);
			auto path = readExString(f);
			auto sel = readBool(f);
			auto on = readExString(f);
			auto off = readExString(f);
			if (!flagsParent(path).add(new cwx.flag.Flag(FlagDir.basename(path), on, off, sel))) { mixin(S_TRACE);
				throw new SummaryException("Invalid flag path: " ~ path);
			}
		}
		summ.levelMin = f.readExUInt;
		summ.levelMax = f.readExUInt;
	}
	debug {
		if (f.pointer != f.length) { mixin(S_TRACE);
			debugln("Rest bytes: %s(0x%08X < 0x%08X)".format("Summary.wsm", f.pointer, f.length));
		}
	}
	return summ;
}
private Motion readMotion(ref RData d, int dataVersion, ref ByteIO f, size_t index) { mixin(S_TRACE);
	byte tType = f.readByte;
	if (2 < dataVersion) { mixin(S_TRACE);
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
			case 0: m = new Motion(MType.Heal, el); break;
			case 1: m = new Motion(MType.Damage, el); break;
			case 2: m = new Motion(MType.Absorb, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		} else { mixin(S_TRACE);
			switch (type) {
			case 0: m = new Motion(MType.Paralyze, el); break;
			case 1: m = new Motion(MType.DisParalyze, el); break;
			case 2: m = new Motion(MType.Poison, el); break;
			case 3: m = new Motion(MType.DisPoison, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		}
		m.damageType = dmgTyp;
		m.uValue = val;
		return m;
	}
	case 2: { mixin(S_TRACE);
		switch (type) {
		case 0: return new Motion(MType.GetSkillPower, el);
		case 1: return new Motion(MType.LoseSkillPower, el);
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 3, 4: { mixin(S_TRACE);
		uint rnd;
		if (2 < dataVersion) { mixin(S_TRACE);
			rnd = f.readUIntL;
		} else { mixin(S_TRACE);
			rnd = 10;
		}
		Motion m;
		if (tType == 3u) { mixin(S_TRACE);
			switch (type) {
			case 0: m = new Motion(MType.Sleep, el); break;
			case 1: m = new Motion(MType.Confuse, el); break;
			case 2: m = new Motion(MType.Overheat, el); break;
			case 3: m = new Motion(MType.Brave, el); break;
			case 4: m = new Motion(MType.Panic, el); break;
			case 5: m = new Motion(MType.Normal, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		} else { mixin(S_TRACE);
			switch (type) {
			case 0: m = new Motion(MType.Bind, el); break;
			case 1: m = new Motion(MType.DisBind, el); break;
			case 2: m = new Motion(MType.Silence, el); break;
			case 3: m = new Motion(MType.DisSilence, el); break;
			case 4: m = new Motion(MType.FaceUp, el); break;
			case 5: m = new Motion(MType.FaceDown, el); break;
			case 6: m = new Motion(MType.AntiMagic, el); break;
			case 7: m = new Motion(MType.DisAntiMagic, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		}
		if (m.detail.use(MArg.Round)) m.round = rnd;
		return m;
	}
	case 5: { mixin(S_TRACE);
		uint val = f.readUIntL;
		uint rnd;
		if (2 < dataVersion) { mixin(S_TRACE);
			rnd = f.readUIntL;
		} else { mixin(S_TRACE);
			rnd = 10;
		}
		Motion m;
		switch (type) {
		case 0: m = new Motion(MType.EnhanceAction, el); break;
		case 1: m = new Motion(MType.EnhanceAvoid, el); break;
		case 2: m = new Motion(MType.EnhanceResist, el); break;
		case 3: m = new Motion(MType.EnhanceDefense, el); break;
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
		m.round = rnd;
		m.aValue = val;
		return m;
	}
	case 6: { mixin(S_TRACE);
		switch (type) {
		case 0: return new Motion(MType.VanishTarget, el);
		case 1: return new Motion(MType.VanishCard, el);
		case 2: return new Motion(MType.VanishBeast, el);
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 7: { mixin(S_TRACE);
		switch (type) {
		case 0: return new Motion(MType.DealAttackCard, el);
		case 1: return new Motion(MType.DealPowerfulAttackCard, el);
		case 2: return new Motion(MType.DealCriticalAttackCard, el);
		case 3: return new Motion(MType.DealFeintCard, el);
		case 4: return new Motion(MType.DealDefenseCard, el);
		case 5: return new Motion(MType.DealDistanceCard, el);
		case 6: return new Motion(MType.DealConfuseCard, el);
		case 7: return new Motion(MType.DealSkillCard, el);
		case 8: return new Motion(MType.CancelAction, el); // CardWirth 1.50
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
		auto m = new Motion(MType.SummonBeast, el);
		m.newBeast = beast;
		return m;
	}
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private Content readContent(ref RData d, ref ByteIO f, size_t index) { mixin(S_TRACE);
	static string checkStepExpression(in RData d, string step, uint stepValue, Comparison4 comparison4) { mixin(S_TRACE);
		string v;
		if (step in d.numberSteps) { mixin(S_TRACE);
			v = "@\"%s\"".format(step.replace("\"", "\"\""));
		} else { mixin(S_TRACE);
			v = "STEPVALUE(\"%s\")".format(step.replace("\"", "\"\""));
		}
		string cmp4;
		final switch (comparison4) {
		case Comparison4.Eq: cmp4 = "="; break;
		case Comparison4.Ne: cmp4 = "<>"; break;
		case Comparison4.Lt: cmp4 = ">"; break;
		case Comparison4.Gt: cmp4 = "<"; break;
		}
		return "%s %s %s".format(v, cmp4, stepValue);
	}
	static string checkFlagExpression(string flag) { mixin(S_TRACE);
		return "FLAGVALUE(\"%s\")".format(flag.replace("\"", "\"\""));
	}
	static Content readImpl(ref RData d, ref ByteIO f, int dataVersion, byte type, string name,
			ref string[string] info, ref string[string] branchMultiStep, ref Tuple!(string, string)[string] branchStepCmp) { mixin(S_TRACE);
		//cdebugln("Read Content --------------------------------------------------");
		//cdebugln(type);
		//cdebugln("0x%04X".format(f.pointer));
		Content e;
		switch (type) {
		case 0:
			e = new Content(CType.Start, name);
			break;
		case 1:
			e = new Content(CType.LinkStart, name);
			e.start = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 2:
			e = new Content(CType.StartBattle, name);
			e.battle = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 3:
			e = new Content(CType.End, name);
			e.complete = readBool(f);
			break;
		case 4:
			e = new Content(CType.EndBadEnd, name);
			break;
		case 5:
			e = new Content(CType.ChangeArea, name);
			e.area = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			e.transition = Transition.Default;
			e.transitionSpeed = 5u;
			break;
		case 6: { mixin(S_TRACE);
			auto msgPath = "";
			ubyte tb;
			if (dataVersion < 7) { mixin(S_TRACE);
				msgPath = readString(f);
			} else { mixin(S_TRACE);
				tb = f.readUByte;
				if ((tb & 0b00000001) != 0) msgPath = readExString(f);
			}
			Talker msgTalker;
			bool hasTalker = true;
			switch (msgPath) {
			case "": hasTalker = false; break;
			case "??Selected": msgTalker = Talker.Selected; break;
			case "??Unselected": msgTalker = Talker.Unselected; break;
			case "??Random": msgTalker = Talker.Random; break;
			case "??Card": msgTalker = Talker.Card; break;
			default: hasTalker = false; break;
			}
			e = new Content(CType.TalkMessage, name);
			auto s = dataVersion < 7 ? readString(f) : readExString(f);
			foreach (path; d.numberSteps.byKey()) { mixin(S_TRACE);
				s = .replStepToVariantInText(s, path, path);
			}
			e.text = s;
			if (hasTalker) { mixin(S_TRACE);
				e.cardPaths = [new CardImage(msgTalker)];
			} else if (msgPath.length) { mixin(S_TRACE);
				e.cardPaths = [new CardImage(decodePathLegacy(msgPath), CardImagePosition.Default)];
			} else { mixin(S_TRACE);
				e.cardPaths = [];
			}
			if (7 <= dataVersion && (tb & 0b10000000) != 0) { mixin(S_TRACE);
				e.selectionColumns = f.readExUInt;
			}
			break;
		}
		case 7:
			e = new Content(CType.PlayBgm, name);
			e.bgmPath = decodePathLegacy(dataVersion < 7 ? readString(f) : readExString(f));
			break;
		case 8: { mixin(S_TRACE);
			BgImage[] bgImgs = readBgImages(d, f, dataVersion, false);
			e = new Content(CType.ChangeBgImage, name);
			e.backs = bgImgs;
			e.transition = Transition.Default;
			e.transitionSpeed = 5u;
			break;
		}
		case 9:
			e = new Content(CType.PlaySound, name);
			e.soundPath = decodePathLegacy(dataVersion < 7 ? readString(f) : readExString(f));
			break;
		case 10:
			e = new Content(CType.Wait, name);
			if (dataVersion < 7) { mixin(S_TRACE);
				e.wait = f.readUIntL;
			} else { mixin(S_TRACE);
				auto i = f.readExInt;
				e.wait = i < 0 ? .roundTo!uint(-i / 100.0) : i;
				if (i < 0 && e.wait * 100 != -i) e.comment = .tryFormat(d.prop.msgs.convertFromNextWarning, .tryFormat(d.prop.msgs.convertFromNextWarningWaitMillis, -i));
			}
			break;
		case 11: { mixin(S_TRACE);
			e = new Content(CType.Effect, name);
			uint effMotionNum;
			if (dataVersion < 7) { mixin(S_TRACE);
				e.signedLevel = f.readIntL;
				byte effTarget = f.readByte;
				e.range = toRangeEffectContent(effTarget);
				e.effectType = toEffectType(f.readByte);
				e.resist = toResist(f.readByte);
				e.successRate = f.readIntL;
				string sp = readString(f);
				e.soundPath = (sp == "（なし）" || sp == "（なし）.wav") ? "" : decodePathLegacy(sp);
				e.cardVisual = toCardVisual(f.readByte);
				effMotionNum = f.readUIntL;
			} else { mixin(S_TRACE);
				e.signedLevel = f.readExInt;
				auto effTarget = f.readByte;
				e.range = toRangeEffectContent(effTarget);
				e.effectType = toEffectType(f.readByte);
				e.resist = toResist(f.readByte);
				e.successRate = f.readExInt;
				auto sp = readSound(d, f);
				e.soundPath = (sp == "（なし）" || sp == "（なし）.wav") ? "" : decodePathLegacy(sp);
				e.cardVisual = toCardVisual(f.readByte);
				effMotionNum = f.readExUInt;
			}
			Motion[] effMotions;
			effMotions.length = effMotionNum;
			auto hasDamage = false;
			for (uint i = 0u; i < effMotionNum; i++) { mixin(S_TRACE);
				effMotions[i] = readMotion(d, dataVersion, f, i);
				switch (effMotions[i].type) {
				case MType.Damage:
				case MType.Absorb:
				case MType.Paralyze:
				case MType.VanishTarget:
					hasDamage = true;
					break;
				default:
					break;
				}
			}
			e.motions = effMotions;
			if (7 <= dataVersion && hasDamage) { mixin(S_TRACE);
				e.ignite = true; // 死亡イベントが発火する
			}
			break;
		}
		case 12: { mixin(S_TRACE);
			bool brMemAll = readBool(f);
			bool brMemRnd = readBool(f);
			e = new Content(CType.BranchSelect, name);
			e.targetAll = brMemAll;
			e.selectionMethod = brMemRnd ? SelectionMethod.Random : SelectionMethod.Manual;
			break;
		}
		case 13: { mixin(S_TRACE);
			e = new Content(CType.BranchAbility, name);
			if (dataVersion < 7) { mixin(S_TRACE);
				e.signedLevel = f.readUIntL;
				e.targetS = toTargetA(f.readByte);
				e.physical = toPhysical(f.readUIntL);
				e.mental = toMental(f.readIntL);
			} else { mixin(S_TRACE);
				e.signedLevel = f.readExInt;
				e.targetS = toTargetA(f.readByte);
				e.physical = toPhysical(f.readExInt);
				e.mental = toMental(f.readExInt);
			}
			break;
		}
		case 14:
			e = new Content(CType.BranchRandom, name);
			e.percent = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 15:
			e = new Content(CType.BranchFlag, name);
			e.flag = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 16: { mixin(S_TRACE);
			string flag = dataVersion < 7 ? readString(f) : readExString(f);
			bool val = readBool(f);
			e = new Content(CType.SetFlag, name);
			e.flag = flag;
			e.flagValue = val;
			break;
		}
		case 17:
			auto step = dataVersion < 7 ? readString(f) : readExString(f);
			auto p = step in d.numberSteps;
			if (p) { mixin(S_TRACE);
				e = new Content(CType.TalkMessage, name);
				e.comment = "%s: %s".format(d.prop.msgs.contentName(CType.BranchMultiStep), step);
				branchMultiStep[e.eventId] = step;
			} else { mixin(S_TRACE);
				e = new Content(CType.BranchMultiStep, name);
				e.step = step;
			}
			break;
		case 18: { mixin(S_TRACE);
			auto step = dataVersion < 7 ? readString(f) : readExString(f);
			uint val = dataVersion < 7 ? f.readUIntL : f.readExInt;
			auto p = step in d.numberSteps;
			if (p) { mixin(S_TRACE);
				e = new Content(CType.SetVariant, name);
				e.variant = step;
				e.expression = .text(val);
			} else { mixin(S_TRACE);
				e = new Content(CType.SetStep, name);
				e.step = step;
				e.stepValue = val;
			}
			break;
		}
		case 19:
			e = new Content(CType.BranchCast, name);
			e.casts = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 20: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.BranchItem, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.BranchItem, name);
			e.item = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 21: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.BranchSkill, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.BranchSkill, name);
			e.skill = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 22:
			e = new Content(CType.BranchInfo, name);
			e.info = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 23: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.BranchBeast, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.BranchBeast, name);
			e.beast = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 24:
			e = new Content(CType.BranchMoney, name);
			e.money = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 25: { mixin(S_TRACE);
			auto coupon = dataVersion < 7 ? readString(f) : readExString(f);
			auto val = dataVersion < 7 ? readIntL(f) : readExInt(f);
			auto rng = f.readByte;
			auto invertResult = dataVersion < 7 ? false : f.readBool;
			e = new Content(CType.BranchCoupon, name);
			e.couponNames = [coupon];
			e.range = toCouponRange(rng);
			e.invertResult = invertResult;
			break;
		}
		case 26:
			e = new Content(CType.GetCast, name);
			e.casts = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 27: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.GetItem, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.GetItem, name);
			e.item = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 28: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.GetSkill, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.GetSkill, name);
			e.skill = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 29:
			e = new Content(CType.GetInfo, name);
			e.info = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 30: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.GetBeast, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.GetBeast, name);
			e.beast = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 31:
			e = new Content(CType.GetMoney, name);
			e.money = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 32: { mixin(S_TRACE);
			auto coupon = dataVersion < 7 ? readString(f) : readExString(f);
			auto val = dataVersion < 7 ? readIntL(f) : readExInt(f);
			auto rng = f.readByte;
			if (7 <= dataVersion) f.readByte; // 不所持条件
			e = new Content(CType.GetCoupon, name);
			e.coupon = coupon;
			e.range = toRange(d, rng, e, dataVersion);
			e.couponValue = val;
			break;
		}
		case 33:
			e = new Content(CType.LoseCast, name);
			e.casts = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 34: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.LoseItem, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.LoseItem, name);
			e.item = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 35: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.LoseSkill, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.LoseSkill, name);
			e.skill = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 36:
			e = new Content(CType.LoseInfo, name);
			e.info = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 37: { mixin(S_TRACE);
			ulong id = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			if (dataVersion <= 2) { mixin(S_TRACE);
				e = new Content(CType.LoseBeast, name);
				e.item = id;
				e.range = Range.PartyAndBackpack;
				e.cardNumber = 1;
				break;
			}
			uint num = dataVersion < 7 ? readUIntL(f) : readExUInt(f);
			byte rng = f.readByte;
			e = new Content(CType.LoseBeast, name);
			e.beast = id;
			e.range = toRange(d, rng, e, dataVersion);
			e.cardNumber = num;
			break;
		}
		case 38:
			e = new Content(CType.LoseMoney, name);
			e.money = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 39: { mixin(S_TRACE);
			auto coupon = dataVersion < 7 ? readString(f) : readExString(f);
			auto val = dataVersion < 7 ? readIntL(f) : readExInt(f);
			auto rng = f.readByte;
			if (7 <= dataVersion) f.readByte; // 不所持条件
			e = new Content(CType.LoseCoupon, name);
			e.coupon = coupon;
			e.range = toRange(d, rng, e, dataVersion);
			break;
		}
		case 40: { mixin(S_TRACE);
			byte targ = f.readByte;
			Talker t;
			Coupon[] coupons = [];
			int initValue = 0;
			if (3 == targ) { mixin(S_TRACE);
				t = Talker.Valued;
				if (dataVersion < 7) { mixin(S_TRACE);
					auto cpNum = readUIntL(f);
					foreach (i; 0 .. cpNum) { mixin(S_TRACE);
						coupons ~= new Coupon(readString(f), f.readIntL);
					}
				} else { mixin(S_TRACE);
					auto cpNum = readExUInt(f);
					foreach (i; 0 .. cpNum) { mixin(S_TRACE);
						coupons ~= new Coupon(readExString(f), f.readExInt);
					}
				}
				if (coupons.length && coupons[0].name == "") { mixin(S_TRACE);
					initValue = coupons[0].value;
					coupons = coupons[1 .. $];
				}
			} else { mixin(S_TRACE);
				switch (toTargetT(targ).m) {
				case Target.M.Selected: t = Talker.Selected; break;
				case Target.M.Unselected: t = Talker.Unselected; break;
				case Target.M.Random: t = Talker.Random; break;
				default: throw new SummaryException("Unknown talker: " ~ to!(string)(targ));
				}
			}
			SDialog[] dlgs;
			if (dataVersion < 7) { mixin(S_TRACE);
				uint dlgNum = f.readUIntL;
				for (uint i = 0u; i < dlgNum; i++) { mixin(S_TRACE);
					string[] cps = readStrings(f);
					string text = readString(f, true);
					dlgs ~= new SDialog(text, cps);
				}
			} else { mixin(S_TRACE);
				uint dlgNum = f.readExUInt;
				for (uint i = 0u; i < dlgNum; i++) { mixin(S_TRACE);
					string[] cps = readExStrings(f);
					string text = readExString(f, true);
					foreach (path; d.numberSteps.byKey()) { mixin(S_TRACE);
						text = .replStepToVariantInText(text, path, path);
					}
					dlgs ~= new SDialog(text, cps);
				}
			}
			e = new Content(CType.TalkDialog, name);
			e.talkerNC = t;
			e.dialogs = dlgs;
			e.coupons = coupons;
			e.initValue = initValue;
			if (7 <= dataVersion) { mixin(S_TRACE);
				auto ob = f.readUByte;
				e.selectTalker = (ob & 0b00000001) != 0;
				if (ob & 0b00000010) e.selectionColumns = f.readUByte;
			}
			break;
		}
		case 41:
			auto step = dataVersion < 7 ? readString(f) : readExString(f);
			auto p = step in d.numberSteps;
			if (p) { mixin(S_TRACE);
				e = new Content(CType.SetVariant, name);
				e.variant = step;
				e.expression = "MIN(@\"%s\" + 1, %s)".format(step.replace("\"", "\"\""), *p - 1);
			} else { mixin(S_TRACE);
				e = new Content(CType.SetStepUp, name);
				e.step = step;
			}
			break;
		case 42:
			auto step = dataVersion < 7 ? readString(f) : readExString(f);
			auto p = step in d.numberSteps;
			if (p) { mixin(S_TRACE);
				e = new Content(CType.SetVariant, name);
				e.variant = step;
				e.expression = "MAX(@\"%s\" - 1, 0)".format(step.replace("\"", "\"\""));
			} else { mixin(S_TRACE);
				e = new Content(CType.SetStepDown, name);
				e.step = step;
			}
			break;
		case 43:
			e = new Content(CType.ReverseFlag, name);
			e.flag = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 44: { mixin(S_TRACE);
			auto step = dataVersion < 7 ? readString(f) : readExString(f);
			uint val = dataVersion < 7 ? f.readUIntL : f.readExInt;
			auto p = step in d.numberSteps;
			if (p) { mixin(S_TRACE);
				e = new Content(CType.BranchVariant, name);
				e.expression = "%s <= @\"%s\"".format(val, step.replace("\"", "\"\""));
			} else { mixin(S_TRACE);
				e = new Content(CType.BranchStep, name);
				e.step = step;
				e.stepValue = val;
			}
			break;
		}
		case 45:
			e = new Content(CType.ElapseTime, name);
			break;
		case 46: { mixin(S_TRACE);
			bool avg = readBool(f);
			uint val = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			e = new Content(CType.BranchLevel, name);
			e.average = avg;
			e.unsignedLevel = val;
			break;
		}
		case 47: { mixin(S_TRACE);
			byte stat = f.readByte;
			byte targ = f.readByte;
			e = new Content(CType.BranchStatus, name);
			e.range = toRangeE(targ);
			e.status = toStatus(stat);
			break;
		}
		case 48:
			e = new Content(CType.BranchPartyNumber, name);
			e.partyNumber = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 49:
			e = new Content(CType.ShowParty, name);
			break;
		case 50:
			e = new Content(CType.HideParty, name);
			break;
		case 51:
			e = new Content(CType.EffectBreak, name);
			break;
		case 52:
			e = new Content(CType.CallStart, name);
			e.start = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 53:
			e = new Content(CType.LinkPackage, name);
			e.packages = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 54:
			e = new Content(CType.CallPackage, name);
			e.packages = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 55:
			e = new Content(CType.BranchArea, name);
			break;
		case 56:
			e = new Content(CType.BranchBattle, name);
			break;
		case 57:
			e = new Content(CType.BranchCompleteStamp, name);
			e.completeStamp = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 58:
			e = new Content(CType.GetCompleteStamp, name);
			e.completeStamp = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 59:
			e = new Content(CType.LoseCompleteStamp, name);
			e.completeStamp = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 60:
			e = new Content(CType.BranchGossip, name);
			e.gossip = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 61:
			e = new Content(CType.GetGossip, name);
			e.gossip = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 62:
			e = new Content(CType.LoseGossip, name);
			e.gossip = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 63:
			e = new Content(CType.BranchIsBattle, name);
			break;
		case 64:
			e = new Content(CType.Redisplay, name);
			e.transition = Transition.Default;
			e.transitionSpeed = 5u;
			break;
		case 65:
			e = new Content(CType.CheckFlag, name);
			e.flag = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 66:
			auto step1 = dataVersion < 7 ? readString(f) : readExString(f);
			auto step2 = dataVersion < 7 ? readString(f) : readExString(f);
			auto p1 = step1 in d.numberSteps;
			auto p2 = step2 in d.numberSteps;
			if (p1 || p2) { mixin(S_TRACE);
				e = new Content(CType.SetVariant, name);
				if (p2) { mixin(S_TRACE);
					e.variant = step2;
				} else { mixin(S_TRACE);
					e.step = step2;
				}
				if (p1) { mixin(S_TRACE);
					e.expression = "@\"%s\"".format(step1.replace("\"", "\"\""));
				} else if (.icmp(step1, d.prop.sys.randomValue) == 0 && step1 !in d.stepNames) { mixin(S_TRACE);
					assert (p2 !is null);
					e.expression = "DICE(1, %s) - 1".format(*p2);
				} else if (.icmp(step1, d.prop.sys.selectedPlayerCardNumber) == 0 && step1 !in d.stepNames) { mixin(S_TRACE);
					assert (p2 !is null);
					e.expression = "IF(CASTTYPE(SELECTED()) = 1, SELECTED(), 0)";
				} else { mixin(S_TRACE);
					assert (p2 !is null);
					e.expression = "STEPVALUE(\"%s\")".format(step1.replace("\"", "\"\""));
				}
			} else { mixin(S_TRACE);
				e = new Content(CType.SubstituteStep, name);
				e.step = step1;
				e.step2 = step2;
			}
			break;
		case 67:
			e = new Content(CType.SubstituteFlag, name);
			e.flag = dataVersion < 7 ? readString(f) : readExString(f);
			e.flag2 = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 68:
			auto step1 = dataVersion < 7 ? readString(f) : readExString(f);
			auto step2 = dataVersion < 7 ? readString(f) : readExString(f);
			auto p1 = step1 in d.numberSteps;
			auto p2 = step2 in d.numberSteps;
			if (p1 || p2) { mixin(S_TRACE);
				e = new Content(CType.TalkMessage, name);
				e.comment = "%s: %s, %s".format(d.prop.msgs.contentName(CType.BranchStepCmp), step1, step2);
				branchStepCmp[e.eventId] = .tuple(step1, step2);
			} else { mixin(S_TRACE);
				e = new Content(CType.BranchStepCmp, name);
				e.step = step1;
				e.step2 = step2;
			}
			break;
		case 69:
			e = new Content(CType.BranchFlagCmp, name);
			e.flag = dataVersion < 7 ? readString(f) : readExString(f);
			e.flag2 = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 70:
			e = new Content(CType.BranchRandomSelect, name);
			e.castRange = toCastRanges(f.readByte);
			ubyte style = f.readUByte;
			if (style & 0b01) { mixin(S_TRACE);
				if (dataVersion < 7) { mixin(S_TRACE);
					e.levelMin = f.readUIntL;
					e.levelMax = f.readUIntL;
				} else { mixin(S_TRACE);
					e.levelMin = f.readExUInt;
					e.levelMax = f.readExUInt;
				}
			} else { mixin(S_TRACE);
				e.levelMin = 0;
				e.levelMax = 0;
			}
			if (style & 0b10) { mixin(S_TRACE);
				e.status = toStatus(f.readByte);
			} else { mixin(S_TRACE);
				e.status = Status.None;
			}
			break;
		case 71:
			e = new Content(CType.BranchKeyCode, name);
			e.keyCodeRange = toKeyCodeRange(d, f.readByte, e, dataVersion);
			auto effCardTyp = toEffectCardType(f.readByte);
			final switch (effCardTyp) {
			case EffectCardType.All:
				e.targetIsSkill = true;
				e.targetIsItem = true;
				e.targetIsBeast = true;
				e.targetIsHand = true; // BUG: CardWirth 1.50ではアイテムが対象にあると手札も検索される
				break;
			case EffectCardType.Skill:
				e.targetIsSkill = true;
				e.targetIsItem = false;
				e.targetIsBeast = false;
				e.targetIsHand = false;
				break;
			case EffectCardType.Item:
				e.targetIsSkill = false;
				e.targetIsItem = true;
				e.targetIsBeast = false;
				e.targetIsHand = true; // BUG: CardWirth 1.50ではアイテムが対象にあると手札も検索される
				break;
			case EffectCardType.Beast:
				e.targetIsSkill = false;
				e.targetIsItem = false;
				e.targetIsBeast = true;
				e.targetIsHand = false;
				break;
			case EffectCardType.Hand: // 実際にはありえない
				e.targetIsSkill = false;
				e.targetIsItem = false;
				e.targetIsBeast = false;
				e.targetIsHand = true;
				break;
			}
			e.keyCode = dataVersion < 7 ? readString(f) : readExString(f);
			break;
		case 72:
			auto step = dataVersion < 7 ? readString(f) : readExString(f);
			auto stepValue = dataVersion < 7 ? f.readUIntL : f.readExInt;
			auto comparison4 = toComparison4(f.readByte);
			auto p = step in d.numberSteps;
			if (p) { mixin(S_TRACE);
				e = new Content(CType.CheckVariant, name);
				e.expression = checkStepExpression(d, step, stepValue, comparison4);
			} else { mixin(S_TRACE);
				e = new Content(CType.CheckStep, name);
				e.step = step;
				e.stepValue = stepValue;
				e.comparison4 = comparison4;
			}
			break;
		case 73:
			e = new Content(CType.BranchRound, name);
			e.comparison3 = toComparison3(f.readByte);
			e.round = dataVersion < 7 ? f.readUIntL : f.readExUInt;
			break;
		case 74:
			e = new Content(CType.MoveBgImage, name);
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
			e.transition = Transition.Default;
			e.transitionSpeed = 5u;
			break;
		case 75:
			e = new Content(CType.LoseBgImage, name);
			e.cellName = readExString(f);
			e.transition = Transition.Default;
			e.transitionSpeed = 5u;
			break;
		case 76:
			e = new Content(CType.ReplaceBgImage, name);
			e.cellName = readExString(f);
			e.backs = readBgImages(d, f, dataVersion, false, true);
			e.transition = Transition.Default;
			e.transitionSpeed = 5u;
			break;
		case 77:
			e = new Content(CType.MoveCard, name);
			e.cardGroup = readExString(f);
			auto anime = f.readBool;
			auto move = f.readBool;
			if (move) { mixin(S_TRACE);
				e.positionType = toCoordinateType(f.readByte);
				e.x = f.readExInt;
				e.y = f.readExInt;
				e.cardSpeed = anime ? -1 : 0;
				if (anime) e.overrideCardSpeed = true;
			}
			break;
		case 78:
			auto fb = f.readUByte;
			e = new Content(CType.ChangeEnvironment, name);
			auto fBackpack = (fb & 0b00000001) != 0;
			auto fSave = (fb & 0b00000010) != 0;
			auto fCamp = (fb & 0b00000100) != 0;
			if (fSave || fCamp) { mixin(S_TRACE);
				string[] lines;
				if (fSave) lines ~= .tryFormat(d.prop.msgs.convertFromNextWarning, d.prop.msgs.convertFromNextWarningForbidSave);
				if (fCamp) lines ~= .tryFormat(d.prop.msgs.convertFromNextWarning, d.prop.msgs.convertFromNextWarningForbidCamp);
				e.comment = lines.join("\n");
			}
			e.backpackEnabled = fBackpack || fCamp ? EnvironmentStatus.Disable : EnvironmentStatus.Enable;
			break;
		default: throw new SummaryException("Unknown content type: " ~ to!(string)(type));
		}
		auto p = "comment" in info;
		if (p) { mixin(S_TRACE);
			e.comment = *p;
		}
		return e;
	}
	int[] dataVersions;
	byte[] types;
	string[string][] infos;
	string[] names;
	Content[] children;
	while (true) { mixin(S_TRACE);
		byte type = f.readByte;
		string[string] info;
		string name = readString(f, info, false, false);
		auto cNum = f.readUIntL;
		int dataVersion;
		if (cNum <= 19999) { mixin(S_TRACE);
			dataVersion = 0;
		} else if (cNum <= 39999) { mixin(S_TRACE);
			dataVersion = 2;
			cNum -= 20000u;
		} else if (cNum <= 69999) { mixin(S_TRACE);
			dataVersion = 4;
			cNum -= 40000u;
		} else { mixin(S_TRACE);
			dataVersion = 7;
			cNum -= 70000u;
		}
		dataVersions ~= dataVersion;
		types ~= type;
		infos ~= info;
		names ~= name;

		if (cNum == 0) { mixin(S_TRACE);
			break;
		} else if (cNum == 1) { mixin(S_TRACE);
			continue;
		} else { mixin(S_TRACE);
			children.length = cNum;
			for (uint i = 0u; i < cNum; i++) { mixin(S_TRACE);
				children[i] = readContent(d, f, i);
			}
			break;
		}
	}

	string[string] branchMultiStep;
	Tuple!(string, string)[string] branchStepCmp;

	Content e = null;
	foreach_reverse (i, type; types) { mixin(S_TRACE);
		e = readImpl(d, f, dataVersions[i], type, names[i], infos[i], branchMultiStep, branchStepCmp);
		auto ed = e.detail;
		if (ed.owner) { mixin(S_TRACE);
			static immutable REG_C = .ctRegex!("^[0-9]+$");
			auto defExpr = "";
			if (auto p = e.eventId in branchMultiStep) { mixin(S_TRACE);
				if (.any(.map!(c => c.name == "Default")(children))) { mixin(S_TRACE);
					// 数値ステップの多岐分岐をコモン版へ変換した時の「その他」の式
					// (他の全ての選択肢に一致しない)を生成しておく
					auto step = *p;
					auto encoded = step.replace("\"", "\"\"");
					assert (step in d.numberSteps);
					string[] arr;
					bool[string] ccNames;
					foreach (cc; children) { mixin(S_TRACE);
						if (.match(cc.name, REG_C).empty) continue;
						if (cc.name in ccNames) continue;
						ccNames[cc.name] = true;
						arr ~= "@\"%s\" = %s".format(encoded, cc.name);
					}
					if (arr.length) { mixin(S_TRACE);
						defExpr = "not (%s)".format(arr.join(" or "));
					} else { mixin(S_TRACE);
						defExpr = "TRUE";
					}
				}
			}
			foreach (c; children) { mixin(S_TRACE);
				if (ed.nextType is CNextType.Text) { mixin(S_TRACE);
					auto name2 = c.name;
					foreach (path; d.numberSteps.byKey()) { mixin(S_TRACE);
						name2 = .replStepToVariantInText(name2, path, path);
					}
					c.setName(null, name2);
				}
				void mergeCheckContent(Content chk) { mixin(S_TRACE);
					// 数値ステップの多岐分岐と比較をコモン版に置換する時、
					// 直後のイベントコンテントがCheck系であればそれとマージする
					if (c.type is CType.CheckFlag) { mixin(S_TRACE);
						chk.expression = "(%s) and (%s)".format(chk.expression, checkFlagExpression(c.flag));
						foreach (cc; c.next) { mixin(S_TRACE);
							cc.setName(null, "");
							chk.add(null, cc);
						}
						e.add(null, chk);
					} else if (c.type is CType.CheckStep) { mixin(S_TRACE);
						chk.expression = "(%s) and (%s)".format(chk.expression, checkStepExpression(d, c.step, c.stepValue, c.comparison4));
						foreach (cc; c.next) { mixin(S_TRACE);
							cc.setName(null, "");
							chk.add(null, cc);
						}
						e.add(null, chk);
					} else if (c.type is CType.CheckVariant) { mixin(S_TRACE);
						chk.expression = "(%s) and (%s)".format(chk.expression, c.expression);
						foreach (cc; c.next) { mixin(S_TRACE);
							cc.setName(null, "");
							chk.add(null, cc);
						}
						e.add(null, chk);
					} else { mixin(S_TRACE);
						c.setName(null, "");
						chk.add(null, c);
						e.add(null, chk);
					}
				}
				if (auto p = e.eventId in branchMultiStep) { mixin(S_TRACE);
					// 数値ステップの多岐分岐をコモン判定へ置換
					auto chk = new Content(CType.CheckVariant, "");
					auto step = *p;
					auto encoded = step.replace("\"", "\"\"");
					assert (step in d.numberSteps);
					if (c.name == "Default") { mixin(S_TRACE);
						chk.expression = defExpr;
					} else if (!.match(c.name, REG_C).empty) { mixin(S_TRACE);
						chk.expression = "@\"%s\" = %s".format(encoded, c.name);
					} else { mixin(S_TRACE);
						chk.expression = "FALSE";
					}
					mergeCheckContent(chk);
					branchMultiStep.remove(c.eventId);
				} else if (auto p = e.eventId in branchStepCmp) { mixin(S_TRACE);
					// 数値ステップないし普通ステップの比較分岐をコモン判定へ置換
					auto chk = new Content(CType.CheckVariant, "");
					auto step1 = (*p)[0];
					auto step2 = (*p)[1];
					auto encoded1 = step1.replace("\"", "\"\"");
					auto encoded2 = step2.replace("\"", "\"\"");
					string exprStep1;
					string exprStep2;
					if (step1 in d.numberSteps) { mixin(S_TRACE);
						exprStep1 = "@\"%s\"".format(encoded1);
					} else { mixin(S_TRACE);
						exprStep1 = "STEPVALUE(\"%s\")".format(encoded1);
					}
					if (step2 in d.numberSteps) { mixin(S_TRACE);
						exprStep2 = "@\"%s\"".format(encoded2);
					} else { mixin(S_TRACE);
						exprStep2 = "STEPVALUE(\"%s\")".format(encoded2);
					}
					switch (c.name) {
					case "<":
					case ">":
					case "=":
						chk.expression = "%s %s %s".format(exprStep1, c.name, exprStep2);
						break;
					default:
						chk.expression = "FALSE";
						break;
					}
					mergeCheckContent(chk);
					branchStepCmp.remove(c.eventId);
				} else { mixin(S_TRACE);
					e.add(null, c);
				}
			}
		}
		children = [e];
	}
	return e;
}
private EventTree readCEventTree(ref RData d, ref ByteIO f, size_t index) { mixin(S_TRACE);
	EventTree tree = null;
	uint cNum = f.readUIntL;
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	if (0x7000000 <= cNum) { mixin(S_TRACE);
		// データバージョン？
		cNum -= 0x7000000;
		d.dataVersion = 7;
	}
	for (uint i = 0u; i < cNum; i++) { mixin(S_TRACE);
		auto start = readContent(d, f, i);
		if (tree) { mixin(S_TRACE);
			tree.add(start);
		} else { mixin(S_TRACE);
			tree = new EventTree(start);
		}
	}
	if (!tree) tree = new EventTree("");
	return tree;
}
private EventTree readEventTree(ref RData d, ref ByteIO f, bool enemyCard, size_t index) { mixin(S_TRACE);
	EventTree tree = null;
	uint cNum = f.readUIntL;
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	if (0x7000000 <= cNum) { mixin(S_TRACE);
		// データバージョン？
		cNum -= 0x7000000;
		d.dataVersion = 7;
	}
	for (uint i = 0u; i < cNum; i++) { mixin(S_TRACE);
		auto start = readContent(d, f, i);
		if (tree) { mixin(S_TRACE);
			tree.add(start);
		} else { mixin(S_TRACE);
			tree = new EventTree(start);
		}
	}
	if (!tree) tree = new EventTree("");
	uint igNum = d.dataVersion < 7 ? f.readUIntL : f.readExUInt;
	for (uint i = 0u; i < igNum; i++) { mixin(S_TRACE);
		int ig = d.dataVersion < 7 ? f.readIntL : f.readExUInt;
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
	tree.sortRounds();
	if (7 <= d.dataVersion) { mixin(S_TRACE);
		tree.keyCodeMatchingType = f.readBool ? MatchingType.And : MatchingType.Or;
	}
	auto keyCodes = d.dataVersion < 7 ? readStrings(f) : readExStrings(f);
	if (d.dataVersion < 7 && keyCodes.length && "MatchingType=All" == keyCodes[0]) { mixin(S_TRACE);
		// CardWirth 1.50
		tree.keyCodeMatchingType = MatchingType.And;
		keyCodes = keyCodes[1 .. $];
	}
	FKeyCode[] kcArray;
	foreach (keyCode; keyCodes) { mixin(S_TRACE);
		auto kind = d.prop.sys.fireKeyCodeKindRef(keyCode);
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
	} else if (dataVersion <= 6) { mixin(S_TRACE);
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
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
			cell.cellName = cellName;
			return cell;
		case 2:
			// テキストセル
			bool mask = readBool(f);
			bool foreground = false;
			if (7 <= dataVersion) { mixin(S_TRACE);
				foreground = readBool(f);
			}
			string text = readString(f).replace("\r", "");
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
			auto cell = new TextCell(text, fontName, size, color, bold, italic, underline, strike, vertical, false,
				borderingType, borderingColor, borderingWidth, UpdateType.Fixed, flag, x, y, w, h, mask);
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
			cell.cellName = cellName;
			return cell;
		case 3:
			// カラーセル
			bool mask = false;
			bool foreground = false;
			auto blend = toBlendMode(f.readByte, mask);
			if (7 <= dataVersion) { mixin(S_TRACE);
				foreground = readBool(f);
			}
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
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
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
			auto cell = new PCCell(pcNumber, false, flag, x, y, w, h, mask);
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
			cell.cellName = cellName;
			return cell;
		default:
			throw new SummaryException("Unknown cell type: " ~ to!string(type));
		}
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
				imgPath = .decodePathLegacy(readExString(f));
			}
			auto flag = readExString(f);
			f.readByte; // 不明(0)
			auto cellName = readExString(f);
			auto cell = new ImageCell(imgPath, flag, x, y, w, h, mask);
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
			cell.cellName = cellName;
			return cell;
		case 2:
			// テキストセル
			bool mask = readBool(f);
			bool foreground = readBool(f);
			string text = readExString(f).replace("\r", "");
			foreach (path; d.numberSteps.byKey()) { mixin(S_TRACE);
				text = .replStepToVariantInText(text, path, path);
			}
			string fontName = readExString(f);
			uint size = f.readExUInt;
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
				borderingWidth = f.readExUInt;
			}
			f.readByte; // 不明(0xC8)
			f.readByte; // 不明(0x01)
			f.readByte; // 不明(0)
			f.readByte; // 不明(0)
			f.readByte; // 不明(縦書き時:2,他:0)
			auto flag = readExString(f);
			f.readByte; // 不明(0)
			auto cellName = readExString(f);
			auto cell = new TextCell(text, fontName, size, color, bold, italic, underline, strike, vertical, false,
				borderingType, borderingColor, borderingWidth, UpdateType.Fixed, flag, x, y, w, h, mask);
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
			cell.cellName = cellName;
			return cell;
		case 3:
			// カラーセル
			bool mask = false;
			auto blend = toBlendMode(f.readByte, mask);
			bool foreground = readBool(f);
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
			auto flag = readExString(f);
			f.readByte; // 不明(0)
			auto cellName = readExString(f);
			auto cell = new ColorCell(blend, gradient, color1, color2, flag, x, y, w, h, mask);
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
			cell.cellName = cellName;
			return cell;
		case 4:
			// PCイメージセル
			bool mask = readBool(f);
			bool foreground = readBool(f);
			ubyte pcNumber = f.readUByte;
			auto flag = readExString(f);
			f.readByte; // 不明(0)
			auto cellName = readExString(f);
			auto cell = new PCCell(pcNumber, false, flag, x, y, w, h, mask);
			cell.layer = foreground ? LAYER_FORE_CELL : LAYER_BACK_CELL;
			cell.cellName = cellName;
			return cell;
		default:
			throw new SummaryException("Unknown cell type: " ~ to!string(type));
		}
	}
}
private BgImage[] readBgImages(in RData d, ref ByteIO f, int dataVersion, bool area, bool replBgImg = false) { mixin(S_TRACE);
	BgImage[] bgImgs;
	if (dataVersion < 7) { mixin(S_TRACE);
		bgImgs.length = f.readUIntL;
	} else { mixin(S_TRACE);
		bgImgs.length = f.readExUInt;
	}
	for (uint i = 0u; i < bgImgs.length; i++) { mixin(S_TRACE);
		bgImgs[i] = readBgImage(d, f, area, i);
	}
	if (replBgImg) return bgImgs;
	if (!bgImgs.length) { mixin(S_TRACE);
		return bgImgs;
	}
	auto b = cast(ImageCell)bgImgs[0u];
	if (b && b.path == "" && b.flag == ""
			&& b.x == 0 && b.y == 0 && b.width == 632 && b.height == 420 && !b.mask && b.cellName == "") { mixin(S_TRACE);
		// クラシックなエンジンでは必ず1枚以上の背景画像が必要であるため、
		// 背景継承時はダミーのイメージが挿入されている
		return bgImgs[1u .. $];
	} else { mixin(S_TRACE);
		return bgImgs;
	}
}
private void readAreaHeader(ref RData d, ref ByteIO f, out ulong id, out string name) { mixin(S_TRACE);
	auto tb = f.readUByte;
	if (tb == 0xFF) { mixin(S_TRACE);
		d.dataVersion = f.readUByte;
		name = readExString(f);
		id = f.readExUInt;
	} else { mixin(S_TRACE);
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
}
private Area loadArea(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	ulong id;
	string name;
	readAreaHeader(d, f, id, name);
	auto a = new Area(id, name);
	if (d.dataVersion < 7) { mixin(S_TRACE);
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
			uint scale = f.readUIntL;
			int x = f.readIntL;
			int y = f.readIntL;
			CardImage imgPath = null;
			if (d.dataVersion <= 2) { mixin(S_TRACE);
				// 格納のみ
				imgPath = img ? new CardImage(img, CardImagePosition.Default) : null;
			} else { mixin(S_TRACE);
				auto file = decodePathLegacy(readString(f));
				if (isNumeric(file)) { mixin(S_TRACE);
					// PC画像
					try { mixin(S_TRACE);
						auto pcNum = .to!uint(file);
						if (0 < pcNum) imgPath = new CardImage(pcNum);
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
				}
				if (!imgPath && file.length) { mixin(S_TRACE);
					// ファイル指定
					imgPath = new CardImage(file, CardImagePosition.Default);
				}
				if (!imgPath && img.length) {
					// イメージ格納
					imgPath = new CardImage(img, CardImagePosition.Default);
				}
			}
			auto c = new MenuCard(cName, false, imgPath ? [imgPath] : [], desc, flag, x, y, scale, LAYER_MENU_CARD, "", -1);
			foreach (tree; trees) { mixin(S_TRACE);
				c.add(tree);
			}
			a.append(c);
		}
	} else { mixin(S_TRACE);
		uint evtNum = f.readExUInt;
		for (uint i = 0; i < evtNum; i++) { mixin(S_TRACE);
			a.add(readEventTree(d, f, false, i));
		}
		a.spAuto = !readBool(f);
		uint cNum = f.readExUInt;
		for (uint i = 0; i < cNum; i++) { mixin(S_TRACE);
			f.readUByte; // 不明(0x80)
			f.readUByte; // バージョン情報？(0x07)
			f.readUByte; // 不明(0)
			string img = readImage(d, f);
			string cName = readExString(f);
			f.readUByte; // 不明(0)
			string desc = readExString(f);
			uint cEvtNum = f.readExUInt;
			EventTree[] trees;
			trees.length = cEvtNum;
			for (uint j = 0; j < cEvtNum; j++) { mixin(S_TRACE);
				trees[j] = readEventTree(d, f, false, j);
			}
			string flag = readExString(f);
			uint scale = f.readExUInt;
			int x = f.readExInt;
			int y = f.readExInt;
			auto sb = f.readUByte;
			auto imgType = sb & 0x0F;

			CardImage imgPath = null;
			switch (imgType) {
			case 0: // イメージ無しないし格納
				if (img != "") imgPath = new CardImage(img, CardImagePosition.Default);
				break;
			case 1: // ファイル指定
				auto file = decodePathLegacy(readExString(f));
				imgPath = new CardImage(file, CardImagePosition.Default);
				break;
			case 2: // PC番号
				auto pcNum = f.readUByte;
				imgPath = new CardImage(pcNum);
				break;
			default:
				throw new Exception("Invalid menu card image type: %s".format(imgType));
			}

			auto cardGroup = readExString(f);
			auto noAnime = (sb & 0b00010000) != 0;
			auto expandVars = (sb & 0b00100000) != 0;
			auto animationSpeed = noAnime ? 0 : -1;

			auto c = new MenuCard(cName, expandVars, imgPath ? [imgPath] : [], desc, flag, x, y, scale, LAYER_MENU_CARD, cardGroup, animationSpeed);
			foreach (tree; trees) { mixin(S_TRACE);
				c.add(tree);
			}
			a.append(c);
		}
	}
	foreach (bg; readBgImages(d, f, d.dataVersion, true)) { mixin(S_TRACE);
		a.append(bg);
	}
	return a;
}
private Battle loadBattle(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	ulong id;
	string name;
	readAreaHeader(d, f, id, name);
	auto r = new Battle(id, name, "");
	if (d.dataVersion < 7) { mixin(S_TRACE);
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
			uint scale = f.readUIntL;
			int x = f.readIntL;
			int y = f.readIntL;
			bool escape = readBool(f);
			auto c = new EnemyCard(cId, [ActionCardType.RunAway:escape], flag, x, y, scale, LAYER_MENU_CARD, "", -1, false, "", false, []);
			foreach (tree; cTrees) { mixin(S_TRACE);
				c.add(tree);
			}
			r.append(c);
		}
		if (0 < d.dataVersion) { mixin(S_TRACE);
			r.music = decodePathLegacy(readString(f));
		} else { mixin(S_TRACE);
			r.music = "DefBattle.mid";
		}
	} else { mixin(S_TRACE);
		uint evtNum = f.readExUInt;
		for (uint i = 0; i < evtNum; i++) { mixin(S_TRACE);
			r.add(readEventTree(d, f, false, i));
		}
		r.spAuto = !readBool(f);
		uint cNum = f.readExUInt;
		for (uint i = 0; i < cNum; i++) { mixin(S_TRACE);
			ulong cId = f.readExUInt;
			uint cEvtNum = f.readUIntL;
			EventTree[] cTrees;
			cTrees.length = cEvtNum;
			for (uint j = 0u; j < cEvtNum; j++) { mixin(S_TRACE);
				cTrees[j] = readEventTree(d, f, true, j);
			}
			string flag = readString(f);
			uint scale = f.readUIntL;
			int x = f.readIntL;
			int y = f.readIntL;
			auto sb = f.readUByte;
			auto escape = (sb & 0b0001) != 0;
			auto pcImage = (sb & 0b0010) != 0;
			auto isOverrideName = (sb & 0b0100) != 0;
			uint pcNum = 0;
			if (pcImage) pcNum = f.readUByte;
			string overrideName;
			if (isOverrideName) overrideName = readExString(f);

			auto c = new EnemyCard(cId, [ActionCardType.RunAway:escape], flag, x, y, scale, LAYER_MENU_CARD, "", -1, isOverrideName, overrideName, pcImage, pcImage ? [new CardImage(pcNum)] : []);
			foreach (tree; cTrees) { mixin(S_TRACE);
				c.add(tree);
			}
			r.append(c);
		}
		r.music = decodePathLegacy(readExString(f));
	}
	return r;
}
private Package loadPackage(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	d.dataVersion = f.readUIntL;
	string name;
	ulong id;
	uint evtNum;
	if (d.dataVersion < 7) { mixin(S_TRACE);
		name = readString(f);
		id = f.readUIntL;
		evtNum = f.readUIntL;
	} else { mixin(S_TRACE);
		name = readExString(f);
		id = f.readExUInt;
		evtNum = f.readExUInt;
	}
	auto r = new Package(id, name);
	for (uint i = 0u; i < evtNum; i++) { mixin(S_TRACE);
		r.add(readCEventTree(d, f, i));
	}
	return r;
}
private CastCard loadCast(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	auto b = f.readUByte;
	CastCard r;
	if (b == 0x80) { mixin(S_TRACE);
		d.dataVersion = f.readByte;
		f.readByte; // Type: Mate=2
		auto img = readImage(d, f);
		auto name = readExString(f);
		auto id = f.readExUInt;
		r = new CastCard(id, name, img.length ? [new CardImage(img, CardImagePosition.Default)] : [], "", 1u, 1u);
		auto eb1 = f.readUByte;
		auto eb2 = f.readUByte;
		r.weaponResist = (eb1 & 0b00000001) != 0;
		r.magicResist = (eb1 & 0b00000010) != 0;
		r.undead = (eb1 & 0b00000100) != 0;
		r.automaton = (eb1 & 0b00001000) != 0;
		r.unholy = (eb1 & 0b00010000) != 0;
		r.constructure = (eb1 & 0b00100000) != 0;
		r.resist(Element.Fire, (eb1 & 0b01000000) != 0);
		r.resist(Element.Ice, (eb1 & 0b10000000) != 0);
		r.weakness(Element.Fire, (eb2 & 0b00000001) != 0);
		r.weakness(Element.Ice, (eb2 & 0b00000010) != 0);
		r.level = f.readExUInt;
		r.desc = readExString(f, true, true);
		r.life = f.readExUInt;
		r.lifeMax = f.readExUInt;
		r.paralyze = f.readExUInt;
		r.poison = f.readExUInt;
		r.defaultEnhance(Enhance.Avoid, f.readExInt);
		r.defaultEnhance(Enhance.Resist, f.readExInt);
		r.defaultEnhance(Enhance.Defense, f.readExInt);
		r.physical(Physical.Dex, f.readExUInt);
		r.physical(Physical.Agl, f.readExUInt);
		r.physical(Physical.Int, f.readExUInt);
		r.physical(Physical.Str, f.readExUInt);
		r.physical(Physical.Vit, f.readExUInt);
		r.physical(Physical.Min, f.readExUInt);
		r.mental(Mental.Aggressive, f.readExInt);
		r.mental(Mental.Cheerful, f.readExInt);
		r.mental(Mental.Brave, f.readExInt);
		r.mental(Mental.Cautious, f.readExInt);
		r.mental(Mental.Trickish, f.readExInt);
		r.mentality = toMentality(f.readByte);
		r.mentalityRound = f.readExUInt;
		r.bindRound = f.readExUInt;
		r.silenceRound = f.readExUInt;
		r.faceUpRound = f.readExUInt;
		r.antiMagicRound = f.readExUInt;
		r.enhance(Enhance.Action, f.readExInt);
		r.enhanceRound(Enhance.Action, f.readExUInt);
		r.enhance(Enhance.Avoid, f.readExInt);
		r.enhanceRound(Enhance.Avoid, f.readExUInt);
		r.enhance(Enhance.Resist, f.readExInt);
		r.enhanceRound(Enhance.Resist, f.readExUInt);
		r.enhance(Enhance.Defense, f.readExInt);
		r.enhanceRound(Enhance.Defense, f.readExUInt);
		auto itmNum = f.readExUInt;
		for (uint i = 0u; i < itmNum; i++) { mixin(S_TRACE);
			r.add(loadItem(d, f, i + 1), true);
		}
		auto sklNum = f.readExUInt;
		for (uint i = 0u; i < sklNum; i++) { mixin(S_TRACE);
			r.add(loadSkill(d, f, i + 1), true);
		}
		auto bstNum = f.readExUInt;
		for (uint i = 0u; i < bstNum; i++) { mixin(S_TRACE);
			r.add(loadBeast(d, f, i + 1), true);
		}
		f.readByte; // 不明
		auto cpnNum = f.readExUInt;
		Coupon[] cpns;
		cpns.length = cpnNum;
		for (uint i = 0u; i < cpnNum; i++) { mixin(S_TRACE);
			auto coupon = readString(f);
			auto val = f.readIntL;
			cpns[i] = new Coupon(coupon, val);
		}
		r.coupons = cpns;
	} else { mixin(S_TRACE);
		auto img = readImage(d, f);
		auto name = readString(f);
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
		r = new CastCard(id, name, img.length ? [new CardImage(img, CardImagePosition.Default)] : [], "", 1u, 1u);
		r.weaponResist = readBool(f);
		r.magicResist = readBool(f);
		r.undead = readBool(f);
		r.automaton = readBool(f);
		r.unholy = readBool(f);
		r.constructure = readBool(f);
		r.resist(Element.Fire, readBool(f));
		r.resist(Element.Ice, readBool(f));
		r.weakness(Element.Fire, readBool(f));
		r.weakness(Element.Ice, readBool(f));
		r.level = f.readUIntL;
		f.readUIntL; // 所持金。現行エンジンでは未使用
		r.desc = readString(f, true, true);
		r.life = f.readUIntL;
		r.lifeMax = f.readUIntL;
		r.paralyze = f.readUIntL;
		r.poison = f.readUIntL;
		r.defaultEnhance(Enhance.Avoid, f.readUIntL);
		r.defaultEnhance(Enhance.Resist, f.readUIntL);
		r.defaultEnhance(Enhance.Defense, f.readUIntL);
		r.physical(Physical.Dex, f.readUIntL);
		r.physical(Physical.Agl, f.readUIntL);
		r.physical(Physical.Int, f.readUIntL);
		r.physical(Physical.Str, f.readUIntL);
		r.physical(Physical.Vit, f.readUIntL);
		r.physical(Physical.Min, f.readUIntL);
		r.mental(Mental.Aggressive, f.readIntL);
		r.mental(Mental.Cheerful, f.readIntL);
		r.mental(Mental.Brave, f.readIntL);
		r.mental(Mental.Cautious, f.readIntL);
		r.mental(Mental.Trickish, f.readIntL);
		r.mentality = toMentality(f.readByte);
		r.mentalityRound = f.readUIntL;
		r.bindRound = f.readUIntL;
		r.silenceRound = f.readUIntL;
		r.faceUpRound = f.readUIntL;
		r.antiMagicRound = f.readUIntL;
		r.enhance(Enhance.Action, f.readUIntL);
		r.enhanceRound(Enhance.Action, f.readUIntL);
		r.enhance(Enhance.Avoid, f.readUIntL);
		r.enhanceRound(Enhance.Avoid, f.readUIntL);
		r.enhance(Enhance.Resist, f.readUIntL);
		r.enhanceRound(Enhance.Resist, f.readUIntL);
		r.enhance(Enhance.Defense, f.readUIntL);
		r.enhanceRound(Enhance.Defense, f.readUIntL);
		uint itmNum = f.readUIntL;
		for (uint i = 0u; i < itmNum; i++) { mixin(S_TRACE);
			r.add(loadItem(d, f, i + 1), true);
		}
		uint sklNum = f.readUIntL;
		for (uint i = 0u; i < sklNum; i++) { mixin(S_TRACE);
			r.add(loadSkill(d, f, i + 1), true);
		}
		uint bstNum = f.readUIntL;
		for (uint i = 0u; i < bstNum; i++) { mixin(S_TRACE);
			r.add(loadBeast(d, f, i + 1), true);
		}
		if (0 < d.dataVersion) { mixin(S_TRACE);
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
	}
	return r;
}
private C readEffCard(C)(ref RData d, ref ByteIO f) { mixin(S_TRACE);
	auto b = f.readUByte;
	C r;
	if (b == 0x80) { mixin(S_TRACE);
		d.dataVersion = f.readByte;
		f.readByte; // Type: Skill=5, Item=3, Beast=6
		auto img = readImage(d, f);
		auto name = readExString(f);
		auto id = f.readExUInt;
		auto desc = readExString(f);
		r = new C(d.prop.sys, id, name, img.length ? [new CardImage(img, CardImagePosition.Default)] : [], desc);
		r.physical = toPhysical(f.readExInt);
		r.mental = toMental(f.readExInt);
		r.spell = readBool(f);
		r.allRange = readBool(f);
		r.target = toCardTarget(f.readByte);
		r.effectType = toEffectType(f.readByte);
		r.resist = toResist(f.readByte);
		r.successRate = f.readExInt;
		r.visual = toCardVisual(f.readByte);
		uint mNum = f.readExUInt;
		Motion[] motions;
		motions.length = mNum;
		for (uint i = 0u; i < mNum; i++) { mixin(S_TRACE);
			motions[i] = readMotion(d, d.dataVersion, f, i);
		}
		r.motions = motions;
		r.enhance(Enhance.Avoid, f.readExInt);
		r.enhance(Enhance.Resist, f.readExInt);
		r.enhance(Enhance.Defense, f.readExInt);

		auto sp1 = readSound(d, f);
		r.soundPath1 = (sp1 == "（なし）" || sp1 == "（なし）.wav") ? "" : decodePathLegacy(sp1);
		auto sp2 = readSound(d, f);
		r.soundPath2 = (sp2 == "（なし）" || sp2 == "（なし）.wav") ? "" : decodePathLegacy(sp2);

		auto keyCodeNum = f.readExUInt;
		auto keyCodes = new string[keyCodeNum];
		uint keyCodeCount = 0;
		for (uint i = 0u; i < keyCodeNum; i++) { mixin(S_TRACE);
			keyCodes[i] = readExString(f);
			if (keyCodes[i] != "") keyCodeCount = i + 1;
		}
		keyCodes.length = keyCodeCount;
		r.keyCodes = keyCodes;
		r.premium = toPremium(f.readByte);
		f.readByte; // 不明
		r.scenario = readExString(f);
		r.author = readExString(f);
		uint evtNum = f.readExUInt;
		for (uint i = 0u; i < evtNum; i++) { mixin(S_TRACE);
			r.add(readCEventTree(d, f, i));
		}
	} else { mixin(S_TRACE);
		auto img = readImage(d, f);
		auto name = readString(f);
		auto idl = f.readUIntL;
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
		auto desc = readString(f);
		r = new C(d.prop.sys, id, name, img.length ? [new CardImage(img, CardImagePosition.Default)] : [], desc);
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
			motions[i] = readMotion(d, d.dataVersion, f, i);
		}
		r.motions = motions;
		r.enhance(Enhance.Avoid, f.readIntL);
		r.enhance(Enhance.Resist, f.readIntL);
		r.enhance(Enhance.Defense, f.readIntL);
		string sp1 = readString(f);
		r.soundPath1 = (sp1 == "（なし）" || sp1 == "（なし）.wav") ? "" : decodePathLegacy(sp1);
		string sp2 = readString(f);
		r.soundPath2 = (sp2 == "（なし）" || sp2 == "（なし）.wav") ? "" : decodePathLegacy(sp2);
		string[] keyCodes;
		keyCodes.length = 5u;
		uint keyCodeCount = 0;
		for (uint i = 0u; i < 5u; i++) { mixin(S_TRACE);
			keyCodes[i] = readString(f);
			if (keyCodes[i] != "") keyCodeCount = i + 1;
		}
		keyCodes.length = keyCodeCount;
		r.keyCodes = keyCodes;
		if (0 < d.dataVersion) { mixin(S_TRACE);
			r.premium = toPremium(f.readByte);
		}
		if (2 < d.dataVersion) { mixin(S_TRACE);
			r.scenario = readString(f);
			r.author = readString(f);
			uint evtNum = f.readUIntL;
			for (uint i = 0u; i < evtNum; i++) { mixin(S_TRACE);
				r.add(readCEventTree(d, f, i));
			}
		}
	}
	return r;
}
private SkillCard loadSkill(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	auto r = readEffCard!(SkillCard)(d, f);
	if (2 < d.dataVersion) { mixin(S_TRACE);
		r.hold = readBool(f);
	}
	if (d.dataVersion < 7) { mixin(S_TRACE);
		r.level = f.readUIntL;
		r.useLimit = f.readUIntL;
	} else { mixin(S_TRACE);
		r.level = f.readExInt;
		r.useLimit = f.readExUInt;
		f.readBool; // バックパック対応
	}
	return r;
}
private ItemCard loadItem(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	auto r = readEffCard!(ItemCard)(d, f);
	if (2 < d.dataVersion) { mixin(S_TRACE);
		r.hold = readBool(f);
	}
	if (d.dataVersion < 7) { mixin(S_TRACE);
		r.useLimit = f.readUIntL;
		r.useLimitMax = f.readUIntL;
		r.price = f.readUIntL;
		r.enhanceOwner(Enhance.Avoid, f.readUIntL);
		r.enhanceOwner(Enhance.Resist, f.readUIntL);
		r.enhanceOwner(Enhance.Defense, f.readUIntL);
	} else { mixin(S_TRACE);
		r.useLimit = f.readExUInt;
		r.useLimitMax = f.readExUInt;
		r.price = f.readExUInt;
		r.enhanceOwner(Enhance.Avoid, f.readExInt);
		r.enhanceOwner(Enhance.Resist, f.readExInt);
		r.enhanceOwner(Enhance.Defense, f.readExInt);
		// バックパック対応は記憶されない(バグ？)
	}
	return r;
}
private BeastCard loadBeast(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	auto r = readEffCard!(BeastCard)(d, f);
	if (2 < d.dataVersion) { mixin(S_TRACE);
		readBool(f); // Hold
	}
	r.useLimit = d.dataVersion < 7 ? f.readUIntL : f.readExUInt;
	// バックパック対応は記憶されない(バグ？)
	if (7 <= d.dataVersion) f.readByte; // 不明(使用回数あり=1, 使用回数無し=0。付帯フラグか？)
	return r;
}
private InfoCard loadInfo(ref RData d, ref ByteIO f, ulong fid) { mixin(S_TRACE);
	auto v = d.dataVersion;
	scope (exit) d.dataVersion = v;
	auto b = f.readUByte;
	string img;
	string name;
	ulong id;
	string desc;
	if (b == 0x80) { mixin(S_TRACE);
		d.dataVersion = f.readByte;
		f.readByte; // Type: Info=4
		img = readImage(d, f);
		name = readExString(f);
		id = f.readExUInt;
		desc = readExString(f);
	} else { mixin(S_TRACE);
		img = readImage(d, f);
		name = readString(f);
		ulong idl = f.readUIntL;
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
		desc = readString(f);
	}
	return new InfoCard(id, name, img.length ? [new CardImage(img, CardImagePosition.Default)] : [], desc);
}

/// パーティ見出しデータ(*.wpl)からパーティ名を取得する。
string readPartyName(const CProps prop, string wpl) { mixin(S_TRACE);
	auto d = RData(prop, false, "", "", "", 0);
	ubyte* ptr = null;
	auto f = ByteIO(readBinaryFrom!ubyte(wpl, ptr));
	scope (exit) freeAll(ptr);
	f.readUShortL; // 不明(0)
	readString(f); // 宿名
	readImage(d, f); // 宿イメージ
	readString(f); // メンバリスト
	return readString(f); // パーティ名
}

/// 宿情報(Environment.wyd)からデバッグ宿か否かを取得する。
bool isDebugYado(const CProps prop, string yadoDir) { mixin(S_TRACE);
	auto d = RData(prop, false, "", "", "", 0);
	auto env = yadoDir.buildPath("Environment.wyd");
	ubyte* ptr = null;
	auto f = ByteIO(readBinaryFrom!ubyte(env, ptr));
	scope (exit) freeAll(ptr);
	auto dataVersion = readString(f);
	auto type = f.readByte; // 1 = 通常宿, 2 = デバッグ宿
	return type == 2;
}

struct SData {
	const CProps prop;
	string sPath;
	const Skin skin;
	bool saveInnerImagePath;
	bool logicalSort;
	SkillCard delegate(ulong) skill;
	ItemCard delegate(ulong) item;
	BeastCard delegate(ulong) beast;
	const(SaveOption) opt;
	string[string] comment;
	string[string] imageRef;
	ulong[string] cardRef;
	uint[string] maxNest;
	uint[ulong] nestCount; /// 召喚獣カードのCWXパスとネストされた回数。

	void merge(in SData d) { mixin(S_TRACE);
		foreach (key, value; d.comment) comment[key] = value;
		foreach (key, value; d.imageRef) imageRef[key] = value;
		foreach (key, value; d.cardRef) cardRef[key] = value;
		foreach (key, value; d.maxNest) maxNest[key] = value;
		foreach (key, value; d.nestCount) nestCount[key] = value;
	}
}
/// 4.0形式のCardWirthシナリオを保存する。
void saveLScenario(Summary summ, string scenarioPath, const Skin skin, const CProps prop, in SaveOption opt, FileSync sync) { mixin(S_TRACE);
	HashSet!Object changed = null;
	if (opt.saveChangedOnly) changed = summ.changedResources;

	static immutable SYS_FNAME = .ctRegex!("^(((Area|Battle|Package|Mate|Skill|Item|Beast|Info)[0-9]+\\.wid)|((Comment|ImageRef|CardRef|Template)\\.wex))$");
	bool canBackup = opt.backup && (!opt.backupDir.exists() || opt.backupDir.isDir());
	if (canBackup) { mixin(S_TRACE);
		if (!opt.backupDir.exists()) opt.backupDir.mkdirRecurse();
		foreach (file; clistdir(opt.backupDir)) { mixin(S_TRACE);
			.delAll(opt.backupDir.buildPath(file));
		}
		auto summPath = std.path.buildPath(scenarioPath, "Summary.wsm");
		if (summPath.exists()) { mixin(S_TRACE);
			summPath.copy(opt.backupDir.buildPath("Summary.wsm"));
		}
	}

	class Save {
		SData d;
		Area[] areas;
		Battle[] battles;
		Package[] packages;
		CastCard[] casts;
		SkillCard[] skills;
		ItemCard[] items;
		BeastCard[] beasts;
		InfoCard[] infos;
		bool[string] wids;
		this () {
			d = SData(prop, scenarioPath, skin, opt.saveInnerImagePath, opt.logicalSort, (id) => summ.skill(id), (id) => summ.item(id), (id) => summ.beast(id), opt);
		}
		void writeFile(CWXPath a, string name, void delegate(ref ByteIO f) write) { mixin(S_TRACE);
			auto path = std.path.buildPath(d.sPath, name);
			auto changed = !d.opt.saveChangedOnly || changed.contains(cast(Object)a);
			if (changed && canBackup && path.exists()) { mixin(S_TRACE);
				try {
					if (!opt.backupDir.exists()) opt.backupDir.mkdirRecurse();
				} catch (FileException e) { }
				path.copy(opt.backupDir.buildPath(name));
			}
			if (changed || !path.exists() || !path.isFile()) { mixin(S_TRACE);
				ByteIO f;
				write(f);
				.writeFile(path, f.bytes, sync);
				f.dispose();
			} else { mixin(S_TRACE);
				putExData(d, a);
			}
			wids[name] = true;
		}
		void save() { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Start Classic Save Thread");
			}
			foreach (a; areas) { mixin(S_TRACE);
				writeFile(a, "Area" ~ to!(string)(a.id) ~ ".wid", (ref f) => writeArea(d, f, a));
			}
			foreach (a; battles) { mixin(S_TRACE);
				writeFile(a, "Battle" ~ to!(string)(a.id) ~ ".wid", (ref f) => writeBattle(d, f, a));
			}
			foreach (a; packages) { mixin(S_TRACE);
				writeFile(a, "Package" ~ to!(string)(a.id) ~ ".wid", (ref f) => writePackage(d, f, a));
			}
			foreach (c; casts) { mixin(S_TRACE);
				writeFile(c, "Mate" ~ to!(string)(c.id) ~ ".wid", (ref f) => writeCast(d, f, c));
			}
			foreach (c; skills) { mixin(S_TRACE);
				writeFile(c, "Skill" ~ to!(string)(c.id) ~ ".wid", (ref f) => writeSkill(d, f, c));
			}
			foreach (c; items) { mixin(S_TRACE);
				writeFile(c, "Item" ~ to!(string)(c.id) ~ ".wid", (ref f) => writeItem(d, f, c));
			}
			foreach (c; beasts) { mixin(S_TRACE);
				writeFile(c, "Beast" ~ to!(string)(c.id) ~ ".wid", (ref f) => writeBeast(d, f, c));
			}
			foreach (c; infos) { mixin(S_TRACE);
				writeFile(c, "Info" ~ to!(string)(c.id) ~ ".wid", (ref f) => writeInfo(d, f, c));
			}
			version (Console) {
				debug std.stdio.writeln("Exit Classic Save Thread");
			}
		}
	}

	auto save1 = new Save;
	auto save2 = new Save;
	save1.writeFile(summ, "Summary.wsm", (ref f) => writeSummary(save1.d, f, summ));
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
	save1.d.merge(save2.d);

	string comment = saveComment(save1.d);
	if (comment.length) { mixin(S_TRACE);
		auto file = "Comment.wex";
		.writeFile(save1.d.sPath.buildPath(file), cast(immutable byte[])comment, sync);
		save1.wids[file] = true;
	}
	string imageRef = saveImageRef(save1.d);
	if (imageRef.length) { mixin(S_TRACE);
		auto file = "ImageRef.wex";
		.writeFile(save1.d.sPath.buildPath(file), cast(immutable byte[])imageRef, sync);
		save1.wids[file] = true;
	}
	string cardRef = saveCardRef(save1.d);
	if (cardRef.length) { mixin(S_TRACE);
		auto file = "CardRef.wex";
		.writeFile(save1.d.sPath.buildPath(file), cast(immutable byte[])cardRef, sync);
		save1.wids[file] = true;
	}
	string templates = saveTemplate(summ);
	if (templates.length) { mixin(S_TRACE);
		auto file = "Template.wex";
		.writeFile(save1.d.sPath.buildPath(file), cast(immutable byte[])templates, sync);
		save1.wids[file] = true;
	}

	foreach (file; .clistdir(scenarioPath)) { mixin(S_TRACE);
		if (!std.regex.match(file, SYS_FNAME).empty && file !in save1.wids && file !in save2.wids) { mixin(S_TRACE);
		auto path = std.path.buildPath(scenarioPath, file);
			if (canBackup) { mixin(S_TRACE);
				if (!opt.backupDir.exists()) opt.backupDir.mkdirRecurse();
				path.rename(opt.backupDir.buildPath(file));
			} else { mixin(S_TRACE);
				preRemove(path);
				std.file.remove(path);
			}
		}
	}
}

/// 拡張情報"Comment.wex"を保存する。
string saveComment(in SData d) { mixin(S_TRACE);
	if (!d.comment.length) return "";
	auto node = XNode.create("comments");
	node.newAttr("dataVersion", 1);
	foreach (cwxPath; std.algorithm.sort(d.comment.keys)) { mixin(S_TRACE);
		auto e = node.newElement("comment", d.comment[cwxPath]);
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
	foreach (cwxPath; std.algorithm.sort(d.imageRef.keys)) { mixin(S_TRACE);
		auto e = node.newElement("imageRef", encodePath(d.imageRef[cwxPath]));
		e.newAttr("path", cwxPath);
	}
	return node.text;
}
/// 拡張情報"CardRef.wex"を保存する。
string saveCardRef(in SData d) { mixin(S_TRACE);
	if (!d.cardRef.length && !d.maxNest.length) return "";
	auto node = XNode.create("cardRefs");
	node.newAttr("dataVersion", 1);
	foreach (cwxPath; std.algorithm.sort(d.maxNest.keys)) { mixin(S_TRACE);
		auto e = node.newElement("maxNest", .text(d.maxNest[cwxPath]));
		e.newAttr("path", cwxPath);
	}
	foreach (cwxPath; std.algorithm.sort(d.cardRef.keys)) { mixin(S_TRACE);
		auto e = node.newElement("cardRef", .text(d.cardRef[cwxPath]));
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

/// 保存用の拡張データ情報をdへ記録する。
void putExData(ref SData d, CWXPath cp) { mixin(S_TRACE);
	while (true) { mixin(S_TRACE);
		void putInnerImagePath(ref SData d, CWXPath cp, in CardImage imgPath) { mixin(S_TRACE);
			if (!d.saveInnerImagePath) return;
			if (imgPath.type !is CardImageType.File) return;
			if (!imgPath.path.length) return;
			if (isBinImg(imgPath.path)) return;
			d.imageRef[cp.cwxPath(true)] = encodePathLegacy(imgPath.path);
		}
		if (auto summ = cast(Summary)cp) { mixin(S_TRACE);
			auto paths = summ.imagePaths;
			if (paths.length) putInnerImagePath(d, cp, paths[0]);
		} else if (auto m = cast(Motion)cp) { mixin(S_TRACE);
			if (Motion.maxNest_init != m.maxNest) { mixin(S_TRACE);
				d.maxNest[m.cwxPath(true)] = m.maxNest;
			}
		} else if (auto e = cast(Content)cp) { mixin(S_TRACE);
			if (e.comment.length) { mixin(S_TRACE);
				d.comment[e.cwxPath(true)] = e.comment;
			}
		} else if (auto c = cast(Card)cp) { mixin(S_TRACE);
			auto paths = c.paths;
			if (paths.length) putInnerImagePath(d, cp, paths[0]);
			if (auto ec = cast(EffectCard)cp) { mixin(S_TRACE);
				if (0 != ec.linkId) {
					d.cardRef[ec.cwxPath(true)] = ec.linkId;
				}
			}
		}
		auto children = cp.cwxChilds;
		if (children.length == 1) { mixin(S_TRACE);
			// 再帰回避
			cp = children[0];
			continue;
		}
		foreach (child; children) { mixin(S_TRACE);
			putExData(d, child);
		}
		break;
	}
}

private byte fromTargetT(Target v) { mixin(S_TRACE);
	switch (v.m) {
	case Target.M.Selected: return 0;
	case Target.M.Random: return 1;
	case Target.M.Unselected: return 2;
	default: throw new SummaryException("Unknown target T value: " ~ to!(string)(cast(int)v.m));
	}
}
private byte fromTargetA(Target v) { mixin(S_TRACE);
	if (v.m == Target.M.Unselected) throw new SummaryException("Unknown target A value with sleep: " ~ to!(string)(cast(int)v.m));
	if (v.sleep) { mixin(S_TRACE);
		switch (v.m) {
		case Target.M.Selected: return 3;
		case Target.M.Random: return 4;
		case Target.M.Party: return 5;
		default: throw new SummaryException("Unknown target A value with sleep: " ~ to!(string)(cast(int)v.m));
		}
	} else { mixin(S_TRACE);
		switch (v.m) {
		case Target.M.Selected: return 0;
		case Target.M.Random: return 1;
		case Target.M.Party: return 2;
		default: throw new SummaryException("Unknown target A value: " ~ to!(string)(cast(int)v.m));
		}
	}
}

private byte fromEffectType(EffectType v) { mixin(S_TRACE);
	switch (v) {
	case EffectType.Physic: return 0;
	case EffectType.Magic: return 1;
	case EffectType.MagicalPhysic: return 2;
	case EffectType.PhysicalMagic: return 3;
	case EffectType.None: return 4;
	default: throw new SummaryException("Unknown effect type value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromResist(Resist v) { mixin(S_TRACE);
	switch (v) {
	case Resist.Avoid: return 0;
	case Resist.Resist: return 1;
	case Resist.Unfail: return 2;
	default: throw new SummaryException("Unknown resist value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromCardVisual(CardVisual v) { mixin(S_TRACE);
	switch (v) {
	case CardVisual.None: return 0;
	case CardVisual.Reverse: return 1;
	case CardVisual.Horizontal: return 2;
	case CardVisual.Vertical: return 3;
	default: throw new SummaryException("Unknown card visual value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromRange(Range v) { mixin(S_TRACE);
	final switch (v) {
	case Range.Selected: return 0;
	case Range.Random: return 1;
	case Range.Party: return 2;
	case Range.Backpack: return 3;
	case Range.PartyAndBackpack: return 4;
	case Range.Field: return 5;
	case Range.CouponHolder: return 0; // Wsn.2
	case Range.CardTarget: return 0; // Wsn.2
	case Range.SelectedCard: return 0; // Wsn.3
	}
}
private byte fromRangeEffectContent(Range v) { mixin(S_TRACE);
	final switch (v) {
	case Range.Selected: return 0;
	case Range.Random: return 1;
	case Range.Party: return 2;
	case Range.Backpack: return 0;
	case Range.PartyAndBackpack: return 0;
	case Range.Field: return 0;
	case Range.CouponHolder: return 0;
	case Range.CardTarget: return 3;
	case Range.SelectedCard: return 0;
	}
}
/// CardWirth 1.50
private byte fromKeyCodeRange(Range v) { mixin(S_TRACE);
	switch (v) {
	case Range.Selected: return 0;
	case Range.Random: return 1;
	case Range.Backpack: return 2;
	case Range.PartyAndBackpack: return 3;
	case Range.CouponHolder: return 0; // Wsn.2
	case Range.SelectedCard: return 0; // Wsn.3
	default: throw new SummaryException("Unknown range value: " ~ to!(string)(cast(int)v));
	}
}
/// CardWirth Extender 1.30～
private byte fromCouponRange(Range v) { mixin(S_TRACE);
	switch (v) {
	case Range.Selected: return 0;
	case Range.Random: return 1;
	case Range.Party: return 2;
	case Range.Field: return 3;
	default: throw new SummaryException("Unknown range value: " ~ to!(string)(cast(int)v));
	}
}
/// CardWirth Extender 1.30～
private byte fromCastRanges(in CastRange[] v) { mixin(S_TRACE);
	byte r = 0;
	foreach (e; v) { mixin(S_TRACE);
		switch (e) {
		case CastRange.Party: r |= 0b0001; break;
		case CastRange.Enemy: r |= 0b0010; break;
		case CastRange.Npc:   r |= 0b0100; break;
		default: throw new SummaryException("Unknown cast range value: " ~ to!(string)(cast(int)e));
		}
	}
	return r;
}
/// CardWirth 1.50
private byte fromEffectCardType(EffectCardType v) { mixin(S_TRACE);
	switch (v) {
	case EffectCardType.All: return 0;
	case EffectCardType.Skill: return 1;
	case EffectCardType.Item: return 2;
	case EffectCardType.Beast: return 3;
	case EffectCardType.Hand: assert (0);
	default: throw new SummaryException("Unknown range value: " ~ to!(string)(cast(int)v));
	}
}
/// CardWirth 1.50
private byte fromComparison4(Comparison4 v) { mixin(S_TRACE);
	switch (v) {
	case Comparison4.Eq: return 0;
	case Comparison4.Ne: return 1;
	case Comparison4.Lt: return 2;
	case Comparison4.Gt: return 3;
	default: throw new SummaryException("Unknown 4 way comparison value: " ~ to!(string)(cast(int)v));
	}
}
/// CardWirth 1.50
private byte fromComparison3(Comparison3 v) { mixin(S_TRACE);
	switch (v) {
	case Comparison3.Eq: return 0;
	case Comparison3.Lt: return 1;
	case Comparison3.Gt: return 2;
	default: throw new SummaryException("Unknown 3 way comparison value: " ~ to!(string)(cast(int)v));
	}
}
/// CardWirth 1.50
private byte fromBorderingType(BorderingType v) { mixin(S_TRACE);
	switch (v) {
	case BorderingType.Outline: return 0;
	case BorderingType.Inline: return 1;
	default: throw new SummaryException("Unknown bordering type value: " ~ to!(string)(cast(int)v));
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
	default: throw new SummaryException("Unknown blend mode value: " ~ to!(string)(cast(int)v));
	}
}
/// CardWirth 1.50
private byte fromGradientDir(GradientDir v) { mixin(S_TRACE);
	switch (v) {
	case GradientDir.None: return 0;
	case GradientDir.LeftToRight: return 1;
	case GradientDir.TopToBottom: return 2;
	default: throw new SummaryException("Unknown gradient direction value: " ~ to!(string)(cast(int)v));
	}
}
/// Wsn.1
private byte fromCoordinateType(CoordinateType v) { mixin(S_TRACE);
	switch (v) {
	case CoordinateType.Absolute: return 0;
	case CoordinateType.Relative: return 1;
	case CoordinateType.Percentage: return 2;
	default: throw new SummaryException("Unknown coordinate type value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromStatus(Status v) { mixin(S_TRACE);
	switch (v) {
	case Status.Active: return 0;
	case Status.Inactive: return 1;
	case Status.Alive: return 2;
	case Status.Dead: return 3;
	case Status.Fine: return 4;
	case Status.Injured: return 5;
	case Status.HeavyInjured: return 6;
	case Status.Unconscious: return 7;
	case Status.Poison: return 8;
	case Status.Sleep: return 9;
	case Status.Bind: return 10;
	case Status.Paralyze: return 11;
	case Status.Confuse: return 12;
	case Status.Overheat: return 13;
	case Status.Brave: return 14;
	case Status.Panic: return 15;
	case Status.Silence: return 16;
	case Status.FaceUp: return 17;
	case Status.AntiMagic: return 18;
	case Status.UpAction: return 19;
	case Status.UpAvoid: return 20;
	case Status.UpResist: return 21;
	case Status.UpDefense: return 22;
	case Status.DownAction: return 23;
	case Status.DownAvoid: return 24;
	case Status.DownResist: return 25;
	case Status.DownDefense: return 26;
	default: throw new SummaryException("Unknown status value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromElement(Element v) { mixin(S_TRACE);
	switch (v) {
	case Element.All: return 0;
	case Element.Health: return 1;
	case Element.Mind: return 2;
	case Element.Miracle: return 3;
	case Element.Magic: return 4;
	case Element.Fire: return 5;
	case Element.Ice: return 6;
	default: throw new SummaryException("Unknown element value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromDamageType(DamageType v) { mixin(S_TRACE);
	switch (v) {
	case DamageType.LevelRatio: return 0;
	case DamageType.Normal: return 1;
	case DamageType.Max: return 2;
	default: throw new SummaryException("Unknown damage type value: " ~ to!(string)(cast(int)v));
	}
}
private uint fromPhysical(Physical v) { mixin(S_TRACE);
	switch (v) {
	case Physical.Dex: return 0;
	case Physical.Agl: return 1;
	case Physical.Int: return 2;
	case Physical.Str: return 3;
	case Physical.Vit: return 4;
	case Physical.Min: return 5;
	default: throw new SummaryException("Unknown pysical value: " ~ to!(string)(cast(int)v));
	}
}
private int fromMental(Mental v) { mixin(S_TRACE);
	switch (v) {
	case Mental.Aggressive: return 1;
	case Mental.Cheerful: return 2;
	case Mental.Brave: return 3;
	case Mental.Cautious: return 4;
	case Mental.Trickish: return 5;
	case Mental.Unaggressive: return -1;
	case Mental.Uncheerful: return -2;
	case Mental.Unbrave: return -3;
	case Mental.Uncautious: return -4;
	case Mental.Untrickish: return -5;
	default: throw new SummaryException("Unknown mental value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromMentality(Mentality v) { mixin(S_TRACE);
	switch (v) {
	case Mentality.Normal: return 0;
	case Mentality.Sleep: return 1;
	case Mentality.Confuse: return 2;
	case Mentality.Overheat: return 3;
	case Mentality.Brave: return 4;
	case Mentality.Panic: return 5;
	default: throw new SummaryException("Unknown mentality value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromCardTarget(CardTarget v) { mixin(S_TRACE);
	switch (v) {
	case CardTarget.None: return 0;
	case CardTarget.User: return 1;
	case CardTarget.Party: return 2;
	case CardTarget.Enemy: return 3;
	case CardTarget.Both: return 4;
	default: throw new SummaryException("Unknown card target value: " ~ to!(string)(cast(int)v));
	}
}
private byte fromPremium(Premium v) { mixin(S_TRACE);
	switch (v) {
	case Premium.Normal: return 0;
	case Premium.Rare: return 1;
	case Premium.Premium: return 2;
	default: throw new SummaryException("Unknown card premium value: " ~ to!(string)(cast(int)v));
	}
}
private const B_IMG_REF = ":INNER_BINARY_IMAGE";
private void writeBool(ref ByteIO f, bool b) { mixin(S_TRACE);
	f.writeL(cast(byte)(b ? 1 : 0));
}
private void writeExImage(ref SData d, ref ByteIO f, CWXPath cp, string imgPath) { mixin(S_TRACE);
	writeImageImpl(d, f, cp, imgPath, (val) => f.writeExUInt(val));
}
private void writeImage(ref SData d, ref ByteIO f, CWXPath cp, string imgPath) { mixin(S_TRACE);
	writeImageImpl(d, f, cp, imgPath, &f.writeL);
}
private void writeImageImpl(ref SData d, ref ByteIO f, CWXPath cp, string imgPath, void delegate(uint) writeSize) { mixin(S_TRACE);
	if (!imgPath.length) { mixin(S_TRACE);
		writeSize(cast(uint)0);
		return;
	}
	ubyte* ptr = null;
	scope (exit) {
		if (ptr) freeAll(ptr);
	}
	ubyte[] bytes;
	if (isBinImg(imgPath)) { mixin(S_TRACE);
		bytes = cast(ubyte[]) strToBImg(imgPath);
	} else { mixin(S_TRACE);
		auto path = d.skin.findImagePath(imgPath, d.sPath, "");
		if (exists(path)) { mixin(S_TRACE);
			bytes = readBinaryFrom!ubyte(path, ptr);
		}
		if (d.saveInnerImagePath) { mixin(S_TRACE);
			d.imageRef[cp.cwxPath(true)] = encodePathLegacy(imgPath);
		}
	}
	writeSize(cast(uint)bytes.length);
	f.write(bytes);
}
private void writeExString(ref ByteIO f, string str, bool lns = false, bool cutText = false) { mixin(S_TRACE);
	writeStringImpl(f, str, lns, cutText, (val) => f.writeExUInt(val));
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
		writeSize(cast(uint)str.length);
		f.writeL(cast(ubyte[])str);
	} else { mixin(S_TRACE);
		if (lns) { mixin(S_TRACE);
			writeSize(cast(uint)0);
		} else { mixin(S_TRACE);
			writeSize(cast(uint)1);
			f.writeL(cast(char)0x0);
		}
	}
}
private void writeExStrings(ref ByteIO f, string[] strs) { mixin(S_TRACE);
	if (strs.length) { mixin(S_TRACE);
		auto s = std.string.join(strs, "\n");
		if (s.length && s[$ - 1] != '\n') s ~= '\n';
		writeExString(f, s, true);
	} else { mixin(S_TRACE);
		writeExString(f, "", true);
	}
}
private void writeStrings(ref ByteIO f, string[] strs) { mixin(S_TRACE);
	if (strs.length) { mixin(S_TRACE);
		auto s = std.string.join(strs, "\n");
		if (s.length && s[$ - 1] != '\n') s ~= '\n';
		writeString(f, s, true);
	} else { mixin(S_TRACE);
		f.writeL(cast(uint)0);
	}
}

private void writeSummary(ref SData d, ref ByteIO f, Summary summ) { mixin(S_TRACE);
	auto paths = summ.imagePaths;
	writeImage(d, f, summ, paths.length && paths[0].type is CardImageType.File ? paths[0].path : "");
	writeString(f, summ.scenarioName);
	writeString(f, summ.desc, true);
	writeString(f, summ.author);
	writeStrings(f, summ.rCoupons);
	f.writeL(cast(uint)summ.rCouponNum);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(uint)(summ.startArea + 40000u));
		auto steps = summ.flagDirRoot.allSteps;
		f.writeL(cast(uint)steps.length);
		void putStep(Step step) { mixin(S_TRACE);
			writeString(f, step.path);
			f.writeL((step.select < 10u) ? cast(uint)step.select : (10u - 1u));
			for (uint i = 0u; i < 10u; i++) { mixin(S_TRACE);
				if (i < step.count) { mixin(S_TRACE);
					writeString(f, step.getValue(i));
				} else { mixin(S_TRACE);
					writeString(f, "Step - " ~ to!(string)(i + 1u));
				}
			}
		}
		.sortedWithPath(steps, d.logicalSort, &putStep);
		auto flags = summ.flagDirRoot.allFlags;
		f.writeL(cast(uint)flags.length);
		void putFlag(Flag flag) { mixin(S_TRACE);
			writeString(f, flag.path);
			writeBool(f, flag.onOff);
			writeString(f, flag.on);
			writeString(f, flag.off);
		}
		.sortedWithPath(flags, d.logicalSort, &putFlag);
		f.writeL(cast(uint)0u);
		f.writeL(cast(uint)summ.levelMin);
		f.writeL(cast(uint)summ.levelMax);
	} else { mixin(S_TRACE);
		f.writeL(cast(uint)(summ.startArea + 70000u));
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		f.write(cast(byte)0); // 不明(0)
		auto steps = summ.flagDirRoot.allSteps;
		f.writeExUInt(cast(uint)steps.length);
		void putStepEx(Step step) { mixin(S_TRACE);
			writeExString(f, step.path);
			ubyte type = 1;
			if (step.expandSPChars) { mixin(S_TRACE);
				type |= 0b10000000;
				f.write(type);
				f.write(cast(ubyte)2);
			} else { mixin(S_TRACE);
				f.write(type);
			}

			f.writeExUInt(step.count);
			foreach (i; 0 .. step.count) { mixin(S_TRACE);
				writeExString(f, step.getValue(i));
			}
			f.writeExUInt(step.select);
		}
		.sortedWithPath(steps, d.logicalSort, &putStepEx);
		auto flags = summ.flagDirRoot.allFlags;
		f.writeExUInt(cast(uint)flags.length);
		void putFlagEx(Flag flag) { mixin(S_TRACE);
			writeExString(f, flag.path);
			writeBool(f, flag.onOff);
			writeExString(f, flag.on);
			writeExString(f, flag.off);
		}
		.sortedWithPath(flags, d.logicalSort, &putFlagEx);
		f.writeExUInt(summ.levelMin);
		f.writeExUInt(summ.levelMax);
	}
}
private void writeMotion(ref SData d, ref ByteIO f, Motion m) { mixin(S_TRACE);
	byte tType;
	byte type;
	switch (m.type) {
	case MType.Heal:
		tType = 0;
		type = 0;
		break;
	case MType.Damage:
		tType = 0;
		type = 1;
		break;
	case MType.Absorb:
		tType = 0;
		type = 2;
		break;
	case MType.Paralyze:
		tType = 1;
		type = 0;
		break;
	case MType.DisParalyze:
		tType = 1;
		type = 1;
		break;
	case MType.Poison:
		tType = 1;
		type = 2;
		break;
	case MType.DisPoison:
		tType = 1;
		type = 3;
		break;
	case MType.GetSkillPower:
		tType = 2;
		type = 0;
		break;
	case MType.LoseSkillPower:
		tType = 2;
		type = 1;
		break;
	case MType.Sleep:
		tType = 3;
		type = 0;
		break;
	case MType.Confuse:
		tType = 3;
		type = 1;
		break;
	case MType.Overheat:
		tType = 3;
		type = 2;
		break;
	case MType.Brave:
		tType = 3;
		type = 3;
		break;
	case MType.Panic:
		tType = 3;
		type = 4;
		break;
	case MType.Normal:
		tType = 3;
		type = 5;
		break;
	case MType.Bind:
		tType = 4;
		type = 0;
		break;
	case MType.DisBind:
		tType = 4;
		type = 1;
		break;
	case MType.Silence:
		tType = 4;
		type = 2;
		break;
	case MType.DisSilence:
		tType = 4;
		type = 3;
		break;
	case MType.FaceUp:
		tType = 4;
		type = 4;
		break;
	case MType.FaceDown:
		tType = 4;
		type = 5;
		break;
	case MType.AntiMagic:
		tType = 4;
		type = 6;
		break;
	case MType.DisAntiMagic:
		tType = 4;
		type = 7;
		break;
	case MType.EnhanceAction:
		tType = 5;
		type = 0;
		break;
	case MType.EnhanceAvoid:
		tType = 5;
		type = 1;
		break;
	case MType.EnhanceResist:
		tType = 5;
		type = 2;
		break;
	case MType.EnhanceDefense:
		tType = 5;
		type = 3;
		break;
	case MType.VanishTarget:
		tType = 6;
		type = 0;
		break;
	case MType.VanishCard:
		tType = 6;
		type = 1;
		break;
	case MType.VanishBeast:
		tType = 6;
		type = 2;
		break;
	case MType.DealAttackCard:
		tType = 7;
		type = 0;
		break;
	case MType.DealPowerfulAttackCard:
		tType = 7;
		type = 1;
		break;
	case MType.DealCriticalAttackCard:
		tType = 7;
		type = 2;
		break;
	case MType.DealFeintCard:
		tType = 7;
		type = 3;
		break;
	case MType.DealDefenseCard:
		tType = 7;
		type = 4;
		break;
	case MType.DealDistanceCard:
		tType = 7;
		type = 5;
		break;
	case MType.DealConfuseCard:
		tType = 7;
		type = 6;
		break;
	case MType.DealSkillCard:
		tType = 7;
		type = 7;
		break;
	case MType.SummonBeast:
		tType = 8;
		type = 0;
		break;
	case MType.CancelAction: // CardWirth 1.50
		tType = 7;
		type = 8;
		break;
	case MType.NoEffect: // Wsn.2(ダメージに変換)
		tType = 0;
		type = 1;
		break;
	default: assert (0);
	}
	f.write(tType);
	f.writeL(cast(byte)0x8);
	f.writeL(cast(byte)0x4);
	f.writeL(cast(byte)0x0);
	f.writeL(cast(byte)0x0);
	f.writeL(cast(byte)0x0);
	f.write(fromElement(m.element));
	if (tType != 8) { mixin(S_TRACE);
		f.write(type);
	}
	switch (tType) {
	case 0, 1:
		f.write(fromDamageType(m.damageType));
		f.writeL(cast(uint)m.uValue);
		break;
	case 2:
		break;
	case 3, 4:
		f.writeL(cast(uint)m.detail.use(MArg.Round) ? m.round : 0xA);
		break;
	case 5:
		f.writeL(cast(uint)m.aValue);
		f.writeL(cast(uint)m.round);
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
					f.writeL(cast(uint)0x1);
					writeBeast(d, f, beast);
				} else { mixin(S_TRACE);
					f.writeL(cast(uint)0x0);
				}
				if (1 >= nestCount) { mixin(S_TRACE);
					d.nestCount.remove(beast.linkId);
				} else { mixin(S_TRACE);
					d.nestCount[beast.linkId] = nestCount - 1;
				}
			} else { mixin(S_TRACE);
				f.writeL(cast(uint)0x1);
				writeBeast(d, f, beast);
			}
		} else { mixin(S_TRACE);
			f.writeL(cast(uint)0x0);
		}
		break;
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private void writeContent(ref SData d, ref ByteIO f, Content e2) { mixin(S_TRACE);
	Content[] lazys;
	while (true) { mixin(S_TRACE);
		byte type;
		final switch (e2.type) {
		case CType.Start: type = 0; break;
		case CType.LinkStart: type = 1; break;
		case CType.StartBattle: type = 2; break;
		case CType.End: type = 3; break;
		case CType.EndBadEnd: type = 4; break;
		case CType.ChangeArea: type = 5; break;
		case CType.TalkMessage: type = 6; break;
		case CType.PlayBgm: type = 7; break;
		case CType.ChangeBgImage: type = 8; break;
		case CType.PlaySound: type = 9; break;
		case CType.Wait: type = 10; break;
		case CType.Effect: type = 11; break;
		case CType.BranchSelect: type = 12; break;
		case CType.BranchAbility: type = 13; break;
		case CType.BranchRandom: type = 14; break;
		case CType.BranchFlag: type = 15; break;
		case CType.SetFlag: type = 16; break;
		case CType.BranchMultiStep: type = 17; break;
		case CType.SetStep: type = 18; break;
		case CType.BranchCast: type = 19; break;
		case CType.BranchItem: type = 20; break;
		case CType.BranchSkill: type = 21; break;
		case CType.BranchInfo: type = 22; break;
		case CType.BranchBeast: type = 23; break;
		case CType.BranchMoney: type = 24; break;
		case CType.BranchCoupon: type = 25; break;
		case CType.GetCast: type = 26; break;
		case CType.GetItem: type = 27; break;
		case CType.GetSkill: type = 28; break;
		case CType.GetInfo: type = 29; break;
		case CType.GetBeast: type = 30; break;
		case CType.GetMoney: type = 31; break;
		case CType.GetCoupon: type = 32; break;
		case CType.LoseCast: type = 33; break;
		case CType.LoseItem: type = 34; break;
		case CType.LoseSkill: type = 35; break;
		case CType.LoseInfo: type = 36; break;
		case CType.LoseBeast: type = 37; break;
		case CType.LoseMoney: type = 38; break;
		case CType.LoseCoupon: type = 39; break;
		case CType.TalkDialog: type = 40; break;
		case CType.SetStepUp: type = 41; break;
		case CType.SetStepDown: type = 42; break;
		case CType.ReverseFlag: type = 43; break;
		case CType.BranchStep: type = 44; break;
		case CType.ElapseTime: type = 45; break;
		case CType.BranchLevel: type = 46; break;
		case CType.BranchStatus: type = 47; break;
		case CType.BranchPartyNumber: type = 48; break;
		case CType.ShowParty: type = 49; break;
		case CType.HideParty: type = 50; break;
		case CType.EffectBreak: type = 51; break;
		case CType.CallStart: type = 52; break;
		case CType.LinkPackage: type = 53; break;
		case CType.CallPackage: type = 54; break;
		case CType.BranchArea: type = 55; break;
		case CType.BranchBattle: type = 56; break;
		case CType.BranchCompleteStamp: type = 57; break;
		case CType.GetCompleteStamp: type = 58; break;
		case CType.LoseCompleteStamp: type = 59; break;
		case CType.BranchGossip: type = 60; break;
		case CType.GetGossip: type = 61; break;
		case CType.LoseGossip: type = 62; break;
		case CType.BranchIsBattle: type = 63; break;
		case CType.Redisplay: type = 64; break;
		case CType.CheckFlag: type = 65; break;
		case CType.SubstituteStep: type = 66; break;
		case CType.SubstituteFlag: type = 67; break;
		case CType.BranchStepCmp: type = 68; break;
		case CType.BranchFlagCmp: type = 69; break;
		case CType.BranchRandomSelect: type = 70; break;
		case CType.BranchKeyCode: type = 71; break;
		case CType.CheckStep: type = 72; break;
		case CType.BranchRound: type = 73; break;
		case CType.MoveBgImage: type = d.opt.dataVersion < 7 ? 6 : 74; break; // Wsn.1
		case CType.LoseBgImage: type = d.opt.dataVersion < 7 ? 6 : 75; break; // Wsn.1
		case CType.ReplaceBgImage: type = d.opt.dataVersion < 7 ? 6 : 76; break; // Wsn.1
		case CType.BranchMultiCoupon: type = 6; break; // Wsn.2
		case CType.BranchMultiRandom: type = 6; break; // Wsn.2
		case CType.MoveCard: type = d.opt.dataVersion < 7 ? 6 : 77; break; // Wsn.3
		case CType.ChangeEnvironment: type = d.opt.dataVersion < 7 ? 6 : 78; break; // Wsn.4
		case CType.BranchVariant: type = 6; break; // Wsn.4
		case CType.SetVariant: type = 6; break; // Wsn.4
		case CType.CheckVariant: type = 6; break; // Wsn.4
		}
		f.write(type);
		string name = e2.name;
		writeString(f, name);
		if (e2.comment.length) { mixin(S_TRACE);
			d.comment[e2.cwxPath(true)] = e2.comment;
		}
		lazys ~= e2;
		if (e2.detail.owner && e2.next.length) { mixin(S_TRACE);
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)(40000 + e2.next.length));
			} else { mixin(S_TRACE);
				f.writeL(cast(uint)(70000 + e2.next.length));
			}
			if (e2.next.length == 1) { mixin(S_TRACE);
				e2 = e2.next[0];
			} else { mixin(S_TRACE);
				foreach (child; e2.next) { mixin(S_TRACE);
					writeContent(d, f, child);
				}
				break;
			}
		} else { mixin(S_TRACE);
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)40000);
			} else { mixin(S_TRACE);
				f.writeL(cast(uint)70000);
			}
			break;
		}
	}
	foreach_reverse (e; lazys) { mixin(S_TRACE);
		final switch (e.type) {
		case CType.Start:
			break;
		case CType.LinkStart:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.start);
			} else { mixin(S_TRACE);
				writeExString(f, e.start);
			}
			break;
		case CType.StartBattle:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.battle);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.battle);
			}
			break;
		case CType.End:
			writeBool(f, e.complete);
			break;
		case CType.EndBadEnd:
			break;
		case CType.ChangeArea:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.area);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.area);
			}
			break;
		case CType.TalkMessage:
			string path = "";
			if (e.cardPaths.length) { mixin(S_TRACE);
				auto imgPath = e.cardPaths[0];
				final switch (imgPath.type) {
				case CardImageType.File:
					path = encodePathLegacy(imgPath.path);
					break;
				case CardImageType.PCNumber:
					// 非対応
					break;
				case CardImageType.Talker:
					path = "??" ~ fromTalker(imgPath.talker);
					break;
				}
			}
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, path);
				writeString(f, lastRet(e.text), true);
			} else { mixin(S_TRACE);
				ubyte tb = 0;
				if (path != "") tb |= 0b00000001;
				if (1 < e.selectionColumns) tb |= 0b10000000;
				f.write(tb);
				if (path != "") writeExString(f, path);
				writeExString(f, lastRet(e.text), true);
				if (1 < e.selectionColumns) f.writeExUInt(e.selectionColumns);
			}
			break;
		case CType.PlayBgm:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, encodePathLegacy(e.bgmPath));
			} else { mixin(S_TRACE);
				writeExString(f, encodePathLegacy(e.bgmPath));
			}
			break;
		case CType.ChangeBgImage:
			writeBgImages(d, f, e.backs);
			break;
		case CType.PlaySound:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, encodePathLegacy(e.soundPath));
			} else { mixin(S_TRACE);
				writeExString(f, encodePathLegacy(e.soundPath));
			}
			break;
		case CType.Wait:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.wait);
			} else { mixin(S_TRACE);
				f.writeExInt(e.wait);
			}
			break;
		case CType.Effect:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(int)e.signedLevel);
				byte targ = fromRange(e.range);
				f.write(targ);
				f.write(fromEffectType(e.effectType));
				f.write(fromResist(e.resist));
				f.writeL(cast(int)e.successRate);
				writeString(f, e.soundPath.length ? encodePathLegacy(e.soundPath) : "（なし）");
				f.write(fromCardVisual(e.cardVisual));
				f.writeL(cast(uint)e.motions.length);
			} else { mixin(S_TRACE);
				f.writeExInt(e.signedLevel);
				byte targ = fromRangeEffectContent(e.range);
				f.write(targ);
				f.write(fromEffectType(e.effectType));
				f.write(fromResist(e.resist));
				f.writeExInt(e.successRate);
				f.write(cast(ubyte)1); // パス指定
				writeExString(f, e.soundPath.length ? encodePathLegacy(e.soundPath) : "（なし）");
				f.write(fromCardVisual(e.cardVisual));
				f.writeExUInt(cast(uint)e.motions.length);
			}
			foreach (m; e.motions) { mixin(S_TRACE);
				writeMotion(d, f, m);
			}
			break;
		case CType.BranchSelect:
			writeBool(f, e.targetAll);
			writeBool(f, e.selectionMethod is SelectionMethod.Random);
			break;
		case CType.BranchAbility:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(int)e.signedLevel);
				f.write(fromTargetA(e.targetS));
				f.writeL(cast(uint)fromPhysical(e.physical));
				f.writeL(cast(int)fromMental(e.mental));
			} else { mixin(S_TRACE);
				f.writeExInt(e.signedLevel);
				f.write(fromTargetA(e.targetS));
				f.writeExInt(fromPhysical(e.physical));
				f.writeExInt(fromMental(e.mental));
			}
			break;
		case CType.BranchRandom:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.percent);
			} else { mixin(S_TRACE);
				f.writeExUInt(e.percent);
			}
			break;
		case CType.BranchFlag:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.flag);
			} else { mixin(S_TRACE);
				writeExString(f, e.flag);
			}
			break;
		case CType.SetFlag:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.flag);
			} else { mixin(S_TRACE);
				writeExString(f, e.flag);
			}
			writeBool(f, e.flagValue);
			break;
		case CType.BranchMultiStep:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
			}
			break;
		case CType.SetStep:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
				f.writeL(e.stepValue < 10u ? cast(uint)e.stepValue : 10u - 1u);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
				f.writeExInt(e.stepValue);
			}
			break;
		case CType.BranchCast:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.casts);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.casts);
			}
			break;
		case CType.BranchItem:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.item);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.item);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.BranchSkill:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.skill);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.skill);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.BranchInfo:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.info);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.info);
			}
			break;
		case CType.BranchBeast:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.beast);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.beast);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.BranchMoney:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.money);
			} else { mixin(S_TRACE);
				f.writeExUInt(e.money);
			}
			break;
		case CType.BranchCoupon:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.couponNames.length ? e.couponNames[0] : "");
				f.writeL(cast(int)0x0);
				f.write(fromCouponRange(e.range));
			} else { mixin(S_TRACE);
				writeExString(f, e.couponNames.length ? e.couponNames[0] : "");
				f.writeExInt(0x0);
				f.write(fromCouponRange(e.range));
				writeBool(f, e.invertResult);
			}
			break;
		case CType.GetCast:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.casts);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.casts);
			}
			break;
		case CType.GetItem:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.item);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.item);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.GetSkill:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.skill);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.skill);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.GetInfo:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.info);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.info);
			}
			break;
		case CType.GetBeast:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.beast);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.beast);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.GetMoney:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.money);
			} else { mixin(S_TRACE);
				f.writeExUInt(e.money);
			}
			break;
		case CType.GetCoupon:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.coupon);
				f.writeL(cast(int)e.couponValue);
				f.write(fromRange(e.range));
			} else { mixin(S_TRACE);
				writeExString(f, e.coupon);
				f.writeExInt(e.couponValue);
				f.write(fromRange(e.range));
				writeBool(f, false); // 不所持条件
			}
			break;
		case CType.LoseCast:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.casts);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.casts);
			}
			break;
		case CType.LoseItem:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.item);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.item);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.LoseSkill:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.skill);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.skill);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.LoseInfo:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.info);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.info);
			}
			break;
		case CType.LoseBeast:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.beast);
				f.writeL(cast(uint)e.cardNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.beast);
				f.writeExUInt(e.cardNumber);
			}
			f.write(fromRange(e.range));
			break;
		case CType.LoseMoney:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.money);
			} else { mixin(S_TRACE);
				f.writeExUInt(e.money);
			}
			break;
		case CType.LoseCoupon:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.coupon);
				f.writeL(cast(int)0x0);
				f.write(fromRange(e.range));
			} else { mixin(S_TRACE);
				writeExString(f, e.coupon);
				f.writeExInt(0x0);
				f.write(fromRange(e.range));
				writeBool(f, false); // 不所持条件
			}
			break;
		case CType.TalkDialog:
			switch (e.talkerNC) {
			case Talker.Selected: f.write(cast(byte)0); break;
			case Talker.Random: f.write(cast(byte)1); break;
			case Talker.Unselected: f.write(cast(byte)2); break;
			case Talker.Valued: f.write(cast(byte)3); break;
			default: throw new SummaryException("Unknown talker value: " ~ to!(string)(cast(int)e.talkerNC));
			}
			Coupon[] coupons;
			if (Talker.Valued == e.talkerNC) { mixin(S_TRACE);
				bool[string] cSet;
				foreach (cc; e.coupons) { mixin(S_TRACE);
					auto name2 = cc.name.tosjis().touni();
					if (name2 in cSet) continue;
					cSet[name2] = true;
					coupons ~= cc;
				}
			}
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				if (Talker.Valued == e.talkerNC) { mixin(S_TRACE);
					if (0 == e.initValue) { mixin(S_TRACE);
						f.writeL(cast(uint)coupons.length);
					} else { mixin(S_TRACE);
						f.writeL(cast(uint)coupons.length + 1);
						writeString(f, "");
						f.writeL(cast(int)e.initValue);
					}
					foreach (c; coupons) { mixin(S_TRACE);
						writeString(f, c.name);
						f.writeL(cast(int)c.value);
					}
				}
				f.writeL(cast(uint)e.dialogs.length);
				foreach (dlg; e.dialogs) { mixin(S_TRACE);
					writeStrings(f, dlg.rCoupons);
					writeString(f, lastRet(dlg.text), true);
				}
			} else { mixin(S_TRACE);
				if (Talker.Valued == e.talkerNC) { mixin(S_TRACE);
					if (0 == e.initValue) { mixin(S_TRACE);
						f.writeExUInt(cast(uint)coupons.length);
					} else { mixin(S_TRACE);
						f.writeExUInt(cast(uint)coupons.length + 1u);
						writeExString(f, "");
						f.writeExInt(e.initValue);
					}
					foreach (c; coupons) { mixin(S_TRACE);
						writeExString(f, c.name);
						f.writeExInt(c.value);
					}
				}
				f.writeExUInt(cast(uint)e.dialogs.length);
				foreach (dlg; e.dialogs) { mixin(S_TRACE);
					writeExStrings(f, dlg.rCoupons);
					writeExString(f, lastRet(dlg.text), true);
				}
				ubyte ob = 0;
				if (e.selectTalker) ob |= 0b00000001;
				if (1 < e.selectionColumns) ob |= 0b00000010;
				f.write(ob);
				if (1 < e.selectionColumns) f.write(cast(ubyte)e.selectionColumns);
			}
			break;
		case CType.SetStepUp:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
			}
			break;
		case CType.SetStepDown:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
			}
			break;
		case CType.ReverseFlag:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.flag);
			} else { mixin(S_TRACE);
				writeExString(f, e.flag);
			}
			break;
		case CType.BranchStep:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
				f.writeL(e.stepValue < 10u ? cast(uint)e.stepValue : 10u - 1u);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
				f.writeExInt(e.stepValue);
			}
			break;
		case CType.ElapseTime:
			break;
		case CType.BranchLevel:
			writeBool(f, e.average);
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.unsignedLevel);
			} else { mixin(S_TRACE);
				f.writeExUInt(e.unsignedLevel);
			}
			break;
		case CType.BranchStatus:
			f.write(fromStatus(e.status));
			f.write(fromRange(e.range));
			break;
		case CType.BranchPartyNumber:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.partyNumber);
			} else { mixin(S_TRACE);
				f.writeExUInt(e.partyNumber);
			}
			break;
		case CType.ShowParty:
			break;
		case CType.HideParty:
			break;
		case CType.EffectBreak:
			break;
		case CType.CallStart:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.start);
			} else { mixin(S_TRACE);
				writeExString(f, e.start);
			}
			break;
		case CType.LinkPackage:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.packages);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.packages);
			}
			break;
		case CType.CallPackage:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.packages);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)e.packages);
			}
			break;
		case CType.BranchArea:
			break;
		case CType.BranchBattle:
			break;
		case CType.BranchCompleteStamp:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.completeStamp);
			} else { mixin(S_TRACE);
				writeExString(f, e.completeStamp);
			}
			break;
		case CType.GetCompleteStamp:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.completeStamp);
			} else { mixin(S_TRACE);
				writeExString(f, e.completeStamp);
			}
			break;
		case CType.LoseCompleteStamp:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.completeStamp);
			} else { mixin(S_TRACE);
				writeExString(f, e.completeStamp);
			}
			break;
		case CType.BranchGossip:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.gossip);
			} else { mixin(S_TRACE);
				writeExString(f, e.gossip);
			}
			break;
		case CType.GetGossip:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.gossip);
			} else { mixin(S_TRACE);
				writeExString(f, e.gossip);
			}
			break;
		case CType.LoseGossip:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.gossip);
			} else { mixin(S_TRACE);
				writeExString(f, e.gossip);
			}
			break;
		case CType.BranchIsBattle:
			break;
		case CType.Redisplay:
			break;
		case CType.CheckFlag:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.flag);
			} else { mixin(S_TRACE);
				writeExString(f, e.flag);
			}
			break;
		case CType.SubstituteStep:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
				writeString(f, e.step2);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
				writeExString(f, e.step2);
			}
			break;
		case CType.SubstituteFlag:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.flag);
				writeString(f, e.flag2);
			} else { mixin(S_TRACE);
				writeExString(f, e.flag);
				writeExString(f, e.flag2);
			}
			break;
		case CType.BranchStepCmp:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
				writeString(f, e.step2);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
				writeExString(f, e.step2);
			}
			break;
		case CType.BranchFlagCmp:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.flag);
				writeString(f, e.flag2);
			} else { mixin(S_TRACE);
				writeExString(f, e.flag);
				writeExString(f, e.flag2);
			}
			break;
		case CType.BranchRandomSelect:
			f.write(fromCastRanges(e.castRange));
			ubyte style = 0b00;
			if (0 < e.levelMax) { mixin(S_TRACE);
				style |= 0b01;
			}
			if (e.status !is Status.None) { mixin(S_TRACE);
				style |= 0b10;
			}
			f.write(style);
			if (style & 0b01) { mixin(S_TRACE);
				if (d.opt.dataVersion < 7) { mixin(S_TRACE);
					f.writeL(cast(uint)e.levelMin);
					f.writeL(cast(uint)e.levelMax);
				} else { mixin(S_TRACE);
					f.writeExUInt(e.levelMin);
					f.writeExUInt(e.levelMax);
				}
			}
			if (style & 0b10) { mixin(S_TRACE);
				f.write(fromStatus(e.status));
			}
			break;
		case CType.BranchKeyCode:
			f.write(fromKeyCodeRange(e.keyCodeRange));
			if (e.targetIsSkill && e.targetIsItem && e.targetIsBeast) { mixin(S_TRACE);
				f.write(fromEffectCardType(EffectCardType.All));
			} else if (e.targetIsSkill) { mixin(S_TRACE);
				f.write(fromEffectCardType(EffectCardType.Skill));
			} else if (e.targetIsItem) { mixin(S_TRACE);
				f.write(fromEffectCardType(EffectCardType.Item));
			} else if (e.targetIsBeast) { mixin(S_TRACE);
				f.write(fromEffectCardType(EffectCardType.Beast));
			} else { mixin(S_TRACE);
				f.write(fromEffectCardType(EffectCardType.All));
			}
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.keyCode);
			} else { mixin(S_TRACE);
				writeExString(f, e.keyCode);
			}
			break;
		case CType.CheckStep:
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, e.step);
				f.writeL(e.stepValue < 10u ? cast(uint)e.stepValue : 10u - 1u);
			} else { mixin(S_TRACE);
				writeExString(f, e.step);
				f.writeExInt(e.stepValue);
			}
			f.write(fromComparison4(e.comparison4));
			break;
		case CType.BranchRound:
			f.write(fromComparison3(e.comparison3));
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)e.round);
			} else { mixin(S_TRACE);
				f.writeExUInt(e.round);
			}
			break;
		case CType.MoveBgImage:
			if (d.opt.dataVersion < 7) goto case CType.BranchMultiCoupon;
			writeExString(f, e.cellName);
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
			break;
		case CType.LoseBgImage:
			if (d.opt.dataVersion < 7) goto case CType.BranchMultiCoupon;
			writeExString(f, e.cellName);
			break;
		case CType.ReplaceBgImage:
			if (d.opt.dataVersion < 7) goto case CType.BranchMultiCoupon;
			writeExString(f, e.cellName);
			writeBgImages(d, f, e.backs, true);
			break;
		case CType.MoveCard: // Wsn.3
			if (d.opt.dataVersion < 7) goto case CType.BranchMultiCoupon;
			writeExString(f, e.cardGroup);
			writeBool(f, e.cardSpeed <= 1); // カード速度1以下はアニメーション無しとして扱う
			if (e.positionType is CoordinateType.None) { mixin(S_TRACE);
				f.writeBool(false);
			} else { mixin(S_TRACE);
				f.writeBool(true);
				f.write(fromCoordinateType(e.positionType));
				f.writeExInt(e.x);
				f.writeExInt(e.y);
			}
			break;
		case CType.ChangeEnvironment: // Wsn.3
			if (d.opt.dataVersion < 7) goto case CType.BranchMultiCoupon;
			ubyte fb = 0;
			final switch (e.backpackEnabled) {
			case EnvironmentStatus.NotSet:
				break;
			case EnvironmentStatus.Enable:
				break;
			case EnvironmentStatus.Disable:
				fb |= 0b00000001;
				break;
			}
			// セーブの制限 0b00000010
			// キャンプの制限 0b00000100
			f.write(fb);
			break;
		case CType.BranchMultiCoupon: // Wsn.2
		case CType.BranchMultiRandom: // Wsn.2
		case CType.BranchVariant: // Wsn.4
		case CType.SetVariant: // Wsn.4
		case CType.CheckVariant: // Wsn.4
			// 非対応コンテントはメッセージコンテントの内容に説明を書いたものに置換する
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				writeString(f, "");
				writeString(f, lastRet(d.prop.msgs.contentName(e.type)), true);
			} else { mixin(S_TRACE);
				f.write(cast(ubyte)0);
				writeExString(f, lastRet(d.prop.msgs.contentName(e.type)), true);
			}
			break;
		}
	}
}
private void writeCEventTree(ref SData d, ref ByteIO f, EventTree tree) { mixin(S_TRACE);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(uint)tree.starts.length);
	} else { mixin(S_TRACE);
		f.writeL(cast(uint)(tree.starts.length + 0x7000000));
	}
	foreach (evt; tree.starts) { mixin(S_TRACE);
		writeContent(d, f, evt);
	}
}
private void writeEventTree(ref SData d, ref ByteIO f, EventTree tree) { mixin(S_TRACE);
	int[] igs;
	if (tree.fireEnter) igs ~= 1;
	if (tree.fireEscape) igs ~= 2;
	if (tree.fireLose) igs ~= 3;
	if (tree.fireEveryRound) igs ~= 4;
	if (tree.fireRound0) igs ~= 5;
	foreach (rnd; tree.rounds) { mixin(S_TRACE);
		igs ~= -(cast(int)rnd);
	}
	string[] keyCodes;
	foreach (keyCode; tree.keyCodes) { mixin(S_TRACE);
		keyCodes ~= d.prop.sys.convFireKeyCode(keyCode);
	}

	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(uint)tree.starts.length);
		foreach (evt; tree.starts) { mixin(S_TRACE);
			writeContent(d, f, evt);
		}
		f.writeL(cast(uint)igs.length);
		foreach (ig; igs) { mixin(S_TRACE);
			f.writeL(cast(int)ig);
		}
		if (MatchingType.And is tree.keyCodeMatchingType) { mixin(S_TRACE);
			// CardWirth 1.50
			writeStrings(f, ["MatchingType=All"] ~ keyCodes);
		} else { mixin(S_TRACE);
			writeStrings(f, keyCodes);
		}
	} else { mixin(S_TRACE);
		f.writeL(cast(uint)(tree.starts.length + 0x7000000));
		foreach (evt; tree.starts) { mixin(S_TRACE);
			writeContent(d, f, evt);
		}
		f.writeExUInt(cast(uint)igs.length);
		foreach (ig; igs) { mixin(S_TRACE);
			f.writeExUInt(cast(uint)ig);
		}
		writeBool(f, MatchingType.And is tree.keyCodeMatchingType);
		writeExStrings(f, keyCodes);
	}
}
private void writeBgImage(ref SData d, ref ByteIO f, BgImage b) { mixin(S_TRACE);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		auto ic = cast(ImageCell)b;
		if (ic) { mixin(S_TRACE);
			f.writeL(cast(int)ic.x);
			f.writeL(cast(int)ic.y);
			f.writeL(cast(uint)ic.width + 40000u);
			f.writeL(cast(uint)ic.height);
			writeString(f, encodePathLegacy(ic.path));
			writeBool(f, ic.mask);
			writeString(f, ic.flag);
			f.writeL(cast(byte)0x0);
		}
		auto tc = cast(TextCell)b;
		if (tc) { mixin(S_TRACE);
			f.writeL(cast(int)tc.x);
			f.writeL(cast(int)tc.y);
			f.writeL(cast(uint)tc.width + 60000u);
			f.writeL(cast(uint)tc.height);
			f.write(cast(byte)2);
			writeBool(f, tc.mask);
			writeString(f, tc.text);
			writeString(f, tc.fontName);
			f.writeL(cast(uint)tc.size);
			auto color = tc.color;
			f.write(cast(ubyte)color.r);
			f.write(cast(ubyte)color.g);
			f.write(cast(ubyte)color.b);
			f.write(cast(ubyte)color.a);
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
				f.write(cast(ubyte)bColor.r);
				f.write(cast(ubyte)bColor.g);
				f.write(cast(ubyte)bColor.b);
				f.write(cast(ubyte)bColor.a);
				f.writeL(cast(uint)tc.borderingWidth);
			}
			f.write(cast(byte)100);
			f.writeL(cast(uint)0);
			f.writeL(cast(uint)0);
			f.write(cast(byte)(tc.vertical ? 2 : 0));

			writeString(f, tc.flag);
			f.writeL(cast(byte)0x0);
		}
		auto cc = cast(ColorCell)b;
		if (cc) { mixin(S_TRACE);
			f.writeL(cast(int)cc.x);
			f.writeL(cast(int)cc.y);
			f.writeL(cast(uint)cc.width + 60000u);
			f.writeL(cast(uint)cc.height);
			f.write(cast(byte)3);
			f.write(fromBlendMode(cc.blendMode, cc.mask));
			f.write(fromGradientDir(cc.gradientDir));
			auto color1 = cc.color1;
			f.write(cast(ubyte)color1.b);
			f.write(cast(ubyte)color1.g);
			f.write(cast(ubyte)color1.r);
			f.write(cast(ubyte)color1.a);
			if (cc.gradientDir !is GradientDir.None) { mixin(S_TRACE);
				auto color2 = cc.color2;
				f.write(cast(ubyte)color2.b);
				f.write(cast(ubyte)color2.g);
				f.write(cast(ubyte)color2.r);
				f.write(cast(ubyte)color2.a);
			}
			writeString(f, cc.flag);
			f.writeL(cast(byte)0x0);
		}
		auto pc = cast(PCCell)b;
		if (pc) { mixin(S_TRACE);
			f.writeL(cast(int)pc.x);
			f.writeL(cast(int)pc.y);
			f.writeL(cast(uint)pc.width + 60000u);
			f.writeL(cast(uint)pc.height);
			f.write(cast(byte)4);
			writeBool(f, pc.mask);
			f.write(cast(ubyte)pc.pcNumber);
			writeString(f, pc.flag);
			f.writeL(cast(byte)0x0);
		}
	} else { mixin(S_TRACE);
		f.writeL(cast(int)b.x);
		f.writeL(cast(int)b.y);
		f.writeL(cast(uint)b.width + 70000u);
		f.writeL(cast(uint)b.height);

		auto ic = cast(ImageCell)b;
		if (ic) { mixin(S_TRACE);
			f.write(cast(byte)0);
			writeBool(f, ic.mask);
			writeBool(f, LAYER_MENU_CARD < ic.layer);
			writeBool(f, false);
			writeExString(f, .encodePathLegacy(ic.path));
			writeExString(f, ic.flag);
			f.write(cast(byte)0); // 不明(0)
			writeExString(f, ic.cellName);
		}
		auto tc = cast(TextCell)b;
		if (tc) { mixin(S_TRACE);
			f.write(cast(byte)2);
			writeBool(f, tc.mask);
			writeBool(f, LAYER_MENU_CARD < tc.layer);
			writeExString(f, tc.text);
			writeExString(f, tc.fontName);
			f.writeExUInt(tc.size);
			auto color = tc.color;
			f.write(cast(ubyte)color.r);
			f.write(cast(ubyte)color.g);
			f.write(cast(ubyte)color.b);
			f.write(cast(ubyte)color.a);
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
				f.write(cast(ubyte)bColor.r);
				f.write(cast(ubyte)bColor.g);
				f.write(cast(ubyte)bColor.b);
				f.write(cast(ubyte)bColor.a);
				f.writeExUInt(tc.borderingWidth);
			}
			f.write(cast(byte)0xC8); // 不明(0xC8)
			f.write(cast(byte)0x01); // 不明(0x01)
			f.write(cast(byte)0); // 不明(0)
			f.write(cast(byte)0); // 不明(0)
			f.write(cast(byte)(tc.vertical ? 2 : 0)); // 不明(縦書き時:2,他:0)
			writeExString(f, tc.flag);
			f.write(cast(byte)0); // 不明(0)
			writeExString(f, tc.cellName);
		}
		auto cc = cast(ColorCell)b;
		if (cc) { mixin(S_TRACE);
			f.write(cast(byte)3);
			f.write(fromBlendMode(cc.blendMode, cc.mask));
			writeBool(f, LAYER_MENU_CARD < cc.layer);
			f.write(fromGradientDir(cc.gradientDir));
			auto color1 = cc.color1;
			f.write(cast(ubyte)color1.b);
			f.write(cast(ubyte)color1.g);
			f.write(cast(ubyte)color1.r);
			f.write(cast(ubyte)color1.a);
			if (cc.gradientDir !is GradientDir.None) { mixin(S_TRACE);
				auto color2 = cc.color2;
				f.write(cast(ubyte)color2.b);
				f.write(cast(ubyte)color2.g);
				f.write(cast(ubyte)color2.r);
				f.write(cast(ubyte)color2.a);
			}
			writeExString(f, cc.flag);
			f.write(cast(byte)0); // 不明(0)
			writeExString(f, cc.cellName);
		}
		auto pc = cast(PCCell)b;
		if (pc) { mixin(S_TRACE);
			f.write(cast(byte)4);
			writeBool(f, pc.mask);
			writeBool(f, LAYER_MENU_CARD < pc.layer);
			f.write(cast(ubyte)pc.pcNumber);
			writeExString(f, pc.flag);
			f.write(cast(byte)0); // 不明(0)
			writeExString(f, pc.cellName);
		}
	}
}
private void writeBgImages(ref SData d, ref ByteIO f, BgImage[] backs, bool replBgImg = false) { mixin(S_TRACE);
	if (replBgImg)  { mixin(S_TRACE);
		f.writeExUInt(cast(uint)backs.length);
	} else { mixin(S_TRACE);
		auto b = backs.length ? cast(ImageCell)backs[0] : null;
		if (b && b.path != "" && b.flag == "" && b.x == 0 && b.y == 0
				&& b.width == 632 && b.height == 420 && !b.mask && b.cellName == "") { mixin(S_TRACE);
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)backs.length);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)backs.length);
			}
		} else { mixin(S_TRACE);
			if (d.opt.dataVersion < 7) { mixin(S_TRACE);
				f.writeL(cast(uint)backs.length + 1u);
			} else { mixin(S_TRACE);
				f.writeExUInt(cast(uint)backs.length + 1u);
			}
			writeBgImage(d, f, new ImageCell("", "", 0, 0, 632, 420, false));
		}
	}
	foreach (back; backs) { mixin(S_TRACE);
		writeBgImage(d, f, back);
	}
}
private void writeArea(ref SData d, ref ByteIO f, Area a) { mixin(S_TRACE);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(byte)0x0);
		f.writeL(cast(uint)0x0);
		writeString(f, a.name);
		f.writeL(cast(uint)(a.id + 40000u));
		f.writeL(cast(uint)a.trees.length);
		foreach (tree; a.trees) { mixin(S_TRACE);
			writeEventTree(d, f, tree);
		}
		writeBool(f, !a.spAuto);
		f.writeL(cast(uint)a.cards.length);
		foreach (c; a.cards) { mixin(S_TRACE);
			f.writeL(cast(byte)0x0);
			bool saveBinImg;
			auto paths = c.paths;
			auto path = paths.length ? paths[0] : null;
			if (path && path.type is CardImageType.File && isBinImg(path.path)) { mixin(S_TRACE);
				writeImage(d, f, c, path.path);
				saveBinImg = true;
			} else { mixin(S_TRACE);
				writeImage(d, f, c, "");
				saveBinImg = false;
			}
			writeString(f, c.name);
			f.writeL(cast(byte)0x40);
			f.writeL(cast(byte)0x9C);
			f.writeL(cast(byte)0x0);
			f.writeL(cast(byte)0x0);
			writeString(f, c.desc);
			f.writeL(cast(uint)c.trees.length);
			foreach (tree; c.trees) { mixin(S_TRACE);
				writeEventTree(d, f, tree);
			}
			writeString(f, c.flag);
			f.writeL(cast(uint)c.scale);
			f.writeL(cast(int)c.x);
			f.writeL(cast(int)c.y);
			if (path && path.type is CardImageType.File) { mixin(S_TRACE);
				writeString(f, saveBinImg ? "" : encodePathLegacy(path.path));
			} else if (path && path.type is CardImageType.PCNumber && 0 < path.pcNumber) { mixin(S_TRACE);
				writeString(f, .text(path.pcNumber));
			} else {
				writeString(f, "");
			}
		}
		writeBgImages(d, f, a.backs);
	} else { mixin(S_TRACE);
		f.write(cast(ubyte)0xFF);
		f.write(cast(ubyte)d.opt.dataVersion);
		writeExString(f, a.name);
		f.writeExUInt(cast(uint)a.id);

		f.writeExUInt(cast(uint)a.trees.length);
		foreach (tree; a.trees) { mixin(S_TRACE);
			writeEventTree(d, f, tree);
		}
		writeBool(f, !a.spAuto);
		f.writeExUInt(cast(uint)a.cards.length);
		foreach (c; a.cards) { mixin(S_TRACE);
			f.write(cast(ubyte)0x80); // 不明(0x80)
			f.write(cast(ubyte)d.opt.dataVersion); // バージョン情報？(0x07)
			f.write(cast(ubyte)0); // 不明(0)
			bool saveBinImg;
			auto paths = c.paths;
			auto path = paths.length ? paths[0] : null;
			if (path && path.type is CardImageType.File && isBinImg(path.path)) { mixin(S_TRACE);
				writeImage(d, f, c, path.path);
				saveBinImg = true;
			} else { mixin(S_TRACE);
				writeImage(d, f, c, "");
				saveBinImg = false;
			}
			writeExString(f, c.name);
			f.write(cast(byte)0); // 不明
			writeExString(f, c.desc);
			f.writeExUInt(cast(uint)c.trees.length);
			foreach (tree; c.trees) { mixin(S_TRACE);
				writeEventTree(d, f, tree);
			}
			writeExString(f, c.flag);
			f.writeExUInt(c.scale);
			f.writeExInt(c.x);
			f.writeExInt(c.y);

			ubyte sb = 0;
			// カード速度1以下はアニメーション無しとして扱う
			if (c.animationSpeed <= 1) { mixin(S_TRACE);
				sb |= 0b00010000;
			}
			if (c.expandSPChars) { mixin(S_TRACE);
				sb |= 0b00100000;
			}

			if (path && path.type is CardImageType.File) { mixin(S_TRACE);
				if (saveBinImg) { mixin(S_TRACE);
					// イメージ格納
					f.write(cast(ubyte)(sb | 0x0));
				} else { mixin(S_TRACE);
					// ファイル指定
					f.write(cast(ubyte)(sb | 0x1));
					writeExString(f, encodePathLegacy(path.path));
				}
			} else if (path && path.type is CardImageType.PCNumber && 0 < path.pcNumber) { mixin(S_TRACE);
				// PC番号
				f.write(cast(ubyte)(sb | 0x2));
				f.write(cast(ubyte)path.pcNumber);
			} else {
				// イメージ無し
				f.write(cast(ubyte)(sb | 0x0));
			}
			writeExString(f, c.cardGroup);
		}
		writeBgImages(d, f, a.backs);
	}
}
private void writeBattle(ref SData d, ref ByteIO f, Battle a) { mixin(S_TRACE);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(byte)0x1);
		f.writeL(cast(uint)0x0);
		writeString(f, a.name);
		f.writeL(cast(uint)(a.id + 40000u));
		f.writeL(cast(uint)a.trees.length);
		foreach (tree; a.trees) { mixin(S_TRACE);
			writeEventTree(d, f, tree);
		}
		writeBool(f, !a.spAuto);
		f.writeL(cast(uint)a.cards.length);
		foreach (c; a.cards) { mixin(S_TRACE);
			f.writeL(cast(uint)c.id);
			f.writeL(cast(uint)c.trees.length);
			foreach (tree; c.trees) { mixin(S_TRACE);
				writeEventTree(d, f, tree);
			}
			writeString(f, c.flag);
			f.writeL(cast(uint)c.scale);
			f.writeL(cast(int)c.x);
			f.writeL(cast(int)c.y);
			writeBool(f, c.action(ActionCardType.RunAway));
		}
		writeString(f, encodePathLegacy(a.music));
	} else { mixin(S_TRACE);
		f.write(cast(ubyte)0xFF);
		f.write(cast(ubyte)d.opt.dataVersion);
		writeExString(f, a.name);
		f.writeExUInt(cast(uint)a.id);

		f.writeExUInt(cast(uint)a.trees.length);
		foreach (tree; a.trees) { mixin(S_TRACE);
			writeEventTree(d, f, tree);
		}
		writeBool(f, !a.spAuto);
		f.writeExUInt(cast(uint)a.cards.length);
		foreach (c; a.cards) { mixin(S_TRACE);
			f.writeExUInt(cast(uint)c.id);
			f.writeL(cast(uint)c.trees.length);
			foreach (tree; c.trees) { mixin(S_TRACE);
				writeEventTree(d, f, tree);
			}
			writeString(f, c.flag);
			f.writeL(cast(uint)c.scale);
			f.writeL(cast(int)c.x);
			f.writeL(cast(int)c.y);

			auto pcNumber = 0u;
			if (c.isOverrideImage) { mixin(S_TRACE);
				auto paths = c.overrideImages;
				auto path = paths.length ? paths[0] : null;
				if (path && path.type is CardImageType.PCNumber && 0 < path.pcNumber) { mixin(S_TRACE);
					pcNumber = path.pcNumber;
				}
			}

			ubyte sb = 0;
			if (c.action(ActionCardType.RunAway)) sb |= 0b0001;
			if (0u < pcNumber) sb |= 0b0010;
			if (c.isOverrideName) sb |= 0b0100;
			f.write(sb);
			if (0u < pcNumber) f.write(cast(ubyte)pcNumber);
			if (c.isOverrideName) writeExString(f, c.overrideName);
		}
		writeExString(f, encodePathLegacy(a.music));
	}
}
private void writePackage(ref SData d, ref ByteIO f, Package a) { mixin(S_TRACE);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(uint)0x4);
		writeString(f, a.name);
		f.writeL(cast(uint)a.id);
		f.writeL(cast(uint)a.trees.length);
	} else { mixin(S_TRACE);
		f.writeL(cast(uint)7);
		writeExString(f, a.name);
		f.writeExUInt(cast(uint)a.id);
		f.writeExUInt(cast(uint)a.trees.length);
	}
	foreach (tree; a.trees) { mixin(S_TRACE);
		writeCEventTree(d, f, tree);
	}
}
private void writeCast(ref SData d, ref ByteIO f, CastCard c) { mixin(S_TRACE);
	Coupon[] coupons;
	bool[string] cSet;
	foreach (cc; c.coupons) { mixin(S_TRACE);
		auto name2 = cc.name.tosjis().touni();
		if (name2 in cSet) continue;
		cSet[name2] = true;
		coupons ~= cc;
	}
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(byte)0x2);
		auto paths = c.paths;
		writeImage(d, f, c, paths.length && paths[0].type is CardImageType.File ? paths[0].path : "");
		writeString(f, c.name);
		f.writeL(cast(uint)(c.id + 40000u));
		writeBool(f, c.weaponResist);
		writeBool(f, c.magicResist);
		writeBool(f, c.undead);
		writeBool(f, c.automaton);
		writeBool(f, c.unholy);
		writeBool(f, c.constructure);
		writeBool(f, c.resist(Element.Fire));
		writeBool(f, c.resist(Element.Ice));
		writeBool(f, c.weakness(Element.Fire));
		writeBool(f, c.weakness(Element.Ice));
		f.writeL(cast(uint)c.level);
		f.writeL(cast(uint)0u); // 所持金。現行エンジンでは未使用
		writeString(f, c.desc, true, true);
		f.writeL(cast(uint)c.life);
		f.writeL(cast(uint)c.lifeMax);
		f.writeL(cast(uint)c.paralyze);
		f.writeL(cast(uint)c.poison);
		f.writeL(cast(int)c.defaultEnhance(Enhance.Avoid));
		f.writeL(cast(int)c.defaultEnhance(Enhance.Resist));
		f.writeL(cast(int)c.defaultEnhance(Enhance.Defense));
		f.writeL(cast(uint)c.physical(Physical.Dex));
		f.writeL(cast(uint)c.physical(Physical.Agl));
		f.writeL(cast(uint)c.physical(Physical.Int));
		f.writeL(cast(uint)c.physical(Physical.Str));
		f.writeL(cast(uint)c.physical(Physical.Vit));
		f.writeL(cast(uint)c.physical(Physical.Min));
		f.writeL(cast(int)c.mental(Mental.Aggressive));
		f.writeL(cast(int)c.mental(Mental.Cheerful));
		f.writeL(cast(int)c.mental(Mental.Brave));
		f.writeL(cast(int)c.mental(Mental.Cautious));
		f.writeL(cast(int)c.mental(Mental.Trickish));
		f.write(fromMentality(c.mentality));
		f.writeL(cast(uint)c.mentalityRound);
		f.writeL(cast(uint)c.bindRound);
		f.writeL(cast(uint)c.silenceRound);
		f.writeL(cast(uint)c.faceUpRound);
		f.writeL(cast(uint)c.antiMagicRound);
		foreach (enh; [Enhance.Action, Enhance.Avoid, Enhance.Resist, Enhance.Defense]) { mixin(S_TRACE);
			int val = c.enhance(enh);
			uint round = c.enhanceRound(enh);
			if (!val) round = 0;
			f.writeL(val);
			f.writeL(round);
		}
		f.writeL(cast(uint)c.items.length);
		foreach (cc; c.items) { mixin(S_TRACE);
			writeItem(d, f, cc);
		}
		f.writeL(cast(uint)c.skills.length);
		foreach (cc; c.skills) { mixin(S_TRACE);
			writeSkill(d, f, cc);
		}
		f.writeL(cast(uint)c.beasts.length);
		foreach (cc; c.beasts) { mixin(S_TRACE);
			writeBeast(d, f, cc);
		}
		f.writeL(cast(uint)coupons.length);
		foreach (cc; coupons) { mixin(S_TRACE);
			writeString(f, cc.name);
			f.writeL(cast(int)cc.value);
		}
	} else { mixin(S_TRACE);
		f.write(cast(ubyte)0x80);
		f.write(cast(ubyte)d.opt.dataVersion);
		f.write(cast(ubyte)2);
		auto paths = c.paths;
		writeImage(d, f, c, paths.length && paths[0].type is CardImageType.File ? paths[0].path : "");
		writeExString(f, c.name);
		f.writeExUInt(cast(uint)c.id);
		ubyte eb1 = 0;
		ubyte eb2 = 0;
		if (c.weaponResist) eb1 |= 0b00000001;
		if (c.magicResist) eb1 |= 0b00000010;
		if (c.undead) eb1 |= 0b00000100;
		if (c.automaton) eb1 |= 0b00001000;
		if (c.unholy) eb1 |= 0b00010000;
		if (c.constructure) eb1 |= 0b00100000;
		if (c.resist(Element.Fire)) eb1 |= 0b01000000;
		if (c.resist(Element.Ice)) eb1 |= 0b10000000;
		if (c.weakness(Element.Fire)) eb2 |= 0b00000001;
		if (c.weakness(Element.Ice)) eb2 |= 0b00000010;
		f.write(eb1);
		f.write(eb2);
		f.writeExUInt(c.level);
		writeExString(f, c.desc, true, true);
		f.writeExUInt(c.life);
		f.writeExUInt(c.lifeMax);
		f.writeExUInt(c.paralyze);
		f.writeExUInt(c.poison);
		f.writeExInt(c.defaultEnhance(Enhance.Avoid));
		f.writeExInt(c.defaultEnhance(Enhance.Resist));
		f.writeExInt(c.defaultEnhance(Enhance.Defense));
		f.writeExUInt(c.physical(Physical.Dex));
		f.writeExUInt(c.physical(Physical.Agl));
		f.writeExUInt(c.physical(Physical.Int));
		f.writeExUInt(c.physical(Physical.Str));
		f.writeExUInt(c.physical(Physical.Vit));
		f.writeExUInt(c.physical(Physical.Min));
		f.writeExInt(cast(int)c.mental(Mental.Aggressive));
		f.writeExInt(cast(int)c.mental(Mental.Cheerful));
		f.writeExInt(cast(int)c.mental(Mental.Brave));
		f.writeExInt(cast(int)c.mental(Mental.Cautious));
		f.writeExInt(cast(int)c.mental(Mental.Trickish));
		f.write(fromMentality(c.mentality));
		f.writeExUInt(c.mentalityRound);
		f.writeExUInt(c.bindRound);
		f.writeExUInt(c.silenceRound);
		f.writeExUInt(c.faceUpRound);
		f.writeExUInt(c.antiMagicRound);
		foreach (enh; [Enhance.Action, Enhance.Avoid, Enhance.Resist, Enhance.Defense]) { mixin(S_TRACE);
			auto val = c.enhance(enh);
			auto round = c.enhanceRound(enh);
			if (!val) round = 0;
			f.writeExInt(val);
			f.writeExUInt(round);
		}
		f.writeExUInt(cast(uint)c.items.length);
		foreach (cc; c.items) { mixin(S_TRACE);
			writeItem(d, f, cc);
		}
		f.writeExUInt(cast(uint)c.skills.length);
		foreach (cc; c.skills) { mixin(S_TRACE);
			writeSkill(d, f, cc);
		}
		f.writeExUInt(cast(uint)c.beasts.length);
		foreach (cc; c.beasts) { mixin(S_TRACE);
			writeBeast(d, f, cc);
		}
		f.write(cast(byte)0); // 不明
		f.writeExUInt(cast(uint)coupons.length);
		foreach (cc; coupons) { mixin(S_TRACE);
			writeString(f, cc.name);
			f.writeL(cast(int)cc.value);
		}
	}
}
private void writeEffCard(ref SData d, ref ByteIO f, EffectCard c, byte type, ulong id) { mixin(S_TRACE);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.write(type);
		auto paths = c.paths;
		writeImage(d, f, c, paths.length && paths[0].type is CardImageType.File ? paths[0].path : "");
		writeString(f, c.name);
		f.writeL(cast(uint)(id + 40000u));
		writeString(f, c.desc);
		f.writeL(cast(uint)fromPhysical(c.physical));
		f.writeL(cast(int)fromMental(c.mental));
		writeBool(f, c.spell);
		writeBool(f, c.allRange);
		f.write(fromCardTarget(c.target));
		f.write(fromEffectType(c.effectType));
		f.write(fromResist(c.resist));
		f.writeL(cast(int)c.successRate);
		f.write(fromCardVisual(c.visual));
		f.writeL(cast(uint)c.motions.length);
		foreach (m; c.motions) { mixin(S_TRACE);
			writeMotion(d, f, m);
		}
		f.writeL(cast(int)c.enhance(Enhance.Avoid));
		f.writeL(cast(int)c.enhance(Enhance.Resist));
		f.writeL(cast(int)c.enhance(Enhance.Defense));
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
		f.writeL(cast(uint)c.trees.length);
		foreach (tree; c.trees) { mixin(S_TRACE);
			writeCEventTree(d, f, tree);
		}
	} else { mixin(S_TRACE);
		f.write(cast(ubyte)0x80);
		f.write(cast(ubyte)d.opt.dataVersion);
		f.write(type);
		auto paths = c.paths;
		writeImage(d, f, c, paths.length && paths[0].type is CardImageType.File ? paths[0].path : "");
		writeExString(f, c.name);
		f.writeExUInt(cast(uint)id);
		writeExString(f, c.desc);
		f.writeExInt(fromPhysical(c.physical));
		f.writeExInt(fromMental(c.mental));
		writeBool(f, c.spell);
		writeBool(f, c.allRange);
		f.write(fromCardTarget(c.target));
		f.write(fromEffectType(c.effectType));
		f.write(fromResist(c.resist));
		f.writeExInt(c.successRate);
		f.write(fromCardVisual(c.visual));
		f.writeExUInt(cast(uint)c.motions.length);
		foreach (m; c.motions) { mixin(S_TRACE);
			writeMotion(d, f, m);
		}
		f.writeExInt(c.enhance(Enhance.Avoid));
		f.writeExInt(c.enhance(Enhance.Resist));
		f.writeExInt(c.enhance(Enhance.Defense));
		f.write(cast(ubyte)1); // パス指定
		writeExString(f, c.soundPath1.length ? encodePathLegacy(c.soundPath1) : "（なし）");
		f.write(cast(ubyte)1); // パス指定
		writeExString(f, c.soundPath2.length ? encodePathLegacy(c.soundPath2) : "（なし）");

		f.writeExUInt(cast(uint)c.keyCodes.length);
		foreach (keyCode; c.keyCodes) { mixin(S_TRACE);
			writeExString(f, keyCode);
		}
		f.write(fromPremium(c.premium));
		f.write(cast(byte)0); // 不明
		writeExString(f, c.scenario);
		writeExString(f, c.author);
		f.writeExUInt(cast(uint)c.trees.length);
		foreach (tree; c.trees) { mixin(S_TRACE);
			writeCEventTree(d, f, tree);
		}
	}
}
private void writeSkill(ref SData d, ref ByteIO f, SkillCard c) { mixin(S_TRACE);
	ulong id = c.id;
	ulong linkId = c.linkId;
	bool hold = c.hold;
	if (0 != c.linkId) { mixin(S_TRACE);
		d.cardRef[c.cwxPath(true)] = linkId;
		c = d.skill(c.linkId);
		if (!c) c = new SkillCard(null, id, "", [], "");
	}
	writeEffCard(d, f, c, 0x5, id);
	writeBool(f, hold);

	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(uint)c.level);
		f.writeL(cast(uint)c.useLimit);
	} else { mixin(S_TRACE);
		f.writeExInt(c.level);
		f.writeExUInt(c.useLimit);
		writeBool(f, true); // バックパック対応
	}
}
private void writeItem(ref SData d, ref ByteIO f, ItemCard c) { mixin(S_TRACE);
	ulong id = c.id;
	ulong linkId = c.linkId;
	bool hold = c.hold;
	if (0 != c.linkId) { mixin(S_TRACE);
		d.cardRef[c.cwxPath(true)] = linkId;
		c = d.item(c.linkId);
		if (!c) c = new ItemCard(null, id, "", [], "");
	}
	writeEffCard(d, f, c, 0x3, id);
	writeBool(f, hold);

	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(uint)c.useLimit);
		f.writeL(cast(uint)c.useLimitMax);
		f.writeL(cast(uint)c.price);
		f.writeL(cast(int)c.enhanceOwner(Enhance.Avoid));
		f.writeL(cast(int)c.enhanceOwner(Enhance.Resist));
		f.writeL(cast(int)c.enhanceOwner(Enhance.Defense));
	} else { mixin(S_TRACE);
		f.writeExUInt(c.useLimit);
		f.writeExUInt(c.useLimitMax);
		f.writeExUInt(c.price);
		f.writeExInt(c.enhanceOwner(Enhance.Avoid));
		f.writeExInt(c.enhanceOwner(Enhance.Resist));
		f.writeExInt(c.enhanceOwner(Enhance.Defense));
	}
}
private void writeBeast(ref SData d, ref ByteIO f, BeastCard c) { mixin(S_TRACE);
	ulong id = c.id;
	ulong linkId = c.linkId;
	if (0 != c.linkId) { mixin(S_TRACE);
		d.cardRef[c.cwxPath(true)] = linkId;
		c = d.beast(c.linkId);
		if (!c) c = new BeastCard(null, id, "", [], "");
	}
	writeEffCard(d, f, c, 0x6, id);
	writeBool(f, false); // Hold

	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(uint)c.useLimit);
	} else { mixin(S_TRACE);
		f.writeExUInt(c.useLimit);
		f.write(cast(byte)(c.useLimit ? 1 : 0)); // 不明(使用回数あり=1, 使用回数無し=0。付帯フラグか？)
	}
}
private void writeInfo(ref SData d, ref ByteIO f, InfoCard c) { mixin(S_TRACE);
	if (d.opt.dataVersion < 7) { mixin(S_TRACE);
		f.writeL(cast(byte)0x4);
		auto paths = c.paths;
		writeImage(d, f, c, paths.length && paths[0].type is CardImageType.File ? paths[0].path : "");
		writeString(f, c.name);
		f.writeL(cast(uint)(c.id + 40000u));
		writeString(f, c.desc);
	} else { mixin(S_TRACE);
		f.writeL(cast(byte)0x80);
		f.writeL(cast(ubyte)d.opt.dataVersion);
		f.writeL(cast(byte)0x4);
		auto paths = c.paths;
		writeImage(d, f, c, paths.length && paths[0].type is CardImageType.File ? paths[0].path : "");
		writeExString(f, c.name);
		f.writeExUInt(cast(uint)c.id);
		writeExString(f, c.desc);
	}
}
