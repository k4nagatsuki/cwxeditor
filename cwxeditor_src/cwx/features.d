
module cwx.features;

import cwx.types;

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
/// 性別による肉体能力の修正値を返す。
real physicalMod(Sex e, Physical phy) {
	switch (e) {
	case Sex.MALE:
		switch (phy) {
		case Physical.STR:
			return 1.0;
		default:
		}
		break;
	case Sex.FEMALE:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		default:
		}
		break;
	default:
	}
	return 0.0;
}
/// 性別による精神能力の修正値を返す。
real mentalMod(Sex e, Mental mtl) {
	switch (mtl) {
	case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
			Mental.UNCAUTIOUS, Mental.UNTRICKISH:
		return mentalMod(e, reverseMental(mtl)) * -1.0;
	default:
	}
	switch (e) {
	case Sex.MALE:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		default:
		}
		break;
	case Sex.FEMALE:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	default:
	}
	return 0.0;
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
/// 年代による肉体能力の修正値を返す。
real physicalMod(Period e, Physical phy) {
	switch (e) {
	case Period.CHILD:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.AGL:
			return 1.0;
		case Physical.STR:
			return -1.0;
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Period.ADULT:
		switch (phy) {
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Period.OLD:
		switch (phy) {
		case Physical.DEX:
			return -1.0;
		case Physical.AGL:
			return -1.0;
		case Physical.INT:
			return 1.0;
		case Physical.STR:
			return -1.0;
		case Physical.VIT:
			return -1.0;
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	default:
	}
	return 0.0;
}
/// 年代による精神能力の修正値を返す。
real mentalMod(Period e, Mental mtl) {
	switch (mtl) {
	case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
			Mental.UNCAUTIOUS, Mental.UNTRICKISH:
		return mentalMod(e, reverseMental(mtl)) * -1.0;
	default:
	}
	switch (e) {
	case Period.CHILD:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Period.ADULT:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Period.OLD:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.BRAVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	default:
	}
	return 0.0;
}

/// 素質。
enum Nature {
	SPI, /// 標準型。
	INT, /// 知将型。
	AGL, /// 万能型。
	SCH, /// 策士型。
	STR, /// 勇将型。
	VIT, /// 豪傑型。
	BRI, /// 英明型。
	MAT, /// 無双型。
	GEN, /// 天才型。
	MED, /// 凡庸型。
	HER, /// 英雄型。
	DIV, /// 神仙型。
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
/// 素質による肉体能力の修正値を返す。
real physicalMod(Nature e, Physical phy) {
	switch (e) {
	case Nature.SPI:
		switch (phy) {
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	case Nature.INT:
		switch (phy) {
		case Physical.INT:
			return 2.0;
		case Physical.STR:
			return -1.0;
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Nature.AGL:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.AGL:
			return 1.0;
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	case Nature.SCH:
		switch (phy) {
		case Physical.AGL:
			return -1.0;
		case Physical.INT:
			return 3.0;
		case Physical.STR:
			return -2.0;
		case Physical.VIT:
			return -2.0;
		default:
		}
		break;
	case Nature.STR:
		switch (phy) {
		case Physical.DEX:
			return -1.0;
		case Physical.INT:
			return -1.0;
		case Physical.STR:
			return 2.0;
		default:
		}
		break;
	case Nature.VIT:
		switch (phy) {
		case Physical.DEX:
			return -2.0;
		case Physical.AGL:
			return -1.0;
		case Physical.INT:
			return -2.0;
		case Physical.STR:
			return 3.0;
		case Physical.VIT:
			return 1.0;
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	case Nature.BRI:
		return 1.0;
	case Nature.MAT:
		switch (phy) {
		case Physical.AGL:
			return 1.0;
		case Physical.STR:
			return 3.0;
		case Physical.VIT:
			return 2.0;
		default:
		}
		break;
	case Nature.GEN:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.INT:
			return 3.0;
		case Physical.MIN:
			return 2.0;
		default:
		}
		break;
	case Nature.MED:
		return -2.0;
	case Nature.HER:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.AGL:
			return 1.0;
		case Physical.INT:
			return 2.0;
		case Physical.STR:
			return 2.0;
		case Physical.VIT:
			return 1.0;
		case Physical.MIN:
			return 2.0;
		default:
		}
		break;
	case Nature.DIV:
		return 2.0;
	default:
	}
	return 0.0;
}
/// 素質による精神能力の修正値を返す。
real mentalMod(Nature e, Mental mtl) {
	switch (mtl) {
	case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
			Mental.UNCAUTIOUS, Mental.UNTRICKISH:
		return mentalMod(e, reverseMental(mtl)) * -1.0;
	default:
	}
	switch (e) {
	case Nature.SPI:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Nature.INT:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Nature.AGL:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		default:
		}
		break;
	case Nature.SCH:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Nature.STR:
		switch (mtl) {
		case Mental.BRAVE:
			return 1.0;
		default:
		}
		break;
	case Nature.VIT:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.BRAVE:
			return 0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Nature.BRI:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Nature.MAT:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.BRAVE:
			return 0.5;
		default:
		}
		break;
	case Nature.GEN:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Nature.MED:
		switch (mtl) {
		case Mental.BRAVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Nature.HER:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		case Mental.BRAVE:
			return 0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Nature.DIV:
		return 0.0;
	default:
	}
	return 0.0;
}

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
/// 特徴による肉体能力の修正値を返す。
real physicalMod(Makings e, Physical phy) {
	switch (e) {
	case Makings.LOOKS_B:
		switch (phy) {
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Makings.LOOKS_U:
		switch (phy) {
		case Physical.VIT:
			return 1.0;
		default:
		}
		break;
	case Makings.BRED_T:
		switch (phy) {
		case Physical.INT:
			return 1.0;
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Makings.BRED_C:
		switch (phy) {
		case Physical.AGL:
			return -1.0;
		case Physical.VIT:
			return 1.0;
		default:
		}
		break;
	case Makings.MEANS_H:
		switch (phy) {
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	case Makings.MEANS_L:
		switch (phy) {
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	case Makings.FAITH_F:
		switch (phy) {
		case Physical.INT:
			return -1.0;
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	case Makings.DISP_C:
		switch (phy) {
		case Physical.AGL:
			return -1.0;
		case Physical.INT:
			return 1.0;
		default:
		}
		break;
	case Makings.DISP_S:
		switch (phy) {
		case Physical.AGL:
			return 1.0;
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	case Makings.DESIRE_G:
		switch (phy) {
		case Physical.VIT:
			return 1.0;
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	case Makings.DEVOTE_D:
		switch (phy) {
		case Physical.VIT:
			return -1.0;
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	case Makings.DEVOTE_S:
		switch (phy) {
		case Physical.DEX:
			return -1.0;
		case Physical.AGL:
			return 1.0;
		default:
		}
		break;
	case Makings.DISC_C:
		switch (phy) {
		case Physical.STR:
			return 1.0;
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	case Makings.POLIT_R:
		switch (phy) {
		case Physical.AGL:
			return 1.0;
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Makings.POLIT_C:
		switch (phy) {
		case Physical.STR:
			return -1.0;
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	case Makings.SENSE_R:
		switch (phy) {
		case Physical.AGL:
			return 1.0;
		case Physical.STR:
			return -1.0;
		default:
		}
		break;
	case Makings.SENSE_S:
		switch (phy) {
		case Physical.INT:
			return -1.0;
		case Physical.VIT:
			return 1.0;
		default:
		}
		break;
	case Makings.CURIO_B:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Makings.CURIO_I:
		switch (phy) {
		case Physical.AGL:
			return -1.0;
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	case Makings.NOTION_R:
		switch (phy) {
		case Physical.STR:
			return 1.0;
		case Physical.VIT:
			return -1.0;
		default:
		}
		break;
	case Makings.IDEA_O:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.AGL:
			return -1.0;
		default:
		}
		break;
	case Makings.IDEA_P:
		switch (phy) {
		case Physical.INT:
			return 1.0;
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	case Makings.WORK_H:
		switch (phy) {
		case Physical.DEX:
			return -1.0;
		case Physical.VIT:
			return 1.0;
		default:
		}
		break;
	case Makings.WORK_S:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.INT:
			return -1.0;
		default:
		}
		break;
	case Makings.STYLE_F:
		switch (phy) {
		case Physical.AGL:
			return 1.0;
		case Physical.INT:
			return -1.0;
		default:
		}
		break;
	case Makings.STYLE_P:
		switch (phy) {
		case Physical.STR:
			return -1.0;
		case Physical.VIT:
			return 1.0;
		default:
		}
		break;
	case Makings.PRIDE_P:
		switch (phy) {
		case Physical.DEX:
			return -1.0;
		case Physical.MIN:
			return 1.0;
		default:
		}
		break;
	case Makings.PRIDE_M:
		switch (phy) {
		case Physical.DEX:
			return -1.0;
		case Physical.INT:
			return 1.0;
		default:
		}
		break;
	case Makings.REF_R:
		switch (phy) {
		case Physical.INT:
			return 1.0;
		case Physical.STR:
			return -1.0;
		default:
		}
		break;
	case Makings.REF_B:
		switch (phy) {
		case Physical.INT:
			return -1.0;
		case Physical.STR:
			return 1.0;
		default:
		}
		break;
	case Makings.GRACE_G:
		switch (phy) {
		case Physical.DEX:
			return -1.0;
		case Physical.STR:
			return 1.0;
		default:
		}
		break;
	case Makings.GRACE_R:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.STR:
			return -1.0;
		default:
		}
		break;
	case Makings.LINER_H:
		switch (phy) {
		case Physical.AGL:
			return -1.0;
		case Physical.STR:
			return 1.0;
		default:
		}
		break;
	case Makings.LINER_M:
		switch (phy) {
		case Physical.DEX:
			return 1.0;
		case Physical.MIN:
			return -1.0;
		default:
		}
		break;
	default:
	}
	return 0.0;
}
/// 特徴による精神能力の修正値を返す。
real mentalMod(Makings e, Mental mtl) {
	switch (mtl) {
	case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
			Mental.UNCAUTIOUS, Mental.UNTRICKISH:
		return mentalMod(e, reverseMental(mtl)) * -1.0;
	default:
	}
	switch (e) {
	case Makings.LOOKS_B:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		default:
		}
		break;
	case Makings.LOOKS_U:
		switch (mtl) {
		case Mental.CHEERFUL:
			return -0.5;
		default:
		}
		break;
	case Makings.CLASS_H:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.BRAVE:
			return 0.5;
		default:
		}
		break;
	case Makings.CLASS_L:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return -0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.BRED_T:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.BRED_C:
		switch (mtl) {
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.MEANS_H:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.MEANS_L:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.BRAVE:
			return -0.5;
		default:
		}
		break;
	case Makings.FAITH_F:
		switch (mtl) {
		case Mental.BRAVE:
			return 0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.FAITH_I:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.RELI_R:
		switch (mtl) {
		case Mental.BRAVE:
			return 0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.RELI_U:
		switch (mtl) {
		case Mental.BRAVE:
			return -0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.DISP_C:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.DISP_S:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Makings.DESIRE_G:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.BRAVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Makings.DESIRE_C:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		default:
		}
		break;
	case Makings.DEVOTE_D:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		default:
		}
		break;
	case Makings.DEVOTE_S:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.CHEERFUL:
			return -0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.DISC_O:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.DISC_C:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.POLIT_R:
		switch (mtl) {
		case Mental.BRAVE:
			return 0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Makings.POLIT_C:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Makings.SENSE_R:
		switch (mtl) {
		case Mental.CHEERFUL:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Makings.CURIO_I:
		switch (mtl) {
		case Mental.CHEERFUL:
			return -0.5;
		default:
		}
		break;
	case Makings.NOTION_R:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Makings.NOTION_M:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Makings.IDEA_O:
		switch (mtl) {
		case Mental.BRAVE:
			return 0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Makings.IDEA_P:
		switch (mtl) {
		case Mental.BRAVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Makings.WORK_S:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		case Mental.TRICKISH:
			return 0.5;
		default:
		}
		break;
	case Makings.CHAR_C:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		default:
		}
		break;
	case Makings.CHAR_B:
		switch (mtl) {
		case Mental.BRAVE:
			return -0.5;
		default:
		}
		break;
	case Makings.STYLE_F:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		default:
		}
		break;
	case Makings.STYLE_P:
		switch (mtl) {
		case Mental.BRAVE:
			return -0.5;
		default:
		}
		break;
	case Makings.PRIDE_P:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.CHEERFUL:
			return -0.5;
		default:
		}
		break;
	case Makings.PRIDE_M:
		switch (mtl) {
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Makings.REF_R:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		case Mental.CHEERFUL:
			return 0.5;
		default:
		}
		break;
	case Makings.REF_B:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return 0.5;
		case Mental.CHEERFUL:
			return -0.5;
		default:
		}
		break;
	case Makings.GRACE_G:
		switch (mtl) {
		case Mental.CHEERFUL:
			return -0.5;
		case Mental.BRAVE:
			return 0.5;
		default:
		}
		break;
	case Makings.GRACE_R:
		switch (mtl) {
		case Mental.BRAVE:
			return -0.5;
		case Mental.CAUTIOUS:
			return 0.5;
		default:
		}
		break;
	case Makings.LINER_H:
		switch (mtl) {
		case Mental.BRAVE:
			return 0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.LINER_M:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		case Mental.BRAVE:
			return -0.5;
		default:
		}
		break;
	case Makings.PER_S:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.PER_T:
		switch (mtl) {
		case Mental.CHEERFUL:
			return 0.5;
		default:
		}
		break;
	case Makings.FAME_H:
		switch (mtl) {
		case Mental.BRAVE:
			return 0.5;
		case Mental.CAUTIOUS:
			return -0.5;
		case Mental.TRICKISH:
			return -0.5;
		default:
		}
		break;
	case Makings.FAME_A:
		switch (mtl) {
		case Mental.AGGRESSIVE:
			return -0.5;
		default:
		}
		break;
	default:
	}
	return 0.0;
}
