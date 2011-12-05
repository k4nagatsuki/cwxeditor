
module cwx.editor.gui.dwt.absdialog;

import cwx.utils;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;

interface DSize {
	void width(int);
	void height(int);
	int width();
	int height();
}

struct ButtonInfo {
	string name;
	void delegate() func;
}

abstract class AbsDialog {
	/// ダイアログが閉じられた際に呼び出される。
	void delegate()[] closeEvent;
	/// OKまたは適用ボタンの処理が行われる直前に呼び出される。
	void delegate()[] applyEvent;
	/// OKまたは適用ボタンが押され、その処理がキャンセルされなかった際に呼び出される。
	void delegate()[] appliedEvent;

	private Props _prop;
	private Shell _win;
	private DSize _size;
	private Composite _area;
	private Composite _addition;
	private bool _modal;
	private bool _hasApply;
	this (Props prop, Shell parent, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true, ButtonInfo[] button = []) {
		this (prop, parent, true, text, img, resizable, size, apply, cancel, button);
	}
	this (Props prop, Shell parent, bool modal, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true, ButtonInfo[] button = []) {
		_prop = prop;
		_size = size;
		_modal = modal;
		_hasApply = apply;
		int style = resizable ? SWT.SHELL_TRIM : SWT.DIALOG_TRIM;
		if (modal) {
			style |= SWT.APPLICATION_MODAL;
		}
		_win = new Shell(parent, style);
		_win.setText = text;
		_win.setImage = img;
		_win.setLayout = zeroGridLayout(2, false);
		_win.addShellListener(new SListener);

		_area = new Composite(_win, SWT.NONE);
		auto agd = new GridData(GridData.FILL_BOTH);
		agd.horizontalSpan = 2;
		_area.setLayoutData = agd;

		auto sep = new Label(_win, SWT.SEPARATOR | SWT.HORIZONTAL);
		auto sgd = new GridData(GridData.FILL_HORIZONTAL);
		sgd.horizontalSpan = 2;
		sep.setLayoutData = sgd;

		_addition = new Composite(_win, SWT.NONE);
		_addition.setLayout = new GridLayout(1, true);
		_addition.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

		auto buttons = new Composite(_win, SWT.NONE);
		buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
		int gll = 1;
		if (apply) gll++;
		if (cancel) gll++;
		gll += button.length;
		buttons.setLayout = new GridLayout(gll, true);
		auto okComp = new Composite(buttons, SWT.NONE);
		okComp.setLayout = new FillLayout;
		_okBtn = createButton(okComp, prop.msgs.dlgTextOK, &this.ok);
		if (cancel) {
			createButton(buttons, prop.msgs.dlgTextCancel, &this.cancel);
		}
		if (apply) {
			_apply = createButton(buttons, prop.msgs.dlgTextApply, &this.applyFunc);
		}
		foreach (info; button) {
			createButton(buttons, info.name, info.func);
		}
	}
	Composite addition() {return _addition;}

	private Button createButton(Composite parent, string text, void delegate() push) {
		auto b = new Button(parent, SWT.PUSH);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = 85;
		if (cast(GridLayout) parent.getLayout) {
			b.setLayoutData = gd;
		} else {
			parent.setLayoutData = gd;
		}
		b.setText = text;
		auto sa = new Push;
		sa.push = push;
		b.addSelectionListener(sa);
		return b;
	}
	private class Push : SelectionAdapter {
		private void delegate() push;
		override void widgetSelected(SelectionEvent e) {
			push();
		}
	}
	private class Mod : SelectionAdapter, ModifyListener {
		override void widgetSelected(SelectionEvent e) {
			mod();
		}
		override void modifyText(ModifyEvent e) {
			mod();
		}
		void mod() {
			if (!ignoreMod) applyEnabled;
		}
	}
	private Mod _mod = null;
	/// ctrlの押下時・テキスト変更時に適用ボタンを有効化する。
	void mod(C)(C ctrl) {
		if (!_mod) {
			_mod = new Mod;
		}
		static if (is(typeof(ctrl.modEvent))) {
			ctrl.modEvent ~= &_mod.mod;
		} else static if (is(typeof(ctrl.addModifyListener(_mod)))) {
			ctrl.addModifyListener(_mod);
		} else static if (is(typeof(ctrl.addSelectionListener(_mod)))) {
			ctrl.addSelectionListener(_mod);
		} else static assert (0);
	}
	/// trueの時は適用ボタンの有効化を行わない。
	protected bool ignoreMod = false;
	/// ignoreModを反転して返す。
	const
	bool catchMod() {return !ignoreMod;}

	protected Shell getShell() {return _win;}
	private Button _okBtn;
	private bool _applied = false;
	private Button _apply = null;
	private int _imeMode = SWT.NONE;
	private bool _inCloseEvent = false;
	private class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			if (_inCloseEvent) return;
			_inCloseEvent = true;
			scope (exit) _inCloseEvent = false;
			if (_forceCancel) {
				e.doit = true;
				foreach (dlg; closeEvent) {
					dlg();
				}
				return;
			}
			_imeMode = _win.getImeInputMode;
			if (_ret) {
				foreach (dlg; applyEvent) {
					dlg();
				}
			}
			bool cancel;
			_ret = close(_ret, cancel);
			e.doit = !cancel;
			if (e.doit && _size) {
				auto s = _win.getSize;
				_size.width = s.x;
				_size.height = s.y;
			}
			if (e.doit) {
				if (_ret) {
					foreach (dlg; appliedEvent) {
						dlg();
					}
				}
				foreach (dlg; closeEvent) {
					dlg();
				}
				auto parShl = cast(Shell) _win.getParent;
				if (parShl) parShl.setImeInputMode = _imeMode;
			}
		}
	}
	private bool _ret = false;
	private void ok() {
		if (_inCloseEvent) return;
		_ret = true;
		_win.close;
	}
	private bool _enterClose;
	void enterClose(bool value) {_enterClose = value;}
	bool enterClose() {return _enterClose;}
	private bool _ffio = false;
	void firstFocusIsOK(bool ffio) {_ffio = true;}
	bool firstFocusIsOK() {return _ffio;}
	private void cancel() {
		if (_inCloseEvent) return;
		_win.close;
	}
	private bool _forceCancel = false;
	void forceCancel() {
		if (_inCloseEvent) return;
		_forceCancel = true;
		if (!_win.isDisposed) _win.close();
	}

	bool open() {
		setup(_area);
		if (_enterClose) {
			_win.setDefaultButton = _okBtn;
		}
		if (_size) {
			auto p = new Point(_size.width, _size.height);
			if (p.x == SWT.DEFAULT || p.y == SWT.DEFAULT) {
				auto cs = _win.computeSize(SWT.DEFAULT, SWT.DEFAULT);
				p.x = p.x == SWT.DEFAULT ? cs.x : p.x;
				p.y = p.y == SWT.DEFAULT ? cs.y : p.y;
			}
			_win.setSize = p;
		} else {
			_win.pack;
		}
		auto par = cast(Shell) _win.getParent;
		if (par) {
			auto b = par.getBounds;
			auto p = _win.getSize;
			int x = b.x + (b.width - p.x) / 2;
			int y = b.y + (b.height - p.y) / 2;
			intoDisplay(x, y, p.x, p.y);
			_win.setLocation = new Point(x, y);
			_imeMode = par.getImeInputMode;
			_win.setImeInputMode = _imeMode;
		}
		if (_apply) _apply.setEnabled = false;
		_win.open;
		if (firstFocusIsOK) _okBtn.setFocus;
		opened;
		if (!_modal) return false;
		auto d = _win.getDisplay;
		scope (failure) {
			if (!_win.isDisposed) _win.close;
		}
		while (!_win.isDisposed) {
			try {
				if (!d.readAndDispatch) d.sleep;
			} catch (Throwable e) {
				throw e;
			}
		}
		if (par) {
			par.setImeInputMode = _imeMode;
		}
		return _ret || _applied;
	}
	void active() {
		if (!_win.isDisposed) {
			_win.setActive();
		}
	}
	bool close() {
		if (_inCloseEvent) return false;
		_win.close();
		return _win.isDisposed;
	}

	private void applyFunc() {
		foreach (dlg; applyEvent) {
			dlg();
		}
		if (apply) {
			_apply.setEnabled = false;
			_applied = true;
			foreach (dlg; appliedEvent) {
				dlg();
			}
		}
	}
	private void check() {
		bool enbl = true;
		for (size_t i = 0; enbl && i < _chk1.length; i++) {
			enbl &= _chk1[i].getText && _chk1[i].getText.length > 0;
		}
		for (size_t i = 0; enbl && i < _chk2.length; i++) {
			enbl &= _chk2[i].getText && _chk2[i].getText.length > 0;
		}
		for (size_t i = 0; enbl && i < _chk3.length; i++) {
			enbl &= _chk3[i].getText && _chk3[i].getText.length > 0;
		}
		_okBtn.setEnabled = enbl;
		if (_apply) _apply.setEnabled = _apply.getEnabled && enbl;
	}
	private class MListener : ModifyListener {
		override void modifyText(ModifyEvent e) {
			auto t = cast(Text) e.widget;
			check;
		}
	}
	protected final void applyEnabled() {
		check();
		if (_apply) _apply.setEnabled = _okBtn.getEnabled;
	}

	protected final void warning(string[] ws) {
		if ((_okBtn.getImage !is null) != (0 != ws.length)) {
			// FIXME:
			// 画像の有無を切り替えるとOKボタンの文字が
			// ずれてしまうため、作り直す
			auto parent = _okBtn.getParent;
			bool enbl = _okBtn.getEnabled;
			bool focus = _okBtn.isFocusControl;
			_okBtn.dispose();
			_okBtn = createButton(parent, _prop.msgs.dlgTextOK, &this.ok);
			if (_enterClose) {
				_win.setDefaultButton = _okBtn;
			}
			_okBtn.setEnabled = enbl;
			if (focus) _okBtn.setFocus;
			parent.layout(true);
		}
		if (ws.length) {
			_okBtn.setImage = _prop.images.warning;
			_okBtn.setToolTipText = std.string.join(ws, "\n");
		} else {
			_okBtn.setImage = null;
			_okBtn.setToolTipText = null;
		}
	}

	protected void checkerImpl(T)(T text) {
		check;
		text.addModifyListener = new MListener;
	}
	private Combo[] _chk1;
	private CCombo[] _chk2;
	private Text[] _chk3;
	protected void checker(Combo text) {
		_chk1 ~= text;
		checkerImpl(text);
	}
	protected void checker(CCombo text) {
		_chk2 ~= text;
		checkerImpl(text);
	}
	protected void checker(Text text) {
		_chk3 ~= text;
		checkerImpl(text);
	}
	protected void setup(Composite area);
	protected bool apply() {
		return true;
	}
	protected bool close(bool ok, out bool cancel) {
		if (_hasApply) {
			if (ok) {
				ok = apply;
				if (!ok) cancel = true;
			}
			return ok;
		} else {
			cancel = false;
			return close(ok);
		}
	}
	protected bool close(bool ok) {return ok;}
	protected void opened() {}
}
