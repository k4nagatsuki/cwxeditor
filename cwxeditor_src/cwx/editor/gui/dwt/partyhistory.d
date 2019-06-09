
module cwx.editor.gui.dwt.partyhistory;

import cwx.binary;
import cwx.cwl;
import cwx.menu;
import cwx.structs;
import cwx.types;
import cwx.utils;
import cwx.win32res;
import cwx.xml;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;

import core.thread;

import std.file;
import std.path;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

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
