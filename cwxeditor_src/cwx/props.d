
module cwx.props;

import cwx.system;
import cwx.msgs;
import cwx.utils;
import cwx.structs;
import cwx.types;
import cwx.features;
import cwx.summary;

import std.path;
import std.conv;
import std.file;
import std.string;

public class Looks {
public:
	@property const string[] fontFiles() { mixin(S_TRACE);
		return [
			"Data" ~ dirSeparator.idup ~ "Font" ~ dirSeparator.idup ~ "gothic.ttf",
			"Data" ~ dirSeparator.idup ~ "Font" ~ dirSeparator.idup ~ "mincho.ttf",
			"Data" ~ dirSeparator.idup ~ "Font" ~ dirSeparator.idup ~ "uigothic.ttf"
		];
	}
	@property const CPoint castCardNamePoint() {return CPoint(5, 5);}
	@property const CPoint menuCardNamePoint() {return CPoint(5, 5);}
	@property const CPoint cardNamePoint() {return CPoint(5, 5);}
	@property const CSize cardSize() {return CSize(74, 94);}
	@property const CSize summarySize() {return CSize(400, 370);}
	@property const CPoint summaryImageXY() {return CPoint(163, 65);}
	@property const int summaryLevelY() {return 15;}
	@property const int summaryTitleY() {return 35;}
	@property const CPoint summaryDescXY() {return CPoint(65, 175);}
	@property const int summaryDescLen() {return 40;}
	@property const int summaryDescLine() {return 11;}
	@property const int summaryPageY() {return 340;}
	@property const CRGB summaryLevelColor() {return CRGB(32, 128, 128);}
	@property const CInsets castCardInsets(){return CInsets(18, 11, 18, 10);}
	@property const CInsets menuCardInsets(){return CInsets(13, 3, 3, 3);}
	@property const CInsets cardInsets(){return menuCardInsets;}
	@property const CPoint[] partyCardXY() { mixin(S_TRACE);
		return [
			CPoint(8, 285),
			CPoint(112, 285),
			CPoint(216, 285),
			CPoint(320, 285),
			CPoint(424, 285),
			CPoint(528, 285)
		];
	}
	@property const CRect cardNameArea() { return CRect(5, 5, 70, 15); }
	@property const CRect castCardNameArea() { return CRect(5, 5, 85, 15); }

	@property const CRect messageBounds() {return CRect(81, 50, 470, 180);}
	@property const int messageButtonHeight() {return 25;}
	const CPoint messageStartPos(bool legacy, bool withTalker) { mixin(S_TRACE);
		return withTalker ? CPoint(115, 11) : CPoint(16, 11);
	}
	@property const uint messageLineHeight() { return 22; }
	@property const CPoint messageTalkerPos() {return CPoint(15, 43);}
	@property const uint selectionBarMaxWithMessage() { return 7; }
	@property const uint selectionBarMax() { return 13; }

	@property const int aptVeryHigh() {return 15;}
	@property const int aptHigh() {return 9;}
	@property const int aptNormal() {return 3;}

	@property const CPoint useStoneXY() {return CPoint(60, 75);}
	@property const CPoint aptStoneXY() {return CPoint(60, 90);}

	@property const CPoint eventTreeXY() {return CPoint(7, 90);}
	@property const CPoint eventTreeXYWithCount() {return CPoint(7, 71);}

	@property const CPoint premiumXY() {return CPoint(5, 5);}
	@property const uint itemCardMaxNum(uint lev) { mixin(S_TRACE);
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	@property const uint skillCardMaxNum(uint lev) { mixin(S_TRACE);
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	@property const uint beastCardMaxNum(uint lev) { mixin(S_TRACE);
		int r = (lev + 1) / 4 + 1;
		return r <= 10 ? r : 10;
	}
	@property const int cardDescLen() {return 39;}
	@property const int cardDescLine() {return 8;}

	@property const int messageImageLen() {return 34;}
	@property const int messageLen() {return 44;}
	@property const int messageLine() {return 7;}

	@property const int stepMaxCount() {return 10;}

	@property const uint castNameLimit() {return 14;}
	@property const uint nameLimit() {return 12;}
	const uint lifeCalc(uint lev, uint vit, uint spi) { mixin(S_TRACE);
		return cast(uint) (((lev + 1.0) * (vit / 2.0 + 4.0)) + (spi / 2.0));
	}
	@property const uint physicalCutMin() {return 1;}
	@property const uint physicalCutMaxBase() {return 6;}
	@property const uint physicalNormal() {return 6;}
	@property const uint[] physicalBorders() {return [1, 6, 12];}
	@property const uint mentalCut() {return 3;}
	@property const uint[] mentalBorders() {return [3];}

	const int skillPrice(int lev) {return (lev + 2) * 200;}
	@property const int beastPrice() {return 500;}
	@property const int keyCodesMaxLegacy() {return 5;}
	@property const uint motionRoundDefault() {return 10;}
	@property const uint stoneBorder() {return 20;}

	@property const uint idMax() {return 99999;}

	@property const CSize viewSize() {return CSize(632, 420);}
	@property const uint partyTop() {return 280;}

	@property const string monospace() { mixin(S_TRACE);
		version (Windows) {
			return "ＭＳ ゴシック";
		}
		return "IPAゴシック";
	}

	private static string gothic(bool legacy) { mixin(S_TRACE);
		version (Windows) {
			if (legacy) return "ＭＳ ゴシック";
		}
		return "IPAゴシック";
	}
	private static string pgothic(bool legacy) { mixin(S_TRACE);
		version (Windows) {
			if (legacy) return "ＭＳ Ｐゴシック";
		}
		return "IPA Pゴシック";
	}
	private static string mincho(bool legacy) { mixin(S_TRACE);
		version (Windows) {
			if (legacy) return "ＭＳ 明朝";
		}
		return "IPA明朝";
	}
	private static string uigothic(bool legacy) { mixin(S_TRACE);
		version (Windows) {
			if (legacy) return "MS UI Gothic";
		}
		return "IPA UIゴシック";
	}
	const CFont textDlgFont(uint defSize) { mixin(S_TRACE);
		return CFont(gothic(true), defSize <= 0 ? 12 : defSize, false, false);
	}
	const CFont castCardNameFont(bool legacy) {return CFont(uigothic(legacy), 9, true, false);}
	const CFont castCardLevelFont(bool legacy) {return CFont(mincho(legacy), 24, true, true);}
	const CFont pcNumberFont(bool legacy) {return CFont(mincho(legacy), 42, true, false);}
	@property const CInsets castCardLevelInsets() {return CInsets(2, 8, 0, 0);}
	@property const CRGB castCardLevelColor() {return CRGB(0, 0, 0, 128);}
	@property const CPoint castLifeBarPoint() {return CPoint(8, 110);}
	@property const int statusX() {return 7;}
	@property const uint statusVerMax() {return 6;}
	@property const CFont beastNumFont(bool legacy) {return CFont(pgothic(legacy), 9, false, false);}

	const CFont skillCardLevelFont(bool legacy) {return CFont(mincho(legacy), 20, true, true);}
	@property const CRGB skillCardLevelColor() {return CRGB(0, 0, 0, 128);}
	@property const CInsets skillCardLevelInsets() {return CInsets(2, 8, 0, 0);}

	const CFont menuCardNameFont(bool legacy) {return castCardNameFont(legacy);}
	const CFont cardNameFont(bool legacy) {return castCardNameFont(legacy);}
	const CFont useCountFont(bool legacy) {return CFont(mincho(legacy), 12, true, false);}
	@property const CPoint useCountPoint() {return CPoint(10, 90);}
	@property const CRGB recycleNumColor() {return CRGB(255, 255, 0);}
	const CFont summaryLevelFont(bool legacy) {return CFont(mincho(legacy), 10, true, true);}
	const CFont summaryTitleFont(bool legacy) {return CFont(mincho(legacy), 16, true, false);}
	const CFont summaryDescFont(bool legacy) { mixin(S_TRACE);
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 10, true, false);
		}
		return CFont(gothic(legacy), 10, true, false);
	}
	@property const uint summaryDescLineHeightClassic() { mixin(S_TRACE);
		return 15;
	}
	const CFont summaryPageFont(bool legacy) {return CFont(gothic(legacy), 9, true, false);}
	const CFont cardDescFont(bool legacy) {return CFont(gothic(legacy), 10, false, false);}
	const CFont messageFont(bool legacy) { mixin(S_TRACE);
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 15, true, false);
		}
		return CFont(mincho(legacy), 15, true, false);
	}
	const CFont messageSelectFont(bool legacy) { mixin(S_TRACE);
		version (Windows) {
			if (legacy) return CFont(pgothic(legacy), 11, true, false);
		}
		return CFont(pgothic(legacy), 14, false, false);
	}
	const CFont scriptErrorFont(uint defSize) { mixin(S_TRACE);
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
	this (string appPath, cwx.system.System sys) { mixin(S_TRACE);
		string dStr = .text(__LINE__);
		try { mixin(S_TRACE);
			dStr ~= " - " ~ .text(__LINE__);
			_appPath = appPath;
			_sys = sys;
			dStr ~= " - " ~ .text(__LINE__);
			_msgs = new Msgs;
			dStr ~= " - " ~ .text(__LINE__);
			_looks = new Looks;
			dStr ~= " - " ~ .text(__LINE__);
		} catch (Throwable e) {
			printStackTrace();
			fdebugln(dStr);
			fdebugln(e);
			throw new Exception(dStr, __FILE__, __LINE__);
		}
	}
	/// アプリケーションの実行ファイルのパス。
	@property const string appPath() {return _appPath;}
	/// CardWirthのシステム情報。
	@property const const(cwx.system.System) sys() {return _sys;}
	/// 各種メッセージ情報。
	@property const const(Msgs) msgs() {return _msgs;}
	/// ditto
	@property void msgs(Msgs msgs) {_msgs = msgs;}
	/// 各種外観情報。
	@property const const(Looks) looks() {return _looks;}

	/// pathをアプリケーションの実行ファイルからの相対パスと見做してフルパスに変換する。
	const string toAppAbs(string path) { mixin(S_TRACE);
		if (.isAbsolute(path)) return nabs(path);
		return nabs(std.path.buildPath(_appPath.dirName(), path));
	}

	/// 言語ファイルを読み込む。
	void loadMsgs(string relPath) { mixin(S_TRACE);
		auto path = toAppAbs(relPath);
		try { mixin(S_TRACE);
			_msgs = Msgs.fromXML(std.file.readText(path), 0);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}

	/// 言語ファイルの一覧を得る。
	const
	Msgs[string] msgsTable(string languageDir, ref string[string] msgsTableFile, out string defLocale) { mixin(S_TRACE);
		Msgs[string] msgsTable;
		auto def = new Msgs;
		string loc = def.locale;
		defLocale = .toLower(loc);
		msgsTableFile[defLocale] = "";
		try { mixin(S_TRACE);
			auto dir = toAppAbs(languageDir);
			if (.exists(dir)) { mixin(S_TRACE);
				foreach (file; clistdir(dir)) { mixin(S_TRACE);
					if (!cfnmatch(extension(file), ".xml")) continue;
					try { mixin(S_TRACE);
						auto msgs = Msgs.fromXML(std.file.readText(dir.buildPath(file)), 0);
						loc = msgs.locale;
						auto msgsLocale = .toLower(loc);
						if (defLocale == msgsLocale) { mixin(S_TRACE);
							def = msgs;
						} else { mixin(S_TRACE);
							msgsTable[msgsLocale] = msgs;
						}
						msgsTableFile[msgsLocale] = file;
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
				}
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		msgsTable[defLocale] = def;
		return msgsTable;
	}

	/// verがターゲットとなる環境のバージョン
	/// targVer以下であればtrueを返す。
	const
	bool targetVersion(string ver, string targVer) { mixin(S_TRACE);
		immutable VER_TABLE = [
			"1.20": 0,
			"1.28": 1,
			"1.29": 2,
			"1.30": 3,
			"1.50": 4,
			"1.60": 5,
		];
		return VER_TABLE.get(ver, int.min) <= VER_TABLE.get(targVer, int.max);
	}
	/// summが存在する場合はwsnVer以上かを返す。
	/// それ以外の場合は対象バージョンがCardWirthPyか否かを返す。
	const
	bool isTargetVersion(in Summary summ, string targVer, string wsnVer) { mixin(S_TRACE);
		return summ ? summ.isTargetVersion(wsnVer) : targVer == "CardWirthPy";
	}
}
