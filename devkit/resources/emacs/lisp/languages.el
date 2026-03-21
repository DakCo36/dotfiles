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

(provide 'languages)
