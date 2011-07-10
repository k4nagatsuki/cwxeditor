
module cwx.editor.gui.dwt.textdialog;

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
import org.eclipse.swt.graphics.Image;
import java.lang.all;

class TextDialog : AbsDialog {
private:
	Props _prop;
	string _text;
	Text _viewer;

public:
	this(Props prop, Shell shell, string title, Image icon, string text, DSize size = null) {
		_prop = prop;
		_text = text;
		super(prop, shell, title, icon, true, size, false, false);
		enterClose = true;
		firstFocusIsOK = true;
	}

protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout = cl;
		_viewer = new Text(area, SWT.BORDER | SWT.MULTI | SWT.READ_ONLY | SWT.WRAP | SWT.V_SCROLL);
		_viewer.setText = _text;
		auto font = _viewer.getFont;
		auto fSize = font ? cast(uint) font.getFontData[0].height : 0;
		_viewer.setFont = new Font(Display.getCurrent, dwtData(_prop.looks.textDlgFont(fSize)));
	}
	override bool close(bool ok) {
		_viewer.getFont.dispose;
		return ok;
	}
}
