
module cwx.editor.gui.dwt.absdialog;

import cwx.utils;
import cwx.structs;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;

import org.eclipse.swt.all;

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

	/// サイズが計算された際に呼び出される。
	void delegate(int x, int y, int w, int h)[] calcBoundsEvent;
	/// ダイアログが開かれた際に呼び出される。
	void delegate()[] openedEvent;

	private Props _prop;
	private Shell _win;
	private DSize _size;
	private Composite _area;
	private Composite _addition;
	private Composite _rightGroup;
	private bool _modal;
	private bool _hasApply;
	this (Props prop, Shell parent, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true, ButtonInfo[] button = []) {
		this (prop, parent, true, text, img, resizable, size, apply, cancel, button);
	}
	this (Props prop, Shell parent, bool modal, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true, ButtonInfo[] button = [], bool rightGroup = false) {
		_prop = prop;
		_size = size;
		_modal = modal;
		_hasApply = apply;
		int style = resizable ? SWT.SHELL_TRIM : SWT.DIALOG_TRIM;
		if (modal) {
			style |= SWT.APPLICATION_MODAL;
		}
		_win = new Shell(parent, style);
		_win.setText(text);
		_win.setImage(img);
		if (rightGroup) {
			_win.setLayout(zeroGridLayout(3, false));
		} else {
			_win.setLayout(zeroGridLayout(2, false));
		}
		_win.addShellListener(new SListener);

		_area = new Composite(_win, SWT.NONE);
		auto agd = new GridData(GridData.FILL_BOTH);
		agd.horizontalSpan = 2;
		_area.setLayoutData(agd);

		if (rightGroup) {
			_rightGroup = new Composite(_win, SWT.NONE);
			auto rgd = new GridData(GridData.FILL_VERTICAL);
			rgd.verticalSpan = 3;
			rgd.widthHint = 0;
			rgd.heightHint = 0;
			_rightGroup.setLayoutData(rgd);
		}

		auto sep = new Label(_win, SWT.SEPARATOR | SWT.HORIZONTAL);
		auto sgd = new GridData(GridData.FILL_HORIZONTAL);
		sgd.horizontalSpan = 2;
		sep.setLayoutData(sgd);

		_addition = new Composite(_win, SWT.NONE);
		_addition.setLayout(new GridLayout(1, true));
		_addition.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto buttons = new Composite(_win, SWT.NONE);
		buttons.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
		int gll = 1;
		if (apply) gll++;
		if (cancel) gll++;
		gll += button.length;
		buttons.setLayout(new GridLayout(gll, true));
		auto okComp = new Composite(buttons, SWT.NONE);
		okComp.setLayout(new FillLayout);
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
	@property
	Composite addition() {return _addition;}
	@property
	Composite rightGroup() {return _rightGroup;}
	void rightGroupSize(int width, int height) {
		if (!_rightGroup) throw new Exception("rightGroup is null", __FILE__, __LINE__);

		if (getShell().isVisible()) getShell().setRedraw(false);
		scope (exit) {
			if (getShell().isVisible()) getShell().setRedraw(true);
		}
		auto rgd = cast(GridData) _rightGroup.getLayoutData();
		rgd.widthHint = width;
		rgd.heightHint = height;
		_rightGroup.getParent().layout();
	}

	private Button createButton(Composite parent, string text, void delegate() push) {
		auto b = new Button(parent, SWT.PUSH);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = 85;
		if (cast(GridLayout) parent.getLayout()) {
			b.setLayoutData(gd);
		} else {
			parent.setLayoutData(gd);
		}
		b.setText(text);
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
			if (!ignoreMod) applyEnabled();
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
	@property
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
			_imeMode = _win.getImeInputMode();
			if (_ret) {
				foreach (dlg; applyEvent) {
					dlg();
				}
			}
			bool cancel;
			_ret = close(_ret, cancel);
			e.doit = !cancel;
			if (e.doit && _size) {
				saveWin();
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
				auto parShl = cast(Shell) _win.getParent();
				if (parShl) parShl.setImeInputMode(_imeMode);
			}
		}
	}
	private void saveWin() {
		if (!_size) return;
		auto ws = cast(WSize) _size;
		auto p = _win.getParent();
		if (!_win.getMaximized() && !_win.getMinimized()) {
			auto b = _win.getBounds();
			_size.width = b.width;
			_size.height = b.height;
			if (ws) {
				if (p) {
					auto pb = p.getBounds();
					ws.x = b.x - pb.x;
					ws.y = b.y - pb.y;
				} else {
					ws.x = b.x;
					ws.y = b.y;
				}
			}
		}
		if (ws) {
			ws.maximized = _win.getMaximized();
		}
	}
	private bool _ret = false;
	private void ok() {
		if (_inCloseEvent) return;
		_ret = true;
		_win.close();
	}
	private bool _enterClose;
	@property
	void enterClose(bool value) {_enterClose = value;}
	@property
	bool enterClose() {return _enterClose;}
	private bool _ffio = false;
	@property
	void firstFocusIsOK(bool ffio) {_ffio = true;}
	@property
	bool firstFocusIsOK() {return _ffio;}
	private void cancel() {
		if (_inCloseEvent) return;
		_win.close();
	}
	private bool _forceCancel = false;
	void forceCancel() {
		if (_inCloseEvent) return;
		_forceCancel = true;
		if (!_win.isDisposed()) _win.close();
	}

	private void calcBounds() {
		auto par = _win.getParent();
		auto winProps = cast(WSize) _size;
		scope wp = _win.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		int width = !_size || _size.width == SWT.DEFAULT ? wp.x : _size.width;
		int height = !_size || _size.height == SWT.DEFAULT ? wp.y : _size.height;
		int x, y;
		if (par) {
			auto pb = par.getBounds();
			if (winProps && winProps.x != SWT.DEFAULT) {
				x = winProps.x + pb.x;
			} else {
				x = pb.x + (pb.width - width) / 2;
			}
			if (winProps && winProps.y != SWT.DEFAULT) {
				y = winProps.y + pb.y;
			} else {
				y = pb.y + (pb.height - height) / 2;
			}
		} else {
			auto pb = _win.getDisplay().getBounds();
			if (winProps && winProps.x != SWT.DEFAULT) {
				x = winProps.x;
			} else {
				x = (pb.width - width) / 2;
			}
			if (winProps && winProps.y != SWT.DEFAULT) {
				y = winProps.y;
			} else {
				y = (pb.height - height) / 2;
			}
		}
		intoDisplay(x, y, width, height);
		_win.setBounds(x, y, width, height);
		if (winProps) {
			_win.setMaximized(winProps.maximized);
		}
		_win.layout(true);
		foreach (dlg; calcBoundsEvent) {
			dlg(x, y, width, height);
		}
	}
	bool open() {
		setup(_area);
		if (_enterClose) {
			_win.setDefaultButton(_okBtn);
		}
		calcBounds();
		auto par = cast(Shell) _win.getParent();
		if (par) {
			_imeMode = par.getImeInputMode();
			_win.setImeInputMode(_imeMode);
		}
		if (_apply) _apply.setEnabled(false);
		_win.open();
		if (firstFocusIsOK) _okBtn.setFocus();
		opened();
		foreach (dlg; openedEvent) {
			dlg();
		}
		if (!_modal) return false;
		auto d = _win.getDisplay();
		scope (failure) {
			if (!_win.isDisposed()) _win.close();
		}
		while (!_win.isDisposed()) {
			try {
				if (!d.readAndDispatch()) d.sleep();
			} catch (Throwable e) {
				throw e;
			}
		}
		if (par) {
			par.setImeInputMode(_imeMode);
		}
		return _ret || _applied;
	}
	void active() {
		if (!_win.isDisposed()) {
			_win.setActive();
		}
	}
	bool close() {
		if (_inCloseEvent) return false;
		_win.close();
		return _win.isDisposed();
	}

	private void applyFunc() {
		foreach (dlg; applyEvent) {
			dlg();
		}
		if (apply()) {
			_apply.setEnabled(false);
			_applied = true;
			foreach (dlg; appliedEvent) {
				dlg();
			}
		}
	}
	private void check() {
		bool enbl = true;
		for (size_t i = 0; enbl && i < _chk1.length; i++) {
			enbl &= _chk1[i].getText() && _chk1[i].getText().length > 0;
		}
		for (size_t i = 0; enbl && i < _chk2.length; i++) {
			enbl &= _chk2[i].getText() && _chk2[i].getText().length > 0;
		}
		for (size_t i = 0; enbl && i < _chk3.length; i++) {
			enbl &= _chk3[i].getText() && _chk3[i].getText().length > 0;
		}
		_okBtn.setEnabled(enbl);
		if (_apply) _apply.setEnabled(_apply.getEnabled() && enbl);
	}
	private class MListener : ModifyListener {
		override void modifyText(ModifyEvent e) {
			auto t = cast(Text) e.widget;
			check();
		}
	}
	protected final void applyEnabled() {
		check();
		if (_apply) _apply.setEnabled(_okBtn.getEnabled());
	}

	@property
	protected final void warning(string[] ws) {
		if ((_okBtn.getImage() !is null) != (0 != ws.length)) {
			// FIXME:
			// 画像の有無を切り替えるとOKボタンの文字が
			// ずれてしまうため、作り直す
			auto parent = _okBtn.getParent();
			bool enbl = _okBtn.getEnabled();
			bool focus = _okBtn.isFocusControl();
			_okBtn.dispose();
			_okBtn = createButton(parent, _prop.msgs.dlgTextOK, &this.ok);
			if (_enterClose) {
				_win.setDefaultButton(_okBtn);
			}
			_okBtn.setEnabled(enbl);
			if (focus) _okBtn.setFocus();
			parent.layout(true);
		}
		if (ws.length) {
			_okBtn.setImage(_prop.images.warning);
			_okBtn.setToolTipText(std.string.join(ws, "\n"));
		} else {
			_okBtn.setImage(null);
			_okBtn.setToolTipText(null);
		}
	}

	protected void checkerImpl(T)(T text) {
		check();
		text.addModifyListener(new MListener);
	}
	private Combo[] _chk1;
	private CCombo[] _chk2;
	private Text[] _chk3;
	@property
	protected void checker(Combo text) {
		_chk1 ~= text;
		checkerImpl(text);
	}
	@property
	protected void checker(CCombo text) {
		_chk2 ~= text;
		checkerImpl(text);
	}
	@property
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
				ok = apply();
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
