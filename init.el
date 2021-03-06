;; -*- lexical-binding: t -*-
;; Uses Outline-Minor-Mode
;; C-c @ C-c or zo (Evil mode) - Hide entry
;; C-c @ C-e or zc (Evil mode) - Show entry

;;; Package Configuration
  (require 'package) ;; Add package repos
    (setq package-archives
    '(("melpa" . "https://melpa.org/packages/")
      ("nongnu-elpa" . "https://elpa.nongnu.org/nongnu/")
      ("elpa" . "https://elpa.gnu.org/packages/")))
    (package-initialize) ;; Initialize package.el
    (unless package-archive-contents ;; Auto download package archive repository manifest if not present
      (package-refresh-contents))

;;; Use-Package Configuration
  (unless (package-installed-p 'use-package) ;; Download use-package if not present
    (package-install 'use-package))
  (eval-when-compile ;; Use use-package to manage packages
    (require 'use-package))
  (require 'use-package)
    (setq use-package-always-ensure t) ;; Always download packages that are marked under use-package if they aren't installed
    (setq use-package-always-defer t) ;; Always defer package loading. If absolutely necessary use :demand to override

;;; Native Comp
  (when (and (fboundp 'native-comp-available-p) (native-comp-available-p))
    (progn
      (setq-default native-comp-async-report-warnings-errors nil)
      (setq-default comp-deferred-compilation t)
      (setq-default native-comp-speed 2)
      (add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" user-emacs-directory))
      (setq package-native-compile t)))

;;; Load Custom Files
  (add-to-list 'load-path (expand-file-name "~/.emacs.d/Custom")) ;; The directory that my custom files are kept in
  (load "functions") ;; Load functions
  (load "skeletons") ;; Skeletons

;;; Evil Mode and Evil Mode Extras
  (use-package evil ;; Vim keybindings
    :hook (after-init . evil-mode)
    :init
      (setq evil-want-keybinding nil) ;; Needed to use evil-collection
      (setq evil-insert-state-message nil) ;; Remove INSERT message from minibuffer
    :bind (
      :map evil-normal-state-map
        ("<leader>bl" . list-buffers)
        ("<leader>bd" . kill-this-buffer)
        ("<leader>bg" . switch-to-buffer)
        ("]q" . next-error)
        ("[q" . previous-error)
        ("]b" . next-buffer)
        ("[b" . previous-buffer)
        ("<leader>f" . lgrep)
        ("K" . eldoc)
        ("gd" . xref-find-definitions)
        ("gr" . xref-find-references)
      )
    :config
      (evil-set-undo-system 'undo-tree)
      (evil-set-leader 'normal (kbd "\\"))
      (eval-after-load 'evil-ex
          '(evil-ex-define-cmd "find" 'find-file))
      (eval-after-load 'evil-ex
          '(evil-ex-define-cmd "browse-old" 'recentf-open-files))
      (eval-after-load 'evil-ex
          '(evil-ex-define-cmd "Files" 'project-find-file))
      (eval-after-load 'evil-ex
          '(evil-ex-define-cmd "Term" 'gh/open-ansi-term-in-split))
  )

  (use-package evil-collection ;; Extend default evil mode keybindings to more modes
    :after evil
    :init
      (evil-collection-init)
    :config
      (setq-default evil-collection-company-use-tng nil) ;; Don't autocomplete like vim
  )

  (use-package evil-surround ;; Port of vim-surround to Evil
    :after evil
    :init
      (global-evil-surround-mode 1)
  )

  (use-package evil-commentary ;; Port of vim-commentary to Evil
    :after evil
    :init
      (evil-commentary-mode)
  )

  (use-package undo-tree ;; Undo tree to enable redoing with Evil
    :after evil
    :init
      (global-undo-tree-mode t)
  )

;;; Theme
  (use-package modus-themes ;; High contrast themes
    :hook (prog-mode . (lambda () (gh/custom-theme-faces)))
    :init
      (setq modus-themes-operandi-color-overrides '(list (bg-main . "#d7d7d7")))
      (custom-set-faces
       '(hl-line ((t (:background "#cbcbcb"))))
       '(corfu-default ((t (:background "#e9e9e9"))))
       '(completions-common-part ((t (:foreground "#004850" :background "#8eecf4"))))
       '(completions-first-difference ((t (:foreground "#000000" :background "#d5baff" :inherit bold)))))
      (setq modus-themes-paren-match '(bold underline)
          modus-themes-bold-constructs t
          modus-themes-italic-constructs t
          modus-themes-lang-checkers '(straight-underline)
          modus-themes-subtle-line-numbers t)
      (load-theme 'modus-operandi t)
  )

;;; In-Buffer Text Completion
  (use-package corfu ;; In buffer text completion
    :hook ((prog-mode . corfu-mode)
           (shell-mode . corfu-mode)
           (eshell-mode . corfu-mode)
           (term-mode . corfu-mode))
    :custom
      (corfu-cycle t)
      (corfu-auto t)
      (corfu-quit-at-boundary t)
      (corfu-quit-no-match t)
      (corfu-echo-documentation t)
      (corfu-preselect-first nil)
    :bind (:map corfu-map
            ("TAB" . corfu-next)
            ([tab] . corfu-next)
            ("S-TAB" . corfu-previous)
            ([backtab] . corfu-previous)
    )
  )

;;; Eglot Mode
  (use-package eglot ;; Minimal LSP client
    :hook (((c-mode c++-mode objc-mode) . (lambda () (when (executable-find "clangd") (eglot-ensure))))
           (python-mode . (lambda () (when (executable-find "pylsp") (eglot-ensure))))
           (rust-mode . (lambda () (when (executable-find "rls") (eglot-ensure))))
           (haskell-mode . (lambda () (when (executable-find "haskell-language-server") (eglot-ensure))))
           (go-mode . (lambda () (when (executable-find "gopls") (eglot-ensure))))
           (java-mode . (lambda () (when (executable-find "jdtls") (eglot-ensure))))
           (javascript-mode . (lambda () (when (executable-find "typescript-language-server" (eglot-ensure)))))
           (eglot-managed-mode . (lambda () (gh/eglot-eldoc-toggle-order+)))) ;; Priortize errors over eldoc
    :bind (:map evil-normal-state-map
                ("gi" . eglot-find-implementation)
                ("gy" . eglot-find-typeDefinition)
                ("C-=" . gh/eglot-eldoc-toggle-order+))
    :config
      (setq eglot-ignored-server-capabilities '(list :documentHighlightProvider))
      (add-to-list 'eglot-server-programs
                `(java-mode "jdtls" "-configuration" ,(expand-file-name "~/.cache/jdtls") "-data" ,(expand-file-name "~/eclipse-workspace")))
      (cl-defmethod eglot-execute-command
          (_server (_cmd (eql java.apply.workspaceEdit)) arguments)
          "Eclipse JDT breaks spec and replies with edits as arguments."
          (mapc #'eglot--apply-workspace-edit arguments))
  )

;;; Eldoc Mode
  (use-package eldoc ;; Built-in documentation mode
    :config
      (setq eldoc-echo-area-use-multiline-p nil)
      (setq eldoc-echo-area-display-truncation-message nil)
      (setq eldoc-echo-area-prefer-doc-buffer t)
  )

;;; Minibuffer Completion etc.
  (use-package minibuffer
    :ensure nil
    :hook (minibuffer-setup-hook . cursor-intangible-mode)
    :config
      ;; Make cursor intangible in minibuffer
      (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  )

  (use-package vertico ;; Fast, lightweight, and improved minibuffer completion system
    :hook ((after-init . vertico-mode))
    :config
      (setq vertico-cycle t)
  )

  (use-package marginalia ;; Documentation in the minibuffer
    :init
      (marginalia-mode)
  )

  (use-package orderless ;; Allow for space delimeted searching
    :init
       (setq completion-styles '(substring initials flex partial-completion orderless))
       (setq completion-category-overrides '((file (styles . (partial-completion orderless)))))
       (setq completion-ignore-case t)
  )

;;; Which-Key Mode
  (use-package which-key ;; Show possible keybindings when you pause a keycord
    :defer 5
    :hook ((after-init . which-key-mode))
  )

;;; Hydra
  (use-package hydra ;; Beautiful, practical custom keybind menus
    :bind (("C-c o r" . hydra-org-roam/body)
           ("C-c p" . hydra-project/body)
           ("C-c l" . hydra-eglot/body))
  )

;;; Avy
  (use-package avy ;; Quickly jump to visible location
    :after evil
    :bind (:map evil-normal-state-map
                ("s" . avy-goto-char-2)
                ("gl" . avy-goto-line))
  )

;;; Flycheck Mode
  (use-package flycheck ;; Improved linting and checking
    :hook ((prog-mode . flycheck-mode))
    :bind-keymap ("C-c f" . flycheck-command-map)
    :config
      (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc)) ;; Stop flycheck from treating init.el as package file
  )

;;; Project Management
  (use-package project ;; Built-in project managment package
    :ensure nil
    :config
      (when (file-directory-p "~/dev")
        (eval-after-load 'project (project-remember-projects-under "~/dev" t))
      )
  )

;;; Version Control
  (use-package magit ;; Git managment within Emacs (Very slow on Windows)
    :bind-keymap ("C-c m" . magit-mode-map)
  )

;;; Org Mode Et Al.
  (use-package org ;; Powerful plain text note taking and more
    :hook ((org-mode . visual-line-mode)
           (org-mode . flyspell-mode)
           (org-mode . font-lock-mode)
           (org-mode . org-cdlatex-mode)
           (org-mode . org-fragtog-mode)
           (org-mode . org-appear-mode)
           (org-mode . gh/org-add-electric-pairs))
    :bind-keymap ("C-c o o" . org-mode-map)
    :init
      (with-eval-after-load "org"
        (define-abbrev org-mode-abbrev-table "asrc" "" 'org-src-block))
    :config
      (setq org-src-fontify-natively t
        org-startup-with-inline-images t
        org-hide-emphasis-markers t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-hide-block-startup nil
        org-src-preserve-indentation nil
        org-cycle-separator-lines 2
        org-startup-with-latex-preview t
        org-startup-indented t
        org-return-follows-link t)
      (plist-put org-format-latex-options :scale 1.5) ;; Increase size of latex previews
      (org-babel-do-load-languages 'org-babel-load-languages ;; Set the langs. to load for org src blocks
                                   (append org-babel-load-languages
                                           '((C . t)
                                             (haskell . t))))
      (if (executable-find "latexmk") ;; Set the command for org -> latex -> pdf
        (setq-default org-latex-pdf-process '("latexmk -output-directory=%o -pdflatex='pdflatex -interaction nonstopmode' -pdf -bibtex -f %f")))
      (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
      (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)
      (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
      (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup)
      (evil-define-key '(normal) org-mode-map (kbd "RET") 'org-return)
  )

  (use-package org-agenda ;; Powerful TODO list and agenda tracking
    :ensure nil
    :after org
    :bind-keymap ("C-c o a" . org-agenda-mode-map)
    :config
      (setq org-agenda-files (directory-files-recursively (expand-file-name "~/org/org-agenda") "\\.org$")) ;; Add all .org files in folder to org agenda list
      (setq org-log-done 'time) ;; Auto mark time when TODO item is marked done
  )

  (use-package org-roam ;; Add powerful non-hierarchical note taking tools to Org
    :init
      (setq org-roam-v2-ack t)
    :config
      (setq org-roam-directory (file-truename "~/org/org-roam"))
      (setq org-roam-completion-everywhere t)
      (setq org-roam-node-display-template "${title:*} ${tags:50}")
      (org-roam-db-autosync-enable)
      (setq org-roam-capture-templates
       '(
         ("d" "default" plain
           "%?"
           :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+author: Greg Heiman\n#+date: %U\n#+filetags: ")
           :unnarrowed t)
         )
      )
  )

  (use-package org-fragtog ;; Auto toggle org latex previews
    :after org
  )

  (use-package org-appear ;; Auto toggle all auto hidden org elements
    :after org
    :config
      (setq org-appear-autosubmarkers t
            org-appear-autoentities t
            org-appear-autokeywords t)
  )

;;; Flyspell Mode
  (use-package flyspell ;; Builtin spell checking
    :ensure nil
    :config
      (if (executable-find "aspell") ;; Use aspell if available
        (setq ispell-program-name "aspell"))
  )

;;; Outline-Minor-Mode
  (use-package outline ;; Minor mode that allows for folding code
    :ensure nil
    :hook ((emacs-lisp-mode . outline-minor-mode)
            (outline-minor-mode . outline-hide-body))
    :config
      (setq outline-blank-line t) ;; Have a blank line before a heading
  )

;;; Eshell Mode
  (use-package eshell ;; Emacs lisp shell
    :ensure nil
    :config
      (setq-default eshell-prompt-function 'gh/eshell-prompt)
      (setq-default eshell-highlight-prompt nil)
  )

;;; Gnus
  (use-package gnus ;; Builtin Emacs news reader that can be configured for email
    :ensure nil
    :config
      (setq gnus-select-method '(nnnil nil))
      (setq gnus-secondary-select-methods
      '((nnimap "gregheiman02@gmail.com"
                (nnimap-address "imap.gmail.com")
                (nnimap-server-port 993)
                (nnimap-stream ssl)
                (nnir-search-engine imap)
                (nnmail-expiry-target "nnimap+gregheiman02@gmail.com:[Gmail]/Trash")
                (nnmail-expiry-wait 'immediate))
        (nnimap "w459e964@wichita.edu"
                (nnimap-address "outlook.office365.com")
                (nnimap-server-port 993)
                (nnimap-stream ssl)
                (nnir-search-engine imap)
                (nnmail-expiry-target "nnimap+w459e964@wichita.edu:Trash")
                (nnmail-expiry-wait 'immediate))))
      (setq gnus-ignored-newsgroups "^to\\.\\|^[0-9. ]+\\( \\|$\\)\\|^[\"]\"[#'()]") ;; Make gnus NOT ignore [Gmail] folders
      (setq gnus-posting-styles ;; Correct way to set up responding to emails with the correct email
            '((".*" ;; Matches all groups of messages
               (address "Greg Heiman <gregheiman02@gmail.com>")
               ("X-Message-SMTP-Method" "smtp smtp.gmail.com 587 gregheiman02@gmail.com"))
              ("w459e964@wichita.edu" ;; Matches Gnus group called w459e964@wichita.edu
               (address "Greg Heiman <w459e964@wichita.edu")
               (organization "Wichita State University")
               ("X-Message-SMTP-Method" "smtp smtp.office365.com 587 w459e964@wichita.edu"))
              )
      )
  )

;;; Emacs Configuration
 (use-package emacs
   :ensure nil
   :hook ((emacs-startup . efs/display-startup-time)
          (auto-save . gh/full-auto-save))
   :config
     ;; Set information about ourselves
     (setq user-mail-address "gregheiman02@gmail.com"
           user-full-name "Greg Heiman")
     ;; Font configuration
     (set-face-attribute 'default nil :font "JetBrains Mono 11" ) ;; Set font options
     (set-frame-font "JetBrains Mono 11" nil t)

     ;; Add to the interface
     (global-hl-line-mode 1) ;; Highlight the current line
     (column-number-mode t) ;; Show column numbers in modeline
     (show-paren-mode t) ;; Highlight matching delimeter pair
     (setq-default show-paren-style 'parenthesis)
     (add-to-list 'initial-frame-alist '(fullscreen . maximized)) ;; Start emacs fullscreen and maximized

     ;; Bring Emacs into the 21st century
     (recentf-mode 1) ;; Keep a list of recently opened files
     (delete-selection-mode t) ;; Whatever is highlighted will be replaced with whatever is typed or pasted
     (electric-pair-mode 1) ;; Auto pair delimeters
     (auto-save-visited-mode) ;; Auto save files without the #filename#
     (when (string-equal system-type "gnu/linux")
       (setq exec-path (append exec-path '("~/.local/bin") '("~/.cargo/bin"))))

     ;; Indent configuration
     (setq-default indent-tabs-mode nil) ;; Use spaces for tabs instead of tab characters
     (setq tab-width 4) ;; Set the tab width to 4 characters
     (setq electric-indent-inhibit t) ;; Make return key indent to current indent level
     (setq backward-delete-char-untabify-method 'hungry) ;; Have Emacs backspace the entire tab at a time

     ;; Personal preference
     (set-default 'truncate-lines t) ;; Disable wrapping of lines
     (setq read-process-output-max (* 1024 1024)) ;; 1MB
     (defalias 'yes-or-no-p 'y-or-n-p) ;; Mad efficiency gains
     (setq custom-file (make-temp-file "emacs-custom-")) ;; Closest thing to disabling custom
     (setq compilation-scroll-output t) ;; Auto scroll to bottom of compilation buffer

     ;; Set default line endings and encoding
     (set-default-coding-systems 'utf-8-unix)
     (set-locale-environment "en_US.UTF-8")
     (setq buffer-file-coding-system 'utf-8-unix)
     (setq default-file-name-coding-system 'utf-8-unix)
     (setq default-keyboard-coding-system 'utf-8-unix)
     (setq default-process-coding-system '(utf-8-unix . utf-8-unix))
     (setq default-sendmail-coding-system 'utf-8-unix)
     (setq default-terminal-coding-system 'utf-8-unix)

     ;; Version control settings
     (setq vc-follow-symlinks t) ;; Don't prompt to follow symlinks
     (setq auto-revert-check-vc-info t) ;; Auto revert vc

     ;; Auto revert files
     (global-auto-revert-mode 1) ;; Auto update when files change on disk
     (setq auto-revert-verbose nil) ;; Be quite about updating files when they're changed on disk

     ;; Auto follow vc symlinks and auto-revert vc changes
     (setq vc-follow-symlinks t) ;; Don't prompt to follow symlinks
     (setq auto-revert-check-vc-info t) ;; Auto revert vc

     ;; Don't show commands that aren't valid with current modes (Only in Emacs > 28)
     (if (not (version< emacs-version "28"))
         (setq read-extended-command-predicate #'command-completion-default-include-p))

     ;; Set the bell to flash the modeline rather than audio or standard visual bell
     (setq ring-bell-function
      (lambda ()
        (let ((orig-fg (face-foreground 'mode-line)))
          (set-face-foreground 'mode-line "#F2804F")
          (run-with-idle-timer 0.1 nil
                               (lambda (fg) (set-face-foreground 'mode-line fg))
                               orig-fg))))

     ;; Scrolling configuration
     (setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
     (setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
     (setq scroll-step 1) ;; keyboard scroll one line at a time
     (setq mouse-wheel-scroll-amount '(5)) ;; mouse wheel scroll 5 lines at a time

     ;; Backup file configuration
     (setq backup-directory-alist '(("." . "~/.emacs.d/backup")) ;; Write backups to ~/.emacs.d/backup/
         backup-by-copying      t  ; Don't de-link hard links
         version-control        t  ; Use version numbers on backups
         delete-old-versions    t  ; Automatically delete excess backups:
         kept-new-versions      5 ; how many of the newest versions to keep
         kept-old-versions      2) ; and how many of the old
  )

;;; Line Numbers
  (use-package display-line-numbers
    ;; Display line numbers for some modes
    :hook ((text-mode . display-line-numbers-mode)
           (prog-mode . display-line-numbers-mode)
           (conf-mode . display-line-numbers-mode)
           (org-mode . display-line-numbers-mode))
  )

;;; Whitespace Mode
  (use-package whitespace ;; Highlight various whitespaces in files
    :ensure nil
    :hook ((prog-mode . whitespace-mode))
    :config
      ;; Highlight lines longer than 80 chars. and trailing spaces
      (setq whitespace-style '(face trailing lines-tail))
      (setq whitespace-line-column 80)
  )

;;; Modeline Configuration
  (use-package modeline ;; The status line at the bottom of the screen
    :ensure nil
    :init
      (setq-default mode-line-format
          '((:eval (gh/simple-mode-line-render
                      ;; left
                      (format-mode-line
                       (list
                        " "
                        '(:eval (propertize (format "<%s>" (upcase (substring (symbol-name evil-state) 0 1))))) ;; Evil mode
                        '(vc-mode vc-mode)
                        '(:eval (propertize (format " %s" "%b")))
                        '(:eval (propertize (format " %s " "[%*]")))
                        ))
                      ;; right
                       (format-mode-line
                        (list
                         '(:eval (propertize (format "[%s] " (gh/flycheck-indicator))))
                         '(:eval (propertize (format "%s" (upcase (symbol-name buffer-file-coding-system)))))
                         '(:eval (propertize (format " %s " "%m")))
                         '(:eval (propertize (format "%s/%s:%s " "%l" (line-number-at-pos (point-max)) "%c")))
                         ))
                      ))))
  )

;;; Dired Configuration
  (use-package dired ;; Builtin file manager
    :ensure nil
    :hook (dired-mode . (lambda()
                          (auto-revert-mode 1) ;; Automatically update Dired
                          (setq auto-revert-verbose nil))) ;; Be quiet about updating Dired
    :bind-keymap ("C-c d" . dired-mode-map)
    :bind (:map dired-mode-map
             ("C-c d v" . 'gh/dired-preview-file)
    )
  )

;;; Grep Configuration
  (use-package grep
    :ensure nil
    :config
      (if (executable-find "rg")
          (setq grep-template "rg -n -H --no-heading -g <F> -e <R> .")
          (setq grep-use-null-device nil)
      )
  )

;;; Tags Configuration
  (use-package etags
    :ensure nil
    :config
      (setq tags-revert-without-query t) ;; Don't ask before rereading the TAGS files if they have changed
      (setq tags-add-tables nil) ;; Don't ask to keep current list of tags tables also
  )

;;; Abbrev, and Skeleton Modes
  (use-package abbrev ;; In buffer snippets
    :ensure nil
    :hook ((c-mode . abbrev-mode)
           (c++-mode . abbrev-mode)
           (java-mode . abbrev-mode)
           (org-mode . abbrev-mode))
    :config
      (setq save-abbrevs nil)
  )

  (use-package skeleton ;; Skeletons for new files and code structures
    :ensure nil
    :init
      (setq skeleton-end-hook nil)
      (setq skeleton-further-elements '((abbrev-mode nil)))
  )

;;; Markdown Configuration
  (use-package markdown-mode
    :hook ((markdown-mode . flyspell-mode))
    :config
      (if (executable-find "pandoc") ;; Set pandoc as the program that gets called when you issue a markdown command
        (setq markdown-command "pandoc"))
  )

;;; Java Configuration
  (use-package java-mode
    :ensure nil
    :hook (java-mode . gh/java-mode-configuration)
    :init
      (define-auto-insert '(java-mode . "Java Class Skeleton") 'java-class-skeleton)
      (with-eval-after-load "cc-mode"
        (define-abbrev java-mode-abbrev-table "aif" "" 'java-if-statement)
        (define-abbrev java-mode-abbrev-table "aelif" "" 'java-elif-statement)
        (define-abbrev java-mode-abbrev-table "aelse" "" 'java-else-statement)
        (define-abbrev java-mode-abbrev-table "amain" "" 'java-main-function))
  )

;;; C Configuration
  (use-package c-mode
    :ensure nil
    :hook (c-mode . gh/c-mode-configuration)
    :init
      (with-eval-after-load "cc-mode"
        (define-abbrev c-mode-abbrev-table "aif" "" 'c-if-statement)
        (define-abbrev c-mode-abbrev-table "aelif" "" 'c-elif-statement)
        (define-abbrev c-mode-abbrev-table "aelse" "" 'c-else-statement)
        (define-abbrev c-mode-abbrev-table "amain" "" 'c-main-function))
  )

  (use-package c++-mode
    :ensure nil
    :hook (c++-mode . gh/c-mode-configuration)
    :init
      (with-eval-after-load "cc-mode"
        (define-abbrev c++-mode-abbrev-table "aif" "" 'c-if-statement)
        (define-abbrev c++-mode-abbrev-table "aelif" "" 'c-elif-statement)
        (define-abbrev c++-mode-abbrev-table "aelse" "" 'c-else-statement)
        (define-abbrev c++-mode-abbrev-table "amain" "" 'c-main-function))
  )

  (use-package objc-mode
    :ensure nil
    :hook (objc-mode . gh/c-mode-configuration)
  )

;;; Elisp Configuration
  (use-package elisp-mode
    :ensure nil
    :hook (elisp-mode . gh/elisp-mode-configuration)
  )

;;; Emacs Keybindings
    (global-set-key (kbd "<escape>") 'keyboard-escape-quit) ;; Make ESC quit prompts
