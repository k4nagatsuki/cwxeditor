
module cwx.props;

import cwx.system;
import cwx.msgs;
import cwx.utils;
import cwx.structs;
import cwx.event;

import std.path;

public class Looks {
public:
	const string[] fontFiles() {
		return [
			"Data" ~ sep.idup ~ "Font" ~ sep.idup ~ "gothic.ttf",
			"Data" ~ sep.idup ~ "Font" ~ sep.idup ~ "mincho.ttf",
			"Data" ~ sep.idup ~ "Font" ~ sep.idup ~ "uigothic.ttf"
		];
	}
	const CPoint castCardNamePoint(){return CPoint(5, 5);}
	const CPoint menuCardNamePoint(){return CPoint(5, 5);}
	const CPoint cardNamePoint(){return CPoint(5, 5);}
	const CSize cardSize(){return CSize(74, 94);}
	const CSize summarySize() {return CSize(400, 370);}
	const CPoint summaryImageXY() {return CPoint(163, 65);}
	const int summaryLevelY() {return 15;}
	const int summaryTitleY() {return 35;}
	const CPoint summaryDescXY() {return CPoint(65, 175);}
	const int summaryDescLen() {return 40;}
	const int summaryDescLine() {return 11;}
	const int summaryPageY() {return 340;}
	const CRGB summaryLevelColor() {return CRGB(32, 128, 128);}
	const int posLeftMax() {return 9999;}
	const int posLeftMin() {return -9999;}
	const int posTopMax() {return 9999;}
	const int posTopMin() {return -9999;}
	const int backWidthMax() {return 9999;}
	const int backWidthMin() {return -9999;}
	const int backHeightMax() {return 9999;}
	const int backHeightMin() {return -9999;}
	const double cardSizeMin(){return 0.50;}
	const double cardSizeMax(){return 3.0;}
	const CInsets castCardInsets(){return CInsets(18, 11, 18, 10);}
	const CInsets menuCardInsets(){return CInsets(13, 3, 3, 3);}
	const CInsets cardInsets(){return menuCardInsets;}
	const uint partyMax() {return 6;}
	const CPoint[] partyCardXY() {
		return [
			CPoint(8, 285),
			CPoint(112, 285),
			CPoint(216, 285),
			CPoint(320, 285),
			CPoint(424, 285),
			CPoint(528, 285)
		];
	}

	const CRect messageBounds() {return CRect(81, 50, 470, 180);}
	const int messageButtonHeight() {return 25;}
	const CRGB messageLineColor1() {return CRGB(0, 0, 0);}
	const CRGB messageLineColor2() {return CRGB(128, 0, 0);}
	const CRGB messageBackColor() {return CRGB(0, 0, 128);}
	const CRGB messageForeColor() {return CRGB(255, 255, 255);}
	const CRGB messageHemColor() {return CRGB(0, 0, 0);}
	const CPoint messageStartPos(bool legacy, bool withTalker) {
		if (legacy) {
			return withTalker ? CPoint(115, 11) : CPoint(16, 11);
		} else {
			return withTalker ? CPoint(115, 15) : CPoint(15, 15);
		}
	}
	const CPoint messageTalkerPos() {return CPoint(15, 43);}
	const int levelMax() {return 15;}

	const int aptVeryHigh() {return 15;}
	const int aptHigh() {return 9;}
	const int aptNormal() {return 3;}

	const CPoint useStoneXY() {return CPoint(60, 75);}
	const CPoint aptStoneXY() {return CPoint(60, 90);}

	const CPoint premiumXY() {return CPoint(5, 5);}
	const uint itemCardMaxNum(uint lev) {
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	const uint skillCardMaxNum(uint lev) {
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	const uint beastCardMaxNum(uint lev) {
		int r = (lev + 1) / 4 + 1;
		return r <= 10 ? r : 10;
	}
	const int cardDescLen() {return 38;}
	const int cardDescLine() {return 7;}

	const int messageImageLen() {return 34;}
	const int messageLen() {return 44;}
	const int messageLine() {return 7;}

	const int stepMaxCount() {return 10;}

	const uint castNameLimit() {return 14;}
	const uint nameLimit() {return 12;}
	const uint castLevelMax() {return 99;}
	const uint lifeMax() {return 999;}
	const uint lifeCalc(uint lev, uint vit, uint spi) {
		return cast(uint) (((lev + 1.0) * (vit / 2.0 + 4.0)) + (spi / 2.0));
	}
	const uint couponValueMax() {return Content.couponValue_max;}
	const uint physicalMax() {return 15;}
	const uint physicalCutMin() {return 1;}
	const uint physicalCutMaxBase() {return 6;}
	const uint physicalNormal() {return 6;}
	const uint[] physicalBorders() {return [1, 6, 12];}
	const uint mentalMax() {return 4;}
	const uint mentalCut() {return 3;}
	const uint[] mentalBorders() {return [3];}

	const uint skillLevelMax() {return 999;}
	const int skillPrice(int lev) {return (lev + 2) * 200;}
	const int beastPrice() {return 500;}
	const uint useCountMax() {return 999;}
	const uint priceMax() {return Content.money_max;}
	const uint enhanceMax() {return 10;}
	const int keyCodesMaxLegacy() {return 5;}
	const int keyCodesMax() {return 10;}
	const uint motionRoundDefault() {return 10;}
	const uint roundMax() {return 999;}
	const uint paralyzeMax() {return 40;}
	const uint poisonMax() {return 40;}
	const uint stoneBorder() {return 20;}

	const uint idMax() {return 99999;}

	const uint transitionSpeedDef() {
		return Content.transitionSpeed_min
			+ ((Content.transitionSpeed_max - Content.transitionSpeed_min) / 2);
	}

	const CSize viewSize() {return CSize(632, 420);}

	const string monospace() {
		version (Windows) {
			return "ＭＳ ゴシック";
		}
		return "IPAゴシック";
	}

	private static string gothic(bool legacy) {
		version (Windows) {
			if (legacy) return "ＭＳ ゴシック";
		}
		return "IPAゴシック";
	}
	private static string pgothic(bool legacy) {
		version (Windows) {
			if (legacy) return "ＭＳ Ｐゴシック";
		}
		return "IPA Pゴシック";
	}
	private static string mincho(bool legacy) {
		version (Windows) {
			if (legacy) return "ＭＳ 明朝";
		}
		return "IPA明朝";
	}
	private static string uigothic(bool legacy) {
		version (Windows) {
			if (legacy) return "MS UI Gothic";
		}
		return "IPA UIゴシック";
	}
	const CFont textDlgFont(uint defSize) {
		return CFont(gothic(true), defSize <= 0 ? 12 : defSize, false, false);
	}
	const CFont castCardNameFont(bool legacy) {return CFont(uigothic(legacy), 9, true, false);}
	const CFont castCardLevelFont(bool legacy) {return CFont(mincho(legacy), 24, true, true);}
	const CInsets castCardLevelInsets() {return CInsets(2, 8, 0, 0);}
	const CRGB castCardLevelColor() {return CRGB(0, 0, 0, 128);}
	const CPoint castLifeBarPoint() {return CPoint(8, 110);}
	const int statusX() {return 7;}
	const uint statusVerMax() {return 6;}
	const CFont beastNumFont(bool legacy){return CFont(pgothic(legacy), 9, false, false);}

	const CFont menuCardNameFont(bool legacy){return castCardNameFont(legacy);}
	const CFont cardNameFont(bool legacy){return castCardNameFont(legacy);}
	const CFont useCountFont(bool legacy){return CFont(mincho(legacy), 12, true, false);}
	const CPoint useCountPoint(){return CPoint(10, 90);}
	const CRGB recycleNumColor() {return CRGB(255, 255, 0);}
	const CFont summaryLevelFont(bool legacy) {return CFont(mincho(legacy), 10, true, true);}
	const CFont summaryTitleFont(bool legacy) {return CFont(mincho(legacy), 16, true, false);}
	const CFont summaryDescFont(bool legacy) {
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 10, true, false);
		}
		return CFont(gothic(legacy), 10, true, false);
	}
	const uint summaryDescLineHeightClassic() {
		return 15;
	}
	const CFont summaryPageFont(bool legacy) {return CFont(gothic(legacy), 9, true, false);}
	const CFont cardDescFont(bool legacy) {return CFont(gothic(legacy), 10, false, false);}
	const CFont messageFont(bool legacy) {
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 15, true, false);
		}
		return CFont(gothic(legacy), 16, false, false);
	}
	const CFont messageSelectFont(bool legacy) {
		version (Windows) {
			if (legacy) return CFont(pgothic(legacy), 11, true, false);
		}
		return CFont(pgothic(legacy), 14, false, false);
	}
	const CFont scriptErrorFont(uint defSize) {
		return textDlgFont(defSize);
	}
}

public class CProps {
private:
	cwx.system.System _sys;
	Msgs _msgs;
	Looks _looks;
	string _appPath;
public:
	this(string appPath, cwx.system.System sys) {
		_appPath = appPath;
		_sys = sys;
		_msgs = new Msgs;
		_looks = new Looks;
	}
	const string appPath() {return _appPath;}
	const const(cwx.system.System) sys() {return _sys;}
	const const(Msgs) msgs() {return _msgs;}
	const const(Looks) looks() {return _looks;}
	const string toAppAbs(string path) {
		if (cwx.utils.isabs(path)) return nabs(path);
		return nabs(std.path.buildPath(_appPath, path));
	}
}
