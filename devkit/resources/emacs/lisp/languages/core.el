;; Global
(electric-pair-mode 1)

;; Tree-sitter
(use-package treesit-auto
  :config
  (setq treesit-auto-install 'prompt)
  (global-treesit-auto-mode))

;; hs-minor-mode folding blocks
(add-hook 'prog-mode-hook #'hs-minor-mode)

(defun languages--set-indent (use-tabs width)
  "Set buffer-local indentation to USE-TABS and WIDTH."
  (setq-local indent-tabs-mode use-tabs)
  (setq-local tab-width width))

;; Flymake
;; Emacs 30+ Eglot automatically enables Flymake — this hook toggles it off.
;; (add-hook 'eglot-managed-mode-hook #'flymake-mode)

;; [BUG] Eglot Flymake diagnostics silently dropped on non-ASCII paths.
;;
;; Root cause:
;;   eglot.el `eglot-uri-to-path` calls `url-unhex-string`, which returns a
;;   unibyte string. `publishDiagnostics` compares that path with the multibyte
;;   path in `eglot--TextDocumentIdentifier-cache`, so the comparison fails.
;;
;; Fix (commented out — using English paths instead):
;; (with-eval-after-load 'eglot
;;   (advice-add 'eglot-uri-to-path :filter-return
;;               (lambda (path)
;;                 (if (and path (not (multibyte-string-p path)))
;;                     (decode-coding-string path 'utf-8)
;;                   path))))

(provide 'languages/core)
