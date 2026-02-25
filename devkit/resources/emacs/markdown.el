;;; markdowns.el --- Markdown configurations

;;; Commentary:
;; Markdown-specific configurations including syntax highlighting,
;; preview, and auto-completion.

;;; Code:

;; Markdown support
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
        ("\\.md\\'" . markdown-mode)
        ("\\.markdown\\'" . markdown-mode)
  :init (setq markdown-command "multimarkdown"))

;; Cape (Completion At Point Extensions) for better text/markdown auto-completion
(use-package cape
  :ensure t
  :init
  (add-hook 'text-mode-hook (lambda ()
                              (add-to-list 'completion-at-point-functions 'cape-dabbrev)
                              (add-to-list 'completion-at-point-functions 'cape-file))))

(provide 'markdown)
;;; markdowns.el ends here
