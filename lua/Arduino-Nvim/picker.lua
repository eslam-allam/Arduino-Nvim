local M = {}

---@class Arduino-Nvim.Picker.Finder.EntryMaker.Result
---@field value string
---@field display string
---@field ordinal string

---@class Arduino-Nvim.Picker.Finder<T>
---@field results T[]
---@field entry_maker? fun(entry: T): Arduino-Nvim.Picker.Finder.EntryMaker.Result

---@class Arduino-Nvim.Picker.Actions
---@field close fun()

---@class Arduino-Nvim.Picker.opts
---@field prompt_title string
---@field finder Arduino-Nvim.Picker.Finder
---@field sorter fun(self, prompt: string, line: string, entry: Arduino-Nvim.Picker.Finder.EntryMaker.Result): number
---@field attach_mappings? fun(prompt_bufnr: number, map: function): boolean
---@field on_confirm? fun(actions: Arduino-Nvim.Picker.Actions, item: Arduino-Nvim.Picker.Finder.EntryMaker.Result)

---@param opts Arduino-Nvim.Picker.opts
---@return snacks.picker.Config
local function tosnacks(opts)
	local items = opts.finder.results
	if opts.finder.entry_maker ~= nil or type(items[1]) == "table" then
		items = vim.tbl_map(function(entry)
			local result = opts.finder.entry_maker(entry)
			return vim.tbl_deep_extend(
				"keep",
				{ text = result.ordinal ~= nil and result.ordinal or result.value },
				result
			)
		end, opts.finder.results)
	else
		items = vim.tbl_map(function(item)
			return { text = tostring(item), display = tostring(item) }
		end, items)
	end

	---@type snacks.picker.Config
	local transformed = {
		title = opts.prompt_title,
		items = items,
		format = function(item, _)
			return {
				{ item.display ~= nil and item.display or item.text, "SnacksNormal" },
			}
		end,
		matcher = {
			alt = true,
		},
		preview = "none",
		layout = "select",
		confirm = function(picker, item)
			local actions = {
				close = function()
					picker:close()
				end,
			}
			opts.on_confirm(
				actions,
				vim.tbl_deep_extend("keep", {
					display = item.text,
					value = item.value,
					ordinal = item.ordinal,
				}, item)
			)
		end,
		-- TODO: Attach mappings
	}

	return transformed
end

---@param opts Arduino-Nvim.Picker.opts
---@return table
local function totelescope(opts)
	local attach_mappings = opts.attach_mappings
	local transformed = vim.deepcopy(opts)
	transformed.finder = require("telescope.finders").new_table(opts.finder)
	transformed.attach_mappings = function(prompt_bufnr, map)
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		local mappedActions = {
			close = function()
				actions.close(prompt_bufnr)
			end,
		}
		if transformed.on_confirm ~= nil then
			local confirmWrapper = function()
				local selection = action_state.get_selected_entry()
				transformed.on_confirm(mappedActions, selection)
			end
			map("i", "<CR>", confirmWrapper)
			map("n", "<CR>", confirmWrapper)
		end
		if attach_mappings ~= nil then
			return attach_mappings(prompt_bufnr, map)
		end
		return true
	end
	return transformed
end

---@param picker Arduino-Nvim.Picker
---@param opts Arduino-Nvim.Picker.opts
function M.pick(picker, opts)
	if picker == "telescope" then
		require("telescope.pickers").new({}, totelescope(opts)):find()
	elseif picker == "snacks" then
		require("snacks.picker").pick(tosnacks(opts))
	end
end

return M
