
module cwx.editor.gui.dwt.absdialog;

import cwx.utils;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;

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

abstract class AbsDialog {
	private Shell _win;
	private DSize _size;
	private Composite _area;
	this (Props prop, Shell parent, string text, Image img, bool resizable, DSize size = null, bool apply = false, bool cancel = true) {
		_size = size;
		_win = new Shell(parent, (resizable ? SWT.SHELL_TRIM : SWT.DIALOG_TRIM) | SWT.APPLICATION_MODAL);
		_win.setText = text;
		_win.setImage = img;
		_win.setLayout = zeroGridLayout(1, true);
		_win.addShellListener(new SListener);

		_area = new Composite(_win, SWT.NONE);
		_area.setLayoutData = new GridData(GridData.FILL_BOTH);

		auto sep = new Label(_win, SWT.SEPARATOR | SWT.HORIZONTAL);
		sep.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

		auto buttons = new Composite(_win, SWT.NONE);
		buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
		int gll = 1;
		if (apply) gll++;
		if (cancel) gll++;
		buttons.setLayout = new GridLayout(gll, true);
		Button createButton(string text, void delegate() push) {
			auto b = new Button(buttons, SWT.PUSH);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = 85;
			b.setLayoutData = gd;
			b.setText = text;
			auto sa = new class SelectionAdapter {
				private void delegate() push;
				override void widgetSelected(SelectionEvent e) {
					push();
				}
			};
			sa.push = push;
			b.addSelectionListener(sa);
			return b;
		}
		_okBtn = createButton(prop.msgs.dlgTextOK, &this.ok);
		if (apply) {
			_apply = createButton(prop.msgs.dlgTextApply, &this.applyFunc);
		}
		if (cancel) {
			createButton(prop.msgs.dlgTextCancel, &this.cancel);
		}
	}
	protected Shell getShell() {return _win;}
	private Button _okBtn;
	private bool _applied = false;
	private Button _apply = null;
	private int _imeMode = SWT.NONE;
	private class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			bool cancel;
			_imeMode = _win.getImeInputMode;
			_ret = close(_ret, cancel);
			e.doit = !cancel;
			if (e.doit && _size) {
				auto s = _win.getSize;
				_size.width = s.x;
				_size.height = s.y;
			}
		}
	}
	private bool _ret = false;
	private void ok() {
		_ret = true;
		_win.close;
	}
	private bool _enterClose;
	void enterClose(bool value) {_enterClose = value;}
	bool enterClose() {return _enterClose;}
	private bool _ffio = false;
	void firstFocusIsOK(bool ffio) {_ffio = true;}
	bool firstFocusIsOK() {return _ffio;}
	private void cancel() {_win.close;}
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
		auto d = _win.getDisplay;
		while (!_win.isDisposed) {
			try {
				if (!d.readAndDispatch) d.sleep;
			} catch (Exception e) {
				_win.close;
				throw e;
			}
		}
		if (par) {
			par.setImeInputMode = _imeMode;
		}
		return _ret || _applied;
	}
	private void applyFunc() {
		if (apply) {
			_apply.setEnabled = false;
			_applied = true;
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
	}
	private class MListener : ModifyListener {
		override void modifyText(ModifyEvent e) {
			auto t = cast(Text) e.widget;
			check;
		}
	}
	protected final void applyEnabled() {
		_apply.setEnabled = true;
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
		cancel = false;
		return close(ok);
	}
	protected bool close(bool ok) {return ok;}
	protected void opened() {}
}
