
module cwx.editor.gui.dwt.settingsdialog;

import cwx.background;
import cwx.utils;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.areaview;

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
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.layout.GridLayout;
import dwt.layout.GridData;

class SettingsDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	CTabItem _tabB;
	Text _enginePath;
	Text _tempDir;
	Text _author;
	Spinner _histMax;
	Text _ignorePaths;
	Button _singleWindow;
	Button _smoothingCard;
	Button _expandXMLs;
	Button _contentsFloat;
	Button _xmlCopy;
	Button _saveInnerImagePath;
	Button _traceDirectories;

	CTabItem _tabS;
	List _bgStgsL;
	BgImageSetting[] _bgStgs;
	BgImageS[] _bgImagesDefault;
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

	class Mod : SelectionAdapter, ModifyListener {
		override void widgetSelected(SelectionEvent e) {
			if (!_onProc) applyEnabled;
		}
		override void modifyText(ModifyEvent e) {
			if (!_onProc) applyEnabled;
		}
	}
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
		applyEnabled;
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
		applyEnabled;
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
		applyEnabled;
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
		applyEnabled;
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
			_prop.var.etc.engine, _prop.msgs.dlgTitEnginePath(_prop.var.etc.engine),
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
		scope (exit) dlg.dispose;
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
	private bool _onProc = false;
	void selectBgImageSetting() {
		_onProc = true;
		scope (exit) _onProc = false;
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
		_onProc = true;
		scope (exit) _onProc = false;
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
	class SelEngine : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectEngine;}
	}
	class SelTemp : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectTemp;}
	}
	class ClearHist : SelectionAdapter {
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
			_enginePath.addModifyListener(_mod);
			auto refr = new Button(grp, DWT.PUSH);
			refr.setText = _prop.msgs.reference;
			refr.addSelectionListener(new SelEngine);
			auto l = new Label(grp, DWT.NONE);
			l.setText = _prop.msgs.enginePathAtten;
			auto gd = new GridData;
			gd.horizontalSpan = 2;
			l.setLayoutData = gd;
		}
		{
			auto grp = new Group(comp, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new GridLayout(2, false);
			grp.setText = _prop.msgs.tempDir;
			_tempDir = new Text(grp, DWT.BORDER);
			_tempDir.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			_tempDir.addModifyListener(_mod);
			auto refr = new Button(grp, DWT.PUSH);
			refr.setText = _prop.msgs.reference;
			refr.addSelectionListener(new SelTemp);
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
				_author.addModifyListener(_mod);
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
				_histMax.addModifyListener(_mod);
				auto clear = new Button(grp, DWT.PUSH);
				clear.setEnabled = _prop.var.etc.openHistories.length > 0;
				clear.setText = _prop.msgs.openHistoryClear;
				clear.addSelectionListener(new ClearHist);
			}
		}
		{
			auto comp2 = new Composite(comp, DWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_BOTH);
			comp2.setLayout = zeroMarginGridLayout(2, false);
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_BOTH);
				grp.setText = _prop.msgs.ignorePaths;
				grp.setLayout = new GridLayout(1, false);
				_ignorePaths = new Text(grp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL);
				_ignorePaths.addModifyListener(_mod);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.ignorePathsWidth;
				gd.heightHint = 0;
				_ignorePaths.setLayoutData = gd;
			}
			{
				auto grp = new Group(comp2, DWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				grp.setText = _prop.msgs.settingEtc;
				grp.setLayout = new GridLayout(1, false);
				_singleWindow = new Button(grp, DWT.CHECK);
				_singleWindow.setText = _prop.msgs.singleWindow;
				_singleWindow.addSelectionListener(_mod);
				_smoothingCard = new Button(grp, DWT.CHECK);
				_smoothingCard.setText = _prop.msgs.smoothingCard;
				_smoothingCard.addSelectionListener(_mod);
				_expandXMLs = new Button(grp, DWT.CHECK);
				_expandXMLs.setText = _prop.msgs.expandXMLs;
				_expandXMLs.addSelectionListener(_mod);
				_contentsFloat = new Button(grp, DWT.CHECK);
				_contentsFloat.setText = _prop.msgs.contentsFloat;
				_contentsFloat.addSelectionListener(_mod);
				_xmlCopy = new Button(grp, DWT.CHECK);
				_xmlCopy.setText = _prop.msgs.xmlCopy;
				_xmlCopy.addSelectionListener(_mod);
				_saveInnerImagePath = new Button(grp, DWT.CHECK);
				_saveInnerImagePath.setText = _prop.msgs.saveInnerImagePath;
				_saveInnerImagePath.addSelectionListener(_mod);
				_traceDirectories = new Button(grp, DWT.CHECK);
				_traceDirectories.setText = _prop.msgs.traceDirectories;
				_traceDirectories.addSelectionListener(_mod);
			}
		}
	}
	class ModSpin(string Set) : ModifyListener {
		// FIXME: テンプレート外へのアクセスでアクセス違反
		private SettingsDialog _v;
		this(SettingsDialog v) {
			_v = v;
		}
		override void modifyText(ModifyEvent e) {
			if (_onProc) return;
			int i = _v._bgStgsL.getSelectionIndex;
			if (i < 0) return;
			auto spn = cast(Spinner) e.widget;
			mixin ("_v." ~ Set);
			applyEnabled;
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
		spn.addModifyListener(new ModSpin!(Set)(v));
		return spn;
	}
	class DefBgSetting : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto dlg = new DefBgImgDialog(_comm, _prop, getShell, _bgImagesDefault);
			if (dlg.open) {
				_bgImagesDefault = dlg.backs;
				applyEnabled;
			}
		}
	}
	class SelBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectBgImageSetting;}
	}
	class UpBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			upBgImage;
		}
	}
	class DownBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			downBgImage;
		}
	}
	class DBgImgStg : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights;
			_prop.var.etc.bgImageSettingsSashL = ws[0];
			_prop.var.etc.bgImageSettingsSashR = ws[1];
		}
	}
	class ModBgImgName : ModifyListener {
		override void modifyText(ModifyEvent e) {
			if (_onProc) return;
			int i = _bgStgsL.getSelectionIndex;
			if (i < 0 || _bgStgsL.getItem(i) == _bgImgName.getText) return;
			_bgStgsL.setItem(i, _bgImgName.getText);
			_bgStgs[i].name = _bgImgName.getText;
			applyEnabled;
		}
	}
	class PushBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _bgStgsL.getSelectionIndex;
			if (i < 0) return;
			_bgStgs[i].mask = _bgImgMask.getSelection;
			applyEnabled;
		}
	}
	class NewBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			_bgStgs ~= BgImageSetting(_prop.msgs.newBgImageSettingName, 0, 0, 0, 0, false);
			_bgStgsL.add(_bgStgs[$ - 1].name);
			_bgStgsL.select = _bgStgs.length - 1;
			selectBgImageSetting;
			applyEnabled;
		}
	}
	class DelBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _bgStgsL.getSelectionIndex;
			if (i < 0) return;
			_bgStgsL.remove(i);
			_bgStgs = _bgStgs[0 .. i] ~ _bgStgs[i + 1 .. $];
			if (_bgStgs.length > 0) {
				_bgStgsL.select = i < _bgStgs.length ? i : _bgStgs.length - 1;
			}
			selectBgImageSetting;
			applyEnabled;
		}
	}
	class DBgImgKeyCodeSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights;
			_prop.var.etc.bgImageKeyCodeSashL = ws[0];
			_prop.var.etc.bgImageKeyCodeSashR = ws[1];
		}
	}
	void construct2(CTabFolder tabf) {
		auto comp = new Composite(tabf, DWT.NONE);
		_tabS = new CTabItem(tabf, DWT.NONE);
		_tabS.setText = _prop.msgs.bgImageAndKeyCode;
		_tabS.setControl = comp;
		comp.setLayout = new GridLayout(1, true);
		auto sash = new SplitPane(comp, DWT.HORIZONTAL);
		sash.setLayoutData = new GridData(GridData.FILL_BOTH);
		auto back = new Composite(sash, DWT.NONE);
		back.setLayout = zeroMarginGridLayout(1, true);
		{
			auto grp = new Group(back, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout = cl;
			grp.setText = _prop.msgs.bgImagesDefault;
			auto defBtn = new Button(grp, DWT.PUSH);
			defBtn.setText = _prop.msgs.setBgImagesDefault;
			defBtn.addSelectionListener(new DefBgSetting);
		}
		{
			auto grp = new Group(back, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, true);
			grp.setText = _prop.msgs.bgImageSettings;
			auto leftSash = new SplitPane(grp, DWT.HORIZONTAL);
			leftSash.setLayoutData = new GridData(GridData.FILL_BOTH);
			{
				auto left = new Composite(leftSash, DWT.NONE);
				left.setLayout = zeroMarginGridLayout(2, true);
				_bgStgsL = new List(left, DWT.BORDER | DWT.SINGLE | DWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.bgImageSettingsNameWidth;
				gd.heightHint = _prop.var.etc.bgImageSettingsNameHeight;
				gd.horizontalSpan = 2;
				_bgStgsL.setLayoutData = gd;
				_bgStgsL.addSelectionListener(new SelBgImgStg);
				auto up = new Button(left, DWT.PUSH);
				up.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				up.setText = _prop.msgs.ttUp;
				up.setImage = _prop.images.menuUp;
				up.addSelectionListener(new UpBgImgStg);
				auto down = new Button(left, DWT.PUSH);
				down.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				down.setText = _prop.msgs.ttDown;
				down.setImage = _prop.images.menuDown;
				down.addSelectionListener(new DownBgImgStg);
			}
			leftSash.setWeights = [_prop.var.etc.bgImageSettingsSashL, _prop.var.etc.bgImageSettingsSashR];
			leftSash.addDisposeListener(new DBgImgStg);
			auto right = new Composite(leftSash, DWT.NONE);
			right.setLayout = zeroMarginGridLayout(1, true);
			{
				auto comp2 = new Composite(right, DWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
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
					_bgImgName.addModifyListener(new ModBgImgName);
					_bgImgMask.addSelectionListener(new PushBgImgStg);
				}
				_bgImgX = createS!("_bgStgs[i].x = spn.getSelection;")
					(this, comp2, _prop.msgs.left, _prop.looks.posLeftMax, _prop.looks.posLeftMin);
				_bgImgY = createS!("_bgStgs[i].y = spn.getSelection;")
					(this, comp2, _prop.msgs.top, _prop.looks.posTopMax, _prop.looks.posTopMin);
				_bgImgW = createS!("_bgStgs[i].width = spn.getSelection;")
					(this, comp2, _prop.msgs.width, _prop.looks.backWidthMax, _prop.looks.backWidthMin);
				_bgImgH = createS!("_bgStgs[i].height = spn.getSelection;")
					(this, comp2, _prop.msgs.height, _prop.looks.backHeightMax, _prop.looks.backHeightMin);
			}
			{
				auto buttons = new Composite(right, DWT.NONE);
				buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
				buttons.setLayout = zeroMarginGridLayout(2, true);
				auto newBstg = new Button(buttons, DWT.PUSH);
				newBstg.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				newBstg.setText = _prop.msgs.newBgImageSetting;
				newBstg.addSelectionListener(new NewBgImgStg);
				_bgImgDel = new Button(buttons, DWT.PUSH);
				_bgImgDel.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_bgImgDel.setText = _prop.msgs.delBgImageSetting;
				_bgImgDel.addSelectionListener(new DelBgImgStg);
			}
		}
		{
			auto grp = new Group(sash, DWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, false);
			grp.setText = _prop.msgs.standardKeyCode;
			_keyCodes = new Text(grp, DWT.BORDER | DWT.MULTI | DWT.V_SCROLL);
			_keyCodes.addModifyListener(_mod);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.keyCodeWidth;
			gd.heightHint = 0;
			_keyCodes.setLayoutData = gd;
		}
		sash.setWeights = [_prop.var.etc.bgImageKeyCodeSashL, _prop.var.etc.bgImageKeyCodeSashR];
		sash.addDisposeListener(new DBgImgKeyCodeSash);
	}
	class SelOutTools : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectOuterTool;}
	}
	class UpOutTools : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			upTool;
		}
	}
	class DownOutTools : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			downTool;
		}
	}
	class ModOutToolName : ModifyListener {
		override void modifyText(ModifyEvent e) {
			if (_onProc) return;
			int i = _toolsL.getSelectionIndex;
			if (i < 0 || _toolsL.getItem(i) == _toolName.getText) return;
			_toolsL.setItem(i, _toolName.getText);
			_tools[i].name = _toolName.getText;
			applyEnabled;
		}
	}
	class PushToolCmdRef : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			selectProgram(i);
			applyEnabled;
		}
	}
	class ModToolCmd : ModifyListener {
		override void modifyText(ModifyEvent e) {
			if (_onProc) return;
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			_tools[i].command = _toolCommand.getText;
			applyEnabled;
		}
	}
	class PushToolWorkDirRef : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			selectWorkDir(i);
			applyEnabled;
		}
	}
	class ModToolWorkDir : ModifyListener {
		override void modifyText(ModifyEvent e) {
			if (_onProc) return;
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			_tools[i].workDir = _toolWorkDir.getText;
			applyEnabled;
		}
	}
	class NewOutTool : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			_tools ~= OuterTool(_prop.msgs.newOuterToolName, "", "");
			_toolsL.add(_tools[$ - 1].name);
			_toolsL.select = _tools.length - 1;
			selectOuterTool;
			applyEnabled;
		}
	}
	class DelOutTool : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			_toolsL.remove(i);
			_tools = _tools[0 .. i] ~ _tools[i + 1 .. $];
			if (_tools.length > 0) {
				_toolsL.select = i < _tools.length ? i : _tools.length - 1;
			}
			selectOuterTool;
			applyEnabled;
		}
	}
	class DOutToolsSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights;
			_prop.var.etc.outerToolsSashL = ws[0];
			_prop.var.etc.outerToolsSashR = ws[1];
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
			grp.setLayout = new GridLayout(1, true);
			grp.setText = _prop.msgs.outerToolsTitle;
			auto sash = new SplitPane(grp, DWT.HORIZONTAL);
			sash.setLayoutData = new GridData(GridData.FILL_BOTH);
			{
				auto left = new Composite(sash, DWT.NONE);
				left.setLayout = zeroMarginGridLayout(2, true);
				_toolsL = new List(left, DWT.BORDER | DWT.SINGLE | DWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.outerToolsNameWidth;
				gd.heightHint = _prop.var.etc.outerToolsNameHeight;
				gd.horizontalSpan = 2;
				_toolsL.setLayoutData = gd;
				_toolsL.addSelectionListener(new SelOutTools);
				auto up = new Button(left, DWT.PUSH);
				up.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				up.setText = _prop.msgs.ttUp;
				up.setImage = _prop.images.menuUp;
				up.addSelectionListener(new UpOutTools);
				auto down = new Button(left, DWT.PUSH);
				down.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				down.setText = _prop.msgs.ttDown;
				down.setImage = _prop.images.menuDown;
				down.addSelectionListener(new DownOutTools);
			}
			auto right = new Composite(sash, DWT.NONE);
			right.setLayout = zeroMarginGridLayout(1, true);
			{
				auto comp2 = new Composite(right, DWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				comp2.setLayout = zeroMarginGridLayout(3, false);
				{
					auto l = new Label(comp2, DWT.NONE);
					l.setText = _prop.msgs.outerToolName;
					_toolName = new Text(comp2, DWT.BORDER);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 2;
					gd.widthHint = _prop.var.etc.outerToolsNameWidth;
					_toolName.setLayoutData = gd;
					_toolName.addModifyListener(new ModOutToolName);
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
					_toolCommandRef.addSelectionListener(new PushToolCmdRef);
					_toolCommand.addModifyListener(new ModToolCmd);
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
					_toolWorkDirRef.addSelectionListener(new PushToolWorkDirRef);
					_toolWorkDir.addModifyListener(new ModToolWorkDir);
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
			}
			{
				auto buttons = new Composite(right, DWT.NONE);
				buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
				buttons.setLayout = zeroMarginGridLayout(2, true);
				auto newTool = new Button(buttons, DWT.PUSH);
				newTool.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				newTool.setText = _prop.msgs.newOuterTool;
				newTool.addSelectionListener(new NewOutTool);
				_toolDel = new Button(buttons, DWT.PUSH);
				_toolDel.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_toolDel.setText = _prop.msgs.delOuterTool;
				_toolDel.addSelectionListener(new DelOutTool);
			}
			sash.setWeights = [_prop.var.etc.outerToolsSashL, _prop.var.etc.outerToolsSashR];
			sash.addDisposeListener(new DOutToolsSash);
		}
	}
	private Mod _mod;
public:
	this(Commons comm, Props prop, Shell shell) {
		super(prop, shell, prop.msgs.dlgTitSettings, prop.images.menuSettings, true, prop.var.settingsDlg, true);
		_comm = comm;
		_prop = prop;
	}

protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		auto tabf = new CTabFolder(area, DWT.BORDER);
		tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		_mod = new Mod;
		construct1(tabf);
		construct2(tabf);
		construct3(tabf);

		_enginePath.setText = _prop.var.etc.enginePath;
		_tempDir.setText = _prop.var.etc.tempPath;
		_author.setText = _prop.var.etc.defaultAuthor;
		_histMax.setSelection = _prop.var.etc.historyMax;
		string ipbuf = "";
		foreach (path; _prop.var.etc.ignorePaths) {
			ipbuf ~= path ~ "\n";
		}
		_ignorePaths.setText = ipbuf;
		_expandXMLs.setSelection = _prop.var.etc.expandXMLs;
		_smoothingCard.setSelection = _prop.var.etc.smoothingCard;
		_singleWindow.setSelection = _prop.var.etc.singleWindow;
		_contentsFloat.setSelection = _prop.var.etc.contentsFloat;
		_xmlCopy.setSelection = _prop.var.etc.xmlCopy;
		_saveInnerImagePath.setSelection = _prop.var.etc.saveInnerImagePath;
		_traceDirectories.setSelection = _prop.var.etc.traceDirectories;

		_bgStgs.length = _prop.var.etc.bgImageSettings.length;
		foreach (i, stg; _prop.var.etc.bgImageSettings) {
			_bgStgsL.add(stg.name);
			_bgStgs[i] = stg.dup;
		}
		if (_bgStgs.length > 0) _bgStgsL.select = 0;
		_bgImagesDefault = _prop.var.etc.bgImagesDefault;
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

	override bool apply() {
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
			return false;
		}
		if (engine.length) {
			if (!.exists(engine) || .isdir(engine)) {
				err(_tabB, _enginePath, _prop.msgs.errorEnginePath(_prop.var.etc.engine));
				return false;
			}
		}
		string temp;
		try {
			temp = _tempDir.getText;
		} catch {
			err(_tabB, _tempDir, _prop.msgs.errorTempPath);
			return false;
		}
		string[] oldKeyCodes = _prop.var.etc.standardKeyCodes;
		auto tools = _prop.var.etc.outerTools;
		string[] oldIgnorePaths = _prop.var.etc.ignorePaths;
		bool oldSmoothingCard = _prop.var.etc.smoothingCard;
		scope (exit) {
			if (oldKeyCodes != _prop.var.etc.standardKeyCodes) {
				_comm.refStandardKeyCodes.call;
			}
			if (tools != _prop.var.etc.outerTools) {
				_comm.refOuterTools.call;
			}
			if (oldIgnorePaths != _prop.var.etc.ignorePaths) {
				_comm.refIgnorePaths.call;
			}
			if (oldSmoothingCard != _prop.var.etc.smoothingCard) {
				_comm.refCardState.call;
			}
		}
		_prop.var.etc.enginePath = engine;
		_prop.var.etc.tempPath = temp;
		_prop.var.etc.defaultAuthor = _author.getText;
		_prop.var.etc.historyMax = _histMax.getSelection;
		string[] ipLines = splitlines(_ignorePaths.getText);
		if (ipLines.length > 0) {
			int i;
			for (i = ipLines.length - 1; i >= 0 && ipLines[i].length == 0; i--) {
				;
			}
			_prop.var.etc.ignorePaths = ipLines[0 .. i + 1];
		} else {
			_prop.var.etc.ignorePaths = [];
		}
		_prop.var.etc.singleWindow = _singleWindow.getSelection;
		_prop.var.etc.smoothingCard = _smoothingCard.getSelection;
		_prop.var.etc.expandXMLs = _expandXMLs.getSelection;
		_prop.var.etc.xmlCopy = _xmlCopy.getSelection;
		_prop.var.etc.saveInnerImagePath = _saveInnerImagePath.getSelection;
		_prop.var.etc.traceDirectories = _traceDirectories.getSelection;
		_prop.var.etc.contentsFloat = _contentsFloat.getSelection;
		if (_prop.var.etc.historyMax < _prop.var.etc.openHistories.length) {
			_prop.var.etc.openHistories
				= _prop.var.etc.openHistories[0 .. _prop.var.etc.historyMax];
		}
		_prop.var.etc.bgImageSettings = _bgStgs;
		_prop.var.etc.bgImagesDefault = _bgImagesDefault;
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
		return true;
	}
	override bool close(bool ok, out bool cancel) {
		if (ok) {
			ok = apply;
			if (!ok) cancel = true;
		}
		return ok;
	}
}

class DefBgImgDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	BgImageContainer _cont;
	BgImagesView _view;

public:
	this(Commons comm, Props prop, Shell shell, BgImageS[] bgImagesDefault) {
		super(prop, shell, prop.msgs.dlgTitBgImagesDefault,
			prop.images.menuSettings, true, prop.var.bgImagesDlg);
		_comm = comm;
		_prop = prop;

		BgImage[] bgImages;
		auto skin = findSkin(_prop, null);
		_cont = new BgImageContainer(BgImageS.createBgImages(skin, bgImagesDefault));
	}

	BgImageS[] backs() {return BgImageS.createBgImageSs(_cont.backs);}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			_view = createBgImagesViewAndMenu(_comm, _prop, null, _cont, area);
			_view.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
	}

	override bool close(bool ok) {
		return ok;
	}
}
