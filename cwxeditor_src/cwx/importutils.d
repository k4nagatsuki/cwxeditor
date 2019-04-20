
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
import cwx.props;

static import std.algorithm;
import std.array;
import std.path;
import std.file;

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
	bool overwriteScenarioInfo = false; /// シナリオ名とシナリオ作者の情報を書き換えるか。
}

/// ファイルをインポートするための情報。
struct ImportFile {
	string dst; /// コピー先ファイル名。
	string src; /// コピー元ファイル名。
	bool overwrite; /// 上書きする場合はtrue。
}

/// フラグをインポートするための情報。
struct ImportFlag {
	string path; /// 追加先のディレクトリパス。
	Flag flag; /// フラグ。
	bool overwrite; /// 上書きする場合はtrue。
	/// フラグ名。
	const
	string name() { return flag.name; }
}
/// ステップをインポートするための情報。
struct ImportStep {
	string path; /// 追加先のディレクトリパス。
	Step step; /// ステップ。
	bool overwrite; /// 上書きする場合はtrue。
	/// ステップ名。
	const
	string name() { return step.name; }
}
/// コモンをインポートするための情報。
struct ImportVariant {
	string path; /// 追加先のディレクトリパス。
	Variant variant; /// コモン。
	bool overwrite; /// 上書きする場合はtrue。
	/// コモン名。
	const
	string name() { return variant.name; }
}

/// インポート結果。実際の配置をこの情報に基づいて行う。
struct ImportResult {
	ImportFile[] materials; /// 外部素材。
	ImportFlag[][string] flags; /// 状態変数。
	ImportStep[][string] steps; /// ditto
	ImportVariant[][string] variants; /// ditto
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
ImportResult importResource(in CProps prop, Summary to, Summary from, in string[] resCWXPath, in ImportOption opt) { mixin(S_TRACE);
	ImportResult r;
	auto uc = new UseCounter(null);
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

	void ref1(ID)(ImportTypeReference1 type, void delegate(ID) put) { mixin(S_TRACE);
		final switch (type) {
		case ImportTypeReference1.Rename:
			foreach (path; uc.keys!ID) { mixin(S_TRACE);
				put(path);
			}
			break;
		case ImportTypeReference1.NoOverwrite:
			foreach (path; uc.keys!ID) { mixin(S_TRACE);
				put(path);
			}
			break;
		case ImportTypeReference1.Overwrite:
			foreach (path; uc.keys!ID) { mixin(S_TRACE);
				put(path);
			}
			break;
		case ImportTypeReference1.NoImport:
			break;
		}
	}
	auto sName = from.scenarioName.replace("\\", "");
	if (sName == "") sName = "_";
	bool ref2(ID, U)(ImportTypeReference2 type, U delegate(ulong) get, ref U[ulong] table) { mixin(S_TRACE);
		bool r = false;
		final switch (type) {
		case ImportTypeReference2.Rename:
			foreach (id; uc.keys!ID) { mixin(S_TRACE);
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
		up = ref2!AreaId(opt.areas, &from.area, r.areas) || up;
		up = ref2!BattleId(opt.battles, &from.battle, r.battles) || up;
		up = ref2!PackageId(opt.packages, &from.cwPackage, r.packages) || up;
		up = ref2!CastId(opt.casts, (id) => from.cwCast(id), r.casts) || up;
		up = ref2!SkillId(opt.skills, (id) => from.skill(id), r.skills) || up;
		up = ref2!ItemId(opt.items, (id) => from.item(id), r.items) || up;
		up = ref2!BeastId(opt.beasts, (id) => from.beast(id), r.beasts) || up;
		up = ref2!InfoId(opt.infos, (id) => from.info(id), r.infos) || up;
		if (!up) break;
	}

	// インポート先で重複しないようにエリア・カードのIDを振り直す。
	void renumbering(T)(in T[] toList, ref T[ulong] list) { mixin(S_TRACE);
		ulong minId = toList.length ? toList[$-1].id + 1 : 1;
		foreach (i, id; std.algorithm.sort(list.keys()).array()) { mixin(S_TRACE);
			auto a = list[id];
			a.id = ulong.max - list.length + i;
			uc.change(T.toID(id), T.toID(a.id));
		}
		T[ulong] list2;
		foreach (i, id; std.algorithm.sort(list.keys()).array()) { mixin(S_TRACE);
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
	auto newFolder = createNewFileName(to.scenarioPath.buildPath(createNewFileName(to.scenarioPath.buildPath(from.scenarioPath.baseName()), true).baseName()), true).baseName();
	ref1(opt.materials, (PathId path) { mixin(S_TRACE);
		if (path.isBinData) return;
		if (!from.scenarioPath.buildPath(cast(string)path).exists()) return;
		if (opt.materials is ImportTypeReference1.Rename) { mixin(S_TRACE);
			auto newPath = newFolder.buildPath(cast(string)path);
			r.materials ~= ImportFile(to.scenarioPath.buildPath(newPath), from.scenarioPath.buildPath(cast(string)path), false);
			uc.change(path, toPathId(newPath));
		} else { mixin(S_TRACE);
			auto dst = to.scenarioPath.buildPath(cast(string)path);
			bool overwrite = dst.exists();
			if (!overwrite || opt.materials !is ImportTypeReference1.NoOverwrite) { mixin(S_TRACE);
				r.materials ~= ImportFile(dst, from.scenarioPath.buildPath(cast(string)path), overwrite);
			}
		}
	});
	// 状態変数のインポート。
	auto newFlagDir = to.flagDirRoot.createNewDirName(from.flagDirRoot.createNewDirName(from.scenarioName, ""), "");
	ref1(opt.variables, (FlagId path) { mixin(S_TRACE);
		auto f = from.flagDirRoot.findFlag(cast(string)path);
		if (!f) return;
		auto o = new Flag(f);
		if (opt.variables is ImportTypeReference1.Rename) { mixin(S_TRACE);
			auto newPath = FlagDir.join(newFlagDir, cast(string)path);
			auto dir = FlagDir.up(newPath);
			r.flags[dir] ~= ImportFlag(dir, o, false);
			uc.change(path, toFlagId(newPath));
		} else { mixin(S_TRACE);
			bool overwrite = to.flagDirRoot.getFlag(cast(string)path) !is null;
			if (!overwrite || opt.variables !is ImportTypeReference1.NoOverwrite) { mixin(S_TRACE);
				auto dir = FlagDir.up(cast(string)path);
				r.flags[dir] ~= ImportFlag(dir, o, overwrite);
			}
		}
	});
	ref1(opt.variables, (StepId path) { mixin(S_TRACE);
		auto f = from.flagDirRoot.findStep(cast(string)path);
		if (!f) return;
		auto o = new Step(f);
		if (opt.variables is ImportTypeReference1.Rename) { mixin(S_TRACE);
			auto newPath = FlagDir.join(newFlagDir, cast(string)path);
			auto dir = FlagDir.up(newPath);
			r.steps[dir] ~= ImportStep(dir, o, false);
			uc.change(path, toStepId(newPath));
		} else { mixin(S_TRACE);
			bool overwrite = to.flagDirRoot.getStep(cast(string)path) !is null;
			if (!overwrite || opt.variables !is ImportTypeReference1.NoOverwrite) { mixin(S_TRACE);
				auto dir = FlagDir.up(cast(string)path);
				r.steps[dir] ~= ImportStep(dir, o, overwrite);
			}
		}
	});
	ref1(opt.variables, (VariantId path) { mixin(S_TRACE);
		auto f = from.flagDirRoot.findVariant(cast(string)path);
		if (!f) return;
		auto o = new Variant(f);
		if (opt.variables is ImportTypeReference1.Rename) { mixin(S_TRACE);
			auto newPath = FlagDir.join(newFlagDir, cast(string)path);
			auto dir = FlagDir.up(newPath);
			r.variants[dir] ~= ImportVariant(dir, o, false);
			uc.change(path, toVariantId(newPath));
		} else { mixin(S_TRACE);
			bool overwrite = to.flagDirRoot.getVariant(cast(string)path) !is null;
			if (!overwrite || opt.variables !is ImportTypeReference1.NoOverwrite) { mixin(S_TRACE);
				auto dir = FlagDir.up(cast(string)path);
				r.variants[dir] ~= ImportVariant(dir, o, overwrite);
			}
		}
	});

	// 手札カードの外部化・内部化
	if (opt.hands !is ImportTypeIncluded.AsIs) { mixin(S_TRACE);
		foreach (cc; r.casts) { mixin(S_TRACE);
			void outputRefCard(T)(T c, ref T[ulong] table, in T[] toArr, T delegate(ulong) get) { mixin(S_TRACE);
				if (opt.hands is ImportTypeIncluded.Exclude) {
					if (c.linkId) return;
					auto ids = table.keys();
					std.algorithm.sort(ids);
					auto id = ids.length ? ids[$-1] + 1 : (toArr.length ? toArr[$-1].id + 1 : 1);
					auto index = cc.indexOf(c);
					cc.remove(c);
					auto nc = new T(c.id, "", [], "");
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
					auto index = cc.indexOf(c);
					cc.remove(c);
					cc.insert(index, nc);
				}
			}
			foreach (c; cc.skills) outputRefCard(c, r.skills, to.skills, (id) => from.skill(id));
			foreach (c; cc.items) outputRefCard(c, r.items, to.items, (id) => from.item(id));
			foreach (c; cc.beasts) outputRefCard(c, r.beasts, to.beasts, (id) => from.beast(id));
		}
	}
	// 召喚獣召喚効果内の召喚獣の外部化・内部化
	if (opt.beastsInMotions !is ImportTypeIncluded.AsIs) { mixin(S_TRACE);
		void recurseB(CWXPath path) { mixin(S_TRACE);
			auto childs = path.cwxChilds;
			if (auto b = cast(Motion)path) { mixin(S_TRACE);
				if (opt.beastsInMotions is ImportTypeIncluded.Exclude && b.beast && !b.beast.linkId) { mixin(S_TRACE);
					auto ids = r.beasts.keys();
					std.algorithm.sort(ids);
					auto id = ids.length ? ids[$-1] + 1 : 1;
					auto c = b.beast;
					auto nc = new BeastCard(c.id, "", [], "");
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
	// 格納イメージの外部化・内部化及びシナリオ情報の書き換え
	if (opt.includedFiles !is ImportTypeIncluded.AsIs || opt.includedBgImages is ImportTypeIncluded.AsIs || opt.overwriteScenarioInfo) { mixin(S_TRACE);
		string putBinImg(string name, string binImg) { mixin(S_TRACE);
			auto bytes = strToBImg(binImg);
			auto ext = imageType(bytes);
			auto fileName = createNewName(cleanFileName(name), (name) { mixin(S_TRACE);
				auto path = to.scenarioPath.buildPath(newFolder.buildPath(name)) ~ ext;
				foreach (file; r.materials) {
					if (cfnmatch(file.dst, path)) {
						return false;
					}
				}
				return true;
			}, false);
			auto path = newFolder.buildPath(fileName) ~ ext;
			r.materials ~= ImportFile(to.scenarioPath.buildPath(path), binImg);
			uc.change(toPathId(binImg), toPathId(path));
			return path;
		}
		string includeImg(string path) { mixin(S_TRACE);
			try {
				auto file = from.scenarioPath.buildPath(path);
				if (file.exists()) { mixin(S_TRACE);
					ubyte* ptr = null;
					auto bin = readBinaryFrom!ubyte(file, ptr);
					scope (exit) freeAll(ptr);
					return bImgToStr(bin);
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
			return path;
		}
		void recurseF(string name, CWXPath path) { mixin(S_TRACE);
			auto childs = path.cwxChilds;
			if (opt.includedFiles !is ImportTypeIncluded.AsIs || opt.includedBgImages is ImportTypeIncluded.AsIs) { mixin(S_TRACE);
				if (auto c = cast(Card)path) { mixin(S_TRACE);
					CardImage[] paths;
					foreach (imgPath; c.paths) { mixin(S_TRACE);
						if (imgPath.type is CardImageType.File) { mixin(S_TRACE);
							if (opt.includedFiles is ImportTypeIncluded.Exclude && imgPath.path.isBinImg()) { mixin(S_TRACE);
								auto eName = .toExportedImageNameWithCardName(prop, from.scenarioName, from.author, c.name);
								imgPath = new CardImage(putBinImg(eName, imgPath.path), imgPath.positionType);
							} else if (opt.includedFiles is ImportTypeIncluded.Include && imgPath.path.length) { mixin(S_TRACE);
								imgPath = new CardImage(includeImg(imgPath.path), imgPath.positionType);
							}
						}
						paths ~= imgPath;
					}
					c.paths = paths;
				}
				if (auto c = cast(MenuCard)path) { mixin(S_TRACE);
					CardImage[] paths;
					foreach (imgPath; c.paths) { mixin(S_TRACE);
						if (imgPath.type is CardImageType.File) { mixin(S_TRACE);
							if (opt.includedFiles is ImportTypeIncluded.Exclude && imgPath.path.isBinImg()) { mixin(S_TRACE);
								auto eName = .toExportedImageNameWithCardName(prop, from.scenarioName, from.author, c.name);
								imgPath = new CardImage(putBinImg(eName, imgPath.path), imgPath.positionType);
							} else if (opt.includedFiles is ImportTypeIncluded.Include && imgPath.path.length) { mixin(S_TRACE);
								imgPath = new CardImage(includeImg(imgPath.path), imgPath.positionType);
							}
						}
						paths ~= imgPath;
					}
					c.paths = paths;
				}
				if (auto c = cast(ImageCell)path) { mixin(S_TRACE);
					if (opt.includedBgImages !is ImportTypeIncluded.Exclude && c.path.isBinImg()) { mixin(S_TRACE);
						auto eName = .toExportedImageNameWithCardName(prop, from.scenarioName, from.author, c.cellName);
						c.path = putBinImg(eName, c.path);
					} else if (opt.includedBgImages is ImportTypeIncluded.Include && c.path.length) { mixin(S_TRACE);
						c.path = includeImg(c.path);
					}
				}
			}
			if (opt.overwriteScenarioInfo) { mixin(S_TRACE);
				if (auto c = cast(EffectCard)path) { mixin(S_TRACE);
					c.scenario = to.scenarioName;
					c.author = to.author;
				}
			}
			foreach (child; childs) recurseF(name, cast(CWXPath)child);
		}
		foreach (a; r.areas) recurseF(a.name, a);
		foreach (a; r.battles) recurseF(a.name, a);
		foreach (a; r.packages) recurseF(a.name, a);
		foreach (a; r.casts) recurseF(a.name, a);
		foreach (a; r.skills) recurseF(a.name, a);
		foreach (a; r.items) recurseF(a.name, a);
		foreach (a; r.beasts) recurseF(a.name, a);
		foreach (a; r.infos) recurseF(a.name, a);
	}

	return r;
}
