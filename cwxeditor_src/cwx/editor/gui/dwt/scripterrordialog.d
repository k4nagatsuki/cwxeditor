
module cwx.editor.gui.dwt.scripterrordialog;

import cwx.utils;
import cwx.script;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;

import std.array;
import std.string;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.graphics.Font;
import java.lang.all;

class ScriptErrorDialog : AbsDialog {
private:
	Props _prop;
	CWXScriptException _ex;
	Text _result;

public:
	this(Props prop, Shell shell, CWXScriptException ex) {
		_prop = prop;
		_ex = ex;
		super(prop, shell, prop.msgs.dlgTitScriptError, prop.images.script, true, prop.var.scriptDlg, false, false);
		enterClose = true;
		firstFocusIsOK = true;
	}

protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout = cl;
		string buf = _prop.msgs.scriptError ~ "\n";
		buf ~= _ex.msg ~ "\n";
		string lStr = .format("Line %d: ", _ex.errLine + 1);
		buf ~= lStr;
		auto line = splitlines(_ex.text)[_ex.errLine];
		buf ~= line;
		string btm;
		foreach (i, dchar c; line) {
			if (btm.length < _ex.errPos) {
				if (c == '\t') {
					btm ~= "\t";
				} else {
					char[] str;
					std.utf.encode(str, c);
					btm ~= rjustify("", lengthJ(str));
				}
			}
		}
		buf ~= "\n";
		buf ~= rjustify("", lStr.length) ~ btm ~ "^";
		_result = new Text(area, SWT.BORDER | SWT.MULTI | SWT.READ_ONLY | SWT.WRAP | SWT.V_SCROLL);
		_result.setText = buf;
		auto font = _result.getFont;
		auto fSize = font ? cast(uint) font.getFontData[0].height : 0;
		_result.setFont = new Font(Display.getCurrent, dwtData(_prop.looks.scriptErrorFont(fSize)));
	}
	override bool close(bool ok) {
		_result.getFont.dispose;
		return ok;
	}
}
