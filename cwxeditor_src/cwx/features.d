
module cwx.features;

import cwx.types;

/// クーポンのタイプ
enum CouponType {
	Normal, /// 通常。
	Hide, /// 隠蔽クーポン。
	System, /// システムクーポン。
	Dur, /// 次元クーポン。
	DurBattle, /// 戦闘中限定時限クーポン。
}

/// 性別。
enum Sex {
	MALE, /// 男。
	FEMALE, /// 女。
}
/// すべての性別。
static const SEX_ALL = [
	Sex.MALE,
	Sex.FEMALE,
];
/// 性別を文字列に変換する。
string fromSex(Sex e) {
	final switch (e) {
	case Sex.MALE: return "Male";
	case Sex.FEMALE: return "Female";
	}
}
/// ditto
Sex toSex(string e) {
	final switch (e) {
	case "Male": return Sex.MALE;
	case "Female": return Sex.FEMALE;
	}
}

/// 年代。
enum Period {
	CHILD, /// 子供。
	YOUNG, /// 若者。
	ADULT, /// 大人。
	OLD, /// 老人。
}
/// すべての年代。
static const PERIOD_ALL = [
	Period.CHILD,
	Period.YOUNG,
	Period.ADULT,
	Period.OLD,
];
/// 年代を文字列に変換する。
string fromPeriod(Period e) {
	final switch (e) {
	case Period.CHILD: return "Child";
	case Period.YOUNG: return "Young";
	case Period.ADULT: return "Adult";
	case Period.OLD: return "Old";
	}
}
/// ditto
Period toPeriod(string e) {
	final switch (e) {
	case "Child": return Period.CHILD;
	case "Young": return Period.YOUNG;
	case "Adult": return Period.ADULT;
	case "Old": return Period.OLD;
	}
}

/// 素質。
enum Nature {
	SPI, /// 標準型。
	AGL, /// 万能型。
	STR, /// 勇将型。
	VIT, /// 豪傑型。
	INT, /// 知将型。
	SCH, /// 策士型。
	MED, /// 凡庸型。
	BRI, /// 英明型。
	MAT, /// 無双型。
	GEN, /// 天才型。
	HER, /// 英雄型。
	DIV, /// 神仙型。
}
/// 素質を文字列に変換する。
string fromNature(Nature e) {
	final switch (e) {
	case Nature.SPI: return "Spi";
	case Nature.AGL: return "Agl";
	case Nature.STR: return "Str";
	case Nature.VIT: return "Vit";
	case Nature.INT: return "Int";
	case Nature.SCH: return "Sch";
	case Nature.MED: return "Med";
	case Nature.BRI: return "Bri";
	case Nature.MAT: return "Mat";
	case Nature.GEN: return "Gen";
	case Nature.HER: return "Her";
	case Nature.DIV: return "Div";
	}
}
/// ditto
Nature toNature(string e) {
	final switch (e) {
	case "Spi": return Nature.SPI;
	case "Agl": return Nature.AGL;
	case "Str": return Nature.STR;
	case "Vit": return Nature.VIT;
	case "Int": return Nature.INT;
	case "Sch": return Nature.SCH;
	case "Med": return Nature.MED;
	case "Bri": return Nature.BRI;
	case "Mat": return Nature.MAT;
	case "Gen": return Nature.GEN;
	case "Her": return Nature.HER;
	case "Div": return Nature.DIV;
	}
}

/// 通常の素質。
static const NATURE_DEF = [
	Nature.SPI,
	Nature.INT,
	Nature.AGL,
	Nature.SCH,
	Nature.STR,
	Nature.VIT,
];
/// 特殊型。
static const NATURE_EXT = [
	Nature.BRI,
	Nature.MAT,
	Nature.GEN,
	Nature.MED,
	Nature.HER,
	Nature.DIV,
];

/// 特徴。
enum Makings {
	LOOKS_B, /// 秀麗。
	LOOKS_U, /// 醜悪。
	CLASS_H, /// 高貴の出。
	CLASS_L, /// 下賎の出。
	BRED_T, /// 都会育ち。
	BRED_C, /// 田舎育ち。
	MEANS_H, /// 裕福。
	MEANS_L, /// 貧乏。
	FAITH_F, /// 厚き信仰。
	FAITH_I, /// 不心得者。
	RELI_R, /// 誠実。
	RELI_U, /// 不実。
	DISP_C, /// 冷静沈着。
	DISP_S, /// 猪突猛進。
	DESIRE_G, /// 貪欲。
	DESIRE_C, /// 無欲。
	DEVOTE_D, /// 献身的。
	DEVOTE_S, /// 利己的。
	DISC_O, /// 秩序派。
	DISC_C, /// 混沌派。
	POLIT_R, /// 進取派。
	POLIT_C, /// 保守派。
	SENSE_R, /// 神経質。
	SENSE_S, /// 鈍感。
	CURIO_B, /// 好奇心旺盛。
	CURIO_I, /// 無頓着。
	NOTION_R, /// 過激。
	NOTION_M, /// 穏健。
	IDEA_O, /// 楽観的。
	IDEA_P, /// 悲観的。
	WORK_H, /// 勤勉。
	WORK_S, /// 遊び人。
	CHAR_C, /// 陽気。
	CHAR_B, /// 内気。
	STYLE_F, /// 派手。
	STYLE_P, /// 地味。
	PRIDE_P, /// 高慢。
	PRIDE_M, /// 謙虚。
	REF_R, /// 上品。
	REF_B, /// 粗野。
	GRACE_G, /// 武骨。
	GRACE_R, /// 繊細。
	LINER_H, /// 硬派。
	LINER_M, /// 軟派。
	PER_S, /// お人好し。
	PER_T, /// ひねくれ者。
	FAME_H, /// 名誉こそ命。
	FAME_A, /// 愛に生きる。
}
/// 素質を文字列に変換する。
string fromMakings(Makings e) {
	final switch (e) {
	case Makings.LOOKS_B: return "LooksB";
	case Makings.LOOKS_U: return "LooksU";
	case Makings.CLASS_H: return "ClassH";
	case Makings.CLASS_L: return "ClassL";
	case Makings.BRED_T: return "BredT";
	case Makings.BRED_C: return "BredC";
	case Makings.MEANS_H: return "MeansH";
	case Makings.MEANS_L: return "MeansL";
	case Makings.FAITH_F: return "FaithF";
	case Makings.FAITH_I: return "FaithI";
	case Makings.RELI_R: return "ReliR";
	case Makings.RELI_U: return "ReliU";
	case Makings.DISP_C: return "DispC";
	case Makings.DISP_S: return "DispS";
	case Makings.DESIRE_G: return "DesireG";
	case Makings.DESIRE_C: return "DesireC";
	case Makings.DEVOTE_D: return "DevoteD";
	case Makings.DEVOTE_S: return "DevoteS";
	case Makings.DISC_O: return "DiscO";
	case Makings.DISC_C: return "DiscC";
	case Makings.POLIT_R: return "PolitR";
	case Makings.POLIT_C: return "PolitC";
	case Makings.SENSE_R: return "SenseR";
	case Makings.SENSE_S: return "SenseS";
	case Makings.CURIO_B: return "CurioB";
	case Makings.CURIO_I: return "CurioI";
	case Makings.NOTION_R: return "NotionR";
	case Makings.NOTION_M: return "NotionM";
	case Makings.IDEA_O: return "IdeaO";
	case Makings.IDEA_P: return "IdeaP";
	case Makings.WORK_H: return "WorkH";
	case Makings.WORK_S: return "WorkS";
	case Makings.CHAR_C: return "CharC";
	case Makings.CHAR_B: return "CharB";
	case Makings.STYLE_F: return "StyleF";
	case Makings.STYLE_P: return "StyleP";
	case Makings.PRIDE_P: return "PrideP";
	case Makings.PRIDE_M: return "PrideM";
	case Makings.REF_R: return "RefR";
	case Makings.REF_B: return "RefB";
	case Makings.GRACE_G: return "GraceG";
	case Makings.GRACE_R: return "GraceR";
	case Makings.LINER_H: return "LinerH";
	case Makings.LINER_M: return "LinerM";
	case Makings.PER_S: return "PerS";
	case Makings.PER_T: return "PerT";
	case Makings.FAME_H: return "FameH";
	case Makings.FAME_A: return "FameA";
	}
}
/// 素質を文字列に変換する。
Makings toMakings(string e) {
	final switch (e) {
	case "LooksB": return Makings.LOOKS_B;
	case "LooksU": return Makings.LOOKS_U;
	case "ClassH": return Makings.CLASS_H;
	case "ClassL": return Makings.CLASS_L;
	case "BredT": return Makings.BRED_T;
	case "BredC": return Makings.BRED_C;
	case "MeansH": return Makings.MEANS_H;
	case "MeansL": return Makings.MEANS_L;
	case "FaithF": return Makings.FAITH_F;
	case "FaithI": return Makings.FAITH_I;
	case "ReliR": return Makings.RELI_R;
	case "ReliU": return Makings.RELI_U;
	case "DispC": return Makings.DISP_C;
	case "DispS": return Makings.DISP_S;
	case "DesireG": return Makings.DESIRE_G;
	case "DesireC": return Makings.DESIRE_C;
	case "DevoteD": return Makings.DEVOTE_D;
	case "DevoteS": return Makings.DEVOTE_S;
	case "DiscO": return Makings.DISC_O;
	case "DiscC": return Makings.DISC_C;
	case "PolitR": return Makings.POLIT_R;
	case "PolitC": return Makings.POLIT_C;
	case "SenseR": return Makings.SENSE_R;
	case "SenseS": return Makings.SENSE_S;
	case "CurioB": return Makings.CURIO_B;
	case "CurioI": return Makings.CURIO_I;
	case "NotionR": return Makings.NOTION_R;
	case "NotionM": return Makings.NOTION_M;
	case "IdeaO": return Makings.IDEA_O;
	case "IdeaP": return Makings.IDEA_P;
	case "WorkH": return Makings.WORK_H;
	case "WorkS": return Makings.WORK_S;
	case "CharC": return Makings.CHAR_C;
	case "CharB": return Makings.CHAR_B;
	case "StyleF": return Makings.STYLE_F;
	case "StyleP": return Makings.STYLE_P;
	case "PrideP": return Makings.PRIDE_P;
	case "PrideM": return Makings.PRIDE_M;
	case "RefR": return Makings.REF_R;
	case "RefB": return Makings.REF_B;
	case "GraceG": return Makings.GRACE_G;
	case "GraceR": return Makings.GRACE_R;
	case "LinerH": return Makings.LINER_H;
	case "LinerM": return Makings.LINER_M;
	case "PerS": return Makings.PER_S;
	case "PerT": return Makings.PER_T;
	case "FameH": return Makings.FAME_H;
	case "FameA": return Makings.FAME_A;
	}
}
/// 左辺の特徴。
static const MAKINGS_LEFT = [
	Makings.LOOKS_B,
	Makings.CLASS_H,
	Makings.BRED_T,
	Makings.MEANS_H,
	Makings.FAITH_F,
	Makings.RELI_R,
	Makings.DISP_C,
	Makings.DESIRE_G,
	Makings.DEVOTE_D,
	Makings.DISC_O,
	Makings.POLIT_R,
	Makings.SENSE_R,
	Makings.CURIO_B,
	Makings.NOTION_R,
	Makings.IDEA_O,
	Makings.WORK_H,
	Makings.CHAR_C,
	Makings.STYLE_F,
	Makings.PRIDE_P,
	Makings.REF_R,
	Makings.GRACE_G,
	Makings.LINER_H,
	Makings.PER_S,
	Makings.FAME_H,
];
/// 左辺に対応する右辺の特徴を返す。
Makings reverseMakings(Makings m) {
	final switch (m) {
	case Makings.LOOKS_B: return Makings.LOOKS_U;
	case Makings.LOOKS_U: return Makings.LOOKS_B;
	case Makings.CLASS_H: return Makings.CLASS_L;
	case Makings.CLASS_L: return Makings.CLASS_H;
	case Makings.BRED_T: return Makings.BRED_C;
	case Makings.BRED_C: return Makings.BRED_T;
	case Makings.MEANS_H: return Makings.MEANS_L;
	case Makings.MEANS_L: return Makings.MEANS_H;
	case Makings.FAITH_F: return Makings.FAITH_I;
	case Makings.FAITH_I: return Makings.FAITH_F;
	case Makings.RELI_R: return Makings.RELI_U;
	case Makings.RELI_U: return Makings.RELI_R;
	case Makings.DISP_C: return Makings.DISP_S;
	case Makings.DISP_S: return Makings.DISP_C;
	case Makings.DESIRE_G: return Makings.DESIRE_C;
	case Makings.DESIRE_C: return Makings.DESIRE_G;
	case Makings.DEVOTE_D: return Makings.DEVOTE_S;
	case Makings.DEVOTE_S: return Makings.DEVOTE_D;
	case Makings.DISC_O: return Makings.DISC_C;
	case Makings.DISC_C: return Makings.DISC_O;
	case Makings.POLIT_R: return Makings.POLIT_C;
	case Makings.POLIT_C: return Makings.POLIT_R;
	case Makings.SENSE_R: return Makings.SENSE_S;
	case Makings.SENSE_S: return Makings.SENSE_R;
	case Makings.CURIO_B: return Makings.CURIO_I;
	case Makings.CURIO_I: return Makings.CURIO_B;
	case Makings.NOTION_R: return Makings.NOTION_M;
	case Makings.NOTION_M: return Makings.NOTION_R;
	case Makings.IDEA_O: return Makings.IDEA_P;
	case Makings.IDEA_P: return Makings.IDEA_O;
	case Makings.WORK_H: return Makings.WORK_S;
	case Makings.WORK_S: return Makings.WORK_H;
	case Makings.CHAR_C: return Makings.CHAR_B;
	case Makings.CHAR_B: return Makings.CHAR_C;
	case Makings.STYLE_F: return Makings.STYLE_P;
	case Makings.STYLE_P: return Makings.STYLE_F;
	case Makings.PRIDE_P: return Makings.PRIDE_M;
	case Makings.PRIDE_M: return Makings.PRIDE_P;
	case Makings.REF_R: return Makings.REF_B;
	case Makings.REF_B: return Makings.REF_R;
	case Makings.GRACE_G: return Makings.GRACE_R;
	case Makings.GRACE_R: return Makings.GRACE_G;
	case Makings.LINER_H: return Makings.LINER_M;
	case Makings.LINER_M: return Makings.LINER_H;
	case Makings.PER_S: return Makings.PER_T;
	case Makings.PER_T: return Makings.PER_S;
	case Makings.FAME_H: return Makings.FAME_A;
	case Makings.FAME_A: return Makings.FAME_H;
	}
}
