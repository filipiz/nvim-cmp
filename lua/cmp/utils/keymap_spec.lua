local spec = require('cmp.utils.spec')
local api = require('cmp.utils.api')
local feedkeys = require('cmp.utils.feedkeys')

local keymap = require('cmp.utils.keymap')

describe('keymap', function()
  before_each(spec.before)

  it('t', function()
    for _, key in ipairs({
      '<F1>',
      '<C-a>',
      '<C-]>',
      '<C-[>',
      '<C-^>',
      '<C-@>',
      '<C-\\>',
      '<Tab>',
      '<S-Tab>',
      '<Plug>(example)',
      '<C-r>="abc"<CR>',
      '<Cmd>normal! ==<CR>',
    }) do
      assert.are.equal(keymap.t(key), vim.api.nvim_replace_termcodes(key, true, true, true))
      assert.are.equal(keymap.t(key .. key), vim.api.nvim_replace_termcodes(key .. key, true, true, true))
      assert.are.equal(keymap.t(key .. key .. key), vim.api.nvim_replace_termcodes(key .. key .. key, true, true, true))
    end
  end)

  it('to_keymap', function()
    assert.are.equal(keymap.to_keymap('\n'), '<CR>')
    assert.are.equal(keymap.to_keymap('<CR>'), '<CR>')
    assert.are.equal(keymap.to_keymap('|'), '<Bar>')
  end)

  describe('fallback', function()
    before_each(spec.before)

    local keys = function(keys, mode)
      local state = {}
      feedkeys.call(keys, mode, function()
        if api.is_cmdline_mode() then
          state.buffer = { api.get_current_line() }
        else
          state.buffer = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        end
        state.cursor = api.get_cursor()
        state.wildmenumode = vim.fn.wildmenumode() == 1
      end)
      feedkeys.call('', 'x')
      return state
    end

    it('recursive', function()
      vim.api.nvim_buf_set_keymap(0, 'i', '(', '()<Left>', {
        expr = false,
        noremap = false,
        silent = true,
      })
      local fallback = keymap.fallback(0, 'i', keymap.get_map('i', '('))
      local state = keys('i' .. fallback.keys, fallback.noremap and 'n' or 'm')
      assert.are.same({ '()' }, state.buffer)
      assert.are.same({ 1, 1 }, state.cursor)
    end)

    it('recursive expr', function()
      vim.api.nvim_buf_set_keymap(0, 'i', '(', '"()<Left>"', {
        expr = true,
        noremap = false,
        silent = true,
      })
      local fallback = keymap.fallback(0, 'i', keymap.get_map('i', '('))
      local state = keys('i' .. fallback.keys, fallback.noremap and 'n' or 'm')
      assert.are.same({ '()' }, state.buffer)
      assert.are.same({ 1, 1 }, state.cursor)
    end)

    it('recursive callback', function()
      vim.api.nvim_buf_set_keymap(0, 'i', '(', '', {
        expr = true,
        noremap = false,
        silent = true,
        callback = function()
          return keymap.t('()<Left>')
        end,
      })
      local fallback = keymap.fallback(0, 'i', keymap.get_map('i', '('))
      local state = keys('i' .. fallback.keys, fallback.noremap and 'n' or 'm')
      assert.are.same({ '()' }, state.buffer)
      assert.are.same({ 1, 1 }, state.cursor)
    end)
  end)

  describe('realworld', function()
    before_each(spec.before)
    it('#226', function()
      keymap.listen('i', '<c-n>', function(_, fallback)
        fallback()
      end)
      vim.api.nvim_feedkeys(keymap.t('iaiueo<CR>a<C-n><C-n>'), 'tx', true)
      assert.are.same({ 'aiueo', 'aiueo' }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)
    it('#414', function()
      keymap.listen('i', '<M-j>', function()
        vim.api.nvim_feedkeys(keymap.t('<C-n>'), 'int', true)
      end)
      vim.api.nvim_feedkeys(keymap.t('iaiueo<CR>a<M-j><M-j>'), 'tx', true)
      assert.are.same({ 'aiueo', 'aiueo' }, vim.api.nvim_buf_get_lines(0, 0, -1, true))
    end)
  end)
end)
