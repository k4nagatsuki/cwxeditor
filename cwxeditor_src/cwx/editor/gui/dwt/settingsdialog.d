
module cwx.editor.gui.dwt.settingsdialog;

import cwx.utils;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;

import std.path;
import std.file;
import std.string;

import dwt.DWT;
import dwt.widgets.Display;
import dwt.widgets.Shell;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.List;
import dwt.widgets.Group;
import dwt.widgets.Spinner;
import dwt.widgets.Button;
import dwt.widgets.Text;
import dwt.widgets.Label;
import dwt.widgets.FileDialog;
import dwt.widgets.DirectoryDialog;
import dwt.widgets.MessageBox;
import dwt.custom.CTabFolder;
import dwt.custom.CTabItem;
import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.ModifyListener;
import dwt.events.ModifyEvent;
import dwt.layout.GridLayout;
import dwt.layout.GridData;

class SettingsDialog : AbsDialog {
private:
	Props _prop;

	CTabItem _tabB;
	Text _enginePath;
	Text _tempDir;
	Text _author;
	Spinner _histMax;
	Button _singleWindow;
	Button _expandXMLs;
	Button _contentsFloat;
	Button _xmlCopy;
	Button _saveInnerImagePath;

	CTabItem _tabS;
	List _bgStgsL;
	BgImageSetting[] _bgStgs;
	Text _bgImgName;
	Spinner _bgImgX;
	Spinner _bgImgY;
	Spinner _bgImgW;
	Spinner _bgImgH;
	Button _bgImgMask;
	Button _bgImgDel;
	Text _keyCodes;

	CTabItem _tabT;
	List _toolsL;
	OuterTool[] _tools;
	Text _toolName;
	Text _toolCommand;
	Button _toolCommandRef;
	Text _toolWorkDir;
	Button _toolWorkDirRef;
	Button _toolDel;

	void upBgImage() {
		int i = _bgStgsL.getSelectionIndex;
		if (i <= 0) return;
		string tempS = _bgStgsL.getItem(i - 1);
		_bgStgsL.setItem(i - 1, _bgStgsL.getItem(i));
		_bgStgsL.setItem(i, tempS);
		auto temp = _bgStgs[i - 1];
		_bgStgs[i - 1] = _bgStgs[i];
		_bgStgs[i] = temp;
		_bgStgsL.select = i - 1;
	}
	void downBgImage() {
		int i = _bgStgsL.getSelectionIndex;
		if (i < 0 || _bgStgs.length <= i + 1) return;
		string tempS = _bgStgsL.getItem(i + 1);
		_bgStgsL.setItem(i + 1, _bgStgsL.getItem(i));
		_bgStgsL.setItem(i, tempS);
		auto temp = _bgStgs[i + 1];
		_bgStgs[i + 1] = _bgStgs[i];
		_bgStgs[i] = temp;
		_bgStgsL.select = i + 1;
	}
	void upTool() {
		int i = _toolsL.getSelectionIndex;
		if (i <= 0) return;
		string tempS = _toolsL.getItem(i - 1);
		_toolsL.setItem(i - 1, _toolsL.getItem(i));
		_toolsL.setItem(i, tempS);
		auto temp = _tools[i - 1];
		_tools[i - 1] = _tools[i];
		_tools[i] = temp;
		_toolsL.select = i - 1;
	}
	void downTool() {
		int i = _toolsL.getSelectionIndex;
		if (i < 0 || _tools.length <= i + 1) return;
		string tempS = _toolsL.getItem(i + 1);
		_toolsL.setItem(i + 1, _toolsL.getItem(i));
		_toolsL.setItem(i, tempS);
		auto temp = _tools[i + 1];
		_tools[i + 1] = _tools[i];
		_tools[i] = temp;
		_toolsL.select = i + 1;
	}
	static string selectFile(Text file, string[] name, string[] ext, string fileName, string title, string p) {
		auto dlg = new FileDialog(file.getShell, DWT.PRIMARY_MODAL | DWT.APPLICATION_MODAL | DWT.SINGLE | DWT.OPEN);
		dlg.setFilterExtensions = ext;
		dlg.setFilterNames = name;
		dlg.setText = title;
		string path;
		try {
			path = file.getText;
		} catch {
			path = p;
		}
		dlg.setFilterPath = getDirName(nabs(path));
		dlg.setFileName = fileName;
		string fname = dlg.open;
		if (fname) {
			file.setText = fname;
		}
		return fname;
	}
	void selectEngine() {
		selectFile(_enginePath, [_prop.var.etc.engine], [_prop.var.etc.engine],
			_prop.var.etc.engine, _prop.msgs.enginePath(_prop.var.etc.engine),
			_prop.var.etc.enginePath);
	}
	void selectProgram(int i) {
		auto tool = _tools[i];
		string[] ext;
		version (Windows) {
			ext = ["*.exe", "*.*"];
		} else {
			ext = ["*.*"];
		}
		string fname = selectFile(_toolCommand, _prop.msgs.toolTName, ext, "", _prop.msgs.dlgTitOuterTool, tool.command);
		if (fname) {
			_tools[i].command = fname;
		}
	}
	string selectDir(Text dir, string title, string msg, string p) {
		auto dlg = new DirectoryDialog(dir.getShell);
		dlg.setText = title;
		dlg.setMessage = msg;
		string path;
		try {
			auto d = dir.getText;
			if (!std.path.isabs(d)) {
				d = std.path.join(std.path.getDirName(_prop.parent.appPath), d);
			}
			path = d;
		} catch {
			path = p;
		}
		dlg.setFilterPath = nabs(path);
		string fname = dlg.open;
		if (fname) {
			dir.setText = fname;
		}
		return fname;
	}
	void selectTemp() {
		selectDir(_tempDir, _prop.msgs.tempDir, _prop.msgs.tempDirDesc, _prop.tempPath);
	}
	void selectWorkDir(int i) {
		auto tool = _tools[i];
		string fname = selectDir(_toolWorkDir, _prop.msgs.toolWorkDir, _prop.msgs.toolWorkDirDesc, tool.workDir);
		if (fname) {
			_tools[i].workDir = fname;
		}
	}
	void selectBgImageSetting() {
		int i = _bgStgsL.getSelectionIndex;
		_bgImgName.setEnabled = i >= 0;
		_bgImgX.setEnabled = i >= 0;
		_bgImgY.setEnabled = i >= 0;
		_bgImgW.setEnabled = i >= 0;
		_bgImgH.setEnabled = i >= 0;
		_bgImgMask.setEnabled = i >= 0;
		_bgImgDel.setEnabled = i >= 0;
		if (i >= 0) {
			_bgImgName.setText = _bgStgs[i].name;
			_bgImgX.setSelection = _bgStgs[i].x;
			_bgImgY.setSelection = _bgStgs[i].y;
			_bgImgW.setSelection = _bgStgs[i].width;
			_bgImgH.setSelection = _bgStgs[i].height;
			_bgImgMask.setSelection = _bgStgs[i].mask;
		} else {
			_bgImgName.setText = "";
			_bgImgX.setSelection = 0;
			_bgImgY.setSelection = 0;
			_bgImgW.setSelection = 0;
			_bgImgH.setSelection = 0;
			_bgImgMask.setSelection = false;
		}
	}
	void selectOuterTool() {
		int i = _toolsL.getSelectionIndex;
		_toolName.setEnabled = i >= 0;
		_toolCommand.setEnabled = i >= 0;
		_toolCommandRef.setEnabled = i >= 0;
		_toolWorkDir.setEnabled = i >= 0;
		_toolWorkDirRef.setEnabled = i >= 0;
		_toolDel.setEnabled = i >= 0;
		if (i >= 0) {
			_toolName.setText = _tools[i].name;
			_toolCommand.setText = _tools[i].command;
			_toolWorkDir.setText = _tools[i].workDir;
		} else {
			_toolName.setText = "";
			_toolCommand.setText = "";
			_toolWorkDir.setText = "";
		}
	}
	void construct1(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		_tabB = new CTabItem(tabf, DWT.NONE);
		_tabB.setText = _prop.msgs.baseSettings;
		_tabB.setControl = comp;
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new GridLayout(2, false);
			grp.setText = _prop.msgs.enginePath(_prop.var.etc.engine);
			_enginePath = new Text(grp, DWT.BORDER);
			_enginePath.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto refr = new Button(grp, DWT.PUSH);
			refr.setText = _prop.msgs.reference;
			refr.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) {selectEngine;}
			});
			checker(_enginePath);
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new GridLayout(2, false);
			grp.setText = _prop.msgs.tempDir;
			_tempDir = new Text(grp, DWT.BORDER);
			_tempDir.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto refr = new Button(grp, DWT.PUSH);
			refr.setText = _prop.msgs.reference;
			refr.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) {selectTemp;}
			});
		}
		{
			auto comp2 = new Composite(comp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			comp2.setLayout = zeroMarginGridLayout(2, false);
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				auto cl = new CenterLayout;
				cl.fillHorizontal = true;
				grp.setLayout = cl;
				grp.setText = _prop.msgs.scenarioAuthor;
				_author = new Text(grp, DWT.BORDER);
			}
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				grp.setText = _prop.msgs.openHistory;
				grp.setLayout = new GridLayout(3, false);
				auto l = new Label(grp, DWT.NONE);
				l.setText = _prop.msgs.openHistoryMax;
				_histMax = new Spinner(grp, DWT.BORDER);
				_histMax.setMinimum = 0;
				_histMax.setMaximum = 99;
				auto clear = new Button(grp, DWT.PUSH);
				clear.setEnabled = _prop.var.etc.openHistories.length > 0;
				clear.setText = _prop.msgs.openHistoryClear;
				clear.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						auto dlg = new MessageBox(_histMax.getShell, DWT.ICON_QUESTION | DWT.OK | DWT.CANCEL);
						scope (exit) dlg.dispose;
						dlg.setText = _prop.msgs.dlgTitQuestion;
						dlg.setMessage = _prop.msgs.dlgMsgHistoryClear;
						if (DWT.OK == dlg.open) {
							_prop.var.etc.openHistories = [];
							(cast(Control) e.widget).setEnabled = false;
						}
					}
				});
			}
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.settingEtc;
			grp.setLayout = new GridLayout(1, false);
			_singleWindow = new Button(grp, DWT.CHECK);
			_singleWindow.setText = _prop.msgs.singleWindow;
			_expandXMLs = new Button(grp, DWT.CHECK);
			_expandXMLs.setText = _prop.msgs.expandXMLs;
			_contentsFloat = new Button(grp, DWT.CHECK);
			_contentsFloat.setText = _prop.msgs.contentsFloat;
			_xmlCopy = new Button(grp, DWT.CHECK);
			_xmlCopy.setText = _prop.msgs.xmlCopy;
			_saveInnerImagePath = new Button(grp, DWT.CHECK);
			_saveInnerImagePath.setText = _prop.msgs.saveInnerImagePath;
		}
	}
	Spinner createS(string Set)(SettingsDialog v, Composite parent, string name, int max, int min) {
		auto l = new Label(parent, DWT.NONE);
		l.setText = name;
		auto spn = new Spinner(parent, DWT.BORDER);
		spn.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		spn.setMaximum = max;
		spn.setMinimum = min;
		spn.setSelection = 0;
		spn.addModifyListener(new class(v) ModifyListener {
			// FIXME: テンプレート外へのアクセスでアクセス違反
			private SettingsDialog _v;
			this(SettingsDialog v) {
				_v = v;
			}
			override void modifyText(ModifyEvent e) {
				int i = _v._bgStgsL.getSelectionIndex;
				if (i < 0) return;
				auto spn = cast(Spinner) e.widget;
				mixin ("_v." ~ Set);
			}
		});
		return spn;
	}
	void construct2(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		_tabS = new CTabItem(tabf, DWT.NONE);
		_tabS.setText = _prop.msgs.bgImageAndKeyCode;
		_tabS.setControl = comp;
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(2, false);
			grp.setText = _prop.msgs.bgImageSettings;
			{
				auto comp2 = new Composite(grp, DWT.NONE);
				auto cgd = new GridData(GridData.FILL_BOTH);
				cgd.verticalSpan = 3;
				comp2.setLayoutData = cgd;
				comp2.setLayout = zeroMarginGridLayout(2, true);
				_bgStgsL = new List(comp2, DWT.BORDER | DWT.SINGLE | DWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.bgImageSettingsNameWidth;
				gd.heightHint = _prop.var.etc.bgImageSettingsNameHeight;
				gd.horizontalSpan = 2;
				_bgStgsL.setLayoutData = gd;
				_bgStgsL.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {selectBgImageSetting;}
				});
				auto up = new Button(comp2, DWT.PUSH);
				up.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				up.setText = _prop.msgs.ttUp;
				up.setImage = _prop.images.menuUp;
				up.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {upBgImage;}
				});
				auto down = new Button(comp2, DWT.PUSH);
				down.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				down.setText = _prop.msgs.ttDown;
				down.setImage = _prop.images.menuDown;
				down.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {downBgImage;}
				});
			}
			auto comp2 = new Composite(grp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			comp2.setLayout = zeroMarginGridLayout(4, false);
			{
				auto comp3 = new Composite(comp2, DWT.NONE);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 4;
				comp3.setLayoutData = gd;
				comp3.setLayout = zeroMarginGridLayout(2, false);
				_bgImgName = new Text(comp3, DWT.BORDER);
				auto ngd = new GridData(GridData.FILL_HORIZONTAL);
				ngd.widthHint = _prop.var.etc.bgImageSettingsNameWidth;
				_bgImgName.setLayoutData = ngd;
				_bgImgMask = new Button(comp3, DWT.TOGGLE);
				_bgImgMask.setImage = _prop.images.menuMask;
				_bgImgMask.setToolTipText = _prop.msgs.ttMask;
				_bgImgName.addModifyListener(new class ModifyListener {
					override void modifyText(ModifyEvent e) {
						int i = _bgStgsL.getSelectionIndex;
						if (i < 0 || _bgStgsL.getItem(i) == _bgImgName.getText) return;
						_bgStgsL.setItem(i, _bgImgName.getText);
						_bgStgs[i].name = _bgImgName.getText;
					}
				});
				_bgImgMask.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						int i = _bgStgsL.getSelectionIndex;
						if (i < 0) return;
						_bgStgs[i].mask = _bgImgMask.getSelection;
					}
				});
			}
			_bgImgX = createS!("_bgStgs[i].x = spn.getSelection;")
				(this, comp2, _prop.msgs.left, _prop.looks.posLeftMax, _prop.looks.posLeftMin);
			_bgImgY = createS!("_bgStgs[i].y = spn.getSelection;")
				(this, comp2, _prop.msgs.top, _prop.looks.posTopMax, _prop.looks.posTopMin);
			_bgImgW = createS!("_bgStgs[i].width = spn.getSelection;")
				(this, comp2, _prop.msgs.width, _prop.looks.backWidthMax, _prop.looks.backWidthMin);
			_bgImgH = createS!("_bgStgs[i].height = spn.getSelection;")
				(this, comp2, _prop.msgs.height, _prop.looks.backHeightMax, _prop.looks.backHeightMin);
			{
				auto newBstg = new Button(grp, DWT.PUSH);
				newBstg.setLayoutData = new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_END);
				newBstg.setText = _prop.msgs.newBgImageSetting;
				newBstg.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						_bgStgs ~= BgImageSetting(_prop.msgs.newBgImageSettingName, 0, 0, 0, 0, false);
						_bgStgsL.add(_bgStgs[$ - 1].name);
						_bgStgsL.select = _bgStgs.length - 1;
						selectBgImageSetting;
					}
				});
				_bgImgDel = new Button(grp, DWT.PUSH);
				_bgImgDel.setLayoutData = new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_END);
				_bgImgDel.setText = _prop.msgs.delBgImageSetting;
				_bgImgDel.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						int i = _bgStgsL.getSelectionIndex;
						if (i < 0) return;
						_bgStgsL.remove(i);
						_bgStgs = _bgStgs[0 .. i] ~ _bgStgs[i + 1 .. $];
						if (_bgStgs.length > 0) {
							_bgStgsL.select = i < _bgStgs.length ? i : _bgStgs.length - 1;
						}
						selectBgImageSetting;
					}
				});
			}
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, false);
			grp.setText = _prop.msgs.standardKeyCode;
			_keyCodes = new Text(grp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.keyCodeWidth;
			gd.heightHint = 0;
			_keyCodes.setLayoutData = gd;
		}
	}
	void construct3(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		_tabT = new CTabItem(tabf, DWT.NONE);
		_tabT.setText = _prop.msgs.outerTools;
		_tabT.setControl = comp;
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(2, false);
			grp.setText = _prop.msgs.outerToolsTitle;
			{
				auto comp2 = new Composite(grp, DWT.NONE);
				auto cgd = new GridData(GridData.FILL_VERTICAL);
				cgd.verticalSpan = 3;
				comp2.setLayoutData = cgd;
				comp2.setLayout = zeroMarginGridLayout(2, true);
				_toolsL = new List(comp2, DWT.BORDER | DWT.SINGLE | DWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.outerToolsNameWidth;
				gd.heightHint = _prop.var.etc.outerToolsNameHeight;
				gd.horizontalSpan = 2;
				_toolsL.setLayoutData = gd;
				_toolsL.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {selectOuterTool;}
				});
				auto up = new Button(comp2, DWT.PUSH);
				up.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				up.setText = _prop.msgs.ttUp;
				up.setImage = _prop.images.menuUp;
				up.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {upTool;}
				});
				auto down = new Button(comp2, DWT.PUSH);
				down.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				down.setText = _prop.msgs.ttDown;
				down.setImage = _prop.images.menuDown;
				down.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {downTool;}
				});
			}
			auto comp2 = new Composite(grp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_BOTH);
			comp2.setLayout = zeroMarginGridLayout(3, false);
			{
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.outerToolName;
				_toolName = new Text(comp2, DWT.BORDER);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 2;
				gd.widthHint = _prop.var.etc.outerToolsNameWidth;
				_toolName.setLayoutData = gd;
				_toolName.addModifyListener(new class ModifyListener {
					override void modifyText(ModifyEvent e) {
						int i = _toolsL.getSelectionIndex;
						if (i < 0 || _toolsL.getItem(i) == _toolName.getText) return;
						_toolsL.setItem(i, _toolName.getText);
						_tools[i].name = _toolName.getText;
					}
				});
			}
			{
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.outerToolCommand;
				_toolCommand = new Text(comp2, DWT.BORDER);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = 0;
				_toolCommand.setLayoutData = gd;
				_toolCommandRef = new Button(comp2, DWT.PUSH);
				_toolCommandRef.setText = _prop.msgs.reference;
				_toolCommandRef.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						int i = _toolsL.getSelectionIndex;
						if (i < 0) return;
						selectProgram(i);
					}
				});
				_toolCommand.addModifyListener(new class ModifyListener {
					override void modifyText(ModifyEvent e) {
						int i = _toolsL.getSelectionIndex;
						if (i < 0) return;
						_tools[i].command = _toolCommand.getText;
					}
				});
			}
			{
				auto l = new Label(comp2, DWT.NONE);
				l.setText = _prop.msgs.outerToolWorkDir;
				_toolWorkDir = new Text(comp2, DWT.BORDER);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = 0;
				_toolWorkDir.setLayoutData = gd;
				_toolWorkDirRef = new Button(comp2, DWT.PUSH);
				_toolWorkDirRef.setText = _prop.msgs.reference;
				_toolWorkDirRef.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						int i = _toolsL.getSelectionIndex;
						if (i < 0) return;
						selectWorkDir(i);
					}
				});
				_toolWorkDir.addModifyListener(new class ModifyListener {
					override void modifyText(ModifyEvent e) {
						int i = _toolsL.getSelectionIndex;
						if (i < 0) return;
						_tools[i].workDir = _toolWorkDir.getText;
					}
				});
			}
			{
				auto dummy = new Composite(comp2, DWT.NONE);
				auto gd = new GridData;
				gd.verticalSpan = 3;
				gd.widthHint = 0;
				gd.heightHint = 0;
				dummy.setLayoutData = gd;
				auto hint1 = new Label(comp2, DWT.NONE);
				hint1.setText = _prop.msgs.toolsHint1;
				auto gd1 = new GridData;
				gd1.horizontalSpan = 2;
				hint1.setLayoutData = gd1;
				auto hint2 = new Label(comp2, DWT.NONE);
				hint2.setText = _prop.msgs.toolsHint2;
				auto gd2 = new GridData;
				gd2.horizontalSpan = 2;
				hint2.setLayoutData = gd2;
				auto hint3 = new Label(comp2, DWT.NONE);
				hint3.setText = _prop.msgs.toolsHint3;
				auto gd3 = new GridData;
				gd3.horizontalSpan = 2;
				hint3.setLayoutData = gd3;
			}
			{
				auto newTool = new Button(grp, DWT.PUSH);
				newTool.setLayoutData = new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_END);
				newTool.setText = _prop.msgs.newOuterTool;
				newTool.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						_tools ~= OuterTool(_prop.msgs.newOuterToolName, "", "");
						_toolsL.add(_tools[$ - 1].name);
						_toolsL.select = _tools.length - 1;
						selectOuterTool;
					}
				});
				_toolDel = new Button(grp, DWT.PUSH);
				_toolDel.setLayoutData = new GridData(GridData.FILL_HORIZONTAL | GridData.VERTICAL_ALIGN_END);
				_toolDel.setText = _prop.msgs.delOuterTool;
				_toolDel.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						int i = _toolsL.getSelectionIndex;
						if (i < 0) return;
						_toolsL.remove(i);
						_tools = _tools[0 .. i] ~ _tools[i + 1 .. $];
						if (_tools.length > 0) {
							_toolsL.select = i < _tools.length ? i : _tools.length - 1;
						}
						selectOuterTool;
					}
				});
			}
		}
	}
public:
	this(Props prop, Shell shell) {
		super(prop, shell, prop.msgs.dlgTitSettings, prop.images.menuSettings, false);
		_prop = prop;
	}

protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		auto tabf = new CTabFolder(area, DWT.BORDER);
		tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		construct1(tabf);
		construct2(tabf);
		construct3(tabf);

		_enginePath.setText = _prop.var.etc.enginePath;
		_tempDir.setText = _prop.var.etc.tempPath;
		_author.setText = _prop.var.etc.defaultAuthor;
		_histMax.setSelection = _prop.var.etc.historyMax;
		_expandXMLs.setSelection = _prop.var.etc.expandXMLs;
		_singleWindow.setSelection = _prop.var.etc.singleWindow;
		_contentsFloat.setSelection = _prop.var.etc.contentsFloat;
		_xmlCopy.setSelection = _prop.var.etc.xmlCopy;
		_saveInnerImagePath.setSelection = _prop.var.etc.saveInnerImagePath;

		_bgStgs.length = _prop.var.etc.bgImageSettings.length;
		foreach (i, stg; _prop.var.etc.bgImageSettings) {
			_bgStgsL.add(stg.name);
			_bgStgs[i] = stg.dup;
		}
		if (_bgStgs.length > 0) _bgStgsL.select = 0;
		selectBgImageSetting;

		string buf = "";
		foreach (kc; _prop.var.etc.standardKeyCodes) {
			buf ~= kc ~ "\n";
		}
		_keyCodes.setText = buf;

		_tools.length = _prop.var.etc.outerTools.length;
		foreach (i, tool; _prop.var.etc.outerTools) {
			_toolsL.add(tool.name);
			_tools[i] = tool.dup;
		}
		if (_tools.length > 0) _toolsL.select = 0;
		selectOuterTool;
	}

	override bool close(bool ok, out bool cancel) {
		if (ok) {
			void err(CTabItem tab, Text t, string msg) {
				auto dlg = new MessageBox(t.getShell, DWT.ICON_WARNING | DWT.OK);
				scope (exit) dlg.dispose;
				dlg.setText = _prop.msgs.dlgTitWarning;
				dlg.setMessage = msg;
				dlg.open;
				tab.getParent.setSelection = tab;
				t.setFocus;
			}
			string engine;
			try {
				engine = _enginePath.getText;
			} catch {
				err(_tabB, _enginePath, _prop.msgs.errorEnginePath(_prop.var.etc.engine));
				cancel = true;
				return false;
			}
			if (!.exists(engine) || .isdir(engine)) {
				err(_tabB, _enginePath, _prop.msgs.errorEnginePath(_prop.var.etc.engine));
				cancel = true;
				return false;
			}
			string temp;
			try {
				temp = _tempDir.getText;
			} catch {
				err(_tabB, _tempDir, _prop.msgs.errorTempPath);
				cancel = true;
				return false;
			}
			_prop.var.etc.enginePath = engine;
			_prop.var.etc.tempPath = temp;
			_prop.var.etc.defaultAuthor = _author.getText;
			_prop.var.etc.historyMax = _histMax.getSelection;
			_prop.var.etc.singleWindow = _singleWindow.getSelection;
			_prop.var.etc.expandXMLs = _expandXMLs.getSelection;
			_prop.var.etc.xmlCopy = _xmlCopy.getSelection;
			_prop.var.etc.saveInnerImagePath = _saveInnerImagePath.getSelection;
			_prop.var.etc.contentsFloat = _contentsFloat.getSelection;
			if (_prop.var.etc.historyMax < _prop.var.etc.openHistories.length) {
				_prop.var.etc.openHistories
					= _prop.var.etc.openHistories[0 .. _prop.var.etc.historyMax];
			}
			_prop.var.etc.bgImageSettings = _bgStgs;
			string[] lines = splitlines(_keyCodes.getText);
			if (lines.length > 0) {
				int i;
				for (i = lines.length - 1; i >= 0 && lines[i].length == 0; i--) {
					;
				}
				_prop.var.etc.standardKeyCodes = lines[0 .. i + 1];
			} else {
				_prop.var.etc.standardKeyCodes = [];
			}
			_prop.var.etc.outerTools = _tools;
		}
		return ok;
	}
}
