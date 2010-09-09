
module cwx.system;

import cwx.card;
import cwx.features;
import cwx.utils;

class System {
	private Sex[string] _sexTbl;
	private Period[string] _periodTbl;
	private Nature[string] _natureTbl;
	private Makings[string] _makingsTbl;

	/// 唯一のコンストラクタ。
	this () {
		foreach (e; SEX_ALL) {
			_sexTbl[sexCoupon(e)] = e;
		}
		foreach (e; PERIOD_ALL) {
			_periodTbl[periodCoupon(e)] = e;
		}
		foreach (e; NATURE_DEF) {
			_natureTbl[natureCoupon(e)] = e;
		}
		foreach (e; MAKINGS_LEFT) {
			_makingsTbl[makingsCoupon(e)] = e;
			auto re = reverseMakings(e);
			_makingsTbl[makingsCoupon(re)] = re;
		}
	}

	/// クーポンから特性を取得し、oに格納する。
	/// クーポンが特性に関連付けられない場合はfalseを返す。
	bool toSex(string coupon, Sex o) {
		auto p = coupon in _sexTbl;
		if (p) {
			o = *p;
			return true;
		}
		return false;
	}
	/// ditto
	bool toPeriod(string coupon, Period o) {
		auto p = coupon in _periodTbl;
		if (p) {
			o = *p;
			return true;
		}
		return false;
	}
	/// ditto
	bool toNature(string coupon, Nature o) {
		auto p = coupon in _natureTbl;
		if (p) {
			o = *p;
			return true;
		}
		return false;
	}
	/// ditto
	bool toMakings(string coupon, Makings o) {
		auto p = coupon in _makingsTbl;
		if (p) {
			o = *p;
			return true;
		}
		return false;
	}

	/// 各特性を名前に変換する。名前は'＿'を除いてクーポンと一致する。
	string sexName(Sex s) {
		switch (s) {
		case Sex.MALE: return "♂";
		case Sex.FEMALE: return "♀";
		default: assert (0);
		}
	}
	/// ditto
	string periodName(Period p) {
		switch (p) {
		case Period.CHILD: return "子供";
		case Period.YOUNG: return "若者";
		case Period.ADULT: return "大人";
		case Period.OLD: return "老人";
		default: assert (0);
		}
	}
	/// ditto
	string natureName(Nature n) {
		switch (n) {
		case Nature.SPI: return "標準型";
		case Nature.INT: return "知将型";
		case Nature.AGL: return "万能型";
		case Nature.SCH: return "策士型";
		case Nature.STR: return "勇将型";
		case Nature.VIT: return "豪傑型";
		case Nature.BRI: return "英明型";
		case Nature.MAT: return "無双型";
		case Nature.GEN: return "天才型";
		case Nature.MED: return "凡庸型";
		case Nature.HER: return "英雄型";
		case Nature.DIV: return "神仙型";
		default: assert (0);
		}
	}
	/// ditto
	string makingsName(Makings m) {
		switch (m) {
		case Makings.LOOKS_B: return "秀麗";
		case Makings.LOOKS_U: return "醜悪";
		case Makings.CLASS_H: return "高貴の出";
		case Makings.CLASS_L: return "下賎の出";
		case Makings.BRED_T:  return "都会育ち";
		case Makings.BRED_C:  return "田舎育ち";
		case Makings.MEANS_H: return "裕福";
		case Makings.MEANS_L: return "貧乏";
		case Makings.FAITH_F: return "厚き信仰";
		case Makings.FAITH_I: return "不心得者";
		case Makings.RELI_R:  return "誠実";
		case Makings.RELI_U:  return "不実";
		case Makings.DISP_C:  return "冷静沈着";
		case Makings.DISP_S:  return "猪突猛進";
		case Makings.DESIRE_G:return "貪欲";
		case Makings.DESIRE_C:return "無欲";
		case Makings.DEVOTE_D:return "献身的";
		case Makings.DEVOTE_S:return "利己的";
		case Makings.DISC_O:  return "秩序派";
		case Makings.DISC_C:  return "混沌派";
		case Makings.POLIT_R: return "進取派";
		case Makings.POLIT_C: return "保守派";
		case Makings.SENSE_R: return "神経質";
		case Makings.SENSE_S: return "鈍感";
		case Makings.CURIO_B: return "好奇心旺盛";
		case Makings.CURIO_I: return "無頓着";
		case Makings.NOTION_R:return "過激";
		case Makings.NOTION_M:return "穏健";
		case Makings.IDEA_O:  return "楽観的";
		case Makings.IDEA_P:  return "悲観的";
		case Makings.WORK_H:  return "勤勉";
		case Makings.WORK_S:  return "遊び人";
		case Makings.CHAR_C:  return "陽気";
		case Makings.CHAR_B:  return "内気";
		case Makings.STYLE_F: return "派手";
		case Makings.STYLE_P: return "地味";
		case Makings.PRIDE_P: return "高慢";
		case Makings.PRIDE_M: return "謙虚";
		case Makings.REF_R:   return "上品";
		case Makings.REF_B:   return "粗野";
		case Makings.GRACE_G: return "武骨";
		case Makings.GRACE_R: return "繊細";
		case Makings.LINER_H: return "硬派";
		case Makings.LINER_M: return "軟派";
		case Makings.PER_S:   return "お人好し";
		case Makings.PER_T:   return "ひねくれ者";
		case Makings.FAME_H:  return "名誉こそ命";
		case Makings.FAME_A:  return "愛に生きる";
		default: assert (0);
		}
	}

	/// 各特性をクーポンに変換する。
	string sexCoupon(Sex p) {
		return "＿" ~ sexName(p);
	}
	/// ditto
	string periodCoupon(Period p) {
		return "＿" ~ periodName(p);
	}
	/// ditto
	string natureCoupon(Nature n) {
		return "＿" ~ natureName(n);
	}
	/// ditto
	string makingsCoupon(Makings m) {
		return "＿" ~ makingsName(m);
	}

	/// ペナルティカードであればtrue。
	bool isPenalty(EffectCard card) {
		return contains(card.keyCodes, "ペナルティ");
	}
	/// リサイクルカードであればtrue。
	bool isRecycle(EffectCard card) {
		return contains(card.keyCodes, "リサイクル");
	}
}
