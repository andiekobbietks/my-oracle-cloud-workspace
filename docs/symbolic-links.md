# Symbolic Links (symlinks)

What is a symlink?

A symbolic link (symlink) is a special filesystem entry that points to another file or directory by path. It acts like a lightweight pointer or shortcut.

Why use symlinks?
- Avoid duplicating content.
- Provide alternate or legacy paths to files after moving them.
- Let multiple locations reference a single canonical file.

Command examples

Create a symlink:

```bash
ln -s path/to/target path/to/symlink
```

Remove a symlink (only removes the link, not the target):

```bash
rm path/to/symlink
```

Symlink vs hard link
- Symlink: stores a pathname, can cross filesystems, can point to directories, can become dangling if the target is removed.
- Hard link: is an additional directory entry referencing the same inode; cannot usually point to directories or cross filesystems, and does not dangle while any link remains.

History

Links originated in early Unix. Hard links existed in the original Unix filesystems; symbolic (soft) links were introduced later (by the BSD/Unix community in the early 1980s) to provide more flexible redirection.

Gotchas and repo notes
- Symlinks can break if the target is moved or deleted.
- Git stores symlinks as the link path, not the target content. On platforms without symlink support (some Windows setups), behavior may differ.
- When moving documentation files in this repo, prefer copying then deleting (or `git mv` to preserve history). If you want to preserve the original path for compatibility, create a symlink at the old path pointing to the new file.

When to prefer a redirect file instead

If symlinks are not supported in your environment or by consuming tools, create a small Markdown redirect at the old location that points to the new file, for example:

```md
# Moved

This document was moved to `../README.md`. See the new location.
```
