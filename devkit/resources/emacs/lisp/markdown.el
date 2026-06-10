;;; markdowns.el --- Markdown configurations

;;; Commentary:
;; Markdown-specific configurations including syntax highlighting,
;; preview, and auto-completion.

;;; Code:

;; Switch a markdown buffer between writing (edit) and reading (view) modes.
;; view modes auto-hide markup and enter read-only; editing modes show markup.
(defun markdown-read-mode ()
  "Switch the current markdown buffer to read-only reading view."
  (interactive)
  (if (derived-mode-p 'gfm-mode) (gfm-view-mode) (markdown-view-mode)))

(defun markdown-write-mode ()
  "Switch the current markdown buffer back to editable writing mode."
  (interactive)
  (if (derived-mode-p 'gfm-mode) (gfm-mode) (markdown-mode))
  (read-only-mode -1))

;; Markdown support
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
        ("\\.md\\'" . markdown-mode)
        ("\\.markdown\\'" . markdown-mode)
  :init (setq markdown-command "multimarkdown")
  :custom
  (markdown-header-scaling t)                ;; Larger sizes per heading level
  (markdown-fontify-code-blocks-natively t)  ;; Syntax-highlight fenced code blocks
  :hook (markdown-mode . visual-line-mode)
  :bind (:map markdown-mode-map
         ("C-c m r" . markdown-read-mode)
         ("C-c m w" . markdown-write-mode)))

;; Cape (Completion At Point Extensions) for better text/markdown auto-completion
(use-package cape
  :ensure t
  :init
  (add-hook 'text-mode-hook (lambda ()
                              (add-to-list 'completion-at-point-functions 'cape-dabbrev)
                              (add-to-list 'completion-at-point-functions 'cape-file))))

(provide 'markdown)
;;; markdowns.el ends here
