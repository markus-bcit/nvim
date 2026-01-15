require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
-- Added 
vim.keymap.set({"n", "v"}, "<leader>rq", ":DB mysql://markus:P%40ssw0rd@127.0.0.1:3306<CR>", { desc = "Run Query on MySQL" })
