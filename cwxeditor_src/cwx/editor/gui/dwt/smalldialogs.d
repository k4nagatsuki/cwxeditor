
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
import cwx.importutils;
import cwx.flag;
import cwx.card;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.scripterrordialog;
import cwx.editor.gui.dwt.settingsdialog;

static import core.stdc.stdlib;

static import std.algorithm;
import std.string;
import std.conv;
import std.path;
import std.file;
import std.functional;
import std.array;
import std.traits;
import std.typecons : Tuple;

import org.eclipse.swt.all;

class CreateScenarioDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	Text _name;
	Combo _skinC;
	Tuple!(string, "type", string, "name")[] _skinTypes;
	Combo _templateC;
	string _nameVal;
	string _skinType = "";
	string _skinName = "";
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

	void enabledClassicDir() { mixin(S_TRACE);
		_dir.setEnabled(legacy);
		_dirRef.setEnabled(legacy);
		_createScDir.setEnabled(legacy);
	}
	void refSkinVal() { mixin(S_TRACE);
		auto index = _skinC.getSelectionIndex();
		if (index == _skinC.getItemCount() - 1) { mixin(S_TRACE);
			_skinName = "";
			_skinType = "";
		} else { mixin(S_TRACE);
			_skinName = _skinTypes[index].name;
			_skinType = _skinTypes[index].type;
		}
	}
	void refClassic() { mixin(S_TRACE);
		refSkinVal();
		scope (exit) enabledClassicDir();
		if (_baseTemplate.getSelection()) { mixin(S_TRACE);
			string tPath = _tTbl[_templateC.getSelectionIndex()].path;
			if (!.exists(tPath)) { mixin(S_TRACE);
				_classic = false;
			} else { mixin(S_TRACE);
				auto p = tPath in _isClassic;
				if (p) { mixin(S_TRACE);
					_classic = *p;
				} else { mixin(S_TRACE);
					bool r;
					if (.isDir(tPath)) { mixin(S_TRACE);
						r = tPath.buildPath("Summary.wsm").exists();
					} else if (.fnstartsWith(tPath.baseName(), "Summary")) { mixin(S_TRACE);
						r = tPath.baseName().cfnmatch("Summary.wsm");
					} else { mixin(S_TRACE);
						if (.extension(tPath).cfnmatch(".cab") && canUncab) { mixin(S_TRACE);
							r = cabHasFile(tPath, "Summary.wsm");
						} else { mixin(S_TRACE);
							r = zipHasFile(tPath, "Summary.wsm");
						}
					}
					_isClassic[tPath] = r;
					_classic = r;
				}
			}
		} else { mixin(S_TRACE);
			_classic = skinType.length == 0;
		}
	}
public:
	this (Commons comm, Props prop, Shell shell, bool currentWin) { mixin(S_TRACE);
		_comm = comm;
		_prop = prop;
		_useTemplate = currentWin;
		string title = currentWin ? _prop.msgs.dlgTitNewScenario : _prop.msgs.dlgTitNewScenarioAtNewWin;
		auto img = currentWin ? _prop.images.menu(MenuID.New) : _prop.images.menu(MenuID.NewAtNewWindow);
		super(_prop, shell, title, img, true, _prop.var.newScDlg);
		enterClose = true;
	}

	@property
	const
	override
	bool noScenario() { return true; }

	@property
	string name() { mixin(S_TRACE);
		return _nameVal;
	}
	@property
	string skinType() { mixin(S_TRACE);
		return _skinType;
	}
	@property
	string skinName() { mixin(S_TRACE);
		return _skinName;
	}
	@property
	Summary fromTemplate() { mixin(S_TRACE);
		return _fromTemplate;
	}
	@property
	bool legacy() { mixin(S_TRACE);
		return _classic;
	}
	@property
	string classicDir() { mixin(S_TRACE);
		auto dir = nabs(_prop.toAppAbs(_dirVal));
		if (_prop.var.etc.createScenarioDir) { mixin(S_TRACE);
			dir = dir.buildPath(toFileName(name)).createNewFileName(true);
		}
		return dir;
	}

	static string createClassicDir(Props prop, Shell parent) { mixin(S_TRACE);
		auto dlg = new DirectoryDialog(parent);
		dlg.setText(prop.msgs.newClassicDir);
		dlg.setMessage(prop.msgs.newClassicDirDesc);
		dlg.setFilterPath(prop.var.etc.scenarioPath);
		while (true) { mixin(S_TRACE);
			auto path = dlg.open();
			if (path) { mixin(S_TRACE);
				if (clistdir(path).length) { mixin(S_TRACE);
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
	override void setup(Composite area) { mixin(S_TRACE);
		auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
		cl.fillHorizontal = true;
		area.setLayout(cl);
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout(normalGridLayout(1, true));
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.scenarioName);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(1, true));

			_name = new Text(grp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _name, &catchMod);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData(gd);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.initialize);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(2, false));

			void refRadio() { mixin(S_TRACE);
				_skinC.setEnabled(_baseSkin.getSelection());
				_templateC.setEnabled(_baseTemplate.getSelection());
				enabledClassicDir();
			}

			_baseSkin = new Button(grp, SWT.RADIO);
			_baseSkin.setText(_prop.msgs.type);
			listener(_baseSkin, SWT.Selection, &refRadio);
			_skinC = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_skinC.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_skinC.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_skinTypes = [];
			foreach (key, value; skinTable(_prop)) { mixin(S_TRACE);
				_skinTypes ~= typeof(_skinTypes[0])(value.type, value.name);
			}
			int skinCmp(in typeof(_skinTypes[0]) skin1, in typeof(_skinTypes[0]) skin2) { mixin(S_TRACE);
				if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
					int i = ncmp(skin1.name, skin2.name);
					if (i == 0) i = ncmp(skin1.type, skin2.type);
					return i;
				} else { mixin(S_TRACE);
					int i = cmp(skin1.name, skin2.name);
					if (i == 0) i = cmp(skin1.type, skin2.type);
					return i;
				}
			}
			_skinTypes = sort!(skinCmp)(_skinTypes);
			int lastIndex = -1;
			foreach (ref t; _skinTypes) { mixin(S_TRACE);
				_skinC.add(.tryFormat("%s(%s)", t.name, t.type));
				if (t.name == _prop.var.etc.lastSkinName && t.type == _prop.var.etc.lastSkinType) { mixin(S_TRACE);
					lastIndex = _skinC.getItemCount() - 1;
				}
			}
			auto defText = .tryFormat("%s(%s)", _prop.var.etc.defaultSkinName, _prop.var.etc.defaultSkin);
			if (!_skinC.getItemCount()) { mixin(S_TRACE);
				// スキンが無い
				_skinC.add(defText);
				_skinTypes ~= typeof(_skinTypes[0])(_prop.var.etc.defaultSkin, _prop.var.etc.defaultSkinName);
			}
			_skinC.add(_prop.msgs.defaultSelection(_prop.msgs.classic));

			if (_prop.var.etc.targetVersion != "CardWirthPy") {
				// ターゲットバージョンはクラシック
				_skinC.select(_skinC.getItemCount() - 1);
			} else if (lastIndex == -1) { mixin(S_TRACE);
				auto defIndex = _skinC.indexOf(defText);
				if (defIndex == -1) { mixin(S_TRACE);
					_skinC.select(0);
				} else { mixin(S_TRACE);
					_skinC.select(defIndex);
				}
			} else { mixin(S_TRACE);
				_skinC.select(lastIndex);
			}

			_baseTemplate = new Button(grp, SWT.RADIO);
			_baseTemplate.setText(_prop.msgs.scenarioTemplate);
			listener(_baseTemplate, SWT.Selection, &refRadio);
			_templateC = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_templateC.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			auto tgd = new GridData(GridData.FILL_HORIZONTAL);
			tgd.widthHint = 0;
			_templateC.setLayoutData(tgd);
			foreach (i, sct; _prop.var.etc.scenarioTemplates) { mixin(S_TRACE);
				_templateC.add(.tryFormat(_prop.msgs.templateDesc, sct.name, sct.path));
				if (cfnmatch(sct.path, _prop.var.etc.defaultScenarioTemplate)) { mixin(S_TRACE);
					_templateC.select(cast(int)i);
				}
				_tTbl[cast(int)i] = sct;
			}
			bool tenbl = _templateC.getItemCount() > 0 && _useTemplate;
			if (!tenbl) _templateC.add(_prop.msgs.defaultSelection(_prop.msgs.noTemplate));
			if (_templateC.getSelectionIndex() == -1) _templateC.select(0);
			_baseTemplate.setEnabled(tenbl);

			_baseSkin.setSelection(!tenbl || !_prop.var.etc.defaultIsTemplate);
			_baseTemplate.setSelection(!_baseSkin.getSelection());
			_skinC.setEnabled(_baseSkin.getSelection());
			_templateC.setEnabled(_baseTemplate.getSelection());

			.listener(_skinC, SWT.Selection, &refClassic);
			.listener(_baseTemplate, SWT.Selection, &refClassic);
			.listener(_templateC, SWT.Selection, &refClassic);

			auto l = new Label(grp, SWT.NONE);
			l.setText(_prop.msgs.notClassicWarning);
			auto lgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			lgd.horizontalSpan = 2;
			l.setLayoutData(lgd);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp, SWT.NONE);
			grp.setText(_prop.msgs.createClassicDir);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(normalGridLayout(3, false));

			_dir = new Text(grp, SWT.BORDER);
			.listener(_dir, SWT.Modify, { mixin(S_TRACE);
				_dirVal = _dir.getText();
			});
			createTextMenu!Text(_comm, _prop, _dir, &catchMod);
			_dir.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_dirRef = new Button(grp, SWT.PUSH);
			_dirRef.setText(_prop.msgs.reference);
			.listener(_dirRef, SWT.Selection, { mixin(S_TRACE);
				selectDir(_prop, _dir, _prop.msgs.newClassicDir, _prop.msgs.newClassicDirDesc, _dir.getText());
			});
			_dirOpen = createOpenButton(_comm, grp, {return _prop.toAppAbs(_dir.getText());}, true);

			_createScDir = new Button(grp, SWT.CHECK);
			_createScDir.setText(_prop.msgs.createScenarioNameDir);
			auto gd = new GridData;
			gd.horizontalSpan = 3;
			_createScDir.setLayoutData(gd);
			.listener(_createScDir, SWT.Selection, { mixin(S_TRACE);
				_prop.var.etc.createScenarioDir = _createScDir.getSelection();
			});

			setupDropFile(grp, _dir, toDelegate(&dropDir));
		}

		_dir.setText(_prop.var.etc.scenarioPath);
		_createScDir.setSelection(_prop.var.etc.createScenarioDir);

		refClassic();
	}

	override bool close(bool ok, out bool cancel) { mixin(S_TRACE);
		if (ok) { mixin(S_TRACE);
			_nameVal = _name.getText();
			if (!_nameVal.length) _nameVal = _prop.var.etc.newScenarioName;

			auto skinIndex = _skinC.getSelectionIndex();
			if (0 <= skinIndex && skinIndex < _skinTypes.length) { mixin(S_TRACE);
				_prop.var.etc.lastSkinName = _skinTypes[skinIndex].name;
				_prop.var.etc.lastSkinType = _skinTypes[skinIndex].type;
			}

			auto dir = classicDir;
			if (legacy) { mixin(S_TRACE);
				if (dir.exists() && clistdir(dir).length) { mixin(S_TRACE);
					auto q = new MessageBox(getShell(), SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
					q.setText(_prop.msgs.dlgTitQuestion);
					q.setMessage(.tryFormat(_prop.msgs.notEmptyDir, dir));
					if (SWT.OK != q.open()) { mixin(S_TRACE);
						cancel = true;
						return false;
					}
				}
			}

			if (_baseTemplate.getSelection()) { mixin(S_TRACE);
				Summary summ = null;
				string tPath = _tTbl[_templateC.getSelectionIndex()].path;
				if (!.exists(tPath)) { mixin(S_TRACE);
					if (!dir.exists()) mkdirRecurse(dir);
					summ = new Summary(_nameVal, skinType, skinName, dir, false, true);
				} else if (.isDir(tPath) && !tPath.buildPath("Summary.wsm").exists() && !tPath.buildPath("Summary.xml").exists()) { mixin(S_TRACE);
					auto cursors = setWaitCursors(topShell(getShell()));
					scope (exit) {
						resetCursors(cursors);
					}
					// 非シナリオのディレクトリをベースとする
					summ = Summary.createScenario(_prop.parent, _prop.tempPath, name,
						findSkin2(_prop, skinType, skinName), _prop.var.etc.newAreaName != "",
						_prop.var.etc.newAreaName, _prop.var.etc.bgImagesDefault, _prop.var.etc.saveSkinName);
					tPath.copyAll(summ.scenarioPath);
				} else { mixin(S_TRACE);
					auto cursors = setWaitCursors(topShell(getShell()));
					scope (exit) {
						resetCursors(cursors);
					}
					try { mixin(S_TRACE);
						LoadOption opt;
						opt.cardOnly = false;
						opt.textOnly = false;
						opt.doubleIO = _prop.var.etc.doubleIO;
						opt.expandXMLs = _prop.var.etc.expandXMLs;
						summ = Summary.loadScenarioFromFile(_prop.parent, opt, tPath, _prop.tempPath, () => dir);
					} catch (SummaryException e) {
						printStackTrace();
						debugln(e);
					}
				}
				if (ok) { mixin(S_TRACE);
					if (!summ) { mixin(S_TRACE);
						summ = Summary.createScenario(_prop.parent, _prop.tempPath, name,
							findSkin2(_prop, skinType, skinName), _prop.var.etc.newAreaName != "",
							_prop.var.etc.newAreaName, _prop.var.etc.bgImagesDefault, _prop.var.etc.saveSkinName);
					}
					summ.setBaseParams(name, _prop.var.etc.defaultAuthor);
					_prop.var.etc.defaultScenarioTemplate = tPath;
					_prop.var.etc.defaultIsTemplate = true;
					_fromTemplate = summ;
				}
			} else if (ok) { mixin(S_TRACE);
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
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto prog = Program.findProgram("html");
			if (prog) prog.execute(e.text);
		}
	}
public:
	this(Commons comm, Props prop, Shell shell) { mixin(S_TRACE);
		super(prop, shell, true, prop.msgs.dlgTitVersion, prop.images.menu(MenuID.VersionInfo), false, null, false, false);
		_comm = comm;
		_prop = prop;
		enterClose = true;
		firstFocusIsOK = true;
	}
	@property
	const
	override
	bool noScenario() { return true; }

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		auto gl = normalGridLayout(2, false);
		gl.marginWidth = 10.ppis;
		gl.horizontalSpacing = 15.ppis;
		area.setLayout(gl);
		auto d = Display.getCurrent();
		auto img = new Label(area, SWT.CENTER);
		img.setImage(_prop.images.largeIcon);
		auto gd = new GridData;
		auto rect = _prop.images.largeIcon.getBounds();
		gd.widthHint = rect.width;
		gd.heightHint = rect.height;
		gd.verticalSpan = 2;
		img.setLayoutData(gd);
		{ mixin(S_TRACE);
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

	this (Commons comm, Props prop, Shell shell, string desc) { mixin(S_TRACE);
		auto size = new class DSize {
			void width(int v) {}
			void height(int v) {}
			int width() {return 600.ppis;}
			int height() {return 400.ppis;}
		};
		auto info = ButtonInfo(prop.msgs.shutdown, {core.stdc.stdlib.exit(0);});
		super (prop, shell, false, prop.msgs.dlgTitError, shell.getImage(), true, size, false, false, [info]);
		_comm = comm;
		_prop = prop;
		_desc = desc;
	}

	@property
	const
	override
	bool noScenario() { return true; }

	override void setup(Composite area) { mixin(S_TRACE);
		auto d = area.getDisplay();
		auto gl = normalGridLayout(2, false);
		gl.horizontalSpacing = 0;
		area.setLayout(gl);

		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			auto cgl = normalGridLayout(1, true);
			cgl.marginWidth = 10.ppis;
			cgl.marginHeight = 10.ppis;
			comp.setLayout(cgl);
			auto img = new Label(comp, SWT.NONE);
			img.setImage(d.getSystemImage(SWT.ICON_ERROR));
		}
		auto l = new Link(area, SWT.WRAP);
		l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		l.setText(.tryFormat(_prop.msgs.unknownError, "<a>" ~ nabs(cwx.utils.debugLog) ~ "</a>"));
		.listener(l, SWT.Selection, (Event e) { mixin(S_TRACE);
			auto prog = Program.findProgram("log");
			if (prog) { mixin(S_TRACE);
				prog.execute(e.text);
			} else { mixin(S_TRACE);
				prog = Program.findProgram("txt");
				if (prog) { mixin(S_TRACE);
					prog.execute(e.text);
				} else { mixin(S_TRACE);
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
	Summary _summ;
	A _area;
	ulong _minId;

	Spinner _id;

	ulong _newId;
public:
	this (Props prop, Shell shell, Summary summ, A area, ulong minId) { mixin(S_TRACE);
		_prop = prop;
		_summ = summ;
		_area = area;
		_minId = minId;
		super(prop, shell, prop.msgs.dlgTitReNumbering, prop.images.menu(MenuID.ReNumbering), false);
		enterClose = true;
	}

	@property
	ulong newId() { mixin(S_TRACE);
		return _newId;
	}
	@property
	const
	override
	bool noScenario() { return true; }

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.reNumbering);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(3, false));
			string cName = objNameFrom(_prop, _area);
			auto l1 = new Label(comp, SWT.NONE);
			auto name = _area.name;
			static if (is(typeof(_area.linkId))) {
				if (_area.linkId != 0) { mixin(S_TRACE);
					static if (is(A:SkillCard)) {
						auto a = _summ.skill(_area.linkId);
						name = _prop.msgs.noSelectSkill;
					} else static if (is(A:ItemCard)) {
						auto a = _summ.item(_area.linkId);
						name = _prop.msgs.noSelectItem;
					} else static if (is(A:BeastCard)) {
						auto a = _summ.beast(_area.linkId);
						name = _prop.msgs.noSelectBeast;
					} else static assert (0);

					if (a) name = a.name;
				}
			}
			l1.setText(.tryFormat(_prop.msgs.reNumbering1, cName, name));
			_id = new Spinner(comp, SWT.BORDER);
			initSpinner(_id);
			_id.setMaximum(_prop.looks.idMax);
			_id.setMinimum(cast(int) _minId);
			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(.tryFormat(_prop.msgs.reNumbering2, cName, name));
		}
	}
	override bool close(bool ok) { mixin(S_TRACE);
		if (ok) { mixin(S_TRACE);
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

	void editEnd(TableItem itm, int column, string text) { mixin(S_TRACE);
		int i = _editor.getSelectionIndex();
		auto row = itm.getParent().indexOf(itm);
		if (-1 == i) { mixin(S_TRACE);
			_values[row] = text;
		} else { mixin(S_TRACE);
			_values[row] = _editorTable[i];
		}
		itm.setText(column, _values[row]);
	}
	Control createEditor(TableItem itm, int column) { mixin(S_TRACE);
		string[] strs;
		_editorTable.length = 0;
		if (_summ) { mixin(S_TRACE);
			auto flags = _summ.flagDirRoot.allFlags;
			sortedWithPath(flags, _comm.prop.var.etc.logicalSort, (cwx.flag.Flag f) { mixin(S_TRACE);
				strs ~= objName!(typeof(f))(_comm.prop) ~ " - " ~ f.path;
				_editorTable ~= CWXScript.createString(f.path);
			});
			auto steps = _summ.flagDirRoot.allSteps;
			sortedWithPath(steps, _comm.prop.var.etc.logicalSort, (Step f) { mixin(S_TRACE);
				strs ~= objName!(typeof(f))(_comm.prop) ~ " - " ~ f.path;
				_editorTable ~= CWXScript.createString(f.path);
			});
			foreach (a; _summ.areas) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.battles) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.packages) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.casts) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.skills) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.items) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.beasts) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; _summ.infos) { mixin(S_TRACE);
				strs ~= objName!(typeof(a))(_comm.prop) ~ " - " ~ .text(a.id) ~ "." ~ a.name;
				_editorTable ~= .text(a.id);
			}
			foreach (a; std.algorithm.sort(_summ.useCounter.coupon.keys)) { mixin(S_TRACE);
				strs ~= _comm.prop.msgs.coupon ~ " - " ~ a;
				_editorTable ~= CWXScript.createString(a);
			}
			foreach (a; std.algorithm.sort(_summ.useCounter.gossip.keys)) { mixin(S_TRACE);
				strs ~= _comm.prop.msgs.gossip ~ " - " ~ a;
				_editorTable ~= CWXScript.createString(a);
			}
			foreach (a; std.algorithm.sort(_summ.useCounter.completeStamp.keys)) { mixin(S_TRACE);
				strs ~= _comm.prop.msgs.completeStamp ~ " - " ~ a;
				_editorTable ~= CWXScript.createString(a);
			}
			foreach (p; _summ.allMaterials(_comm.skin, _comm.prop.var.etc.ignorePaths, _comm.prop.var.etc.logicalSort, false)) { mixin(S_TRACE);
				strs ~= _comm.prop.msgs.material ~ " - " ~ p;
				_editorTable ~= CWXScript.createString(p);
			}
		}

		foreach (keyword; .keywordInfos(_comm.prop.parent)) { mixin(S_TRACE);
			if (keyword.type == "") { mixin(S_TRACE);
				strs ~= keyword.name;
			} else { mixin(S_TRACE);
				strs ~= .tryFormat("%1$s - %2$s", keyword.type, keyword.name);
			}
			_editorTable ~= keyword.keyword;
		}

		auto editorTable2 = _editorTable.dup;
		_editor = createComboEditor(_comm, _comm.prop, _table, strs, itm.getText(column), false, (incSearch) { mixin(S_TRACE);
			string[] strs2 = [];
			_editorTable.length = 0;
			foreach (i, str; strs) { mixin(S_TRACE);
				if (incSearch.match(str)) { mixin(S_TRACE);
					strs2 ~= str;
					_editorTable ~= editorTable2[i];
				}
			}
			return strs2;
		});
		return _editor;
	}

public:
	this (Commons comm, Summary summ, Shell shell, in string[] vars, string script, string base, in CompileOption opt) { mixin(S_TRACE);
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
	Content[] contents() { mixin(S_TRACE);
		return _contents;
	}

	@property
	const
	override
	bool noScenario() { return true; }

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));

		auto grp = new Group(area, SWT.NONE);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		grp.setText(_comm.prop.msgs.scriptVarSet);
		grp.setLayout(normalGridLayout(1, false));

		_table = .rangeSelectableTable(grp, SWT.BORDER | SWT.FULL_SELECTION);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _comm.prop.var.etc.scriptVarTableHeight;
		_table.setLayoutData(vgd);
		_table.setHeaderVisible(true);
		auto nameCol = new TableColumn(_table, SWT.NONE);
		nameCol.setText(_comm.prop.msgs.scriptVarNameColumn);
		nameCol.setResizable(false);
		auto valueCol = new FullTableColumn(_table, SWT.NONE);
		valueCol.column.setText(_comm.prop.msgs.scriptVarValueColumn);

		foreach (var; _vars) { mixin(S_TRACE);
			auto itm = new TableItem(_table, SWT.NONE);
			itm.setText(var);
		}
		nameCol.pack();

		new TableTextEdit(_comm, _comm.prop, _table, 1, &editEnd, null, &createEditor);
	}
	override bool close(bool ok, out bool cancel) { mixin(S_TRACE);
		if (ok) { mixin(S_TRACE);
			CompileOption opt = _opt;
			try { mixin(S_TRACE);
				VarSet[] varTable;
				foreach (i, var; _vars) { mixin(S_TRACE);
					varTable ~= VarSet(var, _values[i]);
				}
				_contents = cwx.script.compile(_comm.prop.parent, _summ, CWXScript.pushVars(_script, varTable, opt), opt);
			} catch (CWXScriptException e) {
				printStackTrace();
				debugln(e);
				auto dlg = new ScriptErrorDialog(_comm, _comm.prop, _table, e, _base, opt);
				dlg.open();
				ok = false;
				cancel = true;
			}
		}
		return ok;
	}
}

class EventTemplateDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private ToolsPane!EvTemplate _evTempls;
	private EvTemplate[] _tmpls;

	this (Commons comm, Props prop, Summary summ, Shell shell, EvTemplate[] tmpls) { mixin(S_TRACE);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_tmpls = tmpls;
		auto size = comm.prop.var.evTemplDlg;
		super (prop, shell, false, title, prop.images.menu(MenuID.EvTemplates), true, size, true, true);
	}

	@property
	const
	override
	bool noScenario() { return _summ is null; }

	@property
	private string title() { mixin(S_TRACE);
		return .tryFormat(_prop.msgs.dlgTitEvTemplates, _summ.scenarioName);
	}

	@property
	EvTemplate[] eventTemplates() { return _tmpls; }

	private void refScenarioName() { mixin(S_TRACE);
		getShell().setText(title);
	}
	private void refScenario(Summary summ) { mixin(S_TRACE);
		if (_summ !is summ) forceCancel();
	}

	protected override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(windowGridLayout(1, true));
		_evTempls = new ToolsPane!EvTemplate(_comm, (b) { ignoreMod = b; }, &catchMod, &applyEnabled, area, SWT.NONE);
		_evTempls.setup(_tmpls, _prop.var.etc.eventTemplatesOfScenarioSashL, _prop.var.etc.eventTemplatesOfScenarioSashR);
		_evTempls.setShortcutWeights(_prop.var.etc.eventTemplateOfScenarioShortcutSashL, _prop.var.etc.eventTemplateOfScenarioShortcutSashR);
		_evTempls.setLayoutData(new GridData(GridData.FILL_BOTH));

		_comm.refScenarioName.add(&refScenarioName);
		_comm.refScenario.add(&refScenario);
		.listener(_evTempls, SWT.Dispose, {
			_comm.refScenarioName.remove(&refScenarioName);
			_comm.refScenario.remove(&refScenario);
		});
	}

	protected override bool apply() { mixin(S_TRACE);
		if (_evTempls.noApply) {
			auto dlg = new MessageBox(getShell(), SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
			dlg.setText(_prop.msgs.dlgTitQuestion);
			dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgForceApplySingle, _evTempls.boxName));
			final switch (dlg.open()) {
			case SWT.YES:
				_evTempls.forceApply();
				break;
			case SWT.NO:
				break;
			case SWT.CANCEL:
				return false;
			}
		}

		_tmpls = _evTempls.array;
		return true;
	}
}

class ImportOptionDialog : AbsDialog {
	private Commons _comm;
	private ImportOption _opt;
	private Props _prop;
	private bool _canIncludeImage;

	private Combo _materials;
	private Combo _variables;
	private Combo _casts;
	private Combo _skills;
	private Combo _items;
	private Combo _beasts;
	private Combo _infos;
	private Combo _areas;
	private Combo _battles;
	private Combo _packages;
	private Combo _includedFiles;
	// FIXME: CardWirth 1.60 格納イメージ
/+	private Combo _includedBgImages;
+/	private Combo _hands;
	private Combo _beastsInMotions;
	private Button _overwriteScenarioInfo;

	this (Commons comm, Shell shell, bool canIncludeImage) { mixin(S_TRACE);
		_comm = comm;
		_prop = comm.prop;
		_canIncludeImage = canIncludeImage;
		super (_prop, shell, true, _prop.msgs.dlgTitImportOption, _prop.images.menu(MenuID.Import), false);
	}

	@property
	const
	override
	bool noScenario() { return true; }

	@property
	ImportOption option() { return _opt; }

	protected override void setup(Composite area) { mixin(S_TRACE);
		auto agd = normalGridLayout(1, true);
		agd.marginWidth = 0;
		area.setLayout(agd);
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto cgd = normalGridLayout(4, false);
		cgd.marginHeight = 0;
		comp.setLayout(cgd);
		Combo create(T)(Image icon, string name, int opValue, T value, bool canIncludeImage = true) { mixin(S_TRACE);
			if (opValue < value.min || value.max < opValue) opValue = value;
			value = cast(T)opValue;
			auto label = new CLabel(comp, SWT.NONE);
			label.setText(name);
			label.setImage(icon);
			auto combo = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(combo);
			combo.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			foreach (t; EnumMembers!T) { mixin(S_TRACE);
				static if (is(T:ImportTypeIncluded)) {
					final switch (t) {
					case ImportTypeIncluded.Exclude:
						break;
					case ImportTypeIncluded.Include:
						if (!canIncludeImage) continue;
						break;
					case ImportTypeIncluded.AsIs:
						if (!canIncludeImage) continue;
						break;
					}
					combo.add(_prop.msgs.importTypeIncludedName(t));
				} else static if (is(T:ImportTypeReference1)) {
					combo.add(_prop.msgs.importTypeReference1Name(t));
				} else static if (is(T:ImportTypeReference2)) {
					combo.add(_prop.msgs.importTypeReference2Name(t));
				} else static assert (0);
				if (t is value) { mixin(S_TRACE);
					combo.select(combo.getItemCount() - 1);
				}
			}
			combo.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			return combo;
		}
		_materials = create(_prop.images.text, _prop.msgs.importOptionMaterials, _prop.var.etc.importOptionMaterials, _opt.materials);
		_variables = create(_prop.images.flagDir, _prop.msgs.importOptionVariables, _prop.var.etc.importOptionVariables, _opt.variables);
		_casts = create(_prop.images.casts, _prop.msgs.importOptionCasts, _prop.var.etc.importOptionCasts, _opt.casts);
		_skills = create(_prop.images.skill, _prop.msgs.importOptionSkills, _prop.var.etc.importOptionSkills, _opt.skills);
		_items = create(_prop.images.item, _prop.msgs.importOptionItems, _prop.var.etc.importOptionItems, _opt.items);
		_beasts = create(_prop.images.beast, _prop.msgs.importOptionBeasts, _prop.var.etc.importOptionBeasts, _opt.beasts);
		_infos = create(_prop.images.info, _prop.msgs.importOptionInfos, _prop.var.etc.importOptionInfos, _opt.infos);
		_areas = create(_prop.images.area, _prop.msgs.importOptionAreas, _prop.var.etc.importOptionAreas, _opt.areas);
		_battles = create(_prop.images.battle, _prop.msgs.importOptionBattles, _prop.var.etc.importOptionBattles, _opt.battles);
		_packages = create(_prop.images.packages, _prop.msgs.importOptionPackages, _prop.var.etc.importOptionPackages, _opt.packages);
		_includedFiles = create(_prop.images.cards, _prop.msgs.importOptionIncludedFiles, _canIncludeImage ? _prop.var.etc.importOptionIncludedFiles : _prop.var.etc.importOptionIncludedFilesWithoutIncluding, _opt.includedFiles, _canIncludeImage);
		// FIXME: CardWirth 1.60 格納イメージ
/+		_includedBgImages = create(_prop.images.backs, _prop.msgs.importOptionIncludedBgImages, _prop.var.etc.importOptionIncludedBgImages, _opt.includedBgImages);
+/		_hands = create(_prop.images.menu(MenuID.OpenHand), _prop.msgs.importOptionHands, _prop.var.etc.importOptionHands, _opt.hands);
		_beastsInMotions = create(_prop.images.beast, _prop.msgs.importOptionBeastsInMotions, _prop.var.etc.importOptionBeastsInMotions, _opt.beastsInMotions);
		auto sep = new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL);
		sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		_overwriteScenarioInfo = new Button(area, SWT.CHECK);
		_overwriteScenarioInfo.setText(_prop.msgs.importOverwriteScenarioInfo);
		_overwriteScenarioInfo.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.HORIZONTAL_ALIGN_END));
		_overwriteScenarioInfo.setSelection(_prop.var.etc.importOptionOverwriteScenarioInfo);
	}

	protected override bool close(bool ok) { mixin(S_TRACE);
		if (!ok) return ok;

		void put(T)(Combo combo, ref int opValue, ref T value, bool canIncludeImage = true) { mixin(S_TRACE);
			static if (is(T:ImportTypeIncluded)) {
				T[] arr;
				if (canIncludeImage) { mixin(S_TRACE);
					foreach (t; EnumMembers!T) arr ~= t;
				} else { mixin(S_TRACE);
					arr = [T.Exclude];
				}
			} else {
				auto arr = EnumMembers!T;
			}
			auto index = combo.getSelectionIndex();
			foreach (i, t; arr) { mixin(S_TRACE);
				if (i == index) { mixin(S_TRACE);
					opValue = cast(int)t;
					value = t;
					break;
				}
			}
		}
		put(_materials, _prop.var.etc.importOptionMaterials.value, _opt.materials);
		put(_variables, _prop.var.etc.importOptionVariables.value, _opt.variables);
		put(_casts, _prop.var.etc.importOptionCasts.value, _opt.casts);
		put(_skills, _prop.var.etc.importOptionSkills.value, _opt.skills);
		put(_items, _prop.var.etc.importOptionItems.value, _opt.items);
		put(_beasts, _prop.var.etc.importOptionBeasts.value, _opt.beasts);
		put(_infos, _prop.var.etc.importOptionInfos.value, _opt.infos);
		put(_areas, _prop.var.etc.importOptionAreas.value, _opt.areas);
		put(_battles, _prop.var.etc.importOptionBattles.value, _opt.battles);
		put(_packages, _prop.var.etc.importOptionPackages.value, _opt.packages);
		put(_includedFiles, _canIncludeImage ? _prop.var.etc.importOptionIncludedFiles.value : _prop.var.etc.importOptionIncludedFilesWithoutIncluding.value, _opt.includedFiles, _canIncludeImage);
		// FIXME: CardWirth 1.60 格納イメージ
/+		put(_includedBgImages, _prop.var.etc.importOptionIncludedBgImages.value, _opt.includedBgImages);
+/		put(_hands, _prop.var.etc.importOptionHands.value, _opt.hands);
		put(_beastsInMotions, _prop.var.etc.importOptionBeastsInMotions.value, _opt.beastsInMotions);
		_opt.overwriteScenarioInfo = _overwriteScenarioInfo.getSelection();
		_prop.var.etc.importOptionOverwriteScenarioInfo = _opt.overwriteScenarioInfo;

		return ok;
	}
}

/// インポート結果を表示・選択するダイアログ。
class ImportResultDialog : AbsDialog {
	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private ImportResult _result;
	private Table _list;

	this (Commons comm, Summary summ, Shell shell, ImportResult result) { mixin(S_TRACE);
		_comm = comm;
		_prop = comm.prop;
		_summ = summ;
		_result = result;
		auto size = _prop.var.importResultDlg;
		super (_prop, shell, true, _prop.msgs.dlgTitImportResult, _prop.images.menu(MenuID.Import), true, size, false, true);
	}

	@property
	const
	override
	bool noScenario() { return true; }

	@property
	ImportResult checkedResult() { return _result; }

	private Tuple!(string, F)[] sortedVars(F)(F[][string] table) { mixin(S_TRACE);
		Tuple!(string, F)[] flags;
		auto sorter = _prop.var.etc.logicalSort ? (string a, string b) => ncmp(a, b) < 0 : (string a, string b) => cmp(a, b) < 0;
		auto sorter2 = _prop.var.etc.logicalSort ? (F a, F b) => ncmp(a.name, b.name) < 0 : (F a, F b) => cmp(a.name, b.name) < 0;
		foreach (dir; table.keys.sortDlg(sorter)) { mixin(S_TRACE);
			foreach (f; table[dir].dup.sortDlg(sorter2)) { mixin(S_TRACE);
				flags ~= Tuple!(string, F)(dir, f);
			}
		}
		return flags;
	}

	protected override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		auto label = new Label(area, SWT.WRAP);
		label.setText(_prop.msgs.importResourceList);
		label.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		_list = .rangeSelectableTable(area, SWT.MULTI | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		_list.setLayoutData(new GridData(GridData.FILL_BOTH));
		new FullTableColumn(_list, SWT.NONE);
		.listener(_list, SWT.Selection, (e) { mixin(S_TRACE);
			updateChecked!Event(e);
		});

		auto menu = new Menu(_list.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.SelectAll, &_list.selectAll, () => _list.getItemCount() && _list.getSelectionCount() != _list.getItemCount());
		_list.setMenu(menu);

		auto skin = _comm.skin;
		foreach (m; _result.materials) { mixin(S_TRACE);
			auto itm = new TableItem(_list, SWT.NONE);
			itm.setImage(.fimage(_prop, m.src, skin));
			auto text = m.dst.relativePath(_summ.scenarioPath).encodePath();
			if (m.overwrite) text = .tryFormat(_prop.msgs.overwriteMark, text);
			itm.setText(text);
			itm.setChecked(true);
		}
		void putVars(F)(Image icon, F[string] table) { mixin(S_TRACE);
			foreach (t; sortedVars(table)) { mixin(S_TRACE);
				auto itm = new TableItem(_list, SWT.NONE);
				itm.setImage(icon);
				auto path = t[0].length ? FlagDir.join(t[0], t[1].name) : t[1].name;
				auto text = .tryFormat(_prop.msgs.searchResultFlag, path);
				if (t[1].overwrite) text = .tryFormat(_prop.msgs.overwriteMark, text);
				itm.setText(text);
				itm.setChecked(true);
			}
		}
		putVars(_prop.images.flag, _result.flags);
		putVars(_prop.images.step, _result.steps);
		void putRes(T)(T[ulong] table) { mixin(S_TRACE);
			foreach (id; std.algorithm.sort(table.keys)) { mixin(S_TRACE);
				auto itm = new TableItem(_list, SWT.NONE);
				Image icon;
				string text;
				getSymbols(_comm, _summ, table[id], text, icon);
				itm.setImage(icon);
				itm.setText(text);
				itm.setChecked(true);
			}
		}
		putRes(_result.casts);
		putRes(_result.skills);
		putRes(_result.items);
		putRes(_result.beasts);
		putRes(_result.infos);
		putRes(_result.areas);
		putRes(_result.battles);
		putRes(_result.packages);
	}

	protected override bool close(bool ok) { mixin(S_TRACE);
		if (!ok) return ok;

		ImportResult result2;
		int i = 0;

		foreach (m; _result.materials) { mixin(S_TRACE);
			if (_list.getItem(i).getChecked()) result2.materials ~= m;
			i++;
		}
		void putVars(F)(Image icon, F[string] table, ref F[string] table2) { mixin(S_TRACE);
			foreach (t; sortedVars(table)) { mixin(S_TRACE);
				if (_list.getItem(i).getChecked()) table2[t[0]] ~= t[1];
				i++;
			}
		}
		putVars(_prop.images.flag, _result.flags, result2.flags);
		putVars(_prop.images.step, _result.steps, result2.steps);
		void putRes(T)(T[ulong] table, ref T[ulong] table2) { mixin(S_TRACE);
			foreach (id; std.algorithm.sort(table.keys)) { mixin(S_TRACE);
				if (_list.getItem(i).getChecked()) table2[id] = table[id];
				i++;
			}
		}
		putRes(_result.casts, result2.casts);
		putRes(_result.skills, result2.skills);
		putRes(_result.items, result2.items);
		putRes(_result.beasts, result2.beasts);
		putRes(_result.infos, result2.infos);
		putRes(_result.areas, result2.areas);
		putRes(_result.battles, result2.battles);
		putRes(_result.packages, result2.packages);

		_result = result2;

		return ok;
	}
}
