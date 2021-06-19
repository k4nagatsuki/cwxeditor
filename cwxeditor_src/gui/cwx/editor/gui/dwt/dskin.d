
module cwx.editor.gui.dwt.dskin;

import cwx.utils;
import cwx.skin;
import cwx.types;
import cwx.structs;
import cwx.summary;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dutils;

import std.algorithm : countUntil;
import std.string;
import std.utf;
import std.ascii;
import std.file;
import std.path;
import std.conv;

import org.eclipse.swt.all;

Skin createClassicSkin(in Props prop, in ClassicEngine ce) { mixin(S_TRACE);
	auto skin = Skin.createLegacySkin(prop.parent, prop.enginePath, ce.enginePath, ce.dataDirName, ce.execute, [ce], prop.var.etc.defaultSkin);
	skin.initialize();
	return skin;
}

bool findCWPy(Props prop, string sPath) { mixin(S_TRACE);
	if (prop.var.etc.findEnginePath && !prop.var.etc.enginePath.length) { mixin(S_TRACE);
		auto p = Skin.findCardWirthPy(sPath, prop.var.etc.engine, prop.var.etc.dataDir);
		if (p.length) { mixin(S_TRACE);
			prop.var.etc.enginePath = p;
			prop.var.etc.findEnginePath = false;
			return true;
		}
		p = Skin.findCardWirthPy(sPath, prop.var.etc.engineScript, prop.var.etc.dataDir);
		if (p.length) { mixin(S_TRACE);
			prop.var.etc.enginePath = p;
			prop.var.etc.findEnginePath = false;
			return true;
		}
	}
	return false;
}

Skin findSkin2(const(Props) prop, string type, string name) { mixin(S_TRACE);
	Skin typeSkin = null;
	if (type == "") type = prop.var.etc.defaultSkin;
	foreach (path, skin; skinTable(prop)) { mixin(S_TRACE);
		if (skin.type == type) { mixin(S_TRACE);
			if (!typeSkin) typeSkin = skin;
			if (!name || name == skin.name) { mixin(S_TRACE);
				skin.initialize();
				return skin;
			}
		}
	}
	if (typeSkin) { mixin(S_TRACE);
		typeSkin.initialize();
		return typeSkin;
	}

	static Skin[string] emptySkins;
	auto p = prop.enginePath in emptySkins;
	if (p) return *p;
	auto r = new Skin(prop.parent, prop.enginePath);
	r.initialize();
	emptySkins[prop.enginePath] = r;
	return r;
}
bool hasSkin(in Props prop, string type) { mixin(S_TRACE);
	foreach (path, skin; skinTable(prop)) { mixin(S_TRACE);
		if (skin.type == type) return true;
	}
	return false;
}
Skin[string] skinTable(const(Props) prop) { mixin(S_TRACE);
	return Skin.table(prop.parent, prop.enginePath);
}

string[] findSkinTypes(const(Props) prop) { mixin(S_TRACE);
	bool[string] types;
	types[prop.var.etc.defaultSkin] = true;
	foreach (key, value; .skinTable(prop)) { mixin(S_TRACE);
		if (value.type != "") types[value.type] = true;
	}
	foreach (ref ce; prop.var.etc.classicEngines) { mixin(S_TRACE);
		if (ce.type != "") types[ce.type] = true;
	}
	foreach (ref s; prop.var.etc.settingsWithSkinTypes) { mixin(S_TRACE);
		if (s.type != "") types[s.type] = true;
	}
	foreach (ref stc; prop.var.etc.skinTypesByClassicEngines) { mixin(S_TRACE);
		if (stc.type != "") types[stc.type] = true;
	}
	auto arr = types.keys();
	if (prop.var.etc.logicalSort) { mixin(S_TRACE);
		.sort!ncmp(arr);
	} else { mixin(S_TRACE);
		.sort!cmp(arr);
	}
	return arr;
}

private static ImageDataWithScale imgd(string path, uint targetScale, MaskType maskType) { mixin(S_TRACE);
	mixin FileCache!(ImageDataWithScale);
	auto key = path.findScaledImage(targetScale).path;
	auto ca = cache(key);
	if (ca) { mixin(S_TRACE);
		return ca.value;
	} else { mixin(S_TRACE);
		auto data = .loadImageWithScale(path, targetScale, maskType is MaskType.NormalMask);
		if (data.valid) { mixin(S_TRACE);
			if (maskType is MaskType.Mask1_1) { mixin(S_TRACE);
				data.baseData.transparentPixel = data.baseData.getPixel(1, 1);
			} else if (maskType is MaskType.RightMask) { mixin(S_TRACE);
				data.baseData.transparentPixel = data.baseData.getPixel(data.baseData.width - 1, 0);
			}
		}
		putCache(key, data, data.bufferSize);
		return data;
	}
}

version (Windows) {
	import core.sys.windows.windows;
	private extern (Windows) {
		HINSTANCE LoadLibraryExW(LPCWSTR, HANDLE, DWORD);
		immutable DWORD LOAD_LIBRARY_AS_DATAFILE = 0x2;
		immutable DWORD LOAD_WITH_ALTERED_SEARCH_PATH = 0x8;
		HBITMAP LoadBitmapW(HINSTANCE, LPCWSTR);
		const DWORD LR_DEFAULTSIZE = 0x0040;
		LPWSTR MAKEINTRESOURCEW(WORD w) { return cast(LPWSTR) w; }
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

	ImageData loadIcon(string exe, int w, int h, void delegate(void delegate()) syncExec = null) { mixin(S_TRACE);
		static import org.eclipse.swt.internal.win32.OS;
		static import org.eclipse.swt.internal.win32.WINAPI;
		static import org.eclipse.swt.internal.win32.WINTYPES;
		alias org.eclipse.swt.internal.win32.OS.OS OS;
		alias org.eclipse.swt.internal.win32.WINAPI WINAPI;
		alias org.eclipse.swt.internal.win32.WINTYPES WINTYPES;
		mixin FileCache!(ImageData);
		auto ca = cache(exe);
		if (ca) { mixin(S_TRACE);
			return ca.value;
		} else { mixin(S_TRACE);
			if (!isAbsolute(exe)) { mixin(S_TRACE);
				auto path = new wchar[MAX_PATH];
				DWORD cchOut = cast(DWORD)path.length;
				auto r = WINAPI.AssocQueryStringW(ASSOCSTR_EXECUTABLE, OS.ASSOCSTR_COMMAND, toUTFz!(wchar*)(exe), null, path.ptr, &cchOut);
				if (FAILED(r) || 0 == cchOut) return null;
				PathRemoveArgsW(path.ptr);
				PathUnquoteSpacesW(path.ptr);
				exe = std.conv.to!string(path[0 .. .countUntil(path, '\0')]);
			}
			if (!.exists(exe)) return null;
			SHFILEINFO info;
			SHGetFileInfoW(toUTFz!(wchar*)(exe), 0, &info, info.sizeof, SHGFI_ICON | SHGFI_SMALLICON);
			HICON hbmp = info.hIcon;
			if (!hbmp) return null;
			scope (exit) DeleteObject(hbmp);
			ImageData data = null;
			void put() { mixin(S_TRACE);
				auto display = Display.getCurrent();
				if (!display || display.isDisposed()) return;
				auto img = Image.win32_new(display, SWT.ICON, hbmp);
				data = img.getImageData();
				img.destroy();
			}
			if (syncExec) { mixin(S_TRACE);
				syncExec(&put);
			} else { mixin(S_TRACE);
				put();
			}
			putCache(exe, data, data.data.length + data.maskData.length + data.alphaData.length);
			return data;
		}
	}
	private static ImageDataWithScale imgr(string legacyEngine, string resName, uint targetScale, MaskType maskType) { mixin(S_TRACE);
		mixin FileCache!(ImageDataWithScale);
		void setMask(ImageDataWithScale data) { mixin(S_TRACE);
			if (data.baseData.depth == 32 && data.baseData.alphaData) return;
			final switch (maskType) {
			case MaskType.NoMask:
				break;
			case MaskType.NormalMask:
				data.baseData.transparentPixel = data.baseData.getPixel(0, 0);
				break;
			case MaskType.RightMask:
				data.baseData.transparentPixel = data.baseData.getPixel(data.baseData.width - 1, 0);
				break;
			case MaskType.Mask1_1:
				if (1 < data.baseData.width && 1 < data.baseData.height) { mixin(S_TRACE);
					data.baseData.transparentPixel = data.baseData.getPixel(1, 1);
				}
				break;
			}
		}

		/// リソースオーバーライドに対応
		string oPath = legacyEngine.dirName().buildPath("Data").buildPath("Resource").buildPath(resName.setExtension(".bmp"));
		if (.exists(oPath)) { mixin(S_TRACE);
			auto key = oPath.findScaledImage(targetScale).path;
			auto ca = cache(key);
			if (ca) { mixin(S_TRACE);
				return ca.value;
			} else { mixin(S_TRACE);
				auto data = .loadImageWithScale(oPath, targetScale, false);
				setMask(data);
				putCache(key, data, data.bufferSize);
				return data;
			}
		}

		string path = std.path.buildPath(legacyEngine, resName);
		auto ca = cache(path);
		if (ca) { mixin(S_TRACE);
			return ca.value;
		} else { mixin(S_TRACE);
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
			auto sData = new ImageDataWithScale(data, 1);
			setMask(sData);
			putCache(path, sData, sData.bufferSize);
			return sData;
		}
	}
}

/// 背景画像として使用可能であればイメージデータを生成して返す。
/// Params:
/// path = ファイルパス。
/// Returns: 背景画像。背景画像でないならnull。
ImageDataWithScale loadBgImage(Props prop, in Skin skin, in Summary summ, string path, uint targetScale) { mixin(S_TRACE);
 	return skin.isBgImage(path) ? .loadImageWithScale(prop, skin, summ, path, targetScale, false, true) : null;
}

private ImageDataWithScale createImg(T ...)(string lEnginePath, string resName, uint targetScale,
		string delegate(out MaskType, T) res, T t) { mixin(S_TRACE);
	MaskType maskType;
	auto path = res(maskType, t);
	version (Windows) {
		if (lEnginePath.length && resName.length) { mixin(S_TRACE);
			auto img = imgr(lEnginePath, resName, targetScale, maskType);
			if (img) return img;
		}
	}
	return imgd(path, targetScale, maskType);
}

ImageDataWithScale summary(Skin skin, uint targetScale) { return createImg("", "", targetScale, &skin.resSummary); }

ImageDataWithScale menuCard(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_NORMAL", targetScale, &skin.resMenuCard); }
ImageDataWithScale castCard(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_LARGE", targetScale, &skin.resCastCard); }
ImageDataWithScale castCardInjury(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_INJURY", targetScale, &skin.resCastCardInjury); }
ImageDataWithScale castCardDanger(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_DANGER", targetScale, &skin.resCastCardDanger); }
ImageDataWithScale castCardFaint(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_FAINT", targetScale, &skin.resCastCardFaint); }
ImageDataWithScale castCardBind(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_BIND", targetScale, &skin.resCastCardBind); }
ImageDataWithScale castCardParaly(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_PARALY", targetScale, &skin.resCastCardParaly); }
ImageDataWithScale castCardPetrif(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_PETRIF", targetScale, &skin.resCastCardPetrif); }
ImageDataWithScale castCardSleep(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_SLEEP", targetScale, &skin.resCastCardSleep); }
ImageDataWithScale lifeBar(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_LIFEBAR", targetScale, &skin.resLifeBar); }
ImageDataWithScale lifeGuage(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_LIFEGUAGE", targetScale, &skin.resLifeGuage); }
ImageDataWithScale lifeGuage2(Skin skin, uint targetScale) { return createImg("", "", targetScale, &skin.resLifeGuage2); }
ImageDataWithScale lifeGuage2Mask(Skin skin, uint targetScale) { return createImg("", "", targetScale, &skin.resLifeGuage2Mask); }
ImageDataWithScale enhanceUp(Skin skin, uint targetScale, Enhance enh) { mixin(S_TRACE);
	string res;
	switch (enh) {
	case Enhance.Action: res = "STATUS_UP0"; break;
	case Enhance.Avoid: res = "STATUS_UP1"; break;
	case Enhance.Resist: res = "STATUS_UP2"; break;
	case Enhance.Defense: res = "STATUS_UP3"; break;
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, targetScale, &skin.resEnhanceUp, enh);
}
ImageDataWithScale enhanceDown(Skin skin, uint targetScale, Enhance enh) { mixin(S_TRACE);
	string res;
	switch (enh) {
	case Enhance.Action: res = "STATUS_DOWN0"; break;
	case Enhance.Avoid: res = "STATUS_DOWN1"; break;
	case Enhance.Resist: res = "STATUS_DOWN2"; break;
	case Enhance.Defense: res = "STATUS_DOWN3"; break;
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, targetScale, &skin.resEnhanceDown, enh);
}
ImageDataWithScale mentality(Skin skin, uint targetScale, Mentality mtly) { mixin(S_TRACE);
	string res;
	switch (mtly) {
	case Mentality.Normal: res = "STATUS_MIND0"; break;
	case Mentality.Sleep: res = "STATUS_MIND1"; break;
	case Mentality.Confuse: res = "STATUS_MIND2"; break;
	case Mentality.Overheat: res = "STATUS_MIND3"; break;
	case Mentality.Brave: res = "STATUS_MIND4"; break;
	case Mentality.Panic: res = "STATUS_MIND5"; break;
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, targetScale, &skin.resMentality, mtly);
}
ImageDataWithScale bind(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_MAGIC0", targetScale, &skin.resBind); }
ImageDataWithScale silence(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_MAGIC1", targetScale, &skin.resSilence); }
ImageDataWithScale faceUp(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_MAGIC2", targetScale, &skin.resFaceUp); }
ImageDataWithScale antiMagic(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_MAGIC3", targetScale, &skin.resAntiMagic); }
ImageDataWithScale paralyze(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_BODY1", targetScale, &skin.resParalyze); }
ImageDataWithScale poison(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_BODY0", targetScale, &skin.resPoison); }
ImageDataWithScale summon(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STATUS_SUMMON", targetScale, &skin.resSummon); }

ImageDataWithScale itemCard(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_ITEM", targetScale, &skin.resItemCard); }
ImageDataWithScale skillCard(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_SKILL", targetScale, &skin.resSkillCard); }
ImageDataWithScale beastCard(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_BEAST", targetScale, &skin.resBeastCard); }
ImageDataWithScale optionCard(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_OPTION", targetScale, &skin.resOptionCard); }
ImageDataWithScale infoCard(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "CARD_INFO", targetScale, &skin.resInfoCard); }
ImageDataWithScale cardHold(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "SIGN_HOLD", targetScale, &skin.resCardHold); }
ImageDataWithScale cardPenalty(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "SIGN_PENALTY", targetScale, &skin.resCardPenalty); }

ImageDataWithScale rare(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "SIGN_RARE", targetScale, &skin.resRare); }
ImageDataWithScale premier(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "SIGN_PREMIER", targetScale, &skin.resPremier); }

ImageDataWithScale aptVeryHigh(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND3", targetScale, &skin.resAptVeryHigh); }
ImageDataWithScale aptHigh(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND2", targetScale, &skin.resAptHigh); }
ImageDataWithScale aptNormal(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND1", targetScale, &skin.resAptNormal); }
ImageDataWithScale aptLow(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND0", targetScale, &skin.resAptLow); }

ImageDataWithScale use0(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND5", targetScale, &skin.resUse0); }
ImageDataWithScale use1(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND6", targetScale, &skin.resUse1); }
ImageDataWithScale use2(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND7", targetScale, &skin.resUse2); }
ImageDataWithScale use3(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND8", targetScale, &skin.resUse3); }
ImageDataWithScale use4(Skin skin, uint targetScale) { return createImg(skin.legacyEngine, "STONE_HAND9", targetScale, &skin.resUse4); }

private ImageDataWithScale createImg(T ...)(string delegate(out MaskType, T) res, T t) { mixin(S_TRACE);
	MaskType maskType;
	auto path = res(maskType, t);
	return imgd(path, maskType);
}

/// 特殊文字の画像。
ImageDataWithScale spChar(Skin skin, uint targetScale, dchar c) { mixin(S_TRACE);
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
	return .createImg(skin.legacyEngine, res, targetScale, delegate string (out MaskType maskType) { mixin(S_TRACE);
		auto p = c in skin.spChars;
		if (p) { mixin(S_TRACE);
			maskType = MaskType.NormalMask;
			return *p;
		} else { mixin(S_TRACE);
			maskType = MaskType.NoMask;
			return null;
		}
	});
}
