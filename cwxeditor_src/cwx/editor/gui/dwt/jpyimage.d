
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

import std.algorithm : max;
import std.file;
import std.path;
import std.string;
import std.utf;

import org.eclipse.swt.all;

/// JPYの動作をエミュレートするが、甚だ不完全。
ImageDataWithScale loadJPYImageWithScale(Props prop, in Skin skin, in Summary summ, string path, uint targetScale, string[] stratum, out bool resizable) { mixin(S_TRACE);
	uint width, height;
	return loadJPYImageWithScale(prop, skin, summ, path, targetScale, stratum, width, height, resizable);
}
/// ditto
ImageDataWithScale loadJPYImageWithScale(Props prop, in Skin skin, in Summary summ, string path, uint targetScale, string[] stratum, out uint width, out uint height, out bool resizable) { mixin(S_TRACE);
	auto ext = .extension(path);
	resizable = true;
	try { mixin(S_TRACE);
		if (cfnmatch(ext, ".jpy1")) { mixin(S_TRACE);
			auto img = loadJPYImageImpl(prop, skin, summ, path, targetScale, stratum);
			if (img) { mixin(S_TRACE);
				width = img.getWidth(1);
				height = img.getHeight(1);
				return img;
			}
		} else if (cfnmatch(ext, ".jptx")) { mixin(S_TRACE);
			auto img = loadJPTXImage(prop, path, targetScale);
			width = img.getWidth(1);
			height = img.getHeight(1);
			return img;
		} else if (cfnmatch(ext, ".jpdc")) { mixin(S_TRACE);
			auto img = loadJPDCImage(prop, summ ? summ.scenarioPath : "", path, targetScale);
			width = img.getWidth(1);
			height = img.getHeight(1);
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
		return new ImageDataWithScale(img, .dpiMuls);
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
	}
	width = 0;
	height = 0;
	return new ImageDataWithScale(blankImage, 1);
}

private ImageDataWithScale loadJPYImageImpl(Props prop, in Skin skin, in Summary summ, string path, uint targetScale, string[] stratum) { mixin(S_TRACE);
	Jpy1 jpy = Jpy1.load(prop.parent, summ ? summ.scenarioPath : "", path);
	if (!jpy.sections.length) return new ImageDataWithScale(blankImage, 1);
	auto init = jpy.sections[0];
	int ts(int value) { return value * .max(1, targetScale); }
	int width = ts(632), height = ts(420);
	if (init.backwidth >= 0) width = ts(init.backwidth);
	if (init.backheight >= 0) height = ts(init.backheight);
	auto d = Display.getCurrent();
	if (width == 0 || height == 0) return null;
	auto img = new Image(d, width, height);
	scope (exit) img.dispose();
	auto gc = new GC(img);
	scope (exit) gc.dispose();
	path = nabs(path);
	ImageData[Cache] cache;
	foreach (i, sec; jpy.sections) { mixin(S_TRACE);
		if (sec.animation != 0 && sec.animation != 1) continue;
		int pw = i == 0 || sec.width < 0 ? width : ts(sec.width);
		int ph = i == 0 || sec.height < 0 ? height : ts(sec.height);
		ImageDataWithScale dataWS = null;
		if (sec.loadcache != Cache.NONE) { mixin(S_TRACE);
			auto p = sec.loadcache in cache;
			dataWS = p ? new ImageDataWithScale(*p, targetScale) : null;
			if (!dataWS) { mixin(S_TRACE);
				if (sec.savecache != Cache.NONE) { mixin(S_TRACE);
					cache[sec.savecache] = null;
				}
				continue;
			}
		}
		if (!dataWS && sec.filename.length && !cfnmatch(.extension(sec.filename), ".wav")) { mixin(S_TRACE);
			string[] dirs;
			auto drawingScale = targetScale;
			switch (sec.dirtype) {
			case Dirtype.CURRENT: { mixin(S_TRACE);
				dirs = [dirName(path)];
				drawingScale = prop.drawingScaleForImage(summ);
			} break;
			case Dirtype.TABLE: { mixin(S_TRACE);
				if (!skin) continue;
				dirs = skin.tableDirs;
			} break;
			case Dirtype.SCHEME: { mixin(S_TRACE);
				if (!skin) continue;
				if (skin.legacy) { mixin(S_TRACE);
					auto edir = dirName(skin.engine);
					if (!exists(edir)) continue;
					dirs = [std.path.buildPath(edir, "scheme")];
				} else { mixin(S_TRACE);
					if (skin.path == "") continue;
					auto dir = std.path.buildPath(skin.path, "EffectBooster");
					if (!exists(dir)) continue;
					dirs = [dir];
				}
			} break;
			case Dirtype.SCENARIO: { mixin(S_TRACE);
				if (!summ) continue;
				auto dir = summ.scenarioPath;
				for (int dp = 0; dp < sec.dirdepth; dp++) { mixin(S_TRACE);
					dir = dirName(dir);
				}
				dirs = [dir];
				drawingScale = prop.drawingScaleForImage(summ);
			} break;
			case Dirtype.WAV: { mixin(S_TRACE);
				if (!skin) continue;
				dirs = skin.seDirs;
			} break;
			case Dirtype.PARENT: { mixin(S_TRACE);
				dirs = [dirName(dirName(path))];
				drawingScale = prop.drawingScaleForImage(summ);
			} break;
			case Dirtype.PROGRAM: { mixin(S_TRACE);
				if (!skin) continue;
				dirs = [dirName(skin.engine)];
			} break;
			default: continue;
			}
			foreach (dir; dirs) { mixin(S_TRACE);
				auto fname = std.path.buildPath(dir, sec.filename);
				if (!exists(fname)) continue;
				dataWS = .loadImageWithScale(prop, skin, summ, fname, drawingScale, false, 0, 0, stratum);
				stratum ~= nabs(fname);
				break;
			}
		}
		int dtw = dataWS && dataWS.valid ? dataWS.getWidth(targetScale) : pw;
		int dth = dataWS && dataWS.valid ? dataWS.getHeight(targetScale) : ph;
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
		if (dataWS) { mixin(S_TRACE);
			auto tData = dataWS.scaled(targetScale);
			auto timg = new Image(d, tData);
			scope (exit) timg.dispose();
			if (ts(sec.clip.width) > 0 && ts(sec.clip.height) > 0) { mixin(S_TRACE);
				dgc.drawImage(timg, ts(sec.clip.x), ts(sec.clip.y), ts(sec.clip.width), ts(sec.clip.height),
					ts(0), ts(0), tData.width, tData.height);
			} else { mixin(S_TRACE);
				dgc.drawImage(timg, ts(0), ts(0));
			}
		}
		auto data = dimg.getImageData();
		if (sec.colorexchange != Colorexchange.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[])data.data;
			auto balpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])colorexchange(sec.colorexchange, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[])balpha;
		}
		if (sec.filter != Filter.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[])data.data;
			auto balpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])cwx.graphics.filter(sec.filter, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[])balpha;
		}
		if (sec.colormap != Colormap.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[])data.data;
			auto balpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])colormap(sec.colormap, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[])balpha;
		}
		if (sec.flip) { mixin(S_TRACE);
			auto bdata = cast(ubyte[])data.data;
			auto balpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])flip(bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[])balpha;
		}
		if (sec.mirror) { mixin(S_TRACE);
			auto bdata = cast(ubyte[])data.data;
			auto balpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])mirror(bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[])balpha;
		}
		if (sec.noise != Noise.NONE && sec.noisepoint != 0) { mixin(S_TRACE);
			auto bdata = cast(ubyte[])data.data;
			auto balpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])noise(sec.noise, sec.noisepoint, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[])balpha;
		}
		if (sec.turn != Turn.NONE) { mixin(S_TRACE);
			ubyte[] bytes = cast(ubyte[])data.data;
			ubyte[] balpha = cast(ubyte[])data.alphaData;
			size_t dw = data.width;
			size_t dh = data.height;
			size_t bpl = data.bytesPerLine;
			turn(bytes, balpha, dw, dh, bpl, sec.turn, data.depth);
			data.data = cast(byte[])bytes;
			data.alphaData = cast(byte[])balpha;
			data.width = cast(int)dw;
			data.height = cast(int)dh;
			data.bytesPerLine = cast(int)bpl;
		}
		int sw = data.width, sh = data.height;
		if (ts(sec.width) > 0) sw = ts(sec.width);
		if (ts(sec.height) > 0) sh = ts(sec.height);
		if (sw != data.width || sh != data.height) { mixin(S_TRACE);
			if (sec.smooth) { mixin(S_TRACE);
				size_t bpl;
				auto bdata = cast(ubyte[])data.data;
				auto balpha = cast(ubyte[])data.alphaData;
				data.data = cast(byte[])smoothResize(sw, sh, bdata, balpha, data.depth, data.width, data.height,
					data.bytesPerLine, bpl);
				data.alphaData = cast(byte[])balpha;
				data.width = sw;
				data.height = sh;
				data.bytesPerLine = cast(int)bpl;
			} else { mixin(S_TRACE);
				data = data.scaledTo(sw, sh);
			}
		}
		if (sec.mask != Mask.NONE) { mixin(S_TRACE);
			auto bdata = cast(ubyte[])data.data;
			auto balpha = cast(ubyte[])data.alphaData;
			data.data = cast(byte[])mask(sec.mask, bdata, balpha, data.depth, data.width, data.height, data.bytesPerLine);
			data.alphaData = cast(byte[])balpha;
		}
		void fill(bool delegate(ubyte r, ubyte g, ubyte b) isMask) { mixin(S_TRACE);
			size_t bpp = data.bytesPerLine / data.width;
			for (size_t y = 0; y < data.height; y++) { mixin(S_TRACE);
				for (size_t x = 0; x < data.width; x++) { mixin(S_TRACE);
					size_t i = y * data.width * bpp + x * bpp;
					if (isMask(data.data[i + 2], data.data[i + 1], data.data[i + 0])) { mixin(S_TRACE);
						data.setAlpha(cast(int)x, cast(int)y, 0);
					} else { mixin(S_TRACE);
						data.setAlpha(cast(int)x, cast(int)y, 255);
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
	return new ImageDataWithScale(img.getImageData(), targetScale);
}

/// この実装は実質Windows専用である。
/// 他のOSではレンダリング結果が大幅に異なる。
/// また、antialiasプロパティの値は一切反映されない。
private ImageDataWithScale loadJPTXImage(in Props prop, string path, uint targetScale) { mixin(S_TRACE);
	auto jptx = Jptx.load(prop.parent, path);
	if (jptx.backwidth == 0 || jptx.backheight == 0) return new ImageDataWithScale(blankImage, 1);
	auto d = Display.getCurrent();
	int ts(int value) { return value * .max(1, targetScale); }
	int width = ts(632), height = ts(420);
	if (ts(jptx.backwidth) > -1) { mixin(S_TRACE);
		width = ts(jptx.backwidth);
	}
	if (ts(jptx.backheight) > -1) { mixin(S_TRACE);
		height = ts(jptx.backheight);
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
	gc.fillRectangle(ts(0), ts(0), width, height);
	if (jptx.fonttransparent) { mixin(S_TRACE);
		auto cFore = new Color(d, dwtData(jptx.fontcolor, alpha));
		scope (exit) cFore.dispose();
		gc.setForeground(cFore);
		gc.drawLine(ts(0), ts(0), img.getBounds().width, ts(0));
	}
	int x = ts(0);
	int y = ts(0);
	int autoW = 1;
	int autoH = 1;
	int lineCount = 0;
	jptx.parse((string text, in JptxParam param) { mixin(S_TRACE);
		// FIXME: 現行の実装で必ずantialiasがかかってしまう
//		auto a = jptx.antialias;
		auto a = true;
		auto font = .createFontFromPixels(param.face, ts(param.pixels), param.b, param.i, param.u, param.s, a);
		scope (exit) font.dispose();
		Font majorFont = null;
		if (1 < targetScale) { mixin(S_TRACE);
			// 描画スケールが2以上の時でもサイズ計算はスケール1の時に
			// 合わせなければならないため、スケール1のフォントで計測を行う
			majorFont = .createFontFromPixels(param.face, param.pixels, param.b, param.i, param.u, param.s, a);
		}
		scope (exit) {
			if (majorFont) majorFont.dispose();
		}
		gc.setFont(font);

		x += ts(param.shiftx);
		y += ts(param.shifty);

		int height = 0;
		if (majorFont) { mixin(S_TRACE);
			gc.setFont(majorFont);
			height = ts(gc.getFontMetrics().getHeight());
			gc.setFont(font);
		} else { mixin(S_TRACE);
			height = gc.getFontMetrics().getHeight();
		}
		if (text == "\n") { mixin(S_TRACE);
			// wrap
			height *= ts(param.lineheight) / 100.0;
			y += height;
			x = ts(0);
			return;
		}
		auto cFore = new Color(d, dwtData(param.color, alpha));
		scope (exit) cFore.dispose();
		gc.setForeground(cFore);
		int w = 0;
		if (majorFont) { mixin(S_TRACE);
			gc.setFont(majorFont);
			auto e = gc.wTextExtent(text);
			e.x = ts(e.x);
			e.y = ts(e.y);
			gc.shrinkDrawText(text, x, y, e, a);
			w = e.x;
			gc.setFont(font);
		} else { mixin(S_TRACE);
			auto e = gc.wTextExtent(text);
			gc.shrinkDrawText(text, x, y, e, a);
			w = e.x;
		}
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
	int rw = jptx.backwidth == -1 ? autoW : ts(jptx.backwidth);
	int rh = jptx.backheight == -1 ? autoH : ts(jptx.backheight);
	auto r = new Image(d, rw, rh);
	scope (exit) r.dispose();
	auto rgc = new GC(r);
	rgc.setBackground(cBack);
	rgc.fillRectangle(ts(0), ts(0), rw, rh);
	scope (exit) rgc.dispose();
	int w = width < rw ? width : rw;
	int h = height < rh ? height : rh;
	rgc.drawImage(img, ts(0), ts(0), w, h, ts(0), ts(0), w, h);
	return new ImageDataWithScale(r.getImageData(), targetScale);
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
		height = (lh * 2) * cast(int)e.errors.length + 5.ppis * (cast(int)e.errors.length - 1) + 2.ppis * 2;
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
		width += imgBounds.width + 4.ppis + 5.ppis * 2;
	}
	auto img = new Image(d, width, height);
	scope (exit) img.dispose();
	auto gc = new GC(img);
	scope (exit) gc.dispose();
	gc.setForeground(d.getSystemColor(SWT.COLOR_WHITE));
	gc.fillRectangle(0, 0, width, height);
	gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
	int x = 5.ppis;
	int y = 2.ppis;
	foreach (i, msg; msgs) { mixin(S_TRACE);
		gc.drawImage(prop.images.warning, x, y + (lh - imgBounds.height) / 2);
		gc.wDrawText(msg, x + imgBounds.width + 4.ppis, y + (lh - lineHeight) / 2, true);
		y += lh * 2 + 5.ppis;
	}
	return img.getImageData();
}

private ImageDataWithScale loadJPDCImage(in Props prop, string sPath, string path, uint targetScale) { mixin(S_TRACE);
	Jpdc jpdc = Jpdc.load(prop.parent, sPath, path);
	auto d = Display.getCurrent();
	int ts(int value) { return value * .max(1, targetScale); }
	auto img = new Image(d, ts(jpdc.clip.width), ts(jpdc.clip.height));
	scope (exit) img.dispose();
	auto gc = new GC(img);
	scope (exit) gc.dispose();
	gc.setForeground(d.getSystemColor(SWT.COLOR_WHITE));
	gc.fillRectangle(ts(0), ts(0), ts(jpdc.clip.width), ts(jpdc.clip.height));
	gc.setForeground(d.getSystemColor(SWT.COLOR_BLACK));
	int tw = ts(jpdc.clip.width) - 4.ppis;
	string text = "JPDC Save to: " ~ (jpdc.saveFileName.length ? jpdc.saveFileName : "(undefined)");
	int ty = 2.ppis;
	while (text.length) { mixin(S_TRACE);
		string t = text[0 .. 1];
		size_t i;
		for (i = 1; i < text.length; i++) { mixin(S_TRACE);
			if (gc.wTextExtent(t ~ text[i]).x > tw) break;
			t ~= text[i];
		}
		gc.wDrawText(t, 2.ppis, ty, true);
		ty += gc.wTextExtent(t).y;
		text = text[t.length .. $];
	}
	auto data = img.getImageData();
	return new ImageDataWithScale(data, targetScale);
}
