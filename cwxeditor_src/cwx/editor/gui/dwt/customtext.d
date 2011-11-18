
module cwx.editor.gui.dwt.customtext;

import cwx.utils;

import cwx.editor.gui.dwt.undo;

import std.utf;
import std.string;
import std.exception;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontData;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import java.lang.all;

/// 折り返しを反映したテキストを取得可能なText。
class FixedWidthText {
	private Text _widget;
	private GC _gc = null;
	private int _width;
	private int _num;
	this(FontData fontData, int num, Composite parent, int style) {
		_widget = new Text(parent, style | SWT.MULTI | SWT.WRAP);
		_num = num;
		font = fontData;

		_widget.addListener(SWT.Dispose, new class Listener {
			override void handleEvent(Event e) {
				_widget.getFont.dispose;
				_gc.dispose;
			}
		});
	}
	void num(int num) {
		_num = num;
		calcWidth();
	}
	void font(FontData fontData) {
		if (_gc) {
			_widget.getFont.dispose;
		}
		_widget.setFont = new Font(Display.getCurrent, fontData);
		calcWidth();
	}
	private void calcWidth() {
		if (_gc) {
			_gc.dispose;
		}
		_gc = new GC(_widget);
		_gc.setFont = _widget.getFont;
		// FIXME: Windows環境で太字にするとサイズが合わなくなる
/+		_width = _gc.getAdvanceWidth(' ') * _num;
+/		_width = _gc.textExtent("　").x * (_num / 2) + 1;
		if (_num & 1) _width += _gc.textExtent(" ").x;
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
		string[] text = splitLines(targ);
		foreach (t8; text) {
			dstring t = toUTF32(t8);
			if (gc.textExtent(t8).x > width) {
				dchar[] lBuf;
				while (t.length > 0) {
					if (gc.textExtent(toUTF8(lBuf)).x + gc.textExtent(toUTF8(t[0 .. 1])).x > width) {
						buf ~= assumeUnique(lBuf);
						lBuf = [];
					}
					lBuf ~= t[0];
					t = t[1 .. $];
				}
				if (lBuf.length > 0) {
					buf ~= assumeUnique(lBuf);
					lBuf = [];
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
	/// 入力された文字列の長さが制限を超えたか、
	/// または制限内に収まったときに呼び出される。
	void delegate()[] limitEvent;

	private bool _over = false;

	private bool _cut = true;
	private Text _widget;
	private bool _ed = false;
	private int _width;
	private GC _gc;
	private string _old = "";

	/// Params:
	/// font = 検証に使用するフォント。
	/// num = 最大文字数。[' 'の幅 * num]が入力可能な文字列幅となる。
	/// cut = trueの場合、制限を超えた分は無条件にカットする。
	this(string font, int num, bool cut, Composite parent, int style) {
		_widget = new Text(parent, style | SWT.NO_BACKGROUND);
		_cut = cut;
		_gc = new GC(_widget);
		_gc.setFont = new Font(Display.getCurrent, new FontData(font, 10, SWT.NORMAL));
		_width = _gc.textExtent(" ").x * num;

		_widget.addListener(SWT.Verify, new class Listener {
			override void handleEvent(Event e) {
				if (!_cut) {
					e.doit = true;
					return;
				}
				if (_ed) return;
				scope dstring vText;
				try {
					vText = toUTF32(e.text);
				} catch {
					// FIXME: 時々壊れたテキストが来る
					//        「情報」と入力したときなど
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
		_widget.addListener(SWT.Modify, new class Listener {
			override void handleEvent(Event e) {
				if (!_cut) {
					bool over = _gc.textExtent(getText).x > _width;
					if (_over != over) {
						_over = over;
						foreach (le; limitEvent) {
							le();
						}
					} else {
						_over = over;
					}
					return;
				}
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
		_widget.addListener(SWT.Dispose, new class Listener {
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
		return _widget.computeSize(wHint == SWT.DEFAULT ? _width : wHint, hHint);
	}
	bool over() {return _over;}
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

// FIXME: TextMenuModifyをテンプレート化できない
immutable TMM_T = 0;
immutable TMM_C = 1;
immutable TMM_CC = 2;
struct TMM {
	union {
		Text text;
		Combo combo;
		CCombo ccombo;
	}
	int kind;
	static TMM opCall(Text text) {
		TMM r;
		r.text = text;
		r.kind = TMM_T;
		return r;
	}
	static TMM opCall(Combo combo) {
		TMM r;
		r.combo = combo;
		r.kind = TMM_C;
		return r;
	}
	static TMM opCall(CCombo ccombo) {
		TMM r;
		r.ccombo = ccombo;
		r.kind = TMM_CC;
		return r;
	}
	string getText() {
		final switch (kind) {
		case TMM_T:
			return text.getText;
		case TMM_C:
			return combo.getText;
		case TMM_CC:
			return ccombo.getText;
		}
	}
	void setText(string v) {
		final switch (kind) {
		case TMM_T:
			text.setText = v;
			break;
		case TMM_C:
			combo.setText = v;
			break;
		case TMM_CC:
			ccombo.setText = v;
			break;
		}
	}
	Point getSelection() {
		final switch (kind) {
		case TMM_T:
			return text.getSelection;
		case TMM_C:
			return combo.getSelection;
		case TMM_CC:
			return ccombo.getSelection;
		}
	}
	void setSelection(Point v) {
		final switch (kind) {
		case TMM_T:
			text.setSelection = v;
			break;
		case TMM_C:
			combo.setSelection = v;
			break;
		case TMM_CC:
			ccombo.setSelection = v;
			break;
		}
	}
}
struct TMAppendData {
	Object delegate(Object old) read = null;
	void delegate(Object) write = null;
}
// FIXME: これをテンプレート化しただけでリンクに失敗する
class TextMenuModify : ModifyListener {
	private class TextMenuUndo : Undo {
		private Object _apData = null;
		private Point _sel;
		private string _oldText;
		this () {
			if (_apd.read) _apData = _oldApData;
			_oldText = _oldTextBase;
			_sel = _oldSel;
		}
		private void impl() {
			_inProc = true;
			scope (exit) _inProc = false;

			auto oapd = _apData;
			string o = _oldText;
			auto os = _sel;

			if (_apd.read) _apData = _apd.read(oapd);
			_oldText = _text.getText;
			_sel = _text.getSelection;

			if (_apd.write) _apd.write(oapd);
			_text.setText = o;
			_text.setSelection = os;

			_oldApData = oapd;
			_oldSel = os;
			_oldTextBase = o;
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			// Nothing
		}
	}

	private bool _inProc = false;
	private TMM _text;
	private TMAppendData _apd;
	private Object _oldApData = null;
	private Point _oldSel;
	private string _oldTextBase;
	private bool delegate() _canSaveHistory;
	private UndoManager _undo;

	this (TMM text, bool delegate() canSaveHistory, UndoManager undo, TMAppendData apd) {
		_text = text;
		_canSaveHistory = canSaveHistory;
		_undo = undo;
		_apd = apd;

		save();
	}
	private void save() {
		if (_apd.read) _oldApData = _apd.read(_oldApData);
		_oldSel = _text.getSelection;
		_oldTextBase = _text.getText;
	}

	const
	bool inProc() {return _inProc;}

	void reset() {
		_undo.reset();
		save();
	}

	override void modifyText(ModifyEvent e) {
		if (_inProc) return;
		if (_oldTextBase == _text.getText) return;
		if (!_canSaveHistory) {
			_undo ~= new TextMenuUndo;
		} else if (_canSaveHistory()) {
			_undo ~= new TextMenuUndo;
		}
		save();
	}
}
