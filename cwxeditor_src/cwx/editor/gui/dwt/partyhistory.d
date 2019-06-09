
module cwx.editor.gui.dwt.partyhistory;

import cwx.binary;
import cwx.cwl;
import cwx.menu;
import cwx.structs;
import cwx.types;
import cwx.utils;
import cwx.win32res;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import core.thread;

import std.algorithm;
import std.array;
import std.file;
import std.path;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

/// 使用したパーティの履歴とブックマークを編集する。
class ExecutedPartyHistoryDialog : AbsDialog, TCPD {
	private Commons _comm;
	private Table _list;
	private static struct Hist {
		ExecutionParty hist;
		bool bookmark;
		this (in ExecutionParty hist, bool bookmark) { mixin(S_TRACE);
			this.hist = hist;
			this.bookmark = bookmark;
		}
	}
	private Hist[] _hist;
	private Image[string] _icon;

	private UndoManager _undo;

	private class HUndo : Undo {
		private int[] _selected;
		private Hist[] _oldHist;

		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			_selected = _list.getSelectionIndices();
			_oldHist = _hist.dup;
		}
		private void impl() { mixin(S_TRACE);
			auto selected = _selected;
			auto oldHist = _oldHist;
			save();
			_hist = oldHist.dup;
			_list.setItemCount(cast(int)_hist.length);
			_list.clearAll();
			_list.setSelection(selected);
			_comm.refreshToolBar();
			applyEnabled();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// 処理無し
		}
	}
	private void store() { mixin(S_TRACE);
		_undo ~= new HUndo();
	}

	private TableItem _dragItm = null;
	private class DragHist : DragSourceAdapter {
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = 0 < _list.getSelectionCount();
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto sels = _list.getSelectionIndices();
				assert (0 < sels.length);
				auto sel = _list.getSelectionIndex();
				assert (sel != -1);
				_dragItm =_list.getItem(sel);
				e.data = .bytesFromXML(createNode(sels).text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			_dragItm = null;
		}
	}
	private class DropHist : DropTargetAdapter {
		private void move(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = _dragItm ? DND.DROP_MOVE : DND.DROP_COPY;
		}
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			move(e);
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_NONE;
			if (_dragItm) { mixin(S_TRACE);
				// 同じビュー上のドラッグ&ドロップ(位置の移動)
				if (_dragItm is e.item) return;
				e.detail = DND.DROP_MOVE;
				auto dragIndex = _list.indexOf(_dragItm);
				auto dropIndex = cast(TableItem)e.item ? _list.indexOf(cast(TableItem)e.item) : _list.getItemCount();
				assert (dragIndex != -1);
				assert (dropIndex != -1);
				assert (dragIndex != dropIndex);
				store();
				if (dropIndex < dragIndex) { mixin(S_TRACE);
					upImpl(dragIndex - dropIndex);
				} else { mixin(S_TRACE);
					assert (dragIndex < dropIndex);
					downImpl(dropIndex - dragIndex);
				}
				applyEnabled();
				_comm.refreshToolBar();
			} else { mixin(S_TRACE);
				// 他のビューからのドロップ
				if (!.isXMLBytes(e.data)) return;
				auto xml = .bytesToXML(e.data);
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					if (pasteImpl(node)) { mixin(S_TRACE);
						e.detail = DND.DROP_COPY;
					}
				} catch (Exception e) { mixin(S_TRACE);
					printStackTrace();
					debugln(e);
				}
			}
		}
	}

	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _comm.prop.var.etc.undoMaxEtc;
	}

	this (Commons comm, Shell shell) { mixin(S_TRACE);
		_comm = comm;
		auto size = _comm.prop.var.executedPartyHistoryDlg;
		super (_comm.prop, shell, false, _comm.prop.msgs.editExecutedPartyHistory, _comm.prop.images.menu(MenuID.EditScenarioHistory), true, size, true, true);
	}

	protected override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));

		_undo = new UndoManager(_comm.prop.var.etc.undoMaxEtc);
		_comm.refUndoMax.add(&refUndoMax);
		.listener(area, SWT.Dispose, { mixin(S_TRACE);
			_comm.refUndoMax.remove(&refUndoMax);
		});

		auto label = new Label(area, SWT.WRAP);
		label.setText(_comm.prop.msgs.scenarioBookmarkHint);
		label.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		_list = .rangeSelectableTable(area, SWT.MULTI | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.VIRTUAL);
		_list.setHeaderVisible(true);
		.listener(_list, SWT.Selection, (e) { mixin(S_TRACE);
			if (e.detail == SWT.CHECK) { mixin(S_TRACE);
				updateChecked(e);
				foreach (i; _list.getSelectionIndices() ~ _list.indexOf(cast(TableItem)e.item)) { mixin(S_TRACE);
					_hist[i].bookmark = _list.getItem(i).getChecked();
				}
				applyEnabled();
			}
		});
		_list.setLayoutData(new GridData(GridData.FILL_BOTH));

		auto nameCol = new TableColumn(_list, SWT.NONE);
		nameCol.setText(_comm.prop.msgs.executionPartyName);
		auto yadoCol = new TableColumn(_list, SWT.NONE);
		yadoCol.setText(_comm.prop.msgs.executionPartyYado);
		auto engineCol = new TableColumn(_list, SWT.NONE);
		engineCol.setText(_comm.prop.msgs.executionPartyEngine);

		saveColumnWidth!("prop.var.etc.executionPartyNameColumn")(_comm.prop, nameCol);
		saveColumnWidth!("prop.var.etc.executionPartyYadoColumn")(_comm.prop, yadoCol);
		saveColumnWidth!("prop.var.etc.executionPartyEngineColumn")(_comm.prop, engineCol);

		auto menu = new Menu(_list.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.Up, &up, &canUp);
		createMenuItem(_comm, menu, MenuID.Down, &down, &canDown);
		new MenuItem(menu, SWT.SEPARATOR);
		.appendMenuTCPD(_comm, menu, this, true, true, true, true, false);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &_list.selectAll, () => _list.getItemCount() && _list.getSelectionCount() != _list.getItemCount());
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.DeleteNotExistsParties, &delNotExists, () => 0 < _list.getItemCount());
		_list.setMenu(menu);

		_hist = .map!(h => Hist(h, true))(_comm.prop.var.etc.executedPartyBookmarks).array();
		_hist ~= .map!(h => Hist(h, false))(_comm.prop.var.etc.executedParties).array();
		_list.setItemCount(cast(int)_hist.length);
		.listener(_list, SWT.SetData, (e) { mixin(S_TRACE);
			auto m = _hist[e.index];
			auto itm = cast(TableItem)e.item;
			if (.existsParty(_comm, m.hist)) { mixin(S_TRACE);
				itm.setImage(_comm.prop.images.menu(MenuID.ExecEngine));
				// エンジンアイコン
				if (!.cfnmatch(m.hist.enginePath.extension(), ".py")) { mixin(S_TRACE);
					auto p = m.hist.enginePath in _icon;
					if (p && *p) { mixin(S_TRACE);
						itm.setImage(*p);
					} else { mixin(S_TRACE);
						auto imgData = .loadIcon(m.hist.enginePath, 16.ppis, 16.ppis);
						if (imgData) { mixin(S_TRACE);
							auto img = new Image(_list.getDisplay(), imgData);
							itm.setImage(img);
							_icon[m.hist.enginePath] = img;
						} else { mixin(S_TRACE);
							_icon[m.hist.enginePath] = null;
						}
					}
				}
			} else { mixin(S_TRACE);
				itm.setImage(_comm.prop.images.warning);
			}
			itm.setText(0, m.hist.partyName);
			itm.setText(1, m.hist.yadoName);
			itm.setText(2, m.hist.engineName);
			itm.setChecked(m.bookmark);
		});

		auto drag = new DragSource(_list, DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new DragHist);
		auto drop = new DropTarget(_list, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE);
		drop.setTransfer([XMLBytesTransfer.getInstance()]);
		drop.addDropListener(new DropHist);

		_comm.refClassicSkin.add(&refClassicSkin);
		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			_comm.refClassicSkin.remove(&refClassicSkin);
			foreach (img; _icon.byValue()) { mixin(S_TRACE);
				img.dispose();
			}
		});
	}

	@property
	private bool canUp() { mixin(S_TRACE);
		return _list.getSelectionCount() && 0 < .minElement(_list.getSelectionIndices());
	}
	private void up() { mixin(S_TRACE);
		if (!canUp) return;
		store();
		upImpl(1);
		applyEnabled();
		_comm.refreshToolBar();
	}
	private void upImpl(size_t count) { mixin(S_TRACE);
		auto indices = _list.getSelectionIndices();
		indices = indices.sort().array();
		foreach (i; 0 .. count) { mixin(S_TRACE);
			if (indices[0] <= 0) break;
			foreach (index; indices) { mixin(S_TRACE);
				.swap(_hist[index - 1], _hist[index]);
			}
			indices[] -= 1;
		}
		_list.setSelection(indices);
		_list.clearAll();
	}

	@property
	private bool canDown() { mixin(S_TRACE);
		return _list.getSelectionCount() && .maxElement(_list.getSelectionIndices()) + 1 < _list.getItemCount();
	}
	private void down() { mixin(S_TRACE);
		if (!canDown) return;
		store();
		downImpl(1);
		applyEnabled();
		_comm.refreshToolBar();
	}
	private void downImpl(size_t count) { mixin(S_TRACE);
		auto indices = _list.getSelectionIndices();
		indices = indices.sort().array();
		foreach (i; 0 .. count) { mixin(S_TRACE);
			if (_hist.length <= indices[$ - 1] + 1) break;
			foreach_reverse (index; indices) { mixin(S_TRACE);
				.swap(_hist[index], _hist[index + 1]);
			}
			indices[] += 1;
		}
		_list.setSelection(indices);
		_list.clearAll();
	}

	private XNode createNode(int[] indices) { mixin(S_TRACE);
		auto doc = XNode.create("executionParties");
		foreach (index; indices) { mixin(S_TRACE);
			auto e = _hist[index].hist.toNode(doc);
			if (_hist[index].bookmark) { mixin(S_TRACE);
				e.newAttr("bookmark", .fromBool(_hist[index].bookmark));
			}
		}
		return doc;
	}

	override void cut(SelectionEvent se) { mixin(S_TRACE);
		copy(se);
		del(se);
	}
	override void copy(SelectionEvent se) { mixin(S_TRACE);
		auto indices = _list.getSelectionIndices();
		if (!indices.length) return;
		XMLtoCB(_comm.prop, _comm.clipboard, createNode(indices).text);
		_comm.refreshToolBar();
	}
	override void paste(SelectionEvent se) { mixin(S_TRACE);
		auto c = CBtoXML(_comm.clipboard);
		if (c) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				auto node = XNode.parse(c);
				pasteImpl(node);
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
	}
	override void del(SelectionEvent se) { mixin(S_TRACE);
		delImpl();
	}
	override void clone(SelectionEvent se) { assert (false); }
	@property override bool canDoTCPD() { return true; }
	@property override bool canDoT() { return canDoC; }
	@property override bool canDoC() { return 0 < _list.getSelectionCount(); }
	@property override bool canDoP() { return CBisXML(_comm.clipboard); }
	@property override bool canDoD() { return 0 < _list.getSelectionCount(); }
	@property override bool canDoClone() { return false; }

	private bool pasteImpl(ref XNode node) { mixin(S_TRACE);
		if (node.name != "executionParties") return false;
		int[ExecutionParty] set;
		foreach (i, ep; _hist) { mixin(S_TRACE);
			set[ep.hist] = cast(int)i;
		}
		Hist[] hists;
		int[] selIndices;
		node.onTag[ExecutionParty.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
			ExecutionParty ep;
			ep.fromNode(node);
			if (auto p = ep in set) { mixin(S_TRACE);
				selIndices ~= *p;
				return;
			}
			auto bookmark = node.attr("bookmark", false, false);
			auto i = cast(int)(_hist.length + hists.length);
			hists ~= Hist(ep, bookmark);
			selIndices ~= i;
			set[ep] = i;
		};
		node.parse();
		if (!hists.length) return false;
		store();
		_hist ~= hists;
		_list.setItemCount(cast(int)_hist.length);
		_list.deselectAll();
		_list.select(selIndices);
		_list.showSelection();
		applyEnabled();
		_comm.refreshToolBar();
		return true;
	}
	private void delImpl() { mixin(S_TRACE);
		auto indices = _list.getSelectionIndices();
		if (!indices.length) return;
		store();
		foreach_reverse (index; indices) { mixin(S_TRACE);
			_hist = .remove(_hist, index);
		}
		_list.deselectAll();
		_list.setItemCount(cast(int)_hist.length);
		_list.clearAll();
		applyEnabled();
		_comm.refreshToolBar();
	}

	private void delNotExists() { mixin(S_TRACE);
		auto indices = _list.getSelectionIndices();
		bool[Hist] sels;
		foreach (i; indices) { mixin(S_TRACE);
			sels[_hist[i]] = true;
		}
		Hist[] hist;
		int[] indices2;
		foreach (i, m; _hist) { mixin(S_TRACE);
			if (.existsParty(_comm, m.hist)) { mixin(S_TRACE);
				if (m in sels) indices2 ~= cast(int)hist.length;
				hist ~= m;
			}
		}
		if (_hist.length == hist.length) return;
		store();
		_hist = hist;
		_list.setSelection(indices2);
		_list.setItemCount(cast(int)_hist.length);
		_list.clearAll();
		applyEnabled();
		_comm.refreshToolBar();
	}

	private void refClassicSkin() { mixin(S_TRACE);
		// アイコン更新
		foreach (img; _icon.byValue()) { mixin(S_TRACE);
			img.dispose();
		}
		_icon = null;
		_list.clearAll();
	}

	protected override bool apply() { mixin(S_TRACE);
		_comm.prop.var.etc.executedPartyBookmarks = _hist.filter!(h => h.bookmark)().map!(h => h.hist)().array();
		_comm.prop.var.etc.executedParties = _hist.filter!(h => !h.bookmark)().map!(h => h.hist)().array();
		_comm.refExecutedParties.call();
		_comm.refreshToolBar();
		return true;
	}
}

/// エンジン実行及びシナリオ開始のメニューを生成する。
void createExecEngineMenu(Commons comm, Menu menu, Menu mWithParty,
		bool delegate() canExecWithParty,
		string delegate() origScenarioPath,
		void delegate(string path, string scenario, ExecutionParty ep) execEngineP,
		bool delegate() canExecClassic) { mixin(S_TRACE);
	class ExecWithPartyClassic : MenuAdapter {
		private string path;
		private string yPath;
		private string yName;
		private string engineName;
		this (string path, string yPath, string engineName, string yName) { mixin(S_TRACE);
			this.path = path;
			this.yPath = yPath;
			this.engineName = engineName;
			this.yName = yName;
		}
		override void menuShown(MenuEvent e) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				// 各宿のフォルダ
				foreach (m; (cast(Menu)e.widget).getItems()) { mixin(S_TRACE);
					m.dispose();
				}
				foreach (wpl; .clistdir(yPath)) { mixin(S_TRACE);
					// *.wpl
					if (wpl.extension().toLower() != ".wpl") continue;
					auto party = wpl.stripExtension();
					wpl = yPath.buildPath(wpl);
					auto name = .readPartyName(comm.prop.parent, wpl);
					auto img = comm.prop.images.team;
					createMI(cast(Menu)e.widget, path, yPath, name, img, party);
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		void createMI(Menu menu, string path, string yPath, string name, Image img, string party) { mixin(S_TRACE);
			auto mi = createMenuItem2(comm, menu, name, img, { mixin(S_TRACE);
				ExecutionParty ep;
				ep.engineName = engineName;
				ep.enginePath = path;
				ep.isClassic = true;
				ep.yadoName = yName;
				ep.yadoPath = yPath.baseName();
				ep.partyName = name;
				ep.partyPath = name; // クラシックなエンジンは宿名にフォルダ名を使用している
				execEngineP(path, .tryFormat(`"%s"`, origScenarioPath()), ep);
			}, () => true);
		}
	}
	class ExecEngine : MenuAdapter {
		private string yPath;
		private string engineName;
		private string yName;
		this (string yPath, string engineName, string yName) { mixin(S_TRACE);
			this.yPath = yPath;
			this.engineName = engineName;
			this.yName = yName;
		}
		override void menuShown(MenuEvent e) { mixin(S_TRACE);
			foreach (item; (cast(Menu)e.widget).getItems()) { mixin(S_TRACE);
				item.dispose();
			}
			try { mixin(S_TRACE);
				foreach (p; .clistdir(yPath)) { mixin(S_TRACE);
					p = yPath.buildPath(p);
					if (!p.exists() || !p.isDir()) continue;
					foreach (xml; .clistdir(p)) { mixin(S_TRACE);
						xml = p.buildPath(xml);
						if (!(xml.exists() && xml.isFile() && xml.extension().toLower() == ".xml")) continue;
						auto name = "";
						bool hasName = false;
						auto node = XNode.parse(std.file.readText(xml));
						node.onTag["Property"] = (ref XNode node) { mixin(S_TRACE);
							node.onTag["Name"] = (ref XNode node) { mixin(S_TRACE);
								name = node.value;
								hasName = true;
							};
							node.parse();
						};
						node.parse();
						if (!hasName) continue;
						auto img = comm.prop.images.team;
						createMI(cast(Menu)e.widget, comm.prop.enginePath, yPath.dirName(), name, img, p.baseName());
						break;
					}
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		void createMI(Menu menu, string path, string yPath, string name, Image img, string party) { mixin(S_TRACE);
			auto mi = createMenuItem2(comm, menu, name, img, { mixin(S_TRACE);
				ExecutionParty ep;
				ep.engineName = engineName;
				ep.enginePath = path;
				ep.isClassic = false;
				ep.yadoName = yName;
				ep.yadoPath = yPath.baseName();
				ep.partyName = name;
				ep.partyPath = party;
				execEngineP(path, .tryFormat(`"%s"`, origScenarioPath()), ep);
			}, () => true);
		}
	}

	void putMenu(string path, string ePath, string name, Image img, bool withParty) { mixin(S_TRACE);
		MenuItem mi1 = null, mi2 = null;
		if (menu) { mixin(S_TRACE);
			// クラシックエンジンの起動
			auto mi = createMenuItem2(comm, menu, name, img, { mixin(S_TRACE);
				if (path.length) { mixin(S_TRACE);
					execEngineP(path, "", ExecutionParty.init);
				}
			}, () => path.length > 0);
			mi1 = mi;
		}
		if (withParty && mWithParty) { mixin(S_TRACE);
			// クラシックな宿のパーティ選択
			void delegate() dummy = null;
			auto yadoDir = path.dirName().buildPath(comm.prop.sys.yadoName(path.baseName()));
			if (!yadoDir.exists() || !yadoDir.isDir()) return;
			auto mi = createMenuItem2(comm, mWithParty, name, img, dummy, delegate bool() { mixin(S_TRACE);
				if (canExecClassic()) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						foreach (yado; .clistdir(yadoDir)) { mixin(S_TRACE);
							// Yadoフォルダ
							if (std.string.startsWith(yado, "~")) continue;
							auto yPath = yadoDir.buildPath(yado);
							if (!yPath.exists() || !yPath.isDir()) continue;
							foreach (wpl; .clistdir(yPath)) { mixin(S_TRACE);
								// *.wpl
								if (wpl.extension().toLower() == ".wpl") return true;
							}
						}
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
				}
				return false;
			}, SWT.CASCADE);
			auto mwpMenu = new Menu(mi);
			mi.setMenu(mwpMenu);
			mi2 = mi;
			.listener(mwpMenu, SWT.Show, (Event e) { mixin(S_TRACE);
				foreach (item; mwpMenu.getItems()) { mixin(S_TRACE);
					item.dispose();
				}
				try { mixin(S_TRACE);
					if (!canExecWithParty()) return;
					foreach (yado; .clistdir(yadoDir)) { mixin(S_TRACE);
						// Yadoフォルダ
						if (std.string.startsWith(yado, "~")) continue;
						auto yPath = yadoDir.buildPath(yado);
						if (!yPath.exists() || !yPath.isDir()) continue;
						auto envPath = yPath.buildPath("Environment.wyd");
						if (!envPath.exists() || !envPath.isFile()) continue;
						auto img = comm.prop.images.yado;
						if (.isDebugYado(comm.prop.parent, yPath)) img = comm.prop.images.debugYado;
						bool enable = false;
						if (canExecClassic()) { mixin(S_TRACE);
							foreach (wpl; .clistdir(yPath)) { mixin(S_TRACE);
								if (wpl.extension().toLower() == ".wpl") { mixin(S_TRACE);
									enable = true;
									break;
								}
							}
						}
						auto mi = (enable) { return createMenuItem2(comm, mwpMenu, yado, img, dummy, () => enable, SWT.CASCADE); }(enable);
						auto yMenu = new Menu(mi);
						mi.setMenu(yMenu);
						yMenu.addMenuListener(new ExecWithPartyClassic(path, yPath, name, yado));
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			});
		}
		.putEngineIcon(comm, mi1, mi2, ePath);
	}
	if (comm.prop.var.etc.enginePath.length) { mixin(S_TRACE);
		MenuItem mi1 = null, mi2 = null;
		if (menu) { mixin(S_TRACE);
			if (0 < menu.getItemCount()) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
			}
			auto mi = createMenuItem(comm, menu, MenuID.ExecEngineMain, { mixin(S_TRACE);
				if (comm.prop.enginePath.length) { mixin(S_TRACE);
					execEngineP(comm.prop.enginePath, "", ExecutionParty.init);
				}
			}, () => comm.prop.enginePath.length > 0);
			mi1 = mi;
		}
		if (mWithParty) { mixin(S_TRACE);
			// CardWirthPy 0.12.2以降でパーティを指定してシナリオを実行
			if (0 < mWithParty.getItemCount()) { mixin(S_TRACE);
				new MenuItem(mWithParty, SWT.SEPARATOR);
			}
			void delegate() dummy = null;
			auto mi = createMenuItem(comm, mWithParty, MenuID.ExecEngineMain, dummy, delegate bool() { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto dir = comm.prop.var.etc.enginePath.value.dirName().buildPath("Yado");
					if (!dir.exists() || !dir.isDir()) return false;
					foreach (yado; .clistdir(dir)) { mixin(S_TRACE);
						yado = dir.buildPath(yado).buildPath("Party");
						if (!yado.exists() || !yado.isDir()) continue;
						foreach (p; .clistdir(yado)) { mixin(S_TRACE);
							p = yado.buildPath(p);
							if (!p.exists() || !p.isDir()) continue;
							foreach (xml; .clistdir(p)) { mixin(S_TRACE);
								xml = p.buildPath(xml);
								if (xml.isFile() && xml.extension().toLower() == ".xml") return true;
							}
						}
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
				return false;
			}, SWT.CASCADE);
			auto mwpMenu = new Menu(mi);
			mi.setMenu(mwpMenu);
			mi2 = mi;
			.listener(mwpMenu, SWT.Show, (Event e) { mixin(S_TRACE);
				foreach (item; (cast(Menu)e.widget).getItems()) { mixin(S_TRACE);
					item.dispose();
				}
				try { mixin(S_TRACE);
					auto dir = comm.prop.var.etc.enginePath.value.dirName().buildPath("Yado");
					if (!dir.exists() || !dir.isDir()) return;
					foreach (yado; .clistdir(dir)) { mixin(S_TRACE);
						auto dName = yado;
						auto env = dir.buildPath(yado).buildPath("Environment.xml");
						if (!env.exists() || !env.isFile()) continue;
						yado = dir.buildPath(yado).buildPath("Party");
						if (!yado.exists() || !yado.isDir()) continue;

						auto name = "";
						bool hasName = false;
						auto xml = std.file.readText(env);
						auto node = XNode.parse(xml);
						node.onTag["Property"] = (ref XNode node) { mixin(S_TRACE);
							node.onTag["Name"] = (ref XNode node) { mixin(S_TRACE);
								name = node.value;
								hasName = true;
							};
							node.parse();
						};
						node.parse();
						if (!hasName) name = dName;
						auto img = comm.prop.images.yado;
						bool enable = false;
						foreach (p; .clistdir(yado)) { mixin(S_TRACE);
							p = yado.buildPath(p);
							if (!p.exists() || !p.isDir()) continue;
							foreach (file; .clistdir(p)) { mixin(S_TRACE);
								file = p.buildPath(file);
								if (file.exists() && file.isFile() && file.extension().toLower() == ".xml") { mixin(S_TRACE);
									enable = true;
									break;
								}
							}
							if (enable) break;
						}

						auto mi = (enable) { return createMenuItem2(comm, mwpMenu, name, img, dummy, () => enable, SWT.CASCADE); }(enable);
						mi.setEnabled(enable);
						auto yMenu = new Menu(mi);
						mi.setMenu(yMenu);
						yMenu.addMenuListener(new ExecEngine(yado, comm.prop.msgs.menuTextExecEngineMain, name));
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			});
			.putEngineIcon(comm, mi1, mi2, comm.prop.enginePath);
		}
	}
	if (comm.prop.var.etc.classicEngines.length) { mixin(S_TRACE);
		if (menu || mWithParty) { mixin(S_TRACE);
			if (menu && 0 < menu.getItemCount()) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
			}
			bool withPartyItem = false;
			foreach (i, ce; comm.prop.var.etc.classicEngines) { mixin(S_TRACE);
				string name = MenuProps.buildMenu(ce.name, ce.mnemonic, ce.hotkey, false);
				auto p = nabs(ce.executePath(comm.prop.parent.appPath, false)); // 代替実行
				auto e = ce.executePath(comm.prop.parent.appPath, true); // エンジン本体
				if (!p.exists()) continue;
				if (!p.isFile()) continue;
				try {
					auto res = Win32Res(e.exists() && e.isFile() ? e : p);
					auto bin = res.getRCData(ResID(ResType.RT_VERSION), ResID(1u));
					if (bin is null || !bin.length) continue;
					auto ver = ByteIO(bin.dup);
					ver.seek(48);
					auto v2 = ver.readShortL;
					auto v1 = ver.readShortL;
					auto v4 = ver.readShortL;
					auto v3 = ver.readShortL;
					auto exeV = v1 * 0x1000000L + v2 * 0x10000L + v3 * 0x100L + v4 * 0x1L;
					auto v1_50 = 1 * 0x1000000L + 5 * 0x10000L + 0 * 0x100L + 0 * 0x1L;
					bool is1_50 = v1_50 <= exeV;

					if (mWithParty && !withPartyItem && is1_50 && mWithParty.getItemCount()) { mixin(S_TRACE);
						new MenuItem(mWithParty, SWT.SEPARATOR);
					}
					withPartyItem |= is1_50;
					putMenu(p, e, name, comm.prop.images.classicEngine, is1_50);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
	}
}

private void putIcon(Commons comm, MenuItem mi1, MenuItem mi2, string ePath, bool delegate() hasWarning) { mixin(S_TRACE);
	// loadIcon()は低速のため、メニューを開いた際に呼ぶようにする
	Menu menu1 = null, menu2 = null;
	if (mi1) menu1 = mi1.getParent();
	if (mi2) menu2 = mi2.getParent();
	auto rmv = false;
	auto init = false;
	auto img1 = mi1 ? mi1.getImage() : null;
	auto img2 = mi2 ? mi2.getImage() : null;
	MenuAdapter mShown;
	mShown = new class MenuAdapter {
		override void menuShown(MenuEvent e) { mixin(S_TRACE);
			if (hasWarning && init) { mixin(S_TRACE);
				// すでにロード済みのアイコンを警告アイコンに差し替える、
				// または警告アイコンから戻す
				if (hasWarning()) { mixin(S_TRACE);
					if (mi1) mi1.setImage(comm.prop.images.warning);
					if (mi2) mi2.setImage(comm.prop.images.warning);
				} else { mixin(S_TRACE);
					if (mi1) mi1.setImage(img1);
					if (mi2) mi2.setImage(img2);
				}
				return;
			}
			init = true;

			if (!hasWarning) { mixin(S_TRACE);
				// 警告アイコンへの差し替えが必要無い場合は最初の一回のみ処理を行う
				if (menu1) menu1.removeMenuListener(mShown);
				if (menu2) menu2.removeMenuListener(mShown);
				rmv = true;
			}
			version (Windows) {
				// 実行ファイルのアイコンを取得
				auto display = Display.getCurrent();
				auto w = 16.ppis;
				auto h = 16.ppis;
				auto thr = new core.thread.Thread({ mixin(S_TRACE);
					auto exeIcon = loadIcon(ePath, w, h, (void delegate() dlg) { mixin(S_TRACE);
						display.syncExec(new class Runnable {
							void run() { mixin(S_TRACE);
								if (display.isDisposed()) return;
								dlg();
							}
						});
					});
					if (exeIcon) { mixin(S_TRACE);
						display.syncExec(new class Runnable {
							void run() { mixin(S_TRACE);
								if (mi1 && !mi1.isDisposed()) { mixin(S_TRACE);
									img1 = new Image(mi1.getDisplay(), exeIcon);
									listener(mi1, SWT.Dispose, { mixin(S_TRACE);
										img1.dispose();
									});
									if (!hasWarning || !hasWarning()) mi1.setImage(img1);
								}
								if (mi2 && !mi2.isDisposed()) { mixin(S_TRACE);
									img2 = new Image(mi2.getDisplay(), exeIcon);
									listener(mi2, SWT.Dispose, { mixin(S_TRACE);
										img2.dispose();
									});
									if (!hasWarning || !hasWarning()) mi2.setImage(img2);
								}
							}
						});
					}
				});
				thr.start();
			}
		}
	};
	if (menu1) menu1.addMenuListener(mShown);
	if (menu2) menu2.addMenuListener(mShown);
	if (mi1) { mixin(S_TRACE);
		mi1.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				if (!rmv) { mixin(S_TRACE);
					menu1.removeMenuListener(mShown);
				}
			}
		});
	}
	if (mi2) { mixin(S_TRACE);
		mi2.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				if (!rmv) { mixin(S_TRACE);
					menu2.removeMenuListener(mShown);
				}
			}
		});
	}
}
void putEngineIcon(Commons comm, MenuItem mi1, MenuItem mi2, string ePath, bool delegate() hasWarning = null) { mixin(S_TRACE);
	if (!mi1 && !mi2) return;
	if (!.cfnmatch(ePath.extension(), ".py")) { mixin(S_TRACE);
		putIcon(comm, mi1, mi2, ePath, hasWarning);
	}
}

bool existsParty(in Commons comm, in ExecutionParty ep) { mixin(S_TRACE);
	string yadoDir;
	if (ep.isClassic) { mixin(S_TRACE);
		yadoDir = ep.enginePath.dirName().buildPath(comm.prop.sys.yadoName(ep.enginePath.baseName()));
	} else { mixin(S_TRACE);
		yadoDir = ep.enginePath.dirName().buildPath("Yado");
	}

	auto yadoPath = yadoDir.buildPath(ep.yadoPath.baseName());
	auto partyPath = ep.isClassic ? yadoPath.buildPath(ep.partyPath.baseName()).setExtension(".wpl") : yadoPath.buildPath("Party").buildPath(ep.partyPath.baseName());
	return ep.enginePath != "" && ep.enginePath.exists() && ep.enginePath.isFile()
		&& yadoPath.exists() && yadoPath.isDir()
		&& partyPath.exists() && (ep.isClassic ? partyPath.isFile() : partyPath.isDir());
}
