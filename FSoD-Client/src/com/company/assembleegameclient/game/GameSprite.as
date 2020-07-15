﻿package com.company.assembleegameclient.game {
import com.company.assembleegameclient.game.events.MoneyChangedEvent;
import com.company.assembleegameclient.map.Map;
import com.company.assembleegameclient.objects.GameObject;
import com.company.assembleegameclient.objects.IInteractiveObject;
import com.company.assembleegameclient.objects.Pet;
import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.objects.Projectile;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.tutorial.Tutorial;
import com.company.assembleegameclient.ui.GuildText;
import com.company.assembleegameclient.ui.RankText;
import com.company.assembleegameclient.ui.menu.PlayerMenu;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.util.CachingColorTransformer;
import com.company.util.MoreColorUtil;
import com.company.util.MoreObjectUtil;
import com.company.util.PointUtil;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.ColorMatrixFilter;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import kabam.lib.loopedprocs.LoopedCallback;
import kabam.lib.loopedprocs.LoopedProcess;
import kabam.rotmg.account.core.Account;
import kabam.rotmg.appengine.api.AppEngineClient;
import kabam.rotmg.arena.view.ArenaTimer;
import kabam.rotmg.arena.view.ArenaWaveCounter;
import kabam.rotmg.chat.view.Chat;
import kabam.rotmg.constants.GeneralConstants;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.core.model.MapModel;
import kabam.rotmg.core.model.PlayerModel;
import kabam.rotmg.game.view.CreditDisplay;
import kabam.rotmg.game.view.GiftStatusDisplay;
import kabam.rotmg.game.view.NewsModalButton;
import kabam.rotmg.maploading.signals.HideMapLoadingSignal;
import kabam.rotmg.maploading.signals.MapLoadedSignal;
import kabam.rotmg.messaging.impl.GameServerConnectionConcrete;
import kabam.rotmg.messaging.impl.incoming.MapInfo;
import kabam.rotmg.news.model.NewsModel;
import kabam.rotmg.news.view.NewsTicker;
import kabam.rotmg.packages.services.PackageModel;
import kabam.rotmg.packages.view.PackageButton;
import kabam.rotmg.promotions.model.BeginnersPackageModel;
import kabam.rotmg.promotions.signals.ShowBeginnersPackageSignal;
import kabam.rotmg.promotions.view.BeginnersPackageButton;
import kabam.rotmg.protip.signals.ShowProTipSignal;
import kabam.rotmg.questrewards.view.QuestRewardsPanel;
import kabam.rotmg.servers.api.Server;
import kabam.rotmg.stage3D.Renderer;
import kabam.rotmg.ui.UIUtils;
import kabam.rotmg.ui.view.HUDView;

import org.osflash.signals.Signal;

public class GameSprite extends AGameSprite {

    protected static const PAUSED_FILTER:ColorMatrixFilter = new ColorMatrixFilter(MoreColorUtil.greyscaleFilterMatrix);

    public const monitor:Signal = new Signal(String, int);
    public const modelInitialized:Signal = new Signal();
    public const drawCharacterWindow:Signal = new Signal(Player);

    public var chatBox_:Chat;
    public var isNexus_:Boolean = false;
    public var idleWatcher_:IdleWatcher;
    public var rankText_:RankText;
    public var guildText_:GuildText;
    public var creditDisplay_:CreditDisplay;
    public var giftStatusDisplay:GiftStatusDisplay;
    public var newsModalButton:NewsModalButton;
    public var newsTicker:NewsTicker;
    public var arenaTimer:ArenaTimer;
    public var arenaWaveCounter:ArenaWaveCounter;
    public var mapModel:MapModel;
    public var beginnersPackageModel:BeginnersPackageModel;
    public var showBeginnersPackage:ShowBeginnersPackageSignal;
    public var showPackage:Signal;
    public var packageModel:PackageModel;
    private var focus:GameObject;
    private var frameTimeSum_:int = 0;
    private var frameTimeCount_:int = 0;
    private var isGameStarted:Boolean;
    private var displaysPosY:uint = 4;
    private var currentPackage:DisplayObject;
    private var packageY:Number;
    public var chatPlayerMenu:PlayerMenu;

    public function GameSprite(_arg_1:Server, _arg_2:int, _arg_3:Boolean, _arg_4:int, _arg_5:int, _arg_6:ByteArray, _arg_7:PlayerModel, _arg_8:String, _arg_9:Boolean) {
        this.showPackage = new Signal();
        this.currentPackage = new Sprite();
        super();
        this.model = _arg_7;
        map = new Map(this);
        addChild(map);
        gsc_ = new GameServerConnectionConcrete(this, _arg_1, _arg_2, _arg_3, _arg_4, _arg_5, _arg_6, _arg_8, _arg_9);
        mui_ = new MapUserInput(this);
        this.chatBox_ = new Chat();
        this.chatBox_.list.addEventListener(MouseEvent.MOUSE_DOWN, this.onChatDown);
        this.chatBox_.list.addEventListener(MouseEvent.MOUSE_UP, this.onChatUp);
        addChild(this.chatBox_);
        this.idleWatcher_ = new IdleWatcher();
    }

    public static function dispatchMapLoaded(_arg_1:MapInfo):void {
        var _local_2:MapLoadedSignal = StaticInjectorContext.getInjector().getInstance(MapLoadedSignal);
        ((_local_2) && (_local_2.dispatch(_arg_1)));
    }

    private static function hidePreloader():void {
        var _local_1:HideMapLoadingSignal = StaticInjectorContext.getInjector().getInstance(HideMapLoadingSignal);
        ((_local_1) && (_local_1.dispatch()));
    }


    public function onChatDown(_arg_1:MouseEvent):void {
        if (this.chatPlayerMenu != null) {
            this.removeChatPlayerMenu();
        }
        mui_.onMouseDown(_arg_1);
    }

    public function onChatUp(_arg_1:MouseEvent):void {
        mui_.onMouseUp(_arg_1);
    }

    override public function setFocus(_arg_1:GameObject):void {
        _arg_1 = ((_arg_1) || (map.player_));
        this.focus = _arg_1;
    }

    public function addChatPlayerMenu(_arg_1:Player, _arg_2:Number, _arg_3:Number, _arg_4:String = null, _arg_5:Boolean = false, _arg_6:Boolean = false):void {
        this.removeChatPlayerMenu();
        this.chatPlayerMenu = new PlayerMenu();
        if (_arg_4 == null) {
            this.chatPlayerMenu.init(this, _arg_1);
        }
        else {
            if (_arg_6) {
                this.chatPlayerMenu.initDifferentServer(this, _arg_4, _arg_5, _arg_6);
            }
            else {
                if ((((_arg_4.length > 0)) && ((((((_arg_4.charAt(0) == "#")) || ((_arg_4.charAt(0) == "*")))) || ((_arg_4.charAt(0) == "@")))))) {
                    return;
                }
                this.chatPlayerMenu.initDifferentServer(this, _arg_4, _arg_5);
            }
        }
        addChild(this.chatPlayerMenu);
        this.chatPlayerMenu.x = _arg_2;
        this.chatPlayerMenu.y = (_arg_3 - this.chatPlayerMenu.height);
    }

    public function removeChatPlayerMenu():void {
        if (((!((this.chatPlayerMenu == null))) && (!((this.chatPlayerMenu.parent == null))))) {
            removeChild(this.chatPlayerMenu);
            this.chatPlayerMenu = null;
        }
    }

    override public function applyMapInfo(_arg_1:MapInfo):void {
        map.setProps(_arg_1.width_, _arg_1.height_, _arg_1.name_, _arg_1.background_, _arg_1.allowPlayerTeleport_, _arg_1.showDisplays_);
        dispatchMapLoaded(_arg_1);
    }

    public function hudModelInitialized():void {
        hudView = new HUDView();
        hudView.x = 600;
        addChild(hudView);
    }

    override public function initialize():void {
        var _local_1:Account;
        var _local_4:ShowProTipSignal;
        map.initialize();
        this.modelInitialized.dispatch();
        if (this.evalIsNotInCombatMapArea()) {
            this.showSafeAreaDisplays();
        }
        if (map.name_ == "Arena") {
            this.showTimer();
            this.showWaveCounter();
        }
        _local_1 = StaticInjectorContext.getInjector().getInstance(Account);
        if (((this.packageModel.shouldSpam()) && ((map.name_ == Map.NEXUS)))) {
            if (this.beginnersPackageModel.isBeginnerAvailable()) {
                this.showBeginnersPackage.dispatch();
            }
            else {
                this.showPackage.dispatch();
            }
            this.packageModel.numSpammed++;
        }
        this.isNexus_ = (map.name_ == Map.NEXUS);
        if (((this.isNexus_) || ((map.name_ == Map.DAILY_QUEST_ROOM)))) {
            this.creditDisplay_ = new CreditDisplay(this, true, true);
        }
        else {
            this.creditDisplay_ = new CreditDisplay(this);
        }
        this.creditDisplay_.x = 594;
        this.creditDisplay_.y = 0;
        addChild(this.creditDisplay_);
        var _local_2:AppEngineClient = StaticInjectorContext.getInjector().getInstance(AppEngineClient);
        var _local_3:Object = {
            "game_net_user_id": _local_1.gameNetworkUserId(),
            "game_net": _local_1.gameNetwork(),
            "play_platform": _local_1.playPlatform()
        };
        MoreObjectUtil.addToObject(_local_3, _local_1.getCredentials());
        if (((((((!((map.name_ == "Kitchen"))) && (!((map.name_ == "Tutorial"))))) && (!((map.name_ == "Nexus Explanation"))))) && ((Parameters.data_.watchForTutorialExit == true)))) {
            Parameters.data_.watchForTutorialExit = false;
            _local_3["fteStepCompleted"] = 9900;
            _local_2.sendRequest("/log/logFteStep", _local_3);
        }
        if (map.name_ == "Kitchen") {
            _local_3["fteStepCompleted"] = 200;
            _local_2.sendRequest("/log/logFteStep", _local_3);
        }
        if (map.name_ == "Tutorial") {
            if (Parameters.data_.needsTutorial == true) {
                Parameters.data_.watchForTutorialExit = true;
                _local_3["fteStepCompleted"] = 100;
                _local_2.sendRequest("/log/logFteStep", _local_3);
            }
            this.startTutorial();
        }
        else {
            if (((((((((((((!((map.name_ == "Arena"))) && (!((map.name_ == "Kitchen"))))) && (!((map.name_ == "Nexus Explanation"))))) && (!((map.name_ == "Vault Explanation"))))) && (!((map.name_ == "Guild Explanation"))))) && (!(this.evalIsNotInCombatMapArea())))) && (Parameters.data_.showProtips))) {
                _local_4 = StaticInjectorContext.getInjector().getInstance(ShowProTipSignal);
                ((_local_4) && (_local_4.dispatch()));
            }
        }
        if (map.name_ == "Daily Quest Room") {
            QuestRewardsPanel.checkQuests();
        }
        Parameters.save();
        hidePreloader();
    }

    private function showSafeAreaDisplays():void {
        this.showRankText();
        this.showGuildText();
        this.setYAndPositionPackage();
        this.showGiftStatusDisplay();
        if (((((("production".toLowerCase() == "dev")) || (Player.isAdmin))) || (("production".toLowerCase() == "localhost")))) {
            this.showNewsUpdate();
        }
        this.showNewsTicker();
    }

    private function showTimer():void {
        this.arenaTimer = new ArenaTimer();
        this.arenaTimer.y = 5;
        addChild(this.arenaTimer);
    }

    private function showWaveCounter():void {
        this.arenaWaveCounter = new ArenaWaveCounter();
        this.arenaWaveCounter.y = 5;
        this.arenaWaveCounter.x = 5;
        addChild(this.arenaWaveCounter);
    }

    private function showNewsTicker():void {
        this.newsTicker = new NewsTicker();
        this.newsTicker.x = (300 - (this.newsTicker.width / 2));
        this.newsTicker.y = (5 + UIUtils.NOTIFICATION_SPACE);
        addChild(this.newsTicker);
    }

    private function showGiftStatusDisplay():void {
        this.giftStatusDisplay = new GiftStatusDisplay();
        this.giftStatusDisplay.x = 6;
        this.giftStatusDisplay.y = (this.displaysPosY + 2);
        this.displaysPosY = (this.displaysPosY + UIUtils.NOTIFICATION_SPACE);
        addChild(this.giftStatusDisplay);
    }

    private function showNewsUpdate(_arg_1:Boolean = true):void {
        var _local_3:NewsModalButton;
        var _local_2:NewsModel = StaticInjectorContext.getInjector().getInstance(NewsModel);
        if (_local_2.hasValidModalNews()) {
            _local_3 = new NewsModalButton();
            _local_3.x = 6;
            _local_3.y = 92;
            if (_arg_1) {
                this.displaysPosY = (this.displaysPosY + UIUtils.NOTIFICATION_SPACE);
            }
            if (this.newsModalButton != null) {
                removeChild(this.newsModalButton);
            }
            this.newsModalButton = _local_3;
            addChild(this.newsModalButton);
        }
    }

    public function refreshNewsUpdateButton():void {
        this.showNewsUpdate(false);
    }

    private function setYAndPositionPackage():void {
        this.packageY = (this.displaysPosY + 2);
        this.displaysPosY = (this.displaysPosY + UIUtils.NOTIFICATION_SPACE);
        this.positionPackage();
    }

    private function positionPackage():void {
        this.currentPackage.x = 6;
        this.currentPackage.y = this.packageY;
    }

    public function showBeginnersButtonIfSafe():void {
        if (this.evalIsNotInCombatMapArea()) {
            this.addAndPositionPackage(new BeginnersPackageButton());
        }
    }

    public function showPackageButtonIfSafe():void {
        if (this.evalIsNotInCombatMapArea()) {
            this.addAndPositionPackage(new PackageButton());
        }
    }

    private function addAndPositionPackage(_arg_1:DisplayObject):void {
        this.currentPackage = _arg_1;
        addChild(this.currentPackage);
        this.positionPackage();
    }

    private function showGuildText():void {
        this.guildText_ = new GuildText("", -1);
        this.guildText_.x = 64;
        this.guildText_.y = 6;
        addChild(this.guildText_);
    }

    private function showRankText():void {
        this.rankText_ = new RankText(-1, true, false);
        this.rankText_.x = 8;
        this.rankText_.y = this.displaysPosY;
        this.displaysPosY = (this.displaysPosY + UIUtils.NOTIFICATION_SPACE);
        addChild(this.rankText_);
    }

    private function startTutorial():void {
        tutorial_ = new Tutorial(this);
        addChild(tutorial_);
    }

    private function updateNearestInteractive():void {
        var _local_4:Number;
        var _local_7:GameObject;
        var _local_8:IInteractiveObject;
        if (((!(map)) || (!(map.player_)))) {
            return;
        }
        var _local_1:Player = map.player_;
        var _local_2:Number = GeneralConstants.MAXIMUM_INTERACTION_DISTANCE;
        var _local_3:IInteractiveObject;
        var _local_5:Number = _local_1.x_;
        var _local_6:Number = _local_1.y_;
        for each (_local_7 in map.goDict_) {
            _local_8 = (_local_7 as IInteractiveObject);
            if (((_local_8) && (((!((_local_8 is Pet))) || (this.map.isPetYard))))) {
                if ((((Math.abs((_local_5 - _local_7.x_)) < GeneralConstants.MAXIMUM_INTERACTION_DISTANCE)) || ((Math.abs((_local_6 - _local_7.y_)) < GeneralConstants.MAXIMUM_INTERACTION_DISTANCE)))) {
                    _local_4 = PointUtil.distanceXY(_local_7.x_, _local_7.y_, _local_5, _local_6);
                    if ((((_local_4 < GeneralConstants.MAXIMUM_INTERACTION_DISTANCE)) && ((_local_4 < _local_2)))) {
                        _local_2 = _local_4;
                        _local_3 = _local_8;
                    }
                }
            }
        }
        this.mapModel.currentInteractiveTarget = _local_3;
    }

    private function isPetMap():Boolean {
        return (true);
    }

    public function connect():void {
        if (!this.isGameStarted) {
            this.isGameStarted = true;
            Renderer.inGame = true;
            gsc_.connect();
            this.idleWatcher_.start(this);
            lastUpdate_ = getTimer();
            stage.addEventListener(MoneyChangedEvent.MONEY_CHANGED, this.onMoneyChanged);
            stage.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
            LoopedProcess.addProcess(new LoopedCallback(100, this.updateNearestInteractive));
        }
    }

    public function disconnect():void {
        if (this.isGameStarted) {
            this.isGameStarted = false;
            Renderer.inGame = false;
            this.idleWatcher_.stop();
            stage.removeEventListener(MoneyChangedEvent.MONEY_CHANGED, this.onMoneyChanged);
            stage.removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
            LoopedProcess.destroyAll();
            ((contains(map)) && (removeChild(map)));
            map.dispose();
            CachingColorTransformer.clear();
            TextureRedrawer.clearCache();
            Projectile.dispose();
            gsc_.disconnect();
        }
    }

    private function onMoneyChanged(_arg_1:Event):void {
        gsc_.checkCredits();
    }

    override public function evalIsNotInCombatMapArea():Boolean {
        return ((((((((((((map.name_ == Map.NEXUS)) || ((map.name_ == Map.VAULT)))) || ((map.name_ == Map.GUILD_HALL)))) || ((map.name_ == Map.CLOTH_BAZAAR)))) || ((map.name_ == Map.NEXUS_EXPLANATION)))) || ((map.name_ == Map.DAILY_QUEST_ROOM))));
    }

    private function onEnterFrame(_arg_1:Event):void {
        var _local_7:Number;
        var _local_2:int = getTimer();
        var _local_3:int = (_local_2 - lastUpdate_);
        if (this.idleWatcher_.update(_local_3)) {
            closed.dispatch();
            return;
        }
        LoopedProcess.runProcesses(_local_2);
        this.frameTimeSum_ = (this.frameTimeSum_ + _local_3);
        this.frameTimeCount_ = (this.frameTimeCount_ + 1);
        if (this.frameTimeSum_ > 300000) {
            _local_7 = int(Math.round(((1000 * this.frameTimeCount_) / this.frameTimeSum_)));
            this.frameTimeCount_ = 0;
            this.frameTimeSum_ = 0;
        }
        var _local_4:int = getTimer();
        map.update(_local_2, _local_3);
        this.monitor.dispatch("Map.update", (getTimer() - _local_4));
        camera_.update(_local_3);
        var _local_5:Player = map.player_;
        if (this.focus) {
            camera_.configureCamera(this.focus, ((_local_5) ? _local_5.isHallucinating() : false));
            map.draw(camera_, _local_2);
        }
        if (_local_5 != null) {
            this.creditDisplay_.draw(_local_5.credits_, _local_5.fame_, _local_5.tokens_);
            this.drawCharacterWindow.dispatch(_local_5);
            if (this.evalIsNotInCombatMapArea()) {
                this.rankText_.draw(_local_5.numStars_);
                this.guildText_.draw(_local_5.guildName_, _local_5.guildRank_);
            }
            if (_local_5.isPaused()) {
                map.filters = [PAUSED_FILTER];
                hudView.filters = [PAUSED_FILTER];
                map.mouseEnabled = false;
                map.mouseChildren = false;
                hudView.mouseEnabled = false;
                hudView.mouseChildren = false;
            }
            else {
                if (map.filters.length > 0) {
                    map.filters = [];
                    hudView.filters = [];
                    map.mouseEnabled = true;
                    map.mouseChildren = true;
                    hudView.mouseEnabled = true;
                    hudView.mouseChildren = true;
                }
            }
            moveRecords_.addRecord(_local_2, _local_5.x_, _local_5.y_);
        }
        lastUpdate_ = _local_2;
        var _local_6:int = (getTimer() - _local_2);
        this.monitor.dispatch("GameSprite.loop", _local_6);
    }

    public function showPetToolTip(_arg_1:Boolean):void {
    }


}
}//package com.company.assembleegameclient.game
