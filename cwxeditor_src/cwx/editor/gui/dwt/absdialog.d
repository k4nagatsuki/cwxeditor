
module cwx.editor.gui.dwt.absdialog;

import cwx.utils;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;

import std.compat;

import dwt.all;

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
	this (Props prop, Shell parent, string text, Image img, bool resizable, DSize size = null) {
		_size = size;
		_win = new Shell(parent, (resizable ? DWT.SHELL_TRIM : DWT.DIALOG_TRIM) | DWT.APPLICATION_MODAL);
		_win.setText = text;
		_win.setImage = img;
		_win.setLayout = zeroGridLayout(1, true);
		_win.addShellListener(new SListener);

		_area = new Composite(_win, DWT.NONE);
		_area.setLayoutData = new GridData(GridData.FILL_BOTH);

		auto sep = new Label(_win, DWT.SEPARATOR | DWT.HORIZONTAL);
		sep.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

		auto buttons = new Composite(_win, DWT.NONE);
		buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
		buttons.setLayout = new GridLayout(2, true);
		Button createButton(string text, void delegate() push) {
			auto b = new Button(buttons, DWT.PUSH);
			b.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
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
		_okBtn = createButton(prop.msgs.dlgTextOK, &ok);
		createButton(prop.msgs.dlgTextCancel, &cancel);
	}
	protected Shell getShell() {return _win;}
	private Button _okBtn;
	private class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			bool cancel;
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
	private void cancel() {_win.close;}
	bool open() {
		setup(_area);
		if (_size) {
			auto p = new Point(_size.width, _size.height);
			if (p.x == DWT.DEFAULT || p.y == DWT.DEFAULT) {
				auto cs = _win.computeSize(DWT.DEFAULT, DWT.DEFAULT);
				p.x = p.x == DWT.DEFAULT ? cs.x : p.x;
				p.y = p.y == DWT.DEFAULT ? cs.y : p.y;
			}
			_win.setSize = p;
		} else {
			_win.pack;
		}
		if (_win.getParent) {
			auto b = _win.getParent.getBounds;
			auto p = _win.getSize;
			_win.setLocation = new Point(b.x + (b.width - p.x) / 2, b.y + (b.height - p.y) / 2);
		}
		_win.open;
		auto d = _win.getDisplay;
		while (!_win.isDisposed) {
			if (!d.readAndDispatch) d.sleep;
		}
		return _ret;
	}
	private void check() {
		bool enbl = false;
		for (size_t i = 0; !enbl && i < _chk1.length; i++) {
			enbl |= _chk1[i].getText && _chk1[i].getText.length > 0;
		}
		for (size_t i = 0; !enbl && i < _chk2.length; i++) {
			enbl |= _chk2[i].getText && _chk2[i].getText.length > 0;
		}
		for (size_t i = 0; !enbl && i < _chk3.length; i++) {
			enbl |= _chk3[i].getText && _chk3[i].getText.length > 0;
		}
		_okBtn.setEnabled = enbl;
	}
	private class MListener : ModifyListener {
		override void modifyText(ModifyEvent e) {
			auto t = cast(Text) e.widget;
			check;
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
	protected bool close(bool ok, out bool cancel) {
		cancel = false;
		return close(ok);
	}
	protected bool close(bool ok) {return ok;}
}
