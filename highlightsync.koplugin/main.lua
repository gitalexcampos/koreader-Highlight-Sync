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
local salt = assert(require("salt"))

local Highlightsync = WidgetContainer:extend{
    name = "Highlightsync",
    is_doc_only = false,
}

Highlightsync.settings = G_reader_settings:readSetting("statistics")

function Highlightsync:onDispatcherRegisterActions()
    Dispatcher:registerAction("hightlightsync_action", {category="tool", event="Highlightsync", title=_("Highlight Sync"), general=true,})
end


function Highlightsync:init()
    self:onDispatcherRegisterActions(
    self.ui.menu:registerToMainMenu(self))
end

local function fileExists(filename)
    local file = io.open(filename, "r")
    if file then
        file:close()
        return true
    else
        return false

    end
end


function Highlightsync.onSync(local_path, cached_path, income_path)

    local local_highlights = dofile(local_path)
    local cached_highlights
    if cached_path ~= nil and fileExists(cached_path) then -- Aqui está o erro. O arquivo não existe, mas está tentando abrir
        cached_highlights = dofile(cached_path)
    else
        cached_highlights = {}
    end
    local income_highlights
    if income_path ~= nil and fileExists(income_path)then
        income_highlights = dofile(income_path)
    else
        income_highlights = {}
    end
    local annotations = Merge.merge_highlights(local_highlights,income_highlights,cached_highlights)

    salt.save(annotations,SidecarDir .. "/" .. FileName .. ".lua",true) -- Save annotations local
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
         DataAnnotations = self.ui.doc_settings.data.annotations
         SidecarDir = self.ui.doc_settings.doc_sidecar_dir
         FileName = SidecarDir:match("([^/]+)/*$")
         salt.save(self.ui.annotation.annotations,SidecarDir .. "/" .. FileName .. ".lua",true) -- Save annotations local
         SyncService.sync(self.settings.sync_server, SidecarDir .. "/" .. FileName .. ".lua", self.onSync)
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
