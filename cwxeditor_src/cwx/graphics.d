
module cwx.graphics;

import cwx.jpy;
import cwx.utils;

import std.compat;
import std.random;

private struct FC {
	int r, g, b;
}
private void swapBytes(ref ubyte[] data, size_t i, size_t j) {
	swap(data[i + 0], data[j + 0]);
	swap(data[i + 1], data[j + 1]);
	swap(data[i + 2], data[j + 2]);
}
/// Turnの効果を適用する。
void turn(ref ubyte[] data, ref size_t width, ref size_t height, ref size_t bytesPerLine, Turn f, size_t depth) {
	if (f is Turn.NONE || data.length < 3 || depth < 24 || width < 1 || height < 1) return;
	size_t bpp = bytesPerLine / width;
	size_t nw = height;
	size_t nh = width;
	size_t nbpl = bpp * width;
	ubyte[] ndata = new ubyte[nbpl * height];
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			size_t i = y * width * bpp + x * bpp;
			size_t j;
			switch (f) {
			case Turn.LEFT: j = x * nw * bpp + (height - 1 - y) * bpp; break;
			case Turn.RIGHT: j = (width - 1 - x) * nw * bpp + y * bpp; break;
			default: assert (0);
			}
			ndata[j + 0] = data[i + 0];
			ndata[j + 1] = data[i + 1];
			ndata[j + 2] = data[i + 2];
		}
	}
	data = ndata;
	width = nw;
	height = nh;
	bytesPerLine = nbpl;
}
/// Flipの効果を適用する。
ubyte[] flip(ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	for (size_t y1 = 0; y1 < height / 2; y1++) {
		for (size_t x = 0; x < width; x++) {
			size_t y2 = height - y1 - 1;
			size_t i = y1 * width * bpp + x * bpp;
			size_t j = y2 * width * bpp + x * bpp;
			swapBytes(data, i, j);
		}
	}
	return data;
}
/// Mirrorの効果を適用する。
ubyte[] mirror(ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	for (size_t y = 0; y < height; y++) {
		for (size_t x1 = 0; x1 < width / 2; x1++) {
			size_t x2 = width - x1 - 1;
			size_t i = y * width * bpp + x1 * bpp;
			size_t j = y * width * bpp + x2 * bpp;
			swapBytes(data, i, j);
		}
	}
	return data;
}
void pixelProcImpl(T)(T f, ref FC rgb) {
	static if (is(T == Colorexchange)) {
		void push(int r, int g, int b) {
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
		void push(int rp, int gp, int bp) {
			pixelProcImpl(Colormap.GRAY_SCALE, rgb);
			rgb.r += rp;
			rgb.g += gp;
			rgb.b += bp;
		}
		switch (f) {
		case Colormap.NONE: return;
		case Colormap.GRAY_SCALE: {
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
		void push(int r, int g, int b) {
			rgb.r = r;
			rgb.g = g;
			rgb.b = b;
		}
		switch (f) {
		case Filter.MONO: {
			if (rgb.r == 0 && rgb.g == 0 && rgb.b == 0) {
				push(255, 255, 255);
			} else {
				push(0, 0, 0);
			}
		} break;
		case Filter.NEGA: {
			push(255 - rgb.r, 255 - rgb.g, 255 - rgb.b);
		} break;
		default: assert (0);
		}
	}
}
private void round(ref FC rgb) {
	if (rgb.r < 0) rgb.r = 0;
	if (rgb.r > 255) rgb.r = 255;
	if (rgb.g < 0) rgb.g = 0;
	if (rgb.g > 255) rgb.g = 255;
	if (rgb.b < 0) rgb.b = 0;
	if (rgb.b > 255) rgb.b = 255;
}
/// Colorexchange・Colormap・Filter・Maskの効果を適用する。
private ubyte[] pixelProc(T)(T f, ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			size_t i = y * width * bpp + x * bpp;
			auto fc = FC(data[i + 2], data[i + 1], data[i + 0]);
			pixelProcImpl!(T)(f, fc);
			data[i + 2] = fc.r;
			data[i + 1] = fc.g;
			data[i + 0] = fc.b;
		}
	}
	return data;
}
/// Colorexchangeの効果を適用する。
ubyte[] colorexchange(Colorexchange f, ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	return pixelProc(f, data, depth, width, height, bytesPerLine);
}
/// Colormapの効果を適用する。
ubyte[] colormap(Colormap f, ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	return pixelProc(f, data, depth, width, height, bytesPerLine);
}
private ubyte[] emboss(ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			size_t i = y * width * bpp + x * bpp;
			int jx = x + 1 < width ? x + 1 : x;
			int jy = y + 1 < height ? y + 1 : y;
			int j = jy * width * bpp + jx * bpp;
			auto val = (data[j + 2] + data[j + 1] + data[j + 0]) / 3
				- (data[i + 2] + data[i + 1] + data[i + 0]) / 3 + 128;
			if (val < 0 || val > 255) val = 0;
			data[i + 2] = val;
			data[i + 1] = val;
			data[i + 0] = val;
		}
	}
	return data;
}
private ubyte[] deffusion(ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	uint nextSeed = rand;
	rand_seed(1, 0); // 拡散値を固定する
	scope (exit) rand_seed(nextSeed, 0);
	size_t bpp = bytesPerLine / width;
	ubyte[] r = new ubyte[data.length];
	for (size_t y = 0; y < height; y++) {
		// cwconv.dllの実装では縦方向への拡散が微妙だがそれに合わせる
		// 真に拡散させたい場合、jyの計算はxのループの内側にあるべき
		int jy = y + cast(int) rand % 3;
		if (jy < 0) jy = 0;
		if (height <= jy) jy = height - 1;
		for (size_t x = 0; x < width; x++) {
			size_t i = y * width * bpp + x * bpp;
			auto fc = FC(data[i + 2], data[i + 1], data[i + 0]);
			int jx = x + cast(int) rand % 3;
			if (jx < 0) jx = 0;
			if (width <= jx) jx = width - 1;
			int j = jy * width * bpp + jx * bpp;
			r[i + 2] = data[j + 2];
			r[i + 1] = data[j + 1];
			r[i + 0] = data[j + 0];
		}
	}
	return r;
}
/// Filterの効果を適用する。
ubyte[] filter(Filter f, ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (f is Filter.NONE || data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	switch (f) {
	case Filter.MONO, Filter.NEGA: {
		return pixelProc(f, data, depth, width, height, bytesPerLine);
	}
	case Filter.DIFFUSION: return deffusion(data, depth, width, height, bytesPerLine);
	case Filter.EMBOSS: return emboss(data, depth, width, height, bytesPerLine);
	default: break;
	}
	int[3][3] ft;
	int en = 1, adj = 0;
	switch (f) {
	case Filter.SHADE: {
		en = 9;
		foreach (ref ln; ft) ln[] = 1;
	} break;
	case Filter.SHARP: {
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
	case Filter.SUN: {
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
	case Filter.C_EMBOSS: {
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
	case Filter.D_EMBOSS: {
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
	case Filter.ELEC: {
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
	ubyte[] result = new ubyte[data.length];
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			int r = 0, g = 0, b = 0;
			for (int xt = 0; xt < 3; xt++) {
				for (int yt = 0; yt < 3; yt++) {
					int xti = x + xt - 1;
					if (xti < 0) xti = 0;
					if (width <= xti) xti = width - 1;
					int yti = y + yt - 1;
					if (yti < 0) yti = 0;
					if (height <= yti) yti = height - 1;
					size_t it = yti * width * bpp + xti * bpp;
					r += data[it + 2] * ft[yt][xt];
					g += data[it + 1] * ft[yt][xt];
					b += data[it + 0] * ft[yt][xt];
				}
			}
			r = r / en + adj;
			g = g / en + adj;
			b = b / en + adj;
			auto fc = FC(r, g, b);
			round(fc);
			size_t i = y * width * bpp + x * bpp;
			result[i + 2] = fc.r;
			result[i + 1] = fc.g;
			result[i + 0] = fc.b;
		}
	}
	return result;
}
/// Maskの効果を適用する。
ubyte[] mask(Mask f, ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	size_t bpp = bytesPerLine / width;
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			size_t i = y * width * bpp + x * bpp;
			if (((f is Mask.V_LINE || f is Mask.MESH) && !(x & 0x1))
					|| ((f is Mask.H_LINE || f is Mask.MESH) && !(y & 0x1))) {
				data[i + 2] = 0;
				data[i + 1] = 0;
				data[i + 0] = 0;
			}
		}
	}
	return data;
}
void noiseImpl(Noise f, ref FC rgb, int value) {
	switch (f) {
	case Noise.NONE: return;
	case Noise.LIGHT: {
		rgb.r += value;
		rgb.g += value;
		rgb.b += value;
	} break;
	case Noise.MONO: {
		int val = (rgb.r > value || rgb.g > value || rgb.b > value) ? 255 : 0;
		rgb.r = val;
		rgb.g = val;
		rgb.b = val;
	} break;
	case Noise.NOISE: {
		if (value >= 0) {
			auto val = cast(int) rand % value;
			rgb.r += val;
			rgb.g += val;
			rgb.b += val;
		} else {
			int val = (rand & 1) ? 255 : 0;
			rgb.r = val;
			rgb.g = val;
			rgb.b = val;
		}
	} break;
	case Noise.C_NOISE: {
		if (value >= 0) {
			rgb.r += cast(int) rand % value;
			rgb.g += cast(int) rand % value;
			rgb.b += cast(int) rand % value;
		} else {
			rgb.r = (rand & 1) ? 255 : 0;
			rgb.g = (rand & 1) ? 255 : 0;
			rgb.b = (rand & 1) ? 255 : 0;
		}
	} break;
	default: assert (0);
	}
	round(rgb);
}
/// Noiseの効果を適用する。
ubyte[] noise(Noise f, int value, ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine) {
	if (f is Noise.NONE || value == 0 || data.length < 3 || depth < 24 || width < 1 || height < 1) {
		return data;
	}
	value %= 256;
	if (f is Noise.MOSAIC && value < 0) return data;
	uint nextSeed = 0;
	if (f is Noise.NOISE || f is Noise.C_NOISE) {
		nextSeed = rand;
		rand_seed(42, 0); // ノイズを固定する
	}
	scope (exit) {
		if (f is Noise.NOISE || f is Noise.C_NOISE) {
			rand_seed(nextSeed, 0);
		}
	}
	size_t bpp = bytesPerLine / width;
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			size_t i = y * width * bpp + x * bpp;
			if (f is Noise.MOSAIC) {
				// cwconv.dllの実装では平均値を求めず左上の値を取っているので
				// それに合わせる
				size_t j = (y - y % value) * width * bpp + (x - x % value) * bpp;
				data[i + 0] = data[j + 0];
				data[i + 1] = data[j + 1];
				data[i + 2] = data[j + 2];
			} else {
				auto fc = FC(data[i + 2], data[i + 1], data[i + 0]);
				noiseImpl(f, fc, value);
				data[i + 2] = fc.r;
				data[i + 1] = fc.g;
				data[i + 0] = fc.b;
			}
		}
	}
	return data;
}
/// 拡大・縮小した結果を返す。
/// スムージングは行わない。
ubyte[] resize(size_t newWidth, size_t newHeight,
		ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine,
		out size_t newBytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	if (width == newWidth && height == newHeight) {
		newBytesPerLine = bytesPerLine;
		return data;
	}
	real pw = cast(real) newWidth / width;
	real ph = cast(real) newHeight / height;
	size_t bpp = bytesPerLine / width;
	newBytesPerLine = bpp * newWidth;
	auto result = new ubyte[newHeight * newBytesPerLine];
	for (size_t y = 0; y < newHeight; y++) {
		size_t ty = cast(size_t) (y / ph);
		for (size_t x = 0; x < newWidth; x++) {
			size_t tx = cast(size_t) (x / pw);
			size_t ti = ty * width * bpp + tx * bpp;
			size_t i = y * newWidth * bpp + x * bpp;
			result[i + 2] = data[ti + 2];
			result[i + 1] = data[ti + 1];
			result[i + 0] = data[ti + 0];
		}
	}
	return result;
}
/// 滑らかに拡大・縮小した結果を返す。
ubyte[] smoothResize(size_t newWidth, size_t newHeight,
		ubyte[] data, size_t depth, size_t width, size_t height, size_t bytesPerLine,
		out size_t newBytesPerLine) {
	if (data.length < 3 || depth < 24 || width < 1 || height < 1) return data;
	if (width == newWidth && height == newHeight) {
		newBytesPerLine = bytesPerLine;
		return data;
	}
	// 双線形補完
	real pw = cast(real) newWidth / width;
	real ph = cast(real) newHeight / height;
	size_t bpp = bytesPerLine / width;
	newBytesPerLine = bpp * newWidth;
	auto result = new ubyte[newHeight * newBytesPerLine];
	for (size_t y = 0; y < newHeight; y++) {
		real ty = y / ph;
		int bby = cast(int) ty;
		real yb = ty % 1.0;
		auto ybm = 1.0 - yb;
		for (size_t x = 0; x < newWidth; x++) {
			real tx = x / pw;
			int bbx = cast(int) tx;
			real xb = tx % 1.0;
			auto xbm = 1.0 - xb;
			FC[2][2] a;
			for (int i = 0; i < 2; i++) {
				for (int j = 0; j < 2; j++) {
					int by = bby + i;
					int bx = bbx + j;
					if (by < 0) by = 0;
					if (height <= by) by = height - 1;
					if (bx < 0) bx = 0;
					if (width <= bx) bx = width - 1;
					size_t bi = by * width * bpp + bx * bpp;
					a[i][j].r = data[bi + 2];
					a[i][j].g = data[bi + 1];
					a[i][j].b = data[bi + 0];
				}
			}
			int r = cast(int) (xbm * (a[0][0].r * ybm + a[1][0].r * yb)
				+ xb * (a[0][1].r * ybm + a[1][1].r * yb));
			int g = cast(int) (xbm * (a[0][0].g * ybm + a[1][0].g * yb)
				+ xb * (a[0][1].g * ybm + a[1][1].g * yb));
			int b = cast(int) (xbm * (a[0][0].b * ybm + a[1][0].b * yb)
				+ xb * (a[0][1].b * ybm + a[1][1].b * yb));
			auto fc = FC(r, g, b);
			round(fc);
			size_t i = y * newWidth * bpp + x * bpp;
			result[i + 2] = fc.r;
			result[i + 1] = fc.g;
			result[i + 0] = fc.b;
		}
	}
	return result;
}
