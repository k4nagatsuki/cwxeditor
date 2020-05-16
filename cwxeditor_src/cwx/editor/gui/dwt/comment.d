
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

import std.conv;
import std.datetime;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

string commentText(in CWXPath o, bool isEventView) { mixin(S_TRACE);
	if (isEventView) { mixin(S_TRACE);
		if (auto eto = cast(const EventTreeOwner)o) return eto.commentForEvents;
	}
	if (auto c = cast(const Commentable)o) return c.comment;
	return "";
}

void setupComment(Commons comm, Table table, bool isEventView) { mixin(S_TRACE);
	auto img = comm.prop.images.menu(MenuID.Comment);
	auto ib = img.getBounds();
	TableItem drawing = null;
	.listener(table, SWT.Paint, (e) { mixin(S_TRACE);
		auto ca = table.getClientArea();
		ca.width = 0;
		foreach (col; table.getColumns()) ca.width += col.getWidth();
		auto count = table.getItemCount();
		for (auto index = table.getTopIndex(); index < count; index++) { mixin(S_TRACE);
			auto itm = table.getItem(index);
			auto b = itm.getBounds();
			if (ca.y + ca.height <= b.y) break;
			drawComment(isEventView, img, ib, itm, e.gc, drawing);
		}
	});
	setupCommentToolTip(comm, table, isEventView, drawing);
}

void setupComment(Commons comm, Tree tree, bool isEventView) {
	auto img = comm.prop.images.menu(MenuID.Comment);
	auto ib = img.getBounds();
	TreeItem drawing = null;
	.listener(tree, SWT.Paint, (e) { mixin(S_TRACE);
		auto ca = tree.getClientArea();
		bool recurse(TreeItem itm) { mixin(S_TRACE);
			auto bounds = itm.getBounds();
			if (bounds.y + bounds.height < ca.y) return true;
			if (ca.y + ca.height <= bounds.y) return false;

			drawComment(isEventView, img, ib, itm, e.gc, drawing);

			if (!itm.getExpanded()) return true;
			foreach (cItm; itm.getItems()) { mixin(S_TRACE);
				if (!recurse(cItm)) break;
			}
			return true;
		}
		foreach (itm; tree.getItems()) { mixin(S_TRACE);
			if (!recurse(itm)) break;
		}
	});
	setupCommentToolTip(comm, tree, isEventView, drawing);
}

void setupComment(C)(Commons comm, CardList!C list) {
}

private Point commentPos(Item)(Rectangle ib, Item itm) { mixin(S_TRACE);
	auto table = itm.getParent();
	auto ca = table.getClientArea();
	static if (is(Item:TableItem)) {
		ca.width = 0;
		foreach (col; table.getColumns()) ca.width += col.getWidth();
	}
	auto b = itm.getBounds();
	return new Point(ca.x + ca.width - ib.width - 5.ppis, b.y + (b.height - ib.height) / 2);
}

private void drawComment(Item)(bool isEventView, Image img, Rectangle ib, Item itm, GC gc, ref Item drawing) { mixin(S_TRACE);
	auto comment = .commentText(cast(CWXPath)itm.getData(), isEventView);
	if (comment == "") return;
	gc.setAlpha(drawing is itm ? 255 : 128);
	auto pos = commentPos(ib, itm);
	gc.drawImage(img, pos.x, pos.y);
}

private void setupCommentToolTip(T, Item)(Commons comm, T table, bool isEventView, ref Item drawing) { mixin(S_TRACE);
	auto img = comm.prop.images.menu(MenuID.Comment);
	auto ib = img.getBounds();
	ToolTip toolTip = null;
	.listener(table, SWT.Dispose, { mixin(S_TRACE);
		if (toolTip) toolTip.dispose();
		toolTip = null;
	});
	auto display = table.getDisplay();
	void mouseMove() { mixin(S_TRACE);
		auto curPos = display.getCursorLocation();
		curPos = table.toControl(curPos);
		auto itm = table.getItem(curPos);
		string comment;
		if (itm) { mixin(S_TRACE);
			comment = .commentText(cast(CWXPath)itm.getData(), isEventView);
			if (comment == "") { mixin(S_TRACE);
				itm = null;
			}
		}
		auto old = drawing;
		Point pos = null;
		if (itm) { mixin(S_TRACE);
			pos = commentPos(ib, itm);
			auto b = itm.getBounds();
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
			auto dp = commentPos(ib, old);
			table.redraw(dp.x, dp.y, ib.width, ib.height, false);
		}
		if (drawing) { mixin(S_TRACE);
			if (!toolTip) { mixin(S_TRACE);
				toolTip = new ToolTip(table.getShell(), SWT.BALLOON);
				toolTip.setAutoHide(false);
			}
			toolTip.setMessage(comment);
			auto p = table.toDisplay(pos);
			toolTip.setLocation(p.x + ib.x + 5.ppis + ib.width / 2, p.y + ib.height / 2);
			toolTip.setVisible(true);
			table.redraw(pos.x, pos.y, ib.width, ib.height, false);

			auto track = new class Runnable {
				override void run() { mixin(S_TRACE);
					if (table.isDisposed()) return;
					if (!toolTip) return;
					if (!toolTip.isVisible()) return;
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
		} else if (toolTip) { mixin(S_TRACE);
			toolTip.setVisible(false);
		}
	}
	.listener(table, SWT.MouseMove, &mouseMove);
	.listener(table, SWT.MouseEnter, &mouseMove);
	.listener(table, SWT.MouseExit, &mouseMove);
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
