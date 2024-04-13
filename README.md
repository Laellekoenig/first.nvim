# first.nvim

* Jump to the next/previous word on the line that starts with the given character
* Continue jumping to the next/previous word that starts with the given character
* Can be used as a replacement for `f` and `F`

## Usage

The cursor is represented by | |.
```
 Old position                       Keys pressed    New position
--------------------------------------------------------------------------------------
 fu|n|ction my_func(my_type y) {    fy              function my_func(my_type |y|) {
 |f|unction my_func(my_type y) {    fm              function |m|y_func(my_type y) {
 |f|unction my_func(my_type y) {    fm;             function my_func(|m|y_type y) {
 |f|unction my_func(my_type y) {    fm;,            function |m|y_func(my_type y) {
 function my_func(my_ty|p|e y) {    Ff              function my_|f|unc(my_type y) {
 function my_func(my_ty|p|e y) {    Ff;             |f|unction my_func(my_type y) {
 function my_func(my_ty|p|e y) {    Fy              function my_func(my_ty|p|e y) {
```

The plugin does not have to be used as a replacement for `f`, `F`, `;` and `,`.

It is also possible to remap the functions `jump_to_next`, `jump_to_prev`, 
`continue_jump_to_next` and `continue_jump_to_prev` to custom keys.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "Laellekoenig/first.nvim",
    config = function()
        require("first").setup({
            use_default_keymap = true  -- set to false if you do not want to override f, F, ; and ,
        })
    end
}
```

If you use `;` or `,` for other purposes, do not use the default keymaps.

### Customize Keybindings
```lua
vim.keymap.set("n", "f", "<cmd>lua require('first').jump_to_next()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "F", "<cmd>lua require('first').jump_to_prev()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", ";", "<cmd>lua require('first').goto_next()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", ",", "<cmd>lua require('first').goto_prev()<cr>", { noremap = true, silent = true })
```

These are the keybinds set by `use_default_keymap = true`.
