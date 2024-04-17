# first.nvim

* Jump to the next/previous word on the line that starts with the given character
* Continue jumping to the next/previous word that starts with the given character
* Can be used as a replacement for `f` and `F`
* Also supports deleting or changing motions

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
 function my_func(|m|y_type y) {    dfy             function my_func(|y|) {
 function my_func(my_type |y|) {    dFm             function |y|) {
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
            use_default_keymap = true   --set to false if you do not want to override f, F, ; and ,
            use_delete_and_change = true,  --create remaps for df, cf, dF and dF
            inclusive_forward_delete = false,  --delete first character of searched word?
            inclusive_backward_delete = true,  --delete first character of searched word?
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
-- kemaps below replace native f and F in dfc or dFc
vim.keymap.set("n", "d", "<cmd>lua require('first').delete_until()<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "c", "<cmd>lua require('first').change_until()<cr>", { noremap = true, silent = true })
```

These are the keybinds set by `use_default_keymap = true`.
