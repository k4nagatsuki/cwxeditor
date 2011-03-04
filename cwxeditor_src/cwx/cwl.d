
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

unittest {
	try {
		loadLScenario!(Summary)("", "");
		loadLScenario!(Importable)("", "");
	} catch {}
}

private bool sWith(string f, string s) {
	return f.length > s.length && fnmatch(f[0u .. s.length], s);
}
private string encodePathLegacy(string path) {
	// エフェクトブースターは'/'区切りのパスを受け付けない
	return isBinImg(path) ? path : replace(path, sep, "\\");
}
private string decodePathLegacy(string path) {
	return isBinImg(path) ? path : replace(path, "\\", sep);
}

private struct RData {
	string sPath;
	string skin;
}
/// 4.0形式のCardWirthシナリオを読込む。
/// Params:
/// newName = シナリオ名。null以外が指定された場合、
///           Summary.wsmが存在しない際はこの名前で新規に作成する。
S loadLScenario(S)(string p, string skin, string newName = null) {
	static const bool AR = is (S : AreaOwner);
	static const bool BA = is (S : BattleOwner);
	static const bool PA = is (S : PackageOwner);
	static const bool CA = is (S : CastOwner);
	static const bool SK = is (S : SkillOwner);
	static const bool IT = is (S : ItemOwner);
	static const bool BE = is (S : BeastOwner);
	static const bool IN = is (S : InfoOwner);
	auto sPath = p;
	string summPath = std.path.join(p, "Summary.wsm");
	S summ;
	RData d;
	ulong startAreaId;
	if (.exists(summPath)) {
		d = RData(sPath, skin);
		{
			auto bytes = ByteIO(std.file.read(summPath));
			summ = loadSummary!(S)(d, bytes, startAreaId);
		}
	} else {
		if (!newName) throw new SummaryException("Not Scenario: " ~ p);
		d = RData(sPath, skin);
		static if (is(S == Summary)) {
			summ = new Summary(newName, d.skin, d.sPath, false, true);
		} else {
			summ = new S(d.sPath, newName, true);
		}
	}
	class Load {
		static if (AR) Area[] areas;
		static if (BA) Battle[] battles;
		static if (PA) Package[] packages;
		static if (CA) CastCard[] casts;
		static if (SK) SkillCard[] skills;
		static if (IT) ItemCard[] items;
		static if (BE) BeastCard[] beasts;
		static if (IN) InfoCard[] infos;
		string[] files;
		ulong wait = 0L;
		int load() {
			foreach (file; this.files) {
				try {
					auto f = ByteIO(std.file.read(file));
					auto base = getBaseName(file);
					static if (AR) if (sWith(base, "Area")) {
						areas ~= .loadArea(d, f);
					}
					static if (BA) if (sWith(base, "Battle")) {
						battles ~= .loadBattle(d, f);
					}
					static if (PA) if (sWith(base, "Package")) {
						packages ~= .loadPackage(d, f);
					}
					static if (CA) if (sWith(base, "Mate")) {
						casts ~= .loadCast(d, f);
					}
					static if (SK) if (sWith(base, "Skill")) {
						skills ~= .loadSkill(d, f);
					}
					static if (IT) if (sWith(base, "Item")) {
						items ~= .loadItem(d, f);
					}
					static if (BE) if (sWith(base, "Beast")) {
						beasts ~= .loadBeast(d, f);
					}
					static if (IN) if (sWith(base, "Info")) {
						infos ~= .loadInfo(d, f);
					}
				} catch (Exception e) {
					debugln(file ~ " - " ~ e.msg);
					throw e;
				}
			}
			return 0;
		}
	}
	auto load1 = new Load;
	auto load2 = new Load;
	foreach (file; clistdir(sPath)) {
		if (fnmatch(getExt(file), "wid")) {
			file = std.path.join(sPath, file);
			auto size = std.file.getSize(file);
			if (load1.wait < load2.wait) {
				load1.files ~= file;
				load1.wait += size;
			} else {
				load2.files ~= file;
				load2.wait += size;
			}
		}
	}
	version (TwinIO) {
		auto thr = new Thread(&load2.load);
		thr.start;
		load1.load;
		thr.wait;
	} else {
		load1.load;
		load2.load;
	}
	static if (AR) Area[] areas = load1.areas ~ load2.areas;
	static if (BA) Battle[] battles = load1.battles ~ load2.battles;
	static if (PA) Package[] packages = load1.packages ~ load2.packages;
	static if (CA) CastCard[] casts = load1.casts ~ load2.casts;
	static if (SK) SkillCard[] skills = load1.skills ~ load2.skills;
	static if (IT) ItemCard[] items = load1.items ~ load2.items;
	static if (BE) BeastCard[] beasts = load1.beasts ~ load2.beasts;
	static if (IN) InfoCard[] infos = load1.infos ~ load2.infos;
	static if (is (S == Summary)) {
		foreach (a; areas.sort) summ.add(a, false);
		foreach (a; battles.sort) summ.add(a, false);
		foreach (a; packages.sort) summ.add(a, false);
		foreach (a; casts.sort) summ.add(a, false);
		foreach (a; skills.sort) summ.add(a, false);
		foreach (a; items.sort) summ.add(a, false);
		foreach (a; beasts.sort) summ.add(a, false);
		foreach (a; infos.sort) summ.add(a, false);
		summ.startArea = startAreaId;
		summ.resetChanged;
	} else {
		static if (AR) foreach (a; areas.sort) summ.add(a);
		static if (BA) foreach (a; battles.sort) summ.add(a);
		static if (PA) foreach (a; packages.sort) summ.add(a);
		static if (CA) foreach (a; casts.sort) summ.add(a);
		static if (SK) foreach (a; skills.sort) summ.add(a);
		static if (IT) foreach (a; items.sort) summ.add(a);
		static if (BE) foreach (a; beasts.sort) summ.add(a);
		static if (IN) foreach (a; infos.sort) summ.add(a);
	}
	return summ;
}

/// fileのIDと型を返す。
TypeInfo getType(string file, out ulong id) {
	try {
		if (!.exists(file)) {
			bool chk(string prefix) {
				if (!sWith(file, prefix)) return false;
				if (file.length < prefix.length + 5) return false;
				if (!fnmatch(getExt(file), "wid")) return false;
				string i = file[prefix.length .. $ - 4];
				if (.match(toUTF32(i), .regex!(dstring)("^[0-9]+$"d)).empty) return false;
				id = to!(ulong)(i);
				return true;
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
		auto f = ByteIO(std.file.read(file));
		file = getBaseName(file);
		// 今の所ファイル名しか見分ける手段が無い
		if (sWith(file, "Package")) {
			if (f.readUIntL != 0x4) return null;
			readString(f);
			id = f.readUIntL;
			return typeid(Package);
		} else {
			TypeInfo type;
			switch (f.readByte) {
			case 0x0: type = typeid(Area); break;
			case 0x1: type = typeid(Battle); break;
			case 0x2: type = typeid(CastCard); break;
			case 0x5: type = typeid(SkillCard); break;
			case 0x3: type = typeid(ItemCard); break;
			case 0x6: type = typeid(BeastCard); break;
			case 0x4: type = typeid(InfoCard); break;
			default: return null;
			}
			// readImage
			uint len = f.readUIntL;
			if (len) f.read(len);

			readString(f);
			id = f.readUIntL - 40000L;
			return type;
		}
	} catch (Exception e) {
		return null;
	}
}

private Target toTarget(byte b) {
	switch (b) {
	case 0: return Target(Target.M.SELECTED, false);
	case 1: return Target(Target.M.RANDOM, false);
	case 2: return Target(Target.M.UNSELECTED, false);
	case 3: return Target(Target.M.SELECTED, true);
	case 4: return Target(Target.M.RANDOM, true);
	case 5: return Target(Target.M.PARTY, true);
	case 6: return Target(Target.M.PARTY, false);
	default: throw new SummaryException("Unknown target: " ~ to!(string)(b));
	}
}
private EffectType toEffectType(byte b) {
	switch (b) {
	case 0: return EffectType.PHYSIC;
	case 1: return EffectType.MAGIC;
	case 2: return EffectType.MAGICAL_PHYSIC;
	case 3: return EffectType.PHYSICAL_MAGIC;
	case 4: return EffectType.NONE;
	default: throw new SummaryException("Unknown effect type: " ~ to!(string)(b));
	}
}
private Resist toResist(byte b) {
	switch (b) {
	case 0: return Resist.AVOID;
	case 1: return Resist.RESIST;
	case 2: return Resist.UNFAIL;
	default: throw new SummaryException("Unknown resist: " ~ to!(string)(b));
	}
}
private CardVisual toCardVisual(byte b) {
	switch (b) {
	case 0: return CardVisual.NONE;
	case 1: return CardVisual.REVERSE;
	case 2: return CardVisual.HORIZONTAL;
	case 3: return CardVisual.VERTICAL;
	default: throw new SummaryException("Unknown card visual: " ~ to!(string)(b));
	}
}
private Range toRange(byte b) {
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
private Status toStatus(byte b) {
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
	default: throw new SummaryException("Unknown status: " ~ to!(string)(b));
	}
}
private Element toElement(byte b) {
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
private DamageType toDamageType(byte b) {
	switch (b) {
	case 0: return DamageType.LEVEL_RATIO;
	case 1: return DamageType.NORMAL;
	case 2: return DamageType.MAX;
	default: throw new SummaryException("Unknown damage type: " ~ to!(string)(b));
	}
}
private Physical toPhysical(uint b) {
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
private Mental toMental(int b) {
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
private Mentality toMentality(byte b) {
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
private CardTarget toCardTarget(byte b) {
	switch (b) {
	case 0: return CardTarget.NONE;
	case 1: return CardTarget.USER;
	case 2: return CardTarget.PARTY;
	case 3: return CardTarget.ENEMY;
	case 4: return CardTarget.BOTH;
	default: throw new SummaryException("Unknown card target: " ~ to!(string)(b));
	}
}
private Premium toPremium(byte b) {
	switch (b) {
	case 0: return Premium.NORMAL;
	case 1: return Premium.RARE;
	case 2: return Premium.PREMIUM;
	default: throw new SummaryException("Unknown card premium: " ~ to!(string)(b));
	}
}
private bool readBool(ref ByteIO f) {
	return f.readByte ? true : false;
}
private string readImage(in RData d, ref ByteIO f) {
	uint len = f.readUIntL;
	if (!len) return "";
	ubyte[] img = f.read(len);
	if (endsWith(img, cast(ubyte[]) B_IMG_REF)) {
		size_t index = size_t.max;
		foreach_reverse (i, c; img[0 .. $ - B_IMG_REF.length]) {
			if (c == '\0') {
				index = i + 1;
				break;
			}
		}
		if (index != size_t.max) {
			auto s = cast(string) img[index .. $ - B_IMG_REF.length];
			if (.exists(std.path.join(d.sPath, s))) {
				return s;
			} else {
				return bImgToStr(img[0 .. index - 1]);
			}
		}
	}
	return bImgToStr(img);
}
private string readString(ref ByteIO f, bool lns = false, bool cutText = false) {
	uint len = f.readUIntL;
	if (!len) return "";
	string str = cast(string) f.read(len);
	if (!lns && str[$ - 1] == '\0') str = str[0 .. $ - 1];
	str = touni(str);
	if (cutText) {
		str = str.length > "TEXT\r\n".length ? str["TEXT\r\n".length .. $] : "";
	}
	str = replace(str, "\r\n", "\n");
	return str;
}
private string[] readStrings(ref ByteIO f) {
	auto str = readString(f, true);
	return str.length ? splitlines(str) : cast(string[]) [];
}
private S loadSummary(S)(in RData d, ref ByteIO f, out ulong startAreaId) {
	string img = readImage(d, f);
	static if (is (S == Summary)) {
		byte b;
		auto summ = new Summary(readString(f), d.skin, d.sPath, false, true);
		summ.imagePath = img;
		summ.desc = readString(f, true);
		summ.author = readString(f);
		summ.rCoupons = readStrings(f);
		summ.rCouponNum = f.readUIntL;
		startAreaId = f.readUIntL - 40000u;
		FlagDir flagsParent(string path) {
			FlagDir dir = summ.flagDirRoot;
			string par = FlagDir.up(path);
			if (par.length) {
				string[] spPath = std.string.split(par, "\\")[0u .. $ - 1u];
				while (spPath.length) {
					auto sub = dir.getSubDir(spPath[0u]);
					if (!sub) {
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
		for (uint i = 0u; i < stepNum; i++) {
			string path = readString(f);
			uint sel = f.readUIntL;
			string[] vals;
			vals.length = 10u;
			for (uint j = 0u; j < 10u; j++) {
				vals[j] = readString(f);
			}
			if (!flagsParent(path).add(new Step(FlagDir.basename(path), vals, sel))) {
				throw new SummaryException("Invalid step path: " ~ path);
			}
		}
		summ.flagDirRoot.sortSteps(true);
		uint flagNum = f.readUIntL;
		for (uint i = 0u; i < flagNum; i++) {
			string path = readString(f);
			bool sel = readBool(f);
			string on = readString(f);
			string off = readString(f);
			if (!flagsParent(path).add(new Flag(FlagDir.basename(path), on, off, sel))) {
				throw new SummaryException("Invalid flag path: " ~ path);
			}
		}
		summ.flagDirRoot.sortFlags(true);
		f.readUIntL;
		summ.levelMin = f.readUIntL;
		summ.levelMax = f.readUIntL;
		return summ;
	} else {
		return new S(d.sPath, readString(f), true);
	}
}
private Motion readMotion(in RData d, ref ByteIO f) {
	byte tType = f.readByte;
	f.readByte;
	f.readByte;
	f.readByte;
	f.readByte;
	f.readByte;
	byte elb = f.readByte;
	auto el = toElement(elb);
	byte type;
	if (tType == 8) {
		type = 0u;
	} else {
		type = f.readByte;
	}
	switch (tType) {
	case 0, 1: {
		byte dmgTypB = f.readByte;
		auto dmgTyp = toDamageType(dmgTypB);
		uint val = f.readUIntL;
		Motion m;
		if (tType == 0u) {
			switch (type) {
			case 0: m = new Motion(MType.HEAL, el); break;
			case 1: m = new Motion(MType.DAMAGE, el); break;
			case 2: m = new Motion(MType.ABSORB, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		} else {
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
	case 2: {
		switch (type) {
		case 0: return new Motion(MType.GET_SKILL_POWER, el);
		case 1: return new Motion(MType.LOSE_SKILL_POWER, el);
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 3, 4: {
		uint rnd = f.readUIntL;
		Motion m;
		if (tType == 3u) {
			switch (type) {
			case 0: m = new Motion(MType.SLEEP, el); break;
			case 1: m = new Motion(MType.CONFUSE, el); break;
			case 2: m = new Motion(MType.OVERHEAT, el); break;
			case 3: m = new Motion(MType.BRAVE, el); break;
			case 4: m = new Motion(MType.PANIC, el); break;
			case 5: m = new Motion(MType.NORMAL, el); break;
			default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
			}
		} else {
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
	case 5: {
		uint val = f.readUIntL;
		uint rnd = f.readUIntL;
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
	case 6: {
		switch (type) {
		case 0: return new Motion(MType.VANISH_TARGET, el);
		case 1: return new Motion(MType.VANISH_CARD, el);
		case 2: return new Motion(MType.VANISH_BEAST, el);
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 7: {
		switch (type) {
		case 0: return new Motion(MType.DEAL_ATTACK_CARD, el);
		case 1: return new Motion(MType.DEAL_POWERFUL_ATTACK_CARD, el);
		case 2: return new Motion(MType.DEAL_CRITICAL_ATTACK_CARD, el);
		case 3: return new Motion(MType.DEAL_FEINT_CARD, el);
		case 4: return new Motion(MType.DEAL_DEFENSE_CARD, el);
		case 5: return new Motion(MType.DEAL_DISTANCE_CARD, el);
		case 6: return new Motion(MType.DEAL_CONFUSE_CARD, el);
		case 7: return new Motion(MType.DEAL_SKILL_CARD, el);
		default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
		}
	}
	case 8: {
		BeastCard beast = null;
		uint bNum = f.readUIntL; // 常に0か1のはず
		for (uint i = 0u; i < bNum ; i++) {
			beast = loadBeast(d, f);
		}
		auto m = new Motion(MType.SUMMON_BEAST, el);
		m.beast = beast;
		return m;
	}
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private Content readContent(in RData d, ref ByteIO f) {
	byte type = f.readByte;
	string name = readString(f);
	uint cNum = f.readUIntL - 40000u;
	Content[] childs;
	childs.length = cNum;
	for (uint i = 0u; i < cNum; i++) {
		childs[i] = readContent(d, f);
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
	case 6: {
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
		e.text = readString(f, true);
		e.talkerC = msgTalker;
		e.cardPath = msgTalker != Talker.IMAGE ? "" : decodePathLegacy(msgPath);
		break;
	}
	case 7:
		e = new Content(CType.PLAY_BGM, name);
		e.bgmPath = decodePathLegacy(readString(f));
		break;
	case 8: {
		BgImage[] bgImgs = readBgImages(f);
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
	case 11: {
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
		for (uint i = 0u; i < effMotionNum; i++) {
			effMotions[i] = readMotion(d, f);
		}
		e = new Content(CType.EFFECT, name);
		e.level = effLev;
		e.targetNS = toTarget(effTarget);
		e.effectType = toEffectType(effType);
		e.resist = toResist(effResist);
		e.successRate = effSuc;
		e.soundPath = effSePath;
		e.cardVisual = toCardVisual(effVis);
		e.motions = effMotions;
		break;
	}
	case 12: {
		bool brMemAll = readBool(f);
		bool brMemRnd = readBool(f);
		e = new Content(CType.BRANCH_SELECT, name);
		e.targetAll = brMemAll;
		e.random = brMemRnd;
		break;
	}
	case 13: {
		uint val = f.readUIntL;
		byte targ = f.readByte;
		uint phy = f.readUIntL;
		int mtl = f.readIntL;
		e = new Content(CType.BRANCH_ABILITY, name);
		e.targetS = toTarget(targ);
		e.mental = toMental(mtl);
		e.physical = toPhysical(phy);
		e.level = val;
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
	case 16: {
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
	case 18: {
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
	case 20: {
		ulong id = f.readUIntL;
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.BRANCH_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 21: {
		ulong id = f.readUIntL;
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
	case 23: {
		ulong id = f.readUIntL;
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
	case 25: {
		string coupon = readString(f);
		f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.BRANCH_COUPON, name);
		e.coupon = coupon;
		e.range = toRange(rng);
		break;
	}
	case 26:
		e = new Content(CType.GET_CAST, name);
		e.casts = f.readUIntL;
		break;
	case 27: {
		ulong id = f.readUIntL;
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.GET_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 28: {
		ulong id = f.readUIntL;
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
	case 30: {
		ulong id = f.readUIntL;
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
	case 32: {
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
	case 34: {
		ulong id = f.readUIntL;
		uint num = f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.LOSE_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 35: {
		ulong id = f.readUIntL;
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
	case 37: {
		ulong id = f.readUIntL;
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
	case 39: {
		string coupon = readString(f);
		f.readUIntL;
		byte rng = f.readByte;
		e = new Content(CType.LOSE_COUPON, name);
		e.coupon = coupon;
		e.range = toRange(rng);
		break;
	}
	case 40: {
		byte targ = f.readByte;
		Talker t;
		switch (toTarget(targ).m) {
		case Target.M.SELECTED: t = Talker.SELECTED; break;
		case Target.M.UNSELECTED: t = Talker.UNSELECTED; break;
		case Target.M.RANDOM: t = Talker.RANDOM; break;
		default: throw new SummaryException("Unknown talker: " ~ to!(string)(targ));
		}
		uint dlgNum = f.readUIntL;
		SDialog[] dlgs;
		for (uint i = 0u; i < dlgNum; i++) {
			string[] coupons = readStrings(f);
			string text = readString(f, true);
			dlgs ~= new SDialog(text, coupons);
		}
		e = new Content(CType.TALK_DIALOG, name);
		e.talkerNC = t;
		e.dialogs = dlgs;
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
	case 44: {
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
	case 46: {
		bool avg = readBool(f);
		uint val = f.readUIntL;
		e = new Content(CType.BRANCH_LEVEL, name);
		e.average = avg;
		e.level = val;
		break;
	}
	case 47: {
		byte stat = f.readByte;
		byte targ = f.readByte;
		e = new Content(CType.BRANCH_STATUS, name);
		e.targetNS = toTarget(targ);
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
	default: throw new SummaryException("Unknown content type: " ~ to!(string)(type));
	}
	if (e.detail.owner) {
		foreach (c; childs) {
			e.add(c);
		}
	}
	return e;
}
private EventTree readCEventTree(in RData d, ref ByteIO f) {
	auto tree = new EventTree("");
	auto dest = tree.starts[0u];
	uint cNum = f.readUIntL;
	for (uint i = 0u; i < cNum; i++) {
		tree.add(readContent(d, f));
	}
	tree.remove(dest);
	return tree;
}
private EventTree readEventTree(in RData d, ref ByteIO f) {
	auto tree = new EventTree("");
	auto dest = tree.starts[0u];
	uint cNum = f.readUIntL;
	for (uint i = 0u; i < cNum; i++) {
		tree.add(readContent(d, f));
	}
	tree.remove(dest);
	uint igNum = f.readUIntL;
	for (uint i = 0u; i < igNum; i++) {
		int ig = f.readIntL;
		if (ig < 0) {
			tree.addRound(-ig);
		} else {
			switch (ig) {
			case 1: tree.enter = true; break;
			case 2: tree.escape = true; break;
			case 3: tree.lose = true; break;
			default: throw new SummaryException("Unknown ignition: " ~ to!(string)(ig));
			}
		}
	}
	tree.keyCodes = readStrings(f);
	return tree;
}
private BgImage readBgImage(ref ByteIO f) {
	byte b;
	int x = f.readIntL;
	int y = f.readIntL;
	int w = f.readUIntL - 40000u;
	int h = f.readUIntL;
	string imgPath = decodePathLegacy(readString(f));
	bool mask = readBool(f);
	string flag = readString(f);
	f.readByte;
	return new BgImage(imgPath, flag, x, y, w, h, mask);
}
private BgImage[] readBgImages(ref ByteIO f) {
	BgImage[] bgImgs;
	bgImgs.length = f.readUIntL;
	for (uint i = 0u; i < bgImgs.length; i++) {
		bgImgs[i] = readBgImage(f);
	}
	if (!bgImgs.length) return bgImgs;
	BgImage b = bgImgs[0u];
	if (b.path == "" && b.flag == ""
			&& b.x == 0 && b.y == 0 && b.width == 632 && b.height == 420 && !b.mask) {
		// クラシックなエンジンでは必ず1枚以上の背景画像が必要であるため、
		// ダミーのイメージが挿入されている
		return bgImgs[1u .. $];
	} else {
		return bgImgs;
	}
}
private Area loadArea(in RData d, ref ByteIO f) {
	f.readByte;
	f.readUIntL;
	string name = readString(f);
	ulong id = f.readUIntL - 40000u;
	auto a = new Area(id, name);
	uint evtNum = f.readUIntL;
	for (uint i = 0; i < evtNum; i++) {
		a.add(readEventTree(d, f));
	}
	a.spAuto = !readBool(f);
	uint cNum = f.readUIntL;
	for (uint i = 0; i < cNum; i++) {
		f.readByte;
		string img = readImage(d, f);
		string cName = readString(f);
		f.readUIntL;
		string desc = readString(f);
		uint cEvtNum = f.readUIntL;
		EventTree[] trees;
		trees.length = cEvtNum;
		for (uint j = 0; j < cEvtNum; j++) {
			trees[j] = readEventTree(d, f);
		}
		string flag = readString(f);
		real scale = f.readUIntL / 100.0;
		int x = f.readIntL;
		int y = f.readIntL;
		string imgPath = decodePathLegacy(readString(f));
		auto c = new MenuCard(cName, imgPath.length ? imgPath : img, desc, flag, x, y, scale);
		foreach (tree; trees) {
			c.add(tree);
		}
		a.append(c);
	}
	foreach (bg; readBgImages(f)) {
		a.append(bg);
	}
	return a;
}
private Battle loadBattle(in RData d, ref ByteIO f) {
	f.readByte;
	f.readUIntL;
	string name = readString(f);
	ulong id = f.readUIntL - 40000;
	auto r = new Battle(id, name, "");
	uint evtNum = f.readUIntL;
	for (uint i = 0u; i < evtNum; i++) {
		r.add(readEventTree(d, f));
	}
	r.spAuto = !readBool(f);
	uint cNum = f.readUIntL;
	for (uint i = 0u; i < cNum; i++) {
		ulong cId = f.readUIntL;
		uint cEvtNum = f.readUIntL;
		EventTree[] cTrees;
		cTrees.length = cEvtNum;
		for (uint j = 0u; j < cEvtNum; j++) {
			cTrees[j] = readEventTree(d, f);
		}
		string flag = readString(f);
		real scale = f.readUIntL / 100.0;
		int x = f.readIntL;
		int y = f.readIntL;
		bool escape = readBool(f);
		auto c = new EnemyCard(cId, escape, flag, x, y, scale);
		foreach (tree; cTrees) {
			c.add(tree);
		}
		r.append(c);
	}
	r.music = decodePathLegacy(readString(f));
	return r;
}
private Package loadPackage(in RData d, ref ByteIO f) {
	f.readUIntL;
	string name = readString(f);
	ulong id = f.readUIntL;
	auto r = new Package(id, name);
	uint evtNum = f.readUIntL;
	for (uint i = 0u; i < evtNum; i++) {
		r.add(readCEventTree(d, f));
	}
	return r;
}
private CastCard loadCast(in RData d, ref ByteIO f) {
	f.readByte;
	string img = readImage(d, f);
	string name = readString(f);
	ulong id = f.readUIntL - 40000;
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
	for (uint i = 0u; i < itmNum; i++) {
		r.add(loadItem(d, f));
	}
	uint sklNum = f.readUIntL;
	for (uint i = 0u; i < sklNum; i++) {
		r.add(loadSkill(d, f));
	}
	uint bstNum = f.readUIntL;
	for (uint i = 0u; i < bstNum; i++) {
		r.add(loadBeast(d, f));
	}
	uint cpnNum = f.readUIntL;
	Coupon[] cpns;
	cpns.length = cpnNum;
	for (uint i = 0u; i < cpnNum; i++) {
		string coupon = readString(f);
		int val = f.readIntL;
		cpns[i] = new Coupon(coupon, val);
	}
	r.coupons = cpns;
	return r;
}
private C readEffCard(C)(in RData d, ref ByteIO f) {
	f.readByte;
	string img = readImage(d, f);
	string name = readString(f);
	ulong id = f.readUIntL - 40000;
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
	for (uint i = 0u; i < mNum; i++) {
		motions[i] = readMotion(d, f);
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
	for (uint i = 0u; i < 5u; i++) {
		keyCodes[i] = readString(f);
	}
	r.keyCodes = keyCodes;
	r.premium = toPremium(f.readByte);
	r.scenario = readString(f);
	r.author = readString(f);
	uint evtNum = f.readUIntL;
	for (uint i = 0u; i < evtNum; i++) {
		r.add(readCEventTree(d, f));
	}
	return r;
}
private SkillCard loadSkill(in RData d, ref ByteIO f) {
	auto r = readEffCard!(SkillCard)(d, f);
	r.hold = readBool(f);
	r.level = f.readUIntL;
	r.useLimit = f.readUIntL;
	return r;
}
private ItemCard loadItem(in RData d, ref ByteIO f) {
	auto r = readEffCard!(ItemCard)(d, f);
	r.hold = readBool(f);
	r.useLimit = f.readUIntL;
	r.useLimitMax = f.readUIntL;
	r.price = f.readUIntL;
	r.enhanceOwner(Enhance.AVOID, f.readUIntL);
	r.enhanceOwner(Enhance.RESIST, f.readUIntL);
	r.enhanceOwner(Enhance.DEFENSE, f.readUIntL);
	return r;
}
private BeastCard loadBeast(in RData d, ref ByteIO f) {
	auto r = readEffCard!(BeastCard)(d, f);
	readBool(f); // Hold
	r.useLimit = f.readUIntL;
	return r;
}
private InfoCard loadInfo(in RData d, ref ByteIO f) {
	f.readByte;
	string img = readImage(d, f);
	string name = readString(f);
	ulong id = f.readUIntL - 40000;
	string desc = readString(f);
	return new InfoCard(id, name, img, desc);
}

struct SData {
	string sPath;
	bool saveInnerImagePath;
}
/// 4.0形式のCardWirthシナリオを保存する。
void saveLScenario(Summary summ, bool saveInnerImagePath = false) {
	auto d = SData(summ.scenarioPath, saveInnerImagePath);
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
		int save() {
			foreach (a; areas) {
				auto file = "~Area" ~ to!(string)(a.id) ~ ".wid";
				ByteIO f;
				writeArea(d, f, a);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			foreach (a; battles) {
				auto file = "~Battle" ~ to!(string)(a.id) ~ ".wid";
				ByteIO f;
				writeBattle(d, f, a);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			foreach (a; packages) {
				auto file = "~Package" ~ to!(string)(a.id) ~ ".wid";
				ByteIO f;
				writePackage(d, f, a);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			foreach (c; casts) {
				auto file = "~Mate" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeCast(d, f, c);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			foreach (c; skills) {
				auto file = "~Skill" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeSkill(d, f, c);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			foreach (c; items) {
				auto file = "~Item" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeItem(d, f, c);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			foreach (c; beasts) {
				auto file = "~Beast" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeBeast(d, f, c);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			foreach (c; infos) {
				auto file = "~Info" ~ to!(string)(c.id) ~ ".wid";
				ByteIO f;
				writeInfo(d, f, c);
				std.file.write(std.path.join(d.sPath, file), f.bytes);
				wids ~= file;
			}
			return 0;
		}
		void rename() {
			foreach (file; wids) {
				std.file.rename(std.path.join(d.sPath, file), std.path.join(d.sPath, file[1u .. $]));
			}
		}
	}
	auto save1 = new Save;
	auto save2 = new Save;
	{
		auto file = "~Summary.wsm";
		ByteIO f;
		writeSummary(d, f, summ);
		std.file.write(std.path.join(d.sPath, file), f.bytes);
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
	version (TwinIO) {
		auto thr = new Thread(&save2.save);
		thr.start;
		save1.save;
		thr.wait;
	} else {
		save1.save;
		save2.save;
	}
	foreach (file; clistdir(d.sPath)) {
		if (std.path.fnmatch(file, "Summary.wsm")
				|| !std.regex.match(toUTF32(file), .regex!(dstring)("^(Area|Battle|Package|Mate|Skill|Item|Beast|Info)[0-9]+\\.wid$"d)).empty) {
			scope path = std.path.join(d.sPath, file);
			preRemove(path);
			std.file.remove(path);
		}
	}
	save1.rename;
	save2.rename;
}

private byte fromTarget(Target v) {
	if (v.m == Target.M.UNSELECTED) return 2;
	if (v.sleep) {
		switch (v.m) {
		case Target.M.SELECTED: return 3;
		case Target.M.RANDOM: return 4;
		case Target.M.PARTY: return 5;
		default: throw new SummaryException("Unknown target value with sleep: " ~ to!(string)(cast(int) v.m));
		}
	} else {
		switch (v.m) {
		case Target.M.SELECTED: return 0;
		case Target.M.RANDOM: return 1;
		case Target.M.PARTY: return 6;
		default: throw new SummaryException("Unknown target value: " ~ to!(string)(cast(int) v.m));
		}
	}
}
private byte fromEffectType(EffectType v) {
	switch (v) {
	case EffectType.PHYSIC: return 0;
	case EffectType.MAGIC: return 1;
	case EffectType.MAGICAL_PHYSIC: return 2;
	case EffectType.PHYSICAL_MAGIC: return 3;
	case EffectType.NONE: return 4;
	default: throw new SummaryException("Unknown effect type value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromResist(Resist v) {
	switch (v) {
	case Resist.AVOID: return 0;
	case Resist.RESIST: return 1;
	case Resist.UNFAIL: return 2;
	default: throw new SummaryException("Unknown resist value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromCardVisual(CardVisual v) {
	switch (v) {
	case CardVisual.NONE: return 0;
	case CardVisual.REVERSE: return 1;
	case CardVisual.HORIZONTAL: return 2;
	case CardVisual.VERTICAL: return 3;
	default: throw new SummaryException("Unknown card visual value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromRange(Range v) {
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
private byte fromStatus(Status v) {
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
	default: throw new SummaryException("Unknown status value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromElement(Element v) {
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
private byte fromDamageType(DamageType v) {
	switch (v) {
	case DamageType.LEVEL_RATIO: return 0;
	case DamageType.NORMAL: return 1;
	case DamageType.MAX: return 2;
	default: throw new SummaryException("Unknown damage type value: " ~ to!(string)(cast(int) v));
	}
}
private uint fromPhysical(Physical v) {
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
private int fromMental(Mental v) {
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
private byte fromMentality(Mentality v) {
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
private byte fromCardTarget(CardTarget v) {
	switch (v) {
	case CardTarget.NONE: return 0;
	case CardTarget.USER: return 1;
	case CardTarget.PARTY: return 2;
	case CardTarget.ENEMY: return 3;
	case CardTarget.BOTH: return 4;
	default: throw new SummaryException("Unknown card target value: " ~ to!(string)(cast(int) v));
	}
}
private byte fromPremium(Premium v) {
	switch (v) {
	case Premium.NORMAL: return 0;
	case Premium.RARE: return 1;
	case Premium.PREMIUM: return 2;
	default: throw new SummaryException("Unknown card premium value: " ~ to!(string)(cast(int) v));
	}
}
private const B_IMG_REF = ":INNER_BINARY_IMAGE";
private void writeBool(ref ByteIO f, bool b) {
	f.writeL(cast(byte) (b ? 1 : 0));
}
private void writeImage(in SData d, ref ByteIO f, string imgPath) {
	if (!imgPath.length) {
		f.writeL(cast(uint) 0);
		return;
	}
	ubyte[] bytes;
	if (isBinImg(imgPath)) {
		bytes = cast(ubyte[]) strToBImg(imgPath);
	} else {
		bytes = cast(ubyte[]) std.file.read(std.path.join(d.sPath, imgPath));
		if (d.saveInnerImagePath) {
			bytes ~= '\0';
			bytes ~= cast(ubyte[]) (imgPath ~ B_IMG_REF);
		}
	}
	f.writeL(cast(uint) bytes.length);
	f.write(bytes);
}
private void writeString(ref ByteIO f, string str, bool lns = false, bool cutText = false) {
	str = replace(str, "\n", "\r\n");
	if (cutText) {
		str = "TEXT\r\n" ~ str;
	}
	if (str.length) {
		str = tosjis(str);
		if (!lns) str ~= "\0";
		f.writeL(cast(uint) str.length);
		f.writeL(cast(ubyte[]) str);
	} else {
		if (lns) {
			f.writeL(cast(uint) 0);
		} else {
			f.writeL(cast(uint) 1);
			f.writeL(cast(char) 0x0);
		}
	}
}
private void writeStrings(ref ByteIO f, string[] strs) {
	if (strs.length) {
		auto s = std.string.join(strs, "\n");
		if (s.length && s[$ - 1] != '\n') s ~= '\n';
		writeString(f,  s, true);
	} else {
		f.writeL(cast(uint) 0);
	}
}

private void writeSummary(in SData d, ref ByteIO f, Summary summ) {
	writeImage(d, f, summ.imagePath);
	writeString(f, summ.scenarioName);
	writeString(f, summ.desc, true);
	writeString(f, summ.author);
	writeStrings(f, summ.rCoupons);
	f.writeL(cast(uint) summ.rCouponNum);
	f.writeL(cast(uint) (summ.startArea + 40000u));
	auto steps = summ.flagDirRoot.allSteps;
	f.writeL(cast(uint) steps.length);
	foreach (step; steps) {
		writeString(f, step.path);
		f.writeL(cast(uint) step.select);
		for (uint i = 0u; i < 10u; i++) {
			if (i < step.count) {
				writeString(f, step.getValue(i));
			} else {
				writeString(f, "Step - " ~ to!(string)(i + 1u));
			}
		}
	}
	auto flags = summ.flagDirRoot.allFlags;
	f.writeL(cast(uint) flags.length);
	foreach (flag; flags) {
		writeString(f, flag.path);
		writeBool(f, flag.onOff);
		writeString(f, flag.on);
		writeString(f, flag.off);
	}
	f.writeL(cast(uint) 0u);
	f.writeL(cast(uint) summ.levelMin);
	f.writeL(cast(uint) summ.levelMax);
}
private void writeMotion(in SData d, ref ByteIO f, Motion m) {
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
	default: assert (0);
	}
	f.write(tType);
	f.writeL(cast(byte) 0x8);
	f.writeL(cast(byte) 0x4);
	f.writeL(cast(byte) 0x0);
	f.writeL(cast(byte) 0x0);
	f.writeL(cast(byte) 0x0);
	f.write(fromElement(m.element));
	if (tType != 8) {
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
		auto beast = m.beast;
		if (beast) {
			f.writeL(cast(uint) 0x1);
			writeBeast(d, f, beast);
		} else {
			f.writeL(cast(uint) 0x0);
		}
		break;
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private void writeContent(in SData d, ref ByteIO f, Content e) {
	auto dt = e.detail;
	void wb(byte type) {
		f.write(type);
		writeString(f, e.name);
		if (dt.owner) {
			f.writeL(cast(uint) 40000 + e.next.length);
			foreach (child; e.next) {
				writeContent(d, f, child);
			}
		} else {
			f.writeL(cast(uint) 40000);
		}
	}
	if (e.type is CType.START) {
		wb(0);
	} else if (e.type is CType.LINK_START) {
		wb(1);
		writeString(f, e.start);
	} else if (e.type is CType.START_BATTLE) {
		wb(2);
		f.writeL(cast(uint) e.battle);
	} else if (e.type is CType.END) {
		wb(3);
		writeBool(f, e.complete);
	} else if (e.type is CType.END_BAD_END) {
		wb(4);
	} else if (e.type is CType.CHANGE_AREA) {
		wb(5);
		f.writeL(cast(uint) e.area);
	} else if (e.type is CType.TALK_MESSAGE) {
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
	} else if (e.type is CType.PLAY_BGM) {
		wb(7);
		writeString(f, encodePathLegacy(e.bgmPath));
	} else if (e.type is CType.CHANGE_BG_IMAGE) {
		wb(8);
		writeBgImages(f, e.backs);
	} else if (e.type is CType.PLAY_SOUND) {
		wb(9);
		writeString(f, encodePathLegacy(e.soundPath));
	} else if (e.type is CType.WAIT) {
		wb(10);
		f.writeL(cast(uint) e.wait);
	} else if (e.type is CType.EFFECT) {
		wb(11);
		f.writeL(cast(uint) e.level);
		byte targ = fromTarget(e.targetNS);
		if (targ == 6) targ = 2;
		f.write(targ);
		f.write(fromEffectType(e.effectType));
		f.write(fromResist(e.resist));
		f.writeL(cast(int) e.successRate);
		writeString(f, e.soundPath.length ? encodePathLegacy(e.soundPath) : "（なし）");
		f.write(fromCardVisual(e.cardVisual));
		f.writeL(cast(uint) e.motions.length);
		foreach (m; e.motions) {
			writeMotion(d, f, m);
		}
	} else if (e.type is CType.BRANCH_SELECT) {
		wb(12);
		writeBool(f, e.targetAll);
		writeBool(f, e.random);
	} else if (e.type is CType.BRANCH_ABILITY) {
		wb(13);
		f.writeL(cast(uint) e.level);
		f.write(fromTarget(e.targetS));
		f.writeL(cast(uint) fromPhysical(e.physical));
		f.writeL(cast(int) fromMental(e.mental));
	} else if (e.type is CType.BRANCH_RANDOM) {
		wb(14);
		f.writeL(cast(uint) e.percent);
	} else if (e.type is CType.BRANCH_FLAG) {
		wb(15);
		writeString(f, e.flag);
	} else if (e.type is CType.SET_FLAG) {
		wb(16);
		writeString(f, e.flag);
		writeBool(f, e.flagValue);
	} else if (e.type is CType.BRANCH_MULTI_STEP) {
		wb(17);
		writeString(f, e.step);
	} else if (e.type is CType.SET_STEP) {
		wb(18);
		writeString(f, e.step);
		f.writeL(cast(uint) e.stepValue);
	} else if (e.type is CType.BRANCH_CAST) {
		wb(19);
		f.writeL(cast(uint) e.casts);
	} else if (e.type is CType.BRANCH_ITEM) {
		wb(20);
		f.writeL(cast(uint) e.item);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_SKILL) {
		wb(21);
		f.writeL(cast(uint) e.skill);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_INFO) {
		wb(22);
		f.writeL(cast(uint) e.info);
	} else if (e.type is CType.BRANCH_BEAST) {
		wb(23);
		f.writeL(cast(uint) e.beast);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_MONEY) {
		wb(24);
		f.writeL(cast(uint) e.money);
	} else if (e.type is CType.BRANCH_COUPON) {
		wb(25);
		writeString(f, e.coupon);
		f.writeL(cast(int) 0x0);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_CAST) {
		wb(26);
		f.writeL(cast(uint) e.casts);
	} else if (e.type is CType.GET_ITEM) {
		wb(27);
		f.writeL(cast(uint) e.item);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_SKILL) {
		wb(28);
		f.writeL(cast(uint) e.skill);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_INFO) {
		wb(29);
		f.writeL(cast(uint) e.info);
	} else if (e.type is CType.GET_BEAST) {
		wb(30);
		f.writeL(cast(uint) e.beast);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_MONEY) {
		wb(31);
		f.writeL(cast(uint) e.money);
	} else if (e.type is CType.GET_COUPON) {
		wb(32);
		writeString(f, e.coupon);
		f.writeL(cast(int) e.couponValue);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_CAST) {
		wb(33);
		f.writeL(cast(uint) e.casts);
	} else if (e.type is CType.LOSE_ITEM) {
		wb(34);
		f.writeL(cast(uint) e.item);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_SKILL) {
		wb(35);
		f.writeL(cast(uint) e.skill);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_INFO) {
		wb(36);
		f.writeL(cast(uint) e.info);
	} else if (e.type is CType.LOSE_BEAST) {
		wb(37);
		f.writeL(cast(uint) e.beast);
		f.writeL(cast(uint) e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_MONEY) {
		wb(38);
		f.writeL(cast(uint) e.money);
	} else if (e.type is CType.LOSE_COUPON) {
		wb(39);
		writeString(f, e.coupon);
		f.writeL(cast(int) 0x0);
		f.write(fromRange(e.range));
	} else if (e.type is CType.TALK_DIALOG) {
		wb(40);
		switch (e.talkerNC) {
		case Talker.SELECTED: f.writeL(cast(byte) 0); break;
		case Talker.RANDOM: f.writeL(cast(byte) 1); break;
		case Talker.UNSELECTED: f.writeL(cast(byte) 2); break;
		default: throw new SummaryException("Unknown talker value: " ~ to!(string)(cast(int) e.talkerNC));
		}
		f.writeL(cast(uint) e.dialogs.length);
		foreach (dlg; e.dialogs) {
			writeStrings(f, dlg.rCoupons);
			writeString(f, lastRet(dlg.text), true);
		}
	} else if (e.type is CType.SET_STEP_UP) {
		wb(41);
		writeString(f, e.step);
	} else if (e.type is CType.SET_STEP_DOWN) {
		wb(42);
		writeString(f, e.step);
	} else if (e.type is CType.REVERSE_FLAG) {
		wb(43);
		writeString(f, e.flag);
	} else if (e.type is CType.BRANCH_STEP) {
		wb(44);
		writeString(f, e.step);
		f.writeL(cast(uint) e.stepValue);
	} else if (e.type is CType.ELAPSE_TIME) {
		wb(45);
	} else if (e.type is CType.BRANCH_LEVEL) {
		wb(46);
		writeBool(f, e.average);
		f.writeL(cast(uint) e.level);
	} else if (e.type is CType.BRANCH_STATUS) {
		wb(47);
		f.write(fromStatus(e.status));
		f.write(fromTarget(e.targetNS));
	} else if (e.type is CType.BRANCH_PARTY_NUMBER) {
		wb(48);
		f.writeL(cast(uint) e.partyNumber);
	} else if (e.type is CType.SHOW_PARTY) {
		wb(49);
	} else if (e.type is CType.HIDE_PARTY) {
		wb(50);
	} else if (e.type is CType.EFFECT_BREAK) {
		wb(51);
	} else if (e.type is CType.CALL_START) {
		wb(52);
		writeString(f, e.start);
	} else if (e.type is CType.LINK_PACKAGE) {
		wb(53);
		f.writeL(cast(uint) e.packages);
	} else if (e.type is CType.CALL_PACKAGE) {
		wb(54);
		f.writeL(cast(uint) e.packages);
	} else if (e.type is CType.BRANCH_AREA) {
		wb(55);
	} else if (e.type is CType.BRANCH_BATTLE) {
		wb(56);
	} else if (e.type is CType.BRANCH_COMPLETE_STAMP) {
		wb(57);
		writeString(f, e.completeStamp);
	} else if (e.type is CType.GET_COMPLETE_STAMP) {
		wb(58);
		writeString(f, e.completeStamp);
	} else if (e.type is CType.LOSE_COMPLETE_STAMP) {
		wb(59);
		writeString(f, e.completeStamp);
	} else if (e.type is CType.BRANCH_GOSSIP) {
		wb(60);
		writeString(f, e.gossip);
	} else if (e.type is CType.GET_GOSSIP) {
		wb(61);
		writeString(f, e.gossip);
	} else if (e.type is CType.LOSE_GOSSIP) {
		wb(62);
		writeString(f, e.gossip);
	} else if (e.type is CType.BRANCH_IS_BATTLE) {
		wb(63);
	} else if (e.type is CType.REDISPLAY) {
		wb(64);
	} else if (e.type is CType.CHECK_FLAG) {
		wb(65);
		writeString(f, e.flag);
	} else {
		assert (0, "event");
	}
}
private void writeCEventTree(in SData d, ref ByteIO f, EventTree tree) {
	f.writeL(cast(uint) tree.starts.length);
	foreach (evt; tree.starts) {
		writeContent(d, f, evt);
	}
}
private void writeEventTree(in SData d, ref ByteIO f, EventTree tree) {
	f.writeL(cast(uint) tree.starts.length);
	foreach (evt; tree.starts) {
		writeContent(d, f, evt);
	}
	int[] igs;
	if (tree.fireEnter) igs ~= 1;
	if (tree.fireEscape) igs ~= 2;
	if (tree.fireLose) igs ~= 3;
	foreach (rnd; tree.rounds) {
		igs ~= -(cast(int) rnd);
	}
	f.writeL(cast(uint) igs.length);
	foreach (ig; igs) {
		f.writeL(cast(int) ig);
	}
	writeStrings(f, tree.keyCodes);
}
private void writeBgImage(ref ByteIO f, BgImage b) {
	f.writeL(cast(int) b.x);
	f.writeL(cast(int) b.y);
	f.writeL(cast(uint) b.width + 40000u);
	f.writeL(cast(uint) b.height);
	writeString(f, encodePathLegacy(b.path));
	writeBool(f, b.mask);
	writeString(f, b.flag);
	f.writeL(cast(byte) 0x0);
}
private void writeBgImages(ref ByteIO f, BgImage[] backs) {
	if (backs.length && backs[0].path != "" && backs[0].flag == ""
			&& backs[0].x == 0 && backs[0].y == 0
			&& backs[0].width == 632 && backs[0].height == 420 && !backs[0].mask) {
		f.writeL(cast(uint) backs.length);
	} else {
		f.writeL(cast(uint) backs.length + 1u);
		writeBgImage(f, new BgImage("", "", 0, 0, 632, 420, false));
	}
	foreach (b; backs) {
		writeBgImage(f, b);
	}
}
private void writeArea(in SData d, ref ByteIO f, Area a) {
	f.writeL(cast(byte) 0x0);
	f.writeL(cast(uint) 0x0);
	writeString(f, a.name);
	f.writeL(cast(uint) (a.id + 40000u));
	f.writeL(cast(uint) a.trees.length);
	foreach (tree; a.trees) {
		writeEventTree(d, f, tree);
	}
	writeBool(f, !a.spAuto);
	f.writeL(cast(uint) a.cards.length);
	foreach (c; a.cards) {
		f.writeL(cast(byte) 0x0);
		writeImage(d, f, isBinImg(c.path) ? c.path : "");
		writeString(f, c.name);
		f.writeL(cast(byte) 0x40);
		f.writeL(cast(byte) 0x9C);
		f.writeL(cast(byte) 0x0);
		f.writeL(cast(byte) 0x0);
		writeString(f, c.desc);
		f.writeL(cast(uint) c.trees.length);
		foreach (tree; c.trees) {
			writeEventTree(d, f, tree);
		}
		writeString(f, c.flag);
		f.writeL(cast(uint) rndtol(c.scale * 100.0));
		f.writeL(cast(int) c.x);
		f.writeL(cast(int) c.y);
		writeString(f, isBinImg(c.path) ? "" : encodePathLegacy(c.path));
	}
	writeBgImages(f, a.backs);
}
private void writeBattle(in SData d, ref ByteIO f, Battle a) {
	f.writeL(cast(byte) 0x1);
	f.writeL(cast(uint) 0x0);
	writeString(f, a.name);
	f.writeL(cast(uint) (a.id + 40000u));
	f.writeL(cast(uint) a.trees.length);
	foreach (tree; a.trees) {
		writeEventTree(d, f, tree);
	}
	writeBool(f, !a.spAuto);
	f.writeL(cast(uint) a.cards.length);
	foreach (c; a.cards) {
		f.writeL(cast(uint) c.id);
		f.writeL(cast(uint) c.trees.length);
		foreach (tree; c.trees) {
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
private void writePackage(in SData d, ref ByteIO f, Package a) {
	f.writeL(cast(uint) 0x4);
	writeString(f, a.name);
	f.writeL(cast(uint) a.id);
	f.writeL(cast(uint) a.trees.length);
	foreach (tree; a.trees) {
		writeCEventTree(d, f, tree);
	}
}
private void writeCast(in SData d, ref ByteIO f, CastCard c) {
	f.writeL(cast(byte) 0x2);
	writeImage(d, f, c.path);
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
	f.writeL(cast(int) c.enhance(Enhance.ACTION));
	f.writeL(cast(uint) c.enhanceRound(Enhance.ACTION));
	f.writeL(cast(int) c.enhance(Enhance.AVOID));
	f.writeL(cast(uint) c.enhanceRound(Enhance.AVOID));
	f.writeL(cast(int) c.enhance(Enhance.RESIST));
	f.writeL(cast(uint) c.enhanceRound(Enhance.RESIST));
	f.writeL(cast(int) c.enhance(Enhance.DEFENSE));
	f.writeL(cast(uint) c.enhanceRound(Enhance.DEFENSE));
	f.writeL(cast(uint) c.items.length);
	foreach (cc; c.items) {
		writeItem(d, f, cc);
	}
	f.writeL(cast(uint) c.skills.length);
	foreach (cc; c.skills) {
		writeSkill(d, f, cc);
	}
	f.writeL(cast(uint) c.beasts.length);
	foreach (cc; c.beasts) {
		writeBeast(d, f, cc);
	}
	f.writeL(cast(uint) c.coupons.length);
	foreach (cc; c.coupons) {
		writeString(f, cc.name);
		f.writeL(cast(int) cc.value);
	}
}
private void writeEffCard(in SData d, ref ByteIO f, EffectCard c, byte type) {
	f.write(type);
	writeImage(d, f, c.path);
	writeString(f, c.name);
	f.writeL(cast(uint) (c.id + 40000u));
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
	foreach (m; c.motions) {
		writeMotion(d, f, m);
	}
	f.writeL(cast(int) c.enhance(Enhance.AVOID));
	f.writeL(cast(int) c.enhance(Enhance.RESIST));
	f.writeL(cast(int) c.enhance(Enhance.DEFENSE));
	writeString(f, c.soundPath1.length ? encodePathLegacy(c.soundPath1) : "（なし）");
	writeString(f, c.soundPath2.length ? encodePathLegacy(c.soundPath2) : "（なし）");
	for (uint i = 0u; i < 5u; i++) {
		if (i < c.keyCodes.length) {
			writeString(f, c.keyCodes[i]);
		} else {
			writeString(f, "");
		}
	}
	f.write(fromPremium(c.premium));
	writeString(f, c.scenario);
	writeString(f, c.author);
	f.writeL(cast(uint) c.trees.length);
	foreach (tree; c.trees) {
		writeCEventTree(d, f, tree);
	}
}
private void writeSkill(in SData d, ref ByteIO f, SkillCard c) {
	writeEffCard(d, f, c, 0x5);
	writeBool(f, c.hold);
	f.writeL(cast(uint) c.level);
	f.writeL(cast(uint) c.useLimit);
}
private void writeItem(in SData d, ref ByteIO f, ItemCard c) {
	writeEffCard(d, f, c, 0x3);
	writeBool(f, c.hold);
	f.writeL(cast(uint) c.useLimit);
	f.writeL(cast(uint) c.useLimitMax);
	f.writeL(cast(uint) c.price);
	f.writeL(cast(int) c.enhanceOwner(Enhance.AVOID));
	f.writeL(cast(int) c.enhanceOwner(Enhance.RESIST));
	f.writeL(cast(int) c.enhanceOwner(Enhance.DEFENSE));
}
private void writeBeast(in SData d, ref ByteIO f, BeastCard c) {
	writeEffCard(d, f, c, 0x6);
	writeBool(f, false); // Hold
	f.writeL(cast(uint) c.useLimit);
}
private void writeInfo(in SData d, ref ByteIO f, InfoCard c) {
	f.writeL(cast(byte) 0x4);
	writeImage(d, f, c.path);
	writeString(f, c.name);
	f.writeL(cast(uint) (c.id + 40000u));
	writeString(f, c.desc);
}
