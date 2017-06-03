/// ビューにインクリメンタルサーチを載せる。
module cwx.editor.gui.dwt.incsearch;

import cwx.utils;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.timebar;

import std.algorithm;
import std.conv;
import std.string;
import std.regex;
import std.uni;

import java.lang.all;

import org.eclipse.swt.all;

/// 追加検索条件。
/// オブジェクトの種類毎に絞り込みたい等の場合に使用する。
struct AdditionMatcher {
	string name; /// 条件名。
	bool delegate(in Object) match; /// オブジェクトがこの条件にマッチするか判定する。
}
class IncSearch {
	/// 検索語が変更された際に呼び出される。
	void delegate()[] modEvent;

	/// 文字列がマッチすればtrue。
	bool match(string text, in Object additionalData = null) { mixin(S_TRACE);
		if (!_win) return true;
		if (!_win.isVisible()) return true;
		if (!_wild) return matchAdditional(additionalData);
		if (!_text.getText().length) return matchAdditional(additionalData);
		switch (_type.getSelectionIndex()) {
		case 0: return std.string.indexOf(text, _text.getText(), CaseSensitive.no) != -1 && matchAdditional(additionalData);
		case 1: return _wild.match(text) && matchAdditional(additionalData);
		case 2:
			if (_regexErr) return false;
			return !.match(to!dstring(text), _regex).empty && matchAdditional(additionalData);
		default: assert (0);
		}
	}
	@property
	bool isSearching() { mixin(S_TRACE);
		if (!_win) return false;
		if (!_win.isVisible()) return false;
		foreach (chk, dlg; _additionCheckers) { mixin(S_TRACE);
			if (!chk.getSelection()) return true;
		}
		return 0 < _text.getText().length;
	}
	bool matchAdditional(in Object additionalData) { mixin(S_TRACE);
		if (!additionalData) return true;
		foreach (chk, dlg; _additionCheckers) { mixin(S_TRACE);
			if (!chk.getSelection() && dlg(additionalData)) { mixin(S_TRACE);
				return false;
			}
		}
		return true;
	}

	private Commons _comm = null;
	private AdditionMatcher[] _addition = [];

	private Shell _win = null;
	private Text _text = null;
	private Combo _type = null;
	private Control _parent = null;
	private Wildcard _wild = null;
	private Regex!dchar _regex;
	private bool delegate(in Object)[Button] _additionCheckers;
	private bool _regexErr = false;
	private bool _open = false;
	private bool _inMod = false;

	this (Commons comm, Control parent, AdditionMatcher[] addition = []) { mixin(S_TRACE);
		_comm = comm;
		_parent = parent;
		_addition = addition;

		auto d = _parent.getDisplay();

		// 文字列入力による絞り込み検索開始
		auto keyDown = new class Listener {
			private class Start : Runnable {
				wchar[] text;
				override void run() { mixin(S_TRACE);
					_start = null;
					startIncSearch(text.text());
				}
			}
			private Start _start = null;
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (_open) return;
				if (!_comm.prop.var.etc.startIncrementalSearchWhenKeyDown) return;
				if (_parent.isDisposed() || !_parent.isVisible()) return;
				auto c = cast(Control)e.widget;
				if (!c || c.isDisposed()) return;
				if (cast(Text)c) return;
				if (cast(Spinner)c) return;
				if (cast(TimeBar)c) return;
				if (auto combo = cast(Combo)c) { mixin(S_TRACE);
					if ((combo.getStyle() & SWT.READ_ONLY) == 0) return;
				}
				if (auto combo = cast(CCombo)c) { mixin(S_TRACE);
					if ((combo.getStyle() & SWT.READ_ONLY) == 0) return;
				}
				auto comp = cast(Composite)_parent;
				if (comp) { mixin(S_TRACE);
					if (!isDescendant(comp, c)) { mixin(S_TRACE);
						return;
					}
				} else { mixin(S_TRACE);
					if (c !is _parent) { mixin(S_TRACE);
						return;
					}
				}
				if (!_start) { mixin(S_TRACE);
					if (findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
				}
				if (e.character.isGraphical()) { mixin(S_TRACE);
					// IMEによる変換後の文字列は一連のKeyDownイベントとして発生するが、
					// 1文字ずつ送出されるため、最初の1件ですぐにstartIncSearch()を
					// 開始すると2文字も以降が落ちてしまう。
					// そのため、Display#asyncExec()を用いて遅延実行を行う。
					if (_start) { mixin(S_TRACE);
						_start.text ~= e.character;
					} else { mixin(S_TRACE);
						_start = new Start;
						_start.text ~= e.character;
						d.asyncExec(_start);
					}
				}
			}
		};
		d.addFilter(SWT.KeyDown, keyDown);
		.listener(_parent, SWT.Dispose, { mixin(S_TRACE);
			d.removeFilter(SWT.KeyDown, keyDown);
		});
	}
	private void initialize() { mixin(S_TRACE);
		_win = new Shell(_parent.getShell(), SWT.BORDER | SWT.MODELESS);
		_win.setData(this);
		auto wgl = windowGridLayout(3, false);
		wgl.marginWidth = 0;
		wgl.marginHeight = 0;
		wgl.horizontalSpacing = 0;
		_win.setLayout(wgl);
		_text = new Text(_win, SWT.BORDER);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = _comm.prop.var.etc.incrementalSearchBoxWidth;
		_text.setLayoutData(gd);
		createTextMenu!Text(_comm, _comm.prop, _text, null);
		auto menu = _text.getMenu();
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CloseIncSearch, &close, null);

		_type = new Combo(_win, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		createTextMenu!Combo(_comm, _comm.prop, _type, null);
		_type.add(_comm.prop.msgs.incSearchContains);
		_type.add(_comm.prop.msgs.incSearchWildcard);
		_type.add(_comm.prop.msgs.incSearchRegex);
		_type.select(.min(_type.getItemCount() - 1, .max(0, _comm.prop.var.etc.incrementalSearchType)));
		auto menuc = _type.getMenu();
		new MenuItem(menuc, SWT.SEPARATOR);
		createMenuItem(_comm, menuc, MenuID.CloseIncSearch, &close, null);
		.listener(_type, SWT.Selection, { mixin(S_TRACE);
			_comm.prop.var.etc.incrementalSearchType = _type.getSelectionIndex();
			if (!_open) return;
			if (!_win.isVisible()) return;
			foreach (dlg; modEvent) { mixin(S_TRACE);
				dlg();
			}
		});
		auto bar = new ToolBar(_win, SWT.FLAT);
		_comm.put(bar);
		createToolItem(_comm, bar, MenuID.CloseIncSearch, &close, null);

		if (_addition.length) { mixin(S_TRACE);
			auto addComp = new Composite(_win, SWT.NONE);
			auto agd = new GridData(GridData.FILL_HORIZONTAL);
			agd.horizontalSpan = 3;
			addComp.setLayoutData(agd);
			addComp.setLayout(zeroMarginGridLayout(cast(int)_addition.length, false));
			foreach (add; _addition) { mixin(S_TRACE);
				auto check = new Button(addComp, SWT.CHECK);
				check.setText(add.name);
				check.setSelection(true);
				.listener(check, SWT.Selection, { mixin(S_TRACE);
					foreach (dlg; modEvent) { mixin(S_TRACE);
						dlg();
					}
				});
				_additionCheckers[check] = add.match;
			}
		}

		.listener(_text, SWT.Modify, &modified);
		.listener(_text, SWT.KeyDown, (Event e) { mixin(S_TRACE);
			// 何かキーを押すと検索する設定であれば、
			// BackspaceかDelete押下で閉じる操作を有効にする
			if (!_comm.prop.var.etc.startIncrementalSearchWhenKeyDown) return;
			if ((e.character == '\b' || e.keyCode == SWT.DEL) && !_text.getText().length) { mixin(S_TRACE);
				close();
			}
		});
		auto l = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				resize();
			}
		};
		auto rmFocus = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				if (_win.isDisposed()) return;
				if (!_open) return;
				if (!_win.isVisible()) return;
				auto c = _parent.getDisplay().getFocusControl();
				if (!c) return;
				if (isDescendant(_win, c)) return;
				if (c is _parent.getShell()) return;
				if (!(c.getShell() is _win || c.getShell() is _parent.getShell())) return;
				auto comp = cast(Composite)_parent;
				if (comp) { mixin(S_TRACE);
					if (!isDescendant(comp, c)) { mixin(S_TRACE);
						close();
					}
				} else { mixin(S_TRACE);
					if (c !is _parent) { mixin(S_TRACE);
						close();
					}
				}
			}
		};
		_parent.getShell().addListener(SWT.Resize, l);
		_parent.getShell().addListener(SWT.Move, l);
		_parent.addListener(SWT.Resize, l);
		_parent.addListener(SWT.Move, l);
		auto d = _parent.getDisplay();
		d.addFilter(SWT.FocusIn, rmFocus);
		d.addFilter(SWT.FocusOut, rmFocus);
		.listener(_win, SWT.Dispose, { mixin(S_TRACE);
			_parent.getShell().removeListener(SWT.Resize, l);
			_parent.getShell().removeListener(SWT.Move, l);
			_parent.removeListener(SWT.Resize, l);
			_parent.removeListener(SWT.Move, l);
			d.removeFilter(SWT.FocusIn, rmFocus);
			d.removeFilter(SWT.FocusOut, rmFocus);
		});
		.listener(_parent, SWT.Dispose, { mixin(S_TRACE);
			if (!_win.isDisposed()) { mixin(S_TRACE);
				_win.dispose();
			}
		});
		.listener(_win, SWT.Close, (Event e) { mixin(S_TRACE);
			e.doit = false;
			close();
		});

		_win.pack();
		resize();
	}
	private void resize() { mixin(S_TRACE);
		if (!_win) initialize();
		_win.setLocation(_parent.toDisplay(0, -_win.getSize().y));
	}
	private void modified() { mixin(S_TRACE);
		if (_inMod) return;
		if (!_open) return;
		if (!_win.isVisible()) return;
		_inMod = true;
		scope (exit) _inMod = false;
		_win.setRedraw(false);
		scope (exit) _win.setRedraw(true);

		_wild = Wildcard(_text.getText());
		try { mixin(S_TRACE);
			_regex = .regex(to!dstring(_text.getText()), "i");
			_regexErr = false;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			_regexErr = true;
		}

		auto gc = new GC(_text);
		scope (exit) gc.dispose();
		auto gd = new GridData(GridData.FILL_BOTH);
		int maxW = _comm.prop.var.etc.incrementalSearchBoxWidth;
		gd.widthHint = .max(maxW, _text.computeSize(gc.wTextExtent(_text.getText()).x, SWT.DEFAULT).x);
		_text.setLayoutData(gd);
		_win.pack();

		// テキストの末尾位置がずれるため調整
		auto sel = _text.getSelection();
		_text.setText(_text.getText());
		_text.setSelection(sel);

		foreach (dlg; modEvent) { mixin(S_TRACE);
			dlg();
		}
	}

	void startIncSearch(string first = "") { mixin(S_TRACE);
		if (!_win) initialize();
		if (!_win.isVisible()) { mixin(S_TRACE);
			_text.setText(first);
			_text.setSelection(cast(int)first.length);
			resize();
			_win.setVisible(true);
			_text.setFocus();
			_open = true;
			if (first != "") { mixin(S_TRACE);
				modified();
			}
		} else { mixin(S_TRACE);
			_text.setFocus();
			_open = true;
		}
	}
	void close() { mixin(S_TRACE);
		if (!_win) initialize();
		if (_win.isVisible()) { mixin(S_TRACE);
			_win.setVisible(false);
			_wild = null;
			bool mod = false;
			foreach (chk, dlg; _additionCheckers) { mixin(S_TRACE);
				if (!chk.getSelection()) { mixin(S_TRACE);
					chk.setSelection(true);
					mod = true;
				}
			}
			if (_text.getText().length) { mixin(S_TRACE);
				_text.setText("");
				mod = true;
			}
			if (mod) { mixin(S_TRACE);
				foreach (dlg; modEvent) { mixin(S_TRACE);
					dlg();
				}
			}
			_open = false;
		}
	}
}
