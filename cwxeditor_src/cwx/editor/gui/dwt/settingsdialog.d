
module cwx.editor.gui.dwt.settingsdialog;

import cwx.background;
import cwx.utils;
import cwx.xml;
import cwx.summary;
import cwx.skin;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.undo;

import std.path;
import std.file;
import std.string;
import std.functional;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.List;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.DirectoryDialog;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;

class SettingsDialog : AbsDialog {
private:
	class UndoBgStgs : Undo {
		private BgImageSetting[] _old;
		private int _selected;
		this () {
			save();
		}
		private void save() {
			_old = _bgStgs.dup;
			_selected = _bgStgsL.getSelectionIndex;
		}
		private void impl() {
			auto old = _old;
			auto selected = _selected;
			save();
			_bgStgsL.setRedraw = false;
			scope (exit) _bgStgsL.setRedraw = true;
			_bgStgs = old;
			_bgStgsL.removeAll();
			foreach (o; old) {
				_bgStgsL.add(o.name);
			}
			_bgStgsL.select = selected;
			_bgStgsL.showSelection();
			selectBgImageSetting();
			applyEnabled();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			// Nothing
		}
	}
	void storeBgStgs() {
		_undoBgStgs ~= new UndoBgStgs;
	}
	void undoBgStgs() {
		_undoBgStgs.undo();
	}
	void redoBgStgs() {
		_undoBgStgs.redo();
	}
	class UndoTools : Undo {
		private OuterTool[] _old;
		private int _selected;
		this () {
			save();
		}
		private void save() {
			_old = _tools.dup;
			_selected = _toolsL.getSelectionIndex;
		}
		private void impl() {
			auto old = _old;
			auto selected = _selected;
			save();
			_toolsL.setRedraw = false;
			scope (exit) _toolsL.setRedraw = true;
			_tools = old;
			_toolsL.removeAll();
			foreach (o; old) {
				_toolsL.add(o.name);
			}
			_toolsL.select = selected;
			_toolsL.showSelection();
			selectOuterTool();
			applyEnabled();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			// Nothing
		}
	}
	void storeTools() {
		_undoTools ~= new UndoTools;
	}
	void undoTools() {
		_undoTools.undo();
	}
	void redoTools() {
		_undoTools.redo();
	}
	class UndoCEngines : Undo {
		private ClassicEngine[] _old;
		private int _selected;
		this () {
			save();
		}
		private void save() {
			_old = _cEngines.dup;
			_selected = _cEnginesL.getSelectionIndex;
		}
		private void impl() {
			auto old = _old;
			auto selected = _selected;
			save();
			_cEnginesL.setRedraw = false;
			scope (exit) _cEnginesL.setRedraw = true;
			_cEngines = old;
			_cEnginesL.removeAll();
			foreach (o; old) {
				_cEnginesL.add(o.name);
			}
			_cEnginesL.select = selected;
			_cEnginesL.showSelection();
			selectCEngine();
			applyEnabled();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			// Nothing
		}
	}
	void storeCEngines() {
		_undoCEngines ~= new UndoCEngines;
	}
	void undoCEngines() {
		_undoCEngines.undo();
	}
	void redoCEngines() {
		_undoCEngines.redo();
	}

	Commons _comm;
	Props _prop;
	Summary _summ;
	DockingFolderCTC _dock;
	UndoManager _undoBgStgs;
	UndoManager _undoTools;
	UndoManager _undoCEngines;
	KeyDownFilter _kdFilter;

	CTabItem _tabB;
	Text _enginePath;
	Text _tempDir;
	Text _backupDir;
	Button _backupEnabled;
	Spinner _backupInterval;
	Spinner _backupCount;
	Button _backupRef;
	Button _backupDirOpen;
	Text _author;
	Text _wallpaper;
	Spinner _histMax;
	Spinner _sHistMax;

	CTabItem _tabS;
	List _bgStgsL;
	Composite _bgStgsView;
	BgImageSetting[] _bgStgs;
	BgImageS[] _bgImagesDefault;
	Text _bgImgName;
	Spinner _bgImgX;
	Spinner _bgImgY;
	Spinner _bgImgW;
	Spinner _bgImgH;
	Button _bgImgMask;
	Button _bgImgAlt;
	Button _bgImgDel;
	TextMenuModify[] _bgImgTMs;
	Text _keyCodes;

	CTabItem _tabT;
	Composite _toolsView;
	List _toolsL;
	OuterTool[] _tools;
	Text _toolName;
	Text _toolCommand;
	Button _toolCommandRef;
	Button _toolCommandDirOpen;
	Text _toolWorkDir;
	Button _toolWorkDirRef;
	Button _toolWorkDirOpen;
	Button _toolAlt;
	Button _toolDel;
	TextMenuModify[] _toolTMs;

	CTabItem _tabC;
	Composite _cEnginesView;
	List _cEnginesL;
	ClassicEngine[] _cEngines;
	Text _cEngineName;
	Text _cEnginePath;
	Button _cEnginePathRef;
	Button _cEnginePathDirOpen;
	Text _cEngineDataDir;
	Button _cEngineDataDirRef;
	Button _cEngineDataDirOpen;
	Text _cEngineExecute;
	Button _cEngineExecuteRef;
	Button _cEngineExecuteDirOpen;
	Button _cEngineAlt;
	Button _cEngineDel;
	TextMenuModify[] _cEngineTMs;

	CTabItem _tabE;
	Text _ignorePaths;
	Button _singleWindow;
	Button _smoothingCard;
	Button _showImagePreview;
	Button _expandXMLs;
	Button _contentsFloat;
	Button _xmlCopy;
	Button _saveInnerImagePath;
	Button _traceDirectories;
	Button _logicalSort;
	Button _copyDesc;
	Button _refCardsAtEditBgImage;
	Button _addNewClassicEngine;
	Button _doubleIO;
	Button _switchTabWheel;
	Button _openTabAtRightOfCurrentTab;
	version (Windows) {
		Combo _soundPlayType;
	}
	Text _savedSound;

	class RefE : SelectionAdapter, ModifyListener {
		override void widgetSelected(SelectionEvent e) {
			refreshEnabled();
		}
		override void modifyText(ModifyEvent e) {
			refreshEnabled();
		}
	}
	void up(T)(List list, ref T[] array) {
		int i = list.getSelectionIndex;
		if (i <= 0) return;
		string tempS = list.getItem(i - 1);
		list.setItem(i - 1, list.getItem(i));
		list.setItem(i, tempS);
		auto temp = array[i - 1];
		array[i - 1] = array[i];
		array[i] = temp;
		list.select = i - 1;
		applyEnabled;
	}
	void down(T)(List list, ref T[] array) {
		int i = list.getSelectionIndex;
		if (i < 0 || array.length <= i + 1) return;
		string tempS = list.getItem(i + 1);
		list.setItem(i + 1, list.getItem(i));
		list.setItem(i, tempS);
		auto temp = array[i + 1];
		array[i + 1] = array[i];
		array[i] = temp;
		list.select = i + 1;
		applyEnabled;
	}
	void upBgImage() {
		storeBgStgs();
		up(_bgStgsL, _bgStgs);
	}
	void downBgImage() {
		storeBgStgs();
		down(_bgStgsL, _bgStgs);
	}
	void upTool() {
		storeTools();
		up(_toolsL, _tools);
	}
	void downTool() {
		storeTools();
		down(_toolsL, _tools);
	}
	void upCEngine() {
		storeCEngines();
		up(_cEnginesL, _cEngines);
	}
	void downCEngine() {
		storeCEngines();
		down(_cEnginesL, _cEngines);
	}
	class DropFiles : DropTargetAdapter {
		private Text _text;
		private string delegate(string[] files) _drop;
		private void delegate(string) _dropPath;
		this (Text text, string delegate(string[] files) drop, void delegate(string) dropPath = null) {
			_text = text;
			_drop = drop;
			_dropPath = dropPath;
		}
		override void dragEnter(DropTargetEvent e){
			e.detail = DND.DROP_LINK;
		}
		override void dragOver(DropTargetEvent e){
			e.detail = DND.DROP_LINK;
		}
		override void drop(DropTargetEvent e){
			e.detail = DND.DROP_NONE;
			auto str = _drop((cast(FileNames) e.data).array);
			if (str.length && str != _text.getText) {
				_text.setText = str;
				_text.selectAll;
				e.detail = DND.DROP_LINK;
				if (_dropPath) _dropPath(str);
			}
		}
	}
	void setupDropFile(Control c, Text text, string delegate(string[] files) drop, void delegate(string) dropPath = null) {
		auto dropt = new DropTarget(c, DND.DROP_DEFAULT | DND.DROP_LINK);
		dropt.setTransfer([FileTransfer.getInstance]);
		if (!drop) drop = &dropDefault;
		dropt.addDropListener(new DropFiles(text, drop, dropPath));
	}
	string dropDefault(string[] files) {
		return files.length ? files[0] : "";
	}
	string dropEngine(string[] files) {
		if (!files.length) return "";
		string file = files[0];
		if (cfnmatch(baseName(file), _prop.var.etc.engine)) {
			return file;
		} else {
			return "";
		}
	}
	const SYSTEM_SOUND_EXT = [
		"aiff", // AIFF
		"mid", "midi", // MIDI
		"mod", "s3m", "xm", "it", "mt2", "669", "med", // MOD
		"ogg", "ogv", "oga", "ogx", // Ogg
		"voc", // VOC
		"wav" // WAV/RIFF
	];
	string dropSysSound(string[] files) {
		if (!files.length) return "";
		foreach (file; files) {
			string ext = cwx.utils.toLower(cwx.utils.getExt(file));
			if (.contains!("a == b", string)(SYSTEM_SOUND_EXT, ext)) {
				return file;
			}
		}
		return "";
	}
	string dropDir(string[] files) {
		if (!files.length) return "";
		string file = files[0];
		if (!.exists(file)) return "";
		if (.isDir(file)) {
			return file;
		} else {
			return dirName(file);
		}
	}
	string dropCEnginePath(string[] files) {
		if (!files.length) return "";
		string file = files[0];
		if (.exists(file) && .isDir(file)) {
			string resDir, lEnginePath;
			if (Skin.hasClassicEngine(file, resDir, lEnginePath)) {
				return lEnginePath;
			}
			return file;
		}
		return file;
	}
	string curCEnginePath() {
		string path = _cEnginePath.getText;
		if (!path.length) return path;
		if (cwx.utils.isabs(path)) return path;
		return std.path.buildPath(nabs(_prop.parent.appPath).dirName, path);
	}
	string dropCEngineSub(string file) {
		string engine = curCEnginePath;
		if (!engine.length) return file;
		return abs2rel(engine.dirName, file);
	}
	string dropCEngineDataDir(string[] files) {
		return dropCEngineSub(dropDir(files));
	}
	string dropCEngineExecute(string[] files) {
		return dropCEngineSub(dropDefault(files));
	}

	const WALLPAPER_EXT = ["bmp", "ico", "icon", "jpg", "jpeg", "gif", "png", "tif", "tiff"];
	string dropWallpaper(string[] files) {
		if (!files.length) return "";
		foreach (file; files) {
			if (.contains!("a == b", string)(WALLPAPER_EXT, cwx.utils.toLower(cwx.utils.getExt(file)))) {
				return file;
			}
		}
		return "";
	}
	static string selectFile(Text file, string[] name, string[] ext, string fileName, string title, string p) {
		auto dlg = new FileDialog(file.getShell, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.OPEN);
		dlg.setFilterExtensions = ext;
		dlg.setFilterNames = name;
		dlg.setText = title;
		dlg.setFilterPath = dirName(nabs(p));
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
	void selectSysSound(Text widget) {
		string[] extArr;
		foreach (sse; SYSTEM_SOUND_EXT) {
			extArr ~= "*." ~ sse;
		}
		string exts = std.string.join(extArr, ";");
		selectFile(widget, [_prop.msgs.playableSounds(exts)], [exts],
			baseName(widget.getText), _prop.msgs.dlgTitSystemSound,
			widget.getText);
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
	string selectDir(Text dir, string title, string msg, string p, bool appPath = true) {
		auto dlg = new DirectoryDialog(dir.getShell);
		dlg.setText = title;
		dlg.setMessage = msg;
		string path = p;
		if (appPath) {
			auto d = dir.getText;
			if (!cwx.utils.isabs(d)) {
				d = std.path.buildPath(std.path.dirName(_prop.parent.appPath), d);
			}
			path = d;
		}
		dlg.setFilterPath = nabs(path);
		string fname = dlg.open;
		if (fname) {
			dir.setText = fname;
		}
		return fname;
	}
	void selectCEnginePath(int i) {
		auto cEngine = _cEngines[i];
		string[] ext;
		version (Windows) {
			ext = ["*.exe", "*.*"];
		} else {
			ext = ["*.*"];
		}
		string fname = selectFile(_cEnginePath, _prop.msgs.classicEnginePathTName, ext, "", _prop.msgs.dlgTitClassicEnginePath, cEngine.enginePath);
		if (fname) {
			_cEngines[i].enginePath = fname;
			dropCEnginePath(fname);
		}
	}
	void dropCEnginePath(string path) {
		auto i = _cEnginesL.getSelectionIndex;
		if (-1 == i) return;
		string resDir = Skin.findResDir(path.dirName);
		if (resDir.length) {
			_cEngines[i].dataDirName = resDir;
			_cEngineDataDir.setText = resDir;
		}
	}
	void selectCEngineDataDir(int i) {
		auto cEngine = _cEngines[i];
		string path = cEngine.dataDirName;
		if (cEngine.enginePath.length && !cwx.utils.isabs(path)) {
			path = std.path.buildPath(cEngine.enginePath.dirName, path);
		}
		path = nabs(path);
		string fname = selectDir(_cEngineDataDir, _prop.msgs.classicEngineDataDirName, _prop.msgs.classicEngineDataDirNameDesc, path, false);
		if (fname) {
			fname = dropCEngineSub(fname);
			_cEngineDataDir.setText = fname;
			_cEngines[i].dataDirName = fname;
		}
	}
	void selectCEngineExecute(int i) {
		auto cEngine = _cEngines[i];
		string[] ext;
		version (Windows) {
			ext = ["*.exe", "*.*"];
		} else {
			ext = ["*.*"];
		}
		string path = cEngine.execute;
		string fileName = "";
		if (path.length) {
			fileName = path.baseName;
			if (cEngine.enginePath.length && !cwx.utils.isabs(path)) {
				path = std.path.buildPath(cEngine.enginePath.dirName, path);
			}
		} else {
			path = std.path.buildPath(cEngine.enginePath.dirName, "*.exe");
		}
		path = nabs(path);
		string fname = selectFile(_cEngineExecute, _prop.msgs.classicEngineExecuteTName, ext, fileName, _prop.msgs.dlgTitClassicEngineExecute, path);
		if (fname) {
			fname = dropCEngineSub(fname);
			_cEngineExecute.setText = fname;
			_cEngines[i].execute = fname;
		}
	}
	void selectTemp() {
		selectDir(_tempDir, _prop.msgs.tempDir, _prop.msgs.tempDirDesc, _prop.tempPath);
	}
	void selectBackup() {
		selectDir(_backupDir, _prop.msgs.backupDir, _prop.msgs.backupDirDesc, _prop.backupPath);
	}
	void selectWorkDir(int i) {
		auto tool = _tools[i];
		string fname = selectDir(_toolWorkDir, _prop.msgs.toolWorkDir, _prop.msgs.toolWorkDirDesc, tool.workDir);
		if (fname) {
			_tools[i].workDir = fname;
		}
	}
	void selectWallpaper() {
		auto filterName = [_prop.msgs.filterWallpaper, _prop.msgs.filterAll];
		string[] filter = [
			"*." ~ std.string.join(WALLPAPER_EXT.dup, ";*."),
			"*"
		];
		selectFile(_wallpaper, filterName, filter,
			_prop.var.etc.wallpaper, _prop.msgs.dlgTitWallpaper, getcwd);
	}
	void selectBgImageSetting() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		int i = _bgStgsL.getSelectionIndex;
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
		_bgImgAlt.setEnabled = false;
		foreach (tm; _bgImgTMs) {
			tm.reset();
		}
	}
	void selectOuterTool() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		int i = _toolsL.getSelectionIndex;
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
		_toolAlt.setEnabled = false;
		foreach (tm; _toolTMs) {
			tm.reset();
		}
	}
	void selectCEngine() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		int i = _cEnginesL.getSelectionIndex;
		_cEngineDel.setEnabled = i >= 0;
		if (i >= 0) {
			_cEngineName.setText = _cEngines[i].name;
			_cEnginePath.setText = _cEngines[i].enginePath;
			_cEngineDataDir.setText = _cEngines[i].dataDirName;
			_cEngineExecute.setText = _cEngines[i].execute;
		} else {
			_cEngineName.setText = "";
			_cEnginePath.setText = "";
			_cEngineDataDir.setText = "";
			_cEngineExecute.setText = "";
		}
		_cEngineAlt.setEnabled = false;
		foreach (tm; _cEngineTMs) {
			tm.reset();
		}
	}
	class SelEngine : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectEngine;}
	}
	class SelTemp : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectTemp;}
	}
	class SelBackup : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectBackup;}
	}
	class SelWallpaper : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectWallpaper;}
	}
	class SelSysSound : SelectionAdapter {
		private Text _text;
		this (Text text) {
			_text = text;
		}
		override void widgetSelected(SelectionEvent e) {
			selectSysSound(_text);
		}
	}
	class ClearHist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto dlg = new MessageBox(_histMax.getShell, SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
			dlg.setText = _prop.msgs.dlgTitQuestion;
			dlg.setMessage = _prop.msgs.dlgMsgHistoryClear;
			if (SWT.OK == dlg.open) {
				_prop.var.etc.openHistories = [];
				(cast(Control) e.widget).setEnabled = false;
			}
		}
	}
	class ClearSHist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto dlg = new MessageBox(_sHistMax.getShell, SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
			dlg.setText = _prop.msgs.dlgTitQuestion;
			dlg.setMessage = _prop.msgs.dlgMsgSearchHistoryClear;
			if (SWT.OK == dlg.open) {
				_prop.var.etc.searchHistories = [];
				_prop.var.etc.replaceHistories = [];
				(cast(Control) e.widget).setEnabled = false;
			}
		}
	}
	class OpenDir : SelectionAdapter {
		private bool _cEngineSub;
		private Text _text;
		this (Text text, bool cEngineSub) {
			_text = text;
			_cEngineSub = cEngineSub;
		}
		override void widgetSelected(SelectionEvent e) {
			string file = _text.getText;
			if (!cwx.utils.isabs(file)) {
				if (_cEngineSub) {
					auto engine = curCEnginePath;
					if (engine.length) {
						file = std.path.buildPath(engine.dirName, file);
					}
				} else {
					file = std.path.buildPath(_prop.parent.appPath.dirName, file);
				}
			}
			if (!.exists(file) || !isDir(file)) {
				file = file.dirName;
			}
			if (!.exists(file)) return;
			openFolder(file);
		}
	}
	Button createOpenButton(Composite parent, Text path, bool dir) {
		auto open = new Button(parent, SWT.PUSH);
		open.setToolTipText = dir ? _prop.msgs.ttOpenDirectory : _prop.msgs.ttOpenFilePlace;
		open.setImage = _prop.images.menuOpenDirectory;
		open.addSelectionListener(new OpenDir(path, false));
		return open;
	}
	Button createCEngineSubOpenButton(Composite parent, Text path, bool dir) {
		auto open = new Button(parent, SWT.PUSH);
		open.setToolTipText = dir ? _prop.msgs.ttOpenDirectory : _prop.msgs.ttOpenFilePlace;
		open.setImage = _prop.images.menuOpenDirectory;
		open.addSelectionListener(new OpenDir(path, true));
		return open;
	}
	void construct1(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		_tabB = new CTabItem(tabf, SWT.NONE);
		_tabB.setText = _prop.msgs.baseSettings;
		_tabB.setControl = comp;
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new GridLayout(3, false);
			grp.setText = _prop.msgs.enginePath(_prop.var.etc.engine);
			_enginePath = new Text(grp, SWT.BORDER);
			createTextMenu!Text(_prop, _enginePath, &catchMod);
			_enginePath.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			mod(_enginePath);
			auto refr = new Button(grp, SWT.PUSH);
			refr.setText = _prop.msgs.reference;
			refr.addSelectionListener(new SelEngine);
			createOpenButton(grp, _enginePath, false);
			auto l = new Label(grp, SWT.NONE);
			l.setText = _prop.msgs.enginePathAtten;
			auto gd = new GridData;
			gd.horizontalSpan = 3;
			l.setLayoutData = gd;
			setupDropFile(grp, _enginePath, &dropEngine);
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setLayout = new GridLayout(3, false);
			grp.setText = _prop.msgs.tempDir;
			_tempDir = new Text(grp, SWT.BORDER);
			createTextMenu!Text(_prop, _tempDir, &catchMod);
			_tempDir.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			mod(_tempDir);
			auto refr = new Button(grp, SWT.PUSH);
			refr.setText = _prop.msgs.reference;
			refr.addSelectionListener(new SelTemp);
			createOpenButton(grp, _tempDir, true);
			setupDropFile(grp, _tempDir, &dropDir);
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.backupDir;
			auto gl = new GridLayout(3, false);
			gl.horizontalSpacing = 10;
			grp.setLayout = gl;

			{
				_backupEnabled = new Button(grp, SWT.CHECK);
				_backupEnabled.setText = _prop.msgs.backupEnabled;
				mod(_backupEnabled);
				_backupEnabled.addSelectionListener(_refe);
			}
			{
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				comp2.setLayout = zeroMarginGridLayout(3, false);
				auto l = new Label(comp2, SWT.CENTER);
				l.setText = _prop.msgs.backupInterval;
				_backupInterval = new Spinner(comp2, SWT.BORDER);
				_backupInterval.setMinimum = 1;
				_backupInterval.setMaximum = 99;
				mod(_backupInterval);
				auto l2 = new Label(comp2, SWT.CENTER);
				l2.setText = _prop.msgs.minute;
			}
			{
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				comp2.setLayout = zeroMarginGridLayout(2, false);
				auto l = new Label(comp2, SWT.CENTER);
				l.setText = _prop.msgs.backupCount;
				_backupCount = new Spinner(comp2, SWT.BORDER);
				_backupCount.setMinimum = 0;
				_backupCount.setMaximum = 99;
				mod(_backupCount);
			}
			{
				auto comp2 = new Composite(grp, SWT.NONE);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				comp2.setLayoutData = gd;;
				comp2.setLayout = zeroMarginGridLayout(4, false);
				auto l = new Label(comp2, SWT.NONE);
				l.setText = _prop.msgs.backupPath;
				_backupDir = new Text(comp2, SWT.BORDER);
				createTextMenu!Text(_prop, _backupDir, &catchMod);
				_backupDir.setLayoutData = new GridData(GridData.FILL_BOTH);
				mod(_backupDir);
				_backupRef = new Button(comp2, SWT.PUSH);
				_backupRef.setText = _prop.msgs.reference;
				_backupRef.addSelectionListener(new SelBackup);
				_backupDirOpen = createOpenButton(comp2, _backupDir, true);
				setupDropFile(grp, _backupDir, &dropDir);
			}
		}
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			comp2.setLayout = zeroMarginGridLayout(2, false);
			{
				auto comp3 = new Composite(comp2, SWT.NONE);
				comp3.setLayoutData = new GridData(GridData.FILL_BOTH);
				comp3.setLayout = zeroMarginGridLayout(1, false);
				{
					auto grp = new Group(comp3, SWT.NONE);
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					auto cl = new CenterLayout;
					cl.fillHorizontal = true;
					grp.setLayout = cl;
					grp.setText = _prop.msgs.scenarioAuthor;
					_author = new Text(grp, SWT.BORDER);
					createTextMenu!Text(_prop, _author, &catchMod);
					mod(_author);
				}
				{
					auto grp = new Group(comp3, SWT.NONE);
					grp.setLayoutData = new GridData(GridData.FILL_BOTH);
					grp.setLayout = new GridLayout(3, false);
					grp.setText = _prop.msgs.wallpaper;
					_wallpaper = new Text(grp, SWT.BORDER);
					createTextMenu!Text(_prop, _wallpaper, &catchMod);
					_wallpaper.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					mod(_wallpaper);
					auto refr = new Button(grp, SWT.PUSH);
					refr.setText = _prop.msgs.reference;
					refr.addSelectionListener(new SelWallpaper);
					createOpenButton(grp, _wallpaper, false);
					setupDropFile(grp, _wallpaper, &dropWallpaper);
				}
			}
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setText = _prop.msgs.historiesSettings;
				grp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
				grp.setLayout = new GridLayout(3, false);
				{
					auto lComp = new Composite(grp, SWT.NONE);
					auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
					cl.fillHorizontal = true;
					lComp.setLayout = cl;
					lComp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
					auto l = new Label(lComp, SWT.NONE);
					l.setText = _prop.msgs.openHistoryMax;
					_histMax = new Spinner(grp, SWT.BORDER);
					_histMax.setMinimum = 0;
					_histMax.setMaximum = 99;
					mod(_histMax);
					auto clear = new Button(grp, SWT.PUSH);
					clear.setEnabled = _prop.var.etc.openHistories.length > 0;
					clear.setText = _prop.msgs.openHistoryClear;
					clear.addSelectionListener(new ClearHist);
				}
				{
					auto lComp = new Composite(grp, SWT.NONE);
					auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
					cl.fillHorizontal = true;
					lComp.setLayout = cl;
					lComp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
					auto l = new Label(lComp, SWT.NONE);
					l.setText = _prop.msgs.searchHistoryMax;
					_sHistMax = new Spinner(grp, SWT.BORDER);
					_sHistMax.setMinimum = 0;
					_sHistMax.setMaximum = 99;
					mod(_sHistMax);
					auto clear = new Button(grp, SWT.PUSH);
					clear.setEnabled = _prop.var.etc.searchHistories.length > 0;
					clear.setText = _prop.msgs.searchHistoryClear;
					clear.addSelectionListener(new ClearSHist);
				}
			}
		}
	}
	Spinner createS(Composite parent, string name, int max, int min) {
		auto l = new Label(parent, SWT.NONE);
		l.setText = name;
		auto spn = new Spinner(parent, SWT.BORDER);
		spn.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		spn.setMaximum = max;
		spn.setMinimum = min;
		spn.setSelection = 0;
		return spn;
	}
	class DefBgSetting : SelectionAdapter {
		private DefBgImgDialog _dlg = null;
		override void widgetSelected(SelectionEvent e) {
			if (_dlg) {
				_dlg.active();
				return;
			}
			_dlg = new DefBgImgDialog(_comm, _prop, getShell, _bgImagesDefault);
			_dlg.appliedEvent ~= {
				_bgImagesDefault = _dlg.backs;
				applyEnabled;
			};
			_dlg.closeEvent ~= {
				_dlg = null;
			};
			_dlg.open();
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
	void addBgImage(BgImageSetting bgStg) {
		storeBgStgs();
		int index = _bgStgsL.getItemCount;
		_bgStgs ~= bgStg;
		_bgStgsL.add(bgStg.name);
		_bgStgsL.select = index;
		selectBgImageSetting();
		applyEnabled();
	}
	class NewBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			string name = _bgImgName.getText;
			bool mask = _bgImgMask.getSelection;
			int x = _bgImgX.getSelection;
			int y = _bgImgY.getSelection;
			int w = _bgImgW.getSelection;
			int h = _bgImgH.getSelection;
			addBgImage(BgImageSetting(name, x, y, w, h, mask));
		}
	}
	void altBgImage() {
		int i = _bgStgsL.getSelectionIndex;
		if (-1 == i) return;
		storeBgStgs();
		_bgStgs[i].name = _bgImgName.getText;
		_bgStgsL.setItem(i, _bgStgs[i].name);
		_bgStgs[i].mask = _bgImgMask.getSelection;
		_bgStgs[i].x = _bgImgX.getSelection;
		_bgStgs[i].y = _bgImgY.getSelection;
		_bgStgs[i].width = _bgImgW.getSelection;
		_bgStgs[i].height = _bgImgH.getSelection;
		_bgImgAlt.setEnabled = false;
		applyEnabled();
	}
	void delBgImage() {
		int i = _bgStgsL.getSelectionIndex;
		if (i < 0) return;
		storeBgStgs();
		_bgStgsL.remove(i);
		_bgStgs = _bgStgs[0 .. i] ~ _bgStgs[i + 1 .. $];
		if (_bgStgs.length > 0) {
			_bgStgsL.select = i < _bgStgs.length ? i : _bgStgs.length - 1;
		}
		selectBgImageSetting();
		applyEnabled();
	}
	class AltBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			altBgImage();
		}
	}
	class DelBgImgStg : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			delBgImage();
		}
	}
	class DBgImgKeyCodeSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights;
			_prop.var.etc.bgImageKeyCodeSashL = ws[0];
			_prop.var.etc.bgImageKeyCodeSashR = ws[1];
		}
	}
	class BgImagesTCPD : TCPD {
		void cut(SelectionEvent se) {
			int i = _bgStgsL.getSelectionIndex;
			if (i < 0) return;
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) {
			int i = _bgStgsL.getSelectionIndex;
			if (i < 0) return;
			XMLtoCB(_prop, _comm.clipboard, _bgStgs[i].toNode.text);
		}
		void paste(SelectionEvent se) {
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == BgImageSetting.XML_NAME) {
						BgImageSetting stg;
						stg.fromNode(node);
						addBgImage(stg);
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {
			delBgImage;
		}
		bool canDoTCPD() {
			return _bgStgsL.isFocusControl;
		}
	}
	void modB(C)(Button button, List list, C ctrl) {
		static if (is(C : Button)) {
			ctrl.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) {
					if (0 < list.getItemCount) {
						button.setEnabled = true;
					}
				}
			});
		} else {
			ctrl.addModifyListener(new class ModifyListener {
				override void modifyText(ModifyEvent e) {
					if (0 < list.getItemCount) {
						button.setEnabled = true;
					}
				}
			});
		}
	}
	void construct2(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		_tabS = new CTabItem(tabf, SWT.NONE);
		_tabS.setText = _prop.msgs.bgImageAndKeyCode;
		_tabS.setControl = comp;
		comp.setLayout = new GridLayout(1, true);
		auto sash = new SplitPane(comp, SWT.HORIZONTAL);
		sash.setLayoutData = new GridData(GridData.FILL_BOTH);
		auto back = new Composite(sash, SWT.NONE);
		back.setLayout = zeroMarginGridLayout(1, true);
		{
			auto grp = new Group(back, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout = cl;
			grp.setText = _prop.msgs.bgImagesDefault;
			auto defBtn = new Button(grp, SWT.PUSH);
			defBtn.setText = _prop.msgs.setBgImagesDefault;
			defBtn.addSelectionListener(new DefBgSetting);
		}
		{
			auto grp = new Group(back, SWT.NONE);
			_bgStgsView = grp;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, true);
			grp.setText = _prop.msgs.bgImageSettings;
			auto leftSash = new SplitPane(grp, SWT.HORIZONTAL);
			leftSash.setLayoutData = new GridData(GridData.FILL_BOTH);
			{
				auto left = new Composite(leftSash, SWT.NONE);
				left.setLayout = zeroMarginGridLayout(2, true);
				_bgStgsL = new List(left, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.bgImageSettingsNameWidth;
				gd.heightHint = _prop.var.etc.bgImageSettingsNameHeight;
				gd.horizontalSpan = 2;
				_bgStgsL.setLayoutData = gd;
				_bgStgsL.addSelectionListener(new SelBgImgStg);

				auto menu = new Menu(_bgStgsL);
				createMenuItem(menu, _prop.msgs.menuUndo, _prop.images.menuUndo, &undoBgStgs);
				createMenuItem(menu, _prop.msgs.menuRedo, _prop.images.menuRedo, &redoBgStgs);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(menu, _prop.msgs.menuUp, _prop.images.menuUp, &upBgImage);
				createMenuItem(menu, _prop.msgs.menuDown, _prop.images.menuDown, &downBgImage);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_prop, menu, new BgImagesTCPD, true, true, true, true);
				_bgStgsL.setMenu = menu;

				auto up = new Button(left, SWT.PUSH);
				up.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				up.setText = _prop.msgs.ttUp;
				up.setImage = _prop.images.menuUp;
				up.addSelectionListener(new UpBgImgStg);
				auto down = new Button(left, SWT.PUSH);
				down.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				down.setText = _prop.msgs.ttDown;
				down.setImage = _prop.images.menuDown;
				down.addSelectionListener(new DownBgImgStg);
			}
			leftSash.setWeights = [_prop.var.etc.bgImageSettingsSashL, _prop.var.etc.bgImageSettingsSashR];
			leftSash.addDisposeListener(new DBgImgStg);
			auto right = new Composite(leftSash, SWT.NONE);
			right.setLayout = zeroMarginGridLayout(1, true);
			{
				auto comp2 = new Composite(right, SWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				comp2.setLayout = zeroMarginGridLayout(4, false);
				{
					auto comp3 = new Composite(comp2, SWT.NONE);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 4;
					comp3.setLayoutData = gd;
					comp3.setLayout = zeroMarginGridLayout(2, false);
					_bgImgName = new Text(comp3, SWT.BORDER);
					_bgImgTMs ~= createTextMenu!Text(_prop, _bgImgName, &catchMod);
					auto ngd = new GridData(GridData.FILL_HORIZONTAL);
					ngd.widthHint = _prop.var.etc.bgImageSettingsNameWidth;
					_bgImgName.setLayoutData = ngd;
					_bgImgMask = new Button(comp3, SWT.TOGGLE);
					_bgImgMask.setImage = _prop.images.menuMask;
					_bgImgMask.setToolTipText = _prop.msgs.ttMask;
				}
				_bgImgX = createS(comp2, _prop.msgs.left, _prop.looks.posLeftMax, _prop.looks.posLeftMin);
				_bgImgY = createS(comp2, _prop.msgs.top, _prop.looks.posTopMax, _prop.looks.posTopMin);
				_bgImgW = createS(comp2, _prop.msgs.width, _prop.looks.backWidthMax, _prop.looks.backWidthMin);
				_bgImgH = createS(comp2, _prop.msgs.height, _prop.looks.backHeightMax, _prop.looks.backHeightMin);
			}
			{
				auto buttons = new Composite(right, SWT.NONE);
				buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
				buttons.setLayout = zeroMarginGridLayout(3, true);
				auto newBstg = new Button(buttons, SWT.PUSH);
				newBstg.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				newBstg.setText = _prop.msgs.newBgImageSetting;
				newBstg.addSelectionListener(new NewBgImgStg);
				_bgImgAlt = new Button(buttons, SWT.PUSH);
				_bgImgAlt.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_bgImgAlt.setText = _prop.msgs.altBgImageSetting;
				_bgImgAlt.addSelectionListener(new AltBgImgStg);
				_bgImgDel = new Button(buttons, SWT.PUSH);
				_bgImgDel.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_bgImgDel.setText = _prop.msgs.delBgImageSetting;
				_bgImgDel.addSelectionListener(new DelBgImgStg);
			}
			modB(_bgImgAlt, _bgStgsL, _bgImgName);
			modB(_bgImgAlt, _bgStgsL, _bgImgMask);
			modB(_bgImgAlt, _bgStgsL, _bgImgX);
			modB(_bgImgAlt, _bgStgsL, _bgImgY);
			modB(_bgImgAlt, _bgStgsL, _bgImgW);
			modB(_bgImgAlt, _bgStgsL, _bgImgH);
		}
		{
			auto grp = new Group(sash, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, false);
			grp.setText = _prop.msgs.standardKeyCode;
			_keyCodes = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL);
			createTextMenu!Text(_prop, _keyCodes, &catchMod);
			mod(_keyCodes);
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
	class PushToolCmdRef : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			selectProgram(i);
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
	void addTool(OuterTool tool) {
		storeTools();
		int index = _toolsL.getItemCount;
		_tools ~= tool;
		_toolsL.add(tool.name);
		_toolsL.select = index;
		selectOuterTool();
		applyEnabled();
	}
	class NewOutTool : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			string name = _toolName.getText;
			string commnad = _toolCommand.getText;
			string workDir = _toolWorkDir.getText;
			addTool(OuterTool(name, commnad, workDir));
		}
	}
	void altTool() {
		int i = _toolsL.getSelectionIndex;
		if (-1 == i) return;
		storeTools();
		_tools[i].name = _toolName.getText;
		_toolsL.setItem(i, _tools[i].name);
		_tools[i].command = _toolCommand.getText;
		_tools[i].workDir = _toolWorkDir.getText;
		_toolAlt.setEnabled = false;
		applyEnabled();
	}
	void delTool() {
		int i = _toolsL.getSelectionIndex;
		if (i < 0) return;
		storeTools();
		_toolsL.remove(i);
		_tools = _tools[0 .. i] ~ _tools[i + 1 .. $];
		if (_tools.length > 0) {
			_toolsL.select = i < _tools.length ? i : _tools.length - 1;
		}
		selectOuterTool();
		applyEnabled();
	}
	class AltOutTool : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			altTool();
		}
	}
	class DelOutTool : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			delTool();
		}
	}
	class DOutToolsSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights;
			_prop.var.etc.outerToolsSashL = ws[0];
			_prop.var.etc.outerToolsSashR = ws[1];
		}
	}
	class ToolsTCPD : TCPD {
		void cut(SelectionEvent se) {
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) {
			int i = _toolsL.getSelectionIndex;
			if (i < 0) return;
			XMLtoCB(_prop, _comm.clipboard, _tools[i].toNode.text);
		}
		void paste(SelectionEvent se) {
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == OuterTool.XML_NAME) {
						OuterTool tool;
						tool.fromNode(node);
						addTool(tool);
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {
			delTool;
		}
		bool canDoTCPD() {
			return _toolsL.isFocusControl;
		}
	}

	class PushCEngineRef : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _cEnginesL.getSelectionIndex;
			if (i < 0) return;
			selectCEnginePath(i);
			applyEnabled;
		}
	}
	class PushCEnginePathRef : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _cEnginesL.getSelectionIndex;
			if (i < 0) return;
			selectCEnginePath(i);
			applyEnabled;
		}
	}
	void addCEngine(ClassicEngine cEngine) {
		storeCEngines();
		int index = _cEnginesL.getItemCount;
		_cEngines ~= cEngine;
		_cEnginesL.add(cEngine.name);
		_cEnginesL.select = index;
		selectCEngine();
		applyEnabled();
	}
	class NewCEngine : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			string name = _cEngineName.getText;
			string path = _cEnginePath.getText;
			string dataDir = _cEngineDataDir.getText;
			string execute = _cEngineExecute.getText;
			addCEngine(ClassicEngine(name, path, dataDir, execute));
		}
	}
	void altCEngine() {
		int i = _cEnginesL.getSelectionIndex;
		if (-1 == i) return;
		storeCEngines();
		_cEngines[i].name = _cEngineName.getText;
		_cEnginesL.setItem(i, _cEngines[i].name);
		_cEngines[i].enginePath = _cEnginePath.getText;
		_cEngines[i].dataDirName = _cEngineDataDir.getText;
		_cEngines[i].execute = _cEngineExecute.getText;
		_cEngineAlt.setEnabled = false;
		applyEnabled();
	}
	void delCEngine() {
		int i = _cEnginesL.getSelectionIndex;
		if (i < 0) return;
		storeCEngines();
		_cEnginesL.remove(i);
		_cEngines = _cEngines[0 .. i] ~ _cEngines[i + 1 .. $];
		if (_cEngines.length > 0) {
			_cEnginesL.select = i < _cEngines.length ? i : _cEngines.length - 1;
		}
		selectCEngine();
		applyEnabled();
	}
	class AltCEngine : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			altCEngine();
		}
	}
	class DelCEngine : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			delCEngine();
		}
	}
	class SelCEngine : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectCEngine;}
	}
	class UpCEngines : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {upCEngine;}
	}
	class DownCEngines : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {downCEngine;}
	}
	class DCEnginesSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights;
			_prop.var.etc.classicEnginesSashL = ws[0];
			_prop.var.etc.classicEnginesSashR = ws[1];
		}
	}
	class CEnginesTCPD : TCPD {
		void cut(SelectionEvent se) {
			int i = _cEnginesL.getSelectionIndex;
			if (i < 0) return;
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) {
			int i = _cEnginesL.getSelectionIndex;
			if (i < 0) return;
			XMLtoCB(_prop, _comm.clipboard, _cEngines[i].toNode.text);
		}
		void paste(SelectionEvent se) {
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == ClassicEngine.XML_NAME) {
						ClassicEngine cEngine;
						cEngine.fromNode(node);
						addCEngine(cEngine);
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {
			delCEngine();
		}
		bool canDoTCPD() {
			return _cEnginesL.isFocusControl;
		}
	}
	class PushCEngineDataDirRef : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _cEnginesL.getSelectionIndex;
			if (i < 0) return;
			selectCEngineDataDir(i);
			applyEnabled;
		}
	}
	class PushCEngineExecuteRef : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int i = _cEnginesL.getSelectionIndex;
			if (i < 0) return;
			selectCEngineExecute(i);
			applyEnabled;
		}
	}

	void construct3(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		_tabC = new CTabItem(tabf, SWT.NONE);
		_tabC.setText = _prop.msgs.classicEngines;
		_tabC.setControl = comp;
		{
			auto grp = new Group(comp, SWT.NONE);
			_cEnginesView = grp;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, true);
			grp.setText = _prop.msgs.classicEnginesTitle;
			auto sash = new SplitPane(grp, SWT.HORIZONTAL);
			sash.setLayoutData = new GridData(GridData.FILL_BOTH);
			{
				auto left = new Composite(sash, SWT.NONE);
				left.setLayout = zeroMarginGridLayout(2, true);
				_cEnginesL = new List(left, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.classicEnginesNameWidth;
				gd.heightHint = _prop.var.etc.classicEnginesNameHeight;
				gd.horizontalSpan = 2;
				_cEnginesL.setLayoutData = gd;
				_cEnginesL.addSelectionListener(new SelCEngine);

				auto menu = new Menu(_cEnginesL);
				createMenuItem(menu, _prop.msgs.menuUndo, _prop.images.menuUndo, &undoCEngines);
				createMenuItem(menu, _prop.msgs.menuRedo, _prop.images.menuRedo, &undoCEngines);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(menu, _prop.msgs.menuUp, _prop.images.menuUp, &upCEngine);
				createMenuItem(menu, _prop.msgs.menuDown, _prop.images.menuDown, &downCEngine);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_prop, menu, new CEnginesTCPD, true, true, true, true);
				_cEnginesL.setMenu = menu;

				auto up = new Button(left, SWT.PUSH);
				up.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				up.setText = _prop.msgs.ttUp;
				up.setImage = _prop.images.menuUp;
				up.addSelectionListener(new UpCEngines);
				auto down = new Button(left, SWT.PUSH);
				down.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				down.setText = _prop.msgs.ttDown;
				down.setImage = _prop.images.menuDown;
				down.addSelectionListener(new DownCEngines);
			}
			auto right = new Composite(sash, SWT.NONE);
			right.setLayout = zeroMarginGridLayout(1, true);
			{
				auto comp2 = new Composite(right, SWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				comp2.setLayout = zeroMarginGridLayout(4, false);
				{
					auto l = new Label(comp2, SWT.NONE);
					l.setText = _prop.msgs.classicEngineName;
					_cEngineName = new Text(comp2, SWT.BORDER);
					_cEngineTMs ~= createTextMenu!Text(_prop, _cEngineName, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					gd.widthHint = _prop.var.etc.classicEnginesNameWidth;
					_cEngineName.setLayoutData = gd;
				}
				{
					auto l = new Label(comp2, SWT.NONE);
					l.setText = _prop.msgs.classicEnginePath;
					_cEnginePath = new Text(comp2, SWT.BORDER);
					_cEngineTMs ~= createTextMenu!Text(_prop, _cEnginePath, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.widthHint = 0;
					_cEnginePath.setLayoutData = gd;
					_cEnginePathRef = new Button(comp2, SWT.PUSH);
					_cEnginePathRef.setText = _prop.msgs.reference;
					_cEnginePathRef.addSelectionListener(new PushCEnginePathRef);
					_cEnginePathDirOpen = createOpenButton(comp2, _cEnginePath, false);
					setupDropFile(_cEnginePath, _cEnginePath, &dropCEnginePath, &dropCEnginePath);
				}
				{
					auto l = new Label(comp2, SWT.NONE);
					l.setText = _prop.msgs.classicEngineDataDirName;
					_cEngineDataDir = new Text(comp2, SWT.BORDER);
					_cEngineTMs ~= createTextMenu!Text(_prop, _cEngineDataDir, &catchMod);
					_cEngineDataDir.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

					_cEngineDataDirRef = new Button(comp2, SWT.PUSH);
					_cEngineDataDirRef.setText = _prop.msgs.reference;
					_cEngineDataDirRef.addSelectionListener(new PushCEngineDataDirRef);
					_cEngineDataDirOpen = createCEngineSubOpenButton(comp2, _cEngineDataDir, true);
					setupDropFile(_cEngineDataDir, _cEngineDataDir, &dropCEngineDataDir);
				}
				{
					auto l = new Label(comp2, SWT.NONE);
					l.setText = _prop.msgs.classicEngineExecute;
					_cEngineExecute = new Text(comp2, SWT.BORDER);
					_cEngineTMs ~= createTextMenu!Text(_prop, _cEngineExecute, &catchMod);
					_cEngineExecute.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

					_cEngineExecuteRef = new Button(comp2, SWT.PUSH);
					_cEngineExecuteRef.setText = _prop.msgs.reference;
					_cEngineExecuteRef.addSelectionListener(new PushCEngineExecuteRef);
					_cEngineExecuteDirOpen = createCEngineSubOpenButton(comp2, _cEngineExecute, true);
					setupDropFile(_cEngineExecute, _cEngineExecute, &dropCEngineExecute);
				}
				{
					auto hint1 = new Label(comp2, SWT.NONE);
					hint1.setText = _prop.msgs.classicEngineHint1;
					auto gd1 = new GridData;
					gd1.horizontalSpan = 4;
					hint1.setLayoutData = gd1;
				}
			}
			{
				auto buttons = new Composite(right, SWT.NONE);
				buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
				buttons.setLayout = zeroMarginGridLayout(3, true);
				auto newCEngine = new Button(buttons, SWT.PUSH);
				newCEngine.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				newCEngine.setText = _prop.msgs.newClassicEngine;
				newCEngine.addSelectionListener(new NewCEngine);
				_cEngineAlt = new Button(buttons, SWT.PUSH);
				_cEngineAlt.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_cEngineAlt.setText = _prop.msgs.altClassicEngine;
				_cEngineAlt.addSelectionListener(new AltCEngine);
				_cEngineDel = new Button(buttons, SWT.PUSH);
				_cEngineDel.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_cEngineDel.setText = _prop.msgs.delClassicEngine;
				_cEngineDel.addSelectionListener(new DelCEngine);
			}
			modB(_cEngineAlt, _cEnginesL, _cEngineName);
			modB(_cEngineAlt, _cEnginesL, _cEnginePath);
			modB(_cEngineAlt, _cEnginesL, _cEngineDataDir);
			modB(_cEngineAlt, _cEnginesL, _cEngineExecute);
			sash.setWeights = [_prop.var.etc.classicEnginesSashL, _prop.var.etc.classicEnginesSashR];
			sash.addDisposeListener(new DCEnginesSash);
		}
	}

	void construct4(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, false);
		_tabT = new CTabItem(tabf, SWT.NONE);
		_tabT.setText = _prop.msgs.outerTools;
		_tabT.setControl = comp;

		{
			auto grp = new Group(comp, SWT.NONE);
			_toolsView = grp;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, true);
			grp.setText = _prop.msgs.outerToolsTitle;
			auto sash = new SplitPane(grp, SWT.HORIZONTAL);
			sash.setLayoutData = new GridData(GridData.FILL_BOTH);
			{
				auto left = new Composite(sash, SWT.NONE);
				left.setLayout = zeroMarginGridLayout(2, true);
				_toolsL = new List(left, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.outerToolsNameWidth;
				gd.heightHint = _prop.var.etc.outerToolsNameHeight;
				gd.horizontalSpan = 2;
				_toolsL.setLayoutData = gd;
				_toolsL.addSelectionListener(new SelOutTools);

				auto menu = new Menu(_toolsL);
				createMenuItem(menu, _prop.msgs.menuUndo, _prop.images.menuUndo, &undoTools);
				createMenuItem(menu, _prop.msgs.menuRedo, _prop.images.menuRedo, &redoTools);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(menu, _prop.msgs.menuUp, _prop.images.menuUp, &upTool);
				createMenuItem(menu, _prop.msgs.menuDown, _prop.images.menuDown, &downTool);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_prop, menu, new ToolsTCPD, true, true, true, true);
				_toolsL.setMenu = menu;

				auto up = new Button(left, SWT.PUSH);
				up.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				up.setText = _prop.msgs.ttUp;
				up.setImage = _prop.images.menuUp;
				up.addSelectionListener(new UpOutTools);
				auto down = new Button(left, SWT.PUSH);
				down.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				down.setText = _prop.msgs.ttDown;
				down.setImage = _prop.images.menuDown;
				down.addSelectionListener(new DownOutTools);
			}
			auto right = new Composite(sash, SWT.NONE);
			right.setLayout = zeroMarginGridLayout(1, true);
			{
				auto comp2 = new Composite(right, SWT.NONE);
				comp2.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				comp2.setLayout = zeroMarginGridLayout(4, false);
				{
					auto l = new Label(comp2, SWT.NONE);
					l.setText = _prop.msgs.outerToolName;
					_toolName = new Text(comp2, SWT.BORDER);
					_toolTMs ~= createTextMenu!Text(_prop, _toolName, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					_toolName.setLayoutData = gd;
				}
				{
					auto l = new Label(comp2, SWT.NONE);
					l.setText = _prop.msgs.outerToolCommand;
					_toolCommand = new Text(comp2, SWT.BORDER);
					_toolTMs ~= createTextMenu!Text(_prop, _toolCommand, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.widthHint = 0;
					_toolCommand.setLayoutData = gd;
					_toolCommandRef = new Button(comp2, SWT.PUSH);
					_toolCommandRef.setText = _prop.msgs.reference;
					_toolCommandRef.addSelectionListener(new PushToolCmdRef);
					_toolCommandDirOpen = createOpenButton(comp2, _toolCommand, false);
					setupDropFile(_toolCommand, _toolCommand, &dropDefault);
				}
				{
					auto l = new Label(comp2, SWT.NONE);
					l.setText = _prop.msgs.outerToolWorkDir;
					_toolWorkDir = new Text(comp2, SWT.BORDER);
					_toolTMs ~= createTextMenu!Text(_prop, _toolWorkDir, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.widthHint = 0;
					_toolWorkDir.setLayoutData = gd;
					_toolWorkDirRef = new Button(comp2, SWT.PUSH);
					_toolWorkDirRef.setText = _prop.msgs.reference;
					_toolWorkDirRef.addSelectionListener(new PushToolWorkDirRef);
					_toolWorkDirOpen = createOpenButton(comp2, _toolWorkDir, true);
					setupDropFile(_toolWorkDir, _toolWorkDir, &dropDir);
				}
				{
					auto dummy = new Composite(comp2, SWT.NONE);
					auto gd = new GridData;
					gd.verticalSpan = 3;
					gd.widthHint = 0;
					gd.heightHint = 0;
					dummy.setLayoutData = gd;
					auto hint1 = new Label(comp2, SWT.NONE);
					hint1.setText = _prop.msgs.toolsHint1;
					auto gd1 = new GridData;
					gd1.horizontalSpan = 3;
					hint1.setLayoutData = gd1;
					auto hint2 = new Label(comp2, SWT.NONE);
					hint2.setText = _prop.msgs.toolsHint2;
					auto gd2 = new GridData;
					gd2.horizontalSpan = 3;
					hint2.setLayoutData = gd2;
					auto hint3 = new Label(comp2, SWT.NONE);
					hint3.setText = _prop.msgs.toolsHint3;
					auto gd3 = new GridData;
					gd3.horizontalSpan = 3;
					hint3.setLayoutData = gd3;
				}
			}
			{
				auto buttons = new Composite(right, SWT.NONE);
				buttons.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
				buttons.setLayout = zeroMarginGridLayout(3, true);
				auto newTool = new Button(buttons, SWT.PUSH);
				newTool.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				newTool.setText = _prop.msgs.newOuterTool;
				newTool.addSelectionListener(new NewOutTool);
				_toolAlt = new Button(buttons, SWT.PUSH);
				_toolAlt.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_toolAlt.setText = _prop.msgs.altOuterTool;
				_toolAlt.addSelectionListener(new AltOutTool);
				_toolDel = new Button(buttons, SWT.PUSH);
				_toolDel.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_toolDel.setText = _prop.msgs.delOuterTool;
				_toolDel.addSelectionListener(new DelOutTool);
			}
			modB(_toolAlt, _toolsL, _toolName);
			modB(_toolAlt, _toolsL, _toolCommand);
			modB(_toolAlt, _toolsL, _toolWorkDir);
			sash.setWeights = [_prop.var.etc.outerToolsSashL, _prop.var.etc.outerToolsSashR];
			sash.addDisposeListener(new DOutToolsSash);
		}
	}

	void construct5(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		_tabE = new CTabItem(tabf, SWT.NONE);
		_tabE.setText = _prop.msgs.etcSettings;
		_tabE.setControl = comp;
		comp.setLayout = new GridLayout(2, false);
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData = new GridData(GridData.VERTICAL_ALIGN_BEGINNING);
			comp2.setLayout = zeroMarginGridLayout(1, false);
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setText = _prop.msgs.etcSettingsTitle;
				grp.setLayout = new GridLayout(2, false);
				Button createB(string text) {
					auto btn = new Button(grp, SWT.CHECK);
					btn.setText = text;
					mod(btn);
					auto gd = new GridData;
					gd.horizontalSpan = 2;
					btn.setLayoutData = gd;
					return btn;
				}
				_singleWindow = createB(_prop.msgs.singleWindow);
				_smoothingCard = createB(_prop.msgs.smoothingCard);
				_showImagePreview = createB(_prop.msgs.showImagePreview);
				_expandXMLs = createB(_prop.msgs.expandXMLs);
				_contentsFloat = createB(_prop.msgs.contentsFloat);
				_xmlCopy = createB(_prop.msgs.xmlCopy);
				_saveInnerImagePath = createB(_prop.msgs.saveInnerImagePath);
				_traceDirectories = createB(_prop.msgs.traceDirectories);
				_logicalSort = createB(_prop.msgs.logicalSort);
				_copyDesc = createB(_prop.msgs.copyDesc);
				_refCardsAtEditBgImage = createB(_prop.msgs.refCardsAtEditBgImage);
				_addNewClassicEngine = createB(_prop.msgs.addNewClassicEngine);
				_doubleIO = createB(_prop.msgs.doubleIO);
				_switchTabWheel = createB(_prop.msgs.switchTabWheel);
				_openTabAtRightOfCurrentTab = createB(_prop.msgs.openTabAtRightOfCurrentTab);
			}
			{
				version (Windows) {
					auto grp = new Group(comp2, SWT.NONE);
					grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					grp.setText = _prop.msgs.soundPlayType;
					grp.setLayout = new GridLayout(1, false);
					_soundPlayType = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
					mod(_soundPlayType);
					_soundPlayType.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
					_soundPlayType.setVisibleItemCount = 20;
					_soundPlayType.add(_prop.msgs.soundPlayTypeDef);
					_soundPlayType.add(_prop.msgs.soundPlayTypeSDL);
					_soundPlayType.add(_prop.msgs.soundPlayTypeMCI);
					_soundPlayType.add(_prop.msgs.soundPlayTypeApp);
				}
			}
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				grp.setText = _prop.msgs.systemSounds;
				grp.setLayout = new GridLayout(4, false);
				auto l = new Label(grp, SWT.NONE);
				l.setText = _prop.msgs.soundSaved;
				_savedSound = new Text(grp, SWT.BORDER);
				createTextMenu!Text(_prop, _savedSound, &catchMod);
				_savedSound.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				mod(_savedSound);
				auto refr = new Button(grp, SWT.PUSH);
				refr.setText = _prop.msgs.reference;
				refr.addSelectionListener(new SelSysSound(_savedSound));
				createOpenButton(grp, _savedSound, false);
				setupDropFile(grp, _savedSound, &dropSysSound);	
			}
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.verticalSpan = 2;
			version (Windows) {
				gd.verticalSpan++;
			}
			grp.setLayoutData = gd;
			grp.setText = _prop.msgs.ignorePaths;
			grp.setLayout = new GridLayout(1, false);
			_ignorePaths = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL);
			createTextMenu!Text(_prop, _ignorePaths, &catchMod);
			mod(_ignorePaths);
			auto gdp = new GridData(GridData.FILL_BOTH);
			gdp.widthHint = _prop.var.etc.ignorePathsWidth;
			gdp.heightHint = 0;
			_ignorePaths.setLayoutData = gdp;
		}
	}
	private RefE _refe;
	private void refreshScenario(Summary summ) {
		if (!summ) {
			forceCancel();
		} else {
			_summ = summ;
		}
	}
	private void refreshEnabled() {
		_backupDir.setEnabled = _backupEnabled.getSelection;
		_backupInterval.setEnabled = _backupEnabled.getSelection;
		_backupCount.setEnabled = _backupEnabled.getSelection;
		_backupRef.setEnabled = _backupEnabled.getSelection;
		_backupDirOpen.setEnabled = _backupEnabled.getSelection;
	}
	class KeyDownFilter : Listener {
		private int _undoAcc;
		private int _redoAcc;
		this () {
			_undoAcc = convertAccelerator(_prop.msgs.menuUndo);
			_redoAcc = convertAccelerator(_prop.msgs.menuRedo);
		}
		override void handleEvent(Event e) {
			auto c = cast(Control) e.widget;
			if (!c || c.getShell !is getShell) return;
			bool chk(Composite view, UndoManager undo) {
				if (isDescendant(view, c)) {
					if (c.getMenu && findMenu(c.getMenu, e.keyCode, e.character, e.stateMask)) return false;
					if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) {
						undo.undo();
						e.doit = false;
						return true;
					} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) {
						undo.redo();
						e.doit = false;
						return true;
					}
				}
				return false;
			}
			if (chk(_bgStgsView, _undoBgStgs)) return;
			if (chk(_toolsView, _undoTools)) return;
			if (chk(_cEnginesView, _undoCEngines)) return;
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, DockingFolderCTC dock, Summary summ) {
		super(prop, shell, false, prop.msgs.dlgTitSettings, prop.images.menuSettings, true, prop.var.settingsDlg, true);
		_comm = comm;
		_prop = prop;
		_dock = dock;
		_summ = summ;
		_undoBgStgs = new UndoManager(1024);
		_undoTools = new UndoManager(1024);
		_undoCEngines = new UndoManager(1024);
	}

protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		_comm.refScenario.add(&refreshScenario);
		area.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refScenario.remove(&refreshScenario);
				e.widget.getDisplay.removeFilter(SWT.KeyDown, _kdFilter);
			}
		});
		_kdFilter = new KeyDownFilter();
		area.getDisplay.addFilter(SWT.KeyDown, _kdFilter);
		auto tabf = new CTabFolder(area, SWT.BORDER);
		tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		_refe = new RefE;
		construct1(tabf);
		construct2(tabf);
		construct3(tabf);
		construct4(tabf);
		construct5(tabf);

		_enginePath.setText = _prop.var.etc.enginePath;
		_tempDir.setText = _prop.var.etc.tempPath;
		_backupDir.setText = _prop.var.etc.backupPath;
		_backupEnabled.setSelection = _prop.var.etc.backupEnabled;
		_backupInterval.setSelection = _prop.var.etc.backupInterval;
		_backupCount.setSelection = _prop.var.etc.backupCount;
		_author.setText = _prop.var.etc.defaultAuthor;
		_wallpaper.setText = _prop.var.etc.wallpaper;
		_histMax.setSelection = _prop.var.etc.historyMax;
		_sHistMax.setSelection = _prop.var.etc.searchHistoryMax;
		string ipbuf = "";
		foreach (path; _prop.var.etc.ignorePaths) {
			ipbuf ~= path ~ "\n";
		}
		_ignorePaths.setText = ipbuf;
		_expandXMLs.setSelection = _prop.var.etc.expandXMLs;
		_smoothingCard.setSelection = _prop.var.etc.smoothingCard;
		_showImagePreview.setSelection = _prop.var.etc.showImagePreview;
		_singleWindow.setSelection = _prop.var.etc.singleWindow;
		_contentsFloat.setSelection = _prop.var.etc.contentsFloat;
		_xmlCopy.setSelection = _prop.var.etc.xmlCopy;
		_saveInnerImagePath.setSelection = _prop.var.etc.saveInnerImagePath;
		_traceDirectories.setSelection = _prop.var.etc.traceDirectories;
		_logicalSort.setSelection = _prop.var.etc.logicalSort;
		_copyDesc.setSelection = _prop.var.etc.copyDesc;
		_refCardsAtEditBgImage.setSelection = _prop.var.etc.refCardsAtEditBgImage;
		_addNewClassicEngine.setSelection = _prop.var.etc.addNewClassicEngine;
		_doubleIO.setSelection = _prop.var.etc.doubleIO;
		_switchTabWheel.setSelection = _prop.var.etc.switchTabWheel;
		_openTabAtRightOfCurrentTab.setSelection = _prop.var.etc.openTabAtRightOfCurrentTab;
		version (Windows) {
			_soundPlayType.select = _prop.var.etc.soundPlayType;
		}
		_savedSound.setText = _prop.var.etc.savedSound;

		_bgStgs.length = _prop.var.etc.bgImageSettings.length;
		foreach (i, stg; _prop.var.etc.bgImageSettings) {
			_bgStgsL.add(stg.name);
			_bgStgs[i] = stg.dup;
		}
		if (_bgStgs.length > 0) _bgStgsL.select = 0;
		_bgImagesDefault = _prop.var.etc.bgImagesDefault.dup;
		selectBgImageSetting();

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
		selectOuterTool();

		_cEngines.length = _prop.var.etc.classicEngines.length;
		foreach (i, cEngine; _prop.var.etc.classicEngines) {
			_cEnginesL.add(cEngine.name);
			_cEngines[i] = cEngine;
		}
		if (_cEngines.length > 0) _cEnginesL.select = 0;
		selectCEngine();

		refreshEnabled();
	}

	override bool apply() {
		void err(CTabItem tab, Text t, string msg) {
			auto dlg = new MessageBox(t.getShell, SWT.ICON_WARNING | SWT.OK);
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
			if (!.exists(engine) || .isDir(engine)) {
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
		string backup;
		try {
			backup = _backupDir.getText;
		} catch {
			err(_tabB, _backupDir, _prop.msgs.errorBackupPath);
			return false;
		}
		string oldEnginePath = _prop.var.etc.enginePath;
		string oldWallpaper = _prop.var.etc.wallpaper;
		auto oldKeyCodes = _prop.var.etc.standardKeyCodes;
		auto tools = _prop.var.etc.outerTools;
		auto cEngines = _prop.var.etc.classicEngines;
		auto oldIgnorePaths = _prop.var.etc.ignorePaths;
		bool oldSmoothingCard = _prop.var.etc.smoothingCard;
		bool oldLogicalSort = _prop.var.etc.logicalSort;
		scope (exit) {
			bool refSkin = false;
			if (_summ && oldEnginePath != _prop.var.etc.enginePath) {
				refSkin = true;
			}
			if (oldWallpaper != _prop.var.etc.wallpaper) {
				_comm.refreshWallpaper(_prop);
				_comm.refWallpaper.call;
			}
			if (oldKeyCodes != _prop.var.etc.standardKeyCodes) {
				_comm.refStandardKeyCodes.call;
			}
			if (tools != _prop.var.etc.outerTools) {
				_comm.refOuterTools.call;
			}
			if (cEngines != _prop.var.etc.classicEngines) {
				refSkin = true;
			}
			if (oldIgnorePaths != _prop.var.etc.ignorePaths) {
				_comm.refIgnorePaths.call;
			}
			if (oldSmoothingCard != _prop.var.etc.smoothingCard) {
				_comm.refCardState.call;
			}
			if (oldLogicalSort != _prop.var.etc.logicalSort) {
				if (_summ) {
					if (_prop.var.etc.logicalSort) {
						_summ.flagDirRoot.sorter = (string a, string b) {
							return ncmp(a, b);
						};
					} else {
						_summ.flagDirRoot.sorter = (string a, string b) {
							return cmp(a, b);
						};
					}
				}
				_comm.refSortCondition.call;
			}
			if (refSkin) {
				_comm.skin = findSkin(_comm, _prop, _summ, false);
				_comm.refSkin.call;
			}
			_comm.refClassicSkin.call();
		}
		_prop.var.etc.enginePath = engine;
		_prop.var.etc.tempPath = temp;
		_prop.var.etc.backupPath = backup;
		_prop.var.etc.backupEnabled = _backupEnabled.getSelection;
		_prop.var.etc.backupInterval = _backupInterval.getSelection;
		_prop.var.etc.backupCount = _backupCount.getSelection;
		_prop.var.etc.defaultAuthor = _author.getText;
		_prop.var.etc.wallpaper = _wallpaper.getText;
		_prop.var.etc.historyMax = _histMax.getSelection;
		_prop.var.etc.searchHistoryMax = _sHistMax.getSelection;
		string[] ipLines = splitLines(_ignorePaths.getText);
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
		_prop.var.etc.showImagePreview = _showImagePreview.getSelection;
		_prop.var.etc.expandXMLs = _expandXMLs.getSelection;
		_prop.var.etc.xmlCopy = _xmlCopy.getSelection;
		_prop.var.etc.saveInnerImagePath = _saveInnerImagePath.getSelection;
		_prop.var.etc.traceDirectories = _traceDirectories.getSelection;
		_prop.var.etc.logicalSort = _logicalSort.getSelection;
		_prop.var.etc.copyDesc = _copyDesc.getSelection;
		_prop.var.etc.refCardsAtEditBgImage = _refCardsAtEditBgImage.getSelection;
		_prop.var.etc.addNewClassicEngine = _addNewClassicEngine.getSelection;
		_prop.var.etc.doubleIO = _doubleIO.getSelection;
		_prop.var.etc.switchTabWheel = _switchTabWheel.getSelection;
		_prop.var.etc.openTabAtRightOfCurrentTab = _openTabAtRightOfCurrentTab.getSelection;
		_prop.var.etc.contentsFloat = _contentsFloat.getSelection;
		version (Windows) {
			_prop.var.etc.soundPlayType = _soundPlayType.getSelectionIndex;
		}
		_prop.var.etc.savedSound = _savedSound.getText;
		if (_prop.var.etc.historyMax < _prop.var.etc.openHistories.length) {
			_prop.var.etc.openHistories
				= _prop.var.etc.openHistories[0 .. _prop.var.etc.historyMax].dup;
		}
		if (_prop.var.etc.searchHistoryMax < _prop.var.etc.searchHistories.length) {
			_prop.var.etc.searchHistories
				= _prop.var.etc.searchHistories[0 .. _prop.var.etc.searchHistoryMax].dup;
		}
		_prop.var.etc.bgImageSettings = _bgStgs.dup;
		_prop.var.etc.bgImagesDefault = _bgImagesDefault;
		string[] lines = splitLines(_keyCodes.getText);
		if (lines.length > 0) {
			int i;
			for (i = lines.length - 1; i >= 0 && lines[i].length == 0; i--) {
				;
			}
			_prop.var.etc.standardKeyCodes = lines[0 .. i + 1];
		} else {
			_prop.var.etc.standardKeyCodes = [];
		}
		_prop.var.etc.outerTools = _tools.dup;
		_prop.var.etc.classicEngines = _cEngines.dup;
		_prop.var.save(_dock);
		return true;
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
		super(prop, shell, false, prop.msgs.dlgTitBgImagesDefault,
			prop.images.menuSettings, true, prop.var.bgImagesDlg, true);
		_comm = comm;
		_prop = prop;

		BgImage[] bgImages;
		auto skin = _comm.skin;
		_cont = new BgImageContainer(BgImageS.createBgImages(skin, bgImagesDefault));
	}

	BgImageS[] backs() {return BgImageS.createBgImageSs(_cont.backs);}
protected:
	override void setup(Composite area) {
		area.setLayout = new GridLayout(1, false);
		{
			_view = createBgImagesViewAndMenu(_comm, _prop, null, _cont, area, null);
			mod(_view);
			_view.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
	}

	override bool apply() {
		return true;
	}
}
