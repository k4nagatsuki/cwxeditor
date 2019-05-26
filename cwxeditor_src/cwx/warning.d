
module cwx.warning;

import cwx.area;
import cwx.background;
import cwx.binary;
import cwx.card;
import cwx.event;
import cwx.expression;
import cwx.features;
import cwx.flag;
import cwx.imagesize;
import cwx.motion;
import cwx.msgutils;
import cwx.path;
import cwx.props;
import cwx.sjis;
import cwx.skin;
import cwx.summary;
import cwx.types;
import cwx.usecounter;
import cwx.utils;

import std.algorithm;
import std.ascii;
import std.conv;
import std.path;
import std.stdio;
import std.string;
import std.traits;
import std.typecons : Tuple;

/// pathの内容を調査し、警告すべき点があればメッセージ群を返す。
string[] warnings(in CProps prop, in Skin skin, in Summary summ, in CWXPath path, string targVer) { mixin(S_TRACE);
	if (!summ || !summ.legacy) targVer = "";
	auto wsnVer = summ ? summ.dataVersion : LATEST_VERSION;
	auto sPath = summ ? summ.scenarioPath : "";
	auto froot = summ ? summ.flagDirRoot : null;
	string[] r;

	void putCardImages(in CardImage[] imagePaths, bool includeType) { mixin(S_TRACE);
		bool warnPos = false;
		foreach (imagePath; imagePaths) { mixin(S_TRACE);
			if (imagePath.type is CardImageType.File) { mixin(S_TRACE);
				if (imagePath.path != "" && !isBinImg(imagePath.path) && !skin.findPath(imagePath.path, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(imagePath.path));
				}
				if (imagePath.path != "") {
					r ~= skin.warningImage(prop, imagePath.path, summ ? summ.legacy : false, includeType, targVer);
				}
			}
			if (imagePath.type is CardImageType.PCNumber && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningPCNumberClassic;
			}
			if (!warnPos && imagePath.positionType !is CardImagePosition.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardImagePosition;
				warnPos = true;
			}
		}
	}

	auto psumm = cast(Summary)path;
	if (psumm) { mixin(S_TRACE);
		putCardImages(psumm.imagePaths, true);
		if (psumm.levelMin > psumm.levelMax) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (!psumm.area(psumm.startArea)) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorStartAreaNotFound;
		}
		r ~= .sjisWarnings(prop, summ, psumm.scenarioName, prop.msgs.title);
		r ~= .sjisWarnings(prop, summ, psumm.desc, prop.msgs.desc);
		r ~= .sjisWarnings(prop, summ, psumm.author, prop.msgs.author);
		foreach (rc; psumm.rCoupons) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, rc, prop.msgs.rCoupons);
		}
	}

	auto spChars = skin.spChars;
	auto checkTextRes(string text, in UseCounter uc, in string[] flags, in string[] steps, in string[] variants, in string[] fonts, in char[] colors,
			ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wVariants, ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
		return .textWarnings(prop, skin, summ, uc, targVer, text, flags, steps, variants, fonts, colors, wFlags, wSteps, wVariants, wFonts, wColors);
	}
	string[] checkTextRes2(string text, in UseCounter uc, in string[] flags, in string[] steps, in string[] variants, in string[] fonts, in char[] colors) { mixin(S_TRACE);
		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wVariants;
		bool[string] wFonts;
		bool[char] wColors;
		return checkTextRes(text, uc, flags, steps, variants, fonts, colors, wFlags, wSteps, wVariants, wFonts, wColors).all;
	}

	auto flagDir = cast(FlagDir)path;
	if (flagDir) { mixin(S_TRACE);
		if (flagDir.parent is froot && prop.sys.isSystemVar(flagDir.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, flagDir.name);
		}
		r ~= .sjisWarnings(prop, summ, flagDir.name, "");
	}
	auto flag = cast(cwx.flag.Flag)path;
	if (flag) { mixin(S_TRACE);
		if (flag.parent is froot && prop.sys.isSystemVar(flag.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, flag.name);
		}
		if (flag.expandSPChars && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningExpandSPChars;
		}
		if (cast(Summary)flag.useCounter.owner && flag.initialization !is VariableInitialization.Leave && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningVariableInitialization;
		}
		r ~= .sjisWarnings(prop, summ, flag.name, prop.msgs.dlgLblFlagName);
		r ~= .sjisWarnings(prop, summ, flag.on, prop.msgs.flagOnValue);
		r ~= .sjisWarnings(prop, summ, flag.off, prop.msgs.flagOffValue);
		if (flag.expandSPChars) { mixin(S_TRACE);
			r ~= checkTextRes2(flag.on, flag.useCounter, flag.flagsInText(true), flag.stepsInText(true), flag.variantsInText(true), [], []);
			r ~= checkTextRes2(flag.off, flag.useCounter, flag.flagsInText(false), flag.stepsInText(false), flag.variantsInText(false), [], []);
		}
	}
	auto step = cast(Step)path;
	if (step) { mixin(S_TRACE);
		if (step.parent is froot && prop.sys.isSystemVar(step.name)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSystemVariable, step.name);
		}
		if (step.count != prop.looks.stepMaxCount && summ && summ.legacy) {
			r ~= .tryFormat(prop.msgs.warningStepCount, prop.looks.stepMaxCount);
		}
		if (step.expandSPChars && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningExpandSPChars;
		}
		if (cast(Summary)step.useCounter.owner && step.initialization !is VariableInitialization.Leave && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningVariableInitialization;
		}
		r ~= .sjisWarnings(prop, summ, step.name, prop.msgs.dlgLblStepName);
		foreach (val; step.values) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, val, prop.msgs.stepValueForWarning);
		}
		if (step.expandSPChars) { mixin(S_TRACE);
			foreach (i; 0u .. step.count) { mixin(S_TRACE);
				r ~= checkTextRes2(step.values[i], step.useCounter, step.flagsInText(i), step.stepsInText(i), step.variantsInText(i), [], []);
			}
		}
	}
	if (auto variant = cast(Variant)path) { mixin(S_TRACE);
		if (!prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningVariant;
		}
	}
	auto eventTree = cast(EventTree)path;
	if (eventTree) { mixin(S_TRACE);
		if (eventTree.fireEveryRound && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningEveryRound;
		}
		if (eventTree.fireRoundEnd && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningRoundEnd;
		}
		if (eventTree.fireRound0 && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningRound0;
		}
		if (eventTree.keyCodeMatchingType is MatchingType.And && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningKeyCodeMatchingTypeAnd;
		}
		if (eventTree.keyCodes.length && prop.sys.convFireKeyCode(eventTree.keyCodes[0]) == "MatchingType=All") { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorKeyCodeMatchingAll;
		}
		foreach (keyCode; eventTree.keyCodes) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, keyCode.keyCode, prop.msgs.keyCode);
			if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				if (keyCode.kind is FKCKind.HasNot) { mixin(S_TRACE);
					r ~= prop.msgs.warningHasNotKeyCode;
				}
			}
		}
	}
	auto playerEvents = cast(PlayerCardEvents)path;
	if (playerEvents) { mixin(S_TRACE);
		if (playerEvents.trees.length && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningPlayerCardEvents;
		}
	}
	auto casts = cast(CastCard)path;
	if (casts) { mixin(S_TRACE);
		foreach (cc; casts.coupons) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, cc.coupon, prop.msgs.history);
			if (cc.coupon.startsWith(prop.sys.couponSystem) && cc.coupon != prop.sys.levelLimit && cc.coupon != prop.sys.ep && !prop.sys.isGene(cc.coupon)) { mixin(S_TRACE);
				r ~= prop.msgs.warningSystemCouponForHistory;
			}
		}
		foreach (c; casts.skills) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.skill(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdSkillNotFound, c.linkId);
			}
		}
		foreach (c; casts.items) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.item(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdItemNotFound, c.linkId);
			}
		}
		foreach (c; casts.beasts) { mixin(S_TRACE);
			if (0 != c.linkId && !(summ && summ.beast(c.linkId))) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorLinkIdBeastNotFound, c.linkId);
			}
		}

		Status[] statuses;
		if (casts.life == 0) { mixin(S_TRACE);
			statuses ~= Status.Unconscious;
		} else if (casts.life <= casts.lifeMax / 5) { mixin(S_TRACE);
			statuses ~= Status.HeavyInjured;
		} else if (casts.life < casts.lifeMax) { mixin(S_TRACE);
			statuses ~= Status.Injured;
		} else { mixin(S_TRACE);
			statuses ~= Status.Fine;
		}
		foreach (enh; EnumMembers!Enhance) { mixin(S_TRACE);
			if (casts.enhanceRound(enh) <= 0) continue;
			if (casts.enhance(enh) < 0) { mixin(S_TRACE);
				final switch (enh) {
				case Enhance.Action:
					statuses ~= Status.DownAction;
					break;
				case Enhance.Avoid:
					statuses ~= Status.DownAvoid;
					break;
				case Enhance.Resist:
					statuses ~= Status.DownResist;
					break;
				case Enhance.Defense:
					statuses ~= Status.DownDefense;
					break;
				}
			} else if (0 < casts.enhance(enh)) {
				final switch (enh) {
				case Enhance.Action:
					statuses ~= Status.UpAction;
					break;
				case Enhance.Avoid:
					statuses ~= Status.UpAvoid;
					break;
				case Enhance.Resist:
					statuses ~= Status.UpResist;
					break;
				case Enhance.Defense:
					statuses ~= Status.UpDefense;
					break;
				}
			}
		}
		if (0 < casts.paralyze) { mixin(S_TRACE);
			statuses ~= Status.Paralyze;
		}
		if (0 < casts.poison) { mixin(S_TRACE);
			statuses ~= Status.Poison;
		}
		if (0 < casts.bindRound) { mixin(S_TRACE);
			statuses ~= Status.Bind;
		}
		if (0 < casts.silenceRound) { mixin(S_TRACE);
			statuses ~= Status.Silence;
		}
		if (0 < casts.faceUpRound) { mixin(S_TRACE);
			statuses ~= Status.FaceUp;
		}
		if (0 < casts.antiMagicRound) { mixin(S_TRACE);
			statuses ~= Status.AntiMagic;
		}
		if (0 < casts.mentalityRound) { mixin(S_TRACE);
			final switch (casts.mentality) {
			case Mentality.Normal:
				break;
			case Mentality.Sleep:
				statuses ~= Status.Sleep;
				break;
			case Mentality.Confuse:
				statuses ~= Status.Confuse;
				break;
			case Mentality.Overheat:
				statuses ~= Status.Overheat;
				break;
			case Mentality.Brave:
				statuses ~= Status.Brave;
				break;
			case Mentality.Panic:
				statuses ~= Status.Panic;
				break;
			}
		}
		r ~= .warningInconsistency(prop, statuses);
	}
	auto card = cast(Card)path;
	if (card) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, card.name, prop.msgs.name);
		r ~= .sjisWarnings(prop, summ, card.desc, prop.msgs.desc);
		putCardImages(card.paths, true);
	}
	void putMotions(in Motion[] motions) { mixin(S_TRACE);
		bool[string] exists;
		foreach (m; motions) { mixin(S_TRACE);
			void put(string w) { mixin(S_TRACE);
				if (w !in exists) { mixin(S_TRACE);
					r ~= w;
					exists[w] = true;
				}
			}
			if (m.type is MType.CancelAction && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				put(.tryFormat(prop.msgs.warningUnknownMotion, prop.msgs.motionName(m.type), "1.50"));
			}
			if (m.type is MType.NoEffect && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				put(.tryFormat(prop.msgs.warningUnknownMotion, prop.msgs.motionName(m.type), "2"));
			}
			if (m.type == MType.SummonBeast && !m.beast) { mixin(S_TRACE);
				put(prop.msgs.searchErrorNoBeast);
			}
			if (m.type == MType.SummonBeast && m.beast && 0 != m.beast.linkId && !(summ && summ.beast(m.beast.linkId))) { mixin(S_TRACE);
				put(.tryFormat(prop.msgs.searchErrorLinkIdBeastNotFound, m.beast.linkId));
			}
			if ((m.type == MType.GetSkillPower || m.type == MType.LoseSkillPower)
					&& m.damageType !is DamageType.Max && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				put(prop.msgs.warningSkillPowerWithFixedValue);
			}
		}
	}
	auto effCard = cast(EffectCard)path;
	if (effCard) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, effCard.scenario, prop.msgs.sourceScenario);
		r ~= .sjisWarnings(prop, summ, effCard.author, prop.msgs.sourceAuthor);
		putMotions(effCard.motions);
		auto beast = cast(BeastCard)effCard;
		if (beast) { mixin(S_TRACE);
			if (beast.showStyle != ShowStyle.Center && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
				r ~= prop.msgs.warningShowStyleForBeastCard;
			}
			if (!.equal(beast.invocationCondition, [Status.Alive])) { mixin(S_TRACE);
				r ~= prop.msgs.warningInvocationCondition;
			}
			if (!beast.removeWithUnconscious) { mixin(S_TRACE);
				r ~= prop.msgs.warningRemoveWithUnconscious;
			}
			if (beast.removeWithUnconscious && beast.invocationCondition.contains(Status.Unconscious)) { mixin(S_TRACE);
				r ~= prop.msgs.warningUnconsciousCondition;
			}
		}
		if (effCard.soundPath1 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath1, summ ? summ.legacy : false, targVer);
			if (!skin.findPath(effCard.soundPath1, skin.extSound, skin.seDirs, sPath, wsnVer, skin.wsnSoundDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorSENotFound, .encodePath(effCard.soundPath1));
			}
			if ((effCard.volume1 != 100 || effCard.volume2 != 100) && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
		}
		if (effCard.soundPath2 != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, effCard.soundPath2, summ ? summ.legacy : false, targVer);
			if (!skin.findPath(effCard.soundPath2, skin.extSound, skin.seDirs, sPath, wsnVer, skin.wsnSoundDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorSENotFound, .encodePath(effCard.soundPath2));
			}
			if ((effCard.loopCount1 != 1 || effCard.loopCount2 != 1) && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
		}
		if (prop.sys.isRunAway(effCard.keyCodes)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningRunAwayCard, prop.sys.runAway);
		}
		if (prop.looks.keyCodesMaxLegacy < effCard.keyCodes.length && summ && summ.legacy) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningKeyCodeCount, prop.looks.keyCodesMaxLegacy);
		}
		foreach (keyCode; effCard.keyCodes) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, keyCode, prop.msgs.keyCode);
		}
		if ((effCard.flagDirRoot.hasFlag || effCard.flagDirRoot.hasStep || effCard.flagDirRoot.hasVariant) && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningLocalVariablesOfEffectCard;
		}
	}
	auto bi = cast(BgImage)path;
	if (bi) { mixin(S_TRACE);
		if (bi.flag != "" && !findVar!Flag(froot, bi.useCounter, bi.flag)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, bi.flag);
		}
		if (bi.cellName != "") { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, bi.cellName, prop.msgs.bgImageCellName);
			if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageCellName;
			}
		}
		if (bi.layer != LAYER_BACK_CELL) { mixin(S_TRACE);
			// 1.60
/+			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageForeground;
			}
+/			if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLayer;
			}
		}
	}
	auto ic = cast(ImageCell)path;
	if (ic) { mixin(S_TRACE);
		if (!ic.path.length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoImage;
		}
		if (isBinImg(ic.path)) { mixin(S_TRACE);
			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageIncluded;
			}
		} else if (ic.path.length && !skin.findPath(ic.path, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorImageNotFound, .encodePath(ic.path));
		}
		if (ic.path != "") { mixin(S_TRACE);
			r ~= skin.warningImage(prop, ic.path, summ ? summ.legacy : false, false, targVer);
		}
		if (ic.smoothing !is Smoothing.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningBgImageSmoothing;
		}
	}
	auto tc = cast(TextCell)path;
	if (tc) { mixin(S_TRACE);
		r ~= checkTextRes2(tc.text, null, tc.flagsInText, tc.stepsInText, tc.variantsInText, [], []);
		if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningTextCell;
		}
		if (summ && summ.legacy) { mixin(S_TRACE);
			if (tc.updateType !is UpdateType.Fixed) { mixin(S_TRACE);
				r ~= prop.msgs.warningUpdateTypeNotFixed;
			}
		} else { mixin(S_TRACE);
			if (tc.updateType !is UpdateType.Variables && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
				r ~= prop.msgs.warningUpdateType;
			}
		}
		if (tc.antialias && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningAntialiasedTextCell;
		}
	}
	auto cc = cast(ColorCell)path;
	if (cc) { mixin(S_TRACE);
		if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningColorCell;
		}
	}
	auto pc = cast(PCCell)path;
	if (pc) { mixin(S_TRACE);
		if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningPCCell;
		}
		if (pc.smoothing !is Smoothing.Default && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningBgImageSmoothing;
		}
	}
	auto aa = cast(AbstractArea)path;
	if (aa) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, aa.name, prop.msgs.name);
	}
	auto btl = cast(Battle)path;
	if (btl) { mixin(S_TRACE);
		if (!btl.possibleToRunAway && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningPossibleToRunAway;
		}
		if (!btl.possibleToRunAway) { mixin(S_TRACE);
			foreach (et; btl.trees) { mixin(S_TRACE);
				if (et.fireEscape) { mixin(S_TRACE);
					r ~= prop.msgs.warningNoIgniteRunAway;
					break;
				}
			}
		}
		if (btl.music != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, btl.music, summ ? summ.legacy : false, targVer);
			if (!skin.findPath(btl.music, skin.extBgm, skin.bgmDirs, sPath, wsnVer, skin.wsnMusicDirs(wsnVer)).length) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorBGMNotFound, .encodePath(btl.music));
			}
			if (btl.volume != 100 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
			if (btl.loopCount != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
			if (btl.fadeIn != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningFadeIn;
			}
		}
		if (btl.continueBGM && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningContinueBGM;
		}
	}
	auto mc = cast(MenuCard)path;
	if (mc) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, mc.name, prop.msgs.name);
		r ~= .sjisWarnings(prop, summ, mc.desc, prop.msgs.desc);
		if (mc.expandSPChars &&  !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningExpandSPCharsInMenuCardName;
		}
		if (mc.expandSPChars) { mixin(S_TRACE);
			r ~= checkTextRes2(mc.name, null, mc.flagsInText, mc.stepsInText, mc.variantsInText, [], []);
		}
		putCardImages(mc.paths, false);
		if (mc.flag != "" && !findVar!Flag(froot, mc.useCounter, mc.flag)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, mc.flag);
		}
	}
	auto ec = cast(EnemyCard)path;
	if (ec) { mixin(S_TRACE);
		if (ec.id == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoCast;
		}
		if (ec.id != 0 && !(summ && summ.cwCast(ec.id))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorCastNotFound, ec.id);
		}
		if (ec.flag != "" && !findVar!Flag(froot, ec.useCounter, ec.flag)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, ec.flag);
		}
		if (ec.isOverrideName &&  !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningOverrideEnemyCardName;
		}
		r ~= checkTextRes2(ec.overrideName, null, ec.flagsInText, ec.stepsInText, ec.variantsInText, [], []);
		if (ec.isOverrideImage &&  !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningOverrideEnemyCardImage;
		}
		auto noActionWarn = false;
		if (summ && summ.legacy) { mixin(S_TRACE);
			auto c = summ ? summ.cwCast(ec.id) : null;
			auto hasExchange = c && c.items.length && summ.baseCard(c.items[0]).name == skin.actionCardName(prop.sys, ActionCardType.Exchange);
			if (ec.action(ActionCardType.Exchange) && hasExchange) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningExchangeIsItemInClassic, skin.actionCardName(prop.sys, ActionCardType.Exchange));
			} else if (!ec.action(ActionCardType.Exchange) && !hasExchange) { mixin(S_TRACE);
				r ~= prop.msgs.warningNoActionCard;
				noActionWarn = true;
			}
		}
		if (!noActionWarn) { mixin(S_TRACE);
			bool checkActionCardType(ActionCardType type) { mixin(S_TRACE);
				if (type is ActionCardType.Exchange && (summ && summ.legacy)) return true;
				if (type is ActionCardType.RunAway) return true;
				if (!ec.action(type) && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
					r ~= prop.msgs.warningNoActionCard;
					return false;
				}
				return true;
			}
			foreach (type; EnumMembers!ActionCardType) { mixin(S_TRACE);
				if (!checkActionCardType(type)) break;
			}
		}
		putCardImages(ec.overrideImages, false);
	}
	auto spc = cast(AbstractSpCard)path;
	if (spc) { mixin(S_TRACE);
		r ~= .sjisWarnings(prop, summ, spc.cardGroup, prop.msgs.cardGroup);
		if (spc.layer != LAYER_MENU_CARD) {
			// 1.60
/+			if (!prop.targetVersion("1.60", targVer)) { mixin(S_TRACE);
				r ~= prop.msgs.warningBgImageForeground;
			}
+/			if (!prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLayer;
			}
		}
		if (spc.cardGroup != "") {
			if (!prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardGroup;
			}
		}
		if (spc.animationSpeed != -1) { mixin(S_TRACE);
			if (!prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
				r ~= prop.msgs.warningCardAnimationSpeed;
			}
		}
	}
	auto c = cast(Content)path;
	if (c) { mixin(S_TRACE);
		auto cd = c.detail;
		if (!c.parent || c.parent.detail.nextType is CNextType.Text || c.parent.detail.nextType is CNextType.Coupon) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.name, prop.msgs.contentNameForWarning);
		}
		if ((summ ? summ.legacy : false) && c.type == CType.Wait && !c.next.length) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorIgnoreWait;
		}
		if (c.parent) { mixin(S_TRACE);
			auto wNC = .warningNextCondition(prop, c.parent.detail.nextType, c.name);
			if (wNC) r ~= wNC;
		}
		if (cd.owner && cd.nextType != CNextType.Text) { mixin(S_TRACE);
			auto set = new HashSet!(string);
			foreach (cld; c.next) { mixin(S_TRACE);
				if (cld.name == "" && c.type !is CType.BranchMultiCoupon) continue;
				if (cld.type is CType.CheckFlag || cld.type is CType.CheckStep || cld.type is CType.CheckVariant) continue;
				if (set.contains(cld.name)) { mixin(S_TRACE);
					r ~= prop.msgs.searchErrorDupNextContent;
					break;
				}
				set.add(cld.name);
			}
		}
		if (c.parent && c.parent.detail.nextType == CNextType.Text) { mixin(S_TRACE);
			auto fit = c.flagsInName;
			auto sit = c.stepsInName;
			auto vit = c.variantsInName;
			auto foit = c.namesInName;
			if (!prop.targetVersion("1.50", targVer) && (fit.length || sit.length || vit.length || foit.length)) { mixin(S_TRACE);
				r ~= prop.msgs.warningSPCharsInSelections;
			} else { mixin(S_TRACE);
				r ~= checkTextRes2("", c.useCounter, fit, sit, vit, [], []);
			}
		}

		void couponWarnings(string coupon, bool getLose, string name) { mixin(S_TRACE);
			r ~= .couponWarnings(prop, summ, targVer, coupon, getLose, name);
		}

		if (c.type == CType.TalkDialog) { mixin(S_TRACE);
			if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				if (Talker.Valued is c.talkerNC) { mixin(S_TRACE);
					r ~= prop.msgs.warningValuedTalker;
				}
			}
			if (c.dialogs.length) { mixin(S_TRACE);
				bool[string] wFlags;
				bool[string] wSteps;
				bool[string] wVariants;
				bool[string] wFonts;
				bool[char] wColors;
				foreach (i, dlg; c.dialogs) { mixin(S_TRACE);
					foreach (coupon; dlg.rCoupons) { mixin(S_TRACE);
						couponWarnings(coupon, false, prop.msgs.toneCoupons);
					}
					r ~= checkTextRes(dlg.text, dlg.useCounter, dlg.flagsInText, dlg.stepsInText, dlg.variantsInText,
						dlg.fontsInText, dlg.colorsInText,
						wFlags, wSteps, wVariants, wFonts, wColors).noDup;
					if (i + 1 < c.dialogs.length && !dlg.rCoupons.length) { mixin(S_TRACE);
						// 最後以外にクーポンが設定されていない場合
						r ~= prop.msgs.searchErrorNoRCouponsDialog;
					}
				}
			}
		}
		r ~= checkTextRes2(c.text, c.useCounter, c.flagsInText, c.stepsInText, c.variantsInText, c.fontsInText, c.colorsInText);
		bool hasStart() { mixin(S_TRACE);
			foreach (s; c.tree.starts) { mixin(S_TRACE);
				if (s.name == c.start) return true;
			}
			return false;
		}
		{ mixin(S_TRACE);
			bool[string] tbl;
			string[] ws2;
			foreach (back; c.backs) { mixin(S_TRACE);
				auto ws = warnings(prop, skin, summ, back, targVer);
				if (cd.use(CArg.IgnoreEffectBooster) && c.ignoreEffectBooster) { mixin(S_TRACE);
					if (auto ic2 = cast(ImageCell)back) { mixin(S_TRACE);
						auto ext = ic2.path.extension().toLower();
						if (ext == ".jpy1" || ext == ".jptx" || ext == ".jpdc") { mixin(S_TRACE);
							ws ~= prop.msgs.warningEffectBoosterFileWithReplaceBgImage;
						}
					}
				}
				foreach (w; ws) { mixin(S_TRACE);
					if (w !in tbl) { mixin(S_TRACE);
						ws2 ~= w;
						tbl[w] = true;
					}
				}
			}
			r ~= ws2;
		}
		if (c.flag != "" && !findVar!Flag(froot, c.useCounter, c.flag)) { mixin(S_TRACE);
			// 代入コンテントではランダム値が有効
			if (c.type != CType.SubstituteFlag || .icmp(prop.sys.randomValue, c.flag) != 0) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, c.flag);
			}
		}
		if (c.step != "" && !findVar!Step(froot, c.useCounter, c.step)) { mixin(S_TRACE);
			// 代入コンテントではランダム値・選択メンバ番号が有効
			if (c.type != CType.SubstituteStep || (.icmp(prop.sys.randomValue, c.step) != 0 && .icmp(prop.sys.selectedPlayerCardNumber, c.step) != 0)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.searchErrorStepNotFound, c.step);
			}
			if (c.type == CType.SubstituteStep && .icmp(prop.sys.selectedPlayerCardNumber, c.step) == 0 && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				r ~= prop.msgs.warningSelectedPlayerValue;
			}
		}
		if (c.variant != "" && !findVar!Variant(froot, c.useCounter, c.variant)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorVariantNotFound, c.flag);
		}
		putCardImages(c.cardPaths, false);
		if (c.bgmPath != "") { mixin(S_TRACE);
			r ~= skin.warningBGM(prop, c.bgmPath, summ ? summ.legacy : false, targVer);
		}
		if (c.bgmPath != "" && !skin.findPath(c.bgmPath, skin.extBgm, skin.bgmDirs, sPath, wsnVer, skin.wsnMusicDirs(wsnVer)).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBGMNotFound, .encodePath(c.bgmPath));
		}
		if (c.soundPath != "") { mixin(S_TRACE);
			r ~= skin.warningSE(prop, c.soundPath, summ ? summ.legacy : false, targVer);
		}
		if (c.soundPath != "" && !skin.findPath(c.soundPath, skin.extSound, skin.seDirs, sPath, wsnVer, skin.wsnSoundDirs(wsnVer)).length) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSENotFound, .encodePath(c.soundPath));
		}
		if (c.area != 0 && !(summ && summ.area(c.area))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorAreaNotFound, c.area);
		}
		if (c.battle != 0 && !(summ && summ.battle(c.battle))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBattleNotFound, c.battle);
		}
		if (c.packages != 0 && !(summ && summ.cwPackage(c.packages))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorPackageNotFound, c.packages);
		}
		if (c.casts != 0 && !(summ && summ.cwCast(c.casts))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorCastNotFound, c.casts);
		}
		if (c.item != 0 && !(c.range is Range.SelectedCard && c.type is CType.LoseItem) && !(summ && summ.item(c.item))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorItemNotFound, c.item);
		}
		if (c.skill != 0 && !(c.range is Range.SelectedCard && c.type is CType.LoseSkill) && !(summ && summ.skill(c.skill))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorSkillNotFound, c.skill);
		}
		if (c.beast != 0 && !(c.range is Range.SelectedCard && c.type is CType.LoseBeast) && !(summ && summ.beast(c.beast))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorBeastNotFound, c.beast);
		}
		if (c.info != 0 && !(summ && summ.info(c.info))) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorInfoNotFound, c.info);
		}
		if (c.start != "" && !hasStart()) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorStartNotFound, c.start);
		}
		putMotions(c.motions);
		if (c.flag2 != "" && !findVar!Flag(froot, c.useCounter, c.flag2)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorFlagNotFound, c.flag2);
		}
		if (c.step2 != "" && !findVar!Step(froot, c.useCounter, c.step2)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.searchErrorStepNotFound, c.step2);
		}
		if (c.flag != "" && c.flag == c.flag2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSourceIsTarget;
		}
		if (c.step != "" && c.step == c.step2) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorSourceIsTarget;
		}
		if (cd.use(CArg.CouponNames)) { mixin(S_TRACE);
			if (!c.couponNames.length) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoCoupon;
			}
			if(!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				if (1 < c.couponNames.length) { mixin(S_TRACE);
					r ~= prop.msgs.warningBranchCouponMulti;
				}
			}
			foreach (coupon; c.couponNames) { mixin(S_TRACE);
				couponWarnings(coupon, false, prop.msgs.couponName);
			}
		}
		if ((c.type is CType.GetCoupon || c.type is CType.LoseCoupon) && prop.sys.isCouponType(c.coupon, CouponType.System)) { mixin(S_TRACE);
			couponWarnings(c.coupon, true, prop.msgs.couponName);
		}
		if (cd.use(CArg.Coupons)) { mixin(S_TRACE);
			foreach (coupon; c.coupons) { mixin(S_TRACE);
				couponWarnings(coupon.name, false, prop.msgs.valued);
			}
		}
		if (c.levelMin > c.levelMax) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorReversalLevel;
		}
		if (c.type is CType.BranchRound) { mixin(S_TRACE);
			CWXPath cwxPath = c;
			while (cwxPath) { mixin(S_TRACE);
				if (cast(Area) cwxPath) { mixin(S_TRACE);
					r ~= prop.msgs.searchErrorBranchRoundInArea;
					break;
				}
				cwxPath = cwxPath.cwxParent();
			}
		}
		if (c.bgmChannel != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningChannel;
		}
		if (c.bgmFadeIn != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningFadeIn;
		}
		if (c.bgmPath != "") { mixin(S_TRACE);
			if (c.bgmVolume != 100 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
			if (c.bgmLoopCount != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
		}
		if (c.soundPath != "") { mixin(S_TRACE);
			if (c.soundFadeIn != 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningFadeIn;
			}
			if (c.soundVolume != 100 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningVolume;
			}
			if (c.soundLoopCount != 1 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningLoopCount;
			}
			if (c.soundChannel!= 0 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
				r ~= prop.msgs.warningChannel;
			}
		}
		if (cd.use(CArg.Area) && c.area == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoArea;
		}
		if (cd.use(CArg.Battle) && c.battle == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoBattle;
		}
		if (cd.use(CArg.Package) && c.packages == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoPackage;
		}
		if (cd.use(CArg.Cast) && c.casts == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoCast;
		}
		if (cd.use(CArg.Item) && c.item == 0) { mixin(S_TRACE);
			if (!(c.range is Range.SelectedCard && c.type is CType.LoseItem)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoItem;
			}
		}
		if (cd.use(CArg.Skill) && c.skill == 0) { mixin(S_TRACE);
			if (!(c.range is Range.SelectedCard && c.type is CType.LoseSkill)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoSkill;
			}
		}
		if (cd.use(CArg.Beast) && c.beast == 0) { mixin(S_TRACE);
			if (!(c.range is Range.SelectedCard && c.type is CType.LoseBeast)) { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoBeast;
			}
		}
		if (cd.use(CArg.Info) && c.info == 0) { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoInfo;
		}
		if (cd.use(CArg.Flag) && cd.use(CArg.Step) && cd.use(CArg.Variant)) { mixin(S_TRACE);
			if (c.flag == "" && c.step == "" && c.variant == "") { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoExpressionTarget;
			}
		} else { mixin(S_TRACE);
			if (cd.use(CArg.Flag) && c.flag == "") { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoFlag;
			}
			if (cd.use(CArg.Step) && c.step == "") { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoStep;
			}
			if (cd.use(CArg.Variant) && c.variant == "") { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoVariant;
			}
		}
		if (cd.use(CArg.Flag2) && c.flag2 == "") { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoFlag;
		}
		if (cd.use(CArg.Step2) && c.step2 == "") { mixin(S_TRACE);
			r ~= prop.msgs.searchErrorNoStep;
		}
		if (cd.use(CArg.Coupon)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.coupon, prop.msgs.couponName);
			if (c.coupon == "") r ~= prop.msgs.searchErrorNoCoupon;
		}
		if (cd.use(CArg.Gossip)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.gossip, prop.msgs.gossipName);
			if (c.gossip == "") r ~= prop.msgs.searchErrorNoGossip;
		}
		if (cd.use(CArg.CompleteStamp)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.completeStamp, prop.msgs.endName);
			if (c.completeStamp == "") r ~= prop.msgs.searchErrorNoCompleteStamp;
		}
		if (cd.use(CArg.KeyCode)) { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.keyCode, prop.msgs.keyCode);
			if (c.keyCode == "") r ~= prop.msgs.searchErrorNoKeyCode;
		}
		if (cd.use(CArg.CellName) && c.cellName == "") { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.cellName, prop.msgs.cellName);
			r ~= prop.msgs.searchErrorNoCellName;
		}
		if (cd.use(CArg.CardGroup) && c.cardGroup == "") { mixin(S_TRACE);
			r ~= .sjisWarnings(prop, summ, c.cardGroup, prop.msgs.cardGroup);
			r ~= prop.msgs.searchErrorNoCardGroup;
		}
		uint maxNextLen(in Content c) { mixin(S_TRACE);
			if (c.type is CType.TalkMessage) { mixin(S_TRACE);
				return c.text == "" ? prop.looks.selectionBarMax : prop.looks.selectionBarMaxWithMessage;
			} else if (c.type is CType.TalkDialog) { mixin(S_TRACE);
				foreach (dlg; c.dialogs) { mixin(S_TRACE);
					if (dlg.text != "") return prop.looks.selectionBarMaxWithMessage;
				}
				return prop.looks.selectionBarMax;
			}
			return uint.max;
		}
		size_t rows(in Content c) { mixin(S_TRACE);
			size_t len = 0;
			foreach (n; c.next) { mixin(S_TRACE);
				if (n.name != "" && n.type !is CType.CheckFlag && n.type !is CType.CheckStep && n.type !is CType.CheckVariant) { mixin(S_TRACE);
					len++;
				}
			}
			return (len + (c.selectionColumns - 1)) / c.selectionColumns;
		}
		if (cd.nextType is CNextType.Text && maxNextLen(c) < rows(c)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningSelectionBarIsMany, rows(c), maxNextLen(c));
		}
		if (cd.nextType is CNextType.Text && c.selectionColumns != 1 && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningSelectionColumns;
		}

		if (c.status !is Status.None) { mixin(S_TRACE);
			if (Status.Silence <= c.status && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchStatusMental, prop.msgs.statusName(c.status), "1.50");
			} else if (Status.Confuse <= c.status && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchStatusMental, prop.msgs.statusName(c.status), "1.30");
			}
		}
		if (c.range == Range.Field && cd.use(CArg.Coupon) && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= prop.msgs.warningBranchCouponAtField;
		}
		if (c.selectionMethod is SelectionMethod.Valued && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= prop.msgs.warningValuedSelectionMethod;
		}
		if (c.type is CType.CheckStep && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.CheckStep), "1.50");
		}
		if (c.type is CType.SubstituteStep && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.SubstituteStep), "1.30");
		}
		if (c.type is CType.SubstituteFlag && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.SubstituteFlag), "1.30");
		}
		if (c.type is CType.BranchStepCmp && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BranchStepCmp), "1.30");
		}
		if (c.type is CType.BranchFlagCmp && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BranchFlagCmp), "1.30");
		}
		if (c.type is CType.BranchRandomSelect && !prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BranchRandomSelect), "1.30");
		}
		if (c.type is CType.BranchKeyCode && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BranchKeyCode), "1.50");
		}
		if (c.type is CType.BranchRound && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContent, prop.msgs.contentName(CType.BranchRound), "1.50");
		}
		if (c.type is CType.ReplaceBgImage && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.ReplaceBgImage), "1");
		}
		if (c.type is CType.LoseBgImage && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.LoseBgImage), "1");
		}
		if (c.type is CType.MoveBgImage && !prop.isTargetVersion(summ, targVer, "1")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.MoveBgImage), "1");
		}
		if (c.type is CType.BranchMultiCoupon && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.BranchMultiCoupon), "2");
		}
		if (c.type is CType.BranchMultiRandom && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.BranchMultiRandom), "2");
		}
		if (c.type is CType.MoveCard && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.MoveCard), "3");
		}
		if (c.type is CType.ChangeEnvironment && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.ChangeEnvironment), "4");
		}
		if (c.type is CType.BranchVariant && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.BranchVariant), "4");
		}
		if (c.type is CType.SetVariant && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.SetVariant), "4");
		}
		if (c.type is CType.CheckVariant && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningUnknownContentWsn, prop.msgs.contentName(CType.CheckVariant), "4");
		}
		if (cd.use(CArg.StepValue)) { mixin(S_TRACE);
			if (froot && c.step != "") { mixin(S_TRACE);
				auto s = findVar!Step(froot, c.useCounter, c.step);
				if (s && s.count < c.stepValue) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningStepOverCount, s.name, s.count, c.stepValue);
				}
			}
			if (summ && summ.legacy && prop.looks.stepMaxCount < c.stepValue) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningStepCount, prop.looks.stepMaxCount);
			}
		}
		if (c.parent && c.parent.detail.nextType is CNextType.Step && c.name != prop.sys.evtChildDefault && std.string.isNumeric(c.name)) { mixin(S_TRACE);
			try {
				auto value = .to!uint(c.name);
				if (froot && c.parent.step != "") { mixin(S_TRACE);
					auto s = findVar!Step(froot, c.parent.useCounter, c.parent.step);
					if (s && s.count < value) { mixin(S_TRACE);
						r ~= .tryFormat(prop.msgs.warningStepOverCount, s.name, s.count, value);
					}
				}
				if (summ && summ.legacy && prop.looks.stepMaxCount < value) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningStepCount, prop.looks.stepMaxCount);
				}
			} catch (ConvException e) {
				// 処理無し
				printStackTrace();
			}
		}
		if (summ && summ.legacy && (c.type is CType.ChangeArea || c.type is CType.StartBattle || c.type is CType.End)) { mixin(S_TRACE);
			auto tree = c.tree;
			if (tree && tree.fireRound0) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningEndOrChangeAreaInRound0);
			}
		}
		if (cd.use(CArg.StartAction) && summ) { mixin(S_TRACE);
			if (summ.legacy && c.startAction !is StartAction.NextRound) { mixin(S_TRACE);
				// クラシックなシナリオではStartAction.NextRoundがデフォルト
				r ~= .tryFormat(prop.msgs.warningStartAction);
			} else if (!summ.legacy && !prop.isTargetVersion(summ, targVer, "2") && c.startAction !is StartAction.Now) { mixin(S_TRACE);
				// Wsn.1以前は戦闘行動開始タイミング指定不可かつStartAction.Nowがデフォルト
				r ~= .tryFormat(prop.msgs.warningStartAction);
			}
		}
		if (cd.use(CArg.RefAbility)) { mixin(S_TRACE);
			if (c.refAbility && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				// Wsn.1以前は選択者の能力参照は指定不可
				r ~= .tryFormat(prop.msgs.warningRefAbility);
			}
		}
		if (cd.use(CArg.Ignite)) { mixin(S_TRACE);
			if (c.ignite && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
				// Wsn.1以前はイベントの発火有無は指定不可
				r ~= .tryFormat(prop.msgs.warningIgnite);
			}
		}
		if (cd.use(CArg.KeyCodes)) { mixin(S_TRACE);
			if (!c.ignite && c.keyCodes.length) { mixin(S_TRACE);
				r ~= prop.msgs.warningIgnoreKeyCode;
			}
			if (c.ignite && prop.sys.isRunAway(c.keyCodes)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningRunAwayCard, prop.sys.runAway);
			}
		}
		if (c.type is CType.BranchKeyCode && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			if (summ.legacy
					&& !(c.targetIsSkill && c.targetIsItem && c.targetIsBeast && c.targetIsHand)
					&& !(c.targetIsSkill && !c.targetIsItem && !c.targetIsBeast && !c.targetIsHand)
					&& !(!c.targetIsSkill && c.targetIsItem && !c.targetIsBeast && c.targetIsHand)
					&& !(!c.targetIsSkill && !c.targetIsItem && c.targetIsBeast && !c.targetIsHand)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchKeyCodeAtClassic);
			} else if (!summ.legacy
					&& !(c.targetIsSkill && c.targetIsItem && c.targetIsBeast && !c.targetIsHand)
					&& !(c.targetIsSkill && !c.targetIsItem && !c.targetIsBeast && !c.targetIsHand)
					&& !(!c.targetIsSkill && c.targetIsItem && !c.targetIsBeast && !c.targetIsHand)
					&& !(!c.targetIsSkill && !c.targetIsItem && c.targetIsBeast && !c.targetIsHand)) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningBranchKeyCodeAtWsn1);
			}
		}
		if (c.range is Range.CouponHolder) { mixin(S_TRACE);
			switch (c.type) {
			case CType.Effect:
				if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningCouponHolder, prop.msgs.contentName(c.type), "2");
				}
				break;
			case CType.GetCoupon:
			case CType.LoseCoupon:
				if (!prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
					r ~= .tryFormat(prop.msgs.warningCouponHolder, prop.msgs.contentName(c.type), "3");
				}
				break;
			default:
				assert (0);
			}
			if (c.holdingCoupon == "") { mixin(S_TRACE);
				r ~= prop.msgs.warningNoHoldingCoupon;
			}
		}
		if (c.range is Range.CardTarget && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningCardTarget;
		}
		if (c.boundaryCheck && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningBoundaryCheck;
		}
		if (c.centeringX && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningCenteringX;
		}
		if (c.centeringY && !prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= prop.msgs.warningCenteringY;
		}
		if ((c.type is CType.BranchKeyCode || c.type is CType.BranchSkill || c.type is CType.BranchItem || c.type is CType.BranchBeast)
				&& c.selectCard && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningSelectCard;
		}
		if (cd.use(CArg.SelectTalker) && c.selectTalker && hasCharacterTalker(c) && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningSelectTalker;
		}
		if (cd.use(CArg.InvertResult) && c.invertResult && c.invertResult && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningInvertResult;
		}
		if (cd.use(CArg.ConsumeCard) && !c.consumeCard && !prop.isTargetVersion(summ, targVer, "3")) { mixin(S_TRACE);
			r ~= prop.msgs.warningConsumeCard;
		}
		if (cd.use(CArg.CardSpeed) && c.cardSpeed != -1 && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningCardAnimationSpeed;
		}
		if (cd.use(CArg.Expression)) { mixin(S_TRACE);
			if (c.expression == "") { mixin(S_TRACE);
				r ~= prop.msgs.searchErrorNoExpression;
			} else { mixin(S_TRACE);
				string[char] names;
				VarValue[string] flags, steps, variants, sysSteps;
				switch (c.type) {
				case CType.SetVariant:
					if (c.flag != "") { mixin(S_TRACE);
						auto val = c.getExpressionReturnValue(prop);
						if (val.valid) { mixin(S_TRACE);
							final switch (val.type) {
							case VariantType.Number:
								r ~= .tryFormat(prop.msgs.warningExpressionToFlag, prop.msgs.numberValue);
								break;
							case VariantType.String:
								r ~= .tryFormat(prop.msgs.warningExpressionToFlag, prop.msgs.stringValue);
								break;
							case VariantType.Boolean:
								break;
							}
						}
					} else if (c.step != "") { mixin(S_TRACE);
						auto val = c.getExpressionReturnValue(prop);
						if (val.valid) { mixin(S_TRACE);
							final switch (val.type) {
							case VariantType.Number:
								break;
							case VariantType.String:
								r ~= .tryFormat(prop.msgs.warningExpressionToStep, prop.msgs.stringValue);
								break;
							case VariantType.Boolean:
								r ~= .tryFormat(prop.msgs.warningExpressionToStep, prop.msgs.booleanValue);
								break;
							}
						}
					}
					break;
				case CType.BranchVariant:
				case CType.CheckVariant:
					auto val = c.getExpressionReturnValue(prop);
					final switch (val.type) {
					case VariantType.Number:
						r ~= .tryFormat(prop.msgs.warningExpressionNeedBooleanReturnType, prop.msgs.numberValue, prop.msgs.contentName(c.type));
						break;
					case VariantType.String:
						r ~= .tryFormat(prop.msgs.warningExpressionNeedBooleanReturnType, prop.msgs.stringValue, prop.msgs.contentName(c.type));
						break;
					case VariantType.Boolean:
						break;
					}
					break;
				default:
					assert (0);
				}
				r ~= .exprErrorToWarnings(prop, c.expression, c.getExpressionErrors(prop, VariableInfo(prop, summ, c.useCounter, targVer, names, flags, steps, variants, sysSteps)));
				r ~= checkTextRes2(c.expression, c.useCounter, c.flagsInExpression, c.stepsInExpression, c.variantsInExpression, [], []);
			}
		}
		if ((cd.use(CArg.Coupon) || cd.use(CArg.CouponNames)) && cd.use(CArg.ExpandSPChars) && c.expandSPChars) { mixin(S_TRACE);
			if (!prop.isTargetVersion(summ, targVer, "4")) r ~= prop.msgs.warningExpandSPCharsInCoupon;
			r ~= checkTextRes2(c.coupon, c.useCounter, c.flagsInCoupons, c.stepsInCoupons, c.variantsInCoupons, [], []);
		}
		if (cd.use(CArg.Gossip) && cd.use(CArg.ExpandSPChars) && c.expandSPChars) { mixin(S_TRACE);
			if (!prop.isTargetVersion(summ, targVer, "4")) r ~= prop.msgs.warningExpandSPCharsInGossip;
			r ~= checkTextRes2(c.gossip, c.useCounter, c.flagsInGossip, c.stepsInGossip, c.variantsInGossip, [], []);
		}
		if (cd.nextType is CNextType.Coupon && c.expandSPChars) { mixin(S_TRACE);
			if (!prop.isTargetVersion(summ, targVer, "4")) r ~= prop.msgs.warningExpandSPCharsInCoupon;
		}
		if (c.parent && c.parent.expandSPChars && c.parent.detail.nextType is CNextType.Coupon) { mixin(S_TRACE);
			r ~= checkTextRes2(c.name, c.useCounter, c.flagsInName, c.stepsInName, c.variantsInName, [], []);
		}
		if (cd.use(CArg.InitialEffect) && c.initialEffect && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
			r ~= prop.msgs.warningInitialEffect;
		}
		if (cd.use(CArg.AbsorbTo)) { mixin(S_TRACE);
			if (c.absorbTo && c.absorbTo is AbsorbTo.Selected && !prop.isTargetVersion(summ, targVer, "4")) { mixin(S_TRACE);
				r ~= prop.msgs.warningAbsorbToSelected;
			}
		}
	}
	return r;
}

/// exprErrsを警告テキストとしてまとめる。
string[] exprErrorToWarnings(in CProps prop, string expr, in ExprError[] exprErrs) { mixin(S_TRACE);
	string[] lines;
	string[] ws;
	foreach (err; exprErrs) { mixin(S_TRACE);
		if (lines.length == 0) lines = .splitLines(expr);
		auto errLine = lines[err.errLine - 1];
		if (errLine.length <= err.errPos) { mixin(S_TRACE);
			errLine = errLine ~ prop.msgs.warningExpressionEnd;
		} else { mixin(S_TRACE);
			errLine = errLine[0 .. err.errPos - 1] ~ prop.msgs.warningExpressionPosition ~ errLine[err.errPos - 1 .. $];
		}
		ws ~= .tryFormat(prop.msgs.warningExpression, err.message, errLine);
	}
	return ws;
}

/// evtの話者の選択中のメンバ・ランダムメンバ・選択中以外のメンバのいずれかが含まれているか。
@property
bool hasCharacterTalker(in Content evt) { mixin(S_TRACE);
	if (evt.type is CType.TalkMessage) { mixin(S_TRACE);
		foreach (imgPath; evt.cardPaths) { mixin(S_TRACE);
			if (imgPath.type is CardImageType.Talker && imgPath.talker !is Talker.Card) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	} else if (evt.type is CType.TalkDialog) { mixin(S_TRACE);
		return true;
	} else assert (0);
}

/// 台詞・メッセージ内で使用されているデータに対する警告のリスト。
struct TextWarnings {
	string[] all; /// 全ての警告。
	string[] noDup; /// 重複する警告を取り除いた配列。
}

/// 台詞・メッセージ内で使用されているデータに対する警告を返す。
/// 警告が行われたデータは引数の連想配列に格納される。
TextWarnings textWarnings(in CProps prop, in Skin skin, in Summary summ, in UseCounter uc, string targVer,
		string text, in string[] flags, in string[] steps, in string[] variants, in string[] fonts, in char[] colors,
		ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wVariants,
		ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
	string[] all = [];
	string[] noDup = [];

	auto sPath = summ ? summ.scenarioPath : "";
	auto spChars = skin.spChars;
	auto froot = summ ? summ.flagDirRoot : null;
	auto wsnVer = summ ? summ.dataVersion : LATEST_VERSION;

	auto sw = .sjisWarnings(prop, summ, text, prop.msgs.message);
	all ~= sw;
	noDup ~= sw;

	foreach (font; fonts) { mixin(S_TRACE);
		dchar c = decodeFontPath(font);
		if (c in spChars) continue;
		bool put = false;
		if (summ && summ.legacy && !.isSJIS1ByteChar(c)) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorSPFontIsNotSJIS1ByteChar, .tryFormat("#%s", c));
			all ~= msg;
			if (!wFonts.get(font, false)) { mixin(S_TRACE);
				noDup ~= msg;
				put = true;
			}
		}
		if (!skin.findPath(font, skin.extImage, skin.tableDirs, sPath, wsnVer, skin.wsnTableDirs(wsnVer)).length) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorSPFontNotFound, .tryFormat("#%s", c));
			all ~= msg;
			if (!wFonts.get(font, false)) { mixin(S_TRACE);
				noDup ~= msg;
				put = true;
			}
		}
		if (put) wFonts[font] = true;
	}
	foreach (flag; flags) { mixin(S_TRACE);
		if (!.findVar!Flag(froot, uc, flag)) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorFlagNotFound, flag);
			all ~= msg;
			if (!wFlags.get(flag, false)) { mixin(S_TRACE);
				noDup ~= msg;
				wFlags[flag] = true;
			}
		}
	}
	foreach (step; steps) { mixin(S_TRACE);
		if (!.findVar!Step(froot, uc, step)) { mixin(S_TRACE);
			auto msg = "";
			if (step.startsWith(prop.sys.prefixSystemVarName)) { mixin(S_TRACE);
				if (.icmp(prop.sys.selectedPlayerCardNumber, step) == 0) { mixin(S_TRACE);
					// 選択メンバ番号(Wsn.2)
					if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
						msg ~= prop.msgs.warningSelectedPlayerCardNumber;
					}
				} else { mixin(S_TRACE);
					auto isPC = false;
					foreach (i; 1 .. prop.looks.partyMax + 1) { mixin(S_TRACE);
						if (.icmp(prop.sys.playerCardName(cast(uint)i), step) == 0) { mixin(S_TRACE);
							// プレイヤーキャラクタ名(Wsn.2)
							if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
								msg ~= .tryFormat(prop.msgs.warningPlayerCardName, i);
							}
							isPC = true;
							break;
						}
					}
					if (!isPC) { mixin(S_TRACE);
						msg ~= .tryFormat(prop.msgs.warningUnknownSystemValue, step);
					}
				}
			} else { mixin(S_TRACE);
				msg = .tryFormat(prop.msgs.searchErrorStepNotFound, step);
			}
			if (msg == "") continue;
			all ~= msg;
			if (!wSteps.get(step, false)) { mixin(S_TRACE);
				noDup ~= msg;
				wSteps[step] = true;
			}
		}
	}
	foreach (variant; variants) { mixin(S_TRACE);
		if (!.findVar!Variant(froot, uc, variant)) { mixin(S_TRACE);
			auto msg = .tryFormat(prop.msgs.searchErrorVariantNotFound, variant);
			all ~= msg;
			if (!wVariants.get(variant, false)) { mixin(S_TRACE);
				noDup ~= msg;
				wVariants[variant] = true;
			}
		}
	}
	if ((summ && summ.legacy) && !prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
		foreach (color; colors) { mixin(S_TRACE);
			switch (std.ascii.toUpper(color)) {
			case 'O', 'P', 'L', 'D':
				auto w = .tryFormat(prop.msgs.warningTextColor, "&" ~ color, "1.50");
				all ~= w;
				if (!wColors.get(color, false)) { mixin(S_TRACE);
					noDup ~= w;
					wColors[color] = true;
				}
				break;
			default:
				break;
			}
		}
	}
	return typeof(return)(all, noDup);
}

/// システムクーポンに関する警告を返す。
string[] couponWarnings(in CProps prop, in Summary summ, string targVer, string coupon, bool getLose, string itemName) { mixin(S_TRACE);
	string[] r;
	r ~= .sjisWarnings(prop, summ, coupon, itemName);
	if (coupon == prop.sys.userCoupon || coupon == prop.sys.eventTargetCoupon || coupon == prop.sys.effectOutOfTargetCoupon) { mixin(S_TRACE);
		if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningWsnSystemCoupon, coupon, "2");
		}
		if (getLose) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningCanNotGetSetCoupon, coupon);
		}
	} else if (coupon == prop.sys.effectTargetCoupon) { mixin(S_TRACE);
		if (!prop.isTargetVersion(summ, targVer, "2")) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningWsnSystemCoupon, coupon, "2");
		}
	} else if (getLose && coupon.startsWith(prop.sys.couponSystem)) { mixin(S_TRACE);
		r ~= .tryFormat(prop.msgs.warningSystemCoupon, coupon);
	}
	return r;
}

/// cNextTypeに後続コンテントの名称nameが適合しない場合は警告を返す。
/// 適合する場合はnullを返す。
string warningNextCondition(in CProps prop, CNextType cNextType, string name) { mixin(S_TRACE);
	final switch (cNextType) {
	case CNextType.None:
		if (name != "") return .tryFormat(prop.msgs.invalidNextName, name);
		return null;
	case CNextType.Text:
	case CNextType.Coupon:
		return null;
	case CNextType.Bool:
		return warningBoolCondition(prop, name);
	case CNextType.Step:
	case CNextType.IdArea:
	case CNextType.IdBattle:
		return warningNumberCondition(prop, name);
	case CNextType.Trio:
		return warningTrioCondition(prop, name);
	}
}
private string warningBoolCondition(in CProps prop, string text) { mixin(S_TRACE);
	if (text == prop.sys.evtChildTrue || text == prop.sys.evtChildFalse) { mixin(S_TRACE);
		return null;
	} else if (text == "") { mixin(S_TRACE);
		return prop.msgs.unknownBranchConditionNoText;
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.unknownBranchCondition, text);
	}
}
private string warningNumberCondition(in CProps prop, string text) { mixin(S_TRACE);
	if (text == prop.sys.evtChildDefault) { mixin(S_TRACE);
		return null;
	} else if (std.string.isNumeric(text)) { mixin(S_TRACE);
		try {
			auto value = .to!uint(text);
			return null;
		} catch (ConvException e) {
			// 処理無し
			printStackTrace();
		}
	}

	if (text == "") { mixin(S_TRACE);
		return prop.msgs.unknownBranchConditionNoText;
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.unknownBranchCondition, text);
	}
}
private string warningTrioCondition(in CProps prop, string text) { mixin(S_TRACE);
	if (text == prop.sys.evtChildGreater || text == prop.sys.evtChildLesser || text == prop.sys.evtChildEq) { mixin(S_TRACE);
		return null;
	} else if (text == "") { mixin(S_TRACE);
		return prop.msgs.unknownBranchConditionNoText;
	} else { mixin(S_TRACE);
		return .tryFormat(prop.msgs.unknownBranchCondition, text);
	}
}

/// ステータス群が両立しないものを含んでいる場合は警告を返す。
@property
string[] warningInconsistency(in CProps prop, in Status[] statuses) { mixin(S_TRACE);
	auto tbl = new bool[(EnumMembers!Status).length];
	foreach (s; statuses) tbl[cast(size_t)s] = true;
	string[] ws;

	void w(Status s1, Status s2) { mixin(S_TRACE);
		if (s1 < s2) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningInconsistencyStatus, prop.msgs.statusName(s1), prop.msgs.statusName(s2));
		} else { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningInconsistencyStatus, prop.msgs.statusName(s2), prop.msgs.statusName(s1));
		}
	}

	with (Status) { mixin(S_TRACE);
		if (tbl[Active]) { mixin(S_TRACE);
			if (tbl[Inactive]) w(Active, Inactive);
			if (tbl[Dead]) w(Active, Dead);
			if (tbl[Unconscious]) w(Active, Unconscious);
			if (tbl[Sleep]) w(Active, Sleep);
			if (tbl[Bind]) w(Active, Bind);
			if (tbl[Paralyze]) w(Active, Paralyze);
		}
		if (tbl[Alive]) { mixin(S_TRACE);
			if (tbl[Dead]) w(Alive, Dead);
			if (tbl[Unconscious]) w(Alive, Unconscious);
			if (tbl[Paralyze]) w(Alive, Paralyze);
		}
		if (tbl[Dead]) { mixin(S_TRACE);
			if (tbl[Sleep]) w(Dead, Sleep);
			if (tbl[Confuse]) w(Dead, Confuse);
			if (tbl[Overheat]) w(Dead, Overheat);
			if (tbl[Brave]) w(Dead, Brave);
			if (tbl[Panic]) w(Dead, Panic);
		}
		if (tbl[Fine]) { mixin(S_TRACE);
			if (tbl[Injured]) w(Fine, Injured);
			if (tbl[HeavyInjured]) w(Fine, HeavyInjured);
			if (tbl[Unconscious]) w(Fine, Unconscious);
		}
		if (tbl[Injured]) { mixin(S_TRACE);
			if (tbl[HeavyInjured]) w(Injured, HeavyInjured);
			if (tbl[Unconscious]) w(Injured, Unconscious);
		}
		if (tbl[HeavyInjured]) { mixin(S_TRACE);
			if (tbl[Unconscious]) w(HeavyInjured, Unconscious);
		}
		if (tbl[Unconscious]) { mixin(S_TRACE);
			if (tbl[Sleep]) w(Unconscious, Sleep);
			if (tbl[Bind]) w(Unconscious, Bind);
			if (tbl[Confuse]) w(Unconscious, Confuse);
			if (tbl[Overheat]) w(Unconscious, Overheat);
			if (tbl[Brave]) w(Unconscious, Brave);
			if (tbl[Panic]) w(Unconscious, Panic);
			if (tbl[Silence]) w(Unconscious, Silence);
			if (tbl[FaceUp]) w(Unconscious, FaceUp);
			if (tbl[AntiMagic]) w(Unconscious, AntiMagic);
			if (tbl[UpAction]) w(Unconscious, UpAction);
			if (tbl[UpAvoid]) w(Unconscious, UpAvoid);
			if (tbl[UpResist]) w(Unconscious, UpResist);
			if (tbl[UpDefense]) w(Unconscious, UpDefense);
			if (tbl[DownAction]) w(Unconscious, DownAction);
			if (tbl[DownAvoid]) w(Unconscious, DownAvoid);
			if (tbl[DownResist]) w(Unconscious, DownResist);
			if (tbl[DownDefense]) w(Unconscious, DownDefense);
		}
		if (tbl[Sleep]) { mixin(S_TRACE);
			if (tbl[Paralyze]) w(Sleep, Paralyze);
			if (tbl[Confuse]) w(Sleep, Confuse);
			if (tbl[Overheat]) w(Sleep, Overheat);
			if (tbl[Brave]) w(Sleep, Brave);
			if (tbl[Panic]) w(Sleep, Panic);
		}
		if (tbl[Paralyze]) { mixin(S_TRACE);
			if (tbl[Confuse]) w(Paralyze, Confuse);
			if (tbl[Overheat]) w(Paralyze, Overheat);
			if (tbl[Brave]) w(Paralyze, Brave);
			if (tbl[Panic]) w(Paralyze, Panic);
		}
		if (tbl[Confuse]) { mixin(S_TRACE);
			if (tbl[Overheat]) w(Confuse, Overheat);
			if (tbl[Brave]) w(Confuse, Brave);
			if (tbl[Panic]) w(Confuse, Panic);
		}
		if (tbl[Overheat]) { mixin(S_TRACE);
			if (tbl[Brave]) w(Overheat, Brave);
			if (tbl[Panic]) w(Overheat, Panic);
		}
		if (tbl[Brave]) { mixin(S_TRACE);
			if (tbl[Panic]) w(Brave, Panic);
		}
		if (tbl[UpAction]) { mixin(S_TRACE);
			if (tbl[DownAction]) w(UpAction, DownAction);
		}
		if (tbl[UpAvoid]) { mixin(S_TRACE);
			if (tbl[DownAvoid]) w(UpAvoid, DownAvoid);
		}
		if (tbl[UpResist]) { mixin(S_TRACE);
			if (tbl[DownResist]) w(UpResist, DownResist);
		}
		if (tbl[UpDefense]) { mixin(S_TRACE);
			if (tbl[DownDefense]) w(UpDefense, DownDefense);
		}
	}
	std.algorithm.sort(ws);
	std.algorithm.uniq(ws);
	return ws;
}

/// ファイル拡張子不一致エラーがあれば返す。
string[] fileExtensionWarnings(in CProps prop, string path) { mixin(S_TRACE);
	string[] r;
	try {
		auto f = .rawFile(path, "rb");
		scope (exit) f.close();
		auto ext = .getNormalizedImageExt(f);
		if (ext != "" && path.extension().normalizedImageExt != ext) { mixin(S_TRACE);
			r ~= .tryFormat(prop.msgs.warningFileExtension, ext);
		}
		if (ext == "") { mixin(S_TRACE);
			ext = .getNormalizedSoundExt(f);
			if (ext != "" && path.extension().normalizedSoundExt != ext) { mixin(S_TRACE);
				r ~= .tryFormat(prop.msgs.warningFileExtension, ext);
			}
		}
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
	}
	return r;
}

/// textにクラシックなシナリオでの文字エンコーディングの問題がある場合は警告を返す。
string[] sjisWarnings(in CProps prop, in Summary summ, string text, string name) { mixin(S_TRACE);
	return .sjisWarnings(prop, summ ? summ.legacy : false, text, name);
}
/// ditto
string[] sjisWarnings(in CProps prop, bool legacy, string text, string name) { mixin(S_TRACE);
	if (!legacy) return [];
	foreach (dchar c; text) { mixin(S_TRACE);
		if (!.canConvToSJIS(c)) { mixin(S_TRACE);
			if (name == "") { mixin(S_TRACE);
				return [.tryFormat(prop.msgs.warningInvalidSJISCharacter, c)];
			} else { mixin(S_TRACE);
				return [.tryFormat(prop.msgs.warningInvalidSJISCharacterWithName, name, c)];
			}
		}
	}
	return [];
}
