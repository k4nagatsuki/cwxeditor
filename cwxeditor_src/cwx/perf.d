/// パフォーマンスカウンタ。コンソール/デバグビルドでない場合は無効。
module cwx.perf;

version (Console) {
	debug {
		import std.datetime;
		import std.string;
		import std.metastrings;
		import std.stdio;

		StopWatch initTimer;
		static this () {
			initTimer.start();
		}

		__gshared ulong utperf = 0;
		__gshared ulong t[1024u];
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
				~ ".t[" ~ .toStringNow!(I) ~ "] += f_timer.peek().msecs;"
				~ "}";
		}
		/// mixin(BPerfS)とmixin(BPerf!N)でブロックの実行時間を計測する。
		const BPerfS = "scope b_timer = new std.datetime.StopWatch(std.datetime.AutoStart.yes);";
		template BPerf(int I) {
			static const BPerf
				= "b_timer.stop();"
				~ ".t[" ~ .toStringNow!(I) ~ "] += b_timer.peek().msecs;"
				~ "b_timer.reset();"
				~ "b_timer.start();";
		}
		/// unittestの実行時間を計測する。
		static const UTPerf
			= "scope f_timer = std.datetime.StopWatch(std.datetime.AutoStart.yes);"
			~ "scope (exit) {"
			~ "f_timer.stop();"
			~ ".utperf += f_timer.peek().msecs;"
			~ "}";
		static assert (FPerf!(10));
		static assert (BPerf!(10));
	}
}
