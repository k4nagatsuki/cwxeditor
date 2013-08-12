
module cwx.system;

import cwx.perf;
import cwx.features;
import cwx.types;

import std.string;
import std.algorithm;

/// XMLからデータを生成する際に必要な情報。
class XMLInfo {
	const System sys; /// 対象システム情報。
	string ver; /// バージョン情報。

	this (const System sys, string ver) { mixin(S_TRACE);
		this.sys = sys;
		this.ver = ver;
	}
}

/// 発火条件キーコードの種別。
enum FKCKind {
	Use, /// 使用時。
	Success, /// 成功時。
	Failure, /// 失敗時。
	HasNot, /// 不保有。
}
/// キーコード発火条件とキーコード本体の組み合わせ。
struct FKeyCode {
	string keyCode; /// キーコード。
	FKCKind kind; /// 発火条件。
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
	string sexName(Sex s, string legacyName) { mixin(S_TRACE);
		switch (s) {
		case Sex.MALE: return "♂";
		case Sex.FEMALE: return "♀";
		default: assert (0);
		}
	}
	/// ditto
	const
	string periodName(Period p, string legacyName) { mixin(S_TRACE);
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
	string natureName(Nature n, string legacyName) { mixin(S_TRACE);
		switch (n) {
		case Nature.SPI: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "darkwirth": return "他種族";
			default: return "標準型";
			}
		}
		case Nature.INT: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "理性型";
			case "oedowirth": return "参謀型";
			case "darkwirth": return "妖木族";
			default: return "知将型";
			}
		}
		case Nature.AGL: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "隠密型";
			case "darkwirth": return "人獣族";
			default: return "万能型";
			}
		}
		case Nature.SCH: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "秀才型";
			case "darkwirth": return "小悪魔";
			default:return "策士型";
			}
		}
		case Nature.STR: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "根性型";
			case "oedowirth": return "剣客型";
			case "darkwirth": return "悪鬼族";
			default: return "勇将型";
			}
		}
		case Nature.VIT: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "熱血型";
			case "darkwirth": return "蜥蜴族";
			default: return "豪傑型";
			}
		}
		case Nature.BRI: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "秀英型";
			case "darkwirth": return "人狼族";
			default: return "英明型";
			}
		}
		case Nature.MAT: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "剣豪型";
			case "darkwirth": return "鬼人族";
			default: return "無双型";
			}
		}
		case Nature.GEN: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "賢才型";
			case "darkwirth": return "大悪魔";
			default: return "天才型";
			}
		}
		case Nature.MED: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "努力型";
			case "oedowirth": return "晩成型";
			case "darkwirth": return "妖虫族";
			default: return "凡庸型";
			}
		}
		case Nature.HER: { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "超人型";
			case "oedowirth": return "覇道型";
			case "darkwirth": return "闇の者";
			default: return "英雄型";
			}
		}
		case Nature.DIV: { mixin(S_TRACE);
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
	string makingsName(Makings m, string legacyName) { mixin(S_TRACE);
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
	string sexCoupon(Sex p, string legacyName) { mixin(S_TRACE);
		return "＿" ~ sexName(p, legacyName);
	}
	/// ditto
	const
	string periodCoupon(Period p, string legacyName) { mixin(S_TRACE);
		return "＿" ~ periodName(p, legacyName);
	}
	/// ditto
	const
	string natureCoupon(Nature n, string legacyName) { mixin(S_TRACE);
		return "＿" ~ natureName(n, legacyName);
	}
	/// ditto
	const
	string makingsCoupon(Makings m, string legacyName) { mixin(S_TRACE);
		return "＿" ~ makingsName(m, legacyName);
	}

	/// ペナルティカードであればtrue。
	const
	bool isPenalty(in string[] keyCodes) { mixin(S_TRACE);
		return 0 < keyCodes.find("ペナルティ").length;
	}
	/// リサイクルカードであればtrue。
	const
	bool isRecycle(in string[] keyCodes) { mixin(S_TRACE);
		return 0 < keyCodes.find("リサイクル").length;
	}

	private immutable FKC_SUCCESS = "○";
	private immutable FKC_FAILURE = "×";
	private immutable FKC_HASNOT = "！";
	/// キーコード発火条件の種別を返す。
	const
	FKCKind fireKeyCodeKind(string keyCode) { mixin(S_TRACE);
		if (.endsWith(keyCode, FKC_SUCCESS.idup)) { mixin(S_TRACE);
			return FKCKind.Success;
		} else if (std.string.endsWith(keyCode, FKC_FAILURE.idup)) { mixin(S_TRACE);
			return FKCKind.Failure;
		} else if (std.string.startsWith(keyCode, FKC_HASNOT.idup)) { mixin(S_TRACE);
			return FKCKind.HasNot;
		}
		return FKCKind.Use;
	}
	/// ditto
	const
	FKCKind fireKeyCodeKindRef(ref string keyCode) { mixin(S_TRACE);
		if (.endsWith(keyCode, FKC_SUCCESS.idup)) { mixin(S_TRACE);
			keyCode = keyCode[0..$-FKC_SUCCESS.length];
			return FKCKind.Success;
		} else if (std.string.endsWith(keyCode, FKC_FAILURE.idup)) { mixin(S_TRACE);
			keyCode = keyCode[0..$-FKC_FAILURE.length];
			return FKCKind.Failure;
		} else if (std.string.startsWith(keyCode, FKC_HASNOT.idup)) { mixin(S_TRACE);
			keyCode = keyCode[FKC_HASNOT.length..$];
			return FKCKind.HasNot;
		}
		return FKCKind.Use;
	}
	/// キーコード発火条件を変換する。
	const
	string convFireKeyCode(in FKeyCode keyCode) { mixin(S_TRACE);
		return convFireKeyCode(keyCode.keyCode, keyCode.kind);
	}
	/// ditto
	const
	string convFireKeyCode(string keyCode, FKCKind kind) { mixin(S_TRACE);
		if (.endsWith(keyCode, FKC_SUCCESS.idup)) { mixin(S_TRACE);
			final switch (kind) {
			case FKCKind.Use: return keyCode[0 .. $ - FKC_SUCCESS.length];
			case FKCKind.Success: return keyCode;
			case FKCKind.Failure: return keyCode[0 .. $ - FKC_SUCCESS.length] ~ FKC_FAILURE;
			case FKCKind.HasNot: return FKC_HASNOT ~ keyCode[0 .. $ - FKC_SUCCESS.length];
			}
		} else if (.endsWith(keyCode, FKC_FAILURE.idup)) { mixin(S_TRACE);
			final switch (kind) {
			case FKCKind.Use: return keyCode[0 .. $ - FKC_FAILURE.length];
			case FKCKind.Success: return keyCode[0 .. $ - FKC_FAILURE.length] ~ FKC_SUCCESS;
			case FKCKind.Failure: return keyCode;
			case FKCKind.HasNot: return FKC_HASNOT ~ keyCode[0 .. $ - FKC_FAILURE.length];
			}
		} else if (.startsWith(keyCode, FKC_HASNOT.idup)) { mixin(S_TRACE);
			final switch (kind) {
			case FKCKind.Use: return keyCode[FKC_HASNOT.length .. $];
			case FKCKind.Success: return keyCode[FKC_HASNOT.length .. $] ~ FKC_SUCCESS;
			case FKCKind.Failure: return keyCode[FKC_HASNOT.length .. $] ~ FKC_FAILURE;
			case FKCKind.HasNot: return keyCode;
			}
		} else { mixin(S_TRACE);
			final switch (kind) {
			case FKCKind.Use: return keyCode;
			case FKCKind.Success: return keyCode ~ FKC_SUCCESS;
			case FKCKind.Failure: return keyCode ~ FKC_FAILURE;
			case FKCKind.HasNot: return FKC_HASNOT ~ keyCode;
			}
		}
	}
	/// 発火条件付のキーコードをFKeyCodeへ変換する。
	const
	FKeyCode toFKeyCode(string keyCode) { mixin(S_TRACE);
		auto kind = fireKeyCodeKindRef(keyCode);
		return FKeyCode(keyCode, kind);
	}

	/// 種族名をクーポンに変換する。
	const
	string raceCoupon(string raceName) { mixin(S_TRACE);
		return "＠Ｒ" ~ raceName;
	}

	/// 後続イベントコンテントのTrue値。
	@property const string evtChildTrue() {return "○";}
	/// 後続イベントコンテントのFalse値。
	@property const string evtChildFalse() {return "×";}
	/// 後続イベントコンテントのDefault値。
	@property const string evtChildDefault() {return "Default";}
	/// 後続イベントコンテントのメッセージ送り標準値。
	@property const string evtChildOK(string legacyName) { mixin(S_TRACE);
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
	const CouponType couponType(string coupon) { mixin(S_TRACE);
		foreach (coType; [CouponType.Hide, CouponType.System, CouponType.Dur, CouponType.DurBattle]) { mixin(S_TRACE);
			if (isCouponType(coupon, coType)) { mixin(S_TRACE);
				return coType;
			}
		}
		return CouponType.Normal;
	}
	/// ditto
	const bool isCouponType(string coupon, CouponType type) { mixin(S_TRACE);
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
	const string convCoupon(string coupon, CouponType type, bool ignoreSystemCoupon) { mixin(S_TRACE);
		final switch (type) {
		case CouponType.Normal:
			if (isCouponType(coupon, CouponType.Hide)) { mixin(S_TRACE);
				return coupon[couponHide.length .. $];
			}
			if (!ignoreSystemCoupon && isCouponType(coupon, CouponType.System)) { mixin(S_TRACE);
				return coupon[couponSystem.length .. $];
			}
			if (isCouponType(coupon, CouponType.Dur)) { mixin(S_TRACE);
				return coupon[couponDur.length .. $];
			}
			if (isCouponType(coupon, CouponType.DurBattle)) { mixin(S_TRACE);
				return coupon[couponDurBattle.length .. $];
			}
			return coupon;
		case CouponType.Hide:
			if (isCouponType(coupon, CouponType.Hide)) { mixin(S_TRACE);
				return coupon;
			}
			return couponHide ~ convCoupon(coupon, CouponType.Normal, ignoreSystemCoupon);
		case CouponType.System:
			if (ignoreSystemCoupon) goto case CouponType.Normal;
			if (isCouponType(coupon, CouponType.System)) { mixin(S_TRACE);
				return coupon;
			}
			return couponSystem ~ convCoupon(coupon, CouponType.Normal, ignoreSystemCoupon);
		case CouponType.Dur:
			if (isCouponType(coupon, CouponType.Dur)) { mixin(S_TRACE);
				return coupon;
			}
			return couponDur ~ convCoupon(coupon, CouponType.Normal, ignoreSystemCoupon);
		case CouponType.DurBattle:
			if (isCouponType(coupon, CouponType.DurBattle)) { mixin(S_TRACE);
				return coupon;
			}
			return couponDurBattle ~ convCoupon(coupon, CouponType.Normal, ignoreSystemCoupon);
		}
	}
	/// 各クーポンの型を表現する文字列。
	@property const string couponHide() { mixin(S_TRACE);
		return "＿";
	}
	/// ditto
	@property const string couponSystem() { mixin(S_TRACE);
		return "＠";
	}
	/// ditto
	@property const string couponDur() { mixin(S_TRACE);
		return "：";
	}
	/// ditto
	@property const string couponDurBattle() { mixin(S_TRACE);
		return "；";
	}

	/// システム変数名の接頭辞を返す。
	@property const string prefixSystemVarName() { mixin(S_TRACE);
		return "??";
	}
	/// システム変数名か。
	@property const bool isSystemVar(string varName) { mixin(S_TRACE);
		return varName.startsWith(prefixSystemVarName);
	}
	/// フラグ・ステップ値のランダム値ソース名。
	@property const string randomValue() { mixin(S_TRACE);
		return "??Random";
	}

	/// 値の配列をenum値のテーブルに変換する。
	private static const(R[T]) mod(T, R)(in R[] values...) { mixin(S_TRACE);
		import std.traits;
		R[T] r;
		foreach (key; EnumMembers!T) { mixin(S_TRACE);
			int iKey = key;
			static if (is(T:Mental)) {
				iKey /= 2;
			}
			R v = values[iKey];
			static if (is(T:Mental)) {
				if (iKey & 0b1) v = -v;
			}
			r[key] = v;
		}
		return r;
	}
	private alias mod!(Physical, int) modP;
	private alias mod!(Mental, real) modM;

	/// 特徴による肉体能力の修正値のテーブルを返す。
	const
	const(int[Physical][E]) physicalMod(E)(string legacyName) { mixin(S_TRACE);
		static if (is(E:Sex)) {
			return [
				Sex.MALE  : modP( 0,  0,  0,  1,  0,  0),
				Sex.FEMALE: modP( 1,  0,  0,  0,  0,  0),
			];
		} else static if (is(E:Period)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Period.CHILD: modP( 1,  1,  1,  0,  0,  1),
					Period.YOUNG: modP( 1,  1,  1,  1,  1,  1),
					Period.ADULT: modP( 1,  1,  1,  1,  0,  2),
					Period.OLD  : modP( 1,  0,  2,  0,  0,  2),
				];
			} else { mixin(S_TRACE);
				return [
					Period.CHILD: modP( 1,  1,  0, -1, -1,  0),
					Period.YOUNG: modP( 0,  0,  0,  0,  0,  0),
					Period.ADULT: modP( 0,  0,  0,  0, -1,  0),
					Period.OLD  : modP(-1, -1,  1, -1, -1,  1),
				];
			}
		} else static if (is(E:Nature)) {
			if ("cw´standard" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature.SPI: modP(-1, -1, -1, -1, -1,  1),
					Nature.AGL: modP( 0,  1, -1, -1, -1, -2),
					Nature.STR: modP(-1, -1, -2,  0,  0,  0),
					Nature.VIT: modP(-2, -1, -2,  1,  1, -1),
					Nature.INT: modP(-1, -1,  0, -1, -1,  0),
					Nature.SCH: modP( 0,  0,  1, -2, -2, -1),
					Nature.MED: modP(-3, -3, -3, -3, -3, -3),
					Nature.BRI: modP( 0,  1,  0,  0,  0,  1),
					Nature.MAT: modP(-1,  0, -1,  2,  2,  0),
					Nature.GEN: modP( 0,  0,  2, -1, -1,  2),
					Nature.HER: modP( 0,  0,  1,  1,  1,  2),
					Nature.DIV: modP( 1,  1,  1,  1,  1,  2),
				];
			} else if ("cw´heroic" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature.SPI: modP( 0,  0,  0,  0,  0,  2),
					Nature.AGL: modP( 1,  1,  0,  0,  0,  0),
					Nature.STR: modP( 0,  0, -1,  1,  1,  1),
					Nature.VIT: modP(-1,  0, -1,  2,  2,  0),
					Nature.INT: modP( 0,  0,  2, -1,  0,  1),
					Nature.SCH: modP( 1,  0,  3, -1, -1,  0),
					Nature.MED: modP(-2, -2, -2, -2, -2, -2),
					Nature.BRI: modP( 1,  1,  1,  1,  1,  2),
					Nature.MAT: modP( 0,  1,  0,  3,  2,  1),
					Nature.GEN: modP( 1,  1,  3,  0,  0,  2),
					Nature.HER: modP( 2,  2,  2,  2,  2,  2),
					Nature.DIV: modP( 2,  2,  3,  2,  2,  3),
				];
			} else if ("cw´commoner" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature.SPI: modP(-2, -2, -2, -2, -2, -1),
					Nature.AGL: modP(-1, -1, -2, -2, -2, -3),
					Nature.STR: modP(-2, -2, -2, -1, -2, -2),
					Nature.VIT: modP(-3, -2, -3,  0, -1, -2),
					Nature.INT: modP(-2, -2, -1, -2, -2, -2),
					Nature.SCH: modP(-1, -2,  0, -3, -3, -2),
					Nature.MED: modP(-3, -3, -3, -3, -3, -3),
					Nature.BRI: modP( 0,  1,  0,  0,  0,  1),
					Nature.MAT: modP(-1,  0, -1,  2,  2,  0),
					Nature.GEN: modP( 0,  0,  2, -1, -1,  2),
					Nature.HER: modP( 0,  0,  1,  1,  1,  2),
					Nature.DIV: modP( 1,  1,  1,  1,  1,  2),
				];
			} else if ("darkwirth" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature.SPI: modP( 1,  0,  0,  0,  1,  1),
					Nature.AGL: modP( 1,  1,  0,  0,  0, -1),
					Nature.STR: modP(-1,  0, -2,  2,  2, -1),
					Nature.VIT: modP(-2, -1, -2,  3,  2, -2),
					Nature.INT: modP(-2, -2,  2, -1,  2,  1),
					Nature.SCH: modP(-2,  2,  3, -2, -2, -1),
					Nature.MED: modP(-1,  0, -3, -3, -3, -2),
					Nature.BRI: modP( 1,  1,  1,  1,  1,  1),
					Nature.MAT: modP( 0,  1,  0,  3,  2,  0),
					Nature.GEN: modP( 0,  2,  3,  0,  0,  1),
					Nature.HER: modP( 1,  2,  1,  2,  2,  1),
					Nature.DIV: modP( 2,  2,  2,  2,  2,  2),
				];
			} else { mixin(S_TRACE);
				return [
					Nature.SPI: modP( 0,  0,  0,  0,  0,  1),
					Nature.AGL: modP( 1,  1,  0,  0,  0, -1),
					Nature.STR: modP(-1,  0, -1,  2,  0,  0),
					Nature.VIT: modP(-2, -1, -2,  3,  1, -1),
					Nature.INT: modP( 0,  0,  2, -1, -1,  0),
					Nature.SCH: modP( 0, -1,  3, -2, -2,  0),
					Nature.MED: modP(-2, -2, -2, -2, -2, -2),
					Nature.BRI: modP( 1,  1,  1,  1,  1,  1),
					Nature.MAT: modP( 0,  1,  0,  3,  2,  0),
					Nature.GEN: modP( 1,  0,  3,  0,  0,  2),
					Nature.HER: modP( 1,  1,  2,  2,  1,  2),
					Nature.DIV: modP( 2,  2,  2,  2,  2,  2),
				];
			}
		} else static if (is(E:Makings)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Makings.LOOKS_B : modP( 0,  0,  0,  0, -1,  0),
					Makings.LOOKS_U : modP( 0,  0,  0,  0,  1,  0),
					Makings.CLASS_H : modP( 0,  0,  0,  0,  0,  0),
					Makings.CLASS_L : modP( 0,  0,  0,  1,  0, -1),
					Makings.BRED_T  : modP( 0,  0,  1,  0, -1,  0),
					Makings.BRED_C  : modP(-1,  0,  0,  0,  1,  0),
					Makings.MEANS_H : modP( 0,  0,  0,  0,  0, -1),
					Makings.MEANS_L : modP( 0,  0,  0,  0,  0,  1),
					Makings.FAITH_F : modP( 0,  0, -1,  0,  0,  1),
					Makings.FAITH_I : modP( 0,  0,  0,  0,  0,  0),
					Makings.RELI_R  : modP( 0,  0,  0,  0,  0,  0),
					Makings.RELI_U  : modP( 0,  0,  0,  0,  0,  0),
					Makings.DISP_C  : modP( 0, -1,  0,  0,  0,  1),
					Makings.DISP_S  : modP( 0,  1,  0,  0,  0, -1),
					Makings.DESIRE_G: modP( 0,  0,  0,  0,  1, -1),
					Makings.DESIRE_C: modP( 1,  0,  0,  0, -1,  0),
					Makings.DEVOTE_D: modP( 0,  0,  0,  0, -1,  1),
					Makings.DEVOTE_S: modP( 0,  0,  1,  0,  0, -1),
					Makings.DISC_O  : modP( 0,  0,  0,  0,  0,  0),
					Makings.DISC_C  : modP(-1,  1,  0,  0,  0,  0),
					Makings.POLIT_R : modP( 0,  1,  0,  0, -1,  0),
					Makings.POLIT_C : modP( 0,  0,  0,  0,  0,  0),
					Makings.SENSE_R : modP( 0,  1,  0, -1,  0,  0),
					Makings.SENSE_S : modP( 0,  0, -1,  0,  1,  0),
					Makings.CURIO_B : modP( 0,  0,  0,  0,  0,  0),
					Makings.CURIO_I : modP( 0, -1,  0,  0,  1,  0),
					Makings.NOTION_R: modP( 0,  0,  0,  1, -1,  0),
					Makings.NOTION_M: modP( 0,  0,  0, -1,  0,  1),
					Makings.IDEA_O  : modP( 1, -1,  0,  0,  0,  0),
					Makings.IDEA_P  : modP( 0,  0,  0,  0,  0,  0),
					Makings.WORK_H  : modP(-1,  0,  1,  0,  0,  0),
					Makings.WORK_S  : modP( 1,  0, -1,  0,  0,  0),
					Makings.CHAR_C  : modP( 0,  0,  0,  0,  0,  0),
					Makings.CHAR_B  : modP( 0,  0,  0,  0,  0,  0),
					Makings.STYLE_F : modP( 0,  1, -1,  0,  0,  0),
					Makings.STYLE_P : modP( 0,  0,  0, -1,  1,  0),
					Makings.PRIDE_P : modP(-1,  0,  0,  0,  0,  1),
					Makings.PRIDE_M : modP( 0, -1,  1,  0,  0,  0),
					Makings.REF_R   : modP( 0,  0,  1, -1,  0,  0),
					Makings.REF_B   : modP( 0,  0, -1,  1,  0,  0),
					Makings.GRACE_G : modP(-1,  0,  0,  1,  0,  0),
					Makings.GRACE_R : modP( 1,  0,  0, -1,  0,  0),
					Makings.LINER_H : modP( 0, -1,  0,  1,  0,  0),
					Makings.LINER_M : modP( 1,  0,  0,  0,  0, -1),
					Makings.PER_S   : modP( 0,  0,  0,  0,  0,  0),
					Makings.PER_T   : modP( 0,  0,  0,  0,  0,  0),
					Makings.FAME_H  : modP( 0,  0,  0,  0,  0,  0),
					Makings.FAME_A  : modP( 0,  0,  0,  0,  0,  0),
				];
			} else { mixin(S_TRACE);
				return [
					Makings.LOOKS_B : modP( 0,  0,  0,  0, -1,  0),
					Makings.LOOKS_U : modP( 0,  0,  0,  0,  1,  0),
					Makings.CLASS_H : modP( 0,  0,  0,  0,  0,  0),
					Makings.CLASS_L : modP( 0,  0,  0,  0,  0,  0),
					Makings.BRED_T  : modP( 0,  0,  1,  0, -1,  0),
					Makings.BRED_C  : modP( 0, -1,  0,  0,  1,  0),
					Makings.MEANS_H : modP( 0,  0,  0,  0,  0, -1),
					Makings.MEANS_L : modP( 0,  0,  0,  0,  0,  1),
					Makings.FAITH_F : modP( 0,  0, -1,  0,  0,  1),
					Makings.FAITH_I : modP( 0,  0,  0,  0,  0,  0),
					Makings.RELI_R  : modP( 0,  0,  0,  0,  0,  0),
					Makings.RELI_U  : modP( 0,  0,  0,  0,  0,  0),
					Makings.DISP_C  : modP( 0, -1,  1,  0,  0,  0),
					Makings.DISP_S  : modP( 0,  1,  0,  0,  0, -1),
					Makings.DESIRE_G: modP( 0,  0,  0,  0,  1, -1),
					Makings.DESIRE_C: modP( 0,  0,  0,  0,  0,  0),
					Makings.DEVOTE_D: modP( 0,  0,  0,  0, -1,  1),
					Makings.DEVOTE_S: modP(-1,  1,  0,  0,  0,  0),
					Makings.DISC_O  : modP( 0,  0,  0,  0,  0,  0),
					Makings.DISC_C  : modP( 0,  0,  0,  1,  0, -1),
					Makings.POLIT_R : modP( 0,  1,  0,  0, -1,  0),
					Makings.POLIT_C : modP( 0,  0,  0, -1,  0,  1),
					Makings.SENSE_R : modP( 0,  1,  0, -1,  0,  0),
					Makings.SENSE_S : modP( 0,  0, -1,  0,  1,  0),
					Makings.CURIO_B : modP( 1,  0,  0,  0, -1,  0),
					Makings.CURIO_I : modP( 0, -1,  0,  0,  0,  1),
					Makings.NOTION_R: modP( 0,  0,  0,  1, -1,  0),
					Makings.NOTION_M: modP( 0,  0,  0,  0,  0,  0),
					Makings.IDEA_O  : modP( 1, -1,  0,  0,  0,  0),
					Makings.IDEA_P  : modP( 0,  0,  1,  0,  0, -1),
					Makings.WORK_H  : modP(-1,  0,  0,  0,  1,  0),
					Makings.WORK_S  : modP( 1,  0, -1,  0,  0,  0),
					Makings.CHAR_C  : modP( 0,  0,  0,  0,  0,  0),
					Makings.CHAR_B  : modP( 0,  0,  0,  0,  0,  0),
					Makings.STYLE_F : modP( 0,  1, -1,  0,  0,  0),
					Makings.STYLE_P : modP( 0,  0,  0, -1,  1,  0),
					Makings.PRIDE_P : modP(-1,  0,  0,  0,  0,  1),
					Makings.PRIDE_M : modP(-1,  0,  1,  0,  0,  0),
					Makings.REF_R   : modP( 0,  0,  1, -1,  0,  0),
					Makings.REF_B   : modP( 0,  0, -1,  1,  0,  0),
					Makings.GRACE_G : modP(-1,  0,  0,  1,  0,  0),
					Makings.GRACE_R : modP( 1,  0,  0, -1,  0,  0),
					Makings.LINER_H : modP( 0, -1,  0,  1,  0,  0),
					Makings.LINER_M : modP( 1,  0,  0,  0,  0, -1),
					Makings.PER_S   : modP( 0,  0,  0,  0,  0,  0),
					Makings.PER_T   : modP( 0,  0,  0,  0,  0,  0),
					Makings.FAME_H  : modP( 0,  0,  0,  0,  0,  0),
					Makings.FAME_A  : modP( 0,  0,  0,  0,  0,  0),
				];
			}
		} else static assert ( 0);
	}
	/// 特徴による精神能力の修正値を返す。
	const
	const(real[Mental][E]) mentalMod(E)(string legacyName) { mixin(S_TRACE);
		static if (is(E:Sex)) {
			return [
				Sex.MALE  : modM( 0.5,  0  ,  0  ,  0  ,  0  ),
				Sex.FEMALE: modM( 0  ,  0.5,  0  ,  0  ,  0  ),
			];
		} else static if (is(E:Period)) {
			return [
				Period.CHILD: modM( 0  , -0.5,  0  ,  0.5,  0  ),
				Period.YOUNG: modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				Period.ADULT: modM(-0.5,  0.5,  0  ,  0  ,  0  ),
				Period.OLD  : modM(-0.5,  0.5, -0.5,  0  ,  0.5),
			];
		} else static if (is(E:Nature)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Nature.SPI: modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Nature.AGL: modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Nature.STR: modM( 0  ,  0  ,  1.5,  0  ,  0  ),
					Nature.VIT: modM( 1  , -0.5,  0.5,  0  ,  0  ),
					Nature.INT: modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Nature.SCH: modM( 0  ,  0.5,  0  ,  0  ,  1  ),
					Nature.MED: modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Nature.BRI: modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Nature.MAT: modM( 1  ,  0  ,  1  ,  0  ,  0  ),
					Nature.GEN: modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Nature.HER: modM( 0  ,  0  ,  1  ,  1  , -0.5),
					Nature.DIV: modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				];
			} else if ("darkwirth" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature.SPI: modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Nature.AGL: modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Nature.STR: modM( 1  ,  0  ,  0  ,  0  ,  0  ),
					Nature.VIT: modM( 0.5, -0.5,  0.5,  0  ,  0  ),
					Nature.INT: modM( 0  ,  1  ,  0  ,  0  ,  0  ),
					Nature.SCH: modM( 0  , -0.5,  0  ,  0  ,  0.5),
					Nature.MED: modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Nature.BRI: modM( 0  ,  0.5,  0  ,  0.5,  0  ),
					Nature.MAT: modM( 0.5,  0  ,  0.5,  0  ,  0  ),
					Nature.GEN: modM( 0  ,  0.5,  0  ,  0  ,  1  ),
					Nature.HER: modM( 0  ,  0  ,  0  ,  0  ,  1  ),
					Nature.DIV: modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				];
			} else { mixin(S_TRACE);
				return [
					Nature.SPI: modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Nature.AGL: modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Nature.STR: modM( 0  ,  0  ,  1  ,  0  ,  0  ),
					Nature.VIT: modM( 0.5, -0.5,  0.5,  0  ,  0  ),
					Nature.INT: modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Nature.SCH: modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Nature.MED: modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Nature.BRI: modM( 0  ,  0.5,  0  ,  0.5,  0  ),
					Nature.MAT: modM( 0.5,  0  ,  0.5,  0  ,  0  ),
					Nature.GEN: modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Nature.HER: modM( 0  ,  0  ,  0.5,  0.5, -0.5),
					Nature.DIV: modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				];
			}
		} else static if (is(E:Makings)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Makings.LOOKS_B : modM( 0  ,  0  ,  0  ,  1  ,  0  ),
					Makings.LOOKS_U : modM( 0  ,  0  ,  0  , -1  ,  0  ),
					Makings.CLASS_H : modM(-0.5,  0  ,  0.5,  0.5,  0  ),
					Makings.CLASS_L : modM( 0  , -0.5,  0  ,  0  ,  0.5),
					Makings.BRED_T  : modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings.BRED_C  : modM( 0  ,  0  ,  0  ,  0  , -0.5),
					Makings.MEANS_H : modM(-0.5,  0  ,  0  ,  0  , -0.5),
					Makings.MEANS_L : modM( 0  ,  0  , -0.5,  0  ,  0  ),
					Makings.FAITH_F : modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings.FAITH_I : modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Makings.RELI_R  : modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings.RELI_U  : modM( 0  ,  0  , -0.5,  0  ,  1  ),
					Makings.DISP_C  : modM( 0  ,  1  ,  0  ,  0  ,  0.5),
					Makings.DISP_S  : modM( 0  , -1  ,  0  ,  0  , -0.5),
					Makings.DESIRE_G: modM( 0.5,  0  , -0.5,  0  ,  0  ),
					Makings.DESIRE_C: modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings.DEVOTE_D: modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings.DEVOTE_S: modM( 0  ,  0  ,  0  , -0.5,  1  ),
					Makings.DISC_O  : modM( 0.5,  0.5,  0  ,  0  ,  0  ),
					Makings.DISC_C  : modM( 0.5,  0  ,  0  , -0.5,  0.5),
					Makings.POLIT_R : modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings.POLIT_C : modM(-0.5,  0.5, -0.5,  0  ,  0  ),
					Makings.SENSE_R : modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings.SENSE_S : modM( 0  ,  0  ,  0.5,  0  ,  0  ),
					Makings.CURIO_B : modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings.CURIO_I : modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings.NOTION_R: modM( 1  , -0.5,  0  ,  0  ,  0  ),
					Makings.NOTION_M: modM(-1  ,  0.5,  0  ,  0  ,  0  ),
					Makings.IDEA_O  : modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings.IDEA_P  : modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings.WORK_H  : modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings.WORK_S  : modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings.CHAR_C  : modM( 0  ,  0  ,  0  ,  1  ,  0  ),
					Makings.CHAR_B  : modM( 0  ,  0  , -0.5, -1  ,  0  ),
					Makings.STYLE_F : modM( 0  , -1  ,  0  ,  0.5,  0  ),
					Makings.STYLE_P : modM( 0  ,  0  , -0.5, -0.5,  0  ),
					Makings.PRIDE_P : modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings.PRIDE_M : modM(-0.5,  0.5,  0  ,  0  , -0.5),
					Makings.REF_R   : modM(-0.5,  0  ,  0  ,  0.5,  0  ),
					Makings.REF_B   : modM( 0.5, -0.5,  0  , -0.5,  0  ),
					Makings.GRACE_G : modM( 0  ,  0  ,  0.5, -0.5,  0  ),
					Makings.GRACE_R : modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings.LINER_H : modM( 0.5,  0  ,  0.5,  0  , -0.5),
					Makings.LINER_M : modM( 0  ,  0  , -0.5,  0.5,  0  ),
					Makings.PER_S   : modM( 0  ,  0  ,  0  ,  0.5, -0.5),
					Makings.PER_T   : modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings.FAME_H  : modM( 0.5,  0  ,  0.5,  0  , -0.5),
					Makings.FAME_A  : modM(-0.5,  0  ,  0  ,  0.5, -0.5),
				];
			} else { mixin(S_TRACE);
				return [
					Makings.LOOKS_B : modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Makings.LOOKS_U : modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings.CLASS_H : modM(-0.5,  0  ,  0.5,  0  ,  0  ),
					Makings.CLASS_L : modM( 0  , -0.5,  0  ,  0  ,  0.5),
					Makings.BRED_T  : modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings.BRED_C  : modM( 0  ,  0  ,  0  ,  0  , -0.5),
					Makings.MEANS_H : modM(-0.5,  0  ,  0  ,  0  , -0.5),
					Makings.MEANS_L : modM( 0.5,  0  , -0.5,  0  ,  0  ),
					Makings.FAITH_F : modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings.FAITH_I : modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Makings.RELI_R  : modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings.RELI_U  : modM( 0  ,  0  , -0.5,  0  ,  0.5),
					Makings.DISP_C  : modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Makings.DISP_S  : modM( 0  , -0.5,  0  ,  0  ,  0  ),
					Makings.DESIRE_G: modM( 0.5, -0.5, -0.5,  0  ,  0  ),
					Makings.DESIRE_C: modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings.DEVOTE_D: modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings.DEVOTE_S: modM( 0.5,  0  ,  0  , -0.5,  0.5),
					Makings.DISC_O  : modM( 0.5,  0  ,  0  ,  0  , -0.5),
					Makings.DISC_C  : modM( 0.5,  0  ,  0  ,  0  ,  0.5),
					Makings.POLIT_R : modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings.POLIT_C : modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Makings.SENSE_R : modM( 0  ,  0.5,  0  , -0.5,  0  ),
					Makings.SENSE_S : modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings.CURIO_B : modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings.CURIO_I : modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings.NOTION_R: modM( 0.5, -0.5,  0  ,  0  ,  0  ),
					Makings.NOTION_M: modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Makings.IDEA_O  : modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings.IDEA_P  : modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings.WORK_H  : modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings.WORK_S  : modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings.CHAR_C  : modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Makings.CHAR_B  : modM( 0  ,  0  , -0.5,  0  ,  0  ),
					Makings.STYLE_F : modM( 0  , -0.5,  0  ,  0.5,  0  ),
					Makings.STYLE_P : modM( 0  ,  0  , -0.5,  0  ,  0  ),
					Makings.PRIDE_P : modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings.PRIDE_M : modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Makings.REF_R   : modM(-0.5,  0  ,  0  ,  0.5,  0  ),
					Makings.REF_B   : modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings.GRACE_G : modM( 0  ,  0  ,  0.5, -0.5,  0  ),
					Makings.GRACE_R : modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings.LINER_H : modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings.LINER_M : modM( 0  ,  0  , -0.5,  0.5,  0  ),
					Makings.PER_S   : modM( 0  ,  0  ,  0  ,  0.5, -0.5),
					Makings.PER_T   : modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings.FAME_H  : modM( 0  , -0.5,  0.5,  0  , -0.5),
					Makings.FAME_A  : modM(-0.5,  0  ,  0  ,  0  ,  0  ),
				];
			}
		} else static assert (0);
	}
}
