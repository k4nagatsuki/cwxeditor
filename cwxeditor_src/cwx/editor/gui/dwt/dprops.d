
module cwx.editor.gui.dwt.dprops;

import cwx.utils;
import cwx.props;
import cwx.structs;
import cwx.menu;
import cwx.types;
import cwx.msgs;
import cwx.summary;

import cwx.editor.gui.dwt.image;
import cwx.editor.gui.dwt.properties;

import std.algorithm : max;
import std.conv;
import std.file;
import std.path;

import org.eclipse.swt.all;

import java.lang.all;
import java.io.ByteArrayInputStream;
import java.nonstandard.Locale;

public class Props {
private:
	CProps _parent;
	Images _images;
	FlexProps _var;
public:
	this (string confFilePath, CProps parent) { mixin(S_TRACE);
		string dStr = .text(__LINE__);
		try { mixin(S_TRACE);
			_parent = parent;
			dStr ~= " - " ~ .text(__LINE__);
			_images = new Images(_parent.appPath);
			dStr ~= " - " ~ .text(__LINE__);
			_var = new FlexProps(_parent.appPath, confFilePath);
			dStr ~= " - " ~ .text(__LINE__);

			// システムの言語
			string[string] msgsTableFile;
			string defLocale;
			dStr ~= " - " ~ .text(__LINE__);
			auto msgsTable = _parent.msgsTable(var.etc.languageDir, msgsTableFile, defLocale);
			dStr ~= " - " ~ .text(__LINE__);
			auto msgs = msgsTable.get(.caltureName(), null);
			dStr ~= " - " ~ .text(__LINE__);
			if (msgs) { mixin(S_TRACE);
				_parent.msgs = msgs;
			}
			dStr ~= " - " ~ .text(__LINE__);

			// 設定された言語
			if (!var.etc.useSystemLanguage && var.etc.languageFile.length) { mixin(S_TRACE);
				dStr ~= " - " ~ .text(__LINE__);
				auto langFile = toAppAbs(var.etc.languageDir).buildPath(var.etc.languageFile);
				dStr ~= " - " ~ .text(__LINE__);
				if (.exists(langFile)) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						dStr ~= " - " ~ .text(__LINE__);
						_parent.loadMsgs(langFile);
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
					dStr ~= " - " ~ .text(__LINE__);
				}
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);
		} catch (Throwable e) {
			printStackTrace();
			fdebugln(dStr);
			fdebugln(e);
			throw new Exception(dStr, __FILE__, __LINE__);
		}
	}
	@property
	const
	string enginePath() { mixin(S_TRACE);
		if (!var.etc.enginePath.length) return "";
		if (isAbsolute(var.etc.enginePath.value)) { mixin(S_TRACE);
			return var.etc.enginePath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.enginePath);
		}
	}
	@property
	const
	string tempPath() { mixin(S_TRACE);
		if (!var.etc.tempPath.length) return "";
		if (isAbsolute(var.etc.tempPath.value)) { mixin(S_TRACE);
			return var.etc.tempPath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.tempPath);
		}
	}
	@property
	const
	string backupPath() { mixin(S_TRACE);
		if (!var.etc.backupPath.length) return "";
		if (isAbsolute(var.etc.backupPath.value)) { mixin(S_TRACE);
			return var.etc.backupPath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.backupPath);
		}
	}
	@property
	const
	string backupBeforeSavePath() { mixin(S_TRACE);
		if (!var.etc.backupBeforeSavePath.length) return "";
		if (isAbsolute(var.etc.backupBeforeSavePath.value)) { mixin(S_TRACE);
			return var.etc.backupBeforeSavePath;
		} else { mixin(S_TRACE);
			return std.path.buildPath(std.path.dirName(parent.appPath), var.etc.backupBeforeSavePath);
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

	const
	string buildTool(MenuID id) { mixin(S_TRACE);
		return var.menu.buildTool(parent, id);
	}
	const
	string buildMenu(MenuID id) { mixin(S_TRACE);
		return var.menu.buildMenu(parent, id);
	}

	/// verがターゲットとなる環境のバージョン以下であればtrueを返す。
	const
	bool targetVersion(in Summary summ, string ver) { mixin(S_TRACE);
		if (summ && !summ.legacy) return true;
		return parent.targetVersion(ver, var.etc.targetVersion);
	}
	/// summが存在する場合はwsnVer以上かを返す。
	/// それ以外の場合は対象バージョンがCardWirthPyか否かを返す。
	const
	bool isTargetVersion(in Summary summ, string ver) { mixin(S_TRACE);
		return parent.isTargetVersion(summ, var.etc.targetVersion, ver);
	}

	/// 拡大率に応じた値に変換する。
	const
	int s(int s) { mixin(S_TRACE);
		return s * .max(1u, var.etc.imageScale);
	}
}

/// CPoint等の構造体をSWTのクラスに変換するための関数。
Point dwtData(CPoint v) {return new Point(v.x, v.y);}
/// ditto
Point dwtData(CSize v) {return new Point(v.width, v.height);}
/// ditto
RGB dwtData(CRGB v, out int alpha) { mixin(S_TRACE);
	alpha = v.a;
	return new RGB(cast(int) v.r, cast(int) v.g, cast(int) v.b);
}
/// ditto
FontData dwtData(CFont v) { mixin(S_TRACE);
	int flag = SWT.NONE;
	if (v.bold) flag |= SWT.BOLD;
	if (v.italic) flag |= SWT.ITALIC;
	return new FontData(v.name, cast(int) v.point, flag == SWT.NONE ? SWT.NORMAL : flag);
}
