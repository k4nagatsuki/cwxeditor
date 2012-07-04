
module cwx.editor.gui.dwt.centerlayout;

import cwx.utils;
import cwx.props;
import cwx.structs;

import org.eclipse.swt.all;

public:

class CenterLayoutData {
	bool fillVertical = false;
	bool fillHorizontal = false;
	this (bool fillVertical, bool fillHorizontal) {
		this.fillVertical = fillVertical;
		this.fillHorizontal = fillHorizontal;
	}
}
class Insets {
	int n, e, s, w;
	static Insets opCall(int n, int e, int s, int w) {
		auto r = new Insets;
		r.n = n;
		r.e = e;
		r.s = s;
		r.w = w;
		return r;
	}
	static Insets opCall(CInsets i) {
		auto r = new Insets;
		r.n = i.n;
		r.e = i.e;
		r.s = i.s;
		r.w = i.w;
		return r;
	}
}

class CenterLayout : Layout {
public:
	this (int style = SWT.VERTICAL | SWT.HORIZONTAL, int margin = 5) {
		_margin = margin;
		_style = style;
	}
	bool fillVertical = false;
	bool fillHorizontal = false;
	@property
	int margin() {return _margin;}
private:
	int _margin;
	int _style;
	Point childSize(Control c) {
		if (c.getLayoutData() !is null && cast(Point) c.getLayoutData()) {
			return cast(Point) c.getLayoutData();
		} else {
			return c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		}
	}
protected override:
	Point computeSize(Composite composite, int wHint, int hHint, bool flushCache) {
		if (wHint is SWT.DEFAULT) wHint = 0;
		if (hHint is SWT.DEFAULT) hHint = 0;
		foreach (c; composite.getChildren()) {
			auto p = childSize(c);
			if (wHint < p.x) wHint = p.x;
			if (hHint < p.y) hHint = p.y;
		}
		return new Point(wHint + _margin * 2, hHint + _margin * 2);
	}
	void layout(Composite composite, bool flushCache) {
		auto s = composite.getClientArea();
		foreach (c; composite.getChildren()) {
			int x = int.min;
			int y = int.min;
			int w = int.min;
			int h = int.min;
			if (cast(Insets) c.getLayoutData()) {
				auto insets = cast(Insets) c.getLayoutData();
				if (insets.e != SWT.DEFAULT && insets.w != SWT.DEFAULT) {
					w = insets.e - insets.w;
				} else if (insets.e != SWT.DEFAULT || insets.w != SWT.DEFAULT) {
					w = c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
				}
				if (insets.n != SWT.DEFAULT && insets.s != SWT.DEFAULT) {
					h = insets.s - insets.n;
				} else if (insets.s != SWT.DEFAULT || insets.n != SWT.DEFAULT) {
					h = c.computeSize(SWT.DEFAULT, SWT.DEFAULT).y;
				}
				if (w > int.min) {
					x = insets.w != SWT.DEFAULT ? insets.w : s.x + s.width - w - insets.e;
				}
				if (h > int.min) {
					y = insets.n != SWT.DEFAULT ? insets.n : s.y + s.height - h - insets.s;
				}
			}
			if (cast(Rectangle) c.getLayoutData()) {
				auto rect = cast(Rectangle) c.getLayoutData();
				x = rect.x;
				y = rect.y;
				w = rect.width;
				h = rect.height;
			}
			auto cld = cast(CenterLayoutData) c.getLayoutData();
			auto p = childSize(c);
			if (fillHorizontal || (cld && cld.fillHorizontal)) {
				if (x == int.min) x = _margin + s.x;
				if (w == int.min) w = s.width - _margin * 2;
			} else {
				if (x == int.min) {
					x = (SWT.HORIZONTAL & _style) != 0 ? (s.width - _margin * 2 - p.x) / 2 : 0;
					x += _margin + s.x;
				}
				if (w == int.min) w = p.x;
			}
			if (fillVertical || (cld && cld.fillVertical)) {
				if (y == int.min) y = _margin + s.y;
				if (h == int.min) h = s.height - _margin * 2;
			} else {
				if (y == int.min) {
					y = (SWT.VERTICAL & _style) != 0 ? (s.height - _margin * 2 - p.y) / 2 : 0;
					y += _margin + s.y;
				}
				if (h == int.min) h = p.y;
			}
			c.setBounds(x, y, w, h);
		}
	}
}
