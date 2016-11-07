/// CWXEditorの変数。
module cwx.variables;

import cwx.xml;
import cwx.structs;
import cwx.settings;
import cwx.types;

import std.path;

class FlexEtcProps : Properties {
	auto languageDir = Prop!(string, true)("languageDir", "lang");
	auto languageFile = Prop!(string)("languageFile", "");
	auto useSystemLanguage = Prop!(bool)("useSystemLanguage", true);

	auto targetVersion = Prop!(string)("targetVersion", "1.50");
	auto imeMode = Prop!(int)("imeMode", 0);
	auto imageScale = Prop!(uint)("imageScale", 1, 2016091800);
	auto toolsLock = Prop!(bool)("toolsLock", false);
	auto toolsOrder = Prop!(int[])("toolsOrder", []);
	auto toolsWrapIndices = Prop!(int[])("toolsWrapIndices", []);
	auto comboVisibleItemCount = Prop!(int, true)("comboVisibleItemCount", 20);
	auto directorySashL = Prop!(int)("directorySashL", 2);
	auto directorySashR = Prop!(int)("directorySashR", 5);
	auto directorySashV = Prop!(bool)("directorySashV", false);
	auto filesSortColumn = Prop!(int)("filesSortColumn", 1);
	auto filesSortDirection = Prop!(int)("filesSortDirection", SortDir.Up);
	auto fileNameColumn = Prop!(int, false, true)("fileNameColumn", 150);
	auto fileExtColumn = Prop!(int, false, true)("fileExtColumn", 60);
	auto fileCountColumn = Prop!(int, false, true)("fileCountColumn", 60);
	auto areaIdColumn = Prop!(int, false, true)("areaIdColumn", 50);
	auto areaNameColumn = Prop!(int, false, true)("areaNameColumn", 190);
	auto areaCountColumn = Prop!(int, false, true)("areaCountColumn", 60);
	auto importAreaIdColumn = Prop!(int, false, true)("importAreaIdColumn", 50);
	auto importAreaNameColumn = Prop!(int, false, true)("importAreaNameColumn", 190);
	auto importAreaCountColumn = Prop!(int, false, true)("importAreaCountColumn", 60);
	auto areasSortColumn = Prop!(int)("areasSortColumn", 0);
	auto areasSortDirection = Prop!(int)("areasSortDirection", SortDir.Up);
	auto importAreasSortColumn = Prop!(int)("importAreasSortColumn", 0);
	auto importAreasSortDirection = Prop!(int)("importAreasSortDirection", SortDir.Up);
	auto summaryParamSashL = Prop!(int)("summaryParamSashL", 2, 2012101100);
	auto summaryParamSashR = Prop!(int)("summaryParamSashR", 1, 2012101100);
	auto rCouponsStartAreaSashL = Prop!(int)("rCouponsStartAreaSashL", 1, 2012101100);
	auto rCouponsStartAreaSashR = Prop!(int)("rCouponsStartAreaSashR", 1, 2012101100);
	auto areaViewL = Prop!(int)("areaViewL", 1);
	auto areaViewR = Prop!(int)("areaViewR", 4);
	auto battleViewL = Prop!(int)("battleViewL", 1);
	auto battleViewR = Prop!(int)("battleViewR", 4);
	auto bgImageViewL = Prop!(int)("bgImageViewL", 1);
	auto bgImageViewR = Prop!(int)("bgImageViewR", 4);
	auto areaViewImageFlagL = Prop!(int)("areaViewImageFlagL", 4);
	auto areaViewImageFlagR = Prop!(int)("areaViewImageFlagR", 1);
	auto battleViewImageFlagL = Prop!(int)("battleViewImageFlagL", 4);
	auto battleViewImageFlagR = Prop!(int)("battleViewImageFlagR", 1);
	auto bgImageViewImageFlagL = Prop!(int)("bgImageViewImageFlagL", 4);
	auto bgImageViewImageFlagR = Prop!(int)("bgImageViewImageFlagR", 1);
	auto partyCardAlpha = Prop!(int, true)("partyCardAlpha", 176);
	auto viewPartyCardsArea = Prop!(bool)("viewPartyCardsArea", true);
	auto viewPartyCardsBattle = Prop!(bool)("viewPartyCardsBattle", true);
	auto viewEnemyCardDebug = Prop!(bool)("viewEnemyCardDebug", false);
	auto viewPartyCardsEvent = Prop!(bool)("viewPartyCardsEvent", true);
	auto messageAlpha = Prop!(int, true)("messageAlpha", 176);
	auto viewMessageArea = Prop!(bool)("viewMessageArea", false);
	auto viewMessageBattle = Prop!(bool)("viewMessageBattle", false);
	auto viewMessageEvent = Prop!(bool)("viewMessageEvent", false);
	auto viewReferenceCards = Prop!(bool)("viewReferenceCards", true);
	auto fixedImagesMenuCards = Prop!(bool)("fixedImagesMenuCards", false);
	auto fixedImagesCells = Prop!(bool)("fixedImagesCells", false);
	auto fixedImagesBackground = Prop!(bool)("fixedImagesBackground", true);
	auto fixedImagesBattle = Prop!(bool)("fixedImagesBattle", false);
	auto fixedImagesEvent = Prop!(bool)("fixedImagesEvent", false);
	auto fixedImagesEventBackground = Prop!(bool)("fixedImagesEventBackground", true);
	auto viewCards = Prop!(bool)("viewCards", true);
	auto viewBgImages = Prop!(bool)("viewBgImages", true);
	auto showGrid = Prop!(bool)("showGrid", false);
	auto areaSashT = Prop!(int)("areaSashT", 5);
	auto areaSashB = Prop!(int)("areaSashB", 4);
	auto areaSashL = Prop!(int)("areaSashL", 1);
	auto areaSashR = Prop!(int)("areaSashR", 4);
	auto importAreaSashL = Prop!(int)("importAreaSashL", 1);
	auto importAreaSashR = Prop!(int)("importAreaSashR", 3);
	auto areaSashV = Prop!(bool)("areaSashV", false);
	auto importAreaSashV = Prop!(bool)("importAreaSashV", true);
	auto flagSashL = Prop!(int)("flagSashL", 1);
	auto flagSashR = Prop!(int)("flagSashR", 4);
	auto flagSashV = Prop!(bool)("flagSashV", false);
	auto flagsWidth = Prop!(int, true, true)("flagsWidth", 150);
	auto flagsHeight = Prop!(int, true, true)("flagsHeight", 200);
	auto menuCardSashL = Prop!(int)("menuCardSashL", 5, 2012101100);
	auto menuCardSashR = Prop!(int)("menuCardSashR", 3, 2012101100);
	auto enemyCardSashL = Prop!(int)("enemyCardSashL", 3);
	auto enemyCardSashR = Prop!(int)("enemyCardSashR", 5);
	auto backSashL = Prop!(int)("backSashL", 5);
	auto backSashR = Prop!(int)("backSashR", 3);
	auto bgImageSampleWidth = Prop!(int, true, true)("bgImageSampleWidth", 150);
	auto bgImageSampleHeight = Prop!(int, true, true)("bgImageSampleHeight", 150);
	auto cellPCNumberWidth = Prop!(int, true)("cellPCNumberWidth", 150, false);
	auto textCellVSashT = Prop!(int)("textCellVSashT", 2);
	auto textCellVSashB = Prop!(int)("textCellVSashB", 1);
	auto textCellHSashL = Prop!(int)("textCellHSashL", 2);
	auto textCellHSashR = Prop!(int)("textCellHSashR", 1);
	auto textCellPreviewSashL = Prop!(int)("textCellPreviewSashL", 1);
	auto textCellPreviewSashR = Prop!(int)("textCellPreviewSashR", 1);
	auto textCellPreviewWidth = Prop!(int, true, true)("textCellPreviewWidth", 100);
	auto textCellPreviewHeight = Prop!(int, true, true)("textCellPreviewHeight", 100);
	auto textCellBoxWidth = Prop!(int, true, true)("textCellBoxWidth", 100);
	auto textCellBoxHeight = Prop!(int, true, true)("textCellBoxHeight", 50);
	auto cardIdColumn = Prop!(int, false, true)("cardIdColumn", 50);
	auto cardNameColumn = Prop!(int, false, true)("cardNameColumn", 100);
	auto cardNumberColumn = Prop!(int, false, true)("cardNumberColumn", 60);
	auto cardDescriptionColumn = Prop!(int, false, true)("cardDescriptionColumn", 280);
	auto cardCountColumn = Prop!(int, false, true)("cardCountColumn", 60);
	auto handCardIdColumn = Prop!(int, false, true)("handCardIdColumn", 50);
	auto handCardNameColumn = Prop!(int, false, true)("handCardNameColumn", 100);
	auto handCardNumberColumn = Prop!(int, false, true)("handCardNumberColumn", 60);
	auto handCardDescriptionColumn = Prop!(int, false, true)("handCardDescriptionColumn", 50);
	auto importCardIdColumn = Prop!(int, false, true)("importCardIdColumn", 50);
	auto importCardNameColumn = Prop!(int, false, true)("importCardNameColumn", 100);
	auto importCardNumberColumn = Prop!(int, false, true)("importCardNumberColumn", 60);
	auto importCardDescriptionColumn = Prop!(int, false, true)("importCardDescriptionColumn", 50);
	auto importCardCountColumn = Prop!(int, false, true)("importCardCountColumn", 30);
	auto importHandCardIdColumn = Prop!(int, false, true)("importHandCardIdColumn", 50);
	auto importHandCardNameColumn = Prop!(int, false, true)("importHandCardNameColumn", 100);
	auto importHandCardNumberColumn = Prop!(int, false, true)("importHandCardNumberColumn", 60);
	auto importHandCardDescriptionColumn = Prop!(int, false, true)("importHandCardDescriptionColumn", 50);
	auto mainCardsSortColumn = Prop!(int)("mainCardsSortColumn", 0);
	auto mainCardsSortDirection = Prop!(int)("mainCardsSortDirection", SortDir.Up);
	auto handCardsSortColumn = Prop!(int)("handCardsSortColumn", 0);
	auto handCardsSortDirection = Prop!(int)("handCardsSortDirection", SortDir.Up);
	auto importCardsSortColumn = Prop!(int)("importCardsSortColumn", 0);
	auto importCardsSortDirection = Prop!(int)("importCardsSortDirection", SortDir.Up);
	auto importHandCardsSortColumn = Prop!(int)("importHandCardsSortColumn", 0);
	auto importHandCardsSortDirection = Prop!(int)("importHandCardsSortDirection", SortDir.Up);
	auto linkCardMaskColor = Prop!(CRGB)("linkCardMaskColor", CRGB(0, 255, 0, 64), true);
	auto negativeCardNameBorder = Prop!(int)("negativeCardNameBorder", 116, true);
	auto couponWidth = Prop!(int, true, true)("couponWidth", 150);
	auto couponValueColumn = Prop!(int, true, true)("couponValueColumn", 40);
	auto idColumn = Prop!(int, false, true)("idColumn", 50);
	auto valueNumberColumn = Prop!(int, false, true)("valueNumberColumn", 50);
	auto nameTableWidth = Prop!(int, true, true)("nameTableWidth", 250);
	auto nameTableHeight = Prop!(int, true, true)("nameTableHeight", 250);
	auto flagEventSashL = Prop!(int)("flagEventSashL", 3);
	auto flagEventSashR = Prop!(int)("flagEventSashR", 2);
	auto nameWidth = Prop!(int, true, true)("nameWidth", 300);
	auto firesWidth = Prop!(int, true, true)("firesWidth", 120);
	auto flagNameWidth = Prop!(int, true, true)("flagNameWidth", 150);
	auto flagInitWidth = Prop!(int, true, true)("flagInitWidth", 50);
	auto flagValueWidth = Prop!(int, true, true)("flagValueWidth", 50);
	auto flagNameColumn = Prop!(int, false, true)("flagNameColumn", 150);
	auto flagInitColumn = Prop!(int, false, true)("flagInitColumn", 90);
	auto flagCountColumn = Prop!(int, false, true)("flagCountColumn", 60);
	auto filesWidth = Prop!(int, true, true)("filesWidth", 150);
	auto filesHeight = Prop!(int, true, true)("filesHeight", 150);
	auto talkersWidth = Prop!(int, true, true)("talkersWidth", 100);
	auto motionsWidth = Prop!(int, true, true)("motionsWidth", 150);
	auto incrementalSearchBoxWidth = Prop!(int, true, true)("incrementalSearchBoxWidth", 100);
	auto showMainToolBar = Prop!(bool)("showMainToolBar", true);
	auto showSceneToolBar = Prop!(bool)("showSceneToolBar", true);
	auto showEventToolBar = Prop!(bool)("showEventToolBar", true);
	auto flagCombiSashL = Prop!(int)("flagCombiSashL", 1);
	auto flagCombiSashR = Prop!(int)("flagCombiSashR", 1);
	auto mainToolBarCustomSashL = Prop!(int)("mainToolBarCustomSashL", 1);
	auto mainToolBarCustomSashR = Prop!(int)("mainToolBarCustomSashR", 1);
	auto stepTopSashL = Prop!(int)("stepTopSashL", 3);
	auto stepTopSashR = Prop!(int)("stepTopSashR", 2);
	auto flagTopSashL = Prop!(int)("flagTopSashL", 3);
	auto flagTopSashR = Prop!(int)("flagTopSashR", 2);
	auto toolTipWidth = Prop!(int, true, true)("toolTipWidth", 300);
	auto colorExampleWidth = Prop!(int, true, true)("colorExampleWidth", 50);
	auto buttonWidth = Prop!(int, true, true)("buttonWidth", 100);
	auto radioGroupSeparatorWidth = Prop!(int, true, true)("radioGroupSeparatorWidth", 15);
	auto couponValueColumnWidth = Prop!(int, true, true)("couponValueColumnWidth", 40);

	auto partyMax = Prop!(uint, true)("partyMax", 6);
	auto cardScaleMax = Prop!(int)("cardScaleMax", 300);
	auto cardScaleMin = Prop!(int)("cardScaleMin", 50);
	auto layerMax = Prop!(int)("layerMax", 9999);
	auto posLeftMax = Prop!(uint, true)("posLeftMax", 9999);
	auto posTopMax = Prop!(uint, true)("posTopMax", 9999);
	auto backWidthMax = Prop!(uint, true)("backWidthMax", 9999);
	auto backHeightMax = Prop!(uint, true)("backHeightMax", 9999);
	auto levelMax = Prop!(uint, true)("levelMax", 15);
	auto castLevelMax = Prop!(uint, true)("castLevelMax", 99);
	auto lifeMax = Prop!(uint, true)("lifeMax", 9999);
	auto couponValueMax = Prop!(uint, true)("couponValueMax", 999);
	auto physicalMax = Prop!(uint, true)("physicalMax", 15);
	auto mentalMax = Prop!(uint, true)("mentalMax", 4);
	auto skillLevelMax = Prop!(uint, true)("skillLevelMax", 999);
	auto useCountMax = Prop!(uint, true)("useCountMax", 999);
	auto priceMax = Prop!(uint, true)("priceMax", 999999);
	auto enhanceMax = Prop!(uint, true)("enhanceMax", 10);
	auto roundMax = Prop!(uint, true)("roundMax", 999);
	auto paralyzeMax = Prop!(uint, true)("paralyzeMax", 40);
	auto poisonMax = Prop!(uint, true)("poisonMax", 40);
	auto cardNumberMax = Prop!(uint, true)("cardNumberMax", 99);
	auto waitMax = Prop!(uint, true)("waitMax", 1000);
	auto uValueMax = Prop!(uint, true)("uValueMax", 999);
	auto skillPowerMax = Prop!(uint, true)("skillPowerMax", 9);
	auto beastMaxNest = Prop!(uint, true)("beastMaxNest", 99);

	auto flagInitValue = Prop!(bool)("flagInitValue", true);
	auto stepInitValue = Prop!(int)("stepInitValue", 0);
	auto stepCountMax = Prop!(uint)("stepCountMax", 10000, true);

	auto imageListWidth = Prop!(int, false, true)("imageListWidth", 380);
	auto imageListHeight = Prop!(int, false, true)("imageListHeight", 300);
	auto layerListWidth = Prop!(int, false, true)("layerListWidth", 300);
	auto layerListHeight = Prop!(int, false, true)("layerListHeight", 350);
	auto cardLife = Prop!(bool)("cardLife", false);
	auto cardDetails = Prop!(bool)("cardDetails", false);
	auto cardsMarginX = Prop!(int, true, true)("cardsMarginX", 5);
	auto cardsSpaceX = Prop!(int, true, true)("cardsSpaceX", 8);
	auto cardsMarginY = Prop!(int, true, true)("cardsMarginY", 5);
	auto cardsSpaceY = Prop!(int, true, true)("cardsSpaceY", 8);
	auto cardsTitleSpace = Prop!(int, true, true)("cardsTitleSpace", 2);
	auto cardsFocusLinePadding = Prop!(int, true, true)("cardsFocusLinePadding", 2);
	auto cardsDefaultWrap = Prop!(int, true)("cardsDefaultWrap", 4);
	auto seKeyCodeSashL = Prop!(int)("seKeyCodeSashL", 4, 2012101100);
	auto seKeyCodeSashR = Prop!(int)("seKeyCodeSashR", 7, 2012101100);
	auto talkMainSashL = Prop!(int)("talkMainSashL", 3);
	auto talkMainSashR = Prop!(int)("talkMainSashR", 7);
	auto talkLeftSashL = Prop!(int)("talkLeftSashL", 4);
	auto talkLeftSashR = Prop!(int)("talkLeftSashR", 5);
	auto msgBackR = Prop!(int, true)("msgBackR", 0);
	auto msgBackG = Prop!(int, true)("msgBackG", 0);
	auto msgBackB = Prop!(int, true)("msgBackB", 128);
	auto msgForeR = Prop!(int, true)("msgForeR", 255);
	auto msgForeG = Prop!(int, true)("msgForeG", 255);
	auto msgForeB = Prop!(int, true)("msgForeB", 255);
	auto textTabs = Prop!(int, true)("textTabs", 4);
	auto messageLineColor1 = Prop!(CRGB, true)("messageLineColor1", CRGB(0, 0, 0));
	auto messageLineColor2 = Prop!(CRGB, true)("messageLineColor2", CRGB(128, 0, 0));
	auto messageBackColor = Prop!(CRGB, true)("messageBackColor", CRGB(0, 0, 128));
	auto messageForeColor = Prop!(CRGB, true)("messageForeColor", CRGB(255, 255, 255));
	auto messageHemColor = Prop!(CRGB, true)("messageHemColor", CRGB(0, 0, 0));
	auto gridX = Prop!(uint)("gridX", 10);
	auto gridY = Prop!(uint)("gridY", 10);
	auto gridRange = Prop!(uint)("gridRange", 5);
	auto gridColor = Prop!(CRGB, true)("gridColor", CRGB(64, 64, 64));
	auto gridHighlightColor = Prop!(CRGB, true)("gridHighlightColor", CRGB(192, 192, 192));
	auto enhanceMaxVal = Prop!(uint, true)("enhanceMaxVal", 10);
	auto enhanceHighVal = Prop!(uint, true)("enhanceHighVal", 7);
	auto enhanceMiddleVal = Prop!(uint, true)("enhanceMiddleVal", 4);
	auto enhanceColorMax = Prop!(CRGB, true)("enhanceColorHigh", CRGB(255, 0, 0));
	auto enhanceColorHigh = Prop!(CRGB, true)("enhanceColorHigh", CRGB(175, 0, 0));
	auto enhanceColorMiddle = Prop!(CRGB, true)("enhanceColorMiddle", CRGB(127, 0, 0));
	auto enhanceColorLow = Prop!(CRGB, true)("enhanceColorLow", CRGB(79, 0, 0));
	auto penaltyColorMax = Prop!(CRGB, true)("penaltyColorHigh", CRGB(0, 0, 51));
	auto penaltyColorHigh = Prop!(CRGB, true)("penaltyColorHigh", CRGB(0, 0, 85));
	auto penaltyColorMiddle = Prop!(CRGB, true)("penaltyColorMiddle", CRGB(0, 0, 136));
	auto penaltyColorLow = Prop!(CRGB, true)("penaltyColorLow", CRGB(0, 0, 187));
	auto textCellDefaultWidth = Prop!(int, true)("textCellDefaultWidth", 100);
	auto textCellDefaultHeight = Prop!(int, true)("textCellDefaultHeight", 100);
	auto textCellDefaultFontClassic = Prop!(string, true)("textCellDefaultFontClassic", "ＭＳ ゴシック");
	auto textCellDefaultFont = Prop!(string, true)("textCellDefaultFont", "IPA ゴシック");
	auto textCellDefaultFontSize = Prop!(int, true)("textCellDefaultFontSize", 18);
	auto textCellDefaultColor = Prop!(CRGB, true)("textCellDefaultColor", CRGB(0, 0, 0, 255));
	auto textCellDefaultBorderingColor = Prop!(CRGB, true)("textCellDefaultBorderingColor", CRGB(255, 255, 255, 255));
	auto fontSizeMax = Prop!(uint, true)("fontSizeMax", 999);
	auto borderingWidthMax = Prop!(uint, true)("borderingWidthMax", 99);
	auto colorCellDefaultWidth = Prop!(int, true)("colorCellDefaultWidth", 100);
	auto colorCellDefaultHeight = Prop!(int, true)("colorCellDefaultHeight", 100);
	auto colorCellDefaultColor1 = Prop!(CRGB, true)("colorCellDefaultColor1", CRGB(255, 255, 255, 255));
	auto colorCellDefaultColor2 = Prop!(CRGB, true)("colorCellDefaultColor2", CRGB(0, 0, 0, 255));

	auto noFileName = Prop!(string, true)("noFileName", "_");

	auto contentsOrder = Prop!(int[])("contentsOrder", []);
	auto contentsLock = Prop!(bool)("contentsLock", false);
	auto contentsWrapIndices = Prop!(int[])("contentsWrapIndices", [4, 6, 8]);
	auto contentsAutoOpen = Prop!(bool)("contentsAutoOpen", true);
	auto contentsPutMode = Prop!(int)("contentsPutMode", 0);
	auto contentsInsertFirst = Prop!(bool)("contentsInsertFirst", false);
	auto showContentsGroupName = Prop!(bool)("showContentsGroupName", true);
	auto showEventContentDescription = Prop!(bool)("showEventContentDescription", true);
	auto showMotionDescription = Prop!(bool)("showMotionDescription", true);
	auto contentsFloat = Prop!(bool)("contentsFloat", false);
	auto contentsAutoHide = Prop!(bool)("contentsAutoHide", false);
	auto comboListVisible = Prop!(bool)("comboListVisible", true);
	auto showContentsBoxHeightWhenNoToolBar = Prop!(int, true)("showContentsBoxHeightWhenNoToolBar", 8);
	auto showSummaryInAreaTable = Prop!(bool)("showSummaryInAreaTable", true);
	auto clickIsOpenEvent = Prop!(bool)("clickIsOpenEvent", false);
	auto smoothingCard = Prop!(bool)("smoothingCard", true);
	auto ignorePathsWidth = Prop!(int, true, true)("ignorePathsWidth", 50);
	auto menuSettingsHeight = Prop!(int, true, true)("menuSettingsHeight", 150);
	auto settingListWidth = Prop!(int, true, true)("settingListWidth", 150);
	auto settingListHeight = Prop!(int, true, true)("settingListHeight", 150);

	auto importOptionMaterials = Prop!(int)("importOptionMaterials", ImportTypeReference1.NoOverwrite);
	auto importOptionVariables = Prop!(int)("importOptionVariables", ImportTypeReference1.Rename);
	auto importOptionCasts = Prop!(int)("importOptionCasts", ImportTypeReference2.NoImport);
	auto importOptionSkills = Prop!(int)("importOptionSkills", ImportTypeReference2.NoImport);
	auto importOptionItems = Prop!(int)("importOptionItems", ImportTypeReference2.NoImport);
	auto importOptionBeasts = Prop!(int)("importOptionBeasts", ImportTypeReference2.NoImport);
	auto importOptionInfos = Prop!(int)("importOptionInfos", ImportTypeReference2.NoImport);
	auto importOptionAreas = Prop!(int)("importOptionAreas", ImportTypeReference2.NoImport);
	auto importOptionBattles = Prop!(int)("importOptionBattles", ImportTypeReference2.NoImport);
	auto importOptionPackages = Prop!(int)("importOptionPackages", ImportTypeReference2.NoImport);
	auto importOptionIncludedFiles = Prop!(int)("importOptionIncludedFiles", ImportTypeIncluded.AsIs);
	auto importOptionIncludedFilesWithoutIncluding = Prop!(int)("importOptionIncludedFilesWithoutIncluding", ImportTypeIncluded.Exclude);
	auto importOptionIncludedBgImages = Prop!(int)("importOptionIncludedBgImages", ImportTypeIncluded.AsIs);
	auto importOptionHands = Prop!(int)("importOptionHands", ImportTypeIncluded.AsIs);
	auto importOptionBeastsInMotions = Prop!(int)("importOptionBeastsInMotions", ImportTypeIncluded.AsIs);
	auto importOptionOverwriteScenarioInfo = Prop!(bool)("importOptionOverwriteScenarioInfo", false);
	auto wallpaper = Prop!(string)("wallpaper", "");
	auto wallpaperStyle = Prop!(int)("wallpaperStyle", WallpaperStyle.Tile);
	auto wallColorR = Prop!(int)("wallColorR", 0);
	auto wallColorG = Prop!(int)("wallColorG", 0);
	auto wallColorB = Prop!(int)("wallColorB", 128);
	auto bgImagesDefault = Prop!(BgImageS[])("bgImagesDefault", [BgImageS("MapOfWirth", 0, 0, 632, 420, false)]);
	auto bgImageSettingsSashL = Prop!(int)("bgImageSettingsSashL", 1);
	auto bgImageSettingsSashR = Prop!(int)("bgImageSettingsSashR", 1);
	auto bgImageKeyCodeSashL = Prop!(int)("bgImageKeyCodeSashL", 2);
	auto bgImageKeyCodeSashR = Prop!(int)("bgImageKeyCodeSashR", 1);
	auto outerToolsSashL = Prop!(int)("outerToolsSashL", 1);
	auto outerToolsSashR = Prop!(int)("outerToolsSashR", 2);
	auto outerToolShortcutSashL = Prop!(int)("outerToolShortcutSashL", 1, 2014103100);
	auto outerToolShortcutSashR = Prop!(int)("outerToolShortcutSashR", 4, 2014103100);
	auto classicEnginesSashL = Prop!(int)("classicEnginesSashL", 1);
	auto classicEnginesSashR = Prop!(int)("classicEnginesSashR", 2);
	auto classicEngineShortcutSashL = Prop!(int)("classicEngineShortcutSashL", 1, 2014103100);
	auto classicEngineShortcutSashR = Prop!(int)("classicEngineShortcutSashR", 4, 2014103100);
	auto featureDefaultNameWidth = Prop!(int, false, true)("featureDefaultNameWidth", 100);
	auto featureVariantNameWidth = Prop!(int, false, true)("featureVariantNameWidth", 100);
	auto featureManualNameWidth = Prop!(int, false, true)("featureManualNameWidth", 100);
	auto eventTemplatesSashL = Prop!(int)("eventTemplatesSashL", 1);
	auto eventTemplatesSashR = Prop!(int)("eventTemplatesSashR", 2);
	auto eventTemplatesOfScenarioSashL = Prop!(int)("eventTemplatesOfScenarioSashL", 1);
	auto eventTemplatesOfScenarioSashR = Prop!(int)("eventTemplatesOfScenarioSashR", 2);
	auto eventTemplateShortcutSashL = Prop!(int)("eventTemplateShortcutSashL", 1, 2014103100);
	auto eventTemplateShortcutSashR = Prop!(int)("eventTemplateShortcutSashR", 4, 2014103100);
	auto eventTemplateOfScenarioShortcutSashL = Prop!(int)("eventTemplateOfScenarioShortcutSashL", 1, 2014103100);
	auto eventTemplateOfScenarioShortcutSashR = Prop!(int)("eventTemplateOfScenarioShortcutSashR", 5, 2014103100);
	auto scenarioTemplatesSashL = Prop!(int)("scenarioTemplatesSashL", 1);
	auto scenarioTemplatesSashR = Prop!(int)("scenarioTemplatesSashR", 2);
	auto templatesSashL = Prop!(int)("templatesSashL", 1);
	auto templatesSashR = Prop!(int)("templatesSashR", 1);
	auto toolsClassicEnginesSashL = Prop!(int)("toolsClassicEnginesSashL", 1);
	auto toolsClassicEnginesSashR = Prop!(int)("toolsClassicEnginesSashR", 1);
	auto keyCodeWidth = Prop!(int, true, true)("keyCodeWidth", 100);
	auto scenarioPath = Prop!(string)("scenarioPath", "");
	auto tempPath = Prop!(string)("tempPath", "temp");
	auto backupPath = Prop!(string)("backupPath", "backup");
	auto backupEnabled = Prop!(bool)("backupEnabled", true);
	auto backupIntervalType = Prop!(int)("backupIntervalType", 0);
	auto backupInterval = Prop!(int)("backupInterval", 15);
	auto backupIntervalEdit = Prop!(int)("backupIntervalEdit", 20);
	auto backupCount = Prop!(int)("backupCount", 10);
	auto autoSave = Prop!(bool)("autoSave", false);
	auto backupRefAuthor = Prop!(bool)("backupRefAuthor", false);
	auto backupBeforeSaveEnabled = Prop!(bool)("backupBeforeSaveEnabled", true);
	auto backupBeforeSavePath = Prop!(string)("backupBeforeSavePath", "backup");
	auto backupBeforeSaveDir = Prop!(string, true)("backupBeforeSaveDir", "files");
	auto backupArchived = Prop!(bool)("backupArchived", true);
	auto ignoreMenuSashL = Prop!(int)("ignoreMenuSashL", 2);
	auto ignoreMenuSashR = Prop!(int)("ignoreMenuSashR", 1);
	auto highValueOfImageControl = Prop!(uint, true)("highValueOfImageControl", 10);

	auto openHistories = Prop!(OpenHistory[])("openHistories", []);
	auto historyMax = Prop!(int)("historyMax", 9);
	auto historySnipLength = Prop!(int)("historySnipLength", 30);
	auto lastScenario = Prop!(string)("lastScenario", "");
	auto searchResultTableWidth = Prop!(int, true, true)("searchResultTableWidth", 400);
	auto searchResultTableHeight = Prop!(int, true, true)("searchResultTableHeight", 200);
	version (Windows) {
		auto engine = Prop!(string, true)("engine", "CardWirthPy.exe");
	} else {
		auto engine = Prop!(string, true)("engine", "CardWirthPy");
	}
	auto engineScript = Prop!(string, true)("engineScript", "cardwirth.py");
	auto enginePath = Prop!(string)("enginePath", "");
	auto lastExecuteIsClassic = Prop!(bool)("lastExecuteIsClassic", false, 2015022500);
	auto lastExecuteEngine = Prop!(string)("lastExecuteEngine", "", 2015022500);
	auto lastExecuteParameters = Prop!(string)("lastExecuteParameters", "", 2015022500);
	auto lastExecuteEngineName = Prop!(string)("lastExecuteEngineName", "");
	auto lastExecuteYadoName = Prop!(string)("lastExecuteYadoName", "");
	auto lastExecutePartyName = Prop!(string)("lastExecutePartyName", "");
	auto dataDir = Prop!(string, true)("dataDir", "Data");
	auto findEnginePath = Prop!(bool)("findEnginePath", true);
	auto defaultSkin = Prop!(string, true)("defaultSkin", "MedievalFantasy");
	auto defaultAuthor = Prop!(string)("defaultAuthor", "");

	auto classicEngineRegex = Prop!(string)("classicEngineRegex", "^(CW´|.+Wirth(_.+|Next)?)\\.exe$");
	auto classicDataDirRegex = Prop!(string)("classicDataDirRegex", "^Data|D_[A-Z]1|[A-Z]_dt$");
	auto classicMatchKey = Prop!(string, true)("classicMatchKey", "Table" ~ dirSeparator ~ "MapOfWirth.BMP");

	auto expandXMLs = Prop!(bool)("expandXMLs", false);
	auto xmlCopy = Prop!(bool)("xmlCopy", false);
	auto showSpNature = Prop!(bool)("showSpNature", false);
	auto saveChangedOnly = Prop!(bool)("saveChangedOnly", false);
	auto xmlFileNameIsIDOnly = Prop!(bool)("xmlFileNameIsIDOnly", false);
	auto archiveInNewThread = Prop!(bool)("archiveInNewThread", true);
	auto saveInnerImagePath = Prop!(bool)("saveInnerImagePath", false);
	auto linkCard = Prop!(bool)("linkCard", false);
	auto traceDirectories = Prop!(bool)("traceDirectories", true);
	auto logicalSort = Prop!(bool)("logicalSort", true);
	auto copyDesc = Prop!(bool)("copyDesc", false);
	auto refCardsAtEditBgImage = Prop!(bool)("refCardsAtEditBgImage", true);
	auto showImagePreview = Prop!(bool)("showImagePreview", true);
	auto maskCardImagePreview = Prop!(bool)("maskCardImagePreview", true);
	auto ignoreBackgroundInRange = Prop!(bool)("ignoreBackgroundInRange", true);
	auto classicStyleTree = Prop!(bool)("classicStyleTree", false);
	auto adjustContentName = Prop!(bool)("adjustContentName", true);
	auto showEventTreeMark = Prop!(bool)("showEventTreeMark", true);
	auto ignoreEmptyStart = Prop!(bool)("ignoreEmptyStart", true);
	auto showSkillCardLevel = Prop!(bool)("showSkillCardLevel", true);
	auto switchTabWheel = Prop!(bool)("switchTabWheel", true);
	auto closeTabWithMiddleClick = Prop!(bool)("closeTabWithMiddleClick", true);
	auto openTabAtRightOfCurrentTab = Prop!(bool)("openTabAtRightOfCurrentTab", true);
	auto showCloseButtonAllTab = Prop!(bool)("showCloseButtonAllTab", false);
	auto cautionBeforeReplace = Prop!(bool)("cautionBeforeReplace", false);
	auto startIncrementalSearchWhenKeyDown = Prop!(bool)("startIncrementalSearchWhenKeyDown", true);
	auto radarStyleParams = Prop!(bool)("radarStyleParams", true);
	auto showCardListHeader = Prop!(bool)("showCardListHeader", true);
	auto showCardListTitle = Prop!(bool)("showCardListTitle", true);
	auto applyDialogsBeforeSave = Prop!(bool)("applyDialogsBeforeSave", true);
	auto useNamesAfterStandard = Prop!(bool)("useNamesAfterStandard", false);
	auto selectVariableWithTree = Prop!(bool)("selectVariableWithTree", true);
	auto useCurrentStartName = Prop!(bool)("useCurrentStartName", true);
	auto autoUpdateJpy1File = Prop!(bool)("autoUpdateJpy1File", false);
	auto straightEventTreeView = Prop!(bool)("straightEventTreeView", true);
	auto eventTreeSlope = Prop!(int)("eventTreeSlope", 16);
	auto forceIndentBranchContent = Prop!(bool)("forceIndentBranchContent", true);
	auto showTerminalMark = Prop!(bool)("showTerminalMark", true);
	auto clickIconIsStartEdit = Prop!(bool)("clickIconIsStartEdit", false);
	auto showAreaDirTree = Prop!(bool)("showAreaDirTree", true);
	auto sortFlagDirs = Prop!(bool)("sortFlagDirs", true);
	auto saveNeedChanged = Prop!(bool)("saveNeedChanged", true);
	auto canVanishWorkAreaInMainWindow = Prop!(bool)("canVanishWorkAreaInMainWindow", false);

	auto showEventTreeLineNumber = Prop!(bool)("showEventTreeLineNumber", true);
	auto showEventTreeDetail = Prop!(bool)("showEventTreeDetail", true);
	auto editTriggerType = Prop!(int)("editTriggerType", EditTrigger.Slow);

	auto spinnerUpDownWithWheel = Prop!(bool)("spinnerUpDownWithWheel", true);

	auto soundPlayType = Prop!(int)("soundPlayType", 0);
	auto soundEffectPlayType = Prop!(int)("soundEffectPlayType", -1);
	auto bgmVolume = Prop!(int)("bgmVolume", 100);
	auto seVolume = Prop!(int)("seVolume", 100);

	auto loopCountMax = Prop!(uint)("loopCountMax", 100, true);
	auto fadeInMax = Prop!(uint)("fadeInMax", 1000, true);

	auto selectionColumnsMax = Prop!(uint)("selectionColumnsMax", 4, true);

	auto detailAreaWidth = Prop!(int, false, true)("detailAreaWidth", 200);

	auto searchPlan = Prop!(int)("searchPlan", 0);
	auto searchIDKind = Prop!(int)("searchIDKind", 0);
	auto searchHistories = Prop!(string[])("searchHistories", []);
	auto replaceHistories = Prop!(string[])("replaceHistories", []);
	auto searchHistoryMax = Prop!(int)("searchHistoryMax", 50);
	auto replaceRangeSashL = Prop!(int)("replaceRangeSashL", 3, 2012090100);
	auto replaceRangeSashR = Prop!(int)("replaceRangeSashR", 1, 2012090100);
	auto replaceTextNotIgnoreCase = Prop!(bool)("replaceTextNotIgnoreCase", false);
	auto replaceTextRegExp = Prop!(bool)("replaceTextRegExp", false);
	auto replaceTextWildcard = Prop!(bool)("replaceTextWildcard", false);
	auto replaceTextExactMatch = Prop!(bool)("replaceTextExactMatch", false);
	auto replaceTextIgnoreReturnCode = Prop!(bool)("replaceTextIgnoreReturnCode", false);
	auto grepDir = Prop!(string)("grepDir", "");
	auto grepDirHistories = Prop!(string[])("grepDirHistories", []);
	auto grepSubDir = Prop!(bool)("grepSubDir", true);
	auto searchResultRefreshCount = Prop!(int, true)("searchResultRefreshCount", 100);
	auto searchResultRealtime = Prop!(bool)("searchResultRealtime", false);

	auto replaceTextSummary = Prop!(bool)("replaceTextSummary", true);
	auto replaceTextScenario = Prop!(bool)("replaceTextScenario", false);
	auto replaceTextAuthor = Prop!(bool)("replaceTextAuthor", false);
	auto replaceTextMessage = Prop!(bool)("replaceTextMessage", true);
	auto replaceTextCardName = Prop!(bool)("replaceTextCardName", true);
	auto replaceTextCardDescription = Prop!(bool)("replaceTextCardDescription", true);
	auto replaceTextEventText = Prop!(bool)("replaceTextEventText", true);
	auto replaceTextStart = Prop!(bool)("replaceTextStart", true);
	auto replaceTextFlagAndStep = Prop!(bool)("replaceTextFlagAndStep", true);
	auto replaceTextCoupon = Prop!(bool)("replaceTextCoupon", true);
	auto replaceTextGossip = Prop!(bool)("replaceTextGossip", true);
	auto replaceTextEndScenario = Prop!(bool)("replaceTextEndScenario", true);
	auto replaceTextAreaName = Prop!(bool)("replaceTextAreaName", true);
	auto replaceTextKeyCode = Prop!(bool)("replaceTextKeyCode", true);
	auto replaceTextCellName = Prop!(bool)("replaceTextCellName", true);
	auto replaceTextFile = Prop!(bool)("replaceTextFile", false);
	auto replaceTextComment = Prop!(bool)("replaceTextComment", true);
	auto replaceTextJptx = Prop!(bool)("replaceTextJptx", false);

	auto replaceNameCoupon = Prop!(bool)("replaceNameCoupon", true);
	auto replaceNameGossip = Prop!(bool)("replaceNameGossip", true);
	auto replaceNameEndScenario = Prop!(bool)("replaceNameEndScenario", true);
	auto replaceNameKeyCode = Prop!(bool)("replaceNameKeyCode", true);
	auto replaceNameCellName = Prop!(bool)("replaceNameCellName", true);

	auto searchContentsStart = Prop!(bool)("searchContentsStart", false);
	auto searchContentsStartBattle = Prop!(bool)("searchContentsStartBattle", false);
	auto searchContentsEnd = Prop!(bool)("searchContentsEnd", false);
	auto searchContentsEndBadEnd = Prop!(bool)("searchContentsEndBadEnd", false);
	auto searchContentsChangeArea = Prop!(bool)("searchContentsChangeArea", false);
	auto searchContentsChangeBgImage = Prop!(bool)("searchContentsChangeBgImage", false);
	auto searchContentsEffect = Prop!(bool)("searchContentsEffect", false);
	auto searchContentsEffectBreak = Prop!(bool)("searchContentsEffectBreak", false);
	auto searchContentsLinkStart = Prop!(bool)("searchContentsLinkStart", false);
	auto searchContentsLinkPackage = Prop!(bool)("searchContentsLinkPackage", false);
	auto searchContentsTalkMessage = Prop!(bool)("searchContentsTalkMessage", false);
	auto searchContentsTalkDialog = Prop!(bool)("searchContentsTalkDialog", false);
	auto searchContentsPlayBgm = Prop!(bool)("searchContentsPlayBgm", false);
	auto searchContentsPlaySound = Prop!(bool)("searchContentsPlaySound", false);
	auto searchContentsWait = Prop!(bool)("searchContentsWait", false);
	auto searchContentsElapseTime = Prop!(bool)("searchContentsElapseTime", false);
	auto searchContentsCallStart = Prop!(bool)("searchContentsCallStart", false);
	auto searchContentsCallPackage = Prop!(bool)("searchContentsCallPackage", false);
	auto searchContentsBranchFlag = Prop!(bool)("searchContentsBranchFlag", false);
	auto searchContentsBranchMultiStep = Prop!(bool)("searchContentsBranchMultiStep", false);
	auto searchContentsBranchStep = Prop!(bool)("searchContentsBranchStep", false);
	auto searchContentsBranchSelect = Prop!(bool)("searchContentsBranchSelect", false);
	auto searchContentsBranchAbility = Prop!(bool)("searchContentsBranchAbility", false);
	auto searchContentsBranchRandom = Prop!(bool)("searchContentsBranchRandom", false);
	auto searchContentsBranchLevel = Prop!(bool)("searchContentsBranchLevel", false);
	auto searchContentsBranchStatus = Prop!(bool)("searchContentsBranchStatus", false);
	auto searchContentsBranchPartyNumber = Prop!(bool)("searchContentsBranchPartyNumber", false);
	auto searchContentsBranchArea = Prop!(bool)("searchContentsBranchArea", false);
	auto searchContentsBranchBattle = Prop!(bool)("searchContentsBranchBattle", false);
	auto searchContentsBranchIsBattle = Prop!(bool)("searchContentsBranchIsBattle", false);
	auto searchContentsBranchCast = Prop!(bool)("searchContentsBranchCast", false);
	auto searchContentsBranchItem = Prop!(bool)("searchContentsBranchItem", false);
	auto searchContentsBranchSkill = Prop!(bool)("searchContentsBranchSkill", false);
	auto searchContentsBranchInfo = Prop!(bool)("searchContentsBranchInfo", false);
	auto searchContentsBranchBeast = Prop!(bool)("searchContentsBranchBeast", false);
	auto searchContentsBranchMoney = Prop!(bool)("searchContentsBranchMoney", false);
	auto searchContentsBranchCoupon = Prop!(bool)("searchContentsBranchCoupon", false);
	auto searchContentsBranchCompleteStamp = Prop!(bool)("searchContentsBranchCompleteStamp", false);
	auto searchContentsBranchGossip = Prop!(bool)("searchContentsBranchGossip", false);
	auto searchContentsSetFlag = Prop!(bool)("searchContentsSetFlag", false);
	auto searchContentsSetStep = Prop!(bool)("searchContentsSetStep", false);
	auto searchContentsSetStepUp = Prop!(bool)("searchContentsSetStepUp", false);
	auto searchContentsSetStepDown = Prop!(bool)("searchContentsSetStepDown", false);
	auto searchContentsReverseFlag = Prop!(bool)("searchContentsReverseFlag", false);
	auto searchContentsCheckFlag = Prop!(bool)("searchContentsCheckFlag", false);
	auto searchContentsGetCast = Prop!(bool)("searchContentsGetCast", false);
	auto searchContentsGetItem = Prop!(bool)("searchContentsGetItem", false);
	auto searchContentsGetSkill = Prop!(bool)("searchContentsGetSkill", false);
	auto searchContentsGetInfo = Prop!(bool)("searchContentsGetInfo", false);
	auto searchContentsGetBeast = Prop!(bool)("searchContentsGetBeast", false);
	auto searchContentsGetMoney = Prop!(bool)("searchContentsGetMoney", false);
	auto searchContentsGetCoupon = Prop!(bool)("searchContentsGetCoupon", false);
	auto searchContentsGetCompleteStamp = Prop!(bool)("searchContentsGetCompleteStamp", false);
	auto searchContentsGetGossip = Prop!(bool)("searchContentsGetGossip", false);
	auto searchContentsLoseCast = Prop!(bool)("searchContentsLoseCast", false);
	auto searchContentsLoseItem = Prop!(bool)("searchContentsLoseItem", false);
	auto searchContentsLoseSkill = Prop!(bool)("searchContentsLoseSkill", false);
	auto searchContentsLoseInfo = Prop!(bool)("searchContentsLoseInfo", false);
	auto searchContentsLoseBeast = Prop!(bool)("searchContentsLoseBeast", false);
	auto searchContentsLoseMoney = Prop!(bool)("searchContentsLoseMoney", false);
	auto searchContentsLoseCoupon = Prop!(bool)("searchContentsLoseCoupon", false);
	auto searchContentsLoseCompleteStamp = Prop!(bool)("searchContentsLoseCompleteStamp", false);
	auto searchContentsLoseGossip = Prop!(bool)("searchContentsLoseGossip", false);
	auto searchContentsShowParty = Prop!(bool)("searchContentsShowParty", false);
	auto searchContentsHideParty = Prop!(bool)("searchContentsHideParty", false);
	auto searchContentsRedisplay = Prop!(bool)("searchContentsRedisplay", false);
	auto searchContentsSubstituteStep = Prop!(bool)("searchContentsSubstituteStep", false);
	auto searchContentsSubstituteFlag = Prop!(bool)("searchContentsSubstituteFlag", false);
	auto searchContentsBranchStepCmp = Prop!(bool)("searchContentsBranchStepCmp", false);
	auto searchContentsBranchFlagCmp = Prop!(bool)("searchContentsBranchFlagCmp", false);
	auto searchContentsBranchRandomSelect = Prop!(bool)("searchContentsBranchRandomSelect", false);
	auto searchContentsBranchKeyCode = Prop!(bool)("searchContentsBranchKeyCode", false);
	auto searchContentsCheckStep = Prop!(bool)("searchContentsCheckStep", false);
	auto searchContentsBranchRound = Prop!(bool)("searchContentsBranchRound", false);
	auto searchContentsReplaceBgImage = Prop!(bool)("searchContentsReplaceBgImage", false);
	auto searchContentsMoveBgImage = Prop!(bool)("searchContentsMoveBgImage", false);
	auto searchContentsLoseBgImage = Prop!(bool)("searchContentsLoseBgImage", false);

	auto searchUnusedFlag = Prop!(bool)("searchUnusedFlag", true);
	auto searchUnusedStep = Prop!(bool)("searchUnusedStep", true);
	auto searchUnusedArea = Prop!(bool)("searchUnusedArea", true);
	auto searchUnusedBattle = Prop!(bool)("searchUnusedBattle", true);
	auto searchUnusedPackage = Prop!(bool)("searchUnusedPackage", true);
	auto searchUnusedCast = Prop!(bool)("searchUnusedCast", true);
	auto searchUnusedSkill = Prop!(bool)("searchUnusedSkill", true);
	auto searchUnusedItem = Prop!(bool)("searchUnusedItem", true);
	auto searchUnusedBeast = Prop!(bool)("searchUnusedBeast", true);
	auto searchUnusedInfo = Prop!(bool)("searchUnusedInfo", true);
	auto searchUnusedStart = Prop!(bool)("searchUnusedStart", true);
	auto searchUnusedPath = Prop!(bool)("searchUnusedPath", true);
	auto searchOpenDialog = Prop!(bool)("searchOpenDialog", false);

	auto searchResultColumnMain = Prop!(int, false, true)("searchResultColumnMain", 400);
	auto searchResultColumnParent = Prop!(int, false, true)("searchResultColumnParent", 200);
	auto searchResultColumnCouponCount = Prop!(int, false, true)("searchResultColumnCouponCount", 60);
	auto searchResultColumnErrorDesc = Prop!(int, false, true)("searchResultColumnErrorDesc", 500);
	auto searchResultColumnScenario = Prop!(int, false, true)("searchResultColumnScenario", 500);

	auto incrementalSearchType = Prop!(int)("incrementalSearchType", 0);

	auto usedCouponToCombo = Prop!(bool, true)("usedCouponToCombo", true);

	auto flagTrues = Prop!(string[])("flagTrues", ["TRUE", "表示", "ON", "有", "可", "済み"], true);
	auto flagFalses = Prop!(string[])("flagFalses", ["FALSE", "非表示", "OFF", "無", "不可", "まだ"], true);

	auto bgImageSettings = Prop!(BgImageSetting[])("bgImageSettings", [
		BgImageSetting("冒険者の宿", 116, 15, 400, 260, false, LAYER_BACK_CELL),
		BgImageSetting("冒険者の宿(フレーム)", 116, 14, 400, 261, true, LAYER_BACK_CELL),
		BgImageSetting("フル", 0, 0, 632, 420, false, LAYER_BACK_CELL),
		BgImageSetting("フル(マスク)", 0, 0, 632, 420, true, LAYER_BACK_CELL),
		BgImageSetting("カード", 0, 0, 74, 94, true, LAYER_BACK_CELL),
		BgImageSetting("冒険者カード", 0, 0, 95, 130, false, LAYER_BACK_CELL),
		BgImageSetting("ゲームオーバー", 116, 55, 400, 260, false, LAYER_BACK_CELL),
		BgImageSetting("Qubes 地面", 160, 80, 320, 160, true, LAYER_BACK_CELL),
		BgImageSetting("Qubes 左後", 80, 0, 240, 160, true, LAYER_BACK_CELL),
		BgImageSetting("Qubes 右後", 320, 0, 240, 160, true, LAYER_BACK_CELL),
		BgImageSetting("Qubes 左前", 80, 80, 240, 200, true, LAYER_BACK_CELL),
		BgImageSetting("Qubes 右前", 320, 80, 240, 200, true, LAYER_BACK_CELL)
	]);
	auto standardCoupons = Prop!(string[])("standardCoupons", [
		"：Ｒ", "＿１", "＿２", "＿３", "＿４", "＿５", "＿６", "＿消滅予約", "：レベル補正中"
	], true);
	auto standardKeyCodes = Prop!(string[])("standardKeyCodes", [
		"攻撃",
		"治療",
		"魔法",
		"召喚獣",
		"気功法",
		"遠距離攻撃",
		"神聖な攻撃",
		"魔法による攻撃",
		"炎による攻撃",
		"冷気による攻撃",
		"暗殺",
		"精神を回復",
		"中毒を解除",
		"麻痺を解除",
		"眠り",
		"麻痺",
		"中毒",
		"呪縛",
		"沈黙",
		"召喚",
		"鑑定",
		"解錠",
		"呪縛を解除",
		"沈黙を解除",
		"魔法を解除",
		"",
		"魔力感知",
		"生命感知",
		"魔法の鍵",
		"解読",
		"石化",
		"石化を解除",
		"蝙蝠変化",
		"明かり",
		"目つぶし",
		"魅了",
		"透明",
		"召喚獣を付与",
		"暴露",
		"即死",
		"一撃必殺",
		"対象消去",
		"恐慌",
		"不浄な攻撃",
		"呪い",
		"飛行",
		"浮遊",
		"灯火",
		"",
		"フェイント",
		"防御",
		"逃走",
		"カード交換",
		"ペナルティ",
		"リサイクル",
		"",
		"一撃",
		"守備",
	]);
	version (Windows) {
		auto outerTools = Prop!(OuterTool[])("outerTools", [
			OuterTool("メモ帳", "notepad $F", "", "", ""),
			OuterTool("ペイント", "mspaint $F", "", "", "")
		]);
	} else {
		auto outerTools = Prop!(OuterTool[])("outerTools", []);
	}
	version (Windows) {
		auto ignorePaths = Prop!(string[])("ignorePaths", [".*", "Thumbs.db"]);
	} else {
		auto ignorePaths = Prop!(string[])("ignorePaths", [".*"]);
	}

	auto selectedArchiveFilter = Prop!(string)("selectedArchiveFilter", ".zip");

	auto classicEngines = Prop!(ClassicEngine[])("classicEngines", []);
	auto addNewClassicEngine = Prop!(bool)("addNewClassicEngine", true);

	auto drawCountOfUseOfStart = Prop!(bool)("drawCountOfUseOfStart", true);
	auto drawContentTreeLine = Prop!(bool)("drawContentTreeLine", true);
	auto drawContentWarnings = Prop!(bool)("drawContentWarnings", true);
	auto commentBoxDistance = Prop!(int, true, true)("commentBoxDistance", 50);
	auto warningImageWidth = Prop!(int, true, true)("warningImageWidth", 200);
	auto warningImageColor = Prop!(CRGB, true)("warningImageColor", CRGB(255, 128, 128));

	auto doubleIO = Prop!(bool)("doubleIO", true);
	auto reconstruction = Prop!(bool)("reconstruction", true);
	auto openLastScenario = Prop!(bool)("openLastScenario", true);
	auto imageCache = Prop!(bool)("imageCache", true);

	auto savedSound = Prop!(string)("savedSound", "");

	auto connContentTools = Prop!(bool)("connContentTools", true);

	auto previewAlpha = Prop!(int, true)("previewAlpha", 255);
	auto previewMaxWidth = Prop!(int, true, true)("previewMaxWidth", 150);
	auto previewMaxHeight = Prop!(int, true, true)("previewMaxHeight", 150);

	auto undoMaxMainView = Prop!(int)("undoMaxMainView", 1024);
	auto undoMaxEvent = Prop!(int)("undoMaxEvent", 1024);
	auto undoMaxEtc = Prop!(int)("undoMaxEtc", 1024);
	auto undoMaxLimit = Prop!(int)("undoMaxLimit", short.max);
	auto undoMaxReplace = Prop!(int)("undoMaxReplace", 16);

	auto dialogStatus = Prop!(int)("dialogStatus", DialogStatus.Top);

	auto showInputGuide = Prop!(bool)("showInputGuide", true);

	auto showSummaryPreview = Prop!(bool)("showSummaryPreview", true);

	auto floatMessagePreview = Prop!(bool)("floatMessagePreview", false);
	auto showDialogPreview = Prop!(bool)("showDialogPreview", true);
	auto showMessagePreview = Prop!(bool)("showMessagePreview", true);
	auto messageVarKindColumn = Prop!(int, false, true)("messageVarKindColumn", 200);
	auto messageVarValueColumn = Prop!(int, false, true)("messageVarValueColumn", 250);
	auto textVarKindColumn = Prop!(int, false, true)("textVarKindColumn", 160);
	auto textVarValueColumn = Prop!(int, false, true)("textVarValueColumn", 180);
	auto messageVarTableHeight = Prop!(int, true, true)("messageVarTableHeight", 300);
	auto messageVarSelected = Prop!(string)("messageVarSelected", "[選択中----14]");
	auto messageVarUnselected = Prop!(string)("messageVarUnselected", "[選択外----14]");
	auto messageVarRandom = Prop!(string)("messageVarRandom", "[ランダム--14]");
	auto messageVarCard = Prop!(string)("messageVarCard", "[カード--12]");
	auto messageVarRef = Prop!(string)("messageVarRef", "[話者------14]");
	auto messageVarTeam = Prop!(string)("messageVarTeam", "[チーム名------------------30]");
	auto messageVarYado = Prop!(string)("messageVarYado", "[宿屋名--------18]");
	auto showVariableValuesInEventText = Prop!(bool)("showVariableValuesInEventText", false);

	auto scenarioTemplates = Prop!(ScTemplate[])("scenarioTemplates", []);
	auto defaultScenarioTemplate = Prop!(string)("defaultScenarioTemplate", "");
	auto defaultIsTemplate = Prop!(bool)("defaultIsTemplate", false);
	auto createScenarioDir = Prop!(bool)("createScenarioDir", true);

	auto eventTemplates = Prop!(EvTemplate[])("eventTemplates", []);
	auto scriptVarTableHeight = Prop!(int, true, true)("scriptVarTableHeight", 300);

	auto archivePath = Prop!(string)("archivePath", "");

	auto mainToolBar = Prop!(ToolBarSettings)("mainToolBar", ToolBarSettings([
		[
			Tool(MenuID.New),
			Tool(MenuID.Open),
			Tool(MenuID.Save),
		],
		[
			Tool(MenuID.Undo),
			Tool(MenuID.Redo),
		],
		[
			Tool(MenuID.Cut),
			Tool(MenuID.Copy),
			Tool(MenuID.Paste),
		],
		[
			Tool(MenuID.Up),
			Tool(MenuID.Down),
		],
		[
			Tool(MenuID.Find),
		],
		[
			Tool(MenuID.NewAreaDir),
			Tool(MenuID.NewArea),
			Tool(MenuID.NewBattle),
			Tool(MenuID.NewPackage),
			Tool(),
			Tool(MenuID.NewFlagDir),
			Tool(MenuID.NewFlag),
			Tool(MenuID.NewStep),
		],
		[
			Tool(MenuID.ShowCardProp),
			Tool(MenuID.ShowCardDetail),
			Tool(),
			Tool(MenuID.NewCast),
			Tool(MenuID.NewSkill),
			Tool(MenuID.NewItem),
			Tool(MenuID.NewBeast),
			Tool(MenuID.NewInfo),
		],
		[
			Tool(MenuID.OpenDir),
		],
		[
			Tool(MenuID.ExecEngine),
			Tool(MenuID.ExecEngineWithParty),
			Tool(),
			Tool(MenuID.OpenImportSource),
			Tool(),
			Tool(MenuID.Settings),
		],
	]));

	/// 不使用。設定引き継ぎのために残してある
	auto gentleAngleEventTree = Prop!(bool)("gentleAngleEventTree", false, true);

	mixin XMLFuncs!(FlexEtcProps);
}
