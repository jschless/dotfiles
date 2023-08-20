(setq inhibit-startup-message t)

(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode 10)

(menu-bar-mode -1)
(toggle-frame-fullscreen)


(setq visible-bell t)

(add-to-list 'default-frame-alist '(fullscreen . maximized))


(load-theme 'deeper-blue)

;; Initialize package sources
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents
 (package-refresh-contents))

;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
   (package-install 'use-package))

(global-set-key (kbd "<escape>") `keyboard-escape-quit)
(global-set-key (kbd "C-M-<tab>") 'counsel-switch-buffer)
(global-set-key (kbd "C->") 'text-scale-increase)
(global-set-key (kbd "C-<") 'text-scale-decrease)
(column-number-mode)
(global-display-line-numbers-mode t)
(dolist (mode `(term-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))


(require 'use-package)
(setq use-package-always-ensure t)

(use-package command-log-mode)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(ein jupyter lsp-python-ms lsp-pyright pyvenv hide-mode-line treemacs counsel ivy-rich which-key rainbow-delimiters doom-modeline swiper diminish ivy command-log-mode)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Rust config
(require 'rust-mode)
(add-hook 'rust-mode-hook
          (lambda () (setq indent-tabs-mode nil)))

(use-package rustic
  :ensure
  :bind (:map rustic-mode-map
              ("M-j" . lsp-ui-imenu)
              ("M-?" . lsp-find-references)
              ("C-c C-c l" . flycheck-list-errors)
              ("C-c C-c a" . lsp-execute-code-action)
              ("C-c C-c r" . lsp-rename)
              ("C-c C-c q" . lsp-workspace-restart)
              ("C-c C-c Q" . lsp-workspace-shutdown)
              ("C-c C-c s" . lsp-rust-analyzer-status))
  :config
  ;; uncomment for less flashiness
  ;; (setq lsp-eldoc-hook nil)
  ;; (setq lsp-enable-symbol-highlighting nil)
  ;; (setq lsp-signature-auto-activate nil)

  ;; comment to disable rustfmt on save
  (setq rustic-format-on-save t)
  (add-hook 'rustic-mode-hook 'rk/rustic-mode-hook))

(defun rk/rustic-mode-hook ()
  ;; so that run C-c C-c C-r works without having to confirm, but don't try to
  ;; save rust buffers that are not file visiting. Once
  ;; https://github.com/brotzeit/rustic/issues/253 has been resolved this should
  ;; no longer be necessary.
  (when buffer-file-name
    (setq-local buffer-save-without-query t))
  (add-hook 'before-save-hook 'lsp-format-buffer nil t))

(use-package lsp-mode
  :ensure
  :commands lsp
  :custom
  ;; what to use when checking on-save. "check" is default, I prefer clippy
  (lsp-rust-analyzer-cargo-watch-command "clippy")
  (lsp-eldoc-render-all t)
  (lsp-idle-delay 0.6)
  ;; enable / disable the hints as you prefer:
  (lsp-inlay-hint-enable t)
  ;; These are optional configurations. See https://emacs-lsp.github.io/lsp-mode/page/lsp-rust-analyzer/#lsp-rust-analyzer-display-chaining-hints for a full list
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-parameter-hints nil)
  (lsp-rust-analyzer-display-reborrow-hints nil)
  :config
  (add-hook 'lsp-mode-hook 'lsp-ui-mode)
  :hook (python-mode . lsp-deferred))


(use-package lsp-ui
  :ensure
  :commands lsp-ui-mode
  :custom
  (lsp-ui-peek-always-show t)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-doc-enable nil))

(use-package company
  :ensure
  :custom
  (company-idle-delay 0.5) ;; how long to wait until popup
  ;; (company-begin-commands nil) ;; uncomment to disable popup
  :bind
  (:map company-active-map
	      ("C-n". company-select-next)
	      ("C-p". company-select-previous)
	      ("M-<". company-select-first)
	      ("M->". company-select-last))
    (:map company-mode-map
	("<tab>". tab-indent-or-complete)
	("TAB". tab-indent-or-complete)))

(use-package yasnippet
  :ensure
  :config
  (yas-reload-all)
  (add-hook 'prog-mode-hook 'yas-minor-mode)
  (add-hook 'text-mode-hook 'yas-minor-mode))

(defun company-yasnippet-or-completion ()
  (interactive)
  (or (do-yas-expand)
      (company-complete-common)))

(defun check-expansion ()
  (save-excursion
    (if (looking-at "\\_>") t
      (backward-char 1)
      (if (looking-at "\\.") t
        (backward-char 1)
        (if (looking-at "::") t nil)))))

(defun do-yas-expand ()
  (let ((yas/fallback-behavior 'return-nil))
    (yas/expand)))

(defun tab-indent-or-complete ()
  (interactive)
  (if (minibufferp)
      (minibuffer-complete)
    (if (or (not yas/minor-mode)
            (null (do-yas-expand)))
        (if (check-expansion)
            (company-complete-common)
          (indent-for-tab-command)))))

(use-package flycheck :ensure)

;; END RUST CONFIG

;; BEGIN PYTHON CONFIG
(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp))))  ; or lsp-deferred

;; Provides workspaces with file browsing (tree file viewer)
;; and project management when coupled with `projectile`.
(use-package treemacs
  :ensure t
  :defer t
  :config
  (setq treemacs-no-png-images t
	  treemacs-width 24)
  :bind ("C-c t" . treemacs))

;; Provide LSP-mode for python, it requires a language server.
;; I use `lsp-pyright`. Know that you have to `M-x lsp-restart-workspace` 
;; if you change the virtual environment in an open python buffer.


;; Provides completion, with the proper backend
;; it will provide Python completion.

;; (use-package company
;;   :ensure t
;;   :defer t
;;   :diminish
;;   :config
;;   (setq company-dabbrev-other-buffers t
;;         company-dabbrev-code-other-buffers t)
;;   :hook ((text-mode . company-mode)
;;          (prog-mode . company-mode)))

;; Provides visual help in the buffer 
;; For example definitions on hover. 
;; The `imenu` lets me browse definitions quickly.
;; (use-package lsp-ui
;;   :ensure t
;;   :defer t
;;   :config
;;   (setq lsp-ui-sideline-enable nil
;; 	    lsp-ui-doc-delay 2)
;;   :hook (lsp-mode . lsp-ui-mode)
;;   :bind (:map lsp-ui-mode-map
;; 	      ("C-c i" . lsp-ui-imenu)))

;; Integration with the debug server 
;; (use-package dap-mode
;;   :ensure t
;;   :defer t
;;   :after lsp-mode
;;   :config
;;   (dap-auto-configure-mode))

;; Built-in Python utilities
;; (use-package python
;;   :ensure t
;;   :config
;;   ;; Remove guess indent python message
;;   (setq python-indent-guess-indent-offset-verbose nil)
;;   ;; Use IPython when available or fall back to regular Python 
;;   (cond
;;    ((executable-find "ipython")
;;     (progn
;;       (setq python-shell-buffer-name "IPython")
;;       (setq python-shell-interpreter "ipython")
;;       (setq python-shell-interpreter-args "-i --simple-prompt")))
;;    ((executable-find "python3")
;;     (setq python-shell-interpreter "python3"))
;;    ((executable-find "python2")
;;     (setq python-shell-interpreter "python2"))
;;    (t
;;     (setq python-shell-interpreter "python"))))

;; ;; Hide the modeline for inferior python processes
;; (use-package inferior-python-mode
;;   :ensure nil
;;   :hook (inferior-python-mode . hide-mode-line-mode))

;; ;; Required to hide the modeline 
;; (use-package hide-mode-line
;;   :ensure t
;;   :defer t)

;; ;; Required to easily switch virtual envs 
;; ;; via the menu bar or with `pyvenv-workon` 
;; ;; Setting the `WORKON_HOME` environment variable points 
;; ;; at where the envs are located. I use miniconda. 
;; (use-package pyvenv
;;   :ensure t
;;   :defer t
;;   :config
;;   ;; Setting work on to easily switch between environments
;;   (setenv "WORKON_HOME" (expand-file-name "~/miniconda3/envs/"))
;;   ;; Display virtual envs in the menu bar
;;   (setq pyvenv-menu t)
;;   ;; Restart the python process when switching environments
;;   (add-hook 'pyvenv-post-activate-hooks (lambda ()
;; 					  (pyvenv-restart-python)))
;;   :hook (python-mode . pyvenv-mode))

;; ;; Language server for Python 
;; ;; Read the docs for the different variables set in the config.
;; (use-package lsp-pyright
;;   :ensure t
;;   :defer t
;;   :config
;;   (setq lsp-clients-python-library-directories '("/usr/" "~/miniconda3/pkgs"))
;;   (setq lsp-pyright-disable-language-service nil
;; 	lsp-pyright-disable-organize-imports nil
;; 	lsp-pyright-auto-import-completions t
;; 	lsp-pyright-use-library-code-for-types t
;; 	lsp-pyright-venv-path "~/miniconda3/envs")
;;   :hook ((python-mode . (lambda () 
;;                           (require 'lsp-pyright) (lsp-deferred)))))

;; Format the python buffer following YAPF rules
;; There's also blacken if you like it better.
;; (use-package yapfify
;;   :ensure t
;;   :defer t
;;   :hook (python-mode . yapf-mode))

;; END PYTHON CONFIG 
(use-package diminish)
(use-package swiper)
(use-package ivy
  :diminish
  :bind (("C-s" . 'swiper)
         :map ivy-minibuffer-map
         ("TAB" . ivy-alt-done)	
         ("C-l" . ivy-alt-done)
         ("C-j" . ivy-next-line)
         ("C-k" . ivy-previous-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :config
  (ivy-mode 1))

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  )

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(use-package counsel
  :bind (("M-x" . counsel-M-x)
	 ("C-x b" . counsel-ibuffer)
	 ("C-x C-f" . counsel-find-file)
	 )
  )

(use-package ivy-rich
  :init
  (ivy-rich-mode 1))
