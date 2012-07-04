
module cwx.editor.gui.dwt.smalldialogs;

import cwx.utils;
import cwx.versioninfo;
import cwx.structs;
import cwx.menu;
import cwx.summary;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;

import std.string;
import std.path;
import std.file;

import org.eclipse.swt.all;

class CreateScenarioDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	Text _name;
	Combo _skinC;
	Combo _templateC;
	string _nameVal, _skinVal, _classicFolder;
	Button _baseSkin;
	Button _baseTemplate;
	ScTemplate[int] _tTbl;

	bool _useTemplate;
	Summary _fromTemplate = null;

public:
	this (Commons comm, Props prop, Shell shell, bool currentWin) {
		_comm = comm;
		_prop = prop;
		_useTemplate = currentWin;
		string title = currentWin ? _prop.msgs.dlgTitNewScenario : _prop.msgs.dlgTitNewScenarioAtNewWin;
		auto img = currentWin ? _prop.images.menu(MenuID.New) : _prop.images.menu(MenuID.NewAtNewWindow);
		super(_prop, shell, title, img, true, _prop.var.newScDlg);
		enterClose = true;
	}

	@property
	string name() {
		return _nameVal;
	}
	@property
	string skin() {
		return _skinVal;
	}
	@property
	Summary fromTemplate() {
		return _fromTemplate;
	}
	@property
	bool legacy() {return _skinVal.length == 0;}
	@property
	string classicFolder() {
		return _classicFolder;
	}

	static string createClassicDir(Props prop, Shell parent) {
		auto dlg = new DirectoryDialog(parent);
		dlg.setText(prop.msgs.newClassicDir);
		dlg.setMessage(prop.msgs.newClassicDirDesc);
		dlg.setFilterPath(prop.var.etc.scenarioPath);
		while (true) {
			auto path = dlg.open();
			if (path) {
				if (clistdir(path).length) {
					auto q = new MessageBox(parent, SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
					q.setText(prop.msgs.dlgTitQuestion);
					q.setMessage(.tryFormat(prop.msgs.notEmptyDir, path));
					if (SWT.OK != q.open()) continue;
				}
				prop.var.etc.scenarioPath = dlg.getFilterPath();
				return path;
			}
			break;
		}
		return null;
	}
	string createClassicDir() {
		_classicFolder = createClassicDir(_prop, getShell());
		return _classicFolder;
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
		cl.fillHorizontal = true;
		area.setLayout(cl);
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.scenarioName);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, true));

			_name = new Text(grp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _name, &catchMod);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData(gd);
			checker(_name);
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.initialize);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(2, false));

			void refRadio() {
				_skinC.setEnabled(_baseSkin.getSelection());
				_templateC.setEnabled(_baseTemplate.getSelection());
			}

			_baseSkin = new Button(grp, SWT.RADIO);
			_baseSkin.setText(_prop.msgs.type);
			listener(_baseSkin, SWT.Selection, &refRadio);
			_skinC = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_skinC.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			string[] skins;
			foreach (key, value; skinTable(_prop)) {
				skins ~= key;
			}
			// FIXME: リンクに失敗する
//			auto skins = skinTable(_prop).keys;
			if (_prop.var.etc.logicalSort) {
				skins = sort!(ncmp)(skins);
			} else {
				skins = sort!(cmp)(skins);
			}
			foreach (type; skins) {
				_skinC.add(type);
			}
			if (!_skinC.getItemCount()) {
				// スキンが無い
				_skinC.add(_prop.var.etc.defaultSkin);
			}
			if (_prop.var.etc.canCreateClassic) {
				_skinC.add(_prop.msgs.classic);
			}
			_skinC.setText(_prop.var.etc.defaultSkin);
			_skinVal = _prop.var.etc.defaultSkin;
			if (_skinC.getSelectionIndex() == -1) _skinC.select(0);

			_baseTemplate = new Button(grp, SWT.RADIO);
			_baseTemplate.setText(_prop.msgs.scenarioTemplate);
			listener(_baseTemplate, SWT.Selection, &refRadio);
			_templateC = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_templateC.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			auto tgd = new GridData(GridData.FILL_HORIZONTAL);
			tgd.widthHint = 0;
			_templateC.setLayoutData(tgd);
			foreach (i, sct; _prop.var.etc.scenarioTemplates) {
				_templateC.add(.tryFormat(_prop.msgs.templateDesc, sct.name, sct.path));
				if (cfnmatch(sct.path, _prop.var.etc.defaultScenarioTemplate)) {
					_templateC.select(i);
				}
				_tTbl[i] = sct;
			}
			bool tenbl = _templateC.getItemCount() > 0 && _useTemplate;
			if (!tenbl) _templateC.add(_prop.msgs.noTemplate);
			if (_templateC.getSelectionIndex() == -1) _templateC.select(0);
			_baseTemplate.setEnabled(tenbl);

			_baseSkin.setSelection(!tenbl || !_prop.var.etc.defaultIsTemplate);
			_baseTemplate.setSelection(!_baseSkin.getSelection());
			_skinC.setEnabled(_baseSkin.getSelection());
			_templateC.setEnabled(_baseTemplate.getSelection());
		}
	}

	override bool close(bool ok, out bool cancel) {
		if (ok) {
			string createClassicDirInner() {
				string s = createClassicDir();
				if (s is null) {
					ok = false;
					cancel = true;
				}
				return s;
			}
			_nameVal = _name.getText();
			if (_baseTemplate.getSelection()) {
				Summary summ = null;
				string tPath = _tTbl[_templateC.getSelectionIndex()].path;
				if (!.exists(tPath)) {
					ok = false;
					cancel = true;
				} else if (.isDir(tPath) && !tPath.buildPath("Summary.wsm").exists && !tPath.buildPath("Summary.xml").exists) {
					// 非シナリオのディレクトリをベースとする
					summ = Summary.createScenario(_prop.tempPath, name, findSkin2(_prop, _skinVal));
					tPath.copyAll(summ.scenarioPath);
				} else {
					try {
						summ = Summary.loadScenarioFromFile(_prop.parent, _prop.var.etc.doubleIO,
							tPath, _prop.var.etc.expandXMLs, _prop.tempPath,
							&createClassicDirInner);
					} catch (SummaryException e) {
						// Nothing;
					}
				}
				if (ok) {
					if (!summ) {
						summ = Summary.createScenario(_prop.tempPath, name, findSkin2(_prop, _skinVal));
					}
					summ.setBaseParams(name, _prop.var.etc.defaultAuthor);
					_prop.var.etc.defaultScenarioTemplate = tPath;
					_prop.var.etc.defaultIsTemplate = true;
					_fromTemplate = summ;
				}
			} else {
				if (_prop.var.etc.canCreateClassic && _skinC.getSelectionIndex() == _skinC.getItemCount() - 1) {
					_skinVal = "";
					createClassicDirInner();
				} else {
					_skinVal = _skinC.getText();
				}
				if (ok) {
					_prop.var.etc.defaultIsTemplate = false;
				}
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
		super(prop, shell, true, prop.msgs.dlgTitVersion, prop.images.menu(MenuID.VersionInfo), false, null, false, false);
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
		area.setLayout(gl);
		auto d = Display.getCurrent();
		auto img = new Label(area, SWT.CENTER);
		img.setImage(_prop.images.icon);
		auto gd = new GridData;
		auto rect = _prop.images.icon.getBounds();
		gd.widthHint = rect.width;
		gd.heightHint = rect.height;
		gd.verticalSpan = 2;
		img.setLayoutData(gd);
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(zeroGridLayout(1, true));
			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_prop.msgs.application ~ " / " ~ APP_VERSION);
			auto ln = new Link(comp, SWT.NONE);
			ln.setText("<a>" ~ APP_WEB_SITE_URI ~ "</a>");
			ln.addSelectionListener(new OpenLink);
			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(_prop.msgs.appDesc);
		}
		auto build = new Text(area, SWT.READ_ONLY | SWT.BORDER | SWT.MULTI);
		createTextMenu!Text(_comm, _prop, build, null);
		build.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		build.setText(APP_BUILD);
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
		super (prop, shell, false, prop.msgs.dlgTitError, shell.getImage(), true, size, false, false, [info]);
		_comm = comm;
		_prop = prop;
		_desc = desc;
	}

	override void setup(Composite area) {
		auto d = area.getDisplay();
		auto gl = new GridLayout(2, false);
		gl.horizontalSpacing = 0;
		area.setLayout(gl);

		{
			auto comp = new Composite(area, SWT.NONE);
			auto cgl = new GridLayout(1, true);
			cgl.marginWidth = 10;
			cgl.marginHeight = 10;
			comp.setLayout(cgl);
			auto img = new Label(comp, SWT.NONE);
			img.setImage(d.getSystemImage(SWT.ICON_ERROR));
		}
		auto l = new Label(area, SWT.WRAP);
		l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		l.setText(_prop.msgs.unknownError);

		auto msg = new Text(area, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.V_SCROLL | SWT.READ_ONLY);
		createTextMenu!Text(_comm, _prop, msg, null);
		auto msgL = new GridData(GridData.FILL_BOTH);
		msgL.horizontalSpan = 2;
		msg.setLayoutData(msgL);
		msg.setText(_desc);
	}
}

private class ReNumDialog(A) : AbsDialog {
private:
	Props _prop;
	A _area;
	ulong _minId;

	Spinner _id;

	ulong _newId;
public:
	this (Props prop, Shell shell, A area, ulong minId) {
		_prop = prop;
		_area = area;
		_minId = minId;
		super(prop, shell, prop.msgs.dlgTitReNumbering, prop.images.menu(MenuID.ReNumbering), false);
		enterClose = true;
	}

	@property
	ulong newId() {
		return _newId;
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.reNumbering);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(new GridLayout(3, false));
			string cName = objName!A(_prop);
			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(.tryFormat(_prop.msgs.reNumbering1, cName, _area.name));
			_id = new Spinner(comp, SWT.BORDER);
			_id.setMaximum(_prop.looks.idMax);
			_id.setMinimum(cast(int) _minId);
			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(.tryFormat(_prop.msgs.reNumbering2, cName, _area.name));
		}
	}
	override bool close(bool ok) {
		if (ok) {
			_newId = _id.getSelection();
		}
		return ok;
	}
}
