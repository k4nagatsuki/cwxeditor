
module cwx.editor.gui.dwt.customtext;

import cwx.utils;

import std.compat;
import std.utf;
import std.string;

import dwt.DWT;
import dwt.DWTException;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.Display;
import dwt.widgets.Text;
import dwt.widgets.Item;
import dwt.widgets.Widget;
import dwt.widgets.Listener;
import dwt.widgets.Event;
import dwt.graphics.Image;
import dwt.graphics.Font;
import dwt.graphics.FontData;
import dwt.graphics.GC;
import dwt.graphics.Point;
import dwt.dwthelper.utils;

/// 折り返しを反映したテキストを取得可能なText。
class FixedWidthText {
	private Text _widget;
	private GC _gc;
	private int _width;
	this(FontData fontData, int num, Composite parent, int style) {
		_widget = new Text(parent, style | DWT.MULTI | DWT.WRAP);
		_widget.setFont = new Font(Display.getCurrent, fontData);
		_gc = new GC(_widget);
		_gc.setFont = _widget.getFont;
		// FIXME: Windows環境で太字にするとサイズが合わなくなる
/+		_width = _gc.getAdvanceWidth(' ') * num;
+/		_width = _gc.textExtent("　").x * (num / 2) + 1;
		if (num & 1) _width += _gc.textExtent(" ").x;

		_widget.addListener(DWT.Dispose, new class Listener {
			override void handleEvent(Event e) {
				_widget.getFont.dispose;
				_gc.dispose;
			}
		});
	}
	Text widget() {
		return _widget;
	}
	Point computeTextBaseSize(int line) {
		return _widget.computeSize(_width, _gc.getFontMetrics.getHeight * line);
	}
	string getRRText(bool lastRet = true) {
		return toRRText(_widget.getText, _width, _gc, lastRet);
	}
	static string toRRText(string targ, int num, FontData fontData, bool lastRet = true) {
		if (targ == "") return "";
		scope img = new Image(Display.getCurrent, 1, 1);
		scope (exit) img.dispose;
		scope gc = new GC(img);
		scope (exit) gc.dispose;
		scope font = new Font(Display.getCurrent, fontData);
		scope (exit) font.dispose;
		gc.setFont = font;
		int width = gc.getAdvanceWidth(' ') * num;
		return toRRText(targ, width, gc, lastRet);
	}
	private static string toRRText(string targ, int width, GC gc, bool lastRet) {
		if (targ == "") return "";
		dstring[] buf;
		string[] text = splitlines(targ);
		foreach (t8; text) {
			dstring t = toUTF32(t8);
			if (gc.textExtent(t8).x > width) {
				dchar[] lBuf;
				while (t.length > 0) {
					if (gc.textExtent(toUTF8(lBuf)).x + gc.textExtent(toUTF8(t[0 .. 1])).x > width) {
						buf ~= lBuf.dup;
						lBuf.length = 0;
					}
					lBuf ~= t[0];
					t = t[1 .. $];
				}
				if (lBuf.length > 0) {
					buf ~= lBuf;
				}
			} else {
				buf ~= t;
			}
		}
		foreach_reverse (i, t; buf) {
			if (t.length > 0) {
				string newText;
				for (int j = 0; j < i + 1; j++) {
					newText ~= toUTF8(buf[j]);
					if (lastRet || j + 1 < i + 1) newText ~= "\n";
				}
				return newText;
			}
		}
		return "";
	}
	void insert(string text) {
		_widget.insert = text;
	}
	void setText(string text) {
		_widget.setText = text;
	}
	string getText() {
		return _widget.getText;
	}
}

/// 入力された文字列の長さを検証し、制限をかける。
class GBLimitText {
	private Text _widget;
	private bool _ed = false;
	private int _width;
	private GC _gc;
	private string _old = "";

	/// Params:
	/// font = 検証に使用するフォント。
	/// num = 最大文字数。[' 'の幅 * num]が入力可能な文字列幅となる。
	this(string font, int num, Composite parent, int style) {
		_widget = new Text(parent, style | DWT.NO_BACKGROUND);
		_gc = new GC(_widget);
		_gc.setFont = new Font(Display.getCurrent, new FontData(font, 10, DWT.NORMAL));
		_width = _gc.textExtent(" ").x * num;

		_widget.addListener(DWT.Verify, new class Listener {
			override void handleEvent(Event e) {
				if (_ed) return;
				scope dstring vText;
				try {
					vText = toUTF32(e.text);
				} catch {
					// FIXME: たまーに壊れたテキストが来るんだよね
					//        「情報」と入力したときとか
					return;
				}
				if (vText.length < e.end - e.start) {
					// 文字数が減少するなら無条件に通す
					e.doit = true;
				} else {
					scope text = toUTF32(_widget.getText);
					scope p = _widget.getSelection;
					text = text[0 .. p.x] ~ text[p.y .. $];
					scope st = text[0 .. e.start];
					scope el = text[e.end .. $];
					if (vText.length > 1) {
						// 複数文字挿入。ペーストのみ。
						while (_gc.textExtent(toUTF8(st ~ vText ~ el)).x > _width && vText.length > 0) {
							vText = vText[0 .. $ - 1];
						}
						e.text = toUTF8(vText);
						e.doit = true;
					} else {
						// 単字。FIXME: 日本語入力ではe.textが化けるみたい。
						e.doit = _gc.textExtent(toUTF8(st ~ vText ~ el)).x <= _width;
					}
				}
			}
		});
		// FIXME: 全角スペース入力でVerifyEventが入力文字を取れないようなので暫定
		_widget.addListener(DWT.Modify, new class Listener {
			override void handleEvent(Event e) {
				if (_ed) return;
				if (_gc.textExtent(getText).x <= _width) {
					_old = _widget.getText;
				} else {
					dstring old32 = toUTF32(_old);
					int cur = _widget.getCaretPosition;
					Point sel = _widget.getSelection;
					if (cur >= sel.x) sel.x--;
					if (cur >= sel.y) sel.y--;
					_ed = true;
					_widget.setText = _old;
					_ed = false;
					_widget.setSelection = sel;
				}
			}
		});
		_widget.addListener(DWT.Dispose, new class Listener {
			override void handleEvent(Event e) {
				_gc.getFont.dispose;
				_gc.dispose;
			}
		});
	}
	Text widget() {
		return _widget;
	}
	Point computeSize(int wHint, int hHint) {
		return _widget.computeSize(wHint == DWT.DEFAULT ? _width : wHint, hHint);
	}
	void insert(string text) {
		_widget.insert = text;
	}
	void setText(string text) {
		_widget.setText = text;
		_old = text;
	}
	string getText() {
		return _widget.getText;
	}
}
