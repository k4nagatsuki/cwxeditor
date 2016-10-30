/// パフォーマンスカウンタ。コンソール/デバグビルドでない場合は無効。
module cwx.perf;

struct StackTrace {
	string file;
	size_t line;
}
StackTrace[] tStack, stStack;
size_t tStackLen = 0;
immutable S_TRACE = `.putStack(__FILE__, __LINE__);
	scope (exit) .tStackLen--;
	scope (failure) .saveStack();
`;
void putStack(string file, size_t line) {
	if (!.tStack.length) {
		.tStack = new StackTrace[8];
	} else if (.tStack.length <= .tStackLen) {
		.tStack.length *= 2;
	}
	.tStack[.tStackLen] = StackTrace(file, line);
	.tStackLen++;
}
void saveStack() {
	if (!stStack.length) {
		stStack = tStack[0 .. tStackLen].dup;
	}
}

debug {
	version (Console) {
		import std.datetime;
		import std.string;
		import std.conv;
		import std.stdio;

		StopWatch initTimer;
		static this () {
			initTimer.start();
		}

		__gshared ulong utperf = 0;
		__gshared ulong[1024u] t;
		shared static ~this () {
			foreach (i, time; t) {
				if (time > 0u) {
					writeln(format("%04d = ", i), time);
				}
			}
		}
		/// mixin(FPerf!N)でスコープ内の実行時間を計測する。
		template FPerf(int I) {
			static const FPerf
				= "scope f_timer = std.datetime.StopWatch(std.datetime.AutoStart.yes);"
				~ "scope (exit) {"
				~ "f_timer.stop();"
				~ ".t[" ~ .to!string(I) ~ "] += f_timer.peek().msecs;"
				~ "}";
		}
		/// mixin(BPerfS)とmixin(BPerf!N)でブロックの実行時間を計測する。
		const BPerfS = "scope b_timer = new std.datetime.StopWatch(std.datetime.AutoStart.yes);";
		template BPerf(int I) {
			static const BPerf
				= "b_timer.stop();"
				~ ".t[" ~ .to!string(I) ~ "] += b_timer.peek().msecs;"
				~ "b_timer.reset();"
				~ "b_timer.start();";
		}
		/// unittestの実行時間を計測する。
		static const UTPerf
			= "static import std.datetime;"
			~ "scope f_timer = std.datetime.StopWatch(std.datetime.AutoStart.yes);"
			~ "scope (exit) {"
			~ "f_timer.stop();"
			~ ".utperf += f_timer.peek().msecs;"
			~ "}";
		static assert (FPerf!(10));
		static assert (BPerf!(10));
	} else {
		static immutable UTPerf = "";
	}
}
