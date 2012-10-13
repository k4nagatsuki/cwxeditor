
module cwx.system;

import cwx.features;
import cwx.types;

import std.string;
import std.algorithm;

/// 発火条件キーコードの種別。
enum FKCKind {
	Use, /// 使用時。
	Success, /// 成功時。
	Failure /// 失敗時。
}

class System {
	/// 唯一のコンストラクタ。
	this () {}

	/// 各特性を名前に変換する。名前は'＿'を除いてクーポンと一致する。
	/// クラシックなシナリオの場合、legacyNameにエンジンのファイル名
	/// (拡張子は除く)を指定する。
	/// バリアントの型名については次のサイトを参照した。
	/// http://www.geocities.jp/chikuan_shusui/history/variant_engine.htm
	/// http://dwandnl.web.fc2.com/darkwirth/
	const
	string sexName(Sex s, string legacyName) {
		switch (s) {
		case Sex.MALE: return "♂";
		case Sex.FEMALE: return "♀";
		default: assert (0);
		}
	}
	/// ditto
	const
	string periodName(Period p, string legacyName) {
		switch (p) {
		case Period.CHILD: return "子供";
		case Period.YOUNG: return "若者";
		case Period.ADULT: return "大人";
		case Period.OLD: return "老人";
		default: assert (0);
		}
	}
	/// ditto
	const
	string natureName(Nature n, string legacyName) {
		switch (n) {
		case Nature.SPI: {
			switch (toLower(legacyName)) {
			case "darkwirth": return "他種族";
			default: return "標準型";
			}
		}
		case Nature.INT: {
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "理性型";
			case "oedowirth": return "参謀型";
			case "darkwirth": return "妖木族";
			default: return "知将型";
			}
		}
		case Nature.AGL: {
			switch (toLower(legacyName)) {
			case "oedowirth": return "隠密型";
			case "darkwirth": return "人獣族";
			default: return "万能型";
			}
		}
		case Nature.SCH: {
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "秀才型";
			case "darkwirth": return "小悪魔";
			default:return "策士型";
			}
		}
		case Nature.STR: {
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "根性型";
			case "oedowirth": return "剣客型";
			case "darkwirth": return "悪鬼族";
			default: return "勇将型";
			}
		}
		case Nature.VIT: {
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "熱血型";
			case "darkwirth": return "蜥蜴族";
			default: return "豪傑型";
			}
		}
		case Nature.BRI: {
			switch (toLower(legacyName)) {
			case "oedowirth": return "秀英型";
			case "darkwirth": return "人狼族";
			default: return "英明型";
			}
		}
		case Nature.MAT: {
			switch (toLower(legacyName)) {
			case "oedowirth": return "剣豪型";
			case "darkwirth": return "鬼人族";
			default: return "無双型";
			}
		}
		case Nature.GEN: {
			switch (toLower(legacyName)) {
			case "oedowirth": return "賢才型";
			case "darkwirth": return "大悪魔";
			default: return "天才型";
			}
		}
		case Nature.MED: {
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "努力型";
			case "oedowirth": return "晩成型";
			case "darkwirth": return "妖虫族";
			default: return "凡庸型";
			}
		}
		case Nature.HER: {
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "超人型";
			case "oedowirth": return "覇道型";
			case "darkwirth": return "闇の者";
			default: return "英雄型";
			}
		}
		case Nature.DIV: {
			switch (toLower(legacyName)) {
			case "darkwirth": return "神竜族";
			default: return "神仙型";
			}
		}
		default: assert (0);
		}
	}
	/// ditto
	const
	string makingsName(Makings m, string legacyName) {
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
	const
	string sexCoupon(Sex p, string legacyName) {
		return "＿" ~ sexName(p, legacyName);
	}
	/// ditto
	const
	string periodCoupon(Period p, string legacyName) {
		return "＿" ~ periodName(p, legacyName);
	}
	/// ditto
	const
	string natureCoupon(Nature n, string legacyName) {
		return "＿" ~ natureName(n, legacyName);
	}
	/// ditto
	const
	string makingsCoupon(Makings m, string legacyName) {
		return "＿" ~ makingsName(m, legacyName);
	}

	/// ペナルティカードであればtrue。
	const
	bool isPenalty(in string[] keyCodes) {
		return 0 < keyCodes.find("ペナルティ").length;
	}
	/// リサイクルカードであればtrue。
	const
	bool isRecycle(in string[] keyCodes) {
		return 0 < keyCodes.find("リサイクル").length;
	}

	private immutable FKC_SUCCESS = "○";
	private immutable FKC_FAILURE = "×";
	/// キーコード発火条件の種別を返す。
	const
	FKCKind fireKeyCodeKind(string keyCode) {
		if (.endsWith(keyCode, FKC_SUCCESS.idup)) {
			return FKCKind.Success;
		} else if (std.string.endsWith(keyCode, FKC_FAILURE.idup)) {
			return FKCKind.Failure;
		}
		return FKCKind.Use;
	}
	/// キーコード発火条件を変換する。
	const
	string convFireKeyCode(string keyCode, FKCKind kind) {
		if (.endsWith(keyCode, FKC_SUCCESS.idup)) {
			final switch (kind) {
			case FKCKind.Use: return keyCode[0 .. $ - FKC_SUCCESS.length];
			case FKCKind.Success: return keyCode;
			case FKCKind.Failure: return keyCode[0 .. $ - FKC_SUCCESS.length] ~ FKC_FAILURE;
			}
		} else if (.endsWith(keyCode, FKC_FAILURE.idup)) {
			final switch (kind) {
			case FKCKind.Use: return keyCode[0 .. $ - FKC_FAILURE.length];
			case FKCKind.Success: return keyCode[0 .. $ - FKC_FAILURE.length] ~ FKC_SUCCESS;
			case FKCKind.Failure: return keyCode;
			}
		} else {
			final switch (kind) {
			case FKCKind.Use: return keyCode;
			case FKCKind.Success: return keyCode ~ FKC_SUCCESS;
			case FKCKind.Failure: return keyCode ~ FKC_FAILURE;
			}
		}
	}
	/// 種族名をクーポンに変換する。
	const
	string raceCoupon(string raceName) {
		return "＠Ｒ" ~ raceName;
	}

	/// 後続イベントコンテントのTrue値。
	@property const string evtChildTrue() {return "○";}
	/// 後続イベントコンテントのFalse値。
	@property const string evtChildFalse() {return "×";}
	/// 後続イベントコンテントのDefault値。
	@property const string evtChildDefault() {return "Default";}
	/// 後続イベントコンテントのメッセージ送り標準値。
	@property const string evtChildOK(string legacyName) {
		switch (toLower(legacyName)) {
		case "oedowirth":
			return " 是 ";
		default:
			return "ＯＫ";
		}
	}
	/// 後続イベントコンテントの大なり値。
	@property const string evtChildGreater() {return ">";}
	/// 後続イベントコンテントの小なり値。
	@property const string evtChildLesser() {return "<";}
	/// 後続イベントコンテントの一致値。
	@property const string evtChildEq() {return "=";}

	/// クーポンの型を判別する。
	const CouponType couponType(string coupon) {
		foreach (coType; [CouponType.Hide, CouponType.System, CouponType.Dur, CouponType.DurBattle]) {
			if (isCouponType(coupon, coType)) {
				return coType;
			}
		}
		return CouponType.Normal;
	}
	/// ditto
	const bool isCouponType(string coupon, CouponType type) {
		final switch (type) {
		case CouponType.Normal:
			return !isCouponType(coupon, CouponType.Hide)
				&& !isCouponType(coupon, CouponType.System)
				&& !isCouponType(coupon, CouponType.Dur)
				&& !isCouponType(coupon, CouponType.DurBattle);
		case CouponType.Hide:
			return std.string.startsWith(coupon, couponHide);
		case CouponType.System:
			return std.string.startsWith(coupon, couponSystem);
		case CouponType.Dur:
			return std.string.startsWith(coupon, couponDur);
		case CouponType.DurBattle:
			return std.string.startsWith(coupon, couponDurBattle);
		}
	}
	/// クーポンの型を変換する。
	const string convCoupon(string coupon, CouponType type) {
		final switch (type) {
		case CouponType.Normal:
			if (isCouponType(coupon, CouponType.Hide)) {
				return coupon[couponHide.length .. $];
			}
			if (isCouponType(coupon, CouponType.System)) {
				return coupon[couponSystem.length .. $];
			}
			if (isCouponType(coupon, CouponType.Dur)) {
				return coupon[couponDur.length .. $];
			}
			if (isCouponType(coupon, CouponType.DurBattle)) {
				return coupon[couponDurBattle.length .. $];
			}
			return coupon;
		case CouponType.Hide:
			if (isCouponType(coupon, CouponType.Hide)) {
				return coupon;
			}
			return couponHide ~ convCoupon(coupon, CouponType.Normal);
		case CouponType.System:
			if (isCouponType(coupon, CouponType.System)) {
				return coupon;
			}
			return couponSystem ~ convCoupon(coupon, CouponType.Normal);
		case CouponType.Dur:
			if (isCouponType(coupon, CouponType.Dur)) {
				return coupon;
			}
			return couponDur ~ convCoupon(coupon, CouponType.Normal);
		case CouponType.DurBattle:
			if (isCouponType(coupon, CouponType.DurBattle)) {
				return coupon;
			}
			return couponDurBattle ~ convCoupon(coupon, CouponType.Normal);
		}
	}
	/// 各クーポンの型を表現する文字列。
	@property const string couponHide() {
		return "＿";
	}
	/// ditto
	@property const string couponSystem() {
		return "＠";
	}
	/// ditto
	@property const string couponDur() {
		return "：";
	}
	/// ditto
	@property const string couponDurBattle() {
		return "；";
	}

	/// システム変数名の接頭辞を返す。
	@property const string prefixSystemVarName() {
		return "??";
	}
	/// システム変数名か。
	@property const bool isSystemVar(string varName) {
		return varName.startsWith(prefixSystemVarName);
	}
	/// フラグ・ステップ値のランダム値ソース名。
	@property const string randomValue() {
		return "??Random";
	}

	/// 性別による肉体能力の修正値のテーブルを返す。
	const
	real physicalMod(Sex e, Physical phy, string legacyName) {
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
	const
	real mentalMod(Sex e, Mental mtl, string legacyName) {
		switch (mtl) {
		case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
				Mental.UNCAUTIOUS, Mental.UNTRICKISH:
			return mentalMod(e, reverseMental(mtl), legacyName) * -1.0;
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

	/// 年代による肉体能力の修正値を返す。
	const
	real physicalMod(Period e, Physical phy, string legacyName) {
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
	const
	real mentalMod(Period e, Mental mtl, string legacyName) {
		switch (mtl) {
		case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
				Mental.UNCAUTIOUS, Mental.UNTRICKISH:
			return mentalMod(e, reverseMental(mtl), legacyName) * -1.0;
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
	/// 素質による肉体能力の修正値を返す。
	const
	real physicalMod(Nature e, Physical phy, string legacyName) {
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
	const
	real mentalMod(Nature e, Mental mtl, string legacyName) {
		switch (mtl) {
		case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
				Mental.UNCAUTIOUS, Mental.UNTRICKISH:
			return mentalMod(e, reverseMental(mtl), legacyName) * -1.0;
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
	/// 特徴による肉体能力の修正値を返す。
	const
	real physicalMod(Makings e, Physical phy, string legacyName) {
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
	const
	real mentalMod(Makings e, Mental mtl, string legacyName) {
		switch (mtl) {
		case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
				Mental.UNCAUTIOUS, Mental.UNTRICKISH:
			return mentalMod(e, reverseMental(mtl), legacyName) * -1.0;
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
}
