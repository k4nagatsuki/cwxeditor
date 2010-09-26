
module cwx.editor.gui.dwt.splitpane;

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
	private Control _c1 = null, _c2 = null;
	private Sash _sash = null;
	private FormData _sfd = null;
	private int[] _weights = [1, 1];
	private Listener _resizeL = null;
	private int _style;

	this (Composite parent, int style) {
		_style = style;
		style &= !DWT.VERTICAL;
		style &= !DWT.HORIZONTAL;
		super (parent, style);
		setLayout(new FormLayout);
		_resizeL = new ResizeL;
		addListener(DWT.Resize, _resizeL);
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
			int lw = cast(int) (ca.height * (cast(real) l / full));
			if (lw < 0) lw = 0;
			_sfd.top = new FormAttachment(0, lw);
		} else {
			if (ca.width == 0) return false;
			int lw = cast(int) (ca.width * (cast(real) l / full));
			if (lw < 0) lw = 0;
			_sfd.left = new FormAttachment(0, lw);
		}
		layout(true);
		refreshWeights;
		return true;
	}
	private class ResizeL : Listener {
		private bool _first = true;
		override void handleEvent(Event e) {
			if (_first) {
				_first = !resize;
			} else {
				layout(true);
				refreshWeights;
			}
		}
	}
	private void refreshWeights() {
		if (_c1 && _c2) {
			if (getStyle & DWT.VERTICAL) {
				_weights = [_c1.getSize.y, _c2.getSize.y];
			} else {
				_weights = [_c1.getSize.x, _c2.getSize.x];
			}
		}
	}
	Control getControl1() {return _c1;}
	void setControl1(Control c) {
		if (_c1) throw new DWTException("SplitPane control 1");
		_c1 = c;
		_sash = new Sash(this, (getStyle & DWT.HORIZONTAL) ? DWT.VERTICAL : DWT.HORIZONTAL);
		auto c1fd = new FormData;
		if (getStyle & DWT.VERTICAL) {
			c1fd.left = new FormAttachment(0, 0);
			c1fd.right = new FormAttachment(100, 0);
			c1fd.top = new FormAttachment(0, 0);
			c1fd.bottom = new FormAttachment(_sash, 0);
		} else {
			c1fd.left = new FormAttachment(0, 0);
			c1fd.right = new FormAttachment(_sash, 0);
			c1fd.top = new FormAttachment(0, 0);
			c1fd.bottom = new FormAttachment(100, 0);
		}
		_c1.setLayoutData = c1fd;
		_sfd = new FormData;
		if (getStyle & DWT.VERTICAL) {
			_sfd.left = new FormAttachment(0, 0);
			_sfd.top = new FormAttachment(50, 0);
			_sfd.right = new FormAttachment(100, 0);
		} else {
			_sfd.left = new FormAttachment(50, 0);
			_sfd.top = new FormAttachment(0, 0);
			_sfd.bottom = new FormAttachment(100, 0);
		}
		_sfd.width = SASH_WIDTH;
		_sash.setLayoutData = _sfd;
		_sash.addListener(DWT.Selection, new SSelL);
	}
	private static const SASH_WIDTH = 3;
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
					layout(true);
					refreshWeights;
				}
			} else {
				int right = cb.width - sb.width - SashForm.DRAG_MINIMUM;
				if (right < e.x) e.x = right;
				if (SashForm.DRAG_MINIMUM > e.x) e.x = SashForm.DRAG_MINIMUM;
				if (e.x != sb.x)  {
					_sfd.left = new FormAttachment(0, e.x);
					layout(true);
					refreshWeights;
				}
			}
		}
	}
	Control getControl2() {return _c2;}
	void setControl2(Control c) {
		if (_c2) throw new DWTException("SplitPane control 2");
		_c2 = c;
		auto fd = new FormData;
		if (getStyle & DWT.VERTICAL) {
			fd.left = new FormAttachment(0, 0);
			fd.right = new FormAttachment(100, 0);
			fd.top = new FormAttachment(_sash, 0);
			fd.bottom = new FormAttachment(100, 0);
		} else {
			fd.left = new FormAttachment(_sash, 0);
			fd.right = new FormAttachment(100, 0);
			fd.top = new FormAttachment(0, 0);
			fd.bottom = new FormAttachment(100, 0);
		}
		_c2.setLayoutData = fd;
	}
}
