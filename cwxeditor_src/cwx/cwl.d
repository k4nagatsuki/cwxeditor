
module cwx.cwl;

import std.stream;
import std.c.string;

import std.file;
import std.path;
import std.math;
import std.string;

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
		loadLScenario!(CardContainer!(true, true, true, true, false))("", "");
	} catch {}
}

/// 4.0形式のCardWirthシナリオを読込む。
S loadLScenario(S)(string p, string skin) {
	auto sPath = p;
	auto summPath = std.path.join(p, "Summary.wsm");
	if (!exists(summPath)) throw new SummaryException("Not Scenario: " ~ p);
	S summ;
	ulong startAreaId;
	{
		auto f = new std.stream.BufferedFile(summPath);
		scope (exit) f.close;
		summ = loadSummary!(S)(f, skin, sPath, startAreaId);
	}
	static if (is (typeof(summ.areas))) Area[] areas;
	static if (is (typeof(summ.battles))) Battle[] battles;
	static if (is (typeof(summ.packages))) Package[] packages;
	static if (is (typeof(summ.casts))) CastCard[] casts;
	static if (is (typeof(summ.skills))) SkillCard[] skills;
	static if (is (typeof(summ.items))) ItemCard[] items;
	static if (is (typeof(summ.beasts))) BeastCard[] beasts;
	static if (is (typeof(summ.infos))) InfoCard[] infos;
	foreach (file; listdir(sPath)) {
		file = std.path.join(sPath, file);
		try {
			if (fnmatch(getExt(file), "wid")) {
				auto f = new std.stream.BufferedFile(file);
				scope (exit) f.close;
				bool sWith(string f, string s) {
					return f.length > s.length && fnmatch(f[0u .. s.length], s);
				}
				auto base = getBaseName(file);
				static if (is (typeof(summ.areas))) if (sWith(base, "Area")) {
					areas ~= loadArea(f);
				}
				static if (is (typeof(summ.battles))) if (sWith(base, "Battle")) {
					battles ~= loadBattle(f);
				}
				static if (is (typeof(summ.packages))) if (sWith(base, "Package")) {
					packages ~= loadPackage(f);
				}
				static if (is (typeof(summ.casts))) if (sWith(base, "Mate")) {
					casts ~= loadCast(f);
				}
				static if (is (typeof(summ.skills))) if (sWith(base, "Skill")) {
					skills ~= loadSkill(f);
				}
				static if (is (typeof(summ.items))) if (sWith(base, "Item")) {
					items ~= loadItem(f);
				}
				static if (is (typeof(summ.beasts))) if (sWith(base, "Beast")) {
					beasts ~= loadBeast(f);
				}
				static if (is (typeof(summ.infos))) if (sWith(base, "Info")) {
					infos ~= loadInfo(f);
				}
			}
		} catch (Exception e) {
			debugln(file ~ " - " ~ e.msg);
			throw e;
		}
	}
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
		static if (is (typeof(summ.areas))) foreach (a; areas.sort) summ.add(a);
		static if (is (typeof(summ.battles))) foreach (a; battles.sort) summ.add(a);
		static if (is (typeof(summ.packages))) foreach (a; packages.sort) summ.add(a);
		static if (is (typeof(summ.casts))) foreach (a; casts.sort) summ.add(a);
		static if (is (typeof(summ.skills))) foreach (a; skills.sort) summ.add(a);
		static if (is (typeof(summ.items))) foreach (a; items.sort) summ.add(a);
		static if (is (typeof(summ.beasts))) foreach (a; beasts.sort) summ.add(a);
		static if (is (typeof(summ.infos))) foreach (a; infos.sort) summ.add(a);
	}
	return summ;
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
	case 1: return Mentality.PANIC;
	case 2: return Mentality.BRAVE;
	case 3: return Mentality.OVERHEAT;
	case 4: return Mentality.CONFUSE;
	case 5: return Mentality.SLEEP;
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
private bool readBool(std.stream.InputStream f) {
	byte b;
	f.read(b);
	return b ? true : false;
}
private string readImage(std.stream.InputStream f) {
	uint len = readUIntL(f);
	if (!len) return "";
	ubyte[] img;
	img.length = len;
	f.read(img);
	return bImgToStr(cast(byte[]) img);
}
private string readString(std.stream.InputStream f, bool lns = false, bool cutText = false) {
	uint len = readUIntL(f);
	if (!len) return "";
	char[] str;
	str.length = len;
	f.read(cast(ubyte[]) str);
	if (!lns && str[$ - 1] == '\0') str = str[0 .. $ - 1];
	str = touni(str);
	if (cutText) {
		str = str.length > "TEXT\r\n".length ? str["TEXT\r\n".length .. $] : "";
	}
	str = replace(str, "\r\n", "\n");
	return str;
}
private string[] readStrings(std.stream.InputStream f) {
	auto str = readString(f, true);
	return str.length ? splitlines(str) : cast(string[]) [];
}
private S loadSummary(S)(std.stream.InputStream f, string skin, string sPath, out ulong startAreaId) {
	string img = readImage(f);
	static if (is (S == Summary)) {
		byte b;
		auto summ = new Summary(readString(f), skin, sPath, true);
		summ.imagePath = img;
		summ.desc = readString(f, true);
		summ.author = readString(f);
		summ.rCoupons = readStrings(f);
		summ.rCouponNum = readUIntL(f);
		startAreaId = readUIntL(f) - 40000u;
		FlagDir flagsParent(string path) {
			FlagDir dir = summ.flagDirRoot;
			string par = FlagDir.up(path);
			if (par.length) {
				string[] spPath = .split(par, "\\")[0u .. $ - 1u];
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
		uint stepNum = readUIntL(f);
		for (uint i = 0u; i < stepNum; i++) {
			string path = readString(f);
			uint sel = readUIntL(f);
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
		uint flagNum = readUIntL(f);
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
		readUIntL(f);
		summ.levelMin = readUIntL(f);
		summ.levelMax = readUIntL(f);
		return summ;
	} else {
		return new S(sPath, readString(f), true);
	}
}
private Motion readMotion(std.stream.InputStream f) {
	byte tType;
	f.read(tType);
	byte b;
	f.read(b);
	f.read(b);
	f.read(b);
	f.read(b);
	f.read(b);
	byte elb;
	f.read(elb);
	auto el = toElement(elb);
	byte type;
	if (tType == 8) {
		type = 0u;
	} else {
		f.read(type);
	}
	switch (tType) {
	case 0, 1: {
		byte dmgTypB;
		f.read(dmgTypB);
		auto dmgTyp = toDamageType(dmgTypB);
		uint val = readUIntL(f);
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
		uint rnd = readUIntL(f);
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
		uint val = readUIntL(f);
		uint rnd = readUIntL(f);
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
		uint bNum = readUIntL(f); // 常に0か1のはず
		for (uint i = 0u; i < bNum ; i++) {
			beast = loadBeast(f);
		}
		auto m = new Motion(MType.SUMMON_BEAST, el);
		m.beast = beast;
		return m;
	}
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private Content readContent(std.stream.InputStream f) {
	byte b;
	f.read(b);
	string name = readString(f);
	uint cNum = readUIntL(f) - 40000u;
	Content[] childs;
	childs.length = cNum;
	for (uint i = 0u; i < cNum; i++) {
		childs[i] = readContent(f);
	}
	Content e;
	switch (b) {
	case 0:
		e = new Content(CType.START, name);
		break;
	case 1:
		e = new Content(CType.LINK_START, name);
		e.start = readString(f);
		break;
	case 2:
		e = new Content(CType.START_BATTLE, name);
		e.battle = readUIntL(f);
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
		e.area = readUIntL(f);
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
		e.cardPath = msgTalker != Talker.IMAGE ? "" : msgPath;
		break;
	}
	case 7:
		e = new Content(CType.PLAY_BGM, name);
		e.bgmPath = readString(f);
		break;
	case 8: {
		BgImage[] bgImgs = readBgImages(f);
		e = new Content(CType.CHANGE_BG_IMAGE, name);
		e.bgImages = bgImgs;
		e.transition = Transition.DEFAULT;
		e.transitionSpeed = 5u;
		break;
	}
	case 9:
		e = new Content(CType.PLAY_SOUND, name);
		e.soundPath = readString(f);
		break;
	case 10:
		e = new Content(CType.WAIT, name);
		e.wait = readUIntL(f);
		break;
	case 11: {
		uint effLev = readUIntL(f);
		byte effTarget;
		f.read(effTarget);
		if (effTarget == 2) effTarget = 6;
		byte effType;
		f.read(effType);
		byte effResist;
		f.read(effResist);
		int effSuc = readIntL(f);
		string sp = readString(f);
		string effSePath = sp == "（なし）" ? "" : sp;
		byte effVis;
		f.read(effVis);
		uint effMotionNum = readUIntL(f);
		Motion[] effMotions;
		effMotions.length = effMotionNum;
		for (uint i = 0u; i < effMotionNum; i++) {
			effMotions[i] = readMotion(f);
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
		uint val = readUIntL(f);
		byte targ;
		f.read(targ);
		uint phy = readUIntL(f);
		int mtl = readIntL(f);
		e = new Content(CType.BRANCH_ABILITY, name);
		e.targetS = toTarget(targ);
		e.mental = toMental(mtl);
		e.physical = toPhysical(phy);
		e.level = val;
		break;
	}
	case 14:
		e = new Content(CType.BRANCH_RANDOM, name);
		e.percent = readUIntL(f);
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
		uint val = readUIntL(f);
		e = new Content(CType.SET_STEP, name);
		e.step = step;
		e.stepValue = val;
		break;
	}
	case 19:
		e = new Content(CType.BRANCH_CAST, name);
		e.casts = readUIntL(f);
		break;
	case 20: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.BRANCH_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 21: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.BRANCH_SKILL, name);
		e.skill = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 22:
		e = new Content(CType.BRANCH_INFO, name);
		e.info = readUIntL(f);
		break;
	case 23: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.BRANCH_BEAST, name);
		e.beast = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 24:
		e = new Content(CType.BRANCH_MONEY, name);
		e.money = readUIntL(f);
		break;
	case 25: {
		string coupon = readString(f);
		readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.BRANCH_COUPON, name);
		e.coupon = coupon;
		e.range = toRange(rng);
		break;
	}
	case 26:
		e = new Content(CType.GET_CAST, name);
		e.casts = readUIntL(f);
		break;
	case 27: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.GET_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 28: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.GET_SKILL, name);
		e.skill = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 29:
		e = new Content(CType.GET_INFO, name);
		e.info = readUIntL(f);
		break;
	case 30: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.GET_BEAST, name);
		e.beast = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 31:
		e = new Content(CType.GET_MONEY, name);
		e.money = readUIntL(f);
		break;
	case 32: {
		string coupon = readString(f);
		int val = readIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.GET_COUPON, name);
		e.coupon = coupon;
		e.range = toRange(rng);
		e.couponValue = val;
		break;
	}
	case 33:
		e = new Content(CType.LOSE_CAST, name);
		e.casts = readUIntL(f);
		break;
	case 34: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.LOSE_ITEM, name);
		e.item = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 35: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.LOSE_SKILL, name);
		e.skill = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 36:
		e = new Content(CType.LOSE_INFO, name);
		e.info = readUIntL(f);
		break;
	case 37: {
		ulong id = readUIntL(f);
		uint num = readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.LOSE_BEAST, name);
		e.beast = id;
		e.range = toRange(rng);
		e.cardNumber = num;
		break;
	}
	case 38:
		e = new Content(CType.LOSE_MONEY, name);
		e.money = readUIntL(f);
		break;
	case 39: {
		string coupon = readString(f);
		readUIntL(f);
		byte rng;
		f.read(rng);
		e = new Content(CType.LOSE_COUPON, name);
		e.coupon = coupon;
		e.range = toRange(rng);
		break;
	}
	case 40: {
		byte targ;
		f.read(targ);
		Talker t;
		switch (toTarget(targ).m) {
		case Target.M.SELECTED: t = Talker.SELECTED; break;
		case Target.M.UNSELECTED: t = Talker.UNSELECTED; break;
		case Target.M.RANDOM: t = Talker.RANDOM; break;
		default: throw new SummaryException("Unknown talker: " ~ to!(string)(targ));
		}
		uint dlgNum = readUIntL(f);
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
		uint val = readUIntL(f);
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
		uint val = readUIntL(f);
		e = new Content(CType.BRANCH_LEVEL, name);
		e.average = avg;
		e.level = val;
		break;
	}
	case 47: {
		byte stat;
		f.read(stat);
		byte targ;
		f.read(targ);
		e = new Content(CType.BRANCH_STATUS, name);
		e.targetNS = toTarget(targ);
		e.status = toStatus(stat);
		break;
	}
	case 48:
		e = new Content(CType.BRANCH_PARTY_NUMBER, name);
		e.partyNumber = readUIntL(f);
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
		e.packages = readUIntL(f);
		break;
	case 54:
		e = new Content(CType.CALL_PACKAGE, name);
		e.packages = readUIntL(f);
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
	default: throw new SummaryException("Unknown content type: " ~ to!(string)(b));
	}
	if (e.detail.owner) {
		foreach (c; childs) {
			e.add(c);
		}
	}
	return e;
}
private EventTree readCEventTree(std.stream.InputStream f) {
	auto tree = new EventTree("");
	auto dest = tree.starts[0u];
	uint cNum = readUIntL(f);
	for (uint i = 0u; i < cNum; i++) {
		tree.add(readContent(f));
	}
	tree.remove(dest);
	return tree;
}
private EventTree readEventTree(std.stream.InputStream f) {
	auto tree = new EventTree("");
	auto dest = tree.starts[0u];
	uint cNum = readUIntL(f);
	for (uint i = 0u; i < cNum; i++) {
		tree.add(readContent(f));
	}
	tree.remove(dest);
	uint igNum = readUIntL(f);
	for (uint i = 0u; i < igNum; i++) {
		int ig = readIntL(f);
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
private BgImage readBgImage(std.stream.InputStream f) {
	byte b;
	int x = readIntL(f);
	int y = readIntL(f);
	int w = readUIntL(f) - 40000u;
	int h = readUIntL(f);
	string imgPath = readString(f);
	bool mask = readBool(f);
	string flag = readString(f);
	f.read(b);
	return new BgImage(imgPath, flag, x, y, w, h, mask);
}
private BgImage[] readBgImages(std.stream.InputStream f) {
	BgImage[] bgImgs;
	bgImgs.length = readUIntL(f);
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
private Area loadArea(std.stream.InputStream f) {
	byte b;
	f.read(b);
	readUIntL(f);
	string name = readString(f);
	ulong id = readUIntL(f) - 40000u;
	auto a = new Area(id, name);
	uint evtNum = readUIntL(f);
	for (uint i = 0; i < evtNum; i++) {
		a.add(readEventTree(f));
	}
	a.spAuto = !readBool(f);
	uint cNum = readUIntL(f);
	for (uint i = 0; i < cNum; i++) {
		f.read(b);
		string img = readImage(f);
		string cName = readString(f);
		readUIntL(f);
		string desc = readString(f);
		uint cEvtNum = readUIntL(f);
		EventTree[] trees;
		trees.length = cEvtNum;
		for (uint j = 0; j < cEvtNum; j++) {
			trees[j] = readEventTree(f);
		}
		string flag = readString(f);
		real scale = readUIntL(f) / 100.0;
		int x = readIntL(f);
		int y = readIntL(f);
		string imgPath = readString(f);
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
private Battle loadBattle(std.stream.InputStream f) {
	byte b;
	f.read(b);
	readUIntL(f);
	string name = readString(f);
	ulong id = readUIntL(f) - 40000;
	auto r = new Battle(id, name, "");
	uint evtNum = readUIntL(f);
	for (uint i = 0u; i < evtNum; i++) {
		r.add(readEventTree(f));
	}
	r.spAuto = !readBool(f);
	uint cNum = readUIntL(f);
	for (uint i = 0u; i < cNum; i++) {
		ulong cId = readUIntL(f);
		uint cEvtNum = readUIntL(f);
		EventTree[] cTrees;
		cTrees.length = cEvtNum;
		for (uint j = 0u; j < cEvtNum; j++) {
			cTrees[j] = readEventTree(f);
		}
		string flag = readString(f);
		real scale = readUIntL(f) / 100.0;
		int x = readIntL(f);
		int y = readIntL(f);
		bool escape = readBool(f);
		auto c = new EnemyCard(cId, escape, flag, x, y, scale);
		foreach (tree; cTrees) {
			c.add(tree);
		}
		r.append(c);
	}
	r.music = readString(f);
	return r;
}
private Package loadPackage(std.stream.InputStream f) {
	readUIntL(f);
	string name = readString(f);
	ulong id = readUIntL(f);
	auto r = new Package(id, name);
	uint evtNum = readUIntL(f);
	for (uint i = 0u; i < evtNum; i++) {
		r.add(readCEventTree(f));
	}
	return r;
}
private CastCard loadCast(std.stream.InputStream f) {
	byte b;
	f.read(b);
	string img = readImage(f);
	string name = readString(f);
	ulong id = readUIntL(f) - 40000;
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
	r.level = readUIntL(f);
	readUIntL(f); // 所持金。現行エンジンでは未使用
	r.desc = readString(f, true, true);
	r.life = readUIntL(f);
	r.lifeMax = readUIntL(f);
	r.paralyze = readUIntL(f);
	r.poison = readUIntL(f);
	r.defaultEnhance(Enhance.AVOID, readUIntL(f));
	r.defaultEnhance(Enhance.RESIST, readUIntL(f));
	r.defaultEnhance(Enhance.DEFENSE, readUIntL(f));
	r.physical(Physical.DEX, readUIntL(f));
	r.physical(Physical.AGL, readUIntL(f));
	r.physical(Physical.INT, readUIntL(f));
	r.physical(Physical.STR, readUIntL(f));
	r.physical(Physical.VIT, readUIntL(f));
	r.physical(Physical.MIN, readUIntL(f));
	r.mental(Mental.AGGRESSIVE, readIntL(f));
	r.mental(Mental.CHEERFUL, readIntL(f));
	r.mental(Mental.BRAVE, readIntL(f));
	r.mental(Mental.CAUTIOUS, readIntL(f));
	r.mental(Mental.TRICKISH, readIntL(f));
	f.read(b);
	r.mentality = toMentality(b);
	r.mentalityRound = readUIntL(f);
	r.bindRound = readUIntL(f);
	r.silenceRound = readUIntL(f);
	r.faceUpRound = readUIntL(f);
	r.antiMagicRound = readUIntL(f);
	r.enhance(Enhance.ACTION, readUIntL(f));
	r.enhanceRound(Enhance.ACTION, readUIntL(f));
	r.enhance(Enhance.AVOID, readUIntL(f));
	r.enhanceRound(Enhance.AVOID, readUIntL(f));
	r.enhance(Enhance.RESIST, readUIntL(f));
	r.enhanceRound(Enhance.RESIST, readUIntL(f));
	r.enhance(Enhance.DEFENSE, readUIntL(f));
	r.enhanceRound(Enhance.DEFENSE, readUIntL(f));
	uint itmNum = readUIntL(f);
	for (uint i = 0u; i < itmNum; i++) {
		r.add(loadItem(f));
	}
	uint sklNum = readUIntL(f);
	for (uint i = 0u; i < sklNum; i++) {
		r.add(loadSkill(f));
	}
	uint bstNum = readUIntL(f);
	for (uint i = 0u; i < bstNum; i++) {
		r.add(loadBeast(f));
	}
	uint cpnNum = readUIntL(f);
	Coupon[] cpns;
	cpns.length = cpnNum;
	for (uint i = 0u; i < cpnNum; i++) {
		string coupon = readString(f);
		int val = readIntL(f);
		cpns[i] = new Coupon(coupon, val);
	}
	r.coupons = cpns;
	return r;
}
private C readEffCard(C)(std.stream.InputStream f) {
	byte b;
	f.read(b);
	string img = readImage(f);
	string name = readString(f);
	ulong id = readUIntL(f) - 40000;
	string desc = readString(f);
	auto r = new C(id, name, img, desc);
	r.physical = toPhysical(readUIntL(f));
	r.mental = toMental(readIntL(f));
	r.spell = readBool(f);
	r.allRange = readBool(f);
	f.read(b);
	r.target = toCardTarget(b);
	f.read(b);
	r.effectType = toEffectType(b);
	f.read(b);
	r.resist = toResist(b);
	r.successRate = readIntL(f);
	f.read(b);
	r.visual = toCardVisual(b);
	uint mNum = readUIntL(f);
	Motion[] motions;
	motions.length = mNum;
	for (uint i = 0u; i < mNum; i++) {
		motions[i] = readMotion(f);
	}
	r.motions = motions;
	r.enhance(Enhance.AVOID, readIntL(f));
	r.enhance(Enhance.RESIST, readIntL(f));
	r.enhance(Enhance.DEFENSE, readIntL(f));
	string sp1 = readString(f);
	r.soundPath1 = sp1 == "（なし）" ? "" : sp1;
	string sp2 = readString(f);
	r.soundPath2 = sp2 == "（なし）" ? "" : sp2;
	string[] keyCodes;
	keyCodes.length = 5u;
	for (uint i = 0u; i < 5u; i++) {
		keyCodes[i] = readString(f);
	}
	r.keyCodes = keyCodes;
	f.read(b);
	r.premium = toPremium(b);
	r.scenario = readString(f);
	r.author = readString(f);
	uint evtNum = readUIntL(f);
	for (uint i = 0u; i < evtNum; i++) {
		r.add(readCEventTree(f));
	}
	return r;
}
private SkillCard loadSkill(std.stream.InputStream f) {
	auto r = readEffCard!(SkillCard)(f);
	r.hold = readBool(f);
	r.level = readUIntL(f);
	r.useLimit = readUIntL(f);
	return r;
}
private ItemCard loadItem(std.stream.InputStream f) {
	auto r = readEffCard!(ItemCard)(f);
	r.hold = readBool(f);
	r.useLimit = readUIntL(f);
	r.useLimitMax = readUIntL(f);
	r.price = readUIntL(f);
	r.enhanceOwner(Enhance.AVOID, readUIntL(f));
	r.enhanceOwner(Enhance.RESIST, readUIntL(f));
	r.enhanceOwner(Enhance.DEFENSE, readUIntL(f));
	return r;
}
private BeastCard loadBeast(std.stream.InputStream f) {
	auto r = readEffCard!(BeastCard)(f);
	readBool(f); // Hold
	r.useLimit = readUIntL(f);
	return r;
}
private InfoCard loadInfo(std.stream.InputStream f) {
	byte b;
	f.read(b);
	string img = readImage(f);
	string name = readString(f);
	ulong id = readUIntL(f) - 40000;
	string desc = readString(f);
	return new InfoCard(id, name, img, desc);
}

/// 4.0形式のCardWirthシナリオを保存する。
void saveLScenario(Summary summ) {
	scope wids = new HashSet!(string);
	string scName = summ.scenarioName;
	string scPath = summ.scenarioPath;
	{
		auto file = "~Summary.wsm";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeSummary(f, summ);
		wids.add(file);
	}
	foreach (a; summ.areas) {
		auto file = "~Area" ~ to!(string)(a.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeArea(f, scName, scPath, a);
		wids.add(file);
	}
	foreach (a; summ.battles) {
		auto file = "~Battle" ~ to!(string)(a.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeBattle(f, scName, scPath, a);
		wids.add(file);
	}
	foreach (a; summ.packages) {
		auto file = "~Package" ~ to!(string)(a.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writePackage(f, scName, scPath, a);
		wids.add(file);
	}
	foreach (c; summ.casts) {
		auto file = "~Mate" ~ to!(string)(c.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeCast(f, scName, scPath, c);
		wids.add(file);
	}
	foreach (c; summ.skills) {
		auto file = "~Skill" ~ to!(string)(c.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeSkill(f, scName, scPath, c);
		wids.add(file);
	}
	foreach (c; summ.items) {
		auto file = "~Item" ~ to!(string)(c.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeItem(f, scName, scPath, c);
		wids.add(file);
	}
	foreach (c; summ.beasts) {
		auto file = "~Beast" ~ to!(string)(c.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeBeast(f, scName, scPath, c);
		wids.add(file);
	}
	foreach (c; summ.infos) {
		auto file = "~Info" ~ to!(string)(c.id) ~ ".wid";
		scope f = new std.stream.BufferedFile
			(std.path.join(scPath, file), std.stream.FileMode.OutNew);
		scope (exit) f.close;
		writeInfo(f, scName, scPath, c);
		wids.add(file);
	}
	scope regex = std.regexp.RegExp("^(Area|Battle|Package|Mate|Skill|Item|Beast|Info)[0-9]+\\.wid$");
	foreach (file; std.file.listdir(scPath)) {
		if (regex.test(file, 0) || std.path.fnmatch(file, "Summary.wsm")) {
			scope path = std.path.join(scPath, file);
			preRemove(path);
			std.file.remove(path);
		}
	}
	foreach (file; wids) {
		std.file.rename(std.path.join(scPath, file), std.path.join(scPath, file[1u .. $]));
	}
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
	case Mentality.PANIC: return 1;
	case Mentality.BRAVE: return 2;
	case Mentality.OVERHEAT: return 3;
	case Mentality.CONFUSE: return 4;
	case Mentality.SLEEP: return 5;
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
private void writeBool(std.stream.OutputStream f, bool b) {
	f.write(cast(byte) (b ? 1 : 0));
}
private void writeImage(std.stream.OutputStream f, string scPath, string imgPath) {
	if (!imgPath.length) {
		writeUIntL(f, 0);
		return;
	}
	ubyte[] bytes;
	if (isBinImg(imgPath)) {
		bytes = cast(ubyte[]) strToBImg(imgPath);
	} else {
		bytes = cast(ubyte[]) std.file.read(std.path.join(scPath, imgPath));
	}
	writeUIntL(f, bytes.length);
	f.write(bytes);
}
private void writeString(std.stream.OutputStream f, string str, bool lns = false, bool cutText = false) {
	str = replace(str, "\n", "\r\n");
	if (cutText) {
		str = "TEXT\r\n" ~ str;
	}
	if (str.length) {
		str = tosjis(str);
		if (!lns) str ~= "\0";
		writeUIntL(f, str.length);
		f.write(cast(ubyte[]) str);
	} else {
		if (lns) {
			writeUIntL(f, 0);
		} else {
			writeUIntL(f, 1);
			f.write(cast(char) 0x0);
		}
	}
}
private void writeStrings(std.stream.OutputStream f, string[] strs) {
	if (strs.length) {
		auto s = std.string.join(strs, "\n");
		if (s.length && s[$ - 1] != '\n') s ~= '\n';
		writeString(f,  s, true);
	} else {
		writeUIntL(f, 0);
	}
}

private void writeSummary(std.stream.OutputStream f, Summary summ) {
	writeImage(f, summ.scenarioPath, summ.imagePath);
	writeString(f, summ.scenarioName);
	writeString(f, summ.desc, true);
	writeString(f, summ.author);
	writeStrings(f, summ.rCoupons);
	writeUIntL(f, summ.rCouponNum);
	writeUIntL(f, cast(uint) (summ.startArea + 40000u));
	auto steps = summ.flagDirRoot.allSteps;
	writeUIntL(f, steps.length);
	foreach (step; steps) {
		writeString(f, step.path);
		writeUIntL(f, step.select);
		for (uint i = 0u; i < 10u; i++) {
			if (i < step.count) {
				writeString(f, step.getValue(i));
			} else {
				writeString(f, "Step - " ~ to!(string)(i + 1u));
			}
		}
	}
	auto flags = summ.flagDirRoot.allFlags;
	writeUIntL(f, flags.length);
	foreach (flag; flags) {
		writeString(f, flag.path);
		writeBool(f, flag.onOff);
		writeString(f, flag.on);
		writeString(f, flag.off);
	}
	writeUIntL(f, 0u);
	writeUIntL(f, summ.levelMin);
	writeUIntL(f, summ.levelMax);
}
private void writeMotion(std.stream.OutputStream f, string scName, string scPath, Motion m) {
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
	f.write(cast(byte) 0x8);
	f.write(cast(byte) 0x4);
	f.write(cast(byte) 0x0);
	f.write(cast(byte) 0x0);
	f.write(cast(byte) 0x0);
	f.write(fromElement(m.element));
	if (tType != 8) {
		f.write(type);
	}
	switch (tType) {
	case 0, 1:
		f.write(fromDamageType(m.damageType));
		writeUIntL(f, m.uValue);
		break;
	case 2:
		break;
	case 3, 4:
		writeUIntL(f, m.detail.use(MArg.ROUND) ? m.round : 0xA);
		break;
	case 5:
		writeUIntL(f, m.aValue);
		writeUIntL(f, m.round);
		break;
	case 6, 7:
		break;
	case 8:
		auto beast = m.beast;
		if (beast) {
			writeUIntL(f, 0x1);
			writeBeast(f, scName, scPath, beast);
		} else {
			writeUIntL(f, 0x0);
		}
		break;
	default: throw new SummaryException("Unknown motion: " ~ to!(string)(tType) ~ ", " ~ to!(string)(type));
	}
}
private void writeContent(std.stream.OutputStream f, string scName, string scPath, Content e) {
	auto d = e.detail;
	void wb(byte type) {
		f.write(type);
		writeString(f, e.name);
		if (d.owner) {
			writeUIntL(f, 40000 + e.next.length);
			foreach (child; e.next) {
				writeContent(f, scName, scPath, child);
			}
		} else {
			writeUIntL(f, 40000);
		}
	}
	if (e.type is CType.START) {
		wb(0);
	} else if (e.type is CType.LINK_START) {
		wb(1);
		writeString(f, e.start);
	} else if (e.type is CType.START_BATTLE) {
		wb(2);
		writeUIntL(f, cast(uint) e.battle);
	} else if (e.type is CType.END) {
		wb(3);
		writeBool(f, e.complete);
	} else if (e.type is CType.END_BAD_END) {
		wb(4);
	} else if (e.type is CType.CHANGE_AREA) {
		wb(5);
		writeUIntL(f, cast(uint) e.area);
	} else if (e.type is CType.TALK_MESSAGE) {
		wb(6);
		string path;
		switch (e.talkerC) {
		case Talker.NARRATION: path = ""; break;
		case Talker.SELECTED: path = "??Selected"; break;
		case Talker.UNSELECTED: path = "??Unselected"; break;
		case Talker.RANDOM: path = "??Random"; break;
		case Talker.CARD: path = "??Card"; break;
		case Talker.IMAGE: path = e.cardPath; break;
		default: assert (0, "event 6");
		}
		writeString(f, path);
		writeString(f, lastRet(e.text), true);
	} else if (e.type is CType.PLAY_BGM) {
		wb(7);
		writeString(f, e.bgmPath);
	} else if (e.type is CType.CHANGE_BG_IMAGE) {
		wb(8);
		writeBgImages(f, e.bgImages);
	} else if (e.type is CType.PLAY_SOUND) {
		wb(9);
		writeString(f, e.soundPath);
	} else if (e.type is CType.WAIT) {
		wb(10);
		writeUIntL(f, e.wait);
	} else if (e.type is CType.EFFECT) {
		wb(11);
		writeUIntL(f, e.level);
		byte targ = fromTarget(e.targetNS);
		if (targ == 6) targ = 2;
		f.write(targ);
		f.write(fromEffectType(e.effectType));
		f.write(fromResist(e.resist));
		writeIntL(f, e.successRate);
		writeString(f, e.soundPath.length ? e.soundPath : "（なし）");
		f.write(fromCardVisual(e.cardVisual));
		writeUIntL(f, e.motions.length);
		foreach (m; e.motions) {
			writeMotion(f, scName, scPath, m);
		}
	} else if (e.type is CType.BRANCH_SELECT) {
		wb(12);
		writeBool(f, e.targetAll);
		writeBool(f, e.random);
	} else if (e.type is CType.BRANCH_ABILITY) {
		wb(13);
		writeUIntL(f, e.level);
		f.write(fromTarget(e.targetS));
		writeUIntL(f, fromPhysical(e.physical));
		writeIntL(f, fromMental(e.mental));
	} else if (e.type is CType.BRANCH_RANDOM) {
		wb(14);
		writeUIntL(f, e.percent);
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
		writeUIntL(f, e.stepValue);
	} else if (e.type is CType.BRANCH_CAST) {
		wb(19);
		writeUIntL(f, cast(uint) e.casts);
	} else if (e.type is CType.BRANCH_ITEM) {
		wb(20);
		writeUIntL(f, cast(uint) e.item);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_SKILL) {
		wb(21);
		writeUIntL(f, cast(uint) e.skill);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_INFO) {
		wb(22);
		writeUIntL(f, cast(uint) e.info);
	} else if (e.type is CType.BRANCH_BEAST) {
		wb(23);
		writeUIntL(f, cast(uint) e.beast);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.BRANCH_MONEY) {
		wb(24);
		writeUIntL(f, e.money);
	} else if (e.type is CType.BRANCH_COUPON) {
		wb(25);
		writeString(f, e.coupon);
		writeIntL(f, 0x0);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_CAST) {
		wb(26);
		writeUIntL(f, cast(uint) e.casts);
	} else if (e.type is CType.GET_ITEM) {
		wb(27);
		writeUIntL(f, cast(uint) e.item);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_SKILL) {
		wb(28);
		writeUIntL(f, cast(uint) e.skill);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_INFO) {
		wb(29);
		writeUIntL(f, cast(uint) e.info);
	} else if (e.type is CType.GET_BEAST) {
		wb(30);
		writeUIntL(f, cast(uint) e.beast);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.GET_MONEY) {
		wb(31);
		writeUIntL(f, e.money);
	} else if (e.type is CType.GET_COUPON) {
		wb(32);
		writeString(f, e.coupon);
		writeIntL(f, e.couponValue);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_CAST) {
		wb(33);
		writeUIntL(f, cast(uint) e.casts);
	} else if (e.type is CType.LOSE_ITEM) {
		wb(34);
		writeUIntL(f, cast(uint) e.item);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_SKILL) {
		wb(35);
		writeUIntL(f, cast(uint) e.skill);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_INFO) {
		wb(36);
		writeUIntL(f, cast(uint) e.info);
	} else if (e.type is CType.LOSE_BEAST) {
		wb(37);
		writeUIntL(f, cast(uint) e.beast);
		writeUIntL(f, e.cardNumber);
		f.write(fromRange(e.range));
	} else if (e.type is CType.LOSE_MONEY) {
		wb(38);
		writeUIntL(f, e.money);
	} else if (e.type is CType.LOSE_COUPON) {
		wb(39);
		writeString(f, e.coupon);
		writeIntL(f, 0x0);
		f.write(fromRange(e.range));
	} else if (e.type is CType.TALK_DIALOG) {
		wb(40);
		switch (e.talkerNC) {
		case Talker.SELECTED: f.write(cast(byte) 0); break;
		case Talker.RANDOM: f.write(cast(byte) 1); break;
		case Talker.UNSELECTED: f.write(cast(byte) 2); break;
		default: throw new SummaryException("Unknown talker value: " ~ to!(string)(cast(int) e.talkerNC));
		}
		writeUIntL(f, e.dialogs.length);
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
		writeUIntL(f, e.stepValue);
	} else if (e.type is CType.ELAPSE_TIME) {
		wb(45);
	} else if (e.type is CType.BRANCH_LEVEL) {
		wb(46);
		writeBool(f, e.average);
		writeUIntL(f, e.level);
	} else if (e.type is CType.BRANCH_STATUS) {
		wb(47);
		f.write(fromStatus(e.status));
		f.write(fromTarget(e.targetNS));
	} else if (e.type is CType.BRANCH_PARTY_NUMBER) {
		wb(48);
		writeUIntL(f, e.partyNumber);
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
		writeUIntL(f, cast(uint) e.packages);
	} else if (e.type is CType.CALL_PACKAGE) {
		wb(54);
		writeUIntL(f, cast(uint) e.packages);
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
private void writeCEventTree(std.stream.OutputStream f, string scName, string scPath, EventTree tree) {
	writeUIntL(f, tree.starts.length);
	foreach (evt; tree.starts) {
		writeContent(f, scName, scPath, evt);
	}
}
private void writeEventTree(std.stream.OutputStream f, string scName, string scPath, EventTree tree) {
	writeUIntL(f, tree.starts.length);
	foreach (evt; tree.starts) {
		writeContent(f, scName, scPath, evt);
	}
	int[] igs;
	if (tree.fireEnter) igs ~= 1;
	if (tree.fireEscape) igs ~= 2;
	if (tree.fireLose) igs ~= 3;
	foreach (rnd; tree.rounds) {
		igs ~= -(cast(int) rnd);
	}
	writeUIntL(f, igs.length);
	foreach (ig; igs) {
		writeIntL(f, ig);
	}
	writeStrings(f, tree.keyCodes);
}
private void writeBgImage(std.stream.OutputStream f, BgImage b) {
	writeIntL(f, b.x);
	writeIntL(f, b.y);
	writeUIntL(f, b.width + 40000u);
	writeUIntL(f, b.height);
	writeString(f, b.path);
	writeBool(f, b.mask);
	writeString(f, b.flag);
	f.write(cast(byte) 0x0);
}
private void writeBgImages(std.stream.OutputStream f, BgImage[] backs) {
	if (backs.length && backs[0].path != "" && backs[0].flag == ""
			&& backs[0].x == 0 && backs[0].y == 0
			&& backs[0].width == 632 && backs[0].height == 420 && !backs[0].mask) {
		writeUIntL(f, backs.length);
	} else {
		writeUIntL(f, backs.length + 1u);
		writeBgImage(f, new BgImage("", "", 0, 0, 632, 420, false));
	}
	foreach (b; backs) {
		writeBgImage(f, b);
	}
}
private void writeArea(std.stream.OutputStream f, string scName, string scPath, Area a) {
	f.write(cast(byte) 0x0);
	writeUIntL(f, 0x0);
	writeString(f, a.name);
	writeUIntL(f, cast(uint) (a.id + 40000u));
	writeUIntL(f, a.trees.length);
	foreach (tree; a.trees) {
		writeEventTree(f, scName, scPath, tree);
	}
	writeBool(f, !a.spAuto);
	writeUIntL(f, a.cards.length);
	foreach (c; a.cards) {
		f.write(cast(byte) 0x0);
		writeImage(f, scPath, isBinImg(c.path) ? c.path : "");
		writeString(f, c.name);
		f.write(cast(byte) 0x40);
		f.write(cast(byte) 0x9C);
		f.write(cast(byte) 0x0);
		f.write(cast(byte) 0x0);
		writeString(f, c.desc);
		writeUIntL(f, c.trees.length);
		foreach (tree; c.trees) {
			writeEventTree(f, scName, scPath, tree);
		}
		writeString(f, c.flag);
		writeUIntL(f, cast(uint) rndtol(c.scale * 100.0));
		writeIntL(f, c.x);
		writeIntL(f, c.y);
		writeString(f, isBinImg(c.path) ? "" : c.path);
	}
	writeBgImages(f, a.backs);
}
private void writeBattle(std.stream.OutputStream f, string scName, string scPath, Battle a) {
	f.write(cast(byte) 0x1);
	writeUIntL(f, 0x0);
	writeString(f, a.name);
	writeUIntL(f, cast(uint) (a.id + 40000u));
	writeUIntL(f, a.trees.length);
	foreach (tree; a.trees) {
		writeEventTree(f, scName, scPath, tree);
	}
	writeBool(f, !a.spAuto);
	writeUIntL(f, a.cards.length);
	foreach (c; a.cards) {
		writeUIntL(f, cast(uint) c.id);
		writeUIntL(f, c.trees.length);
		foreach (tree; c.trees) {
			writeEventTree(f, scName, scPath, tree);
		}
		writeString(f, c.flag);
		writeUIntL(f, cast(uint) rndtol(c.scale * 100.0));
		writeIntL(f, c.x);
		writeIntL(f, c.y);
		writeBool(f, c.escape);
	}
	writeString(f, a.music);
}
private void writePackage(std.stream.OutputStream f, string scName, string scPath, Package a) {
	writeUIntL(f, 0x4);
	writeString(f, a.name);
	writeUIntL(f, cast(uint) a.id);
	writeUIntL(f, a.trees.length);
	foreach (tree; a.trees) {
		writeCEventTree(f, scName, scPath, tree);
	}
}
private void writeCast(std.stream.OutputStream f, string scName, string scPath, CastCard c) {
	f.write(cast(byte) 0x2);
	writeImage(f, scPath, c.path);
	writeString(f, c.name);
	writeUIntL(f, cast(uint) (c.id + 40000u));
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
	writeUIntL(f, c.level);
	writeUIntL(f, 0u); // 所持金。現行エンジンでは未使用
	writeString(f, c.desc, true, true);
	writeUIntL(f, c.life);
	writeUIntL(f, c.lifeMax);
	writeUIntL(f, c.paralyze);
	writeUIntL(f, c.poison);
	writeUIntL(f, c.defaultEnhance(Enhance.AVOID));
	writeUIntL(f, c.defaultEnhance(Enhance.RESIST));
	writeUIntL(f, c.defaultEnhance(Enhance.DEFENSE));
	writeUIntL(f, c.physical(Physical.DEX));
	writeUIntL(f, c.physical(Physical.AGL));
	writeUIntL(f, c.physical(Physical.INT));
	writeUIntL(f, c.physical(Physical.STR));
	writeUIntL(f, c.physical(Physical.VIT));
	writeUIntL(f, c.physical(Physical.MIN));
	writeIntL(f, c.mental(Mental.AGGRESSIVE));
	writeIntL(f, c.mental(Mental.CHEERFUL));
	writeIntL(f, c.mental(Mental.BRAVE));
	writeIntL(f, c.mental(Mental.CAUTIOUS));
	writeIntL(f, c.mental(Mental.TRICKISH));
	f.write(fromMentality(c.mentality));
	writeUIntL(f, c.mentalityRound);
	writeUIntL(f, c.bindRound);
	writeUIntL(f, c.silenceRound);
	writeUIntL(f, c.faceUpRound);
	writeUIntL(f, c.antiMagicRound);
	writeUIntL(f, c.enhance(Enhance.ACTION));
	writeUIntL(f, c.enhanceRound(Enhance.ACTION));
	writeUIntL(f, c.enhance(Enhance.AVOID));
	writeUIntL(f, c.enhanceRound(Enhance.AVOID));
	writeUIntL(f, c.enhance(Enhance.RESIST));
	writeUIntL(f, c.enhanceRound(Enhance.RESIST));
	writeUIntL(f, c.enhance(Enhance.DEFENSE));
	writeUIntL(f, c.enhanceRound(Enhance.DEFENSE));
	writeUIntL(f, c.items.length);
	foreach (cc; c.items) {
		writeItem(f, scName, scPath, cc);
	}
	writeUIntL(f, c.skills.length);
	foreach (cc; c.skills) {
		writeSkill(f, scName, scPath, cc);
	}
	writeUIntL(f, c.beasts.length);
	foreach (cc; c.beasts) {
		writeBeast(f, scName, scPath, cc);
	}
	writeUIntL(f, c.coupons.length);
	foreach (cc; c.coupons) {
		writeString(f, cc.name);
		writeIntL(f, cc.value);
	}
}
private void writeEffCard(std.stream.OutputStream f, string scName, string scPath, EffectCard c, byte type) {
	f.write(type);
	writeImage(f, scPath, c.path);
	writeString(f, c.name);
	writeUIntL(f, cast(uint) (c.id + 40000u));
	writeString(f, c.desc);
	writeUIntL(f, fromPhysical(c.physical));
	writeIntL(f, fromMental(c.mental));
	writeBool(f, c.spell);
	writeBool(f, c.allRange);
	f.write(fromCardTarget(c.target));
	f.write(fromEffectType(c.effectType));
	f.write(fromResist(c.resist));
	writeIntL(f, c.successRate);
	f.write(fromCardVisual(c.visual));
	writeUIntL(f, c.motions.length);
	foreach (m; c.motions) {
		writeMotion(f, scName, scPath, m);
	}
	writeIntL(f, c.enhance(Enhance.AVOID));
	writeIntL(f, c.enhance(Enhance.RESIST));
	writeIntL(f, c.enhance(Enhance.DEFENSE));
	writeString(f, c.soundPath1.length ? c.soundPath1 : "（なし）");
	writeString(f, c.soundPath2.length ? c.soundPath2 : "（なし）");
	for (uint i = 0u; i < 5u; i++) {
		if (i < c.keyCodes.length) {
			writeString(f, c.keyCodes[i]);
		} else {
			writeString(f, "");
		}
	}
	f.write(fromPremium(c.premium));
	writeString(f, scName);
	writeString(f, c.author);
	writeUIntL(f, c.trees.length);
	foreach (tree; c.trees) {
		writeCEventTree(f, scName, scPath, tree);
	}
}
private void writeSkill(std.stream.OutputStream f, string scName, string scPath, SkillCard c) {
	writeEffCard(f, scName, scPath, c, 0x5);
	writeBool(f, c.hold);
	writeUIntL(f, c.level);
	writeUIntL(f, c.useLimit);
}
private void writeItem(std.stream.OutputStream f, string scName, string scPath, ItemCard c) {
	writeEffCard(f, scName, scPath, c, 0x3);
	writeBool(f, c.hold);
	writeUIntL(f, c.useLimit);
	writeUIntL(f, c.useLimitMax);
	writeUIntL(f, c.price);
	writeUIntL(f, c.enhanceOwner(Enhance.AVOID));
	writeUIntL(f, c.enhanceOwner(Enhance.RESIST));
	writeUIntL(f, c.enhanceOwner(Enhance.DEFENSE));
}
private void writeBeast(std.stream.OutputStream f, string scName, string scPath, BeastCard c) {
	writeEffCard(f, scName, scPath, c, 0x6);
	writeBool(f, false); // Hold
	writeUIntL(f, c.useLimit);
}
private void writeInfo(std.stream.OutputStream f, string scName, string scPath, InfoCard c) {
	f.write(cast(byte) 0x4);
	writeImage(f, scPath, c.path);
	writeString(f, c.name);
	writeUIntL(f, cast(uint) (c.id + 40000u));
	writeString(f, c.desc);
}
