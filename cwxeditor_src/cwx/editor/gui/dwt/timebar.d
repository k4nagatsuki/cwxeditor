
module cwx.editor.gui.dwt.timebar;

import cwx.utils;

import cwx.editor.gui.dwt.dutils;

import std.algorithm;
import std.datetime;
import std.string;

import org.eclipse.swt.all;

/// 音声の再生時間などを表示する。
class TimeBar : Canvas {
	void delegate()[] updateCurrentEvent;

	private Image _warningIcon = null;
	private string _warning = "";

	private Duration _dur = Duration.min;
	private Duration _cur = Duration.min;

	private Duration _setCur = Duration.min;
	private bool _moving = false;
	private bool _keyMoving = false;

	this (Composite parent, int style) { mixin(S_TRACE);
		super (parent, style | SWT.DOUBLE_BUFFERED);
		.listener(this, SWT.Paint, &onPaint);
		.listener(this, SWT.MouseUp, &onMouseUp);
		.listener(this, SWT.MouseDown, &onMouseDown);
		.listener(this, SWT.MouseMove, &onMouseMove);
		.listener(this, SWT.KeyDown, &onKeyDown);
		.listener(this, SWT.Traverse, (Event e) { mixin(S_TRACE);
			switch (e.detail) {
			case SWT.TRAVERSE_ARROW_NEXT, SWT.TRAVERSE_ARROW_PREVIOUS:
				e.doit = false;
				break;
			default:
				e.doit = true;
			}
		});
		.listener(this, SWT.FocusIn, &redraw);
		.listener(this, SWT.FocusOut, &redraw);
	}

	private void onKeyDown(Event e) { mixin(S_TRACE);
		if (e.keyCode == SWT.ARROW_LEFT) { mixin(S_TRACE);
			if (!_keyMoving) _setCur = current;
			_keyMoving = true;
			_moving = false;
			_setCur -= dur!"seconds"(1);
			_setCur = .max(dur!"msecs"(0), _setCur);
			redraw();
		} else if (e.keyCode == SWT.ARROW_RIGHT) { mixin(S_TRACE);
			if (!_keyMoving) _setCur = current;
			_keyMoving = true;
			_moving = false;
			_setCur += dur!"seconds"(1);
			_setCur = .min(_setCur, length);
			redraw();
		} else if ((e.keyCode == SWT.ARROW_DOWN || e.keyCode == SWT.ARROW_UP || e.character == SWT.CR || e.character == ' ') && _keyMoving) { mixin(S_TRACE);
			current = _setCur;
			_keyMoving = false;
			foreach (dlg; updateCurrentEvent) dlg();
		} else if (e.character == SWT.ESC || e.character == SWT.BS) { mixin(S_TRACE);
			_keyMoving = false;
			_moving = false;
			redraw();
		}
	}

	private void onMouseDown(Event e) { mixin(S_TRACE);
		if (e.button == 1) { mixin(S_TRACE);
			setFocus();
			_moving = true;
			_keyMoving = false;
			onMouseMove(e);
		} else if (e.button == 3 && _moving) { mixin(S_TRACE);
			_moving = false;
			redraw();
		}
	}
	private void onMouseUp(Event e) { mixin(S_TRACE);
		if (e.button == 1 && _moving) { mixin(S_TRACE);
			current = .max(dur!"msecs"(0), .min(_setCur, length));
			_moving = false;
			foreach (dlg; updateCurrentEvent) dlg();
		}
	}
	private void onMouseMove(Event e) { mixin(S_TRACE);
		if (!_moving) return;
		auto w = getClientArea().width;
		_setCur = dur!"seconds"(cast(int)((cast(real)e.x / w) * length.total!"seconds"));
		redraw();
	}

	void setWarning(Image img, string msg) { mixin(S_TRACE);
		_warningIcon = img;
		_warning = msg;
		redraw();
	}
	void clearWarning() { mixin(S_TRACE);
		_warningIcon = null;
		_warning = "";
		redraw();
	}
	@property
	void length(Duration dur) { mixin(S_TRACE);
		_dur = dur;
		redraw();
	}
	@property
	Duration length() { return _dur; }

	@property
	void current(Duration cur) { mixin(S_TRACE);
		_cur = cur;
		redraw();
	}
	@property
	Duration current() { return _cur; }

	override
	Point computeSize(int wHint, int hHint, bool change) { mixin(S_TRACE);
		return new Point(100.ppis, 28.ppis);
	}

	private void onPaint(Event e) { mixin(S_TRACE);
		auto ca = getClientArea();
		auto total = length.total!"seconds";
		e.gc.fillRectangle(ca);
		e.gc.drawRectangle(ca.x, ca.y, ca.width - 1, ca.height - 1);
		for (auto i = 0; i < total; i += 5) { mixin(S_TRACE);
			auto x = cast(int)((cast(real)ca.width / total) * i);
			if (i % 30 == 0) { mixin(S_TRACE);
				e.gc.drawLine(x, ca.height, x, ca.height - 8);
			} else { mixin(S_TRACE);
				e.gc.drawLine(x, ca.height, x, ca.height - 5);
			}
		}

		if (_warning != "") { mixin(S_TRACE);
			auto te = e.gc.textExtent(_warning);
			auto ib = _warningIcon.getBounds();
			auto iw = ib.width + 2;
			auto ih = ib.height;
			if (_warningIcon) { mixin(S_TRACE);
				te.x += iw;
			}
			auto sx = (ca.width - te.x) / 2;
			if (_warningIcon) { mixin(S_TRACE);
				auto iy = (ca.height - ih) / 2;
				e.gc.drawImage(_warningIcon, sx, iy);
				sx += iw;
			}
			auto sy = (ca.height - te.y) / 2;
			e.gc.drawText(_warning, sx, sy, true);
		} else { mixin(S_TRACE);
			auto cur = current.total!"seconds";
			auto x = cast(int)((cast(real)ca.width / total) * cur);
			e.gc.drawLine(x, 0, x, ca.height);

			if (_moving || _keyMoving) { mixin(S_TRACE);
				cur = _setCur.total!"seconds";
				x = cast(int)((cast(real)ca.width / total) * cur);
				e.gc.setLineStyle(SWT.LINE_DOT);
				e.gc.drawLine(x, 0, x, ca.height);
			}

			int hour, minute, second;
			current.split!("hours", "minutes", "seconds")(hour, minute, second);
			int lHour, lMinute, lSecond;
			length.split!("hours", "minutes", "seconds")(lHour, lMinute, lSecond);
			string s;
			if (0 < lHour) { mixin(S_TRACE);
				s = std.string.format("%02d:%02d:%02d / %02d:%02d:%02d", hour, minute, second, lHour, lMinute, lSecond);
			} else { mixin(S_TRACE);
				s = std.string.format("%02d:%02d / %02d:%02d", minute, second, lMinute, lSecond);
			}
			auto te = e.gc.textExtent(s);
			auto sx = (ca.width - te.x) / 2;
			auto sy = (ca.height - 5 - te.y) / 2;
			e.gc.drawText(s, sx, sy, true);
		}
		if (isFocusControl()) { mixin(S_TRACE);
			e.gc.drawFocus(2, 2, ca.width - 4, ca.height - 4);
		}
	}
}
