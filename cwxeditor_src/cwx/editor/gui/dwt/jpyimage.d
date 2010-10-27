
module cwx.editor.gui.dwt.jpyimage;

import cwx.skin;
import cwx.utils;
import cwx.structs;
import cwx.jpy;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;

import std.file;
import std.path;

import dwt.DWT;
import dwt.DWTException;
import dwt.widgets.Display;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.graphics.PaletteData;
import dwt.graphics.GC;
import dwt.graphics.Color;
import dwt.graphics.Font;

/// JPYの動作をエミュレートするが、甚だ不完全。
ImageData loadJPYImage(Skin skin, string path) {
	auto ext = getExt(path);
	try {
		if (fnmatch(ext, "jpy1")) {
			return loadJPYImageImpl(skin, path);
		} else if (fnmatch(ext, "jptx")) {
			return loadJPTXImage(path);
		} else if (fnmatch(ext, "jpdc")) {
			return loadJPDCImage(path);
		}
	} catch (Exception e) {
		debugln(e);
	}
	return blankImage;
}

private ImageData loadJPYImageImpl(Skin skin, string path) {
	auto jpy = Jpy1.load(path);
	if (!jpy.sections.length) return blankImage;
	auto init = jpy.sections[0];
	int width = 632, height = 420;
	if (init.backwidth > 0) width = init.backwidth;
	if (init.backheight > 0) height = init.backheight;
	auto d = Display.getCurrent;
	auto img = new Image(d, width, height);
	scope (exit) img.dispose;
	auto gc = new GC(img);
	scope (exit) gc.dispose;
	path = nabs(path);
	ImageData[Cache] cache;
	foreach (i, sec; jpy.sections) {
		int pw = i == 0 ? width : sec.width;
		int ph = i == 0 ? height : sec.height;
		ImageData data = null;
		if (sec.loadcache == Cache.NONE) {
			auto p = sec.loadcache in cache;
			data = p ? *p : null;
		}
		if (!data && sec.filename.length && !fnmatch(getExt(sec.filename), "wav")) {
			string dir;
			switch (sec.dirtype) {
			case Dirtype.CURRENT: {
				dir = getDirName(path);
			} break;
			case Dirtype.TABLE: {
				if (!skin) continue;
				dir = skin.tableDir;
			} break;
			case Dirtype.SCHEME: {
				if (!skin) continue;
				auto edir = getDirName(skin.engine);
				if (!exists(edir)) continue;
				dir = std.path.join(edir, "scheme");
			} break;
			case Dirtype.SCENARIO: {
				dir = getDirName(path);
				for (int dp = 0; dp < sec.dirdepth; dp++) {
					dir = getDirName(dir);
				}
			} break;
			case Dirtype.WAV: {
				if (!skin) continue;
				dir = skin.seDir;
			} break;
			case Dirtype.PARENT: {
				dir = getDirName(getDirName(path));
				for (int dp = 0; dp < sec.dirdepth; dp++) {
					dir = getDirName(dir);
				}
			} break;
			case Dirtype.PROGRAM: {
				if (!skin) continue;
				dir = getDirName(skin.engine);
			} break;
			default: continue;
			}
			auto fname = std.path.join(dir, sec.filename);
			if (!exists(fname)) continue;
			data = loadImage(skin, fname, false);
		}
		if (!data) continue;
		int sw = data.width, sh = data.height;
		if (sec.width > 0) sw = sec.width;
		if (sec.height > 0) sh = sec.height;
		auto simg = new Image(d, sw, sh);
		scope (exit) simg.dispose;
		auto sgc = new GC(simg);
		scope (exit) sgc.dispose;
		int alpha;
		auto sbc = new Color(d, dwtData(sec.color, alpha));
		scope (exit) sbc.dispose;
		sgc.setBackground = sbc;
		auto dimg = new Image(d, data);
		scope (exit) dimg.dispose;
		sgc.drawImage(dimg, 0, 0, data.width, data.height, 0, 0, sw, sh);
		// 非対応
		// paintmode/smooth/exchange/colormap/filter/mask/noise/noisepoint/turn/flip/mirror
		if (sec.transparent) {
			data = simg.getImageData;
			data.transparentPixel = data.getPixel(0, 0);
			simg.dispose;
			simg = new Image(d, data);
		}
		if (sec.visible && sec.paintmode != Paintmode.NO_PAINT) {
			if (sec.alpha < 0xFF && sec.paintmode == Paintmode.BLEND) {
				gc.setAlpha = sec.alpha;
			}
			scope (exit) gc.setAlpha = 0xFF;
			if (sec.clip.width > 0 && sec.clip.height > 0) {
				gc.drawImage(simg, sec.clip.x, sec.clip.y, sec.clip.width, sec.clip.height,
					sec.position.x, sec.position.y, sec.clip.width, sec.clip.height);
			} else {
				gc.drawImage(simg, sec.position.x, sec.position.y);
			}
		}
		if (sec.savecache != Cache.NONE) {
			cache[sec.savecache] = simg.getImageData;
		}
	}
	return img.getImageData;
}

private ImageData loadJPTXImage(string path) {
	auto jptx = Jptx.load(path);
	if (jptx.backwidth == 0 || jptx.backheight == 0) return blankImage;
	auto d = Display.getCurrent;
	int width = 632, height = 420;
	if (jptx.backwidth > -1) {
		width = jptx.backwidth;
	}
	if (jptx.backheight > -1) {
		height = jptx.backheight;
	}
	auto img = new Image(d, width, height);
	scope (exit) img.dispose;
	auto gc = new GC(img);
	scope (exit) gc.dispose;
	int alpha;
	auto cBack = new Color(d, dwtData(jptx.backcolor, alpha));
	scope (exit) cBack.dispose;
	gc.setBackground = d.getSystemColor(DWT.COLOR_BLACK);
	gc.fillRectangle(0, 0, width, height);
	gc.setTextAntialias = jptx.antialias;
	if (jptx.fonttransparent) {
		auto cFore = new Color(d, dwtData(jptx.fontcolor, alpha));
		scope (exit) cFore.dispose;
		gc.setForeground = cFore;
		gc.drawLine(0, 0, img.width, 0);
	}
	int x = 0;
	int y = 0;
	int autoW = 1;
	int autoH = 1;
	jptx.parse((string text, in JptxParam param) {
		int fStyle = DWT.NORMAL;
		if (param.b) fStyle |= DWT.BOLD;
		if (param.i) fStyle |= DWT.ITALIC;
		auto fontData = new FontData(param.face, jptx.fontpixels, fStyle);
		fontData.height = cast(float) (jptx.fontpixels * (72.0 / d.getDPI.y));
		auto font = new Font(d, fontData);
		scope (exit) font.dispose;
		gc.setFont = font;
		int height = gc.getFontMetrics.getHeight;
		if (text == "\n") {
			// wrap
			height *= param.lineheight / 100.0;
			y += height;
			x = 0;
			return;
		}
		auto cFore = new Color(d, dwtData(param.color, alpha));
		scope (exit) cFore.dispose;
		gc.setForeground = cFore;
		gc.drawText(text, x + param.shiftx, y + param.shifty);
		int w = gc.textExtent(text).x;
		if (param.s) {
			int ly = y + height / 2;
			gc.drawLine(x, ly, x + w, ly);
		}
		if (param.u) {
			int ly = y + height;
			gc.drawLine(x, ly, x + w, ly);
		}
		x += w;
		if (x > autoW) autoW = x;
		if (y + height > autoH) autoH = y + height; 
	});
	int rw = jptx.backwidth == -1 ? autoW : jptx.backwidth;
	int rh = jptx.backheight == -1 ? autoH : jptx.backheight;
	auto r = new Image(d, rw, rh);
	scope (exit) r.dispose;
	auto rgc = new GC(r);
	rgc.setBackground = cBack;
	rgc.fillRectangle(0, 0, rw, rh);
	scope (exit) rgc.dispose;
	int w = width < rw ? width : rw;
	int h = height < rh ? height : rh;
	rgc.drawImage(img, 0, 0, w, h, 0, 0, w, h);
	return r.getImageData;
}

private ImageData loadJPDCImage(string path) {
	auto jpdc = Jpdc.load(path);
	auto d = Display.getCurrent;
	auto img = new Image(d, jpdc.clip.width, jpdc.clip.height);
	scope (exit) img.dispose;
	auto gc = new GC(img);
	scope (exit) gc.dispose;
	gc.setBackground = d.getSystemColor(DWT.COLOR_BLACK);
	gc.fillRectangle(0, 0, img.width, img.height);
	gc.setForeground = d.getSystemColor(DWT.COLOR_WHITE);
	gc.drawText("JPDC Save to: " ~ (jpdc.saveFileName.length ? jpdc.saveFileName : "(undefined)"), 2, 2, true);
	auto data = img.getImageData;
	data.transparentPixel = data.getPixel(0, 0);
	return data;
}
