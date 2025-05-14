local Dispatcher = require("dispatcher")  -- luacheck:ignore
local UIManager = require("ui/uimanager")
local ButtonDialog = require("ui/widget/buttondialog")
local ConfirmBox = require("ui/widget/confirmbox")
local FFIUtil = require("ffi/util")
local T = FFIUtil.template
local InfoMessage = require("ui/widget/infomessage")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local SyncService = require("frontend/apps/cloudstorage/syncservice")
local Merge = require("merge")
local rapidjson = require("rapidjson")

local function dir_exists(path)
    local ok, _, code = os.rename(path, path)
    if not ok then
        -- Código 13 = permission denied, mas o diretório existe
        return code == 13
    end
    return true
end

local function ensure_dir_exists(path)
    if not dir_exists(path) then
        local result = os.execute('mkdir -p "' .. path .. '"')
        if not result then
            error("Failed to create directory: " .. path)
        end
    end
end

local Highlightsync = WidgetContainer:extend{
    name = "Highlightsync",
    is_doc_only = false,
}

local function read_json_file(path)
    local file = io.open(path, "r")
    if not file then
        -- Arquivo não existe
        return {}
    end

    local content = file:read("*a")
    file:close()

    if not content or content == "" then
        return {}
    end

    local ok, data = pcall(rapidjson.decode, content)
    if not ok or type(data) ~= "table" then
        return {}
    end

    return data
end

local function write_json_file(path, data)
    local file = io.open(path, "w")
    if not file then return false end
    file:write(rapidjson.encode(data))
    file:close()
    return true
end


function Highlightsync:onDispatcherRegisterActions()
    Dispatcher:registerAction("hightlightsync_action", {category="tool", event="Highlightsync", title=_("Highlight Sync"), general=true,})
end

Highlightsync.default_settings = {
       is_enabled = true,
}



function Highlightsync:init()
    if self.document and self.document.is_pic then
        return -- disable in PIC documents
    end

    Highlightsync.settings = G_reader_settings:readSetting("highlight_sync", self.default_settings)
    self:onDispatcherRegisterActions(
    self.ui.menu:registerToMainMenu(self))
end


function Highlightsync.onSync(local_path, cached_path, income_path)

    local local_highlights  = DataAnnotations --read_json_file(local_path)  or {}
    local cached_highlights = read_json_file(cached_path) or {}
    local income_highlights = read_json_file(income_path) or {}
    local annotations = Merge.Merge_highlights(local_highlights,income_highlights,cached_highlights)

    write_json_file(SidecarDir .. "/" .. FileName .. ".json", annotations) -- Save annotations local
    DataAnnotations = annotations
    return true
end

function Highlightsync:is_doc()
    if self.document then
        return true
    else
        return false
    end
end

function Highlightsync:canSync()
    return self.is_doc(self) and self.settings.sync_server ~= nil
end



function Highlightsync:onSyncBookHighlights()
    if not self:canSync() then return end

    UIManager:show(InfoMessage:new {
        text = _("Syncing book highlights. This may take a while."),
        timeout = 1,
    })

    UIManager:nextTick(function()
         DataAnnotations = self.ui.annotation.annotations -- self.ui.doc_settings.data.annotations
         SidecarDir = self.ui.doc_settings.doc_sidecar_dir
         FileName = SidecarDir:match("([^/]+)/*$")
         ensure_dir_exists(SidecarDir)
         write_json_file(SidecarDir .. "/" .. FileName .. ".json", self.ui.annotation.annotations) -- Save annotations local
         SyncService.sync(self.settings.sync_server, SidecarDir .. "/" .. FileName .. ".json", self.onSync)
         self.ui.annotation.annotations = DataAnnotations
         self.ui:reloadDocument()
    end)
end


function Highlightsync:addToMainMenu(menu_items)

    menu_items.highlight_sync = {
        text = _("Highlight Sync"),
        sub_item_table = {
            {
                text = _("Sync Cloud"),
                callback = function(touchmenu_instance)
                    local server = self.settings.sync_server
                    local edit_cb = function()
                        local sync_settings = SyncService:new{}
                        sync_settings.onClose = function(this)
                            UIManager:close(this)
                        end
                        sync_settings.onConfirm = function(sv)
                            self.settings.sync_server = sv
                            touchmenu_instance:updateItems()
                        end
                        UIManager:show(sync_settings)
                    end
                    if not server then
                        edit_cb()
                        return
                    end
                    local dialogue
                    local delete_button = {
                        text = _("Delete"),
                        callback = function()
                            UIManager:close(dialogue)
                            UIManager:show(ConfirmBox:new{
                                text = _("Delete server info?"),
                                cancel_text = _("Cancel"),
                                cancel_callback = function()
                                end,
                                ok_text = _("Delete"),
                                ok_callback = function()
                                    self.settings.sync_server = nil
                                    touchmenu_instance:updateItems()
                                end,
                            })
                        end,
                    }
                    local edit_button = {
                        text = _("Edit"),
                        callback = function()
                            UIManager:close(dialogue)
                            edit_cb()
                        end
                    }
                    local close_button = {
                        text = _("Close"),
                        callback = function()
                            UIManager:close(dialogue)
                        end
                    }
                    local type = server.type == "dropbox" and " (DropBox)" or " (WebDAV)"
                    dialogue = ButtonDialog:new{
                        title = T(_("Cloud storage:\n%1\n\nFolder path:\n%2\n\nSet up the same cloud folder on each device to sync across your devices."),
                                     server.name.." "..type, SyncService.getReadablePath(server)),
                        buttons = {
                            {delete_button, edit_button, close_button}
                        },
                    }
                    UIManager:show(dialogue)
                end,
                enabled_func = function() return self.settings.is_enabled end,
                keep_menu_open = true,
            },
            {
                text = _("Sync Highlights"),
                callback = function()
                    self:onSyncBookHighlights()
                end,
                enabled_func = function() return self.canSync(self) end
            }
        }
    }
end

require("insert_menu")

return Highlightsync
