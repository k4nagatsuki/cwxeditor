
module cwx.editor.gui.dwt.scripterrordialog;

import cwx.utils;
import cwx.script;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;

import std.array;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

class ScriptErrorDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	Control _parent;
	CWXScriptException _ex;
	string _base;
	Text _result;
	DisposeListener _parentClose;
	const(CompileOption) _opt;

	class ParentClose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			forceCancel();
		}
	}

	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_result.getFont().dispose();
			_parent.removeDisposeListener(_parentClose);
		}
	}
public:
	this (Commons comm, Props prop, Control parent, CWXScriptException ex, string base, in CompileOption opt) {
		_comm = comm;
		_prop = prop;
		_parent = parent;
		_ex = ex;
		_base = base;
		_opt = opt;
		super(prop, parent.getShell(), false, prop.msgs.dlgTitScriptError, prop.images.script, true, prop.var.scriptDlg, false, false);
		enterClose = true;
		firstFocusIsOK = true;
		_parentClose = new ParentClose;
		parent.addDisposeListener(_parentClose);
	}

protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		string buf = _prop.msgs.scriptError ~ "\n";
		auto lines = splitLines!string(_base);
		auto lines2 = _base != _ex.text ? splitLines!string(_ex.text) : lines;
		foreach (err; _ex.errors) {
			buf ~= "\n";
			buf ~= err.message ~ "\n";
			debug {
				buf ~= .format("Debug info: %s, %d\n", err.file, err.line);
			}
			string line, lStr;
			if ((err.errLine - _opt.startLine) < _opt.addLines) {
				line = lines2[err.errLine - _opt.startLine];
				lStr = .format("Line %s: ", "---");
			} else {
				line = lines[err.errLine];
				lStr = .format("Line %d: ", err.errLine + 1);
			}
			buf ~= lStr;
			buf ~= line;
			string btm;
			foreach (i, dchar c; line) {
				if (btm.length < err.errPos) {
					if (c == '\t') {
						btm ~= "\t";
					} else {
						char[] str;
						std.utf.encode(str, c);
						btm ~= rightJustify("", lengthJ(str));
					}
				}
			}
			buf ~= "\n";
			buf ~= rightJustify("", lStr.length) ~ btm ~ "^";
		}
		if (_ex.over100) {
			buf ~= "\n";
			buf ~= _prop.msgs.scriptErrorOver100Error ~ "\n";
		}
		_result = new Text(area, SWT.BORDER | SWT.MULTI | SWT.READ_ONLY | SWT.WRAP | SWT.V_SCROLL);
		createTextMenu!Text(_comm, _prop, _result, null);
		_result.setText(buf);
		auto font = _result.getFont();
		auto fSize = font ? cast(uint) font.getFontData()[0].height : 0;
		_result.setFont(new Font(Display.getCurrent(), dwtData(_prop.looks.scriptErrorFont(fSize))));
		_result.addDisposeListener(new Dispose);
	}
}
