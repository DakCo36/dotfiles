(use-package agent-shell
    :ensure t
    
    :ensure-system-package
    (
        ;; Claude
        ;; (claude . "brew install claude-code")
        ;; (claude-agent-acp . "npm install -g @zed-industries/claude-agent-acp")

        (codex . "npm install -g @openai/codex")
        (codex-acp . "npm install -g @zed-industries/codex-acp")
    ))

(provide 'ai)
