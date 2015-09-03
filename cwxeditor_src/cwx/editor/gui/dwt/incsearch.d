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

import std.algorithm;
import std.conv;
import std.string;
import std.regex;

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
		case 0: return .indexOf(text, _text.getText(), CaseSensitive.no) != -1 && matchAdditional(additionalData);
		case 1: return _wild.match(text) && matchAdditional(additionalData);
		case 2:
			if (_regexErr) return false;
			return !.match(to!dstring(text), _regex).empty && matchAdditional(additionalData);
		default: assert (0);
		}
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
	private CCombo _type = null;
	private Control _parent = null;
	private Wildcard _wild = null;
	private Regex!dchar _regex;
	private bool delegate(in Object)[Button] _additionCheckers;
	private bool _regexErr = false;
	private bool _open = false;

	this (Commons comm, Control parent, AdditionMatcher[] addition = []) { mixin(S_TRACE);
		_comm = comm;
		_parent = parent;
		_addition = addition;
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

		_type = new CCombo(_win, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		createTextMenu!CCombo(_comm, _comm.prop, _type, null);
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

		bool inMod = false;
		.listener(_text, SWT.Modify, { mixin(S_TRACE);
			if (inMod) return;
			if (!_open) return;
			if (!_win.isVisible()) return;
			inMod = true;
			scope (exit) inMod = false;
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
				auto comp = cast(Composite) _parent;
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
			d.removeListener(SWT.FocusIn, rmFocus);
			d.removeListener(SWT.FocusOut, rmFocus);
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

	void startIncSearch(string first = "") { mixin(S_TRACE);
		if (!_win) initialize();
		if (!_win.isVisible()) { mixin(S_TRACE);
			_text.setText(first);
			resize();
			_win.setVisible(true);
		}
		_text.setFocus();
		_open = true;
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
