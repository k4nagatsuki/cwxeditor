
module cwx.editor.gui.dwt.skin;

import cwx.cwl;
import cwx.race;
import cwx.utils;
import cwx.skin;
import cwx.summary;
import cwx.imagesize;
import cwx.types;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;

import std.string;
import std.utf;
import std.ctype;
import std.file;

import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Image;

Skin findSkin(S = Summary)(in Props prop, in S summ) {
	static if (is(typeof(summ.type))) {
		if (!summ) {
			return findSkin2(prop, prop.var.etc.defaultSkin);
		}
		if (summ.legacy && !summ.type.length) {
			return Skin.find2!(S)(prop.parent, prop.var.etc.enginePath, summ);
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
	p = prop.var.etc.enginePath in emptySkins;
	if (p) return *p;
	auto r = new Skin(prop.parent, prop.var.etc.enginePath);
	emptySkins[prop.var.etc.enginePath] = r;
	return r;
}
bool hasSkin(in Props prop, string type) {
	return (type in skinTable(prop)) !is null;
}
Skin[string] skinTable(const(Props) prop) {
	return Skin.table(prop.parent, prop.var.etc.enginePath);
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
	}
	private static ImageData imgr(string legacyEngine, string resName, bool mask, bool rmask) {
		mixin FileCache!(ImageData);
		string path = std.path.join(legacyEngine, resName);
		auto ca = cache(path);
		if (ca) {
			return ca.value;
		} else {
			if (!.exists(legacyEngine)) return null;
			// TODO lEnginePathからリソース読込み
			HINSTANCE handle;
			handle = LoadLibraryExW(toUTF16z(legacyEngine), null, LOAD_LIBRARY_AS_DATAFILE | LOAD_WITH_ALTERED_SEARCH_PATH);
			if (!handle) return null;
			scope (exit) FreeLibrary(handle);
			HBITMAP hbmp;
			hbmp = LoadBitmapW(handle, toUTF16z(resName));
			if (!hbmp) return null;
			scope (exit) DeleteObject(hbmp);
			auto img = Image.win32_new(Display.getCurrent, SWT.BITMAP, hbmp);
			auto data = img.getImageData;
			img.destroy;
			if (mask) {
				data.transparentPixel = data.getPixel(0, 0);
			}
			if (rmask) {
				data.transparentPixel = data.getPixel(data.width - 1, 0);
			}
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
	case Enhance.ACTION: res = "STATUS_UP0";
	case Enhance.AVOID: res = "STATUS_UP1";
	case Enhance.RESIST: res = "STATUS_UP2";
	case Enhance.DEFENSE: res = "STATUS_UP3";
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, &skin.resEnhanceUp, enh);
}
ImageData enhanceDown(Skin skin, Enhance enh) {
	string res;
	switch (enh) {
	case Enhance.ACTION: res = "STATUS_DOWN0";
	case Enhance.AVOID: res = "STATUS_DOWN1";
	case Enhance.RESIST: res = "STATUS_DOWN2";
	case Enhance.DEFENSE: res = "STATUS_DOWN3";
	default: assert (0);
	}
	return createImg(skin.legacyEngine, res, &skin.resEnhanceDown, enh);
}
ImageData mentality(Skin skin, Mentality mtly) {
	string res;
	switch (mtly) {
	case Mentality.NORMAL: res = "STATUS_MIND0";
	case Mentality.SLEEP: res = "STATUS_MIND1";
	case Mentality.CONFUSE: res = "STATUS_MIND2";
	case Mentality.OVERHEAT: res = "STATUS_MIND3";
	case Mentality.BRAVE: res = "STATUS_MIND4";
	case Mentality.PANIC: res = "STATUS_MIND5";
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
	case 'C', 'c': res = "FONT_CLUB"; break;
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
	return createImg(skin.legacyEngine, res, (out bool mask, out bool rMask) {
		mask = true;
		rMask = false;
		return skin.spChars[c];
	});
}
