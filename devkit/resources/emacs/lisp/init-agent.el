;;; init-agent.el  -*- lexical-binding: t; -*-

(use-package agent-shell
    :ensure t

    :ensure-system-package
    (
        ;; Claude
        (claude . "brew install claude-code")
        (claude-agent-acp . "npm install -g @zed-industries/claude-agent-acp")

        ;; Codex
        (codex . "npm install -g @openai/codex")
        (codex-acp . "npm install -g @zed-industries/codex-acp")
    ))

;; Minuet

(defun init-agent--minuet-resume-auto ()
  "Resume automatic suggestions before the next command."
  (remove-hook 'pre-command-hook #'init-agent--minuet-resume-auto t)
  (minuet-auto-suggestion-mode 1))


(defun init-agent--minuet-dismiss-on-quit ()
  "Dismiss current suggestions and cancel pending automatic requests."
  (when minuet-auto-suggestion-mode
    (minuet-auto-suggestion-mode -1)
    (add-hook 'pre-command-hook #'init-agent--minuet-resume-auto nil t))
  (minuet-dismiss-suggestion))

(use-package minuet
  :ensure t
  :hook (prog-mode . minuet-auto-suggestion-mode)
  :bind
  (("C-c a c" . minuet-show-suggestion)
   ("C-c a y" . minuet-complete-with-minibuffer)
   ("C-c a p" . minuet-configure-provider)
   :map minuet-active-mode-map
   ("M-RET" . minuet-accept-suggestion)
   ("M-]" . minuet-next-suggestion)
   ("M-[" . minuet-previous-suggestion)
   ("M-<down>" . minuet-accept-suggestion-line)
   ("M-<right>" . minuet-accept-suggestion-word))

  :custom
  (minuet-provider 'codestral)
  (minuet-n-completions 1)
  (minuet-auto-suggestion-debounce-delay 0.6)
  (minuet-auto-suggestion-throttle-delay 1.5)
  :config
  (plist-put minuet-codestral-options
             :end-point "https://api.kilo.ai/api/fim/completions")
  (plist-put minuet-codestral-options
             :model "mistralai/codestral-2508")
  (plist-put minuet-codestral-options
             :api-key "KILO_API_KEY")
  (minuet-set-optional-options
   minuet-codestral-options :max_tokens 64)
  (advice-add 'keyboard-quit :before #'init-agent--minuet-dismiss-on-quit))

(provide 'init-agent)
