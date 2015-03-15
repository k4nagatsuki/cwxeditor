
module cwx.system;

import cwx.perf;
import cwx.features;
import cwx.types;

import std.algorithm;
import std.conv;
import std.string;
import std.path;

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
		if (s == Sex(0)) return "♂";
		if (s == Sex(1)) return "♀";
		throw new Exception(s.text());
	}
	/// ditto
	const
	string periodName(Period p, string legacyName) { mixin(S_TRACE);
		if (p == Period(0)) return "子供";
		if (p == Period(1)) return "若者";
		if (p == Period(2)) return "大人";
		if (p == Period(3)) return "老人";
		throw new Exception(p.text());
	}
	/// ditto
	const
	string natureName(Nature n, string legacyName) { mixin(S_TRACE);
		if (n == Nature(0)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "darkwirth": return "他種族";
			default: return "標準型";
			}
		}
		if (n == Nature(1)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "隠密型";
			case "darkwirth": return "人獣族";
			default: return "万能型";
			}
		}
		if (n == Nature(2)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "根性型";
			case "oedowirth": return "剣客型";
			case "darkwirth": return "悪鬼族";
			default: return "勇将型";
			}
		}
		if (n == Nature(3)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "熱血型";
			case "darkwirth": return "蜥蜴族";
			default: return "豪傑型";
			}
		}
		if (n == Nature(4)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "理性型";
			case "oedowirth": return "参謀型";
			case "darkwirth": return "妖木族";
			default: return "知将型";
			}
		}
		if (n == Nature(5)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "秀才型";
			case "darkwirth": return "小悪魔";
			default:return "策士型";
			}
		}
		if (n == Nature(6)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "努力型";
			case "oedowirth": return "晩成型";
			case "darkwirth": return "妖虫族";
			default: return "凡庸型";
			}
		}
		if (n == Nature(7)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "秀英型";
			case "darkwirth": return "人狼族";
			default: return "英明型";
			}
		}
		if (n == Nature(8)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "剣豪型";
			case "darkwirth": return "鬼人族";
			default: return "無双型";
			}
		}
		if (n == Nature(9)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "oedowirth": return "賢才型";
			case "darkwirth": return "大悪魔";
			default: return "天才型";
			}
		}
		if (n == Nature(10)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "s_c_wirth": return "超人型";
			case "oedowirth": return "覇道型";
			case "darkwirth": return "闇の者";
			default: return "英雄型";
			}
		}
		if (n == Nature(11)) { mixin(S_TRACE);
			switch (toLower(legacyName)) {
			case "darkwirth": return "神竜族";
			default: return "神仙型";
			}
		}
		throw new Exception(n.text());
	}
	/// ditto
	const
	string makingsName(Makings m, string legacyName) { mixin(S_TRACE);
		if (m == Makings(0))  return "秀麗";
		if (m == Makings(1))  return "醜悪";
		if (m == Makings(2))  return "高貴の出";
		if (m == Makings(3))  return "下賎の出";
		if (m == Makings(4))  return "都会育ち";
		if (m == Makings(5))  return "田舎育ち";
		if (m == Makings(6))  return "裕福";
		if (m == Makings(7))  return "貧乏";
		if (m == Makings(8))  return "厚き信仰";
		if (m == Makings(9))  return "不心得者";
		if (m == Makings(10)) return "誠実";
		if (m == Makings(11)) return "不実";
		if (m == Makings(12)) return "冷静沈着";
		if (m == Makings(13)) return "猪突猛進";
		if (m == Makings(14)) return "貪欲";
		if (m == Makings(15)) return "無欲";
		if (m == Makings(16)) return "献身的";
		if (m == Makings(17)) return "利己的";
		if (m == Makings(18)) return "秩序派";
		if (m == Makings(19)) return "混沌派";
		if (m == Makings(20)) return "進取派";
		if (m == Makings(21)) return "保守派";
		if (m == Makings(22)) return "神経質";
		if (m == Makings(23)) return "鈍感";
		if (m == Makings(24)) return "好奇心旺盛";
		if (m == Makings(25)) return "無頓着";
		if (m == Makings(26)) return "過激";
		if (m == Makings(27)) return "穏健";
		if (m == Makings(28)) return "楽観的";
		if (m == Makings(29)) return "悲観的";
		if (m == Makings(30)) return "勤勉";
		if (m == Makings(31)) return "遊び人";
		if (m == Makings(32)) return "陽気";
		if (m == Makings(33)) return "内気";
		if (m == Makings(34)) return "派手";
		if (m == Makings(35)) return "地味";
		if (m == Makings(36)) return "高慢";
		if (m == Makings(37)) return "謙虚";
		if (m == Makings(38)) return "上品";
		if (m == Makings(39)) return "粗野";
		if (m == Makings(40)) return "武骨";
		if (m == Makings(41)) return "繊細";
		if (m == Makings(42)) return "硬派";
		if (m == Makings(43)) return "軟派";
		if (m == Makings(44)) return "お人好し";
		if (m == Makings(45)) return "ひねくれ者";
		if (m == Makings(46)) return "名誉こそ命";
		if (m == Makings(47)) return "愛に生きる";
		throw new Exception(m.text());
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

	private static immutable FKC_SUCCESS = "○";
	private static immutable FKC_FAILURE = "×";
	private static immutable FKC_HASNOT = "！";
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
		final switch (keyCode.kind) {
		case FKCKind.Use: return keyCode.keyCode;
		case FKCKind.Success: return keyCode.keyCode ~ FKC_SUCCESS;
		case FKCKind.Failure: return keyCode.keyCode ~ FKC_FAILURE;
		case FKCKind.HasNot: return FKC_HASNOT ~ keyCode.keyCode;
		}
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
		static if (is(T:Physical)) {
			static immutable KEYS = [
				Physical.DEX,
				Physical.AGL,
				Physical.INT,
				Physical.STR,
				Physical.VIT,
				Physical.MIN,
			];
		} else static if (is(T:Mental)) {
			static immutable KEYS = [
				Mental.AGGRESSIVE,
				Mental.CAUTIOUS,
				Mental.BRAVE,
				Mental.CHEERFUL,
				Mental.TRICKISH,
			];
		} else static assert (0);
		foreach (iKey, key; KEYS) { mixin(S_TRACE);
			R v = values[iKey];
			r[key] = v;
			static if (is(T:Mental)) {
				r[.reverseMental(key)] = -v;
			}
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
				Sex(0): modP( 0,  0,  0,  1,  0,  0),
				Sex(1): modP( 1,  0,  0,  0,  0,  0),
			];
		} else static if (is(E:Period)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Period(0): modP( 1,  1,  1,  0,  0,  1),
					Period(1): modP( 1,  1,  1,  1,  1,  1),
					Period(2): modP( 1,  1,  1,  1,  0,  2),
					Period(3): modP( 1,  0,  2,  0,  0,  2),
				];
			} else { mixin(S_TRACE);
				return [
					Period(0): modP( 1,  1,  0, -1, -1,  0),
					Period(1): modP( 0,  0,  0,  0,  0,  0),
					Period(2): modP( 0,  0,  0,  0, -1,  0),
					Period(3): modP(-1, -1,  1, -1, -1,  1),
				];
			}
		} else static if (is(E:Nature)) {
			if ("cw´standard" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature(0):  modP(-1, -1, -1, -1, -1,  1),
					Nature(1):  modP( 0,  1, -1, -1, -1, -2),
					Nature(2):  modP(-1, -1, -2,  0,  0,  0),
					Nature(3):  modP(-2, -1, -2,  1,  1, -1),
					Nature(4):  modP(-1, -1,  0, -1, -1,  0),
					Nature(5):  modP( 0,  0,  1, -2, -2, -1),
					Nature(6):  modP(-3, -3, -3, -3, -3, -3),
					Nature(7):  modP( 0,  1,  0,  0,  0,  1),
					Nature(8):  modP(-1,  0, -1,  2,  2,  0),
					Nature(9):  modP( 0,  0,  2, -1, -1,  2),
					Nature(10): modP( 0,  0,  1,  1,  1,  2),
					Nature(11): modP( 1,  1,  1,  1,  1,  2),
				];
			} else if ("cw´heroic" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature(0):  modP( 0,  0,  0,  0,  0,  2),
					Nature(1):  modP( 1,  1,  0,  0,  0,  0),
					Nature(2):  modP( 0,  0, -1,  1,  1,  1),
					Nature(3):  modP(-1,  0, -1,  2,  2,  0),
					Nature(4):  modP( 0,  0,  2, -1,  0,  1),
					Nature(5):  modP( 1,  0,  3, -1, -1,  0),
					Nature(6):  modP(-2, -2, -2, -2, -2, -2),
					Nature(7):  modP( 1,  1,  1,  1,  1,  2),
					Nature(8):  modP( 0,  1,  0,  3,  2,  1),
					Nature(9):  modP( 1,  1,  3,  0,  0,  2),
					Nature(10): modP( 2,  2,  2,  2,  2,  2),
					Nature(11): modP( 2,  2,  3,  2,  2,  3),
				];
			} else if ("cw´commoner" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature(0):  modP(-2, -2, -2, -2, -2, -1),
					Nature(1):  modP(-1, -1, -2, -2, -2, -3),
					Nature(2):  modP(-2, -2, -2, -1, -2, -2),
					Nature(3):  modP(-3, -2, -3,  0, -1, -2),
					Nature(4):  modP(-2, -2, -1, -2, -2, -2),
					Nature(5):  modP(-1, -2,  0, -3, -3, -2),
					Nature(6):  modP(-3, -3, -3, -3, -3, -3),
					Nature(7):  modP( 0,  1,  0,  0,  0,  1),
					Nature(8):  modP(-1,  0, -1,  2,  2,  0),
					Nature(9):  modP( 0,  0,  2, -1, -1,  2),
					Nature(10): modP( 0,  0,  1,  1,  1,  2),
					Nature(11): modP( 1,  1,  1,  1,  1,  2),
				];
			} else if ("darkwirth" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature(0):  modP( 1,  0,  0,  0,  1,  1),
					Nature(1):  modP( 1,  1,  0,  0,  0, -1),
					Nature(2):  modP(-1,  0, -2,  2,  2, -1),
					Nature(3):  modP(-2, -1, -2,  3,  2, -2),
					Nature(4):  modP(-2, -2,  2, -1,  2,  1),
					Nature(5):  modP(-2,  2,  3, -2, -2, -1),
					Nature(6):  modP(-1,  0, -3, -3, -3, -2),
					Nature(7):  modP( 1,  1,  1,  1,  1,  1),
					Nature(8):  modP( 0,  1,  0,  3,  2,  0),
					Nature(9):  modP( 0,  2,  3,  0,  0,  1),
					Nature(10): modP( 1,  2,  1,  2,  2,  1),
					Nature(11): modP( 2,  2,  2,  2,  2,  2),
				];
			} else { mixin(S_TRACE);
				return [
					Nature(0):  modP( 0,  0,  0,  0,  0,  1),
					Nature(1):  modP( 1,  1,  0,  0,  0, -1),
					Nature(2):  modP(-1,  0, -1,  2,  0,  0),
					Nature(3):  modP(-2, -1, -2,  3,  1, -1),
					Nature(4):  modP( 0,  0,  2, -1, -1,  0),
					Nature(5):  modP( 0, -1,  3, -2, -2,  0),
					Nature(6):  modP(-2, -2, -2, -2, -2, -2),
					Nature(7):  modP( 1,  1,  1,  1,  1,  1),
					Nature(8):  modP( 0,  1,  0,  3,  2,  0),
					Nature(9):  modP( 1,  0,  3,  0,  0,  2),
					Nature(10): modP( 1,  1,  2,  2,  1,  2),
					Nature(11): modP( 2,  2,  2,  2,  2,  2),
				];
			}
		} else static if (is(E:Makings)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Makings(0):  modP( 0,  0,  0,  0, -1,  0),
					Makings(1):  modP( 0,  0,  0,  0,  1,  0),
					Makings(2):  modP( 0,  0,  0,  0,  0,  0),
					Makings(3):  modP( 0,  0,  0,  1,  0, -1),
					Makings(4):  modP( 0,  0,  1,  0, -1,  0),
					Makings(5):  modP(-1,  0,  0,  0,  1,  0),
					Makings(6):  modP( 0,  0,  0,  0,  0, -1),
					Makings(7):  modP( 0,  0,  0,  0,  0,  1),
					Makings(8):  modP( 0,  0, -1,  0,  0,  1),
					Makings(9):  modP( 0,  0,  0,  0,  0,  0),
					Makings(10): modP( 0,  0,  0,  0,  0,  0),
					Makings(11): modP( 0,  0,  0,  0,  0,  0),
					Makings(12): modP( 0, -1,  0,  0,  0,  1),
					Makings(13): modP( 0,  1,  0,  0,  0, -1),
					Makings(14): modP( 0,  0,  0,  0,  1, -1),
					Makings(15): modP( 1,  0,  0,  0, -1,  0),
					Makings(16): modP( 0,  0,  0,  0, -1,  1),
					Makings(17): modP( 0,  0,  1,  0,  0, -1),
					Makings(18): modP( 0,  0,  0,  0,  0,  0),
					Makings(19): modP(-1,  1,  0,  0,  0,  0),
					Makings(20): modP( 0,  1,  0,  0, -1,  0),
					Makings(21): modP( 0,  0,  0,  0,  0,  0),
					Makings(22): modP( 0,  1,  0, -1,  0,  0),
					Makings(23): modP( 0,  0, -1,  0,  1,  0),
					Makings(24): modP( 0,  0,  0,  0,  0,  0),
					Makings(25): modP( 0, -1,  0,  0,  1,  0),
					Makings(26): modP( 0,  0,  0,  1, -1,  0),
					Makings(27): modP( 0,  0,  0, -1,  0,  1),
					Makings(28): modP( 1, -1,  0,  0,  0,  0),
					Makings(29): modP( 0,  0,  0,  0,  0,  0),
					Makings(30): modP(-1,  0,  1,  0,  0,  0),
					Makings(31): modP( 1,  0, -1,  0,  0,  0),
					Makings(32): modP( 0,  0,  0,  0,  0,  0),
					Makings(33): modP( 0,  0,  0,  0,  0,  0),
					Makings(34): modP( 0,  1, -1,  0,  0,  0),
					Makings(35): modP( 0,  0,  0, -1,  1,  0),
					Makings(36): modP(-1,  0,  0,  0,  0,  1),
					Makings(37): modP( 0, -1,  1,  0,  0,  0),
					Makings(38): modP( 0,  0,  1, -1,  0,  0),
					Makings(39): modP( 0,  0, -1,  1,  0,  0),
					Makings(40): modP(-1,  0,  0,  1,  0,  0),
					Makings(41): modP( 1,  0,  0, -1,  0,  0),
					Makings(42): modP( 0, -1,  0,  1,  0,  0),
					Makings(43): modP( 1,  0,  0,  0,  0, -1),
					Makings(44): modP( 0,  0,  0,  0,  0,  0),
					Makings(45): modP( 0,  0,  0,  0,  0,  0),
					Makings(46): modP( 0,  0,  0,  0,  0,  0),
					Makings(47): modP( 0,  0,  0,  0,  0,  0),
				];
			} else { mixin(S_TRACE);
				return [
					Makings(0):  modP( 0,  0,  0,  0, -1,  0),
					Makings(1):  modP( 0,  0,  0,  0,  1,  0),
					Makings(2):  modP( 0,  0,  0,  0,  0,  0),
					Makings(3):  modP( 0,  0,  0,  0,  0,  0),
					Makings(4):  modP( 0,  0,  1,  0, -1,  0),
					Makings(5):  modP( 0, -1,  0,  0,  1,  0),
					Makings(6):  modP( 0,  0,  0,  0,  0, -1),
					Makings(7):  modP( 0,  0,  0,  0,  0,  1),
					Makings(8):  modP( 0,  0, -1,  0,  0,  1),
					Makings(9):  modP( 0,  0,  0,  0,  0,  0),
					Makings(10): modP( 0,  0,  0,  0,  0,  0),
					Makings(11): modP( 0,  0,  0,  0,  0,  0),
					Makings(12): modP( 0, -1,  1,  0,  0,  0),
					Makings(13): modP( 0,  1,  0,  0,  0, -1),
					Makings(14): modP( 0,  0,  0,  0,  1, -1),
					Makings(15): modP( 0,  0,  0,  0,  0,  0),
					Makings(16): modP( 0,  0,  0,  0, -1,  1),
					Makings(17): modP(-1,  1,  0,  0,  0,  0),
					Makings(18): modP( 0,  0,  0,  0,  0,  0),
					Makings(19): modP( 0,  0,  0,  1,  0, -1),
					Makings(20): modP( 0,  1,  0,  0, -1,  0),
					Makings(21): modP( 0,  0,  0, -1,  0,  1),
					Makings(22): modP( 0,  1,  0, -1,  0,  0),
					Makings(23): modP( 0,  0, -1,  0,  1,  0),
					Makings(24): modP( 1,  0,  0,  0, -1,  0),
					Makings(25): modP( 0, -1,  0,  0,  0,  1),
					Makings(26): modP( 0,  0,  0,  1, -1,  0),
					Makings(27): modP( 0,  0,  0,  0,  0,  0),
					Makings(28): modP( 1, -1,  0,  0,  0,  0),
					Makings(29): modP( 0,  0,  1,  0,  0, -1),
					Makings(30): modP(-1,  0,  0,  0,  1,  0),
					Makings(31): modP( 1,  0, -1,  0,  0,  0),
					Makings(32): modP( 0,  0,  0,  0,  0,  0),
					Makings(33): modP( 0,  0,  0,  0,  0,  0),
					Makings(34): modP( 0,  1, -1,  0,  0,  0),
					Makings(35): modP( 0,  0,  0, -1,  1,  0),
					Makings(36): modP(-1,  0,  0,  0,  0,  1),
					Makings(37): modP(-1,  0,  1,  0,  0,  0),
					Makings(38): modP( 0,  0,  1, -1,  0,  0),
					Makings(39): modP( 0,  0, -1,  1,  0,  0),
					Makings(40): modP(-1,  0,  0,  1,  0,  0),
					Makings(41): modP( 1,  0,  0, -1,  0,  0),
					Makings(42): modP( 0, -1,  0,  1,  0,  0),
					Makings(43): modP( 1,  0,  0,  0,  0, -1),
					Makings(44): modP( 0,  0,  0,  0,  0,  0),
					Makings(45): modP( 0,  0,  0,  0,  0,  0),
					Makings(46): modP( 0,  0,  0,  0,  0,  0),
					Makings(47): modP( 0,  0,  0,  0,  0,  0),
				];
			}
		} else static assert ( 0);
	}
	/// 特徴による精神能力の修正値を返す。
	const
	const(real[Mental][E]) mentalMod(E)(string legacyName) { mixin(S_TRACE);
		static if (is(E:Sex)) {
			return [
				Sex(0): modM( 0.5,  0  ,  0  ,  0  ,  0  ),
				Sex(1): modM( 0  ,  0.5,  0  ,  0  ,  0  ),
			];
		} else static if (is(E:Period)) {
			return [
				Period(0): modM( 0  , -0.5,  0  ,  0.5,  0  ),
				Period(1): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				Period(2): modM(-0.5,  0.5,  0  ,  0  ,  0  ),
				Period(3): modM(-0.5,  0.5, -0.5,  0  ,  0.5),
			];
		} else static if (is(E:Nature)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Nature(0):  modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Nature(1):  modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Nature(2):  modM( 0  ,  0  ,  1.5,  0  ,  0  ),
					Nature(3):  modM( 1  , -0.5,  0.5,  0  ,  0  ),
					Nature(4):  modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Nature(5):  modM( 0  ,  0.5,  0  ,  0  ,  1  ),
					Nature(6):  modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Nature(7):  modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Nature(8):  modM( 1  ,  0  ,  1  ,  0  ,  0  ),
					Nature(9):  modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Nature(10): modM( 0  ,  0  ,  1  ,  1  , -0.5),
					Nature(11): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				];
			} else if ("darkwirth" == .toLower(legacyName)) { mixin(S_TRACE);
				return [
					Nature(0):  modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Nature(1):  modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Nature(2):  modM( 1  ,  0  ,  0  ,  0  ,  0  ),
					Nature(3):  modM( 0.5, -0.5,  0.5,  0  ,  0  ),
					Nature(4):  modM( 0  ,  1  ,  0  ,  0  ,  0  ),
					Nature(5):  modM( 0  , -0.5,  0  ,  0  ,  0.5),
					Nature(6):  modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Nature(7):  modM( 0  ,  0.5,  0  ,  0.5,  0  ),
					Nature(8):  modM( 0.5,  0  ,  0.5,  0  ,  0  ),
					Nature(9):  modM( 0  ,  0.5,  0  ,  0  ,  1  ),
					Nature(10): modM( 0  ,  0  ,  0  ,  0  ,  1  ),
					Nature(11): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				];
			} else { mixin(S_TRACE);
				return [
					Nature(0):  modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Nature(1):  modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Nature(2):  modM( 0  ,  0  ,  1  ,  0  ,  0  ),
					Nature(3):  modM( 0.5, -0.5,  0.5,  0  ,  0  ),
					Nature(4):  modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Nature(5):  modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Nature(6):  modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Nature(7):  modM( 0  ,  0.5,  0  ,  0.5,  0  ),
					Nature(8):  modM( 0.5,  0  ,  0.5,  0  ,  0  ),
					Nature(9):  modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Nature(10): modM( 0  ,  0  ,  0.5,  0.5, -0.5),
					Nature(11): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
				];
			}
		} else static if (is(E:Makings)) {
			if (legacyName.toLower().startsWith("cw´")) { mixin(S_TRACE);
				return [
					Makings(0):  modM( 0  ,  0  ,  0  ,  1  ,  0  ),
					Makings(1):  modM( 0  ,  0  ,  0  , -1  ,  0  ),
					Makings(2):  modM(-0.5,  0  ,  0.5,  0.5,  0  ),
					Makings(3):  modM( 0  , -0.5,  0  ,  0  ,  0.5),
					Makings(4):  modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings(5):  modM( 0  ,  0  ,  0  ,  0  , -0.5),
					Makings(6):  modM(-0.5,  0  ,  0  ,  0  , -0.5),
					Makings(7):  modM( 0  ,  0  , -0.5,  0  ,  0  ),
					Makings(8):  modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings(9):  modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Makings(10): modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings(11): modM( 0  ,  0  , -0.5,  0  ,  1  ),
					Makings(12): modM( 0  ,  1  ,  0  ,  0  ,  0.5),
					Makings(13): modM( 0  , -1  ,  0  ,  0  , -0.5),
					Makings(14): modM( 0.5,  0  , -0.5,  0  ,  0  ),
					Makings(15): modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings(16): modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings(17): modM( 0  ,  0  ,  0  , -0.5,  1  ),
					Makings(18): modM( 0.5,  0.5,  0  ,  0  ,  0  ),
					Makings(19): modM( 0.5,  0  ,  0  , -0.5,  0.5),
					Makings(20): modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings(21): modM(-0.5,  0.5, -0.5,  0  ,  0  ),
					Makings(22): modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings(23): modM( 0  ,  0  ,  0.5,  0  ,  0  ),
					Makings(24): modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings(25): modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings(26): modM( 1  , -0.5,  0  ,  0  ,  0  ),
					Makings(27): modM(-1  ,  0.5,  0  ,  0  ,  0  ),
					Makings(28): modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings(29): modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings(30): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings(31): modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings(32): modM( 0  ,  0  ,  0  ,  1  ,  0  ),
					Makings(33): modM( 0  ,  0  , -0.5, -1  ,  0  ),
					Makings(34): modM( 0  , -1  ,  0  ,  0.5,  0  ),
					Makings(35): modM( 0  ,  0  , -0.5, -0.5,  0  ),
					Makings(36): modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings(37): modM(-0.5,  0.5,  0  ,  0  , -0.5),
					Makings(38): modM(-0.5,  0  ,  0  ,  0.5,  0  ),
					Makings(39): modM( 0.5, -0.5,  0  , -0.5,  0  ),
					Makings(40): modM( 0  ,  0  ,  0.5, -0.5,  0  ),
					Makings(41): modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings(42): modM( 0.5,  0  ,  0.5,  0  , -0.5),
					Makings(43): modM( 0  ,  0  , -0.5,  0.5,  0  ),
					Makings(44): modM( 0  ,  0  ,  0  ,  0.5, -0.5),
					Makings(45): modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings(46): modM( 0.5,  0  ,  0.5,  0  , -0.5),
					Makings(47): modM(-0.5,  0  ,  0  ,  0.5, -0.5),
				];
			} else { mixin(S_TRACE);
				return [
					Makings(0):  modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Makings(1):  modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings(2):  modM(-0.5,  0  ,  0.5,  0  ,  0  ),
					Makings(3):  modM( 0  , -0.5,  0  ,  0  ,  0.5),
					Makings(4):  modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings(5):  modM( 0  ,  0  ,  0  ,  0  , -0.5),
					Makings(6):  modM(-0.5,  0  ,  0  ,  0  , -0.5),
					Makings(7):  modM( 0.5,  0  , -0.5,  0  ,  0  ),
					Makings(8):  modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings(9):  modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Makings(10): modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings(11): modM( 0  ,  0  , -0.5,  0  ,  0.5),
					Makings(12): modM( 0  ,  0.5,  0  ,  0  ,  0.5),
					Makings(13): modM( 0  , -0.5,  0  ,  0  ,  0  ),
					Makings(14): modM( 0.5, -0.5, -0.5,  0  ,  0  ),
					Makings(15): modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings(16): modM(-0.5,  0  ,  0  ,  0  ,  0  ),
					Makings(17): modM( 0.5,  0  ,  0  , -0.5,  0.5),
					Makings(18): modM( 0.5,  0  ,  0  ,  0  , -0.5),
					Makings(19): modM( 0.5,  0  ,  0  ,  0  ,  0.5),
					Makings(20): modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings(21): modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Makings(22): modM( 0  ,  0.5,  0  , -0.5,  0  ),
					Makings(23): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings(24): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings(25): modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings(26): modM( 0.5, -0.5,  0  ,  0  ,  0  ),
					Makings(27): modM(-0.5,  0.5,  0  ,  0  ,  0  ),
					Makings(28): modM( 0  , -0.5,  0.5,  0  ,  0  ),
					Makings(29): modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings(30): modM( 0  ,  0  ,  0  ,  0  ,  0  ),
					Makings(31): modM( 0  ,  0  ,  0  ,  0.5,  0.5),
					Makings(32): modM( 0  ,  0  ,  0  ,  0.5,  0  ),
					Makings(33): modM( 0  ,  0  , -0.5,  0  ,  0  ),
					Makings(34): modM( 0  , -0.5,  0  ,  0.5,  0  ),
					Makings(35): modM( 0  ,  0  , -0.5,  0  ,  0  ),
					Makings(36): modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings(37): modM( 0  ,  0.5,  0  ,  0  ,  0  ),
					Makings(38): modM(-0.5,  0  ,  0  ,  0.5,  0  ),
					Makings(39): modM( 0.5,  0  ,  0  , -0.5,  0  ),
					Makings(40): modM( 0  ,  0  ,  0.5, -0.5,  0  ),
					Makings(41): modM( 0  ,  0.5, -0.5,  0  ,  0  ),
					Makings(42): modM( 0  ,  0  ,  0.5,  0  , -0.5),
					Makings(43): modM( 0  ,  0  , -0.5,  0.5,  0  ),
					Makings(44): modM( 0  ,  0  ,  0  ,  0.5, -0.5),
					Makings(45): modM( 0  ,  0  ,  0  , -0.5,  0  ),
					Makings(46): modM( 0  , -0.5,  0.5,  0  , -0.5),
					Makings(47): modM(-0.5,  0  ,  0  ,  0  ,  0  ),
				];
			}
		} else static assert (0);
	}

	/// エンジンのファイル名からYadoフォルダの名前を返す。
	const
	string yadoName(string legacyName) { mixin(S_TRACE);
		switch (legacyName.baseName().toLower()) {
		case "s_c_wirth":
			return "heya";
		case "oedowirth":
			return "Naga";
		case "dirkwirth":
			return "mori";
		default:
			return "Yado";
		}
	}
}
