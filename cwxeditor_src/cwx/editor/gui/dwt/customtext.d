
module cwx.editor.gui.dwt.customtext;

import cwx.utils;

import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.utf;
import std.string;
import std.exception;
import std.array;
import std.ascii;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

Text mnemonicText(Composite parent, int style) { mixin(S_TRACE);
	auto text = new Text(parent, style | SWT.READ_ONLY);
	class Key : KeyAdapter {
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			text.setText(acceleratorText(e.keyCode));
		}
	}
	text.addKeyListener(new Key);
	text.setData(new CIgnoreHotkey);
	return text;
}

/// ホットキーを入力するためのフィールド。
class HotKeyField {
	private Text _char;
	this (Composite parent, int style) { mixin(S_TRACE);
		_char = new Text(parent, style | SWT.READ_ONLY);
		_char.addKeyListener(new StateMaskKey);
		_char.setData(new CIgnoreHotkey);
	}
	private class StateMaskKey : KeyAdapter {
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			refText(e.keyCode | e.stateMask);
		}
	}
	private void refText(int val) { mixin(S_TRACE);
		string t = "";
		void put(string a) { mixin(S_TRACE);
			if (!a.length) return;
			if (t.length) t ~= " + ";
			t ~= a;
		}
		if (SWT.CONTROL & val) { mixin(S_TRACE);
			put("Ctrl");
			val &= ~SWT.CONTROL;
		}
		if (SWT.SHIFT & val) { mixin(S_TRACE);
			put("Shift");
			val &= ~SWT.SHIFT;
		}
		if (SWT.ALT & val) { mixin(S_TRACE);
			put("Alt");
			val &= ~SWT.ALT;
		}
		if (SWT.COMMAND & val) { mixin(S_TRACE);
			put("Command");
			val &= ~SWT.COMMAND;
		}
		put(.acceleratorText(val));
		_char.setText(t);
	}
	@property
	Text widget() {return _char;}
	@property
	string acceleratorText() { mixin(S_TRACE);
		return _char.getText().replace(" + ", "+");
	}
	@property
	void accelerator(string hotkey) { mixin(S_TRACE);
		refText(convertAccelerator2(hotkey));
	}
}

/// 折り返しを反映したテキストを取得可能なText。
class FixedWidthText {
	private Text _widget;
	private GC _gc = null;
	private int _width;
	private int _num;
	this (FontData fontData, int num, Composite parent, int style, bool wordWrap = false) { mixin(S_TRACE);
		_widget = new Text(parent, style | SWT.MULTI | SWT.WRAP);
		_num = num;
		font = fontData;

		_widget.addListener(SWT.Dispose, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				_widget.getFont().dispose();
				_gc.dispose();
			}
		});
	}
	@property
	void num(int num) { mixin(S_TRACE);
		_num = num;
		calcWidth();
	}
	@property
	void font(FontData fontData) { mixin(S_TRACE);
		if (_gc) { mixin(S_TRACE);
			_widget.getFont().dispose();
		}
		_widget.setFont(new Font(Display.getCurrent(), fontData));
		calcWidth();
	}
	private void calcWidth() { mixin(S_TRACE);
		if (_gc) { mixin(S_TRACE);
			_gc.dispose();
		}
		_gc = new GC(_widget);
		_gc.setFont(_widget.getFont());
		// FIXME: Windows環境で太字にするとサイズが合わなくなる
/+		_width = _gc.getAdvanceWidth(' ') * _num;
+/		_width = _gc.textExtent("　").x * (_num / 2) + 1;
		if (_num & 1) _width += _gc.textExtent(" ").x;
	}
	@property
	Text widget() { mixin(S_TRACE);
		return _widget;
	}
	Point computeTextBaseSize(int line) { mixin(S_TRACE);
		return _widget.computeSize(_width, _gc.getFontMetrics().getHeight() * line);
	}
	string getRRText(bool lastRet = true) { mixin(S_TRACE);
		return toRRText(_widget.getText(), _width, _gc, lastRet);
	}
	static string toRRText(string targ, int num, FontData fontData, bool lastRet = true) { mixin(S_TRACE);
		if (targ == "") return "";
		scope img = new Image(Display.getCurrent(), 1, 1);
		scope (exit) img.dispose();
		scope gc = new GC(img);
		scope (exit) gc.dispose();
		scope font = new Font(Display.getCurrent(), fontData);
		scope (exit) font.dispose();
		gc.setFont(font);
		int width = gc.getAdvanceWidth(' ') * num;
		return toRRText(targ, width, gc, lastRet);
	}
	private static string toRRText(string targ, int width, GC gc, bool lastRet) { mixin(S_TRACE);
		if (targ == "") return "";
		dstring[] buf;
		string[] text = splitLines!string(targ);
		foreach (t8; text) { mixin(S_TRACE);
			dstring t = toUTF32(t8);
			if (gc.textExtent(t8).x > width) { mixin(S_TRACE);
				dchar[] lBuf;
				while (t.length > 0) { mixin(S_TRACE);
					if (gc.textExtent(toUTF8(lBuf)).x + gc.textExtent(toUTF8(t[0 .. 1])).x > width) { mixin(S_TRACE);
						buf ~= assumeUnique(lBuf);
						lBuf = [];
					}
					lBuf ~= t[0];
					t = t[1 .. $];
				}
				if (lBuf.length > 0) { mixin(S_TRACE);
					buf ~= assumeUnique(lBuf);
					lBuf = [];
				}
			} else { mixin(S_TRACE);
				buf ~= t;
			}
		}
		foreach_reverse (i, t; buf) { mixin(S_TRACE);
			if (t.length > 0) { mixin(S_TRACE);
				string newText;
				for (int j = 0; j < i + 1; j++) { mixin(S_TRACE);
					newText ~= toUTF8(buf[j]);
					if (lastRet || j + 1 < i + 1) newText ~= "\n";
				}
				return newText;
			}
		}
		return "";
	}
	void insert(string text) { mixin(S_TRACE);
		_widget.insert(text);
	}
	void setText(string text) { mixin(S_TRACE);
		_widget.setText(text);
	}
	string getText() { mixin(S_TRACE);
		return _widget.getText();
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
	this (string font, int num, bool cut, Composite parent, int style) { mixin(S_TRACE);
		_widget = new Text(parent, style | SWT.NO_BACKGROUND);
		_cut = cut;
		_gc = new GC(_widget);
		_gc.setFont(new Font(Display.getCurrent(), new FontData(font, 10, SWT.NORMAL)));
		_width = _gc.textExtent(" ").x * num;

		_widget.addListener(SWT.Verify, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (!_cut) { mixin(S_TRACE);
					e.doit = true;
					return;
				}
				if (_ed) return;
				dstring vText;
				try { mixin(S_TRACE);
					vText = toUTF32(e.text);
				} catch { mixin(S_TRACE);
					// FIXME: 時々壊れたテキストが来る
					//        「情報」と入力したときなど
					return;
				}
				if (vText.length < e.end - e.start) { mixin(S_TRACE);
					// 文字数が減少するなら無条件に通す
					e.doit = true;
				} else { mixin(S_TRACE);
					auto text = toUTF32(_widget.getText());
					auto p = _widget.getSelection();
					text = text[0 .. p.x] ~ text[p.y .. $];
					auto st = text[0 .. e.start];
					auto el = text[e.end .. $];
					if (vText.length > 1) { mixin(S_TRACE);
						// 複数文字挿入。ペーストのみ。
						while (_gc.textExtent(toUTF8(st ~ vText ~ el)).x > _width && vText.length > 0) { mixin(S_TRACE);
							vText = vText[0 .. $ - 1];
						}
						e.text = toUTF8(vText);
						e.doit = true;
					} else { mixin(S_TRACE);
						// 単字。FIXME: 日本語入力ではe.textが化けるみたい。
						e.doit = _gc.textExtent(toUTF8(st ~ vText ~ el)).x <= _width;
					}
				}
			}
		});
		// FIXME: 全角スペース入力でVerifyEventが入力文字を取れないようなので暫定
		_widget.addListener(SWT.Modify, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (!_cut) { mixin(S_TRACE);
					bool over = _gc.textExtent(getText()).x > _width;
					if (_over != over) { mixin(S_TRACE);
						_over = over;
						foreach (le; limitEvent) { mixin(S_TRACE);
							le();
						}
					} else { mixin(S_TRACE);
						_over = over;
					}
					return;
				}
				if (_ed) return;
				if (_gc.textExtent(getText()).x <= _width) { mixin(S_TRACE);
					_old = _widget.getText();
				} else { mixin(S_TRACE);
					dstring old32 = toUTF32(_old);
					int cur = _widget.getCaretPosition();
					Point sel = _widget.getSelection();
					if (cur >= sel.x) sel.x--;
					if (cur >= sel.y) sel.y--;
					_ed = true;
					_widget.setText(_old);
					_ed = false;
					_widget.setSelection(sel);
				}
			}
		});
		_widget.addListener(SWT.Dispose, new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				_gc.getFont().dispose();
				_gc.dispose();
			}
		});
	}
	@property
	Text widget() { mixin(S_TRACE);
		return _widget;
	}
	Point computeSize(int wHint, int hHint) { mixin(S_TRACE);
		return _widget.computeSize(wHint == SWT.DEFAULT ? _width : wHint, hHint);
	}
	@property
	bool over() {return _over;}
	void insert(string text) { mixin(S_TRACE);
		_widget.insert(text);
	}
	void setText(string text) { mixin(S_TRACE);
		_widget.setText(text);
		_old = text;
	}
	string getText() { mixin(S_TRACE);
		return _widget.getText();
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
	string getText() { mixin(S_TRACE);
		final switch (kind) {
		case TMM_T:
			return text.getText();
		case TMM_C:
			return combo.getText();
		case TMM_CC:
			return ccombo.getText();
		}
	}
	void setText(string v) { mixin(S_TRACE);
		final switch (kind) {
		case TMM_T:
			text.setText(v);
			break;
		case TMM_C:
			combo.setText(v);
			break;
		case TMM_CC:
			ccombo.setText(v);
			break;
		}
	}
	Point getSelection() { mixin(S_TRACE);
		final switch (kind) {
		case TMM_T:
			return text.getSelection();
		case TMM_C:
			return combo.getSelection();
		case TMM_CC:
			return ccombo.getSelection();
		}
	}
	void setSelection(Point v) { mixin(S_TRACE);
		final switch (kind) {
		case TMM_T:
			text.setSelection(v);
			break;
		case TMM_C:
			combo.setSelection(v);
			break;
		case TMM_CC:
			ccombo.setSelection(v);
			break;
		}
	}
	void addListener(int type, Listener l) { mixin(S_TRACE);
		final switch (kind) {
		case TMM_T:
			text.addListener(type, l);
			break;
		case TMM_C:
			combo.addListener(type, l);
			break;
		case TMM_CC:
			ccombo.addListener(type, l);
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
		this () { mixin(S_TRACE);
			if (_apd.read) _apData = _oldApData;
			_oldText = _oldTextBase;
			_sel = _oldSel;
		}
		private void impl() { mixin(S_TRACE);
			_inProc = true;
			scope (exit) _inProc = false;

			auto oapd = _apData;
			string o = _oldText;
			auto os = _sel;

			if (_apd.read) _apData = _apd.read(oapd);
			_oldText = _text.getText();
			_sel = _text.getSelection();

			if (_apd.write) _apd.write(oapd);
			_text.setText(o);
			_text.setSelection(os);

			_oldApData = oapd;
			_oldSel = os;
			_oldTextBase = o;
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() { mixin(S_TRACE);
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
	private class SelectChanged : Listener {
		private bool _mouseDown = false;
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (e.type is SWT.MouseMove) { mixin(S_TRACE);
				if (!_mouseDown) return;
			} else if (e.type is SWT.MouseUp) { mixin(S_TRACE);
				_mouseDown = false;
				return;
			} else if (e.type is SWT.MouseDown) { mixin(S_TRACE);
				_mouseDown = true;
			}
			auto sel = _text.getSelection();
			if (sel.x != _oldSel.x || sel.y != _oldSel.y) { mixin(S_TRACE);
				_oldSel = sel;
				if (selectChanged) selectChanged();
			}
		}
	}

	this (TMM text, bool delegate() canSaveHistory, UndoManager undo, TMAppendData apd) { mixin(S_TRACE);
		_text = text;
		_canSaveHistory = canSaveHistory;
		_undo = undo;
		_apd = apd;
		auto sc = new SelectChanged;
		text.addListener(SWT.KeyDown, sc);
		text.addListener(SWT.KeyUp, sc);
		text.addListener(SWT.MouseDown, sc);
		text.addListener(SWT.MouseUp, sc);
		text.addListener(SWT.MouseMove, sc);
		text.addListener(SWT.MouseDoubleClick, sc);

		save();
	}
	private void save() { mixin(S_TRACE);
		if (_apd.read) _oldApData = _apd.read(_oldApData);
		_oldSel = _text.getSelection();
		_oldTextBase = _text.getText();
	}

	const
	bool inProc() {return _inProc;}

	void delegate() selectChanged;

	void reset() { mixin(S_TRACE);
		_undo.reset();
		save();
	}

	override void modifyText(ModifyEvent e) { mixin(S_TRACE);
		if (_inProc) return;
		if (_oldTextBase == _text.getText()) return;
		if (!_canSaveHistory) { mixin(S_TRACE);
			_undo ~= new TextMenuUndo;
		} else if (_canSaveHistory()) { mixin(S_TRACE);
			_undo ~= new TextMenuUndo;
		}
		save();
	}
}
