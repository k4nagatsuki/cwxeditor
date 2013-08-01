
module cwx.editor.gui.dwt.smalldialogs;

import cwx.utils;
import cwx.versioninfo;
import cwx.structs;
import cwx.menu;
import cwx.summary;
import cwx.archive;
import cwx.cab;
import cwx.types;
import cwx.script;
import cwx.event;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.scripterrordialog;

import std.string;
import std.conv;
import std.path;
import std.file;
import std.functional;

import org.eclipse.swt.all;

class CreateScenarioDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	Text _name;
	Combo _skinC;
	Combo _templateC;
	string _nameVal, _skinVal;
	Button _baseSkin;
	Button _baseTemplate;
	ScTemplate[int] _tTbl;
	bool[string] _isClassic;

	bool _useTemplate;
	Summary _fromTemplate = null;

	Text _dir;
	Button _dirRef;
	Button _dirOpen;
	Button _createScDir;
	string _dirVal;
	bool _classic = false;

	void enabledClassicDir() {
		_dir.setEnabled(legacy);
		_dirRef.setEnabled(legacy);
		_createScDir.setEnabled(legacy);
	}
	void refSkinVal() {
		if (_skinC.getSelectionIndex() == _skinC.getItemCount() - 1) {
			_skinVal = "";
		} else {
			_skinVal = _skinC.getText();
		}
	}
	void refClassic() {
		refSkinVal();
		scope (exit) enabledClassicDir();
		if (_baseTemplate.getSelection()) {
			string tPath = _tTbl[_templateC.getSelectionIndex()].path;
			if (!.exists(tPath)) {
				_classic = false;
			} else {
				auto p = tPath in _isClassic;
				if (p) {
					_classic = *p;
				} else {
					bool r;
					if (.isDir(tPath)) {
						r = tPath.buildPath("Summary.wsm").exists();
					} else if (.fnstartsWith(tPath.baseName(), "Summary")) {
						r = tPath.baseName().cfnmatch("Summary.wsm");
					} else {
						if (.extension(tPath).cfnmatch(".cab") && canUncab) {
							r = cabHasFile(tPath, "Summary.wsm");
						} else {
							r = zipHasFile(tPath, "Summary.wsm");
						}
					}
					_isClassic[tPath] = r;
					_classic = r;
				}
			}
		} else {
			_classic = skin.length == 0;
		}
	}
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
	bool legacy() {
		return _classic;
	}
	@property
	string classicDir() {
		auto dir = nabs(_prop.toAppAbs(_dirVal));
		if (_prop.var.etc.createScenarioDir) {
			dir = dir.buildPath(toFileName(name)).createNewFileName(true);
		}
		return dir;
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
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.initialize);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(2, false));

			void refRadio() {
				_skinC.setEnabled(_baseSkin.getSelection());
				_templateC.setEnabled(_baseTemplate.getSelection());
				enabledClassicDir();
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
			_skinC.add(_prop.msgs.classic);
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

			.listener(_skinC, SWT.Selection, &refClassic);
			.listener(_baseTemplate, SWT.Selection, &refClassic);
			.listener(_templateC, SWT.Selection, &refClassic);
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.createClassicDir);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(3, false));

			_dir = new Text(grp, SWT.BORDER);
			.listener(_dir, SWT.Modify, {
				_dirVal = _dir.getText();
			});
			createTextMenu!Text(_comm, _prop, _dir, &catchMod);
			_dir.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_dirRef = new Button(grp, SWT.PUSH);
			_dirRef.setText(_prop.msgs.reference);
			.listener(_dirRef, SWT.Selection, {
				selectDir(_prop, _dir, _prop.msgs.newClassicDir, _prop.msgs.newClassicDirDesc, _dir.getText());
			});
			_dirOpen = createOpenButton(_comm, grp, {return _prop.toAppAbs(_dir.getText());}, true);

			_createScDir = new Button(grp, SWT.CHECK);
			_createScDir.setText(_prop.msgs.createScenarioNameDir);
			auto gd = new GridData;
			gd.horizontalSpan = 3;
			_createScDir.setLayoutData(gd);
			.listener(_createScDir, SWT.Selection, {
				_prop.var.etc.createScenarioDir = _createScDir.getSelection();
			});

			setupDropFile(grp, _dir, toDelegate(&dropDir));
		}

		_dir.setText(_prop.var.etc.scenarioPath);
		_createScDir.setSelection(_prop.var.etc.createScenarioDir);

		refClassic();
	}

	override bool close(bool ok, out bool cancel) {
		if (ok) {
			_nameVal = _name.getText();
			if (!_nameVal.length) _nameVal = _prop.msgs.newScenarioName;

			auto dir = classicDir;
			if (legacy) {
				if (dir.exists() && clistdir(dir).length) {
					auto q = new MessageBox(getShell(), SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
					q.setText(_prop.msgs.dlgTitQuestion);
					q.setMessage(.tryFormat(_prop.msgs.notEmptyDir, dir));
					if (SWT.OK != q.open()) {
						cancel = true;
						return false;
					}
				}
			}

			if (_baseTemplate.getSelection()) {
				Summary summ = null;
				string tPath = _tTbl[_templateC.getSelectionIndex()].path;
				if (!.exists(tPath)) {
					if (!dir.exists()) mkdirRecurse(dir);
					summ = new Summary(_nameVal, skin, dir, false, true);
				} else if (.isDir(tPath) && !tPath.buildPath("Summary.wsm").exists && !tPath.buildPath("Summary.xml").exists) {
					auto cursors = setWaitCursors(topShell(getShell()));
					scope (exit) {
						resetCursors(cursors);
					}
					// 非シナリオのディレクトリをベースとする
					summ = Summary.createScenario(_prop.sys, _prop.tempPath, name, findSkin2(_prop, skin));
					tPath.copyAll(summ.scenarioPath);
				} else {
					auto cursors = setWaitCursors(topShell(getShell()));
					scope (exit) {
						resetCursors(cursors);
					}
					try {
						LoadOption opt;
						opt.cardOnly = false;
						opt.textOnly = false;
						opt.doubleIO = _prop.var.etc.doubleIO;
						opt.expandXMLs = _prop.var.etc.expandXMLs;
						summ = Summary.loadScenarioFromFile(_prop.parent, opt, tPath, _prop.tempPath, () => dir);
					} catch (SummaryException e) {
						// Nothing;
						debugln(e);
					}
				}
				if (ok) {
					if (!summ) {
						summ = Summary.createScenario(_prop.sys, _prop.tempPath, name, findSkin2(_prop, skin));
					}
					summ.setBaseParams(name, _prop.var.etc.defaultAuthor);
					_prop.var.etc.defaultScenarioTemplate = tPath;
					_prop.var.etc.defaultIsTemplate = true;
					_fromTemplate = summ;
				}
			} else if (ok) {
				_prop.var.etc.defaultIsTemplate = false;
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
		auto l = new Link(area, SWT.WRAP);
		l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		l.setText(.tryFormat(_prop.msgs.unknownError, "<a>" ~ nabs(cwx.utils.debugLog) ~ "</a>"));
		.listener(l, SWT.Selection, (Event e) {
			auto prog = Program.findProgram("log");
			if (prog) {
				prog.execute(e.text);
			} else {
				prog = Program.findProgram("txt");
				if (prog) {
					prog.execute(e.text);
				} else {
					openFolder(cwx.utils.debugLog.dirName());
				}
			}
		});

		auto msg = new Text(area, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.V_SCROLL | SWT.READ_ONLY);
		createTextMenu!Text(_comm, _prop, msg, null);
		auto msgL = new GridData(GridData.FILL_BOTH);
		msgL.horizontalSpan = 2;
		msg.setLayoutData(msgL);
		msg.setText(_desc);
	}
}

class ReNumDialog(A) : AbsDialog {
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
			initSpinner(_id);
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

class ScriptVarSetDialog : AbsDialog {
private:
	/// 変数の種類(現在未使用)。
	enum VarKind {
		Variant, /// あらゆる変数。
		Boolean, /// true, false。
		Flag, /// フラグ(文字列)。
		Step, /// ステップ(文字列)。
		Area, /// エリア(ID)。
		Battle, /// バトル(ID)。
		Package, /// パッケージ(ID)。
		Cast, /// キャストカード(ID)。
		Skill, /// スキルカード(ID)。
		Item, /// アイテムカード(ID)。
		Beast, /// 召喚獣カード(ID)。
		Info, /// 情報カード(ID)。
		Coupon, /// クーポン(文字列)。
		Gossip, /// ゴシップ(文字列)。
		CompleteStamp, /// 終了印(文字列)。
		File /// ファイルパス。
	}
	Commons _comm;
	Summary _summ;
	const string[] _vars;
	string _script, _base;

	string[] _values;
	Table _table;
	Combo _editor = null;
	string[] _editorTable;
	const CompileOption _opt;

	Content[] _contents;

	void editEnd(TableItem itm, int column, string text) {
		int i = _editor.getSelectionIndex();
		auto row = itm.getParent().indexOf(itm);
		if (-1 == i) {
			_values[row] = text;
		} else {
			_values[row] = _editorTable[i];
		}
		itm.setText(column, _values[row]);
	}
	Control createEditor(TableItem itm, int column) {
		string[] strs;
		_editorTable.length = 0;
		strs ~= "true";
		_editorTable ~= "true";
		strs ~= "false";
		_editorTable ~= "false";
		if (_summ) {
			foreach (f; _summ.flagDirRoot.allFlags) {
				strs ~= objName!(typeof(f))(_comm.prop) ~ " - " ~ f.path;
				_editorTable ~= CWXScript.createString(f.path);
			}
			foreach (f; _summ.flagDirRoot.allSteps) {
				strs ~= objName!(typeof(f))(_comm.prop) ~ " - " ~ f.path;
				_editorTable ~= CWXScript.createString(f.path);
			}
			foreach (a; _summ.areas) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.battles) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.packages) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.casts) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.skills) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.items) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.beasts) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.infos) {
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.useCounter.coupon.keys.sort) {
				strs ~= _comm.prop.msgs.coupon ~ " - " ~ a;
				_editorTable ~= CWXScript.createString(a);
			}
			foreach (a; _summ.useCounter.gossip.keys.sort) {
				strs ~= _comm.prop.msgs.gossip ~ " - " ~ a;
				_editorTable ~= CWXScript.createString(a);
			}
			foreach (a; _summ.useCounter.completeStamp.keys.sort) {
				strs ~= _comm.prop.msgs.completeStamp ~ " - " ~ a;
				_editorTable ~= CWXScript.createString(a);
			}
			foreach (p; _summ.allMaterials(_comm.skin, _comm.prop.var.etc.ignorePaths, _comm.prop.var.etc.logicalSort, false)) {
				strs ~= _comm.prop.msgs.material ~ " - " ~ p;
				_editorTable ~= CWXScript.createString(p);
			}
		}
		_editor = createComboEditor(_comm, _comm.prop, _table, strs, itm.getText(column), false);
		return _editor;
	}

public:
	this (Commons comm, Summary summ, Shell shell, in string[] vars, string script, string base, in CompileOption opt) {
		_comm = comm;
		_summ = summ;
		_vars = vars;
		_values.length = _vars.length;
		_script = script;
		_base = base;
		_opt = opt;
		auto size = comm.prop.var.scriptVarSetDlg;
		super(comm.prop, shell, true, comm.prop.msgs.dlgTitScriptVarSet, comm.prop.images.menu(MenuID.EvTemplates), true, size);
		enterClose = false;
	}

	@property
	Content[] contents() {
		return _contents;
	}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));

		auto grp = new Group(area, SWT.NONE);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		grp.setText(_comm.prop.msgs.scriptVarSet);
		grp.setLayout(new GridLayout(1, false));

		_table = new Table(grp, SWT.BORDER | SWT.FULL_SELECTION);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _comm.prop.var.etc.scriptVarTableHeight;
		_table.setLayoutData(vgd);
		_table.setHeaderVisible(true);
		auto nameCol = new TableColumn(_table, SWT.NONE);
		nameCol.setText(_comm.prop.msgs.scriptVarNameColumn);
		nameCol.setResizable(false);
		auto valueCol = new FullTableColumn(_table, SWT.NONE);
		valueCol.column.setText(_comm.prop.msgs.scriptVarValueColumn);

		foreach (var; _vars) {
			auto itm = new TableItem(_table, SWT.NONE);
			itm.setText(var);
		}
		nameCol.pack();

		new TableTextEdit(_comm, _comm.prop, _table, 1, &editEnd, null, &createEditor);
	}
	override bool close(bool ok, out bool cancel) {
		if (ok) {
			CompileOption opt = _opt;
			try {
				VarSet[] varTable;
				foreach (i, var; _vars) {
					varTable ~= VarSet(var, _values[i]);
				}
				_contents = cwx.script.compile(_comm.prop.parent, _summ, CWXScript.pushVars(_script, varTable, opt), opt);
			} catch (CWXScriptException e) {
				auto dlg = new ScriptErrorDialog(_comm, _comm.prop, _table, e, _base, opt);
				dlg.open();
				ok = false;
				cancel = true;
			}
		}
		return ok;
	}
}
