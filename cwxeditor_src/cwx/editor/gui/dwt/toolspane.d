
module cwx.editor.gui.dwt.toolspane;

import cwx.cab;
import cwx.features;
import cwx.menu;
import cwx.settings;
import cwx.skin;
import cwx.structs;
import cwx.types;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.loader;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

static import std.algorithm;
import std.array;
import std.ascii;
import std.exception;
import std.file;
import std.functional;
import std.path;
import std.range : iota;
import std.string;
import std.traits;

import org.eclipse.swt.all;

import java.lang.all;

class ToolsPane(T) : Composite {
private:
	class UndoU : Undo {
		private T[] _old;
		private int _selected;
		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			static if (is(typeof(_array[0].dup))) {
				_old = [];
				foreach (a; _array) { mixin(S_TRACE);
					_old ~= a.dup;
				}
			} else { mixin(S_TRACE);
				_old = _array.dup;
			}
			_selected = _list.getSelectionIndex();
		}
		private void impl() { mixin(S_TRACE);
			auto old = _old;
			auto sels = _selected;
			save();
			_list.setRedraw(false);
			scope (exit) _list.setRedraw(true);
			_array = old;
			_list.removeAll();
			foreach (o; old) { mixin(S_TRACE);
				_list.add(createName(o));
			}
			_list.select(sels);
			_list.showSelection();
			selected();
			_applyEnabled();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	void store() { mixin(S_TRACE);
		_undo ~= new UndoU;
	}

	KeyDownFilter _kdFilter;

	Commons _comm;
	Props _prop;
	UndoManager _undo;
	void delegate(bool) _ignoreMod;
	bool delegate() _catchMod;
	void delegate() _applyEnabled;

	List _list;
	T[] _array;
	Text _name;
	bool _canApply = false;
	bool _altEnabled = false;
	int _lastSelected = -1;
	static if (is(T:BgImageSetting)) {
		Spinner _bgImgX;
		Spinner _bgImgY;
		Spinner _bgImgW;
		Spinner _bgImgH;
		Button _bgImgMask;
		Spinner _bgImgLayer;
	} else static if (is(T:OuterTool)) {
		Text _toolCommand;
		Button _toolCommandRef;
		Button _toolCommandDirOpen;
		Text _toolWorkDir;
		Button _toolWorkDirRef;
		Button _toolWorkDirOpen;
		Text _mnemonic;
		HotKeyField _hotkey;
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
		Text _mnemonic;
		HotKeyField _hotkey;
		Combo _skinType;

		Shell _ceNameWin;
		Button _features;
		Table _featureName;
		UndoManager _featureUndo;
		TableItem _okText;
		TableItem[Sex] _sexName;
		TableItem[Period] _periodName;
		TableItem[Nature] _natureName;
		TableItem[Makings] _makingsName;
		TableItem[ActionCardType] _actionCardName;
		void refAlt() { mixin(S_TRACE);
			if (0 < _list.getItemCount()) { mixin(S_TRACE);
				_alt.setEnabled(true);
				_altEnabled = true;
			}
			_canApply = true;
		}
		void featuresEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
			if (itm.getText(column) == newText) return;
			storeFeatures();
			itm.setText(column, newText);
			refAlt();
		}
		class UndoFeature : Undo {
			private string[] _features;
			private int[] _selected;
			this () { mixin(S_TRACE);
				save();
			}
			private void save() { mixin(S_TRACE);
				_features = [];
				foreach (itm; _featureName.getItems()) { mixin(S_TRACE);
					_features ~= itm.getText(2);
				}
				_selected = _featureName.getSelectionIndices();
			}
			private void impl() { mixin(S_TRACE);
				auto features = _features.dup;
				auto selected = _selected.dup;
				save();
				_featureName.setRedraw(false);
				scope (exit) _featureName.setRedraw(true);
				foreach (i, itm; _featureName.getItems()) { mixin(S_TRACE);
					itm.setText(2, features[i]);
				}
				_featureName.deselectAll();
				_featureName.select(selected);
				_featureName.showSelection();
				_comm.refreshToolBar();
			}
			void undo() { impl(); }
			void redo() { impl(); }
			override void dispose() { mixin(S_TRACE);
				// Nothing
			}
		}
		void storeFeatures() { mixin(S_TRACE);
			_featureUndo ~= new UndoFeature;
		}
		void undoFeatures() { mixin(S_TRACE);
			_featureUndo.undo();
		}
		void redoFeatures() { mixin(S_TRACE);
			_featureUndo.redo();
		}
		class FTCPD : TCPD {
			void cut(SelectionEvent e) { mixin(S_TRACE);
				copy(e);
				del(e);
			}
			private string copyImpl() { mixin(S_TRACE);
				auto indices = _featureName.getSelectionIndices();
				std.algorithm.sort(indices);
				if (!indices.length) return [];
				string text;
				int i = 0;
				foreach (sel; indices[0] .. indices[$ - 1] + 1) { mixin(S_TRACE);
					auto itm = _featureName.getItem(sel);
					text ~= itm.getText(2);
					text ~= newline;
					i++;
				}
				return text;
			}
			void copy(SelectionEvent e) { mixin(S_TRACE);
				auto t = copyImpl();
				if (!t.length) return;
				_comm.clipboard.setContents([new ArrayWrapperString(t)], [TextTransfer.getInstance()]);
				_comm.refreshToolBar();
			}
			void paste(SelectionEvent e) { mixin(S_TRACE);
				auto a = cast(ArrayWrapperString)_comm.clipboard.getContents(TextTransfer.getInstance());
				if (!a) return;
				pasteImpl(a.array);
			}
			void pasteImpl(in char[] array) { mixin(S_TRACE);
				auto indices = _featureName.getSelectionIndices();
				std.algorithm.sort(indices);
				if (!indices.length) return;
				int i = indices[0];
				auto linesu = array.splitLines();
				if (!linesu.length) return;
				storeFeatures();
				auto lines = assumeUnique(linesu);
				int[] sels;
				foreach (line; lines) { mixin(S_TRACE);
					if (_featureName.getItemCount() <= i) break;
					_featureName.getItem(i).setText(2, line);
					sels ~= i;
					i++;
				}
				_featureName.deselectAll();
				_featureName.select(sels);
				_featureName.showSelection();
				refAlt();
				_comm.refreshToolBar();
			}
			void del(SelectionEvent e) { mixin(S_TRACE);
				if(-1 == _featureName.getSelectionIndex()) return;
				storeFeatures();
				foreach (itm; _featureName.getSelection()) { mixin(S_TRACE);
					itm.setText(2, "");
				}
				refAlt();
				_comm.refreshToolBar();
			}
			void clone(SelectionEvent e) { mixin(S_TRACE);
				return;
			}
			@property
			bool canDoTCPD() { mixin(S_TRACE);
				return true;
			}
			@property
			bool canDoT() { mixin(S_TRACE);
				return -1 != _featureName.getSelectionIndex();
			}
			@property
			bool canDoC() { mixin(S_TRACE);
				return canDoT;
			}
			@property
			bool canDoP() { mixin(S_TRACE);
				return -1 != _featureName.getSelectionIndex() && CBisText(_comm.clipboard);
			}
			@property
			bool canDoD() { mixin(S_TRACE);
				return canDoT;
			}
			@property
			bool canDoClone() { mixin(S_TRACE);
				return false;
			}
		}
	} else static if (is(T:ScTemplate)) {
		Text _templPath;
		Button _templPathRef;
		Button _templPathDirOpen;
	} else static if (is(T:EvTemplate)) {
		Text _templScript;
		Text _mnemonic;
		HotKeyField _hotkey;
	} else static assert (0);

	Button _add;
	Button _alt;
	Button _del;
	Button _up;
	Button _down;
	TextMenuModify[] _tms;

	void upImpl(List list, ref T[] array) { mixin(S_TRACE);
		int i = list.getSelectionIndex();
		if (i <= 0) return;
		string tempS = list.getItem(i - 1);
		list.setItem(i - 1, list.getItem(i));
		list.setItem(i, tempS);
		auto temp = array[i - 1];
		array[i - 1] = array[i];
		array[i] = temp;
		list.select(i - 1);
		_lastSelected = i - 1;
		_applyEnabled();
		_comm.refreshToolBar();
	}
	void downImpl(T)(List list, ref T[] array) { mixin(S_TRACE);
		int i = list.getSelectionIndex();
		if (i < 0 || array.length <= i + 1) return;
		string tempS = list.getItem(i + 1);
		list.setItem(i + 1, list.getItem(i));
		list.setItem(i, tempS);
		auto temp = array[i + 1];
		array[i + 1] = array[i];
		array[i] = temp;
		list.select(i + 1);
		_lastSelected = i + 1;
		_applyEnabled();
		_comm.refreshToolBar();
	}
	void up() { mixin(S_TRACE);
		store();
		upImpl(_list, _array);
	}
	void down() { mixin(S_TRACE);
		store();
		downImpl(_list, _array);
	}

	void selected() { mixin(S_TRACE);
		_ignoreMod(true);
		scope (exit) .asyncExec(getShell().getDisplay(), { mixin(S_TRACE);
			if (getShell().isDisposed()) return;
			_canApply = false;
			_alt.setEnabled(false);
			_altEnabled = false;
			_ignoreMod(false);
		});
		int i = _list.getSelectionIndex();
		_lastSelected = i;
		_del.setEnabled(i >= 0);
		if (i >= 0) { mixin(S_TRACE);
			_name.setText(_array[i].name);
			static if (is(T:BgImageSetting)) {
				_bgImgX.setSelection(_array[i].x);
				_bgImgY.setSelection(_array[i].y);
				_bgImgW.setSelection(_array[i].width);
				_bgImgH.setSelection(_array[i].height);
				_bgImgMask.setSelection(_array[i].mask);
				_bgImgLayer.setSelection(_array[i].layer);
			} else static if (is(T:OuterTool)) {
				_toolCommand.setText(_array[i].command);
				_toolWorkDir.setText(_array[i].workDir);
				_mnemonic.setText(_array[i].mnemonic);
				_hotkey.accelerator = _array[i].hotkey;
			} else static if (is(T:ClassicEngine)) {
				_cEnginePath.setText(_array[i].enginePath);
				_cEngineDataDir.setText(_array[i].dataDirName);
				_cEngineExecute.setText(_array[i].execute);
				_mnemonic.setText(_array[i].mnemonic);
				_hotkey.accelerator = _array[i].hotkey;
				_skinType.setText(_array[i].type);

				auto n = _array[i].legacyName;
				_okText.setText(1, _prop.sys.evtChildOK(n));
				_okText.setText(2, _array[i].okText is null ? "" : _array[i].okText);
				foreach (f, itm; _sexName) { mixin(S_TRACE);
					itm.setText(1, _prop.sys.sexName(f, n));
					itm.setText(2, _array[i].sexName.get(_prop.sys.sexName(f, ""), ""));
				}
				foreach (f, itm; _periodName) { mixin(S_TRACE);
					itm.setText(1, _prop.sys.periodName(f, n));
					itm.setText(2, _array[i].periodName.get(_prop.sys.periodName(f, ""), ""));
				}
				foreach (f, itm; _natureName) { mixin(S_TRACE);
					itm.setText(1, _prop.sys.natureName(f, n));
					itm.setText(2, _array[i].natureName.get(_prop.sys.natureName(f, ""), ""));
				}
				foreach (f, itm; _makingsName) { mixin(S_TRACE);
					itm.setText(1, _prop.sys.makingsName(f, n));
					itm.setText(2, _array[i].makingsName.get(_prop.sys.makingsName(f, ""), ""));
				}
				foreach (f, itm; _actionCardName) { mixin(S_TRACE);
					itm.setText(1, _prop.sys.actionCardName(f, n));
					itm.setText(2, _array[i].actionCardName.get(f, ""));
				}
				_featureUndo.reset();
			} else static if (is(T:ScTemplate)) {
				_templPath.setText(_array[i].path);
			} else static if (is(T:EvTemplate)) {
				_templScript.setText(_array[i].script);
				_mnemonic.setText(_array[i].mnemonic);
				_hotkey.accelerator = _array[i].hotkey;
			} else static assert (0);
		} else { mixin(S_TRACE);
			_name.setText("");
			static if (is(T:BgImageSetting)) {
				_bgImgX.setSelection(0);
				_bgImgY.setSelection(0);
				_bgImgW.setSelection(0);
				_bgImgH.setSelection(0);
				_bgImgMask.setSelection(false);
				_bgImgLayer.setSelection(LAYER_BACK_CELL);
			} else static if (is(T:OuterTool)) {
				_toolCommand.setText("");
				_toolWorkDir.setText("");
				_mnemonic.setText("");
				_hotkey.accelerator = "";
			} else static if (is(T:ClassicEngine)) {
				_cEnginePath.setText("");
				_cEngineDataDir.setText("");
				_cEngineExecute.setText("");
				_mnemonic.setText("");
				_hotkey.accelerator = "";
				_skinType.setText("");
			} else static if (is(T:ScTemplate)) {
				_templPath.setText("");
			} else static if (is(T:EvTemplate)) {
				_templScript.setText("");
				_mnemonic.setText("");
				_hotkey.accelerator = "";
			} else static assert (0);
		}
		_alt.setEnabled(false);
		_altEnabled = false;
		_canApply = false;
		foreach (tm; _tms) { mixin(S_TRACE);
			tm.reset();
		}
		_comm.refreshToolBar();
	}

	void add(T t) { mixin(S_TRACE);
		store();
		int index = _list.getItemCount();
		_array ~= t;
		_list.add(createName(t));
		_list.select(index);
		selected();
		_applyEnabled();
		_list.showSelection();
		_list.redraw();
		_comm.refreshToolBar();
	}
	void create() { mixin(S_TRACE);
		if (!checkData()) return;
		string name = _name.getText();
		static if (is(T:BgImageSetting)) {
			int x = _bgImgX.getSelection();
			int y = _bgImgY.getSelection();
			int w = _bgImgW.getSelection();
			int h = _bgImgH.getSelection();
			bool mask = _bgImgMask.getSelection();
			int layer = _bgImgLayer.getSelection();
			add(BgImageSetting(name, x, y, w, h, mask, layer));
		} else static if (is(T:OuterTool)) {
			string commnad = _toolCommand.getText();
			string workDir = _toolWorkDir.getText();
			string mnemonic = _mnemonic.getText();
			string hotkey = _hotkey.acceleratorText();
			add(OuterTool(name, commnad, workDir, mnemonic, hotkey));
		} else static if (is(T:ClassicEngine)) {
			string path = _cEnginePath.getText();
			string dataDir = _cEngineDataDir.getText();
			string execute = _cEngineExecute.getText();
			string mnemonic = _mnemonic.getText();
			string hotkey = _hotkey.acceleratorText();
			string skinType = _skinType.getText();
			auto ce = ClassicEngine(name, path, dataDir, execute, mnemonic, hotkey, skinType);
			putFeatures(ce);
			add(ce);
		} else static if (is(T:ScTemplate)) {
			string path = _templPath.getText();
			add(ScTemplate(name, path));
		} else static if (is(T:EvTemplate)) {
			string script = _templScript.getText().wrapReturnCode();
			string mnemonic = _mnemonic.getText();
			string hotkey = _hotkey.acceleratorText();
			add(EvTemplate(name, script, mnemonic, hotkey));
		} else static assert (0);
	}
	void alt() { mixin(S_TRACE);
		int i = _lastSelected;
		if (-1 == i) return;
		if (!checkData()) return;
		store();
		_array[i].name = _name.getText();
		static if (is(T:BgImageSetting)) {
			_array[i].x = _bgImgX.getSelection();
			_array[i].y = _bgImgY.getSelection();
			_array[i].width = _bgImgW.getSelection();
			_array[i].height = _bgImgH.getSelection();
			_array[i].mask = _bgImgMask.getSelection();
			_array[i].layer = _bgImgLayer.getSelection();
		} else static if (is(T:OuterTool)) {
			_array[i].command = _toolCommand.getText();
			_array[i].workDir = _toolWorkDir.getText();
			_array[i].mnemonic = _mnemonic.getText();
			_array[i].hotkey = _hotkey.acceleratorText();
		} else static if (is(T:ClassicEngine)) {
			_array[i].enginePath = _cEnginePath.getText();
			_array[i].dataDirName = _cEngineDataDir.getText();
			_array[i].execute = _cEngineExecute.getText();
			_array[i].mnemonic = _mnemonic.getText();
			_array[i].hotkey = _hotkey.acceleratorText();
			_array[i].type = _skinType.getText();
			putFeatures(_array[i]);
		} else static if (is(T:ScTemplate)) {
			_array[i].path = _templPath.getText();
		} else static if (is(T:EvTemplate)) {
			_array[i].script = .wrapReturnCode(_templScript.getText());
			_array[i].mnemonic = _mnemonic.getText();
			_array[i].hotkey = _hotkey.acceleratorText();
		} else static assert (0);
		_list.setItem(i, createName(_array[i]));
		_alt.setEnabled(false);
		_altEnabled = false;
		_canApply = false;
		_applyEnabled();
		_list.showSelection();
		_list.redraw();
		_comm.refreshToolBar();
	}
	static if (is(T:ClassicEngine)) {
		void putFeatures(ref ClassicEngine ce) { mixin(S_TRACE);
			ce.clearFeatures();
			auto emptySkin = new Skin(_prop.parent, "");
			if (_okText.getText(2).length) ce.okText = _okText.getText(2);
			foreach (f; emptySkin.allSexes) { mixin(S_TRACE);
				auto t = _sexName[f].getText(2);
				if (t.length) ce.sexName[_prop.sys.sexName(f, "")] = t;
			}
			foreach (f; emptySkin.allPeriods) { mixin(S_TRACE);
				auto t = _periodName[f].getText(2);
				if (t.length) ce.periodName[_prop.sys.periodName(f, "")] = t;
			}
			foreach (f; emptySkin.allNatures) { mixin(S_TRACE);
				auto t = _natureName[f].getText(2);
				if (t.length) ce.natureName[_prop.sys.natureName(f, "")] = t;
			}
			foreach (Makings f; emptySkin.leftMakings) { mixin(S_TRACE);
				auto t = _makingsName[f].getText(2);
				if (t.length) ce.makingsName[_prop.sys.makingsName(f, "")] = t;
				f = emptySkin.reverseMakings(f);
				t = _makingsName[f].getText(2);
				if (t.length) ce.makingsName[_prop.sys.makingsName(f, "")] = t;
			}
			foreach (f; EnumMembers!ActionCardType) { mixin(S_TRACE);
				auto t = _actionCardName[f].getText(2);
				if (t.length) ce.actionCardName[f] = t;
			}
		}
	}
	void del() { mixin(S_TRACE);
		int i = _list.getSelectionIndex();
		if (i < 0) return;
		store();
		_list.remove(i);
		_array = _array[0 .. i] ~ _array[i + 1 .. $];
		if (_array.length > 0) { mixin(S_TRACE);
			_list.select(i < _array.length ? i : cast(int)_array.length - 1);
		}
		selected();
		_list.showSelection();
		_list.redraw();
		_applyEnabled();
		_comm.refreshToolBar();
	}

	class UTCPD : TCPD {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			int i = _list.getSelectionIndex();
			if (i < 0) return;
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			int i = _list.getSelectionIndex();
			if (i < 0) return;
			XMLtoCB(_prop, _comm.clipboard, _array[i].toNode().text);
			_comm.refreshToolBar();
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					if (node.name == T.XML_NAME) { mixin(S_TRACE);
						T t;
						t.fromNode(node);
						add(t);
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			this.outer.del();
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		bool canDoTCPD() { mixin(S_TRACE);
			return true;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return _list.getSelectionIndex() >= 0;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return canDoC;
		}
	}
	/// ここでfalseを返した場合は不正なデータと見做す。現在未使用。
	bool checkData() { return true; }
	void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxEtc;
	}

	Spinner createS(Composite parent, string name, int max, int min, string hint = "") { mixin(S_TRACE);
		auto l = new Label(parent, SWT.NONE);
		l.setText(name);
		auto spn = new Spinner(parent, SWT.BORDER);
		initSpinner(spn);
		spn.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		spn.setMaximum(max);
		spn.setMinimum(min);
		spn.setSelection(0);
		if (hint != "") { mixin(S_TRACE);
			auto l2 = new Label(parent, SWT.NONE);
			l2.setText(hint);
		}
		return spn;
	}
	void modB(C)(Button button, List list, C ctrl, ref bool flag) { mixin(S_TRACE);
		static if (is(C:Button)) {
			ctrl.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
					if (!_catchMod()) return;
					if (0 < list.getItemCount()) { mixin(S_TRACE);
						button.setEnabled(enabled);
					}
					flag = true;
				}
			});
		} else { mixin(S_TRACE);
			ctrl.addModifyListener(new class ModifyListener {
				override void modifyText(ModifyEvent e) { mixin(S_TRACE);
					if (!_catchMod()) return;
					if (0 < list.getItemCount()) { mixin(S_TRACE);
						button.setEnabled(enabled);
					}
					flag = true;
				}
			});
		}
	}

	class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is getShell()) return;
			if (isDescendant(this.outer, c)) { mixin(S_TRACE);
				if (c.getMenu() && findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
				if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					_undo.undo();
					e.doit = false;
				} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					_undo.redo();
					e.doit = false;
				}
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	void refMenu(MenuID id) { mixin(S_TRACE);
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}

	static if (is(T:OuterTool) || is(T:ClassicEngine) || is(T:EvTemplate)) {
		SplitPane _shortcutSash;
		string createName(ref const T t) { mixin(S_TRACE);
			return MenuProps.buildMenuSample(t.name, t.mnemonic, t.hotkey, false);
		}
		void setupShortcut(Composite parent) { mixin(S_TRACE);
			auto l1 = new Label(parent, SWT.NONE);
			l1.setText(_prop.msgs.mnemonic);

			_shortcutSash = new SplitPane(parent, SWT.HORIZONTAL);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 3;
			_shortcutSash.setLayoutData(gd);
			_mnemonic = mnemonicText(_shortcutSash, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _mnemonic, _catchMod);
			auto hotkeyComp = new Composite(_shortcutSash, SWT.NONE);
			hotkeyComp.setLayout(zeroMarginGridLayout(3, false));
			auto l2 = new Label(hotkeyComp, SWT.NONE);
			l2.setText(_prop.msgs.hotkey);
			_hotkey = new HotKeyField(hotkeyComp, SWT.BORDER);
			createTextMenu!Text(_comm, _prop, _hotkey.widget, _catchMod);
			_hotkey.widget.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			auto del = new Button(hotkeyComp, SWT.PUSH);
			del.setText(_prop.msgs.sDel);
			listener(del, SWT.Selection, { mixin(S_TRACE);
				_mnemonic.setText("");
				_hotkey.accelerator = "";
			});
		}
	} else {
		string createName(ref const T t) { mixin(S_TRACE);
			return t.name;
		}
	}
	static if (is(T:BgImageSetting)) {
		void setupRight(Composite parent) { mixin(S_TRACE);
			auto comp3 = new Composite(parent, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 5;
			comp3.setLayoutData(gd);
			comp3.setLayout(zeroMarginGridLayout(2, false));
			_name = new Text(comp3, SWT.BORDER);
			_tms ~= createTextMenu!Text(_comm, _prop, _name, _catchMod);
			_name.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_bgImgMask = new Button(comp3, SWT.TOGGLE);
			_bgImgMask.setImage(_prop.images.menu(MenuID.Mask));
			_bgImgMask.setToolTipText(_prop.msgs.menuText(MenuID.Mask));

			auto pComp = new Composite(parent, SWT.NONE);
			auto pgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			pgd.horizontalSpan = 4;
			pComp.setLayoutData(pgd);
			pComp.setLayout(zeroMarginGridLayout(8, false));
			_bgImgX = createS(pComp, _prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int)_prop.var.etc.posLeftMax));
			_bgImgY = createS(pComp, _prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int)_prop.var.etc.posTopMax));
			_bgImgW = createS(pComp, _prop.msgs.width, _prop.var.etc.backWidthMax, 0);
			_bgImgH = createS(pComp, _prop.msgs.height, _prop.var.etc.backHeightMax, 0);

			auto lComp = new Composite(parent, SWT.NONE);
			auto lgd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			lgd.horizontalSpan = 4;
			lComp.setLayoutData(lgd);
			lComp.setLayout(zeroMarginGridLayout(3, false));
			_bgImgLayer = createS(lComp, _prop.msgs.layer, _prop.var.etc.layerMax, LAYER_BACK_CELL, .tryFormat(_prop.msgs.layerHint, LAYER_BACK_CELL));
		}
	} else static if (is(T:OuterTool)) {
		void selectProgram() { mixin(S_TRACE);
			string[] desc;
			string[] ext;
			version (Windows) {
				desc = [_prop.msgs.exeFileDescExe, _prop.msgs.exeFileDescAll];
				ext = ["*.exe", "*.*"];
			} else { mixin(S_TRACE);
				desc = [_prop.msgs.exeFileDescAll];
				ext = ["*.*"];
			}
			selectFile(_toolCommand, desc, ext, "", _prop.msgs.dlgTitOuterTool, _toolCommand.getText());
		}
		void selectWorkDir() { mixin(S_TRACE);
			selectDir(_prop, _toolWorkDir, _prop.msgs.toolWorkDir, _prop.msgs.toolWorkDirDesc, _toolWorkDir.getText());
		}
		void setupRight(Composite parent) { mixin(S_TRACE);
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.outerToolName);
				_name = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _name, _catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				_name.setLayoutData(gd);
			}
			setupShortcut(parent);
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.outerToolCommand);
				_toolCommand = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _toolCommand, _catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = 0;
				_toolCommand.setLayoutData(gd);
				_toolCommandRef = new Button(parent, SWT.PUSH);
				_toolCommandRef.setText(_prop.msgs.reference);
				listener(_toolCommandRef, SWT.Selection, &selectProgram);
				_toolCommandDirOpen = createOpenButton(_comm, parent, &_toolCommand.getText, false);
				setupDropFile(_toolCommand, _toolCommand, toDelegate(&dropDefault));
			}
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.outerToolWorkDir);
				_toolWorkDir = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _toolWorkDir, _catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = 0;
				_toolWorkDir.setLayoutData(gd);
				_toolWorkDirRef = new Button(parent, SWT.PUSH);
				_toolWorkDirRef.setText(_prop.msgs.reference);
					listener(_toolWorkDirRef, SWT.Selection, &selectWorkDir);
				_toolWorkDirOpen = createOpenButton(_comm, parent, &_toolWorkDir.getText, true);
				setupDropFile(_toolWorkDir, _toolWorkDir, toDelegate(&dropDir));
			}
			{ mixin(S_TRACE);
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
		string dropCEnginePath(string[] files) { mixin(S_TRACE);
			if (!files.length) return "";
			string file = files[0];
			if (.exists(file) && .isDir(file)) { mixin(S_TRACE);
				string resDir, lEnginePath;
				if (Skin.hasClassicEngine(file, resDir, lEnginePath, _prop.var.etc.classicEngineRegex, _prop.var.etc.classicDataDirRegex, _prop.var.etc.classicMatchKey, _array)) { mixin(S_TRACE);
					return lEnginePath;
				}
				return file;
			}
			return file;
		}
		@property
		string curCEnginePath() { mixin(S_TRACE);
			string path = _cEnginePath.getText();
			if (!path.length) return path;
			if (isAbsolute(path)) return path;
			return std.path.buildPath(nabs(_prop.parent.appPath).dirName(), path);
		}
		string dropCEngineSub(string file) { mixin(S_TRACE);
			string engine = curCEnginePath;
			if (!engine.length) return file;
			return abs2rel(file, engine.dirName());
		}
		string dropCEngineDataDir(string[] files) { mixin(S_TRACE);
			return dropCEngineSub(dropDir(files));
		}
		string dropCEngineExecute(string[] files) { mixin(S_TRACE);
			return dropCEngineSub(dropDefault(files));
		}
		void selectCEnginePath() { mixin(S_TRACE);
			string[] desc;
			string[] ext;
			version (Windows) {
				desc = [_prop.msgs.exeFileDescExe, _prop.msgs.exeFileDescAll];
				ext = ["*.exe", "*.*"];
			} else { mixin(S_TRACE);
				desc = [_prop.msgs.exeFileDescAll];
				ext = ["*.*"];
			}
			string fname = selectFile(_cEnginePath, desc, ext, "", _prop.msgs.dlgTitClassicEnginePath, _cEnginePath.getText());
			if (fname) { mixin(S_TRACE);
				dropCEnginePath(fname);
			}
		}
		void dropCEnginePath(string path) { mixin(S_TRACE);
			string resDir = Skin.findResDir(path.dirName(), _prop.var.etc.classicDataDirRegex,  _prop.var.etc.classicMatchKey);
			if (resDir.length) { mixin(S_TRACE);
				_cEngineDataDir.setText(resDir);
			}
		}
		void selectCEngineDataDir() { mixin(S_TRACE);
			string path = _cEngineDataDir.getText();
			if (_cEnginePath.getText().length && !isAbsolute(path)) { mixin(S_TRACE);
				path = std.path.buildPath(_cEnginePath.getText().dirName(), path);
			}
			path = nabs(path);
			string fname = selectDir(_prop, _cEngineDataDir, _prop.msgs.classicEngineDataDirName, _prop.msgs.classicEngineDataDirNameDesc, path, false);
			if (fname) { mixin(S_TRACE);
				fname = dropCEngineSub(fname);
				_cEngineDataDir.setText(fname);
			}
		}
		void selectCEngineExecute() { mixin(S_TRACE);
			string[] desc;
			string[] ext;
			version (Windows) {
				desc = [_prop.msgs.exeFileDescExe, _prop.msgs.exeFileDescAll];
				ext = ["*.exe", "*.*"];
			} else { mixin(S_TRACE);
				desc = [_prop.msgs.exeFileDescAll];
				ext = ["*.*"];
			}
			string path = _cEngineExecute.getText();
			string fileName = "";
			if (path.length) { mixin(S_TRACE);
				fileName = path.baseName();
				if (_cEnginePath.getText().length && !isAbsolute(path)) { mixin(S_TRACE);
					path = std.path.buildPath(_cEnginePath.getText().dirName(), path);
				}
			} else { mixin(S_TRACE);
				path = std.path.buildPath(_cEnginePath.getText().dirName(), "*.exe");
			}
			path = nabs(path);
			string fname = selectFile(_cEngineExecute, desc, ext, fileName, _prop.msgs.dlgTitClassicEngineExecute, path);
			if (fname) { mixin(S_TRACE);
				fname = dropCEngineSub(fname);
				_cEngineExecute.setText(fname);
			}
		}
		private class CEOpenDir : SelectionAdapter {
			private Text _text;
			this (Text text) { mixin(S_TRACE);
				_text = text;
			}
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				string file = _text.getText();
				if (!isAbsolute(file)) { mixin(S_TRACE);
					auto engine = curCEnginePath;
					if (engine.length) { mixin(S_TRACE);
						file = std.path.buildPath(engine.dirName(), file);
					}
				}
				if (!.exists(file) || !isDir(file)) { mixin(S_TRACE);
					file = file.dirName();
				}
				if (!.exists(file)) return;
				openFolder(file);
			}
		}
		Button createCEngineSubOpenButton(Composite parent, Text path, bool dir) { mixin(S_TRACE);
			auto open = new Button(parent, SWT.PUSH);
			open.setToolTipText(_prop.msgs.menuText(dir ? MenuID.OpenDir : MenuID.OpenPlace));
			open.setImage(_prop.images.menu(MenuID.OpenDir));
			open.addSelectionListener(new CEOpenDir(path));
			return open;
		}
		void setupRight(Composite parent) { mixin(S_TRACE);
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.classicEngineName);

				auto sash = new SplitPane(parent, SWT.HORIZONTAL);

				_name = new Text(sash, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _name, _catchMod);

				auto typeComp = new Composite(sash, SWT.NONE);
				typeComp.setLayout(zeroMarginGridLayout(2, false));
				auto lt = new Label(typeComp, SWT.NONE);
				lt.setText(_prop.msgs.type);
				_skinType = new Combo(typeComp, SWT.DROP_DOWN | SWT.BORDER);
				_skinType.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				.createTextMenu!Combo(_comm, _prop, _skinType, _catchMod);
				_skinType.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				void refSkinsImpl() { mixin(S_TRACE);
					.setComboItems(_skinType, .findSkinTypes(_comm.prop));
				}
				void refSkins() { mixin(S_TRACE);
					_ignoreMod(true);
					scope (exit) .asyncExec(getShell().getDisplay(), { mixin(S_TRACE);
						if (getShell().isDisposed()) return;
						_ignoreMod(false);
					});
					auto t = _skinType.getText();
					refSkinsImpl();
					_skinType.setText(t);
				}
				refSkinsImpl();
				_comm.refSkin.add(&refSkins);
				_comm.refSortCondition.add(&refSkins);
				_comm.refClassicSkin.add(&refSkins);
				_comm.refSettingsWithSkinTypes.add(&refSkins);
				.listener(_skinType, SWT.Dispose, { mixin(S_TRACE);
					_comm.refSkin.remove(&refSkins);
					_comm.refSortCondition.remove(&refSkins);
					_comm.refClassicSkin.remove(&refSkins);
					_comm.refSettingsWithSkinTypes.remove(&refSkins);
				});

				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				sash.setLayoutData(gd);
				.setupWeights(sash, _prop.var.etc.classicEnginesNameTypeSashL, _prop.var.etc.classicEnginesNameTypeSashR);
			}
			setupShortcut(parent);
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.classicEnginePath);
				_cEnginePath = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _cEnginePath, _catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = 0;
				_cEnginePath.setLayoutData(gd);
				_cEnginePathRef = new Button(parent, SWT.PUSH);
				_cEnginePathRef.setText(_prop.msgs.reference);
				listener(_cEnginePathRef, SWT.Selection, &selectCEnginePath);
				_cEnginePathDirOpen = createOpenButton(_comm, parent, &_cEnginePath.getText, false);
				setupDropFile(_cEnginePath, _cEnginePath, &dropCEnginePath, &dropCEnginePath);
			}
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.classicEngineDataDirName);
				_cEngineDataDir = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _cEngineDataDir, _catchMod);
				_cEngineDataDir.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

				_cEngineDataDirRef = new Button(parent, SWT.PUSH);
				_cEngineDataDirRef.setText(_prop.msgs.reference);
				listener(_cEngineDataDirRef, SWT.Selection, &selectCEngineDataDir);
				_cEngineDataDirOpen = createCEngineSubOpenButton(parent, _cEngineDataDir, true);
				setupDropFile(_cEngineDataDir, _cEngineDataDir, &dropCEngineDataDir);
			}
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.classicEngineExecute);
				_cEngineExecute = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _cEngineExecute, _catchMod);
				_cEngineExecute.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

				_cEngineExecuteRef = new Button(parent, SWT.PUSH);
				_cEngineExecuteRef.setText(_prop.msgs.reference);
				listener(_cEngineExecuteRef, SWT.Selection, &selectCEngineExecute);
				_cEngineExecuteDirOpen = createCEngineSubOpenButton(parent, _cEngineExecute, true);
				setupDropFile(_cEngineExecute, _cEngineExecute, &dropCEngineExecute);
			}
			{ mixin(S_TRACE);
				auto hint1 = new Label(parent, SWT.NONE);
				hint1.setText(_prop.msgs.classicEngineHint1);
				auto gd1 = new GridData;
				gd1.horizontalSpan = 4;
				hint1.setLayoutData(gd1);
			}
		}
	} else static if (is(T:ScTemplate)) {
		string dropTemplate(string[] files) { mixin(S_TRACE);
			if (!files.length) return "";
			string file = files[0];
			if (.isDir(file)) return file;
			auto bn = file.baseName();
			if (cfnmatch(bn, "Summary.wsm") || cfnmatch(bn, "Summary.xml")) { mixin(S_TRACE);
				return file;
			}
			auto ext = .extension(bn);
			if (cfnmatch(ext, ".zip") || cfnmatch(ext, ".wsn") || cfnmatch(ext, ".lzh") || cfnmatch(ext, ".lha") || (cfnmatch(ext, ".cab") && canUncab)) { mixin(S_TRACE);
				return file;
			}
			return "";
		}
		void selectTemplate() { mixin(S_TRACE);
			string[] desc = scenarioFilterDesc(_prop);
			string[] ext = scenarioFilter;
			selectFile(_templPath, desc, ext, "", _prop.msgs.dlgTitScTemplate, _templPath.getText());
		}
		void setupRight(Composite parent) { mixin(S_TRACE);
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.scenarioTemplateName);
				_name = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _name, _catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				_name.setLayoutData(gd);
			}
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.scenarioTemplatePath);
				_templPath = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _templPath, _catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = 0;
				_templPath.setLayoutData(gd);
				_templPathRef = new Button(parent, SWT.PUSH);
				_templPathRef.setText(_prop.msgs.reference);
				listener(_templPathRef, SWT.Selection, &selectTemplate);
				_templPathDirOpen = createOpenButton(_comm, parent, &_templPath.getText, false);
				setupDropFile(_templPath, _templPath, &dropTemplate);
			}
		}
	} else static if (is(T:EvTemplate)) {
		void setupRight(Composite parent) { mixin(S_TRACE);
			parent.setLayoutData(new GridData(GridData.FILL_BOTH));
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.eventTemplateName);
				_name = new Text(parent, SWT.BORDER);
				_tms ~= createTextMenu!Text(_comm, _prop, _name, _catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				_name.setLayoutData(gd);
			}
			setupShortcut(parent);
			{ mixin(S_TRACE);
				auto l = new Label(parent, SWT.NONE);
				l.setText(_prop.msgs.eventTemplateScript);
				_templScript = new Text(parent, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.H_SCROLL | SWT.V_SCROLL);
				_tms ~= createTextMenu!Text(_comm, _prop, _templScript, _catchMod);
				_templScript.setTabs(_prop.var.etc.tabs);
				auto gd = new GridData(GridData.FILL_BOTH);
				gd.widthHint = 0;
				gd.horizontalSpan = 3;
				_templScript.setLayoutData(gd);

				auto font = _templScript.getFont();
				auto fSize = font ? cast(uint)font.getFontData()[0].height : 0;
				auto font2 = new Font(Display.getCurrent(), dwtData(CFont(_prop.looks.monospace, fSize, false, false)));
				_templScript.setFont(font2);
				listener(_templScript, SWT.Dispose, { mixin(S_TRACE);
					font2.dispose();
				});
			}
			{ mixin(S_TRACE);
				void putDummy() { mixin(S_TRACE);
					auto dummy1 = new Composite(parent, SWT.NONE);
					auto dgd1 = new GridData;
					dgd1.widthHint = 0;
					dgd1.heightHint = 0;
					dummy1.setLayoutData(dgd1);
				}
				putDummy();
				auto hint1 = new Label(parent, SWT.WRAP);
				hint1.setText(_prop.msgs.eventTemplateHint1);
				auto gd1 = new GridData(GridData.FILL_HORIZONTAL);
				gd1.widthHint = 0;
				gd1.horizontalSpan = 3;
				hint1.setLayoutData(gd1);

				putDummy();
				auto hint2 = new Text(parent, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.READ_ONLY);
				hint2.setText(_prop.msgs.eventTemplateHint2);
				createTextMenu!Text(_comm, _prop, hint2, _catchMod);
				auto gd2 = new GridData(GridData.FILL_HORIZONTAL);
				gd2.widthHint = 0;
				gd2.horizontalSpan = 3;
				hint2.setLayoutData(gd2);
			}
		}
	} else static assert (0);
public:
	this (Commons comm, void delegate(bool) ignoreMod, bool delegate() catchMod, void delegate() applyEnabled, Composite parent, int style) { mixin(S_TRACE);
		super (parent, style);
		_comm = comm;
		_prop = comm.prop;
		_ignoreMod = ignoreMod;
		_applyEnabled = applyEnabled;
		_catchMod = catchMod;
		_undo = new UndoManager(_prop.var.etc.undoMaxEtc);
	}

	void setup(T[] array, ref Prop!(int, false) sashL, ref Prop!(int, false) sashR) { mixin(S_TRACE);
		this.setLayout(zeroMarginGridLayout(1, true));

		auto grp = new Group(this, SWT.NONE);
		grp.setLayoutData(new GridData(GridData.FILL_BOTH));
		grp.setLayout(normalGridLayout(1, true));
		grp.setText(boxName);
		auto leftSash = new SplitPane(grp, SWT.HORIZONTAL);
		leftSash.setLayoutData(new GridData(GridData.FILL_BOTH));
		{ mixin(S_TRACE);
			auto left = new Composite(leftSash, SWT.NONE);
			left.setLayout(zeroMarginGridLayout(2, true));
			_list = new List(left, SWT.BORDER | SWT.SINGLE | SWT.V_SCROLL);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.settingListWidth;
			gd.heightHint = _prop.var.etc.settingListHeight;
			gd.horizontalSpan = 2;
			_list.setLayoutData(gd);
			listener(_list, SWT.Selection, { mixin(S_TRACE);
				if (_list.getSelectionIndex() == _lastSelected) return;
				if (_canApply && _lastSelected != -1) { mixin(S_TRACE);
					auto dlg = new MessageBox(getShell(), SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
					dlg.setText(_prop.msgs.dlgTitQuestion);
					auto name = _name.getText();
					if (name == "") name = _prop.msgs.noNameData;
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgForceApplySelection, name));
					final switch (dlg.open()) {
					case SWT.YES:
						forceApply();
						break;
					case SWT.NO:
						break;
					case SWT.CANCEL:
						_list.select(_lastSelected);
						return;
					}
				}
				selected();
			});

			auto menu = new Menu(_list);
			createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Up, &up, &canUp);
			createMenuItem(_comm, menu, MenuID.Down, &down, &canDown);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, new UTCPD, true, true, true, true, true);
			_list.setMenu(menu);

			_up = new Button(left, SWT.PUSH);
			_up.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_up.setText(_prop.msgs.upSelection);
			_up.setImage(_prop.images.menu(MenuID.Up));
			listener(_up, SWT.Selection, &this.up);
			_comm.put(_up, &canUp);
			_down = new Button(left, SWT.PUSH);
			_down.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_down.setText(_prop.msgs.downSelection);
			_down.setImage(_prop.images.menu(MenuID.Down));
			listener(_down, SWT.Selection, &this.down);
			_comm.put(_down, &canDown);
		}

		auto right = new Composite(leftSash, SWT.NONE);
		right.setLayout(zeroMarginGridLayout(2, false));
		{ mixin(S_TRACE);
			auto comp2 = new Composite(right, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			comp2.setLayoutData(gd);
			comp2.setLayout(zeroMarginGridLayout(4, false));
			setupRight(comp2);
		}
		static if (is(T:ClassicEngine)) {
			_features = new Button(right, SWT.TOGGLE);
			_features.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING));
			_features.setText(_prop.msgs.featureName);
		}
		{ mixin(S_TRACE);
			auto buttons = new Composite(right, SWT.NONE);
			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			static if (!is(T:ClassicEngine)) {
				gd.horizontalSpan = 2;
			}
			buttons.setLayoutData(gd);
			buttons.setLayout(zeroMarginGridLayout(3, true));
			_add = new Button(buttons, SWT.PUSH);
			_add.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_add.setText(_prop.msgs.sNew);
			listener(_add, SWT.Selection, &this.create);
			_alt = new Button(buttons, SWT.PUSH);
			_alt.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_alt.setText(_prop.msgs.sAlt);
			_alt.setEnabled(false);
			listener(_alt, SWT.Selection, &alt);
			_del = new Button(buttons, SWT.PUSH);
			_del.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_del.setText(_prop.msgs.sDel);
			listener(_del, SWT.Selection, &del);
		}
		static if (is(T:ClassicEngine)) {
			{ mixin(S_TRACE);
				auto emptySkin = new Skin(_prop.parent, "");
				_ceNameWin = new Shell(parent.getShell(), SWT.TITLE | SWT.RESIZE | SWT.TOOL | SWT.CLOSE);
				_ceNameWin.setLayout(new FillLayout);
				_ceNameWin.setText(_prop.msgs.dlgTitFeatureName);
				.listener(_ceNameWin, SWT.Close, (Event e) { mixin(S_TRACE);
					_ceNameWin.setVisible(false);
					_features.setSelection(false);
					e.doit = false;
				});
				_featureName = .rangeSelectableTable(_ceNameWin, SWT.FULL_SELECTION | SWT.MULTI | SWT.V_SCROLL);
				_featureUndo = new UndoManager(_prop.var.etc.undoMaxEtc);
				auto menu = new Menu(_featureName.getShell(), SWT.POP_UP);
				createMenuItem(_comm, menu, MenuID.Undo, &undoFeatures, &_featureUndo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &redoFeatures, &_featureUndo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new FTCPD, true, true, true, true, false);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.SelectAll, { mixin(S_TRACE);
					_featureName.select(iota(0, _featureName.getItemCount(), 1).array());
				}, () => _featureName.getSelection().length < _featureName.getItemCount());
				_featureName.setMenu(menu);
				_featureName.setLayoutData(new GridData(GridData.FILL_BOTH));
				_featureName.setHeaderVisible(true);
				_featureName.setLinesVisible(true);
				auto col1 = new TableColumn(_featureName, SWT.NONE);
				col1.setText(_prop.msgs.featureDefaultName);
				saveColumnWidth!("prop.var.etc.featureDefaultNameWidth")(_prop, col1);
				auto col2 = new TableColumn(_featureName, SWT.NONE);
				col2.setText(_prop.msgs.featureVariantName);
				saveColumnWidth!("prop.var.etc.featureVariantNameWidth")(_prop, col2);
				auto col3 = new TableColumn(_featureName, SWT.NONE);
				col3.setText(_prop.msgs.featureManualName);
				saveColumnWidth!("prop.var.etc.featureManualNameWidth")(_prop, col3);

				_okText = new TableItem(_featureName, SWT.NONE);
				_okText.setText(0, _prop.sys.evtChildOK(""));
				foreach (f; emptySkin.allSexes) { mixin(S_TRACE);
					auto itm = new TableItem(_featureName, SWT.NONE);
					itm.setText(0, _prop.sys.sexName(f, ""));
					_sexName[f] = itm;
				}
				foreach (f; emptySkin.allPeriods) { mixin(S_TRACE);
					auto itm = new TableItem(_featureName, SWT.NONE);
					itm.setText(0, _prop.sys.periodName(f, ""));
					_periodName[f] = itm;
				}
				foreach (f; emptySkin.allNatures) { mixin(S_TRACE);
					auto itm = new TableItem(_featureName, SWT.NONE);
					itm.setText(0, _prop.sys.natureName(f, ""));
					_natureName[f] = itm;
				}
				foreach (Makings f; emptySkin.leftMakings) { mixin(S_TRACE);
					auto itm = new TableItem(_featureName, SWT.NONE);
					itm.setText(0, _prop.sys.makingsName(f, ""));
					_makingsName[f] = itm;
					f = emptySkin.reverseMakings(f);
					auto itmR = new TableItem(_featureName, SWT.NONE);
					itmR.setText(0, _prop.sys.makingsName(f, ""));
					_makingsName[f] = itmR;
				}
				foreach (f; EnumMembers!ActionCardType) { mixin(S_TRACE);
					auto itm = new TableItem(_featureName, SWT.NONE);
					itm.setText(0, _prop.sys.actionCardName(f, ""));
					_actionCardName[f] = itm;
				}
				new TableTextEdit(_comm, _prop, _featureName, 2, &featuresEnd, null);

				auto winProps = _prop.var.featuresWin;
				auto shell = _ceNameWin;
				bool first = true;
				void resize() { mixin(S_TRACE);
					if (first) return;
					winProps.width = shell.getSize().x;
					winProps.height = shell.getSize().y;
					winProps.x = shell.getBounds().x - shell.getParent().getBounds().x;
					winProps.y = shell.getBounds().y - shell.getParent().getBounds().y;
				}
				.listener(_ceNameWin, SWT.Resize, &resize);
				.listener(_ceNameWin, SWT.Move, &resize);
				int parX, parY;
				.listener(features, SWT.Selection, { mixin(S_TRACE);
					if (first) { mixin(S_TRACE);
						first = false;
						auto pb = _ceNameWin.getParent().getBounds();
						int px = pb.x;
						int py = pb.y;
						int pw = pb.width;
						int ph = pb.height;
						parX = px;
						parY = py;

						scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
						int width = winProps.width == SWT.DEFAULT ? wp.x : winProps.width;
						int height = winProps.height == SWT.DEFAULT ? wp.y : winProps.height;
						int x = winProps.x == SWT.DEFAULT ? SWT.DEFAULT : winProps.x + shell.getParent().getBounds().x;
						int y = winProps.y == SWT.DEFAULT ? SWT.DEFAULT : winProps.y + shell.getParent().getBounds().y;
						if (SWT.DEFAULT == x) { mixin(S_TRACE);
							auto fb = features.getBounds();
							auto p = features.toDisplay(fb.x, fb.y);
							x = p.x + fb.width;
						}
						if (SWT.DEFAULT == y) { mixin(S_TRACE);
							y = py + ph - height;
						}
						intoDisplay(x, y, width, height);
						shell.setBounds(x, y, width, height);
					}

					_ceNameWin.setVisible(features.getSelection());
				});
				.listener(getShell(), SWT.Move, { mixin(S_TRACE);
					if (!getShell().isVisible()) return;
					auto pb = _ceNameWin.getParent().getBounds();
					auto tb = _ceNameWin.getBounds();
					_ceNameWin.setBounds(tb.x + pb.x - parX, tb.y + pb.y - parY, tb.width, tb.height);
					parX = pb.x;
					parY = pb.y;
				});
			}
		}

		_kdFilter = new KeyDownFilter;
		this.getDisplay().addFilter(SWT.KeyDown, _kdFilter);
		_comm.refMenu.add(&refMenu);
		_comm.refUndoMax.add(&refUndoMax);
		listener(this, SWT.Dispose, { mixin(S_TRACE);
			this.getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
			_comm.refMenu.remove(&refMenu);
			_comm.refUndoMax.remove(&refUndoMax);
		});

		modB(_alt, _list, _name, _canApply);
		static if (is(T:BgImageSetting)) {
			modB(_alt, _list, _bgImgMask, _canApply);
			modB(_alt, _list, _bgImgX, _canApply);
			modB(_alt, _list, _bgImgY, _canApply);
			modB(_alt, _list, _bgImgW, _canApply);
			modB(_alt, _list, _bgImgH, _canApply);
			modB(_alt, _list, _bgImgLayer, _canApply);
		} else static if (is(T:OuterTool)) {
			modB(_alt, _list, _toolCommand, _canApply);
			modB(_alt, _list, _toolWorkDir, _canApply);
			modB(_alt, _list, _mnemonic, _canApply);
			modB(_alt, _list, _hotkey.widget, _canApply);
		} else static if (is(T:ClassicEngine)) {
			modB(_alt, _list, _cEnginePath, _canApply);
			modB(_alt, _list, _cEngineDataDir, _canApply);
			modB(_alt, _list, _cEngineExecute, _canApply);
			modB(_alt, _list, _mnemonic, _canApply);
			modB(_alt, _list, _hotkey.widget, _canApply);
			modB(_alt, _list, _skinType, _canApply);
		} else static if (is(T:ScTemplate)) {
			modB(_alt, _list, _templPath, _canApply);
		} else static if (is(T:EvTemplate)) {
			modB(_alt, _list, _templScript, _canApply);
			modB(_alt, _list, _mnemonic, _canApply);
			modB(_alt, _list, _hotkey.widget, _canApply);
		} else static assert (0);
		.setupWeights(leftSash, sashL, sashR);

		this.array = array;
	}
	@property
	private bool canUp() { mixin(S_TRACE);
		return _list.getSelectionIndex() != -1 && 0 < _list.getSelectionIndex();
	}
	@property
	private bool canDown() { mixin(S_TRACE);
		return _list.getSelectionIndex() != -1 && _list.getSelectionIndex() + 1 < _list.getItemCount();
	}

	@property
	void array(in T[] array) { mixin(S_TRACE);
		_list.removeAll();
		_undo.reset();
		_array.length = array.length;
		foreach (i, t; array) { mixin(S_TRACE);
			_list.add(createName(t));
			static if (is(typeof(t.dup))) {
				_array[i] = t.dup;
			} else { mixin(S_TRACE);
				_array[i] = t;
			}
		}
		if (_array.length > 0) _list.select(0);
		selected();
	}
	@property
	const
	T[] array() { mixin(S_TRACE);
		T[] arr;
		arr.length = _array.length;
		foreach (i, t; _array) { mixin(S_TRACE);
			static if (is(typeof(t.dup))) {
				arr[i] = t.dup;
			} else { mixin(S_TRACE);
				arr[i] = t;
			}
		}
		return arr;
	}

	@property
	const
	bool noApply() { return _canApply; }

	void forceApply() { mixin(S_TRACE);
		if (!noApply) return;
		if (_list.getItemCount()) { mixin(S_TRACE);
			alt();
		} else { mixin(S_TRACE);
			create();
		}
	}

	@property
	const
	string boxName() {
		static if (is(T:BgImageSetting)) {
			return _prop.msgs.bgImageSettings;
		} else static if (is(T:OuterTool)) {
			return _prop.msgs.outerToolsTitle;
		} else static if (is(T:ClassicEngine)) {
			return _prop.msgs.classicEnginesTitle;
		} else static if (is(T:ScTemplate)) {
			return _prop.msgs.scenarioTemplatesTitle;
		} else static if (is(T:EvTemplate)) {
			return _prop.msgs.eventTemplatesTitle;
		} else static assert (0);
	}

	static if (is(T:ClassicEngine)) {
		@property
		Shell ceNameWin() { return _ceNameWin; }
		@property
		Button features() { return _features; }
	}
	static if (is(typeof(_shortcutSash))) {
		void setShortcutWeights(ref Prop!(int, false) sashL, ref Prop!(int, false) sashR) {
			.setupWeights(_shortcutSash, sashL, sashR);
		}
	}

	@property
	string editingName() { mixin(S_TRACE);
		return _name.getText();
	}

	@property
	void enabled(bool enabled) { mixin(S_TRACE);
		if (enabled == this.enabled) return;
		_list.setEnabled(enabled);
		_name.setEnabled(enabled);
		static if (is(T:BgImageSetting)) {
			_bgImgX.setEnabled(enabled);
			_bgImgY.setEnabled(enabled);
			_bgImgW.setEnabled(enabled);
			_bgImgH.setEnabled(enabled);
			_bgImgMask.setEnabled(enabled);
			_bgImgLayer.setEnabled(enabled);
		} else static if (is(T:OuterTool)) {
			_toolCommand.setEnabled(enabled);
			_toolCommandRef.setEnabled(enabled);
			_toolCommandDirOpen.setEnabled(enabled);
			_toolWorkDir.setEnabled(enabled);
			_toolWorkDirRef.setEnabled(enabled);
			_toolWorkDirOpen.setEnabled(enabled);
			_mnemonic.setEnabled(enabled);
			_hotkey.widget.setEnabled(enabled);
		} else static if (is(T:ClassicEngine)) {
			_cEnginePath.setEnabled(enabled);
			_cEnginePathRef.setEnabled(enabled);
			_cEnginePathDirOpen.setEnabled(enabled);
			_cEngineDataDir.setEnabled(enabled);
			_cEngineDataDirRef.setEnabled(enabled);
			_cEngineDataDirOpen.setEnabled(enabled);
			_cEngineExecute.setEnabled(enabled);
			_cEngineExecuteRef.setEnabled(enabled);
			_cEngineExecuteDirOpen.setEnabled(enabled);
			_mnemonic.setEnabled(enabled);
			_hotkey.widget.setEnabled(enabled);
			_skinType.setEnabled(enabled);

			if (!enabled && _ceNameWin.isVisible()) _ceNameWin.close();
			_features.setEnabled(enabled);
			_featureName.setEnabled(enabled);

		} else static if (is(T:ScTemplate)) {
			_templPath.setEnabled(enabled);
			_templPathRef.setEnabled(enabled);
			_templPathDirOpen.setEnabled(enabled);
		} else static if (is(T:EvTemplate)) {
			_templScript.setEnabled(enabled);
			_mnemonic.setEnabled(enabled);
			_hotkey.widget.setEnabled(enabled);
		}
		_add.setEnabled(enabled);
		_alt.setEnabled(enabled && _altEnabled);
		_del.setEnabled(enabled && _list.getSelectionIndex() != -1);
		_up.setEnabled(enabled && canUp);
		_down.setEnabled(enabled && canDown);
	}
	@property
	bool enabled() { return _list.getEnabled(); }
}
