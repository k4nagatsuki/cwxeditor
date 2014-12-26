
module cwx.editor.gui.dwt.jpyimage;

import cwx.skin;
import cwx.utils;
import cwx.structs;
import cwx.jpy;
import cwx.graphics;
import cwx.sjis;
import cwx.summary;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;

import std.file;
import std.path;
import std.string;
import std.utf;

import org.eclipse.swt.all;

/// JPYの動作をエミュレートするが、甚だ不完全。
ImageData loadJPYImage(Props prop, in Skin skin, in Summary summ, string path, string[] stratum, out bool resizable) { mixin(S_TRACE);
	uint width, height;
	return loadJPYImage(prop, skin, summ, path, stratum, width, height, resizable);
}
/// ditto
ImageData loadJPYImage(Props prop, in Skin skin, in Summary summ, string path, string[] stratum, out uint width, out uint height, out bool resizable) { mixin(S_TRACE);
	auto ext = .extension(path);
	resizable = true;
	try { mixin(S_TRACE);
		if (cfnmatch(ext, ".jpy1")) { mixin(S_TRACE);
			auto img = loadJPYImageImpl(prop, skin, summ, path, stratum);
			if (img) { mixin(S_TRACE);
				width = img.width;
				height = img.height;
				return img;
			}
		} else if (cfnmatch(ext, ".jptx")) { mixin(S_TRACE);
			auto img = loadJPTXImage(prop, path);
			width = img.width;
			height = img.height;
			return img;
		} else if (cfnmatch(ext, ".jpdc")) { mixin(S_TRACE);
			auto img = loadJPDCImage(prop, path);
			width = img.width;
			height = img.height;
			resizable = false;
			return img;
		}
	} catch (EffectBoosterError e) {
		printStackTrace();
		debugln(e);
		resizable = false;
		auto img = warningImage(prop, summ, e);
		width = img.width;
		height = img.height;
		return img;
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
	}
	width = 0;
	height = 0;
	return blankImage;
}

private ImageData loadJPYImageImpl(Props prop, in Skin skin, in Summary summ, string path, string[] stratum) { mixin(S_TRACE);
	Jpy1 jpy = Jpy1.load(prop.parent, summ.scenarioPath, path);
	if (!jpy.sections.length) return blankImage;
	auto init = jpy.sections[0];
	int width = 632, height = 420;
	if (init.backwidth >= 0) width = init.backwidth;
	if (init.backheight >= 0) height = init.backheight;
	auto d = Display.getCurrent();
	if (width == 0 || height == 0) return null;
	auto img = new Image(d, width, height);
	scope (exit) img.dispose();
	auto gc = new GC(img);
	scope (exit) gc.dispose();
	path = nabs(path);
	ImageData[Cache] cache;
	foreach (i, sec; jpy.sections) { mixin(S_TRACE);
		int pw = i == 0 || sec.width < 0 ? width : sec.width;
		int ph = i == 0 || sec.height < 0 ? height : sec.height;
		ImageData data = null;
		if (sec.loadcache != Cache.NONE) { mixin(S_TRACE);
			auto p = sec.loadcache in cache;
			data = p ? *p : null;
			if (!data) { mixin(S_TRACE);
				if (sec.savecache != Cache.NONE) { mixin(S_TRACE);
					cache[sec.savecache] = null;
				}
				continue;
			}
		}
		if (!data && sec.filename.length && !cfnmatch(.extension(sec.filename), ".wav")) { mixin(S_TRACE);
			string dir;
			switch (sec.dirtype) {
			case Dirtype.CURRENT: { mixin(S_TRACE);
				dir = dirName(path);
			} break;
			case Dirtype.TABLE: { mixin(S_TRACE);
				if (!skin) continue;
				dir = skin.tableDir;
			} break;
			case Dirtype.SCHEME: { mixin(S_TRACE);
				if (!skin) continue;
				auto edir = dirName(skin.engine);
				if (!exists(edir)) continue;
				dir = std.path.buildPath(edir, "scheme");
			} break;
			case Dirtype.SCENARIO: { mixin(S_TRACE);
				if (!summ) continue;
				dir = summ.scenarioPath;
			} break;
			case Dirtype.WAV: { mixin(S_TRACE);
				if (!skin) continue;
				dir = skin.seDir;
			} break;
			case Dirtype.PARENT: { mixin(S_TRACE);
				dir = dirName(dirName(path));
				for (int dp = 0; dp < sec.dirdepth; dp++) { mixin(S_TRACE);
					dir = dirName(dir);
				}
			} break;
			case Dirtype.PROGRAM: { mixin(S_TRACE);
				if (!skin) continue;
				dir = dirName(skin.engine);
			} break;
			default: continue;
			}
			auto fname = std.path.buildPath(dir, sec.filename);
			if (!exists(fname)) continue;
			data = loadImage(prop, skin, summ, fname, false, 0, 0, stratum);
			stratum ~= nabs(fname);
		}
		int dtw = data && data.width > 0 ? data.width : pw;
		int dth = data && data.height > 0 ? data.height : ph;
		if (dtw <= 0 || dth <= 0) { mixin(S_TRACE);
			if (sec.savecache != Cache.NONE) { mixin(S_TRACE);
				cache[sec.savecache] = null;
			}
			continue;
		}
		auto dimg = new Image(d, dtw, dth);
		scope (exit) dimg.dispose();
		auto dgc = new GC(dimg);
		scope (exit) dgc.dispose();
		int alpha;
		auto dbc = new Color(d, dwtData(i == 0 ? sec.backcolor : sec.color, alpha));
		scope (exit) dbc.dispose();
		dgc.setBackground(dbc);
		dgc.fillRectangle(0, 0, dtw, dth);
		if (data) { mixin(S_TRACE);
			auto timg = new Image(d, data);
			scope (exit) timg.dispose();
			if (sec.clip.width > 0 && sec.clip.height > 0) { mixin(S_TRACE);
				dgc.drawImage(timg, sec.clip.x, sec.clip.y, sec.clip.width, sec.clip.height,
					0, 0, data.width, data.height);
			} else { mixin(S_TRACE);
				dgc.drawImage(timg, 0, 0);
			}
		}
		data = dimg.getImageData();
		if (sec.colorexchange != Colorexchange.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[]) data.data;
			auto balpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) colorexchange(sec.colorexchange, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[]) balpha;
		}
		if (sec.filter != Filter.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[]) data.data;
			auto balpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) cwx.graphics.filter(sec.filter, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[]) balpha;
		}
		if (sec.colormap != Colormap.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[]) data.data;
			auto balpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) colormap(sec.colormap, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[]) balpha;
		}
		if (sec.flip) { mixin(S_TRACE);
			auto bdata = cast(ubyte[]) data.data;
			auto balpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) flip(bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[]) balpha;
		}
		if (sec.mirror) { mixin(S_TRACE);
			auto bdata = cast(ubyte[]) data.data;
			auto balpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) mirror(bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[]) balpha;
		}
		if (sec.noise != Noise.NONE && sec.noisepoint != 0) { mixin(S_TRACE);
			auto bdata = cast(ubyte[]) data.data;
			auto balpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) noise(sec.noise, sec.noisepoint, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[]) balpha;
		}
		if (sec.turn != Turn.NONE) { mixin(S_TRACE);
			ubyte[] bytes = cast(ubyte[]) data.data;
			ubyte[] balpha = cast(ubyte[]) data.alphaData;
			size_t dw = data.width;
			size_t dh = data.height;
			size_t bpl = data.bytesPerLine;
			turn(bytes, balpha, dw, dh, bpl, sec.turn, data.depth);
			data.data = cast(byte[]) bytes;
			data.alphaData = cast(byte[]) balpha;
			data.width = dw;
			data.height = dh;
			data.bytesPerLine = bpl;
		}
		int sw = data.width, sh = data.height;
		if (sec.width > 0) sw = sec.width;
		if (sec.height > 0) sh = sec.height;
		if (sw != data.width || sh != data.height) { mixin(S_TRACE);
			if (sec.smooth) { mixin(S_TRACE);
				size_t bpl;
				auto bdata = cast(ubyte[]) data.data;
				auto balpha = cast(ubyte[]) data.alphaData;
				data.data = cast(byte[]) smoothResize(sw, sh, bdata, balpha, data.depth, data.width, data.height,
					data.bytesPerLine, bpl);
				data.alphaData = cast(byte[]) balpha;
				data.width = sw;
				data.height = sh;
				data.bytesPerLine = bpl;
			} else { mixin(S_TRACE);
				data = data.scaledTo(sw, sh);
			}
		}
		if (sec.mask != Mask.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[]) data.data;
			auto balpha = cast(ubyte[]) data.alphaData;
			data.data = cast(byte[]) mask(sec.mask, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[]) balpha;
		}
		void fill(bool delegate(ubyte r, ubyte g, ubyte b) isMask) { mixin(S_TRACE);
			size_t bpp = data.bytesPerLine / data.width;
			for (size_t y = 0; y < data.height; y++) { mixin(S_TRACE);
				for (size_t x = 0; x < data.width; x++) { mixin(S_TRACE);
					size_t i = y * data.width * bpp + x * bpp;
					if (isMask(data.data[i + 2], data.data[i + 1], data.data[i + 0])) { mixin(S_TRACE);
						data.setAlpha(x, y, 0);
					} else { mixin(S_TRACE);
						data.setAlpha(x, y, 255);
					}
				}
			}
		}
		switch (sec.paintmode) {
		case Paintmode.AND: { mixin(S_TRACE);
			if (sec.transparent) { mixin(S_TRACE);
				ubyte fr = data.data[2];
				ubyte fg = data.data[1];
				ubyte fb = data.data[0];
				fill((ubyte r, ubyte g, ubyte b) { mixin(S_TRACE);
					return (r == 255 && g == 255 && b == 255) || (r == fr && g == fg && b == fb);
				});
			} else { mixin(S_TRACE);
				fill((ubyte r, ubyte g, ubyte b) { mixin(S_TRACE);
					return r == 255 && g == 255 && b == 255;
				});
			}
		} break;
		case Paintmode.OR: { mixin(S_TRACE);
			if (sec.transparent) { mixin(S_TRACE);
				ubyte fr = data.data[2];
				ubyte fg = data.data[1];
				ubyte fb = data.data[0];
				fill((ubyte r, ubyte g, ubyte b) { mixin(S_TRACE);
					return (r == 0 && g == 0 && b == 0) || (r == fr && g == fg && b == fb);
				});
			} else { mixin(S_TRACE);
				fill((ubyte r, ubyte g, ubyte b) { mixin(S_TRACE);
					return r == 0 && g == 0 && b == 0;
				});
			}
		} break;
		default: { mixin(S_TRACE);
			if (sec.transparent) { mixin(S_TRACE);
				data.transparentPixel = data.getPixel(0, 0);
			}
		} break;
		}
		if (sec.savecache != Cache.NONE) { mixin(S_TRACE);
			cache[sec.savecache] = data;
		}
		if (sec.visible && sec.paintmode != Paintmode.NO_PAINT) { mixin(S_TRACE);
			auto simg = new Image(d, data);
			scope (exit) simg.dispose();
			if (sec.alpha < 0xFF && sec.paintmode == Paintmode.BLEND) { mixin(S_TRACE);
				gc.setAlpha(sec.alpha);
			}
			scope (exit) gc.setAlpha(0xFF);
			gc.drawImage(simg, sec.position.x, sec.position.y);
		}
	}
	return img.getImageData();
}

version (Windows) {
	import std.c.string;
	import std.c.windows.windows;
	private extern (Windows) {
		const DEFAULT_CHARSET = 0x1;
		const OUT_DEFAULT_PRECIS = 0x0;
		const CLIP_DEFAULT_PRECIS = 0x0;
		const DEFAULT_QUALITY = 0x0;
		const ANTIALIASED_QUALITY = 0x4;
		const DEFAULT_PITCH = 0x0;
		const FIXED_PITCH = 0x1;
		const VARIABLE_PITCH = 0x2;
		const FF_DONTCARE = (0x0 << 4);
		const FF_ROMAN = (0x1 << 4);
		const FF_MODERN = (0x3 << 4);
		HFONT CreateFontW(INT, INT, INT, INT, INT, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
	}
}
/// この実装は実質Windows専用である。
/// 他のOSではレンダリング結果が大幅に異なる。
/// また、antialiasプロパティの値は一切反映されない。
private ImageData loadJPTXImage(in Props prop, string path) { mixin(S_TRACE);
	auto jptx = Jptx.load(prop.parent, path);
	if (jptx.backwidth == 0 || jptx.backheight == 0) return blankImage;
	auto d = Display.getCurrent();
	int width = 632, height = 420;
	if (jptx.backwidth > -1) { mixin(S_TRACE);
		width = jptx.backwidth;
	}
	if (jptx.backheight > -1) { mixin(S_TRACE);
		height = jptx.backheight;
	}
	auto img = new Image(d, width, height);
	scope (exit) img.dispose();
	auto gc = new GC(img);
	scope (exit) gc.dispose();
	// FIXME: cwconv.dllの実装で必ずantialiasがかかってしまう
	version (Windows) {} else {
		// FIXME: IPAフォントの使用とアンチエイリアス設定を
		//        同時に行うと一部環境で問題が出る。
//		gc.setTextAntialias(jptx.antialias ? SWT.ON : SWT.OFF);
	}
	int alpha;
	auto cBack = new Color(d, dwtData(jptx.backcolor, alpha));
	scope (exit) cBack.dispose();
	gc.setBackground(cBack);
	gc.fillRectangle(0, 0, width, height);
	if (jptx.fonttransparent) { mixin(S_TRACE);
		auto cFore = new Color(d, dwtData(jptx.fontcolor, alpha));
		scope (exit) cFore.dispose();
		gc.setForeground(cFore);
		gc.drawLine(0, 0, img.width, 0);
	}
	int x = 0;
	int y = 0;
	int autoW = 1;
	int autoH = 1;
	int lineCount = 0;
	jptx.parse((string text, in JptxParam param) { mixin(S_TRACE);
		version (Windows) {
			int fh = param.pixels;
			DWORD fwg = param.b ? FW_BOLD : FW_NORMAL;
			DWORD fi = param.i ? TRUE : FALSE;
			DWORD fu = param.u ? TRUE : FALSE;
			DWORD fs = param.s ? TRUE : FALSE;
			DWORD fc = DEFAULT_CHARSET;
			DWORD fop = OUT_DEFAULT_PRECIS;
			DWORD fclp = CLIP_DEFAULT_PRECIS;
			// FIXME: 現行の実装で必ずantialiasがかかってしまう
			DWORD fq = ANTIALIASED_QUALITY;
//			DWORD fq = jptx.antialias ? ANTIALIASED_QUALITY : DEFAULT_QUALITY;
			DWORD fp = DEFAULT_PITCH | FF_DONTCARE;
			HFONT hf;
			hf = CreateFontW(fh, 0, 0, 0, fwg, fi, fu, fs, fc, fop, fclp, fq,
				fp, toUTFz!(wchar*)(param.face));
			auto font = Font.win32_new(d, hf);
		} else { mixin(S_TRACE);
			int fStyle = SWT.NORMAL;
			if (param.b) fStyle |= SWT.BOLD;
			if (param.i) fStyle |= SWT.ITALIC;
			auto h = cast(int) (param.pixels * (72.0 / d.getDPI().y) + 0.5);
			auto fontData = new FontData(param.face, h, fStyle);
			auto font = new Font(d, fontData);
		}
		scope (exit) font.dispose();
		gc.setFont(font);

		x += param.shiftx;
		y += param.shifty;

		int height = gc.getFontMetrics().getHeight();
		if (text == "\n") { mixin(S_TRACE);
			// wrap
			height *= param.lineheight / 100.0;
			y += height;
			x = 0;
			return;
		}
		auto cFore = new Color(d, dwtData(param.color, alpha));
		scope (exit) cFore.dispose();
		gc.setForeground(cFore);
		gc.wDrawText(text, x, y);
		int w = gc.wTextExtent(text).x;
		version (Windows) {} else {
			if (param.s) { mixin(S_TRACE);
				int ly = y + height / 2;
				gc.drawLine(x, ly, x + w, ly);
			}
			if (param.u) { mixin(S_TRACE);
				int ly = y + height;
				gc.drawLine(x, ly, x + w, ly);
			}
		}
		x += w;
		if (x > autoW) autoW = x;
		if (y + height > autoH) { mixin(S_TRACE);
			autoH = y + height; 
			lineCount++;
		}
	});
	if (lineCount & 0x1) { mixin(S_TRACE);
		// 奇数行数だと1ピクセル膨れる。cwconv.dllのバグか？
		autoH++;
	}
	int rw = jptx.backwidth == -1 ? autoW : jptx.backwidth;
	int rh = jptx.backheight == -1 ? autoH : jptx.backheight;
	auto r = new Image(d, rw, rh);
	scope (exit) r.dispose();
	auto rgc = new GC(r);
	rgc.setBackground(cBack);
	rgc.fillRectangle(0, 0, rw, rh);
	scope (exit) rgc.dispose();
	int w = width < rw ? width : rw;
	int h = height < rh ? height : rh;
	rgc.drawImage(img, 0, 0, w, h, 0, 0, w, h);
	return r.getImageData();
}

private ImageData warningImage(Props prop, in Summary summ, EffectBoosterError e) { mixin(S_TRACE);
	if (!e.errors.length) return blankImage;
	auto d = Display.getCurrent();
	string[] msgs;
	// エラーメッセージの表示に必要なサイズを求める
	int width, height, lh, lineHeight;
	auto imgBounds = prop.images.warning.getBounds();
	{ mixin(S_TRACE);
		auto img = new Image(d, 1, 1);
		scope (exit) img.dispose();
		auto gc = new GC(img);
		scope (exit) gc.dispose();
		lineHeight = gc.getFontMetrics().getHeight();
		lh = .max(imgBounds.height, lineHeight);
		height = (lh * 2) * e.errors.length + 5 * (e.errors.length - 1) + 2 * 2;
		width = 0;
		auto sPath = summ ? nabs(summ.scenarioPath).toLower() : "";
		foreach (err; e.errors) { mixin(S_TRACE);
			string path;
			if (summ && nabs(err.file).toLower().startsWith(sPath)) { mixin(S_TRACE);
				path = err.file.abs2rel(summ.scenarioPath);
			} else { mixin(S_TRACE);
				path = err.file.baseName();
			}
			auto msg = .tryFormat(prop.msgs.jpyError, err.msg, path, err.line);
			width = .max(width, gc.wTextExtent(msg).x);
			msgs ~= msg;
		}
		width += imgBounds.width + 4 + 5 * 2;
	}
	auto img = new Image(d, width, height);
	scope (exit) img.dispose();
	auto gc = new GC(img);
	scope (exit) gc.dispose();
	gc.setForeground(d.getSystemColor(SWT.COLOR_WHITE));
	gc.fillRectangle(0, 0, width, height);
	gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
	int x = 5;
	int y = 2;
	foreach (i, msg; msgs) { mixin(S_TRACE);
		gc.drawImage(prop.images.warning, x, y + (lh - imgBounds.height) / 2);
		gc.wDrawText(msg, x + imgBounds.width + 4, y + (lh - lineHeight) / 2, true);
		y += lh * 2 + 5;
	}
	return img.getImageData();
}

private ImageData loadJPDCImage(in Props prop, string path) { mixin(S_TRACE);
	Jpdc jpdc = Jpdc.load(prop.parent, path);
	auto d = Display.getCurrent();
	auto img = new Image(d, jpdc.clip.width, jpdc.clip.height);
	scope (exit) img.dispose();
	auto gc = new GC(img);
	scope (exit) gc.dispose();
	gc.setForeground(d.getSystemColor(SWT.COLOR_WHITE));
	gc.fillRectangle(0, 0, jpdc.clip.width, jpdc.clip.height);
	gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
	int tw = jpdc.clip.width - 4;
	string text = "JPDC Save to: " ~ (jpdc.saveFileName.length ? jpdc.saveFileName : "(undefined)");
	int ty = 2;
	while (text.length) { mixin(S_TRACE);
		string t = text[0 .. 1];
		size_t i;
		for (i = 1; i < text.length; i++) { mixin(S_TRACE);
			if (gc.wTextExtent(t ~ text[i]).x > tw) break;
			t ~= text[i];
		}
		gc.wDrawText(t, 2, ty, true);
		ty += gc.wTextExtent(t).y;
		text = text[t.length .. $];
	}
	auto data = img.getImageData();
	return data;
}
