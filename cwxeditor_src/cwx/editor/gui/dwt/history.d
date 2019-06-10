
module cwx.editor.gui.dwt.history;

import cwx.menu;
import cwx.path;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.types;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.algorithm;
import std.ascii;
import std.array;
import std.file;
import std.path;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

/// 開いたシナリオの履歴とブックマークを編集する。
class ScenarioHistoryDialog : AbsDialog, TCPD {

	private void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		auto num = .count!(h => !h.bookmark)(_hist);
		if (_comm.prop.var.etc.historyMax < num) { mixin(S_TRACE);
			ws ~= .tryFormat(_comm.prop.msgs.warningHistoryTooMany, num, _comm.prop.var.etc.historyMax);
		}
		warning = ws;
	}

	private Commons _comm;
	private Table _list;
	private static struct Hist {
		OpenHistory hist;
		bool bookmark;
		this (in OpenHistory hist, bool bookmark) { mixin(S_TRACE);
			this.hist = hist;
			this.bookmark = bookmark;
		}
	}
	private Hist[] _hist;
	private OpenHistory[] _history;
	private OpenHistory[] _bookmark;

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
			refreshWarning();
			applyEnabled();
			_comm.refreshToolBar();
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
				refreshWarning();
				applyEnabled();
				_comm.refreshToolBar();
			} else if (auto files = cast(FileNames)e.data) { mixin(S_TRACE);
				// ファイルリストのドロップで履歴にパスを追加する
				bool[string] paths;
				string normCase(string path) { mixin(S_TRACE);
					static if (filenameCmp("A", "a") == 0) {
						return path.toLower();
					} else {
						return path;
					}
				}
				foreach (m; _hist) paths[normCase(.nabs(.fullHistToHist(m.hist.path)))] = true;
				Hist[] targ;
				foreach (file; files.array) { mixin(S_TRACE);
					if (!file.exists()) continue;
					if (file.isDir()) { mixin(S_TRACE);
						auto wsn = file.buildPath("Summary.xml");
						auto wsm = file.buildPath("Summary.wsm");
						if (wsn.exists()) { mixin(S_TRACE);
							file = wsn;
						} else if (wsm.exists()) { mixin(S_TRACE);
							file = wsm;
						} else { mixin(S_TRACE);
							continue;
						}
					}
					auto p = normCase(.nabs(file));
					if (p !in paths) { mixin(S_TRACE);
						targ ~= Hist(OpenHistory(file), false);
						paths[p] = true;
					}
				}
				if (!targ.length) return;
				store();
				auto dropIndex = cast(TableItem)e.item ? _list.indexOf(cast(TableItem)e.item) : _list.getItemCount();
				assert (dropIndex != -1);
				_hist = _hist[0 .. dropIndex] ~ targ ~ _hist[dropIndex .. $];
				_list.setItemCount(cast(int)_hist.length);
				_list.clearAll();
				_list.deselectAll();
				_list.select(dropIndex);
				_list.showSelection();
				e.detail = DND.DROP_LINK;
				refreshWarning();
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

	this (Commons comm, Shell shell, string title, Image icon, OpenHistory[] history, OpenHistory[] bookmark) { mixin(S_TRACE);
		_comm = comm;
		_history = history;
		_bookmark = bookmark;
		auto size = _comm.prop.var.scenarioHistoryDlg;
		super (_comm.prop, shell, false, title, icon, true, size, true, true);
	}

	@property
	inout
	inout(OpenHistory)[] bookmark() { return _bookmark; }

	@property
	inout
	inout(OpenHistory)[] history() { return _history; }

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
				refreshWarning();
				applyEnabled();
			}
		});
		.listener(_list, SWT.MouseDoubleClick, &openSelection);
		.listener(_list, SWT.KeyDown, (e) { mixin(S_TRACE);
			if (.isEnterKey(e.keyCode)) openSelection();
		});
		_list.setLayoutData(new GridData(GridData.FILL_BOTH));

		auto nameCol = new TableColumn(_list, SWT.NONE);
		nameCol.setText(_comm.prop.msgs.historyScenarioFileName);
		auto pathCol = new TableColumn(_list, SWT.NONE);
		pathCol.setText(_comm.prop.msgs.historyScenarioPath);

		saveColumnWidth!("prop.var.etc.historyScenarioNameColumn")(_comm.prop, nameCol);
		saveColumnWidth!("prop.var.etc.historyScenarioPathColumn")(_comm.prop, pathCol);

		auto menu = new Menu(_list.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.OpenDir, &openSelection, &canOpenSelection);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.Up, &up, &canUp);
		createMenuItem(_comm, menu, MenuID.Down, &down, &canDown);
		new MenuItem(menu, SWT.SEPARATOR);
		.appendMenuTCPD(_comm, menu, this, true, true, true, true, false);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CopyAsText, &copyAsText, () => 0 < _list.getSelectionCount());
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &_list.selectAll, () => _list.getItemCount() && _list.getSelectionCount() != _list.getItemCount());
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.DeleteNotExistsHistory, &delNotExists, () => 0 < _list.getItemCount());
		_list.setMenu(menu);

		_hist = .map!(h => Hist(h, true))(_bookmark).array();
		_hist ~= .map!(h => Hist(h, false))(_history).array();
		_list.setItemCount(cast(int)_hist.length);
		.listener(_list, SWT.SetData, (e) { mixin(S_TRACE);
			auto m = _hist[e.index];
			auto itm = cast(TableItem)e.item;
			auto path = .fullHistToHist(m.hist.path);
			itm.setImage(.historyImage(_comm.prop, path));
			path = toSFileName(path);
			itm.setText(0, .baseName(path));
			itm.setText(1, .nabs(path));
			itm.setChecked(m.bookmark);
		});

		auto drag = new DragSource(_list, DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new DragHist);
		auto drop = new DropTarget(_list, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_MOVE | DND.DROP_LINK);
		drop.setTransfer([XMLBytesTransfer.getInstance(), FileTransfer.getInstance()]);
		drop.addDropListener(new DropHist);

		_comm.refHistoryMax.add(&refHistoryMax);
		.listener(_list, SWT.Dispose, { mixin(S_TRACE);
			_comm.refHistoryMax.remove(&refHistoryMax);
		});
	}

	private static string toSFileName(string path) { mixin(S_TRACE);
		auto name = .baseName(path);
		if (.cfnmatch(name, "Summary.xml") || .cfnmatch(name, "Summary.wsm")) { mixin(S_TRACE);
			return .dirName(path);
		} else { mixin(S_TRACE);
			return path;
		}
	}
	private static string toKeyFileName(in OpenHistory oh) { mixin(S_TRACE);
		return .filenameCmp("a", "A") == 0 ? .nabs(oh.path).toLower() : .nabs(oh.path);
	}

	@property
	private bool canOpenSelection() { mixin(S_TRACE);
		foreach (i; _list.getSelectionIndices()) { mixin(S_TRACE);
			auto path = toSFileName(.fullHistToHist(_hist[i].hist.path));
			if (path.exists()) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	private void openSelection() { mixin(S_TRACE);
		foreach (i; _list.getSelectionIndices()) { mixin(S_TRACE);
			auto path = toSFileName(.fullHistToHist(_hist[i].hist.path));
			if (path.exists()) { mixin(S_TRACE);
				.openFolderWithFile(path);
			}
		}
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
		auto doc = XNode.create("openHistories");
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
		if (node.name != "openHistories") return false;
		int[string] set;
		foreach (i, oh; _hist) { mixin(S_TRACE);
			set[toKeyFileName(oh.hist)] = cast(int)i;
		}
		Hist[] hists;
		int[] selIndices;
		node.onTag[OpenHistory.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
			OpenHistory oh;
			oh.fromNode(node);
			auto key = toKeyFileName(oh);
			if (auto p = key in set) { mixin(S_TRACE);
				selIndices ~= *p;
				return;
			}
			auto bookmark = node.attr("bookmark", false, false);
			auto i = cast(int)(_hist.length + hists.length);
			hists ~= Hist(oh, bookmark);
			selIndices ~= i;
			set[key] = i;
		};
		node.parse();
		if (!hists.length) return false;
		store();
		_hist ~= hists;
		_list.setItemCount(cast(int)_hist.length);
		_list.deselectAll();
		_list.select(selIndices);
		_list.showSelection();
		refreshWarning();
		applyEnabled();
		_comm.refreshToolBar();
		return true;
	}

	private void copyAsText() { mixin(S_TRACE);
		string[] t;
		foreach (index; _list.getSelectionIndices()) { mixin(S_TRACE);
			t ~= toSFileName(.fullHistToHist(_hist[index].hist.path));
		}
		if (!t.length) return;
		auto text = new ArrayWrapperString(std.string.join(t, .newline));
		_comm.clipboard.setContents([text], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
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
		refreshWarning();
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
			if (.fullHistToHist(m.hist.path).exists()) { mixin(S_TRACE);
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
		refreshWarning();
		applyEnabled();
		_comm.refreshToolBar();
	}

	private void refHistoryMax() { mixin(S_TRACE);
		if (_comm.prop.var.etc.historyMax < _history.length) { mixin(S_TRACE);
			_history = _history[0 .. _comm.prop.var.etc.historyMax];
		}
		auto num = .count!(h => !h.bookmark)(_hist);
		if (_history.length < _comm.prop.var.etc.historyMax && _history.length < num) { mixin(S_TRACE);
			applyEnabled();
		}
		refreshWarning();
	}

	protected override bool apply() { mixin(S_TRACE);
		_bookmark = _hist.filter!(h => h.bookmark)().map!(h => h.hist)().array();
		_history = _hist.filter!(h => !h.bookmark)().map!(h => h.hist)().array();
		if (_comm.prop.var.etc.historyMax < _history.length) { mixin(S_TRACE);
			_history = _history[0 .. _comm.prop.var.etc.historyMax];
		}
		return true;
	}
}

Image historyImage(Props prop, string hist) { mixin(S_TRACE);
	if (!.exists(hist)) return prop.images.warning;
	auto ext = .extension(hist);
	if (.cfnmatch(baseName(hist), "Summary.xml")) { mixin(S_TRACE);
		return prop.images.summaryFile;
	} else if (.cfnmatch(ext, ".wsn")) { mixin(S_TRACE);
		return prop.images.scenarioArchive;
	} else if (.cfnmatch(baseName(hist), "Summary.wsm")) { mixin(S_TRACE);
		return prop.images.classic;
	} else if (.cfnmatch(ext, ".cab") || .cfnmatch(ext, ".zip") || .cfnmatch(ext, ".lzh") || .cfnmatch(ext, ".lha")) { mixin(S_TRACE);
		return prop.images.scenarioArchive;
	} else { mixin(S_TRACE);
		return prop.images.unknown;
	}
}

/// `"/foo/bar" /cwx:0/path:0...` -> `/foo/bar`
string fullHistToHist(string hist) { mixin(S_TRACE);
	if (std.string.startsWith(hist, "\"")) { mixin(S_TRACE);
		auto i = std.string.indexOf(hist["\"".length .. $], "\"");
		if (-1 != i) { mixin(S_TRACE);
			return hist["\"".length .. i + "\"".length];
		}
	}
	return hist;
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (fullHistToHist(r"C:\test\test1") == r"C:\test\test1");
	assert (fullHistToHist(`"C:\test\test1" aaa`) == r"C:\test\test1");
}

/// `"/foo/bar" /cwx:0/path:0&/cwx:1/path1:0` -> [`/cwx:0/path:0`, `/cwx:1/path:1`]
string[] fullHistToCWXPaths(string hist) { mixin(S_TRACE);
	if (std.string.startsWith(hist, "\"")) { mixin(S_TRACE);
		auto i = std.string.indexOf(hist["\"".length .. $], "\"");
		if (-1 != i) { mixin(S_TRACE);
			return std.string.split(strip(hist[i + "\"".length + 1 .. $]), CWXPATH_SEP.idup);
		}
	}
	return [];
} unittest { mixin(S_TRACE);
	debug mixin(UTPerf);
	assert (fullHistToCWXPaths(r"C:\test\test1") == []);
	assert (fullHistToCWXPaths(`"C:\test\test1" aaa&bbb`) == ["aaa", "bbb"]);
	assert (fullHistToCWXPaths(`"C:\test\test1" &aaa&bbb&&`) == ["", "aaa", "bbb", "", ""]);
}

string createHistString(in Summary summ) { mixin(S_TRACE);
	if (!summ) return "";
	string hist;
	if (summ.readOnlyPath != "") { mixin(S_TRACE);
		if (!summ.readOnlyPath.exists()) return "";
		if (summ.readOnlyPath.isDir()) { mixin(S_TRACE);
			hist = std.path.buildPath(summ.readOnlyPath, "Summary.wsm");
		} else { mixin(S_TRACE);
			hist = summ.readOnlyPath;
		}
	} else if (summ.legacy) { mixin(S_TRACE);
		if (summ.useTemp) { mixin(S_TRACE);
			hist = summ.origZipName;
		} else { mixin(S_TRACE);
			hist = std.path.buildPath(summ.scenarioPath, "Summary.wsm");
		}
	} else if (summ.useTemp) { mixin(S_TRACE);
		hist = summ.origZipName;
		if (!hist.length) return "";
	} else { mixin(S_TRACE);
		hist = std.path.buildPath(summ.scenarioPath, "Summary.xml");
	}
	return nabs(hist);
}

OpenHistory findHistory(in Commons comm, string hist) { mixin(S_TRACE);
	if ("" == hist) return OpenHistory("");
	foreach (h; comm.prop.var.etc.scenarioBookmarks) { mixin(S_TRACE);
		if (.cfnmatch(.fullHistToHist(h.path), hist)) { mixin(S_TRACE);
			return h;
		}
	}
	foreach (h; comm.prop.var.etc.openHistories) { mixin(S_TRACE);
		if (.cfnmatch(.fullHistToHist(h.path), hist)) { mixin(S_TRACE);
			return h;
		}
	}
	return OpenHistory("");
}

void addHistory(Commons comm, OpenHistory hist, ref OpenHistory[] openHistories, ref OpenHistory[] bookmarks) { mixin(S_TRACE);
	if ("" == hist.path) return;
	auto p = .fullHistToHist(hist.path);
	if (comm.prop.var.etc.historyMax == 0) { mixin(S_TRACE);
		openHistories = [];
	} else { mixin(S_TRACE);
		auto bookmarked = false;
		foreach (h; bookmarks) { mixin(S_TRACE);
			if (.cfnmatch(.fullHistToHist(h.path), p)) { mixin(S_TRACE);
				// すでにブックマークに登録されている
				bookmarked = true;
				break;
			}
		}
		if (!bookmarked) { mixin(S_TRACE);
			auto hists = openHistories.dup;
			foreach (i, h; hists) { mixin(S_TRACE);
				if (.cfnmatch(.fullHistToHist(h.path), p)) { mixin(S_TRACE);
					// すでに履歴中に存在するため、最新位置に移動
					hist = h;
					openHistories = hists[0 .. i] ~ hists[i + 1 .. $];
					hists = openHistories.dup;
					break;
				}
			}
			openHistories = [hist] ~ (hists.length < comm.prop.var.etc.historyMax ? hists : hists[0 .. $ - 1]);
		}
	}
}
