
module cwx.graphics;

import cwx.jpy;
import cwx.utils;

import std.algorithm : max, min;
import std.string;
import std.random;

/// ダイレクトパレットのBitmap。
struct Pixels {
	/// 設定対象の配列。
	ubyte[] data;
	/// 設定対象のアルファ値配列。
	ubyte[] alpha;
	/// 縦幅。
	size_t width;
	/// 横幅。
	size_t height;
	/// 色深度。
	size_t depth;
	/// 1行のバイト数。
	size_t bytesPerLine;
	/// 1ピクセルのバイト数。
	size_t bpp;
	/// Pixelを取得する。
	FC get(size_t x, size_t y) { mixin(S_TRACE);
		size_t i = y * bytesPerLine + x * bpp;
		ubyte a = alpha.length ? alpha[y * width + x] : 0;
		switch (depth) {
		case 32:
			return FC(data[i + 2], data[i + 1], data[i], a);
		case 24:
			return FC(data[i + 2], data[i + 1], data[i], a);
		case 16:
			size_t d1 = data[i];
			size_t d2 = data[i + 1];
			return FC(cast(ubyte) ((d2 << 1) & 0xF8),
				cast(ubyte) ((d2 << 6) | ((d1 & 0xC0) >> 2)),
				cast(ubyte) (d1 << 3), a);
		default:
			throw new Exception(.format("bit depth: %d", depth), __FILE__, __LINE__);
		}
	}
	/// Pixelを設定する。
	void set(size_t x, size_t y, ubyte r, ubyte g, ubyte b, ubyte a) { mixin(S_TRACE);
		size_t i = y * bytesPerLine + x * bpp;
		switch (depth) {
		case 24, 32:
			data[i + 2] = r;
			data[i + 1] = g;
			data[i + 0] = b;
			break;
		case 16:
			data[i + 1] = cast(ubyte) (((r & 0xF8) >> 1) | (g >> 6));
			data[i + 0] = cast(ubyte) (((g << 2) & 0xE0) | (b >> 3));
			break;
		default:
			throw new Exception(.format("bit depth: %d", depth), __FILE__, __LINE__);
		}
		if (alpha.length) { mixin(S_TRACE);
			alpha[y * width + x] = a;
		}
	}
	/// ditto
	void set(size_t x, size_t y, uint r, uint g, uint b, uint a) { mixin(S_TRACE);
		set(x, y, cast(ubyte) r, cast(ubyte) g, cast(ubyte) b, cast(ubyte) a);
	}
	/// ditto
	void set(size_t x, size_t y, in FC fc) { mixin(S_TRACE);
		set(x, y, fc.r, fc.g, fc.b, fc.a);
	}
	/// Pixelを交換する。
	void swap(size_t x1, size_t y1, size_t x2, size_t y2) { mixin(S_TRACE);
		auto temp = get(x1, y1);
		set(x1, y1, get(x2, y2));
		set(x2, y2, temp);
	}
}

/// RGB。
struct FC {
	ubyte r, g, b, a;
	const
	bool eqRgb(in FC fc) { mixin(S_TRACE);
		return r == fc.r && g == fc.g && b == fc.b;
	}
}

/// intを使用するRGB。
struct FCu {
	int r, g, b, a;
	@property
	const
	FC fc() { mixin(S_TRACE);
		return FC(cast(ubyte) r, cast(ubyte) g, cast(ubyte) b, cast(ubyte) a);
	}
}

/// Turnの効果を適用する。
void turn(ref ubyte[] data, ref ubyte[] alpha, ref size_t width, ref size_t height, ref size_t bytesPerLine, Turn f, size_t depth) { mixin(S_TRACE);
	if (f is Turn.NONE || width < 1 || height < 1) return;
	size_t bpp = bytesPerLine / width;
	size_t nw = height;
	size_t nh = width;
	size_t newBytesPerLine = bpp * nw;
	if (newBytesPerLine % 4 != 0) { mixin(S_TRACE);
		newBytesPerLine = newBytesPerLine - (newBytesPerLine % 4) + 4;
	}
	auto base = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	auto r = Pixels(new ubyte[newBytesPerLine * nh], alpha.length ? new ubyte[nw * nh] : new ubyte[0], nw, nh, depth, newBytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			size_t xt;
			size_t yt;
			switch (f) {
			case Turn.LEFT:
				yt = x;
				xt = height - 1 - y;
				break;
			case Turn.RIGHT:
				yt = width - 1 - x;
				xt = y;
				break;
			default: assert (0);
			}
			r.set(xt, yt, base.get(x, y));
		}
	}
	data = r.data;
	alpha = r.alpha;
	width = nw;
	height = nh;
	bytesPerLine = newBytesPerLine;
}
/// Flipの効果を適用する。
ubyte[] flip(ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	auto r = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	for (size_t y1 = 0; y1 < height / 2; y1++) { mixin(S_TRACE);
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			size_t y2 = height - y1 - 1;
			r.swap(x, y1, x, y2);
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}
/// Mirrorの効果を適用する。
ubyte[] mirror(ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	auto r = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		for (size_t x1 = 0; x1 < width / 2; x1++) { mixin(S_TRACE);
			size_t x2 = width - x1 - 1;
			r.swap(x1, y, x2, y);
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}
void pixelProcImpl(T)(T f, ref FCu rgb) { mixin(S_TRACE);
	static if (is(T == Colorexchange)) {
		void push(int r, int g, int b) { mixin(S_TRACE);
			rgb.r = r;
			rgb.g = g;
			rgb.b = b;
		}
		switch (f) {
		case Colorexchange.NONE: return;
		case Colorexchange.GBR: push(rgb.g, rgb.b, rgb.r); break;
		case Colorexchange.BRG: push(rgb.b, rgb.r, rgb.g); break;
		case Colorexchange.GRB: push(rgb.g, rgb.r, rgb.b); break;
		case Colorexchange.BGR: push(rgb.b, rgb.g, rgb.r); break;
		case Colorexchange.RBG: push(rgb.r, rgb.b, rgb.g); break;
		default: assert (0);
		}
	} else static if (is(T == Colormap)) {
		void push(int rp, int gp, int bp) { mixin(S_TRACE);
			pixelProcImpl(Colormap.GRAY_SCALE, rgb);
			rgb.r += rp;
			rgb.g += gp;
			rgb.b += bp;
		}
		switch (f) {
		case Colormap.NONE: return;
		case Colormap.GRAY_SCALE: { mixin(S_TRACE);
			int v = (rgb.r + rgb.g + rgb.b) / 3;
			rgb.r = v;
			rgb.g = v;
			rgb.b = v;
			return;
		}
		case Colormap.SEPIA: push(30, 0, -30); break;
		case Colormap.PINK: push(255, 0, 30); break;
		case Colormap.SUNNY_RED: push(255, 0, 0); break;
		case Colormap.LEAF_GREEN: push(0, 255, 0); break;
		case Colormap.OCEAN_BLUE: push(0, 0, 255); break;
		case Colormap.LIGHTNING: push(191, 191, 0); break;
		case Colormap.PURPLE_LIGHT: push(191, 0, 191); break;
		case Colormap.AQUA_LIGHT: push(0, 191, 191); break;
		case Colormap.CRIMSON: push(0, -255, -255); break;
		case Colormap.DARK_GREEN: push(-255, 0, -255); break;
		case Colormap.DARK_BLUE: push(-255, -255, 0); break;
		case Colormap.SWAMP: push(0, 0, -255); break;
		case Colormap.DARK_PURPLE: push(0, -255, 0); break;
		case Colormap.DARK_SKY: push(-255, 0, 0); break;
		default: assert (0);
		}
		round(rgb);
	} else static if (is(T == Filter)) {
		void push(int r, int g, int b) { mixin(S_TRACE);
			rgb.r = r;
			rgb.g = g;
			rgb.b = b;
		}
		switch (f) {
		case Filter.MONO: { mixin(S_TRACE);
			if (rgb.r == 0 && rgb.g == 0 && rgb.b == 0) { mixin(S_TRACE);
				push(255, 255, 255);
			} else { mixin(S_TRACE);
				push(0, 0, 0);
			}
		} break;
		case Filter.NEGA: { mixin(S_TRACE);
			push(255 - rgb.r, 255 - rgb.g, 255 - rgb.b);
		} break;
		default: assert (0);
		}
	}
}
private void round(ref FCu rgb) { mixin(S_TRACE);
	if (rgb.r < 0) rgb.r = 0;
	if (rgb.r > 255) rgb.r = 255;
	if (rgb.g < 0) rgb.g = 0;
	if (rgb.g > 255) rgb.g = 255;
	if (rgb.b < 0) rgb.b = 0;
	if (rgb.b > 255) rgb.b = 255;
	if (rgb.a < 0) rgb.a = 0;
	if (rgb.a > 255) rgb.a = 255;
}
/// Colorexchange・Colormap・Filter・Maskの効果を適用する。
private ubyte[] pixelProc(T)(T f, ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	auto r = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			auto rgb = r.get(x, y);
			auto fc = FCu(rgb.r, rgb.g, rgb.b);
			pixelProcImpl!(T)(f, fc);
			r.set(x, y, fc.fc);
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}
/// Colorexchangeの効果を適用する。
ubyte[] colorexchange(Colorexchange f, ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	return pixelProc(f, data, alpha, depth, width, height, bytesPerLine);
}
/// Colormapの効果を適用する。
ubyte[] colormap(Colormap f, ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	return pixelProc(f, data, alpha, depth, width, height, bytesPerLine);
}
private ubyte[] emboss(ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	auto r = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			auto jx = x + 1 < width ? x + 1 : x;
			auto jy = y + 1 < height ? y + 1 : y;
			auto i = r.get(x, y);
			auto j = r.get(jx, jy);
			int val = (j.r + j.g + j.b) / 3 - (i.r + i.g + i.b) / 3 + 128;
			if (val < 0 || val > 255) val = 0;
			r.set(x, y, cast(ubyte) val, cast(ubyte) val, cast(ubyte) val, i.a);
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}
private ubyte[] deffusion(ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	Random rnd;
	rnd.seed(1); // 拡散値を固定する
	size_t bpp = bytesPerLine / width;
	auto base = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	auto r = Pixels(new ubyte[data.length], new ubyte[alpha.length], width, height, depth, bytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		// cwconv.dllの実装では縦方向への拡散が微妙だがそれに合わせる
		// 真に拡散させたい場合、jyの計算はxのループの内側にあるべき
		auto jy = y + uniform(0, 3, rnd);
		if (jy < 0) jy = 0;
		if (height <= jy) jy = height - 1;
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			ptrdiff_t jx = x + uniform(0, 3, rnd);
			if (jx < 0) jx = 0;
			if (width <= jx) jx = width - 1;
			r.set(x, y, r.get(jx, jy));
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}
/// Filterの効果を適用する。
ubyte[] filter(Filter f, ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (f is Filter.NONE || width < 1 || height < 1) return data;
	switch (f) {
	case Filter.MONO, Filter.NEGA: { mixin(S_TRACE);
		return pixelProc(f, data, alpha, depth, width, height, bytesPerLine);
	}
	case Filter.DIFFUSION: return deffusion(data, alpha, depth, width, height, bytesPerLine);
	case Filter.EMBOSS: return emboss(data, alpha, depth, width, height, bytesPerLine);
	default: break;
	}
	int[3][3] ft;
	int en = 1, adj = 0;
	switch (f) {
	case Filter.SHADE: { mixin(S_TRACE);
		en = 9;
		foreach (ref ln; ft) ln[] = 1;
	} break;
	case Filter.SHARP: { mixin(S_TRACE);
		en = 16;
		ft[0][0] = -1;
		ft[0][1] = -1;
		ft[0][2] = -1;
		ft[1][0] = -1;
		ft[1][1] = 24;
		ft[1][2] = -1;
		ft[2][0] = -1;
		ft[2][1] = -1;
		ft[2][2] = -1;
	} break;
	case Filter.SUN: { mixin(S_TRACE);
		en = 16;
		ft[0][0] = 1;
		ft[0][1] = 3;
		ft[0][2] = 1;
		ft[1][0] = 3;
		ft[1][1] = 5;
		ft[1][2] = 3;
		ft[2][0] = 1;
		ft[2][1] = 3;
		ft[2][2] = 1;
	} break;
	case Filter.C_EMBOSS: { mixin(S_TRACE);
		ft[0][0] = -1;
		ft[0][1] = -1;
		ft[0][2] = -1;
		ft[1][0] = 0;
		ft[1][1] = 1;
		ft[1][2] = 0;
		ft[2][0] = 1;
		ft[2][1] = 1;
		ft[2][2] = 1;
	} break;
	case Filter.D_EMBOSS: { mixin(S_TRACE);
		adj = 128;
		ft[0][0] = -1;
		ft[0][1] = -2;
		ft[0][2] = -1;
		ft[1][0] = 0;
		ft[1][1] = 0;
		ft[1][2] = 0;
		ft[2][0] = 1;
		ft[2][1] = 2;
		ft[2][2] = 1;
	} break;
	case Filter.ELEC: { mixin(S_TRACE);
		ft[0][0] = 1;
		ft[0][1] = 1;
		ft[0][2] = 1;
		ft[1][0] = 1;
		ft[1][1] = -15;
		ft[1][2] = 1;
		ft[2][0] = 1;
		ft[2][1] = 1;
		ft[2][2] = 1;
	} break;
	default: assert (0);
	}
	size_t bpp = bytesPerLine / width;
	auto base = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	auto result = Pixels(new ubyte[data.length], alpha.length ? new ubyte[width * height] : new ubyte[0], width, height, depth, bytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			int r = 0, g = 0, b = 0;
			for (int xt = 0; xt < 3; xt++) { mixin(S_TRACE);
				for (int yt = 0; yt < 3; yt++) { mixin(S_TRACE);
					ptrdiff_t xti = x + xt - 1;
					if (xti < 0) xti = 0;
					if (width <= xti) xti = width - 1;
					ptrdiff_t yti = y + yt - 1;
					if (yti < 0) yti = 0;
					if (height <= yti) yti = height - 1;
					auto rgb = base.get(xti, yti);
					r += rgb.r * ft[yt][xt];
					g += rgb.g * ft[yt][xt];
					b += rgb.b * ft[yt][xt];
				}
			}
			r = r / en + adj;
			g = g / en + adj;
			b = b / en + adj;
			auto fc = FCu(r, g, b);
			round(fc);
			result.set(x, y, fc.fc);
		}
	}
	data = result.data;
	alpha = result.alpha;
	return result.data;
}
/// Maskの効果を適用する。
ubyte[] mask(Mask f, ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	auto r = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			size_t i = y * bytesPerLine + x * bpp;
			if (((f is Mask.V_LINE || f is Mask.MESH) && !(x & 0x1))
					|| ((f is Mask.H_LINE || f is Mask.MESH) && !(y & 0x1))) { mixin(S_TRACE);
				r.set(x, y, cast(ubyte) 0, cast(ubyte) 0, cast(ubyte) 0, cast(ubyte) 0);
			}
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}
void noiseImpl(ref Random rnd, Noise f, ref FCu rgb, int value) { mixin(S_TRACE);
	switch (f) {
	case Noise.NONE: return;
	case Noise.LIGHT: { mixin(S_TRACE);
		rgb.r += value;
		rgb.g += value;
		rgb.b += value;
	} break;
	case Noise.MONO: { mixin(S_TRACE);
		int val = (rgb.r > value || rgb.g > value || rgb.b > value) ? 255 : 0;
		rgb.r = val;
		rgb.g = val;
		rgb.b = val;
	} break;
	case Noise.NOISE: { mixin(S_TRACE);
		if (value >= 0) { mixin(S_TRACE);
			auto val = uniform(0, value, rnd);
			rgb.r += val;
			rgb.g += val;
			rgb.b += val;
		} else { mixin(S_TRACE);
			int val = uniform(0, 2, rnd) ? 255 : 0;
			rgb.r = val;
			rgb.g = val;
			rgb.b = val;
		}
	} break;
	case Noise.C_NOISE: { mixin(S_TRACE);
		if (value >= 0) { mixin(S_TRACE);
			rgb.r += uniform(0, value, rnd);
			rgb.g += uniform(0, value, rnd);
			rgb.b += uniform(0, value, rnd);
		} else { mixin(S_TRACE);
			rgb.r = uniform(0, 2, rnd) ? 255 : 0;
			rgb.g = uniform(0, 2, rnd) ? 255 : 0;
			rgb.b = uniform(0, 2, rnd) ? 255 : 0;
		}
	} break;
	default: assert (0);
	}
	round(rgb);
}
/// Noiseの効果を適用する。
ubyte[] noise(Noise f, int value, ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine) { mixin(S_TRACE);
	if (f is Noise.NONE || value == 0 || width < 1 || height < 1) { mixin(S_TRACE);
		return data;
	}
	value %= 256;
	if (f is Noise.MOSAIC && value < 0) return data;
	Random rnd;
	rnd.seed(42); // ノイズを固定する
	size_t bpp = bytesPerLine / width;
	auto r = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	for (size_t y = 0; y < height; y++) { mixin(S_TRACE);
		for (size_t x = 0; x < width; x++) { mixin(S_TRACE);
			if (f is Noise.MOSAIC) { mixin(S_TRACE);
				// cwconv.dllの実装では平均値を求めず左上の値を取っているので
				// それに合わせる
				size_t jx = x - x % value;
				size_t jy = y - y % value;
				r.set(x, y, r.get(jx, jy));
			} else { mixin(S_TRACE);
				auto rgb = r.get(x, y);
				auto fc = FCu(rgb.r, rgb.g, rgb.b);
				noiseImpl(rnd, f, fc, value);
				r.set(x, y, fc.fc);
			}
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}
/// 拡大・縮小した結果を返す。
/// スムージングは行わない。
ubyte[] resize(size_t newWidth, size_t newHeight,
		ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine,
		out size_t newBytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	if (width == newWidth && height == newHeight) { mixin(S_TRACE);
		newBytesPerLine = bytesPerLine;
		return data;
	}
	real pw = cast(real) newWidth / width;
	real ph = cast(real) newHeight / height;
	size_t bpp = bytesPerLine / width;
	newBytesPerLine = bpp * newWidth;
	if (newBytesPerLine % 4 != 0) { mixin(S_TRACE);
		newBytesPerLine = newBytesPerLine - (newBytesPerLine % 4) + 4;
	}
	auto base = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	auto r = Pixels(new ubyte[newHeight * newBytesPerLine], alpha.length ? new ubyte[newWidth * newHeight] : new ubyte[0], newHeight, newHeight, depth, newBytesPerLine, bpp);
	for (size_t y = 0; y < newHeight; y++) { mixin(S_TRACE);
		size_t ty = cast(size_t) (y / ph);
		for (size_t x = 0; x < newWidth; x++) { mixin(S_TRACE);
			size_t tx = cast(size_t) (x / pw);
			r.set(x, y, base.get(tx, ty));
		}
	}
	data = r.data;
	alpha = r.alpha;
	return r.data;
}

/// 滑らかに拡大・縮小した結果を返す。
ubyte[] smoothResize(size_t newWidth, size_t newHeight,
		ref ubyte[] data, ref ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine,
		out size_t newBytesPerLine) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	if (width == newWidth && height == newHeight) { mixin(S_TRACE);
		newBytesPerLine = bytesPerLine;
		return data;
	}
	// 双線形補完
	real pw = cast(real) newWidth / width;
	real ph = cast(real) newHeight / height;
	size_t bpp = bytesPerLine / width;
	newBytesPerLine = bpp * newWidth;
	if (newBytesPerLine % 4 != 0) { mixin(S_TRACE);
		newBytesPerLine = newBytesPerLine - (newBytesPerLine % 4) + 4;
	}
	auto base = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	auto result = Pixels(new ubyte[newHeight * newBytesPerLine], alpha.length ? new ubyte[newWidth * newHeight] : new ubyte[0], newWidth, newHeight, depth, newBytesPerLine, bpp);
	for (size_t y = 0; y < newHeight; y++) { mixin(S_TRACE);
		real ty = y / ph;
		int bby = cast(int) ty;
		real yb = ty % 1.0;
		auto ybm = 1.0 - yb;
		for (size_t x = 0; x < newWidth; x++) { mixin(S_TRACE);
			real tx = x / pw;
			int bbx = cast(int) tx;
			real xb = tx % 1.0;
			auto xbm = 1.0 - xb;
			FC[2][2] a;
			for (int i = 0; i < 2; i++) { mixin(S_TRACE);
				for (int j = 0; j < 2; j++) { mixin(S_TRACE);
					ptrdiff_t by = bby + i;
					ptrdiff_t bx = bbx + j;
					if (by < 0) by = 0;
					if (height <= by) by = height - 1;
					if (bx < 0) bx = 0;
					if (width <= bx) bx = width - 1;
					auto rgb = base.get(bx, by);
					a[i][j].r = rgb.r;
					a[i][j].g = rgb.g;
					a[i][j].b = rgb.b;
					a[i][j].a = rgb.a;
				}
			}
			int r = cast(int) (xbm * (a[0][0].r * ybm + a[1][0].r * yb)
				+ xb * (a[0][1].r * ybm + a[1][1].r * yb));
			int g = cast(int) (xbm * (a[0][0].g * ybm + a[1][0].g * yb)
				+ xb * (a[0][1].g * ybm + a[1][1].g * yb));
			int b = cast(int) (xbm * (a[0][0].b * ybm + a[1][0].b * yb)
				+ xb * (a[0][1].b * ybm + a[1][1].b * yb));
			int al = cast(int) (xbm * (a[0][0].a * ybm + a[1][0].a * yb)
				+ xb * (a[0][1].a * ybm + a[1][1].a * yb));
			auto fc = FCu(r, g, b, al);
			round(fc);
			result.set(x, y, fc.fc);
		}
	}
	data = result.data;
	alpha = result.alpha;
	return result.data;
}

/// a部分へのbによる縁取り(bWidth幅)を行う。
ubyte[] bordering(ubyte[] data, ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine, FC a, FC b, uint bWidth) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	auto base = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	auto r = Pixels(data.dup, alpha.dup, width, height, depth, bytesPerLine, bpp);
	auto w = width - 1;
	auto h = height - 1;
	foreach (y; 0..height) { mixin(S_TRACE);
		foreach (x; 0..width) { mixin(S_TRACE);
			if (base.get(x, y) == a) continue;

			// 周囲にaがあるか探す
			bool find = false;
			find |= 0 < x && base.get(x - 1, y) == a;
			find |= 0 < y && base.get(x, y - 1) == a;
			find |= x < w && base.get(x + 1, y) == a;
			find |= y < h && base.get(x, y + 1) == a;
			find |= 0 < x && 0 < y && base.get(x - 1, y - 1) == a;
			find |= 0 < x && y < h && base.get(x - 1, y + 1) == a;
			find |= x < w && 0 < y && base.get(x + 1, y - 1) == a;
			find |= x < w && y < h && base.get(x + 1, y + 1) == a;

			if (!find) continue;

			// 縁取り実行
			ptrdiff_t bx = x - bWidth / 2;
			ptrdiff_t by = y - bWidth / 2;
			foreach (wy; .max(0, by) .. .min(height, by + bWidth)) { mixin(S_TRACE);
				foreach (wx; .max(0, bx) .. .min(width, bx + bWidth)) { mixin(S_TRACE);
					r.set(wx, wy, b);
				}
			}
		}
	}
	return r.data;
}

/// aとbに同時に接触している色cをaによって上書きする。
ubyte[] adjustBordering(ubyte[] data, ubyte[] alpha, size_t depth, size_t width, size_t height, size_t bytesPerLine, FC a, FC b, FC c) { mixin(S_TRACE);
	if (width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	auto base = Pixels(data, alpha, width, height, depth, bytesPerLine, bpp);
	auto r = Pixels(data.dup, alpha.dup, width, height, depth, bytesPerLine, bpp);
	auto w = width - 1;
	auto h = height - 1;
	foreach (y; 0..height) { mixin(S_TRACE);
		foreach (x; 0..width) { mixin(S_TRACE);
			if (!base.get(x, y).eqRgb(c)) continue;

			bool find(in FC fc) { mixin(S_TRACE);
				bool find = 0 < x && base.get(x - 1, y).eqRgb(fc);
				find |= 0 < y && base.get(x, y - 1).eqRgb(fc);
				find |= x < w && base.get(x + 1, y).eqRgb(fc);
				find |= y < h && base.get(x, y + 1).eqRgb(fc);
				return find;
			}
			// 周囲にaとbがあるか探す
			if (!find(a)) continue;
			if (!find(b)) continue;

			r.set(x, y, a);
		}
	}
	return r.data;
}
