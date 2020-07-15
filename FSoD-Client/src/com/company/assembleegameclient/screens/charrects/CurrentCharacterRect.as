﻿package com.company.assembleegameclient.screens.charrects {
import com.company.assembleegameclient.appengine.CharacterStats;
import com.company.assembleegameclient.appengine.SavedCharacter;
import com.company.assembleegameclient.screens.events.DeleteCharacterEvent;
import com.company.assembleegameclient.ui.tooltip.MyPlayerToolTip;
import com.company.assembleegameclient.util.FameUtil;
import com.company.rotmg.graphics.DeleteXGraphic;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

import kabam.rotmg.classes.model.CharacterClass;
import kabam.rotmg.text.model.TextKey;
import kabam.rotmg.text.view.stringBuilder.LineBuilder;

import org.osflash.signals.Signal;

public class CurrentCharacterRect extends CharacterRect {

    private static var toolTip_:MyPlayerToolTip = null;

    public const selected:Signal = new Signal();
    public const deleteCharacter:Signal = new Signal();
    public const showToolTip:Signal = new Signal(Sprite);
    public const hideTooltip:Signal = new Signal();

    public var charName:String;
    public var charStats:CharacterStats;
    public var char:SavedCharacter;
    public var myPlayerToolTipFactory:MyPlayerToolTipFactory;
    private var charType:CharacterClass;
    private var deleteButton:Sprite;
    private var icon:DisplayObject;

    public function CurrentCharacterRect(_arg_1:String, _arg_2:CharacterClass, _arg_3:SavedCharacter, _arg_4:CharacterStats) {
        this.myPlayerToolTipFactory = new MyPlayerToolTipFactory();
        super();
        this.charName = _arg_1;
        this.charType = _arg_2;
        this.char = _arg_3;
        this.charStats = _arg_4;
        var _local_5:String = _arg_2.name;
        var _local_6:int = _arg_3.charXML_.Level;
        super.className = new LineBuilder().setParams(TextKey.CURRENT_CHARACTER_DESCRIPTION, {
            "className": _local_5,
            "level": _local_6
        });
        super.color = 0x5C5C5C;
        super.overColor = 0x7F7F7F;
        super.init();
        this.makeTagline();
        this.makeDeleteButton();
        this.addEventListeners();
    }

    private function addEventListeners():void {
        addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
        selectContainer.addEventListener(MouseEvent.CLICK, this.onSelect);
        this.deleteButton.addEventListener(MouseEvent.CLICK, this.onDelete);
    }

    private function onSelect(_arg_1:MouseEvent):void {
        this.selected.dispatch(this.char);
    }

    private function onDelete(_arg_1:MouseEvent):void {
        this.deleteCharacter.dispatch(this.char);
    }

    public function setIcon(_arg_1:DisplayObject):void {
        ((this.icon) && (selectContainer.removeChild(this.icon)));
        this.icon = _arg_1;
        this.icon.x = CharacterRectConstants.ICON_POS_X;
        this.icon.y = CharacterRectConstants.ICON_POS_Y;
        ((this.icon) && (selectContainer.addChild(this.icon)));
    }

    private function makeTagline():void {
        if (this.getNextStarFame() > 0) {
            super.makeTaglineIcon();
            super.makeTaglineText(new LineBuilder().setParams(TextKey.CURRENT_CHARACTER_TAGLINE, {
                "fame": this.char.fame(),
                "nextStarFame": this.getNextStarFame()
            }));
            taglineText.x = (taglineText.x + taglineIcon.width);
        }
    }

    private function getNextStarFame():int {
        return (FameUtil.nextStarFame((((this.charStats == null)) ? 0 : this.charStats.bestFame()), this.char.fame()));
    }

    private function makeDeleteButton():void {
        this.deleteButton = new DeleteXGraphic();
        this.deleteButton.addEventListener(MouseEvent.MOUSE_DOWN, this.onDeleteDown);
        this.deleteButton.x = (WIDTH - 40);
        this.deleteButton.y = ((HEIGHT - this.deleteButton.height) * 0.5);
        addChild(this.deleteButton);
    }

    override protected function onMouseOver(_arg_1:MouseEvent):void {
        super.onMouseOver(_arg_1);
        this.removeToolTip();
        toolTip_ = this.myPlayerToolTipFactory.create(this.charName, this.char.charXML_, this.charStats);
        toolTip_.createUI();
        this.showToolTip.dispatch(toolTip_);
    }

    override protected function onRollOut(_arg_1:MouseEvent):void {
        super.onRollOut(_arg_1);
        this.removeToolTip();
    }

    private function onRemovedFromStage(_arg_1:Event):void {
        this.removeToolTip();
    }

    private function removeToolTip():void {
        this.hideTooltip.dispatch();
    }

    private function onDeleteDown(_arg_1:MouseEvent):void {
        _arg_1.stopImmediatePropagation();
        dispatchEvent(new DeleteCharacterEvent(this.char));
    }


}
}//package com.company.assembleegameclient.screens.charrects
