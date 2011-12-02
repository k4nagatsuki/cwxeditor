
module cwx.editor.gui.dwt.smalldialogs;

import cwx.utils;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;

import std.string;

import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.DirectoryDialog;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Link;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.program.Program;

class CreateScenarioDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	Text _name;
	Combo _skinC;
	string _nameVal, _skinVal, _classicFolder;

public:
	this (Commons comm, Props prop, Shell shell) {
		_comm = comm;
		_prop = prop;
		super(_prop, shell, _prop.msgs.dlgTitNewScenario, _prop.images.menuNew, true, _prop.var.newScDlg);
		enterClose = true;
	}

	string name() {
		return _nameVal;
	}
	string skin() {
		return _skinVal;
	}
	bool legacy() {return _skinVal.length == 0;}
	string classicFolder() {
		return _classicFolder;
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
		cl.fillHorizontal = true;
		area.setLayout = cl;
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			auto l = new Label(comp, SWT.NONE);
			l.setText = _prop.msgs.scenarioName;
			_name = new Text(comp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _name, &catchMod);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData = gd;
			checker(_name);
		}
		{
			auto l = new Label(comp, SWT.NONE);
			l.setText = _prop.msgs.type;
			_skinC = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_skinC.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto skins = skinTable(_prop).keys;
			if (_prop.var.etc.logicalSort) {
				skins = sort!(ncmp)(skins);
			} else {
				skins = sort!(cmp)(skins);
			}
			foreach (type; skins) {
				_skinC.add(type);
			}
			if (!_skinC.getItemCount) {
				// スキンが無い
				_skinC.add(_prop.var.etc.defaultSkin);
			}
			if (_prop.var.etc.canCreateClassic) {
				_skinC.add(_prop.msgs.classic);
			}
			_skinC.setText = _prop.var.etc.defaultSkin;
			if (_skinC.getSelectionIndex == -1) _skinC.select = 0;
			checker(_skinC);
		}
	}

	override bool close(bool ok, out bool cancel) {
		if (ok) {
			_nameVal = _name.getText;
			if (_prop.var.etc.canCreateClassic && _skinC.getSelectionIndex == _skinC.getItemCount - 1) {
				_skinVal = "";
				auto dlg = new DirectoryDialog(getShell);
				dlg.setText = _prop.msgs.newClassicDir;
				dlg.setMessage = _prop.msgs.newClassicDirDesc;
				dlg.setFilterPath = _prop.var.etc.scenarioPath;
				while (true) {
					auto path = dlg.open;
					if (path) {
						if (clistdir(path).length) {
							auto q = new MessageBox(getShell, SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
							q.setText = _prop.msgs.dlgTitQuestion;
							q.setMessage = _prop.msgs.notEmptyDir(path);
							if (SWT.OK != q.open) continue;
						}
						_prop.var.etc.scenarioPath = dlg.getFilterPath;
						_classicFolder = path;
					} else {
						ok = false;
						cancel = true;
					}
					break;
				}
			} else {
				_skinVal = _skinC.getText;
			}
		}
		return ok;
	}
}

class VersionDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	class OpenLink : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto prog = Program.findProgram("html");
			if (prog) prog.execute(e.text);
		}
	}
public:
	this(Commons comm, Props prop, Shell shell) {
		super(prop, shell, true, prop.msgs.dlgTitVersion, prop.images.menuVersion, false, null, false, false);
		_comm = comm;
		_prop = prop;
		enterClose = true;
		firstFocusIsOK = true;
	}
protected:
	override void setup(Composite area) {
		auto gl = new GridLayout(2, false);
		gl.marginWidth = 10;
		gl.horizontalSpacing = 15;
		area.setLayout = gl;
		auto d = Display.getCurrent;
		auto img = new Label(area, SWT.CENTER);
		img.setImage = _prop.images.icon;
		auto gd = new GridData;
		auto rect = _prop.images.icon.getBounds;
		gd.widthHint = rect.width;
		gd.heightHint = rect.height;
		gd.verticalSpan = 2;
		img.setLayoutData = gd;
		auto ln = new Link(area, SWT.NONE);
		ln.setText = _prop.msgs.application ~ " / " ~ _prop.msgs.appVersion ~ "\n"
			~ "<a>" ~ _prop.msgs.appWebSiteURI ~ "</a>\n"
			~ _prop.msgs.appDesc;
		ln.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		ln.addSelectionListener(new OpenLink);
		auto build = new Text(area, SWT.READ_ONLY | SWT.BORDER | SWT.MULTI);
		createTextMenu!Text(_comm, _prop, build, null);
		build.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		build.setText = _prop.msgs.appBuild;
	}
}

class ErrorDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private string _desc;

	this (Commons comm, Props prop, Shell shell, string desc) {
		auto size = new class DSize {
			void width(int v) {}
			void height(int v) {}
			int width() {return 600;}
			int height() {return 400;}
		};
		auto info = ButtonInfo(prop.msgs.shutdown, {std.c.stdlib.exit(0);});
		super (prop, shell, false, prop.msgs.dlgTitError, shell.getImage, true, size, false, false, [info]);
		_comm = comm;
		_prop = prop;
		_desc = desc;
	}

	override void setup(Composite area) {
		auto d = area.getDisplay;
		auto gl = new GridLayout(2, false);
		gl.horizontalSpacing = 0;
		area.setLayout = gl;

		{
			auto comp = new Composite(area, SWT.NONE);
			auto cgl = new GridLayout(1, true);
			cgl.marginWidth = 10;
			cgl.marginHeight = 10;
			comp.setLayout = cgl;
			auto img = new Label(comp, SWT.NONE);
			img.setImage = d.getSystemImage(SWT.ICON_ERROR);
		}
		auto l = new Label(area, SWT.WRAP);
		l.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		l.setText = _prop.msgs.unknownError;

		auto msg = new Text(area, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.V_SCROLL | SWT.READ_ONLY);
		createTextMenu!Text(_comm, _prop, msg, null);
		auto msgL = new GridData(GridData.FILL_BOTH);
		msgL.horizontalSpan = 2;
		msg.setLayoutData = msgL;
		msg.setText = _desc;
	}
}
