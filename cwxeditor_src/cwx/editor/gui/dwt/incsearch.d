/// ビューにインクリメンタルサーチを載せる。
module cwx.editor.gui.dwt.incsearch;

import cwx.utils;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;

import std.algorithm;

import org.eclipse.swt.all;

class IncSearch {
	/// 検索語が変更された際に呼び出される。
	void delegate()[] modEvent;

	/// 文字列がマッチすればtrue。
	bool match(string text) {
		if (!_wild) return true;
		if (!_text.getText().length) return true;
		return _wild.match(text);
	}

	private Shell _win;
	private Text _text;
	private Control _parent;
	private Wildcard _wild = null;

	this (Commons comm, Control parent) {
		_parent = parent;
		_win = new Shell(parent.getShell(), SWT.BORDER | SWT.MODELESS);
		_win.setLayout(zeroGridLayout(1, true));
		_text = new Text(_win, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = comm.prop.var.etc.incrementalSearchBoxWidth;
		_text.setLayoutData(gd);
		createTextMenu!Text(comm, comm.prop, _text, null);

		.listener(_text, SWT.Modify, {
			if (_wild && !_text.getText().length) {
				close();
			} else if (_text.getText().length) {
				_wild = Wildcard(_text.getText());
				auto gc = new GC(_text);
				scope (exit) gc.dispose();
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = .max(comm.prop.var.etc.incrementalSearchBoxWidth, gc.textExtent(_text.getText()).x);
				_text.setLayoutData(gd);
				_win.pack();
			}
			foreach (dlg; modEvent) {
				dlg();
			}
		});
		void resize() {
			_win.setLocation(parent.toDisplay(0, -_win.getSize().y));
		}
		auto l = new class Listener {
			override void handleEvent(Event e) {
				resize();
			}
		};
		auto rmFocus = new class Listener {
			override void handleEvent(Event e) {
				auto c = parent.getDisplay().getFocusControl();
				if (c is _text) return;
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

		_win.pack();
		resize();
	}

	void startIncSearch(string first = "") {
		_text.setText(first);
		_win.setVisible(true);
		_text.setFocus();
	}
	void close() {
		_win.setVisible(false);
		_wild = null;
		if (_text.getText().length) _text.setText("");
		_parent.setFocus();
	}
}
