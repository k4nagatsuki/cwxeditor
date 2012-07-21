
module cwx.editor.gui.dwt.dskin;

import cwx.cwl;
import cwx.race;
import cwx.utils;
import cwx.skin;
import cwx.summary;
import cwx.imagesize;
import cwx.types;
import cwx.structs;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dutils;

import std.string;
import std.utf;
import std.ascii;
import std.file;
import std.path;

import org.eclipse.swt.all;

Skin createClassicSkin(in Props prop, in ClassicEngine ce) {
	return Skin.createLegacySkin(prop.parent, prop.enginePath, ce.enginePath, ce.dataDirName, ce.execute, [ce]);
}

bool findCWPy(Props prop, string sPath) {
	if (prop.var.etc.findEnginePath && !prop.var.etc.enginePath.length) {
		auto p = Skin.findCardWirthPy(sPath, prop.var.etc.engine, prop.var.etc.dataDir);
		if (p.length) {
			prop.var.etc.enginePath = p;
			prop.var.etc.findEnginePath = false;
			return true;
		}
	}
	return false;
}

Skin findSkin(S = Summary)(Commons comm, Props prop, in S summ, bool appendClassicSkin = true) {
	if (summ && !summ.legacy) {
		findCWPy(prop, summ.useTemp ? summ.zipName : summ.scenarioPath);
	}
	static if (is(typeof(summ.type))) {
		if (!summ) {
			return findSkin2(prop, prop.var.etc.defaultSkin);
		}
		if (summ.legacy && !summ.type.length) {
			auto skin = Skin.find2!(S)(prop.parent, prop.enginePath, summ, prop.var.etc.classicEngineRegex, prop.var.etc.classicDataDirRegex, prop.var.etc.classicMatchKey, prop.var.etc.classicEngines);
			void find() {
				if (!appendClassicSkin) return;
				if (!prop.var.etc.addNewClassicEngine) return;
				if (!skin.legacyEngine.length) return;
				auto lEngine = nabs(skin.legacyEngine);
				foreach (ce; prop.var.etc.classicEngines) {
					if (cfnmatch(nabs(ce.enginePath), lEngine)) {
						skin = createClassicSkin(prop, ce);
						return;
					}
				}
				string dataDirName = abs2rel(lEngine.dirName(), skin.legacyDataPath);
				auto ce = ClassicEngine(lEngine.baseName().stripExtension(), lEngine, dataDirName, "");
				ClassicEngine[] arr;
				foreach (e; prop.var.etc.classicEngines) {
					arr ~= e.dup;
				}
				prop.var.etc.classicEngines = arr ~ ce;
				comm.refClassicSkin.call();
			}
			if (skin.legacyEngine.length) {
				find();
			} else {
				if (prop.var.etc.classicEngines.length) {
					auto ce = prop.var.etc.classicEngines[0];
					skin = createClassicSkin(prop, ce);
				}
			}
			return skin;
		}
		return findSkin2(prop, summ.type);
	} else {
		return findSkin2(prop, prop.var.etc.defaultSkin);
	}
}
Skin findSkin2(const(Props) prop, string type) {
	auto p = type in skinTable(prop);
	if (p) return *p;
	static Skin[string] emptySkins;
	p = prop.enginePath in emptySkins;
	if (p) return *p;
	auto r = new Skin(prop.parent, prop.enginePath);
	emptySkins[prop.enginePath] = r;
	return r;
}
bool hasSkin(in Props prop, string type) {
	return (type in skinTable(prop)) !is null;
}
Skin[string] skinTable(const(Props) prop) {
	return Skin.table(prop.parent, prop.enginePath);
}

private static ImageData imgd(string path, bool mask, bool rmask) {
	mixin FileCache!(ImageData);
	auto ca = cache(path);
	if (ca) {
		return ca.value;
	} else {
		auto data = loadImage(path, mask);
		if (rmask) data.transparentPixel = data.getPixel(data.width - 1, 0);
		putCache(path, data);
		return data;
	}
}

version (Windows) {
	import std.c.windows.windows;
	private extern (Windows) {
		HINSTANCE LoadLibraryExW(LPCWSTR, HANDLE, DWORD);
		const DWORD LOAD_LIBRARY_AS_DATAFILE = 0x2;
		const DWORD LOAD_WITH_ALTERED_SEARCH_PATH = 0x8;
		HBITMAP LoadBitmapW(HINSTANCE, LPCWSTR);
		const DWORD LR_DEFAULTSIZE = 0x0040;
		LPWSTR MAKEINTRESOURCEW(WORD w) {return cast(LPWSTR) w;}
		struct SHFILEINFO {
			HICON hIcon = null;
			INT iIcon;
			DWORD dwAttributes;
			WCHAR[MAX_PATH] szDisplayName;
			WCHAR[80] szTypeName;
		}
		DWORD* SHGetFileInfoW(in LPCWSTR pszPath, DWORD dwFileAttributes, SHFILEINFO *psfi, UINT cbFileInfo, UINT uFlags);
		const DWORD SHGFI_ICON = 0x0100;
		const DWORD SHGFI_LARGEICON = 0x0000;
		const DWORD SHGFI_SMALLICON = 0x0001;
		const DWORD ASSOCSTR_EXECUTABLE = 2;
		void PathRemoveArgsW(LPWSTR);
		void PathUnquoteSpacesW(LPWSTR);
	}

	ImageData loadIcon(string exe, int w, int h) {
		alias org.eclipse.swt.internal.win32.OS.OS OS;
		alias org.eclipse.swt.internal.win32.WINAPI WINAPI;
		alias org.eclipse.swt.internal.win32.WINTYPES WINTYPES;
		mixin FileCache!(ImageData);
		auto ca = cache(exe);
		if (ca) {
			return ca.value;
		} else {
			if (!cwx.utils.isabs(exe)) {
				auto path = new wchar[MAX_PATH];
				DWORD cchOut = path.length;
				auto r = WINAPI.AssocQueryStringW(ASSOCSTR_EXECUTABLE, OS.ASSOCSTR_COMMAND, toUTFz!(wchar*)(exe), null, path.ptr, &cchOut);
				if (FAILED(r) || 0 == cchOut) return null;
				PathRemoveArgsW(path.ptr);
				PathUnquoteSpacesW(path.ptr);
				exe = std.conv.to!string(path[0 .. std.algorithm.countUntil(path, '\0')]);
			}
			if (!.exists(exe)) return null;
			SHFILEINFO info;
			SHGetFileInfoW(toUTFz!(wchar*)(exe), 0, &info, info.sizeof, SHGFI_ICON | SHGFI_SMALLICON);
			HICON hbmp = info.hIcon;
			if (!hbmp) return null;
			scope (exit) DeleteObject(hbmp);
			auto img = Image.win32_new(Display.getCurrent(), SWT.ICON, hbmp);
			auto data = img.getImageData();
			img.destroy();
			putCache(exe, data);
			return data;
		}
	}
	private static ImageData imgr(string legacyEngine, string resName, bool mask, bool rmask) {
		mixin FileCache!(ImageData);
		void setMask(ImageData data) {
			if (mask) {
				data.transparentPixel = data.getPixel(0, 0);
			}
			if (rmask) {
				data.transparentPixel = data.getPixel(data.width - 1, 0);
			}
		}

		/// リソースオーバーライド変更に対応
		string oPath = legacyEngine.dirName().buildPath("Data").buildPath("Resource").buildPath(resName.setExtension("bmp"));
		if (.exists(oPath)) {
			auto ca = cache(oPath);
			if (ca) {
				return ca.value;
			} else {
				auto data = loadImage(oPath, false);
				setMask(data);
				putCache(oPath, data);
				return data;
			}
		}

		string path = std.path.buildPath(legacyEngine, resName);
		auto ca = cache(path);
		if (ca) {
			return ca.value;
		} else {
			if (!.exists(legacyEngine)) return null;
			// lEnginePathからリソース読込み
			HINSTANCE handle;
			handle = LoadLibraryExW(toUTFz!(wchar*)(legacyEngine), null, LOAD_LIBRARY_AS_DATAFILE | LOAD_WITH_ALTERED_SEARCH_PATH);
			if (!handle) return null;
			scope (exit) FreeLibrary(handle);
			HBITMAP hbmp;
			hbmp = LoadBitmapW(handle, toUTFz!(wchar*)(resName));
			if (!hbmp) return null;
			scope (exit) DeleteObject(hbmp);
			auto img = Image.win32_new(Display.getCurrent(), SWT.BITMAP, hbmp);
			auto data = img.getImageData();
			img.destroy();
			setMask(data);
			putCache(path, data);
			return data;
		}
	}
}

/// カード画像として使用可能であればイメージデータを生成して返す。
/// Params:
/// prop = 設定データ。
/// path = ファイルパス。
/// Returns: カード画像。カード画像でないならnull。
ImageData loadCardImage(Skin skin, string path) {
	return skin.isCardImage(path) ? loadImage(skin, path) : null;
}
/// 背景画像として使用可能であればイメージデータを生成して返す。
/// Params:
/// path = ファイルパス。
/// Returns: 背景画像。背景画像でないならnull。
ImageData loadBgImage(Skin skin, string path) {
 	return skin.isBgImage(path) ? loadImage(skin, path) : null;
}

private ImageData createImg(T ...)(string lEnginePath, string resName,
		string delegate(out bool, out bool, T) res, T t) {
	bool mask, rMask;
	auto path = res(mask, rMask, t);
	version (Windows) {
		if (lEnginePath.length && resName.length) {
			auto img = imgr(lEnginePath, resName, mask, rMask);
			if (img) return img;
		}
	}
	return imgd(path, mask, rMask);
}

ImageData summary(Skin skin) {return createImg("", "", &skin.resSummary);}

ImageData menuCard(Skin skin) {return createImg(skin.legacyEngine, "CARD_NORMAL", &skin.resMenuCard);}
ImageData castCard(Skin skin) {return createImg(skin.legacyEngine, "CARD_LARGE", &skin.resCastCard);}
ImageData castCardInjury(Skin skin) {return createImg(skin.legacyEngine, "CARD_INJURY", &skin.resCastCardInjury);}
ImageData castCardDanger(Skin skin) {return createImg(skin.legacyEngine, "CARD_DANGER", &skin.resCastCardDanger);}
ImageData castCardFaint(Skin skin) {return createImg(skin.legacyEngine, "CARD_FAINT", &skin.resCastCardFaint);}
ImageData castCardBind(Skin skin) {return createImg(skin.legacyEngine, "CARD_BIND", &skin.resCastCardBind);}
ImageData castCardParaly(Skin skin) {return createImg(skin.legacyEngine, "CARD_PARALY", &skin.resCastCardParaly);}
ImageData castCardPetrif(Skin skin) {return createImg(skin.legacyEngine, "CARD_PETRIF", &skin.resCastCardPetrif);}
ImageData castCardSleep(Skin skin) {return createImg(skin.legacyEngine, "CARD_SLEEP", &skin.resCastCardSleep);}
ImageData lifeBar(Skin skin) {return createImg(skin.legacyEngine, "STATUS_LIFEBAR", &skin.resLifeBar);}
ImageData lifeGuage(Skin skin) {return createImg(skin.legacyEngine, "STATUS_LIFEGUAGE", &skin.resLifeGuage);}
ImageData enhanceUp(Skin skin, Enhance enh) {
	string res;
	switch (enh) {
	case Enhance.ACTION: res = "STATUS_UP0"; break;
	case Enhance.AVOID: res = "STATUS_UP1"; break;
	case Enhance.RESIST: res = "STATUS_UP2"; break;
	case Enhance.DEFENSE: res = "STATUS_UP3"; break;
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, &skin.resEnhanceUp, enh);
}
ImageData enhanceDown(Skin skin, Enhance enh) {
	string res;
	switch (enh) {
	case Enhance.ACTION: res = "STATUS_DOWN0"; break;
	case Enhance.AVOID: res = "STATUS_DOWN1"; break;
	case Enhance.RESIST: res = "STATUS_DOWN2"; break;
	case Enhance.DEFENSE: res = "STATUS_DOWN3"; break;
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, &skin.resEnhanceDown, enh);
}
ImageData mentality(Skin skin, Mentality mtly) {
	string res;
	switch (mtly) {
	case Mentality.NORMAL: res = "STATUS_MIND0"; break;
	case Mentality.SLEEP: res = "STATUS_MIND1"; break;
	case Mentality.CONFUSE: res = "STATUS_MIND2"; break;
	case Mentality.OVERHEAT: res = "STATUS_MIND3"; break;
	case Mentality.BRAVE: res = "STATUS_MIND4"; break;
	case Mentality.PANIC: res = "STATUS_MIND5"; break;
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, &skin.resMentality, mtly);
}
ImageData bind(Skin skin) {return createImg(skin.legacyEngine, "STATUS_MAGIC0", &skin.resBind);}
ImageData silence(Skin skin) {return createImg(skin.legacyEngine, "STATUS_MAGIC1", &skin.resSilence);}
ImageData faceUp(Skin skin) {return createImg(skin.legacyEngine, "STATUS_MAGIC2", &skin.resFaceUp);}
ImageData antiMagic(Skin skin) {return createImg(skin.legacyEngine, "STATUS_MAGIC3", &skin.resAntiMagic);}
ImageData paralyze(Skin skin) {return createImg(skin.legacyEngine, "STATUS_BODY1", &skin.resParalyze);}
ImageData poison(Skin skin) {return createImg(skin.legacyEngine, "STATUS_BODY0", &skin.resPoison);}
ImageData summon(Skin skin) {return createImg(skin.legacyEngine, "STATUS_SUMMON", &skin.resSummon);}

ImageData itemCard(Skin skin) {return createImg(skin.legacyEngine, "CARD_ITEM", &skin.resItemCard);}
ImageData skillCard(Skin skin) {return createImg(skin.legacyEngine, "CARD_SKILL", &skin.resSkillCard);}
ImageData beastCard(Skin skin) {return createImg(skin.legacyEngine, "CARD_BEAST", &skin.resBeastCard);}
ImageData infoCard(Skin skin) {return createImg(skin.legacyEngine, "CARD_INFO", &skin.resInfoCard);}
ImageData cardHold(Skin skin) {return createImg(skin.legacyEngine, "SIGN_HOLD", &skin.resCardHold);}
ImageData cardPenalty(Skin skin) {return createImg(skin.legacyEngine, "SIGN_PENALTY", &skin.resCardPenalty);}

ImageData rare(Skin skin) {return createImg(skin.legacyEngine, "SIGN_RARE", &skin.resRare);}
ImageData premier(Skin skin) {return createImg(skin.legacyEngine, "SIGN_PREMIER", &skin.resPremier);}

ImageData aptVeryHigh(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND3", &skin.resAptVeryHigh);}
ImageData aptHigh(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND2", &skin.resAptHigh);}
ImageData aptNormal(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND1", &skin.resAptNormal);}
ImageData aptLow(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND0", &skin.resAptLow);}

ImageData use0(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND5", &skin.resUse0);}
ImageData use1(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND6", &skin.resUse1);}
ImageData use2(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND7", &skin.resUse2);}
ImageData use3(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND8", &skin.resUse3);}
ImageData use4(Skin skin) {return createImg(skin.legacyEngine, "STONE_HAND9", &skin.resUse4);}

private ImageData createImg(T ...)(string delegate(out bool, out bool, T) res, T t) {
	bool mask, rMask;
	auto path = res(mask, rMask, t);
	return imgd(path, mask, rMask);
}

/// 特殊文字の画像。
ImageData spChar(Skin skin, dchar c) {
	string res;
	switch (c) {
	case 'A', 'a': res = "FONT_ANGRY"; break;
	case 'B', 'b': res = "FONT_CLUB"; break;
	case 'D', 'd': res = "FONT_DIAMOND"; break;
	case 'E', 'e': res = "FONT_EASY"; break;
	case 'F', 'f': res = "FONT_FLY"; break;
	case 'G', 'g': res = "FONT_GRIEVE"; break;
	case 'H', 'h': res = "FONT_HEART"; break;
	case 'J', 'j': res = "FONT_JACK"; break;
	case 'K', 'k': res = "FONT_KISS"; break;
	case 'L', 'l': res = "FONT_LAUGH"; break;
	case 'N', 'n': res = "FONT_NIKO"; break;
	case 'O', 'o': res = "FONT_ONSEN"; break;
	case 'P', 'p': res = "FONT_PUZZLE"; break;
	case 'Q', 'q': res = "FONT_QUICK"; break;
	case 'S', 's': res = "FONT_SPADE"; break;
	case 'W', 'w': res = "FONT_WORRY"; break;
	case 'X', 'x': res = "FONT_X"; break;
	case 'Z', 'z': res = "FONT_ZAP"; break;
	default: res = "";
	}
	return createImg(skin.legacyEngine, res, delegate string (out bool mask, out bool rMask) {
		auto p = c in skin.spChars;
		if (p) {
			mask = true;
			rMask = false;
			return *p;
		} else {
			return null;
		}
	});
}
