
module cwx.editor.gui.dwt.textdialog;

import cwx.utils;
import cwx.script;
import cwx.structs;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;

import std.array;
import std.string;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import java.lang.all;

class TextDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;
	bool _readOnly;
	string _text;
	Text _viewer;

public:
	this(Commons comm, Props prop, Shell shell, string title, Image icon, string text, bool readOnly = true, DSize size = null) {
		_comm = comm;
		_prop = prop;
		_readOnly = readOnly;
		_text = text;
		super(prop, shell, title, icon, true, size, false, !readOnly);
		if (readOnly) {
			enterClose = true;
			firstFocusIsOK = true;
		}
	}

	@property
	string text() {
		return wrapReturnCode(_viewer.getText());
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		int style = SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.V_SCROLL;
		if (_readOnly) style |= SWT.READ_ONLY;
		_viewer = new Text(area, style);
		createTextMenu!Text(_comm, _prop, _viewer, &catchMod);
		_viewer.setText(_text);
		if (!_readOnly) {
			_viewer.setSelection(_text.length);
		}
		auto font = _viewer.getFont();
		auto fSize = font ? cast(uint) font.getFontData()[0].height : 0;
		_viewer.setFont(new Font(Display.getCurrent(), dwtData(_prop.looks.textDlgFont(fSize))));
		closeEvent ~= () {
			_viewer.getFont().dispose();
		};
	}
}
