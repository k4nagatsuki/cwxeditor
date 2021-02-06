
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
import std.ascii;
import std.conv;
import std.datetime;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

void setupComment(Commons comm, Table table, bool isEventView, string[] delegate(TableItem itm) getWarnings = null) { mixin(S_TRACE);
	auto commentImg = comm.prop.images.menu(MenuID.Comment);
	auto cib = commentImg.getBounds();
	auto warnImg = comm.prop.images.warning;
	auto wib = warnImg.getBounds();
	auto drawing = new DrawingCW!TableItem;
	.listener(table, SWT.Paint, (e) { mixin(S_TRACE);
		auto ca = table.getClientArea();
		auto colWidth = 0;
		foreach (col; table.getColumns()) colWidth += col.getWidth();
		ca.width = .min(ca.width, colWidth);
		auto count = table.getItemCount();
		Image warningImage = null;
		scope (exit) {
			if (warningImage) warningImage.dispose();
		}
		for (auto index = table.getTopIndex(); index < count; index++) { mixin(S_TRACE);
			auto itm = table.getItem(index);
			if (itm.isDisposed()) continue;
			auto b = itm.getBounds();
			if (ca.y + ca.height <= b.y) break;
			auto warnings = getWarnings ? getWarnings(itm) : [];
			.drawCommentAndWarning(comm.prop, isEventView, commentImg, cib, warnImg, wib, ca.x, ca.width, itm, e.gc, drawing, warnings, comm.prop.var.etc.warningImageWidthForTable, warningImage);
		}
	});
	.setupCommentToolTip!(Table, TableItem)(comm, table, isEventView, getWarnings, drawing, pos => table.getItem(pos), itm => .commentPos(cib, itm), itm => .warningPos(cib, wib, itm, isEventView));
}

void setupComment(Commons comm, Tree tree, bool isEventView, string[] delegate(TreeItem itm) getWarnings = null) { mixin(S_TRACE);
	auto commentImg = comm.prop.images.menu(MenuID.Comment);
	auto cib = commentImg.getBounds();
	auto warnImg = comm.prop.images.warning;
	auto wib = warnImg.getBounds();
	auto drawing = new DrawingCW!TreeItem;
	.listener(tree, SWT.Paint, (e) { mixin(S_TRACE);
		auto ca = tree.getClientArea();
		Image warningImage = null;
		scope (exit) {
			if (warningImage) warningImage.dispose();
		}
		.procShowingTreeItem(tree, (itm) { mixin(S_TRACE);
			auto warnings = getWarnings ? getWarnings(itm) : [];
			drawCommentAndWarning(comm.prop, isEventView, commentImg, cib, warnImg, wib, ca.x, ca.width, itm, e.gc, drawing, warnings, comm.prop.var.etc.warningImageWidthForTree, warningImage);
			return true;
		});
	});
	.setupCommentToolTip!(Tree, TreeItem)(comm, tree, isEventView, getWarnings, drawing, (pos) { mixin(S_TRACE);
		TreeItem curItm = null;
		.procShowingTreeItem(tree, (itm) { mixin(S_TRACE);
			auto bounds = itm.getBounds();
			if (bounds.y <= pos.y && pos.y < bounds.y + bounds.height) { mixin(S_TRACE);
				curItm = itm;
				return false;
			}
			return true;
		});
		return curItm;
	}, itm => .commentPos(cib, itm), itm => .warningPos(cib, wib, itm, isEventView));
}

void setupComment(C)(Commons comm, CardList!C list, bool isEventView, string[] delegate(C c) getWarnings = null) { mixin(S_TRACE);
	auto commentImg = comm.prop.images.menu(MenuID.Comment);
	auto cib = commentImg.getBounds();
	auto warnImg = comm.prop.images.warning;
	auto wib = warnImg.getBounds();
	auto drawing = new DrawingCW!C;
	Point commentPos(Rectangle b) { mixin(S_TRACE);
		return new Point(b.x + b.width - cib.width - 5.ppis, b.y + b.height - cib.height - 5.ppis);
	}
	Point warningPos(in C c, Rectangle b) { mixin(S_TRACE);
		auto p = new Point(b.x + b.width - wib.width - 5.ppis, b.y + b.height - wib.height - 5.ppis);
		if (.commentText(c, isEventView) != "") { mixin(S_TRACE);
			p.y -= cib.height + 5.ppis;
		}
		return p;
	}
	.listener(list, SWT.Paint, (e) { mixin(S_TRACE);
		if (list.showingStartIndex == -1) return;
		Image warningImage = null;
		scope (exit) {
			if (warningImage) warningImage.dispose();
		}
		foreach (i; list.showingStartIndex .. list.showingEndIndex) { mixin(S_TRACE);
			auto b = list.getImageBounds(i);
			auto c = list.card(i);
			auto warnings = getWarnings ? getWarnings(c) : [];
			if (warnings.length) { mixin(S_TRACE);
				if (!warningImage) { mixin(S_TRACE);
					warningImage = .tiltWarningImage(comm.prop, e.display, comm.prop.var.etc.warningImageWidthForCardList);
				}
				auto wRect = warningImage.getBounds();
				e.gc.drawImage(warningImage, b.x + b.width - wRect.width, b.y + b.height - wRect.height);
				e.gc.setAlpha(drawing.item is c && drawing.type is DrawingType.Warning ? 255 : 128);
				auto pos = warningPos(c, b);
				e.gc.drawImage(warnImg, pos.x, pos.y);
				e.gc.setAlpha(255);
			}
			auto comment = .commentText(c, isEventView);
			if (comment != "") { mixin(S_TRACE);
				e.gc.setAlpha(drawing.item is c && drawing.type is DrawingType.Comment ? 255 : 128);
				auto pos = commentPos(b);
				e.gc.drawImage(commentImg, pos.x, pos.y);
				e.gc.setAlpha(255);
			}
		}
	});
	.setupCommentToolTip!(CardList!C, C)(comm, list, isEventView, getWarnings, drawing, pos => list.search(pos.x, pos.y), (c) { mixin(S_TRACE);
		auto b = list.getImageBounds(list.indexOf(c));
		return commentPos(b);
	}, (c) { mixin(S_TRACE);
		auto b = list.getImageBounds(list.indexOf(c));
		return warningPos(c, b);
	});
}

private enum DrawingType {
	None,
	Comment,
	Warning,
}

private class DrawingCW(Item) {
	Item item = null;
	DrawingType type = DrawingType.None;
}

private Point commentPos(Item)(Rectangle cib, Item itm) { mixin(S_TRACE);
	auto table = itm.getParent();
	auto ca = table.getClientArea();
	static if (is(Item:TableItem)) {
		auto colWidth = 0;
		foreach (col; table.getColumns()) colWidth += col.getWidth();
		ca.width = .min(ca.width, colWidth);
	}
	auto b = itm.getBounds();
	return new Point(ca.x + ca.width - cib.width - 5.ppis, b.y + (b.height - cib.height) / 2);
}

private Point warningPos(Item)(Rectangle cib, Rectangle wib, Item itm, bool isEventView) { mixin(S_TRACE);
	auto table = itm.getParent();
	auto ca = table.getClientArea();
	static if (is(Item:TableItem)) {
		auto colWidth = 0;
		foreach (col; table.getColumns()) colWidth += col.getWidth();
		ca.width = .min(ca.width, colWidth);
	}
	auto b = itm.getBounds();
	auto p = new Point(ca.x + ca.width - wib.width - 5.ppis, b.y + (b.height - wib.height) / 2);
	if (.commentText(.commentable(itm), isEventView) != "") {
		p.x -= cib.width + 5.ppis;
	}
	return p;
}

private CWXPath commentable(T)(T itm) { mixin(S_TRACE);
	static if (is(T:Item)) {
		return cast(CWXPath)itm.getData();
	} else {
		return itm;
	}
}

private Image tiltWarningImage(Props prop, Display d, int warningImageWidth = -1) { mixin(S_TRACE);
	if (warningImageWidth < 0) warningImageWidth = prop.var.etc.warningImageWidthForCardList;
	auto buf = new Image(d, warningImageWidth, warningImageWidth);
	scope (exit) buf.dispose();
	auto gc = new GC(buf);
	scope (exit) gc.dispose();
	int alpha;
	auto rgb = dwtData(prop.var.etc.warningImageColor, alpha);
	auto color = new Color(d, rgb);
	scope (exit) color.dispose();
	gc.setForeground(color);
	gc.setBackground(color);
	gc.fillRectangle(0, 0, warningImageWidth, warningImageWidth);
	auto alphas = new byte[warningImageWidth * warningImageWidth];
	auto lastLine = alphas[(warningImageWidth - 1) * warningImageWidth .. $];
	foreach (i; 0 .. warningImageWidth) { mixin(S_TRACE);
		lastLine[i] = cast(byte)(cast(real)i / warningImageWidth * alpha);
	}
	foreach (y; 0 .. warningImageWidth - 1) { mixin(S_TRACE);
		auto line = alphas[y * warningImageWidth .. (y + 1) * warningImageWidth];
		line[$ - y .. $] = lastLine[0 .. y];
	}
	assert (alphas.length == warningImageWidth * warningImageWidth);
	auto imgData = buf.getImageData();
	imgData.setAlphas(0, 0, warningImageWidth * warningImageWidth, alphas, 0);
	return new Image(d, imgData);
}

private void drawCommentAndWarning(Item)(Props prop, bool isEventView, Image commentImg, Rectangle cib, Image warningImg, Rectangle wib, int caX, int caWidth, Item itm, GC gc, DrawingCW!Item drawing, in string[] warnings, int warningWidth, ref Image warningImage) { mixin(S_TRACE);
	if (warnings.length) { mixin(S_TRACE);
		if (!warningImage) { mixin(S_TRACE);
			warningImage = .warningImage(prop, itm.getDisplay(), warningWidth);
		}
		auto ib = itm.getBounds();
		gc.drawImage(warningImage, 0, 0, warningWidth, 1, caX + caWidth - warningWidth, ib.y, warningWidth, ib.height);
		gc.setAlpha(drawing.item is itm && drawing.type is DrawingType.Warning ? 255 : 128);
		auto pos = .warningPos(cib, wib, itm, isEventView);
		gc.drawImage(warningImg, pos.x, pos.y);
		gc.setAlpha(255);
	}
	auto comment = .commentText(.commentable(itm), isEventView);
	if (comment != "") { mixin(S_TRACE);
		gc.setAlpha(drawing.item is itm && drawing.type is DrawingType.Comment ? 255 : 128);
		auto pos = .commentPos(cib, itm);
		gc.drawImage(commentImg, pos.x, pos.y);
		gc.setAlpha(255);
	}
}

private void setupCommentToolTip(T, Item)(Commons comm, T table, bool isEventView, string[] delegate(Item itm) getWarnings, DrawingCW!Item drawing, Item delegate(Point pos) hitTest, Point delegate(Item itm) commentPos, Point delegate(Item itm) warningPos) { mixin(S_TRACE);
	auto commentImg = comm.prop.images.menu(MenuID.Comment);
	auto cib = commentImg.getBounds();
	auto warnImg = comm.prop.images.warning;
	auto wib = warnImg.getBounds();
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
		}
		string[] warnings;
		if (itm) { mixin(S_TRACE);
			warnings = getWarnings ? getWarnings(itm) : [];
		}
		if (comment == "" && !warnings.length) { mixin(S_TRACE);
			itm = null;
		}
		auto old = drawing.item;
		auto oldType = drawing.type;
		Point pos = null;
		if (itm) { mixin(S_TRACE);
			if (!pos && comment != "") { mixin(S_TRACE);
				auto cPos = commentPos(itm);
				if (cPos.x <= curPos.x && curPos.x < cPos.x + cib.width && cPos.y <= curPos.y && curPos.y < cPos.y + cib.height) { mixin(S_TRACE);
					if (drawing.item is itm && drawing.type is DrawingType.Comment) return;
					drawing.item = itm;
					drawing.type = DrawingType.Comment;
					pos = cPos;
				}
			}
			if (!pos && warnings.length) { mixin(S_TRACE);
				auto wPos = warningPos(itm);
				if (wPos.x <= curPos.x && curPos.x < wPos.x + wib.width && wPos.y <= curPos.y && curPos.y < wPos.y + wib.height) { mixin(S_TRACE);
					if (drawing.item is itm && drawing.type is DrawingType.Warning) return;
					drawing.item = itm;
					drawing.type = DrawingType.Warning;
					pos = wPos;
				}
			}
		}
		if (!pos) { mixin(S_TRACE);
			drawing.item = null;
			drawing.type = DrawingType.None;
		}
		if (old) { mixin(S_TRACE);
			assert (oldType !is DrawingType.None);
			auto dp = oldType is DrawingType.Comment ? commentPos(old) : warningPos(old);
			auto ib = oldType is DrawingType.Comment ? cib : wib;
			table.redraw(dp.x, dp.y, ib.width, ib.height, false);
		}

		string message;
		Rectangle ib;
		final switch (drawing.type) {
		case DrawingType.Comment:
			message = comment;
			ib = new Rectangle(pos.x, pos.y, cib.width, cib.height);
			break;
		case DrawingType.Warning:
			message = warnings.sort().uniq().join(.newline);
			ib = new Rectangle(pos.x, pos.y, wib.width, wib.height);
			break;
		case DrawingType.None:
			message = "";
			ib = null;
			break;
		}
		.createOrDestroyToolTip(table, message, toolTip, ib, &mouseMove);
		if (ib) { mixin(S_TRACE);
			table.redraw(pos.x, pos.y, ib.width, ib.height, false);
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

void createOrDestroyToolTip(Control parent, string message, ref ToolTip toolTip, Rectangle iconRect, void delegate() mouseTrack) { mixin(S_TRACE);
	if (message != "") { mixin(S_TRACE);
		if (toolTip && !toolTip.isDisposed() && toolTip.getParent() !is parent.getShell()) { mixin(S_TRACE);
			toolTip.dispose();
		}
		if (!toolTip || toolTip.isDisposed()) { mixin(S_TRACE);
			auto create = toolTip is null;
			toolTip = new ToolTip(parent.getShell(), SWT.BALLOON);
			toolTip.setAutoHide(false);
			auto display = parent.getDisplay();

			if (create) { mixin(S_TRACE);
				auto track = new class Runnable {
					override void run() { mixin(S_TRACE);
						if (parent.isDisposed()) return;
						if (!toolTip) return;
						if (!toolTip.isDisposed() && !toolTip.isVisible()) return;
						mouseTrack();
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
		toolTip.setMessage(message);
		auto p = parent.toDisplay(new Point(iconRect.x, iconRect.y));
		toolTip.setLocation(p.x + iconRect.width / 2, p.y + iconRect.height / 2);
		toolTip.setVisible(true);
	} else if (toolTip && !toolTip.isDisposed() && toolTip.isVisible()) { mixin(S_TRACE);
		toolTip.setVisible(false);
	}
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
