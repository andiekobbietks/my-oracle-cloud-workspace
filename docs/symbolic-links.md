# Symbolic Links (symlinks)

What is a symlink?

A symbolic link (symlink) is a special filesystem entry that points to another file or directory by path. It acts like a lightweight pointer or shortcut.


Why use symlinks?

- **Avoid duplicating content.**
	- *Scenario:* Suppose you have a shared setup script or onboarding guide that is relevant to multiple teams or environments. Instead of copying the same file into several locations (which leads to maintenance headaches and version drift), you can place the canonical file in one location and create symlinks elsewhere. This ensures all references always point to the latest version, and updates only need to be made in one place.

- **Provide alternate or legacy paths to files after moving them.**
	- *Scenario:* If you reorganize your documentation and move `docs/old-guide.md` to `docs/guides/new-guide.md`, any scripts, bookmarks, or external links pointing to the old path will break. By placing a symlink at `docs/old-guide.md` pointing to the new location, you preserve backward compatibility. This is especially useful for CI/CD scripts, automation, or users who may not immediately update their references.

- **Let multiple locations reference a single canonical file.**
	- *Scenario:* Sometimes, a file (like a license, code of conduct, or shared configuration) is relevant in several subdirectories (e.g., both in the project root and inside a submodule or template folder). Rather than maintaining separate copies, you can symlink from the subdirectory to the canonical file. This ensures consistency and reduces the risk of outdated or conflicting versions.

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

## Purpose in this project

This project includes a relocation skill (`.github/skills/relocate-file/SKILL.md`) that automates moving documentation and other files. When files are moved, symlinks can be used to preserve compatibility for scripts, tools, or users expecting the old path. The skill offers options to create symlinks or Markdown redirect files at the old location, ensuring discoverability and preventing broken links after refactoring.

- Use symlinks when you want the old path to transparently point to the new file.
- Use redirect files if symlinks are unsupported or for environments (like Windows) where symlinks may not work reliably.

This doc explains the rationale, commands, and best practices for using symlinks in this repo, especially when relocating docs or onboarding files.

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
