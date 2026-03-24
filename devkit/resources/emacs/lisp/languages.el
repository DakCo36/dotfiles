;; Global
(electric-pair-mode 1)
(show-paren-mode 1)

;; Treesitter

;; Enable tree-sitter
(use-package treesit-auto
  :config
  (setq treesit-auto-install 'prompt)
  (global-treesit-auto-mode))

;; Associate major modes with file extensions
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

;; hs-minor-mode folding blocks
(add-hook 'prog-mode-hook #'hs-minor-mode)

;; Indentation

;; Helper functions (currently default to 4 spaces)
(defun set-indent (use-tabs width)
  (setq-local indent-tabs-mode use-tabs)
  (setq-local tab-width width))

;; Go: tabs, display width 4 (gofmt enforced)
(add-hook 'go-ts-mode-hook (lambda ()
                             (set-indent t 4)
                             (setq-local go-ts-mode-indent-offset 4)))

;; Enable electric-indent-local-mode only if save triggered
(dolist (hook '(go-mode-hook go-ts-mode-hook))
  (add-hook hook
            (lambda ()
              ;; (electric-indent-local-mode -1)
              (add-hook 'before-save-hook #'eglot-format-buffer nil t))))

;; Project
(with-eval-after-load 'project
  (add-to-list 'project-vc-extra-root-markers "go.mod"))

;; Ruby
(add-hook 'ruby-mode-hook (lambda () (set-indent nil 2)))
(add-hook 'ruby-ts-mode-hook (lambda () (set-indent nil 2)))

;; JS/TS: 2 spaces
(dolist (hook '(js-ts-mode-hook js-mode-hook))
  (add-hook hook (lambda ()
                   (set-indent nil 2)
                   (setq-local js-indent-level 2))))
(dolist (hook '(typescript-ts-mode-hook typescript-mode-hook tsx-ts-mode-hook))
  (add-hook hook (lambda ()
                   (set-indent nil 2)
                   (setq-local typescript-indent-level 2)
                   (setq-local typescript-ts-mode-indent-offset 2))))


;; Eglot

;; Activate ruby-lsp for both ruby-mode and ruby-ts-mode
;; Ensure ruby-lsp server installed globally
;; $ gem install ruby-lsp
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
			   '((ruby-mode ruby-ts-mode) . ("ruby-lsp"))))
(add-hook 'ruby-mode-hook 'eglot-ensure)
(add-hook 'ruby-ts-mode-hook 'eglot-ensure)

;; Activate go-lsp for go-ts-mode
;; Ensure go-lsp server installed globally
;; $ go install golang.org/x/tools/gopls@latest
(add-hook 'go-ts-mode-hook 'eglot-ensure)

;; Activate js/ts for js/ts-ts-mode
;; Ensure js/ts lsp server installed globally
;; $ npm install -g typescript-language-server typescript
(add-hook 'js-ts-mode-hook 'eglot-ensure)
(add-hook 'typescript-ts-mode-hook 'eglot-ensure)
(add-hook 'tsx-ts-mode-hook 'eglot-ensure)
(add-hook 'js-mode-hook 'eglot-ensure)
(add-hook 'typescript-mode-hook 'eglot-ensure)

;; Activate python-lsp for python-mode
;; Ensure python-lsp server installed globally
;; $ pip install 'python-lsp-server' python-lsp-ruff
(add-hook 'python-ts-mode-hook 'eglot-ensure)
(add-hook 'python-mode-hook 'eglot-ensure)

(defun eglot--python-detect-venv ()
  "Auto-detect virtualenv in project root."
  (let* ((root (project-root (project-current)))
		 (venv (seq-find #'file-directory-p
						 (mapcar (lambda (d) (expand-file-name d root))
								 '(".venv" "venv" ".env" "env")))))
	(when venv
	  (setq-local python-shell-virtualenv-root venv))))
(add-hook 'python-ts-mode-hook 'eglot--python-detect-venv)
(add-hook 'python-mode-hook #'eglot--python-detect-venv)

;; Activate rust-analyzer for rust-mode
;; Ensure rust-analyzer server installed globally
;; $ rustup component add rust-analyzer
(add-hook 'rust-ts-mode-hook 'eglot-ensure)
(add-hook 'rust-mode-hook 'eglot-ensure)

;; flymake
;; Emacs 30+ eglot automatically enables flymake — this hook toggles it OFF
;; (add-hook 'eglot-managed-mode-hook #'flymake-mode)

;; [BUG] eglot flymake diagnostics silently dropped on non-ASCII paths (e.g. Korean)
;;
;; Root cause:
;;   eglot.el `eglot-uri-to-path` (L1088) calls `url-unhex-string` which returns
;;   a **unibyte** string (raw UTF-8 bytes, e.g. 236 157 152 for '의').
;;
;;   `publishDiagnostics` handler (L2430) calls `find-it` (L2443) which compares:
;;     (car eglot--TextDocumentIdentifier-cache)  ← multibyte (from file-truename)
;;     (expand-file-name (eglot-uri-to-path uri)) ← unibyte   (from url-unhex-string)
;;
;;   `equal` on unibyte vs multibyte always returns nil for non-ASCII chars,
;;   so `find-it` returns nil → diagnostics go to `flymake-list-only-diagnostics`
;;   instead of the buffer's `eglot--diagnostics` → flymake shows [0 0] forever.
;;
;; Fix (commented out — using English paths instead):
;; (with-eval-after-load 'eglot
;;   (advice-add 'eglot-uri-to-path :filter-return
;;               (lambda (path)
;;                 (if (and path (not (multibyte-string-p path)))
;;                     (decode-coding-string path 'utf-8)
;;                   path))))

(provide 'languages)
