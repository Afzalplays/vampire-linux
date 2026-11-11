# Vampire Files — console file manager

Run `vfiles` to open the keyboard-driven file manager. It supports directory
navigation, listing, creating files/directories, copying, moving, editing
regular files, and deleting files or empty directories after confirmation.

It deliberately refuses recursive directory deletion. Copy and move operations
use quoted paths and do not invoke a shell to interpret user-entered filenames.

This is a console utility, not the planned graphical Vampire Files application.
