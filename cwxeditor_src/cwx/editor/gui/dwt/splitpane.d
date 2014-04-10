
module cwx.editor.gui.dwt.splitpane;

import cwx.perf;

import std.math;

import org.eclipse.swt.all;

/// SashFormはウィンドウサイズ変更時に左側のサイズを固定する等の
/// 設定が出来ないので再実装。
class SplitPane : Composite {
	private Sash _sash = null;
	private FormData _sfd = null, _fd1 = null, _fd2 = null;
	private int[] _weights = [0, 0];
	private int _style;

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
	override int getStyle() {return _style;}
	int[] getWeights() { mixin(S_TRACE);
		return _weights.dup;
	}
	void setWeights(int[] weights) { mixin(S_TRACE);
		if (weights.length != 2) throw new Exception("SplitPane weights length");
		_weights = weights.dup;
		resize();
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
	private bool resize() { mixin(S_TRACE);
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
			int lw = cast(int) rndtol((ca.height - SASH_WIDTH) * (cast(real) l / full));
			_sfd.top = new FormAttachment(0, lw);
		} else { mixin(S_TRACE);
			if (ca.width == 0) return false;
			int lw = cast(int) rndtol((ca.width - SASH_WIDTH) * (cast(real) l / full));
			_sfd.left = new FormAttachment(0, lw);
		}
		relo();
		return true;
	}
	private void relo() { mixin(S_TRACE);
		if (!_sash) return;
		auto ca = getClientArea();
		if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
			int lw = _sfd.top.offset;
			if (lw < MIN) lw = MIN;
			if (lw + SASH_WIDTH >= ca.height - MIN) lw = ca.height - SASH_WIDTH - MIN;
			_sfd.top.offset = lw;
			_fd1.bottom.control = _sash;
			_fd2.top.control = _sash;
		} else { mixin(S_TRACE);
			int lw = _sfd.left.offset;
			if (lw < MIN) lw = MIN;
			if (lw + SASH_WIDTH >= ca.width - MIN) lw = ca.width - SASH_WIDTH - MIN;
			_sfd.left.offset = lw;
			_fd1.right.control = _sash;
			_fd2.left.control = _sash;
		}
		_sash.setLayoutData(_sfd);
		auto cs = getChildren();
		cs[0].setLayoutData(_fd1);
		cs[1].setLayoutData(_fd2);
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
			if (_first) { mixin(S_TRACE);
				if (getChildren().length < 2) { mixin(S_TRACE);
					return;
				}
				if (!_sash) initSash();
				_first = !resize();
				if (!isVisible() && getShell().getMaximized()) { mixin(S_TRACE);
					_maximizedAfter = true;
				}
			} else if (isVisible()) { mixin(S_TRACE);
				if (_maximizedAfter) { mixin(S_TRACE);
					resize();
					_maximizedAfter = false;
				} else { mixin(S_TRACE);
					relo();
				}
			} else { mixin(S_TRACE);
				resize();
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
	private static const SASH_WIDTH = 3;
	private static const MIN = 10;
	private class SSelL : Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			auto sb = _sash.getBounds();
			auto cb = getClientArea();
			if (getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
				int right = cb.height - sb.height - SashForm.DRAG_MINIMUM;
				if (right < e.y) e.y = right;
				if (SashForm.DRAG_MINIMUM > e.y) e.y = SashForm.DRAG_MINIMUM;
				if (e.y != sb.y)  { mixin(S_TRACE);
					_sfd.top = new FormAttachment(0, e.y);
					relo();
				}
			} else { mixin(S_TRACE);
				int right = cb.width - sb.width - SashForm.DRAG_MINIMUM;
				if (right < e.x) e.x = right;
				if (SashForm.DRAG_MINIMUM > e.x) e.x = SashForm.DRAG_MINIMUM;
				if (e.x != sb.x)  { mixin(S_TRACE);
					_sfd.left = new FormAttachment(0, e.x);
					relo();
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
