
module cwx.editor.gui.dwt.comment;

import cwx.event;
import cwx.path;
import cwx.types;
import cwx.utils;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.cardlist;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;

import core.thread;

import std.algorithm;
import std.conv;
import std.datetime;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

void setupComment(Commons comm, Table table, bool isEventView) { mixin(S_TRACE);
	auto img = comm.prop.images.menu(MenuID.Comment);
	auto ib = img.getBounds();
	TableItem drawing = null;
	.listener(table, SWT.Paint, (e) { mixin(S_TRACE);
		auto ca = table.getClientArea();
		auto colWidth = 0;
		foreach (col; table.getColumns()) colWidth += col.getWidth();
		ca.width = .min(ca.width, colWidth);
		auto count = table.getItemCount();
		for (auto index = table.getTopIndex(); index < count; index++) { mixin(S_TRACE);
			auto itm = table.getItem(index);
			if (itm.isDisposed()) continue;
			auto b = itm.getBounds();
			if (ca.y + ca.height <= b.y) break;
			drawComment(isEventView, img, ib, itm, e.gc, drawing);
		}
	});
	.setupCommentToolTip!(Table, TableItem)(comm, table, isEventView, drawing, pos => table.getItem(pos), itm => .commentPos(ib, itm));
}

void setupComment(Commons comm, Tree tree, bool isEventView) { mixin(S_TRACE);
	auto img = comm.prop.images.menu(MenuID.Comment);
	auto ib = img.getBounds();
	TreeItem drawing = null;
	.listener(tree, SWT.Paint, (e) { mixin(S_TRACE);
		auto ca = tree.getClientArea();
		.procShowingTreeItem(tree, (itm) { mixin(S_TRACE);
			drawComment(isEventView, img, ib, itm, e.gc, drawing);
			return true;
		});
	});
	.setupCommentToolTip!(Tree, TreeItem)(comm, tree, isEventView, drawing, (pos) { mixin(S_TRACE);
		TreeItem curItm = null;
		auto ca = tree.getClientArea();
		.procShowingTreeItem(tree, (itm) { mixin(S_TRACE);
			auto bounds = itm.getBounds();
			if (bounds.y <= pos.y && pos.y < bounds.y + bounds.height) { mixin(S_TRACE);
				curItm = itm;
				return false;
			}
			return true;
		});
		return curItm;
	}, itm => .commentPos(ib, itm));
}

void setupComment(C)(Commons comm, CardList!C list, bool isEventView) { mixin(S_TRACE);
	auto img = comm.prop.images.menu(MenuID.Comment);
	auto ib = img.getBounds();
	C drawing = null;
	Point commentPos(Rectangle b) { mixin(S_TRACE);
		return new Point(b.x + b.width - ib.width - 5.ppis, b.y + b.height - ib.height - 5.ppis);
	}
	.listener(list, SWT.Paint, (e) { mixin(S_TRACE);
		auto ca = list.getClientArea();
		if (list.showingStartIndex == -1) return;
		foreach (i; list.showingStartIndex .. list.showingEndIndex) { mixin(S_TRACE);
			auto b = list.getImageBounds(i);
			auto c = list.card(i);
			auto comment = .commentText(c, isEventView);
			if (comment == "") continue;
			e.gc.setAlpha(drawing is c ? 255 : 128);
			auto pos = commentPos(b);
			e.gc.drawImage(img, pos.x, pos.y);
		}
	});
	.setupCommentToolTip!(CardList!C, C)(comm, list, isEventView, drawing, pos => list.search(pos.x, pos.y), (c) { mixin(S_TRACE);
		auto b = list.getImageBounds(list.indexOf(c));
		return commentPos(b);
	});
}

private Point commentPos(Item)(Rectangle ib, Item itm) { mixin(S_TRACE);
	auto table = itm.getParent();
	auto ca = table.getClientArea();
	static if (is(Item:TableItem)) {
		auto colWidth = 0;
		foreach (col; table.getColumns()) colWidth += col.getWidth();
		ca.width = .min(ca.width, colWidth);
	}
	auto b = itm.getBounds();
	return new Point(ca.x + ca.width - ib.width - 5.ppis, b.y + (b.height - ib.height) / 2);
}

private CWXPath commentable(T)(T itm) { mixin(S_TRACE);
	static if (is(T:Item)) {
		return cast(CWXPath)itm.getData();
	} else {
		return itm;
	}
}

private void drawComment(Item)(bool isEventView, Image img, Rectangle ib, Item itm, GC gc, ref Item drawing) { mixin(S_TRACE);
	auto comment = .commentText(.commentable(itm), isEventView);
	if (comment == "") return;
	gc.setAlpha(drawing is itm ? 255 : 128);
	auto pos = .commentPos(ib, itm);
	gc.drawImage(img, pos.x, pos.y);
}

private void setupCommentToolTip(T, Item)(Commons comm, T table, bool isEventView, ref Item drawing, Item delegate(Point pos) hitTest, Point delegate(Item itm) commentPos) { mixin(S_TRACE);
	auto img = comm.prop.images.menu(MenuID.Comment);
	auto ib = img.getBounds();
	ToolTip toolTip = null;
	.listener(table, SWT.Dispose, { mixin(S_TRACE);
		if (toolTip && !toolTip.isDisposed()) toolTip.dispose();
		toolTip = null;
	});
	auto display = table.getDisplay();
	void mouseMove() { mixin(S_TRACE);
		auto curPos = display.getCursorLocation();
		curPos = table.toControl(curPos);
		auto itm = hitTest(curPos);
		static if (is(typeof(itm.isDisposed()))) {
			if (itm && itm.isDisposed()) itm = null;
		}
		string comment;
		if (itm) { mixin(S_TRACE);
			comment = .commentText(.commentable(itm), isEventView);
			if (comment == "") { mixin(S_TRACE);
				itm = null;
			}
		}
		auto old = drawing;
		Point pos = null;
		if (itm) { mixin(S_TRACE);
			pos = commentPos(itm);
			if (pos.x <= curPos.x && curPos.x < pos.x + ib.width && pos.y <= curPos.y && curPos.y < pos.y + ib.height) { mixin(S_TRACE);
				if (drawing is itm) return;
				drawing = itm;
			} else { mixin(S_TRACE);
				drawing = null;
			}
		} else { mixin(S_TRACE);
			drawing = null;
		}
		if (old) { mixin(S_TRACE);
			auto dp = commentPos(old);
			table.redraw(dp.x, dp.y, ib.width, ib.height, false);
		}
		if (drawing) { mixin(S_TRACE);
			if (toolTip && !toolTip.isDisposed() && toolTip.getParent() !is table.getShell()) { mixin(S_TRACE);
				toolTip.dispose();
			}
			if (!toolTip || toolTip.isDisposed()) { mixin(S_TRACE);
				auto create = toolTip is null;
				toolTip = new ToolTip(table.getShell(), SWT.BALLOON);
				toolTip.setAutoHide(false);

				if (create) { mixin(S_TRACE);
					auto track = new class Runnable {
						override void run() { mixin(S_TRACE);
							if (table.isDisposed()) return;
							if (!toolTip) return;
							if (!toolTip.isDisposed() && !toolTip.isVisible()) return;
							mouseMove();
						}
					};
					auto thr = new core.thread.Thread({ mixin(S_TRACE);
						while (toolTip) { mixin(S_TRACE);
							core.thread.Thread.sleep(.dur!"msecs"(100));
							display.asyncExec(track);
						}
					});
					thr.start();
				}
			}
			toolTip.setMessage(comment);
			auto p = table.toDisplay(pos);
			toolTip.setLocation(p.x + ib.x + 5.ppis + ib.width / 2, p.y + ib.height / 2);
			toolTip.setVisible(true);
			table.redraw(pos.x, pos.y, ib.width, ib.height, false);
		} else if (toolTip && !toolTip.isDisposed() && toolTip.isVisible()) { mixin(S_TRACE);
			toolTip.setVisible(false);
		}
	}
	.listener(table, SWT.MouseMove, &mouseMove);
	.listener(table, SWT.MouseEnter, &mouseMove);
	.listener(table, SWT.MouseExit, &mouseMove);
	comm.replText.add(&table.redraw);
	.listener(table, SWT.Dispose, { mixin(S_TRACE);
		comm.replText.remove(&table.redraw);
	});
}

class CommentDialog : AbsDialog {
	private Commons _comm;
	private Text _comment;
	private string _text;

	this (Commons comm, Shell shell, string comment) { mixin(S_TRACE);
		super (comm.prop, shell, false, comm.prop.msgs.dlgTitComment, comm.prop.images.menu(MenuID.Comment), true, comm.prop.var.commentDlg, true);
		_comm = comm;
		_text = comment;
	}

	override void setup(Composite area) { mixin(S_TRACE);
		auto cl = new CenterLayout;
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		area.setLayout(cl);
		_comment = new Text(area, SWT.BORDER | SWT.MULTI | SWT.WRAP | SWT.V_SCROLL);
		mod(_comment);
		_comment.setTabs(_comm.prop.var.etc.tabs);
		_comment.setText(_text);
		createTextMenu!Text(_comm, _comm.prop, _comment, &catchMod);
		auto font = _comment.getFont();
		auto fSize = font ? cast(uint) font.getFontData()[0].height : 0;
		_comment.setFont(new Font(Display.getCurrent(), dwtData(_comm.prop.adjustFont(_comm.prop.looks.textDlgFont(fSize)))));
		_comment.setSelection(cast(int)to!wstring(_comment.getText()).length);
		closeEvent ~= () { mixin(S_TRACE);
			_comment.getFont().dispose();
		};
	}

	@property
	const
	string comment() { return _text; }

	override bool apply() { mixin(S_TRACE);
		_text = .lastRet(.wrapReturnCode(_comment.getText()));
		return true;
	}
}
