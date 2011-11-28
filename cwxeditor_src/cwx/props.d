
module cwx.props;

import cwx.system;
import cwx.msgs;
import cwx.utils;

import std.path;

public class CProps {
private:
	cwx.system.System _sys;
	Msgs _msgs;
	Looks _looks;
	string _appPath;
public:
	this(string appPath, cwx.system.System sys) {
		_appPath = appPath;
		_sys = sys;
		_msgs = new Msgs;
		_looks = new Looks;
	}
	const string appPath() {return _appPath;}
	const const(cwx.system.System) sys() {return _sys;}
	const const(Msgs) msgs() {return _msgs;}
	const const(Looks) looks() {return _looks;}
	const string toAppAbs(string path) {
		if (cwx.utils.isabs(path)) return nabs(path);
		return nabs(std.path.buildPath(_appPath, path));
	}
}
