
module cwx.editor.gui.dwt.settingsdialog;

import cwx.background;
import cwx.utils;
import cwx.xml;
import cwx.summary;
import cwx.skin;
import cwx.msgs;
import cwx.graphics;
import cwx.structs;
import cwx.menu;
import cwx.variables;
import cwx.cab;
import cwx.script;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.loader;
import cwx.editor.gui.dwt.scripterrordialog;

import std.path;
import std.file;
import std.string;
import std.functional;
import std.traits;
import std.array;

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
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.events.FocusAdapter;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;

class SettingsDialog : AbsDialog {
private:
	private class ToolsPane(T) : Composite {
	private:
		class UndoU : Undo {
			private T[] _old;
			private int _selected;
			this () {
				save();
			}
			private void save() {
				_old = _array.dup;
				_selected = _list.getSelectionIndex();
			}
			private void impl() {
				auto old = _old;
				auto sels = _selected;
				save();
				_list.setRedraw(false);
				scope (exit) _list.setRedraw(true);
				_array = old;
				_list.removeAll();
				foreach (o; old) {
					_list.add(o.name);
				}
				_list.select(sels);
				_list.showSelection();
				selected();
				applyEnabled();
			}
			override void undo() {impl();}
			override void redo() {impl();}
			override void dispose() {
				// Nothing
			}
		}
		void store() {
			_undo ~= new UndoU;
		}

		KeyDownFilter _kdFilter;

		UndoManager _undo;

		List _list;
		T[] _array;
		Text _name;
		static if (is(T:BgImageSetting)) {
			Spinner _bgImgX;
			Spinner _bgImgY;
			Spinner _bgImgW;
			Spinner _bgImgH;
			Button _bgImgMask;
		} else static if (is(T:OuterTool)) {
			Text _toolCommand;
			Button _toolCommandRef;
			Button _toolCommandDirOpen;
			Text _toolWorkDir;
			Button _toolWorkDirRef;
			Button _toolWorkDirOpen;
		} else static if (is(T:ClassicEngine)) {
			Text _cEnginePath;
			Button _cEnginePathRef;
			Button _cEnginePathDirOpen;
			Text _cEngineDataDir;
			Button _cEngineDataDirRef;
			Button _cEngineDataDirOpen;
			Text _cEngineExecute;
			Button _cEngineExecuteRef;
			Button _cEngineExecuteDirOpen;
		} else static if (is(T:ScTemplate)) {
			Text _templPath;
			Button _templPathRef;
			Button _templPathDirOpen;
		} else static if (is(T:EvTemplate)) {
			Text _templScript;
		} else static assert (0);

		Button _alt;
		Button _del;
		TextMenuModify[] _tms;

		void upImpl(List list, ref T[] array) {
			int i = list.getSelectionIndex();
			if (i <= 0) return;
			string tempS = list.getItem(i - 1);
			list.setItem(i - 1, list.getItem(i));
			list.setItem(i, tempS);
			auto temp = array[i - 1];
			array[i - 1] = array[i];
			array[i] = temp;
			list.select(i - 1);
			applyEnabled();
			_comm.refreshToolBar();
		}
		void downImpl(T)(List list, ref T[] array) {
			int i = list.getSelectionIndex();
			if (i < 0 || array.length <= i + 1) return;
			string tempS = list.getItem(i + 1);
			list.setItem(i + 1, list.getItem(i));
			list.setItem(i, tempS);
			auto temp = array[i + 1];
			array[i + 1] = array[i];
			array[i] = temp;
			list.select(i + 1);
			applyEnabled();
			_comm.refreshToolBar();
		}
		void up() {
			store();
			upImpl(_list, _array);
		}
		void down() {
			store();
			downImpl(_list, _array);
		}

		void selected() {
			ignoreMod = true;
			scope (exit) ignoreMod = false;
			int i = _list.getSelectionIndex();
			_del.setEnabled(i >= 0);
			if (i >= 0) {
				_name.setText(_array[i].name);
				static if (is(T:BgImageSetting)) {
					_bgImgX.setSelection(_array[i].x);
					_bgImgY.setSelection(_array[i].y);
					_bgImgW.setSelection(_array[i].width);
					_bgImgH.setSelection(_array[i].height);
					_bgImgMask.setSelection(_array[i].mask);
				} else static if (is(T:OuterTool)) {
					_toolCommand.setText(_array[i].command);
					_toolWorkDir.setText(_array[i].workDir);
				} else static if (is(T:ClassicEngine)) {
					_cEnginePath.setText(_array[i].enginePath);
					_cEngineDataDir.setText(_array[i].dataDirName);
					_cEngineExecute.setText(_array[i].execute);
				} else static if (is(T:ScTemplate)) {
					_templPath.setText(_array[i].path);
				} else static if (is(T:EvTemplate)) {
					_templScript.setText(_array[i].script);
				} else static assert (0);
			} else {
				_name.setText("");
				static if (is(T:BgImageSetting)) {
					_bgImgX.setSelection(0);
					_bgImgY.setSelection(0);
					_bgImgW.setSelection(0);
					_bgImgH.setSelection(0);
					_bgImgMask.setSelection(false);
				} else static if (is(T:OuterTool)) {
					_toolCommand.setText("");
					_toolWorkDir.setText("");
				} else static if (is(T:ClassicEngine)) {
					_cEnginePath.setText("");
					_cEngineDataDir.setText("");
					_cEngineExecute.setText("");
				} else static if (is(T:ScTemplate)) {
					_templPath.setText("");
				} else static if (is(T:EvTemplate)) {
					_templScript.setText("");
				} else static assert (0);
			}
			_alt.setEnabled(false);
			foreach (tm; _tms) {
				tm.reset();
			}
			_comm.refreshToolBar();
		}

		void add(T t) {
			store();
			int index = _list.getItemCount();
			_array ~= t;
			_list.add(t.name);
			_list.select(index);
			selected();
			applyEnabled();
			_comm.refreshToolBar();
		}
		void create() {
			if (!checkData()) return;
			string name = _name.getText();
			static if (is(T:BgImageSetting)) {
				bool mask = _bgImgMask.getSelection();
				int x = _bgImgX.getSelection();
				int y = _bgImgY.getSelection();
				int w = _bgImgW.getSelection();
				int h = _bgImgH.getSelection();
				add(BgImageSetting(name, x, y, w, h, mask));
			} else static if (is(T:OuterTool)) {
				string commnad = _toolCommand.getText();
				string workDir = _toolWorkDir.getText();
				add(OuterTool(name, commnad, workDir));
			} else static if (is(T:ClassicEngine)) {
				string path = _cEnginePath.getText();
				string dataDir = _cEngineDataDir.getText();
				string execute = _cEngineExecute.getText();
				add(ClassicEngine(name, path, dataDir, execute));
			} else static if (is(T:ScTemplate)) {
				string path = _templPath.getText();
				add(ScTemplate(name, path));
			} else static if (is(T:EvTemplate)) {
				string script = _templScript.getText();
				add(EvTemplate(name, script));
			} else static assert (0);
		}
		void alt() {
			int i = _list.getSelectionIndex();
			if (-1 == i) return;
			if (!checkData()) return;
			store();
			_array[i].name = _name.getText();
			_list.setItem(i, _array[i].name);
			static if (is(T:BgImageSetting)) {
				_array[i].mask = _bgImgMask.getSelection();
				_array[i].x = _bgImgX.getSelection();
				_array[i].y = _bgImgY.getSelection();
				_array[i].width = _bgImgW.getSelection();
				_array[i].height = _bgImgH.getSelection();
			} else static if (is(T:OuterTool)) {
				_array[i].command = _toolCommand.getText();
				_array[i].workDir = _toolWorkDir.getText();
			} else static if (is(T:ClassicEngine)) {
				_array[i].enginePath = _cEnginePath.getText();
				_array[i].dataDirName = _cEngineDataDir.getText();
				_array[i].execute = _cEngineExecute.getText();
			} else static if (is(T:ScTemplate)) {
				_array[i].path = _templPath.getText();
			} else static if (is(T:EvTemplate)) {
				_array[i].script = _templScript.getText();
			} else static assert (0);
			_alt.setEnabled(false);
			applyEnabled();
			_comm.refreshToolBar();
		}
		void del() {
			int i = _list.getSelectionIndex();
			if (i < 0) return;
			store();
			_list.remove(i);
			_array = _array[0 .. i] ~ _array[i + 1 .. $];
			if (_array.length > 0) {
				_list.select(i < _array.length ? i : _array.length - 1);
			}
			selected();
			applyEnabled();
			_comm.refreshToolBar();
		}

		class UTCPD : TCPD {
			void cut(SelectionEvent se) {
				int i = _list.getSelectionIndex();
				if (i < 0) return;
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) {
				int i = _list.getSelectionIndex();
				if (i < 0) return;
				XMLtoCB(_prop, _comm.clipboard, _array[i].toNode().text);
			}
			void paste(SelectionEvent se) {
				auto xml = CBtoXML(_comm.clipboard);
				if (xml) {
					try {
						auto node = XNode.parse(xml);
						if (node.name == T.XML_NAME) {
							T t;
							t.fromNode(node);
							add(t);
						}
					} catch (Exception e) {
						debugln(e);
					}
				}
			}
			void del(SelectionEvent se) {
				this.outer.del();
			}
			@property
			bool canDoTCPD() {
				return _list.isFocusControl();
			}
			@property
			bool canDoT() {
				return _list.getSelectionIndex() > 0;
			}
			@property
			bool canDoC() {
				return canDoT;
			}
			@property
			bool canDoP() {
				return true;
			}
			@property
			bool canDoD() {
				return canDoT;
			}
		}
		static if (is(T:EvTemplate)) {
			bool checkData() {
				try {
					cwx.script.compile(_prop.parent, null, _templScript.getText());
					return true;
				} catch (CWXScriptException e) {
					auto dlg = new ScriptErrorDialog(_comm, _prop, this, e);
					dlg.open();
					return false;
				}
				return true;
			}
		} else {
			bool checkData() {return true;}
		}
		void refUndoMax() {
			_undo.max = _prop.var.etc.undoMaxEtc;
		}

		class KeyDownFilter : Listener {
			this () {
				refMenu(MenuID.Undo);
				refMenu(MenuID.Redo);
			}
			override void handleEvent(Event e) {
				auto c = cast(Control) e.widget;
				if (!c || c.getShell() !is getShell()) return;
				if (isDescendant(this.outer, c)) {
					if (c.getMenu() && findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
					if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) {
						_undo.undo();
						e.doit = false;
					} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) {
						_undo.redo();
						e.doit = false;
					}
				}
			}
		}
		private int _undoAcc;
		private int _redoAcc;
		void refMenu(MenuID id) {
			if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
			if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
		}

		static if (is(T:BgImageSetting)) {
			void setupRight(Composite parent) {
				auto comp3 = new Composite(parent, SWT.NONE);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 4;
				comp3.setLayoutData(gd);
				comp3.setLayout(zeroMarginGridLayout(2, false));
				_name = new Text(comp3, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _name, &catchMod);
				_name.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_bgImgMask = new Button(comp3, SWT.TOGGLE);
				_bgImgMask.setImage(_prop.images.menu(MenuID.Mask));
				_bgImgMask.setToolTipText(_prop.buildTool(MenuID.Mask));

				_bgImgX = createS(parent, _prop.msgs.left, _prop.looks.posLeftMax, _prop.looks.posLeftMin);
				_bgImgY = createS(parent, _prop.msgs.top, _prop.looks.posTopMax, _prop.looks.posTopMin);
				_bgImgW = createS(parent, _prop.msgs.width, _prop.looks.backWidthMax, _prop.looks.backWidthMin);
				_bgImgH = createS(parent, _prop.msgs.height, _prop.looks.backHeightMax, _prop.looks.backHeightMin);
			}
		} else static if (is(T:OuterTool)) {
			void selectProgram() {
				string[] desc;
				string[] ext;
				version (Windows) {
					desc = [_prop.msgs.exeFileDescExe, _prop.msgs.exeFileDescAll];
					ext = ["*.exe", "*.*"];
				} else {
					desc = [_prop.msgs.exeFileDescAll];
					ext = ["*.*"];
				}
				selectFile(_toolCommand, desc, ext, "", _prop.msgs.dlgTitOuterTool, _toolCommand.getText());
			}
			void selectWorkDir() {
				selectDir(_toolWorkDir, _prop.msgs.toolWorkDir, _prop.msgs.toolWorkDirDesc, _toolWorkDir.getText());
			}
			void setupRight(Composite parent) {
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.outerToolName);
					_name = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _name, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					_name.setLayoutData(gd);
				}
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.outerToolCommand);
					_toolCommand = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _toolCommand, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.widthHint = 0;
					_toolCommand.setLayoutData(gd);
					_toolCommandRef = new Button(parent, SWT.PUSH);
					_toolCommandRef.setText(_prop.msgs.reference);
					listener(_toolCommandRef, SWT.Selection, &selectProgram);
					_toolCommandDirOpen = createOpenButton(parent, _toolCommand, false);
					setupDropFile(_toolCommand, _toolCommand, &dropDefault);
				}
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.outerToolWorkDir);
					_toolWorkDir = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _toolWorkDir, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.widthHint = 0;
					_toolWorkDir.setLayoutData(gd);
					_toolWorkDirRef = new Button(parent, SWT.PUSH);
					_toolWorkDirRef.setText(_prop.msgs.reference);
 					listener(_toolWorkDirRef, SWT.Selection, &selectWorkDir);
					_toolWorkDirOpen = createOpenButton(parent, _toolWorkDir, true);
					setupDropFile(_toolWorkDir, _toolWorkDir, &dropDir);
				}
				{
					auto dummy = new Composite(parent, SWT.NONE);
					auto gd = new GridData;
					gd.verticalSpan = 3;
					gd.widthHint = 0;
					gd.heightHint = 0;
					dummy.setLayoutData(gd);
					auto hint1 = new Label(parent, SWT.NONE);
					hint1.setText(_prop.msgs.toolsHint1);
					auto gd1 = new GridData;
					gd1.horizontalSpan = 3;
					hint1.setLayoutData(gd1);
					auto hint2 = new Label(parent, SWT.NONE);
					hint2.setText(_prop.msgs.toolsHint2);
					auto gd2 = new GridData;
					gd2.horizontalSpan = 3;
					hint2.setLayoutData(gd2);
					auto hint3 = new Label(parent, SWT.NONE);
					hint3.setText(_prop.msgs.toolsHint3);
					auto gd3 = new GridData;
					gd3.horizontalSpan = 3;
					hint3.setLayoutData(gd3);
				}
			}
		} else static if (is(T:ClassicEngine)) {
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
			@property
			string curCEnginePath() {
				string path = _cEnginePath.getText();
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
			void selectCEnginePath() {
				string[] desc;
				string[] ext;
				version (Windows) {
					desc = [_prop.msgs.exeFileDescExe, _prop.msgs.exeFileDescAll];
					ext = ["*.exe", "*.*"];
				} else {
					desc = [_prop.msgs.exeFileDescAll];
					ext = ["*.*"];
				}
				string fname = selectFile(_cEnginePath, desc, ext, "", _prop.msgs.dlgTitClassicEnginePath, _cEnginePath.getText());
				if (fname) {
					dropCEnginePath(fname);
				}
			}
			void dropCEnginePath(string path) {
				string resDir = Skin.findResDir(path.dirName);
				if (resDir.length) {
					_cEngineDataDir.setText(resDir);
				}
			}
			void selectCEngineDataDir() {
				string path = _cEngineDataDir.getText();
				if (_cEnginePath.getText().length && !cwx.utils.isabs(path)) {
					path = std.path.buildPath(_cEnginePath.getText().dirName, path);
				}
				path = nabs(path);
				string fname = selectDir(_cEngineDataDir, _prop.msgs.classicEngineDataDirName, _prop.msgs.classicEngineDataDirNameDesc, path, false);
				if (fname) {
					fname = dropCEngineSub(fname);
					_cEngineDataDir.setText(fname);
				}
			}
			void selectCEngineExecute() {
				string[] desc;
				string[] ext;
				version (Windows) {
					desc = [_prop.msgs.exeFileDescExe, _prop.msgs.exeFileDescAll];
					ext = ["*.exe", "*.*"];
				} else {
					desc = [_prop.msgs.exeFileDescAll];
					ext = ["*.*"];
				}
				string path = _cEngineExecute.getText();
				string fileName = "";
				if (path.length) {
					fileName = path.baseName;
					if (_cEnginePath.getText().length && !cwx.utils.isabs(path)) {
						path = std.path.buildPath(_cEnginePath.getText().dirName, path);
					}
				} else {
					path = std.path.buildPath(_cEnginePath.getText().dirName, "*.exe");
				}
				path = nabs(path);
				string fname = selectFile(_cEngineExecute, desc, ext, fileName, _prop.msgs.dlgTitClassicEngineExecute, path);
				if (fname) {
					fname = dropCEngineSub(fname);
					_cEngineExecute.setText(fname);
				}
			}
			Button createCEngineSubOpenButton(Composite parent, Text path, bool dir) {
				auto open = new Button(parent, SWT.PUSH);
				open.setToolTipText(_prop.buildTool(dir ? MenuID.OpenDir : MenuID.OpenPlace));
				open.setImage(_prop.images.menu(MenuID.OpenDir));
				open.addSelectionListener(new OpenDir(path, true));
				return open;
			}
			void setupRight(Composite parent) {
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.classicEngineName);
					_name = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _name, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					_name.setLayoutData(gd);
				}
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.classicEnginePath);
					_cEnginePath = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _cEnginePath, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.widthHint = 0;
					_cEnginePath.setLayoutData(gd);
					_cEnginePathRef = new Button(parent, SWT.PUSH);
					_cEnginePathRef.setText(_prop.msgs.reference);
					listener(_cEnginePathRef, SWT.Selection, &selectCEnginePath);
					_cEnginePathDirOpen = createOpenButton(parent, _cEnginePath, false);
					setupDropFile(_cEnginePath, _cEnginePath, &dropCEnginePath, &dropCEnginePath);
				}
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.classicEngineDataDirName);
					_cEngineDataDir = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _cEngineDataDir, &catchMod);
					_cEngineDataDir.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

					_cEngineDataDirRef = new Button(parent, SWT.PUSH);
					_cEngineDataDirRef.setText(_prop.msgs.reference);
					listener(_cEngineDataDirRef, SWT.Selection, &selectCEngineDataDir);
					_cEngineDataDirOpen = createCEngineSubOpenButton(parent, _cEngineDataDir, true);
					setupDropFile(_cEngineDataDir, _cEngineDataDir, &dropCEngineDataDir);
				}
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.classicEngineExecute);
					_cEngineExecute = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _cEngineExecute, &catchMod);
					_cEngineExecute.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

					_cEngineExecuteRef = new Button(parent, SWT.PUSH);
					_cEngineExecuteRef.setText(_prop.msgs.reference);
					listener(_cEngineExecuteRef, SWT.Selection, &selectCEngineExecute);
					_cEngineExecuteDirOpen = createCEngineSubOpenButton(parent, _cEngineExecute, true);
					setupDropFile(_cEngineExecute, _cEngineExecute, &dropCEngineExecute);
				}
				{
					auto hint1 = new Label(parent, SWT.NONE);
					hint1.setText(_prop.msgs.classicEngineHint1);
					auto gd1 = new GridData;
					gd1.horizontalSpan = 4;
					hint1.setLayoutData(gd1);
				}
			}
		} else static if (is(T:ScTemplate)) {
			string dropTemplate(string[] files) {
				if (!files.length) return "";
				string file = files[0];
				if (.isDir(file)) return file;
				auto bn = file.baseName;
				if (fnmatch(bn, "Summary.wsm") || fnmatch(bn, "Summary.xml")) {
					return file;
				}
				auto ext = cwx.utils.getExt(bn);
				if (fnmatch(ext, "zip") || fnmatch(ext, "wsn") || (fnmatch(ext, "cab") && canUncab)) {
					return file;
				}
				return "";
			}
			void selectTemplate() {
				string[] desc = scenarioFilterDesc(_prop);
				string[] ext = scenarioFilter;
				selectFile(_templPath, desc, ext, "", _prop.msgs.dlgTitScTemplate, _templPath.getText());
			}
			void setupRight(Composite parent) {
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.scenarioTemplateName);
					_name = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _name, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					_name.setLayoutData(gd);
				}
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.scenarioTemplatePath);
					_templPath = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _templPath, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.widthHint = 0;
					_templPath.setLayoutData(gd);
					_templPathRef = new Button(parent, SWT.PUSH);
					_templPathRef.setText(_prop.msgs.reference);
					listener(_templPathRef, SWT.Selection, &selectTemplate);
					_templPathDirOpen = createOpenButton(parent, _templPath, false);
					setupDropFile(_templPath, _templPath, &dropTemplate);
				}
			}
		} else static if (is(T:EvTemplate)) {
			void setupRight(Composite parent) {
				parent.setLayoutData(new GridData(GridData.FILL_BOTH));
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.eventTemplateName);
					_name = new Text(parent, SWT.BORDER);
					_tms ~= createTextMenu!Text(_comm, _prop, _name, &catchMod);
					auto gd = new GridData(GridData.FILL_HORIZONTAL);
					gd.horizontalSpan = 3;
					_name.setLayoutData(gd);
				}
				{
					auto l = new Label(parent, SWT.NONE);
					l.setText(_prop.msgs.eventTemplateScript);
					_templScript = new Text(parent, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.H_SCROLL | SWT.V_SCROLL);
					_tms ~= createTextMenu!Text(_comm, _prop, _templScript, &catchMod);
					auto gd = new GridData(GridData.FILL_BOTH);
					gd.widthHint = 0;
					gd.horizontalSpan = 3;
					_templScript.setLayoutData(gd);

					auto font = _templScript.getFont();
					auto fSize = font ? cast(uint) font.getFontData()[0].height : 0;
					auto font2 = new Font(Display.getCurrent(), dwtData(CFont(_prop.looks.monospace, fSize, false, false)));
					_templScript.setFont(font2);
					listener(_templScript, SWT.Dispose, {
						font2.dispose();
					});
				}
			}
		} else static assert (0);
	public:
		this (Composite parent, int style) {
			super (parent, style);
			_undo = new UndoManager(_prop.var.etc.undoMaxEtc);
		}

		void setup() {
			this.setLayout(zeroMarginGridLayout(1, true));

			auto grp = new Group(this, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, true));
			static if (is(T:BgImageSetting)) {
				grp.setText(_prop.msgs.bgImageSettings);
			} else static if (is(T:OuterTool)) {
				grp.setText(_prop.msgs.classicEnginesTitle);
			} else static if (is(T:ClassicEngine)) {
				grp.setText(_prop.msgs.outerToolsTitle);
			} else static if (is(T:ScTemplate)) {
				grp.setText(_prop.msgs.scenarioTemplatesTitle);
			} else static if (is(T:EvTemplate)) {
				grp.setText(_prop.msgs.eventTemplatesTitle);
			} else static assert (0);
			auto leftSash = new SplitPane(grp, SWT.HORIZONTAL);
			leftSash.setLayoutData(new GridData(GridData.FILL_BOTH));
			{
				auto left = new Composite(leftSash, SWT.NONE);
				left.setLayout(zeroMarginGridLayout(2, true));
				_list = new List(left, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = _prop.var.etc.settingListWidth;
				gd.heightHint = _prop.var.etc.settingListHeight;
				gd.horizontalSpan = 2;
				_list.setLayoutData(gd);
				listener(_list, SWT.Selection, &selected);

				auto menu = new Menu(_list);
				createMenuItem(_comm, menu, MenuID.Undo, {_undo.undo();}, &_undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, {_undo.redo();}, &_undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				bool canUp() {
					return _list.getSelectionIndex() != -1 && 0 < _list.getSelectionIndex();
				}
				bool canDown() {
					return _list.getSelectionIndex() != -1 && _list.getSelectionIndex() + 1 < _list.getItemCount();
				}
				createMenuItem(_comm, menu, MenuID.Up, &up, &canUp);
				createMenuItem(_comm, menu, MenuID.Down, &down, &canDown);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new UTCPD, true, true, true, true);
				_list.setMenu(menu);

				auto up = new Button(left, SWT.PUSH);
				up.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				up.setText(_prop.buildTool(MenuID.Up));
				up.setImage(_prop.images.menu(MenuID.Up));
				listener(up, SWT.Selection, &this.up);
				_comm.put(up, &canUp);
				auto down = new Button(left, SWT.PUSH);
				down.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				down.setText(_prop.buildTool(MenuID.Down));
				down.setImage(_prop.images.menu(MenuID.Down));
				listener(down, SWT.Selection, &this.down);
				_comm.put(down, &canDown);
			}

			auto right = new Composite(leftSash, SWT.NONE);
			right.setLayout(zeroMarginGridLayout(1, true));
			{
				auto comp2 = new Composite(right, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				comp2.setLayout(zeroMarginGridLayout(4, false));
				setupRight(comp2);
			}
			{
				auto buttons = new Composite(right, SWT.NONE);
				buttons.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
				buttons.setLayout(zeroMarginGridLayout(3, true));
				auto create = new Button(buttons, SWT.PUSH);
				create.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				create.setText(_prop.msgs.sNew);
				listener(create, SWT.Selection, &this.create);
				_alt = new Button(buttons, SWT.PUSH);
				_alt.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_alt.setText(_prop.msgs.sAlt);
				listener(_alt, SWT.Selection, &alt);
				_del = new Button(buttons, SWT.PUSH);
				_del.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_del.setText(_prop.msgs.sDel);
				listener(_del, SWT.Selection, &del);
			}

			_kdFilter = new KeyDownFilter();
			this.getDisplay().addFilter(SWT.KeyDown, _kdFilter);
			_comm.refMenu.add(&refMenu);
			_comm.refUndoMax.add(&refUndoMax);
			listener(this, SWT.Dispose, {
				this.getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
				_comm.refMenu.remove(&refMenu);
				_comm.refUndoMax.remove(&refUndoMax);
			});

			modB(_alt, _list, _name);
			static if (is(T:BgImageSetting)) {
				modB(_alt, _list, _bgImgMask);
				modB(_alt, _list, _bgImgX);
				modB(_alt, _list, _bgImgY);
				modB(_alt, _list, _bgImgW);
				modB(_alt, _list, _bgImgH);
				leftSash.setWeights([_prop.var.etc.bgImageSettingsSashL, _prop.var.etc.bgImageSettingsSashR]);
				listener(leftSash, SWT.Dispose, (Event e) {
					auto ws = (cast(SplitPane) e.widget).getWeights();
					_prop.var.etc.bgImageSettingsSashL = ws[0];
					_prop.var.etc.bgImageSettingsSashR = ws[1];
				});
				auto l = _prop.var.etc.bgImageSettings;
			} else static if (is(T:OuterTool)) {
				modB(_alt, _list, _toolCommand);
				modB(_alt, _list, _toolWorkDir);
				leftSash.setWeights([_prop.var.etc.outerToolsSashL, _prop.var.etc.outerToolsSashR]);
				listener(leftSash, SWT.Dispose, (Event e) {
					auto ws = (cast(SplitPane) e.widget).getWeights();
					_prop.var.etc.outerToolsSashL = ws[0];
					_prop.var.etc.outerToolsSashR = ws[1];
				});
				auto l = _prop.var.etc.outerTools;
			} else static if (is(T:ClassicEngine)) {
				modB(_alt, _list, _cEnginePath);
				modB(_alt, _list, _cEngineDataDir);
				modB(_alt, _list, _cEngineExecute);
				leftSash.setWeights([_prop.var.etc.classicEnginesSashL, _prop.var.etc.classicEnginesSashR]);
				listener(leftSash, SWT.Dispose, (Event e) {
					auto ws = (cast(SplitPane) e.widget).getWeights();
					_prop.var.etc.classicEnginesSashL = ws[0];
					_prop.var.etc.classicEnginesSashR = ws[1];
				});
				auto l = _prop.var.etc.classicEngines;
			} else static if (is(T:ScTemplate)) {
				modB(_alt, _list, _templPath);
				leftSash.setWeights([_prop.var.etc.scenarioTemplatesSashL, _prop.var.etc.scenarioTemplatesSashR]);
				listener(leftSash, SWT.Dispose, (Event e) {
					auto ws = (cast(SplitPane) e.widget).getWeights();
					_prop.var.etc.scenarioTemplatesSashL = ws[0];
					_prop.var.etc.scenarioTemplatesSashR = ws[1];
				});
				auto l = _prop.var.etc.scenarioTemplates;
			} else static if (is(T:EvTemplate)) {
				modB(_alt, _list, _templScript);
				leftSash.setWeights([_prop.var.etc.eventTemplatesSashL, _prop.var.etc.eventTemplatesSashR]);
				listener(leftSash, SWT.Dispose, (Event e) {
					auto ws = (cast(SplitPane) e.widget).getWeights();
					_prop.var.etc.eventTemplatesSashL = ws[0];
					_prop.var.etc.eventTemplatesSashR = ws[1];
				});
				auto l = _prop.var.etc.eventTemplates;
			} else static assert (0);

			_array.length = l.length;
			foreach (i, t; l) {
				_list.add(t.name);
				_array[i] = t;
			}
			if (_array.length > 0) _list.select(0);
			selected();
		}

		@property
		T[] array() {
			return _array;
		}
	}

	Commons _comm;
	Props _prop;
	Summary _summ;
	DockingFolderCTC _dock;
	void delegate() _sendReloadProps;

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
	Combo _wallpaperStyle;
	int[int] _wallpaperStyleTbl;
	int[int] _wallpaperStyleTbl2;
	Button _clearHist;
	Spinner _histMax;
	Button _clearSHist;
	Spinner _sHistMax;
	Spinner _undoMaxMainView;
	Spinner _undoMaxEvent;
	Spinner _undoMaxReplace;
	Spinner _undoMaxEtc;

	CTabItem _tabS;
	BgImageS[] _bgImagesDefault;
	ToolsPane!BgImageSetting _bgStgs;
	Text _keyCodes;

	CTabItem _tabT;
	ToolsPane!OuterTool _tools;
	ToolsPane!ClassicEngine _cEngines;

	CTabItem _tabC;
	ToolsPane!ScTemplate _scTempls;
	ToolsPane!EvTemplate _evTempls;

	CTabItem _tabE;
	Text _ignorePaths;
	Button _singleWindow = null;
	Button _smoothingCard;
	Button _showImagePreview;
	Button _expandXMLs;
	Button _contentsFloat;
	Button _contentsAutoHide;
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
	Button _reconstruction;
	Button _openLastScenario;
	Combo _soundPlayType;
	int[int] _soundPlayTypeTbl;
	int[int] _soundPlayTypeTbl2;
	Combo _dialogStatus;
	int[int] _dialogStatusTbl;
	int[int] _dialogStatusTbl2;
	Text _savedSound;

	Text _mnemonic;
	HotKeyField _hotkey;
	Table _menu;
	Button _menuApply;
	Button _menuDel;
	class SMenuData {
		MenuID id;
		string mnemonic;
		string hotkey;
	}

	class RefE : SelectionAdapter, ModifyListener {
		override void widgetSelected(SelectionEvent e) {
			refreshEnabled();
		}
		override void modifyText(ModifyEvent e) {
			refreshEnabled();
		}
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
			if (str.length && str != _text.getText()) {
				_text.setText(str);
				_text.selectAll();
				e.detail = DND.DROP_LINK;
				if (_dropPath) _dropPath(str);
			}
		}
	}
	void setupDropFile(Control c, Text text, string delegate(string[] files) drop, void delegate(string) dropPath = null) {
		auto dropt = new DropTarget(c, DND.DROP_DEFAULT | DND.DROP_LINK);
		dropt.setTransfer([FileTransfer.getInstance()]);
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
			if (.contains!("a == b", string, string)(SYSTEM_SOUND_EXT, ext)) {
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

	const WALLPAPER_EXT = ["bmp", "ico", "icon", "jpg", "jpeg", "gif", "png", "tif", "tiff"];
	string dropWallpaper(string[] files) {
		if (!files.length) return "";
		foreach (file; files) {
			if (.contains!("a == b", string, string)(WALLPAPER_EXT, cwx.utils.toLower(cwx.utils.getExt(file)))) {
				return file;
			}
		}
		return "";
	}
	static string selectFile(Text file, string[] name, string[] ext, string fileName, string title, string p) {
		auto dlg = new FileDialog(file.getShell(), SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.OPEN);
		dlg.setFilterExtensions(ext);
		dlg.setFilterNames(name);
		dlg.setText(title);
		dlg.setFilterPath(dirName(nabs(p)));
		dlg.setFileName(fileName);
		string fname = dlg.open();
		if (fname) {
			file.setText(fname);
		}
		return fname;
	}
	void selectEngine() {
		selectFile(_enginePath, [_prop.var.etc.engine], [_prop.var.etc.engine],
			_prop.var.etc.engine, .tryFormat(_prop.msgs.dlgTitEnginePath, _prop.var.etc.engine),
			_prop.var.etc.enginePath);
	}
	void selectSysSound(Text widget) {
		string[] extArr;
		foreach (sse; SYSTEM_SOUND_EXT) {
			extArr ~= "*." ~ sse;
		}
		string exts = std.string.join(extArr, ";");
		selectFile(widget, [.tryFormat(_prop.msgs.playableSounds, exts)], [exts],
			baseName(widget.getText()), _prop.msgs.dlgTitSystemSound,
			widget.getText());
	}
	string selectDir(Text dir, string title, string msg, string p, bool appPath = true) {
		auto dlg = new DirectoryDialog(dir.getShell());
		dlg.setText(title);
		dlg.setMessage(msg);
		string path = p;
		if (appPath) {
			auto d = dir.getText();
			if (!cwx.utils.isabs(d)) {
				d = std.path.buildPath(std.path.dirName(_prop.parent.appPath), d);
			}
			path = d;
		}
		dlg.setFilterPath(nabs(path));
		string fname = dlg.open();
		if (fname) {
			dir.setText(fname);
		}
		return fname;
	}
	void selectTemp() {
		selectDir(_tempDir, _prop.msgs.tempDir, _prop.msgs.tempDirDesc, _prop.tempPath);
	}
	void selectBackup() {
		selectDir(_backupDir, _prop.msgs.backupDir, _prop.msgs.backupDirDesc, _prop.backupPath);
	}
	void selectWallpaper() {
		auto filterName = [_prop.msgs.filterWallpaper, _prop.msgs.filterAll];
		string[] filter = [
			"*." ~ std.string.join(WALLPAPER_EXT.dup, ";*."),
			"*"
		];
		selectFile(_wallpaper, filterName, filter,
			_prop.var.etc.wallpaper, _prop.msgs.dlgTitWallpaper, getcwd());
	}
	class SelEngine : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectEngine();}
	}
	class SelTemp : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectTemp();}
	}
	class SelBackup : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectBackup();}
	}
	class SelWallpaper : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {selectWallpaper();}
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
	void refHistories() {
		_clearHist.setEnabled(_prop.var.etc.openHistories.length > 0);
	}
	void refSearchHistories() {
		_clearSHist.setEnabled(_prop.var.etc.searchHistories.length || _prop.var.etc.replaceHistories.length);
	}
	class ClearHist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto dlg = new MessageBox(_histMax.getShell(), SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
			dlg.setText(_prop.msgs.dlgTitQuestion);
			dlg.setMessage(_prop.msgs.dlgMsgHistoryClear);
			if (SWT.OK == dlg.open()) {
				_prop.var.etc.openHistories = [];
				_comm.refHistories.call();
				_prop.var.save(_dock);
				_sendReloadProps();
			}
		}
	}
	class ClearSHist : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto dlg = new MessageBox(_sHistMax.getShell(), SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
			dlg.setText(_prop.msgs.dlgTitQuestion);
			dlg.setMessage(_prop.msgs.dlgMsgSearchHistoryClear);
			if (SWT.OK == dlg.open()) {
				_prop.var.etc.searchHistories = [];
				_prop.var.etc.replaceHistories = [];
				_comm.refSearchHistories.call();
				_prop.var.save(_dock);
				_sendReloadProps();
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
			string file = _text.getText();
			if (!cwx.utils.isabs(file)) {
				if (_cEngineSub) {
					auto engine = _cEngines.curCEnginePath;
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
		open.setToolTipText(_prop.buildTool(dir ? MenuID.OpenDir : MenuID.OpenPlace));
		open.setImage(_prop.images.menu(MenuID.OpenDir));
		open.addSelectionListener(new OpenDir(path, false));
		_comm.put(open, () => path.getText().length > 0);
		return open;
	}
	void construct1(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		_tabB = new CTabItem(tabf, SWT.NONE);
		_tabB.setText(_prop.msgs.baseSettings);
		_tabB.setControl(comp);
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new GridLayout(3, false));
			grp.setText(.tryFormat(_prop.msgs.enginePath, _prop.var.etc.engine));
			_enginePath = new Text(grp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _enginePath, &catchMod);
			_enginePath.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			mod(_enginePath);
			auto refr = new Button(grp, SWT.PUSH);
			refr.setText(_prop.msgs.reference);
			refr.addSelectionListener(new SelEngine);
			createOpenButton(grp, _enginePath, false);
			auto l = new Label(grp, SWT.NONE);
			l.setText(_prop.msgs.enginePathAtten);
			auto gd = new GridData;
			gd.horizontalSpan = 3;
			l.setLayoutData(gd);
			setupDropFile(grp, _enginePath, &dropEngine);
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setLayout(new GridLayout(3, false));
			grp.setText(_prop.msgs.tempDir);
			_tempDir = new Text(grp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _tempDir, &catchMod);
			_tempDir.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			mod(_tempDir);
			auto refr = new Button(grp, SWT.PUSH);
			refr.setText(_prop.msgs.reference);
			refr.addSelectionListener(new SelTemp);
			createOpenButton(grp, _tempDir, true);
			setupDropFile(grp, _tempDir, &dropDir);
		}
		{
			auto grp = new Group(comp, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.backupDir);
			auto gl = new GridLayout(3, false);
			gl.horizontalSpacing = 10;
			grp.setLayout(gl);

			{
				_backupEnabled = new Button(grp, SWT.CHECK);
				_backupEnabled.setText(_prop.msgs.backupEnabled);
				mod(_backupEnabled);
				_backupEnabled.addSelectionListener(_refe);
			}
			{
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				comp2.setLayout(zeroMarginGridLayout(3, false));
				auto l = new Label(comp2, SWT.CENTER);
				l.setText(_prop.msgs.backupInterval);
				_backupInterval = new Spinner(comp2, SWT.BORDER);
				_backupInterval.setMinimum(1);
				_backupInterval.setMaximum(99);
				mod(_backupInterval);
				auto l2 = new Label(comp2, SWT.CENTER);
				l2.setText(_prop.msgs.minute);
			}
			{
				auto comp2 = new Composite(grp, SWT.NONE);
				comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				comp2.setLayout(zeroMarginGridLayout(2, false));
				auto l = new Label(comp2, SWT.CENTER);
				l.setText(_prop.msgs.backupCount);
				_backupCount = new Spinner(comp2, SWT.BORDER);
				_backupCount.setMinimum(0);
				_backupCount.setMaximum(99);
				mod(_backupCount);
			}
			{
				auto comp2 = new Composite(grp, SWT.NONE);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				comp2.setLayoutData(gd);
				comp2.setLayout(zeroMarginGridLayout(4, false));
				auto l = new Label(comp2, SWT.NONE);
				l.setText(_prop.msgs.backupPath);
				_backupDir = new Text(comp2, SWT.BORDER);
				createTextMenu!Text(_comm, _prop, _backupDir, &catchMod);
				_backupDir.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				mod(_backupDir);
				_backupRef = new Button(comp2, SWT.PUSH);
				_backupRef.setText(_prop.msgs.reference);
				_backupRef.addSelectionListener(new SelBackup);
				_backupDirOpen = createOpenButton(comp2, _backupDir, true);
				setupDropFile(grp, _backupDir, &dropDir);
			}
		}
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp2.setLayout(zeroMarginGridLayout(2, false));
			{
				auto comp3 = new Composite(comp2, SWT.NONE);
				comp3.setLayoutData(new GridData(GridData.FILL_BOTH));
				comp3.setLayout(zeroMarginGridLayout(1, false));
				{
					auto grp = new Group(comp3, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					auto cl = new CenterLayout;
					cl.fillHorizontal = true;
					grp.setLayout(cl);
					grp.setText(_prop.msgs.scenarioAuthor);
					_author = new Text(grp, SWT.BORDER);
					createTextMenu!Text(_comm, _prop, _author, &catchMod);
					mod(_author);
				}
				{
					auto grp = new Group(comp3, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(1, true));
					grp.setText(_prop.msgs.wallpaper);
					{
						auto comp4 = new Composite(grp, SWT.NONE);
						comp4.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						comp4.setLayout(zeroMarginGridLayout(3, false));
						_wallpaper = new Text(comp4, SWT.BORDER);
						createTextMenu!Text(_comm, _prop, _wallpaper, &catchMod);
						_wallpaper.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						mod(_wallpaper);
						auto refr = new Button(comp4, SWT.PUSH);
						refr.setText(_prop.msgs.reference);
						refr.addSelectionListener(new SelWallpaper);
						createOpenButton(comp4, _wallpaper, false);
					}
					{
						auto comp4 = new Composite(grp, SWT.NONE);
						comp4.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						comp4.setLayout(zeroMarginGridLayout(2, false));

						int[] styles;
						string[] names;
						foreach (s; [WallpaperStyle.Center, WallpaperStyle.Tile, WallpaperStyle.ExpandFull, WallpaperStyle.Expand]) {
							styles ~= cast(int) s;
							names ~= _prop.msgs.wallpaperStyleName(s);
						}
						_wallpaperStyle = createEnumC(comp4, _prop.msgs.wallpaperStyle, styles, names, _wallpaperStyleTbl, _wallpaperStyleTbl2);
					}
					setupDropFile(grp, _wallpaper, &dropWallpaper);
				}
				{
					auto grp = new Group(comp3, SWT.NONE);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setText(_prop.msgs.systemSounds);
					grp.setLayout(new GridLayout(4, false));
					auto l = new Label(grp, SWT.NONE);
					l.setText(_prop.msgs.soundSaved);
					_savedSound = new Text(grp, SWT.BORDER);
					createTextMenu!Text(_comm, _prop, _savedSound, &catchMod);
					_savedSound.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					mod(_savedSound);
					auto refr = new Button(grp, SWT.PUSH);
					refr.setText(_prop.msgs.reference);
					refr.addSelectionListener(new SelSysSound(_savedSound));
					createOpenButton(grp, _savedSound, false);
					setupDropFile(grp, _savedSound, &dropSysSound);	
				}
			}
			{
				auto comp3 = new Composite(comp2, SWT.NONE);
				comp3.setLayout(zeroMarginGridLayout(1, true));
				comp3.setLayoutData(new GridData(GridData.FILL_VERTICAL));
				{
					auto grp = new Group(comp3, SWT.NONE);
					grp.setText(_prop.msgs.historiesSettings);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(3, false));
					{
						auto lComp = new Composite(grp, SWT.NONE);
						auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
						cl.fillHorizontal = true;
						lComp.setLayout(cl);
						lComp.setLayoutData(new GridData(GridData.FILL_BOTH));
						auto l = new Label(lComp, SWT.NONE);
						l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						l.setText(_prop.msgs.openHistoryMax);
						_histMax = new Spinner(grp, SWT.BORDER);
						_histMax.setMinimum(0);
						_histMax.setMaximum(99);
						mod(_histMax);
						_clearHist = new Button(grp, SWT.PUSH);
						_clearHist.setEnabled(_prop.var.etc.openHistories.length > 0);
						_clearHist.setText(_prop.msgs.openHistoryClear);
						_clearHist.addSelectionListener(new ClearHist);
					}
					{
						auto lComp = new Composite(grp, SWT.NONE);
						auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
						cl.fillHorizontal = true;
						lComp.setLayout(cl);
						lComp.setLayoutData(new GridData(GridData.FILL_BOTH));
						auto l = new Label(lComp, SWT.NONE);
						l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						l.setText(_prop.msgs.searchHistoryMax);
						_sHistMax = new Spinner(grp, SWT.BORDER);
						_sHistMax.setMinimum(0);
						_sHistMax.setMaximum(99);
						mod(_sHistMax);
						_clearSHist = new Button(grp, SWT.PUSH);
						_clearSHist.setEnabled(_prop.var.etc.searchHistories.length > 0);
						_clearSHist.setText(_prop.msgs.searchHistoryClear);
						_clearSHist.addSelectionListener(new ClearSHist);
					}
				}
				{
					auto grp = new Group(comp3, SWT.NONE);
					grp.setText(_prop.msgs.undoMax);
					grp.setLayoutData(new GridData(GridData.FILL_BOTH));
					grp.setLayout(new GridLayout(2, false));
					Spinner createUndoMax(string title) {
						auto l = new Label(grp, SWT.NONE);
						l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
						l.setText(title);
						auto spn = new Spinner(grp, SWT.BORDER);
						mod(spn);
						spn.setMaximum(_prop.var.etc.undoMaxLimit);
						spn.setMinimum(0);
						return spn;
					}
					_undoMaxMainView = createUndoMax(_prop.msgs.undoMaxMainView);
					_undoMaxEvent = createUndoMax(_prop.msgs.undoMaxEvent);
					_undoMaxReplace = createUndoMax(_prop.msgs.undoMaxReplace);
					_undoMaxEtc = createUndoMax(_prop.msgs.undoMaxEtc);
				}
			}
		}
	}
	Spinner createS(Composite parent, string name, int max, int min) {
		auto l = new Label(parent, SWT.NONE);
		l.setText(name);
		auto spn = new Spinner(parent, SWT.BORDER);
		spn.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		spn.setMaximum(max);
		spn.setMinimum(min);
		spn.setSelection(0);
		return spn;
	}
	class DefBgSetting : SelectionAdapter {
		private DefBgImgDialog _dlg = null;
		override void widgetSelected(SelectionEvent e) {
			if (_dlg) {
				_dlg.active();
				return;
			}
			_dlg = new DefBgImgDialog(_comm, _prop, getShell(), _bgImagesDefault);
			_dlg.appliedEvent ~= {
				_bgImagesDefault = _dlg.backs;
				applyEnabled();
			};
			_dlg.closeEvent ~= {
				_dlg = null;
			};
			_dlg.open();
		}
	}
	class DBgImgStg : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights();
			_prop.var.etc.bgImageSettingsSashL = ws[0];
			_prop.var.etc.bgImageSettingsSashR = ws[1];
		}
	}
	class DBgImgKeyCodeSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights();
			_prop.var.etc.bgImageKeyCodeSashL = ws[0];
			_prop.var.etc.bgImageKeyCodeSashR = ws[1];
		}
	}
	void modB(C)(Button button, List list, C ctrl) {
		static if (is(C : Button)) {
			ctrl.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) {
					if (0 < list.getItemCount()) {
						button.setEnabled(true);
					}
				}
			});
		} else {
			ctrl.addModifyListener(new class ModifyListener {
				override void modifyText(ModifyEvent e) {
					if (0 < list.getItemCount()) {
						button.setEnabled(true);
					}
				}
			});
		}
	}
	void construct2(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		_tabS = new CTabItem(tabf, SWT.NONE);
		_tabS.setText(_prop.msgs.bgImageAndKeyCode);
		_tabS.setControl(comp);
		comp.setLayout(new GridLayout(1, true));
		auto sash = new SplitPane(comp, SWT.HORIZONTAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto back = new Composite(sash, SWT.NONE);
		back.setLayout(zeroMarginGridLayout(1, true));
		{
			auto grp = new Group(back, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			auto cl = new CenterLayout;
			cl.fillHorizontal = true;
			grp.setLayout(cl);
			grp.setText(_prop.msgs.bgImagesDefault);
			auto defBtn = new Button(grp, SWT.PUSH);
			defBtn.setText(_prop.msgs.setBgImagesDefault);
			defBtn.addSelectionListener(new DefBgSetting);
		}
		{
			_bgStgs = new ToolsPane!BgImageSetting(back, SWT.NONE);
			_bgStgs.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{
			auto grp = new Group(sash, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, false));
			grp.setText(_prop.msgs.standardKeyCode);
			_keyCodes = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL);
			createTextMenu!Text(_comm, _prop, _keyCodes, &catchMod);
			mod(_keyCodes);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.keyCodeWidth;
			gd.heightHint = 0;
			_keyCodes.setLayoutData(gd);
		}
		sash.setWeights([_prop.var.etc.bgImageKeyCodeSashL, _prop.var.etc.bgImageKeyCodeSashR]);
		sash.addDisposeListener(new DBgImgKeyCodeSash);
	}

	void construct3(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		_tabT = new CTabItem(tabf, SWT.NONE);
		_tabT.setText(_prop.msgs.templates);
		_tabT.setControl(comp);

		auto sash = new SplitPane(comp, SWT.VERTICAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));

		_evTempls = new ToolsPane!EvTemplate(sash, SWT.NONE);
		_evTempls.setLayoutData(new GridData(GridData.FILL_BOTH));
		_scTempls = new ToolsPane!ScTemplate(sash, SWT.NONE);
		_scTempls.setLayoutData(new GridData(GridData.FILL_BOTH));

		sash.setWeights([_prop.var.etc.templatesSashL, _prop.var.etc.templatesSashR]);
		listener(sash, SWT.Dispose, {
			auto ws = sash.getWeights();
			_prop.var.etc.templatesSashL = ws[0];
			_prop.var.etc.templatesSashR = ws[1];
		});
	}

	void construct4(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, false));
		_tabC = new CTabItem(tabf, SWT.NONE);
		_tabC.setText(_prop.msgs.outerToolsAndClassicEngines);
		_tabC.setControl(comp);

		auto sash = new SplitPane(comp, SWT.VERTICAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));

		_tools = new ToolsPane!OuterTool(sash, SWT.NONE);
		_tools.setLayoutData(new GridData(GridData.FILL_BOTH));
		_cEngines = new ToolsPane!ClassicEngine(sash, SWT.NONE);
		_cEngines.setLayoutData(new GridData(GridData.FILL_BOTH));

		sash.setWeights([_prop.var.etc.toolsClassicEnginesSashL, _prop.var.etc.toolsClassicEnginesSashR]);
		listener(sash, SWT.Dispose, {
			auto ws = sash.getWeights();
			_prop.var.etc.toolsClassicEnginesSashL = ws[0];
			_prop.var.etc.toolsClassicEnginesSashR = ws[1];
		});
	}

	class SelContentsFloat : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			_contentsAutoHide.setEnabled(!_contentsFloat.getSelection());
		}
	}

	Combo createEnumC(Composite grp, string title, in int[] values, in string[] names, ref int[int] tblA, ref int[int] tblB) {
		assert (values.length == names.length);
		auto l = new Label(grp, SWT.NONE);
		l.setText(title);
		auto combo = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
		mod(combo);
		combo.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		combo.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		foreach (i, val; values) {
			tblA[val] = i;
			tblB[i] = val;
			combo.add(names[i]);
		}
		return combo;
	}
	class DMISash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto ws = (cast(SplitPane) e.widget).getWeights();
			_prop.var.etc.ignoreMenuSashL = ws[0];
			_prop.var.etc.ignoreMenuSashR = ws[1];
		}
	}
	void selectMenu() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		auto i = _menu.getSelectionIndex();
		if (-1 == i) return;
		auto itm = _menu.getItem(i);
		auto data = cast(SMenuData) itm.getData();
		_mnemonic.setText(data.mnemonic);
		_hotkey.accelerator = data.hotkey;
		_menuApply.setEnabled(false);
		_menuDel.setEnabled(_mnemonic.getText().length || _hotkey.widget.getText().length);
	}
	void applyMenu() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		auto i = _menu.getSelectionIndex();
		assert (i != -1);
		auto itm = _menu.getItem(i);
		auto data = cast(SMenuData) itm.getData();
		data.mnemonic = _mnemonic.getText();
		data.hotkey = _hotkey.acceleratorText;
		itm.setText(MenuProps.buildMenuSample(_prop.parent, data.id, data.mnemonic, data.hotkey));
		_menuApply.setEnabled(false);
		applyEnabled();
	}
	class SelectMenu : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selectMenu();
		}
	}
	class ModMenu : ModifyListener {
		override void modifyText(ModifyEvent e) {
			if (ignoreMod) return;
			_menuApply.setEnabled(true);
			_menuDel.setEnabled(_mnemonic.getText().length || _hotkey.widget.getText().length);
		}
	}
	class DelMenuAccel : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			ignoreMod = true;
			scope (exit) ignoreMod = false;
			_mnemonic.setText("");
			_hotkey.widget.setText("");
			applyMenu();
			_menuDel.setEnabled(false);
		}
	}
	class ApplyMenu : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			applyMenu();
		}
	}
	void construct5(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		_tabE = new CTabItem(tabf, SWT.NONE);
		_tabE.setText(_prop.msgs.etcSettings);
		_tabE.setControl(comp);
		comp.setLayout(new GridLayout(2, false));
		{
			auto comp2 = new Composite(comp, SWT.NONE);
			comp2.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			comp2.setLayout(zeroMarginGridLayout(1, false));
			{
				auto grp = new Group(comp2, SWT.NONE);
				grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				grp.setText(_prop.msgs.etcSettingsTitle);
				grp.setLayout(new GridLayout(2, false));
				Button createB(string text) {
					auto btn = new Button(grp, SWT.CHECK);
					btn.setText(text);
					mod(btn);
					auto gd = new GridData;
					gd.horizontalSpan = 2;
					btn.setLayoutData(gd);
					return btn;
				}
				if (!_comm.singleWindowMode(_prop)) {
					_singleWindow = createB(_prop.msgs.singleWindow);
				}
				_smoothingCard = createB(_prop.msgs.smoothingCard);
				_showImagePreview = createB(_prop.msgs.showImagePreview);
				_expandXMLs = createB(_prop.msgs.expandXMLs);
				_contentsFloat = createB(_prop.msgs.contentsFloat);
				_contentsAutoHide = createB(_prop.msgs.contentsAutoHide);
				_contentsFloat.addSelectionListener(new SelContentsFloat);
				_contentsAutoHide.setEnabled(!_contentsFloat.getSelection());
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
				_reconstruction = createB(_prop.msgs.reconstruction);
				_openLastScenario = createB(_prop.msgs.openLastScenario);

				auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
				auto sepgd = new GridData(GridData.FILL_HORIZONTAL);
				sepgd.horizontalSpan = 2;
				sep.setLayoutData(sepgd);

				version (Windows) {
					const int[] soundPlayTypeVals = [
						SOUND_TYPE_AUTO,
						SOUND_TYPE_SDL,
						SOUND_TYPE_MCI,
						SOUND_TYPE_APP
					];
					string[] soundPlayTypeNames = [
						_prop.msgs.soundPlayTypeDef,
						_prop.msgs.soundPlayTypeSDL,
						_prop.msgs.soundPlayTypeMCI,
						_prop.msgs.soundPlayTypeApp
					];
				} else {
					const int[] soundPlayTypeVals = [
						SOUND_TYPE_AUTO,
						SOUND_TYPE_SDL,
						SOUND_TYPE_APP
					];
					string[] soundPlayTypeNames = [
						_prop.msgs.soundPlayTypeDef,
						_prop.msgs.soundPlayTypeSDL,
						_prop.msgs.soundPlayTypeApp
					];
				}
				_soundPlayType = createEnumC(grp, _prop.msgs.soundPlayType, soundPlayTypeVals, soundPlayTypeNames, _soundPlayTypeTbl, _soundPlayTypeTbl2);
				_dialogStatus = createEnumC(grp, _prop.msgs.dialogStatus, [
					cast(int) DialogStatus.Top,
					cast(int) DialogStatus.Under,
					cast(int) DialogStatus.UnderWithCoupon,
				], [
					_prop.msgs.dialogStatusName(DialogStatus.Top),
					_prop.msgs.dialogStatusName(DialogStatus.Under),
					_prop.msgs.dialogStatusName(DialogStatus.UnderWithCoupon),
				], _dialogStatusTbl, _dialogStatusTbl2);
			}
		}
		{
			auto sash = new SplitPane(comp, SWT.VERTICAL);
			auto sgd = new GridData(GridData.FILL_BOTH);
			sgd.verticalSpan = 3;
			sash.setLayoutData(sgd);
			{
				auto grp = new Group(sash, SWT.NONE);
				grp.setText(_prop.msgs.keyBind);
				grp.setLayout(new GridLayout(4, false));

				auto l1 = new Label(grp, SWT.NONE);
				l1.setText(_prop.msgs.mnemonic);
				_mnemonic = mnemonicText(grp, SWT.BORDER);
				createTextMenu!Text(_comm, _prop, _mnemonic, &catchMod);
				_mnemonic.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_mnemonic.addModifyListener(new ModMenu);

				_menuApply = new Button(grp, SWT.PUSH);
				_menuApply.setText(_prop.msgs.apply);
				_menuApply.addSelectionListener(new ApplyMenu);
				_menuDel = new Button(grp, SWT.PUSH);
				_menuDel.setText(_prop.msgs.del);
				_menuDel.addSelectionListener(new DelMenuAccel);

				auto l2 = new Label(grp, SWT.NONE);
				l2.setText(_prop.msgs.hotkey);
				_hotkey = new HotKeyField(grp, SWT.BORDER);
				createTextMenu!Text(_comm, _prop, _hotkey.widget, &catchMod);
				auto hgd = new GridData(GridData.FILL_HORIZONTAL);
				hgd.horizontalSpan = 3;
				_hotkey.widget.setLayoutData(hgd);
				_hotkey.widget.addModifyListener(new ModMenu);

				_menu = new Table(grp, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL | SWT.FULL_SELECTION);
				_menu.setData(new CIgnoreHotkey); // 間違いやすいので
				auto mgd = new GridData(GridData.FILL_BOTH);
				mgd.horizontalSpan = 4;
				_menu.setLayoutData(mgd);
				new FullTableColumn(_menu, SWT.NONE);
				foreach (id; EnumMembers!MenuID) {
					if (id == MenuID.None) continue;
					if (isNoKeyBindMenu(id)) continue;
					auto itm = new TableItem(_menu, SWT.NONE);
					itm.setText(_prop.var.menu.buildMenuSample(_prop.parent, id));
					itm.setImage(_prop.images.menu(id));
					auto data = new SMenuData();
					data.id = id;
					data.mnemonic = _prop.var.menu.mnemonic(id);
					data.hotkey = _prop.var.menu.hotkey(id);
					itm.setData(data);
				}
				_menu.select(0);
				selectMenu();
				_menu.addSelectionListener(new SelectMenu);

				grp.setTabList([_menuApply, _menuDel, _menu]);
			}
			{
				auto grp = new Group(sash, SWT.NONE);
				grp.setText(_prop.msgs.ignorePaths);
				grp.setLayout(new GridLayout(1, false));
				_ignorePaths = new Text(grp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL);
				createTextMenu!Text(_comm, _prop, _ignorePaths, &catchMod);
				mod(_ignorePaths);
				auto gdp = new GridData(GridData.FILL_BOTH);
				gdp.widthHint = _prop.var.etc.ignorePathsWidth;
				gdp.heightHint = 0;
				_ignorePaths.setLayoutData(gdp);
			}
			sash.setWeights([_prop.var.etc.ignoreMenuSashL, _prop.var.etc.ignoreMenuSashR]);
			sash.addDisposeListener(new DMISash);
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
		_backupDir.setEnabled(_backupEnabled.getSelection());
		_backupInterval.setEnabled(_backupEnabled.getSelection());
		_backupCount.setEnabled(_backupEnabled.getSelection());
		_backupRef.setEnabled(_backupEnabled.getSelection());
		_backupDirOpen.setEnabled(_backupEnabled.getSelection());
	}
public:
	this (Commons comm, Props prop, Shell shell, DockingFolderCTC dock, Summary summ, void delegate() sendReloadProps) {
		super(prop, shell, false, prop.msgs.dlgTitSettings, prop.images.menu(MenuID.Settings), true, prop.var.settingsDlg, true);
		_comm = comm;
		_prop = prop;
		_dock = dock;
		_summ = summ;
		_sendReloadProps = sendReloadProps;
	}

protected:
	override void setup(Composite area) {
		area.setLayout(windowGridLayout(1, true));
		_comm.refScenario.add(&refreshScenario);
		_comm.refHistories.add(&refHistories);
		_comm.refSearchHistories.add(&refSearchHistories);
		area.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refScenario.remove(&refreshScenario);
				_comm.refHistories.remove(&refHistories);
				_comm.refSearchHistories.remove(&refSearchHistories);
			}
		});
		auto tabf = new CTabFolder(area, SWT.BORDER);
		tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
		_refe = new RefE;
		construct1(tabf);
		construct2(tabf);
		construct3(tabf);
		construct4(tabf);
		construct5(tabf);
		_bgStgs.setup();
		_cEngines.setup();
		_tools.setup();
		_scTempls.setup();
		_evTempls.setup();

		_enginePath.setText(_prop.var.etc.enginePath);
		_tempDir.setText(_prop.var.etc.tempPath);
		_backupDir.setText(_prop.var.etc.backupPath);
		_backupEnabled.setSelection(_prop.var.etc.backupEnabled);
		_backupInterval.setSelection(_prop.var.etc.backupInterval);
		_backupCount.setSelection(_prop.var.etc.backupCount);
		_author.setText(_prop.var.etc.defaultAuthor);
		_wallpaper.setText(_prop.var.etc.wallpaper);
		auto wsp = _prop.var.etc.wallpaperStyle in _wallpaperStyleTbl;
		if (wsp) {
			_wallpaperStyle.select(*wsp);
		} else {
			_wallpaperStyle.select(WallpaperStyle.Tile);
		}
		_histMax.setSelection(_prop.var.etc.historyMax);
		_sHistMax.setSelection(_prop.var.etc.searchHistoryMax);
		_undoMaxMainView.setSelection(_prop.var.etc.undoMaxMainView);
		_undoMaxEvent.setSelection(_prop.var.etc.undoMaxEvent);
		_undoMaxReplace.setSelection(_prop.var.etc.undoMaxReplace);
		_undoMaxEtc.setSelection(_prop.var.etc.undoMaxEtc);
		string ipbuf = "";
		foreach (path; _prop.var.etc.ignorePaths) {
			ipbuf ~= path ~ "\n";
		}
		_ignorePaths.setText(ipbuf);
		_expandXMLs.setSelection(_prop.var.etc.expandXMLs);
		_smoothingCard.setSelection(_prop.var.etc.smoothingCard);
		_showImagePreview.setSelection(_prop.var.etc.showImagePreview);
		if (_singleWindow) {
			_singleWindow.setSelection(_prop.var.etc.singleWindow);
		}
		_contentsFloat.setSelection(_prop.var.etc.contentsFloat);
		_contentsAutoHide.setSelection(_prop.var.etc.contentsAutoHide);
		_xmlCopy.setSelection(_prop.var.etc.xmlCopy);
		_saveInnerImagePath.setSelection(_prop.var.etc.saveInnerImagePath);
		_traceDirectories.setSelection(_prop.var.etc.traceDirectories);
		_logicalSort.setSelection(_prop.var.etc.logicalSort);
		_copyDesc.setSelection(_prop.var.etc.copyDesc);
		_refCardsAtEditBgImage.setSelection(_prop.var.etc.refCardsAtEditBgImage);
		_addNewClassicEngine.setSelection(_prop.var.etc.addNewClassicEngine);
		_doubleIO.setSelection(_prop.var.etc.doubleIO);
		_switchTabWheel.setSelection(_prop.var.etc.switchTabWheel);
		_openTabAtRightOfCurrentTab.setSelection(_prop.var.etc.openTabAtRightOfCurrentTab);
		_reconstruction.setSelection(_prop.var.etc.reconstruction);
		_openLastScenario.setSelection(_prop.var.etc.openLastScenario);
		auto sptp = _prop.var.etc.soundPlayType in _soundPlayTypeTbl;
		if (sptp) {
			_soundPlayType.select(*sptp);
		} else {
			_soundPlayType.select(0);
		}
		auto dsp = _prop.var.etc.dialogStatus in _dialogStatusTbl;
		if (dsp) {
			_dialogStatus.select(*dsp);
		} else {
			_dialogStatus.select(DialogStatus.Top);
		}
		_savedSound.setText(_prop.var.etc.savedSound);
		_bgImagesDefault = _prop.var.etc.bgImagesDefault.dup;

		string buf = "";
		foreach (kc; _prop.var.etc.standardKeyCodes) {
			buf ~= kc ~ "\n";
		}
		_keyCodes.setText(buf);

		refreshEnabled();
	}

	override bool apply() {
		void err(CTabItem tab, Text t, string msg) {
			auto dlg = new MessageBox(t.getShell(), SWT.ICON_WARNING | SWT.OK);
			dlg.setText(_prop.msgs.dlgTitWarning);
			dlg.setMessage(msg);
			dlg.open();
			tab.getParent().setSelection(tab);
			t.setFocus();
		}
		string engine;
		try {
			engine = _enginePath.getText();
		} catch {
			err(_tabB, _enginePath, .tryFormat(_prop.msgs.errorEnginePath, _prop.var.etc.engine));
			return false;
		}
		if (engine.length) {
			if (!.exists(engine) || .isDir(engine)) {
				err(_tabB, _enginePath, .tryFormat(_prop.msgs.errorEnginePath, _prop.var.etc.engine));
				return false;
			}
		}
		string temp;
		try {
			temp = _tempDir.getText();
		} catch {
			err(_tabB, _tempDir, _prop.msgs.errorTempPath);
			return false;
		}
		string backup;
		try {
			backup = _backupDir.getText();
		} catch {
			err(_tabB, _backupDir, _prop.msgs.errorBackupPath);
			return false;
		}
		auto oldStgs = OldSettings(_prop);
		scope (exit) {
			oldStgs.raiseEvent(_comm);
		}
		_prop.var.etc.enginePath = engine;
		_prop.var.etc.tempPath = temp;
		_prop.var.etc.backupPath = backup;
		_prop.var.etc.backupEnabled = _backupEnabled.getSelection();
		_prop.var.etc.backupInterval = _backupInterval.getSelection();
		_prop.var.etc.backupCount = _backupCount.getSelection();
		_prop.var.etc.defaultAuthor = _author.getText();
		_prop.var.etc.wallpaper = _wallpaper.getText();
		_prop.var.etc.wallpaperStyle = cast(WallpaperStyle) _wallpaperStyleTbl2[_wallpaperStyle.getSelectionIndex()];
		_prop.var.etc.historyMax = _histMax.getSelection();
		_prop.var.etc.searchHistoryMax = _sHistMax.getSelection();
		_prop.var.etc.undoMaxMainView = _undoMaxMainView.getSelection();
		_prop.var.etc.undoMaxEvent = _undoMaxEvent.getSelection();
		_prop.var.etc.undoMaxReplace = _undoMaxReplace.getSelection();
		_prop.var.etc.undoMaxEtc = _undoMaxEtc.getSelection();
		string[] ipLines = splitLines!string(_ignorePaths.getText());
		if (ipLines.length > 0) {
			int i;
			for (i = ipLines.length - 1; i >= 0 && ipLines[i].length == 0; i--) {
				;
			}
			_prop.var.etc.ignorePaths = ipLines[0 .. i + 1];
		} else {
			_prop.var.etc.ignorePaths = [];
		}
		if (_singleWindow) {
			_prop.var.etc.singleWindow = _singleWindow.getSelection();
		}
		_prop.var.etc.smoothingCard = _smoothingCard.getSelection();
		_prop.var.etc.showImagePreview = _showImagePreview.getSelection();
		_prop.var.etc.expandXMLs = _expandXMLs.getSelection();
		_prop.var.etc.xmlCopy = _xmlCopy.getSelection();
		_prop.var.etc.saveInnerImagePath = _saveInnerImagePath.getSelection();
		_prop.var.etc.traceDirectories = _traceDirectories.getSelection();
		_prop.var.etc.logicalSort = _logicalSort.getSelection();
		_prop.var.etc.copyDesc = _copyDesc.getSelection();
		_prop.var.etc.refCardsAtEditBgImage = _refCardsAtEditBgImage.getSelection();
		_prop.var.etc.addNewClassicEngine = _addNewClassicEngine.getSelection();
		_prop.var.etc.doubleIO = _doubleIO.getSelection();
		_prop.var.etc.switchTabWheel = _switchTabWheel.getSelection();
		_prop.var.etc.openTabAtRightOfCurrentTab = _openTabAtRightOfCurrentTab.getSelection();
		_prop.var.etc.reconstruction = _reconstruction.getSelection();
		_prop.var.etc.openLastScenario = _openLastScenario.getSelection();
		_prop.var.etc.contentsFloat = _contentsFloat.getSelection();
		_prop.var.etc.contentsAutoHide = _contentsAutoHide.getSelection();
		_prop.var.etc.soundPlayType = _soundPlayTypeTbl2[_soundPlayType.getSelectionIndex()];
		_prop.var.etc.dialogStatus = cast(DialogStatus) _dialogStatusTbl2[_dialogStatus.getSelectionIndex()];
		_prop.var.etc.savedSound = _savedSound.getText();
		if (_prop.var.etc.historyMax < _prop.var.etc.openHistories.length) {
			_prop.var.etc.openHistories
				= _prop.var.etc.openHistories[0 .. _prop.var.etc.historyMax].dup;
		}
		if (_prop.var.etc.searchHistoryMax < _prop.var.etc.searchHistories.length) {
			_prop.var.etc.searchHistories
				= _prop.var.etc.searchHistories[0 .. _prop.var.etc.searchHistoryMax].dup;
		}
		_prop.var.etc.bgImageSettings = _bgStgs.array;
		_prop.var.etc.bgImagesDefault = _bgImagesDefault;
		string[] lines = splitLines!string(_keyCodes.getText());
		if (lines.length > 0) {
			int i;
			for (i = lines.length - 1; i >= 0 && lines[i].length == 0; i--) {
				;
			}
			_prop.var.etc.standardKeyCodes = lines[0 .. i + 1];
		} else {
			_prop.var.etc.standardKeyCodes = [];
		}
		_prop.var.etc.outerTools = _tools.array;
		_prop.var.etc.classicEngines = _cEngines.array;
		_prop.var.etc.eventTemplates = _evTempls.array;
		_prop.var.etc.scenarioTemplates = _scTempls.array;
		foreach (itm; _menu.getItems()) {
			auto data = cast(SMenuData) itm.getData();
			_prop.var.menu.mnemonic(data.id, data.mnemonic);
			_prop.var.menu.hotkey(data.id, data.hotkey);
		}
		_prop.var.save(_dock);
		_sendReloadProps();
		return true;
	}
}

struct OldSettings {
	Props prop;
	string oldEnginePath;
	string oldWallpaper;
	WallpaperStyle oldWallpaperStyle;
	const string[] oldKeyCodes;
	const OuterTool[] tools;
	const ClassicEngine[] cEngines;
	const EvTemplate[] eventTemplates;
	const string[] oldIgnorePaths;
	bool oldSmoothingCard;
	bool oldLogicalSort;
	const string[] oldOpenHistories;
	const string[] oldSearchHistories;
	const string[] oldReplaceHistories;
	int oldUndoMaxMainView;
	int oldUndoMaxEvent;
	int oldUndoMaxReplace;
	int oldUndoMaxEtc;
	DialogStatus oldDialogStatus;
	string[MenuID] oldMnemonic;
	string[MenuID] oldHotkey;
	this (Props prop) {
		this.prop = prop;
		this.oldEnginePath = prop.var.etc.enginePath;
		this.oldWallpaper = prop.var.etc.wallpaper;
		this.oldWallpaperStyle = prop.var.etc.wallpaperStyle;
		this.oldKeyCodes = prop.var.etc.standardKeyCodes;
		this.tools = prop.var.etc.outerTools;
		this.cEngines = prop.var.etc.classicEngines;
		this.eventTemplates = prop.var.etc.eventTemplates;
		this.oldIgnorePaths = prop.var.etc.ignorePaths;
		this.oldSmoothingCard = prop.var.etc.smoothingCard;
		this.oldLogicalSort = prop.var.etc.logicalSort;
		this.oldOpenHistories = prop.var.etc.openHistories;
		this.oldSearchHistories = prop.var.etc.searchHistories;
		this.oldReplaceHistories = prop.var.etc.replaceHistories;
		this.oldUndoMaxMainView = prop.var.etc.undoMaxMainView;
		this.oldUndoMaxEvent = prop.var.etc.undoMaxEvent;
		this.oldUndoMaxReplace = prop.var.etc.undoMaxReplace;
		this.oldUndoMaxEtc = prop.var.etc.undoMaxEtc;
		this.oldDialogStatus = prop.var.etc.dialogStatus;
		foreach (id; EnumMembers!MenuID) {
			if (isNoKeyBindMenu(id)) continue;
			oldMnemonic[id] = prop.var.menu.mnemonic(id);
			oldHotkey[id] = prop.var.menu.hotkey(id);
		}
	}
	void raiseEvent(Commons comm) {
		bool refSkin = false;
		if (comm.summary && oldEnginePath != prop.var.etc.enginePath) {
			refSkin = true;
		}
		if (oldWallpaper != prop.var.etc.wallpaper || oldWallpaperStyle != prop.var.etc.wallpaperStyle) {
			if (oldWallpaper != prop.var.etc.wallpaper) {
				comm.refreshWallpaper(prop);
			}
			comm.refWallpaper.call();
		}
		if (oldKeyCodes != prop.var.etc.standardKeyCodes) {
			comm.refStandardKeyCodes.call();
		}
		if (tools != prop.var.etc.outerTools) {
			comm.refOuterTools.call();
		}
		if (cEngines != prop.var.etc.classicEngines) {
			refSkin = true;
		}
		if (eventTemplates != prop.var.etc.eventTemplates) {
			comm.refEventTemplates.call();
		}
		if (oldIgnorePaths != prop.var.etc.ignorePaths) {
			comm.refIgnorePaths.call();
		}
		if (oldSmoothingCard != prop.var.etc.smoothingCard) {
			comm.refCardState.call();
		}
		if (oldLogicalSort != prop.var.etc.logicalSort) {
			if (comm.summary) {
				if (prop.var.etc.logicalSort) {
					comm.summary.flagDirRoot.sorter = (string a, string b) {
						return ncmp(a, b);
					};
				} else {
					comm.summary.flagDirRoot.sorter = (string a, string b) {
						return cmp(a, b);
					};
				}
			}
			comm.refSortCondition.call();
		}
		if (refSkin) {
			comm.skin = findSkin(comm, prop, comm.summary, false);
			comm.refSkin.call();
		}
		comm.refClassicSkin.call();
		if (oldOpenHistories != prop.var.etc.openHistories) {
			comm.refHistories.call();
		}
		if (oldSearchHistories != prop.var.etc.searchHistories || oldReplaceHistories != prop.var.etc.replaceHistories) {
			comm.refSearchHistories.call();
		}
		if (oldUndoMaxMainView != prop.var.etc.undoMaxMainView
				|| oldUndoMaxEvent != prop.var.etc.undoMaxEvent
				|| oldUndoMaxReplace != prop.var.etc.undoMaxReplace
				|| oldUndoMaxEtc != prop.var.etc.undoMaxEtc) {
			comm.refUndoMax.call();
		}
		if (oldDialogStatus != prop.var.etc.dialogStatus) {
			comm.refContentText.call();
		}
		foreach (id; EnumMembers!MenuID) {
			if (isNoKeyBindMenu(id)) continue;
			if (oldMnemonic[id] != prop.var.menu.mnemonic(id) || oldHotkey[id] != prop.var.menu.hotkey(id)) {
				comm.refMenu.call(id);
			}
		}
	}
}

class DefBgImgDialog : AbsDialog {
private:
	Commons _comm;
	Props _prop;

	BgImageContainer _cont;
	BgImagesView _view;

public:
	this (Commons comm, Props prop, Shell shell, BgImageS[] bgImagesDefault) {
		super(prop, shell, false, prop.msgs.dlgTitBgImagesDefault,
			prop.images.menu(MenuID.Settings), true, prop.var.bgImagesDlg, true);
		_comm = comm;
		_prop = prop;

		BgImage[] bgImages;
		auto skin = _comm.skin;
		_cont = new BgImageContainer(createBgImages(skin, bgImagesDefault));
	}

	@property
	BgImageS[] backs() {return createBgImageSs(_cont.backs);}
protected:
	override void setup(Composite area) {
		area.setLayout(new GridLayout(1, false));
		{
			_view = createBgImagesViewAndMenu(_comm, _prop, null, _cont, area, null);
			mod(_view);
			_view.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
	}

	override bool apply() {
		return true;
	}
}
