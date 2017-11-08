;; 20171031 init.el: a refactor of .emacs using use-package

;;; Load package.el and use-package
(require 'package)
(setq package-enable-at-startup nil)
;;; Add MELPA
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
;; Add ELPA: important compatibility libraries like cl-lib
(when (< emacs-major-version 24)
  (add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

;;; Auto-install use-package if not already existing
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'bind-key)

;;; Load themes
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
(add-to-list 'custom-theme-load-path "~/.emacs.d/manuallyloadedpackages")
(use-package zenburn-theme
             :ensure t
             :init (load-theme 'zenburn t))

;;; Set font and relevant things
(add-to-list 'default-frame-alist
             '(font . "Courier-14"))
(setq-default line-spacing 5) ;; line spacing
(global-subword-mode 1) ;; make cursor movement stop in between camelCase words.
(delete-selection-mode 1) ;; typing deletes/overwrites selected text

;; Turn off the splash screen
(setq inhibit-splash-screen t
      initial-scratch-message nil
      initial-major-mode 'org-mode)

(setq-default indicate-empty-lines t)
(when (not indicate-empty-lines)
  (toggle-indicate-empty-lines))

;; Set y=yes and n=no
(defalias 'yes-or-no-p 'y-or-n-p)

;; Turn down the time to echo keystrokes, use a visual indicator instead of making horrible noises, always highlight parentheses.
(setq echo-keystrokes 0.1
      use-dialog-box nil
      visible-bell t)
(show-paren-mode t)

;; Display line numbers
(global-linum-mode t)

;; Wrap by word (better for prose)
(global-visual-line-mode t)

;; Set "command" key as meta, and save "option" key for special character input
(setq mac-command-modifier 'meta)
(setq mac-option-modifier nil)

;; Disable toolbar
(tool-bar-mode -1)

;; Enable mouse support
(unless window-system
  (require 'mouse)
  (xterm-mouse-mode t)
  (global-set-key [mouse-4] (lambda ()
                              (interactive)
                              (scroll-down 1)))
  (global-set-key [mouse-5] (lambda ()
                              (interactive)
                              (scroll-up 1)))
  (defun track-mouse (e))
  (setq mouse-sel-mode t)
)

;; save desktop session
(desktop-save-mode 1)
(desktop-load-default)
(desktop-read)

;; auto close bracket insertion. New in emacs 24
(electric-pair-mode 1)

;; Tab indentation
(setq default-tab-width 4)
(setq-default indent-tabs-mode nil) ;; indent with spaces, never with tabs

;; "C-c n" creates a new empty buffer called "untitled"
(defun untitled-new-buffer-frame ()
  "Create a new frame with a new empty buffer."
  (interactive)
  (let ((buffer (generate-new-buffer "untitled")))
    (set-buffer-major-mode buffer)
    (display-buffer buffer '(display-buffer-pop-up-frame . nil))))
(global-set-key (kbd "C-c n") #'untitled-new-buffer-frame)

;; Dired on OS X
(when (string= system-type "darwin")       
  (setq dired-use-ls-dired nil))

;; Powerline
(use-package powerline
             :ensure t
             :config (powerline-default-theme))

;; helm
(use-package helm
             :ensure t
             :demand t
             :commands(helm-execute-persistent-action helm-select-action)
             :init
             (unbind-key "C-x c") ; unbinds the default helm-command-prefix. Must set "C-c h" globally: cannot change helm-command-prefix-key after helm-config is loaded
             :bind (
                    ("C-c h" . helm-command-prefix)
                    ("C-c h /" . helm-find)
                    ("C-c h i" . helm-semantic-or-imenu)
                    ("C-c h l" . helm-locate)
                    ("C-c h m" . helm-man-woman)
                    ("C-c h o" . helm-occur)
                    ("C-x C-f" . helm-find-files)
                    ("C-x b" . helm-mini)
                    ("M-x" . helm-M-x)
                    ("M-y" . helm-show-kill-ring)
                    ("C-h SPC" . helm-all-mark-rings)
                    ("C-c h g" . helm-google-suggest)
                    )
             :config
             (require 'helm-config)
             (helm-mode 1)
             (bind-key "<tab>" 'helm-execute-persistent-action helm-map)
             (bind-key "C-i" 'helm-execute-persistent-action helm-map) ; make TAB work in terminal
             (bind-key "C-z" 'helm-select-action helm-map)
             (helm-autoresize-mode 1)
             (when (executable-find "curl")
               (setq helm-google-suggest-use-curl-p t))
             (setq helm-split-window-in-side-p           t ; open helm buffer inside current window, not occupy whole other window
                   helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
                   helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
                   helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
                   helm-ff-file-name-history-use-recentf t
                   helm-echo-input-in-header-line t
                   helm-M-x-fuzzy-match t ; optional fuzzy matching for helm-M-x)
                   helm-autoresize-max-height 0
                   helm-autoresize-min-height 20
                   helm-buffers-fuzzy-matching t
                   helm-imenu-fuzzy-match    t
                   helm-apropos-fuzzy-match t     
                   )
             )

(use-package projectile
             :ensure t
             :demand t
             :init
             (projectile-global-mode)
             :config
             (setq helm-projectile-fuzzy-match nil)
             )
(use-package helm-projectile
             :ensure t
             :demand t
             :init
             (helm-projectile-on)
             )

(use-package org
             :ensure t
             :demand t
             
             :bind (
                    ("C-c l" . org-store-link)
                    ("C-c a" . org-agenda)
                    ("C-c c" . org-capture)
                    )
             :config
             (require 'ox-latex)
             (setq org-log-done t)
             (defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states) ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
             (setq org-journal-directory "~/Dropbox/Journal/")
             (defun get-journal-file-today ()
               "Return filename for today's journal entry."
               (let ((daily-name (format-time-string "%Y-%m-%d")))
                 (expand-file-name (concat org-journal-directory daily-name ".org"))))
             (defun journal-file-today ()
               "Create and load a journal file based on today's date."
               (interactive)
               (find-file (get-journal-file-today)))
             (setq org-capture-templates '(
                                           ("j" "Journal entry"
                                            entry (file (get-journal-file-today))
                                            "* %U %?\n\n"
                                            :empty-lines 0)
                                           ("i" "Inbox"
                                            entry (file "~/Dropbox/orgmode/inbox.org"
                                                        :empty-lines 0))
                                           ))
             (setq org-todo-keywords
      '((sequence "TODO(t)" "WAITING(w@/!)" "HOLD(h@/!)" "|" "DONE(d@/!)" "DELEGATED(l@/!)" "CANCELLED(c@/!)")))
             (setq org-log-into-drawer t)
             (setq org-agenda-window-setup 'current-window)
             (setq org-latex-pdf-process
                   '("latexmk -xelatex -f %f"))
             (setq org-export-latex-hyperref-format "\\ref{%s}")
             (defun org-export-latex-no-toc (depth)  
               (when depth
                 (format "%% Org-mode is exporting headings to %s levels.\n"
                         depth)))
             (setq org-export-latex-format-toc-function 'org-export-latex-no-toc)
             )
;;; Put at the top of the .org file: "#+LaTeX_CLASS: academicarticle"
(add-to-list 'org-latex-classes
             '("academicarticle"
               "\\documentclass[final,twoside,open=any,BCOR10mm,DIV14,dvipsnames,svgnames,captions=tableheading]{scrartcl}
                \\usepackage[natbibapa]{apacite}
                \\bibliographystyle{apacite}
                \\usepackage{epigraph}
                \\setlength\\epigraphwidth{.8\\textwidth}
                \\usepackage{helvet}
                \\usepackage{courier}
                \\usepackage{fontspec,xunicode,xltxtra}
                \\setmainfont{Adobe Garamond Pro}
                \\setkomafont{disposition}{\\sffamily\\bfseries}
                \\usepackage[autostyle=true,english=british]{csquotes}
                \\usepackage[british]{babel}
                \\usepackage[onehalfspacing]{setspace}
                \\usepackage[protrusion=true,stretch=10,shrink=10]{microtype}
                \\usepackage{graphicx}
                \\graphicspath{{images/}}
                \\usepackage{float}
                \\usepackage{fancybox}
                \\usepackage{mathtools,amsmath,amssymb,amsthm,thmtools,thm-restate,siunitx,centernot,tikz-qtree,tikz-qtree-compat}
                \\sisetup{detect-all}
                \\usepackage{rotating}
                \\usepackage{enumitem}
                \\usepackage{multirow}
                \\usepackage{tcolorbox}
                \\usepackage{scrlayer-scrpage}
                \\usepackage{comment}
                \\usepackage[obeyDraft]{todonotes}
                \\usepackage{multicol}
                \\usepackage[colorlinks=true,urlcolor=SteelBlue4,linkcolor=Firebrick4]{hyperref}
                \\hypersetup{
                  pdftitle = {{{TITLE}}}
                  pdfauthor = {{{AUTHOR}}}}
                [NO-DEFAULT-PACKAGES]
                [NO-PACKAGES]"
               ("\\section{%s}" . "\\section*{%s}") ; * section
               ("\\subsection{%s}" . "\\subsection*{%s}") ; ** subsection
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}") ; *** subsection
               ("\\paragraph{%s}" . "\\paragraph*{%s}") ; **** paragraph
               ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))) ; ***** subparagraph ; ****** itemize ; - itemize

;; Make emacs find latex (so that C-c C-x C-l works on orgmode)
(setenv "PATH" (concat (getenv "PATH") ":/Library/TeX/texbin"))

(use-package tex
             :ensure auctex
             :config
             (setq-default TeX-master nil) ; Query for master file
             (setq TeX-auto-save t)
             (setq TeX-parse-self t)
             )

(use-package reftex
             :ensure t
             :config
             (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
             (add-hook 'bibtex-mode-hook 'turn-on-auto-revert-mode) ; auto-reload .bib file on change from external source
             (setq reftex-plug-into-AUCTeX t)
             (setq-default TeX-master "../master") ; All master files called "master".
             (setq reftex-cite-format 'natbib) ; Set natbib as the default citation style
             (setq reftex-default-bibliography '("~/Dropbox/library.bib"))
             )

(use-package helm-bibtex
             :ensure t
             :config
             (setq bibtex-completion-bibliography
                   '("~/Dropbox/library.bib"))
             )
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files
   (quote
    ("/Users/hugopoon/Dropbox/Work/Quintessentially Wine APAC/" "/Users/hugopoon/Dropbox/Work/Quintessentially Wine APAC/meetings/" "/Users/hugopoon/Dropbox/Work/Quintessentially Wine APAC/sourcingreq/" "/Users/hugopoon/Dropbox/Work/Quintessentially Wine APAC/events/" "/Users/hugopoon/Dropbox/Work/Quintessentially Wine APAC/edm/" "/Users/hugopoon/Dropbox/Work/Quintessentially Wine APAC/admin/")))
 '(package-selected-packages
   (quote
    (ox-latex zenburn-theme use-package powerline helm-projectile helm-bibtex auctex)))
 '(package-selected-packagesc
   (quote
    (helm-bibtex ox-latex zenburn-theme use-package powerline helm-projectile auctex))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
