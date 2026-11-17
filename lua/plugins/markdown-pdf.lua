local function export_markdown_to_pdf()
  local file = vim.fn.expand("%:p")
  if file == "" or vim.bo.filetype ~= "markdown" then
    vim.notify("Please open a Markdown file to export.", vim.log.levels.WARN, { title = "Markdown Export" })
    return
  end

  -- Save current buffer before exporting
  vim.cmd("silent write")
  local pdf_file = vim.fn.expand("%:p:r") .. ".pdf"
  local filename = vim.fn.expand("%:t:r") .. ".pdf"

  vim.notify("Exporting " .. filename .. " (Letter size)...", vim.log.levels.INFO, { title = "Markdown Export" })

  local pdf_options = vim.json.encode({
    format = "Letter",
    margin = {
      top = "20mm",
      right = "20mm",
      bottom = "20mm",
      left = "20mm",
    },
  })

  vim.system({ "npx", "--yes", "md-to-pdf", file, "--pdf-options", pdf_options }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify("Successfully exported:\n" .. pdf_file, vim.log.levels.INFO, { title = "Markdown Export" })
      else
        vim.notify("PDF export failed:\n" .. (obj.stderr or obj.stdout or "Unknown error"), vim.log.levels.ERROR, { title = "Markdown Export" })
      end
    end)
  end)
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>ce",
        export_markdown_to_pdf,
        desc = "Export Markdown to PDF (Letter)",
        ft = "markdown",
      },
      {
        "<leader>cr",
        export_markdown_to_pdf,
        desc = "Export Markdown to PDF (Letter)",
        ft = "markdown",
      },
    },
  },
}
