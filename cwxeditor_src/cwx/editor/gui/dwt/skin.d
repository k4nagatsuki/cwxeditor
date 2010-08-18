
module cwx.editor.gui.dwt.skin;

import cwx.cwl;
import cwx.race;
import cwx.utils;
import cwx.skin;
import cwx.imagesize;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;

import std.ctype;

import dwt.widgets.Display;
import dwt.graphics.ImageData;
import dwt.graphics.Image;

Skin findSkin(Summary)(Props prop, Summary summ, bool notFoundIsError = true) {
	if (summ.legacy) return Skin.find(prop.parent, prop.var.etc.enginePath, summ);
	return findSkin2(prop, summ.type, notFoundIsError);
}
Skin findSkin2(Props prop, string type, bool notFoundIsError = true) {
	auto p = type in skinTable(prop);
	if (p) return *p;
	if (notFoundIsError) throw new Exception("Skin is not found: " ~ type);
	return null;
}
Skin[string] skinTable(Props prop) {
	return Skin.table(prop.parent, prop.var.etc.enginePath);
}

private static ImageData imgd(string path, bool mask, bool rmask = false) {
	static REG_MAX = 1024u;
	static ImageData[string] imgDReg;
	static string[] regFiles;
	auto p = path in imgDReg;
	if (p) {
		return *p;
	} else {
		auto data = loadImage(path, mask);
		if (rmask) data.transparentPixel = data.getPixel(data.width - 1, 0);
		if (regFiles.length >= REG_MAX) {
			imgDReg.remove(regFiles[0u]);
			regFiles = regFiles[1u .. $];
		}
		imgDReg[path] = data;
		regFiles ~= path;
		return data;
	}
}

/// カード画像として使用可能であればイメージデータを生成して返す。
/// Params:
/// prop = 設定データ。
/// path = ファイルパス。
/// Returns: カード画像。カード画像でないならnull。
ImageData loadCardImage(Skin skin, string path) {
	return skin.isCardImage(path) ? loadImage(path) : null;
}
/// 背景画像として使用可能であればイメージデータを生成して返す。
/// Params:
/// path = ファイルパス。
/// Returns: 背景画像。背景画像でないならnull。
ImageData loadBgImage(Skin skin, string path) {
 	return skin.isBgImage(path) ? loadImage(path) : null;
}

private ImageData createImg(string delegate(out bool mask, out bool rMask) res) {
	bool mask, rMask;
	auto path = res(mask, rMask);
	return imgd(path, mask, rMask);
}

ImageData summary(Skin skin) {return createImg(&skin.resSummary);}

ImageData menuCard(Skin skin) {return createImg(&skin.resMenuCard);}
ImageData castCard(Skin skin) {return createImg(&skin.resCastCard);}
ImageData itemCard(Skin skin) {return createImg(&skin.resItemCard);}
ImageData skillCard(Skin skin) {return createImg(&skin.resSkillCard);}
ImageData beastCard(Skin skin) {return createImg(&skin.resBeastCard);}
ImageData infoCard(Skin skin) {return createImg(&skin.resInfoCard);}

ImageData rare(Skin skin) {return createImg(&skin.resRare);}
ImageData premier(Skin skin) {return createImg(&skin.resPremier);}

ImageData aptVeryHigh(Skin skin) {return createImg(&skin.resAptVeryHigh);}
ImageData aptHigh(Skin skin) {return createImg(&skin.resAptHigh);}
ImageData aptNormal(Skin skin) {return createImg(&skin.resAptNormal);}
ImageData aptLow(Skin skin) {return createImg(&skin.resAptLow);}

ImageData use0(Skin skin) {return createImg(&skin.resUse0);}
ImageData use1(Skin skin) {return createImg(&skin.resUse1);}
ImageData use2(Skin skin) {return createImg(&skin.resUse2);}
ImageData use3(Skin skin) {return createImg(&skin.resUse3);}
ImageData use4(Skin skin) {return createImg(&skin.resUse4);}

/// 特殊文字の画像。
ImageData spChar(Skin skin, dchar c) {return imgd(skin.spChars[c], true);}
