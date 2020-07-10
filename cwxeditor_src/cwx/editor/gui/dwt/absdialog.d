
module cwx.editor.gui.dwt.absdialog;

import cwx.utils;
import cwx.structs;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;

import std.array;
import std.string;
import std.typecons;

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
	private void delegate(bool save) _clearSetupWin;

	private Composite _area;
	private Composite _addition;
	private Composite _rightGroup;
	private bool _modal;
	private bool _hasApply;
	private bool _forceApplyEnabled = false;
	this (Props prop, Shell parent, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true, ButtonInfo[] button = []) { mixin(S_TRACE);
		this (prop, parent, true, text, img, resizable, size, apply, cancel, button);
	}
	this (Props prop, Shell parent, bool modal, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true, ButtonInfo[] button = [], bool rightGroup = false) { mixin(S_TRACE);
		this (prop, parent, SWT.NONE, modal, text, img, resizable, size, apply, cancel, button, rightGroup);
	}
	this (Props prop, Shell parent, int styleFlag, bool modal, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true, ButtonInfo[] button = [], bool rightGroup = false) { mixin(S_TRACE);
		_prop = prop;
		_size = size;
		_modal = modal;
		_hasApply = apply;
		int style = resizable ? SWT.SHELL_TRIM : SWT.DIALOG_TRIM;
		if (modal) { mixin(S_TRACE);
			style |= SWT.APPLICATION_MODAL;
		}
		_win = new Shell(parent, style);
		_win.setText(text);
		_win.setImage(img);
		_win.setData(this);
		_win.addShellListener(new SListener);

		auto mainComp = new Composite(_win, SWT.NONE);
		mainComp.setLayout(zeroGridLayout(2, false));
		mainComp.setLayoutData(new GridData(GridData.FILL_BOTH));

		_area = new Composite(mainComp, SWT.NONE);
		auto agd = new GridData(GridData.FILL_BOTH);
		agd.horizontalSpan = 2;
		_area.setLayoutData(agd);

		auto sep = new Label(mainComp, SWT.SEPARATOR | SWT.HORIZONTAL);
		auto sgd = new GridData(GridData.FILL_HORIZONTAL);
		sgd.horizontalSpan = 2;
		sep.setLayoutData(sgd);

		_addition = new Composite(mainComp, SWT.NONE);
		_addition.setLayout(normalGridLayout(1, true));
		_addition.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto buttons = new Composite(mainComp, SWT.NONE);
		buttons.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
		int gll = 1;
		if (!(styleFlag & SWT.READ_ONLY)) { mixin(S_TRACE);
			if (apply) gll++;
			if (cancel) gll++;
		}
		gll += button.length;
		buttons.setLayout(normalGridLayout(gll, true));
		auto okComp = new Composite(buttons, SWT.NONE);
		okComp.setLayout(new FillLayout);
		if (styleFlag & SWT.READ_ONLY) { mixin(S_TRACE);
			_okBtn = createButton(okComp, prop.msgs.dlgTextClose, &this.cancel);
		} else { mixin(S_TRACE);
			_okBtn = createButton(okComp, prop.msgs.dlgTextOK, &this.ok);
			if (cancel) { mixin(S_TRACE);
				createButton(buttons, prop.msgs.dlgTextCancel, &this.cancel);
			}
			if (apply) { mixin(S_TRACE);
				_apply = createButton(buttons, prop.msgs.dlgTextApply, &this.forceApply);
			}
		}
		foreach (info; button) { mixin(S_TRACE);
			createButton(buttons, info.name, info.func);
		}

		useRightGroupImpl(rightGroup);
	}
	@property
	Composite addition() { return _addition; }
	@property
	Composite rightGroup() { return _rightGroup; }
	void rightGroupSize(int width, int height) { mixin(S_TRACE);
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
	void useRightGroup(bool rightGroup) { mixin(S_TRACE);
		if (rightGroup) { mixin(S_TRACE);
			if (_rightGroup) return;
		} else { mixin(S_TRACE);
			if (!_rightGroup) return;
		}
		useRightGroupImpl(rightGroup);
	}
	private void useRightGroupImpl(bool rightGroup) { mixin(S_TRACE);
		if (rightGroup) { mixin(S_TRACE);
			_win.setLayout(zeroGridLayout(2, false));
		} else { mixin(S_TRACE);
			_win.setLayout(zeroGridLayout(1, false));
		}
		if (rightGroup) { mixin(S_TRACE);
			_rightGroup = new Composite(_win, SWT.NONE);
			auto rgd = new GridData(GridData.FILL_VERTICAL);
			rgd.verticalSpan = 3;
			rgd.widthHint = 0;
			rgd.heightHint = 0;
			_rightGroup.setLayoutData(rgd);
		} else {
			if (_rightGroup) { mixin(S_TRACE);
				_rightGroup.dispose();
				_rightGroup = null;
			}
		}
	}

	void setImages(Image[] images) {
		_win.setImages(images);
	}

	private Button createButton(Composite parent, string text, void delegate() push) { mixin(S_TRACE);
		auto b = new Button(parent, SWT.PUSH);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = _prop.var.etc.buttonWidth;
		if (cast(GridLayout) parent.getLayout()) { mixin(S_TRACE);
			b.setLayoutData(gd);
		} else { mixin(S_TRACE);
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
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			push();
		}
	}
	private class Mod : SelectionAdapter, ModifyListener {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			mod();
		}
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			mod();
		}
		void mod() { mixin(S_TRACE);
			if (!ignoreMod) applyEnabled();
		}
	}
	private Mod _mod = null;
	/// ctrlの押下時・テキスト変更時に適用ボタンを有効化する。
	void mod(C)(C ctrl) { mixin(S_TRACE);
		if (!_mod) { mixin(S_TRACE);
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

	private bool _ignoreMod = false;
	/// trueの時は適用ボタンの有効化を行わない。
	@property
	protected void ignoreMod(bool v) { mixin(S_TRACE);
		_ignoreMod = v;
		if (_area && !_area.isDisposed()) _area.setEnabled(!v);
	}
	/// ditto
	@property
	protected void setIgnoreMod(bool v, bool setEnabled) { mixin(S_TRACE);
		_ignoreMod = v;
		if (setEnabled && _area && !_area.isDisposed()) _area.setEnabled(!v);
	}
	/// ditto
	@property
	const
	protected bool ignoreMod() { return _ignoreMod; }
	/// ignoreModを反転して返す。
	@property
	const
	bool catchMod() { return !ignoreMod; }

	protected Shell getShell() { return _win; }
	void title(string title) { _win.setText(title); }

	private Button _okBtn;
	private bool _applied = false;
	private Button _apply = null;
	private bool _inCloseEvent = false;
	private class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) { mixin(S_TRACE);
			if (_inCloseEvent) return;
			_inCloseEvent = true;
			scope (exit) _inCloseEvent = false;
			if (_forceCancel) { mixin(S_TRACE);
				e.doit = true;
				foreach (dlg; closeEvent) { mixin(S_TRACE);
					dlg();
				}
				return;
			}
			if (_ret) { mixin(S_TRACE);
				foreach (dlg; applyEvent) { mixin(S_TRACE);
					dlg();
				}
			}
			bool cancel;
			_ret = close(_ret, cancel);
			e.doit = !cancel;
			if (e.doit) { mixin(S_TRACE);
				if (_ret) { mixin(S_TRACE);
					foreach (dlg; appliedEvent.dup) { mixin(S_TRACE);
						dlg();
					}
				}
				foreach (dlg; closeEvent) { mixin(S_TRACE);
					dlg();
				}
			}
		}
	}

	/// 使用するサイズ情報を変更する。
	@property
	public void windowSizeInfo(DSize size) { mixin(S_TRACE);
		clearWindowSizeInfo();
		if (cast(WSize)_size && cast(WSize)size) {
			(cast(WSize)size).x = (cast(WSize)_size).x;
			(cast(WSize)size).y = (cast(WSize)_size).y;
		}
		_size = size;
		calcBounds(false);
	}
	public void clearWindowSizeInfo() { mixin(S_TRACE);
		if (!_clearSetupWin) return;
		_clearSetupWin(true);
		_clearSetupWin = null;
	}

	public void saveWin() { mixin(S_TRACE);
		if (!_size) return;
		auto ws = cast(WSize)_size;
		auto p = _win.getParent();
		if (!_win.getMaximized() && !_win.getMinimized()) { mixin(S_TRACE);
			auto b = _win.getBounds();
			_size.width = b.width;
			_size.height = b.height;
			if (ws) { mixin(S_TRACE);
				if (p) { mixin(S_TRACE);
					auto pb = p.getBounds();
					ws.x = b.x - pb.x;
					ws.y = b.y - pb.y;
				} else { mixin(S_TRACE);
					ws.x = b.x;
					ws.y = b.y;
				}
			}
		}
		if (ws) { mixin(S_TRACE);
			ws.maximized = _win.getMaximized();
		}
	}
	private bool _ret = false;
	private void ok() { mixin(S_TRACE);
		if (_inCloseEvent) return;
		_ret = true;
		_win.close();
	}
	private bool _enterClose;
	@property
	void enterClose(bool value) { _enterClose = value; }
	@property
	bool enterClose() { return _enterClose; }
	private bool _ffio = false;
	@property
	void firstFocusIsOK(bool ffio) { _ffio = true; }
	@property
	bool firstFocusIsOK() { return _ffio; }
	private void cancel() { mixin(S_TRACE);
		if (_inCloseEvent) return;
		_win.close();
	}
	private bool _forceCancel = false;
	void forceCancel() { mixin(S_TRACE);
		if (_inCloseEvent) return;
		_forceCancel = true;
		if (!_win.isDisposed()) _win.close();
	}

	private void calcBounds(bool setLocation) { mixin(S_TRACE);
		auto rect = .setupWindow(_win, _size, _clearSetupWin, setLocation, true);
		_win.layout(true, true);
		foreach (dlg; calcBoundsEvent) { mixin(S_TRACE);
			dlg(rect.x, rect.y, rect.width, rect.height);
		}
	}
	bool open() { mixin(S_TRACE);
		setup(_area);
		if (_enterClose) { mixin(S_TRACE);
			_win.setDefaultButton(_okBtn);
		}
		calcBounds(true);
		if (_apply && !_forceApplyEnabled) _apply.setEnabled(false);
		_forceApplyEnabled = false;
		_win.open();
		version (Windows) {
			// BUG: Google日本語入力を使用しており、IMEがオンの時にダイアログを開くと、
			//      全角スペースを入力しようとしても半角スペースが入る、
			//      バックスペースキーが一度だけ効かないなどの不具合が発生する
			//      バックスペースキー、CapsLockキー、半角/全角キーなど押す事でなぜか回避可能
			//      GoogleJapaneseInput-2.25.3700.0+24.7.9 with Windows 10 Pro 64-bit
			.asyncExec(_win.getDisplay(), { mixin(S_TRACE);
				if (!_win.isDisposed() && _win.getDisplay().getActiveShell() is _win) { mixin(S_TRACE);
					auto fc = _win.getDisplay().getFocusControl();
					if (cast(Spinner)fc) return;
					auto keyEvt = new Event;
					keyEvt.type = SWT.KeyDown;
					keyEvt.character = '\b';
					keyEvt.keyCode = SWT.BS;
					_win.getDisplay().post(keyEvt);
				}
			});
		}
		if (firstFocusIsOK) _okBtn.setFocus();
		opened();
		foreach (dlg; openedEvent) { mixin(S_TRACE);
			dlg();
		}
		if (!_modal) return false;
		auto d = _win.getDisplay();
		scope (failure) {
			if (!_win.isDisposed()) _win.close();
		}
		while (!_win.isDisposed()) { mixin(S_TRACE);
			version (nocatch) {
				if (!d.readAndDispatch()) d.sleep();
			} else {
				try { mixin(S_TRACE);
					if (!d.readAndDispatch()) d.sleep();
				} catch (Throwable e) {
					string s = printStackTrace();
					fdebugln(e);
					throw e;
				}
			}
		}
		return _ret || _applied;
	}
	void active() { mixin(S_TRACE);
		if (!_win.isDisposed()) { mixin(S_TRACE);
			_win.setActive();
		}
	}
	bool close() { mixin(S_TRACE);
		if (_inCloseEvent) return false;
		if (!_win.isDisposed()) { mixin(S_TRACE);
			_win.close();
		}
		return _win.isDisposed();
	}

	/// シナリオの編集に関わるダイアログでない場合はtrue。
	@property
	const
	bool noScenario() { return false; }

	@property
	bool noApply() { return _apply && _apply.getEnabled(); }

	private bool _forceApplying = false;
	@property
	const
	bool forceApplying() { return _forceApplying; }

	void forceApply() { mixin(S_TRACE);
		_forceApplying = true;
		scope (exit) _forceApplying = false;
		foreach (dlg; applyEvent.dup) { mixin(S_TRACE);
			dlg();
		}
		if (apply()) { mixin(S_TRACE);
			foreach (dlg; appliedEvent.dup) { mixin(S_TRACE);
				dlg();
			}
			_apply.setEnabled(false);
			_applied = true;
		}
	}
	protected void check() { mixin(S_TRACE);
		bool enbl = true;
		void checkImpl(T)(Tuple!(T, "widget", bool delegate(T), "check")[] chk) { mixin(S_TRACE);
			for (size_t i = 0; enbl && i < chk.length; i++) { mixin(S_TRACE);
				if (chk[i].check) { mixin(S_TRACE);
					enbl &= chk[i].check(chk[i].widget);
				} else { mixin(S_TRACE);
					enbl &= chk[i].widget.getText() && chk[i].widget.getText().length;
				}
			}
		}
		checkImpl!Combo(_chk1);
		checkImpl!CCombo(_chk2);
		checkImpl!Text(_chk3);
		_okBtn.setEnabled(enbl);
		if (_apply) _apply.setEnabled(_apply.getEnabled() && enbl);
	}
	private class MListener : ModifyListener {
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			check();
		}
	}
	protected final void applyEnabled() { mixin(S_TRACE);
		applyEnabled(false);
	}
	protected final void applyEnabled(bool force) { mixin(S_TRACE);
		check();
		if (_apply) { mixin(S_TRACE);
			_apply.setEnabled(_okBtn.getEnabled());
			_forceApplyEnabled |= force;
		}
	}

	@property
	protected final void warning(string[] ws) { mixin(S_TRACE);
		.asyncExec(_okBtn.getDisplay(), { mixin(S_TRACE);
			warningImpl(ws);
		});
	}
	private void warningImpl(string[] ws) { mixin(S_TRACE);
		if (!_okBtn || _okBtn.isDisposed()) return;
		if ((_okBtn.getImage() !is null) != (0 != ws.length)) { mixin(S_TRACE);
			// FIXME:
			// 画像の有無を切り替えるとOKボタンの文字が
			// ずれてしまうため、作り直す
			auto parent = _okBtn.getParent();
			bool enbl = _okBtn.getEnabled();
			bool focus = _okBtn.isFocusControl();
			_okBtn.dispose();
			_okBtn = createButton(parent, _prop.msgs.dlgTextOK, &this.ok);
			if (_enterClose) { mixin(S_TRACE);
				_win.setDefaultButton(_okBtn);
			}
			_okBtn.setEnabled(enbl);
			if (focus) _okBtn.setFocus();
			parent.layout(true);
		}
		if (ws.length) { mixin(S_TRACE);
			_okBtn.setImage(_prop.images.warning);
			_okBtn.setToolTipText(std.array.replace(std.string.join(ws, "\n"), "&", "&&"));
		} else { mixin(S_TRACE);
			_okBtn.setImage(null);
			_okBtn.setToolTipText(null);
		}
	}

	protected void checkerImpl(T)(T text) { mixin(S_TRACE);
		check();
		text.addModifyListener(new MListener);
	}
	private Tuple!(Combo, "widget", bool delegate(Combo), "check")[] _chk1;
	private Tuple!(CCombo, "widget", bool delegate(CCombo), "check")[] _chk2;
	private Tuple!(Text, "widget", bool delegate(Text), "check")[] _chk3;
	@property
	protected void checker(Combo text, bool delegate(Combo) check = null) { mixin(S_TRACE);
		_chk1 ~= typeof(_chk1[0])(text, check);
		checkerImpl(text);
	}
	@property
	protected void checker(CCombo text, bool delegate(CCombo) check = null) { mixin(S_TRACE);
		_chk2 ~= typeof(_chk2[0])(text, check);
		checkerImpl(text);
	}
	@property
	protected void checker(Text text, bool delegate(Text) check = null) { mixin(S_TRACE);
		_chk3 ~= typeof(_chk3[0])(text, check);
		checkerImpl(text);
	}
	protected void setup(Composite area);
	protected bool apply() { mixin(S_TRACE);
		return true;
	}
	protected bool close(bool ok, out bool cancel) { mixin(S_TRACE);
		if (_hasApply) { mixin(S_TRACE);
			if (ok) { mixin(S_TRACE);
				ok = apply();
				if (!ok) cancel = true;
			}
			return ok;
		} else { mixin(S_TRACE);
			cancel = false;
			return close(ok);
		}
	}
	protected bool close(bool ok) { return ok; }
	protected void opened() {}
}
