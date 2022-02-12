local L = {}
local bankSort = false;
local guildSort = false;
local moves = {};
local depth = 0;
local frame = CreateFrame("Frame");
local t = 0;
local current = nil;
local log = {};
local itemInfo = {};
local soulstonebag = false;

local function contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

-- left item, right item value. true,false = top of bag;  false,true = bottom of bag
local specialItems = {
    ["Hearthstone"] = 0,
    ["Mining Pick"] = 1,
    ["Skinning Knife"] = 2,
    ["Salt Shaker"] = 3,
    ["Blacksmith Hammer"] = 4,
    ["Gnomish Army Knife"] = 5,
    ["Gyromatic Micro-Adjustor"] = 6,
    ["Virtuoso Inking Set"] = 7,
    ["Simple Grinder"] = 8,
    ["Jeweler's Kit"] = 9,
    ["Runed Copper Rod"] = 10,
    ["Runed Titanium Rod"] = 11,
    ["Runed Eternium Rod"] = 12,
    ["Runed Adamantite Rod"] = 13,
    ["Runed Fel Iron Rod"] = 14,
    ["Runed Arcanite Rod"] = 15,
    ["Runed Truesilver Rod"] = 16,
    ["Runed Golden Rod"] = 17,
    ["Runed Silver Rod"] = 18,
    ["Runed Copper Rod"] = 19,
    ["Mercurial Alchemist Stone"] = 20,
    ["Indestructible Alchemist's Stone"] = 21,
    ["Mighty Alchemist's Stone"] = 22,
    ["Guardian's Alchemist Stone"] = 23,
    ["Sorcerer's Alchemist Stone"] = 24,
    ["Redeemer's Alchemist Stone"] = 25,
    ["Assassin's Alchemist Stone"] = 26,
    ["Alchemist's Stone"] = 27,
    ["Philosopher's Stone"] = 28,
};

local itemClassPriority = {
    ["Armor"] = 0,
    ["Weapon"] = 1,
    ["Container"] = 2,
    ["Quiver"] = 3,
    ["Trade Goods"] = 4,
    ["Gem"] = 5,
    ["Reagent"] = 6,
    ["Projectile"] = 7,
    ["Recipe"] = 8,
    ["Consumable"] = 9,
    ["Miscellaneous"] = 10,
    ["Glyph"] = 11,
    ["Quest"] = 12
};

local itemSubClassPriority = {
    ["Consumable"] = {
        ["Food & Drink"] = 0,
        ["Potion"] = 1,
        ["Consumable"] = 2,
    },
    ["Armor"] = {
        ["Plate"] = 0,
        ["Mail"] = 1,
        ["Leather"] = 2,
        ["Cloth"] = 3,
        ["Miscellaneous"] = 4,
        ["Shields"] = 5,
    },
};

local function Log(msg)
    table.insert(log, msg);
    if (BAGSORT ~= nil) then
        BAGSORT.log = log;
    end
end

local function ClearLog()
    log = {};
end

local function GetIDFromLink(link)
    Log("GetIDFromLink(" .. tostring(link) .. ")");
    return link and tonumber(string.match(link, "item:(%d+)"));
end

local function getHigherPrioClass(lItem, rItem)
    local l = 999
    local r = 999
    local count = 0
    for k, _ in pairs(itemClassPriority) do
        print(k)
        if (lItem.class == k) then
            l = count
        end
        if (rItem.class == k) then
            r = count
        end
        count = count + 1
    end
    return (l < r)
end

local function getHigherPrioSubClass(lItem, rItem)
    local l = 999
    local r = 999
    local count = 0
    for subclass, _ in pairs(itemSubClassPriority[lItem.class]) do
        if (lItem.subclass == subclass) then
            l = count
        end
        if (rItem.subclass == subclass) then
            r = count
        end
        count = count + 1
    end
    return (l < r)
end

local function DoMoves()
    Log("DoMoves()");

    while (current ~= nil or #moves > 0) do
        if current ~= nil then
            Log("current.id = " .. tostring(current.id));
            if CursorHasItem() then
                Log("Cursor Has Item");
                local type, id = GetCursorInfo();
                Log("type = " .. tostring(type) .. ", id = " .. tostring(id));
                if (current ~= nil and current.id == id) then
                    if (current.sourcebag ~= nill) then
                        Log("PickupContainerItem(" .. current.targetbag .. ", " .. current.targetslot .. ")");

                        PickupContainerItem(current.targetbag, current.targetslot);

                        local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                        if (current.id ~= GetIDFromLink(link)) then
                            return ;
                        end
                    else
                        Log("PickupGuildBankItem(" .. current.targettab .. ", " .. current.targetslot .. ")");

                        PickupGuildBankItem(current.targettab, current.targetslot);

                        local link = GetGuildBankItemLink(current.targettab, current.targetslot);
                        if (current.id ~= GetIDFromLink(link)) then
                            return ;
                        end
                    end
                else
                    Log("Sort Aborted");
                    DEFAULT_CHAT_FRAME:AddMessage("Sort Aborted");
                    moves = {};
                    current = nil;
                    frame:Hide();
                    return ;
                end
            else
                if (current.sourcebag ~= nill) then
                    local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                    if (current.id ~= GetIDFromLink(link)) then
                        return ;
                    end
                else
                    local link = GetGuildBankItemLink(current.targettab, current.targetslot);
                    if (current.id ~= GetIDFromLink(link)) then
                        return ;
                    end
                end
                current = nil;
            end
        else
            Log("current == nil");
            if (#moves > 0) then
                Log("(" .. #moves .. " > 0)");

                current = table.remove(moves, 1);

                if (current.sourcebag ~= nill) then
                    Log("PickupContainerItem(" .. current.sourcebag .. ", " .. current.sourceslot .. ")");
                    PickupContainerItem(current.sourcebag, current.sourceslot);
                    if CursorHasItem() == false then
                        return ;
                    end

                    Log("PickupContainerItem(" .. current.targetbag .. ", " .. current.targetslot .. ")");
                    PickupContainerItem(current.targetbag, current.targetslot);
                    local link = select(7, GetContainerItemInfo(current.targetbag, current.targetslot));
                    if (current.id == GetIDFromLink(link)) then
                        Log("current = nil");
                        current = nil;
                    else
                        return ;
                    end
                else
                    Log("PickupGuildBankItem(" .. current.sourcetab .. ", " .. current.sourceslot .. ")");
                    PickupGuildBankItem(current.sourcetab, current.sourceslot);
                    Log("PickupGuildBankItem(" .. current.targettab .. ", " .. current.targetslot .. ")");
                    PickupGuildBankItem(current.targettab, current.targetslot);
                    local link = GetGuildBankItemLink(current.targettab, current.targetslot);
                    if (current.id == GetIDFromLink(link)) then
                        Log("current = nil");
                        current = nil;
                    else
                        return ;
                    end
                end

            end
        end
    end
    Log("Sorted!");
    --for class, subclasses in pairs(itemInfo) do
    --    DEFAULT_CHAT_FRAME:AddMessage(class);
    --    for subclassName, items in pairs(subclasses) do
    --        DEFAULT_CHAT_FRAME:AddMessage("--" .. subclassName);
    --        for item, quality in pairs(items) do
    --            DEFAULT_CHAT_FRAME:AddMessage("----" .. item .. " || " .. quality);
    --        end
    --    end
    --end
    DEFAULT_CHAT_FRAME:AddMessage("Sorted!");
    frame:Hide();
end

local function sortOnSpecialItem(lItem, rItem)
    if (lItem.name ~= rItem.name) then
        if (specialItems[lItem.name] ~= nil and specialItems[rItem.name] ~= nil) then
            return (specialItems[lItem.name] < specialItems[rItem.name])
        elseif (specialItems[lItem.name] ~= nil) then
            return specialItems[lItem.name] < 888
        else
            return specialItems[rItem.name] > 888
        end
    end
end

local function sortOnClass(lItem, rItem)
    Log("(lItem.class ~= rItem.class)");
    if (itemClassPriority[lItem.class] == nil) then
        return false
    elseif (itemClassPriority[rItem.class] == nil) then
        return true
    else
        return (itemClassPriority[lItem.class] < itemClassPriority[rItem.class]);
    end
end

local function sortOnSubclass(lItem, rItem)
    Log("(lItem.subclass ~= rItem.subclass)");
    if (itemSubClassPriority[lItem.class] ~= nil) then
        if (itemSubClassPriority[lItem.class][lItem.subclass] == nil) then
            return false
        elseif (itemSubClassPriority[rItem.class][rItem.subclass] == nil) then
            return true
        else
            return (itemSubClassPriority[lItem.class][lItem.subclass] < itemSubClassPriority[rItem.class][rItem.subclass])
        end
    else
        return (lItem.subclass < rItem.subclass);
    end
end

local function recordItemInfo(lItem)
    if (itemInfo[lItem.class] == nil) then
        itemInfo[lItem.class] = {};
    end
    if (itemInfo[lItem.class][lItem.subclass] == nil) then
        itemInfo[lItem.class][lItem.subclass] = {};
    end
    itemInfo[lItem.class][lItem.subclass][lItem.name] = " || " .. lItem.quality;
end

local function CompareItems(lItem, rItem)
    Log("CompareItems(" .. lItem.name .. ", " .. rItem.name .. ")");
    if (rItem.id == nil) then
        Log("(rItem.id == nil)");
        return true;
    elseif (lItem.id == nil) then
        Log("(lItem.id == nil)");
        return false;
    end
    recordItemInfo(lItem)
    if (specialItems[lItem.name] ~= nil or specialItems[rItem.name] ~= nil) then
        return sortOnSpecialItem(lItem, rItem)
    elseif (lItem.class ~= rItem.class) then
        return sortOnClass(lItem, rItem)
    elseif (lItem.subclass ~= rItem.subclass) then
        return sortOnSubclass(lItem, rItem)
    elseif (lItem.quality ~= rItem.quality) then
        Log("(lItem.quality ~= rItem.quality)");
        return (lItem.quality > rItem.quality);
    elseif (lItem.name ~= rItem.name) then
        Log("(lItem.name ~= rItem.name)");
        return (lItem.name < rItem.name);
    elseif ((lItem.count) ~= (rItem.count)) then
        Log("((lItem.count) ~= (rItem.count))");
        return ((lItem.count) >= (rItem.count));
    else
        Log("return true");
        return true;
    end
end

local function BeginSort()
    Log("BeginSort()");
    current = nil;
    moves = {};
    ClearCursor();
end

local function SortBag(bag)
    Log("SortBag(bag)");      --- bag 1,2,3,4    #bag=4

    for i = 1, #bag, 1 do
        Log("i=" .. i);
        local lowest = i; --lowest = 1
        for j = #bag, i + 1, -1 do
            --j=4,2,-1
            Log("j=" .. j);
            if (CompareItems(bag[lowest], bag[j]) == false) then
                Log("lowest=" .. j);
                lowest = j;
            end
        end
        if (i ~= lowest) then
            Log("(i ~= lowest)");


            -- store move
            move = {};
            move.id = bag[lowest].id;
            move.name = bag[lowest].name;
            move.sourcebag = bag[lowest].bag;
            move.sourcetab = bag[lowest].tab;
            move.sourceslot = bag[lowest].slot;
            move.targetbag = bag[i].bag;
            move.targettab = bag[i].tab;
            move.targetslot = bag[i].slot;
            table.insert(moves, move);
            Log("move " .. move.name .. " from " .. move.sourceslot .. " to " .. move.targetslot);

            -- swap items
            local tmp = bag[i];
            bag[i] = bag[lowest];
            bag[lowest] = tmp;

            Log("bag[i] = " .. bag[i].name .. "(" .. bag[i].slot .. "), bag[lowest] = " .. bag[lowest].name .. "(" .. bag[lowest].slot .. ")");

            -- swap slots
            tmp = bag[i].slot;
            bag[i].slot = bag[lowest].slot;
            bag[lowest].slot = tmp;
            tmp = bag[i].bag;
            bag[i].bag = bag[lowest].bag;
            bag[lowest].bag = tmp;
            tmp = bag[i].tab;
            bag[i].tab = bag[lowest].tab;
            bag[lowest].tab = tmp;

            Log("bag[i] = " .. bag[i].name .. "(" .. bag[i].slot .. "), bag[lowest] = " .. bag[lowest].name .. "(" .. bag[lowest].slot .. ")");
        end
    end
end

local function CreateBagFromID(bagID)
    Log("CreateBagFromID(" .. bagID .. ")");

    local items = GetContainerNumSlots(bagID);
    local bag = {};

    Log("items = " .. items);

    for i = 1, items, 1 do
        local item = {};

        Log("i = " .. i);

        local _, count, _, _, _, _, link = GetContainerItemInfo(bagID, i);
        item.bag = bagID;
        item.slot = i;
        item.name = "<EMPTY>";
        item.id = GetIDFromLink(link);
        if (item.id ~= nil) then
            item.count = count;
            item.name, _, item.quality, _, _, item.class, item.subclass, _, item.type, _, item.price = GetItemInfo(item.id);
        end

        Log("item = " .. item.name);

        table.insert(bag, item);
    end
    return bag;
end

local function CreateBagFromTab(tab)
    Log("CreateBagFromTab(" .. tab .. ")");

    local items = MAX_GUILDBANK_SLOTS_PER_TAB;
    local bag = {};

    Log("items = " .. items);

    for i = 1, items, 1 do
        local item = {};

        Log("i = " .. i);

        local _, count = GetGuildBankItemInfo(tab, i);
        local link = GetGuildBankItemLink(tab, i);
        item.tab = tab;
        item.slot = i;
        item.name = "<EMPTY>";
        item.id = GetIDFromLink(link);
        if (item.id ~= nil) then
            item.count = count;
            item.name, _, item.quality, _, _, item.class, item.subclass, _, item.type, _, item.price = GetItemInfo(item.id);
        end
        table.insert(bag, item);

        Log("item = " .. item.name);
    end
    return bag;
end

local function checkForSoulBag(bags)
    if (bags["4"] == nil) then
        specialItems["Soul Shard"] = 999
    else
        specialItems["Soul Shard"] = nil
    end
end

local function BAGSORT_BagSortButton(self)
    ClearLog();

    Log("BAGSORT_BagSortButton(self)");
    local bags = {};

    for i = 0, NUM_BAG_FRAMES, 1 do
        local framenum = i + 1;
        if _G["ContainerFrame" .. framenum .. "SortCheck"]:GetChecked() then
            Log("Bag #" .. i .. " is checked");
            local bag = CreateBagFromID(i);
            local type = select(2, GetContainerNumFreeSlots(i));
            if type == nil then
                type = "ALL"
            else
                type = tostring(type);
            end
            Log("type = " .. type);
            if bags[type] == nil then
                Log("bags[type] == nil");
                bags[type] = bag;
            else
                Log("bags[type] ~= nil");
                Log("#bags[type] = " .. #bags[type]);
                for j = 1, #bag, 1 do
                    table.insert(bags[type], bag[j]);
                end
                Log("#bags[type] = " .. #bags[type]);
            end
        end
    end
    checkForSoulBag(bags)

    BeginSort();

    for k, v in pairs(bags) do
        if v ~= nil then
            Log("k = " .. k .. ", v ~= nli");
            SortBag(v);
        end
    end
    frame:Show();
end

local function BAGSORT_BankSortButton(self)
    ClearLog();

    Log("BAGSORT_BankSortButton(self)");
    local bags = {};

    if _G["BankFrameSortCheck"]:GetChecked() then
        Log("Bank is checked");
        bags["0"] = CreateBagFromID(-1);
    end

    for i = NUM_BAG_FRAMES + 1, NUM_CONTAINER_FRAMES, 1 do
        local framenum = i + 1;
        local frame = _G["ContainerFrame" .. framenum .. "SortCheck"];
        if (frame ~= nil and frame:GetChecked()) then
            Log("Bag #" .. i .. " is checked");
            local bag = CreateBagFromID(i);
            local type = select(2, GetContainerNumFreeSlots(i));
            if type == nil then
                type = "ALL"
            else
                type = tostring(type);
            end
            Log("type = " .. type);
            if bags[type] == nil then
                Log("bags[type] == nil");
                bags[type] = bag;
            else
                Log("bags[type] ~= nil");
                Log("#bags[type] = " .. #bags[type]);
                for j = 1, #bag, 1 do
                    table.insert(bags[type], bag[j]);
                end
                Log("#bags[type] = " .. #bags[type]);
            end
        end
    end
    checkForSoulBag(bags)
    BeginSort();

    for k, v in pairs(bags) do
        if v ~= nil then
            Log("k = " .. k .. ", v ~= nli");
            SortBag(v);
        end
    end
    frame:Show();

end

local function BAGSORT_GuildSortButton(self)
    ClearLog();

    Log("BAGSORT_GuildSortButton(self)");
    local bag = CreateBagFromTab(GetCurrentGuildBankTab());
    SortBag(bag);
    frame:Show();
end

local function CreateSortCheck(name, parent, x, y)
    Log("CreateSortButton(" .. name .. ", parent, " .. x .. ", " .. y .. ", handler)");

    parent.sortButton = CreateFrame("CheckButton", name, parent, "BAGSORTCheckTemplate");
    parent.sortButton.parentFrame = parent;
    parent.sortButton:SetChecked(true);
    parent.sortButton.tooltipText = "Include this bag when sorting?";
    parent.sortButton:ClearAllPoints();
    parent.sortButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);

    if BAGSORT.IsEnabled then
        parent.sortButton:Show();
    else
        parent.sortButton:Hide();
    end
end

local function CreateSortButton(name, parent, x, y, handler)
    Log("CreateSortButton(" .. name .. ", parent, " .. x .. ", " .. y .. ", handler)");

    parent.sortButton = CreateFrame("Button", name, parent, "UIPanelButtonTemplate");
    parent.sortButton.parentFrame = parent;
    parent.sortButton:SetWidth(45);
    parent.sortButton:SetHeight(18);
    parent.sortButton:SetText("Sort");
    parent.sortButton:ClearAllPoints();
    parent.sortButton:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);

    if BAGSORT.IsEnabled then
        parent.sortButton:Show();
    else
        parent.sortButton:Hide();
    end

    parent.sortButton:SetScript("OnClick", handler);
end

function BAGSORT_MainFrame_OnLoad(self)
    Log("BAGSORT_MainFrame_OnLoad(self)");

    local fEnable = true;
    if (BAGSORT ~= nil and BAGSORT.IsEnabled ~= nil) then
        Log("(BAGSORT ~= nil and BAGSORT.IsEnabled ~= nil)");
        fEnable = BAGSORT.IsEnabled;
    end

    BAGSORT = {};
    Log("BAGSORT = {};");
    BAGSORT.IsEnabled = fEnable;
    Log("BAGSORT.IsEnabled = " .. tostring(BAGSORT.IsEnabled));

    L = {
        BAGSORT_OPTIONSPANEL_CREDITS1 = "Bag Sort was designed and built by the guildies of <Bag Regular> on US-Draka.",
        BAGSORT_OPTIONSPANEL_CREDITS2 = "Check out our website at http://www.bag-regular.com",
        BAGSORT_OPTIONSPANEL_ENABLE = "Enable Sort",
        BAGSORT_OPTIONSPANEL_ENABLE_TIP = "Enable or disable this addon without uninstalling it.",
        BAGSORT_OPTIONSPANEL_TITLE = "Bag Sort Settings",
    }

    BAGSORT_OPTIONSPANEL_TITLE = L["BAGSORT_OPTIONSPANEL_TITLE"];
    BAGSORT_OPTIONSPANEL_ENABLE = L["BAGSORT_OPTIONSPANEL_ENABLE"];
    BAGSORT_OPTIONSPANEL_ENABLE_TIP = L["BAGSORT_OPTIONSPANEL_ENABLE_TIP"];
    BAGSORT_OPTIONSPANEL_CREDITS1 = L["BAGSORT_OPTIONSPANEL_CREDITS1"];
    BAGSORT_OPTIONSPANEL_CREDITS2 = L["BAGSORT_OPTIONSPANEL_CREDITS2"];

    for i = 1, NUM_CONTAINER_FRAMES, 1 do
        CreateSortCheck("ContainerFrame" .. i .. "SortCheck", _G["ContainerFrame" .. i], 42, -25)
    end

    CreateSortButton("ContainerFrame1SortButton", _G["ContainerFrame1"], 138, -28, BAGSORT_BagSortButton);

    frame:SetScript("OnUpdate", function()
        Log("OnUpdate(" .. arg1 .. ")");
        t = t + arg1;
        Log("t = " .. t);
        if t > 0.05 then
            Log("t > 0.05");
            t = 0
            DoMoves();
        end
    end)
    frame:Hide();

    DEFAULT_CHAT_FRAME:AddMessage("Bag Sort 3.3.5 Loaded");
    DEFAULT_CHAT_FRAME:AddMessage("To access settings use \"/ss\"");
    self:RegisterEvent("BANKFRAME_OPENED");
    self:RegisterEvent("BANKFRAME_CLOSED")
    self:RegisterEvent("GUILDBANKFRAME_OPENED");
    self:RegisterEvent("GUILDBANKFRAME_CLOSED");
    self:RegisterEvent("VARIABLES_LOADED");
end

local function hook_GuildBankTab_OnClick(...)
    Log("hook_GuildBankTab_OnClick(...)");

    local tab = GetCurrentGuildBankTab();
    if (tab > GetNumGuildBankTabs()) then
        Log("(tab > GetNumGuildBankTabs())");
        _G["GuildBankFrame"].sortButton:Disable();
    else
        Log("else");
        _G["GuildBankFrame"].sortButton:Enable();
    end
end

function BAGSORT_MainFrame_OnEvent(self, event, ...)
    Log("BAGSORT_MainFrame_OnEvent(self, " .. event .. ", ...)");
    if (event == "BANKFRAME_OPENED") then
        bankSort = true;
    elseif (event == "BANKFRAME_CLOSED") then
        bankSort = false;
    elseif (event == "VARIABLES_LOADED") then
        Log("(event == VARIABLES_LOADED)");
        InterfaceOptions_AddCategory(BAGSORT_OptionsPanel);
    end
end

function BAGSORT_OptionsPanel_OnOk(self)
    Log("BAGSORT_OptionsPanel_OnOk(self)");
    BAGSORT.IsEnabled = (BAGSORT_OptionsPanel_OCDEnabled:GetChecked() ~= nil);
    if (BAGSORT.IsEnabled == true) then
        Log("(BAGSORT.IsEnabled == true)");
        for i = 1, NUM_CONTAINER_FRAMES, 1 do
            Log("i=" .. i);
            _G["ContainerFrame" .. i].sortButton:Show();
        end
        _G["BankFrame"].sortButton:Show();
        _G["GuildBankFrame"].sortButton:Show();
    else
        Log("else");
        for i = 1, NUM_CONTAINER_FRAMES, 1 do
            Log("i=" .. i);
            _G["ContainerFrame" .. i].sortButton:Hide();
        end
        _G["BankFrame"].sortButton:Hide();
        _G["GuildBankFrame"].sortButton:Hide();
    end
end

function BAGSORT_OptionsPanel_OnCancel(self)
    Log("BAGSORT_OptionsPanel_OnCancel(self)");
    BAGSORT_OptionsPanel_OCDEnabled:SetChecked(BAGSORT.IsEnabled);
end

function BAGSORT_OptionsPanel_OnDefault(self)
    Log("BAGSORT_OptionsPanel_OnDefault(self)");
    BAGSORT.IsEnabled = false;
    BAGSORT_OptionsPanel_OnCancel()
end

function BAGSORT_OptionsPanel_OnRefresh(self)
    Log("BAGSORT_OptionsPanel_OnRefresh(self)");
    BAGSORT_OptionsPanel_OnCancel()
end

function BAGSORT_OptionsPanel_OnChange(self)
end

function BAGSORT_OptionsPanel_OnLoad(panel)
    Log("BAGSORT_OptionsPanel_OnLoad(panel)");
    panel.name = "Bag Sort";
    panel.okay = BAGSORT_OptionsPanel_OnOk;
    panel.cancel = BAGSORT_OptionsPanel_OnCancel;
    panel.default = BAGSORT_OptionsPanel_OnDefault;
    panel.refresh = BAGSORT_OptionsPanel_OnRefresh;
    panel.onChange = BAGSORT_OptionsPanel_OnChange;
end

function BAGSORT_SlashCommand(cmd, arg2)
    Log("BAGSORT_SlashCommand(" .. tostring(cmd) .. ", " .. tostring(arg2) .. ")");
    if cmd == "sort" then
        BAGSORT_BagSortButton()
        if bankSort == true then
            BAGSORT_BankSortButton()
        end
        if guildSort == true then
            BAGSORT_GuildSortButton()
        end
    elseif cmd == "options" then
        InterfaceOptionsFrame_OpenToCategory("Bag Sort");
    end
end

SLASH_SUSHISORT1 = "/BS";
SlashCmdList["SUSHISORT"] = BAGSORT_SlashCommand;

