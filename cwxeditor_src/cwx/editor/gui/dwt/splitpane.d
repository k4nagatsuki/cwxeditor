
module cwx.editor.gui.dwt.splitpane;

import cwx.perf;
import cwx.utils : remove;

import std.math;

import org.eclipse.swt.all;

/// SashFormはウィンドウサイズ変更時に左側のサイズを固定する等の
/// 設定が出来ないので再実装。
class SplitPane : Composite {
	private Sash _sash = null;
	private SelectionListener[] _sls;
	private FormData _sfd = null, _fd1 = null, _fd2 = null;
	private int[] _weights = [0, 0];
	private int _style;
	private bool _canMinimized1 = false;
	private bool _canMinimized2 = false;
	private bool _min1 = false;
	private bool _min2 = false;
	private bool _resizeControl1 = false;
	private int _size = -1;

	this (Composite parent, int style) { mixin(S_TRACE);
		_style = style;
		style &= !SWT.VERTICAL;
		style &= !SWT.HORIZONTAL;
		super (parent, style);
		setLayout(new FormLayout);
		_fd1 = new FormData;
		_fd2 = new FormData;
		_sfd = new FormData;
		addListener(SWT.Resize, new ResizeL);
	}

	/// 左・上側ペインを最小化可能か。
	@property
	const
	bool canMinimized1() { return _canMinimized1; }
	@property
	void canMinimized1(bool value) { _canMinimized1 = value; }
	/// 右・下側ペインを最小化可能か。
	@property
	const
	bool canMinimized2() { return _canMinimized2; }
	@property
	void canMinimized2(bool value) { _canMinimized2 = value; }

	/// 全体のサイズ変更時にリサイズするのは左・上かペインか。
	@property
	const
	bool resizeControl1() { return _resizeControl1; }
	@property
	void resizeControl1(bool value) { _resizeControl1 = value; }

	override int getStyle() {return _style;}
	int[] getWeights() { mixin(S_TRACE);
		return _weights.dup;
	}

	void addSelectionListener(SelectionListener l) { mixin(S_TRACE);
		if (_sash) { mixin(S_TRACE);
			_sash.addSelectionListener(l);
		}
		_sls ~= l;
	}
	void removeSelectionListener(SelectionListener l) { mixin(S_TRACE);
		if (_sash) { mixin(S_TRACE);
			_sash.removeSelectionListener(l);
		}
		_sls.remove(l);
	}
	void notifySelectionListeners(Event base) { mixin(S_TRACE);
		auto se = new SelectionEvent(base);
		se.widget = _sash;
		se.time = base.time;
		se.stateMask = base.stateMask;
		se.doit = true;
		foreach (sl; _sls) sl.widgetSelected(se);
	}

	void setWeights(int[] weights) { mixin(S_TRACE);
		if (weights.length != 2) throw new Exception("SplitPane weights length");
		_weights = weights.dup;
		_min1 = _weights[0] <= 0;
		_min2 = _weights[1] <= 0;
		resize(true);
	}
	private int[] computeWeights() { mixin(S_TRACE);
		auto cs = getChildren();
		if (cs.length >= 2) { mixin(S_TRACE);
			int l = cs[0].computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
			int r = cs[0].computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
			return [l, r];
		}
		return [1, 1];
	}
	private bool resize(bool updateMin) { mixin(S_TRACE);
		assert (_weights);
		assert (_weights.length == 2u);
		if (_weights[0u] <= 0 || _weights[1u] <= 0) { mixin(S_TRACE);
			_weights = computeWeights();
		}
		int l = _weights[0u];
		int r = _weights[1u];
		int full = l + r;
		auto ca = getClientArea();
		if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			if (ca.height == 0) return false;
			int lw = cast(int)rndtol((ca.height - SASH_WIDTH) * (cast(real)l / full));
			_sfd.top = new FormAttachment(0, lw);
		} else { mixin(S_TRACE);
			if (ca.width == 0) return false;
			int lw = cast(int)rndtol((ca.width - SASH_WIDTH) * (cast(real)l / full));
			_sfd.left = new FormAttachment(0, lw);
		}
		relo(updateMin, false);
		return true;
	}
	private void relo(bool updateMin, bool resize) { mixin(S_TRACE);
		if (!_sash) return;
		auto ca = getClientArea();
		if (updateMin) { mixin(S_TRACE);
			_min1 = false;
			_min2 = false;
		}
		if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			int lw = _sfd.top.offset;
			if (resizeControl1 && resize && -1 != _size) lw += ca.height - _size;
			if (_min1 || lw < MIN) { mixin(S_TRACE);
				if (updateMin && canMinimized1) _min1 = true;
				lw = _min1 ? 0 : MIN;
			}
			if (_min2 || lw + SASH_WIDTH >= ca.height - MIN) { mixin(S_TRACE);
				if (updateMin && canMinimized2) _min2 = true;
				lw = ca.height - SASH_WIDTH - (_min2 ? 0 : MIN);
			}
			_sfd.top.offset = lw;
			_fd1.bottom.control = _sash;
			_fd2.top.control = _sash;
			_size = ca.height;
		} else { mixin(S_TRACE);
			int lw = _sfd.left.offset;
			if (resizeControl1 && resize && -1 != _size) lw += ca.width - _size;
			if (_min1 || lw < MIN) { mixin(S_TRACE);
				if (updateMin && canMinimized1) _min1 = true;
				lw = _min1 ? 0 : MIN;
			}
			if (_min2 || lw + SASH_WIDTH >= ca.width - MIN) { mixin(S_TRACE);
				if (updateMin && canMinimized2) _min2 = true;
				lw = ca.width - SASH_WIDTH - (_min2 ? 0 : MIN);
			}
			_sfd.left.offset = lw;
			_fd1.right.control = _sash;
			_fd2.left.control = _sash;
			_size = ca.width;
		}
		_sash.setLayoutData(_sfd);
		auto cs = getChildren();
		cs[0].setLayoutData(_fd1);
		cs[0].setVisible(!_min1);
		cs[1].setLayoutData(_fd2);
		cs[1].setVisible(!_min2);
		if (_min1) _weights[0] = 0;
		if (_min2) _weights[1] = 0;
		layout(true);
		refreshWeights();
	}
	private class ResizeL : Listener {
		private bool _first = true;
		// Shell.setMaximized()で最大化を設定した直後には
		// サイズ変更イベントが発生せず、Shell.open()によって
		// Shell.isVisible()が有効の状態でイベントが発生してしまう。
		private bool _maximizedAfter = false;
		override void handleEvent(Event e) { mixin(S_TRACE);
			setRedraw(false);
			scope (exit) setRedraw(true);
			if (_first) { mixin(S_TRACE);
				if (getChildren().length < 2) { mixin(S_TRACE);
					return;
				}
				if (!_sash) initSash();
				_first = !resize(false);
				if (!isVisible() && getShell().getMaximized()) { mixin(S_TRACE);
					_maximizedAfter = true;
				}
			} else if (isVisible()) { mixin(S_TRACE);
				if (_maximizedAfter) { mixin(S_TRACE);
					resize(false);
					_maximizedAfter = false;
				} else { mixin(S_TRACE);
					relo(false, true);
				}
			} else { mixin(S_TRACE);
				resize(false);
				if (!isVisible() && getShell().getMaximized()) { mixin(S_TRACE);
					_maximizedAfter = true;
				}
			}
		}
	}
	private void refreshWeights() { mixin(S_TRACE);
		auto cs = getChildren();
		if (cs[0] && cs[1]) { mixin(S_TRACE);
			auto ca = getClientArea();
			if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
				int l = _sfd.top.offset - ca.y;
				_weights = [l, ca.height - l - SASH_WIDTH];
			} else { mixin(S_TRACE);
				int l = _sfd.left.offset - ca.x;
				_weights = [l, ca.width - l - SASH_WIDTH];
			}
		}
	}
	private void initSash() { mixin(S_TRACE);
		_sash = new Sash(this, (getStyle() & SWT.HORIZONTAL) ? SWT.VERTICAL : SWT.HORIZONTAL);
		foreach (sl; _sls) _sash.addSelectionListener(sl);
		if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			_fd1.left = new FormAttachment(0, 0);
			_fd1.right = new FormAttachment(100, 0);
			_fd1.top = new FormAttachment(0, 0);
			_fd1.bottom = new FormAttachment(_sash, 0);
		} else { mixin(S_TRACE);
			_fd1.left = new FormAttachment(0, 0);
			_fd1.right = new FormAttachment(_sash, 0);
			_fd1.top = new FormAttachment(0, 0);
			_fd1.bottom = new FormAttachment(100, 0);
		}
		if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			_sfd.left = new FormAttachment(0, 0);
			_sfd.top = new FormAttachment(50, 0);
			_sfd.right = new FormAttachment(100, 0);
		} else { mixin(S_TRACE);
			_sfd.left = new FormAttachment(50, 0);
			_sfd.top = new FormAttachment(0, 0);
			_sfd.bottom = new FormAttachment(100, 0);
		}
		if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			_fd2.left = new FormAttachment(0, 0);
			_fd2.right = new FormAttachment(100, 0);
			_fd2.top = new FormAttachment(_sash, 0);
			_fd2.bottom = new FormAttachment(100, 0);
		} else { mixin(S_TRACE);
			_fd2.left = new FormAttachment(_sash, 0);
			_fd2.right = new FormAttachment(100, 0);
			_fd2.top = new FormAttachment(0, 0);
			_fd2.bottom = new FormAttachment(100, 0);
		}
		_sfd.width = SASH_WIDTH;
		_sash.setLayoutData(_sfd);
		_sash.addListener(SWT.Selection, new SSelL);
	}
	private static immutable SASH_WIDTH = 5;
	private static immutable MIN = 10;
	private class SSelL : Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			auto sb = _sash.getBounds();
			auto cb = getClientArea();
			auto minSize1 = canMinimized1 ? 0 : MIN;
			auto minSize2 = canMinimized2 ? 0 : MIN;
			if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
				int right = cb.height - sb.height - minSize2;
				if (right < e.y) e.y = right;
				if (minSize1 > e.y) e.y = minSize1;
				if (e.y != sb.y)  { mixin(S_TRACE);
					_sfd.top = new FormAttachment(0, e.y);
					relo(true, false);
				}
			} else { mixin(S_TRACE);
				int right = cb.width - sb.width - minSize2;
				if (right < e.x) e.x = right;
				if (minSize1 > e.x) e.x = minSize1;
				if (e.x != sb.x)  { mixin(S_TRACE);
					_sfd.left = new FormAttachment(0, e.x);
					relo(true, false);
				}
			}
		}
	}
	override Point computeSize(int wHint, int hHint) { mixin(S_TRACE);
		return computeSize(wHint, hHint, true);
	}
	override Point computeSize(int wHint, int hHint, bool change) { mixin(S_TRACE);
		Point[] size;
		foreach (c; getChildren()) { mixin(S_TRACE);
			if (!(cast(Sash) c)) { mixin(S_TRACE);
				size ~= c.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			}
		}
		int x = 0, y = 0;
		if (wHint != SWT.DEFAULT) { mixin(S_TRACE);
			x = wHint;
		} else if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			foreach (s; size) { mixin(S_TRACE);
				if (x < s.x) x = s.x;
			}
		} else { mixin(S_TRACE);
			foreach (s; size) { mixin(S_TRACE);
				x += s.x;
			}
			x += SASH_WIDTH;
		}
		if (hHint != SWT.DEFAULT) { mixin(S_TRACE);
			y = hHint;
		} else if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			foreach (s; size) { mixin(S_TRACE);
				y += s.y;
			}
			y += SASH_WIDTH;
		} else { mixin(S_TRACE);
			foreach (s; size) { mixin(S_TRACE);
				if (y < s.y) y = s.y;
			}
		}
		scope rect = computeTrim(SWT.DEFAULT, SWT.DEFAULT, x, y);
		return new Point(rect.width, rect.height);
	}
}
