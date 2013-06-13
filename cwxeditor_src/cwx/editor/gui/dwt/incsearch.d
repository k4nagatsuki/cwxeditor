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
	bool match(string text, in Object additionalData = null) {
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
	bool matchAdditional(in Object additionalData) {
		if (!additionalData) return true;
		foreach (chk, dlg; _additionCheckers) {
			if (!chk.getSelection() && dlg(additionalData)) {
				return false;
			}
		}
		return true;
	}

	private Shell _win;
	private Text _text;
	private CCombo _type;
	private Control _parent;
	private Wildcard _wild = null;
	private Regex!dchar _regex;
	private bool delegate(in Object)[Button] _additionCheckers;
	private bool _regexErr = false;
	private bool _open = false;

	this (Commons comm, Control parent, AdditionMatcher[] addition = []) {
		_parent = parent;
		_win = new Shell(parent.getShell(), SWT.BORDER | SWT.MODELESS);
		auto wgl = windowGridLayout(3, false);
		wgl.marginWidth = 0;
		wgl.marginHeight = 0;
		wgl.horizontalSpacing = 0;
		_win.setLayout(wgl);
		_text = new Text(_win, SWT.BORDER);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = comm.prop.var.etc.incrementalSearchBoxWidth;
		_text.setLayoutData(gd);
		createTextMenu!Text(comm, comm.prop, _text, null);
		auto menu = _text.getMenu();
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.CloseIncSearch, &close, null);

		_type = new CCombo(_win, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		createTextMenu!CCombo(comm, comm.prop, _type, null);
		_type.add(comm.prop.msgs.incSearchContains);
		_type.add(comm.prop.msgs.incSearchWildcard);
		_type.add(comm.prop.msgs.incSearchRegex);
		_type.select(.min(_type.getItemCount() - 1, .max(0, comm.prop.var.etc.incrementalSearchType)));
		auto menuc = _type.getMenu();
		new MenuItem(menuc, SWT.SEPARATOR);
		createMenuItem(comm, menuc, MenuID.CloseIncSearch, &close, null);
		.listener(_type, SWT.Selection, {
			comm.prop.var.etc.incrementalSearchType = _type.getSelectionIndex();
			if (!_open) return;
			if (!_win.isVisible()) return;
			foreach (dlg; modEvent) {
				dlg();
			}
		});
		auto bar = new ToolBar(_win, SWT.FLAT);
		comm.put(bar);
		createToolItem(comm, bar, MenuID.CloseIncSearch, &close, null);

		if (addition.length) {
			auto addComp = new Composite(_win, SWT.NONE);
			auto agd = new GridData(GridData.FILL_HORIZONTAL);
			agd.horizontalSpan = 3;
			addComp.setLayoutData(agd);
			addComp.setLayout(zeroMarginGridLayout(addition.length, false));
			foreach (add; addition) {
				auto check = new Button(addComp, SWT.CHECK);
				check.setText(add.name);
				check.setSelection(true);
				.listener(check, SWT.Selection, {
					foreach (dlg; modEvent) {
						dlg();
					}
				});
				_additionCheckers[check] = add.match;
			}
		}

		bool inMod = false;
		.listener(_text, SWT.Modify, {
			if (inMod) return;
			if (!_open) return;
			if (!_win.isVisible()) return;
			inMod = true;
			scope (exit) inMod = false;
			_win.setRedraw(false);
			scope (exit) _win.setRedraw(true);

			_wild = Wildcard(_text.getText());
			try {
				_regex = .regex(to!dstring(_text.getText()), "i");
				_regexErr = false;
			} catch (Exception e) {
				_regexErr = true;
			}

			auto gc = new GC(_text);
			scope (exit) gc.dispose();
			auto gd = new GridData(GridData.FILL_BOTH);
			int maxW = comm.prop.var.etc.incrementalSearchBoxWidth;
			gd.widthHint = .max(maxW, _text.computeSize(gc.textExtent(_text.getText()).x, SWT.DEFAULT).x);
			_text.setLayoutData(gd);
			_win.pack();

			// テキストの末尾位置がずれるため調整
			auto sel = _text.getSelection();
			_text.setText(_text.getText());
			_text.setSelection(sel);

			foreach (dlg; modEvent) {
				dlg();
			}
		});
		auto l = new class Listener {
			override void handleEvent(Event e) {
				resize();
			}
		};
		auto rmFocus = new class Listener {
			override void handleEvent(Event e) {
				if (_win.isDisposed()) return;
				if (!_open) return;
				if (!_win.isVisible()) return;
				auto c = parent.getDisplay().getFocusControl();
				if (!c) return;
				if (isDescendant(_win, c)) return;
				if (!(c.getShell() is _win || c.getShell() is parent.getShell())) return;
				auto comp = cast(Composite) parent;
				if (comp) {
					if (!isDescendant(comp, c)) {
						close();
					}
				} else {
					if (c !is parent) {
						close();
					}
				}
			}
		};
		parent.getShell().addListener(SWT.Resize, l);
		parent.getShell().addListener(SWT.Move, l);
		parent.addListener(SWT.Resize, l);
		parent.addListener(SWT.Move, l);
		auto d = parent.getDisplay();
		d.addFilter(SWT.FocusIn, rmFocus);
		d.addFilter(SWT.FocusOut, rmFocus);
		.listener(_win, SWT.Dispose, {
			parent.getShell().removeListener(SWT.Resize, l);
			parent.getShell().removeListener(SWT.Move, l);
			parent.removeListener(SWT.Resize, l);
			parent.removeListener(SWT.Move, l);
			d.removeListener(SWT.FocusOut, rmFocus);
			d.removeListener(SWT.FocusOut, rmFocus);
		});
		.listener(parent, SWT.Dispose, {
			if (!_win.isDisposed()) {
				_win.dispose();
			}
		});
		.listener(_win, SWT.Close, (Event e) {
			e.doit = false;
			close();
		});

		_win.pack();
		resize();
	}
	private void resize() {
		_win.setLocation(_parent.toDisplay(0, -_win.getSize().y));
	}

	void startIncSearch(string first = "") {
		if (!_win.isVisible()) {
			_text.setText(first);
			resize();
			_win.setVisible(true);
		}
		.forceFocus(_text, true);
		_open = true;
	}
	void close() {
		if (_win.isVisible()) {
			_win.setVisible(false);
			_wild = null;
			bool mod = false;
			foreach (chk, dlg; _additionCheckers) {
				if (!chk.getSelection()) {
					chk.setSelection(true);
					mod = true;
				}
			}
			if (_text.getText().length) {
				_text.setText("");
				mod = true;
			}
			if (mod) {
				foreach (dlg; modEvent) {
					dlg();
				}
			}
			_open = false;
		}
	}
}
