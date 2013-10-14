
module cwx.importutils;

import cwx.summary;
import cwx.flag;
import cwx.area;
import cwx.card;
import cwx.utils;
import cwx.path;
import cwx.motion;
import cwx.usecounter;
import cwx.imagesize;
import cwx.background;
import cwx.types;

import std.array;
import std.path;

/// インポートのオプション。
struct ImportOption {
	ImportTypeReference1 materials = ImportTypeReference1.NoOverwrite; /// 外部素材。
	ImportTypeReference1 variables = ImportTypeReference1.Rename; /// 状態変数。
	ImportTypeReference2 casts = ImportTypeReference2.NoImport; /// キャストカード。
	ImportTypeReference2 skills = ImportTypeReference2.NoImport; /// 特殊技能カード。
	ImportTypeReference2 items = ImportTypeReference2.NoImport; /// アイテムカード。
	ImportTypeReference2 beasts = ImportTypeReference2.NoImport; /// 召喚獣カード。
	ImportTypeReference2 infos = ImportTypeReference2.NoImport; /// 情報カード。
	ImportTypeReference2 areas = ImportTypeReference2.NoImport; /// エリア。
	ImportTypeReference2 battles = ImportTypeReference2.NoImport; /// バトル。
	ImportTypeReference2 packages = ImportTypeReference2.NoImport; /// パッケージ。
	ImportTypeIncluded includedFiles = ImportTypeIncluded.AsIs; /// 格納イメージ。
	ImportTypeIncluded includedBgImages = ImportTypeIncluded.AsIs; /// 格納イメージ(イメージセル)。
	ImportTypeIncluded hands = ImportTypeIncluded.AsIs; /// キャストの手札カード。
	ImportTypeIncluded beastsInMotions = ImportTypeIncluded.AsIs; /// 召喚獣召喚効果内の召喚獣カード。
}

/// ファイルをインポートするための情報。
struct ImportFile {
	string dst; /// コピー先ファイル名。
	string src; /// コピー元ファイル名。
}

/// インポート結果。実際の配置をこの情報に基づいて行う。
struct ImportResult {
	ImportFile[] materials; /// 外部素材。
	Flag[][string] flags; /// 状態変数。
	Step[][string] steps; /// ditto
	CastCard[ulong] casts; /// キャストカード。
	SkillCard[ulong] skills; /// 特殊技能カード。
	ItemCard[ulong] items; /// アイテムカード。
	BeastCard[ulong] beasts; /// 召喚獣カード。
	InfoCard[ulong] infos; /// 情報カード。
	Area[ulong] areas; /// エリア。
	Battle[ulong] battles; /// バトル。
	Package[ulong] packages; /// パッケージ。
}

/// fromからtoへインポートするためのデータを生成する。
/// 結果にはインポート対象の一覧が含まれるが、この関数の終了時点では
/// toへの追加は行われていない。ID等はto内で重複しないよう調節されるが、
/// 上書きが許可されていれば重複する可能性がある。
ImportResult importResource(Summary to, Summary from, in string[] resCWXPath, in ImportOption opt) { mixin(S_TRACE);
	ImportResult r;
	auto uc = new UseCounter;
	CWXPath[] objs;
	// 直接のインポート対象。
	foreach (cwxPath; resCWXPath) { mixin(S_TRACE);
		auto path = from.findCWXPath(cwxPath);
		T setUC(T)(in CWXPath obj) { mixin(S_TRACE);
			auto a = cast(const T)obj;
			if (!a) return null;
			auto b = cast(T)a.dup;
			assert (b !is null);
			b.setUseCounter(uc);
			objs ~= b;
			return b;
		}
		if (auto a = setUC!Area(path)) { mixin(S_TRACE);
			r.areas[a.id] = a;
		} else if (auto a = setUC!Battle(path)) { mixin(S_TRACE);
			r.battles[a.id] = a;
		} else if (auto a = setUC!Package(path)) { mixin(S_TRACE);
			r.packages[a.id] = a;
		} else if (auto a = setUC!CastCard(path)) { mixin(S_TRACE);
			r.casts[a.id] = a;
		} else if (auto a = setUC!SkillCard(path)) { mixin(S_TRACE);
			r.skills[a.id] = a;
		} else if (auto a = setUC!ItemCard(path)) { mixin(S_TRACE);
			r.items[a.id] = a;
		} else if (auto a = setUC!BeastCard(path)) { mixin(S_TRACE);
			r.beasts[a.id] = a;
		} else if (auto a = setUC!InfoCard(path)) { mixin(S_TRACE);
			r.infos[a.id] = a;
		} else { mixin(S_TRACE);
			throw new Exception("Can't import: " ~ cwxPath, __FILE__, __LINE__);
		}
	}

	void ref1(T, U)(ImportTypeReference1 type, T ucf, T uct, void delegate(U) put) { mixin(S_TRACE);
		final switch (type) {
		case ImportTypeReference1.Rename:
			foreach (path; ucf.keys()) { mixin(S_TRACE);
				put(path);
			}
			break;
		case ImportTypeReference1.NoOverwrite:
			foreach (path; ucf.keys()) { mixin(S_TRACE);
				if (!uct.get(path)) {
					put(path);
				}
			}
			break;
		case ImportTypeReference1.Overwrite:
			foreach (path; ucf.keys()) { mixin(S_TRACE);
				put(path);
			}
			break;
		case ImportTypeReference1.NoImport:
			break;
		}
	}
	auto sName = from.scenarioName.replace("\\", "");
	if (sName == "") sName = "_";
	bool ref2(T, U)(ImportTypeReference2 type, T ucf, U delegate(ulong) get, ref U[ulong] table) { mixin(S_TRACE);
		bool r = false;
		final switch (type) {
		case ImportTypeReference2.Rename:
			foreach (id; ucf.keys()) { mixin(S_TRACE);
				if (id.id !in table) { mixin(S_TRACE);
					auto a = get(id.id);
					if (!a) continue;
					a = cast(U)a.dup;
					static if (is(U:AbstractArea)) {
						a.name = sName ~ "\\" ~ a.name;
					}
					a.setUseCounter(uc);
					table[id] = a;
					r = true;
				}
			}
			break;
		case ImportTypeReference2.NoImport:
			break;
		}
		return r;
	}

	// エリア・カードのインポート。
	// インポート対象が増えるとさらに参照先が追加される可能性があるため、
	// 対象が増加しなくなるまで繰り返す。
	while (true) { mixin(S_TRACE);
		bool up = false;
		up = ref2(opt.areas, uc.area, &from.area, r.areas) || up;
		up = ref2(opt.battles, uc.battle, &from.battle, r.battles) || up;
		up = ref2(opt.packages, uc.packages, &from.cwPackage, r.packages) || up;
		up = ref2(opt.casts, uc.casts, &from.cwCast, r.casts) || up;
		up = ref2(opt.skills, uc.skill, &from.skill, r.skills) || up;
		up = ref2(opt.items, uc.item, &from.item, r.items) || up;
		up = ref2(opt.beasts, uc.beast, &from.beast, r.beasts) || up;
		up = ref2(opt.infos, uc.info, &from.info, r.infos) || up;
		if (!up) break;
	}

	// インポート先で重複しないようにエリア・カードのIDを振り直す。
	void renumbering(T)(in T[] toList, ref T[ulong] list) { mixin(S_TRACE);
		ulong minId = toList.length ? toList[$-1].id + 1 : 1;
		foreach (i, id; list.keys().sort) { mixin(S_TRACE);
			auto a = list[id];
			a.id = ulong.max - list.length + i;
			uc.change(T.toID(id), T.toID(a.id));
		}
		T[ulong] list2;
		foreach (i, id; list.keys().sort) { mixin(S_TRACE);
			auto a = list[id];
			auto oldId = a.id;
			a.id = minId;
			uc.change(T.toID(oldId), T.toID(a.id));
			list2[minId] = a;
			minId++;
		}
		list = list2;
	}
	renumbering(to.areas, r.areas);
	renumbering(to.battles, r.battles);
	renumbering(to.packages, r.packages);
	renumbering(to.casts, r.casts);
	renumbering(to.skills, r.skills);
	renumbering(to.items, r.items);
	renumbering(to.beasts, r.beasts);
	renumbering(to.infos, r.infos);

	// 素材のインポート。
	auto newFolder = createNewFileName(to.scenarioPath.buildPath(createNewFileName(from.scenarioPath.buildPath(from.scenarioPath.dirName().baseName()), true).baseName()), true).baseName();
	ref1(opt.materials, uc.path, to.useCounter.path, (PathId path) { mixin(S_TRACE);
		if (path.isBinImg) return;
		if (opt.variables is ImportTypeReference1.Rename) { mixin(S_TRACE);
			auto newPath = newFolder.buildPath(cast(string)path);
			r.materials ~= ImportFile(to.scenarioPath.buildPath(newPath), from.scenarioPath.buildPath(cast(string)path));
			uc.change(path, toPathId(newPath));
		} else { mixin(S_TRACE);
			r.materials ~= ImportFile(to.scenarioPath.buildPath(cast(string)path), from.scenarioPath.buildPath(cast(string)path));
		}
	});
	// 状態変数のインポート。
	auto newFlagDir = to.flagDirRoot.createNewDirName(from.flagDirRoot.createNewDirName(from.scenarioName, ""), "");
	ref1(opt.variables, uc.flag, to.useCounter.flag, (FlagId path) { mixin(S_TRACE);
		auto f = from.flagDirRoot.findFlag(cast(string)path);
		if (!f) return;
		auto o = new Flag(f);
		if (opt.variables is ImportTypeReference1.Rename) { mixin(S_TRACE);
			auto newPath = newFlagDir ~ "\\" ~ cast(string)path;
			r.flags[FlagDir.up(newFlagDir)] ~= o;
			uc.change(path, toFlagId(newPath));
		} else { mixin(S_TRACE);
			r.flags[FlagDir.up(cast(string)path)] ~= o;
		}
	});
	ref1(opt.variables, uc.step, to.useCounter.step, (StepId path) { mixin(S_TRACE);
		auto f = from.flagDirRoot.findStep(cast(string)path);
		if (!f) return;
		auto o = new Step(f);
		if (opt.variables is ImportTypeReference1.Rename) { mixin(S_TRACE);
			auto newPath = newFlagDir ~ "\\" ~ cast(string)path;
			r.steps[FlagDir.up(newFlagDir)] ~= o;
			uc.change(path, toStepId(newPath));
		} else { mixin(S_TRACE);
			r.steps[FlagDir.up(cast(string)path)] ~= o;
		}
	});

	// 手札カードの外部化・内部化
	if (opt.hands !is ImportTypeIncluded.AsIs) { mixin(S_TRACE);
		foreach (cc; r.casts) { mixin(S_TRACE);
			void outputRefCard(T)(T c, ref T[ulong] table, in T[] toArr, T delegate(ulong) get) { mixin(S_TRACE);
				if (opt.hands is ImportTypeIncluded.Exclude) {
					if (c.linkId) return;
					auto ids = table.keys().sort;
					auto id = ids.length ? ids[$-1] + 1 : (toArr.length ? toArr[$-1].id + 1 : 1);
					int index = cc.indexOf(c);
					cc.remove(c);
					auto nc = new T(c.id, "", "", "");
					nc.linkId = id;
					static if (is(typeof(c.hold))) nc.hold = c.hold;
					cc.insert(index, nc);
					c.id = id;
					static if (is(typeof(c.hold))) c.hold = false;
					table[id] = c;
				} else if (opt.hands is ImportTypeIncluded.Include) {
					if (!c.linkId) return;
					auto p = c.linkId in table;
					auto nc = p ? *p : get(c.linkId);
					if (!nc) return;
					nc = nc.dup;
					nc.id = c.id;
					static if (is(typeof(c.hold))) nc.hold = c.hold;
					int index = cc.indexOf(c);
					cc.remove(c);
					cc.insert(index, nc);
				}
			}
			foreach (c; cc.skills) outputRefCard(c, r.skills, to.skills, &from.skill);
			foreach (c; cc.items) outputRefCard(c, r.items, to.items, &from.item);
			foreach (c; cc.beasts) outputRefCard(c, r.beasts, to.beasts, &from.beast);
		}
	}
	// 召喚獣召喚効果内の召喚獣の外部化・内部化
	if (opt.beastsInMotions !is ImportTypeIncluded.AsIs) { mixin(S_TRACE);
		void recurseB(CWXPath path) { mixin(S_TRACE);
			auto childs = path.cwxChilds;
			if (auto b = cast(Motion)path) { mixin(S_TRACE);
				if (opt.beastsInMotions is ImportTypeIncluded.Exclude && b.beast && !b.beast.linkId) { mixin(S_TRACE);
					auto ids = r.beasts.keys().sort;
					auto id = ids.length ? ids[$-1] + 1 : 1;
					auto c = b.beast;
					auto nc = new BeastCard(c.id, "", "", "");
					nc.linkId = id;
					b.newBeast = nc;
					c.id = id;
					r.beasts[id] = c;
				} else if (opt.beastsInMotions is ImportTypeIncluded.Include && b.beast && b.beast.linkId) { mixin(S_TRACE);
					auto p = b.beast.linkId in r.beasts;
					auto beast = p ? *p : from.beast(b.beast.linkId);
					if (beast) { mixin(S_TRACE);
						b.newBeast = beast.dup;
					}
				}
			}
			foreach (child; childs) recurseB(cast(CWXPath)child);
		}
		foreach (a; r.areas) recurseB(a);
		foreach (a; r.battles) recurseB(a);
		foreach (a; r.packages) recurseB(a);
		foreach (a; r.casts) recurseB(a);
		foreach (a; r.skills) recurseB(a);
		foreach (a; r.items) recurseB(a);
		foreach (a; r.beasts) recurseB(a);
		foreach (a; r.infos) recurseB(a);
	}
	// 格納イメージの外部化・内部化
	if (opt.includedFiles !is ImportTypeIncluded.AsIs || opt.includedBgImages is ImportTypeIncluded.AsIs) { mixin(S_TRACE);
		void putBinImg(string binImg) { mixin(S_TRACE);
			auto bytes = strToBImg(binImg);
			auto ext = imageType(bytes);
			auto name = createNewName("simage(1)" ~ ext, (name) { mixin(S_TRACE);
				auto path = newFolder.buildPath(name);
				foreach (file; r.materials) {
					if (cfnmatch(file.dst, path)) {
						return false;
					}
				}
				return true;
			});
			r.materials ~= ImportFile(to.scenarioPath.buildPath(newFolder.buildPath(name)), binImg);
		}
		void includeImg(string path, void delegate(string) set) { mixin(S_TRACE);
			try {
				auto file = from.scenarioPath.buildPath(path);
				set(bImgToStr(cast(ubyte[])readBinary(file)));
			} catch (Exception e) {
				debugln(e);
			}
		}
		void recurseF(CWXPath path) { mixin(S_TRACE);
			auto childs = path.cwxChilds;
			if (auto c = cast(Card)path) { mixin(S_TRACE);
				if (opt.includedFiles is ImportTypeIncluded.Exclude && c.path.isBinImg()) { mixin(S_TRACE);
					putBinImg(c.path);
				} else if (opt.includedFiles is ImportTypeIncluded.Include && c.path.length) { mixin(S_TRACE);
					includeImg(c.path, &c.path);
				}
			}
			if (auto c = cast(MenuCard)path) { mixin(S_TRACE);
				if (opt.includedFiles is ImportTypeIncluded.Exclude && c.path.isBinImg()) { mixin(S_TRACE);
					putBinImg(c.path);
				} else if (opt.includedFiles is ImportTypeIncluded.Include && c.path.length) { mixin(S_TRACE);
					includeImg(c.path, &c.path);
				}
			}
			if (auto c = cast(ImageCell)path) { mixin(S_TRACE);
				if (opt.includedBgImages !is ImportTypeIncluded.Exclude && c.path.isBinImg()) { mixin(S_TRACE);
					putBinImg(c.path);
				} else if (opt.includedBgImages is ImportTypeIncluded.Include && c.path.length) { mixin(S_TRACE);
					includeImg(c.path, &c.path);
				}
			}
			foreach (child; childs) recurseF(cast(CWXPath)child);
		}
		foreach (a; r.areas) recurseF(a);
		foreach (a; r.battles) recurseF(a);
		foreach (a; r.packages) recurseF(a);
		foreach (a; r.casts) recurseF(a);
		foreach (a; r.skills) recurseF(a);
		foreach (a; r.items) recurseF(a);
		foreach (a; r.beasts) recurseF(a);
		foreach (a; r.infos) recurseF(a);
	}

	return r;
}
