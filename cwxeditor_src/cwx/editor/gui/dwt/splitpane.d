
module cwx.editor.gui.dwt.splitpane;

import std.math;

import dwt.DWT;
import dwt.DWTException;
import dwt.widgets.Sash;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.Listener;
import dwt.widgets.Event;
import dwt.layout.FormAttachment;
import dwt.layout.FormLayout;
import dwt.layout.FormData;
import dwt.custom.SashForm;
import dwt.graphics.Rectangle;

import cwx.utils;

/// SashFormはウィンドウサイズ変更時に左側のサイズを固定する等の
/// 設定が出来ないので再実装。
class SplitPane : Composite {
	private Sash _sash = null;
	private FormData _sfd = null, _fd1 = null, _fd2 = null;
	private int[] _weights = [1, 1];
	private int _style;

	this (Composite parent, int style) {
		_style = style;
		style &= !DWT.VERTICAL;
		style &= !DWT.HORIZONTAL;
		super (parent, style);
		setLayout(new FormLayout);
		_fd1 = new FormData;
		_fd2 = new FormData;
		_sfd = new FormData;
		addListener(DWT.Resize, new ResizeL);
	}
	override int getStyle() {return _style;}
	int[] getWeights() {
		return _weights.dup;
	}
	void setWeights(int[] weights) {
		if (weights.length != 2) throw new Exception("SplitPane weights length");
		if (weights[0u] <= 0 || weights[1u] <= 0) {
			_weights = [1, 1];
		} else {
			_weights = [weights[0u], weights[1u]];
		}
		resize;
	}
	private bool resize() {
		assert (_weights);
		assert (_weights.length == 2u);
		int l = _weights[0u];
		int r = _weights[1u];
		int full = l + r;
		auto ca = getClientArea;
		if (getStyle & DWT.VERTICAL) {
			if (ca.height == 0) return false;
			int lw = cast(int) rndtol((ca.height - SASH_WIDTH) * (cast(real) l / full));
			_sfd.top = new FormAttachment(0, lw);
		} else {
			if (ca.width == 0) return false;
			int lw = cast(int) rndtol((ca.width - SASH_WIDTH) * (cast(real) l / full));
			_sfd.left = new FormAttachment(0, lw);
		}
		relo;
		return true;
	}
	private void relo() {
		auto ca = getClientArea;
		if (getStyle & DWT.VERTICAL) {
			int lw = _sfd.top.offset;
			if (lw < MIN) lw = MIN;
			if (lw + SASH_WIDTH >= ca.height - MIN) lw = ca.height - SASH_WIDTH - MIN;
			_sfd.top.offset = lw;
			_fd1.bottom.control = _sash;
			_fd2.top.control = _sash;
		} else {
			int lw = _sfd.left.offset;
			if (lw < MIN) lw = MIN;
			if (lw + SASH_WIDTH >= ca.width - MIN) lw = ca.width - SASH_WIDTH - MIN;
			_sfd.left.offset = lw;
			_fd1.right.control = _sash;
			_fd2.left.control = _sash;
		}
		_sash.setLayoutData = _sfd;
		auto cs = getChildren;
		cs[0].setLayoutData = _fd1;
		cs[1].setLayoutData = _fd2;
		layout(true);
		refreshWeights;
	}
	private class ResizeL : Listener {
		private bool _first = true;
		override void handleEvent(Event e) {
			if (_first) {
				if (getChildren.length < 2) {
					return;
				}
				if (!_sash) initSash;
				_first = !resize;
			} else if (isVisible) {
				relo;
			} else {
				resize;
			}
		}
	}
	private void refreshWeights() {
		auto cs = getChildren;
		if (cs[0] && cs[1]) {
			auto ca = getClientArea;
			if (getStyle & DWT.VERTICAL) {
				int l = _sfd.top.offset - ca.y;
				_weights = [l, ca.height - l - SASH_WIDTH];
			} else {
				int l = _sfd.left.offset - ca.x;
				_weights = [l, ca.width - l - SASH_WIDTH];
			}
		}
	}
	private void initSash() {
		_sash = new Sash(this, (getStyle & DWT.HORIZONTAL) ? DWT.VERTICAL : DWT.HORIZONTAL);
		if (getStyle & DWT.VERTICAL) {
			_fd1.left = new FormAttachment(0, 0);
			_fd1.right = new FormAttachment(100, 0);
			_fd1.top = new FormAttachment(0, 0);
			_fd1.bottom = new FormAttachment(_sash, 0);
		} else {
			_fd1.left = new FormAttachment(0, 0);
			_fd1.right = new FormAttachment(_sash, 0);
			_fd1.top = new FormAttachment(0, 0);
			_fd1.bottom = new FormAttachment(100, 0);
		}
		if (getStyle & DWT.VERTICAL) {
			_sfd.left = new FormAttachment(0, 0);
			_sfd.top = new FormAttachment(50, 0);
			_sfd.right = new FormAttachment(100, 0);
		} else {
			_sfd.left = new FormAttachment(50, 0);
			_sfd.top = new FormAttachment(0, 0);
			_sfd.bottom = new FormAttachment(100, 0);
		}
		if (getStyle & DWT.VERTICAL) {
			_fd2.left = new FormAttachment(0, 0);
			_fd2.right = new FormAttachment(100, 0);
			_fd2.top = new FormAttachment(_sash, 0);
			_fd2.bottom = new FormAttachment(100, 0);
		} else {
			_fd2.left = new FormAttachment(_sash, 0);
			_fd2.right = new FormAttachment(100, 0);
			_fd2.top = new FormAttachment(0, 0);
			_fd2.bottom = new FormAttachment(100, 0);
		}
		_sfd.width = SASH_WIDTH;
		_sash.setLayoutData = _sfd;
		_sash.addListener(DWT.Selection, new SSelL);
	}
	private static const SASH_WIDTH = 3;
	private static const MIN = 10;
	private class SSelL : Listener {
		override void handleEvent(Event e) {
			auto sb = _sash.getBounds;
			auto cb = getClientArea;
			if (getStyle & DWT.VERTICAL) {
				int right = cb.height - sb.height - SashForm.DRAG_MINIMUM;
				if (right < e.y) e.y = right;
				if (SashForm.DRAG_MINIMUM > e.y) e.y = SashForm.DRAG_MINIMUM;
				if (e.y != sb.y)  {
					_sfd.top = new FormAttachment(0, e.y);
					relo;
				}
			} else {
				int right = cb.width - sb.width - SashForm.DRAG_MINIMUM;
				if (right < e.x) e.x = right;
				if (SashForm.DRAG_MINIMUM > e.x) e.x = SashForm.DRAG_MINIMUM;
				if (e.x != sb.x)  {
					_sfd.left = new FormAttachment(0, e.x);
					relo;
				}
			}
		}
	}
	override Point computeSize(int wHint, int hHint) {
		return computeSize(wHint, hHint, true);
	}
	override Point computeSize(int wHint, int hHint, bool change) {
		Point[] size;
		foreach (c; getChildren) {
			if (!(cast(Sash) c)) {
				size ~= c.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			}
		}
		int x = 0, y = 0;
		if (wHint != DWT.DEFAULT) {
			x = wHint;
		} else if (getStyle & DWT.VERTICAL) {
			foreach (s; size) {
				if (x < s.x) x = s.x;
			}
		} else {
			foreach (s; size) {
				x += s.x;
			}
			x += SASH_WIDTH;
		}
		if (hHint != DWT.DEFAULT) {
			y = hHint;
		} else if (getStyle & DWT.VERTICAL) {
			foreach (s; size) {
				y += s.y;
			}
			y += SASH_WIDTH;
		} else {
			foreach (s; size) {
				if (y < s.y) y = s.y;
			}
		}
		scope rect = computeTrim(DWT.DEFAULT, DWT.DEFAULT, x, y);
		return new Point(rect.width, rect.height);
	}
}
