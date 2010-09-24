
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

import cwx.utils;

/// SashFormはウィンドウサイズ変更時に左側のサイズを固定する等の
/// 設定が出来ないので再実装。
class SplitPane : Composite {
	private Control _c1 = null, _c2 = null;
	private Sash _sash = null;
	private FormData _sfd = null;
	private int[] _weights = null;
	private Listener _resizeL = null;

	this (Composite parent, int style) {
		style &= !DWT.VERTICAL;
		style &= !DWT.HORIZONTAL;
		super (parent, style);
		setLayout(new FormLayout);
	}
	private int[] _lastWeight = [1, 1];
	int[] getWeights() {
		int lw = _c1.getSize.x;
		int rw = _c2.getSize.x;
		if (lw > 0 && rw > 0) {
			_lastWeight = [lw, rw];
		}
		return _lastWeight;
	}
	void setWeights(int[2u] weights) {
		if (weights[0u] <= 0 || weights[1u] <= 0) {
			_weights = [1, 1];
		} else {
			_weights = [weights[0u], weights[1u]];
			_lastWeight = _weights;
		}
		_resizeL = new class Listener {
			override void handleEvent(Event e) {
				if (isVisible) {
					removeListener(DWT.Resize, _resizeL);
					return;
				}
				assert (_weights);
				assert (_weights.length == 2u);
				int l = _weights[0u];
				int r = _weights[1u];
				int full = l + r;
				int lw = cast(int) (getClientArea.width * (cast(real) l / full));
				_sfd.left = new FormAttachment(0, lw);
				layout;
			}
		};
		addListener(DWT.Resize, _resizeL);
	}
	void setControl1(Control c) {
		if (_c1) throw new DWTException("SplitPane control 1");
		_c1 = c;
		_sash = new Sash(this, DWT.VERTICAL);
		auto c1fd = new FormData;
		c1fd.left = new FormAttachment(0, 0);
		c1fd.right = new FormAttachment(_sash, 0);
		c1fd.top = new FormAttachment(0, 0);
		c1fd.bottom = new FormAttachment(100, 0);
		_c1.setLayoutData = c1fd;
		_sfd = new FormData;
		_sfd.left = new FormAttachment(50, 0);
		_sfd.top = new FormAttachment(0, 0);
		_sfd.bottom = new FormAttachment(100, 0);
		_sfd.width = 3;
		_sash.setLayoutData (_sfd);
		_sash.addListener(DWT.Selection, new class Listener {
			override void handleEvent(Event e) {
				removeListener(DWT.Resize, _resizeL);
				auto sb = _sash.getBounds;
				auto cb = getClientArea;
				int right = cb.width - sb.width - SashForm.DRAG_MINIMUM;
				if (right < e.x) e.x = right;
				if (SashForm.DRAG_MINIMUM > e.x) e.x = SashForm.DRAG_MINIMUM;
				if (e.x != sb.x)  {
					_sfd.left = new FormAttachment(0, e.x);
					layout;
				}
			}
		});
	}
	void setControl2(Control c) {
		if (_c2) throw new DWTException("SplitPane control 2");
		_c2 = c;
		auto fd = new FormData;
		fd.left = new FormAttachment(_sash, 0);
		fd.right = new FormAttachment(100, 0);
		fd.top = new FormAttachment(0, 0);
		fd.bottom = new FormAttachment(100, 0);
		_c2.setLayoutData = fd;
	}
}
