
module cwx.editor.gui.dwt.dprops;

public import org.eclipse.swt.SWT;
public import org.eclipse.swt.graphics.Point;
public import org.eclipse.swt.graphics.RGB;
public import org.eclipse.swt.graphics.FontData;

import cwx.flag;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.area;
import cwx.card;
import cwx.summary;
import cwx.event;
import cwx.race;
import cwx.system;
import cwx.motion;
import cwx.props;
import cwx.structs;
import cwx.msgs;

import cwx.editor.gui.dwt.image;
import cwx.editor.gui.dwt.properties;

import std.file;
import std.path;
import std.conv;

import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import java.lang.all;
import java.io.ByteArrayInputStream;

enum MenuID : int {
	Refresh,
	CEdit,
	Undo,
	Redo,
	Cut,
	Copy,
	Paste,
	Del,
	ToXML,
	New,
	Open,
	Close,
	CloseWin,
	Save,
	SaveA,
	DataWin,
	FlagWin,
	CardWin,
	CastWin,
	SkillWin,
	ItemWin,
	BeastWin,
	InfoWin,
	DirWin,
	ChangeVH,
	ExecEngine,
	Settings,
	Summary,
	NewArea,
	NewBattle,
	NewPackage,
	NewFlagDir,
	NewFlag,
	NewStep,
	ViewParty,
	ViewMsg,
	Fixed,
	EnemyCardDebugView,
	ViewCards,
	ViewBacks,
	Up,
	Down,
	NewMenuCard,
	NewEnemyCard,
	NewBack,
	Auto,
	Custom,
	Mask,
	DoEscape,
	PosTop,
	PosBottom,
	PosLeft,
	PosRight,
	PosEven,
	ScaleMin,
	ScaleMiddle,
	ScaleMax,
	ScaleEvenBig,
	ScaleEvenSmall,
	NewEventTree,
	NewEventFire,
	TreeOpen,
	TreeClose,
	ShowCardLife,
	ShowCardList,
	ShowCardTable,
	AddScenario,
	NewCast,
	NewSkill,
	NewItem,
	NewBeast,
	NewInfo,
	Add,
	EditHand,
	OpenHand,
	EditUseEvent,
	OpenDirectory,
	ReNumbering,
	ReNumberingAll,
	NewFolder,
	ReplacePath,
	DeleteUnuse,
	ReplaceText,
	Reload,
	StartToPackage,
	ConvertContent,
	Version,
	ToScript,
	ToScriptAll,
	CreateArchive,
	OpenTableView,
	OpenFlagView,
	OpenCardView,
	OpenFileView,
	CopyFilePath,
	OpenEventTreeView,
	WriteComment,
	EditScene,
	EditEvent,
	KeyCodeTimingUse,
	KeyCodeTimingSuccess,
	KeyCodeTimingFailure,
	OpenView,
}

public class Props {
private:
	CProps _parent;
	Images _images;
	FlexProps _var;
public:
	this (string confFilePath, CProps parent) {
		string dStr = .text(__LINE__);
		try {
			_parent = parent;
			dStr ~= " - " ~ .text(__LINE__);
			_images = new Images(parent.appPath);
			dStr ~= " - " ~ .text(__LINE__);
			_var = new FlexProps(parent.appPath, confFilePath);
			dStr ~= " - " ~ .text(__LINE__);
		} catch (Throwable e) {
			fdebugln(dStr);
			// FIXME: リンクエラー！
//			fdebugln(e);
			throw e;
		}
	}
	@property
	const
	string enginePath() {
		if (!var.etc.enginePath.length) return "";
		if (cwx.utils.isabs(var.etc.enginePath)) {
			return var.etc.enginePath;
		} else {
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.enginePath);
		}
	}
	@property
	const
	string tempPath() {
		if (!var.etc.tempPath.length) return "";
		if (cwx.utils.isabs(var.etc.tempPath)) {
			return var.etc.tempPath;
		} else {
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.tempPath);
		}
	}
	@property
	const
	string backupPath() {
		if (!var.etc.backupPath.length) return "";
		if (cwx.utils.isabs(var.etc.backupPath)) {
			return var.etc.backupPath;
		} else {
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.backupPath);
		}
	}
	@property
	const
	const(CProps) parent() {return _parent;}
	@property
	const
	const(cwx.system.System) sys() {return _parent.sys;}
	@property
	Images images() {return _images;}
	@property
	const
	const(Msgs) msgs() {return _parent.msgs;}
	@property
	const
	const(Looks) looks() {return _parent.looks;}
	@property
	FlexProps var() {return _var;}
	@property
	const
	const(FlexProps) var() {return _var;}

	const
	string toAppAbs(string path) {return parent.toAppAbs(path);}
}

/// CPoint等の構造体をSWTのクラスに変換するための関数。
Point dwtData(CPoint v) {return new Point(v.x, v.y);}
/// ditto
Point dwtData(CSize v) {return new Point(v.width, v.height);}
/// ditto
RGB dwtData(CRGB v, out int alpha) {
	alpha = v.a;
	return new RGB(cast(int) v.r, cast(int) v.g, cast(int) v.b);
}
/// ditto
FontData dwtData(CFont v) {
	int flag = SWT.NONE;
	if (v.bold) flag |= SWT.BOLD;
	if (v.italic) flag |= SWT.ITALIC;
	return new FontData(v.name, cast(int) v.point, flag == SWT.NONE ? SWT.NORMAL : flag);
}
