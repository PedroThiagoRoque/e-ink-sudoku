local Storage=require("sudoku.storage")
local Definition=require("sudoku.definition")
local Game=require("sudoku.game")
local Session=require("sudoku.session")
local Repo={}; Repo.__index=Repo
function Repo.new(directory) os.execute("mkdir -p '"..directory.."'"); return setmetatable({directory=directory},Repo) end
function Repo:path(mode) return self.directory.."/"..mode..".json" end
function Repo:save(mode,session)
    return Storage.save(self:path(mode), {version=1,puzzle_id=session.puzzle.id,definition=Definition.encode(session.puzzle),game=session.game:serialize(),selected=session.selected,notes_mode=session.notes})
end
function Repo:load(mode)
    local path=self:path(mode); local record=Storage.load(path, nil)
    if not record then return nil end
    local puzzle,err=Definition.decode(record.definition); if not puzzle then return nil,err end
    local game,game_err=Game.restore(puzzle,record.game); if not game then return nil,game_err end
    return setmetatable({puzzle=puzzle,game=game,selected=record.selected,notes=record.notes_mode or false},Session)
end
return Repo
