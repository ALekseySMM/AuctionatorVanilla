
local AuctionatorVersion = "1.0.0-Vanilla";
local AuctionatorAuthor  = "Zirco; Vanilla adaptation by Nimeral";


local AuctionatorLoaded = false;

local recommendElements		= {};
local auctionsTabElements	= {};

AUCTIONATOR_ENABLE_ALT	= 1;
AUCTIONATOR_OPEN_FIRST	= 0;

local AUCTIONATOR_TAB_INDEX = 4;

-----------------------------------------

local auctionator_orig_AuctionFrameTab_OnClick;
local auctionator_orig_ContainerFrameItemButton_OnClick;
local auctionator_orig_AuctionFrameAuctions_Update;
local auctionator_orig_AuctionsCreateAuctionButton_OnClick;

local KM_NULL_STATE	= 0;
local KM_PREQUERY	= 1;
local KM_INQUERY	= 2;
local KM_POSTQUERY	= 3;
local KM_ANALYZING	= 4;

local processing_state	= KM_NULL_STATE;
local current_page;
local forceMsgAreaUpdate = false;

local scandata;
local sorteddata = {};
local basedata;

local currentAuctionItemName = "";
local currentAuctionStackSize = 1;
local currentAuctionTexture = nil;

local currentAuctionClass;
local currentAuctionSubclass;

local auctionator_last_buyoutprice = 1;
local auctionator_last_item_posted = nil;
local auctionator_pending_message = nil;

-----------------------------------------

local	BoolToString, BoolToNum, NumToBool, pluralizeIf, round, chatmsg, calcNewPrice, roundPriceDown;
local	val2gsc, priceToString, ItemType2AuctionClass, SubType2AuctionSubclass;

-----------------------------------------


function Auctionator_EventHandler()

--	chatmsg (event);

    if (event == "VARIABLES_LOADED")			then	Auctionator_OnLoad(); 					end; 
    if (event == "ADDON_LOADED")				then	Auctionator_OnAddonLoaded(); 			end; 
    if (event == "AUCTION_ITEM_LIST_UPDATE")	then	Auctionator_OnAuctionUpdate(); 			end; 
    if (event == "AUCTION_OWNED_LIST_UPDATE")	then	Auctionator_OnAuctionOwnedUpdate(); 	end; 
    if (event == "AUCTION_HOUSE_SHOW")			then	Auctionator_OnAuctionHouseShow(); 		end; 
    if (event == "AUCTION_HOUSE_CLOSED")		then	Auctionator_OnAuctionHouseClosed(); 	end; 
    if (event == "NEW_AUCTION_UPDATE")			then	Auctionator_OnNewAuctionUpdate(); 		end; 

end

-----------------------------------------


function Auctionator_OnLoad()

    chatmsg("Auctionator Loaded");

    AuctionatorLoaded = true;

end

-----------------------------------------

function Auctionator_OnAddonLoaded()

    if (string.lower (arg1) == "blizzard_auctionui") then			
        Auctionator_AddSellTab ();
        Auctionator_AddSellPanel ();
        
        Auctionator_SetupHookFunctions ();
        
        auctionsTabElements[1]  = AuctionsScrollFrame;
        auctionsTabElements[2]  = AuctionsButton1;
        auctionsTabElements[3]  = AuctionsButton2;
        auctionsTabElements[4]  = AuctionsButton3;
        auctionsTabElements[5]  = AuctionsButton4;
        auctionsTabElements[6]  = AuctionsButton5;
        auctionsTabElements[7]  = AuctionsButton6;
        auctionsTabElements[8]  = AuctionsButton7;
        auctionsTabElements[9]  = AuctionsButton8;
        auctionsTabElements[10] = AuctionsButton9;
        auctionsTabElements[11] = AuctionsQualitySort;
        auctionsTabElements[12] = AuctionsDurationSort;
        auctionsTabElements[13] = AuctionsHighBidderSort;
        auctionsTabElements[14] = AuctionsBidSort;
        auctionsTabElements[15] = AuctionsCancelAuctionButton;
        --auctionsTabElements[16] = AuctionFrameAuctions;
        --auctionsTabElements[16] = AuctionFrame;

        recommendElements[1] = getglobal ("Auctionator_Recommend_Text");
        recommendElements[2] = getglobal ("Auctionator_RecommendPerItem_Text");
        recommendElements[3] = getglobal ("Auctionator_RecommendPerItem_Price");
        recommendElements[4] = getglobal ("Auctionator_RecommendPerStack_Text");
        recommendElements[5] = getglobal ("Auctionator_RecommendPerStack_Price");
        recommendElements[6] = getglobal ("Auctionator_Recommend_Basis_Text");
        recommendElements[7] = getglobal ("Auctionator_RecommendItem_Tex");
    end
end


-----------------------------------------


function Auctionator_AuctionFrameTab_OnClick (index)

    if ( not index ) then
        index = this:GetID();
    end

    getglobal("Auctionator_Sell_Template"):Hide();
    
        if (index == 3) then		
        Auctionator_ShowElems (auctionsTabElements);
    end
    
    if (index ~= AUCTIONATOR_TAB_INDEX) then
        auctionator_orig_AuctionFrameTab_OnClick (index);
        auctionator_last_item_posted = nil;
        forceMsgAreaUpdate = true;
        
    elseif (index == AUCTIONATOR_TAB_INDEX) then
        AuctionFrameTab_OnClick(3);
        
        
        PanelTemplates_SetTab(AuctionFrame, AUCTIONATOR_TAB_INDEX);
        
        Auctionator_HideElems (auctionsTabElements);
        
        Auctionator_HideElems (recommendElements);
        
        getglobal("Auctionator_Sell_Template"):Show();
        Auctionator_UseBidArt();
        Auctionator_FitButtonsSafe();
        AuctionFrame:EnableMouse(false);
        
        OpenAllBags(true);
        
        if (currentAuctionItemName ~= "") then
            Auctionator_CalcBaseData();
        end
    
    end

end

-----------------------------------------


function Auctionator_ContainerFrameItemButton_OnModifiedClick (button)
    
    if (	AUCTIONATOR_ENABLE_ALT == 0
        or  not	AuctionFrame:IsShown()
        or	not	IsAltKeyDown())
    then
        return auctionator_orig_ContainerFrameItemButton_OnModifiedClick (button);
    end;

    if (PanelTemplates_GetSelectedTab (AuctionFrame) ~= AUCTIONATOR_TAB_INDEX) then
    
        AuctionFrameTab_OnClick (AUCTIONATOR_TAB_INDEX);
    
    end
    
    
    PickupContainerItem(this:GetParent():GetID(), this:GetID());

    local infoType = GetCursorInfo()

    if (infoType == "item") then
        ClickAuctionSellItemButton();
        ClearCursor();
    end

end


-----------------------------------------

function Auctionator_AuctionFrameAuctions_Update()
    
    auctionator_orig_AuctionFrameAuctions_Update();

    if (PanelTemplates_GetSelectedTab (AuctionFrame) == AUCTIONATOR_TAB_INDEX  and	AuctionFrame:IsShown()) then
        Auctionator_HideElems (auctionsTabElements);
    end

    
end

-----------------------------------------
-- Intercept the Create Auction click so
-- that we can note the auction values
-----------------------------------------

function Auctionator_AuctionsCreateAuctionButton_OnClick()
    
    if (PanelTemplates_GetSelectedTab (AuctionFrame) == AUCTIONATOR_TAB_INDEX  and AuctionFrame:IsShown()) then
        
        auctionator_last_buyoutprice = MoneyInputFrame_GetCopper(BuyoutPrice);
        auctionator_last_item_posted = currentAuctionItemName;

    end
    
    auctionator_orig_AuctionsCreateAuctionButton_OnClick();

end

-----------------------------------------

function Auctionator_OnAuctionOwnedUpdate ()

    if (auctionator_last_item_posted) then
    
        Auctionator_Recommend_Text:SetText ("Auction Created for "..auctionator_last_item_posted);

        MoneyFrame_Update ("Auctionator_RecommendPerStack_Price", auctionator_last_buyoutprice);

        Auctionator_RecommendPerStack_Price:Show();
        Auctionator_RecommendPerItem_Price:Hide();
        Auctionator_RecommendPerItem_Text:Hide();
        Auctionator_Recommend_Basis_Text:Hide();
    end
    
end

-----------------------------------------

function Auctionator_OnNewAuctionUpdate()


end

-----------------------------------------
-- Multi-post: split the item in the Auction Item slot into
-- several stacks of a given size and post them one by one.
-- Runs as a small state machine driven from OnUpdate because
-- every step has to wait for the server.
--
--   release -> next -> placed -> posting -> next -> ... -> done
-----------------------------------------

local multi = nil;			-- nil when idle, otherwise the state of the running batch

local MULTI_STEP_DELAY	= 0.3;	-- seconds between steps
local MULTI_TIMEOUT		= 8;	-- seconds to wait for the server before giving up

-----------------------------------------
-- Scans the bags for 'name'.
-- Returns: number of stacks of 'size' that can be made,
--          bag, slot, count of the best unlocked source slot (nil if none),
--          and whether a suitable slot exists but is still locked.
-----------------------------------------

function Auctionator_MultiPost_FindItems (name, size)

    local possible	= 0;
    local pending	= false;
    local bestBag, bestSlot, bestCount;
    local bag, slot;

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots (bag) do

            local link = GetContainerItemLink (bag, slot);

            if (link) then
                local _, _, linkName = string.find (link, "%[(.+)%]");

                if (linkName == name) then
                    local texture, itemCount, locked = GetContainerItemInfo (bag, slot);

                    if (itemCount and itemCount >= size) then
                        possible = possible + math.floor (itemCount / size);

                        if (locked) then
                            pending = true;
                        elseif (bestCount == nil or itemCount < bestCount) then
                            bestBag, bestSlot, bestCount = bag, slot, itemCount;
                        end
                    end
                end
            end
        end
    end

    return possible, bestBag, bestSlot, bestCount, pending;
end

-----------------------------------------

function Auctionator_MultiPost_FindEmptySlot ()

    local bag, slot;

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots (bag) do
            if (GetContainerItemLink (bag, slot) == nil) then
                return bag, slot;
            end
        end
    end
end

-----------------------------------------
-- The Post and Setup buttons get the size of the default Close button, so that
-- they sit over the button slots drawn into the bottom art of the default frame.
-----------------------------------------

function Auctionator_FitButtons ()

    -- AuctionFrameCloseButton is the X in the title bar; the bottom Close button belongs to each tab

    local close = getglobal ("AuctionsCloseButton") or getglobal ("BidCloseButton") or getglobal ("BrowseCloseButton");

    if (close == nil) then
        return;
    end

    local w, h = close:GetWidth(), close:GetHeight();

    if (w and h and w > 0 and h > 0) then
        Auctionator1Button:SetWidth (w);
        Auctionator1Button:SetHeight (h);
        AuctionatorMultiPostButton:SetWidth (w);
        AuctionatorMultiPostButton:SetHeight (h);
    end

    -- [Post] [Setup] [Close] in a row, like [Bid] [Buyout] [Close] on the Bid tab

    Auctionator1Button:ClearAllPoints();
    Auctionator1Button:SetPoint ("RIGHT", close, "LEFT", -6, 0);

    AuctionatorMultiPostButton:ClearAllPoints();
    AuctionatorMultiPostButton:SetPoint ("RIGHT", Auctionator1Button, "LEFT", -6, 0);
end

-- runs the layout; if it fails, puts the buttons back where the xml placed them

function Auctionator_FitButtonsSafe ()

    local ok, err = pcall (Auctionator_FitButtons);

    if (not ok) then
        chatmsg ("Auctionator: button layout failed: "..tostring(err));

        Auctionator1Button:ClearAllPoints();
        Auctionator1Button:SetPoint ("RIGHT", "Auctionator_Sell_Template", "RIGHT", -14, -163);

        AuctionatorMultiPostButton:ClearAllPoints();
        AuctionatorMultiPostButton:SetPoint ("RIGHT", "Auctionator1Button", "LEFT", -4, 0);
    end
end

-----------------------------------------
-- The bottom art of the default frame has a slot drawn in for every button of the
-- current tab (on the Auctions tab: the Cancel Auction button). The Bid tab has
-- two slots in a row, which fit Post and Setup, so borrow the Bid tab's bottom art.
-- The default tab switch writes the textures again, so nothing has to be undone.
-----------------------------------------

function Auctionator_UseBidArt ()

    local names = { "AuctionFrameBot", "AuctionFrameBotRight" };
    local i;

    for i = 1, 2 do
        local piece = getglobal (names[i]);

        if (piece and piece.GetTexture) then
            local path = piece:GetTexture();

            if (path) then
                local newPath, n = string.gsub (path, "%-Auction%-", "-Bid-");

                if (n > 0) then
                    piece:SetTexture (newPath);
                end
            end
        end
    end
end

-----------------------------------------

function Auctionator_MultiPost_Start ()

    if (multi) then
        chatmsg ("Auctionator: already posting, please wait.");
        return;
    end

    local name, texture, count = GetAuctionSellItemInfo();

    if (name == nil or name == "") then
        chatmsg ("Auctionator: put the item into the Auction Item slot first.");
        return;
    end

    if (CursorHasItem()) then
        chatmsg ("Auctionator: your cursor is holding something, put it down first.");
        return;
    end

    local size = tonumber (AuctionatorMultiSize:GetText());

    if (size == nil or size < 1) then
        chatmsg ("Auctionator: enter the stack size.");
        return;
    end

    local possible = Auctionator_MultiPost_FindItems (name, size);

    if (possible < 1) then
        chatmsg ("Auctionator: you have no stack of "..size.." x "..name.." in your bags.");
        return;
    end

    local stacks = tonumber (AuctionatorMultiCount:GetText());

    if (stacks == nil or stacks < 1) then
        stacks = possible;
    elseif (stacks > possible) then
        chatmsg ("Auctionator: only "..possible.." stack(s) of "..size.." can be made.");
        stacks = possible;
    end

    -- the prices currently entered are for ONE stack of 'size' items; turn them into per-item prices

    local now = GetTime();

    multi = {};
    multi.name			= name;
    multi.size			= size;
    multi.stacks		= stacks;
    multi.posted		= 0;
    multi.startPer		= MoneyInputFrame_GetCopper (StartPrice)  / size;
    multi.buyoutPer		= MoneyInputFrame_GetCopper (BuyoutPrice) / size;
    multi.state			= "release";
    multi.nextTime		= now + MULTI_STEP_DELAY;
    multi.deadline		= now + MULTI_TIMEOUT;

    -- take the whole stack out of the slot; it is put back into the bags
    -- in the "release" step once the slot has really emptied
    ClickAuctionSellItemButton();

end

-----------------------------------------

function Auctionator_MultiPost_Stop (reason, release)

    local m = multi;
    multi = nil;

    if (m == nil) then
        return;
    end

    if (release) then
        ClearCursor();
        ClickAuctionSellItemButton();
        ClearCursor();
    end

    if (reason) then
        chatmsg ("Auctionator: stopped, "..reason.." ("..m.posted.." of "..m.stacks.." stacks posted).");
    else
        chatmsg ("Auctionator: posted "..m.posted.." stack(s) of "..m.size.." x "..m.name..", "..tostring(m.priceText)..".");
    end

    forceMsgAreaUpdate = true;
end

-----------------------------------------

function Auctionator_MultiPost_Step ()

    local now = GetTime();

    if (now < multi.nextTime) then
        return;
    end

    if (now > multi.deadline) then
        local sName, sTex, sCount = GetAuctionSellItemInfo();
        local cursor = "no";
        if (CursorHasItem()) then cursor = "yes"; end

        chatmsg ("Auctionator debug: step="..multi.state.." slot="..tostring(sName).."/"..tostring(sCount).." cursor="..cursor);
        Auctionator_MultiPost_Stop ("timed out in step '"..multi.state.."'", true);
        return;
    end

    if (multi.state == "release") then

        if (GetAuctionSellItemInfo() ~= nil) then
            return;
        end

        ClearCursor();

        multi.state		= "next";
        multi.nextTime	= now + MULTI_STEP_DELAY;
        multi.deadline	= now + MULTI_TIMEOUT;

    elseif (multi.state == "next") then

        if (GetAuctionSellItemInfo() ~= nil or CursorHasItem()) then
            return;
        end

        local possible, bag, slot, itemCount, pending = Auctionator_MultiPost_FindItems (multi.name, multi.size);

        if (bag == nil) then
            if (not pending) then
                Auctionator_MultiPost_Stop ("not enough items left", true);
            end
            return;
        end

        if (itemCount > multi.size) then

            -- the auction slot always takes a whole bag stack, so first split
            -- the wanted amount off into an empty bag slot

            local eBag, eSlot = Auctionator_MultiPost_FindEmptySlot();

            if (eBag == nil) then
                Auctionator_MultiPost_Stop ("no free bag slot to split a stack into", true);
                return;
            end

            SplitContainerItem (bag, slot, multi.size);

            if (not CursorHasItem()) then
                return;
            end

            PickupContainerItem (eBag, eSlot);

            multi.splitBag		= eBag;
            multi.splitSlot		= eSlot;
            multi.state			= "splitting";
            multi.deadline		= now + MULTI_TIMEOUT;
            return;
        end

        PickupContainerItem (bag, slot);

        if (not CursorHasItem()) then
            return;
        end

        ClickAuctionSellItemButton();

        Auctionator_SetMessage ("Posting "..multi.name.."\n\nstack "..(multi.posted + 1).." of "..multi.stacks);

        multi.state		= "placed";
        multi.deadline	= now + MULTI_TIMEOUT;

    elseif (multi.state == "splitting") then

        local texture, itemCount, locked = GetContainerItemInfo (multi.splitBag, multi.splitSlot);

        if (itemCount == multi.size and not locked and not CursorHasItem()) then
            multi.state		= "next";
            multi.nextTime	= now + MULTI_STEP_DELAY;
            multi.deadline	= now + MULTI_TIMEOUT;
        end

    elseif (multi.state == "placed") then

        local sellName, sellTexture, sellCount = GetAuctionSellItemInfo();

        if (sellName ~= multi.name or sellCount ~= multi.size) then
            return;
        end

        local startPrice	= round (multi.startPer  * multi.size);
        local buyoutPrice	= round (multi.buyoutPer * multi.size);

        if (startPrice < 1) then
            startPrice = 1;
        end

        if (buyoutPrice > 0 and buyoutPrice < startPrice) then
            startPrice = buyoutPrice;
        end

        MoneyInputFrame_SetCopper (StartPrice,  startPrice);
        MoneyInputFrame_SetCopper (BuyoutPrice, buyoutPrice);

        local duration = AuctionFrameAuctions.duration;

        local startText		= priceToString (startPrice);
        local buyoutText	= "none";

        if (buyoutPrice > 0) then
            buyoutText = priceToString (buyoutPrice);
        end

        multi.priceText = "start "..startText..", buyout "..buyoutText.." per stack";

        if (duration) then
            StartAuction (startPrice, buyoutPrice, duration);
        else
            AuctionsCreateAuctionButton:Click();
        end

        multi.state		= "posting";
        multi.deadline	= now + MULTI_TIMEOUT;

    elseif (multi.state == "posting") then

        if (GetAuctionSellItemInfo() ~= nil) then
            return;
        end

        multi.posted = multi.posted + 1;

        if (multi.posted >= multi.stacks) then
            Auctionator_MultiPost_Stop (nil, false);
        else
            multi.state		= "next";
            multi.nextTime	= now + MULTI_STEP_DELAY;
            multi.deadline	= now + MULTI_TIMEOUT;
        end
    end
end

-----------------------------------------

function Auctionator_MultiPost_OnUpdate ()

    if (multi == nil) then
        return;
    end

    if (AuctionFrame == nil or not AuctionFrame:IsShown()) then
        Auctionator_MultiPost_Stop ("the auction house was closed", false);
        return;
    end

    local ok, err = pcall (Auctionator_MultiPost_Step);

    if (not ok) then
        Auctionator_MultiPost_Stop ("error: "..tostring(err), true);
    end
end

-----------------------------------------

function Auctionator_ShowTooltip_MultiPost()

    GameTooltip:SetOwner(this, "ANCHOR_TOP");
    GameTooltip:SetText("Post several stacks", 0.9, 1.0, 1.0);
    GameTooltip:AddLine("Put the item in the Auction Item slot. The Starting and Buyout prices are for ONE stack of 'Stack size' items. Auctionator splits the item into such stacks and posts them one by one. Leave 'Stacks' empty to post as many as possible.", 0.5, 0.5, 1.0, 1);
    GameTooltip:Show();

end

-----------------------------------------

function Auctionator_SetupHookFunctions ()
    
    auctionator_orig_AuctionFrameTab_OnClick = AuctionFrameTab_OnClick;
    AuctionFrameTab_OnClick = Auctionator_AuctionFrameTab_OnClick;
    
    auctionator_orig_ContainerFrameItemButton_OnModifiedClick = ContainerFrameItemButton_OnModifiedClick;
    ContainerFrameItemButton_OnModifiedClick = Auctionator_ContainerFrameItemButton_OnModifiedClick;
    
    auctionator_orig_AuctionFrameAuctions_Update = AuctionFrameAuctions_Update;
    AuctionFrameAuctions_Update = Auctionator_AuctionFrameAuctions_Update;
    
    auctionator_orig_AuctionsCreateAuctionButton_OnClick = AuctionsCreateAuctionButton_OnClick;
    AuctionsCreateAuctionButton_OnClick = Auctionator_AuctionsCreateAuctionButton_OnClick;
    
end

-----------------------------------------

function Auctionator_AddSellPanel ()
    
--	local frame = CreateFrame("Frame", "Auctionator_Sell_Panel", AuctionFrame, "Auctionator_Sell_Template");
    --frame:SetParent("AuctionFrame");
    --frame:SetPoint("TOPLEFT", "AuctionFrame", "TOPLEFT", 0, 0);
    --relevel(frame);
--	frame:Hide();
    
end

-----------------------------------------

function Auctionator_AddSellTab ()
        
    local n = AuctionFrame.numTabs+1;
    
    AUCTIONATOR_TAB_INDEX = n;

    local framename = "AuctionFrameTab"..n;

    local frame = CreateFrame("Button", framename, AuctionFrame, "AuctionTabTemplate");

    setglobal("AuctionFrameTab4", frame);
    frame:SetID(n);
    --frame:SetParent("FriendsFrameTabTemplate");
    frame:SetText("Auctionator");
    frame:SetPoint("LEFT", getglobal("AuctionFrameTab"..n-1), "RIGHT", -8, 0);
    frame:Show();

    --Attempting to index local 'frame' now
    
    -- Configure the tab button.
    --setglobal(AuctionFrameTab4, AuctionFrameTab4);
    
    --tabButton:SetPoint("TOPLEFT", getglobal("AuctionFrameTab"..(tabIndex - 1)):GetName(), "TOPRIGHT", -8, 0);
    --tabButton:SetID(tabIndex);
    
    PanelTemplates_SetNumTabs (AuctionFrame, n);
    PanelTemplates_EnableTab  (AuctionFrame, n);
end

-----------------------------------------

function Auctionator_HideElems (tt)

    if (not tt) then
        return;
    end
    
    for i,x in ipairs(tt) do
        x:Hide();
    end
end

-----------------------------------------

function Auctionator_ShowElems (tt)

    for i,x in ipairs(tt) do
        x:Show();
    end
end

-----------------------------------------

function Auctionator_OnAuctionUpdate ()

    if (processing_state ~= KM_POSTQUERY) then
        return;
    end
    
    if (PanelTemplates_GetSelectedTab (AuctionFrame) ~= AUCTIONATOR_TAB_INDEX) then
        return;
    end;
    
    processing_state = KM_ANALYZING;
    
    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");
    
    --chatmsg("auctions:"..numBatchAuctions.." out of  "..totalAuctions)

    if (totalAuctions >= 50) then
        Auctionator_SetMessage ("Scanning auctions: page "..current_page);
    end
    
    if (numBatchAuctions > 0) then
    
        local x;
        
        for x = 1, numBatchAuctions do
        
            local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", x);

            if (name == currentAuctionItemName and buyoutPrice > 0) then
            
                local sd = {};
                
                sd["stackSize"]		= count;
                sd["buyoutPrice"]	= buyoutPrice;
                sd["owner"]			= owner;
                
                tinsert (scandata, sd);
                
                
            end
        end
    end

    if (numBatchAuctions == 50) then
                
        processing_state = KM_PREQUERY;	
        
    else
    
        if (table.getn (scandata) > 0) then
            Auctionator_Process_Scandata ();
            Auctionator_CalcBaseData();
        else
            Auctionator_SetMessage ("No auctions were found for \n\n"..currentAuctionItemName);
        end
        
        processing_state = KM_NULL_STATE;

    end
    
    
    
end

-----------------------------------------

function Auctionator_SetMessage (msg)
    Auctionator_HideElems (recommendElements);
    Auctionator_HideElems (overallElements);

    AuctionatorMessage:SetText (msg);
    AuctionatorMessage:Show();
end

-----------------------------------------

function Auctionator_Process_Scandata ()

    sorteddata = {};
    
    if (scandata == nil) then
        return;
    end;
   
    ----- Condense the scan data into a table that has only a single entry per stacksize/price combo

    local i,sd;
    local conddata = {};

    for i,sd in ipairs (scandata) do
    
        local key = "_"..sd.stackSize.."_"..sd.buyoutPrice;
        
    
        if (conddata[key]) then
            conddata[key].count = conddata[key].count + 1;	
        else
            local data = {};
            
            data.stackSize 		= sd.stackSize;
            data.buyoutPrice	= sd.buyoutPrice;
            data.itemPrice		= sd.buyoutPrice / sd.stackSize;
            data.count			= 1;
            data.numYours		= 0;
            
            conddata[key] = data;
        end

        if (sd.owner == UnitName("player")) then
            conddata[key].numYours = conddata[key].numYours + 1;
        end
    
    end


    ----- create a table of these entries sorted by itemPrice


    local n = 1;
    for i,v in pairs (conddata) do
        sorteddata[n] = v;
        n = n + 1;
    end
    

    table.sort (sorteddata, function(a,b) return a.itemPrice < b.itemPrice; end);

end

-----------------------------------------

local bestPriceOurStackSize;

-----------------------------------------

function Auctionator_CalcBaseData ()

    local bestPrice		= {};		-- a table with one entry per stacksize that is the cheapest auction for that particular stacksize
    local absoluteBest;				-- the overall cheapest auction
    
    local j, sd;

    ----- find the best price per stacksize and overall -----
    
    for j,sd in ipairs(sorteddata) do
    
        if (bestPrice[sd.stackSize] == nil or bestPrice[sd.stackSize].itemPrice >= sd.itemPrice) then
            bestPrice[sd.stackSize] = sd;
        end
    
        if (absoluteBest == nil or absoluteBest.itemPrice > sd.itemPrice) then
            absoluteBest = sd;
        end
    
    end
    
    basedata = absoluteBest;

    if (bestPrice[currentAuctionStackSize]) then
        basedata				= bestPrice[currentAuctionStackSize];
        bestPriceOurStackSize	= bestPrice[currentAuctionStackSize];
    end

    
    Auctionator_UpdateRecommendation();
end

-----------------------------------------

function Auctionator_UpdateRecommendation ()

    --AuctionFrame:setTopLevel (false);
    if (basedata) then
        local newBuyoutPrice = basedata.itemPrice * currentAuctionStackSize;

        if (basedata.numYours < basedata.count) then
            newBuyoutPrice = calcNewPrice (newBuyoutPrice);
        end
        
        local newStartPrice = calcNewPrice(round(newBuyoutPrice *0.95)); 
        
        Auctionator_ShowElems (recommendElements);
        AuctionatorMessage:Hide();
        
        Auctionator_Recommend_Text:SetText ("Recommended Buyout Price");
        Auctionator_RecommendPerStack_Text:SetText ("for your stack of "..currentAuctionStackSize);
        
        if (currentAuctionTexture) then
            Auctionator_RecommendItem_Tex:SetNormalTexture (currentAuctionTexture);
            if (currentAuctionStackSize > 1) then
                Auctionator_RecommendItem_TexCount:SetText (currentAuctionStackSize);
                Auctionator_RecommendItem_TexCount:Show();
            else
                Auctionator_RecommendItem_TexCount:Hide();
            end
        else
            Auctionator_RecommendItem_Tex:Hide();
        end
        
        MoneyFrame_Update ("Auctionator_RecommendPerItem_Price",  round(newBuyoutPrice / currentAuctionStackSize));
        MoneyFrame_Update ("Auctionator_RecommendPerStack_Price", round(newBuyoutPrice));
        
        MoneyInputFrame_SetCopper (BuyoutPrice, newBuyoutPrice);
        MoneyInputFrame_SetCopper (StartPrice,  newStartPrice);

        Auctionator_ScrollbarUpdate();
        
        if (basedata.stackSize == sorteddata[1].stackSize and basedata.buyoutPrice == sorteddata[1].buyoutPrice) then
            Auctionator_Recommend_Basis_Text:SetText ("(based on cheapest)");
        elseif (bestPriceOurStackSize and basedata.stackSize == bestPriceOurStackSize.stackSize and basedata.buyoutPrice == bestPriceOurStackSize.buyoutPrice) then
            Auctionator_Recommend_Basis_Text:SetText ("(based on cheapest stack of the same size)");
        else
            Auctionator_Recommend_Basis_Text:SetText ("(based on auction selected below)");
        end
        
    end
end



-----------------------------------------

function Auctionator_OnAuctionHouseShow()

    if (AUCTIONATOR_OPEN_FIRST ~= 0) then
        AuctionFrameTab_OnClick (AUCTIONATOR_TAB_INDEX);
    end

end

-----------------------------------------

function Auctionator_OnAuctionHouseClosed()

    Auctionator_MultiPost_Stop ("the auction house was closed", false);

    AuctionatorOptionsFrame:Hide();
    AuctionatorDescriptionFrame:Hide();
    Auctionator_Sell_Template:Hide();
    
end



-----------------------------------------

function Auctionator_OnUpdate(self, elapsed)

    Auctionator_MultiPost_OnUpdate();
    Auctionator_Idle (self, elapsed);

end


-----------------------------------------

function Auctionator_Idle(self, elapsed) 
 
    if (self.TimeSinceLastUpdate == nil) then 
        self.TimeSinceLastUpdate = 0; 
    end; 
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + 0.1;--elapsed; 
     
    if (AuctionatorMessage == nil) then 
        return; 
    end; 
     
    if (self.NumIdles == nil) then 
        self.NumIdles = 0; 
    end; 
    self.NumIdles = self.NumIdles + 1;
    
    if (self.TimeSinceLastUpdate > 0.25) then
    
        self.TimeSinceLastUpdate = 0;

        ------- check whether to send a new auction query to get the next page -------

        if (processing_state == KM_PREQUERY) then
            if (CanSendAuctionQuery()) then
                processing_state = KM_IN_QUERY;
                QueryAuctionItems (currentAuctionItemName, "", "", nil, currentAuctionClass, currentAuctionSubclass, current_page, nil, nil);
                processing_state = KM_POSTQUERY;
                current_page = current_page + 1;
            end
        end
    end
    
    ------- don't rescan while a multi-post batch is swapping items in the slot -------

    if (multi) then
        return;
    end

    ------- check whether the "sell" item has changed -------

    local auctionItemName, auctionTexture, auctionCount = GetAuctionSellItemInfo(); 

    if (auctionItemName == nil) then
        auctionItemName = "";
        auctionCount	= 0;
    end

    if (currentAuctionItemName ~= auctionItemName or currentAuctionStackSize ~= auctionCount or self.NumIdles == 1 or forceMsgAreaUpdate) then
    
        forceMsgAreaUpdate = false;
        
        sorteddata = {};
        Auctionator_ScrollbarUpdate();

        currentAuctionItemName  = auctionItemName;
        currentAuctionStackSize = auctionCount;
        currentAuctionTexture	= auctionTexture;
        
        Auctionator_RecommendPerItem_Price:Hide();
        Auctionator_RecommendPerStack_Price:Hide();

        processing_state = KM_NULL_STATE;
        
        basedata = nil;
        
        if (currentAuctionItemName == "") then
            
            if (auctionator_pending_message) then
                Auctionator_SetMessage (auctionator_pending_message);
                auctionator_pending_message = nil;
            elseif (auctionator_last_item_posted == nil) then
                Auctionator_SetMessage ("Drag an item to the Auction Item area\n\nto see recommended pricing information");
            end
        else
            local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(currentAuctionItemName);
        
            currentAuctionClass		= ItemType2AuctionClass (sType);
            currentAuctionSubclass	= "Guns"--Oh, no one's looking! SubType2AuctionSubclass (currentAuctionClass, sSubType);

            SortAuctionItems("list", "buyout");

            if (IsAuctionSortReversed("list", "buyout")) then
                SortAuctionItems("list", "buyout");
            end
         
            current_page = 0;
            processing_state = KM_PREQUERY;

            scandata = {};
        end

    end

end

    
-----------------------------------------

function Auctionator_ScrollbarUpdate()

    local line;				-- 1 through 12 of our window to scroll
    local dataOffset;		-- an index into our data calculated from the scroll offset

    local numrows = table.getn (sorteddata);

    if (numrows == nil) then
        numrows = 0
    end
        
    FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 10, 16);

    for line = 1,10 do

        dataOffset = line + FauxScrollFrame_GetOffset (AuctionatorScrollFrame);
        
        local lineEntry = getglobal ("AuctionatorEntry"..line);
        
        lineEntry:SetID(dataOffset);
        
        if dataOffset <= numrows and sorteddata[dataOffset] then
            
            local data = sorteddata[dataOffset];

            local lineEntry_avail	= getglobal("AuctionatorEntry"..line.."_Availability");
            local lineEntry_comm	= getglobal("AuctionatorEntry"..line.."_Comment");
            local lineEntry_stack	= getglobal("AuctionatorEntry"..line.."_StackPrice");

            if (data.itemPrice == basedata.itemPrice and data.stackSize == basedata.stackSize) then
                lineEntry:LockHighlight();
            else
                lineEntry:UnlockHighlight();
            end

            if ( data.stackSize == currentAuctionStackSize ) then	lineEntry_avail:SetTextColor (0.2, 0.9, 0.2);
            else													lineEntry_avail:SetTextColor (1.0, 1.0, 1.0);
            end;

            
            if		(data.numYours == 0) then			lineEntry_comm:SetText ("");
            elseif	(data.numYours == data.count) then	lineEntry_comm:SetText ("yours");
            else										lineEntry_comm:SetText ("yours: "..data.numYours);
            end;
                
            
            local tx = string.format ("%i %s of %i", data.count, pluralizeIf ("stack", data.count), data.stackSize);

            MoneyFrame_Update ("AuctionatorEntry"..line.."_PerItem_Price", round(data.buyoutPrice/data.stackSize) );

            lineEntry_avail:SetText (tx);
            lineEntry_stack:SetText (priceToString(data.buyoutPrice));

            lineEntry:Show();
        else
            lineEntry:Hide();
        end
    end
end

-----------------------------------------

function Auctionator_EntryOnClick()
    local entryIndex = this:GetID();
    
--	chatmsg (entryIndex);
    
    basedata = sorteddata[entryIndex];

    Auctionator_UpdateRecommendation();

    PlaySound ("igMainMenuOptionCheckBoxOn");
end

-----------------------------------------

function AuctionatorMoneyFrame_OnLoad()

    this.small = 1;
    SmallMoneyFrame_OnLoad();
    MoneyFrame_SetType("AUCTION");
end

-----------------------------------------

function Auctionator_ShowOptionsFrame()

    AuctionatorOptionsFrame:Show();
    AuctionatorOptionsFrame:SetBackdropColor(0,0,0,100);
    
    AuctionatorConfigFrameTitle:SetText ("Auctionator Options for "..UnitName("player"));
    
    local expText = "<html><body>"
                    .."<h1>What is Auctionator?</h1><br/>"
                    .."<p>"
                    .."Figuring out a good buyout price when posting auctions can be tedious and time-consuming.  If you're like most people, you first browse the current "
                    .."auctions to get a sense of how much your item is currently selling for.  Then you undercut the lowest price by a bit.  If you're creating multiple auctions "
                    .."you're bouncing back and forth between the Browse tab and the Auctions tab, doing lots of division in "
                    .."your head, and doing lots of clicking and typing."
                    .."</p><br/><h1>How it works</h1><br/><p>"
                    .."Auctionator makes this whole process easy and streamlined.  When you select an item to auction, Auctionator displays a summary of all the current auctions for "
                    .."that item sorted by per-item price.  Auctionator also calculates a recommended buyout price based on the cheapest per-item price for your item.  If you're "
                    .."selling a stack rather than a single item, Auctionator bases its recommended buyout price on the cheapest stack of the same size."
                    .."</p><br/><p>"
                    .."If you don't like Auctionator's recommendation, you can click on any line in the summary and Auctionator will recalculate the recommended buyout price based "
                    .."on that auction.  Of course, you can always override Auctionator's recommendation by just typing in your own buyout price."
                    .."</p><br/><p>"
                    .."With Auctionator, creating an auction is usually just a matter of picking an item to auction and clicking the Create Auction button."
                    .."</p>"
                    .."</body></html>"
                    ;



    AuctionatorExplanation:SetText ("Auctionator is an addon designed to make it easier and faster to setup your auctions at the auction house.");
    AuctionatorDescriptionHTML:SetText (expText);
    AuctionatorDescriptionHTML:SetSpacing (3);

    AuctionatorVersionText:SetText ("Version: "..AuctionatorVersion);

    
    AuctionatorOption_Enable_Alt:SetChecked (NumToBool(AUCTIONATOR_ENABLE_ALT));
    AuctionatorOption_Open_First:SetChecked (NumToBool(AUCTIONATOR_OPEN_FIRST));
end

-----------------------------------------

function AuctionatorOptionsSave()

    AUCTIONATOR_ENABLE_ALT = BoolToNum(AuctionatorOption_Enable_Alt:GetChecked ());
    AUCTIONATOR_OPEN_FIRST = BoolToNum(AuctionatorOption_Open_First:GetChecked ());
    
end

-----------------------------------------

function Auctionator_ShowTooltip_EnableAlt()

    GameTooltip:SetOwner(this, "ANCHOR_BOTTOM");
    GameTooltip:SetText("Enable alt-key shortcut", 0.9, 1.0, 1.0);
    GameTooltip:AddLine("If this option is checked, holding the Alt key down while clicking an item in your bags will switch to the Auctionator panel, place the item in the Auction Item area, and start the scan.", 0.5, 0.5, 1.0, 1);
    GameTooltip:Show();

end

-----------------------------------------

function Auctionator_ShowTooltip_OpenFirst()

    GameTooltip:SetOwner(this, "ANCHOR_BOTTOM");
    GameTooltip:SetText("Automatically open Auctionator panel", 0.9, 1.0, 1.0);
    GameTooltip:AddLine("If this option is checked, the Auctionator panel will display first whenever you open the Auction House window.", 0.5, 0.5, 1.0, 1);
    GameTooltip:Show();

end



--[[***************************************************************

    All function below here are local utility functions.
    These should be declared local at the top of this file.

--*****************************************************************]]


function BoolToString (b)
    if (b) then
        return "true";
    end
    
    return "false";
end

-----------------------------------------

function BoolToNum (b)
    if (b) then
        return 1;
    end
    
    return 0;
end

-----------------------------------------

function NumToBool (n)
    if (n == 0) then
        return false;
    end
    
    return true;
end

-----------------------------------------

function pluralizeIf (word, count)

    if (count and count == 1) then
        return word;
    else
        return word.."s";
    end
end

-----------------------------------------

function round (v)
    return math.floor (v + 0.5);
end

-----------------------------------------

function chatmsg (msg)
    if (DEFAULT_CHAT_FRAME) then
        DEFAULT_CHAT_FRAME:AddMessage (msg);
    end
end

-----------------------------------------

function calcNewPrice (price)

    if	(price > 2000000)	then return roundPriceDown (price, 10000, 10000);	end;
    if	(price > 1000000)	then return roundPriceDown (price,  2500,  2500);	end;
    if	(price >  500000)	then return roundPriceDown (price,  1000,  1000);	end;
    if	(price >   50000)	then return roundPriceDown (price,   500,   500);	end;
    if	(price >   10000)	then return roundPriceDown (price,   500,   200);	end;
    if	(price >    2000)	then return roundPriceDown (price,   100,    50);	end;
    if	(price >     100)	then return roundPriceDown (price,    10,     5);	end;
    if	(price >       0)	then return math.floor (price - 1);	end;

    return 0;
end

-----------------------------------------
-- roundPriceDown - rounds a price down to the next lowest multiple of a.
--				  - if the result is not at least b lower, rounds down by a again.
--
--	examples:  	(128790, 500, 250)  ->  128500 
--				(128700, 500, 250)  ->  128000 
--				(128400, 500, 250)  ->  128000
-----------------------------------------

function roundPriceDown (price, a, b)
    
    local newprice = math.floor(price / a) * a;
    
    if ((price - newprice) < b) then
        newprice = newprice - a;
    end
    
    return newprice;
    
end

-----------------------------------------

function val2gsc (v)
    local rv = round(v)
    
    local g = math.floor (rv/10000);
    
    rv = rv - g*10000;
    
    local s = math.floor (rv/100);
    
    rv = rv - s*100;
    
    local c = rv;
            
    return g, s, c
end

-----------------------------------------

function priceToString (val)

    local gold, silver, copper  = val2gsc(val);

    local st = "";
    

    if (gold ~= 0) then
        st = gold.."g ";
    end


    if (st ~= "") then
        st = st..format("%02is ", silver);
    elseif (silver ~= 0) then
        st = st..silver.."s ";
    end

        
    if (st ~= "") then
        st = st..format("%02ic", copper);
    elseif (copper ~= 0) then
        st = st..copper.."c";
    end
    
    return st;
end

-----------------------------------------

function ItemType2AuctionClass(itemType)
    local itemClasses = { GetAuctionItemClasses() };
    if (itemClasses ~= nil) then
        if table.getn (itemClasses) > 0 then
        local itemClass;
            for x, itemClass in pairs(itemClasses) do
                if (itemClass == itemType) then
                    return x;
                end
            end
        end
    else chatmsg ("Can't GetAuctionItemClasses"); end
end

-----------------------------------------

function SubType2AuctionSubclass(auctionClass, itemSubtype)
    local itemClasses = { GetAuctionItemSubClasses(auctionClass.number) };
    if itemClasses.n > 0 then
    local itemClass;
        for x, itemClass in pairs(itemClasses) do
            if (itemClass == itemSubtype) then
                return x;
            end
        end
    end
end

function relevel(frame) --Local
    local myLevel = frame:GetFrameLevel() + 1
    local children = { frame:GetChildren() }
    for _,child in pairs(children) do
        child:SetFrameLevel(myLevel)
        relevel(child)
    end
end





