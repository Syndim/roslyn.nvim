local M = {}

---@class RoslynNvimDirectoryWithFiles
---@field directory string
---@field files string[]

---Gets the root directory of the first project file and find all related project file to that directory
---@param buffer integer
---@return RoslynNvimDirectoryWithFiles?
function M.get_project_files(buffer)
    local directory = vim.fs.root(buffer, function(name)
        return name:match("%.csproj$") ~= nil
    end)

    if not directory then
        return nil
    end

    local files = vim.fs.find(function(name, _)
        return name:match("%.csproj$")
    end, { path = directory, limit = math.huge })

    return {
        directory = directory,
        files = files,
    }
end

--TODO: Lot of duplication and not good for method that recursively search the filesystem
---Tries to get csproj files recursively from the current directory.
---If we open a file that is not a child of the current directory, then
---we return `nil` as we haven't found the project files for that.
---Fallback to using normal behaviour to check solution and csproj files like before
---@param bufnr number
---@return RoslynNvimDirectoryWithFiles?
function M.try_get_csproj_files(bufnr)
    local found = false
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    local files = vim.fs.find(function(name, path)
        if bufname == vim.fs.joinpath(path, name) then
            found = true
        end

        return name:match("%.csproj$") or name:match("%.sln$")
    end, { type = "file", limit = math.huge })

    local csproj_files = vim.iter(files)
        :filter(function(it)
            return it:match("%.csproj$")
        end)
        :totable()

    if not found or #files ~= #csproj_files or #files < 1 then
        return nil
    end

    local directory = vim.fs.root(bufnr, function(name)
        return name:match("%.csproj$")
    end)

    return {
        directory = directory,
        files = files,
    }
end

---Find the solution file from the current buffer.
---Recursively see if we have any other solution files, to potentially
---give th user an option to choose which solution file to use
---@param buffer integer
---@return string[]?
function M.get_solution_files(buffer)
    local directory = vim.fs.root(buffer, function(name)
        return name:match("%.sln$") ~= nil
    end)

    if not directory then
        return nil
    end

    return vim.fs.find(function(name, _)
        return name:match("%.sln$")
    end, { type = "file", limit = math.huge, path = directory })
end

--- Find a path to sln file that is likely to be the one that the current buffer
--- belongs to. Ability to predict the right sln file automates the process of starting
--- LSP, without requiring the user to invoke CSTarget each time the solution is open.
--- The prediction assumes that the nearest csproj file (in one of parent dirs from buffer)
--- should be a part of the sln file that the user intended to open.
---@param buffer integer
---@param sln_files string[]
---@return string?
function M.predict_sln_file(buffer, sln_files)
    local csproj = M.get_project_files(buffer)
    if not csproj or #csproj.files > 1 then
        return nil
    end

    local csproj_filename = vim.fn.fnamemodify(csproj.files[1], ":t")

    -- Look for a solution file that contains the name of the project
    -- Predict that to be the "correct" solution file if we find the project name
    for _, file_path in ipairs(sln_files) do
        local file = io.open(file_path, "r")

        if not file then
            return nil
        end

        local content = file:read("*a")
        file:close()

        if content:find(csproj_filename, 1, true) then
            return file_path
        end
    end

    return nil
end

return M
