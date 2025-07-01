---Current date since this has been versioned.
---May produce false positives, so I try to offset this by plus a minute or two to the future. Doesn't seem as reliable,
---but it's able to cover cases where either the user downloaded this addon with a zip, or `git clone`d it
local DATE = "2025-07-01T14:38:05Z"
local changelog = ""

local RED = Color(255, 0, 0)
local GREEN = Color(0, 255, 0)
local GREY = Color(192, 192, 192)

local function displayChangelog()
    MsgC(GREY, "Current changes since update", "\n\n", color_white, changelog)
end

local function versionCheckResponse(isUpToDate)
    if not isUpToDate then
        chat.AddText("Stop Motion Helper Unofficial is not up-to-date. Check the console for the latest changes, and update your addon")
        if #changelog > 0 then
            displayChangelog()
        end
    else
        chat.AddText("Stop Motion Helper Unofficial is up-to-date.")
    end
end

local statusCodes = {
    [400] = "Bad Request",
    [404] = "Resource not found",
    [409] = "Conflict",
    [500] = "Internal Error"
}
local function versionCheck()
    if #changelog > 0 then
        displayChangelog()
        return
    end

    http.Fetch(Format("https://api.github.com/repos/vlazed/StopMotionHelper/commits?sha=develop&since=%s", DATE), function (body, _, _, code)
        if code == 200 then
            local isUpToDate = true
            local response = util.JSONToTable(body)
            if response then
                if #response > 0 then
                    isUpToDate = false
                    for _, commitInfo in ipairs(response) do
                        if commitInfo.commit and commitInfo.commit.message and commitInfo.commit.committer then
                            changelog = Format("%s[%s]: %s\n\n", changelog, commitInfo.commit.committer.date or "unknown", commitInfo.commit.message)
                        end
                    end
                    MsgC(GREEN, "[SMH Unofficial]: Successfully fetched commits since this version was pushed\n")
                else
                    changelog = "SMH is up-to-date\n"
                end
            end
            versionCheckResponse(isUpToDate)
        else
            MsgC(RED, "[SMH Unofficial]: Failed to fetch from given url: ", statusCodes[code], "\n")
        end
    end, function (error)
        MsgC(RED, "[SMH Unofficial]: Failed to check versions: ", error, "\n")
    end)
end

concommand.Add("smh_versioncheck", versionCheck, nil, "Check if SMH is up-to-date")
local cvar = CreateClientConVar("smh_versioncheck_enabled", "1", true, false, "If enabled, version checking will occur whenever one loads into a map", 0, 1)

if cvar:GetBool() then
    versionCheck()
end