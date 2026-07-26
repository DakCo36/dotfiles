;;; markdowns.el --- Markdown configurations

;;; Commentary:
;; Markdown-specific configurations including syntax highlighting,
;; preview, and auto-completion.

;;; Code:

;; Switch a markdown buffer between writing (edit) and reading (view) modes.
;; view modes auto-hide markup and enter read-only; editing modes show markup.
;; Header scaling is applied buffer-locally so it is tied to the view mode
;; instead of the global `markdown-header-scaling' face setting.
(defvar-local markdown--header-remap-cookies nil
  "Active face-remap cookies for buffer-local scaled markdown headers.")

(defun markdown--scale-headers (enable)
  "Scale markdown header faces in the current buffer when ENABLE is non-nil."
  (mapc #'face-remap-remove-relative markdown--header-remap-cookies)
  (setq markdown--header-remap-cookies nil)
  (when enable
    (dotimes (level 6)
      (push (face-remap-add-relative
             (intern (format "markdown-header-face-%d" (1+ level)))
             :height (float (nth level markdown-header-scaling-values)))
            markdown--header-remap-cookies))))

(defun markdown-read-mode ()
  "Switch the current markdown buffer to read-only reading view."
  (interactive)
  (if (derived-mode-p 'gfm-mode) (gfm-view-mode) (markdown-view-mode))
  (markdown--scale-headers t))

(defun markdown-write-mode ()
  "Switch the current markdown buffer back to editable writing mode."
  (interactive)
  (if (derived-mode-p 'gfm-mode) (gfm-mode) (markdown-mode))
  (read-only-mode -1)
  (markdown--scale-headers nil))

;; Markdown support
(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
        ("\\.md\\'" . markdown-mode)
        ("\\.markdown\\'" . markdown-mode)
  :init (setq markdown-command "multimarkdown")
  :custom
  ;; Scaling is applied per-buffer in `markdown-read-mode' (see above),
  ;; so the global face setting stays off to keep write mode at normal size.
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
